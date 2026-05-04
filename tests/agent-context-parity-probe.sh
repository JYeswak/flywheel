#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/agent-context-parity-probe.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-context-parity.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

make_tool() {
  local bin_dir="$TMP/bin"
  mkdir -p "$bin_dir"
  cat >"$bin_dir/b11tool" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  --version) printf 'b11tool 1.0.0\n' ;;
  --help) printf 'B11 fixture parity tool\n' ;;
  *) printf 'b11tool smoke\n' ;;
esac
SH
  chmod +x "$bin_dir/b11tool"
  printf '%s\n' "$bin_dir"
}

make_fake_ntm() {
  local mode="$1"
  local ntm="$TMP/ntm-$mode"
  cat >"$ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
mode="${FAKE_NTM_MODE:-pass}"
if [[ "${1:-}" == "send" ]]; then
  printf '{"success":true,"delivered":1}\n'
  exit 0
fi
if [[ "${1:-}" == "logs" ]]; then
  if [[ "$mode" == "pass" ]]; then
    printf 'PARITY_PROBE_RESULT {"runtime":"codex","status":"responsive","command":"b11tool","found":true,"command_v":"%s/b11tool","realpath":"%s/b11tool","version":"b11tool 1.0.0","smoke_ok":true}\n' "$FAKE_BIN_DIR" "$FAKE_BIN_REAL"
  elif [[ "$mode" == "fail" ]]; then
    printf 'PARITY_PROBE_RESULT {"runtime":"codex","status":"responsive","command":"b11tool","found":false,"command_v":null,"realpath":null,"version":null,"smoke_ok":false}\n'
  else
    printf 'no callback yet\n'
  fi
  exit 0
fi
printf '{}\n'
SH
  chmod +x "$ntm"
  printf '%s\n' "$ntm"
}

write_agent_callback() {
  local path="$1" found="$2" smoke="$3"
  jq -nc \
    --argjson found "$found" \
    --argjson smoke "$smoke" \
    '{runtime:"codex",status:"responsive",command:"b11tool",found:$found,command_v:null,realpath:null,version:null,smoke_ok:$smoke,probe_transport:"fixture",callback_received:true}' \
    >"$path"
}

bin_dir="$(make_tool)"
bin_real="$(cd "$bin_dir" && pwd -P)"
export PATH="$bin_dir:$PATH"
export FAKE_BIN_DIR="$bin_dir"
export FAKE_BIN_REAL="$bin_real"

schema_check="$TMP/schema-check.json"
jq -n \
  --argjson runtime_has_agent "$(jq '.properties.runtime_context.required | index("agent_context") != null' "$ROOT/.flywheel/validation-schema/v1/schema.json")" \
  --argjson runtime_has_orch "$(jq '.properties.runtime_context.required | index("orchestrator_shell_context") != null' "$ROOT/.flywheel/validation-schema/v1/schema.json")" \
  '{runtime_has_agent:$runtime_has_agent,runtime_has_orchestrator:$runtime_has_orch}' >"$schema_check"
assert_jq "$schema_check" '.runtime_has_agent == true and .runtime_has_orchestrator == true' "B11_AG1 schema separates agent and orchestrator contexts"

fake_ntm="$(make_fake_ntm pass)"
codex_pass="$TMP/codex-pass.json"
FAKE_NTM_MODE=pass python3 "$PROBE" --repo "$ROOT" --runtime codex --session flywheel --pane 3 --command b11tool --ntm "$fake_ntm" --timeout 2 --json >"$codex_pass"
assert_jq "$codex_pass" '.status == "pass" and .transport.send_attempted == true and .agent_context.probe_transport == "ntm_send" and .agent_context.callback_received == true' "B11_AG2 Codex path sends via ntm and validates callback"

claude_pass="$TMP/claude-pass.json"
python3 "$PROBE" --repo "$ROOT" --runtime claude --session flywheel --pane 1 --command b11tool --json >"$claude_pass"
assert_jq "$claude_pass" '.status == "pass" and .agent_context.probe_transport == "claude_bash_context"' "B11_AG3 Claude path uses Bash context"

drift_callback="$TMP/drift-callback.json"
write_agent_callback "$drift_callback" false false
drift_out="$TMP/drift.json"
python3 "$PROBE" --repo "$ROOT" --runtime codex --session flywheel --pane 3 --command b11tool --callback-ref "$drift_callback" --json >"$drift_out" && drift_rc=0 || drift_rc=$?
if [[ "$drift_rc" -ne 0 ]] && jq -e '.status == "fail" and .context_drift == true and (.validation.failure_classes | index("context_drift"))' "$drift_out" >/dev/null; then
  pass "B11_AG4 raw-shell pass plus agent failure returns context_drift"
else
  fail "B11_AG4 raw-shell pass plus agent failure returns context_drift"
  jq . "$drift_out" || true
fi

timeout_ntm="$(make_fake_ntm timeout)"
timeout_out="$TMP/timeout.json"
FAKE_NTM_MODE=timeout python3 "$PROBE" --repo "$ROOT" --runtime codex --session flywheel --pane 3 --command b11tool --ntm "$timeout_ntm" --timeout 1 --json >"$timeout_out" && timeout_rc=0 || timeout_rc=$?
if [[ "$timeout_rc" -eq 3 ]] && jq -e '.status == "unknown" and (.validation.failure_classes | index("runtime_unresponsive"))' "$timeout_out" >/dev/null; then
  pass "B11_AG5 agent timeout returns runtime_unresponsive"
else
  fail "B11_AG5 agent timeout returns runtime_unresponsive"
  jq . "$timeout_out" || true
fi

assert_jq "$codex_pass" '.orchestrator_shell_context.found == true and (.orchestrator_shell_context.command_v | test("b11tool$")) and (.orchestrator_shell_context.realpath | test("b11tool$")) and .orchestrator_shell_context.version == "b11tool 1.0.0" and .orchestrator_shell_context.smoke_ok == true' "B11_AG6 CLI identity proof"
assert_jq "$codex_pass" '.q03g_integration | test("flywheel-q03g")' "B11_AG7 q03g fixture-compatible integration documented"
assert_jq "$codex_pass" '.status == "pass"' "B11_AG8 codex agent pass covered"
assert_jq "$drift_out" '.status == "fail"' "B11_AG8 codex agent fail covered"
assert_jq "$timeout_out" '.status == "unknown"' "B11_AG8 runtime timeout covered"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
