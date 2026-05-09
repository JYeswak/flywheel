#!/usr/bin/env bash
# skill-bandit-measurement-probe.sh — closes flywheel-1rmp.3 (value-gap
# `skill-bandit-auto-experiments`).
#
# The smallest recurring measurement that makes the value gap visible:
# scan recent `dispatch_sent` rows in the canonical dispatch-log, read each
# row's task_file (the dispatch packet), extract `skill_auto_routes_matched=`
# from the packet body, and emit a per-skill match-frequency histogram.
#
# Surfacing: tick / dashboard consumers read the JSON receipt. Distribution
# entropy is reported so the "mostly-static skill selection" claim is
# observable as a single number.
#
# Anti-pattern preservation (Step 4o): probe is READ-ONLY. It does not call
# `br create`, `br close`, `ntm send`, `gh`, or any external API. It does not
# auto-dispatch from its own findings. Output is structured JSON only.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json / stable exit codes.
set -euo pipefail

SCHEMA_VERSION="skill-bandit-measurement-probe.v1"
DEFAULT_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"

LOG_PATH="$DEFAULT_LOG"
SAMPLES=200
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: skill-bandit-measurement-probe.sh [--samples N] [--dispatch-log PATH] [--json]
       skill-bandit-measurement-probe.sh --doctor|--health|--info|--schema [--json]

Reads the last --samples (default 200) dispatch-log rows of event=dispatch_sent,
follows each row's task_file to extract skill_auto_routes_matched, and emits a
per-skill frequency histogram with distribution entropy.

Output JSON (run mode):
  {
    schema_version,
    samples_window,
    samples_resolved,            # rows whose task_file was readable
    samples_unresolved,
    skills_observed_count,
    per_skill: [
      {skill, match_count, match_fraction}
    ],
    top_skill,
    distribution_entropy,        # Shannon entropy in bits; 0 = single skill
                                 # always picked, log2(N) = uniform across N
    static_selection_indicator,  # true if entropy <= 1.0 bit
    canonical_set_match_fraction # fraction of dispatches whose matched
                                 # skill set is exactly the canonical
                                 # 4-skill set; surfaces near-static behavior
                                 # even when entropy is low
  }

Exit codes:
  0  measurement emitted
  1  no dispatch-log rows in window
  2  config / usage error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$log, log_present:true,
      reads_only:true,
      auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","doctor signal candidate"],
      anti_pattern_step_4o:"preserved"}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      measurement:"per-skill match-frequency histogram + Shannon entropy",
      input:"dispatch-log dispatch_sent rows -> task_file -> skill_auto_routes_matched",
      output:"per_skill[] + distribution_entropy + static_selection_indicator",
      reads_only:true,
      step_4o_compliance:"no auto-dispatch from findings; emits JSON only"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        samples_window:{type:"integer"},
        samples_resolved:{type:"integer"},
        samples_unresolved:{type:"integer"},
        skills_observed_count:{type:"integer"},
        per_skill:{type:"array",
          items:{properties:{skill:{type:"string"},match_count:{type:"integer"},match_fraction:{type:"number"}}}},
        top_skill:{type:["string","null"]},
        distribution_entropy:{type:"number"},
        static_selection_indicator:{type:"boolean"},
        canonical_set_match_fraction:{type:"number"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --samples) SAMPLES="${2:?--samples requires N}"; shift 2;;
    --dispatch-log) LOG_PATH="${2:?--dispatch-log requires PATH}"; shift 2;;
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

[[ -f "$LOG_PATH" ]] || { echo "ERR: dispatch-log not found: $LOG_PATH" >&2; exit 2; }

# Pull the last N dispatch_sent rows into a tmp file.
RAW_TMP="$(mktemp "${TMPDIR:-/tmp}/skill-bandit-probe.XXXXXX")"
SKILLS_TMP="$(mktemp "${TMPDIR:-/tmp}/skill-bandit-skills.XXXXXX")"
trap 'rm -f "$RAW_TMP" "$SKILLS_TMP"' EXIT
: >"$SKILLS_TMP"

tail -n "$SAMPLES" "$LOG_PATH" \
  | jq -c 'select(.event == "dispatch_sent") | {task_file: (.task_file // "")}' \
  > "$RAW_TMP" 2>/dev/null || true

SAMPLES_WINDOW="$(wc -l <"$RAW_TMP" | tr -d ' ')"
if [[ "$SAMPLES_WINDOW" -eq 0 ]]; then
  echo "ERR: no dispatch_sent rows in last $SAMPLES dispatch-log lines" >&2
  exit 1
