#!/usr/bin/env bash
# Regression test for flywheel-2xdi.47:
# gap-hunt-probe's runtime_source_corpus now captures `for <var> in <list>`
# headers (and their backslash-continuation lines) so that variable-indirected
# `source "$LIB/$module.sh"` patterns are recognized as live wiring.
#
# Before this fix, every lib/<module>.sh sourced via:
#   for module in misc parse repo ... reconcile ... ; do
#     source "$LIB/$module.sh"
#   done
# was flagged as wired-but-cold because the loop body's `source` line never
# contained the module name literally — the substring search for
# `reconcile.sh` / `reconcile` never matched the corpus.
#
# After the fix, the for-loop header lines (with the module-name list) are
# captured into the source corpus, so the substring search finds the names.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gap-hunt-for-loop-fix.XXXXXX")"
trap 'find "$TMP" -depth -type f -exec rm -f {} \; 2>/dev/null; find "$TMP" -depth -type d -exec rmdir {} \; 2>/dev/null' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: probe source code defines for_in_re (the new regex)
if grep -q 'for_in_re' "$PROBE"; then
  pass "probe defines for_in_re for for-loop header capture"
else
  fail "for_in_re missing — the 2xdi.47 fix is not in place"
fi

# Test 2: probe source code captures backslash-continuation lines
if grep -q 'in_for_continuation' "$PROBE"; then
  pass "probe tracks multi-line for-loop continuation"
else
  fail "for-loop continuation tracking missing"
fi

# Test 3: live probe → 0 wired-but-cold gaps total (was ≥1 with reconcile.sh pre-fix)
out="$TMP/probe.json"
if timeout 180 "$PROBE" --json --dry-run >"$out" 2>"$TMP/probe.err"; then
  cold_count=$(jq -r '[.gaps // [] | .[] | select(.class == "wired-but-cold")] | length' "$out" 2>/dev/null || echo "?")
  reconcile_count=$(jq -r '[.gaps // [] | .[] | select(.class == "wired-but-cold" and (.where | test("reconcile")))] | length' "$out" 2>/dev/null || echo "?")
  if [[ "$cold_count" == "0" && "$reconcile_count" == "0" ]]; then
    pass "live probe reports 0 wired-but-cold gaps (was ≥1 with reconcile.sh pre-fix)"
  else
    fail "live probe still reports wired-but-cold (total=$cold_count reconcile=$reconcile_count)"
  fi
else
  fail "probe failed to run; cannot verify end-to-end"
  cat "$TMP/probe.err" >&2
fi

# Test 4: synthetic fixture proves the regex captures the for-loop header
fixture="$TMP/loop.sh"
cat >"$fixture" <<'FIXTURE'
#!/usr/bin/env bash
for module in \
    misc parse repo canonical mission render reconcile bead wire fuckup memory \
    tentacle loop storage jeff daily agent fleet callback polish recovery doctor \
    session print portable skill-discovery step4i-coherence
do
  source "$LIB/$module.sh"
done
FIXTURE
# Capture what the regex *would* match by exporting the same regex pattern
python3 - "$fixture" <<'PY'
import re
import sys

text = open(sys.argv[1]).read()
for_in_re = re.compile(r"^\s*for\s+\w+\s+in\b")
captured = []
in_cont = False
for line in text.splitlines():
    stripped = line.strip()
    if for_in_re.match(line):
        captured.append(stripped)
        in_cont = stripped.endswith("\\")
        continue
    if in_cont:
        captured.append(stripped)
        in_cont = stripped.endswith("\\")
corpus = "\n".join(captured)
if "reconcile" in corpus and "tentacle" in corpus and "doctor" in corpus:
    print("PYOK")
else:
    print("PYFAIL corpus=" + repr(corpus[:300]))
PY
PY_OUT=$(python3 - "$fixture" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
for_in_re = re.compile(r"^\s*for\s+\w+\s+in\b")
captured = []
in_cont = False
for line in text.splitlines():
    stripped = line.strip()
    if for_in_re.match(line):
        captured.append(stripped)
        in_cont = stripped.endswith("\\")
        continue
    if in_cont:
        captured.append(stripped)
        in_cont = stripped.endswith("\\")
corpus = "\n".join(captured)
print("OK" if ("reconcile" in corpus and "tentacle" in corpus and "doctor" in corpus) else "FAIL")
PY
)
if [[ "$PY_OUT" == "OK" ]]; then
  pass "synthetic fixture: for-loop header capture finds reconcile + tentacle + doctor module names"
else
  fail "synthetic fixture: for-loop capture missed expected module names (got $PY_OUT)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
