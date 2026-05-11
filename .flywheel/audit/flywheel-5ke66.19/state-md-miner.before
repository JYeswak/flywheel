#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "state-md-miner/v1"
DEFAULT_ROSTER = Path.home() / ".local/state/flywheel/fleet-roster.json"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel/state-md-miner"


def parse_ts(value: Any) -> datetime | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", text):
        text = f"{text}T00:00:00Z"
    for candidate in (text, text.replace("Z", "+00:00")):
        try:
            parsed = datetime.fromisoformat(candidate)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            continue
    return None


def now_utc(raw: str | None = None) -> datetime:
    return parse_ts(raw) or datetime.now(timezone.utc)


def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except Exception:
        return None


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return rows
    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
    tmp.replace(path)


def append_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def load_roster(roster: Path, root: Path, explicit_repo: str | None) -> list[dict[str, str]]:
    if explicit_repo:
        repo = Path(explicit_repo).expanduser().resolve()
        return [{"name": repo.name, "repo": str(repo), "source": "explicit"}]

    rows: list[dict[str, str]] = []
    data = read_json(roster)
    if isinstance(data, dict):
        for item in data.get("members") or []:
            if not isinstance(item, dict):
                continue
            repo = item.get("repo") or item.get("path")
            if repo:
                rows.append({"name": str(item.get("name") or Path(str(repo)).name), "repo": str(repo), "source": str(roster)})
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict) and (item.get("repo") or item.get("path")):
                repo = item.get("repo") or item.get("path")
                rows.append({"name": str(item.get("name") or Path(str(repo)).name), "repo": str(repo), "source": str(roster)})

    if not rows and roster.suffix == ".jsonl":
        for item in read_jsonl(roster):
            repo = item.get("repo") or item.get("path")
            if repo:
                rows.append({"name": str(item.get("name") or Path(str(repo)).name), "repo": str(repo), "source": str(roster)})

    if not rows:
        for state in sorted(root.glob("*/.flywheel/STATE.md")):
            rows.append({"name": state.parent.parent.name, "repo": str(state.parent.parent), "source": "root-scan"})
    return rows


def state_paths(repo: Path) -> list[Path]:
    paths = [repo / ".flywheel/STATE.md", repo / "STATE.md"]
    seen: set[str] = set()
    result: list[Path] = []
    for path in paths:
        key = str(path)
        if key not in seen:
            seen.add(key)
            result.append(path)
    return result


def section_kind(heading: str) -> str | None:
    text = heading.lower()
    if "next action" in text or "next safe action" in text:
        return "unresolved"
    if "known gap" in text or "gap" in text or "blocker" in text:
        return "orphaned"
    if "deferred" in text or "parking" in text:
        return "stale"
    if "resume" in text or "handoff" in text:
        return "recurring"
    return None


def normalize_text(text: str) -> str:
    text = re.sub(r"`([^`]+)`", r"\1", text.lower())
    text = re.sub(r"\b[A-Za-z]+-[A-Za-z0-9.]+\b", " BEAD ", text)
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()[:100]


def bead_refs(text: str) -> list[str]:
    return sorted(set(re.findall(r"\b[A-Za-z]+-[A-Za-z0-9.]+\b", text)))


def classify_line(kind: str | None, line: str, stale_cutoff: datetime) -> str | None:
    lowered = line.lower()
    if re.search(r"\b(done|closed|complete|completed|resolved)\b", lowered):
        return None
    if kind == "stale":
        dates = [parse_ts(match.group(0)) for match in re.finditer(r"\b20\d{2}-\d{2}-\d{2}\b", line)]
        dates = [dt for dt in dates if dt is not None]
        if dates and min(dates) <= stale_cutoff:
            return "stale"
        if re.search(r"\b(deferred|parked|stale)\b", lowered):
            return "stale"
    if kind == "unresolved":
        return "unresolved"
    if kind == "orphaned":
        return "orphaned" if not bead_refs(line) else "unresolved"
    if kind == "recurring" and re.search(r"\b(again|recurr|reopened|drift|keeps?|still)\b", lowered):
        return "recurring"
    if re.search(r"\b(next action|known gap|deferred|blocked|todo|fix|repair|follow[- ]?up)\b", lowered):
        return kind or "unresolved"
    return None


