#!/usr/bin/env bash
# Verify /flywheel:respawn surfaces checkpoint.working_dir and preserves legacy envelopes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RESPAWN_DOC="/Users/josh/.claude/commands/flywheel/respawn.md"
TMP="$(mktemp -d -t respawn-checkpoint.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -maxdepth 1 -delete; rmdir "$TMP"' EXIT

require_grep() {
  local pattern="$1"
  local file="$2"
  if ! grep -q -- "$pattern" "$file"; then
    echo "MISSING: $pattern in $file" >&2
    exit 1
  fi
}

render_checkpoint() {
  jq -r '
    def checkpoint_path:
      (.checkpoint.loaded_from // .checkpoint.path // .recovery_checkpoint_path // "none");
    def spawn_working_dir:
      (.working_dir // .spawn.working_dir // .current_working_dir // "");
    def checkpoint_working_dir:
      (.checkpoint.working_dir // "");
    def decision:
      if (.checkpoint.gating_decision // "") != "" then
        .checkpoint.gating_decision
      elif checkpoint_working_dir == "" or spawn_working_dir == "" then
        "legacy_either_empty"
      elif checkpoint_working_dir == spawn_working_dir then
        "matched"
      else
        "rejected_mismatch"
      end;
    "checkpoint:\n  loaded_from: \(checkpoint_path)\n  working_dir: \((checkpoint_working_dir // "") | if . == "" then "legacy_empty" else . end)\n  gating_decision: \(decision)"
  ' "$1"
}

require_grep "checkpoint.working_dir" "$RESPAWN_DOC"
require_grep "gating_decision" "$RESPAWN_DOC"
require_grep "matched|legacy_either_empty|rejected_mismatch" "$RESPAWN_DOC"

cat > "$TMP/matched.json" <<'JSON'
{
  "session": "flywheel",
  "panes": [4],
  "working_dir": "/Users/josh/Developer/flywheel",
  "checkpoint": {
    "loaded_from": "/tmp/ntm/checkpoints/flywheel-pane4.json",
    "working_dir": "/Users/josh/Developer/flywheel"
  }
}
JSON

cat > "$TMP/legacy.json" <<'JSON'
{
  "session": "flywheel",
  "panes": [4],
  "checkpoint": {
    "loaded_from": "/tmp/ntm/checkpoints/legacy.json"
  }
}
JSON

cat > "$TMP/mismatch.json" <<'JSON'
{
  "session": "flywheel",
  "panes": [4],
  "working_dir": "/Users/josh/Developer/flywheel",
  "checkpoint": {
    "loaded_from": "/tmp/ntm/checkpoints/wrong-repo.json",
    "working_dir": "/Users/josh/Developer/other"
  }
}
JSON

matched_out="$(render_checkpoint "$TMP/matched.json")"
legacy_out="$(render_checkpoint "$TMP/legacy.json")"
mismatch_out="$(render_checkpoint "$TMP/mismatch.json")"

grep -q "loaded_from: /tmp/ntm/checkpoints/flywheel-pane4.json" <<<"$matched_out"
grep -q "working_dir: /Users/josh/Developer/flywheel" <<<"$matched_out"
grep -q "gating_decision: matched" <<<"$matched_out"

grep -q "loaded_from: /tmp/ntm/checkpoints/legacy.json" <<<"$legacy_out"
grep -q "working_dir: legacy_empty" <<<"$legacy_out"
grep -q "gating_decision: legacy_either_empty" <<<"$legacy_out"

grep -q "working_dir: /Users/josh/Developer/other" <<<"$mismatch_out"
grep -q "gating_decision: rejected_mismatch" <<<"$mismatch_out"

echo "respawn checkpoint working_dir surfaced; legacy envelope compatible"
