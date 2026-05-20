#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.5)
set -euo pipefail

VERSION="capacity-halt-pane-authorization.v1.1.0"
SCHEMA_VERSION="capacity-halt-pane-authorization/v1"
TOPOLOGY="${CAPACITY_HALT_AUTH_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
NOW_EPOCH="${CAPACITY_HALT_AUTH_NOW_EPOCH:-}"
MAX_AGE_SECONDS="${CAPACITY_HALT_AUTH_MAX_AGE_SECONDS:-3600}"
LEDGER="${CAPACITY_HALT_AUTH_LEDGER:-$HOME/.local/state/flywheel/capacity-halt-pane-authorization-ledger.jsonl}"

# ---------- canonical-cli bash-side emitters (added by flywheel-k8gcv.5) ----------

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      required:["session","pane"],
      properties:{
        session:{type:"string"},
        pane:{type:"string",pattern:"^[0-9]+$"},
        tool:{type:"string",description:"agent tool name (e.g., codex)"},
        recovery_class:{enum:["credential_rotation"],description:"narrow recovery class — credential_rotation allows stale topology + protected pane operations"},
        primitive:{type:"string",description:"primitive id requesting authorization"},
        operation:{type:"string",description:"specific operation within recovery_class"},
        quiet:{type:"boolean",description:"emit text-only single-line outcome"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status"],
      properties:{
        schema_version:{type:"string"},
        status:{enum:["authorized","malformed","unknown_pane","protected_refusal","topology_stale"]},
        session:{type:"string"},
        pane:{type:"string"},
        role:{enum:["worker_pane","orchestrator","other","unknown"]},
        authorized:{type:"boolean"},
        authorization_outcome:{type:"string"},
        refusal_reason:{type:["string","null"]},
        topology_age_sec:{type:"integer"},
        topology_source_ts:{type:"string"}
      }
    },
    exit_codes:{
      "0":"authorized-worker-pane",
      "3":"malformed",
      "5":"protected-refusal",
      "6":"unknown-pane",
      "7":"topology-stale"
    }
  }'
}

emit_doctor() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local py_status="pass"; command -v python3 >/dev/null 2>&1 || py_status="fail"
  local topology_status="pass"
  if [[ ! -f "$TOPOLOGY" ]]; then
    topology_status="warn"
  fi
  local topology_dir; topology_dir="$(dirname "$TOPOLOGY")"
  [[ -d "$topology_dir" ]] || topology_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$py_status" "$topology_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg py_s "$py_status" \
    --arg topology_s "$topology_status" --arg topology "$TOPOLOGY" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    --argjson max_age "$MAX_AGE_SECONDS" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      max_age_seconds:$max_age,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"python3",status:$py_s,detail:"python3 required for authorization dispatch"},
        {name:"topology_file",status:$topology_s,path:$topology,detail:"session-topology.jsonl — source of truth for pane roles (warn if missing)"},
        {name:"audit_ledger",status:$ledger_s,path:$ledger,detail:"append-only audit ledger for authorization outcomes"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local row_count=0
  local topology_age=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
  fi
  if [[ -f "$TOPOLOGY" ]]; then
    local topology_mtime now_epoch
    topology_mtime="$(stat -f %m "$TOPOLOGY" 2>/dev/null || printf 0)"
    now_epoch="$(date +%s)"
    topology_age="$((now_epoch - topology_mtime))"
  fi
  local status="pass"
  if [[ -n "$topology_age" && "$topology_age" -gt "$MAX_AGE_SECONDS" ]]; then
    status="warn"
  fi
  if [[ ! -f "$TOPOLOGY" ]]; then
    status="warn"
  fi
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg topology "$TOPOLOGY" --arg ledger "$LEDGER" \
    --argjson row_count "${row_count:-0}" --arg topology_age "${topology_age:-}" \
    --argjson max_age "$MAX_AGE_SECONDS" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,topology_file:$topology,topology_age_sec:($topology_age | tonumber? // null),max_age_seconds:$max_age,audit_ledger:$ledger,audit_row_count:$row_count}'
}

emit_validate() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "" or (.status // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,audit_ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every audit row has non-empty schema_version + status"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",audit_ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,audit_ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|role-classification)
      body='Roles are derived from session-topology.jsonl: worker_pane = explicit codex/agent pane, orchestrator = pane 1 by convention, other = named-but-not-worker, unknown = pane id not present in topology. Only worker_pane authorizes (exit 0); orchestrator+other → protected_refusal (exit 5); unknown → unknown_pane (exit 6).'
      ;;
    topology-stale)
      body='topology_age_sec > max_age_seconds (default 3600) → exit 7 topology_stale UNLESS --recovery-class=credential_rotation is set, in which case stale topology is allowed because caam swaps need to run even when topology has not been refreshed.'
      ;;
    credential-rotation)
      body='Narrow exception for caam-auto-rotate-on-usage-limit primitive. Allowed ops: caam_activate_existing_profile (default), caam_status_post_check, append_recovery_ledger. Forbidden ops: pane_mutation, respawn, launchctl, new_credential_creation, token_rotation, oauth_refresh, vault_write. Stale topology is allowed (recovery may need to run on a halted fleet).'
      ;;
    *)
      body="unknown topic: $topic. known: role-classification, topology-stale, credential-rotation"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-role-classification}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"capacity-halt-pane-authorization.sh doctor --json"},
      {step:2,action:"probe-worker-pane",command:"capacity-halt-pane-authorization.sh --session flywheel --pane 3 --json"},
      {step:3,action:"credential-rotation-authorization",command:"capacity-halt-pane-authorization.sh --session flywheel --pane 2 --tool codex --recovery-class credential_rotation --json"},
      {step:4,action:"audit-recent-outcomes",command:"capacity-halt-pane-authorization.sh audit --json"}
    ],
    next_actions:["dispatch-capacity-halt-auto-continue-with-authorized-pane","tail-audit-ledger"]
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
      --help|-h) printf 'repair --scope <audit-ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (audit-ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    audit-ledger-prime)
      local ledger_dir present_before present_after
      ledger_dir="$(dirname "$LEDGER")"
      present_before="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$LEDGER" ]] || : > "$LEDGER"
      fi
      present_after="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER" --arg key "$idem_key" \
        --argjson before "$present_before" --argjson after "$present_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,audit_ledger:$ledger,ledger_present_before:$before,ledger_present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: audit-ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

