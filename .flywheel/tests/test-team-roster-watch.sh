#!/usr/bin/env bash
# test-team-roster-watch.sh — fixture regression for flywheel-2wyv.
#
# Asserts the read-only roster watch handles 5 cases without crashing:
#   1. fresh — pulse within --fresh-secs window
#   2. stale-warn — pulse beyond fresh but within --stale-secs window
#   3. stale-error — pulse beyond stale window
#   4. missing — no pulse row for session
#   5. malformed — bad JSON line in roster.jsonl
# Plus the non-TTY watch refusal contract.
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
SCRIPT="$ROOT/.flywheel/scripts/team-roster-watch.sh"

[[ -x "$SCRIPT" ]] || { echo "FAIL: script not executable: $SCRIPT" >&2; exit 2; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/team-roster-watch-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

ROSTER="$TMP/roster.jsonl"
PULSE="$TMP/pulse.jsonl"

now_epoch() { date -u +%s; }
iso_at() {
  local epoch="$1"
  date -u -r "$epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -d "@$epoch" +%Y-%m-%dT%H:%M:%SZ
}

now=$(now_epoch)
ts_fresh="$(iso_at $((now - 30)))"          # 30s ago
ts_stale_warn="$(iso_at $((now - 1000)))"   # ~16m ago (>900 fresh, <3600 stale)
ts_stale_error="$(iso_at $((now - 7200)))"  # 2h ago (>3600 stale)
ts_now="$(iso_at "$now")"

# Roster: 5 valid sessions + 1 malformed line.
{
  jq -nc --arg ts "$ts_now" '{ts:$ts, event:"session_active", session:"sess-fresh",
    orchestrator:{pane:1, kind:"claude"}, workers:[{pane:2, kind:"codex"}],
    current_mission:"fresh fixture mission"}'
  jq -nc --arg ts "$ts_now" '{ts:$ts, event:"session_active", session:"sess-stale-warn",
    orchestrator:{pane:1, kind:"claude"}, workers:[],
    current_mission:"stale-warn fixture"}'
  jq -nc --arg ts "$ts_now" '{ts:$ts, event:"session_active", session:"sess-stale-error",
    orchestrator:{pane:0, kind:"codex"}, workers:[{pane:1, kind:"claude"}],
    current_mission:"stale-error fixture"}'
  jq -nc --arg ts "$ts_now" '{ts:$ts, event:"session_active", session:"sess-missing",
    orchestrator:{pane:2, kind:"codex"}, workers:[{pane:3, kind:"codex"}],
    current_mission:"missing-pulse fixture"}'
  printf '{this is malformed json}\n'  # malformed row
  jq -nc --arg ts "$ts_now" '{ts:$ts, event:"session_active", session:"sess-no-mission",
    orchestrator:{pane:1, kind:"claude"}, workers:[]}'
} >"$ROSTER"

# Pulse: 4 sessions have pulse rows, 1 (sess-missing) deliberately absent.
{
  jq -nc --arg ts "$ts_fresh"        --arg s "sess-fresh"        '{ts:$ts, session:$s}'
  jq -nc --arg ts "$ts_stale_warn"   --arg s "sess-stale-warn"   '{ts:$ts, session:$s}'
  jq -nc --arg ts "$ts_stale_error"  --arg s "sess-stale-error"  '{ts:$ts, session:$s}'
  jq -nc --arg ts "$ts_fresh"        --arg s "sess-no-mission"   '{ts:$ts, session:$s}'
} >"$PULSE"

# Run --once --json against fixtures.
out="$(TEAM_ROSTER_PATH="$ROSTER" TEAM_PULSE_PATH="$PULSE" \
       "$SCRIPT" --once --json --roster "$ROSTER" --pulse "$PULSE")"

[[ "$(jq -r '.roster_present' <<<"$out")" == "true" ]] \
  || { echo "FAIL: roster_present expected true" >&2; echo "$out" >&2; exit 1; }
[[ "$(jq -r '.pulse_present' <<<"$out")" == "true" ]] \
  || { echo "FAIL: pulse_present expected true" >&2; exit 1; }
[[ "$(jq -r '.malformed_roster_rows' <<<"$out")" == "1" ]] \
  || { echo "FAIL: expected malformed_roster_rows=1, got $(jq -r '.malformed_roster_rows' <<<"$out")" >&2; exit 1; }
[[ "$(jq -r '.coordination_authority' <<<"$out")" == "false" ]] \
  || { echo "FAIL: coordination_authority should be false" >&2; exit 1; }
[[ "$(jq -r '.reads_only' <<<"$out")" == "true" ]] \
  || { echo "FAIL: reads_only should be true" >&2; exit 1; }

# Per-session pulse classification.
get_status() { jq -r --arg s "$1" '.sessions[] | select(.session == $s) | .pulse_status' <<<"$out"; }
[[ "$(get_status sess-fresh)"        == "fresh"        ]] || { echo "FAIL: sess-fresh status not fresh: $(get_status sess-fresh)" >&2; exit 1; }
[[ "$(get_status sess-stale-warn)"   == "stale-warn"   ]] || { echo "FAIL: sess-stale-warn status not stale-warn: $(get_status sess-stale-warn)" >&2; exit 1; }
[[ "$(get_status sess-stale-error)"  == "stale-error"  ]] || { echo "FAIL: sess-stale-error status not stale-error: $(get_status sess-stale-error)" >&2; exit 1; }
[[ "$(get_status sess-missing)"      == "missing"      ]] || { echo "FAIL: sess-missing status not missing: $(get_status sess-missing)" >&2; exit 1; }

# 5 valid sessions in output (malformed row excluded).
[[ "$(jq -r '.sessions | length' <<<"$out")" == "5" ]] \
  || { echo "FAIL: expected 5 sessions, got $(jq -r '.sessions | length' <<<"$out")" >&2; exit 1; }

# Watch + non-TTY + non-JSON refusal contract.
rc=0
refuse_out="$(TEAM_ROSTER_PATH="$ROSTER" TEAM_PULSE_PATH="$PULSE" \
              "$SCRIPT" --watch --roster "$ROSTER" --pulse "$PULSE" 2>&1 < /dev/null)" \
  || rc=$?
[[ "$rc" -eq 2 ]] || { echo "FAIL: expected rc=2 on watch+non-TTY+non-JSON, got $rc" >&2; echo "$refuse_out" >&2; exit 1; }
echo "$refuse_out" | grep -q "watch_mode_requires_tty_or_json" \
  || { echo "FAIL: refusal output missing watch_mode_requires_tty_or_json" >&2; echo "$refuse_out" >&2; exit 1; }

# Missing roster path → both flags false.
miss_out="$("$SCRIPT" --once --json --roster "$TMP/no-such.jsonl" --pulse "$TMP/also-no.jsonl")"
[[ "$(jq -r '.roster_present' <<<"$miss_out")" == "false" ]] \
  || { echo "FAIL: missing roster should report roster_present=false" >&2; exit 1; }

printf 'PASS: team-roster-watch — fresh/stale-warn/stale-error/missing/malformed classified, watch+non-TTY refused, missing roster handled\n'
