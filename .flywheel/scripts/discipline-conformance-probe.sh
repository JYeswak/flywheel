#!/usr/bin/env bash
set -euo pipefail

DISCIPLINE_CONFORMANCE_PROBE_SCRIPT_PATH="${BASH_SOURCE[0]}" python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "worker-discipline-conformance/v1"

DOCTRINES = [
    ("auto-push-blocked-worker-discipline", ".flywheel/doctrine/auto-push-blocked-worker-discipline.md"),
    ("codex-goal-mode-discipline", ".flywheel/doctrine/codex-goal-mode-discipline.md"),
    ("dry-run-apply-parity-contract", ".flywheel/doctrine/dry-run-apply-parity-contract.md"),
    ("dcg-worker-freeze-discipline", ".flywheel/doctrine/dcg-worker-freeze-discipline.md"),
    ("runtime-doctrine-separation-discipline", ".flywheel/doctrine/runtime-doctrine-separation-discipline.md"),
    ("repo-hygiene-tick-discipline", ".flywheel/doctrine/repo-hygiene-tick-discipline.md"),
]

ALTERNATE_DOCTRINE_PATHS = {
    "codex-goal-mode-discipline": [
        ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
    ],
}

MEMORY_PINS = [
    "feedback_goal_mode_is_codex_usage_limit_workaround",
    "feedback_codex_goal_mode_runtime_enforcement",
    "feedback_auto_push_blocked_worker_abandonment",
    "feedback_dry_run_apply_parity_contract",
]

DEFAULT_FLEET = {
    "flywheel": "/Users/josh/Developer/flywheel",
    "skillos": "/Users/josh/Developer/skillos",
    "mobile-eats": "/Users/josh/Developer/mobile-eats",
    "picoz": "/Users/josh/Developer/polymarket-pico-z",
    "clutterfreespaces": "/Users/josh/Developer/clutterfreespaces",
    "alpsinsurance": "/Users/josh/Developer/alpsinsurance",
    "vrtx": "/Users/josh/Developer/vrtx",
    "zesttube": "/Users/josh/Developer/zesttube",
}

DISPATCH_TEMPLATE_FILES = [
    ".flywheel/scripts/dispatch-template.md",
    ".flywheel/dispatch-template.md",
    "AGENTS.md",
    ".flywheel/AGENTS-CANONICAL.md",
]

TICK_CONTRACT_FILES = [
    ".flywheel/worker-tick.md",
    ".flywheel/WORKER-TICK.md",
    ".flywheel/WORK.md",
    ".flywheel/GOAL.md",
    ".flywheel/scripts/dispatch-template.md",
    "AGENTS.md",
    ".flywheel/AGENTS-CANONICAL.md",
]


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def load_fleet() -> dict[str, str]:
    raw = os.environ.get("WORKER_DISCIPLINE_FLEET_JSON", "")
    if raw:
        data = json.loads(raw)
        return {str(k): str(v) for k, v in data.items()}
    return DEFAULT_FLEET


def project_memory_path(repo: Path, orch: str) -> Path:
    local = repo / ".claude-memory/MEMORY.md"
    if local.exists() or local.parent.exists():
        return local

    explicit = os.environ.get("WORKER_DISCIPLINE_MEMORY_ROOT")
    if explicit:
        root = Path(explicit).expanduser()
        named = root / orch / "MEMORY.md"
        if named.exists() or named.parent.exists():
            return named
        escaped = str(repo).replace("/", "-")
        return root / escaped / "memory/MEMORY.md"

    escaped = str(repo).replace("/", "-")
    return Path.home() / ".claude/projects" / escaped / "memory/MEMORY.md"


def text_for_files(repo: Path, rels: list[str]) -> tuple[str, list[str]]:
    found = []
    combined = ""
    for rel in rels:
        path = repo / rel
        if path.exists() and path.is_file():
            found.append(rel)
            combined += "\n" + read_text(path)
    return combined, found