case "${1:-}" in
  --schema) emit_schema; exit 0 ;;
  doctor) shift; emit_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
  validate) shift; emit_validate; exit 0 ;;
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

python3 - "$VERSION" "$TOPOLOGY" "$NOW_EPOCH" "$MAX_AGE_SECONDS" "$@" <<'PY'
import argparse, json, os, re, sys, time
from datetime import datetime, timezone
from pathlib import Path

VERSION, TOPOLOGY, NOW_RAW, MAX_AGE_RAW = sys.argv[1:5]
PANE_RE = re.compile(r"^[0-9]+$")
CREDENTIAL_ROTATION_CLASS = "credential_rotation"
CREDENTIAL_ROTATION_TOOL = "codex"
CREDENTIAL_ROTATION_PRIMITIVE = "caam-auto-rotate-on-usage-limit"
CREDENTIAL_ROTATION_DEFAULT_OPERATION = "caam_activate_existing_profile"
CREDENTIAL_ROTATION_AUTHORIZED_OPS = [
    "caam_activate_existing_profile",
    "caam_status_post_check",
    "append_recovery_ledger",
]
CREDENTIAL_ROTATION_FORBIDDEN_OPS = [
    "pane_mutation",
    "respawn",
    "launchctl",
    "new_credential_creation",
    "token_rotation",
    "oauth_refresh",
    "vault_write",
]

def parse_args():
    p = argparse.ArgumentParser(description="Authorize capacity-halt auto-continue for worker panes only.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--tool", default="")
    p.add_argument("--recovery-class", default="")
    p.add_argument("--primitive", default=CREDENTIAL_ROTATION_PRIMITIVE)
    p.add_argument("--operation", default=CREDENTIAL_ROTATION_DEFAULT_OPERATION)
    p.add_argument("--quiet", action="store_true")
    return p.parse_args(sys.argv[5:])

def now_epoch():
    return int(NOW_RAW or time.time())

def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    elif not args.quiet:
        print(f"capacity-halt-pane-authorization status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')} role={payload.get('role', '')}")
    raise SystemExit(rc)

def read_rows(path):
    rows = []
    for idx, line in enumerate(Path(path).read_text().splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"malformed_jsonl_line_{idx}:{exc}") from exc
        if isinstance(row, dict):
            rows.append(row)
    return rows

def latest_for_session(rows, session):
    candidates = [r for r in rows if str(r.get("session")) == session]
    if not candidates:
        return None
    return max(candidates, key=lambda r: str(r.get("effective_at") or r.get("ts") or ""))

def role_for_pane(row, pane):
    if str(row.get("orchestrator_pane")) == pane:
        return "orchestrator_pane"
    if str(row.get("human_pane")) == pane:
        return "human_pane"
    if str(row.get("callback_pane")) == pane:
        return "callback_pane"
    if pane in {str(p) for p in (row.get("worker_panes") or [])}:
        return "worker_pane"
    return "unknown"

