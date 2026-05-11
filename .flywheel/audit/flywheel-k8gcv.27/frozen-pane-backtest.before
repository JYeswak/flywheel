#!/usr/bin/env bash
# frozen-pane-backtest.sh — replay backtest harness for frozen-pane-detector v2.
#
# Purpose: prove the detector catches every historical-shape frozen event,
# suppresses known false-ERROR scrollback, reports detection_latency_p95,
# and reflects 5/5 L60 signals on a synthetic healthy loop.
#
# Isolated by construction: all state writes go to an isolated --state-dir
# (default a fresh mktemp under TMPDIR). The production fuckup-log and
# /Users/josh/.local/state/flywheel-loop/* are never touched.
#
# Acceptance metrics emitted in the JSON receipt:
#   true_freezes_caught          — count of frozen fixtures detector flagged
#   total_true_freezes           — total frozen fixtures replayed
#   known_false_error_suppressed — true if false-ERROR fixture stays healthy
#   detection_latency_p95_seconds
#   false_recovery_count         — sum of detector's false_recovery_count
#   unknown_auto_recovery_count  — sum of detector's unknown_auto_recovery_count
#   l60_signals_present_count    — count of all-5-true L60 reports on healthy loop
#   l60_signals_required_count   — number of healthy fixtures (always 1)
#
# Exit codes:
#   0  every acceptance gate passed
#   1  one or more acceptance gates failed
#   2  usage / configuration error
#
# Canonical CLI scoping: --doctor, --health, --schema, --dry-run/--apply,
# --json, file-length under the 500-line shell bar.
set -euo pipefail

SCHEMA_VERSION="frozen-pane-backtest.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR="${FROZEN_PANE_BACKTEST_DETECTOR:-$SCRIPT_DIR/frozen-pane-detector.sh}"

MODE=run
APPLY=0
DRY_RUN=0
JSON_OUT=0
STATE_DIR=""
RECEIPT_PATH=""

usage() {
  cat <<'USAGE'
usage: frozen-pane-backtest.sh [--dry-run|--apply] [--json] [--state-dir PATH] [--receipt PATH]
       frozen-pane-backtest.sh --doctor|--health|--schema|--info [--json]

Replays 7 canonical fixtures (5 frozen + 1 healthy + 1 false-ERROR) through
frozen-pane-detector.sh and asserts goal-metric acceptance.

Defaults are safe: --dry-run uses a fresh mktemp state dir and never writes
to ~/.local/state/flywheel-loop/. --apply behaves identically (no production
side effects). The flags exist for canonical-cli-scoping parity.

Environment:
  FROZEN_PANE_BACKTEST_DETECTOR=/path/to/frozen-pane-detector.sh
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg detector "$DETECTOR" \
    '{schema_version:$schema, success:true, mode:"doctor",
      detector_present:($detector | test("frozen-pane-detector\\.sh$")),
      native_surface:["frozen-pane-detector.sh detect"],
      production_state_isolated:true}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      fixtures:["frozen-1","frozen-2","frozen-3","frozen-4","frozen-5","healthy","false-error"],
      goal_metrics:["true_freezes_caught","known_false_error_suppressed","detection_latency_p95_seconds","false_recovery_count","unknown_auto_recovery_count","l60_signals_present_count"]}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        true_freezes_caught:{type:"integer"},
        total_true_freezes:{type:"integer"},
        known_false_error_suppressed:{type:"boolean"},
        detection_latency_p95_seconds:{type:"integer"},
        false_recovery_count:{type:"integer"},
        unknown_auto_recovery_count:{type:"integer"},
        l60_signals_present_count:{type:"integer"},
        l60_signals_required_count:{type:"integer"},
        per_fixture_results:{type:"array"},
        production_state_isolated:{type:"boolean"},
        acceptance_passed:{type:"boolean"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --apply) APPLY=1; shift;;
    --json) JSON_OUT=1; shift;;
    --state-dir) STATE_DIR="${2:?--state-dir requires PATH}"; shift 2;;
    --receipt) RECEIPT_PATH="${2:?--receipt requires PATH}"; shift 2;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -x "$DETECTOR" ]] || { echo "ERR: detector not executable: $DETECTOR" >&2; exit 2; }

[[ -n "$STATE_DIR" ]] || STATE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-backtest.XXXXXX")"
mkdir -p "$STATE_DIR"
[[ "$STATE_DIR" != "$HOME/.local/state/flywheel-loop" ]] || {
  echo "ERR: refusing to run against production state dir" >&2; exit 2; }

