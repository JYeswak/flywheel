#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "orch-worker-identity/v1"
DEFAULT_LOOP_DIR = Path.home() / ".flywheel/loops"
DEFAULT_TOPOLOGY = Path.home() / ".local/state/flywheel/session-topology.jsonl"
DEFAULT_AGENT_MAIL = Path.home() / ".local/state/flywheel/agent-mail"
DEFAULT_OUT_DIR = Path.home() / ".local/state/flywheel/orch-worker-identity"


def iso_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def parse_ts(value):
    if not value:
        return datetime.min.replace(tzinfo=timezone.utc)
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return datetime.min.replace(tzinfo=timezone.utc)


def latest_topology_rows(path):
    rows = {}
    line_numbers = {}
    if not path.exists():
        return rows, line_numbers
    for idx, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        session = row.get("session")
        if not session:
            continue
        current = rows.get(session)
        if current is None or parse_ts(row.get("effective_at")) >= parse_ts(current.get("effective_at")):
            rows[session] = row
            line_numbers[session] = idx
    return rows, line_numbers


def live_sessions(loop_dir):
    sessions = []
    if not loop_dir.exists():
        return sessions
    for path in sorted(loop_dir.glob("*.json")):
        if ".bak" in path.name:
            continue
        payload = read_json(path)
        if not isinstance(payload, dict):
            continue
        session = payload.get("session") or payload.get("project") or path.stem
        if payload.get("active") is True:
            sessions.append(str(session))
    return sessions


def registry_row(agent_mail_dir, session, pane):
    path = agent_mail_dir / "sessions" / f"{session}:{int(pane)}.json"
    payload = read_json(path)
    if isinstance(payload, dict):
        payload["_path"] = str(path)
        return payload
    return None


def identity_status(row):
    if not row:
        return "missing"
    status = row.get("status") or "missing"
    token_path = row.get("token_path")
    if status == "active" and token_path:
        return "active" if Path(token_path).expanduser().exists() else "stale"
    if status == "needs_registration":
        return "needs_registration"
    if status == "active":
        return "stale"
    return status if status in {"stale", "missing"} else "stale"


def as_int_list(value):
    if not isinstance(value, list):
        return []
    out = []
    for item in value:
        try:
            out.append(int(item))
        except Exception:
            continue
    return out


def topology_workers(row):
    for key in ("worker_panes", "workers"):
        workers = as_int_list(row.get(key))
        if workers:
            return workers
    return []


def build_manifest(session, row, line_no, agent_mail_dir, generated_at):
    if not isinstance(row, dict):
        return {
            "schema_version": SCHEMA_VERSION,
            "session": session,
            "generated_at": generated_at,
            "orchestrator": {
                "pane": None,
                "agent_kind": "unknown",
                "fleet_mail_identity": "unrecorded",
            },
            "workers": [],
            "validation": {
                "all_workers_registered": False,
                "unregistered_count": 0,
                "topology_source_line": None,
                "topology_status": "missing",
            },
        }

    orch_pane = row.get("orchestrator_pane")
    if orch_pane is None:
        orch_pane = row.get("callback_pane")
    worker_panes = topology_workers(row)
    worker_model = row.get("worker_model") or row.get("model")
    worker_effort = row.get("worker_effort") or row.get("effort")

    workers = []
    for pane in worker_panes:
        reg = registry_row(agent_mail_dir, session, pane)
        status = identity_status(reg)
        workers.append({
            "pane": pane,
            "agent_kind": row.get("worker_agent_kind") or row.get("agent_kind") or "unknown",
            "model": worker_model,
            "effort": worker_effort,
            "fleet_mail_identity": (reg or {}).get("identity_name") or "unregistered",
            "fleet_mail_token_path": (reg or {}).get("token_path"),
            "registered_at": (reg or {}).get("registered_ts"),
            "registration_status": status,
            "registry_source": (reg or {}).get("_path"),
        })

    unregistered = sum(1 for worker in workers if worker["registration_status"] != "active")
    return {
        "schema_version": SCHEMA_VERSION,
        "session": session,
        "generated_at": generated_at,
        "orchestrator": {
            "pane": orch_pane,
            "agent_kind": row.get("agent_kind") or "unknown",
            "fleet_mail_identity": row.get("fleet_mail_identity") or "unrecorded",
        },
        "workers": workers,
        "validation": {
            "all_workers_registered": unregistered == 0,
            "unregistered_count": unregistered,
            "topology_source_line": line_no,
            "topology_status": "found",
        },
    }


def write_json_atomic(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, sort_keys=True, separators=(",", ":"))
        handle.write("\n")
    os.replace(tmp_name, path)


