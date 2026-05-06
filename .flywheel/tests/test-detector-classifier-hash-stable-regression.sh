#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/detector-hash-stable-regression.XXXXXX")"
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

fixture() {
  local path="$1" t0="$2" t1="$3"
  jq -nc \
    --arg t0 "$t0" \
    --arg t1 "$t1" \
    '{schema_version:"codex-stuck-detector.fixture.v1",session:"fixture",pane:2,t0:$t0,t1:$t1}' >"$path"
}

run_detector() {
  local fixture="$1" out="$2" rc
  set +e
  CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector.jsonl" \
  CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/contract.jsonl" \
  CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/fuckup.jsonl" \
    "$SCRIPT" --fixture "$fixture" --dry-run --json >"$out"
  rc=$?
  set -e
  return "$rc"
}

run_live_detector() {
  local out="$1" rc
  set +e
  FAKE_NTM_LOG="$TMP/live-ntm.log" \
  FAKE_NTM_STATE="$TMP/live-ntm-state" \
  CODEX_STUCK_DETECTOR_NTM_BIN="$TMP/ntm" \
  CODEX_STUCK_DETECTOR_LEDGER="$TMP/live-detector.jsonl" \
  CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/live-contract.jsonl" \
  CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/live-fuckup.jsonl" \
    "$SCRIPT" --session flywheel --pane 2 --dry-run --json --window-sec 0 >"$out"
  rc=$?
  set -e
  return "$rc"
}

bash -n "$SCRIPT" && pass "detector_syntax" || fail "detector_syntax"

fixture "$TMP/post-callback-hash-drift.json" \
  $'• Working (21m 48s • esc to interrupt)\n\n\n› Find and fix a bug in @filename\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' \
  $'• Working (21m 49s • esc to interrupt)\n\n\n› Find and fix a bug in @filename\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
if run_detector "$TMP/post-callback-hash-drift.json" "$TMP/post-callback-hash-drift.out"; then
  fail "post_callback_hash_drift_returns_stuck"
else
  rc=$?
  [[ "$rc" -eq 1 ]] && pass "post_callback_hash_drift_returns_stuck" || fail "post_callback_hash_drift_returns_stuck"
fi
assert_jq "$TMP/post-callback-hash-drift.out" '.status == "stuck" and .stuck_count == 1' "post_callback_hash_drift_status"
assert_jq "$TMP/post-callback-hash-drift.out" '.panes[0].hash_stable == false and .panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "post_callback_classifier_ignores_hash_drift"
assert_jq "$TMP/post-callback-hash-drift.out" '.panes[0].recommended_recovery == "escape_then_reprompt_or_respawn" and .panes[0].auto_recover == true' "post_callback_recovery_preserved"

fixture "$TMP/implement-template-hash-drift.json" \
  $'• Working (2m 30s • esc to interrupt)\n\n\n› Implement {feature}\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' \
  $'• Working (2m 31s • esc to interrupt)\n\n\n› Implement {feature}\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
if run_detector "$TMP/implement-template-hash-drift.json" "$TMP/implement-template-hash-drift.out"; then
  fail "implement_template_hash_drift_returns_stuck"
else
  rc=$?
  [[ "$rc" -eq 1 ]] && pass "implement_template_hash_drift_returns_stuck" || fail "implement_template_hash_drift_returns_stuck"
fi
assert_jq "$TMP/implement-template-hash-drift.out" '.panes[0].hash_stable == false and .panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "implement_template_hash_drift_uses_post_callback_classifier"

fixture "$TMP/short-spinner-hash-drift.json" \
  $'• Working (1m 20s • esc to interrupt)\n\n\n› Find and fix a bug in @filename\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' \
  $'• Working (1m 21s • esc to interrupt)\n\n\n› Find and fix a bug in @filename\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
if run_detector "$TMP/short-spinner-hash-drift.json" "$TMP/short-spinner-hash-drift.out"; then
  pass "short_spinner_hash_drift_returns_ok"
else
  fail "short_spinner_hash_drift_returns_ok"
fi
assert_jq "$TMP/short-spinner-hash-drift.out" '.status == "ok" and .stuck_count == 0 and .panes[0].hash_stable == false and .panes[0].subclass == "alive"' "short_spinner_hash_drift_not_overclassified"

cat >"$TMP/ntm" <<'SH'
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
    count="$(sample_count)"
    if [[ "$count" -le 1 ]]; then sec=30; else sec=31; fi
    {
      printf '═══ flywheel__cod_1 (pane 2) ═══\n'
      printf '• Working (2m %ss • esc to interrupt)\n\n' "$sec"
      printf '› Implement {feature}\n\n'
      printf '  gpt-5.5 xhigh · ~/Developer/flywheel\n'
    } >"$out"
    ;;
  --robot-tail=*)
    jq -nc '{success:true,panes:{"2":{lines:["• Working (2m 31s • esc to interrupt)","","› Implement {feature}"]}}}'
    ;;
  send|send-key|respawn)
    printf 'Sent\n'
    ;;
  *)
    ;;
esac
SH
chmod +x "$TMP/ntm"

if run_live_detector "$TMP/live-implement-template.out"; then
  fail "live_implement_template_hash_drift_returns_stuck"
else
  rc=$?
  [[ "$rc" -eq 1 ]] && pass "live_implement_template_hash_drift_returns_stuck" || fail "live_implement_template_hash_drift_returns_stuck"
fi
assert_jq "$TMP/live-implement-template.out" '.panes[0].hash_stable == false and .panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "live_session_pane_uses_same_classifier"

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