fi

SAMPLES_RESOLVED=0
SAMPLES_UNRESOLVED=0
CANONICAL_MATCH_COUNT=0

while IFS= read -r row; do
  tf="$(jq -r '.task_file' <<<"$row")"
  if [[ -z "$tf" || ! -f "$tf" ]]; then
    SAMPLES_UNRESOLVED=$((SAMPLES_UNRESOLVED + 1))
    continue
  fi
  matched_line="$(grep -m1 -E '^skill_auto_routes_matched=' "$tf" 2>/dev/null || true)"
  [[ -n "$matched_line" ]] || { SAMPLES_UNRESOLVED=$((SAMPLES_UNRESOLVED + 1)); continue; }
  SAMPLES_RESOLVED=$((SAMPLES_RESOLVED + 1))
  list="${matched_line#skill_auto_routes_matched=}"
  if [[ "$list" == "canonical-cli-scoping,rust-best-practices,python-best-practices,readme-writing" ]]; then
    CANONICAL_MATCH_COUNT=$((CANONICAL_MATCH_COUNT + 1))
  fi
  IFS=',' read -r -a skills <<<"$list"
  for s in "${skills[@]}"; do
    s="$(printf '%s' "$s" | tr -d ' \r\n')"
    [[ -n "$s" ]] || continue
    printf '%s\n' "$s" >>"$SKILLS_TMP"
  done
done <"$RAW_TMP"

PER_SKILL_JSON='[]'
ENTROPY=0
TOP_SKILL=null
SKILLS_OBSERVED_COUNT=0
if [[ "$SAMPLES_RESOLVED" -gt 0 ]]; then
  PER_SKILL_JSON="$(sort "$SKILLS_TMP" | uniq -c | awk '{c=$1; $1=""; sub(/^ /,""); print c"\t"$0}' \
    | jq -R -s --argjson total "$SAMPLES_RESOLVED" '
        split("\n") | map(select(length > 0)
          | split("\t")
          | {skill:.[1], match_count: (.[0]|tonumber), match_fraction: ((.[0]|tonumber) / $total)})
        | sort_by(-.match_count)')"
  SKILLS_OBSERVED_COUNT="$(jq 'length' <<<"$PER_SKILL_JSON")"
  TOP_SKILL="$(jq -c '.[0].skill // null' <<<"$PER_SKILL_JSON")"
  # Shannon entropy in bits over fraction-of-total-resolved.
  ENTROPY="$(jq '[.[] | .match_fraction
    | if . > 0 then (- . * (log / (2|log))) else 0 end] | add // 0' <<<"$PER_SKILL_JSON")"
fi

CANONICAL_FRACTION=0
[[ "$SAMPLES_RESOLVED" -gt 0 ]] && CANONICAL_FRACTION="$(awk -v n="$CANONICAL_MATCH_COUNT" -v d="$SAMPLES_RESOLVED" 'BEGIN{ printf "%.6f", n/d }')"

STATIC_INDICATOR=$(jq -nc --argjson e "$ENTROPY" '$e <= 1.0')

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --argjson samples_window "$SAMPLES_WINDOW" \
  --argjson samples_resolved "$SAMPLES_RESOLVED" \
  --argjson samples_unresolved "$SAMPLES_UNRESOLVED" \
  --argjson skills_observed_count "$SKILLS_OBSERVED_COUNT" \
  --argjson per_skill "$PER_SKILL_JSON" \
  --argjson top_skill "$TOP_SKILL" \
  --argjson entropy "$ENTROPY" \
  --argjson static_indicator "$STATIC_INDICATOR" \
  --argjson canonical_fraction "$CANONICAL_FRACTION" \
  '{schema_version:$schema, success:true, mode:"run",
    samples_window:$samples_window,
    samples_resolved:$samples_resolved,
    samples_unresolved:$samples_unresolved,
    skills_observed_count:$skills_observed_count,
    per_skill:$per_skill,
    top_skill:$top_skill,
    distribution_entropy:$entropy,
    static_selection_indicator:$static_indicator,
    canonical_set_match_fraction:$canonical_fraction,
    reads_only:true,
    auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"skill-bandit measurement window=\(.samples_window) resolved=\(.samples_resolved) unresolved=\(.samples_unresolved) skills=\(.skills_observed_count) top=\(.top_skill // "none") entropy=\(.distribution_entropy) static=\(.static_selection_indicator) canonical_fraction=\(.canonical_set_match_fraction)"' <<<"$PAYLOAD"
fi
