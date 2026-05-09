#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse, json, os, subprocess, sys, tempfile
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "agentmail-registration-broadcast/v1"
DEFAULT_STATE = Path.home() / ".local/state/flywheel/agent-mail"
DEFAULT_COORD = Path.home() / ".local/state/flywheel/cross-orch-coordination.jsonl"
DEFAULT_DEFERRALS = Path.home() / ".local/state/flywheel/identity-overrides"

def parse_ts(value):
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")) if value else None
    except ValueError:
        return None

def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None

def registry_rows(session_dir):
    rows = []
    for path in sorted(session_dir.glob("*.json")) if session_dir.exists() else []:
        data = read_json(path)
        if isinstance(data, dict) and data.get("status") == "needs_registration":
            data["_path"] = str(path)
            rows.append(data)
    return rows

def active_deferrals(deferral_dir, now):
    rows = []
    for path in sorted(deferral_dir.glob("*.json")) if deferral_dir.exists() else []:
        payload = read_json(path)
        if not isinstance(payload, dict) or payload.get("schema_version") != "identity-registration-deferral/v1":
            continue
        expires = parse_ts(payload.get("expires_at"))
        if expires and expires < now:
            continue
        for row in payload.get("deferred_rows") or []:
            if isinstance(row, dict):
                rows.append({**row, "_receipt_path": str(path)})
    return rows

def key(row):
    return f"{row.get('session')}:{int(row.get('pane', -1))}"

def probe_live(ntm, row):
    try:
        proc = subprocess.run([ntm, "health", str(row.get("session")), "--json"], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=8, check=False)
        payload = json.loads(proc.stdout)
    except Exception as exc:
        return False, "session_not_running" if "payload" not in locals() else f"ntm_probe_error:{exc}"
    agents = payload.get("agents")
    if not isinstance(agents, list):
        return True, "session_live_no_agent_rows"
    for agent in agents:
        if int(agent.get("pane", -1)) == int(row.get("pane", -1)):
            ok = agent.get("process_status") == "running" and agent.get("status") in {"ok", "warn", "unknown"}
            return ok, "pane_running" if ok else f"pane_not_running:{agent.get('status')}:{agent.get('process_status')}"
    return False, "pane_missing"

def recent_send(coord_log, row, now, window):
    if not coord_log.exists():
        return None
    cutoff = now.timestamp() - window
    latest = None
    for line in coord_log.read_text(encoding="utf-8", errors="ignore").splitlines():
        try:
            event = json.loads(line)
        except Exception:
            continue
        ts = parse_ts(event.get("ts"))
        if event.get("event") == "agentmail_registration_broadcast_sent" and event.get("row_key") == key(row) and ts and ts.timestamp() >= cutoff:
            latest = event
    return latest

def write_request(rows, request_dir):
    Path(request_dir).mkdir(parents=True, exist_ok=True)
    fd, path_text = tempfile.mkstemp(prefix="agentmail-registration-broadcast-", suffix=".txt", dir=request_dir)
    lines = ["AGENTMAIL_IDENTITY_REGISTRATION_REQUEST bead_id=flywheel-2uin identity_resolved=pending no_raw_tokens=true", ""]
    for row in rows:
        lines += [
            f"- target={key(row)} project={row.get('fleet_mail_project_key')} registry_row={row.get('_path')}",
            f"  token_path=/Users/josh/.local/state/flywheel/agent-mail/tokens/<IdentityName>.token",
        ]
    lines += ["", "Use resolver-mediated registration. Cross-orch handshakes carry identity_resolved=<identity_name> and token_path, never raw tokens.", ""]
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    return Path(path_text)

