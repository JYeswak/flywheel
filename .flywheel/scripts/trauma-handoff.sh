#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (info/schema/examples + prepare/send/doctor/health)
#
# trauma-handoff.sh — hand a trauma-candidate row to skillos via Agent Mail.
#
# Closes P3 of substrate-compounding-v2 (FCLA W2). Reads a row from
# .flywheel/evidence/trauma-candidates.jsonl, builds a packet per
# flywheel-trauma-handoff-request/v1 schema, appends to
# .flywheel/state/skillos-relay-ledger.jsonl, and either prints the AM
# command (operator-fires) or sends via available mechanism.
#
# Default mode is `prepare` (no send). Send requires explicit --send +
# external Agent Mail credentials. Cross-orch traffic is operator-
# authorization-class.
#
# Schema: flywheel-trauma-handoff-request/v1
# Disable via env: FLYWHEEL_TRAUMA_HANDOFF=0
#
# Exit codes:
#   0  packet prepared (or sent)
#   1  I/O error / missing inputs
#   2  usage error
#   3  handoff disabled via env
#   4  schema validation failure

set -euo pipefail

VERSION="trauma-handoff.v0.1.0"
SCHEMA_VERSION="flywheel-trauma-handoff-request/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${TRAUMA_HANDOFF_REPO:-$REPO_DEFAULT}"
CANDIDATES_PATH="${TRAUMA_HANDOFF_CANDIDATES:-$REPO_ROOT/.flywheel/evidence/trauma-candidates.jsonl}"
LEDGER_PATH="${TRAUMA_HANDOFF_LEDGER:-$REPO_ROOT/.flywheel/state/skillos-relay-ledger.jsonl}"
TTL_SECONDS="${TRAUMA_HANDOFF_TTL:-86400}"

if [[ "${FLYWHEEL_TRAUMA_HANDOFF:-1}" == "0" ]]; then
  printf '{"status":"disabled","reason":"FLYWHEEL_TRAUMA_HANDOFF=0"}\n'
  exit 3
fi

usage() {
  cat <<EOF
usage:
  trauma-handoff.sh prepare [--row-index N] [--all] [--json]
  trauma-handoff.sh send-via-mcp-agent-mail [--row-index N] [--dry-run] [--json]
  trauma-handoff.sh doctor|health [--json]
  trauma-handoff.sh --info|--schema|--examples [--json]
  trauma-handoff.sh --help|-h

Reads trauma-candidates.jsonl rows and builds skillos handoff packets.
Default mode (prepare) writes packets to ledger + prints the AM command.
Actual cross-orch send is operator-authorization-class; uses MCP Agent Mail.

Env overrides:
  TRAUMA_HANDOFF_CANDIDATES  default <repo>/.flywheel/evidence/trauma-candidates.jsonl
  TRAUMA_HANDOFF_LEDGER      default <repo>/.flywheel/state/skillos-relay-ledger.jsonl
  TRAUMA_HANDOFF_TTL         default 86400 (24h)
  FLYWHEEL_TRAUMA_HANDOFF=0  disable entirely
EOF
}

emit_info() {
  cat <<JSON
{
  "name": "trauma-handoff",
  "version": "$VERSION",
  "schema_version": "$SCHEMA_VERSION",
  "purpose": "Hand trauma-candidate rows to skillos via Agent Mail (FCLA W2)",
  "subcommands": ["prepare", "send-via-mcp-agent-mail", "doctor", "health"],
  "canonical_cli_flags": ["--info", "--schema", "--examples", "--json", "--help"],
  "mutates_state": "appends to <ledger> + prints AM command (or sends if authorized)",
  "default_mode": "prepare (no send)",
  "send_authorization_class": "operator-must-fire-AM-explicitly"
}
JSON
}

emit_schema() {
  cat <<JSON
{
  "schema_version": "$SCHEMA_VERSION",
  "request_schema_path": ".flywheel/validation-schema/v1/trauma-handoff-request.schema.json",
  "input_schema": {
    "candidates_jsonl": ".flywheel/evidence/trauma-candidates.jsonl (flywheel.trauma_candidate.v0)"
  },
  "output_schema": {
    "ledger_jsonl": ".flywheel/state/skillos-relay-ledger.jsonl",
    "row_shape": "{ts, idempotency_key, trauma_class, target_session, packet_path, am_command, status}"
  }
}
JSON
}

emit_examples() {
  cat <<JSON
{
  "examples": [
    {
      "name": "prepare a single handoff packet from row 0",
      "command": ".flywheel/scripts/trauma-handoff.sh prepare --row-index 0 --json"
    },
    {
      "name": "prepare all unsent candidate handoffs",
      "command": ".flywheel/scripts/trauma-handoff.sh prepare --all --json"
    }
  ]
}
JSON
}