def extract_items(repo_row: dict[str, str], now: datetime, stale_days: int) -> list[dict[str, Any]]:
    repo = Path(repo_row["repo"]).expanduser()
    stale_cutoff = now - timedelta(days=stale_days)
    findings: list[dict[str, Any]] = []
    for path in state_paths(repo):
        if not path.exists():
            continue
        try:
            lines = path.read_text(errors="replace").splitlines()
        except Exception:
            continue
        current_kind: str | None = None
        current_heading = ""
        for lineno, raw in enumerate(lines, 1):
            stripped = raw.strip()
            if stripped.startswith("#"):
                current_heading = stripped.lstrip("#").strip()
                current_kind = section_kind(current_heading)
                continue
            if not stripped:
                continue
            bullet = re.match(r"^(?:[-*]|\d+[.)])\s+(.*)$", stripped)
            if bullet:
                item_text = bullet.group(1).strip()
            elif current_kind and re.search(r"\b(next action|known gap|deferred|blocked|todo|fix|repair|follow[- ]?up)\b", stripped, re.I):
                item_text = stripped
            else:
                continue
            item_class = classify_line(current_kind, item_text, stale_cutoff)
            if not item_class:
                continue
            refs = bead_refs(item_text)
            findings.append({
                "class": item_class,
                "repo": str(repo.resolve()) if repo.exists() else str(repo),
                "repo_name": repo_row["name"],
                "state_path": str(path),
                "line": lineno,
                "heading": current_heading,
                "text": item_text,
                "normalized": normalize_text(item_text),
                "bead_refs": refs,
                "has_bead_ref": bool(refs),
            })
    return findings


def add_pattern_findings(findings: list[dict[str, Any]]) -> None:
    repos_by_norm: dict[str, set[str]] = defaultdict(set)
    by_norm: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for finding in findings:
        key = str(finding.get("normalized") or "")
        if not key:
            continue
        repos_by_norm[key].add(str(finding.get("repo")))
        by_norm[key].append(finding)
    for key, repos in repos_by_norm.items():
        if len(repos) < 3:
            continue
        for finding in by_norm[key]:
            finding["class"] = "pattern"
            finding["pattern_repo_count"] = len(repos)


def br_issues(repo: Path) -> list[dict[str, Any]]:
    try:
        proc = subprocess.run(
            ["br", "list", "--all", "--json", "--limit", "0"],
            cwd=str(repo),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=20,
            check=False,
        )
    except Exception:
        return []
    try:
        data = json.loads(proc.stdout)
    except Exception:
        return []
    if isinstance(data, dict) and isinstance(data.get("issues"), list):
        return [row for row in data["issues"] if isinstance(row, dict)]
    if isinstance(data, list):
        return [row for row in data if isinstance(row, dict)]
    return []


def existing_bead(repo: Path, finding: dict[str, Any]) -> str | None:
    needle = f"[state-md-miner] {finding['class']} {finding['normalized'][:80]}"
    for issue in br_issues(repo):
        if str(issue.get("title") or "") == needle:
            return str(issue.get("id") or "")
    return None


