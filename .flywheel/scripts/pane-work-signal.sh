#!/bin/bash
# pane-work-signal.sh — pane work-signal via robot tail hash delta
#
# RATIONALE: legacy health-table activity/progress.stage fields were unreliable
# for Codex panes on Joshua's hardware. Robot mode now provides canonical
# `--robot-activity` for semantic state and `--robot-tail` for recent output.
# This helper keeps the historical hash-delta signal but consumes robot
# surfaces instead of legacy copy/health scraping.
#
# OUTPUT: appends one row per call to ~/.local/state/flywheel/pane-work-signal.jsonl
#         and prints a single-line summary to stdout.
#
# USAGE:
#   pane-work-signal.sh <session> <pane> [--lines N]   # one sample
#   pane-work-signal.sh --status <session> <pane>      # read latest signal
#   pane-work-signal.sh --classify <session> <pane>    # working|idle|stale
#       (looks at last K samples; defaults vary by agent_kind)
#
# CLASSIFY THRESHOLDS (samples in trailing 90s window):
#   working: at least 1 hash change in window
#   idle:    0 hash changes AND 0 changes in topology/agent_status
#   stale:   0 hash changes for >5 min AND last activity >5 min
#
# Detection windows differ by agent kind:
#   cc    → 30s (claude code outputs steadily)
#   cod   → 90s (codex has long inter-tool gaps)
#   user  → 30s (raw shells go quiet fast)

set -euo pipefail

STATE_DIR="${FLYWHEEL_STATE_DIR:-$HOME/.local/state/flywheel}"
JSONL="$STATE_DIR/pane-work-signal.jsonl"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
RECENCY_CLASSIFIER_BIN="${RECENCY_CLASSIFIER_BIN:-$ROOT/.flywheel/scripts/recency-weighted-two-truth-classifier.sh}"
RECENCY_CLASSIFIER_DIVERGENCE_LOG="${RECENCY_CLASSIFIER_DIVERGENCE_LOG:-$HOME/.local/state/flywheel/classifier-divergence-log.jsonl}"
APPEND_SAFE_WRITE="${APPEND_SAFE_WRITE:-$ROOT/.flywheel/scripts/append-safe-write.sh}"
mkdir -p "$STATE_DIR"

usage() {
    sed -n '2,/^$/p' "$0" | head -40
    exit 2
}

append_classifier_divergence() {
    local row="$1" key="$2"
    mkdir -p "$(dirname "$RECENCY_CLASSIFIER_DIVERGENCE_LOG")" 2>/dev/null || return 0
    if [ -x "$APPEND_SAFE_WRITE" ]; then
        printf '%s\n' "$row" | "$APPEND_SAFE_WRITE" --target "$RECENCY_CLASSIFIER_DIVERGENCE_LOG" --idempotency-key "$key" --json >/dev/null 2>&1 || true
    else
        printf '%s\n' "$row" >>"$RECENCY_CLASSIFIER_DIVERGENCE_LOG" 2>/dev/null || true
    fi
}

warn_on_classifier_divergence() {
    local activity_json="$1" old="$2" out new key row
    [ "${RECENCY_CLASSIFIER_DISABLE:-0}" = "1" ] && return 0
    [ -x "$RECENCY_CLASSIFIER_BIN" ] || return 0
    out="$(RECENCY_CLASSIFIER_ACTIVITY_JSON="$activity_json" bash "$RECENCY_CLASSIFIER_BIN" --session "$SESSION" --pane "$PANE" --json 2>/dev/null || true)"
    new="$(jq -r '.verdict // empty' <<<"$out" 2>/dev/null || true)"
    [ -n "$new" ] && [ "$new" != "UNKNOWN" ] && [ "$new" != "$old" ] || return 0
    key="pane-work-signal:$SESSION:$PANE:$old:$new"
    row="$(jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg source "pane-work-signal.sh" --arg session "$SESSION" --arg pane "$PANE" --arg old "$old" --arg new "$new" --argjson classifier "$out" '{ts:$ts,source:$source,session:$session,pane:($pane|tonumber? // $pane),old_verdict:$old,new_verdict:$new,mode:"warn",used_verdict:"old",classifier:$classifier}')"
    append_classifier_divergence "$row" "$key"
}

[[ $# -lt 1 ]] && usage

MODE="sample"
case "$1" in
    --status) MODE="status"; shift ;;
    --classify) MODE="classify"; shift ;;
    -h|--help) usage ;;
esac

SESSION="${1:?session required}"
PANE="${2:?pane required}"
LINES="${LINES:-50}"
[[ "${3:-}" == "--lines" ]] && LINES="${4:-50}"

