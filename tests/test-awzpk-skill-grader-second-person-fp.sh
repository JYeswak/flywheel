#!/usr/bin/env bash
# tests/test-awzpk-skill-grader-second-person-fp.sh
#
# Regression test for flywheel-awzpk (skill-grader second-person false-positives).
# Asserts count_second_person() skips quoted citations and code-block contexts
# while still catching genuine instructional second-person.

set -euo pipefail

GRADER="${GRADER:-$HOME/.claude/skills/skill-autoresearch/scripts/skill-grader.py}"

[[ -f "$GRADER" ]] || { echo "FAIL grader missing: $GRADER" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. Python syntax
python3 -c "import ast; ast.parse(open('$GRADER').read())" \
  && pass "skill-grader.py Python syntax-clean" \
  || fail "skill-grader.py syntax error"

# 2. count_second_person() skips double-quoted citations
result=$(python3 -c "
import sys
sys.path.insert(0, '$(dirname "$GRADER")')
import importlib.util
spec = importlib.util.spec_from_file_location('skill_grader', '$GRADER')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
content = '| Trigger Quality | third-person voice, no second-person (\"you should\") |'
hits = mod.count_second_person(content)
print(len(hits))
")
[[ "$result" == "0" ]] || fail "double-quoted citation should be skipped, got $result hit(s)"
pass "double-quoted 'you should' citation correctly skipped (FP suppressed)"

# 3. count_second_person() skips backtick-quoted citations
result=$(python3 -c "
import sys
import importlib.util
spec = importlib.util.spec_from_file_location('skill_grader', '$GRADER')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
content = 'Penalize \`you should\` phrasing'
hits = mod.count_second_person(content)
print(len(hits))
")
[[ "$result" == "0" ]] || fail "backtick citation should be skipped, got $result hit(s)"
pass "backtick 'you should' citation correctly skipped (FP suppressed)"

# 4. count_second_person() still catches genuine instructional second-person
result=$(python3 -c "
import sys
import importlib.util
spec = importlib.util.spec_from_file_location('skill_grader', '$GRADER')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
content = 'For best results, you should run the validator first.'
hits = mod.count_second_person(content)
print(len(hits))
")
[[ "$result" == "1" ]] || fail "genuine 'you should' instruction must be caught, got $result hit(s)"
pass "genuine instructional 'you should' still caught (no over-suppression)"

# 5. count_second_person() skips fenced code blocks
result=$(python3 -c "
import sys
import importlib.util
spec = importlib.util.spec_from_file_location('skill_grader', '$GRADER')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
content = '''
Here is a code example:
\`\`\`
# you must run this command
echo hi
\`\`\`
'''
hits = mod.count_second_person(content)
print(len(hits))
")
[[ "$result" == "0" ]] || fail "fenced code block second-person should be skipped, got $result hit(s)"
pass "fenced code block correctly skipped"

# 6. Live grader run on skill-autoresearch — second-person count = 0 post-fix
sp_count=$(cd /tmp && python3 "$GRADER" --skill-path "$HOME/.claude/skills/skill-autoresearch" --verbose 2>&1 | grep "Second-person voice" | head -1)
[[ "$sp_count" == *"none found"* ]] \
  || fail "live grader on skill-autoresearch still finds second-person hits: $sp_count"
pass "live grader on skill-autoresearch reports 'Second-person voice: none found' (FPs eliminated)"

# 7. Live grader composite score >= 9.2 (was 9.0 pre-fix; +0.29 from the trigger_quality gain)
composite=$(cd /tmp && python3 "$GRADER" --skill-path "$HOME/.claude/skills/skill-autoresearch" --json 2>&1 | jq -r '.composite_score // 0')
awk -v c="$composite" 'BEGIN { exit (c >= 9.2 ? 0 : 1) }' \
  || fail "live composite score $composite < 9.2 (pre-fix was 9.0; expected uplift)"
pass "live composite score on skill-autoresearch = $composite (>= 9.2 target; was 9.0 pre-fix)"

# 8. trigger_quality gate score = 10.0 post-fix
tq_score=$(cd /tmp && python3 "$GRADER" --skill-path "$HOME/.claude/skills/skill-autoresearch" --verbose 2>&1 | grep -E "trigger_quality\s+[0-9]+\.[0-9]+/10" | grep -oE "[0-9]+\.[0-9]+/10" | head -1)
[[ "$tq_score" == "10.0/10" ]] || fail "trigger_quality post-fix expected 10.0/10, got $tq_score"
pass "trigger_quality gate score = 10.0/10 post-fix (was 8.0/10 pre-fix)"

printf 'flywheel-awzpk skill-grader second-person FP test passed (8 assertions)\n'
