#!/usr/bin/env bash
set -euo pipefail

VERSION="skillos-template-handshake/v1"
REQ_SCHEMA="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/validation-schema/v1/skillos-template-handshake-request.schema.json"
ACK_SCHEMA="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/validation-schema/v1/skillos-template-handshake-ack.schema.json"
LEDGER="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
JSON_OUT=0 QUIET=0 CMD="" SKILLS="" TTL="" TIMEOUT=30 KEY="" INPUT_JSON=""
PRODUCER_VERSION_REQUIRED="${SKILLOS_TEMPLATE_PRODUCER_VERSION_REQUIRED:-skillos-skill-injection-template/v1}"
TEMPLATE_CLASS="${SKILLOS_TEMPLATE_CLASS:-skill-injection-template}"
REQUESTOR_ORCH="${SKILLOS_TEMPLATE_REQUESTOR_ORCH:-flywheel:1}"
REQUESTOR_SESSION="${SKILLOS_TEMPLATE_REQUESTOR_SESSION:-flywheel}" DISPATCH_TARGET_BEAD_ID=""

usage() {
  cat <<'USAGE'
usage: skillos-template-handshake.sh request|await-ack|validate-request|validate-ack [options]
       skillos-template-handshake.sh --info|--help|--examples [--json]
USAGE
}

info() {
  jq -nc --arg version "$VERSION" '{
    name:"skillos-template-handshake",
    schema_version:$version,
    subcommands:["request","await-ack","validate-request","validate-ack"],
    canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
    states:["success","stale","unavailable","duplicate"],
    ledger_env:"SKILLOS_TEMPLATE_HANDSHAKE_LEDGER"
  }'
}

examples() {
  jq -nc '{examples:[
    "skillos-template-handshake.sh request --skills agent-mail,socraticode --ttl-sec 900 --json",
    "skillos-template-handshake.sh await-ack --idempotency-key sha256:... --timeout-sec 60 --json",
    "skillos-template-handshake.sh validate-request --json '\''{\"idempotency_key\":\"req-001\",...}'\''",
    "skillos-template-handshake.sh validate-ack --json '\''{\"idempotency_key\":\"req-001\",...}'\''"
  ]}'
}

emit() {
  local payload="$1"
  [[ "$QUIET" -eq 1 ]] && return
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"command=\(.command // "info") state=\(.state // .status // "ok")"' <<<"$payload"
  fi
}

sha256() { shasum -a 256 | awk '{print "sha256:" $1}'; }

validate_payload() {
  local schema="$1" payload="$2"
  python3 - "$schema" "$payload" <<'PY'
import json
import sys
from jsonschema import Draft202012Validator

schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.loads(sys.argv[2])
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)
PY
}

iso_add() {
  python3 - "$1" "$2" <<'PY'
from datetime import datetime, timedelta, timezone
import sys
base = datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00"))
print((base + timedelta(seconds=int(sys.argv[2]))).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

skills_json() { printf '%s' "$SKILLS" | jq -Rsc 'split(",") | map(gsub("^ +| +$";"")) | map(select(length > 0))'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    request|await-ack|validate-request|validate-ack) CMD="$1"; shift ;;
    --skills) SKILLS="${2:?--skills requires LIST}"; shift 2 ;;
    --skills=*) SKILLS="${1#*=}"; shift ;;
    --ttl-sec) TTL="${2:?--ttl-sec requires N}"; shift 2 ;;
    --ttl-sec=*) TTL="${1#*=}"; shift ;;
    --timeout-sec) TIMEOUT="${2:?--timeout-sec requires N}"; shift 2 ;;
    --timeout-sec=*) TIMEOUT="${1#*=}"; shift ;;
    --idempotency-key) KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) KEY="${1#*=}"; shift ;;
    --producer-version-required|--producer-version) PRODUCER_VERSION_REQUIRED="${2:?--producer-version requires value}"; shift 2 ;;
    --template-class) TEMPLATE_CLASS="${2:?--template-class requires value}"; shift 2 ;;
    --requestor-orch) REQUESTOR_ORCH="${2:?--requestor-orch requires value}"; shift 2 ;;
    --requestor-session) REQUESTOR_SESSION="${2:?--requestor-session requires value}"; shift 2 ;;
    --dispatch-target-bead-id) DISPATCH_TARGET_BEAD_ID="${2:?--dispatch-target-bead-id requires value}"; shift 2 ;;
    --ledger) LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --json)
      if [[ "$CMD" == validate-* && $# -gt 1 && "$2" != --* ]]; then
        INPUT_JSON="$2"; JSON_OUT=1; shift 2
      else
        JSON_OUT=1; shift
      fi ;;
    --input-json) INPUT_JSON="${2:?--input-json requires JSON}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$CMD" ]] || { usage >&2; exit 2; }

