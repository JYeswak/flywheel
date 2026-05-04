#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/cross-repo-trauma-aggregator.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/repo-a/.flywheel" "$TMP/repo-b/.flywheel"
printf '%s\n' \
  '{"ts":"2026-05-04T18:00:00Z","trauma_class":"secret-leak","severity":"high","mission_lock_id":"ML-1","what_happened":"synthetic eyJabc123456789012345678901234 leaked"}' \
  '{"ts":"2026-05-04T18:05:00Z","trauma_class":"secret-leak","severity":"high","action":"auto_pause"}' \
  >"$TMP/repo-a/.flywheel/lock-log.jsonl"
printf '%s\n' \
  '{"ts":"2026-05-04T18:10:00Z","class":"driver-stale","severity":"medium"}' \
  >"$TMP/repo-b/.flywheel/lock-log.jsonl"

out="$("$SCRIPT" --root "$TMP" --json)"
jq -e '.event_count == 3' <<<"$out" >/dev/null
jq -e '.repo_count == 2' <<<"$out" >/dev/null
jq -e '.cross_repo_trauma_class_top[0].trauma_class == "secret-leak"' <<<"$out" >/dev/null
jq -e '.cross_repo_trauma_class_top[0].count == 2' <<<"$out" >/dev/null

if grep -q 'eyJabc' <<<"$out"; then
  printf 'FAIL aggregator copied synthetic secret-shaped free text\n' >&2
  exit 1
fi

printf 'cross-repo-trauma-aggregator tests passed\n'
