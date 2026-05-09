#!/usr/bin/env bash
# dispatch-surface-conflict-probe.sh — close flywheel-x6h.1.
#
# Detects when a candidate dispatch packet would write the same on-disk surface
# as another in-flight dispatch in the recent window. Replaces per-bead-only
# dedupe with per-write-surface dedupe so two beads pointing at the same file
# can't be assigned to two panes concurrently.
#
# Inputs:
#   --candidate-task-file PATH    dispatch packet path (preferred)
#   --candidate-text-file PATH    arbitrary text file (any markdown with paths)
#   --lookback-minutes N          how far back to look in dispatch-log (default 30)
#   --dispatch-log PATH           override default ~/.flywheel/dispatch-log.jsonl
#   --extra-surface-pattern RE    regex to match additional surface paths
#                                 (default: /Users/josh/[A-Za-z0-9_./-]+)
#   --self-task-id ID             ignore in-flight rows whose task_id matches
#                                 (so re-running the probe on a packet that
#                                 already lives in dispatch-log is clean)
#   --json                        emit JSON receipt (default for CI use)
#   --doctor|--health|--info|--schema   canonical-cli-scoping triad
#
# Output JSON shape:
#   {
#     verdict: "ok" | "conflict",
#     candidate_task_file, candidate_bead_id, candidate_surfaces[],
#     in_flight_count,
#     conflicts: [{ bead_id, task_id, task_file, overlapping_surfaces[] }]
#   }
#
# Exit codes:
#   0  no conflict (verdict=ok)
#   1  conflict detected (verdict=conflict)
#   2  config / usage error
set -euo pipefail

SCHEMA_VERSION="dispatch-surface-conflict-probe.v1"
DEFAULT_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
DEFAULT_PATTERN='/Users/josh/[A-Za-z0-9_./-]+'

CANDIDATE_TASK_FILE=""
CANDIDATE_TEXT_FILE=""
LOOKBACK_MIN=30
LOG_PATH="$DEFAULT_LOG"
EXTRA_PATTERN="$DEFAULT_PATTERN"
SELF_TASK_ID=""
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: dispatch-surface-conflict-probe.sh
         (--candidate-task-file PATH | --candidate-text-file PATH)
         [--lookback-minutes N]
         [--dispatch-log PATH]
         [--extra-surface-pattern RE]
         [--self-task-id ID]
         [--json]
       dispatch-surface-conflict-probe.sh --doctor|--health|--info|--schema [--json]

Detects whether a candidate dispatch packet's write surfaces overlap with
any in-flight dispatch in the recent window.

Default lookback: 30 minutes. Default surface regex: /Users/josh/[A-Za-z0-9_./-]+

Exit 0 = no conflict, 1 = conflict, 2 = config error.
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$log,
      log_present:($log | (. as $p | "" + $p) | test("\\.jsonl$")),
      reads_only:true,
      enforces:["per-write-surface dedupe across panes"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      verdict_classes:["ok","conflict"],
      surface_extraction:"absolute /Users/josh/... paths in candidate body, sorted+unique",
      in_flight_window:"dispatch-log rows with event=dispatch_sent in lookback window"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        verdict:{enum:["ok","conflict"]},
        candidate_task_file:{type:["string","null"]},
        candidate_bead_id:{type:["string","null"]},
        candidate_surfaces:{type:"array"},
        in_flight_count:{type:"integer"},
        conflicts:{type:"array"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --candidate-task-file) CANDIDATE_TASK_FILE="${2:?--candidate-task-file requires PATH}"; shift 2;;
    --candidate-text-file) CANDIDATE_TEXT_FILE="${2:?--candidate-text-file requires PATH}"; shift 2;;
    --lookback-minutes) LOOKBACK_MIN="${2:?--lookback-minutes requires N}"; shift 2;;
    --dispatch-log) LOG_PATH="${2:?--dispatch-log requires PATH}"; shift 2;;
    --extra-surface-pattern) EXTRA_PATTERN="${2:?--extra-surface-pattern requires RE}"; shift 2;;
    --self-task-id) SELF_TASK_ID="${2:?--self-task-id requires ID}"; shift 2;;
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

if [[ -z "$CANDIDATE_TASK_FILE" && -z "$CANDIDATE_TEXT_FILE" ]]; then
  echo "ERR: must pass --candidate-task-file or --candidate-text-file" >&2
  usage >&2; exit 2
fi
[[ -f "$LOG_PATH" ]] || { echo "ERR: dispatch-log not found: $LOG_PATH" >&2; exit 2; }

CANDIDATE_PATH="${CANDIDATE_TASK_FILE:-$CANDIDATE_TEXT_FILE}"
[[ -f "$CANDIDATE_PATH" ]] || { echo "ERR: candidate file not found: $CANDIDATE_PATH" >&2; exit 2; }

extract_surfaces() {
  # Match candidates, then strip trailing prose punctuation that the regex's
  # `+` quantifier may have absorbed (e.g. `.md.` at end-of-sentence).
  local file="$1"
  grep -oE "$EXTRA_PATTERN" "$file" 2>/dev/null \
    | sed -E 's/[.,;:)>"'"'"'\)]+$//' \
    | sort -u
}