def append_event(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")

def main(argv):
    p = argparse.ArgumentParser()
    p.add_argument("--state-dir", default=str(DEFAULT_STATE)); p.add_argument("--session-dir")
    p.add_argument("--deferral-dir", default=str(DEFAULT_DEFERRALS)); p.add_argument("--coordination-log", default=str(DEFAULT_COORD))
    p.add_argument("--request-dir", default="/tmp"); p.add_argument("--ntm", default=os.environ.get("NTM_BIN", "/Users/josh/.local/bin/ntm"))
    p.add_argument("--window-seconds", type=int, default=3600); p.add_argument("--now"); p.add_argument("--session"); p.add_argument("--pane", type=int)
    p.add_argument("--no-raw-tokens", action="store_true"); p.add_argument("--doctor", action="store_true"); p.add_argument("--dry-run", action="store_true"); p.add_argument("--json", action="store_true")
    args = p.parse_args(argv)
    now = parse_ts(args.now) or datetime.now(timezone.utc)
    coord_log = Path(args.coordination_log)
    session_dir = Path(args.session_dir) if args.session_dir else Path(args.state_dir) / "sessions"
    deferrals = active_deferrals(Path(args.deferral_dir), now)
    rows = registry_rows(session_dir)
    if args.session:
        rows = [r for r in rows if r.get("session") == args.session]
    if args.pane is not None:
        rows = [r for r in rows if int(r.get("pane", -1)) == args.pane]

    results, pending, to_send, sent, deduped, dead, deferred = [], 0, [], 0, 0, 0, 0
    for row in rows:
        live, reason = probe_live(args.ntm, row)
        defer = next((d for d in deferrals if d.get("session") == row.get("session") and int(d.get("pane", -1)) == int(row.get("pane", -1))), None)
        recent, action = recent_send(coord_log, row, now, args.window_seconds), "skip"
        if not live:
            dead += 1; deferred += 1 if defer else 0; action = "deferred_dead_session" if defer else "dead_session"
        elif recent:
            deduped += 1; action = "deduped_recent_send"
        else:
            pending += 1; action = "would_send" if args.doctor or args.dry_run else "pending_send"; to_send.append(row)
        results.append({"session": row.get("session"), "pane": int(row.get("pane", -1)), "row_key": key(row), "project_key": row.get("fleet_mail_project_key"), "live": live, "live_reason": reason, "deferred": bool(defer and not live), "deferral_receipt": defer.get("_receipt_path") if defer and not live else None, "recent_send_ts": recent.get("ts") if recent else None, "action": action, "request_path": None})

    errors = []
    if to_send and not (args.doctor or args.dry_run):
        request_path = write_request(to_send, args.request_dir)
        recipients = [key(row) for row in to_send]
        try:
            subprocess.run([args.ntm, "message", "--broadcast", "--to", ",".join(recipients), "--subject", "Agent Mail identity registration requested", "--file", str(request_path), "--no-raw-tokens"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10)
            for row in to_send:
                sent += 1
                event = {"ts": iso(now), "event": "agentmail_registration_broadcast_sent", "from": "flywheel:agentmail-registration-broadcast", "to": key(row), "session": row.get("session"), "pane": int(row.get("pane", -1)), "row_key": key(row), "request_path": str(request_path), "bead": "flywheel-2uin", "no_raw_tokens": True}
                append_event(coord_log, event)
                next(r for r in results if r["row_key"] == key(row)).update({"action": "sent", "request_path": str(request_path)})
        except Exception as exc:
            errors.append({"recipients": recipients, "error": str(exc)})

    payload = {"schema_version": SCHEMA_VERSION, "checked_at": iso(now), "status": "fail" if errors else "pass", "rows_checked": len(rows), "agentmail_pending_registration_broadcasts_count": pending, "live_needs_registration_unsent_count": pending, "sent_count": sent, "deduped_count": deduped, "dead_count": dead, "deferred_dead_count": deferred, "window_seconds": args.window_seconds, "session_filter": args.session, "pane_filter": args.pane, "no_raw_tokens": bool(args.no_raw_tokens), "coordination_log": str(coord_log), "results": results, "errors": errors, "signals": [{"name": "agentmail_pending_registration_broadcasts_count", "producer": ".flywheel/scripts/agentmail-registration-broadcast.sh --doctor --json", "measurement": "live needs_registration session:pane rows with no broadcast in the last hour", "consumer": "flywheel-loop doctor; /flywheel:status identity line", "threshold": "fail when count > 0; pass when deferred/dead rows are the only needs_registration rows"}]}
    print(json.dumps(payload, separators=(",", ":")) if args.json or args.doctor else f"agentmail_pending_registration_broadcasts_count={pending} sent_count={sent} deduped_count={deduped} deferred_dead_count={deferred}")
    return 1 if errors else 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