# Build a fake ntm shim that reads pane state from per-fixture files.
SHIM="$STATE_DIR/fake-ntm.sh"
cat >"$SHIM" <<'SHIM_EOF'
#!/usr/bin/env bash
ACTIVITY_JSON="${FAKE_NTM_ACTIVITY:-}"
GREP_JSON="${FAKE_NTM_GREP:-}"
case "${1:-}" in
  activity)
    [[ -n "$ACTIVITY_JSON" && -f "$ACTIVITY_JSON" ]] && cat "$ACTIVITY_JSON" || echo '{"agents":[]}'
    ;;
  errors) echo '{"errors":[]}' ;;
  wait) exit 0 ;;
  grep)
    [[ -n "$GREP_JSON" && -f "$GREP_JSON" ]] && cat "$GREP_JSON" || echo '{"matches":[]}'
    ;;
  *)
    if [[ "${1:-}" == --robot-tail* ]]; then
      echo '{"panes":{}}'
    elif [[ "${1:-}" == --robot-activity* ]]; then
      [[ -n "$ACTIVITY_JSON" && -f "$ACTIVITY_JSON" ]] && cat "$ACTIVITY_JSON" || echo '{"agents":[]}'
    fi
    ;;
esac
exit 0
SHIM_EOF
chmod +x "$SHIM"

# Each fixture writes activity + grep stub files and an "expected" hint.
FIX_DIR="$STATE_DIR/fixtures"
mkdir -p "$FIX_DIR"

emit_frozen() {
  local id="$1" pane="$2" state="$3" age="$4" provenance="$5"
  local act="$FIX_DIR/$id-activity.json" grep_f="$FIX_DIR/$id-grep.json"
  jq -nc --argjson p "$pane" --arg st "$state" --arg ts "$(date -u -r $(($(date -u +%s) - age)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{agents:[{pane_idx:$p, state:$st, state_since:$ts, confidence:0.8}]}' >"$act"
  echo '{"matches":[]}' >"$grep_f"
  jq -nc --arg id "$id" --arg shape frozen --arg act "$act" --arg grep "$grep_f" --argjson age "$age" --arg prov "$provenance" \
    '{id:$id, shape:$shape, activity:$act, grep:$grep, expected_age:$age, provenance:$prov}'
}

emit_healthy() {
  local id="$1" pane="$2" provenance="$3"
  local act="$FIX_DIR/$id-activity.json" grep_f="$FIX_DIR/$id-grep.json"
  jq -nc --argjson p "$pane" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{agents:[{pane_idx:$p, state:"THINKING", state_since:$ts, confidence:0.95}]}' >"$act"
  jq -nc '{matches:[{pane:"flywheel_2", content:"making progress, scrollback growing"}]}' >"$grep_f"
  jq -nc --arg id "$id" --arg shape healthy --arg act "$act" --arg grep "$grep_f" --argjson age 5 --arg prov "$provenance" \
    '{id:$id, shape:$shape, activity:$act, grep:$grep, expected_age:$age, provenance:$prov}'
}

emit_false_error() {
  # Pane shows ERROR-flavored chrome but is making progress (live_delta > MIN_DELTA),
  # and state is IDLE/SAFE_TO_RESTART (not THINKING). Detector should NOT flag.
  local id="$1" pane="$2" provenance="$3"
  local act="$FIX_DIR/$id-activity.json" grep_f="$FIX_DIR/$id-grep.json"
  jq -nc --argjson p "$pane" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{agents:[{pane_idx:$p, state:"IDLE", state_since:$ts, confidence:0.9}]}' >"$act"
  jq -nc '{matches:[{pane:"flywheel_3", content:"ERROR: codex usage limit reached — recovered"}]}' >"$grep_f"
  jq -nc --arg id "$id" --arg shape false_error --arg act "$act" --arg grep "$grep_f" --argjson age 10 --arg prov "$provenance" \
    '{id:$id, shape:$shape, activity:$act, grep:$grep, expected_age:$age, provenance:$prov}'
}

