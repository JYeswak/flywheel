#!/usr/bin/env bash
set -euo pipefail

repo=/Users/josh/Developer/flywheel
receipt="$repo/.flywheel/receipts/flywheel-z6lk3/triage-receipt.md"
alps_ack=/tmp/flywheel-z6lk3-alps-pane1.txt

test -s "$receipt"
grep -q '#21869' "$receipt"
grep -q 'flywheel-ie2en' "$receipt"
grep -q 'ACK' "$alps_ack"
grep -q '#21620' "$alps_ack"

"$HOME/.local/bin/codex-watchtower-daily.sh" --doctor --json | jq -e '.success == true' >/dev/null

if find "$HOME/.codex/sessions" -type f -perm +044 -print -quit | grep -q .; then
  echo '{"status":"fail","reason":"group_or_world_readable_codex_session_file"}'
  exit 1
fi

br show flywheel-ie2en --json >/dev/null

printf '{"status":"pass","task_id":"flywheel-z6lk3-530e3b","followup":"flywheel-ie2en"}\n'