case "$CMD" in
  validate-request|validate-ack)
    [[ -n "$INPUT_JSON" ]] || INPUT_JSON="$(cat)"
    schema="$REQ_SCHEMA"; [[ "$CMD" == validate-ack ]] && schema="$ACK_SCHEMA"
    if validate_payload "$schema" "$INPUT_JSON"; then
      emit "$(jq -nc --arg version "$VERSION" --arg command "$CMD" '{schema_version:$version,command:$command,status:"pass"}')"
    else
      emit "$(jq -nc --arg version "$VERSION" --arg command "$CMD" '{schema_version:$version,command:$command,status:"fail"}')"
      exit 1
    fi
    ;;
  request)
    [[ -n "$SKILLS" && -n "$TTL" ]] || { usage >&2; exit 2; }
    [[ "$TTL" =~ ^[0-9]+$ && "$TTL" -gt 0 ]] || { printf 'ERR --ttl-sec must be positive integer\n' >&2; exit 2; }
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    [[ -n "$KEY" ]] || KEY="$(printf '%s|%s|%s|%s\n' "$SKILLS" "$TTL" "$PRODUCER_VERSION_REQUIRED" "$ts" | sha256)"
    if [[ -f "$LEDGER" ]] && jq -e --arg key "$KEY" 'select(.type=="skillos_template_handshake_request" and .idempotency_key==$key)' "$LEDGER" >/dev/null; then
      emit "$(jq -nc --arg version "$VERSION" --arg key "$KEY" '{schema_version:$version,command:"request",state:"duplicate",idempotency_key:$key,ledger_written:false}')"
      exit 0
    fi
    row="$(jq -nc --arg sv "skillos-template-handshake-request/v1" --arg type "skillos_template_handshake_request" \
      --arg key "$KEY" --arg producer "$PRODUCER_VERSION_REQUIRED" --arg class "$TEMPLATE_CLASS" \
      --argjson skills "$(skills_json)" --argjson ttl "$TTL" --arg orch "$REQUESTOR_ORCH" \
      --arg session "$REQUESTOR_SESSION" --arg ts "$ts" --arg expires "$(iso_add "$ts" "$TTL")" \
      --arg bead "$DISPATCH_TARGET_BEAD_ID" \
      '{schema_version:$sv,type:$type,idempotency_key:$key,producer_version_required:$producer,requested_template_class:$class,requested_skills:$skills,ttl_seconds:$ttl,requestor_orch:$orch,requestor_session:$session,requested_at:$ts,request_expires_at:$expires} + (if $bead == "" then {} else {dispatch_target_bead_id:$bead} end)')"
    validate_payload "$REQ_SCHEMA" "$row"
    mkdir -p "$(dirname "$LEDGER")"
    printf '%s\n' "$row" >>"$LEDGER"
    emit "$(jq -nc --arg version "$VERSION" --arg ledger "$LEDGER" --argjson row "$row" '{schema_version:$version,command:"request",state:"requested",ledger_written:true,ledger:$ledger,request:$row}')"
    ;;
  await-ack)
    [[ -n "$KEY" && "$TIMEOUT" =~ ^[0-9]+$ ]] || { usage >&2; exit 2; }
    deadline=$((SECONDS + TIMEOUT))
    while :; do
      set +e
      payload="$(python3 - "$LEDGER" "$KEY" "$PRODUCER_VERSION_REQUIRED" <<'PY'
import json
import sys
from datetime import datetime, timedelta, timezone

ledger, key, default_required = sys.argv[1:4]
rows = []
try:
    with open(ledger, encoding="utf-8") as handle:
        rows = [json.loads(line) for line in handle if line.strip()]
except FileNotFoundError:
    pass
reqs = [r for r in rows if r.get("type") == "skillos_template_handshake_request" and r.get("idempotency_key") == key]
acks = [r for r in rows if r.get("type") == "skillos_template_handshake_ack" and r.get("idempotency_key") == key]
mismatched_acks = [r for r in rows if r.get("type") == "skillos_template_handshake_ack" and r.get("idempotency_key") != key]
now = datetime.now(timezone.utc)
base = {"schema_version":"skillos-template-handshake/v1","command":"await-ack","idempotency_key":key}
if len(reqs) > 1:
    print(json.dumps(base | {"state":"duplicate","degraded_fallback":{"reason":"duplicate_request_rows","safe_to_continue":False,"fallback_state":"duplicate"}})); raise SystemExit(0)
if reqs:
    req = reqs[-1]
    required = req.get("producer_version_required") or default_required
    requested_at = datetime.fromisoformat(req["requested_at"].replace("Z", "+00:00"))
    expires_at = requested_at + timedelta(seconds=int(req["ttl_seconds"]))
    if acks:
        ack = acks[-1]
        state = ack.get("state", "unavailable")
        if ack.get("producer_version_provided") != required:
            print(json.dumps(base | {"state":"unavailable","producer_version_provided":ack.get("producer_version_provided"),"producer_version_required":required,"degraded_fallback":{"reason":"producer_version_mismatch","safe_to_continue":False,"fallback_state":"unavailable"}})); raise SystemExit(0)
        print(json.dumps(base | {"state":state,"ack":ack})); raise SystemExit(0)
    if now > expires_at:
        print(json.dumps(base | {"state":"stale","degraded_fallback":{"reason":"ttl_expired_before_ack","safe_to_continue":False,"fallback_state":"stale"}})); raise SystemExit(0)
    if mismatched_acks:
        print(json.dumps(base | {"state":"unavailable","degraded_fallback":{"reason":"ack_idempotency_key_mismatch_or_missing","safe_to_continue":False,"fallback_state":"unavailable"}})); raise SystemExit(0)
print(json.dumps(base | {"state":"pending"}))
raise SystemExit(2)
PY
)"
      rc=$?
      set -e
      if [[ "$rc" -eq 0 ]]; then
        emit "$payload"; exit 0
      fi
      if (( SECONDS >= deadline )); then
        emit "$(jq -nc --arg version "$VERSION" --arg key "$KEY" '{schema_version:$version,command:"await-ack",idempotency_key:$key,state:"unavailable",degraded_fallback:{reason:"ack_timeout",safe_to_continue:false,fallback_state:"unavailable"}}')"
        exit 0
      fi
      sleep 1
    done
    ;;
esac