def doctrine_check(repo: Path) -> list[dict[str, Any]]:
    checks = []
    for doc_id, primary in DOCTRINES:
        candidates = [primary, *ALTERNATE_DOCTRINE_PATHS.get(doc_id, [])]
        present_path = None
        for rel in candidates:
            if (repo / rel).exists():
                present_path = rel
                break
        checks.append(
            {
                "id": doc_id,
                "status": "pass" if present_path else "fail",
                "path": present_path,
                "expected_path": primary,
            }
        )
    return checks


def memory_check(repo: Path, orch: str) -> dict[str, Any]:
    path = project_memory_path(repo, orch)
    text = read_text(path)
    pins = [{"pin": pin, "status": "pass" if pin in text else "fail"} for pin in MEMORY_PINS]
    return {"path": str(path), "exists": path.exists(), "pins": pins}


def activation_check(repo: Path) -> dict[str, Any]:
    text, files = text_for_files(repo, DISPATCH_TEMPLATE_FILES)
    low = text.lower()
    ok = ("codex-goal-activate" in low) or ("/goal" in text and ("codex" in low or "pane" in low))
    return {
        "id": "dispatch_template_activation_primitive",
        "status": "pass" if ok else "fail",
        "files_checked": files,
    }


def callback_check(repo: Path) -> dict[str, Any]:
    text, files = text_for_files(repo, TICK_CONTRACT_FILES)
    low = text.lower()
    ok = ("auto_push_status" in low) or ("auto-push status" in low) or ("auto_push" in low and "callback" in low)
    return {
        "id": "post_callback_auto_push_verification",
        "status": "pass" if ok else "fail",
        "files_checked": files,
    }


def score_repo(orch: str, repo: Path) -> dict[str, Any]:
    repo = repo.expanduser().resolve()
    doc_checks = doctrine_check(repo)
    memory = memory_check(repo, orch)
    activation = activation_check(repo)
    callback = callback_check(repo)

    atomic_checks: list[dict[str, Any]] = []
    atomic_checks.extend({"kind": "doctrine", **row} for row in doc_checks)
    atomic_checks.extend({"kind": "memory_pin", **row} for row in memory["pins"])
    atomic_checks.append({"kind": "dispatch_template", **activation})
    atomic_checks.append({"kind": "tick_contract", **callback})
    passed = sum(1 for row in atomic_checks if row["status"] == "pass")
    total = len(atomic_checks)
    score = passed / total if total else 0.0
    failures = [row for row in atomic_checks if row["status"] != "pass"]

    return {
        "orch": orch,
        "repo": str(repo),
        "repo_exists": repo.exists(),
        "score": round(score, 4),
        "passed": passed,
        "total": total,
        "status": "pass" if not failures else "fail",
        "doctrines": doc_checks,
        "memory": memory,
        "activation": activation,
        "post_callback_verification": callback,
        "failures": failures,
    }


def read_open_beads(repo: Path, br_bin: str) -> list[dict[str, Any]]:
    proc = run([br_bin, "list", "--json"], repo)
    if proc.returncode != 0 or not proc.stdout.strip():
        return []
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return []
    items = payload if isinstance(payload, list) else payload.get("issues", [])
    return [item for item in items if isinstance(item, dict) and item.get("status") not in {"closed", "done"}]


def bead_title(row: dict[str, Any], threshold: float) -> str:
    return f"worker-discipline-conformance: {row['orch']} score {row['score']:.2f} below {threshold:.2f}"


def bead_description(row: dict[str, Any], threshold: float) -> str:
    return (
        "Auto-filed by discipline-conformance-probe.\n\n"
        f"Threshold: {threshold:.2f}\n\n"
        "Conformance envelope:\n"
        "```json\n"
        f"{json.dumps(row, indent=2, sort_keys=True)}\n"
        "```"
    )