case "$MODE" in
    sample)
        TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        TMPFILE=$(mktemp -t pane-work-signal.XXXXXX)
        trap 'rm -f "$TMPFILE"' EXIT

        TAIL_JSON=$(/Users/josh/.local/bin/ntm --robot-tail="$SESSION" --panes="$PANE" --lines="$LINES" 2>/dev/null || true)
        if ! echo "$TAIL_JSON" | jq -e --arg pane "$PANE" '.success == true and (.panes[$pane].lines | type == "array")' >/dev/null 2>&1; then
            ROW=$(jq -nc \
                --arg ts "$TS" --arg session "$SESSION" --arg pane "$PANE" \
                '{ts:$ts, session:$session, pane:($pane|tonumber), error:"robot_tail_failed"}')
            echo "$ROW" >> "$JSONL"
            echo "$ROW"
            exit 1
        fi
        echo "$TAIL_JSON" | jq -r --arg pane "$PANE" '.panes[$pane].lines[]' > "$TMPFILE"

        # Hash + line count are the truth signals
        HASH=$(shasum "$TMPFILE" | cut -c1-12)
        LINE_COUNT=$(wc -l <"$TMPFILE" | tr -d ' ')
        BYTE_COUNT=$(wc -c <"$TMPFILE" | tr -d ' ')

        ACTIVITY=$(/Users/josh/.local/bin/ntm --robot-activity="$SESSION" --panes="$PANE" 2>/dev/null || echo '{}')
        AGENT=$(echo "$ACTIVITY" | jq -c --argjson p "$PANE" '.agents[]? | select((.pane_idx // (.pane|tonumber?)) == $p)' 2>/dev/null || echo '{}')
        AGENT_KIND=$(echo "$AGENT" | jq -r '.agent_type // "unknown"')
        NTM_ACTIVITY=$(echo "$AGENT" | jq -r '.state // "unknown"')
        NTM_STAGE=$(echo "$AGENT" | jq -r '.state // "unknown"')
        NTM_IDLE_S=$(echo "$AGENT" | jq -r '.idle_seconds // -1')
        warn_on_classifier_divergence "$ACTIVITY" "$NTM_ACTIVITY"

        ROW=$(jq -nc \
            --arg ts "$TS" --arg session "$SESSION" --argjson pane "$PANE" \
            --arg hash "$HASH" --argjson lines "$LINE_COUNT" --argjson bytes "$BYTE_COUNT" \
            --arg agent_kind "$AGENT_KIND" --arg ntm_activity "$NTM_ACTIVITY" \
            --arg ntm_stage "$NTM_STAGE" --argjson ntm_idle_s "$NTM_IDLE_S" \
            '{ts:$ts, session:$session, pane:$pane, hash:$hash, lines:$lines, bytes:$bytes,
              agent_kind:$agent_kind, ntm_activity:$ntm_activity, ntm_stage:$ntm_stage, ntm_idle_s:$ntm_idle_s}')
        echo "$ROW" >> "$JSONL"
        echo "$ROW"
        ;;

    status)
        # Latest sample for this session+pane
        jq -c --arg s "$SESSION" --argjson p "$PANE" \
            'select(.session == $s and .pane == $p)' "$JSONL" 2>/dev/null | tail -1
        ;;

    classify)
        # Window thresholds by agent kind (heuristic, can be tuned)
        WINDOW_S=90
        STALE_S=300

        # Get all rows for this session+pane in trailing window
        NOW_EPOCH=$(date -u +%s)
        CUTOFF=$((NOW_EPOCH - WINDOW_S))
        STALE_CUTOFF=$((NOW_EPOCH - STALE_S))

        ROWS=$(jq -c --arg s "$SESSION" --argjson p "$PANE" --argjson cutoff "$CUTOFF" '
            select(.session == $s and .pane == $p) |
            select(((.ts | fromdateiso8601? // 0) >= $cutoff))
        ' "$JSONL" 2>/dev/null || true)

        if [[ -z "$ROWS" ]]; then
            echo "no_data"
            exit 0
        fi

        # Count distinct hashes in window
        DISTINCT_HASHES=$(echo "$ROWS" | jq -r '.hash' | sort -u | wc -l | tr -d ' ')
        SAMPLE_COUNT=$(echo "$ROWS" | wc -l | tr -d ' ')

        # Latest sample for staleness check
        LATEST_TS=$(echo "$ROWS" | jq -r '.ts' | tail -1)
        LATEST_EPOCH=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$LATEST_TS" +%s 2>/dev/null || echo 0)

        if [[ $DISTINCT_HASHES -gt 1 ]]; then
            CLASSIFICATION="working"
        elif [[ $LATEST_EPOCH -lt $STALE_CUTOFF ]]; then
            CLASSIFICATION="stale"
        else
            CLASSIFICATION="idle"
        fi

        jq -nc \
            --arg classification "$CLASSIFICATION" \
            --arg session "$SESSION" --argjson pane "$PANE" \
            --argjson distinct_hashes "$DISTINCT_HASHES" \
            --argjson sample_count "$SAMPLE_COUNT" \
            --argjson window_s "$WINDOW_S" \
            '{classification:$classification, session:$session, pane:$pane,
              distinct_hashes:$distinct_hashes, sample_count:$sample_count, window_s:$window_s}'
        ;;
esac
