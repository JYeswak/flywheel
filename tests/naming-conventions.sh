#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOC="$ROOT/docs/brand/naming-conventions.md"

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

[[ -s "$DOC" ]] && pass "doc exists" || fail "doc exists"

for term in "ZestStream" "Flywheel" "Yuzu Method" "SkillOS" "ZestTube" "Jeff / Dicklesworthstone substrate" "NTM, Beads, Agent Mail"; do
  if rg -qF "$term" "$DOC"; then
    pass "canonical term present: $term"
  else
    fail "canonical term present: $term"
  fi
done

for doctrine in \
  ".flywheel/doctrine/naming-convention-distinguishable-ownership.md" \
  ".flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md" \
  ".flywheel/doctrine/scope-aware-rename-domain-collision-protection.md"; do
  if rg -qF "$doctrine" "$DOC" && [[ -s "$ROOT/$doctrine" ]]; then
    pass "doctrine reference live: $doctrine"
  else
    fail "doctrine reference live: $doctrine"
  fi
done

for collision in doctor ledger worker dispatch tick reap; do
  if rg -q "\`${collision}\`" "$DOC"; then
    pass "domain-collision term documented: $collision"
  else
    fail "domain-collision term documented: $collision"
  fi
done

if rg -q "PROMOTION-PENDING|chiefzester@gmail.com" "$DOC"; then
  fail "public naming doc avoids stale/private markers"
else
  pass "public naming doc avoids stale/private markers"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
