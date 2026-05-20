#!/usr/bin/env bash
# Read-only repo hygiene probe with optional tick-ledger and bead filing.
set -euo pipefail

REPO_HYGIENE_SCRIPT_PATH="${BASH_SOURCE[0]}" python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "repo-hygiene-tick/v1"
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/repo-hygiene-tick.jsonl"

DEFAULT_FLEET_REPOS = [
    "/Users/josh/Developer/flywheel",
    "/Users/josh/Developer/skillos",
    "/Users/josh/Developer/zesttube",
    "/Users/josh/Developer/mobile-eats",
    "/Users/josh/Developer/clutterfreespaces",
    "/Users/josh/Developer/polymarket-pico-z",
    "/Users/josh/Developer/agent-bench",
    "/Users/josh/Desktop/Projects/clients/alps-insurance",
]

DEFAULT_THRESHOLDS = {
    "worktree_count": {"p2": 5, "p1": 10, "p0": 20},
    "stash_count": {"p2": 5, "p1": 10, "p0": 20},
    "local_only_merged_branch_count": {"p2": 10, "p1": 25, "p0": 50},
    "main_ff_drift": {"p2": 50, "p1": 100, "p0": 500},
    "tracked_substrate_bloat_mb": {"p2": 100, "p1": 250, "p0": 500},
}

THRESHOLD_KEYS = {
    f"{metric}_{severity}": (metric, severity)
    for metric, severities in DEFAULT_THRESHOLDS.items()
    for severity in severities
}

CLASS_BY_METRIC = {
    "worktree_count": "worktree-orphan",
    "stash_count": "stash-buildup",
    "local_only_merged_branch_count": "branch-debt",
    "main_ff_drift": "main-FF-divergence",
    "tracked_substrate_bloat_mb": "tracked-substrate-bloat",
}

REMEDIATION = {
    "worktree-orphan": "Run git worktree list, retire stale worktrees after confirming no live pane owns them.",
    "stash-buildup": "Review git stash list, promote useful work to branches or drop obsolete stashes.",
    "branch-debt": "Delete local-only branches already merged to main after checking no active pane owns them.",
    "main-FF-divergence": "Fast-forward local main from origin/main after verifying the worktree is clean.",
    "tracked-substrate-bloat": "Move tracked .flywheel/runtime, .flywheel/state, or .flywheel/evidence payloads out of Git or untrack them.",
}


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def git(cwd: Path, args: list[str]) -> str:
    proc = run(["git", *args], cwd)
    if proc.returncode != 0:
        return ""
    return proc.stdout


def script_repo_root() -> Path:
    script = Path(os.environ.get("REPO_HYGIENE_SCRIPT_PATH", "")).expanduser()
    if script.is_absolute() and len(script.parents) >= 2:
        return script.parents[1]
    return Path.cwd()


def parse_scalar(value: str) -> Any:
    value = value.strip()
    if value == "":
        return ""
    try:
        if "." in value:
            return float(value)
        return int(value)
    except ValueError:
        return value.strip("\"'")


def read_threshold_file(path: Path, repo: Path) -> dict[str, dict[str, float]]:
    thresholds = json.loads(json.dumps(DEFAULT_THRESHOLDS))
    if not path.exists():
        return thresholds

    section = ""
    repo_key = ""
    repo_names = {repo.name, str(repo)}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip(" "))
        stripped = line.strip()
        if indent == 0 and stripped.endswith(":"):
            section = stripped[:-1]
            repo_key = ""
            continue
        if section == "defaults" and indent == 2 and ":" in stripped:
            key, value = [part.strip() for part in stripped.split(":", 1)]
            apply_threshold(thresholds, key, parse_scalar(value))
        elif section == "repos" and indent == 2 and stripped.endswith(":"):
            repo_key = stripped[:-1].strip("\"'")
        elif section == "repos" and indent == 4 and repo_key in repo_names and ":" in stripped:
            key, value = [part.strip() for part in stripped.split(":", 1)]
            apply_threshold(thresholds, key, parse_scalar(value))
    return thresholds


def apply_threshold(thresholds: dict[str, dict[str, float]], flat_key: str, value: Any) -> None:
    if flat_key not in THRESHOLD_KEYS:
        return
    metric, severity = THRESHOLD_KEYS[flat_key]
    if isinstance(value, (int, float)):
        thresholds[metric][severity] = value


def threshold_path(repo: Path, explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).expanduser()
    local = repo / ".flywheel/hygiene-thresholds.yaml"
    if local.exists():
        return local
    return script_repo_root() / ".flywheel/hygiene-thresholds.yaml"


def count_lines(text: str) -> int:
    return 0 if not text else len([line for line in text.splitlines() if line.strip()])


def worktree_count(repo: Path) -> int:
    return len([line for line in git(repo, ["worktree", "list", "--porcelain"]).splitlines() if line.startswith("worktree ")])


def stash_count(repo: Path) -> int:
    return count_lines(git(repo, ["stash", "list"]))


