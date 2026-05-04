#!/usr/bin/env bash
# Isolated round-trip test for the flywheel -> skillos bridge helpers.
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
APPEND="$ROOT/.flywheel/scripts/skillos-candidate-append.sh"
TAIL="$ROOT/.flywheel/scripts/skillos-routed-tail.sh"
tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

export SKILLOS_PENDING_PATH="$tmpdir/skillos-pending-candidates.jsonl"
export SKILLOS_ROUTED_PATH="$tmpdir/skillos-routed.jsonl"
export SKILLOS_MARKER_PATH="$tmpdir/skillos-routed-tail.last_seen"

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

iso_plus_1h() {
  if date -u -v+1H +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -v+1H +%Y-%m-%dT%H:%M:%SZ
  else
    date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ
  fi
}

"$APPEND" \
  --candidate-class trauma-class \
  --evidence-path "synthetic:dry-run" \
  --rationale "synthetic bridge dry-run validates candidate envelope" \
  --recipient new-skill-suggestion \
  --domain synthetic \
  --source-session flywheel \
  --source-repo "$ROOT" \
  --dry-run --json >/dev/null

"$APPEND" \
  --candidate-class trauma-class \
  --evidence-path "synthetic:round-trip" \
  --rationale "synthetic bridge round-trip candidate" \
  --recipient new-skill-suggestion \
  --domain synthetic \
  --source-session flywheel \
  --source-repo "$ROOT" \
  --json >/dev/null

candidate="$(tail -n 1 "$SKILLOS_PENDING_PATH")"
ref="$(printf '%s' "$candidate" | shasum -a 256 | awk '{print $1}')"

jq -nc \
  --arg ts "$(iso_now)" \
  --arg original_row_ref "$ref" \
  --arg decision "new-skill" \
  --arg rationale "synthetic skillos echo confirms routing surface" \
  --arg target_skill_id "synthetic-skillos-bridge" \
  --arg action_taken "queued synthetic skill candidate" \
  --arg eta "$(iso_plus_1h)" \
  --arg source_session "flywheel" \
  '{ts:$ts,original_row_ref:$original_row_ref,decision:$decision,rationale:$rationale,target_skill_id:$target_skill_id,action_taken:$action_taken,eta:$eta,source_session_notify:true,source_session:$source_session}' \
  >> "$SKILLOS_ROUTED_PATH"

out="$("$TAIL" --since 1970-01-01T00:00:00Z --json)"
printf '%s' "$out" | jq -e '
  .status == "rows_found" and
  .count == 1 and
  (.rows[0].decision == "new-skill") and
  (.rows[0].target_skill_id == "synthetic-skillos-bridge") and
  (.decisions[0].count == 1)
' >/dev/null

echo "PASS: synthetic skillos bridge round-trip append -> echo -> subscribe"
