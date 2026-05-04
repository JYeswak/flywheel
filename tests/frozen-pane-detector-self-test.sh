#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/frozen-pane-detector.sh"
TICK_SCHEMA="$ROOT/.flywheel/validation-schema/v1/tick-receipt.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-self-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,160p' "$file" >&2 || true
  fi
}

if bash -n "$SCRIPT"; then
  pass "detector syntax"
else
  fail "detector syntax"
fi

"$SCRIPT" --dry-run --self-test --json >"$TMP/self-test.json"

assert_jq "$TMP/self-test.json" '.schema_version == "frozen-pane-detector.v2"' "schema version emitted"
assert_jq "$TMP/self-test.json" '.self_test.status == "pass" and .self_test.fixtures_total >= 6 and .self_test.fixtures_passed >= 6' "six fixture self-test passes"
assert_jq "$TMP/self-test.json" '(["A_age_only_miss","B_stale_tail","C_post_respawn_residue","D_stale_template_prompt","E_missing_l60_signal","F_queued_not_submitted"] - [.fixture_cases[].fixture_id]) | length == 0' "classes A-F covered"
assert_jq "$TMP/self-test.json" 'all(.fixture_cases[]; .status == "pass") and all(.fixture_cases[] | select(.fixture_id != "F_queued_not_submitted"); .recovery_allowed == false)' "non-queued fixtures do not allow recovery"
assert_jq "$TMP/self-test.json" '.queued_fixture.verdict == "QUEUED_NOT_SUBMITTED" and .queued_fixture.recovery_kind == "queued_bare_enter" and .queued_not_submitted_count == 1' "queued-not-submitted fixture is first-class"
assert_jq "$TMP/self-test.json" 'any(.recoveries[]; .recovery_kind == "queued_bare_enter" and .would_send_empty_enter == true)' "queued fixture plans bare-enter recovery"
assert_jq "$TMP/self-test.json" '.unknown_auto_recovery_count == 0' "unknown never auto-recovers"
assert_jq "$TMP/self-test.json" 'any(.durable_receipts[]; .status == "UNKNOWN") and any(.durable_receipts[]; .status == "UNHEALTHY")' "unknown and unhealthy durable receipts present"
assert_jq "$TMP/self-test.json" 'all(.soft_violations[]; .producer and .measurement and .consumer and .promotion_path and .severity == "SOFT")' "soft violations carry producer measurement consumer promotion"
assert_jq "$TMP/self-test.json" '.l60_signal_decrement_count >= 1 and .l60_signals_present.live_truth_delta == false' "L60 truth-failure decrement is surfaced"
assert_jq "$TMP/self-test.json" '.source_health.status == "unhealthy" and .source_health.degraded_recovery_allowed == false' "unhealthy truth is first-class and fail-closed"
assert_jq "$TMP/self-test.json" '.panes and (.frozen_panes_detected | type == "number") and (.template_stub_prompt_count | type == "number") and (.recoveries | type == "array") and (.f1_through_f7_addressed | type == "array")' "backward-compatible detector fields remain"
assert_jq "$TMP/self-test.json" '.respawn_suppressed_count == 1 and .recoveries[0].idempotency_key == "self-test" and (.recoveries[0].planned_actions | index("re_probe"))' "self-test exposes respawn suppression and idempotency"

"$SCRIPT" --schema >"$TMP/detector-schema.json"
assert_jq "$TMP/detector-schema.json" '.properties.soft_violations and .properties.durable_receipts and .properties.l60_signal_decrement_count and .properties.fixture_cases' "detector schema exposes new fields"
assert_jq "$TMP/detector-schema.json" '.properties.respawn_suppressed_count' "detector schema exposes respawn suppression field"
assert_jq "$TMP/detector-schema.json" '.properties.queued_not_submitted_count and .properties.queued_prompts_submitted' "detector schema exposes queued recovery fields"
assert_jq "$TICK_SCHEMA" '.properties.frozen_detector_self_test and .properties.frozen_detector_soft_violations and .properties.frozen_detector_durable_receipts and .properties.frozen_detector_l60_signal_decrement_count and .properties.frozen_pane_source_health_status' "tick receipt schema exposes consumer fields"

fake_ntm="$TMP/fake-ntm"
cat >"$fake_ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --robot-activity=*)
    printf '{"agents":[{"pane":"1","pane_idx":1,"agent_type":"codex","state":"THINKING","state_since":"2026-05-03T00:00:00Z"}]}\n'
    ;;
  --robot-tail=*)
    printf '{"panes":{"1":{"lines":["frozen line one","frozen line two"]}}}\n'
    ;;
  --robot-restart-pane=*)
    printf 'restart %s\n' "$*" >>"${FAKE_NTM_LOG:?}"
    ;;
  send)
    printf 'send %s\n' "$*" >>"${FAKE_NTM_LOG:?}"
    ;;
  *)
    printf 'unexpected fake ntm call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$fake_ntm"

