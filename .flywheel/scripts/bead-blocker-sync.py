#!/usr/bin/env python3
"""Bridge Beads `blocked` rows into blocker-discipline JSON files.

The blocker-discipline substrate only rechecks files under
`.flywheel/state/blockers/`. A Beads row with `status=blocked` is otherwise just
queue text. This script makes every blocked Bead an executable blocker claim.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "flywheel.bead_blocker_sync.v1"
BLOCKER_SCHEMA_VERSION = "flywheel.bead_blocker.v1"


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def slug_for(bead_id: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "-", bead_id).strip("-")


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)


def load_blocked_beads(args: argparse.Namespace, root: Path) -> list[dict[str, Any]]:
    if args.input:
        raw = Path(args.input).read_text(encoding="utf-8")
    else:
        proc = run([args.br_bin, "list", "--status", "blocked", "--json"], root)
        if proc.returncode != 0:
            raise SystemExit(f"br list --status blocked failed: {proc.stderr.strip()}")
        raw = proc.stdout

    data = json.loads(raw)
    if isinstance(data, dict) and isinstance(data.get("issues"), list):
        return data["issues"]
    if isinstance(data, list):
        return data
    raise SystemExit("blocked bead input must be a JSON array or an object with issues[]")


def classify(issue: dict[str, Any]) -> tuple[str, str]:
    text = " ".join(
        str(issue.get(k, "")) for k in ("id", "title", "description", "notes", "labels")
    ).lower()
    if "trap-on-exit" in text or re.search(r"\brollback\b|\btrap\b", text):
        return (
            "rollback_trap_adoption",
            "Reduce the class with concrete child slices: add cleanup traps to one mutating surface at a time and prove the inventory count moves.",
        )
    if any(term in text for term in ("codex-skills-scan", "2000-dir", "truncation", "skills scan")):
        return (
            "scanner_scale_limit",
            "Replace fixed-depth or fixed-count scanning with bounded pagination/chunking and prove the full skill corpus is covered.",
        )
    if any(term in text for term in ("ntm-coordinator", "config-toml", "runtime-wiring")):
        return (
            "runtime_config_wiring",
            "Prove the runtime loads the intended config file in the deployed path, then lock the fixture so drift becomes a test failure.",
        )
    if re.search(r"\b(contact|form|provider)\b", text):
        return (
            "external_service_decision",
            "Either ship the owned local/provider-backed proof path or record an explicit keep-mailto-only disposition.",
        )
    if any(term in text for term in ("publish", "release", "b15", "cutover", "signoff")):
        return (
            "release_cutover",
            "Drive the release/cutover proof to a green publication-readiness receipt or update the bead with the exact remaining release fact.",
        )
    if any(term in text for term in ("[skillos-handoff]", "agent-ergonomics", "skill package")):
        return (
            "skillos_or_jsm_control_plane",
            "Coordinate with SkillOS and resolve the owning capability-pack or JSM package proof instead of parking the Flywheel bead.",
        )
    if any(term in text for term in ("nextra", "scaffold", "diátaxis", "diataxis")):
        return (
            "documentation_scaffold_wave",
            "Convert the scaffold wave into per-repo proof receipts or defer it behind an explicit release-boundary decision.",
        )
    if any(term in text for term in ("l68-refill", "refill-discipline", "leverage_ceiling", "capacity-buffer")):
        return (
            "capacity_refill_policy",
            "Collect the required leverage-ceiling evidence window before tuning refill behavior, or narrow the bead to a measurable policy slice.",
        )
    if any(term in text for term in ("ownership", "propagation", "canonical", "bootstrap registry", "identifier", "doctrine-sync", "zs-project-bootstrap", "fleet-bootstrap")):
        return (
            "ownership_or_registry_gate",
            "Add the missing ownership or registry artifact and prove the propagator is blocked only where ownership says it should be.",
        )
    if any(term in text for term in ("skillos", "jsm")):
        return (
            "skillos_or_jsm_control_plane",
            "Coordinate with SkillOS and resolve the owning capability-pack or JSM package proof instead of parking the Flywheel bead.",
        )
    if any(term in text for term in ("stash", "janitor")):
        return (
            "cross_repo_stash_or_worktree",
            "Run the non-destructive verifier, fix false positives, then get explicit approval before any destructive cleanup.",
        )
    if any(term in text for term in ("parent", "umbrella", "aggregate", "decomposed")):
        return (
            "decomposed_parent",
            "Close or reclassify child beads first; the parent can close only from child evidence, not from summary prose.",
        )
    if any(term in text for term in ("dependency", "blocked by", "depends on")):
        return (
            "dependency_gate",
            "Clear the dependency chain or replace the dependency with a direct executable proof that no longer needs it.",
        )
    return (
        "unclassified_blocker",
        "Triage into a named blocker class with a runnable acceptance condition; unclassified blockers should not stay unclassified.",
    )


def bead_status_ac(bead_id: str) -> str:
    quoted = json.dumps(bead_id)
    return (
        f"br show {bead_id} --json | "
        "jq -e 'if type == \"array\" then .[0] else . end | "
        f".id == {quoted} and .status != \"blocked\"'"
    )


def bead_still_blocked_probe(bead_id: str) -> str:
    quoted = json.dumps(bead_id)
    return (
        f"br show {bead_id} --json | "
        "jq -e 'if type == \"array\" then .[0] else . end | "
        f".id == {quoted} and .status == \"blocked\"'"
    )


def blocker_payload(issue: dict[str, Any], existing: dict[str, Any] | None = None) -> dict[str, Any]:
    bead_id = str(issue["id"])
    blocker_class, next_action = classify(issue)
    existing = existing or {}
    ts = now_iso()
    source_hash = hashlib.sha256(
        json.dumps(issue, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()

    return {
        "schema_version": BLOCKER_SCHEMA_VERSION,
        "blocker_id": bead_id,
        "status": existing.get("status", "open") if existing.get("status") == "closed" else "open",
        "source": "beads",
        "source_bead_id": bead_id,
        "source_repo": issue.get("source_repo") or "flywheel",
        "source_status": issue.get("status"),
        "title": issue.get("title", ""),
        "priority": issue.get("priority"),
        "issue_type": issue.get("issue_type"),
        "labels": issue.get("labels") or [],
        "dependency_count": issue.get("dependency_count", 0),
        "dependent_count": issue.get("dependent_count", 0),
        "blocker_class": blocker_class,
        "verification_path": bead_still_blocked_probe(bead_id),
        "acceptance_condition": bead_status_ac(bead_id),
        "ac_check_interval_ticks": int(existing.get("ac_check_interval_ticks") or 4),
        "last_verified_at": existing.get("last_verified_at") or ts,
        "next_action": next_action,
        "remediation_required": True,
        "foundational_rule": "A Beads status=blocked row must have an executable blocker-discipline file before it can be treated as stable state.",
        "source_row_sha256": source_hash,
        "synced_at": ts,
    }


def read_existing(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def sync(args: argparse.Namespace) -> int:
    root = Path(args.repo).resolve() if args.repo else repo_root()
    blockers_dir = Path(args.blockers_dir).resolve() if args.blockers_dir else root / ".flywheel/state/blockers"
    blocked = load_blocked_beads(args, root)
    planned: list[dict[str, Any]] = []
    applied: list[dict[str, Any]] = []

    for issue in blocked:
        bead_id = str(issue.get("id") or "")
        if not bead_id:
            continue
        path = blockers_dir / f"{slug_for(bead_id)}.json"
        existing = read_existing(path)
        payload = blocker_payload(issue, existing)
        changed = existing != payload
        row = {
            "bead_id": bead_id,
            "path": str(path),
            "blocker_class": payload["blocker_class"],
            "changed": changed,
            "status": "planned" if args.dry_run or not args.apply else "applied",
        }
        planned.append(row)
        if args.apply:
            write_json(path, payload)
            applied.append(row | {"status": "applied"})

    envelope = {
        "schema_version": SCHEMA_VERSION,
        "command": "sync",
        "status": "applied" if args.apply else "dry_run",
        "mode": "apply" if args.apply else "dry_run",
        "repo": str(root),
        "blockers_dir": str(blockers_dir),
        "blocked_bead_count": len(blocked),
        "planned_count": len(planned),
        "applied_count": len(applied),
        "idempotency_key": args.idempotency_key if args.apply else None,
        "planned": planned,
    }
    print(json.dumps(envelope, indent=2 if args.pretty else None, sort_keys=True))
    return 0


def doctor(args: argparse.Namespace) -> int:
    root = Path(args.repo).resolve() if args.repo else repo_root()
    blockers_dir = Path(args.blockers_dir).resolve() if args.blockers_dir else root / ".flywheel/state/blockers"
    blocked = load_blocked_beads(args, root)
    missing: list[str] = []
    malformed: list[str] = []
    present = 0
    for issue in blocked:
        bead_id = str(issue.get("id") or "")
        path = blockers_dir / f"{slug_for(bead_id)}.json"
        data = read_existing(path)
        if data is None:
            missing.append(bead_id)
            continue
        if not data.get("acceptance_condition") or not data.get("verification_path"):
            malformed.append(bead_id)
            continue
        present += 1
    status = "pass" if not missing and not malformed else "fail"
    envelope = {
        "schema_version": SCHEMA_VERSION,
        "command": "doctor",
        "status": status,
        "repo": str(root),
        "blockers_dir": str(blockers_dir),
        "blocked_bead_count": len(blocked),
        "synced_count": present,
        "missing_count": len(missing),
        "malformed_count": len(malformed),
        "missing_blocker_files": missing,
        "malformed_blocker_files": malformed,
    }
    print(json.dumps(envelope, indent=2 if args.pretty else None, sort_keys=True))
    return 0 if status == "pass" else 1


def validate(args: argparse.Namespace) -> int:
    path = Path(args.blocker_file)
    data = read_existing(path)
    failures = []
    if data is None:
        failures.append("invalid_json")
    else:
        for field in ("blocker_id", "source_bead_id", "verification_path", "acceptance_condition", "last_verified_at"):
            if not data.get(field):
                failures.append(f"{field}_missing")
        if data.get("schema_version") != BLOCKER_SCHEMA_VERSION:
            failures.append("schema_version_invalid")
    status = "pass" if not failures else "fail"
    print(
        json.dumps(
            {
                "schema_version": SCHEMA_VERSION,
                "command": "validate",
                "status": status,
                "blocker_file": str(path),
                "failures": failures,
            },
            sort_keys=True,
        )
    )
    return 0 if status == "pass" else 1


def emit_info() -> int:
    print(
        json.dumps(
            {
                "schema_version": SCHEMA_VERSION,
                "name": "bead-blocker-sync.py",
                "purpose": "sync br status=blocked rows into blocker-discipline JSON files",
                "mutation_default": "dry-run",
                "writes": [".flywheel/state/blockers/<bead-id>.json"],
                "modes": ["sync", "doctor", "validate"],
            },
            sort_keys=True,
        )
    )
    return 0


def main(argv: list[str]) -> int:
    if argv and argv[0] == "--info":
        return emit_info()
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command")

    def add_common(p: argparse.ArgumentParser) -> None:
        p.add_argument("--repo")
        p.add_argument("--blockers-dir")
        p.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
        p.add_argument("--input", help="fixture JSON from br list --status blocked --json")
        p.add_argument("--pretty", action="store_true")

    sync_p = sub.add_parser("sync")
    add_common(sync_p)
    sync_p.add_argument("--apply", action="store_true")
    sync_p.add_argument("--dry-run", action="store_true")
    sync_p.add_argument("--idempotency-key")

    doctor_p = sub.add_parser("doctor")
    add_common(doctor_p)

    validate_p = sub.add_parser("validate")
    validate_p.add_argument("--blocker-file", required=True)

    sub.add_parser("info")

    if not argv:
        argv = ["sync", "--dry-run"]
    args = parser.parse_args(argv)
    if args.command == "info":
        return emit_info()
    if args.command == "sync":
        if args.apply and not args.idempotency_key:
            print("--apply requires --idempotency-key", file=sys.stderr)
            return 2
        return sync(args)
    if args.command == "doctor":
        return doctor(args)
    if args.command == "validate":
        return validate(args)
    parser.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-53-idempotent-delivery-replay.md`
