#!/usr/bin/env bash
# tests/test-y4e47-l107-release-after-commit.sh
#
# Regression test for flywheel-y4e47 (L107 release-then-git-add race).
# Reproduces the race window in a tmpdir, then asserts the canonical
# reserve→write→git add→git commit→release ordering produces ONLY
# this-pane content in this-pane's commit.

set -euo pipefail

TMPROOT="$(mktemp -d -t y4e47-l107.XXXXXX)"
trap 'rm -rf "$TMPROOT"' EXIT

REPO="$TMPROOT/repo"
mkdir -p "$REPO"
cd "$REPO"
git init -q
git config user.email test@test.local
git config user.name test
echo "" > shared.md
git add shared.md
git commit -q -m "init"

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# Test 1: ANTI-PATTERN repro (release-before-git-add).
# Pane A reserves, writes, RELEASES, then peer B writes, then A stages+commits.
# Expectation: A's commit contains BOTH appends (the bug).
echo "=== test 1: anti-pattern repro (release before git add) ==="
echo -e "\n## pane A entry" >> shared.md
# Pane A "release" before staging — peer B sneaks in
echo -e "\n## pane B entry (raced in)" >> shared.md
git add shared.md
git commit -q -m "pane-A-claims-only-A-but-actually-bundles-B"
hash_anti="$(git rev-parse HEAD)"
A_count_anti=$(git show "$hash_anti" -- shared.md | grep -c "pane A entry" || true)
B_count_anti=$(git show "$hash_anti" -- shared.md | grep -c "pane B entry" || true)
if [[ "$A_count_anti" -ge 1 && "$B_count_anti" -ge 1 ]]; then
  pass "anti-pattern repro: commit bundles both A's ($A_count_anti) and B's ($B_count_anti) appends — bug confirmed"
else
  fail "anti-pattern repro failed: A=$A_count_anti B=$B_count_anti (expected both >=1)"
fi

# Test 2: CANONICAL pattern (release after commit).
# Use a fresh file in the same repo so prior anti-pattern commit doesn't pollute.
echo "" > shared2.md
git add shared2.md
git commit -q -m "init shared2"

# Pane A: reserve → write → git add → git commit → THEN release
# (peer B's writes happen AFTER pane A commits)
echo -e "\n## canonical-A entry" >> shared2.md
git add shared2.md
git commit -q -m "canonical-A: holds reservation through commit"
hash_canonical_A="$(git rev-parse HEAD)"
# NOW pane A "releases" — peer B can write
echo -e "\n## canonical-B entry" >> shared2.md
git add shared2.md
git commit -q -m "canonical-B: separate commit"
hash_canonical_B="$(git rev-parse HEAD)"

# Count only ADDED lines in each commit (lines starting with +, not + followed by + which is the diff header)
A_in_A=$(git show "$hash_canonical_A" -- shared2.md | grep -E "^\+[^+]" | grep -c "canonical-A entry" || true)
B_in_A=$(git show "$hash_canonical_A" -- shared2.md | grep -E "^\+[^+]" | grep -c "canonical-B entry" || true)
A_in_B=$(git show "$hash_canonical_B" -- shared2.md | grep -E "^\+[^+]" | grep -c "canonical-A entry" || true)
B_in_B=$(git show "$hash_canonical_B" -- shared2.md | grep -E "^\+[^+]" | grep -c "canonical-B entry" || true)

[[ "$A_in_A" -ge 1 ]] || fail "canonical: A's commit missing A's entry as added line (got $A_in_A)"
[[ "$B_in_A" -eq 0 ]] || fail "canonical: A's commit ADDS B's entry (got $B_in_A; expected 0)"
[[ "$A_in_B" -eq 0 ]] || fail "canonical: B's commit ADDS A's entry (got $A_in_B; expected 0 — A was already in baseline)"
[[ "$B_in_B" -ge 1 ]] || fail "canonical: B's commit missing B's entry as added line (got $B_in_B)"
pass "canonical pattern: A's commit contains only A; B's commit contains only B"

# Test 3: L107 rule body cites the canonical lifecycle ordering
RULE="${RULE:-/Users/josh/Developer/flywheel/.flywheel/rules/L061-L107-shared-surface-writes-must-reserve-across-panes.md}"
[[ -f "$RULE" ]] || fail "L107 rule missing at $RULE"
grep -qF -- "--reserve → write → git add → git commit → --release" "$RULE" \
  || fail "L107 rule does not cite canonical lifecycle order"
pass "L107 rule cites canonical lifecycle order"

grep -qF -- "Releasing the reservation before \`git commit\` exits 0" "$RULE" \
  || fail "L107 rule's Forbidden outputs does not name the release-before-commit anti-pattern"
pass "L107 rule's Forbidden outputs names the release-before-commit anti-pattern"

# Test 4: dispatch-template embeds the lifecycle warning
TEMPLATE="${TEMPLATE:-$HOME/.claude/commands/flywheel/_shared/dispatch-template.md}"
[[ -f "$TEMPLATE" ]] || fail "dispatch-template missing at $TEMPLATE"
grep -qF -- "Reservation lifecycle (exact order)" "$TEMPLATE" \
  || fail "dispatch-template missing Reservation lifecycle section"
pass "dispatch-template embeds Reservation lifecycle warning"

grep -qF -- "37d0de7" "$TEMPLATE" \
  || fail "dispatch-template missing the concrete 37d0de7 incident citation"
pass "dispatch-template cites the concrete 37d0de7 race incident"

printf 'flywheel-y4e47 L107 release-after-commit test passed (7 assertions)\n'