seed_cache() {
  local dir="$1"
  mkdir -p "$dir"
  printf 'frozen line one\nfrozen line two\n' >"$dir/scrollback_cache_flywheel_1.txt"
}

NOW_EPOCH=1777850000
RECENT_TS="$(date -u -r "$NOW_EPOCH" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')"

recovery_state="$TMP/recovery-state"
recovery_cache="$TMP/recovery-cache"
seed_cache "$recovery_cache"
FAKE_NTM_LOG="$TMP/recovery-ntm.log" \
FROZEN_PANE_NTM_BIN="$fake_ntm" \
FROZEN_PANE_STATE_DIR="$recovery_state" \
FROZEN_PANE_CACHE_DIR="$recovery_cache" \
FROZEN_PANE_SAMPLE_DIR="$TMP/recovery-samples" \
FROZEN_PANE_RECOVERY_LEDGER="$TMP/recovery-ledger.jsonl" \
FROZEN_PANE_STRIKE_FILE="$TMP/recovery-strikes.jsonl" \
FROZEN_PANE_METRICS_FILE="$TMP/recovery-metrics.jsonl" \
FROZEN_PANE_SKIP_FUCKUP_LOG=1 \
FROZEN_PANE_AUTO_DISPATCH=0 \
FROZEN_PANE_RESPAWN_SLEEP=0 \
FROZEN_PANE_RELAUNCH_SLEEP=0 \
FROZEN_PANE_REPROBE_SLEEP=0 \
FROZEN_PANE_NOW_EPOCH="$NOW_EPOCH" \
  "$SCRIPT" --session flywheel --auto-recover --json --sample-interval-seconds 0 --idempotency-key recovery-key >"$TMP/recovery.json"

assert_jq "$TMP/recovery.json" '.frozen_panes_detected == 1 and .recoveries[0].respawned == true and .recoveries[0].relaunched == true and .recoveries[0].idempotency_key == "recovery-key" and .recoveries[0].ledger_event_written == true and .recoveries[0].re_probe.success == true' "auto recovery writes restart, relaunch, ledger and re-probe"
assert_jq "$TMP/recovery-ledger.jsonl" '.event == "recovery" and .idempotency_key == "recovery-key" and .re_probe.success == true' "recovery ledger records idempotency key and re-probe"
if [[ -s "$(jq -r '.recoveries[0].snapshot' "$TMP/recovery.json")" ]]; then
  pass "auto recovery writes snapshot"
else
  fail "auto recovery writes snapshot"
fi
if find "$TMP/recovery-samples" -name sample1.txt -print -quit | grep -q . && find "$TMP/recovery-samples" -name sample2.txt -print -quit | grep -q .; then
  pass "atomic two-sample files are persisted"
else
  fail "atomic two-sample files are persisted"
fi

FAKE_NTM_LOG="$TMP/recovery-ntm.log" \
FROZEN_PANE_NTM_BIN="$fake_ntm" \
FROZEN_PANE_STATE_DIR="$recovery_state" \
FROZEN_PANE_CACHE_DIR="$recovery_cache" \
FROZEN_PANE_SAMPLE_DIR="$TMP/recovery-samples-2" \
FROZEN_PANE_RECOVERY_LEDGER="$TMP/recovery-ledger.jsonl" \
FROZEN_PANE_STRIKE_FILE="$TMP/recovery-strikes.jsonl" \
FROZEN_PANE_METRICS_FILE="$TMP/recovery-metrics-2.jsonl" \
FROZEN_PANE_NOW_EPOCH="$NOW_EPOCH" \
  "$SCRIPT" --session flywheel --json --sample-interval-seconds 0 >"$TMP/respawn-suppressed.json"
assert_jq "$TMP/respawn-suppressed.json" '.respawn_suppressed_count == 1 and .panes[0].verdict == "RESPAWN_SUPPRESSED" and .panes[0].recovery_allowed == false and any(.durable_receipts[]; .status == "RESPAWN_SUPPRESSED")' "recent recovery classifies stale residue as RESPAWN_SUPPRESSED"