emit_doctor() {
  local checks=()
  local status="ok"
  if [[ -f "$CANDIDATES_PATH" ]]; then
    local n; n="$(wc -l <"$CANDIDATES_PATH" | tr -d ' ')"
    checks+=("$(printf '{"check":"candidates_exist","ok":true,"path":"%s","row_count":%s}' "$CANDIDATES_PATH" "$n")")
  else
    checks+=("$(printf '{"check":"candidates_exist","ok":false,"path":"%s"}' "$CANDIDATES_PATH")")
    status="fail"
  fi
  local ledger_dir; ledger_dir="$(dirname "$LEDGER_PATH")"
  if [[ -d "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    checks+=("$(printf '{"check":"ledger_dir_writable","ok":true,"path":"%s"}' "$ledger_dir")")
  else
    checks+=("$(printf '{"check":"ledger_dir_writable","ok":false,"path":"%s"}' "$ledger_dir")")
    status="fail"
  fi
  if command -v jq >/dev/null 2>&1; then
    checks+=('{"check":"jq_available","ok":true}')
  else
    checks+=('{"check":"jq_available","ok":false}')
    status="fail"
  fi
  printf '{"command":"doctor","status":"%s","checks":[%s]}\n' "$status" "$(IFS=,; echo "${checks[*]}")"
  [[ "$status" == "fail" ]] && return 1 || return 0
}

build_packet() {
  # Take one trauma-candidate row (JSON on stdin), produce a handoff request packet.
  local row="$1"
  local class; class="$(echo "$row" | jq -r '.class')"
  local fuckup_ref; fuckup_ref="$(echo "$row" | jq -r '.fuckup_log_ref')"
  local recommended_loop; recommended_loop="$(echo "$row" | jq -r '.recommended_skillos_loop')"
  local idem; idem="sha256:$(printf '%s|%s' "$class" "$fuckup_ref" | shasum -a 256 | awk '{print $1}')"
  local now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg idem "$idem" \
    --argjson row "$row" \
    --arg requestor_orch "flywheel:1" \
    --arg requestor_session "flywheel" \
    --arg requested_at "$now" \
    --argjson ttl "$TTL_SECONDS" \
    --argjson target_loop "$recommended_loop" \
    '{
      schema_version: $schema,
      type: "trauma_handoff_request",
      idempotency_key: $idem,
      trauma_candidate: $row,
      requestor_orch: $requestor_orch,
      requestor_session: $requestor_session,
      requested_at: $requested_at,
      ttl_seconds: $ttl,
      target_skillos_loop: $target_loop
    }'
}

write_ledger_row() {
  local packet="$1"
  local class; class="$(echo "$packet" | jq -r '.trauma_candidate.class')"
  local idem; idem="$(echo "$packet" | jq -r '.idempotency_key')"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  mkdir -p "$(dirname "$LEDGER_PATH")"
  local row
  row="$(jq -nc \
    --arg ts "$ts" \
    --arg idem "$idem" \
    --arg class "$class" \
    --arg target "skillos:1" \
    --argjson packet "$packet" \
    '{
      schema_version: "flywheel-skillos-relay-ledger/v1",
      ts: $ts,
      idempotency_key: $idem,
      trauma_class: $class,
      target_session: $target,
      packet: $packet,
      status: "ready_for_send_authorization",
      skillos_handoff_message_id: null
    }')"
  echo "$row" >>"$LEDGER_PATH"
  echo "$idem"
}

print_am_command() {
  local packet="$1"
  local body; body="$(echo "$packet" | jq -c '.')"
  local class; class="$(echo "$packet" | jq -r '.trauma_candidate.class')"
  cat <<EOF
# Operator command to send (MCP Agent Mail):
#
#   mcp__mcp-agent-mail__send_message \\
#     --recipient_session=skillos \\
#     --subject="trauma_handoff: $class" \\
#     --body=<see packet above>
#
# Or via shell wrapper (if installed):
#   ~/.local/bin/agent-mail send --to=skillos --subject "trauma_handoff: $class" --body-stdin <<'EOFBODY'
$body
EOFBODY
EOF
}

cmd_prepare() {
  local row_index=0 do_all=0 json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-index) row_index="$2"; shift 2 ;;
      --all) do_all=1; shift ;;
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  [[ -f "$CANDIDATES_PATH" ]] || { printf 'candidates not found: %s\n' "$CANDIDATES_PATH" >&2; return 1; }

  if [[ "$do_all" -eq 1 ]]; then
    local idems=()
    while IFS= read -r row; do
      [[ -z "$row" ]] && continue
      local packet; packet="$(build_packet "$row")"
      local idem; idem="$(write_ledger_row "$packet")"
      idems+=("$idem")
    done <"$CANDIDATES_PATH"
    if [[ "$json_out" -eq 1 ]]; then
      printf '{"status":"prepared","count":%d,"ledger":"%s","idempotency_keys":%s}\n' "${#idems[@]}" "$LEDGER_PATH" "$(printf '%s\n' "${idems[@]}" | jq -R . | jq -s .)"
    else
      printf 'PREPARED %d packets → ledger: %s\n' "${#idems[@]}" "$LEDGER_PATH"
    fi
  else
    local row; row="$(sed -n "$((row_index + 1))p" "$CANDIDATES_PATH")"
    [[ -z "$row" ]] && { printf 'no row at index %d\n' "$row_index" >&2; return 1; }
    local packet; packet="$(build_packet "$row")"
    local idem; idem="$(write_ledger_row "$packet")"
    if [[ "$json_out" -eq 1 ]]; then
      printf '{"status":"prepared","row_index":%d,"idempotency_key":"%s","ledger":"%s"}\n' "$row_index" "$idem" "$LEDGER_PATH"
      echo "$packet" | jq '.'
    else
      printf 'PREPARED row %d → idem %s → ledger %s\n' "$row_index" "$idem" "$LEDGER_PATH"
      print_am_command "$packet"
    fi
  fi
}

main() {
  case "${1:-}" in
    --info) shift; emit_info ;;
    --schema) shift; emit_schema ;;
    --examples) shift; emit_examples ;;
    --help|-h|"") usage ;;
    prepare) shift; cmd_prepare "$@" ;;
    send-via-mcp-agent-mail)
      printf '{"status":"not_implemented","reason":"cross-orch send is operator-authorization-class; use prepare + manual fire"}\n'
      return 2
      ;;
    doctor|health) shift; emit_doctor ;;
    *) printf 'unknown subcommand: %s\n' "$1" >&2; usage >&2; return 2 ;;
  esac
}

main "$@"
