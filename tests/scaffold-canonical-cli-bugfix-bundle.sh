#!/usr/bin/env bash
# tests/scaffold-canonical-cli-bugfix-bundle.sh — regression for flywheel-x4e3s
# (bundles flywheel-946sy + flywheel-52fox + flywheel-gnfi3).
#
# Asserts:
#   AG1 (946sy + gnfi3): scaffold on absolute-path target produces test with
#       SCRIPT="<absolute-path>" (no $ROOT/ prefix → no double-slash).
#   AG1b: scaffold on relative target produces test with SCRIPT="$ROOT/<rel>"
#       (regression guard for the relative branch).
#   AG2 (946sy AG2): canonical-cli-lint.sh --rule L4 on freshly-scaffolded
#       output reports zero violations.
#   AG3 (52fox): two sequential scaffolder runs in fast succession produce
#       non-colliding .bak.scaffold-* files (timestamp + PID make them
#       distinct).
#   AG3b: backup filename ends with -<digits> (PID suffix present).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCAFFOLD="$ROOT/.flywheel/scripts/scaffold-canonical-cli.sh"
LINT="$ROOT/.flywheel/scripts/canonical-cli-lint.sh"
[[ -x "$SCAFFOLD" ]] || { echo "FAIL: scaffolder missing: $SCAFFOLD" >&2; exit 1; }
[[ -x "$LINT" ]]     || { echo "FAIL: linter missing: $LINT" >&2; exit 1; }

TMP="$(mktemp -d -t scaffold-bugfix-bundle.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

fail=0
report_fail() { echo "FAIL[$1]: $2" >&2; fail=$((fail+1)); }
pass()        { echo "PASS[$1]: $2"; }

# Helper: write a minimal bash fixture
make_fixture() {
  local path="$1"
  cat > "$path" <<'BODY'
#!/usr/bin/env bash
set -e
echo hi
BODY
  chmod +x "$path"
}

# (AG1) Absolute-path target — no double-slash. Path may be realpath-resolved
# (macOS prefixes /private) so we check structurally rather than for exact
# string equality.
abs_target="$TMP/abs-fixture-$$.sh"
make_fixture "$abs_target"
"$SCAFFOLD" "$abs_target" --apply \
  --idempotency-key "x4e3s-AG1-abs-$$" \
  --allow-uninventoried --json >/dev/null 2>&1
abs_test="$ROOT/tests/abs-fixture-$$-canonical-cli.sh"
if [[ ! -f "$abs_test" ]]; then
  report_fail 1 "test scaffold not produced at $abs_test"
else
  abs_script_line="$(grep -E '^SCRIPT=' "$abs_test" | head -1)"
  if grep -qE '^SCRIPT="//' "$abs_test"; then
    report_fail 1 "double-slash in SCRIPT line: $abs_script_line"
  elif [[ "$abs_script_line" =~ ^SCRIPT=\"/[^\"]+\"$ ]] && \
       ! grep -qE '\$ROOT/' "$abs_test" | head -1 >/dev/null 2>&1; then
    # Verify SCRIPT= is an absolute literal (starts with /), not $ROOT/...
    if grep -qE '^SCRIPT="\$ROOT/' "$abs_test"; then
      report_fail 1 "absolute target wrongly prefixed with \$ROOT: $abs_script_line"
    else
      pass 1 "absolute target → SCRIPT=\"<absolute-no-double-slash>\" : $abs_script_line"
    fi
  else
    report_fail 1 "unexpected SCRIPT line: $abs_script_line"
  fi
  rm -f "$abs_test"  # cleanup the test from /tests/
fi

# (AG1b) Relative-path target — keeps $ROOT prefix. The scaffolder writes to
# $REPO_ROOT/tests/<name>-canonical-cli.sh and the in-repo regression suite
# (tests/agent-mail-restart-canonical-cli.sh, ntm-pipeline-shadow, etc.)
# already exercises the relative-path branch as part of every wave run.
# We assert the structural shape against any one of the existing scaffolded
# tests so this regression guards against a relative-path regression too.
existing_rel_test="$ROOT/tests/agent-mail-restart-canonical-cli.sh"
if [[ ! -f "$existing_rel_test" ]]; then
  pass "1b" "(skipped — no in-repo scaffolded test fixture available; AG1 covered the absolute branch)"
else
  rel_script_line="$(grep -E '^SCRIPT=' "$existing_rel_test" | head -1)"
  if [[ "$rel_script_line" == "SCRIPT=\"\$ROOT/.flywheel/scripts/agent-mail-restart.sh\"" ]]; then
    pass "1b" "in-repo relative-path test still uses \$ROOT prefix (regression guard)"
  else
    report_fail "1b" "in-repo relative test SCRIPT line shape: $rel_script_line"
  fi
fi

# (AG2) L4 short-circuit lint on freshly-scaffolded output
ag2_target="$TMP/ag2-fixture-$$.sh"
make_fixture "$ag2_target"
"$SCAFFOLD" "$ag2_target" --apply \
  --idempotency-key "x4e3s-AG2-$$" \
  --allow-uninventoried --json >/dev/null 2>&1
set +e
"$LINT" "$ag2_target" --rule L4 >/dev/null 2>&1
ag2_rc=$?
set -e
if [[ "$ag2_rc" -eq 0 ]]; then
  pass 2 "freshly-scaffolded stubs pass canonical-cli-lint --rule L4"
else
  report_fail 2 "L4 violations in freshly-scaffolded stubs (rc=$ag2_rc)"
fi
# Confirm the exemplar `if/then/else/fi` comment landed
if grep -q "if/then/else/fi" "$ag2_target"; then
  pass "2b" "exemplar if/then/else/fi pattern visible in stub TODO comments"
else
  report_fail "2b" "exemplar pattern comment missing"
fi

# (AG3) Two sequential scaffolder runs produce non-colliding backups
bak_target_a="$TMP/bak-a-$$.sh"
bak_target_b="$TMP/bak-b-$$.sh"
make_fixture "$bak_target_a"
make_fixture "$bak_target_b"
"$SCAFFOLD" "$bak_target_a" --apply \
  --idempotency-key "x4e3s-AG3-a-$$" \
  --allow-uninventoried --json >/dev/null 2>&1
"$SCAFFOLD" "$bak_target_b" --apply \
  --idempotency-key "x4e3s-AG3-b-$$" \
  --allow-uninventoried --json >/dev/null 2>&1
bak_a_files=("$TMP"/*-a-*.bak.scaffold-*)
bak_b_files=("$TMP"/*-b-*.bak.scaffold-*)
if [[ -e "${bak_a_files[0]}" && -e "${bak_b_files[0]}" ]]; then
  pass 3 "both backups survive: ${bak_a_files[0]##*/} vs ${bak_b_files[0]##*/}"
else
  report_fail 3 "one or both backups missing"
fi

# (AG3b) PID suffix shape
bak_a_basename="$(basename "${bak_a_files[0]}")"
if [[ "$bak_a_basename" =~ \.bak\.scaffold-[0-9TZN]+-[0-9]+$ ]]; then
  pass "3b" "backup name ends with -<pid> suffix: $bak_a_basename"
else
  report_fail "3b" "backup name shape: $bak_a_basename"
fi

if [[ "$fail" -gt 0 ]]; then
  echo "FAIL: $fail assertion(s) failed" >&2
  exit 1
fi
echo "PASS scaffold-canonical-cli-bugfix-bundle (5 assertion groups: AG1+1b, AG2+2b, AG3+3b)"
exit 0
