#!/usr/bin/env bash
# .flywheel/tests/test-doctrine-test-receiver-wire-in-recipe.sh
# Lock-in test for .flywheel/doctrine/test-receiver-wire-in-recipe.md
# shipped by flywheel-eq9wv. Mirrors test pattern of sister doctrine docs.
#
# Verifies:
#   AG1 — doctrine doc exists at canonical path
#   AG2 — front matter present (title/type/created)
#   AG3 — N=3 precedent beads cited (2xdi.87 + 2xdi.144 + 2xdi.146)
#   AG4 — 5-step recipe present
#   AG5 — receiver-corpus extensions cited (2xdi.88 + 2xdi.140)
#   AG6 — sister recipes cross-referenced (cluster-maintainer + forward-link)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DOC="$ROOT/.flywheel/doctrine/test-receiver-wire-in-recipe.md"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — doctrine doc exists
if [[ -f "$DOC" ]]; then
  p "AG1 doctrine doc exists at canonical path"
else
  f "AG1 doctrine doc missing"
fi

# AG2 — front matter
if grep -qE '^title:.*Test-Receiver Wire-In' "$DOC" && grep -qE '^type: doctrine' "$DOC"; then
  p "AG2 frontmatter present (title + type)"
else
  f "AG2 frontmatter missing"
fi

# AG3 — N=3 precedent beads cited
if grep -q 'flywheel-2xdi.87' "$DOC" && grep -q 'flywheel-2xdi.144' "$DOC" && grep -q 'flywheel-2xdi.146' "$DOC"; then
  p "AG3 N=3 precedent beads cited (2xdi.87 + 2xdi.144 + 2xdi.146)"
else
  f "AG3 N=3 precedent beads missing"
fi

# AG4 — 5-step recipe present
STEP_COUNT=$(grep -cE '^### Step [0-9]+' "$DOC")
if [[ "$STEP_COUNT" -ge 5 ]]; then
  p "AG4 5-step recipe present (found $STEP_COUNT steps)"
else
  f "AG4 5-step recipe missing (found $STEP_COUNT steps)"
fi

# AG5 — receiver-corpus extensions cited
if grep -q 'flywheel-2xdi.88' "$DOC" && grep -q 'flywheel-2xdi.140' "$DOC"; then
  p "AG5 receiver-corpus extensions cited (2xdi.88 + 2xdi.140)"
else
  f "AG5 receiver-corpus citations missing"
fi

# AG6 — sister recipes cross-referenced
if grep -q 'cluster-maintainer-pattern' "$DOC" && grep -q 'forward-link-doctrine-doc-recipe' "$DOC"; then
  p "AG6 sister recipes cross-referenced (cluster-maintainer + forward-link)"
else
  f "AG6 sister recipe cross-references missing"
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
