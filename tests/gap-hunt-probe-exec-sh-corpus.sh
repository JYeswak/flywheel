#!/usr/bin/env bash
# Regression test for flywheel-2xdi.64:
# gap-hunt-probe's wired-but-cold detector now captures direct-exec invocations
# of sibling shell scripts from bin/ wrappers (run/exec/bash/sh "path/to/x.sh").
#
# Specific case: ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-
# maximization-for-cli-tools/bin/aerg line 184:
#   run "$SKILL_ROOT/scripts/archetype-calibrate.sh" "$@"
# The wrapper does NOT `source` the target; it execs it. Pre-fix, the probe's
# runtime_source_corpus only captured `source`/`.`/`for-in`/`dot_d`/`var_assign_sh`
# patterns, so archetype-calibrate.sh was false-positive flagged wired-but-cold.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gap-hunt-exec-sh.XXXXXX")"
trap 'find "$TMP" -depth -type f -exec rm -f {} \; 2>/dev/null; find "$TMP" -depth -type d -exec rmdir {} \; 2>/dev/null' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: probe source defines exec_sh_re regex
if grep -q 'exec_sh_re' "$PROBE"; then
  pass "probe defines exec_sh_re regex"
else
  fail "exec_sh_re missing — the 2xdi.64 fix is not in place"
fi

# Test 2: exec_sh_re branch wired into the for-line loop
if grep -q 'exec_sh_re.search(line)' "$PROBE"; then
  pass "exec_sh_re wired into runtime_source_corpus line scan"
else
  fail "exec_sh_re defined but not wired into the for-line loop"
fi

# Test 3: live probe → archetype-calibrate.sh no longer flagged
out="$TMP/probe.json"
if timeout 180 "$PROBE" --json --dry-run >"$out" 2>"$TMP/probe.err"; then
  matched=$(jq -r '[.gaps // [] | .[] | select(.class == "wired-but-cold" and (.where | test("archetype-calibrate")))] | length' "$out" 2>/dev/null || echo "?")
  if [[ "$matched" == "0" ]]; then
    pass "live probe: archetype-calibrate.sh no longer flagged wired-but-cold"
  else
    fail "live probe: archetype-calibrate.sh still flagged ($matched gaps)"
  fi
else
  fail "probe failed to run"
fi

# Test 4: live probe → 0 wired-but-cold gaps total
# (combined effect of 2xdi.47 for-loop fix + 2xdi.49 SKILL.md fix + 2xdi.64 exec_sh fix)
if [[ -f "$out" ]]; then
  total=$(jq -r '[.gaps // [] | .[] | select(.class == "wired-but-cold")] | length' "$out" 2>/dev/null || echo "?")
  if [[ "$total" == "0" ]]; then
    pass "live probe: 0 wired-but-cold gaps total (combined 47+49+64 corpus extensions)"
  else
    fail "live probe: still $total wired-but-cold gaps"
  fi
fi

# Test 5: synthetic — exec_sh_re catches each of the 4 verbs (run/exec/bash/sh)
PY_OUT=$(python3 - <<'PY'
import re
exec_sh_re = re.compile(r"\b(?:run|exec|bash|sh)\s+\S*?\.sh\b")
samples = [
    '    run "$SKILL_ROOT/scripts/archetype-calibrate.sh" "$@"',
    '  exec "$SKILL_ROOT/scripts/foo.sh"',
    'bash "$SKILL_ROOT/scripts/foo.sh"',
    '  sh /usr/local/bin/setup.sh --flag',
    '  echo "not a script invocation"',          # negative
    '  some_var=run-something.sh',                # negative — not invocation
]
expected = [True, True, True, True, False, False]
got = [bool(exec_sh_re.search(s)) for s in samples]
print("OK" if got == expected else f"FAIL got={got} expected={expected}")
PY
)
if [[ "$PY_OUT" == "OK" ]]; then
  pass "synthetic: exec_sh_re catches run/exec/bash/sh verbs and skips negatives"
else
  fail "synthetic: exec_sh_re regex mismatch ($PY_OUT)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
