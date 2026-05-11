#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.22)
set -euo pipefail

VERSION="escalate-capsule-plan-consumer.v1.1.0"
SCHEMA_VERSION="escalate-capsule-plan-consumer/v1"
IDEMPOTENCY_KEY=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="$REPO_DEFAULT"
COMMAND=""
INBOX_JSON=""
SLUG=""
SISTER_SESSION=""
MESSAGE_ID=""
DRY_RUN=0
APPLY=0
JSON_OUT=0
REPLY_LEDGER="${ESCALATE_CAPSULE_REPLY_LEDGER:-$HOME/.local/state/flywheel/escalate-capsule-replies.jsonl}"
ACTION_LEDGER="${ESCALATE_CAPSULE_ACTION_LEDGER:-$HOME/.local/state/flywheel/escalate-capsule-consumer.jsonl}"

usage() {
  cat <<'EOF'
usage:
  escalate-capsule-plan-consumer.sh scan --inbox-json PATH [--repo PATH] [--dry-run|--apply --idempotency-key KEY] [--json]
  escalate-capsule-plan-consumer.sh report-progress --slug SLUG --sister-session SESSION [--message-id ID] [--repo PATH] [--dry-run|--apply --idempotency-key KEY] [--json]
  escalate-capsule-plan-consumer.sh --info --json
  escalate-capsule-plan-consumer.sh --schema --json
  escalate-capsule-plan-consumer.sh --examples [--json]
  escalate-capsule-plan-consumer.sh doctor --json
  escalate-capsule-plan-consumer.sh health --json
  escalate-capsule-plan-consumer.sh validate --json
  escalate-capsule-plan-consumer.sh audit --json [--limit N]
  escalate-capsule-plan-consumer.sh why [topic] [--json]
  escalate-capsule-plan-consumer.sh quickstart [--json]
  escalate-capsule-plan-consumer.sh repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY] [--json]

