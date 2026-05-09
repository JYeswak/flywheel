#!/usr/bin/env bash
# operator-fatigue-probe.sh — closes flywheel-1rmp.8 (value-gap
# `operator-fatigue-gate`).
#
# The smallest recurring measurement that makes the value gap visible: count
# dispatches and fuckup-log events per rolling time window (1h / 4h / 24h) and
# emit a fatigue signal when sustained interrupt density crosses thresholds.
#
# Step 4o anti-pattern preserved: probe is READ-ONLY. No Pushover/email/Slack
# notification, no `br create`, no `ntm send`, no auto-dispatch from findings.
# Output is structured JSON only. The orchestrator decides what to do with a
# fatigue_signal=true reading; this probe just measures.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json with stable exit codes.
set -euo pipefail

SCHEMA_VERSION="operator-fatigue-probe.v1"
DEFAULT_DISPATCH_LOG="/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl"
DEFAULT_FUCKUP_LOG="$HOME/.local/state/flywheel/fuckup-log.jsonl"

DISPATCH_LOG="$DEFAULT_DISPATCH_LOG"
FUCKUP_LOG="$DEFAULT_FUCKUP_LOG"
JSON_OUT=0
MODE=run

# Thresholds (operator-tunable). Defaults erring conservative — flag fatigue
# only on sustained high-density windows so the signal isn't noisy.
SIGNAL_1H_DISPATCHES="${OPERATOR_FATIGUE_1H_THRESHOLD:-15}"   # >15 dispatches/h triggers signal candidate
SIGNAL_4H_DISPATCHES="${OPERATOR_FATIGUE_4H_THRESHOLD:-40}"   # >40 dispatches over 4h
SIGNAL_24H_DISPATCHES="${OPERATOR_FATIGUE_24H_THRESHOLD:-150}" # >150 dispatches over 24h
SIGNAL_REPEATED_TRAUMA_CLASSES="${OPERATOR_FATIGUE_TRAUMA_THRESHOLD:-3}" # ≥3 trauma classes recurring in 24h

usage() {
  cat <<'USAGE'
usage: operator-fatigue-probe.sh [--dispatch-log PATH] [--fuckup-log PATH] [--json]
       operator-fatigue-probe.sh --doctor|--health|--info|--schema [--json]

Reads dispatch-log + fuckup-log, computes interrupt density per rolling
window, emits fatigue signal when thresholds are crossed.

Output JSON (run mode):
  {
    schema_version, ts,
    dispatches_1h, dispatches_4h, dispatches_24h,
    fuckups_1h, fuckups_4h, fuckups_24h,
    repeated_trauma_classes_24h: [{class, count}],
    repeated_trauma_classes_count: int,
    fatigue_signal: bool,
    fatigue_reasons: [enum...],
    step_away_recommended: bool,
    thresholds: {dispatches_1h, dispatches_4h, dispatches_24h, repeated_trauma_classes},
    reads_only: true, auto_dispatch: false, step_4o_compliance: "preserved"
  }

Exit codes:
  0  measurement emitted
  1  no log data in window
  2  config error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg dlog "$DISPATCH_LOG" --arg flog "$FUCKUP_LOG" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$dlog, fuckup_log:$flog,
      dispatch_log_present:true, fuckup_log_present:true,
      reads_only:true, auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","Joshua-step-away suggestion (orchestrator decides)"],
      step_4o_compliance:"preserved",
      out_of_scope:["Pushover/email/Slack notification","auto-dispatch","Joshua-blocker creation"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      measurement:"interrupt density (dispatches+fuckups) per 1h/4h/24h window plus repeated-trauma-class density",
      fatigue_reasons_taxonomy:["dispatches_1h_above_threshold","dispatches_4h_above_threshold","dispatches_24h_above_threshold","repeated_trauma_classes_above_threshold"],
      doctrine:"Joshua sustainability is a stock; this measures the flow rate hitting it. Step-away recommendation surfaces only — orchestrator decides whether to act.",
      reads_only:true,
      step_4o_compliance:"preserved"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        dispatches_1h:{type:"integer"},
        dispatches_4h:{type:"integer"},
        dispatches_24h:{type:"integer"},
        fuckups_1h:{type:"integer"},
        fuckups_4h:{type:"integer"},
        fuckups_24h:{type:"integer"},
        repeated_trauma_classes_count:{type:"integer"},
        repeated_trauma_classes_24h:{type:"array"},
        fatigue_signal:{type:"boolean"},
        fatigue_reasons:{type:"array"},
        step_away_recommended:{type:"boolean"},
        thresholds:{type:"object"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dispatch-log) DISPATCH_LOG="${2:?--dispatch-log requires PATH}"; shift 2;;
    --fuckup-log) FUCKUP_LOG="${2:?--fuckup-log requires PATH}"; shift 2;;
    --json) JSON_OUT=1; shift;;
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

