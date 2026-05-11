#!/usr/bin/env bash
# tests/inject-doc-toc-canonical-cli.sh — canonical-CLI surface tests
# Filed by flywheel-2xdi.152 per .flywheel/doctrine/test-receiver-wire-in-recipe.md
# (test-receiver-wire-in-recipe/v1, shipped by flywheel-eq9wv N=3 promotion).
#
# Double-class clearance: serves as receiver-evidence for both
# wired-but-cold (via flywheel-2xdi.140 corpus extension) and
# probe-without-receiver (via flywheel-2xdi.88 test_files_corpus glob).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/inject-doc-toc.sh"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — syntax
if /bin/bash -n "$SCRIPT" 2>/dev/null; then
  p "AG1 bash -n inject-doc-toc.sh"
else
  f "AG1 bash -n inject-doc-toc.sh"
fi

# AG2 — --info emits envelope with schema_version
if "$SCRIPT" --info 2>/dev/null | /usr/bin/jq -e '.schema_version' >/dev/null 2>&1; then
  p "AG2 --info emits schema_version"
else
  f "AG2 --info did not emit valid JSON envelope"
fi

# AG3 — --schema emits schema with required fields
if "$SCRIPT" --schema 2>/dev/null | /usr/bin/jq -e '.required | length > 0' >/dev/null 2>&1; then
  p "AG3 --schema emits required-fields list"
else
  f "AG3 --schema did not emit valid schema envelope"
fi

# AG4 — --examples emits example invocations (text mode per script design)
if "$SCRIPT" --examples 2>/dev/null | /usr/bin/grep -q 'inject-doc-toc.sh'; then
  p "AG4 --examples emits example invocations"
else
  f "AG4 --examples did not emit example invocations"
fi

# AG5 — --doctor / --health emits status
if "$SCRIPT" --doctor 2>/dev/null | /usr/bin/jq -e '.status' >/dev/null 2>&1; then
  p "AG5 --doctor emits status"
else
  f "AG5 --doctor did not emit valid status envelope"
fi

# AG6 — --help emits usage prose
if "$SCRIPT" --help 2>&1 | /usr/bin/grep -q 'inject-doc-toc'; then
  p "AG6 --help emits usage with script name"
else
  f "AG6 --help did not emit usage prose"
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