Consumes sister-orch [ESCALATE] capsules and opens /flywheel:plan intent state
within the current flywheel tick.
EOF
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" \
    --arg reply_ledger "$REPLY_LEDGER" --arg action_ledger "$ACTION_LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:"escalate-capsule-plan-consumer.sh",
      version:$version,
      reply_ledger:$reply_ledger,
      action_ledger:$action_ledger,
      purpose:"Scan sister-orch inbox for [ESCALATE] capsules (blocker survived 2+ ticks) and open /flywheel:plan accretive-fix intent state within the current flywheel tick.",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart","scan","report-progress"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--inbox-json","--slug","--sister-session","--message-id","--repo"],
      capabilities:[
        "escalate-capsule-pattern-detection",
        "blocker-survived-2-ticks-recognition",
        "flywheel-plan-slug-generation",
        "sister-orch-reply-via-agent-mail",
        "report-progress-back-to-sister",
        "action-ledger-append-per-capsule"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["ESCALATE_CAPSULE_REPLY_LEDGER","ESCALATE_CAPSULE_ACTION_LEDGER"],
      exit_codes:{"0":"pass","1":"scan-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        command:{enum:["scan","report-progress"]},
        repo:{type:"string"},
        inbox_json:{type:"string",description:"path to sister-orch inbox JSON"},
        slug:{type:"string",description:"plan slug for report-progress"},
        sister_session:{type:"string",description:"sister session name"},
        message_id:{type:"string"},
        apply:{type:"boolean"},
        dry_run:{type:"boolean"},
        idempotency_key:{type:"string",description:"required with --apply"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status"],
      properties:{
        schema_version:{const:"escalate-capsule-plan-consumer/v1"},
        status:{enum:["pass","fail","dry_run","applied"]},
        capsules_processed:{type:"integer",minimum:0},
        plan_intents_opened:{type:"array"},
        reply_results:{type:"array"}
      }
    },
    exit_codes:{"0":"pass","1":"scan-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

emit_examples() {
  if [[ "${1:-}" == "--json" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" '{
      schema_version:$sv,
      command:"examples",
      examples:[
        {name:"scan-dry-run",invocation:"escalate-capsule-plan-consumer.sh scan --inbox-json /tmp/inbox.json --dry-run --json",purpose:"scan sister inbox for [ESCALATE] capsules without opening plan state"},
        {name:"scan-apply",invocation:"escalate-capsule-plan-consumer.sh scan --inbox-json /tmp/inbox.json --apply --idempotency-key esc-2026-05-11 --json",purpose:"scan + open /flywheel:plan accretive-fix intents + reply to sister; requires --idempotency-key"},
        {name:"report-progress",invocation:"escalate-capsule-plan-consumer.sh report-progress --slug accretive-fix-blocker-abc --sister-session mobile-eats --message-id m123 --apply --idempotency-key esc-report-2026-05-11 --json",purpose:"send progress update back to sister session"},
        {name:"doctor",invocation:"escalate-capsule-plan-consumer.sh doctor --json",purpose:"canonical doctor envelope"},
        {name:"audit",invocation:"escalate-capsule-plan-consumer.sh audit --json",purpose:"tail recent action ledger rows"}
      ]
    }'
  else
    cat <<'EOF'
examples:
  escalate-capsule-plan-consumer.sh scan --inbox-json /tmp/inbox.json --dry-run --json
  escalate-capsule-plan-consumer.sh scan --inbox-json /tmp/inbox.json --apply --idempotency-key esc-2026-05-11 --json
  escalate-capsule-plan-consumer.sh report-progress --slug accretive-fix-blocker-abc --sister-session mobile-eats --apply --idempotency-key esc-r-2026-05-11 --json
  escalate-capsule-plan-consumer.sh doctor --json
  escalate-capsule-plan-consumer.sh audit --json
EOF
  fi
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local py_status="pass"; command -v python3 >/dev/null 2>&1 || py_status="fail"
  local reply_dir; reply_dir="$(dirname "$REPLY_LEDGER")"
  local reply_status="pass"
  if [[ -e "$REPLY_LEDGER" ]]; then
    [[ -w "$REPLY_LEDGER" ]] || reply_status="fail"
  else
    [[ -d "$reply_dir" ]] || reply_status="warn"
  fi
  local action_dir; action_dir="$(dirname "$ACTION_LEDGER")"
  local action_status="pass"
  if [[ -e "$ACTION_LEDGER" ]]; then
    [[ -w "$ACTION_LEDGER" ]] || action_status="fail"
  else
    [[ -d "$action_dir" ]] || action_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$py_status" "$reply_status" "$action_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg py_s "$py_status" \
    --arg reply_s "$reply_status" --arg reply "$REPLY_LEDGER" \
    --arg action_s "$action_status" --arg action "$ACTION_LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"python3",status:$py_s,detail:"python3 required for scan + report-progress logic"},
        {name:"reply_ledger_writable",status:$reply_s,path:$reply,detail:"append-only reply ledger (sister-orch responses)"},
        {name:"action_ledger_writable",status:$action_s,path:$action,detail:"append-only action ledger (capsule consumption)"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local reply_count=0 action_count=0
  [[ -r "$REPLY_LEDGER" ]] && reply_count="$(wc -l <"$REPLY_LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -r "$ACTION_LEDGER" ]] && action_count="$(wc -l <"$ACTION_LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$reply_count" ]] && reply_count=0
  [[ -z "$action_count" ]] && action_count=0
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg reply "$REPLY_LEDGER" --argjson reply_count "$reply_count" \
    --arg action "$ACTION_LEDGER" --argjson action_count "$action_count" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",reply_ledger:$reply,reply_ledger_row_count:$reply_count,action_ledger:$action,action_ledger_row_count:$action_count}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$ACTION_LEDGER" ]]; then
    rows="$(wc -l <"$ACTION_LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "")' "$ACTION_LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$ACTION_LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every action row has non-empty schema_version"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso)"
  if [[ ! -r "$ACTION_LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$ACTION_LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$ACTION_LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$ACTION_LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$ACTION_LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|escalate-capsule-pattern)
      body='Sister-orchestrators emit [ESCALATE] capsules into agent-mail inboxes when a blocker has survived 2 consecutive ticks (per AGENTS.md L70 two-blocker-ticks rule). The capsule subject line matches /^\[?ESCALATE\]?\s+blocker survived 2 ticks/i. This consumer scans inboxes, opens /flywheel:plan accretive-fix-<slug> intent state, and replies to the sister with the plan slug.'
      ;;
    accretive-fix-slug)
      body='Plan slug = accretive-fix- + slugified blocker_id (lowercase, alphanumeric-only, dash-separated, max 96 chars). Used as the /flywheel:plan target so the planner thread can resume on subsequent ticks. Dedupe-by-slug so re-running scan on the same capsule is idempotent.'
      ;;
    sister-orch-reply)
      body='After opening plan intent state, the consumer replies to the sister orchestrator via agent-mail with the plan slug + ETA. Reply ledger appends the response for audit. Sister can then call report-progress later to check status — that path runs through this same consumer.'
      ;;
    *)
      body="unknown topic: $topic. known: escalate-capsule-pattern, accretive-fix-slug, sister-orch-reply"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-escalate-capsule-pattern}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"escalate-capsule-plan-consumer.sh doctor --json"},
      {step:2,action:"scan-dry-run",command:"escalate-capsule-plan-consumer.sh scan --inbox-json /tmp/inbox.json --dry-run --json"},
      {step:3,action:"scan-apply",command:"escalate-capsule-plan-consumer.sh scan --inbox-json /tmp/inbox.json --apply --idempotency-key esc-$(date +%Y%m%d) --json"},
      {step:4,action:"audit-recent",command:"escalate-capsule-plan-consumer.sh audit --json"}
    ],
    next_actions:["wire-to-fleet-tick","monitor-action-ledger"]
  }'
}