CANDIDATE_BEAD_ID=""
if [[ -n "$CANDIDATE_TASK_FILE" ]]; then
  CANDIDATE_BEAD_ID="$(grep -oE '^# Bead: [a-zA-Z0-9._-]+' "$CANDIDATE_TASK_FILE" 2>/dev/null | head -1 | awk '{print $3}' || echo "")"
fi

CANDIDATE_SURFACES_RAW="$(extract_surfaces "$CANDIDATE_PATH")"
CANDIDATE_SURFACES_JSON="$(printf '%s\n' "$CANDIDATE_SURFACES_RAW" | jq -R -s 'split("\n") | map(select(length > 0))')"

# Window cutoff in epoch seconds
NOW_EPOCH="$(date -u +%s)"
WINDOW_CUTOFF=$((NOW_EPOCH - LOOKBACK_MIN * 60))

# Read in-flight rows (event=dispatch_sent within window).
IN_FLIGHT_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-conflict-inflight.XXXXXX")"
trap 'rm -f "$IN_FLIGHT_TMP"' EXIT

while IFS= read -r row; do
  ev="$(jq -r '.event // ""' <<<"$row" 2>/dev/null)"
  [[ "$ev" == "dispatch_sent" ]] || continue
  ts_iso="$(jq -r '.ts // ""' <<<"$row")"
  [[ -n "$ts_iso" ]] || continue
  row_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${ts_iso%%.*}Z" +%s 2>/dev/null \
            || date -u -d "$ts_iso" +%s 2>/dev/null \
            || echo 0)"
  [[ "$row_epoch" -ge "$WINDOW_CUTOFF" ]] || continue
  rid="$(jq -r '.task_id // ""' <<<"$row")"
  [[ -n "$SELF_TASK_ID" && "$rid" == "$SELF_TASK_ID" ]] && continue
  printf '%s\n' "$row" >>"$IN_FLIGHT_TMP"
done < <(tail -n 500 "$LOG_PATH")

CONFLICTS_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-conflict-out.XXXXXX")"
trap 'rm -f "$IN_FLIGHT_TMP" "$CONFLICTS_TMP"' EXIT
: >"$CONFLICTS_TMP"

IN_FLIGHT_COUNT=0
while IFS= read -r row; do
  IN_FLIGHT_COUNT=$((IN_FLIGHT_COUNT + 1))
  task_id="$(jq -r '.task_id // ""' <<<"$row")"
  bead_id="$(jq -r '.bead_id // ""' <<<"$row")"
  task_file="$(jq -r '.task_file // ""' <<<"$row")"

  [[ -n "$task_file" && -f "$task_file" ]] || continue

  in_flight_surfaces="$(extract_surfaces "$task_file")"
  [[ -n "$in_flight_surfaces" ]] || continue

  overlap="$(comm -12 <(printf '%s\n' "$CANDIDATE_SURFACES_RAW" | sort -u) \
                       <(printf '%s\n' "$in_flight_surfaces" | sort -u))"
  if [[ -n "$overlap" ]]; then
    overlap_json="$(printf '%s\n' "$overlap" | jq -R -s 'split("\n") | map(select(length > 0))')"
    jq -nc \
      --arg bead_id "$bead_id" \
      --arg task_id "$task_id" \
      --arg task_file "$task_file" \
      --argjson overlap "$overlap_json" \
      '{bead_id:$bead_id, task_id:$task_id, task_file:$task_file, overlapping_surfaces:$overlap}' \
      >>"$CONFLICTS_TMP"
  fi
done <"$IN_FLIGHT_TMP"

CONFLICT_COUNT="$(wc -l <"$CONFLICTS_TMP" | tr -d ' ')"
VERDICT=ok
EXIT_CODE=0
[[ "$CONFLICT_COUNT" -gt 0 ]] && { VERDICT=conflict; EXIT_CODE=1; }

CONFLICTS_JSON="$(jq -s '.' "$CONFLICTS_TMP")"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg verdict "$VERDICT" \
  --arg candidate_path "$CANDIDATE_PATH" \
  --arg candidate_bead "$CANDIDATE_BEAD_ID" \
  --argjson candidate_surfaces "$CANDIDATE_SURFACES_JSON" \
  --argjson in_flight "$IN_FLIGHT_COUNT" \
  --argjson conflicts "$CONFLICTS_JSON" \
  '{schema_version:$schema, success:($verdict == "ok"),
    mode:"run", verdict:$verdict,
    candidate_task_file:$candidate_path,
    candidate_bead_id:(if $candidate_bead == "" then null else $candidate_bead end),
    candidate_surfaces:$candidate_surfaces,
    in_flight_count:$in_flight,
    conflicts:$conflicts}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"dispatch-surface-conflict verdict=\(.verdict) candidate=\(.candidate_bead_id // "?") candidate_surfaces=\(.candidate_surfaces | length) in_flight=\(.in_flight_count) conflicts=\(.conflicts | length)"' <<<"$PAYLOAD"
fi

exit "$EXIT_CODE"
