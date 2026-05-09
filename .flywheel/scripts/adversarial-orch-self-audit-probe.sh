#!/usr/bin/env bash
# adversarial-orch-self-audit-probe.sh — closes flywheel-1rmp.10 (value-gap
# `adversarial-orchestrator-self-audit`).
#
# The smallest recurring measurement that makes the value gap visible: scan
# recent orchestrator dispatch packets + callbacks for adversarial signals
# the orchestrator might be cutting corners on. Four-axis snapshot:
#
#   1. punt_phrase_count       — L70 forbidden phrases in recent dispatch packets
#   2. mission_drift_count     — dispatches with mission_fitness=drift
#   3. unaddressed_skill_routes — skill auto-routes catalog matched but
#                                  not addressed (yes|no|n/a missing)
#   4. recent_closed_beads_without_evidence — beads closed today with no
#                                  .flywheel/evidence/<bead-id>/ dir
#
# Step 4o anti-pattern preserved: probe is READ-ONLY. No br/ntm/gh/git/
# agent-mail mutating verbs in source. No auto-dispatch from findings.
# Output is structured JSON only. The orchestrator decides what to do with
# the findings; this probe just measures.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json with stable exit codes.
set -euo pipefail

SCHEMA_VERSION="adversarial-orch-self-audit-probe.v1"
DEFAULT_DISPATCH_LOG="/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl"
DEFAULT_TMP_DISPATCH_DIR="/tmp"
DEFAULT_EVIDENCE_DIR="/Users/josh/Developer/flywheel/.flywheel/evidence"
DEFAULT_BEADS_BIN="$(command -v br 2>/dev/null || echo /Users/josh/.cargo/bin/br)"

DISPATCH_LOG="$DEFAULT_DISPATCH_LOG"
TMP_DISPATCH_DIR="$DEFAULT_TMP_DISPATCH_DIR"
EVIDENCE_DIR="$DEFAULT_EVIDENCE_DIR"
BR_BIN="$DEFAULT_BEADS_BIN"
LOOKBACK_HOURS=24
JSON_OUT=0
MODE=run

# L70 forbidden punt-phrase catalog (lowercased; trailing context-stripped).
PUNT_PHRASES=(
  "should i"
  "should we"
  "want me to"
  "do you want me to"
  "would you like me to"
  "shall i"
  "let me know if"
  "let me know when"
  "if you want me to"
  "if you'd like"
  "when you're ready"
  "say the word"
  "want to proceed"
  "confirm and i'll"
  "the next move is yours"
  "standing by"
)

usage() {
  cat <<'USAGE'
usage: adversarial-orch-self-audit-probe.sh [--lookback-hours N] [--json]
       adversarial-orch-self-audit-probe.sh --doctor|--health|--info|--schema [--json]

Multi-axis adversarial self-audit of orchestrator behavior. Four axes:

  1. punt_phrase_count: L70 forbidden phrases in recent /tmp/dispatch_*.md packets
  2. mission_drift_count: dispatches with mission_fitness=drift in dispatch-log
  3. unaddressed_skill_routes_count: callbacks where catalog skill missing yes|no|n/a
     (heuristic — packets list `skill_auto_routes_addressed=...` field)
  4. recent_closed_beads_without_evidence: closed beads (last 24h) with no
     .flywheel/evidence/<bead-id>/ directory present

Default --lookback-hours 24. Emits findings as JSON; never auto-dispatches.

Exit codes:
  0  measurement emitted
  1  no input data in window
  2  config error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg dlog "$DISPATCH_LOG" --arg evid "$EVIDENCE_DIR" --arg brb "$BR_BIN" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$dlog, evidence_dir:$evid, br_bin:$brb,
      reads_only:true, auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","doctor signal candidate"],
      step_4o_compliance:"preserved",
      out_of_scope:["auto-dispatch","Joshua-blocker creation","Pushover notification"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      axes:[
        "punt_phrase_count: L70 forbidden phrases in recent dispatch packets",
        "mission_drift_count: dispatches with mission_fitness=drift",
        "unaddressed_skill_routes_count: skill catalog matched but not addressed",
        "recent_closed_beads_without_evidence: closed beads missing evidence dir"
      ],
      doctrine:"orchestrator behavior should pass the same adversarial audits we run on plans",
      reads_only:true,
      step_4o_compliance:"preserved"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        lookback_hours:{type:"integer"},
        punt_phrase_count:{type:"integer"},
        punt_phrase_samples:{type:"array"},
        mission_drift_count:{type:"integer"},
        unaddressed_skill_routes_count:{type:"integer"},
        recent_closed_beads_without_evidence:{type:"integer"},
        recent_closed_beads_sampled:{type:"integer"},
        adversarial_signal:{type:"boolean"},
        adversarial_axes_triggered:{type:"array"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lookback-hours) LOOKBACK_HOURS="${2:?--lookback-hours requires N}"; shift 2;;
    --dispatch-log) DISPATCH_LOG="${2:?--dispatch-log requires PATH}"; shift 2;;
    --tmp-dispatch-dir) TMP_DISPATCH_DIR="${2:?--tmp-dispatch-dir requires PATH}"; shift 2;;
    --evidence-dir) EVIDENCE_DIR="${2:?--evidence-dir requires PATH}"; shift 2;;
    --br-bin) BR_BIN="${2:?--br-bin requires PATH}"; shift 2;;
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

