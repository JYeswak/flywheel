#!/usr/bin/env bash
# tests/scaffold-canonical-cli-apply-gate-regression.sh
#
# Regression test for flywheel-hoqq8: scaffold-canonical-cli.sh must refuse
# `--apply` without `--idempotency-key` BEFORE any side-effects (test
# scaffolding, backup, mutation). Previously a refused apply would still
# write tests/<name>-canonical-cli.sh, polluting the repo with a test
# pointing at an unscaffolded target.
#
# Three paths exercised:
#   1. --apply (no idem-key)        → rc=3, NO test in TESTS_DIR, fixture untouched
#   2. dry-run (default)            → rc=0, no test in TESTS_DIR (staged in tmp), fixture untouched
#   3. --apply --idempotency-key K  → rc=0, test in TESTS_DIR, fixture has magic comment

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCAFFOLDER="$ROOT/.flywheel/scripts/scaffold-canonical-cli.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ ! -x "$SCAFFOLDER" ]]; then
  fail "scaffolder not executable: $SCAFFOLDER"
  exit 1
fi

WORK_TMP="$(mktemp -d -t scaffold-apply-gate-regression.XXXXXX)" || { fail "mktemp failed"; exit 1; }
trap 'rm -rf "$WORK_TMP" 2>/dev/null || true' EXIT

# ---------- Path 1: refused apply (no idempotency-key) ----------

FIXTURE1="$WORK_TMP/regression-fixture1.sh"
cat > "$FIXTURE1" <<'EOF'
#!/usr/bin/env bash
echo "regression fixture 1"
exit 0
EOF
chmod +x "$FIXTURE1"

TESTS_DIR1="$WORK_TMP/tests-refused"
mkdir -p "$TESTS_DIR1"
EXPECTED_TEST1="$TESTS_DIR1/regression-fixture1-canonical-cli.sh"

set +e
SCAFFOLD_TESTS_DIR="$TESTS_DIR1" "$SCAFFOLDER" "$FIXTURE1" --apply --json --allow-uninventoried >/dev/null 2>&1
rc1=$?
set -e

if [[ "$rc1" -eq 3 ]]; then
  pass "refused apply returns rc=3"
else
  fail "refused apply rc=$rc1 (expected 3)"
fi

if [[ ! -e "$EXPECTED_TEST1" ]]; then
  pass "refused apply does NOT write test scaffold to TESTS_DIR (no leak)"
else
  fail "refused apply leaked test to TESTS_DIR: $EXPECTED_TEST1"
fi

if ! grep -q '# flywheel-cli-surface: true' "$FIXTURE1" 2>/dev/null; then
  pass "refused apply does NOT mutate fixture (magic comment absent)"
else
  fail "refused apply mutated the fixture (magic comment present)"
fi

# ---------- Path 2: dry-run (default mode) ----------

FIXTURE2="$WORK_TMP/regression-fixture2.sh"
cat > "$FIXTURE2" <<'EOF'
#!/usr/bin/env bash
echo "regression fixture 2"
exit 0
EOF
chmod +x "$FIXTURE2"

TESTS_DIR2="$WORK_TMP/tests-dryrun"
mkdir -p "$TESTS_DIR2"
EXPECTED_TEST2="$TESTS_DIR2/regression-fixture2-canonical-cli.sh"

set +e
SCAFFOLD_TESTS_DIR="$TESTS_DIR2" "$SCAFFOLDER" "$FIXTURE2" --json --allow-uninventoried >/dev/null 2>&1
rc2=$?
set -e

if [[ "$rc2" -eq 0 ]]; then
  pass "dry-run returns rc=0"
else
  fail "dry-run rc=$rc2 (expected 0)"
fi

if [[ ! -e "$EXPECTED_TEST2" ]]; then
  pass "dry-run does NOT write test scaffold to TESTS_DIR (correctly staged in tmp)"
else
  fail "dry-run wrote test to TESTS_DIR (should stage in tmp_dir): $EXPECTED_TEST2"
fi

if ! grep -q '# flywheel-cli-surface: true' "$FIXTURE2" 2>/dev/null; then
  pass "dry-run does NOT mutate fixture (magic comment absent)"
else
  fail "dry-run mutated the fixture"
fi

# ---------- Path 3: valid apply (with idempotency-key) ----------

FIXTURE3="$WORK_TMP/regression-fixture3.sh"
cat > "$FIXTURE3" <<'EOF'
#!/usr/bin/env bash
echo "regression fixture 3"
exit 0
EOF
chmod +x "$FIXTURE3"

TESTS_DIR3="$WORK_TMP/tests-applied"
mkdir -p "$TESTS_DIR3"
EXPECTED_TEST3="$TESTS_DIR3/regression-fixture3-canonical-cli.sh"

set +e
SCAFFOLD_TESTS_DIR="$TESTS_DIR3" "$SCAFFOLDER" "$FIXTURE3" --apply --idempotency-key=hoqq8-regression-pilot --json --allow-uninventoried >/dev/null 2>&1
rc3=$?
set -e

if [[ "$rc3" -eq 0 ]]; then
  pass "valid apply returns rc=0"
else
  fail "valid apply rc=$rc3 (expected 0)"
fi

if [[ -e "$EXPECTED_TEST3" ]]; then
  pass "valid apply DID write test scaffold to TESTS_DIR (correct)"
else
  fail "valid apply did not write test scaffold to TESTS_DIR: $EXPECTED_TEST3"
fi

if grep -q '# flywheel-cli-surface: true' "$FIXTURE3" 2>/dev/null; then
  pass "valid apply DID inject magic comment into fixture (correct)"
else
  fail "valid apply did not inject magic comment into fixture"
fi

# ---------- Summary ----------

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
