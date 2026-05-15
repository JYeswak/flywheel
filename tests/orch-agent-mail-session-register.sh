#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orch-agent-mail-session-register.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-am-register.XXXXXX")"
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

mkdir -p "$TMP/bin" "$TMP/state" "$TMP/project" "$TMP/config"
export TMP_PROJECT="$TMP/project"
export TMP_KEY="flywheel:1:$TMP/project"

cat >"$TMP/bin/flywheel-loop" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == *"--register"* ]]; then
  printf '%s\n' "$*" >>"${LOOP_REGISTER_LOG:?}"
  jq -nc --arg identity "${REGISTER_IDENTITY:-flywheel-1-orch}" --arg token_path "${REGISTER_TOKEN_PATH:?}" '{status:"active",identity_name:$identity,token_path:$token_path}'
  exit 0
fi
if [[ "${LOOP_ACTIVE:-0}" == "1" ]]; then
  jq -nc --arg token_path "${ACTIVE_TOKEN_PATH:?}" '{status:"active",identity_name:"ExistingOrch",token_path:$token_path}'
else
  jq -nc '{status:"needs_registration",identity_name:null,token_path:null}'
fi
SH
chmod +x "$TMP/bin/flywheel-loop"

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
text="$(jq -nc '{name:"flywheel-1-orch",registration_token:"test-registration-token"}')"
jq -nc --arg text "$text" '{result:{content:[{text:$text}]}}'
SH
chmod +x "$TMP/bin/curl"

base_env=(
  "HOME=$TMP/home"
  "PATH=$TMP/bin:$PATH"
  "FLYWHEEL_LOOP_BIN=$TMP/bin/flywheel-loop"
  "FLYWHEEL_AGENT_MAIL_STATE_DIR=$TMP/state/agent-mail"
  "FLYWHEEL_AGENT_MAIL_TOKEN_INDEX=$TMP/state/agent-mail-tokens.json"
  "FLYWHEEL_ORCH_AM_CURL=$TMP/bin/curl"
  "FLYWHEEL_ORCH_AM_MCP_CONFIG=$TMP/config/agent-mail.json"
  "AGENTMAIL_HTTP_BEARER_TOKEN=http-token"
  "CURL_PAYLOAD_LOG=$TMP/curl-payloads.jsonl"
  "LOOP_REGISTER_LOG=$TMP/loop-register.log"
  "REGISTER_TOKEN_PATH=$TMP/state/agent-mail/tokens/flywheel-1-orch.token"
)

if bash -n "$SCRIPT"; then
  pass "script syntax"
else
  fail "script syntax"
fi

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "orch-agent-mail-session-register" and .raw_token_in_output == false' "info redacts token"

env "${base_env[@]}" "$SCRIPT" --session flywheel --pane 1 --project-key "$TMP/project" --json >"$TMP/planned.json"
assert_jq "$TMP/planned.json" '.status == "planned" and .apply_required == true and .identity_name == "flywheel-1-orch" and .raw_token_in_output == false' "dry run plans registration"
if [[ ! -e "$TMP/curl-payloads.jsonl" ]]; then
  pass "dry run does not call mcp"
else
  fail "dry run does not call mcp"
fi

set +e
FLYWHEEL_ORCH_AM_REGISTER=0 env "${base_env[@]}" "$SCRIPT" --session flywheel --pane 1 --project-key "$TMP/project" --apply --json >"$TMP/disabled.json"
disabled_rc=$?
set -e
if [[ "$disabled_rc" == "3" ]]; then
  pass "disabled rc"
else
  fail "disabled rc=$disabled_rc"
fi
assert_jq "$TMP/disabled.json" '.status == "disabled" and .reason == "FLYWHEEL_ORCH_AM_REGISTER=0"' "disabled output"

env "${base_env[@]}" "$SCRIPT" --session flywheel --pane 1 --project-key "$TMP/project" --apply --json >"$TMP/registered.json"
assert_jq "$TMP/registered.json" '.status == "registered" and .identity_name == "flywheel-1-orch" and .raw_token_in_output == false and (.token_sha256 | length == 64)' "apply registers without raw token"
assert_jq "$TMP/curl-payloads.jsonl" '.params.name == "register_agent" and .params.arguments.name == "flywheel-1-orch" and .params.arguments.project_key == env.TMP_PROJECT' "mcp register payload"
if [[ "$(cat "$TMP/state/agent-mail/tokens/flywheel-1-orch.token")" == "test-registration-token" ]]; then
  pass "token vault written"
else
  fail "token vault written"
fi
mode="$(stat -f '%Lp' "$TMP/state/agent-mail/tokens/flywheel-1-orch.token")"
if [[ "$mode" == "600" ]]; then
  pass "token vault mode 600"
else
  fail "token vault mode=$mode"
fi
assert_jq "$TMP/state/agent-mail-tokens.json" '.[env.TMP_KEY].raw_token_stored == false and .[env.TMP_KEY].token_path != null and .[env.TMP_KEY].token_sha256 != null' "compat index stores token metadata only"
if grep -F -- '--register' "$TMP/loop-register.log" >/dev/null; then
  pass "loop identity registry updated"
else
  fail "loop identity registry updated"
fi

rm -f "$TMP/curl-payloads.jsonl"
existing_token="$TMP/existing.token"
printf 'existing-token' >"$existing_token"
chmod 600 "$existing_token"
LOOP_ACTIVE=1 ACTIVE_TOKEN_PATH="$existing_token" env "${base_env[@]}" "$SCRIPT" --session flywheel --pane 1 --project-key "$TMP/project" --apply --json >"$TMP/existing.json"
assert_jq "$TMP/existing.json" '.status == "already_registered" and .identity_name == "ExistingOrch" and .raw_token_in_output == false' "existing identity short circuits"
if [[ ! -e "$TMP/curl-payloads.jsonl" ]]; then
  pass "existing identity avoids mcp call"
else
  fail "existing identity avoids mcp call"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
