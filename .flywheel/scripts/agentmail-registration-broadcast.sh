#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "agentmail-registration-broadcast/v1"
DEFAULT_STATE = Path.home() / ".local/state/flywheel/agent-mail"
DEFAULT_COORD = Path.home() / ".local/state/flywheel/cross-orch-coordination.jsonl"
DEFAULT_DEFERRALS = Path.home() / ".local/state/flywheel/identity-overrides"


def parse_ts(value):
    if not value:
        return None
    text = str(value).replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return None


def now_utc(override=None):
    parsed = parse_ts(override)
    return parsed or datetime.now(timezone.utc)


def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def iter_session_rows(session_dir):
    if not session_dir.exists():
        return []
    rows = []
    for path in sorted(session_dir.glob("*.json")):
        data = read_json(path)
        if isinstance(data, dict):
            data["_path"] = str(path)
            rows.append(data)
    return rows


def iter_deferrals(deferral_dir, now):
    if not deferral_dir.exists():
        return []
    rows = []
    for path in sorted(deferral_dir.glob("*.json")):
        payload = read_json(path)
        if not isinstance(payload, dict):
            continue
        if payload.get("schema_version") != "identity-registration-deferral/v1":
            continue
        expires = parse_ts(payload.get("expires_at"))
        if expires and expires < now:
            continue
        for row in payload.get("deferred_rows") or []:
            if isinstance(row, dict):
                merged = dict(row)
                merged["_receipt_path"] = str(path)
                merged["_expires_at"] = payload.get("expires_at")
                rows.append(merged)
    return rows


def deferral_for(row, deferrals):
    session = row.get("session")
    pane = int(row.get("pane", -1))
    for item in deferrals:
        if item.get("session") == session and int(item.get("pane", -1)) == pane:
            return item
    return None


