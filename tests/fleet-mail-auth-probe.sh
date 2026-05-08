#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/fleet-mail-auth-probe.sh"
FIXTURE="$ROOT/.flywheel/fixtures/fleet-mail-auth-probe.jsonl"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-mail-auth-probe.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

pass() { printf 'PASS %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_identity() {
  local session="$1" pane="$2" identity="$3" token_value="$4"
  local token="$TMP/agent-mail/tokens/$identity.token"
  mkdir -p "$TMP/agent-mail/sessions" "$TMP/agent-mail/tokens"
  printf '%s\n' "$token_value" >"$token"
  chmod 600 "$token"
  jq -nc \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg identity "$identity" \
    --arg token "$token" \
    --arg project "/Users/josh/.local/state/flywheel/fleet-mail-project" \
    '{schema_version:"agent-mail-identity-registry/v2",session:$session,pane:$pane,role:"orch",identity_name:$identity,token_path:$token,status:"active",identity_resolved:true,fleet_mail_project_key:$project}' \
    >"$TMP/agent-mail/sessions/$session:$pane.json"
}

write_identity_missing_token() {
  local session="$1" pane="$2" identity="$3" token
  token="$TMP/agent-mail/tokens/$identity.token"
  mkdir -p "$TMP/agent-mail/sessions" "$TMP/agent-mail/tokens"
  jq -nc \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg identity "$identity" \
    --arg token "$token" \
    --arg project "/Users/josh/.local/state/flywheel/fleet-mail-project" \
    '{schema_version:"agent-mail-identity-registry/v2",session:$session,pane:$pane,role:"orch",identity_name:$identity,token_path:$token,status:"active",identity_resolved:true,fleet_mail_project_key:$project}' \
    >"$TMP/agent-mail/sessions/$session:$pane.json"
}

write_mcp_probe() {
  cat >"$TMP/mcp-probe" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$(cat "${FLEET_MAIL_AUTH_TOKEN_PATH:?}")" in
  valid-token)
    jq -nc --arg identity "$FLEET_MAIL_AUTH_IDENTITY" '{status:"ok",authenticated:true,agent_name:$identity,message_id:"fixture-message"}'
    ;;
  invalid-token)
    jq -nc '{status:"fail",authenticated:false,code:"invalid_token"}'
    exit 2
    ;;
  *)
    jq -nc '{status:"fail",authenticated:false,code:"unknown_fixture_token"}'
    exit 2
    ;;
esac
SH
  chmod +x "$TMP/mcp-probe"
}

base_args=(
  --agent-mail-dir "$TMP/agent-mail"
  --token-vault "$TMP/fleet-mail-tokens"
  --topology "$TMP/topology.jsonl"
  --fixtures "$FIXTURE"
  --mcp-probe "$TMP/mcp-probe"
  --json
)

mkdir -p "$TMP/fleet-mail-tokens"
write_mcp_probe

bash -n "$BIN" && pass "script_syntax" || fail "script_syntax"
jq empty "$FIXTURE" && pass "fixture_jsonl_valid" || fail "fixture_jsonl_valid"

"$BIN" --info --json --fixtures "$FIXTURE" >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "fleet-mail-auth-probe.sh" and .read_only == true and (.canonical_cli_surfaces | index("--doctor"))' "info_surface"

"$BIN" --schema --json --fixtures "$FIXTURE" >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.fixed_project_key == "/Users/josh/.local/state/flywheel/fleet-mail-project" and (.failure_classes | index("fleet_mail_identity_invalid_or_missing"))' "schema_surface"

for mode in doctor health validate audit; do
  "$BIN" "--$mode" --json --fixtures "$FIXTURE" >"$TMP/$mode.json"
  assert_jq "$TMP/$mode.json" '.status == "ok" and (.fixture_cases | length) == 5' "${mode}_surface"
done

"$BIN" --why --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.status == "ok" and (.reason | test("authenticated Agent Mail"))' "why_surface"

if "$BIN" --repair --json >"$TMP/repair.json"; then
  fail "repair_refuses"
else
  assert_jq "$TMP/repair.json" '.status == "refused" and .read_only == true and .apply == false' "repair_refuses"
fi

write_identity valid 1 ValidPond valid-token
"$BIN" "${base_args[@]}" --session valid --pane 1 >"$TMP/valid.json"
assert_jq "$TMP/valid.json" '.status == "pass" and .ready == true and .project_key == "/Users/josh/.local/state/flywheel/fleet-mail-project"' "valid_authenticated_identity"
assert_jq "$TMP/valid.json" '.l61.vault_token_validated == true and .l61_gate.would_count_as_success == true and .l61.l61_pairing_status == "authenticated"' "valid_counts_as_l61_success"

write_identity invalid 1 InvalidPond invalid-token
if "$BIN" "${base_args[@]}" --session invalid --pane 1 >"$TMP/invalid.json"; then
  fail "invalid_token_fails"
else
  assert_jq "$TMP/invalid.json" '.status == "fail" and (.failure_classes | index("fleet_mail_token_invalid")) and .l61_gate.would_count_as_success == false' "invalid_token_fails"
fi

write_identity_missing_token no-token 1 MissingTokenPond
if "$BIN" "${base_args[@]}" --session no-token --pane 1 >"$TMP/no-token.json"; then
  fail "missing_token_fails"
else
  assert_jq "$TMP/no-token.json" '.status == "fail" and (.failure_classes | index("fleet_mail_token_missing")) and .l61.vault_token_validated == false' "missing_token_fails"
fi

if "$BIN" "${base_args[@]}" --session missing-identity --pane 1 >"$TMP/missing-identity.json"; then
  fail "missing_identity_fails"
else
  assert_jq "$TMP/missing-identity.json" '.status == "fail" and .fleet_mail_identity_invalid_or_missing == true and (.failure_classes | index("fleet_mail_identity_invalid_or_missing"))' "missing_identity_fails"
fi

write_identity mcp-down 1 DownPond valid-token
if "$BIN" "${base_args[@]/$TMP\/mcp-probe/$TMP\/missing-mcp-probe}" --session mcp-down --pane 1 >"$TMP/mcp-down.json"; then
  fail "mcp_unavailable_fails"
else
  assert_jq "$TMP/mcp-down.json" '.status == "fail" and (.failure_classes | index("agent_mail_mcp_unavailable")) and .l61_gate.would_count_as_success == false' "mcp_unavailable_fails"
fi

if grep -R -F 'valid-token' "$TMP"/*.json >/dev/null || grep -R -F 'invalid-token' "$TMP"/*.json >/dev/null; then
  fail "token_values_redacted"
else
  pass "token_values_redacted"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