idempotency_state="$TMP/idempotency-state"
idempotency_cache="$TMP/idempotency-cache"
seed_cache "$idempotency_cache"
printf '{"ts":"%s","event":"recovery","session":"flywheel","pane":1,"idempotency_key":"same-key"}\n' "$RECENT_TS" >"$TMP/idempotency-ledger.jsonl"
FAKE_NTM_LOG="$TMP/idempotency-ntm.log" \
FROZEN_PANE_NTM_BIN="$fake_ntm" \
FROZEN_PANE_STATE_DIR="$idempotency_state" \
FROZEN_PANE_CACHE_DIR="$idempotency_cache" \
FROZEN_PANE_SAMPLE_DIR="$TMP/idempotency-samples" \
FROZEN_PANE_RECOVERY_LEDGER="$TMP/idempotency-ledger.jsonl" \
FROZEN_PANE_STRIKE_FILE="$TMP/idempotency-strikes.jsonl" \
FROZEN_PANE_METRICS_FILE="$TMP/idempotency-metrics.jsonl" \
FROZEN_PANE_RESPAWN_SUPPRESSION_SECONDS=0 \
FROZEN_PANE_NOW_EPOCH="$NOW_EPOCH" \
  "$SCRIPT" --session flywheel --auto-recover --json --sample-interval-seconds 0 --idempotency-key same-key >"$TMP/idempotency.json"
assert_jq "$TMP/idempotency.json" '.recoveries[0].suppressed == true and .recoveries[0].suppression_reason == "idempotency_replay"' "idempotency replay suppresses duplicate recovery"

restart_state="$TMP/restart-state"
restart_cache="$TMP/restart-cache"
seed_cache "$restart_cache"
printf '{"ts":"%s","event":"recovery","session":"flywheel","pane":1,"idempotency_key":"prior-key"}\n' "$RECENT_TS" >"$TMP/restart-ledger.jsonl"
FAKE_NTM_LOG="$TMP/restart-ntm.log" \
FROZEN_PANE_NTM_BIN="$fake_ntm" \
FROZEN_PANE_STATE_DIR="$restart_state" \
FROZEN_PANE_CACHE_DIR="$restart_cache" \
FROZEN_PANE_SAMPLE_DIR="$TMP/restart-samples" \
FROZEN_PANE_RECOVERY_LEDGER="$TMP/restart-ledger.jsonl" \
FROZEN_PANE_STRIKE_FILE="$TMP/restart-strikes.jsonl" \
FROZEN_PANE_METRICS_FILE="$TMP/restart-metrics.jsonl" \
FROZEN_PANE_RESPAWN_SUPPRESSION_SECONDS=0 \
FROZEN_PANE_NOW_EPOCH="$NOW_EPOCH" \
  "$SCRIPT" --session flywheel --auto-recover --json --sample-interval-seconds 0 --idempotency-key new-key >"$TMP/restart-loop.json"
assert_jq "$TMP/restart-loop.json" '.recoveries[0].suppressed == true and .recoveries[0].suppression_reason == "restart_loop_suppressed"' "restart-loop suppression prevents duplicate storms"

dryrun_state="$TMP/dryrun-state"
dryrun_cache="$TMP/dryrun-cache"
seed_cache "$dryrun_cache"
FAKE_NTM_LOG="$TMP/dryrun-ntm.log" \
FROZEN_PANE_NTM_BIN="$fake_ntm" \
FROZEN_PANE_STATE_DIR="$dryrun_state" \
FROZEN_PANE_CACHE_DIR="$dryrun_cache" \
FROZEN_PANE_SAMPLE_DIR="$TMP/dryrun-samples" \
FROZEN_PANE_RECOVERY_LEDGER="$TMP/dryrun-ledger.jsonl" \
FROZEN_PANE_STRIKE_FILE="$TMP/dryrun-strikes.jsonl" \
FROZEN_PANE_METRICS_FILE="$TMP/dryrun-metrics.jsonl" \
FROZEN_PANE_NOW_EPOCH="$NOW_EPOCH" \
  "$SCRIPT" --session flywheel --auto-recover --dry-run --explain --json --sample-interval-seconds 0 --idempotency-key dry-key >"$TMP/dryrun.json"
assert_jq "$TMP/dryrun.json" '.dry_run == true and .explain == true and .recoveries[0].dry_run == true and (.recoveries[0].planned_actions | index("re_probe")) and .recoveries[0].explain' "dry-run explain JSON lists planned recovery actions"

queued_fake_ntm="$TMP/fake-queued-ntm"
queued_state_since="$(date -u -r "$((NOW_EPOCH - 300))" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')"
cat >"$queued_fake_ntm" <<SH
#!/usr/bin/env bash
set -euo pipefail
case "\${1:-}" in
  --robot-activity=*)
    printf '{"agents":[{"pane":"9","pane_idx":9,"agent_type":"codex","state":"WAITING","state_since":"$queued_state_since","velocity":0,"detected_patterns":["codex_chevron_prompt"]}]}\n'
    ;;
  --robot-tail=*)
    printf '{"panes":{"9":{"lines":["• Working (3m • esc to interrupt)","","› Explain this codebase","","  gpt-5.5 high · ~/Developer/flywheel"]}}}\n'
    ;;
  send)
    printf 'queued send %s\n' "\$*" >>"\${FAKE_NTM_LOG:?}"
    ;;
  *)
    printf '{}\n'
    ;;