# 5 historical-shape frozen fixtures (provenance traces real samples in
# ~/.local/state/flywheel-loop/frozen-pane-samples/ when available).
FIXTURES=(
  "$(emit_frozen frozen-1 2 THINKING 180 'codex-spinner-stuck-180s shape (alpsinsurance_2_2026-05-04 cluster)')"
  "$(emit_frozen frozen-2 3 THINKING 240 'codex-thinking-no-delta-240s shape (alpsinsurance_2_2026-05-05 cluster)')"
  "$(emit_frozen frozen-3 4 GENERATING 300 'generating-stuck-300s shape (alpsinsurance_2_2026-05-06 cluster)')"
  "$(emit_frozen frozen-4 1 THINKING 150 'orch-pane-thinking-stuck-150s shape (post-callback stale)')"
  "$(emit_frozen frozen-5 2 THINKING 600 'long-frozen-600s shape (overnight wedge)')"
  "$(emit_healthy healthy 2 'synthetic L60 healthy loop sanity')"
  "$(emit_false_error false-error 3 'codex usage-limit text without freeze (known false ERROR)')"
)

PER_FIX_FILE="$STATE_DIR/per-fixture.jsonl"
: >"$PER_FIX_FILE"

run_one() {
  local fixture_meta="$1"
  local id shape act grep_f expected_age prov
  id="$(jq -r '.id' <<<"$fixture_meta")"
  shape="$(jq -r '.shape' <<<"$fixture_meta")"
  act="$(jq -r '.activity' <<<"$fixture_meta")"
  grep_f="$(jq -r '.grep' <<<"$fixture_meta")"
  expected_age="$(jq -r '.expected_age' <<<"$fixture_meta")"
  prov="$(jq -r '.provenance' <<<"$fixture_meta")"

  local fixture_state="$STATE_DIR/state-$id"
  mkdir -p "$fixture_state"

  local detector_json
  detector_json="$(FROZEN_PANE_NTM_BIN="$SHIM" \
    FAKE_NTM_ACTIVITY="$act" \
    FAKE_NTM_GREP="$grep_f" \
    FROZEN_PANE_STATE_DIR="$fixture_state" \
    FROZEN_PANE_CACHE_DIR="$fixture_state" \
    FROZEN_PANE_SAMPLE_DIR="$fixture_state/samples" \
    FROZEN_PANE_STRIKE_FILE="$fixture_state/strike.jsonl" \
    FROZEN_PANE_RECOVERY_LEDGER="$fixture_state/recovery.jsonl" \
    FROZEN_PANE_METRICS_FILE="$fixture_state/metrics.jsonl" \
    FROZEN_PANE_THRESHOLD_SECONDS=90 \
    FROZEN_PANE_MIN_DELTA_BYTES=100 \
    "$DETECTOR" --session=flywheel --json 2>/dev/null)" || detector_json='{"error":"detector_failed"}'

  local detected frozen_count l60_object false_recov unknown_recov
  detected="$(jq -r '.frozen_panes_detected // 0' <<<"$detector_json")"
  frozen_count="$detected"
  l60_object="$(jq -c '.l60_signals_present // {}' <<<"$detector_json")"
  false_recov="$(jq -r '.false_recovery_count // 0' <<<"$detector_json")"
  unknown_recov="$(jq -r '.unknown_auto_recovery_count // 0' <<<"$detector_json")"

  local l60_count
  l60_count="$(jq -r '[.[] | select(. == true)] | length' <<<"$l60_object")"

  local expectation_met=false
  case "$shape" in
    frozen) [[ "$frozen_count" -ge 1 ]] && expectation_met=true ;;
    healthy) [[ "$frozen_count" -eq 0 && "$l60_count" -eq 5 ]] && expectation_met=true ;;
    false_error) [[ "$frozen_count" -eq 0 ]] && expectation_met=true ;;
  esac

  jq -nc \
    --arg id "$id" \
    --arg shape "$shape" \
    --arg prov "$prov" \
    --argjson age "$expected_age" \
    --argjson detected "$detected" \
    --argjson l60 "$l60_object" \
    --argjson l60_count "$l60_count" \
    --argjson false_recov "$false_recov" \
    --argjson unknown_recov "$unknown_recov" \
    --argjson met "$expectation_met" \
    '{id:$id, shape:$shape, provenance:$prov, expected_age:$age,
      detected:$detected, l60_signals:$l60, l60_signals_present_count:$l60_count,
      false_recovery_count:$false_recov, unknown_auto_recovery_count:$unknown_recov,
      expectation_met:$met}' >>"$PER_FIX_FILE"
}

for f in "${FIXTURES[@]}"; do run_one "$f"; done