# --- Axis 1: punt_phrase_count ---
# Scan recent /tmp/dispatch_*.md packets (filed within lookback window) for
# the L70 forbidden phrase catalog (case-insensitive). The orchestrator
# should never name these phrases in its own dispatch packets.
PUNT_PATTERN="$(printf '%s\n' "${PUNT_PHRASES[@]}" | paste -sd '|' -)"
PUNT_COUNT=0
PUNT_SAMPLES_TMP="$(mktemp "${TMPDIR:-/tmp}/punt-samples.XXXXXX")"
trap 'rm -f "$PUNT_SAMPLES_TMP"' EXIT
: >"$PUNT_SAMPLES_TMP"

# find packets within lookback (mtime < N hours ago).
while IFS= read -r packet; do
  [[ -f "$packet" ]] || continue
  matches="$(grep -ciE "$PUNT_PATTERN" "$packet" 2>/dev/null || echo 0)"
  if [[ "$matches" -gt 0 ]]; then
    PUNT_COUNT=$((PUNT_COUNT + matches))
    [[ "$(wc -l <"$PUNT_SAMPLES_TMP" | tr -d ' ')" -lt 5 ]] && \
      printf '{"file":"%s","matches":%s}\n' "$packet" "$matches" >>"$PUNT_SAMPLES_TMP"
  fi
done < <(find "$TMP_DISPATCH_DIR" -maxdepth 1 -name 'dispatch_*.md' -type f \
           -mmin -$((LOOKBACK_HOURS * 60)) 2>/dev/null)
PUNT_SAMPLES_JSON="$(jq -s '.' "$PUNT_SAMPLES_TMP" 2>/dev/null || echo '[]')"