esac
SH
chmod +x "$queued_fake_ntm"

queued_cache="$TMP/queued-cache"
mkdir -p "$queued_cache"
printf '• Working (3m • esc to interrupt)\n\n› Explain this codebase\n\n  gpt-5.5 high · ~/Developer/flywheel\n' >"$queued_cache/scrollback_cache_flywheel_9.txt"
FAKE_NTM_LOG="$TMP/queued-ntm.log" \
FROZEN_PANE_NTM_BIN="$queued_fake_ntm" \
FROZEN_PANE_STATE_DIR="$TMP/queued-state" \
FROZEN_PANE_CACHE_DIR="$queued_cache" \
FROZEN_PANE_SAMPLE_DIR="$TMP/queued-samples" \
FROZEN_PANE_RECOVERY_LEDGER="$TMP/queued-ledger.jsonl" \
FROZEN_PANE_STRIKE_FILE="$TMP/queued-strikes.jsonl" \
FROZEN_PANE_METRICS_FILE="$TMP/queued-metrics.jsonl" \
FROZEN_PANE_NOW_EPOCH="$NOW_EPOCH" \
  "$SCRIPT" --session flywheel --auto-recover --dry-run --json \
  --sample-interval-seconds 0 --queued-threshold-seconds 120 \
  --queued-timer-drift-seconds 60 >"$TMP/queued-detect.json"
assert_jq "$TMP/queued-detect.json" '.queued_not_submitted_count == 1 and .queued_prompts_submitted == 0' "queued detector dry-run finds one pane"
assert_jq "$TMP/queued-detect.json" 'any(.panes[]; .verdict == "QUEUED_NOT_SUBMITTED" and .recovery_allowed == true and .working_timer_seconds >= 180)' "queued pane verdict uses scrollback and timer"
assert_jq "$TMP/queued-detect.json" 'any(.recoveries[]; .recovery_kind == "queued_bare_enter" and .would_send_empty_enter == true and (.planned_actions | index("send_empty_enter")))' "queued auto-recovery is bare Enter in dry-run"
assert_jq "$TMP/queued-detect.json" 'any(.soft_violations[]; .class == "codex_queued_not_submitted")' "queued detector emits SOFT violation"

timer_fake_ntm="$TMP/fake-timer-ntm"
timer_state_since="$(date -u -r "$((NOW_EPOCH - 10))" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')"
cat >"$timer_fake_ntm" <<SH
#!/usr/bin/env bash
set -euo pipefail
case "\${1:-}" in
  --robot-activity=*)
    printf '{"agents":[{"pane":"4","pane_idx":4,"agent_type":"codex","state":"THINKING","state_since":"$timer_state_since","velocity":0,"detected_patterns":[]}]}\n'
    ;;
  --robot-tail=*)
    printf '{"panes":{"4":{"lines":["• Waiting for background terminal (13m 21s)","  still waiting"]}}}\n'
    ;;
  *)
    printf '{}\n'
    ;;
esac
SH
chmod +x "$timer_fake_ntm"

FROZEN_PANE_NTM_BIN="$timer_fake_ntm" \
FROZEN_PANE_STATE_DIR="$TMP/timer-state" \
FROZEN_PANE_CACHE_DIR="$TMP/timer-cache" \
FROZEN_PANE_SAMPLE_DIR="$TMP/timer-samples" \
FROZEN_PANE_RECOVERY_LEDGER="$TMP/timer-ledger.jsonl" \
FROZEN_PANE_STRIKE_FILE="$TMP/timer-strikes.jsonl" \
FROZEN_PANE_METRICS_FILE="$TMP/timer-metrics.jsonl" \
FROZEN_PANE_NOW_EPOCH="$NOW_EPOCH" \
  "$SCRIPT" --session flywheel --json --sample-interval-seconds 0 --threshold-seconds 90 >"$TMP/timer-detect.json"
assert_jq "$TMP/timer-detect.json" '.frozen_panes_detected == 1 and .panes[0].verdict == "FROZEN" and .panes[0].reason == "timer-text-identical-2-samples"' "identical timer text bypasses age threshold"
assert_jq "$TMP/timer-detect.json" '.panes[0].timer_text == "13m 21s" and .panes[0].timer_text_identical == true and .panes[0].age_seconds < 90' "timer fast path records timer evidence"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
