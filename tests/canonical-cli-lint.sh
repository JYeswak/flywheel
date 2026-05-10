#!/usr/bin/env bash
# tests/canonical-cli-lint.sh — regression test for canonical-cli-lint.sh
#
# AG4 of flywheel-etp5n. Exercises each rule with a positive (violation
# present, must catch) and negative (clean code, must not flag) fixture.
# Plus --scan-all on the pilot (must report 0 violations), --rule filter,
# and --json schema validity.
set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
LINTER="${LINTER:-$REPO/.flywheel/scripts/canonical-cli-lint.sh}"
PILOT="${PILOT:-$REPO/.flywheel/scripts/daily-report-enabled-repos.sh}"

[[ -x "$LINTER" ]] || { echo "FAIL linter missing or not executable: $LINTER" >&2; exit 1; }
[[ -f "$PILOT" ]] || { echo "FAIL pilot missing: $PILOT" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

WORK_TMP="$(mktemp -d -t etp5n-test.XXXXXX)"
trap 'rm -rf "$WORK_TMP"' EXIT

# helper: write fixture file
fixture() {
  local name="$1"; shift
  local path="$WORK_TMP/$name.sh"
  cat > "$path"
  chmod +x "$path"
  printf '%s\n' "$path"
}

# helper: run linter with set +e/-e to capture rc despite pipefail
run_lint() {
  set +e
  "$@" 2>/dev/null
  local rc=$?
  set -e
  return "$rc"
}

# 1. Linter syntax-clean
bash -n "$LINTER" || fail "linter bash -n failed"
pass "linter syntax-clean (bash -n)"

# 2. Canonical-CLI surfaces
for flag in --info --schema --examples --doctor --help; do
  set +e
  out=$("$LINTER" "$flag" 2>&1)
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "$flag exited rc=$rc"
  [[ -n "$out" ]] || fail "$flag emitted no content"
done
pass "all 5 canonical-CLI flags exit 0 with content"

# 3. --schema is canonical
"$LINTER" --schema | jq -e '.title == "canonical-cli-lint output"' >/dev/null \
  || fail "--schema missing canonical title"
pass "--schema declares canonical title"

# 4. AG5 dogfood: pilot is clean
set +e
"$LINTER" "$PILOT" >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "AG5 dogfood: pilot $PILOT must lint clean (rc=$rc)"
pass "AG5 dogfood: pilot lints clean (rc=0)"

# 5. L1 chained-local-set-u — POSITIVE fixture
P1=$(fixture l1-positive <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
foo() {
  local x="$1" y="$x/foo"
}
EOF
)
set +e
out=$("$LINTER" "$P1" --rule L1 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "L1 positive should rc=1, got rc=$rc out=$out"
echo "$out" | grep -q "L1" || fail "L1 positive should report L1 violation"
pass "L1 positive: chained-local-set-u → caught"

# 6. L1 NEGATIVE fixture
N1=$(fixture l1-negative <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
foo() {
  local x="$1"
  local y="$x/foo"
}
EOF
)
set +e
"$LINTER" "$N1" --rule L1 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "L1 negative should rc=0, got rc=$rc"
pass "L1 negative: split locals → not flagged"

# 7. L2 enumerator missing return — POSITIVE fixture
P2=$(fixture l2-positive <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
list_things() {
  for x in a b c; do
    [[ "$x" != "a" ]] && echo "$x"
  done
}
EOF
)
set +e
out=$("$LINTER" "$P2" --rule L2 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "L2 positive should rc=1, got rc=$rc out=$out"
echo "$out" | grep -q "L2" || fail "L2 positive should report L2 violation"
pass "L2 positive: enumerator missing return 0 → caught"

# 8. L2 NEGATIVE fixture (explicit return 0)
N2=$(fixture l2-negative <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
list_things() {
  for x in a b c; do
    [[ "$x" != "a" ]] && echo "$x"
  done
  return 0
}
EOF
)
set +e
"$LINTER" "$N2" --rule L2 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "L2 negative should rc=0, got rc=$rc"
pass "L2 negative: explicit return 0 → not flagged"

# 9. L3 brace-default-ambiguity — POSITIVE
P3=$(fixture l3-positive <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
foo() {
  local x="${3:-{}}"
}
EOF
)
set +e
out=$("$LINTER" "$P3" --rule L3 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "L3 positive should rc=1, got rc=$rc out=$out"
echo "$out" | grep -q "L3" || fail "L3 positive should report L3"
pass "L3 positive: \${3:-{}} → caught"

# 10. L3 NEGATIVE (intermediate var pattern)
N3=$(fixture l3-negative <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
foo() {
  local x="${3:-}"
  [[ -n "$x" ]] || x='{}'
}
EOF
)
set +e
"$LINTER" "$N3" --rule L3 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "L3 negative should rc=0, got rc=$rc"
pass "L3 negative: intermediate var fallback → not flagged"

# 11. L5 missing strict mode — POSITIVE
P5=$(fixture l5-positive <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
echo hello
EOF
)
set +e
out=$("$LINTER" "$P5" --rule L5 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "L5 positive should rc=1, got rc=$rc"
echo "$out" | grep -q "L5" || fail "L5 should report"
pass "L5 positive: missing set -euo pipefail → caught"

# 12. L6 missing magic comment when --apply present — POSITIVE
P6=$(fixture l6-positive <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  --apply) echo apply; ;;
esac
EOF
)
set +e
out=$("$LINTER" "$P6" --rule L6 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "L6 positive should rc=1, got rc=$rc"
echo "$out" | grep -q "L6" || fail "L6 should report"
pass "L6 positive: --apply without magic comment → caught"

# 13. L7 --apply without idempotency-key — POSITIVE
P7=$(fixture l7-positive <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
case "$1" in
  --apply) echo apply; ;;
esac
EOF
)
set +e
out=$("$LINTER" "$P7" --rule L7 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "L7 positive should rc=1, got rc=$rc"
echo "$out" | grep -q "L7" || fail "L7 should report"
pass "L7 positive: --apply without idempotency-key → caught"

# 14. L7 NEGATIVE (idempotency-key referenced)
N7=$(fixture l7-negative <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
IDEM_KEY=""
case "$1" in
  --apply) [[ -n "$IDEM_KEY" ]] || exit 3 ; ;;
  --idempotency-key) IDEM_KEY="$2" ; ;;
esac
EOF
)
set +e
"$LINTER" "$N7" --rule L7 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "L7 negative should rc=0, got rc=$rc"
pass "L7 negative: --apply with IDEM_KEY check → not flagged"

# 15. --rule filter respected (only L1 should fire on a fixture with L1+L3)
COMBO=$(fixture combo <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
foo() {
  local x="$1" y="$x/foo"
  local z="${3:-{}}"
}
EOF
)
set +e
out=$("$LINTER" "$COMBO" --rule L1 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "combo --rule L1 should rc=1"
echo "$out" | grep -q "L1" || fail "combo --rule L1 should report L1"
echo "$out" | grep -q "L3" && fail "combo --rule L1 should NOT report L3 (filter not respected)"
pass "--rule filter respected (only requested rule fires)"

# 16. --json output is schema-valid
JSON_OUT=$("$LINTER" "$P1" --rule L1 --json 2>/dev/null || true)
echo "$JSON_OUT" | jq -e '.schema_version == "canonical-cli-lint/v1" and (.violations | length) >= 1 and .violations[0].rule == "L1"' >/dev/null \
  || fail "--json output not schema-valid: $JSON_OUT"
pass "--json output is schema-valid (canonical-cli-lint/v1)"

# 17. --json on clean fixture has empty violations array
JSON_CLEAN=$("$LINTER" "$N1" --rule L1 --json 2>/dev/null)
echo "$JSON_CLEAN" | jq -e '.status == "clean" and .violations == []' >/dev/null \
  || fail "--json clean output should have status=clean and violations=[]"
pass "--json clean output is canonical (status=clean, violations=[])"

# 18. --scan-all mode (uses repo's .flywheel/scripts; just verify it runs without crash)
set +e
SCAN_OUT=$("$LINTER" --scan-all --json 2>/dev/null); rc=$?
set -e
echo "$SCAN_OUT" | jq -e '.schema_version == "canonical-cli-lint/v1" and (.files_scanned | type == "number")' >/dev/null \
  || fail "--scan-all --json envelope malformed"
pass "--scan-all --json produces canonical envelope (files_scanned=$(echo "$SCAN_OUT" | jq -r '.files_scanned'))"

printf 'flywheel-etp5n canonical-cli-lint test passed (18 assertions)\n'
