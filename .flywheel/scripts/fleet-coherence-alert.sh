#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

VERSION = "fleet-coherence-alert/v1"
PROJECT_KEY = "/Users/josh/.local/state/flywheel/fleet-mail-project"


def utc_now():
    override = os.environ.get("FLYWHEEL_FLEET_COHERENCE_NOW")
    if override:
        return override
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def emit(payload, pretty=False):
    text = json.dumps(payload, indent=2 if pretty else None, sort_keys=True, separators=None if pretty else (",", ":"))
    print(text)


def load_jsonl(path):
    path = Path(path).expanduser()
    rows = []
    if not path.exists():
        return rows
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            row["__line"] = line_no
            rows.append(row)
    return rows


def append_jsonl(path, row):
    path = Path(path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def read_event(args):
    if args.event_json:
        return json.loads(args.event_json)
    if args.event_row:
        path = Path(args.event_row).expanduser()
        text = sys.stdin.read() if str(path) == "-" else path.read_text(encoding="utf-8")
        return json.loads(text)
    raise SystemExit("send requires --event-row or --event-json")


def run_command(argv, timeout):
    try:
        proc = subprocess.run(argv, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False)
        return {
            "attempted": True,
            "exit_code": proc.returncode,
            "stdout": (proc.stdout or "").strip(),
            "stderr": (proc.stderr or "").strip(),
        }
    except FileNotFoundError:
        return {"attempted": True, "exit_code": 127, "stdout": "", "stderr": "command not found"}
    except subprocess.TimeoutExpired:
        return {"attempted": True, "exit_code": 124, "stdout": "", "stderr": "timeout"}


def parse_message_id(stdout):
    if not stdout:
        return None
    for line in stdout.splitlines()[::-1]:
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(data, dict):
            for key in ("message_id", "id"):
                if data.get(key) is not None:
                    return str(data[key])
            deliveries = data.get("deliveries")
            if isinstance(deliveries, list) and deliveries:
                payload = deliveries[0].get("payload") if isinstance(deliveries[0], dict) else None
                if isinstance(payload, dict) and payload.get("id") is not None:
                    return str(payload["id"])
    return None


def info(args):
    return {
        "schema_version": f"{VERSION}/info",
        "status": "ok",
        "name": "fleet-coherence-alert.sh",
        "commands": ["send", "doctor", "health", "validate", "audit"],
        "canonical_cli_surfaces": ["--info", "--schema", "--doctor", "--health", "--validate", "--audit", "--why", "--repair", "--json", "--dry-run"],
        "mutation_default": "send appends alert ledger and event ledger only after channel attempts",
        "project_key": args.project_key,
        "ledger": args.ledger,
    }


def schema(args):
    return {
        "schema_version": f"{VERSION}/schema",
        "status": "ok",
        "alert_attempt_required": [
            "schema_version",
            "event_id",
            "dedupe_key",
            "attempt_ts",
            "agent_mail_message_id",
            "ntm_result",
            "l61_pairing_status",
        ],
        "event_schema_version": 2,
        "l61_pairing_status": ["complete", "mail_only", "ntm_only", "degraded", "suppressed"],
        "stable_exit_codes": {"0": "complete or suppressed", "1": "degraded", "64": "usage", "65": "invalid event row"},
    }


def check_fixtures(args, mode):
    rows = load_jsonl(args.fixtures)
    cases = {r.get("case") for r in rows}
    required = {"success", "agent_mail_fails", "ntm_fails", "resend_suppressed", "stale_callback_pane"}
    status = "ok" if required.issubset(cases) else "warn"
    return {
        "schema_version": f"{VERSION}/{mode}",
        "mode": mode,
        "status": status,
        "fixture_cases": sorted(c for c in cases if c),
        "fixtures": args.fixtures,
        "read_only": True,
    }


def why(args):
    return {
        "schema_version": f"{VERSION}/why",
        "status": "ok",
        "reason": "L61 is only complete when fleet-mail durable delivery and NTM callback-pane wake signal succeed in the same logical exchange.",
    }


def repair(args):
    return {
        "schema_version": f"{VERSION}/repair",
        "status": "refused",
        "dry_run": True,
        "apply": False,
        "reason": "Cannot repair: alert delivery depends on live Agent Mail and NTM transport state; this helper records degraded attempts instead.",
    }


def latest_attempt(rows, dedupe_key):
    matches = [r for r in rows if r.get("dedupe_key") == dedupe_key]
    if not matches:
        return None
    return sorted(matches, key=lambda r: str(r.get("attempt_ts") or ""))[-1]


def should_suppress(event, ledger_rows, now):
    if event.get("state") in {"closed", "suppressed"}:
        return True, "event_state_not_alertable"
    resend_at = parse_ts(event.get("resend_after_ts"))
    now_dt = parse_ts(now)
    if resend_at and now_dt and now_dt < resend_at:
        return True, "resend_after_ts_not_reached"
    return False, None


def auth_probe(args, session, pane):
    if not args.auth_probe:
        return {"ready": True, "identity_name": args.sender, "identity_source": "explicit", "l61": {"vault_token_validated": False}}
    argv = [args.auth_probe, "--session", session, "--json"]
    if pane is not None:
        argv.extend(["--pane", str(pane)])
    result = run_command(argv, args.timeout)
    data = {}
    try:
        data = json.loads(result["stdout"])
    except Exception:
        pass
    data["_command"] = result
    return data


def attempt_agent_mail(args, event, sender, recipient, subject, body):
    if args.dry_run:
        return {"attempted": False, "exit_code": 0, "stdout": "", "stderr": "", "message_id": "dry-run"}
    if not args.agent_mail_send:
        return {"attempted": False, "exit_code": 127, "stdout": "", "stderr": "agent_mail_send command missing", "message_id": None}
    argv = [
        args.agent_mail_send,
        "send_message",
        "--project-key",
        args.project_key,
        "--sender-name",
        sender,
        "--to",
        recipient,
        "--subject",
        subject,
        "--body",
        body,
        "--sender-token-handle",
        args.sender_token_handle or f"vault:{sender}",
    ]
    if args.agent_mail_capture_dir:
        argv.extend(["--capture-dir", args.agent_mail_capture_dir])
    result = run_command(argv, args.timeout)
    result["message_id"] = parse_message_id(result["stdout"])
    return result


def attempt_ntm(args, session, pane, message):
    if args.dry_run:
        return {"attempted": False, "exit_code": 0, "stdout": "", "stderr": "", "status": "dry-run"}
    if not args.ntm_bin:
        return {"attempted": False, "exit_code": 127, "stdout": "", "stderr": "ntm command missing", "status": "missing"}
    if not session or pane is None:
        return {"attempted": False, "exit_code": 64, "stdout": "", "stderr": "missing callback pane", "status": "stale_callback_pane"}
    result = run_command([args.ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", message], args.timeout)
    result["status"] = "sent" if result["exit_code"] == 0 else "failed"
    return result


def pairing_status(mail_ok, ntm_ok, suppressed=False):
    if suppressed:
        return "suppressed"
    if mail_ok and ntm_ok:
        return "complete"
    if mail_ok and not ntm_ok:
        return "mail_only"
    if ntm_ok and not mail_ok:
        return "ntm_only"
    return "degraded"


def append_event(args, event):
    writer = args.writer
    if not writer:
        return {"attempted": False, "exit_code": 0, "stdout": "", "stderr": "writer disabled"}
    return run_command([writer, "append", "--row-json", json.dumps(event, sort_keys=True), "--json"], args.timeout)


def send(args):
    event = read_event(args)
    now = args.now or utc_now()
    event_id = event.get("event_id") or event.get("id")
    dedupe_key = event.get("dedupe_key")
    if not event_id or not dedupe_key:
        raise SystemExit("event row requires event_id/id and dedupe_key")

    if args.ntm_session is not None:
        target_session = args.ntm_session
    else:
        target_session = event.get("session") or (event.get("l61") or {}).get("ntm_session")
    target_pane = args.ntm_pane
    if target_pane is None:
        target_pane = event.get("pane") if event.get("pane") is not None else (event.get("l61") or {}).get("ntm_pane")

    ledger_rows = load_jsonl(args.ledger)
    suppress, suppress_reason = should_suppress(event, ledger_rows, now)

    auth = auth_probe(args, args.sender_session or event.get("session") or "flywheel", args.sender_pane)
    sender = args.sender or auth.get("identity_name") or (event.get("l61") or {}).get("agent_mail_from") or "LavenderGlen"
    recipient = args.to or (event.get("l61") or {}).get("agent_mail_to") or os.environ.get("FLEET_COHERENCE_ALERT_TO", "FoggyBear")
    subject = args.subject or f"[fleet-coherence] {event.get('class', 'event')} {event.get('severity', '')}".strip()
    body = args.body or f"Fleet coherence event {event_id} dedupe_key={dedupe_key} session={target_session} pane={target_pane}"

    mail = {"attempted": False, "exit_code": None, "stdout": "", "stderr": "", "message_id": None}
    ntm = {"attempted": False, "exit_code": None, "stdout": "", "stderr": "", "status": None}
    degraded_reason = None

    if suppress:
        status = "suppressed"
        degraded_reason = suppress_reason
    elif not auth.get("ready", False):
        status = "degraded"
        degraded_reason = "fleet_mail_auth_probe_failed"
    else:
        mail = attempt_agent_mail(args, event, sender, recipient, subject, body)
        mail_ok = mail.get("exit_code") == 0 and bool(mail.get("message_id"))
        poke = f'POKE fleet-coherence alert msg id={mail.get("message_id")} project={args.project_key} event_id={event_id} dedupe_key={dedupe_key}'
        ntm = attempt_ntm(args, target_session, target_pane, poke)
        ntm_ok = ntm.get("exit_code") == 0
        status = pairing_status(mail_ok, ntm_ok)
        if status != "complete":
            if mail_ok and not ntm_ok:
                degraded_reason = "ntm_send_failed"
            elif ntm_ok and not mail_ok:
                degraded_reason = "agent_mail_send_failed"
            else:
                degraded_reason = "both_channels_failed"
            if ntm.get("status") == "stale_callback_pane":
                degraded_reason = "stale_callback_pane"

    updated = json.loads(json.dumps(event))
    l61 = updated.setdefault("l61", {})
    l61.update({
        "project_key": args.project_key,
        "fleet_mail_identity_source": auth.get("identity_source") or auth.get("identity_name") or "probe",
        "vault_token_validated": bool((auth.get("l61") or {}).get("vault_token_validated")),
        "agent_mail_attempted": bool(mail.get("attempted")),
        "agent_mail_sent_at": now if mail.get("attempted") else None,
        "agent_mail_message_id": mail.get("message_id"),
        "agent_mail_from": sender,
        "agent_mail_to": recipient,
        "ntm_attempted": bool(ntm.get("attempted")),
        "ntm_sent_at": now if ntm.get("attempted") else None,
        "ntm_session": target_session,
        "ntm_pane": target_pane,
        "ntm_result": {"exit_code": ntm.get("exit_code"), "status": ntm.get("status"), "stdout": ntm.get("stdout")},
        "l61_pairing_status": status,
        "degraded_reason": degraded_reason,
    })
    updated["ts"] = now
    updated["last_seen_ts"] = now
    if suppress:
        updated.setdefault("actions", {})["would_l61"] = False

    write_result = append_event(args, updated)
    attempt = {
        "schema_version": "fleet-coherence-alert-attempt/v1",
        "case": args.case,
        "event_id": event_id,
        "dedupe_key": dedupe_key,
        "attempt_ts": now,
        "project_key": args.project_key,
        "agent_mail_message_id": mail.get("message_id"),
        "agent_mail_exit_code": mail.get("exit_code"),
        "ntm_result": {"exit_code": ntm.get("exit_code"), "status": ntm.get("status")},
        "l61_pairing_status": status,
        "degraded_reason": degraded_reason,
        "resend_suppressed": bool(suppress),
        "alert_sent": status == "complete",
        "event_write_exit_code": write_result.get("exit_code"),
    }
    append_jsonl(args.ledger, attempt)

    receipt = {
        "schema_version": f"{VERSION}/receipt",
        "status": "pass" if status in {"complete", "suppressed"} else "fail",
        "event_id": event_id,
        "dedupe_key": dedupe_key,
        "ledger": args.ledger,
        "events_path": os.environ.get("FLYWHEEL_FLEET_COHERENCE_EVENTS"),
        "attempt": attempt,
        "updated_l61": l61,
        "writer": write_result,
    }
    return receipt, 0 if receipt["status"] == "pass" else 1


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Send fleet-coherence L61 dual-channel alerts.")
    parser.add_argument("command", nargs="?", default="send")
    parser.add_argument("--event-row")
    parser.add_argument("--event-json")
    parser.add_argument("--ledger", default=os.environ.get("FLEET_COHERENCE_ALERT_LEDGER", str(Path.home() / ".local/state/flywheel/fleet-coherence-alerts.jsonl")))
    parser.add_argument("--fixtures", default=os.environ.get("FLEET_COHERENCE_ALERT_FIXTURES", ".flywheel/fixtures/fleet-coherence-alerts.jsonl"))
    parser.add_argument("--writer", default=os.environ.get("FLEET_COHERENCE_WRITER", ".flywheel/scripts/fleet-coherence-write.sh"))
    parser.add_argument("--auth-probe", default=os.environ.get("FLEET_COHERENCE_AUTH_PROBE", ".flywheel/scripts/fleet-mail-auth-probe.sh"))
    parser.add_argument("--agent-mail-send", default=os.environ.get("FLEET_COHERENCE_AGENT_MAIL_SEND", ".flywheel/scripts/agent-mail-send-redacted.sh"))
    parser.add_argument("--ntm-bin", default=os.environ.get("FLEET_COHERENCE_NTM", "/Users/josh/.local/bin/ntm"))
    parser.add_argument("--agent-mail-capture-dir")
    parser.add_argument("--project-key", default=os.environ.get("FLEET_COHERENCE_FLEET_MAIL_PROJECT", PROJECT_KEY))
    parser.add_argument("--sender")
    parser.add_argument("--sender-session")
    parser.add_argument("--sender-pane", type=int)
    parser.add_argument("--sender-token-handle")
    parser.add_argument("--to")
    parser.add_argument("--subject")
    parser.add_argument("--body")
    parser.add_argument("--ntm-session")
    parser.add_argument("--ntm-pane", type=int)
    parser.add_argument("--timeout", type=float, default=float(os.environ.get("FLEET_COHERENCE_ALERT_TIMEOUT", "5")))
    parser.add_argument("--now")
    parser.add_argument("--case")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--why", action="store_true")
    parser.add_argument("--repair", action="store_true")
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.info:
        emit(info(args), args.pretty and not args.json); return 0
    if args.schema:
        emit(schema(args), args.pretty and not args.json); return 0
    for flag, mode in ((args.doctor, "doctor"), (args.health, "health"), (args.validate, "validate"), (args.audit, "audit")):
        if flag:
            payload = check_fixtures(args, mode)
            emit(payload, args.pretty and not args.json)
            return 0 if payload["status"] == "ok" else 1
    if args.why:
        emit(why(args), args.pretty and not args.json); return 0
    if args.repair:
        emit(repair(args), args.pretty and not args.json); return 1
    if args.command != "send":
        raise SystemExit(f"unknown command: {args.command}")
    payload, rc = send(args)
    emit(payload, args.pretty and not args.json)
    return rc


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
