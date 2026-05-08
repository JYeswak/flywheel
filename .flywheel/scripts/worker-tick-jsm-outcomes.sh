#!/usr/bin/env bash
# worker-tick-jsm-outcomes.sh - bridge Phase B worker receipts into jsm outcome

set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

SKILL_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")


def read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("receipt_not_object")
    return value


def compact(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, str):
        return [part.strip() for part in value.split(",") if part.strip()]
    return [value]


def receipt_paths(args: argparse.Namespace) -> list[Path]:
    paths: list[Path] = [Path(item).expanduser() for item in args.receipt]
    for root in args.receipt_dir:
        root_path = Path(root).expanduser()
        if root_path.is_file():
            paths.append(root_path)
        elif root_path.exists():
            paths.extend(sorted(root_path.rglob("last_tick.json")))
            paths.extend(sorted(path for path in root_path.rglob("*.json") if path.name != "last_tick.json"))
    seen: set[str] = set()
    unique: list[Path] = []
    for path in paths:
        key = str(path.resolve())
        if key not in seen:
            seen.add(key)
            unique.append(path)
    return unique


def phase_b_valid(receipt: dict[str, Any]) -> bool:
    return (
        receipt.get("schema_version") == "flywheel-worker-tick/v1"
        and receipt.get("mode") == "worker-mode"
        and receipt.get("harness") in {"claude", "codex", "gemini", "unknown"}
        and isinstance(receipt.get("check_results"), list)
    )


def skills_from_receipt(receipt: dict[str, Any]) -> list[str]:
    raw: list[Any] = []
    raw.extend(as_list(receipt.get("skills_used")))
    raw.extend(as_list(receipt.get("skills_consulted")))
    raw.extend(as_list(receipt.get("skill_consultations")))
    for row in receipt.get("check_results") or []:
        if not isinstance(row, dict):
            continue
        if row.get("id") != "skill-tool-call-presence":
            continue
        observed = row.get("observed") if isinstance(row.get("observed"), dict) else {}
        raw.extend(as_list(observed.get("skills_consulted")))
        raw.extend(as_list(observed.get("skill_consultations")))
    skills: list[str] = []
    for item in raw:
        skill = str(item).strip()
        if not skill or skill == "NONE_FOUND":
            continue
        if skill not in skills:
            skills.append(skill)
    return skills


def event_for(path: Path, receipt: dict[str, Any], skill: str) -> dict[str, Any]:
    success = receipt.get("status") in {"ok", "pass", "passed", True}
    context = {
        "schema_version": "worker-tick-jsm-context/v1",
        "source": "worker_tick",
        "harness": receipt.get("harness"),
        "session": receipt.get("session"),
        "pane": receipt.get("pane"),
        "task_id": receipt.get("task_id"),
        "bead": receipt.get("task_id"),
        "repo": receipt.get("repo"),
        "receipt_path": str(path),
        "worker_tick_status": receipt.get("status"),
        "violations": receipt.get("violations") or [],
    }
    return {
        "skill": skill,
        "success": bool(success),
        "harness": receipt.get("harness"),
        "task_id": receipt.get("task_id"),
        "receipt_path": str(path),
        "context": context,
    }


def command_for(jsm_bin: str, event: dict[str, Any], offline: bool) -> list[str]:
    cmd = [
        jsm_bin,
        "outcome",
        "-s",
        event["skill"],
        "--success" if event["success"] else "--failure",
        "--duration",
        "0",
        "--context",
        compact(event["context"]),
        "--json",
    ]
    if offline:
        cmd.append("--offline")
    return cmd


def drift_candidates(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_skill: dict[str, dict[str, set[bool]]] = {}
    for event in events:
        harness = str(event.get("harness") or "unknown")
        by_skill.setdefault(event["skill"], {}).setdefault(harness, set()).add(bool(event["success"]))
    candidates: list[dict[str, Any]] = []
    for skill, by_harness in sorted(by_skill.items()):
        success_harnesses = sorted(h for h, outcomes in by_harness.items() if True in outcomes)
        failure_harnesses = sorted(h for h, outcomes in by_harness.items() if False in outcomes)
        if success_harnesses and failure_harnesses and set(success_harnesses) != set(failure_harnesses):
            candidates.append(
                {
                    "skill": skill,
                    "class": "harness_partitioned_drift_candidate",
                    "success_harnesses": success_harnesses,
                    "failure_harnesses": failure_harnesses,
                    "by_harness": {h: sorted(outcomes) for h, outcomes in sorted(by_harness.items())},
                }
            )
    return candidates


parser = argparse.ArgumentParser(description="Bridge worker tick receipts into jsm outcome events")
parser.add_argument("--receipt", action="append", default=[], help="Worker tick receipt path")
parser.add_argument("--receipt-dir", action="append", default=[], help="Directory to replay worker tick receipts from")
parser.add_argument("--jsm-bin", default="jsm")
parser.add_argument("--apply", action="store_true")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--online", action="store_true", help="Do not pass --offline to jsm")
parser.add_argument("--json", action="store_true")
args = parser.parse_args()

if not args.receipt and not args.receipt_dir:
    parser.error("at least one --receipt or --receipt-dir is required")

mode = "apply" if args.apply else "dry-run"
paths = receipt_paths(args)
events: list[dict[str, Any]] = []
validation_errors: list[dict[str, Any]] = []
phase_b_validated = 0

for path in paths:
    try:
        receipt = read_json(path)
    except Exception as exc:
        validation_errors.append({"receipt_path": str(path), "reason": "receipt_unreadable", "detail": str(exc)})
        continue
    if not phase_b_valid(receipt):
        validation_errors.append({"receipt_path": str(path), "reason": "phase_b_receipt_invalid"})
        continue
    phase_b_validated += 1
    for skill in skills_from_receipt(receipt):
        if not SKILL_RE.match(skill):
            validation_errors.append({"receipt_path": str(path), "reason": "invalid_skill_name", "skill": skill})
            continue
        events.append(event_for(path, receipt, skill))

commands = [command_for(args.jsm_bin, event, offline=not args.online) for event in events]
applied: list[dict[str, Any]] = []

if args.apply:
    for event, cmd in zip(events, commands):
        proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        applied.append(
            {
                "skill": event["skill"],
                "harness": event["harness"],
                "success": event["success"],
                "exit_code": proc.returncode,
                "stdout": proc.stdout.strip(),
                "stderr": proc.stderr.strip(),
            }
        )

receipt = {
    "schema_version": "worker-tick-jsm-outcomes/v1",
    "mode": mode,
    "jsm_schema_probe": {
        "command": "jsm outcome --help",
        "captured_before_implementation": True,
        "uses_context_for_harness": True,
    },
    "receipts_seen": len(paths),
    "phase_b_receipts_validated": phase_b_validated,
    "events_count": len(events),
    "planned_events": events,
    "planned_commands": commands,
    "validation_errors": validation_errors,
    "harness_drift_candidates": drift_candidates(events),
    "applied_count": len(applied),
    "applied": applied,
}

if args.json:
    print(json.dumps(receipt, sort_keys=True))
else:
    print(f"worker-tick-jsm-outcomes mode={mode} receipts={len(paths)} events={len(events)} validation_errors={len(validation_errors)}")

if any(item.get("exit_code", 0) != 0 for item in applied):
    sys.exit(1)
PY
