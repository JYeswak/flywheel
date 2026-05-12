#!/usr/bin/env bash
# test-dispatch-surface-conflict-probe.sh — fixture regression for the bead
# flywheel-x6h.1 scenario: two beads (i9o + x6h) targeting the same on-disk
# surface dispatched within the same window. Probe must flag them as
# verdict=conflict.
#
# Fixture-only — never reads or mutates real dispatch-log.jsonl.
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
PROBE="$ROOT/.flywheel/scripts/dispatch-surface-conflict-probe.sh"

[[ -x "$PROBE" ]] || { echo "FAIL: probe not executable: $PROBE" >&2; exit 2; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-conflict-probe-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SHARED_SURFACE="/Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop.README.md"
OTHER_SURFACE="/Users/josh/Developer/flywheel/.flywheel/scripts/something-else.sh"

# In-flight dispatch packet for the i9o-shape bead (same shared surface).
mkdir -p "$TMP/dispatch-files"
I9O_PACKET="$TMP/dispatch-files/dispatch_flywheel-i9o-0d7bc675.md"
cat >"$I9O_PACKET" <<EOF
# DISPATCH PACKET
# Task ID: flywheel-i9o-0d7bc675
# Bead: flywheel-i9o (P1)
# Title: rewrite autoloop README

Edits to $SHARED_SURFACE plus $OTHER_SURFACE.
EOF

# Candidate dispatch packet (the x6h-shape bead) — same shared surface.
X6H_PACKET="$TMP/dispatch-files/dispatch_flywheel-x6h-36d443ad.md"
cat >"$X6H_PACKET" <<EOF
# DISPATCH PACKET
# Task ID: flywheel-x6h-36d443ad
# Bead: flywheel-x6h (P1)
# Title: also touches autoloop README

The bead also targets $SHARED_SURFACE.
EOF

# Independent candidate (no shared surface) — should pass.
INDEPENDENT_PACKET="$TMP/dispatch-files/dispatch_flywheel-zzz-aaaaa.md"
cat >"$INDEPENDENT_PACKET" <<EOF
# DISPATCH PACKET
# Task ID: flywheel-zzz-aaaaa
# Bead: flywheel-zzz (P3)
# Title: independent work

Touches /Users/josh/Developer/flywheel/.flywheel/scripts/independent-target.sh
EOF

# Synthetic dispatch-log with one in-flight row pointing at the i9o packet.
LOG="$TMP/dispatch-log.jsonl"
jq -nc \
  --arg ts "$NOW_ISO" \
  --arg task_id "flywheel-i9o-0d7bc675" \
  --arg bead_id "flywheel-i9o" \
  --arg task_file "$I9O_PACKET" \
  '{schema_version:2, event:"dispatch_sent", ts:$ts, task_id:$task_id, bead_id:$bead_id, task_file:$task_file}' >"$LOG"

# Case 1: x6h candidate against in-flight i9o → expect conflict.
rc=0
out_conflict="$("$PROBE" \
  --candidate-task-file "$X6H_PACKET" \
  --dispatch-log "$LOG" \
  --lookback-minutes 30 \
  --json 2>&1)" || rc=$?
if [[ "$rc" -ne 1 ]]; then
  echo "FAIL: expected rc=1 on conflict, got $rc" >&2
  echo "$out_conflict" >&2
  exit 1
fi
verdict="$(jq -r '.verdict' <<<"$out_conflict")"
[[ "$verdict" == "conflict" ]] || { echo "FAIL: expected verdict=conflict, got $verdict" >&2; echo "$out_conflict" >&2; exit 1; }

conflict_bead="$(jq -r '.conflicts[0].bead_id' <<<"$out_conflict")"
[[ "$conflict_bead" == "flywheel-i9o" ]] || { echo "FAIL: expected conflicts[0].bead_id=flywheel-i9o, got $conflict_bead" >&2; echo "$out_conflict" >&2; exit 1; }

overlap="$(jq -r '.conflicts[0].overlapping_surfaces[0]' <<<"$out_conflict")"
[[ "$overlap" == "$SHARED_SURFACE" ]] || { echo "FAIL: expected overlapping_surfaces[0]=$SHARED_SURFACE, got $overlap" >&2; exit 1; }

# Case 2: independent candidate against in-flight i9o → expect ok.
rc=0
out_ok="$("$PROBE" \
  --candidate-task-file "$INDEPENDENT_PACKET" \
  --dispatch-log "$LOG" \
  --lookback-minutes 30 \
  --json)" || rc=$?
if [[ "$rc" -ne 0 ]]; then
  echo "FAIL: expected rc=0 for independent candidate, got $rc" >&2
  echo "$out_ok" >&2
  exit 1
fi
[[ "$(jq -r '.verdict' <<<"$out_ok")" == "ok" ]] || { echo "FAIL: independent verdict not ok" >&2; echo "$out_ok" >&2; exit 1; }
[[ "$(jq -r '.conflicts | length' <<<"$out_ok")" == "0" ]] || { echo "FAIL: independent conflicts count not 0" >&2; exit 1; }

# Case 3: candidate matches its own dispatch-log row but --self-task-id should suppress.
# Simulate by adding x6h to dispatch-log too, then probing with --self-task-id.
jq -nc \
  --arg ts "$NOW_ISO" \
  --arg task_id "flywheel-x6h-36d443ad" \
  --arg bead_id "flywheel-x6h" \
  --arg task_file "$X6H_PACKET" \
  '{schema_version:2, event:"dispatch_sent", ts:$ts, task_id:$task_id, bead_id:$bead_id, task_file:$task_file}' >>"$LOG"

rc=0
out_self="$("$PROBE" \
  --candidate-task-file "$X6H_PACKET" \
  --dispatch-log "$LOG" \
  --lookback-minutes 30 \
  --self-task-id flywheel-x6h-36d443ad \
  --json)" || rc=$?
# Even with self-task-id excluded, the i9o row still conflicts → expect rc=1.
[[ "$rc" -eq 1 ]] || { echo "FAIL: expected rc=1 (i9o still conflicts) when self-task-id suppresses x6h, got $rc" >&2; exit 1; }
self_conflict_count="$(jq -r '.conflicts | length' <<<"$out_self")"
[[ "$self_conflict_count" -eq 1 ]] || { echo "FAIL: expected 1 conflict (i9o only) under self-task-id, got $self_conflict_count" >&2; echo "$out_self" >&2; exit 1; }

# Case 4: lookback window excludes old rows.
OLD_LOG="$TMP/old-dispatch-log.jsonl"
jq -nc \
  --arg ts "2026-04-01T00:00:00Z" \
  --arg task_id "flywheel-i9o-0d7bc675" \
  --arg bead_id "flywheel-i9o" \
  --arg task_file "$I9O_PACKET" \
  '{schema_version:2, event:"dispatch_sent", ts:$ts, task_id:$task_id, bead_id:$bead_id, task_file:$task_file}' >"$OLD_LOG"

rc=0
out_old="$("$PROBE" \
  --candidate-task-file "$X6H_PACKET" \
  --dispatch-log "$OLD_LOG" \
  --lookback-minutes 30 \
  --json)" || rc=$?
[[ "$rc" -eq 0 ]] || { echo "FAIL: expected rc=0 when in-flight row predates lookback, got $rc" >&2; echo "$out_old" >&2; exit 1; }

printf 'PASS: dispatch-surface-conflict-probe — i9o/x6h conflict detected, independent ok, self-task-id suppression honored, lookback window honored\n'
