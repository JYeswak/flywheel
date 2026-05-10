#!/usr/bin/env bash
# tests/test-r0rox-journey-entry-schema.sh
#
# Regression test for flywheel-r0rox (per-bead journey-entry schema +
# validator extension, Layer 1 of flywheel-o4b4h). Asserts:
#   1. Schema file exists and is well-formed JSON
#   2. Schema declares the 8 required fields named in the bead
#   3. Schema's example validates against required-fields rule
#   4. Validator's --info now lists journey_entry_path as required
#   5. Validator REJECTS a DONE callback missing journey_entry_path
#   6. Validator ACCEPTS a DONE callback with valid journey_entry_path
#   7. Validator REJECTS a DONE callback with malformed journey_entry_path
#   8. Validator EXEMPTS BLOCKED callbacks (br_close_executed=not_applicable)
#   9. Dispatch-template.md callback contract names journey_entry_path
set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
SCHEMA="$REPO/.flywheel/validation-schema/v1/journey-entry.v1.schema.json"
VALIDATOR="$REPO/.flywheel/scripts/mission-fitness-callback-validator.sh"
DISPATCH_TEMPLATE="${DISPATCH_TEMPLATE:-$HOME/.claude/commands/flywheel/_shared/dispatch-template.md}"

[[ -f "$SCHEMA" ]] || { echo "FAIL schema missing: $SCHEMA" >&2; exit 1; }
[[ -x "$VALIDATOR" ]] || { echo "FAIL validator missing or not executable: $VALIDATOR" >&2; exit 1; }
[[ -f "$DISPATCH_TEMPLATE" ]] || { echo "FAIL dispatch-template missing: $DISPATCH_TEMPLATE" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. Schema is well-formed JSON
jq -e '.title == "Per-bead journey entry v1"' "$SCHEMA" >/dev/null \
  || fail "schema missing canonical title"
pass "schema is well-formed JSON with canonical title"

# 2. Schema declares all 8 required fields
EXPECTED_REQUIRED='["schema_version","bead_id","task_id","worker_identity","prose","ts","mission_fitness","commit_sha"]'
ACTUAL_REQUIRED=$(jq -c '.required | sort' "$SCHEMA")
EXPECTED_SORTED=$(echo "$EXPECTED_REQUIRED" | jq -c 'sort')
[[ "$ACTUAL_REQUIRED" == "$EXPECTED_SORTED" ]] \
  || fail "required field set mismatch: expected $EXPECTED_SORTED got $ACTUAL_REQUIRED"
pass "schema declares 8 required fields (bead_id, task_id, worker_identity, prose, ts, mission_fitness, commit_sha, schema_version)"

# 3. Schema example has all 8 required fields
jq -e '.examples[0] | (has("schema_version") and has("bead_id") and has("task_id") and has("worker_identity") and has("prose") and has("ts") and has("mission_fitness") and has("commit_sha"))' "$SCHEMA" >/dev/null \
  || fail "example missing one of the 8 required fields"
pass "schema example carries all 8 required fields"

# 4. Validator --info lists journey_entry_path as required
"$VALIDATOR" --info | jq -e '.required_callback_fields | index("journey_entry_path") != null' >/dev/null \
  || fail "validator --info missing journey_entry_path in required_callback_fields"
pass "validator --info lists journey_entry_path as required"

# 5. Validator REJECTS DONE callback missing journey_entry_path
CALLBACK_NO_JEP="DONE flywheel-test1 task_id=flywheel-test1-aaa1 mission_fitness=infrastructure mission_fitness_evidence=test br_close_executed=yes"
set +e
DECISION=$("$VALIDATOR" --callback "$CALLBACK_NO_JEP" --json 2>/dev/null | jq -r '.decision')
set -e
[[ "$DECISION" == "reject_malformed" ]] \
  || fail "DONE without journey_entry_path should reject_malformed; got: $DECISION"
set +e
OUT_NO_JEP=$("$VALIDATOR" --callback "$CALLBACK_NO_JEP" --json 2>/dev/null)
set -e
echo "$OUT_NO_JEP" | jq -e '.missing_fields | index("journey_entry_path") != null' >/dev/null \
  || fail "missing_fields list should include journey_entry_path (got: $(echo "$OUT_NO_JEP" | jq -c '.missing_fields'))"
pass "validator REJECTS DONE callback missing journey_entry_path (decision=reject_malformed; missing_fields includes journey_entry_path)"

# 6. Validator ACCEPTS DONE callback with valid journey_entry_path
CALLBACK_WITH_JEP="DONE flywheel-test2 task_id=flywheel-test2-bbb2 mission_fitness=infrastructure mission_fitness_evidence=test br_close_executed=yes journey_entry_path=/repo/.flywheel/journal/flywheel-test2.md"
set +e
DECISION=$("$VALIDATOR" --callback "$CALLBACK_WITH_JEP" --json 2>/dev/null | jq -r '.decision')
set -e
[[ "$DECISION" == "accept" || "$DECISION" == "warn_infra_recursion" ]] \
  || fail "DONE with valid journey_entry_path should accept (or warn_infra_recursion if 5x infra in a row); got: $DECISION"
pass "validator ACCEPTS DONE callback with valid journey_entry_path (decision=$DECISION)"

# 7. Validator REJECTS DONE callback with malformed journey_entry_path
CALLBACK_BAD_JEP="DONE flywheel-test3 task_id=flywheel-test3-ccc3 mission_fitness=infrastructure mission_fitness_evidence=test br_close_executed=yes journey_entry_path=/wrong/path.txt"
set +e
DECISION=$("$VALIDATOR" --callback "$CALLBACK_BAD_JEP" --json 2>/dev/null | jq -r '.decision')
set -e
[[ "$DECISION" == "reject_malformed" ]] \
  || fail "DONE with malformed journey_entry_path (not .flywheel/journal/<id>.md) should reject_malformed; got: $DECISION"
set +e
OUT_BAD_JEP=$("$VALIDATOR" --callback "$CALLBACK_BAD_JEP" --json 2>/dev/null)
set -e
echo "$OUT_BAD_JEP" | jq -e '.missing_fields | index("journey_entry_path_canonical_form") != null' >/dev/null \
  || fail "missing_fields list should include journey_entry_path_canonical_form (got: $(echo "$OUT_BAD_JEP" | jq -c '.missing_fields'))"
pass "validator REJECTS DONE callback with malformed journey_entry_path (decision=reject_malformed; missing_fields includes journey_entry_path_canonical_form)"

# 8. Validator EXEMPTS BLOCKED callbacks (br_close_executed=not_applicable)
CALLBACK_BLOCKED="BLOCKED flywheel-test4-ddd4 task_id=flywheel-test4-ddd4 reason=external_trigger_not_fired mission_fitness=adjacent mission_fitness_evidence=test br_close_executed=not_applicable"
set +e
DECISION=$("$VALIDATOR" --callback "$CALLBACK_BLOCKED" --json 2>/dev/null | jq -r '.decision')
set -e
[[ "$DECISION" == "accept" || "$DECISION" == "warn_infra_recursion" ]] \
  || fail "BLOCKED callback (br_close_executed=not_applicable) should NOT require journey_entry_path; got decision=$DECISION"
pass "validator EXEMPTS BLOCKED callback from journey_entry_path requirement (decision=$DECISION)"

# 9. Dispatch-template.md callback contract names journey_entry_path
grep -F 'journey_entry_path=<repo>/.flywheel/journal/<bead-id>.md' "$DISPATCH_TEMPLATE" >/dev/null \
  || fail "dispatch-template.md callback contract missing journey_entry_path canonical form"
pass "dispatch-template.md callback contract names journey_entry_path=<repo>/.flywheel/journal/<bead-id>.md"

printf 'flywheel-r0rox journey-entry schema + validator test passed (9 assertions)\n'
