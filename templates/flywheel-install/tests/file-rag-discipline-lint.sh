#!/usr/bin/env bash
# tests/file-rag-discipline-lint.sh — regression test for file-rag-discipline-lint.sh
# AG5 of {bead-id}.
set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
LINTER="${LINTER:-$REPO/.flywheel/scripts/file-rag-discipline-lint.sh}"
SCAFFOLDER="${SCAFFOLDER:-$REPO/.flywheel/scripts/scaffold-doc-frontmatter.sh}"
DOCTRINE="${DOCTRINE:-$REPO/.flywheel/doctrine/filesystem-as-rag.md}"
if [[ ! -e "$LINTER" && -e "$REPO/scripts/file-rag-discipline-lint.sh" ]]; then
  LINTER="$REPO/scripts/file-rag-discipline-lint.sh"
fi
if [[ ! -e "$SCAFFOLDER" && -e "$REPO/scripts/scaffold-doc-frontmatter.sh" ]]; then
  SCAFFOLDER="$REPO/scripts/scaffold-doc-frontmatter.sh"
fi
if [[ ! -e "$DOCTRINE" && -e "$REPO/doctrine/filesystem-as-rag.md" ]]; then
  DOCTRINE="$REPO/doctrine/filesystem-as-rag.md"
fi

