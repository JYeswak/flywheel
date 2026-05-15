#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/trauma-handoff.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/trauma-handoff-send.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/bin" "$TMP/repo/.flywheel/evidence" "$TMP/repo/.flywheel/state" "$TMP/tokens"

cat >"$TMP/repo/.flywheel/evidence/trauma-candidates.jsonl" <<'JSONL'
{"schema_version":"flywheel.trauma_candidate.v0","class":"coordination-collision-detected","fuckup_log_ref":"fuckup-log.jsonl#L10","recommended_skillos_loop":{"name":"coordination-collision","version":"v1"}}
JSONL

cat >"$TMP/bin/register" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
apply=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1; shift ;;
    --project-key) project_key="$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ "$apply" -eq 1 ]]; then
  printf 'sender-token' >"${TOKEN_PATH:?}"
  chmod 600 "$TOKEN_PATH"
  jq -nc --arg token_path "$TOKEN_PATH" --arg project_key "${project_key:-}" '{status:"registered",identity_name:"flywheel-1-orch",token_path:$token_path,project_key:$project_key,raw_token_in_output:false}'
else
  jq -nc --arg project_key "${project_key:-}" '{status:"planned",identity_name:"flywheel-1-orch",project_key:$project_key,raw_token_in_output:false}'
fi
SH
chmod +x "$TMP/bin/register"

cat >"$TMP/bin/curl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
payload=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) payload="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
printf '%s\n' "$payload" >>"${CURL_PAYLOAD_LOG:?}"
jq -nc '{result:{content:[{text:"{\"deliveries\":[{\"payload\":{\"id\":456}}],\"count\":1}"}]}}'
SH
chmod +x "$TMP/bin/curl"

base_env=(
  "TRAUMA_HANDOFF_REPO=$TMP/repo"
  "TRAUMA_HANDOFF_REGISTER_SCRIPT=$TMP/bin/register"
  "TRAUMA_HANDOFF_CURL=$TMP/bin/curl"
  "TRAUMA_HANDOFF_MCP_CONFIG=$TMP/missing-agent-mail-config.json"
  "TRAUMA_HANDOFF_PROJECT_KEY=$TMP/repo"
  "AGENTMAIL_HTTP_BEARER_TOKEN=http-token"
  "CURL_PAYLOAD_LOG=$TMP/curl-payloads.jsonl"
  "TOKEN_PATH=$TMP/tokens/flywheel-1-orch.token"
)

if bash -n "$SCRIPT"; then
  pass "script syntax"
else
  fail "script syntax"
fi

env "${base_env[@]}" "$SCRIPT" send-via-mcp-agent-mail --row-index 0 --to SkillOSReceiver --dry-run --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.status == "planned" and .recipient == "SkillOSReceiver" and .registration.status == "planned" and .raw_token_in_output == false' "dry-run plans send"
if [[ ! -e "$TMP/repo/.flywheel/state/skillos-relay-ledger.jsonl" && ! -e "$TMP/curl-payloads.jsonl" ]]; then
  pass "dry-run mutates nothing"
else
  fail "dry-run mutates nothing"
fi

env "${base_env[@]}" "$SCRIPT" send-via-mcp-agent-mail --row-index 0 --to SkillOSReceiver --json >"$TMP/sent.json"
assert_jq "$TMP/sent.json" '.status == "sent" and .message_id == 456 and .sender == "flywheel-1-orch" and .recipient == "SkillOSReceiver" and .raw_token_in_output == false' "send returns redacted success"
assert_jq "$TMP/curl-payloads.jsonl" '.params.name == "send_message" and .params.arguments.sender_name == "flywheel-1-orch" and .params.arguments.sender_token == "sender-token" and .params.arguments.to[0] == "SkillOSReceiver" and (.params.arguments.subject | test("coordination-collision-detected"))' "send payload includes sender token field"
assert_jq "$TMP/repo/.flywheel/state/skillos-relay-ledger.jsonl" 'select(.status == "ready_for_send_authorization")' "ledger preserves prepared row"
assert_jq "$TMP/repo/.flywheel/state/skillos-relay-ledger.jsonl" 'select(.status == "sent" and .skillos_handoff_message_id == "456" and .agent_mail_recipient == "SkillOSReceiver")' "ledger records sent row"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
