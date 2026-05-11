#!/usr/bin/env bash
# .flywheel/tests/test-inject-operator-library-recipe.sh
# Regression test for flywheel-vbk3h inject-operator-library-recipe.sh.
#
# AGs:
#   AG1 — script exists + executable
#   AG2 — bash -n passes
#   AG3 — --doctor returns ok (doctrine present + builder wired + source present)
#   AG4 — doctrine class fixture: OPERATOR LIBRARY RECIPE BLOCK injected
#   AG5 — skill-md class fixture: pipeline includes ⌘ REDUCE
#   AG6 — client-doc class fixture: pipeline excludes MOTIVATE (no ✦)
#   AG7 — readme class fixture: pipeline excludes WARN
#   AG8 — non-matching class fixture: pass through unchanged
#   AG9 — OPERATOR_LIBRARY_RECIPE_DISABLED=1 env-var passes through
#   AG10 — sister doctrine cross-references in doctrine doc

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
INJECTOR="$ROOT/.flywheel/scripts/inject-operator-library-recipe.sh"
BUILDER="$ROOT/.flywheel/scripts/build-dispatch-packet.sh"
DOCTRINE="$ROOT/.flywheel/doctrine/operator-library-recipe.md"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1
if [[ -f "$INJECTOR" && -x "$INJECTOR" ]]; then
  p "AG1 script exists + executable"
else
  f "AG1 script missing or not executable"
fi

# AG2
if /bin/bash -n "$INJECTOR" 2>/dev/null; then
  p "AG2 bash -n passes"
else
  f "AG2 bash -n fails"
fi

# AG3
if "$INJECTOR" --doctor 2>/dev/null | /usr/bin/python3 -c '
import sys, json
d = json.load(sys.stdin)
ok = (d.get("doctrine_doc") == "present"
      and d.get("builder_wired") == "wired"
      and d.get("source_operator_library") == "present")
exit(0 if ok else 1)
' 2>/dev/null; then
  p "AG3 --doctor returns ok"
else
  f "AG3 --doctor reports missing component"
fi

# Fixture helper
make_fixture() {
  local cls="$1"
  local tmp="$2"
  cat > "$tmp" <<FIX
# DISPATCH PACKET
## TASK BODY
### Title
$cls some title
### Description
body text
## METADATA
schema=test
FIX
}

# AG4 — doctrine class
# Capture output to var first to avoid grep -q + pipefail SIGPIPE issue.
TMP=$(/usr/bin/mktemp /tmp/test-oplib.XXXXXX)
trap "rm -f $TMP $TMP.out" EXIT
make_fixture '[doctrine]' "$TMP"
RESULT="$("$INJECTOR" "$TMP" fixture-vbk3h 2>&1)"
if printf '%s' "$RESULT" | /usr/bin/grep -c 'OPERATOR LIBRARY RECIPE BLOCK' | /usr/bin/grep -qv '^0$'; then
  p "AG4 doctrine class injects RECIPE BLOCK"
else
  f "AG4 doctrine class did not inject"
fi

# AG5 — skill-md class includes REDUCE
make_fixture '[skill-md]' "$TMP"
RESULT="$("$INJECTOR" "$TMP" fixture-vbk3h 2>&1)"
if printf '%s' "$RESULT" | /usr/bin/grep -c 'REDUCE' | /usr/bin/grep -qv '^0$'; then
  p "AG5 skill-md class pipeline includes REDUCE"
else
  f "AG5 skill-md class missing REDUCE"
fi

# AG6 — client-doc class excludes MOTIVATE (no ✦ MOTIVATE step in client pipeline)
make_fixture '[client-doc-readme]' "$TMP"
RESULT="$("$INJECTOR" "$TMP" fixture-vbk3h 2>&1)"
# Pipeline section should NOT include MOTIVATE for client-doc
PIPELINE_SECTION="$(printf '%s' "$RESULT" | /usr/bin/awk '/Pipeline for this class/,/Operator definitions/')"
if ! printf '%s' "$PIPELINE_SECTION" | /usr/bin/grep -q '\*\*✦ MOTIVATE'; then
  p "AG6 client-doc pipeline correctly excludes MOTIVATE"
else
  f "AG6 client-doc pipeline incorrectly includes MOTIVATE"
fi

# AG7 — readme class pipeline excludes WARN (per spec: ORIENT→MOTIVATE→EXEMPLIFY→REDUCE only)
make_fixture '[readme]' "$TMP"
RESULT="$("$INJECTOR" "$TMP" fixture-vbk3h 2>&1)"
PIPELINE_SECTION="$(printf '%s' "$RESULT" | /usr/bin/awk '/Pipeline for this class/,/Operator definitions/')"
if ! printf '%s' "$PIPELINE_SECTION" | /usr/bin/grep -q '\*\*⚠ WARN'; then
  p "AG7 readme pipeline correctly excludes WARN"
else
  f "AG7 readme pipeline incorrectly includes WARN"
fi

# AG8 — non-matching class passes through
make_fixture '[bug]' "$TMP"
HITS=$("$INJECTOR" "$TMP" fixture-vbk3h 2>&1 | /usr/bin/grep -c 'OPERATOR LIBRARY RECIPE BLOCK')
if [[ "$HITS" -eq 0 ]]; then
  p "AG8 non-matching class passes through unchanged"
else
  f "AG8 non-matching class incorrectly injected ($HITS hits)"
fi

# AG9 — OPERATOR_LIBRARY_RECIPE_DISABLED=1 bypass
make_fixture '[doctrine]' "$TMP"
HITS=$(OPERATOR_LIBRARY_RECIPE_DISABLED=1 "$INJECTOR" "$TMP" fixture-vbk3h 2>&1 | /usr/bin/grep -c 'OPERATOR LIBRARY RECIPE BLOCK')
if [[ "$HITS" -eq 0 ]]; then
  p "AG9 OPERATOR_LIBRARY_RECIPE_DISABLED=1 bypasses injection"
else
  f "AG9 disabled env-var did not bypass"
fi

# AG10 — doctrine doc cross-references sister recipes
if /usr/bin/grep -q 'forward-link-doctrine-doc-recipe' "$DOCTRINE" && /usr/bin/grep -q 'cluster-maintainer-pattern' "$DOCTRINE" && /usr/bin/grep -q 'test-receiver-wire-in-recipe' "$DOCTRINE"; then
  p "AG10 doctrine doc cross-references 3 sister recipes"
else
  f "AG10 doctrine doc missing sister-recipe cross-references"
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