def probe_live(ntm, session, pane):
    try:
        proc = subprocess.run(
            [ntm, "health", str(session), "--json"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=8,
            check=False,
        )
    except Exception as exc:
        return {"live": False, "reason": "ntm_probe_error", "detail": str(exc)}
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        if proc.returncode != 0:
            return {"live": False, "reason": "session_not_running"}
        return {"live": False, "reason": "ntm_health_invalid_json"}
    agents = payload.get("agents")
    if not isinstance(agents, list):
        return {"live": True, "reason": "session_live_no_agent_rows"}
    for agent in agents:
        if int(agent.get("pane", -1)) != int(pane):
            continue
        process_status = agent.get("process_status")
        status = agent.get("status")
        if process_status == "running" and status in {"ok", "warn", "unknown"}:
            return {"live": True, "reason": "pane_running"}
        return {"live": False, "reason": f"pane_not_running:{status}:{process_status}"}
    return {"live": False, "reason": "pane_missing"}


def row_key(row):
    return f"{row.get('session')}:{int(row.get('pane', -1))}"


def sent_recently(coord_log, row, now, window_seconds):
    if not coord_log.exists():
        return None
    key = row_key(row)
    cutoff = now.timestamp() - window_seconds
    latest = None
    for line in coord_log.read_text(encoding="utf-8", errors="ignore").splitlines():
        if not line.strip():
            continue
        try:
            event = json.loads(line)
        except Exception:
            continue
        if event.get("event") != "agentmail_registration_broadcast_sent":
            continue
        if event.get("row_key") != key:
            continue
        ts = parse_ts(event.get("ts"))
        if ts and ts.timestamp() >= cutoff:
            latest = event
    return latest


def request_body(row):
    session = row.get("session")
    pane = int(row.get("pane", -1))
    project = row.get("fleet_mail_project_key")
    return "\n".join([
        f"AGENTMAIL_IDENTITY_REGISTRATION_REQUEST bead_id=flywheel-2uin session={session} pane={pane} identity_resolved=pending no_raw_tokens=true",
        "",
        f"{session}:{pane} is live and currently registered in the flywheel Agent Mail identity registry as status=needs_registration.",
        "",
        "Please choose/register this orchestrator's fleet-mail-project identity through the durable resolver, then persist the token only to the canonical token vault:",
        f"- registry_row={row.get('_path')}",
        f"- project={project}",
        "- token_path=/Users/josh/.local/state/flywheel/agent-mail/tokens/<IdentityName>.token",
        "",
        "Use resolver-mediated registration, not ad-hoc Agent Mail identity sprawl. Cross-orch handshakes should carry identity_resolved=<identity_name> and token_path, never the raw token.",
        "",
    ])


def send_request(args, row, now):
    request_dir = Path(args.request_dir)
    request_dir.mkdir(parents=True, exist_ok=True)
    key = row_key(row).replace(":", "-")
    fd, path_text = tempfile.mkstemp(prefix=f"agentmail-registration-{key}-", suffix=".txt", dir=request_dir)
    path = Path(path_text)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(request_body(row))
    subprocess.run(
        [args.ntm, "send", str(row.get("session")), f"--pane={int(row.get('pane', -1))}", "--file", str(path), "--no-cass-check"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=10,
    )
    return path


def append_event(coord_log, payload):
    coord_log.parent.mkdir(parents=True, exist_ok=True)
    with coord_log.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", default=str(DEFAULT_STATE))
    parser.add_argument("--session-dir")
    parser.add_argument("--deferral-dir", default=str(DEFAULT_DEFERRALS))
    parser.add_argument("--coordination-log", default=str(DEFAULT_COORD))
    parser.add_argument("--request-dir", default="/tmp")
    parser.add_argument("--ntm", default=os.environ.get("NTM_BIN", "/Users/josh/.local/bin/ntm"))
    parser.add_argument("--window-seconds", type=int, default=3600)
    parser.add_argument("--now")
    parser.add_argument("--session")
    parser.add_argument("--pane", type=int)
    parser.add_argument("--no-raw-tokens", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    state_dir = Path(args.state_dir)
    session_dir = Path(args.session_dir) if args.session_dir else state_dir / "sessions"
    coord_log = Path(args.coordination_log)
    now = now_utc(args.now)
    deferrals = iter_deferrals(Path(args.deferral_dir), now)
    rows = [r for r in iter_session_rows(session_dir) if r.get("status") == "needs_registration"]
    if args.session:
        rows = [r for r in rows if r.get("session") == args.session]
    if args.pane is not None:
        rows = [r for r in rows if int(r.get("pane", -1)) == args.pane]
    results = []
    pending = 0
    sent = 0
    deduped = 0
    deferred = 0
    dead = 0
    errors = []

    for row in rows:
        live = probe_live(args.ntm, row.get("session"), int(row.get("pane", -1)))
        defer = deferral_for(row, deferrals)
        recent = None
        action = "skip"
        request_path = None

        if not live["live"]:
            dead += 1
            if defer:
                deferred += 1
                action = "deferred_dead_session"
            else:
                action = "dead_session"
        else:
            recent = sent_recently(coord_log, row, now, args.window_seconds)
            if recent:
                deduped += 1
                action = "deduped_recent_send"
            else:
                pending += 1
                if args.doctor or args.dry_run:
                    action = "would_send"
                else:
                    try:
                        request_path = send_request(args, row, now)
                        event = {
                            "ts": iso(now),
                            "event": "agentmail_registration_broadcast_sent",
                            "from": "flywheel:agentmail-registration-broadcast",
                            "to": f"{row.get('session')}:{int(row.get('pane', -1))}",
                            "session": row.get("session"),
                            "pane": int(row.get("pane", -1)),
                            "row_key": row_key(row),
                            "request_path": str(request_path),
                            "bead": "flywheel-2uin",
                            "no_raw_tokens": True,
                        }
                        append_event(coord_log, event)
                        sent += 1
                        action = "sent"
                    except Exception as exc:
                        errors.append({"session": row.get("session"), "pane": row.get("pane"), "error": str(exc)})
                        action = "send_failed"

        results.append({
            "session": row.get("session"),
            "pane": int(row.get("pane", -1)),
            "row_key": row_key(row),
            "project_key": row.get("fleet_mail_project_key"),
            "live": live["live"],
            "live_reason": live["reason"],
            "deferred": bool(defer and not live["live"]),
            "deferral_receipt": defer.get("_receipt_path") if defer and not live["live"] else None,
            "recent_send_ts": recent.get("ts") if recent else None,
            "action": action,
            "request_path": str(request_path) if request_path else None,
        })

    payload = {
        "schema_version": SCHEMA_VERSION,
        "checked_at": iso(now),
        "status": "fail" if errors else "pass",
        "rows_checked": len(rows),
        "agentmail_pending_registration_broadcasts_count": pending,
        "live_needs_registration_unsent_count": pending,
        "sent_count": sent,
        "deduped_count": deduped,
        "dead_count": dead,
        "deferred_dead_count": deferred,
        "window_seconds": args.window_seconds,
        "session_filter": args.session,
        "pane_filter": args.pane,
        "no_raw_tokens": bool(args.no_raw_tokens),
        "coordination_log": str(coord_log),
        "results": results,
        "errors": errors,
        "signals": [{
            "name": "agentmail_pending_registration_broadcasts_count",
            "producer": ".flywheel/scripts/agentmail-registration-broadcast.sh --doctor --json",
            "measurement": "live needs_registration session:pane rows with no broadcast in the last hour",
            "consumer": "flywheel-loop doctor; /flywheel:status identity line",
            "threshold": "fail when count > 0; pass when deferred/dead rows are the only needs_registration rows",
        }],
    }
    if args.json or args.doctor:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print(f"agentmail_pending_registration_broadcasts_count={pending} sent_count={sent} deduped_count={deduped} deferred_dead_count={deferred}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
