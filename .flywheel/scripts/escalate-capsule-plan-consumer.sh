#!/usr/bin/env bash
set -euo pipefail

VERSION="escalate-capsule-plan-consumer.v1.0.0"
SCHEMA_VERSION="escalate-capsule-plan-consumer/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="$REPO_DEFAULT"
COMMAND=""
INBOX_JSON=""
SLUG=""
SISTER_SESSION=""
MESSAGE_ID=""
DRY_RUN=0
JSON_OUT=0
REPLY_LEDGER="${ESCALATE_CAPSULE_REPLY_LEDGER:-$HOME/.local/state/flywheel/escalate-capsule-replies.jsonl}"
ACTION_LEDGER="${ESCALATE_CAPSULE_ACTION_LEDGER:-$HOME/.local/state/flywheel/escalate-capsule-consumer.jsonl}"

usage() {
  cat <<'EOF'
usage:
  escalate-capsule-plan-consumer.sh scan --inbox-json PATH [--repo PATH] [--dry-run] [--json]
  escalate-capsule-plan-consumer.sh report-progress --slug SLUG --sister-session SESSION [--message-id ID] [--repo PATH] [--dry-run] [--json]

Consumes sister-orch [ESCALATE] capsules and opens /flywheel:plan intent state
within the current flywheel tick.
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    scan|report-progress) COMMAND="$1"; shift ;;
    --repo) REPO="${2:?}"; shift 2 ;;
    --inbox-json) INBOX_JSON="${2:?}"; shift 2 ;;
    --slug) SLUG="${2:?}"; shift 2 ;;
    --sister-session) SISTER_SESSION="${2:?}"; shift 2 ;;
    --message-id) MESSAGE_ID="${2:?}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

python3 - "$COMMAND" "$REPO" "$INBOX_JSON" "$SLUG" "$SISTER_SESSION" "$MESSAGE_ID" "$DRY_RUN" "$JSON_OUT" "$REPLY_LEDGER" "$ACTION_LEDGER" "$SCHEMA_VERSION" <<'PY'
import json, os, re, sys, tempfile
from datetime import datetime, timezone
from pathlib import Path

command, repo_arg, inbox_arg, slug_arg, sister_arg, message_id_arg = sys.argv[1:7]
dry_run, json_out = sys.argv[7] == "1", sys.argv[8] == "1"
reply_ledger, action_ledger, schema_version = Path(sys.argv[9]), Path(sys.argv[10]), sys.argv[11]
repo = Path(repo_arg)
SUBJECT_RE = re.compile(r"^\[?ESCALATE\]?\s+blocker survived 2 ticks", re.I)

def iso():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

def slugify(value):
    text = re.sub(r"[^a-z0-9]+", "-", str(value).lower()).strip("-")
    return text[:96] or "unknown"

def plan_slug(blocker_id):
    return "accretive-fix-" + slugify(blocker_id)

def read_json_or_jsonl(path):
    text = Path(path).read_text(encoding="utf-8") if path and Path(path).exists() else ""
    if not text.strip():
        return []
    try:
        data = json.loads(text)
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            return data.get("messages") or data.get("inbox") or [data]
    except json.JSONDecodeError:
        pass
    return [json.loads(line) for line in text.splitlines() if line.strip()]

def read_jsonl(path):
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows

def append_jsonl(path, row):
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")

def atomic_write(path, text):
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    tmp_path = Path(tmp)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, path)
    except Exception:
        try:
            tmp_path.unlink()
        except OSError:
            pass
        raise

def atomic_write_json(path, data):
    atomic_write(path, json.dumps(data, sort_keys=True, indent=2) + "\n")

def parse_body(body):
    fields = {}
    current = None
    for raw in str(body or "").splitlines():
        line = raw.rstrip()
        if not line:
            continue
        match = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$", line)
        if match:
            current = match.group(1)
            fields[current] = match.group(2).strip()
        elif current:
            fields[current] += "\n" + line.strip()
    if "ticks_survived" in fields and "tick_count" not in fields:
        fields["tick_count"] = fields["ticks_survived"]
    return fields

def split_list(value):
    return [item.strip() for item in re.split(r"[,\n]+", str(value or "")) if item.strip()]

def valid_subject(subject):
    return bool(SUBJECT_RE.search(str(subject or "")))

def round_count_from_state(state):
    for key in ("round_count", "round", "refine_round", "audit_round", "polish_round"):
        value = state.get(key)
        if isinstance(value, int):
            return value
        if isinstance(value, str) and value.isdigit():
            return int(value)
    return 0

def existing_reply(dedupe_key):
    return any(row.get("dedupe_key") == dedupe_key for row in read_jsonl(reply_ledger))

def emit_reply(kind, sister_session, subject, body, dedupe_key, extra=None):
    row = {
        "schema_version": "fleet-mail-reply/v1",
        "ts": iso(),
        "kind": kind,
        "to_session": sister_session,
        "subject": subject,
        "body_md": body,
        "dedupe_key": dedupe_key,
        "delivery": "fleet-mail-reply-staged",
    }
    if message_id_arg:
        row["reply_to_message_id"] = message_id_arg
    if extra:
        row.update(extra)
    if not existing_reply(dedupe_key):
        append_jsonl(reply_ledger, row)
        return "created"
    return "reused"