def create_bead(repo: Path, finding: dict[str, Any]) -> str | None:
    title = f"[state-md-miner] {finding['class']} {finding['normalized'][:80]}"
    body = "\n".join([
        "## Source",
        "",
        f"- repo: `{repo}`",
        f"- state_path: `{finding['state_path']}`",
        f"- line: {finding['line']}",
        f"- class: `{finding['class']}`",
        "",
        "## Finding",
        "",
        finding["text"],
        "",
        "## Acceptance Criteria",
        "",
        "1. Decide whether the STATE.md item is still valid.",
        "2. Either implement the item or close this bead with an explicit stale/no-longer-needed reason.",
        "3. Update the source STATE.md line or add a bead reference so the next mine does not rediscover it as orphaned.",
        "",
        "## Three-Q",
        "",
        "VALIDATED: source STATE.md line no longer mines as unresolved/orphaned/stale.",
        "DOCUMENTED: source state or close reason records the decision.",
        "SURFACED: bead/no-bead decision is visible to `/flywheel:learn --mine-state`.",
    ])
    existing = existing_bead(repo, finding)
    if existing:
        return existing
    try:
        proc = subprocess.run(
            ["br", "create", title, "--type", "task", "--priority", "2", "--description", body, "--json"],
            cwd=str(repo),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
            check=False,
        )
    except Exception:
        return None
    if proc.returncode != 0:
        return None
    try:
        data = json.loads(proc.stdout)
    except Exception:
        return None
    return str(data.get("id") or data.get("issue", {}).get("id") or "") or None


def decide(args: argparse.Namespace, findings: list[dict[str, Any]], now: datetime) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    decisions: list[dict[str, Any]] = []
    ledger_rows: list[dict[str, Any]] = []
    per_repo_filed: Counter[str] = Counter()
    for finding in findings:
        repo = Path(finding["repo"])
        row = {
            "ts": iso(now),
            "schema_version": SCHEMA_VERSION,
            "repo": finding["repo"],
            "class": finding["class"],
            "state_path": finding["state_path"],
            "line": finding["line"],
            "text": finding["text"],
            "bead_id": None,
            "decision": "planned",
            "no_bead_reason": None,
        }
        if finding.get("has_bead_ref"):
            row["decision"] = "existing_bead_reference"
            row["bead_id"] = ",".join(finding.get("bead_refs") or [])
            row["no_bead_reason"] = "source_state_line_already_references_bead"
        elif args.dry_run or not args.apply:
            row["decision"] = "would_file_bead"
        elif per_repo_filed[finding["repo"]] >= args.max_beads_per_repo:
            row["decision"] = "no_bead_reason"
            row["no_bead_reason"] = "daily_auto_bead_cap_exceeded"
        elif not (repo / ".beads").exists():
            row["decision"] = "no_bead_reason"
            row["no_bead_reason"] = "repo_has_no_beads_db"
        else:
            bead_id = create_bead(repo, finding)
            if bead_id:
                row["decision"] = "bead_filed_or_existing"
                row["bead_id"] = bead_id
                per_repo_filed[finding["repo"]] += 1
            else:
                row["decision"] = "no_bead_reason"
                row["no_bead_reason"] = "br_create_failed"
        decisions.append(row)
        if args.apply and not args.dry_run:
            ledger_rows.append(row)
    return decisions, ledger_rows


def schema() -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "state-md-miner result",
        "type": "object",
        "required": ["schema_version", "status", "findings_count", "findings", "decisions"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "status": {"enum": ["pass", "warn", "fail"]},
            "findings_count": {"type": "integer"},
            "findings": {"type": "array"},
            "decisions": {"type": "array"},
        },
    }


