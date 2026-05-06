#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fuckup-classifier.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

log="$TMP/fuckup-log.jsonl"
processed="$TMP/processed.jsonl"
: >"$processed"

cat >"$log" <<'JSONL'
{"ts":"2026-05-06T00:00:00Z","class":"post-callback-reminder-template-recovery","severity":"low","what_happened":"recovery-escape-then-reprompt attempted staged recovery"}
{"ts":"2026-05-06T00:01:00Z","class":"codex-model-at-capacity-halt","trauma_class":"<unknown>","severity":"high","what_happened":"selected model is at capacity"}
{"ts":"2026-05-06T00:02:00Z","class":"secret-leak","trauma_class":"unknown","severity":"high","what_happened":"DATABASE_URL echoed"}
{"ts":"2026-05-06T00:03:00Z","class":"ignored-legacy-class","trauma_class":"br-db-wedge","severity":"medium","what_happened":"preserve explicit trauma_class"}
{"ts":"2026-05-06T00:04:00Z","severity":"low","what_happened":"no classifier rule"}
JSONL

out=$(FLYWHEEL_FUCKUP_LOG="$log" FUCKUP_PROCESSED="$processed" "$FLYWHEEL_LOOP_BIN" fuckup list --since=all --json)

jq -e '
  (map(select(.trauma_class == "post-callback-reminder-template-recovery")) | length) == 1 and
  (map(select(.trauma_class == "codex-model-at-capacity-halt")) | length) == 1 and
  (map(select(.trauma_class == "secret-leak")) | length) == 1 and
  (map(select(.trauma_class == "br-db-wedge")) | length) == 1 and
  (map(select(.trauma_class == "<unknown>")) | length) == 1
' <<<"$(printf '%s\n' "$out" | jq -s .)" >/dev/null

jq -e '
  map(select(.class == "codex-model-at-capacity-halt"))[0].original_trauma_class == "<unknown>" and
  map(select(.class == "codex-model-at-capacity-halt"))[0].classifier_source == "flywheel-loop:legacy-class-field" and
  map(select(.class == "ignored-legacy-class"))[0].trauma_class == "br-db-wedge"
' <<<"$(printf '%s\n' "$out" | jq -s .)" >/dev/null

filtered=$(FLYWHEEL_FUCKUP_LOG="$log" FUCKUP_PROCESSED="$processed" "$FLYWHEEL_LOOP_BIN" fuckup list --since=all --class codex-model-at-capacity-halt --json | jq -s 'length')
[[ "$filtered" == "1" ]]

printf '%s\n' "$out" | jq -s -e 'all(.[]; .trauma_class and .severity and .what_happened)' >/dev/null
