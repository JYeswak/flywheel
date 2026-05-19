#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

python3 - "$ROOT" "$@" <<'PY'
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(sys.argv[1])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Signal repo-owning orchestrators when peer repos have ready beads."
    )
    parser.add_argument("command", nargs="?")
    parser.add_argument("--local-repo", default=str(ROOT))
    parser.add_argument("--local-session", default="flywheel")
    parser.add_argument("--fleet-config", default="")
    parser.add_argument("--ledger", default="")
    parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
    parser.add_argument("--source-probe", default="fleet-refill-signal/v1")
    parser.add_argument("--now", default="")
    parser.add_argument("--local-idle-capacity", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--json", action="store_true")
    return parser.parse_args(sys.argv[2:])


def check_row(name: str, status: str, detail: str) -> dict:
    return {"name": name, "status": status, "detail": detail}


def aggregate_status(checks: list[dict]) -> str:
    statuses = {str(check.get("status", "")) for check in checks}
    if "fail" in statuses:
        return "fail"
    if "warn" in statuses:
        return "warn"
    return "pass"


def iso_now(explicit: str = "") -> str:
    if explicit:
        return explicit
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: str, default):
    if not path:
        return default
    p = Path(path)
    if not p.is_file():
        return default
    try:
        return json.loads(p.read_text())
    except Exception:
        return default


def read_jsonl(path: Path) -> list[dict]:
    rows = []
    if not path.is_file():
        return rows
    for line in path.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def repo_realpath(path: str) -> str:
    try:
        return str(Path(path).expanduser().resolve())
    except Exception:
        return str(Path(path).expanduser())


def normalize_config_payload(payload) -> list[dict]:
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if not isinstance(payload, dict):
        return []
    for key in ("repos", "sessions", "rows", "fleet"):
        value = payload.get(key)
        if isinstance(value, list):
            return [x for x in value if isinstance(x, dict)]
    return []


def default_fleet_rows(local_repo: str, local_session: str) -> list[dict]:
    topology = Path.home() / ".local/state/flywheel/session-topology.jsonl"
    rows = []
    for row in read_jsonl(topology):
        repo = row.get("repo_path") or row.get("repo") or row.get("repo_root")
        session = row.get("session") or row.get("name")
        if not repo or not session:
            continue
        rows.append(
            {
                "repo": repo,
                "session": session,
                "opted_in": row.get("opted_in", True),
            }
        )
    if not rows:
        rows.append({"repo": local_repo, "session": local_session, "opted_in": True})
    return rows


def fleet_rows(args: argparse.Namespace) -> list[dict]:
    if args.fleet_config:
        payload = read_json(args.fleet_config, [])
        rows = normalize_config_payload(payload)
    else:
        rows = default_fleet_rows(args.local_repo, args.local_session)
    normalized = []
    seen = set()
    for row in rows:
        if row.get("opted_in") is False:
            continue
        repo = row.get("repo") or row.get("repo_path") or row.get("path")
        session = row.get("session") or row.get("target_session") or row.get("name")
        if not repo or not session:
            continue
        real = repo_realpath(str(repo))
        key = (real, str(session))
        if key in seen:
            continue
        seen.add(key)
        normalized.append(
            {
                "repo": real,
                "session": str(session),
                "ready_file": str(row.get("ready_file") or ""),
            }
        )
    return normalized


def run_br_ready(repo: str, br_bin: str):
    try:
        out = subprocess.check_output(
            [br_bin, "ready", "--json"],
            cwd=repo,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=15,
        )
        return json.loads(out)
    except Exception:
        return {"issues": []}


def ready_payload(row: dict, br_bin: str):
    if row.get("ready_file"):
        return read_json(row["ready_file"], {"issues": []})
    return run_br_ready(row["repo"], br_bin)


def ready_items(payload) -> list[dict]:
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if not isinstance(payload, dict):
        return []
    for key in ("issues", "items", "ready", "beads", "rows"):
        value = payload.get(key)
        if isinstance(value, list):
            return [x for x in value if isinstance(x, dict)]
    return []


def is_ready(item: dict) -> bool:
    status = str(item.get("status", "open")).lower()
    return status in {"open", "ready", "todo", "new"}


def priority(item: dict) -> int:
    try:
        return int(item.get("priority", 99))
    except Exception:
        return 99


def bead_id(item: dict) -> str:
    return str(item.get("id") or item.get("bead_id") or item.get("task_id") or "")


def summarize_ready(payload) -> dict:
    items = [x for x in ready_items(payload) if is_ready(x) and bead_id(x)]
    items.sort(key=lambda x: (priority(x), bead_id(x)))
    p0_p1 = [bead_id(x) for x in items if priority(x) <= 1]
    return {
        "ready_count": len(items),
        "top_bead_id": bead_id(items[0]) if items else None,
        "top_p0_p1_bead_ids": p0_p1[:5],
    }