def base(args, row=None, age=None):
    source_ts = (row or {}).get("effective_at") or (row or {}).get("ts")
    return {
        "schema_version": "capacity-halt-pane-authorization.result.v1",
        "version": VERSION,
        "session": args.session,
        "pane": args.pane,
        "topology_file": TOPOLOGY,
        "topology_source_ts": source_ts,
        "topology_age_sec": age,
        "read_only": True,
    }

def with_ledger(payload):
    payload["ledger_row"] = {
        "event": "capacity_halt_authorization",
        "session": payload.get("session"),
        "pane": int(payload["pane"]) if str(payload.get("pane", "")).isdigit() else payload.get("pane"),
        "authorized": payload.get("authorized"),
        "pane_role": payload.get("role"),
        "authorization_outcome": payload.get("authorization_outcome"),
        "topology_source_ts": payload.get("topology_source_ts"),
        "refusal_reason": payload.get("refusal_reason"),
    }
    return payload

def credential_rotation_fields(args, stale_allowed):
    return {
        "tool": args.tool,
        "recovery_class": args.recovery_class,
        "primitive": args.primitive,
        "operation": args.operation,
        "stale_topology_allowed": bool(stale_allowed),
        "authorized_operations": CREDENTIAL_ROTATION_AUTHORIZED_OPS,
        "forbidden_operations": CREDENTIAL_ROTATION_FORBIDDEN_OPS,
        "credential_secret_values_observed": 0,
    }

def credential_rotation_refusal(args, row=None, age=None, role="unknown", status="malformed", rc=3, reason="unsupported_credential_rotation_request", stale_allowed=False):
    return with_ledger(dict(
        base(args, row, age),
        status=status,
        role=role,
        authorized=False,
        authorization_outcome=status,
        refusal_reason=reason,
        **credential_rotation_fields(args, stale_allowed),
    )), rc

def validate_credential_rotation(args, row=None, age=None, role="unknown", stale_allowed=False):
    if args.recovery_class != CREDENTIAL_ROTATION_CLASS:
        return None
    if args.tool != CREDENTIAL_ROTATION_TOOL:
        return credential_rotation_refusal(args, row, age, role, reason="unsupported_tool_for_credential_rotation", stale_allowed=stale_allowed)
    if args.primitive != CREDENTIAL_ROTATION_PRIMITIVE:
        return credential_rotation_refusal(args, row, age, role, reason="unsupported_credential_rotation_primitive", stale_allowed=stale_allowed)
    if args.operation in CREDENTIAL_ROTATION_FORBIDDEN_OPS:
        return credential_rotation_refusal(args, row, age, role, status="protected_refusal", rc=5, reason="forbidden_operation", stale_allowed=stale_allowed)
    if args.operation not in CREDENTIAL_ROTATION_AUTHORIZED_OPS:
        return credential_rotation_refusal(args, row, age, role, reason="unsupported_credential_rotation_operation", stale_allowed=stale_allowed)
    return None

def credential_rotation_authorized(args, row, age, role, stale_allowed):
    return with_ledger(dict(
        base(args, row, age),
        status="authorized",
        role=role,
        authorized=True,
        authorization_outcome="authorized",
        refusal_reason=None,
        **credential_rotation_fields(args, stale_allowed),
    ))

def info(args):
    emit(args, {
        "schema_version": "capacity-halt-pane-authorization.info.v1",
        "command": "info",
        "name": "capacity-halt-pane-authorization",
        "version": VERSION,
        "topology_file": TOPOLOGY,
        "max_age_seconds": int(MAX_AGE_RAW),
        "verbs": ["--info", "--schema", "--help", "--examples", "--json", "--session", "--pane", "--tool", "--recovery-class", "--primitive", "--operation", "--quiet"],
        "subcommands": ["doctor", "health", "validate", "audit", "why", "repair", "quickstart"],
        "capabilities": [
            "role-classification-from-topology",
            "topology-staleness-gate",
            "narrow-credential-rotation-exception",
            "authorized-operation-allowlist",
            "audit-ledger-append"
        ],
        "apply_supported": False,
        "dry_run_supported": False,
        "idempotency_key_required_for_apply": False,
        "mutates_state": True,
        "env_vars": ["CAPACITY_HALT_AUTH_TOPOLOGY", "CAPACITY_HALT_AUTH_NOW_EPOCH", "CAPACITY_HALT_AUTH_MAX_AGE_SECONDS", "CAPACITY_HALT_AUTH_LEDGER"],
        "credential_rotation": {
            "tool": CREDENTIAL_ROTATION_TOOL,
            "recovery_class": CREDENTIAL_ROTATION_CLASS,
            "primitive": CREDENTIAL_ROTATION_PRIMITIVE,
            "authorized_operations": CREDENTIAL_ROTATION_AUTHORIZED_OPS,
            "forbidden_operations": CREDENTIAL_ROTATION_FORBIDDEN_OPS,
        },
        "exit_codes": {"0": "authorized-worker-pane", "3": "malformed", "5": "protected-refusal", "6": "unknown-pane", "7": "topology-stale"},
    }, 0)