[[ -x "$LINTER" ]] || { echo "FAIL linter missing: $LINTER" >&2; exit 1; }
[[ -x "$SCAFFOLDER" ]] || { echo "FAIL scaffolder missing: $SCAFFOLDER" >&2; exit 1; }
[[ -f "$DOCTRINE" ]] || { echo "FAIL doctrine missing: $DOCTRINE" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

WORK_TMP="$(mktemp -d -t s8tdd-test.XXXXXX)"
trap 'rm -rf "$WORK_TMP"' EXIT
export RUN_LOG="$WORK_TMP/scaffold-doc-frontmatter-runs.jsonl"

# 1. linter syntax-clean
bash -n "$LINTER" || fail "linter bash -n"
pass "linter syntax-clean"

# 2. scaffolder syntax-clean
bash -n "$SCAFFOLDER" || fail "scaffolder bash -n"
pass "scaffolder syntax-clean"

# 3. canonical-CLI surfaces (linter)
for flag in --info --schema --examples --doctor --help; do
  set +e
  out=$("$LINTER" "$flag" 2>&1)
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "linter $flag rc=$rc"
  [[ -n "$out" ]] || fail "linter $flag empty"
done
pass "linter canonical-CLI surfaces (5/5 PASS)"

# 4. canonical-CLI surfaces (scaffolder)
for flag in --info --schema --examples --doctor --help; do
  set +e
  out=$("$SCAFFOLDER" "$flag" 2>&1)
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "scaffolder $flag rc=$rc"
  [[ -n "$out" ]] || fail "scaffolder $flag empty"
done
pass "scaffolder canonical-CLI surfaces (5/5 PASS)"

# 5. doctrine doc lints clean (it's the canonical specimen)
set +e
"$LINTER" "$DOCTRINE" >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "doctrine doc must lint clean (rc=$rc)"
pass "doctrine doc lints clean"

# 6. F1 positive — .md without frontmatter
echo "# No frontmatter here" > "$WORK_TMP/no-fm.md"
set +e
out=$("$LINTER" "$WORK_TMP/no-fm.md" --rule F1 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "F1 positive rc=$rc"
echo "$out" | grep -q "F1" || fail "F1 violation not reported"
pass "F1 positive: missing frontmatter → caught"

# 7. F1 negative — .md with frontmatter
cat > "$WORK_TMP/with-fm.md" <<'EOF'
---
title: With frontmatter
type: general
created: 2026-05-10
---

# Body
EOF
set +e
"$LINTER" "$WORK_TMP/with-fm.md" --rule F1 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "F1 negative should rc=0, got $rc"
pass "F1 negative: frontmatter present → not flagged"

# 8. F1 exempt — README.md
echo "# Project" > "$WORK_TMP/README.md"
set +e
"$LINTER" "$WORK_TMP/README.md" --rule F1 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "F1 README exempt should rc=0"
pass "F1 exempt: README.md → not flagged"

# 9. F4 positive — .bak file
mkdir -p "$WORK_TMP/dir-with-bak"
echo "old" > "$WORK_TMP/dir-with-bak/file.md.bak"
echo "new" > "$WORK_TMP/dir-with-bak/file.md"
cat > "$WORK_TMP/dir-with-bak/README.md" <<'EOF'
---
title: t
type: general
created: 2026-05-10
---
EOF
set +e
out=$("$LINTER" "$WORK_TMP/dir-with-bak" --rule F4 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "F4 positive rc=$rc"
echo "$out" | grep -q "F4" || fail "F4 not reported"
pass "F4 positive: .bak file → caught"

# 10. F4 negative — clean dir
mkdir -p "$WORK_TMP/clean-dir"
cat > "$WORK_TMP/clean-dir/README.md" <<'EOF'
---
title: c
type: general
created: 2026-05-10
---
EOF
set +e
"$LINTER" "$WORK_TMP/clean-dir" --rule F4 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "F4 negative rc=$rc"
pass "F4 negative: no .bak → not flagged"

# 11. F7 positive — apply-spec.md missing canonical sections
mkdir -p "$WORK_TMP/audit-incomplete"
cat > "$WORK_TMP/audit-incomplete/apply-spec.md" <<'EOF'
---
title: bad spec
type: apply-spec
created: 2026-05-10
---

# Spec missing canonical sections
EOF
set +e
out=$("$LINTER" "$WORK_TMP/audit-incomplete/apply-spec.md" --rule F7 2>&1); rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "F7 positive rc=$rc out=$out"
echo "$out" | grep -q "F7" || fail "F7 not reported"
pass "F7 positive: apply-spec.md without canonical H2s → caught"

# 12. F7 negative — apply-spec.md with canonical sections
cat > "$WORK_TMP/audit-incomplete/apply-spec.md" <<'EOF'
---
title: good spec
type: apply-spec
created: 2026-05-10
---

# Spec
## Goal
ok
## Boundary
ok
## Acceptance gate
ok
EOF
set +e
"$LINTER" "$WORK_TMP/audit-incomplete/apply-spec.md" --rule F7 >/dev/null 2>&1; rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "F7 negative rc=$rc"
pass "F7 negative: canonical H2 sections present → not flagged"

# 13. --rule filter respected
mkdir -p "$WORK_TMP/multi-rule"
echo "no fm" > "$WORK_TMP/multi-rule/file.md"   # would trip F1
echo "old" > "$WORK_TMP/multi-rule/file.md.bak" # would trip F4
set +e
out=$("$LINTER" "$WORK_TMP/multi-rule/file.md" --rule F1 --json 2>/dev/null); rc=$?
set -e
echo "$out" | jq -e '[.violations[].rule] | sort | unique == ["F1"]' >/dev/null \
  || fail "--rule F1 filter not respected: got $(echo "$out" | jq -c '[.violations[].rule]')"
pass "--rule filter: F1 only → only F1 reported"

# 14. --json schema validity
JSON=$("$LINTER" "$WORK_TMP/no-fm.md" --rule F1 --json 2>/dev/null || true)
echo "$JSON" | jq -e '.schema_version == "file-rag-discipline-lint/v1" and (.violations | length) >= 1' >/dev/null \
  || fail "--json envelope invalid: $JSON"
pass "--json envelope is canonical (file-rag-discipline-lint/v1)"

# 15. Scaffolder dry-run skips files with frontmatter
set +e
out=$("$SCAFFOLDER" "$WORK_TMP/with-fm.md" 2>&1)
rc=$?
set -e
echo "$out" | grep -q "SKIP" || fail "scaffolder should SKIP files with frontmatter; out=$out"
pass "scaffolder idempotent: skips files with existing frontmatter"

# 16. Scaffolder dry-run shows WOULD-MODIFY for files without frontmatter
set +e
out=$("$SCAFFOLDER" "$WORK_TMP/no-fm.md" 2>&1)
rc=$?
set -e
echo "$out" | grep -q "WOULD-MODIFY" || fail "scaffolder should WOULD-MODIFY no-fm.md; out=$out"
pass "scaffolder dry-run: WOULD-MODIFY for files without frontmatter"

# 17. Scaffolder --apply requires --idempotency-key
set +e
out=$("$SCAFFOLDER" "$WORK_TMP/no-fm.md" --apply 2>&1)
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "scaffolder --apply without idem-key should rc=1; got $rc"
pass "scaffolder --apply without idem-key → rc=1 (refusal)"

# 18. Scaffolder --apply with idem-key writes frontmatter
cp "$WORK_TMP/no-fm.md" "$WORK_TMP/scaffold-target.md"
set +e
out=$("$SCAFFOLDER" "$WORK_TMP/scaffold-target.md" --apply --idempotency-key test-key 2>&1)
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "scaffolder apply rc=$rc out=$out"
head -1 "$WORK_TMP/scaffold-target.md" | grep -qE '^---' \
  || fail "scaffolder apply did not add frontmatter"
pass "scaffolder --apply --idempotency-key: frontmatter written"

# 19. Scaffolder --apply is idempotent (second run = no change)
set +e
out=$("$SCAFFOLDER" "$WORK_TMP/scaffold-target.md" --apply --idempotency-key test-key2 2>&1)
rc=$?
set -e
echo "$out" | grep -q "SKIP" || fail "second apply should SKIP (already has frontmatter); out=$out"
pass "scaffolder --apply idempotent: second run skips"

# 20. --scan-all envelope
set +e
SCAN=$("$LINTER" --scan-all --json 2>/dev/null); rc=$?
set -e
echo "$SCAN" | jq -e '.schema_version == "file-rag-discipline-lint/v1" and (.files_scanned | type == "number")' >/dev/null \
  || fail "--scan-all envelope malformed"
pass "--scan-all --json: canonical envelope (files_scanned=$(echo "$SCAN" | jq -r '.files_scanned'))"

printf '{bead-id} file-rag-discipline-lint test passed (20 assertions)\n'
