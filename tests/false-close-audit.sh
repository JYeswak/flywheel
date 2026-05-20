#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/repo"
mkdir -p "$repo/.flywheel" "$repo/transcripts"
git init -q "$repo"
git -C "$repo" config user.email test@example.invalid
git -C "$repo" config user.name "False Close Test"
printf 'seed\n' > "$repo/seed.txt"
git -C "$repo" add seed.txt
git -C "$repo" commit -q -m seed
sha="$(git -C "$repo" rev-parse --short=12 HEAD)"

cat > "$repo/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"task_id":"task-abc","status":"DONE"}
JSONL
cat > "$repo/transcripts/session.jsonl" <<'JSONL'
{"id":"msg-123","text":"closure proof"}
JSONL

hash_ref="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
cat > "$TMP/beads.json" <<JSON
{"issues":[
  {"id":"flywheel-proof","title":"proof child","status":"closed","priority":0,"closed_at":"2026-05-15T00:00:00Z","close_reason":"closed with $sha"},
  {"id":"flywheel-bead-ref","title":"bead ref","status":"closed","priority":0,"closed_at":"2026-05-15T00:01:00Z","close_reason":"parent completed via flywheel-proof"},
  {"id":"flywheel-commit-ref","title":"commit ref","status":"closed","priority":0,"closed_at":"2026-05-15T00:02:00Z","close_reason":"commit $sha"},
  {"id":"flywheel-dispatch-ref","title":"dispatch ref","status":"closed","priority":0,"closed_at":"2026-05-15T00:03:00Z","close_reason":"task_id=task-abc"},
  {"id":"flywheel-transcript-ref","title":"transcript ref","status":"closed","priority":1,"closed_at":"2026-05-15T00:04:00Z","close_reason":"see transcripts/session.jsonl#msg-123"},
  {"id":"flywheel-joshua-ref","title":"joshua ref","status":"closed","priority":1,"closed_at":"2026-05-15T00:05:00Z","close_reason":"Joshua confirmed $hash_ref"},
  {"id":"flywheel-script-only","title":"script only","status":"closed","priority":1,"closed_at":"2026-05-15T00:06:00Z","close_reason":"validated by sync-canonical-doctrine.sh"},
  {"id":"flywheel-date-only","title":"date only","status":"closed","priority":1,"closed_at":"2026-05-15T00:07:00Z","close_reason":"tested branch review/flywheel-2.0-private-20260513"},
  {"id":"flywheel-bad-commit","title":"bad commit","status":"closed","priority":1,"closed_at":"2026-05-15T00:08:00Z","close_reason":"commit deadbee"}
]}
JSON

out="$TMP/out.json"
set +e
"$ROOT/.flywheel/scripts/false-close-audit.py" audit --repo "$repo" --beads-json "$TMP/beads.json" --no-write-log --include-rows --now 2026-05-19T00:00:00Z > "$out"
rc=$?
set -e
[[ "$rc" -eq 1 ]]

jq -e '.counts["TRUE-CLOSE"] == 6 and .counts["NO-EVIDENCE"] == 2 and .counts.SUSPECT == 1' "$out" >/dev/null
jq -e '.rows[] | select(.bead_id=="flywheel-script-only" and .classification=="NO-EVIDENCE")' "$out" >/dev/null
jq -e '.rows[] | select(.bead_id=="flywheel-date-only" and .classification=="NO-EVIDENCE")' "$out" >/dev/null
jq -e '.rows[] | select(.bead_id=="flywheel-bad-commit" and .classification=="SUSPECT")' "$out" >/dev/null
jq -e '.rows[] | select(.bead_id=="flywheel-transcript-ref") | .evidence[] | select(.type=="transcript" and .valid==true)' "$out" >/dev/null

log="$TMP/audit.jsonl"
set +e
"$ROOT/.flywheel/scripts/false-close-audit.py" audit --repo "$repo" --beads-json "$TMP/beads.json" --audit-log "$log" --now 2026-05-19T00:00:00Z >/dev/null
rc=$?
set -e
[[ "$rc" -eq 1 ]]
[[ "$(wc -l < "$log" | tr -d ' ')" -eq 9 ]]

"$ROOT/.flywheel/scripts/false-close-audit.py" doctor --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" health --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" repair --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" validate --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" audit-log --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" why --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" quickstart --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" help --help >/dev/null
"$ROOT/.flywheel/scripts/false-close-audit.py" completion --help >/dev/null

echo "false-close-audit tests PASS"