def examples(args):
    emit(args, {
        "schema_version": "capacity-halt-pane-authorization.examples.v1",
        "command": "examples",
        "examples": [
            {"name": "worker", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 3 --json", "purpose": "probe worker pane authorization — exit 0 if topology lists pane as worker"},
            {"name": "quiet", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 1 --quiet", "purpose": "text-mode single-line outcome (no JSON)"},
            {"name": "credential_rotation", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 2 --tool codex --recovery-class credential_rotation --json", "purpose": "narrow exception: authorize caam swap operations on stale topology"},
            {"name": "doctor", "command": "capacity-halt-pane-authorization.sh doctor --json", "purpose": "verify jq, python3, topology file present, audit ledger writable"},
            {"name": "audit", "command": "capacity-halt-pane-authorization.sh audit --json", "purpose": "tail recent authorization outcomes"},
        ],
    }, 0)

def main():
    args = parse_args()
    if args.info:
        info(args)
    if args.examples:
        examples(args)
    if not args.session or not PANE_RE.match(args.pane):
        emit(args, dict(base(args), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason="session_and_numeric_pane_required"), 3)
    try:
        rows = read_rows(TOPOLOGY)
    except (OSError, ValueError) as exc:
        emit(args, dict(base(args), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason=str(exc)), 3)
    row = latest_for_session(rows, args.session)
    if row is None:
        emit(args, with_ledger(dict(base(args), status="unknown_pane", role="unknown", authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane")), 6)
    source_ts = row.get("effective_at") or row.get("ts")
    source_epoch = parse_ts(source_ts)
    if source_epoch is None:
        emit(args, with_ledger(dict(base(args, row), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason="missing_or_invalid_effective_at")), 3)
    age = max(0, now_epoch() - int(source_epoch))
    role = role_for_pane(row, args.pane)
    if age > int(MAX_AGE_RAW):
        if args.recovery_class == CREDENTIAL_ROTATION_CLASS:
            invalid = validate_credential_rotation(args, row, age, role, stale_allowed=True)
            if invalid:
                payload, rc = invalid
                emit(args, payload, rc)
            if role == "worker_pane":
                emit(args, credential_rotation_authorized(args, row, age, role, stale_allowed=True), 0)
            if role == "unknown":
                emit(args, with_ledger(dict(base(args, row, age), status="unknown_pane", role=role, authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane", **credential_rotation_fields(args, True))), 6)
            emit(args, with_ledger(dict(base(args, row, age), status="protected_refusal", role=role, authorized=False, authorization_outcome="protected_refusal", refusal_reason="protected", **credential_rotation_fields(args, True))), 5)
        emit(args, with_ledger(dict(base(args, row, age), status="topology_stale", role="unknown", authorized=False, authorization_outcome="topology_stale", refusal_reason="topology_stale")), 7)
    if args.recovery_class == CREDENTIAL_ROTATION_CLASS:
        invalid = validate_credential_rotation(args, row, age, role, stale_allowed=False)
        if invalid:
            payload, rc = invalid
            emit(args, payload, rc)
        if role == "worker_pane":
            emit(args, credential_rotation_authorized(args, row, age, role, stale_allowed=False), 0)
        if role == "unknown":
            emit(args, with_ledger(dict(base(args, row, age), status="unknown_pane", role=role, authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane", **credential_rotation_fields(args, False))), 6)
        emit(args, with_ledger(dict(base(args, row, age), status="protected_refusal", role=role, authorized=False, authorization_outcome="protected_refusal", refusal_reason="protected", **credential_rotation_fields(args, False))), 5)
    if role == "worker_pane":
        emit(args, with_ledger(dict(base(args, row, age), status="authorized", role=role, authorized=True, authorization_outcome="authorized", refusal_reason=None)), 0)
    if role == "unknown":
        emit(args, with_ledger(dict(base(args, row, age), status="unknown_pane", role=role, authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane")), 6)
    emit(args, with_ledger(dict(base(args, row, age), status="protected_refusal", role=role, authorized=False, authorization_outcome="protected_refusal", refusal_reason="protected")), 5)

if __name__ == "__main__":
    main()
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
