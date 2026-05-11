#!/usr/bin/env bash
# tests/scaffold-canonical-cli-flag-collision.sh
#
# Regression test for flywheel-efojs: the scaffolder must detect when a
# target script has its own case-arm handler for canonical introspection
# flags (--info|--schema|--examples) and omit those flags from the
# intercept's claim-list so the target's handler still runs.
#
# Surfaced by flywheel-wzjo9.1.7 (flywheel-loop wave-2.0a-g): target had
# its own --info emitting a different envelope shape; scaffold hijacked it.
# Worker note: "Scaffolder's verb-collision detection misses --info/--schema/
# --examples collisions: only the verb-set is checked, not the flag-set.
# Future binaries with native --info will hit the same regression."
#
# This test exercises four shapes:
#   1. Single-flag collision (target has --info case-arm)
#   2. Multi-arm collision (target has -h|--info case-arm)
#   3. All-three collision (target has --info, --schema, --examples)
#   4. Negative: prose-only mention of --info (must NOT false-positive)
# And one no-collision baseline.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/scaffold-canonical-cli.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t efojs-flag-collision.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

write_target() {
  local path="$1" body="$2"
  printf '%s\n' "$body" >"$path"
  chmod +x "$path"
}

scaffold_dry() {
  "$SCRIPT" "$1" --dry-run --allow-uninventoried --no-test-scaffold --json 2>&1
}

# ---------- Test 1: single-flag collision (--info case-arm) ----------

write_target "$TMP/has-info.sh" '#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --info) printf "own\n" ;;
  *) printf "default\n" ;;
esac'

receipt="$(scaffold_dry "$TMP/has-info.sh" | jq -c .receipt)"
if printf '%s' "$receipt" | jq -e '.flag_collision_detected == true and (.colliding_flags | index("--info") != null)' >/dev/null; then
  pass "T1: single --info case-arm detected as collision"
else
  fail "T1: single --info case-arm detected as collision"
  printf '%s\n' "$receipt" | jq . >&2 || true
fi

# Verify the scaffolded output OMITS --info from intercept claim-list.
# The unified_diff_path receipt points at the staged scaffold; inspect it.
diff_path="$(printf '%s' "$receipt" | jq -r .unified_diff_path)"
scaffolded="${diff_path%.diff}.scaffolded"
if [[ -r "$scaffolded" ]] && grep -qE '^\s*--schema\|--examples\) return 0 ;;' "$scaffolded" && ! grep -qE '^\s*--info\|' "$scaffolded"; then
  pass "T1: scaffolded intercept omits --info, keeps --schema|--examples"
else
  fail "T1: scaffolded intercept omits --info, keeps --schema|--examples"
fi
if [[ -r "$scaffolded" ]] && bash -n "$scaffolded"; then
  pass "T1: scaffolded output passes bash -n"
else
  fail "T1: scaffolded output passes bash -n"
fi

# ---------- Test 2: multi-arm collision (-h|--info case-arm) ----------

write_target "$TMP/multi-arm.sh" '#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  -h|--info) printf "help\n" ;;
  *) printf "default\n" ;;
esac'

receipt="$(scaffold_dry "$TMP/multi-arm.sh" | jq -c .receipt)"
if printf '%s' "$receipt" | jq -e '.flag_collision_detected == true and (.colliding_flags | index("--info") != null)' >/dev/null; then
  pass "T2: multi-arm -h|--info case-arm detected as collision"
else
  fail "T2: multi-arm -h|--info case-arm detected as collision"
fi

# ---------- Test 3: all-three collision (--info, --schema, --examples) ----------

write_target "$TMP/all-three.sh" '#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --info) printf "i\n" ;;
  --schema) printf "s\n" ;;
  --examples) printf "e\n" ;;
  *) printf "default\n" ;;
esac'

receipt="$(scaffold_dry "$TMP/all-three.sh" | jq -c .receipt)"
if printf '%s' "$receipt" | jq -e '.flag_collision_detected == true and (.colliding_flags | length) == 3' >/dev/null; then
  pass "T3: all three canonical introspection flags detected"
else
  fail "T3: all three canonical introspection flags detected"
fi

diff_path="$(printf '%s' "$receipt" | jq -r .unified_diff_path)"
scaffolded="${diff_path%.diff}.scaffolded"
if [[ -r "$scaffolded" ]] && bash -n "$scaffolded"; then
  pass "T3: all-three-collide scaffolded output bash -n clean (no empty case-arm syntax error)"
else
  fail "T3: all-three-collide scaffolded output bash -n clean (no empty case-arm syntax error)"
fi
# Should NOT contain a literal `--info|--schema|--examples)` arm
if [[ -r "$scaffolded" ]] && ! grep -qE '^\s*--info\|--schema\|--examples\) return 0 ;;' "$scaffolded"; then
  pass "T3: scaffolded output drops entire introspection case-arm"
else
  fail "T3: scaffolded output drops entire introspection case-arm"
fi

# ---------- Test 4: NEGATIVE — prose-only mention must NOT false-positive ----------

write_target "$TMP/prose-only.sh" '#!/usr/bin/env bash
# This script supports --info | jq filtering but does not implement
# a --info case-arm itself.
set -euo pipefail
case "${1:-}" in
  go) printf "go\n" ;;
  *) printf "default\n" ;;
esac'

receipt="$(scaffold_dry "$TMP/prose-only.sh" | jq -c .receipt)"
if printf '%s' "$receipt" | jq -e '.flag_collision_detected == false and (.colliding_flags | length) == 0' >/dev/null; then
  pass "T4: prose-only --info mention does NOT false-positive"
else
  fail "T4: prose-only --info mention does NOT false-positive"
fi

# ---------- Test 5: NO-COLLISION BASELINE ----------

write_target "$TMP/clean.sh" '#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  hello) printf "hi\n" ;;
  *) printf "default\n" ;;
esac'

receipt="$(scaffold_dry "$TMP/clean.sh" | jq -c .receipt)"
if printf '%s' "$receipt" | jq -e '.flag_collision_detected == false and .verb_collision_detected == false' >/dev/null; then
  pass "T5: clean target → no flag or verb collision"
else
  fail "T5: clean target → no flag or verb collision"
fi

# Default scaffolded output should still have the literal --info|--schema|--examples arm
diff_path="$(printf '%s' "$receipt" | jq -r .unified_diff_path)"
scaffolded="${diff_path%.diff}.scaffolded"
if [[ -r "$scaffolded" ]] && grep -qE '^\s*--info\|--schema\|--examples\) return 0 ;;' "$scaffolded"; then
  pass "T5: clean baseline preserves full --info|--schema|--examples claim"
else
  fail "T5: clean baseline preserves full --info|--schema|--examples claim"
fi

# ---------- Summary ----------

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