def schema():
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "Flywheel orch-worker identity manifest",
        "type": "object",
        "required": ["schema_version", "session", "generated_at", "orchestrator", "workers", "validation"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "session": {"type": "string"},
            "generated_at": {"type": "string"},
            "orchestrator": {
                "type": "object",
                "required": ["pane", "agent_kind", "fleet_mail_identity"],
            },
            "workers": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": [
                        "pane",
                        "agent_kind",
                        "model",
                        "effort",
                        "fleet_mail_identity",
                        "fleet_mail_token_path",
                        "registered_at",
                        "registration_status",
                    ],
                },
            },
            "validation": {
                "type": "object",
                "required": ["all_workers_registered", "unregistered_count", "topology_source_line"],
            },
        },
    }


def print_payload(payload, as_json):
    if as_json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        if isinstance(payload, dict) and "summary" in payload:
            print(payload["summary"])
        else:
            print(json.dumps(payload, indent=2, sort_keys=True))


def main(argv):
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--fleet", action="store_true")
    parser.add_argument("--session")
    parser.add_argument("--loop-dir", default=os.environ.get("FLYWHEEL_LOOP_DIR", str(DEFAULT_LOOP_DIR)))
    parser.add_argument("--topology", default=os.environ.get("FLYWHEEL_SESSION_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    parser.add_argument("--agent-mail-dir", default=os.environ.get("FLYWHEEL_AGENT_MAIL_STATE_DIR", str(DEFAULT_AGENT_MAIL)))
    parser.add_argument("--out-dir", default=os.environ.get("FLYWHEEL_ORCH_WORKER_IDENTITY_DIR", str(DEFAULT_OUT_DIR)))
    args = parser.parse_args(argv)

    if args.info:
        print_payload({
            "schema_version": "canonical-cli-info/v1",
            "name": "orch-worker-identity-manifest",
            "summary": "Builds derived per-orchestrator worker identity manifests from live loop markers, session topology, and Agent Mail identity rows.",
            "dry_run_supported": True,
            "apply_supported": True,
            "idempotency_key": "session",
            "no_raw_tokens": True,
        }, args.json)
        return 0

    if args.examples:
        print_payload({
            "examples": [
                ".flywheel/scripts/orch-worker-identity-manifest.sh --fleet --dry-run --json",
                ".flywheel/scripts/orch-worker-identity-manifest.sh --session flywheel --apply --json",
                "jq '.workers[] | select(.pane == 2)' ~/.local/state/flywheel/orch-worker-identity/flywheel.json",
            ],
        }, args.json)
        return 0

    if args.schema:
        print_payload(schema(), True)
        return 0

    if args.apply and args.dry_run:
        raise SystemExit("--apply and --dry-run are mutually exclusive")
    if not args.apply and not args.dry_run:
        args.dry_run = True

    topology_path = Path(args.topology).expanduser()
    agent_mail_dir = Path(args.agent_mail_dir).expanduser()
    out_dir = Path(args.out_dir).expanduser()
    topology, line_numbers = latest_topology_rows(topology_path)

    sessions = []
    if args.fleet:
        sessions.extend(live_sessions(Path(args.loop_dir).expanduser()))
    if args.session:
        sessions.append(args.session)
    if not sessions:
        sessions = [Path.cwd().name]
    sessions = sorted(dict.fromkeys(sessions))

    generated_at = iso_now()
    manifests = []
    written = []
    for session in sessions:
        manifest = build_manifest(session, topology.get(session), line_numbers.get(session), agent_mail_dir, generated_at)
        target = out_dir / f"{session}.json"
        if args.apply:
            write_json_atomic(target, manifest)
            written.append(str(target))
        manifests.append({"path": str(target), "manifest": manifest})

    summary = {
        "schema_version": "orch-worker-identity-manifest-run/v1",
        "generated_at": generated_at,
        "mode": "apply" if args.apply else "dry-run",
        "sessions_requested": sessions,
        "manifests_written": len(written),
        "manifest_paths": [entry["path"] for entry in manifests],
        "sessions": {
            entry["manifest"]["session"]: {
                "workers": len(entry["manifest"]["workers"]),
                "registered": sum(1 for worker in entry["manifest"]["workers"] if worker["registration_status"] == "active"),
                "unregistered_count": entry["manifest"]["validation"]["unregistered_count"],
                "all_workers_registered": entry["manifest"]["validation"]["all_workers_registered"],
            }
            for entry in manifests
        },
        "manifests": manifests,
    }
    print_payload(summary, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