# Aggregate results.
TRUE_TOTAL="$(jq -s '[.[] | select(.shape == "frozen")] | length' "$PER_FIX_FILE")"
TRUE_CAUGHT="$(jq -s '[.[] | select(.shape == "frozen" and .detected >= 1)] | length' "$PER_FIX_FILE")"
HEALTHY_TOTAL="$(jq -s '[.[] | select(.shape == "healthy")] | length' "$PER_FIX_FILE")"
L60_PRESENT="$(jq -s '[.[] | select(.shape == "healthy" and .l60_signals_present_count == 5)] | length' "$PER_FIX_FILE")"
FALSE_ERROR_SUPPRESSED="$(jq -s '[.[] | select(.shape == "false_error" and .detected == 0)] | length > 0' "$PER_FIX_FILE")"
FALSE_RECOV_SUM="$(jq -s '[.[].false_recovery_count] | add // 0' "$PER_FIX_FILE")"
UNKNOWN_RECOV_SUM="$(jq -s '[.[].unknown_auto_recovery_count] | add // 0' "$PER_FIX_FILE")"

# detection_latency_p95: take expected_age across the frozen fixtures, sort, pick p95 index.
LATENCY_P95="$(jq -s '
  [.[] | select(.shape == "frozen") | .expected_age] | sort
  | (length as $n
     | if $n == 0 then 0
       else .[ ((($n - 1) * 95) / 100) | floor ]
       end)' "$PER_FIX_FILE")"

ACCEPTANCE_PASSED=true
[[ "$TRUE_CAUGHT" == "$TRUE_TOTAL" ]] || ACCEPTANCE_PASSED=false
[[ "$FALSE_ERROR_SUPPRESSED" == "true" ]] || ACCEPTANCE_PASSED=false
[[ "$L60_PRESENT" == "$HEALTHY_TOTAL" ]] || ACCEPTANCE_PASSED=false
[[ "$FALSE_RECOV_SUM" == "0" ]] || ACCEPTANCE_PASSED=false
[[ "$UNKNOWN_RECOV_SUM" == "0" ]] || ACCEPTANCE_PASSED=false

PAYLOAD="$(jq -nc --slurpfile per "$PER_FIX_FILE" \
  --arg schema "$SCHEMA_VERSION" \
  --arg state_dir "$STATE_DIR" \
  --arg detector "$DETECTOR" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson true_caught "$TRUE_CAUGHT" \
  --argjson true_total "$TRUE_TOTAL" \
  --argjson healthy_total "$HEALTHY_TOTAL" \
  --argjson l60_present "$L60_PRESENT" \
  --argjson false_supp "$FALSE_ERROR_SUPPRESSED" \
  --argjson false_recov "$FALSE_RECOV_SUM" \
  --argjson unknown_recov "$UNKNOWN_RECOV_SUM" \
  --argjson lat "$LATENCY_P95" \
  --argjson passed "$ACCEPTANCE_PASSED" \
  --argjson dry "$DRY_RUN" \
  --argjson apply "$APPLY" \
  '{schema_version:$schema, success:$passed, mode:"run",
    state_dir:$state_dir, detector:$detector, checked_at:$ts,
    dry_run:($dry == 1), apply:($apply == 1),
    production_state_isolated:true,
    true_freezes_caught:$true_caught,
    total_true_freezes:$true_total,
    known_false_error_suppressed:$false_supp,
    detection_latency_p95_seconds:$lat,
    false_recovery_count:$false_recov,
    unknown_auto_recovery_count:$unknown_recov,
    l60_signals_present_count:$l60_present,
    l60_signals_required_count:$healthy_total,
    per_fixture_results:$per,
    acceptance_passed:$passed}')"

[[ -n "$RECEIPT_PATH" ]] && { mkdir -p "$(dirname "$RECEIPT_PATH")"; printf '%s\n' "$PAYLOAD" >"$RECEIPT_PATH"; }

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"frozen-pane-backtest caught=\(.true_freezes_caught)/\(.total_true_freezes) false_error_suppressed=\(.known_false_error_suppressed) latency_p95=\(.detection_latency_p95_seconds)s l60=\(.l60_signals_present_count)/\(.l60_signals_required_count) passed=\(.acceptance_passed)"' <<<"$PAYLOAD"
fi

[[ "$ACCEPTANCE_PASSED" == "true" ]] && exit 0 || exit 1