emit_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      --help|-h) printf 'repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(now_iso)"
  case "$scope" in
    ledger-prime)
      local present_action_before present_reply_before present_action_after present_reply_after
      present_action_before="$([[ -f "$ACTION_LEDGER" ]] && printf true || printf false)"
      present_reply_before="$([[ -f "$REPLY_LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$(dirname "$ACTION_LEDGER")" "$(dirname "$REPLY_LEDGER")" 2>/dev/null || true
        [[ -f "$ACTION_LEDGER" ]] || : > "$ACTION_LEDGER"
        [[ -f "$REPLY_LEDGER" ]] || : > "$REPLY_LEDGER"
      fi
      present_action_after="$([[ -f "$ACTION_LEDGER" ]] && printf true || printf false)"
      present_reply_after="$([[ -f "$REPLY_LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg action "$ACTION_LEDGER" --arg reply "$REPLY_LEDGER" --arg key "$idem_key" \
        --argjson action_before "$present_action_before" --argjson action_after "$present_action_after" \
        --argjson reply_before "$present_reply_before" --argjson reply_after "$present_reply_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,action_ledger:$action,reply_ledger:$reply,action_present_before:$action_before,action_present_after:$action_after,reply_present_before:$reply_before,reply_present_after:$reply_after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --info) emit_info; exit 0 ;;
  --schema) emit_schema; exit 0 ;;
  --examples)
    shift
    emit_examples "${1:-}"
    exit 0
    ;;
  doctor) shift; emit_canonical_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
  validate) shift; emit_canonical_validate; exit 0 ;;
  audit)
    shift
    LIMIT=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    emit_audit "$LIMIT"
    exit 0
    ;;
  why)
    shift
    TOPIC=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  quickstart) shift; emit_quickstart; exit 0 ;;
  repair) shift; emit_repair "$@"; exit 0 ;;
esac

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    scan|report-progress) COMMAND="$1"; shift ;;
    --repo) REPO="${2:?}"; shift 2 ;;
    --inbox-json) INBOX_JSON="${2:?}"; shift 2 ;;
    --slug) SLUG="${2:?}"; shift 2 ;;
    --sister-session) SISTER_SESSION="${2:?}"; shift 2 ;;
    --message-id) MESSAGE_ID="${2:?}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# Canonical apply contract: --apply requires --idempotency-key.
if [[ "${APPLY:-0}" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi

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
