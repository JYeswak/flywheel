#!/usr/bin/env bash
# tests/goal-build-canonical-cli.sh
# Canonical-CLI + behavior tests for .flywheel/scripts/goal-build.sh
# Closes the recurring 4k-limit-policed-by-Joshua failure mode.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/goal-build.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/goal-build-test.XXXXXX")"
export GOAL_BUILD_REPO="$TMP/repo"
mkdir -p "$GOAL_BUILD_REPO/.flywheel/goals"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

bash -n "$SCRIPT" 2>/dev/null && pass "shellcheck: syntax" || fail "syntax"

# Canonical surfaces
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .schema_version and .anti_pattern_fixed' >/dev/null \
  && pass "--info exposes name/version/schema/anti_pattern_fixed" || fail "--info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema and .max_chars == 4000' >/dev/null \
  && pass "--schema exposes I/O schemas + max_chars=4000" || fail "--schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length >= 3' >/dev/null \
  && pass "--examples ≥3 invocations" || fail "--examples"
"$SCRIPT" doctor 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 3)' >/dev/null \
  && pass "doctor envelope" || fail "doctor"

# Behavior: under-limit body writes
UNDER="$TMP/under.txt"
python3 -c "open('$UNDER','w').write('x'*3500)"
OUT="$("$SCRIPT" build --repo testrepo --slug under-test --from "$UNDER" --json 2>&1)"
echo "$OUT" | jq -e '.status == "written" and .char_count == 3500' >/dev/null \
  && pass "under-limit body writes (3500 chars)" || { fail "under-limit body should write"; echo "$OUT" >&2; }
echo "$OUT" | jq -e '.path | endswith("under-test-'"$(date -u +%Y%m%d)"'.txt")' >/dev/null \
  && pass "canonical path: <slug>-<YYYYMMDD>.txt" || fail "canonical path wrong"
echo "$OUT" | jq -e '.path | contains("/testrepo/")' >/dev/null \
  && pass "per-repo folder structure" || fail "per-repo folder wrong"

# Behavior: at-limit body writes (exactly 4000)
AT="$TMP/at.txt"
python3 -c "open('$AT','w').write('x'*4000)"
"$SCRIPT" build --repo testrepo --slug at-test --from "$AT" --json 2>&1 | jq -e '.status == "written" and .char_count == 4000' >/dev/null \
  && pass "at-limit body writes (4000 chars)" || fail "at-limit body should write"

# Behavior: over-limit body REFUSES
OVER="$TMP/over.txt"
python3 -c "open('$OVER','w').write('x'*4001)"
OUT="$("$SCRIPT" build --repo testrepo --slug over-test --from "$OVER" --json 2>&1)"
echo "$OUT" | jq -e '.status == "refused" and .char_count == 4001' >/dev/null \
  && pass "over-limit body REFUSES (4001 chars)" || { fail "over-limit body should refuse"; echo "$OUT" >&2; }
[[ ! -f "$GOAL_BUILD_REPO/.flywheel/goals/testrepo/over-test-$(date -u +%Y%m%d).txt" ]] \
  && pass "refused body NOT written to disk" || fail "refused body leaked to disk"

# Behavior: 17000-char body (Joshua's actual case) REFUSES
# Note: script returns 1 on refuse (by design); capture output separately to
# avoid pipefail short-circuiting the test.
HUGE="$TMP/huge.txt"
python3 -c "open('$HUGE','w').write('x'*17343)"
OUT="$("$SCRIPT" build --repo testrepo --slug huge-test --from "$HUGE" --json 2>&1 || true)"
echo "$OUT" | jq -e '.status == "refused" and .char_count == 17343' >/dev/null \
  && pass "17343-char body REFUSES (real failure case)" || fail "17343 should refuse"

# Behavior: check subcommand validates without writing
OUT="$("$SCRIPT" check --from "$UNDER" --json 2>&1 || true)"
echo "$OUT" | jq -e '.status == "pass"' >/dev/null \
  && pass "check: under-limit pass" || fail "check: under-limit"
OUT="$("$SCRIPT" check --from "$OVER" --json 2>&1 || true)"
echo "$OUT" | jq -e '.status == "fail"' >/dev/null \
  && pass "check: over-limit fail" || fail "check: over-limit"

# Behavior: list subcommand
"$SCRIPT" list --repo testrepo --json 2>&1 | jq -e '. | length >= 2 and all(.[]; .limit_ok == true)' >/dev/null \
  && pass "list: shows written files with limit_ok flag" || fail "list"

# Behavior: stdin source
echo -n "stdin body under limit" | "$SCRIPT" build --repo testrepo --slug stdin-test --stdin --json 2>&1 | jq -e '.status == "written"' >/dev/null \
  && pass "stdin body source writes" || fail "stdin source"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