def bead_action(row: dict[str, Any], threshold: float, br_bin: str, dry_run: bool) -> dict[str, Any] | None:
    if row["score"] >= threshold:
        return None
    repo = Path(row["repo"])
    title = bead_title(row, threshold)
    for issue in read_open_beads(repo, br_bin):
        if issue.get("title") == title:
            return {"status": "duplicate_open", "title": title}
    if dry_run:
        return {"status": "dry_run", "title": title, "priority": "2"}
    proc = run(
        [
            br_bin,
            "create",
            title,
            "--type",
            "bug",
            "--priority",
            "2",
            "--description",
            bead_description(row, threshold),
            "--json",
        ],
        repo,
    )
    action = {"status": "created" if proc.returncode == 0 else "create_failed", "title": title, "priority": "2"}
    if proc.stdout.strip():
        action["stdout"] = proc.stdout.strip()
    if proc.stderr.strip():
        action["stderr"] = proc.stderr.strip()
    return action


def write_report(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Worker Discipline Propagation Readiness",
        "",
        f"Generated: `{payload['ts']}`",
        "",
        f"Fleet score: `{payload['fleet_score']:.4f}`",
        f"Threshold: `{payload['threshold']:.2f}`",
        f"Mode: `{'dry-run' if payload['dry_run'] else 'apply'}`",
        "",
        "| Orch | Score | Passed | Failed | Bead action |",
        "|---|---:|---:|---:|---|",
    ]
    for row in payload["repos"]:
        action = row.get("bead_action") or {}
        lines.append(
            f"| {row['orch']} | {row['score']:.4f} | {row['passed']} | {row['total'] - row['passed']} | {action.get('status', 'none')} |"
        )
    lines.extend(["", "## Failed Checks", ""])
    for row in payload["repos"]:
        if not row["failures"]:
            continue
        lines.append(f"### {row['orch']}")
        for failure in row["failures"]:
            label = failure.get("id") or failure.get("pin") or failure.get("kind")
            lines.append(f"- `{failure['kind']}` `{label}`")
        lines.append("")
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def repos_from_args(args: argparse.Namespace) -> dict[str, str]:
    fleet = load_fleet()
    selected: dict[str, str] = {}
    if args.fleet_default:
        selected.update(fleet)
    for item in args.repo:
        if "=" in item:
            name, path = item.split("=", 1)
            selected[name] = path
        else:
            path = str(Path(item).expanduser())
            selected[Path(path).name] = path
    if not selected:
        selected[Path.cwd().name] = str(Path.cwd())
    return selected


def main() -> int:
    parser = argparse.ArgumentParser(description="Probe worker-discipline conformance across repo fleet.")
    parser.add_argument("--fleet-default", action="store_true", help="Check the canonical 8-orch fleet.")
    parser.add_argument("--repo", action="append", default=[], help="Repo path or name=/path; repeatable.")
    parser.add_argument("--threshold", type=float, default=0.85, help="Score threshold for P2 bead action.")
    parser.add_argument("--auto-bead", action="store_true", help="Plan or create P2 beads for repos below threshold.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Report planned bead actions without mutation.")
    mode.add_argument("--apply", action="store_true", help="Create repo-local beads for below-threshold repos.")
    parser.add_argument("--br-bin", default="br", help="br executable used for auto-bead filing.")
    parser.add_argument("--report", help="Write a Markdown readiness report.")
    parser.add_argument("--json", action="store_true", help="Emit JSON.")
    args = parser.parse_args()

    dry_run = not args.apply
    rows = []
    for orch, path in repos_from_args(args).items():
        row = score_repo(orch, Path(path))
        if args.auto_bead:
            action = bead_action(row, args.threshold, args.br_bin, dry_run)
            if action:
                row["bead_action"] = action
        rows.append(row)

    total_passed = sum(row["passed"] for row in rows)
    total_checks = sum(row["total"] for row in rows)
    payload = {
        "schema_version": SCHEMA_VERSION,
        "ts": iso_now(),
        "dry_run": dry_run,
        "threshold": args.threshold,
        "fleet_score": round(total_passed / total_checks, 4) if total_checks else 0.0,
        "repos_checked": len(rows),
        "repos": rows,
    }
    if args.report:
        write_report(Path(args.report), payload)
        payload["report"] = args.report
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        for row in rows:
            print(f"{row['orch']}: score={row['score']:.4f} failures={len(row['failures'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
