#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RULE="$ROOT/.flywheel/rules/L112-L171-skill-creation-requires-skillos-handoff.md"
EXTRACT="$ROOT/.flywheel/scripts/agents-md-shard-extract.sh"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

contains() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if rg -Fq -- "$needle" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if [[ -f "$RULE" ]]; then
  pass "L171 shard exists"
else
  fail "L171 shard exists"
fi
contains "$RULE" "id: L171" "L171 id frontmatter"
contains "$RULE" "status: long_term" "L171 long-term status"
contains "$RULE" "review_due: 2026-11-03" "L171 review due"
contains "$RULE" "trauma_class: skill-shipped-without-skillos-handoff" "L171 trauma class"
contains "$RULE" "skillos_handoff_message_id=<int>" "L171 requires handoff message id"
contains "$RULE" "skillos_handoff_skipped_reason=<text>" "L171 allows explicit skip reason"
contains "$RULE" ".flywheel/scripts/handoff-skill-to-skillos.sh" "L171 names handoff helper"
contains "$RULE" "templates/fuckup-heuristics.json" "L171 cites heuristic"

for surface in \
  "$ROOT/AGENTS.md" \
  "$ROOT/.flywheel/AGENTS-CANONICAL.md" \
  "$ROOT/templates/flywheel-install/AGENTS.md"; do
  contains "$surface" "L171 — SKILL-CREATION-REQUIRES-SKILLOS-HANDOFF" "L171 indexed in ${surface#"$ROOT"/}"
done

if jq -e '.rules[] | select(.id == "L171" and .path == ".flywheel/rules/L112-L171-skill-creation-requires-skillos-handoff.md" and .trauma_class == "skill-shipped-without-skillos-handoff")' \
  "$ROOT/.flywheel/rules/MANIFEST.json" >/dev/null; then
  pass "manifest indexes L171"
else
  fail "manifest indexes L171"
fi

if "$EXTRACT" --dry-run --json 2>/dev/null \
  | jq -e '.status == "in_sync" and .rule_count >= 112 and .drifted_count == 0' >/dev/null; then
  pass "shard extractor dry-run in sync"
else
  fail "shard extractor dry-run in sync"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
