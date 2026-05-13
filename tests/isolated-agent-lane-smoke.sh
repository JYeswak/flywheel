#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/isolated-agent-lane-smoke.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-isolated-agent-lane-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

if bash -n "$SCRIPT" && "$SCRIPT" --help >/dev/null; then
  pass "syntax"
else
  fail "syntax"
fi

run_capture "$TMP/smoke.json" "$TMP/smoke.err" \
  "$SCRIPT" --skip-assemble --receipt-dir "$TMP/receipts" --json
smoke_rc=$?
if [[ "$smoke_rc" -eq 0 ]] && jq -e '
  .schema_version == "flywheel.isolated_agent_lane_smoke.v0"
  and .status == "pass"
  and .isolation.home_isolated == true
  and .isolation.xdg_isolated == true
  and .reduced_journey.runtime_proven == true
  and .private_state_scan.status == "pass"
  and .support_copy_gate.reduced_supported == true
  and .support_copy_gate.claude_supported == false
  and .support_copy_gate.codex_supported == false
  and .support_copy_gate.gemini_supported == false
  and .support_copy_gate.openclaw_supported == false
  and (.blockers | length == 4)
' "$TMP/smoke.json" >/dev/null; then
  pass "isolated smoke envelope"
else
  fail "isolated smoke envelope rc=${smoke_rc}"
fi

if [[ -s "$TMP/receipts/claude.json" && -s "$TMP/receipts/codex.json" \
  && -s "$TMP/receipts/gemini.json" && -s "$TMP/receipts/openclaw.json" ]]; then
  pass "writes per-lane receipts"
else
  fail "writes per-lane receipts"
fi

run_capture "$TMP/probe.json" "$TMP/probe.err" \
  "$ROOT/scripts/agent-lane-probe.sh" --receipt-dir "$TMP/receipts" --json
probe_rc=$?
if [[ "$probe_rc" -eq 0 ]] && jq -e '
  .status == "pass"
  and .summary.blocked_receipts == 4
  and .summary.runtime_proven == 0
  and all(.rows[]; .support_copy_allowed == false and .evidence == "blocker_receipt")
' "$TMP/probe.json" >/dev/null; then
  pass "generated receipts validate as blockers"
else
  fail "generated receipts validate as blockers rc=${probe_rc}"
fi

run_capture "$TMP/require-runtime.json" "$TMP/require-runtime.err" \
  "$SCRIPT" --skip-assemble --require-runtime --receipt-dir "$TMP/receipts-require" --json
require_rc=$?
if [[ "$require_rc" -eq 20 ]] && jq -e '
  .status == "blocked"
  and .reduced_journey.runtime_proven == true
  and ([.blockers[] | select(.blocker_class == "isolated_runtime_receipt_missing" or .blocker_class == "install_required")] | length == 4)
' "$TMP/require-runtime.json" >/dev/null; then
  pass "require-runtime blocks unproven lanes"
else
  fail "require-runtime blocks unproven lanes rc=${require_rc}"
fi

mkdir -p "$TMP/fake-bin"
cat >"$TMP/fake-bin/claude" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  printf 'claude test-adapter\n'
  exit 0
fi
printf '{"result":"FLYWHEEL_LANE_OK"}\n'
SH
chmod +x "$TMP/fake-bin/claude"
cat >"$TMP/fake-bin/openclaw" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  printf 'openclaw test-adapter\n'
  exit 0
fi
printf 'Error: Unknown agent id "flywheel-lane-smoke". Use "openclaw agents list" to see configured agents.\n' >&2
exit 1
SH
chmod +x "$TMP/fake-bin/openclaw"

run_capture "$TMP/live-claude.json" "$TMP/live-claude.err" \
  env PATH="$TMP/fake-bin:$PATH" "$SCRIPT" --skip-assemble --live-adapters --lanes claude --receipt-dir "$TMP/live-receipts" --json
live_claude_rc=$?
if [[ "$live_claude_rc" -eq 0 ]] && jq -e '
  .status == "pass"
  and .support_copy_gate.claude_supported == true
  and .lanes[0].runtime_proven == true
  and .lanes[0].evidence == "runtime_receipt"
  and .lanes[0].adapter.mode == "live_adapter"
  and (.blockers | length == 0)
' "$TMP/live-claude.json" >/dev/null; then
  pass "live adapter promotes proven lane"
else
  fail "live adapter promotes proven lane rc=${live_claude_rc}"
fi

run_capture "$TMP/live-probe.json" "$TMP/live-probe.err" \
  "$ROOT/scripts/agent-lane-probe.sh" --receipt-dir "$TMP/live-receipts" --json
live_probe_rc=$?
if [[ "$live_probe_rc" -eq 0 ]] && jq -e '
  .status == "pass"
  and .summary.runtime_proven == 1
  and .rows[0].support_copy_allowed == true
' "$TMP/live-probe.json" >/dev/null; then
  pass "live runtime receipt validates"
else
  fail "live runtime receipt validates rc=${live_probe_rc}"
fi

run_capture "$TMP/live-openclaw.json" "$TMP/live-openclaw.err" \
  env PATH="$TMP/fake-bin:$PATH" "$SCRIPT" --skip-assemble --live-adapters --lanes openclaw --receipt-dir "$TMP/openclaw-receipts" --json
live_openclaw_rc=$?
if [[ "$live_openclaw_rc" -eq 0 ]] && jq -e '
  .status == "pass"
  and .support_copy_gate.openclaw_supported == false
  and .blockers[0].id == "openclaw"
  and .blockers[0].blocker_class == "adapter_config_required"
' "$TMP/live-openclaw.json" >/dev/null; then
  pass "live adapter classifies missing config"
else
  fail "live adapter classifies missing config rc=${live_openclaw_rc}"
fi

if ! rg -n '/Users/josh|AGENT_MAIL_[A-Z_]*=|sk-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9_]{20,}' "$TMP/smoke.json" "$TMP/receipts" >/dev/null; then
  pass "outputs avoid private markers"
else
  fail "outputs avoid private markers"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
