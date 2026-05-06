#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/detector-live-probe-regression.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

fake_ntm="$TMP/ntm"
fake_log="$TMP/ntm.log"
cat >"$fake_ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
log="${FAKE_NTM_LOG:?}"
state="${FAKE_NTM_STATE:?}"
mkdir -p "$state"
printf '%s\n' "$*" >>"$log"

sample_count() {
  local count_file="$state/copy-count" count=0
  [[ -s "$count_file" ]] && count="$(cat "$count_file")"
  count=$((count + 1))
  printf '%s' "$count" >"$count_file"
  printf '%s\n' "$count"
}

pane_text() {
  local count sec
  count="$(sample_count)"
  if [[ "$count" -le 1 ]]; then sec=30; else sec=31; fi
  cat <<EOF
═══ flywheel__cod_1 (pane 2) ═══
• Working (2m ${sec}s • esc to interrupt)

› Implement {feature}

  gpt-5.5 xhigh · ~/Developer/flywheel
EOF
}

case "${1:-}" in
  copy)
    out=""
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        --output) out="${2:?}"; shift 2 ;;
        --output=*) out="${1#*=}"; shift ;;
        *) shift ;;
      esac
    done
    [[ -n "$out" ]] || exit 2
    pane_text >"$out"
    ;;
  --robot-tail=*)
    jq -nc '{success:true,session:"flywheel",panes:{"2":{type:"codex",state:"idle",lines:["• Working (2m 31s • esc to interrupt)","","› Implement {feature}"],capture_provenance:"live"}}}'
    ;;
  send-key)
    printf 'Sent\n'
    ;;
  send)
    printf 'Sent\n'
    ;;
  respawn)
    printf 'respawned\n'
    ;;
  *)
    ;;
esac
SH
chmod +x "$fake_ntm"

printf 'repeat prior dispatch\n' >"$TMP/prompt.md"
jq -nc --arg path "$TMP/prompt.md" '{target_session:"flywheel",target_pane:2,dispatch_file:$path}' >"$TMP/dispatch-log.jsonl"

bash -n "$SCRIPT" && pass "detector_syntax" || fail "detector_syntax"

set +e
FAKE_NTM_LOG="$fake_log" \
FAKE_NTM_STATE="$TMP/ntm-state" \
CODEX_STUCK_DETECTOR_NTM_BIN="$fake_ntm" \
CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector-ledger.jsonl" \
CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/contract.jsonl" \
CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/detector-fuckup.jsonl" \
RECOVERY_NTM_BIN="$fake_ntm" \
RECOVERY_MOCK_SCENARIO="stage1_success" \
RECOVERY_LEDGER="$TMP/recovery-ledger.jsonl" \
RECOVERY_FUCKUP_LOG="$TMP/recovery-fuckup.jsonl" \
RECOVERY_DISPATCH_LOG="$TMP/dispatch-log.jsonl" \
RECOVERY_REPO_DISPATCH_LOG="$TMP/dispatch-log.jsonl" \
RECOVERY_RECEIPT_DIR="$TMP/recovery-receipts" \
  "$SCRIPT" --session flywheel --pane 2 --apply --auto-recover --json --window-sec 0 >"$TMP/detector.json" 2>"$TMP/detector.err"
rc=$?
set -e

[[ "$rc" -eq 1 && -s "$TMP/detector.json" ]] && pass "live_probe_returns_stuck_with_json" || fail "live_probe_returns_stuck_with_json"
assert_jq "$TMP/detector.json" '.status == "stuck" and .stuck_count == 1 and .unknown_stable_count == 0' "live_probe_not_unknown_stable"
assert_jq "$TMP/detector.json" '.panes[0].hash_stable == false' "live_probe_exercises_hash_drift"
assert_jq "$TMP/detector.json" '.panes[0].subclass != "alive" and .panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "live_probe_implement_template_uses_post_callback_classifier"
assert_jq "$TMP/detector.json" '.panes[0].recommended_recovery == "escape_then_reprompt_or_respawn" and .panes[0].recovery_attempted != "none" and .panes[0].recovery_payload.schema_version == "recovery-receipt.v1" and .panes[0].recovery_payload.stage_succeeded == 1 and .panes[0].recovery_succeeded == true' "live_probe_auto_recover_invokes_stage_recovery"
assert_jq "$TMP/detector-ledger.jsonl" '.subclass == "post_callback_reminder_template_with_stale_spinner" and .hash_stable == false and .recovery_attempted == "escape_then_reprompt_or_respawn"' "ledger_records_live_probe_subclass"

[[ "$(grep -c '^copy flywheel:2' "$fake_log")" -ge 2 ]] && pass "session_pane_path_used_ntm_copy_twice" || fail "session_pane_path_used_ntm_copy_twice"
test ! -s "$TMP/detector.err" && pass "no_stderr_on_successful_json" || fail "no_stderr_on_successful_json"

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
