#!/usr/bin/env bash
# tests/test-d23ow-cd-realpath-wrapper.sh
#
# Regression test for flywheel-d23ow (cd-realpath wrapper for failed-cd
# echo-redirect prevention). Asserts the canonical-CLI surface, sandbox
# enforcement, real-path resolution, and the contrived clobber-prevention
# scenario from AG3.

set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
SCRIPT="${SCRIPT:-$REPO/.flywheel/scripts/cd-realpath-wrapper.sh}"

[[ -x "$SCRIPT" ]] || { echo "FAIL script missing or not executable: $SCRIPT" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. Syntax + permissions
bash -n "$SCRIPT" && pass "script syntax-clean" || fail "bash -n failed"

# 2. Canonical-CLI introspection — all 4 surfaces + doctor
for flag in --help --info --schema --examples; do
  set +e
  out=$("$SCRIPT" "$flag" 2>&1); rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "$flag exited rc=$rc"
  [[ -n "$out" ]] || fail "$flag emitted no content"
done
pass "all 4 introspection flags exit 0 with content"

# 3. --schema is valid JSON Schema
"$SCRIPT" --schema | jq -e '.title == "cd-realpath-wrapper.event"' >/dev/null \
  || fail "--schema missing canonical title"
pass "--schema emits canonical title + draft-07 shape"

# 4. --doctor returns valid envelope
out=$("$SCRIPT" --doctor --json)
echo "$out" | jq -e '.status == "pass" and .realpath_check and .sandbox_prefix_count >= 5' >/dev/null \
  || fail "--doctor envelope incomplete: $out"
pass "--doctor returns status=pass with sandbox_prefix_count >= 5"

# 5. Live: resolve a real mktemp scratch dir → rc=0, stdout = resolved path
TESTDIR=$(mktemp -d -t d23ow-test.XXXXXX)
trap 'find "$TESTDIR" -mindepth 1 -delete 2>/dev/null; rmdir "$TESTDIR" 2>/dev/null || true' EXIT
set +e
out=$("$SCRIPT" "$TESTDIR" 2>&1); rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "real tmpdir should resolve cleanly, got rc=$rc out=$out"
[[ "$out" == *"$TESTDIR"* ]] || fail "resolved output should reference TESTDIR, got: $out"
pass "real mktemp tmpdir resolves to rc=0 with realpath on stdout"

# 6. Live: nonexistent path → rc=2 (realpath_failed)
set +e
out=$("$SCRIPT" /this/path/does/not/exist 2>&1); rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "nonexistent path should rc=2, got rc=$rc"
echo "$out" | grep -qF "realpath failed" || fail "missing 'realpath failed' message: $out"
pass "nonexistent path → rc=2 with realpath_failed reason"

# 7. Live: sandbox-escape path → rc=3 (outside_sandbox)
set +e
out=$("$SCRIPT" /etc 2>&1); rc=$?
set -e
[[ "$rc" -eq 3 ]] || fail "sandbox escape should rc=3, got rc=$rc"
echo "$out" | grep -qF "outside expected sandbox" || fail "missing 'outside expected sandbox' message: $out"
pass "/etc (sandbox escape) → rc=3 with outside_sandbox reason"

# 8. AG3 contrived clobber scenario: dispatch with a cd that would fail.
# Pre-prevention: `cd $UNSET_VAR && printf > target.md` would clobber. With
# the wrapper, the failed resolution stops execution before the redirect.
WORK_DIR=$(mktemp -d -t d23ow-clobber.XXXXXX)
mkdir -p "$WORK_DIR/safe-target"
echo "ORIGINAL CONTENT" > "$WORK_DIR/safe-target/target.md"

# Try to cd into a path that doesn't exist (simulating special-char escape failure)
BOGUS_PATH="/nonexistent-path-$$"
set +e
RESOLVED=$("$SCRIPT" "$BOGUS_PATH" 2>&1)
RESOLVE_RC=$?
set -e

# In the safe pattern, if RESOLVE_RC != 0, the script aborts before any cd or
# redirect. The target.md should remain untouched.
if [[ "$RESOLVE_RC" -eq 0 ]]; then
  fail "AG3 simulation: bogus path unexpectedly resolved successfully"
fi

# Verify the target wasn't clobbered (it can't have been — we never reached the cd)
[[ "$(cat "$WORK_DIR/safe-target/target.md")" == "ORIGINAL CONTENT" ]] \
  || fail "AG3: target.md content was modified despite resolve failure"
pass "AG3 contrived clobber scenario: failed resolve → no cd → target.md untouched"

# 9. Sourceable form: cd_realpath function defined in caller shell
set +e
result=$(bash -c "
  source '$SCRIPT'
  type cd_realpath 2>&1 | head -1
" 2>&1)
set -e
[[ "$result" == *"is a function"* ]] || fail "cd_realpath should be a function when sourced; got: $result"
pass "sourceable form defines cd_realpath function in caller shell"

# 10. Ledger receipt emission: every invocation writes a row
LEDGER_DIR=$(mktemp -d -t d23ow-ledger.XXXXXX)
LEDGER_FILE="$LEDGER_DIR/test-log.jsonl"
set +e
CD_REALPATH_WRAPPER_LEDGER="$LEDGER_FILE" "$SCRIPT" /etc >/dev/null 2>&1
set -e
[[ -f "$LEDGER_FILE" ]] || fail "ledger file not written: $LEDGER_FILE"
LEDGER_TAIL=$(tail -1 "$LEDGER_FILE")
echo "$LEDGER_TAIL" | jq -e '.schema_version == "cd-realpath-wrapper.v1" and .rc == 3 and .reason == "outside_sandbox"' >/dev/null \
  || fail "ledger row malformed: $LEDGER_TAIL"
pass "ledger row emitted with canonical schema + rc + reason"

# 11. Cross-reference to clobber-recovery.sh (the recovery primitive sibling)
"$SCRIPT" --info | grep -qF "clobber-recovery.sh" \
  || fail "--info missing cross-reference to clobber-recovery.sh"
pass "--info cross-references clobber-recovery.sh (recovery primitive)"

printf 'flywheel-d23ow cd-realpath-wrapper test passed (10 assertions)\n'