def base_branch(repo: Path) -> str:
    if run(["git", "show-ref", "--verify", "--quiet", "refs/heads/main"], repo).returncode == 0:
        return "main"
    if run(["git", "show-ref", "--verify", "--quiet", "refs/heads/master"], repo).returncode == 0:
        return "master"
    return "HEAD"


def local_only_merged_branch_count(repo: Path) -> int:
    base = base_branch(repo)
    out = git(repo, ["for-each-ref", "--merged", base, "--format=%(refname:short)|%(upstream:short)", "refs/heads"])
    total = 0
    for line in out.splitlines():
        branch, _, upstream = line.partition("|")
        if branch in {"main", "master"}:
            continue
        if not upstream.strip():
            total += 1
    return total


def main_ff_drift(repo: Path) -> int:
    if run(["git", "show-ref", "--verify", "--quiet", "refs/remotes/origin/main"], repo).returncode != 0:
        return 0
    out = git(repo, ["rev-list", "--count", "main..origin/main"]).strip()
    try:
        return int(out)
    except ValueError:
        return 0


def tracked_substrate(repo: Path) -> tuple[int, int]:
    proc = subprocess.run(
        ["git", "ls-files", "-z", ".flywheel/runtime", ".flywheel/state", ".flywheel/evidence"],
        cwd=str(repo),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        return 0, 0
    total = 0
    count = 0
    for raw in proc.stdout.split(b"\0"):
        if not raw:
            continue
        path = repo / raw.decode("utf-8", errors="replace")
        if path.exists() and path.is_file():
            count += 1
            total += path.stat().st_size
    return count, total


def measure(repo: Path) -> dict[str, Any]:
    tracked_count, tracked_bytes = tracked_substrate(repo)
    return {
        "worktree_count": worktree_count(repo),
        "stash_count": stash_count(repo),
        "local_only_merged_branch_count": local_only_merged_branch_count(repo),
        "main_ff_drift": main_ff_drift(repo),
        "tracked_substrate_bloat_bytes": tracked_bytes,
        "tracked_substrate_bloat_mb": round(tracked_bytes / 1024 / 1024, 2),
        "tracked_substrate_file_count": tracked_count,
    }


def format_number(value: Any) -> str:
    if isinstance(value, float):
        return f"{value:.2f}".rstrip("0").rstrip(".")
    return str(value)


def alert_for(metric: str, value: float, thresholds: dict[str, dict[str, float]]) -> dict[str, Any] | None:
    levels = thresholds[metric]
    severity = ""
    threshold = 0.0
    for level in ("p0", "p1", "p2"):
        if value > float(levels[level]):
            severity = level.upper()
            threshold = float(levels[level])
            break
    if not severity:
        return None
    trauma_class = CLASS_BY_METRIC[metric]
    return {
        "class": trauma_class,
        "metric": metric,
        "severity": severity,
        "current": value,
        "threshold": threshold,
        "remediation_hint": REMEDIATION[trauma_class],
    }


def build_alerts(metrics: dict[str, Any], thresholds: dict[str, dict[str, float]]) -> list[dict[str, Any]]:
    alerts = []
    for metric in CLASS_BY_METRIC:
        alert = alert_for(metric, float(metrics[metric]), thresholds)
        if alert:
            alerts.append(alert)
    return alerts


def read_open_beads(repo: Path, br_bin: str) -> list[dict[str, Any]]:
    proc = run([br_bin, "list", "--json"], repo)
    if proc.returncode != 0 or not proc.stdout.strip():
        return []
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return []
    if isinstance(payload, list):
        items = payload
    else:
        items = payload.get("issues", [])
    return [item for item in items if isinstance(item, dict) and item.get("status") not in {"closed", "done"}]


def recent_duplicate(beads: list[dict[str, Any]], alert: dict[str, Any], repo: Path) -> bool:
    prefix = f"hygiene-tick: {alert['class']} exceeds threshold "
    suffix = f" at {repo}"
    cutoff = datetime.now(timezone.utc).timestamp() - 24 * 60 * 60
    for bead in beads:
        title = str(bead.get("title", ""))
        if not (title.startswith(prefix) and title.endswith(suffix)):
            continue
        created_at = str(bead.get("created_at", ""))
        if not created_at:
            return True
        try:
            created = datetime.fromisoformat(created_at.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return True
        if created >= cutoff:
            return True
    return False


def bead_title(alert: dict[str, Any], repo: Path) -> str:
    return (
        f"hygiene-tick: {alert['class']} exceeds threshold "
        f"(current={format_number(alert['current'])} threshold={format_number(alert['threshold'])}) at {repo}"
    )


def bead_description(envelope: dict[str, Any], alert: dict[str, Any]) -> str:
    return (
        f"Auto-filed by repo-hygiene-doctor for `{alert['class']}`.\n\n"
        f"Remediation hint: {alert['remediation_hint']}\n\n"
        "Metrics envelope:\n"
        "```json\n"
        f"{json.dumps(envelope, indent=2, sort_keys=True)}\n"
        "```"
    )


def file_beads(repo: Path, envelope: dict[str, Any], br_bin: str, dry_run: bool) -> list[dict[str, Any]]:
    actions = []
    open_beads = read_open_beads(repo, br_bin)
    for alert in envelope["alerts"]:
        title = bead_title(alert, repo)
        if recent_duplicate(open_beads, alert, repo):
            actions.append({"class": alert["class"], "status": "duplicate_open_recent", "title": title})
            continue
        if dry_run:
            actions.append({"class": alert["class"], "status": "dry_run", "title": title})
            continue
        description = bead_description(envelope, alert)
        priority = alert["severity"].replace("P", "")
        proc = run(
            [
                br_bin,
                "create",
                title,
                "--type",
                "bug",
                "--priority",
                priority,
                "--description",
                description,
                "--json",
            ],
            repo,
        )
        status = "created" if proc.returncode == 0 else "create_failed"
        action = {"class": alert["class"], "status": status, "title": title}
        if proc.stdout.strip():
            action["stdout"] = proc.stdout.strip()
        if proc.stderr.strip():
            action["stderr"] = proc.stderr.strip()
        actions.append(action)
        if status == "created":
            open_beads.append({"title": title, "status": "open", "created_at": iso_now()})
    return actions


def append_ledger(path: Path, envelope: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(envelope, sort_keys=True) + "\n")


def envelope_for(repo: Path, args: argparse.Namespace) -> dict[str, Any]:
    ts = iso_now()
    repo = repo.expanduser().resolve()
    disabled = repo / ".flywheel/hygiene-tick.disabled"
    base = {
        "schema_version": SCHEMA_VERSION,
        "ts": ts,
        "repo": str(repo),
        "repo_name": repo.name,
        "alerts": [],
    }
    if disabled.exists():
        return {**base, "status": "skipped", "skipped_reason": "hygiene-tick.disabled"}
    if run(["git", "rev-parse", "--is-inside-work-tree"], repo).returncode != 0:
        return {**base, "status": "skipped", "skipped_reason": "not_git_repo"}

    thresholds_file = threshold_path(repo, args.thresholds)
    thresholds = read_threshold_file(thresholds_file, repo)
    metrics = measure(repo)
    alerts = build_alerts(metrics, thresholds)
    return {
        **base,
        "status": "measured",
        "metrics": metrics,
        "thresholds": thresholds,
        "thresholds_file": str(thresholds_file),
        "alerts": alerts,
    }


def repos_from_args(args: argparse.Namespace) -> list[Path]:
    repos = [Path(repo).expanduser() for repo in args.repo]
    if args.fleet_default:
        env_fleet = os.environ.get("FLYWHEEL_HYGIENE_FLEET_REPOS", "")
        fleet = [item for item in env_fleet.split(":") if item] if env_fleet else DEFAULT_FLEET_REPOS
        repos.extend(Path(item).expanduser() for item in fleet)
    if not repos:
        repos = [Path.cwd()]
    seen: set[str] = set()
    unique = []
    for repo in repos:
        key = str(repo.resolve())
        if key not in seen and repo.exists():
            seen.add(key)
            unique.append(repo)
    return unique


def main() -> int:
    parser = argparse.ArgumentParser(description="Measure repo hygiene and optionally file threshold beads.")
    parser.add_argument("--repo", action="append", default=[], help="Repo path to measure; repeatable.")
    parser.add_argument("--fleet-default", action="store_true", help="Measure the default 8-orch fleet repo list.")
    parser.add_argument("--thresholds", help="Threshold YAML path; defaults to repo-local then flywheel canonical.")
    parser.add_argument("--write-ledger", action="store_true", help="Append one JSON envelope per repo to the hygiene ledger.")
    parser.add_argument("--ledger", default=str(DEFAULT_LEDGER), help="Ledger JSONL path.")
    parser.add_argument("--auto-bead", action="store_true", help="Create br beads for P0/P1/P2 alerts.")
    parser.add_argument("--dry-run", action="store_true", help="Measure and plan bead actions without creating beads.")
    parser.add_argument("--br-bin", default="br", help="br executable for auto-bead filing.")
    parser.add_argument("--json", action="store_true", help="Emit JSON.")
    args = parser.parse_args()

    envelopes = []
    for repo in repos_from_args(args):
        envelope = envelope_for(repo, args)
        if args.auto_bead and envelope["status"] == "measured" and envelope["alerts"]:
            envelope["bead_actions"] = file_beads(repo.resolve(), envelope, args.br_bin, args.dry_run)
        if args.write_ledger:
            append_ledger(Path(args.ledger).expanduser(), envelope)
        envelopes.append(envelope)

    payload: Any = envelopes[0] if len(envelopes) == 1 else {"schema_version": SCHEMA_VERSION, "repos": envelopes}
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        for envelope in envelopes:
            print(f"{envelope['repo']}: {envelope['status']} alerts={len(envelope['alerts'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