# --- Axis 2: mission_drift_count ---
# Count dispatch_sent rows in dispatch-log within lookback window where
# mission_fitness_class=drift, OR scan packet bodies for that field.
NOW_EPOCH="$(date -u +%s)"
CUTOFF_EPOCH=$((NOW_EPOCH - LOOKBACK_HOURS * 3600))
set +e
DRIFT_COUNT="$(tail -n 5000 "$DISPATCH_LOG" 2>/dev/null \
  | jq -R -c --argjson cutoff "$CUTOFF_EPOCH" '
      fromjson?
      | select(type == "object" and .event == "dispatch_sent" and (.ts // null) != null)
      | (.ts | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime) as $epoch
      | select($epoch >= $cutoff)
      | select((.mission_fitness_class // "") == "drift")' 2>/dev/null \
  | wc -l | tr -d ' ')"
set -e
DRIFT_COUNT="${DRIFT_COUNT:-0}"

# --- Axis 3: unaddressed_skill_routes_count ---
# Heuristic — recent dispatch packets with `skill_auto_routes_addressed=`
# field where some catalog skill is missing yes|no|n/a. A correct addressed
# field has the pattern `skill=yes|no|n/a` for every catalog skill.
UNADDRESSED_COUNT=0
while IFS= read -r packet; do
  [[ -f "$packet" ]] || continue
  matched="$(grep -m1 -E '^skill_auto_routes_matched=' "$packet" 2>/dev/null | head -1)"
  addressed="$(grep -m1 -E '^skill_auto_routes_addressed=' "$packet" 2>/dev/null | head -1)"
  [[ -z "$matched" || -z "$addressed" ]] && continue
  m_list="${matched#skill_auto_routes_matched=}"
  a_list="${addressed#skill_auto_routes_addressed=}"
  ok=true
  IFS=',' read -r -a matched_arr <<<"$m_list"
  for s in "${matched_arr[@]}"; do
    s="$(printf '%s' "$s" | tr -d ' \r\n')"
    [[ -n "$s" ]] || continue
    if ! grep -qE "(^|,)${s}=(yes|no|n/a)(,|$)" <<<"$a_list"; then
      ok=false
      break
    fi
  done
  [[ "$ok" == "false" ]] && UNADDRESSED_COUNT=$((UNADDRESSED_COUNT + 1))
done < <(find "$TMP_DISPATCH_DIR" -maxdepth 1 -name 'dispatch_*.md' -type f \
           -mmin -$((LOOKBACK_HOURS * 60)) 2>/dev/null)

# --- Axis 4: recent_closed_beads_without_evidence ---
# Sample last 30 closed beads from `br list --json --status closed`; for each,
# check whether `.flywheel/evidence/<bead-id>/` exists. Beads without evidence
# are suspicious closures.
CLOSED_TMP="$(mktemp "${TMPDIR:-/tmp}/closed-sample.XXXXXX")"
trap 'rm -f "$PUNT_SAMPLES_TMP" "$CLOSED_TMP"' EXIT
: >"$CLOSED_TMP"
set +e
"$BR_BIN" list --json --status closed --limit 30 2>/dev/null \
  | jq -r '.issues[]?.id // empty' 2>/dev/null \
  > "$CLOSED_TMP"
set -e
CLOSED_SAMPLED="$(wc -l <"$CLOSED_TMP" | tr -d ' ')"
NO_EVIDENCE_COUNT=0
while IFS= read -r bead_id; do
  [[ -n "$bead_id" ]] || continue
  if [[ ! -d "$EVIDENCE_DIR/$bead_id" ]]; then
    NO_EVIDENCE_COUNT=$((NO_EVIDENCE_COUNT + 1))
  fi
done <"$CLOSED_TMP"

# --- Aggregate ---
AXES_TRIGGERED=()
[[ "$PUNT_COUNT" -gt 0 ]]                 && AXES_TRIGGERED+=("punt_phrase_in_dispatch_packet")
[[ "$DRIFT_COUNT" -gt 0 ]]                && AXES_TRIGGERED+=("mission_drift_dispatch")
[[ "$UNADDRESSED_COUNT" -gt 0 ]]          && AXES_TRIGGERED+=("skill_routes_not_addressed")
[[ "$NO_EVIDENCE_COUNT" -gt 5 ]]          && AXES_TRIGGERED+=("closed_beads_missing_evidence_above_5")

ADVERSARIAL_SIGNAL=false
[[ "${#AXES_TRIGGERED[@]}" -gt 0 ]] && ADVERSARIAL_SIGNAL=true

AXES_JSON="$(printf '%s\n' "${AXES_TRIGGERED[@]:-}" | jq -R -s 'split("\n") | map(select(length > 0))')"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson lookback "$LOOKBACK_HOURS" \
  --argjson punt "$PUNT_COUNT" \
  --argjson punt_samples "$PUNT_SAMPLES_JSON" \
  --argjson drift "$DRIFT_COUNT" \
  --argjson unaddressed "$UNADDRESSED_COUNT" \
  --argjson no_evidence "$NO_EVIDENCE_COUNT" \
  --argjson sampled "$CLOSED_SAMPLED" \
  --argjson signal "$ADVERSARIAL_SIGNAL" \
  --argjson axes "$AXES_JSON" \
  '{schema_version:$schema, ts:$ts, success:true, mode:"run",
    lookback_hours:$lookback,
    punt_phrase_count:$punt,
    punt_phrase_samples:$punt_samples,
    mission_drift_count:$drift,
    unaddressed_skill_routes_count:$unaddressed,
    recent_closed_beads_without_evidence:$no_evidence,
    recent_closed_beads_sampled:$sampled,
    adversarial_signal:$signal,
    adversarial_axes_triggered:$axes,
    reads_only:true, auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"adversarial-orch-audit lookback=\(.lookback_hours)h punt=\(.punt_phrase_count) drift=\(.mission_drift_count) unaddressed_skills=\(.unaddressed_skill_routes_count) closed_no_evidence=\(.recent_closed_beads_without_evidence)/\(.recent_closed_beads_sampled) signal=\(.adversarial_signal) axes=\(.adversarial_axes_triggered | join(\",\"))"' <<<"$PAYLOAD"
fi
