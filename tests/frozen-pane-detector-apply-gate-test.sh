#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/frozen-pane-detector.sh"
LIB="/Users/josh/.local/share/flywheel-watchers/lib/jsonl-append.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-apply-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

seed_cache() {
  local dir="$1"
  mkdir -p "$dir"
  printf 'frozen line one\nfrozen line two\n' >"$dir/scrollback_cache_flywheel_1.txt"
}

make_fake_ntm() {
  local path="$1"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --robot-activity=*)
    jq -nc --arg state_since "${FAKE_STATE_SINCE:?}" \
      '{agents:[{pane:"1",pane_idx:1,agent_type:"codex",state:"THINKING",state_since:$state_since}]}'
    ;;
  --robot-tail=*)
    jq -nc '{panes:{"1":{lines:["frozen line one","frozen line two"]}}}'
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
  chmod +x "$path"
}

run_detector() {
  local state="$1" cache="$2" samples="$3" ledger="$4" strikes="$5" metrics="$6" log="$7"
  shift 7
  seed_cache "$cache"
  FAKE_NTM_LOG="$log" \
  FAKE_STATE_SINCE="2026-05-03T00:00:00Z" \
  FROZEN_PANE_NTM_BIN="$TMP/fake-ntm" \
  FROZEN_PANE_STATE_DIR="$state" \
  FROZEN_PANE_CACHE_DIR="$cache" \
  FROZEN_PANE_SAMPLE_DIR="$samples" \
  FROZEN_PANE_RECOVERY_LEDGER="$ledger" \
  FROZEN_PANE_STRIKE_FILE="$strikes" \
  FROZEN_PANE_METRICS_FILE="$metrics" \
  FROZEN_PANE_SKIP_FUCKUP_LOG=1 \
  FROZEN_PANE_AUTO_DISPATCH=0 \
  FROZEN_PANE_RESPAWN_SLEEP=0 \
  FROZEN_PANE_RELAUNCH_SLEEP=0 \
  FROZEN_PANE_REPROBE_SLEEP=0 \
  FROZEN_PANE_NOW_EPOCH=1777850000 \
    "$SCRIPT" --session flywheel --json --sample-interval-seconds 0 --idempotency-key "$state" "$@"
}

assert_jq() {
  local file="$1" expr="$2"
  jq -e "$expr" "$file" >/dev/null
}

make_fake_ntm "$TMP/fake-ntm"

preview_json="$TMP/preview.json"
preview_err="$TMP/preview.err"
preview_log="$TMP/preview-ntm.log"
run_detector "$TMP/preview-state" "$TMP/preview-cache" "$TMP/preview-samples" \
  "$TMP/preview-ledger.jsonl" "$TMP/preview-strikes.jsonl" "$TMP/preview-metrics.jsonl" \
  "$preview_log" --auto-recover >"$preview_json" 2>"$preview_err"

if assert_jq "$preview_json" '.dry_run == true and .frozen_panes_respawned == 0 and .recoveries[0].dry_run == true and (.recoveries[0].planned_actions | index("restart_pane")) and (has("actual_actions") | not) and (.recoveries[0] | has("actual_actions") | not)' \
  && grep -q -- '--auto-recover is preview-only' "$preview_err" \
  && [[ ! -s "$preview_log" ]]; then
  pass "bare auto-recover is preview-only"
else
  fail "bare auto-recover is preview-only"
  jq . "$preview_json" >&2 || true
  cat "$preview_err" >&2 || true
  cat "$preview_log" >&2 || true
fi

apply_json="$TMP/apply.json"
apply_log="$TMP/apply-ntm.log"
apply_ledger="$TMP/apply-ledger.jsonl"
apply_strikes="$TMP/apply-strikes.jsonl"
apply_metrics="$TMP/apply-metrics.jsonl"
run_detector "$TMP/apply-state" "$TMP/apply-cache" "$TMP/apply-samples" \
  "$apply_ledger" "$apply_strikes" "$apply_metrics" "$apply_log" \
  --auto-recover --apply >"$apply_json"

if assert_jq "$apply_json" '.dry_run == false and .frozen_panes_respawned == 1 and .frozen_panes_relaunched == 1 and .recoveries[0].ledger_event_written == true' \
  && grep -q '^restart ' "$apply_log" \
  && [[ "$(grep -c '^send ' "$apply_log")" -ge 2 ]]; then
  pass "apply executes restart and relaunch"
else
  fail "apply executes restart and relaunch"
  jq . "$apply_json" >&2 || true
  cat "$apply_log" >&2 || true
fi

if jq -e 'select(.class == "frozen-codex-spinner-misclassified-as-thinking" and .source == "frozen-pane-detector.sh")' "$apply_strikes" >/dev/null \
  && jq -e 'select(.event == "recovery" and .source == "frozen-pane-detector.sh")' "$apply_ledger" >/dev/null \
  && jq -e 'select(.schema_version == "frozen-pane-detector.v2" and .source_health == "healthy")' "$apply_metrics" >/dev/null; then
  pass "validated JSONL sites append readable objects"
else
  fail "validated JSONL sites append readable objects"
  cat "$apply_strikes" "$apply_ledger" "$apply_metrics" >&2 || true
fi

# shellcheck disable=SC1090,SC1091
source "$LIB"
empty_file="$TMP/empty.jsonl"
set +e
fw_jsonl_append_validated "$empty_file" ""
empty_rc=$?
set -e
if [[ "$empty_rc" == "1" && ! -s "$empty_file" ]]; then
  pass "empty JSONL row is not written"
else
  fail "empty JSONL row is not written"
  printf 'empty_rc=%s\n' "$empty_rc" >&2
  [[ -e "$empty_file" ]] && cat "$empty_file" >&2
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
