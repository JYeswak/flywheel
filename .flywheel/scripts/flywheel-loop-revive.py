#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "flywheel-loop-revive/v1"


def parse_ts(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    text = value.strip()
    try:
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        parsed = datetime.fromisoformat(text)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except ValueError:
        return None


def iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return value if isinstance(value, dict) else {}


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def latest_boot_time(path: Path | None, raw: str | None) -> datetime | None:
    if raw:
        return parse_ts(raw)
    if path and path.exists():
        payload = read_json(path)
        for key in ("boot_time", "boot_ts", "last_boot_at", "ts"):
            parsed = parse_ts(payload.get(key))
            if parsed:
                return parsed
    return None


def state_ts(marker: dict[str, Any]) -> datetime | None:
    for key in ("last_driver_verified_at", "last_tick", "started_at", "updated_at"):
        parsed = parse_ts(marker.get(key))
        if parsed:
            return parsed
    return None


def marker_paths(loops_dir: Path) -> list[Path]:
    if not loops_dir.exists():
        return []
    return sorted(loops_dir.glob("*.json"))


def setup_candidates(marker: dict[str, Any], repo: Path | None) -> list[str]:
    paths: list[str] = []
    revive = marker.get("revive") if isinstance(marker.get("revive"), dict) else {}
    for key in ("session_setup_path", "ntm_setup_path", "setup_path"):
        value = marker.get(key) or revive.get(key)
        if isinstance(value, str) and value:
            paths.append(value)
    command = marker.get("session_setup_command") or marker.get("ntm_setup") or revive.get("session_setup_command")
    if isinstance(command, str) and command:
        paths.append(command)
    if repo:
        for rel in (".flywheel/ntm-setup.sh", ".flywheel/session-setup.sh", "ntm-setup.sh"):
            paths.append(str(repo / rel))
    return paths


def existing_setup(marker: dict[str, Any]) -> tuple[str | None, str | None]:
    repo_raw = marker.get("repo")
    repo = Path(repo_raw).expanduser() if isinstance(repo_raw, str) and repo_raw else None
    for candidate in setup_candidates(marker, repo):
        if candidate.startswith("/") or candidate.startswith("~"):
            path = Path(candidate).expanduser()
            if path.exists():
                return str(path), None
        elif candidate.startswith(".") and repo:
            path = (repo / candidate).expanduser()
            if path.exists():
                return str(path), None
        else:
            return None, candidate
    return None, None


def planned_start(marker: dict[str, Any]) -> str:
    tier = marker.get("tier") or "active_normal"
    interval = marker.get("interval")
    if interval:
        return f"/flywheel:loop start {interval} --tier {tier} --apply --json"
    return f"/flywheel:loop start --tier {tier} --apply --json"


def classify_marker(path: Path, marker: dict[str, Any], boot_time: datetime | None) -> dict[str, Any] | None:
    if marker.get("active") is not True:
        return None
    if marker.get("auto_revive_on_reboot") is not True:
        return None

    project = str(marker.get("project") or path.stem)
    repo = str(marker.get("repo") or "")
    setup_path, setup_command = existing_setup(marker)
    last_state = state_ts(marker)
    post_reboot = boot_time is None or last_state is None or last_state <= boot_time
    missing_datum = None
    if not repo:
        missing_datum = "repo"
    elif not setup_path and not setup_command:
        missing_datum = "session_setup_path"

    if missing_datum:
        action = "revive_blocked"
    elif not post_reboot:
        action = "already_post_reboot"
    else:
        action = "revive_candidate"

    return {
        "project": project,
        "repo": repo or None,
        "session": marker.get("session"),
        "state_path": str(path),
        "tier": marker.get("tier") or "active_normal",
        "interval": marker.get("interval") or "30m",
        "last_state_ts": iso(last_state) if last_state else None,
        "boot_time": iso(boot_time) if boot_time else None,
        "post_reboot_candidate": post_reboot,
        "setup_path": setup_path,
        "setup_command": setup_command,
        "action": action,
        "missing_datum": missing_datum,
        "planned_loop_start": planned_start(marker),
        "resulting_loop_state": {
            "active": marker.get("active") is True,
            "driver_verified": False,
            "state_marker_not_driver": True,
        },
    }


def select_candidates(candidates: list[dict[str, Any]], project: str | None, all_flag: bool) -> list[dict[str, Any]]:
    if project:
        return [row for row in candidates if row["project"] == project]
    if all_flag:
        return candidates
    return candidates


def launchd_pattern(script_path: Path) -> dict[str, Any]:
    home = str(Path.home())
    return {
        "label": "com.zeststream.flywheel-loop-revive",
        "keepalive": {"SuccessfulExit": False},
        "RunAtLoad": True,
        "StartInterval": 300,
        "ProgramArguments": [
            "/usr/bin/env",
            "python3",
            str(script_path),
            "--dry-run",
            "--json",
            "--write-receipt",
        ],
        "StandardOutPath": f"{home}/.local/state/flywheel/logs/flywheel-loop-revive.out.log",
        "StandardErrorPath": f"{home}/.local/state/flywheel/logs/flywheel-loop-revive.err.log",
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="flywheel-loop-revive")
    parser.add_argument("--loops-dir", default=os.environ.get("FLYWHEEL_LOOP_MARKER_DIR", "~/.flywheel/loops"))
    parser.add_argument("--receipt-dir", default=os.environ.get("FLYWHEEL_LOOP_REVIVE_RECEIPT_DIR", "~/.local/state/flywheel/loop-revive-receipts"))
    parser.add_argument("--boot-time", default=os.environ.get("FLYWHEEL_LOOP_REVIVE_BOOT_TIME"))
    parser.add_argument("--boot-state", default=os.environ.get("FLYWHEEL_LOOP_REVIVE_BOOT_STATE"))
    parser.add_argument("--project")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--simulate-rehydrate", action="store_true")
    parser.add_argument("--idempotency-key", default="")
    parser.add_argument("--write-receipt", action="store_true")
    parser.add_argument("--emit-launchd-pattern", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--now", default=os.environ.get("FLYWHEEL_LOOP_REVIVE_NOW"))
    args = parser.parse_args()

    if args.apply and not args.idempotency_key:
        payload = {
            "schema_version": SCHEMA_VERSION,
            "status": "refused",
            "reason": "idempotency_key_required",
            "guidance": "apply mode requires --idempotency-key",
        }
        print(json.dumps(payload, separators=(",", ":")) if args.json else payload["reason"])
        return 2

    now = parse_ts(args.now) or datetime.now(timezone.utc)
    loops_dir = Path(args.loops_dir).expanduser()
    receipt_dir = Path(args.receipt_dir).expanduser()
    boot_path = Path(args.boot_state).expanduser() if args.boot_state else None
    boot_time = latest_boot_time(boot_path, args.boot_time)

    candidates = []
    for path in marker_paths(loops_dir):
        marker = read_json(path)
        row = classify_marker(path, marker, boot_time)
        if row:
            candidates.append(row)
    selected = select_candidates(candidates, args.project, args.all)
    blocked = [row for row in selected if row["action"] == "revive_blocked"]
    revive_needed = [row for row in selected if row["action"] == "revive_candidate"]

    status = "dry_run" if not args.apply else "applied"
    applied_actions: list[dict[str, Any]] = []
    if args.apply:
        for row in revive_needed:
            applied_actions.append(
                {
                    "project": row["project"],
                    "rehydrate_mode": "simulated" if args.simulate_rehydrate else "planned_external",
                    "session_setup": row["setup_path"] or row["setup_command"],
                    "planned_loop_start": row["planned_loop_start"],
                    "resulting_loop_state": {
                        "active": True,
                        "driver_verified": False,
                        "revive_attempted_at": iso(now),
                        "state_marker_not_driver": True,
                    },
                }
            )

    notification = {
        "dry_run": True,
        "would_notify": bool(blocked),
        "reason": "revive_blocked" if blocked else "routine_successful_check_no_notify",
    }
    receipt_path = None
    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "dry_run": not args.apply,
        "mode": "apply" if args.apply else "dry_run",
        "ts": iso(now),
        "loops_dir": str(loops_dir),
        "boot_time": iso(boot_time) if boot_time else None,
        "state_marker_not_driver": True,
        "candidate_count": len(candidates),
        "selected_count": len(selected),
        "revive_needed_count": len(revive_needed),
        "blocked_count": len(blocked),
        "candidates": candidates,
        "selected": selected,
        "applied_actions": applied_actions,
        "notification": notification,
        "launchd_keepalive_pattern": launchd_pattern(Path(__file__).resolve()) if args.emit_launchd_pattern else None,
    }

    if args.write_receipt or args.apply:
        receipt_path = receipt_dir / f"flywheel-loop-revive-{now.strftime('%Y%m%dT%H%M%SZ')}.json"
        payload["receipt_path"] = str(receipt_path)
        write_json(receipt_path, payload)
    else:
        payload["receipt_path"] = None

    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print(f"revive status={payload['status']} candidates={len(candidates)} selected={len(selected)} blocked={len(blocked)}")
        for row in selected:
            print(f"{row['project']} action={row['action']} loop_start={row['planned_loop_start']}")
    return 1 if args.apply and blocked else 0


if __name__ == "__main__":
    raise SystemExit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