def run(args: argparse.Namespace) -> dict[str, Any]:
    now = now_utc(args.now)
    roster = Path(args.roster).expanduser()
    root = Path(args.root).expanduser()
    repos = load_roster(roster, root, args.repo)
    findings: list[dict[str, Any]] = []
    missing_state: list[str] = []
    for repo_row in repos:
        repo = Path(repo_row["repo"]).expanduser()
        before = len(findings)
        findings.extend(extract_items(repo_row, now, args.stale_days))
        if len(findings) == before and not any(path.exists() for path in state_paths(repo)):
            missing_state.append(str(repo))
    add_pattern_findings(findings)
    findings.sort(key=lambda row: (row["repo_name"], row["class"], row["state_path"], row["line"]))
    decisions, ledger_rows = decide(args, findings, now)
    counts = Counter(str(row["class"]) for row in findings)
    state_dir = Path(args.state_dir).expanduser()
    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": "warn" if findings else "pass",
        "mode": "apply" if args.apply and not args.dry_run else ("doctor" if args.doctor else "dry-run"),
        "generated_at": iso(now),
        "roster": str(roster),
        "repos_checked": len(repos),
        "state_files_missing_count": len(missing_state),
        "missing_state_repos": missing_state[:10],
        "findings_count": len(findings),
        "class_counts": dict(sorted(counts.items())),
        "findings": findings,
        "decisions": decisions,
        "audit_log": str(state_dir / "decisions.jsonl"),
        "latest_json": str(state_dir / "latest.json"),
    }
    if args.apply and not args.dry_run:
        append_jsonl(state_dir / "decisions.jsonl", ledger_rows)
        write_json(state_dir / "latest.json", payload)
    return payload


def doctor(args: argparse.Namespace) -> dict[str, Any]:
    args.dry_run = True
    args.apply = False
    payload = run(args)
    latest_path = Path(args.state_dir).expanduser() / "latest.json"
    latest = read_json(latest_path)
    last_run_age_hours = None
    if isinstance(latest, dict):
        ts = parse_ts(latest.get("generated_at"))
        if ts:
            last_run_age_hours = round((now_utc(args.now) - ts).total_seconds() / 3600, 2)
    warnings = []
    if last_run_age_hours is None:
        warnings.append({"code": "state_md_miner_never_applied", "message": "no applied STATE.md mine receipt found"})
    elif last_run_age_hours > 24:
        warnings.append({"code": "state_md_miner_stale", "message": f"last applied STATE.md mine age {last_run_age_hours}h exceeds 24h"})
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "warn" if payload["findings_count"] or warnings else "pass",
        "state_md_unmined_count": payload["findings_count"],
        "state_md_last_run_age_hours": last_run_age_hours,
        "state_md_class_counts": payload["class_counts"],
        "state_md_top_findings": payload["findings"][:5],
        "repos_checked": payload["repos_checked"],
        "warnings": warnings,
        "errors": [],
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Mine fleet STATE.md files for /flywheel:learn opportunities.")
    parser.add_argument("--repo", help="Mine a single repo instead of the fleet roster.")
    parser.add_argument("--root", default="/Users/josh/Developer")
    parser.add_argument("--roster", default=str(DEFAULT_ROSTER))
    parser.add_argument("--since", default="24h", help="Reserved for compatibility; STATE mining is current-state based.")
    parser.add_argument("--stale-days", type=int, default=14)
    parser.add_argument("--max-beads-per-repo", type=int, default=5)
    parser.add_argument("--state-dir", default=str(DEFAULT_STATE_DIR))
    parser.add_argument("--now", default=os.environ.get("FLYWHEEL_STATE_MD_MINER_NOW"))
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    args = parser.parse_args(argv)
    if args.apply:
        args.dry_run = False
    if args.schema:
        print(json.dumps(schema(), sort_keys=True, separators=(",", ":")))
        return 0
    if args.info:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "script": __file__, "default_roster": str(DEFAULT_ROSTER), "default_state_dir": str(DEFAULT_STATE_DIR)}, sort_keys=True, separators=(",", ":")))
        return 0
    if args.examples:
        print(".flywheel/scripts/state-md-miner.sh --json")
        print(".flywheel/scripts/state-md-miner.sh --repo /Users/josh/Developer/flywheel --dry-run --json")
        print(".flywheel/scripts/state-md-miner.sh --apply --max-beads-per-repo 5 --json")
        return 0
    if args.doctor:
        result = doctor(args)
    else:
        result = run(args)
    if args.json or args.doctor:
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    else:
        print(f"findings={result['findings_count']} status={result['status']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
