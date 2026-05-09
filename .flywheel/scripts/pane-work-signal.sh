#!/usr/bin/env bash
# pane-work-signal.sh - pane work signal from native ntm activity/history JSON.
set -euo pipefail

STATE_DIR="${FLYWHEEL_STATE_DIR:-$HOME/.local/state/flywheel}"
JSONL="$STATE_DIR/pane-work-signal.jsonl"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
WORK_WINDOW_S="${WORK_WINDOW_S:-90}"
STALE_S="${STALE_S:-300}"
HISTORY_LIMIT="${HISTORY_LIMIT:-20}"; mkdir -p "$STATE_DIR"
usage() { sed -n '2,20p' "$0"; exit "${1:-2}"; }
[[ $# -lt 1 ]] && usage
MODE="sample"
case "$1" in
  --status) MODE="status"; shift ;;
  --classify) MODE="classify"; shift ;;
  -h|--help) usage 0 ;;
esac

SESSION="${1:?session required}"
PANE="${2:?pane required}"
[[ "${3:-}" == "--lines" ]] && shift 2 # accepted for compatibility; no scrollback read
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
ts_to_epoch() { date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null || echo 0; }
json_or() { local fallback="$1"; shift; "$@" 2>/dev/null || printf '%s\n' "$fallback"; }
state_is_working() { [[ "$1" =~ ^(THINKING|GENERATING|WORKING|RUNNING|STALLED)$ ]]; }
activity_json() {
  [[ -n "${PANE_WORK_SIGNAL_ACTIVITY_JSON:-}" ]] && printf '%s\n' "$PANE_WORK_SIGNAL_ACTIVITY_JSON" || json_or '{"agents":[]}' "$NTM_BIN" activity "$SESSION" --pane "$PANE" --json
}
history_json() {
  [[ -n "${PANE_WORK_SIGNAL_HISTORY_JSON:-}" ]] && printf '%s\n' "$PANE_WORK_SIGNAL_HISTORY_JSON" || json_or '{"entries":[]}' "$NTM_BIN" history --session "$SESSION" --limit "$HISTORY_LIMIT" --json
}
latest_row() {
  jq -c --arg s "$SESSION" --argjson p "$PANE" 'select(.session == $s and .pane == $p)' "$JSONL" 2>/dev/null | tail -1
}
case "$MODE" in
  sample)
    TS="${PANE_WORK_SIGNAL_SAMPLE_TS:-$(now_iso)}"
    ACTIVITY="$(activity_json)"
    HISTORY="$(history_json)"
    AGENT="$(jq -c --argjson p "$PANE" '.agents[]? | select((.pane // .pane_idx // -1) == $p)' <<<"$ACTIVITY" 2>/dev/null | head -1)"
    [[ -n "$AGENT" ]] || AGENT='{}'
    AGENT_KIND="$(jq -r '.agent_type // "unknown"' <<<"$AGENT")"
    NTM_ACTIVITY="$(jq -r '.state // "UNKNOWN"' <<<"$AGENT")"
    NTM_IDLE_S="$(jq -r '.idle_seconds // -1' <<<"$AGENT")"
    HISTORY_COUNT="$(jq -r '(.entries // []) | length' <<<"$HISTORY" 2>/dev/null || echo 0)"
    LAST_HISTORY_TS="$(jq -r '(.entries // []) | max_by(.ts // "") | .ts // ""' <<<"$HISTORY" 2>/dev/null || true)"
    HASH="$(jq -cn --argjson activity "$ACTIVITY" --argjson history "$HISTORY" '{activity:$activity,history:$history}' | shasum | cut -c1-12)"
    BYTE_COUNT="$(jq -cn --argjson activity "$ACTIVITY" --argjson history "$HISTORY" '{activity:$activity,history:$history}' | wc -c | tr -d ' ')"
    if state_is_working "$NTM_ACTIVITY"; then TRUTH_STATE="working"; TRUTH_SOURCE="ntm_activity"; TRUTH_REASON="activity_state_${NTM_ACTIVITY}"; else TRUTH_STATE="sample"; TRUTH_SOURCE="sample"; TRUTH_REASON="sample_row_collected"; fi
    ROW="$(jq -nc --arg ts "$TS" --arg session "$SESSION" --argjson pane "$PANE" --arg hash "$HASH" --argjson lines "$HISTORY_COUNT" --argjson bytes "$BYTE_COUNT" --arg agent_kind "$AGENT_KIND" --arg ntm_activity "$NTM_ACTIVITY" --argjson ntm_idle_s "$NTM_IDLE_S" --arg last_history_ts "$LAST_HISTORY_TS" --arg truth_state "$TRUTH_STATE" --arg truth_source "$TRUTH_SOURCE" --arg truth_reason "$TRUTH_REASON" '{ts:$ts,session:$session,pane:$pane,hash:$hash,lines:$lines,bytes:$bytes,agent_kind:$agent_kind,ntm_activity:$ntm_activity,ntm_stage:$ntm_activity,ntm_idle_s:$ntm_idle_s,last_history_ts:$last_history_ts,foreground_working_state:false,foreground_working_evidence:"",truth_state:$truth_state,truth_source:$truth_source,truth_reason:$truth_reason,classification:$truth_state}')"
    printf '%s\n' "$ROW" >>"$JSONL"; printf '%s\n' "$ROW"
    ;;
  status)
    latest_row
    ;;
  classify)
    NOW_EPOCH="$(date -u +%s)"; CUTOFF=$((NOW_EPOCH - WORK_WINDOW_S)); STALE_CUTOFF=$((NOW_EPOCH - STALE_S))
    ROWS="$(jq -c --arg s "$SESSION" --argjson p "$PANE" --argjson cutoff "$CUTOFF" 'select(.session == $s and .pane == $p) | select(((.ts | fromdateiso8601? // 0) >= $cutoff))' "$JSONL" 2>/dev/null || true)"
    ALL_ROWS="$(jq -c --arg s "$SESSION" --argjson p "$PANE" 'select(.session == $s and .pane == $p)' "$JSONL" 2>/dev/null || true)"
    if [[ -z "$ALL_ROWS" ]]; then
      jq -nc --arg session "$SESSION" --argjson pane "$PANE" --argjson window_s "$WORK_WINDOW_S" '{truth_state:"no_data",truth_source:"missing_sample",truth_reason:"no_rows_for_session_pane",session:$session,pane:$pane,sample_count:0,distinct_hashes:0,window_s:$window_s,foreground_working_state:false,foreground_working_evidence:""}'
      exit 0
    fi
    LATEST_ROW="$(printf '%s\n' "$ALL_ROWS" | tail -1)"
    LATEST_TS="$(jq -r '.ts // ""' <<<"$LATEST_ROW")"
    LATEST_EPOCH="$(ts_to_epoch "$LATEST_TS")"
    NTM_ACTIVITY="$(jq -r '.ntm_activity // "UNKNOWN"' <<<"$LATEST_ROW")"
    AGENT_KIND="$(jq -r '.agent_kind // "unknown"' <<<"$LATEST_ROW")"
    if [[ -z "$ROWS" ]]; then
      if [[ "$AGENT_KIND" == "codex" && "$LATEST_EPOCH" -lt "$STALE_CUTOFF" ]]; then CLASSIFICATION="stale"; CLASS_SOURCE="pane_work_signal"; CLASS_REASON="no_usable_sample_older_than_${STALE_S}s"
      elif state_is_working "$NTM_ACTIVITY"; then CLASSIFICATION="working"; CLASS_SOURCE="ntm_activity"; CLASS_REASON="activity_state_${NTM_ACTIVITY}"
      else CLASSIFICATION="idle"; CLASS_SOURCE="ntm_activity"; CLASS_REASON="no_recent_window_rows"; fi
      jq -nc --arg c "$CLASSIFICATION" --arg s "$SESSION" --argjson p "$PANE" --arg source "$CLASS_SOURCE" --arg reason "$CLASS_REASON" --arg ts "$LATEST_TS" --arg ntm "$NTM_ACTIVITY" '{truth_state:$c,classification:$c,session:$s,pane:$p,truth_source:$source,truth_reason:$reason,ntm_activity:$ntm,ts:$ts,foreground_working_state:false,foreground_working_evidence:""}'
      exit 0
    fi
    DISTINCT_HASHES="$(jq -r '.hash' <<<"$ROWS" | sort -u | wc -l | tr -d ' ')"
    SAMPLE_COUNT="$(wc -l <<<"$ROWS" | tr -d ' ')"
    FOREGROUND_ROWS="$(jq -r 'select(.foreground_working_state == true) | .ts' <<<"$ROWS" | wc -l | tr -d ' ')"
    FOREGROUND_EVIDENCE="$(jq -r 'select(.foreground_working_state == true) | .foreground_working_evidence // ""' <<<"$ROWS" | tail -1)"
    if (( FOREGROUND_ROWS > 0 )); then CLASSIFICATION="working"; CLASS_SOURCE="pane_work_signal"; CLASS_REASON="foreground_working_structured_row"
    elif state_is_working "$NTM_ACTIVITY"; then CLASSIFICATION="working"; CLASS_SOURCE="ntm_activity"; CLASS_REASON="activity_state_${NTM_ACTIVITY}"
    elif [[ "$DISTINCT_HASHES" -gt 1 ]]; then CLASSIFICATION="working"; CLASS_SOURCE="pane_work_signal"; CLASS_REASON="activity_history_delta_within_${WORK_WINDOW_S}s"
    elif [[ "$AGENT_KIND" == "codex" && "$LATEST_EPOCH" -lt "$STALE_CUTOFF" ]]; then CLASSIFICATION="stale"; CLASS_SOURCE="pane_work_signal"; CLASS_REASON="no_usable_sample_older_than_${STALE_S}s"
    else CLASSIFICATION="idle"; CLASS_SOURCE="ntm_health"; CLASS_REASON="no_activity_no_history_delta"; fi
    jq -nc --arg classification "$CLASSIFICATION" --arg session "$SESSION" --argjson pane "$PANE" --arg source "$CLASS_SOURCE" --arg reason "$CLASS_REASON" --argjson distinct_hashes "$DISTINCT_HASHES" --argjson sample_count "$SAMPLE_COUNT" --argjson window_s "$WORK_WINDOW_S" --arg ts "$LATEST_TS" --arg evidence "$FOREGROUND_EVIDENCE" '{truth_state:$classification,session:$session,pane:$pane,truth_source:$source,truth_reason:$reason,classification:$classification,sample_count:$sample_count,distinct_hashes:$distinct_hashes,window_s:$window_s,ts:$ts,foreground_working_state:($evidence != ""),foreground_working_evidence:$evidence}'
    ;;
esac