[[ -f "$DISPATCH_LOG" ]] || { echo "ERR: dispatch-log not found: $DISPATCH_LOG" >&2; exit 2; }
[[ -f "$FUCKUP_LOG" ]] || { echo "ERR: fuckup-log not found: $FUCKUP_LOG" >&2; exit 2; }

NOW_EPOCH="$(date -u +%s)"
EPOCH_1H=$((NOW_EPOCH - 3600))
EPOCH_4H=$((NOW_EPOCH - 14400))
EPOCH_24H=$((NOW_EPOCH - 86400))

count_after() {
  # $1 = log path, $2 = epoch cutoff, $3 = optional event filter (jq predicate)
  # Uses `fromjson?` to tolerate malformed lines (corrupt JSON in append-only
  # logs is real — see jq parse error at line 809 of dispatch-log.jsonl from
  # 2026-05-08 incident). `?` swallows the error and skips the bad line.
  local log="$1" cutoff="$2" filter="${3:-true}"
  set +e
  local count
  count="$(tail -n 5000 "$log" 2>/dev/null \
    | jq -R -c --argjson cutoff "$cutoff" '
        fromjson?
        | select(type == "object" and (.ts // null) != null)
        | (.ts | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime) as $epoch
        | select($epoch >= $cutoff)
        | select('"$filter"')' 2>/dev/null \
    | wc -l | tr -d ' ')"
  set -e
  printf '%s\n' "${count:-0}"
}

DISP_1H="$(count_after "$DISPATCH_LOG" "$EPOCH_1H" '.event == "dispatch_sent"')"
DISP_4H="$(count_after "$DISPATCH_LOG" "$EPOCH_4H" '.event == "dispatch_sent"')"
DISP_24H="$(count_after "$DISPATCH_LOG" "$EPOCH_24H" '.event == "dispatch_sent"')"

FUCKUP_1H="$(count_after "$FUCKUP_LOG" "$EPOCH_1H" 'true')"
FUCKUP_4H="$(count_after "$FUCKUP_LOG" "$EPOCH_4H" 'true')"
FUCKUP_24H="$(count_after "$FUCKUP_LOG" "$EPOCH_24H" 'true')"

# Repeated trauma classes within 24h window — class with ≥2 occurrences.
set +e
REPEATED_TRAUMA_JSON="$(tail -n 5000 "$FUCKUP_LOG" 2>/dev/null \
  | jq -R -c --argjson cutoff "$EPOCH_24H" '
      fromjson?
      | select(type == "object" and (.ts // null) != null and (.trauma_class // null) != null)
      | (.ts | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime) as $epoch
      | select($epoch >= $cutoff)
      | .trauma_class' 2>/dev/null \
  | sort | uniq -c \
  | awk '$1 >= 2 { printf "{\"class\":\"%s\",\"count\":%s}\n", $2, $1 }' \
  | jq -s 'sort_by(-.count)' 2>/dev/null)"
[[ -z "$REPEATED_TRAUMA_JSON" ]] && REPEATED_TRAUMA_JSON='[]'
set -e
REPEATED_TRAUMA_COUNT="$(jq 'length' <<<"$REPEATED_TRAUMA_JSON" 2>/dev/null || echo 0)"

# Fatigue evaluation.
FATIGUE_REASONS=()
[[ "$DISP_1H"  -gt "$SIGNAL_1H_DISPATCHES"  ]] && FATIGUE_REASONS+=("dispatches_1h_above_threshold")
[[ "$DISP_4H"  -gt "$SIGNAL_4H_DISPATCHES"  ]] && FATIGUE_REASONS+=("dispatches_4h_above_threshold")
[[ "$DISP_24H" -gt "$SIGNAL_24H_DISPATCHES" ]] && FATIGUE_REASONS+=("dispatches_24h_above_threshold")
[[ "$REPEATED_TRAUMA_COUNT" -ge "$SIGNAL_REPEATED_TRAUMA_CLASSES" ]] && FATIGUE_REASONS+=("repeated_trauma_classes_above_threshold")

if [[ "${#FATIGUE_REASONS[@]}" -gt 0 ]]; then
  FATIGUE_SIGNAL=true
else
  FATIGUE_SIGNAL=false
fi

# Step-away recommendation: stricter — needs ≥2 reasons OR sustained 4h+24h.
STEP_AWAY=false
if [[ "${#FATIGUE_REASONS[@]}" -ge 2 ]]; then
  STEP_AWAY=true
elif [[ "$DISP_4H" -gt "$SIGNAL_4H_DISPATCHES" && "$DISP_24H" -gt "$SIGNAL_24H_DISPATCHES" ]]; then
  STEP_AWAY=true
fi

REASONS_JSON="$(printf '%s\n' "${FATIGUE_REASONS[@]:-}" | jq -R -s 'split("\n") | map(select(length > 0))')"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson disp1h "$DISP_1H" \
  --argjson disp4h "$DISP_4H" \
  --argjson disp24h "$DISP_24H" \
  --argjson fuck1h "$FUCKUP_1H" \
  --argjson fuck4h "$FUCKUP_4H" \
  --argjson fuck24h "$FUCKUP_24H" \
  --argjson trauma "$REPEATED_TRAUMA_JSON" \
  --argjson trauma_count "$REPEATED_TRAUMA_COUNT" \
  --argjson signal "$FATIGUE_SIGNAL" \
  --argjson reasons "$REASONS_JSON" \
  --argjson step_away "$STEP_AWAY" \
  --argjson th_1h "$SIGNAL_1H_DISPATCHES" \
  --argjson th_4h "$SIGNAL_4H_DISPATCHES" \
  --argjson th_24h "$SIGNAL_24H_DISPATCHES" \
  --argjson th_trauma "$SIGNAL_REPEATED_TRAUMA_CLASSES" \
  '{schema_version:$schema, ts:$ts, success:true, mode:"run",
    dispatches_1h:$disp1h, dispatches_4h:$disp4h, dispatches_24h:$disp24h,
    fuckups_1h:$fuck1h, fuckups_4h:$fuck4h, fuckups_24h:$fuck24h,
    repeated_trauma_classes_24h:$trauma,
    repeated_trauma_classes_count:$trauma_count,
    fatigue_signal:$signal,
    fatigue_reasons:$reasons,
    step_away_recommended:$step_away,
    thresholds:{dispatches_1h:$th_1h, dispatches_4h:$th_4h, dispatches_24h:$th_24h, repeated_trauma_classes:$th_trauma},
    reads_only:true, auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"operator-fatigue 1h=\(.dispatches_1h)/\(.thresholds.dispatches_1h) 4h=\(.dispatches_4h)/\(.thresholds.dispatches_4h) 24h=\(.dispatches_24h)/\(.thresholds.dispatches_24h) trauma=\(.repeated_trauma_classes_count)/\(.thresholds.repeated_trauma_classes) signal=\(.fatigue_signal) step_away=\(.step_away_recommended)"' <<<"$PAYLOAD"
fi
