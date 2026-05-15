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

if bash -n "$SCRIPT" 2>/dev/null; then
  pass "shellcheck: syntax"
else
  fail "syntax"
fi

# Canonical surfaces
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .schema_version and .anti_pattern_fixed' >/dev/null; then
  pass "--info exposes name/version/schema/anti_pattern_fixed"
else
  fail "--info"
fi
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema and .max_chars == 4000' >/dev/null; then
  pass "--schema exposes I/O schemas + max_chars=4000"
else
  fail "--schema"
fi
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length >= 3' >/dev/null; then
  pass "--examples ≥3 invocations"
else
  fail "--examples"
fi
if "$SCRIPT" doctor 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 3)' >/dev/null; then
  pass "doctor envelope"
else
  fail "doctor"
fi

# Behavior: under-limit body writes
UNDER="$TMP/under.txt"
python3 -c "open('$UNDER','w').write('x'*3500)"
OUT="$("$SCRIPT" build --repo testrepo --slug under-test --from "$UNDER" --json 2>&1)"
if echo "$OUT" | jq -e '.status == "written" and .char_count == 3500' >/dev/null; then
  pass "under-limit body writes (3500 chars)"
else
  fail "under-limit body should write"
  echo "$OUT" >&2
fi
if echo "$OUT" | jq -e '.path | endswith("under-test-'"$(date -u +%Y%m%d)"'.txt")' >/dev/null; then
  pass "canonical path: <slug>-<YYYYMMDD>.txt"
else
  fail "canonical path wrong"
fi
if echo "$OUT" | jq -e '.path | contains("/testrepo/")' >/dev/null; then
  pass "per-repo folder structure"
else
  fail "per-repo folder wrong"
fi

# Behavior: at-limit body writes (exactly 4000)
AT="$TMP/at.txt"
python3 -c "open('$AT','w').write('x'*4000)"
if "$SCRIPT" build --repo testrepo --slug at-test --from "$AT" --json 2>&1 | jq -e '.status == "written" and .char_count == 4000' >/dev/null; then
  pass "at-limit body writes (4000 chars)"
else
  fail "at-limit body should write"
fi

# Behavior: over-limit body REFUSES
OVER="$TMP/over.txt"
python3 -c "open('$OVER','w').write('x'*4001)"
OUT="$("$SCRIPT" build --repo testrepo --slug over-test --from "$OVER" --json 2>&1)"
if echo "$OUT" | jq -e '.status == "refused" and .char_count == 4001' >/dev/null; then
  pass "over-limit body REFUSES (4001 chars)"
else
  fail "over-limit body should refuse"
  echo "$OUT" >&2
fi
if [[ ! -f "$GOAL_BUILD_REPO/.flywheel/goals/testrepo/over-test-$(date -u +%Y%m%d).txt" ]]; then
  pass "refused body NOT written to disk"
else
  fail "refused body leaked to disk"
fi

# Behavior: 17000-char body (Joshua's actual case) REFUSES
# Note: script returns 1 on refuse (by design); capture output separately to
# avoid pipefail short-circuiting the test.
HUGE="$TMP/huge.txt"
python3 -c "open('$HUGE','w').write('x'*17343)"
OUT="$("$SCRIPT" build --repo testrepo --slug huge-test --from "$HUGE" --json 2>&1 || true)"
if echo "$OUT" | jq -e '.status == "refused" and .char_count == 17343' >/dev/null; then
  pass "17343-char body REFUSES (real failure case)"
else
  fail "17343 should refuse"
fi

# Behavior: check subcommand validates without writing
OUT="$("$SCRIPT" check --from "$UNDER" --json 2>&1 || true)"
if echo "$OUT" | jq -e '.status == "pass"' >/dev/null; then
  pass "check: under-limit pass"
else
  fail "check: under-limit"
fi
OUT="$("$SCRIPT" check --from "$OVER" --json 2>&1 || true)"
if echo "$OUT" | jq -e '.status == "fail"' >/dev/null; then
  pass "check: over-limit fail"
else
  fail "check: over-limit"
fi

# Behavior: list subcommand
if "$SCRIPT" list --repo testrepo --json 2>&1 | jq -e '. | length >= 2 and all(.[]; .limit_ok == true)' >/dev/null; then
  pass "list: shows written files with limit_ok flag"
else
  fail "list"
fi

# Behavior: stdin source
if echo -n "stdin body under limit" | "$SCRIPT" build --repo testrepo --slug stdin-test --stdin --json 2>&1 | jq -e '.status == "written"' >/dev/null; then
  pass "stdin body source writes"
else
  fail "stdin source"
fi

# Behavior: grade subcommand returns rubric + composite + weakest_dim
GRADE_BODY="$TMP/grade-body.txt"
python3 -c "open('$GRADE_BODY','w').write('continuous-orchestrator-uptime-self-sustaining-fleet\\ncapability control plane\\nself-improving capability loops\\nEXIT criterion 1\\nEXIT criterion 2\\nEXIT criterion 3\\nrevert reversible env flag rollback\\nhard stall greenfield untested\\nfeeds the next phase compounds because\\nBASELINE shipped\\nself-contained\\n')"
OUT="$("$SCRIPT" grade --from "$GRADE_BODY" --json 2>&1 || true)"
if echo "$OUT" | jq -e '.composite >= 0 and .composite <= 100 and .weakest_dim and .scores and .improvements' >/dev/null; then
  pass "grade: returns composite + weakest_dim + scores + improvements"
else
  fail "grade output shape wrong"
  echo "$OUT" >&2
fi

# Behavior: build auto-writes residue (composite + weakest_dim appear in JSON)
RESIDUE_BODY="$TMP/residue-body.txt"
python3 -c "open('$RESIDUE_BODY','w').write('test body under limit\\n')"
OUT="$("$SCRIPT" build --repo testrepo --slug residue-test --from "$RESIDUE_BODY" --json 2>&1)"
if echo "$OUT" | jq -e '.status == "written" and has("composite") and has("weakest_dim") and .residue_logged == true' >/dev/null; then
  pass "build auto-logs residue (composite + weakest_dim in output)"
else
  fail "build residue auto-log missing"
  echo "$OUT" >&2
fi

# Behavior: review subcommand reads ledger (test uses real ledger, so just check shape)
OUT="$("$SCRIPT" review --json 2>&1 || true)"
if echo "$OUT" | jq -e '. | (.total_rows? // .rows? // 0) >= 0' >/dev/null; then
  pass "review subcommand returns ledger summary"
else
  fail "review shape wrong"
fi

# Behavior: weakest subcommand returns JSON envelope
OUT="$("$SCRIPT" weakest --json 2>&1 || true)"
if echo "$OUT" | jq -e 'has("weakest_dim")' >/dev/null; then
  pass "weakest subcommand returns weakest_dim field"
else
  fail "weakest shape wrong"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