def open_plan_from_message(msg):
    subject = str(msg.get("subject") or "")
    body = msg.get("body_md") if msg.get("body_md") is not None else msg.get("body", "")
    fields = parse_body(body)
    blocker_id = fields.get("blocker_id", "")
    missing = [key for key in ("blocker_id", "affected_beads", "hypothesis") if not fields.get(key)]
    if not valid_subject(subject) or missing:
        return None, {"message_id": msg.get("id"), "subject": subject, "reason": "invalid_escalate_capsule_for_plan_consumer", "missing": missing}
    slug = plan_slug(blocker_id)
    plan_dir = repo / ".flywheel" / "plans" / slug
    intent_path = plan_dir / "00-INTENT.md"
    state_path = plan_dir / "STATE.json"
    command_text = f"/flywheel:plan accretive-fix-{slugify(blocker_id)}"
    affected = split_list(fields.get("affected_beads"))
    evidence = split_list(fields.get("evidence_paths"))
    sister_session = fields.get("sister_session") or str(msg.get("from") or "unknown").split(":")[0]
    intent = "\n".join([
        f"# {slug}",
        "",
        f"Command: `{command_text}`",
        "",
        "## Capsule",
        "",
        f"- message_id: {msg.get('id')}",
        f"- subject: {subject}",
        f"- blocker_id: {blocker_id}",
        f"- sister_session: {sister_session}",
        f"- affected_beads: {', '.join(affected)}",
        f"- hypothesis: {fields.get('hypothesis')}",
        "",
        "## Capsule Body",
        "",
        "```text",
        str(body).rstrip(),
        "```",
        "",
        "## Joshua-Lens Operator Check",
        "",
        "This plan exists because a sister orchestrator retried the same blocker twice. An ops team can tolerate one noisy tick, but two consecutive blocker ticks is a management-system signal: route the structural fix to the owner loop before local teams burn time on repeated recovery.",
        "",
    ]) + "\n"
    state = {
        "schema_version": "flywheel-plan-state/v5",
        "slug": slug,
        "current_phase": "research",
        "round_count": 0,
        "opened_at": iso(),
        "opened_by": "escalate-capsule-plan-consumer",
        "source": "fleet-mail-escalate-capsule",
        "source_message_id": msg.get("id"),
        "sister_session": sister_session,
        "blocker_id": blocker_id,
        "affected_beads": affected,
        "hypothesis": fields.get("hypothesis"),
        "evidence_paths": evidence,
        "intent_command": command_text,
        "sla": "opened_within_same_tick",
    }
    already_open = state_path.exists()
    if not already_open:
        atomic_write(intent_path, intent)
        atomic_write_json(state_path, state)
    append_jsonl(action_ledger, {
        "schema_version": schema_version,
        "ts": iso(),
        "event": "escalate_capsule_plan_opened",
        "message_id": msg.get("id"),
        "blocker_id": blocker_id,
        "slug": slug,
        "intent_path": str(intent_path),
        "state_path": str(state_path),
        "command": command_text,
        "same_tick_sla_met": True,
        "action": "reused" if already_open else "created",
    })
    reply_action = emit_reply(
        "plan_opened",
        sister_session,
        f"Re: {subject}",
        f"plan_opened={slug}\nphase=research\nround_count=0\nintent_path={intent_path}\n",
        f"plan_opened:{msg.get('id')}:{slug}",
        {"plan_slug": slug, "blocker_id": blocker_id, "phase": "research", "round_count": 0},
    )
    return {
        "message_id": msg.get("id"),
        "subject": subject,
        "blocker_id": blocker_id,
        "affected_beads": affected,
        "hypothesis": fields.get("hypothesis"),
        "sister_session": sister_session,
        "slug": slug,
        "intent_path": str(intent_path),
        "state_path": str(state_path),
        "plan_command": command_text,
        "action": "reused" if already_open else "created",
        "plan_opened_reply": reply_action,
        "same_tick_sla_met": True,
    }, None

def scan():
    messages = read_json_or_jsonl(inbox_arg)
    results, errors = [], []
    for msg in messages:
        if not valid_subject(msg.get("subject")):
            continue
        result, error = open_plan_from_message(msg)
        if result:
            results.append(result)
        elif error:
            errors.append(error)
    return {
        "schema_version": schema_version,
        "status": "pass" if not errors else "warn",
        "repo": str(repo),
        "inbox_json": inbox_arg,
        "messages_scanned": len(messages),
        "escalate_capsules_seen": len(results) + len(errors),
        "plans_opened": [row["slug"] for row in results if row["action"] == "created"],
        "plans_reused": [row["slug"] for row in results if row["action"] == "reused"],
        "results": results,
        "errors": errors,
    }

def report_progress():
    if not slug_arg or not sister_arg:
        raise SystemExit("report-progress requires --slug and --sister-session")
    state_path = repo / ".flywheel" / "plans" / slug_arg / "STATE.json"
    state = json.loads(state_path.read_text(encoding="utf-8"))
    phase = state.get("current_phase") or state.get("phase") or "unknown"
    round_count = round_count_from_state(state)
    dedupe = f"plan_progress:{slug_arg}:{phase}:{round_count}"
    action = emit_reply(
        "plan_progress",
        sister_arg,
        f"[PLAN_PROGRESS] {slug_arg} {phase} r{round_count}",
        f"plan_slug={slug_arg}\nplan_phase={phase}\nround_count={round_count}\nstate_path={state_path}\n",
        dedupe,
        {"plan_slug": slug_arg, "phase": phase, "round_count": round_count},
    )
    append_jsonl(action_ledger, {
        "schema_version": schema_version,
        "ts": iso(),
        "event": "escalate_capsule_plan_progress_reported",
        "slug": slug_arg,
        "sister_session": sister_arg,
        "phase": phase,
        "round_count": round_count,
        "reply_action": action,
    })
    return {"schema_version": schema_version, "status": "pass", "slug": slug_arg, "sister_session": sister_arg, "phase": phase, "round_count": round_count, "progress_reply": action}

if command == "scan":
    payload = scan()
elif command == "report-progress":
    payload = report_progress()
else:
    raise SystemExit("unknown command")

if json_out:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    print(json.dumps(payload, sort_keys=True))
PY