def append_atomic(path: Path, row: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n"
    existing = path.read_text() if path.exists() else ""
    fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w") as handle:
        handle.write(existing)
        handle.write(payload)
    os.replace(tmp_name, path)


def build_doctor(args: argparse.Namespace) -> dict:
    local_repo = Path(args.local_repo).expanduser()
    ledger = Path(args.ledger).expanduser() if args.ledger else Path.home() / ".local/state/flywheel/cross-orch-coordination.jsonl"
    checks = []

    checks.append(
        check_row(
            "local_repo_readable",
            "pass" if local_repo.is_dir() else "fail",
            str(local_repo),
        )
    )
    checks.append(
        check_row(
            "br_binary_available",
            "pass" if shutil.which(args.br_bin) else "warn",
            args.br_bin,
        )
    )

    if args.fleet_config:
        config = Path(args.fleet_config).expanduser()
        payload = read_json(str(config), None)
        if payload is None:
            checks.append(check_row("fleet_config_readable", "fail", str(config)))
            row_count = 0
        else:
            row_count = len(normalize_config_payload(payload))
            checks.append(check_row("fleet_config_readable", "pass", f"{config} rows={row_count}"))
    else:
        topology = Path.home() / ".local/state/flywheel/session-topology.jsonl"
        row_count = len(default_fleet_rows(str(local_repo), args.local_session))
        checks.append(
            check_row(
                "default_topology_available",
                "pass" if topology.is_file() or row_count > 0 else "warn",
                f"{topology} rows={row_count}",
            )
        )

    checks.append(
        check_row(
            "fleet_rows_available",
            "pass" if row_count > 0 else "warn",
            f"rows={row_count}",
        )
    )

    parent = ledger.parent
    checks.append(
        check_row(
            "ledger_parent_available",
            "pass" if parent.is_dir() else "warn",
            str(parent),
        )
    )
    checks.append(
        check_row(
            "doctor_read_only",
            "pass",
            "doctor builds no signal rows and never appends the coordination ledger",
        )
    )
    checks.append(
        check_row(
            "unsafe_peer_dispatch_absent",
            "pass",
            "this helper writes coordination rows only; Flywheel-owned orchestration is allowed through explicit transport-gated surfaces",
        )
    )

    return {
        "schema_version": "fleet-refill-signal.doctor.v1",
        "command": "doctor",
        "status": aggregate_status(checks),
        "mode": "read_only",
        "mutates": False,
        "local_repo": repo_realpath(args.local_repo),
        "local_session": args.local_session,
        "cross_repo_orchestration_policy": "flywheel_may_orchestrate_fleet_doctrine_through_explicit_transport_gates",
        "ledger": str(ledger),
        "checks": checks,
    }


def build_result(args: argparse.Namespace) -> dict:
    local_repo = repo_realpath(args.local_repo)
    ledger = Path(args.ledger) if args.ledger else Path.home() / ".local/state/flywheel/cross-orch-coordination.jsonl"
    rows = fleet_rows(args)
    scanned = []
    local_summary = None
    peer_candidates = []

    for row in rows:
        summary = summarize_ready(ready_payload(row, args.br_bin))
        scan_row = {
            "target_repo": row["repo"],
            "target_session": row["session"],
            "ready_count": summary["ready_count"],
            "top_bead_id": summary["top_bead_id"],
            "top_p0_p1_bead_ids": summary["top_p0_p1_bead_ids"],
        }
        scanned.append(scan_row)
        is_local = row["repo"] == local_repo or row["session"] == args.local_session
        if is_local:
            if local_summary is None or scan_row["ready_count"] > local_summary["ready_count"]:
                local_summary = scan_row
        elif scan_row["ready_count"] > 0 and scan_row["top_bead_id"]:
            peer_candidates.append(scan_row)

    local_ready_count = local_summary["ready_count"] if local_summary else 0
    peer_candidates.sort(key=lambda x: (-len(x["top_p0_p1_bead_ids"]), -x["ready_count"], x["target_session"]))
    row = None
    decision = "no_signal"
    reason = "no_peer_ready_work"

    if not args.local_idle_capacity:
        reason = "no_local_idle_capacity"
    elif local_ready_count > 0:
        decision = "local_ready_dispatch_remains_local"
        reason = "local_ready_work_exists"
    elif peer_candidates:
        target = peer_candidates[0]
        decision = "peer_ready_signal_only"
        reason = "local_idle_peer_ready"
        row = {
            "schema_version": "flywheel.fleet_refill_signal.v1",
            "event": "fleet_refill_peer_ready_signal",
            "ts": iso_now(args.now),
            "source_session": args.local_session,
            "source_repo": local_repo,
            "target_repo": target["target_repo"],
            "target_session": target["target_session"],
            "top_bead_id": target["top_bead_id"],
            "top_p0_p1_bead_ids": target["top_p0_p1_bead_ids"],
            "ready_count": target["ready_count"],
            "source_probe": args.source_probe,
            "transport": "cross_orch_coordination_ledger",
            "orchestration_boundary": "signal_only_helper_not_global_flywheel_prohibition",
            "direct_dispatch": False,
            "raw_tokens_included": False,
        }

    ledger_written = False
    if args.apply and row is not None:
        append_atomic(ledger, row)
        ledger_written = True

    return {
        "schema_version": "flywheel.fleet_refill_signal_result.v1",
        "status": "pass",
        "ts": iso_now(args.now),
        "decision": decision,
        "reason": reason,
        "local_repo": local_repo,
        "local_session": args.local_session,
        "cross_repo_orchestration_policy": "flywheel_may_orchestrate_fleet_doctrine_through_explicit_transport_gates",
        "local_idle_capacity": args.local_idle_capacity,
        "local_ready_count": local_ready_count,
        "scanned_repo_count": len(scanned),
        "scanned_repos": scanned,
        "candidate_signal": row,
        "ledger": str(ledger),
        "ledger_written": ledger_written,
        "direct_dispatch_attempted": False,
    }


def main() -> int:
    args = parse_args()
    if args.command == "doctor" or args.doctor:
        result = build_doctor(args)
        if args.json:
            print(json.dumps(result, sort_keys=True, separators=(",", ":")))
        else:
            print(f"doctor status={result['status']} checks={len(result['checks'])}")
        return 0 if result["status"] in {"pass", "warn"} else 1
    if args.command:
        print(f"Unknown command: {args.command}", file=sys.stderr)
        return 2
    result = build_result(args)
    if args.json:
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    else:
        print(f"{result['decision']} reason={result['reason']} ledger_written={result['ledger_written']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
