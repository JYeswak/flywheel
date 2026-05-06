#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/orchestrator-callback-artifact-validator.sh"
OPENER="$ROOT/.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh"
WRAPPER="/Users/josh/.claude/commands/flywheel/_shared/orch-callback-artifact-wrapper.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/orchestrator-callback-artifact-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-callback-artifacts.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
pass_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
expect_rc() {
  local name="$1" want="$2"; shift 2
  set +e; "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"; local got=$?; set -e
  [[ "$got" -eq "$want" ]] || { printf 'expected rc=%s got=%s for %s\n' "$want" "$got" "$name" >&2; cat "$TMP/$name.out" "$TMP/$name.err" >&2 || true; exit 1; }
}
assert_jq() { jq -e "$2" "$1" >/dev/null || { jq . "$1" >&2 || cat "$1" >&2; fail "$3"; }; pass "$3"; }
validate_payload() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator(schema).validate(payload)
PY
}

mkdir -p "$TMP/repo/.flywheel/scripts" "$TMP/repo/.flywheel/tests" "$TMP/repo/.flywheel/validation-schema/v1" "$TMP/repo/.beads"
git -C "$TMP/repo" init -q
: >"$TMP/repo/.beads/issues.jsonl"
export ORCH_CALLBACK_ARTIFACT_LEDGER="$TMP/validator-ledger.jsonl"
export ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER="$TMP/fix-ledger.jsonl"
export ORCH_CALLBACK_ARTIFACT_FIX_BEAD_OPENER="$OPENER"

write_script() { local p="$1"; { printf '#!/usr/bin/env bash\nset -euo pipefail\n'; printf 'printf "fixture line %s\\n"\n' {1..18}; } >"$p"; chmod +x "$p"; }
write_test() { local p="$1"; { printf '#!/usr/bin/env bash\nset -euo pipefail\n'; printf 'printf "test line %s\\n"\n' {1..35}; } >"$p"; }
write_schema() {
  local p="$1"
  cat >"$p" <<'JSON'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://zeststream.ai/schemas/fixture.json",
  "title": "Fixture schema with enough bytes for artifact validation",
  "type": "object",
  "additionalProperties": false,
  "required": ["name"],
  "properties": {
    "name": { "type": "string", "minLength": 1 }
  }
}
JSON
}
write_md() { local p="$1"; { printf '# Fixture incidents\n\n'; printf 'Artifact validation fixture paragraph %s keeps the markdown above threshold.\n' {1..20}; } >"$p"; }
write_dispatch() {
  local file="$1" extra="${2:-}"
  cat >"$file" <<EOF
# Fixture dispatch

## Required artifacts

### 1. Validator script

Path: \`.flywheel/scripts/artifact-validator-fixture.sh\`

### 2. Auto-fix-bead helper

Path: \`.flywheel/scripts/artifact-opener-fixture.sh\`

### 3. Acceptance test

Path: \`.flywheel/tests/artifact-validator-fixture-test.sh\`

### 4. Schema

Path: \`.flywheel/validation-schema/v1/artifact-fixture.schema.json\`

### 5. INCIDENTS.md additive entry

\`INCIDENTS.md\` documents the structural artifact gate.
$extra

## L112 verify

Expected: fixture
EOF
}

write_script "$TMP/repo/.flywheel/scripts/artifact-validator-fixture.sh"
write_script "$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"
write_test "$TMP/repo/.flywheel/tests/artifact-validator-fixture-test.sh"
write_schema "$TMP/repo/.flywheel/validation-schema/v1/artifact-fixture.schema.json"
write_md "$TMP/repo/INCIDENTS.md"
write_dispatch "$TMP/dispatch.md"
evidence=".flywheel/scripts/artifact-validator-fixture.sh,.flywheel/scripts/artifact-opener-fixture.sh,.flywheel/tests/artifact-validator-fixture-test.sh,.flywheel/validation-schema/v1/artifact-fixture.schema.json,INCIDENTS.md"

bash -n "$VALIDATOR" && pass "validator_shell_syntax"
bash -n "$OPENER" && pass "opener_shell_syntax"
bash -n "$WRAPPER" && pass "wrapper_shell_syntax"
jq empty "$SCHEMA" && pass "schema_json_parses"
"$VALIDATOR" --help >/dev/null && "$VALIDATOR" --examples >/dev/null && "$VALIDATOR" --info >/dev/null && pass "validator_help_examples_info"

expect_rc pass 0 "$VALIDATOR" check --callback-text "DONE task-pass bead=flywheel-parent evidence=$evidence" --dispatch-file "$TMP/dispatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/pass.out" '.decision == "PASS" and .total_artifacts == 5 and .fulfilled_count == 5' "all_artifacts_fulfilled_pass"
validate_payload "$TMP/pass.out"; pass "pass_json_shape_valid"

rm "$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"
expect_rc missing 1 "$VALIDATOR" check --callback-text "DONE task-missing bead=flywheel-parent evidence=$evidence" --dispatch-file "$TMP/dispatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/missing.out" '.decision == "REFUSE" and .reason == "artifact_missing" and (.missing_artifacts | index(".flywheel/scripts/artifact-opener-fixture.sh")) and (.fix_bead_id | startswith("flywheel-fix-"))' "missing_artifact_refuses_and_files_fix"
write_script "$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"

printf '#!/usr/bin/env bash\n' >"$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"; chmod +x "$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"
expect_rc subbytes 1 "$VALIDATOR" check --callback-text "DONE task-subbytes bead=flywheel-parent evidence=$evidence" --dispatch-file "$TMP/dispatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/subbytes.out" '.decision == "REFUSE" and .reason == "artifact_subthreshold"' "sub_byte_threshold_refuses"
write_script "$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"

{ printf '{not-json\n'; printf 'malformed schema filler %s\n' {1..30}; } >"$TMP/repo/.flywheel/validation-schema/v1/artifact-fixture.schema.json"
expect_rc badschema 1 "$VALIDATOR" check --callback-text "DONE task-badschema bead=flywheel-parent evidence=$evidence" --dispatch-file "$TMP/dispatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/badschema.out" '.decision == "REFUSE" and .reason == "artifact_malformed"' "malformed_json_schema_refuses"
write_schema "$TMP/repo/.flywheel/validation-schema/v1/artifact-fixture.schema.json"

chmod -x "$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"
expect_rc nonexec 1 "$VALIDATOR" check --callback-text "DONE task-nonexec bead=flywheel-parent evidence=$evidence" --dispatch-file "$TMP/dispatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/nonexec.out" '.decision == "REFUSE" and .reason == "artifact_malformed"' "non_executable_script_refuses"
chmod +x "$TMP/repo/.flywheel/scripts/artifact-opener-fixture.sh"

printf '# no required artifacts here\n' >"$TMP/no-required.md"
expect_rc norequired 2 "$VALIDATOR" check --callback-text "DONE task-norequired bead=flywheel-parent evidence=$evidence" --dispatch-file "$TMP/no-required.md" --repo "$TMP/repo" --json
assert_jq "$TMP/norequired.out" '.decision == "UNVERIFIABLE" and .reason == "required_artifacts_section_missing" and .exit_code == 2' "missing_required_artifacts_section_fail_open"

bad_evidence=".flywheel/scripts/artifact-validator-fixture.sh,.flywheel/scripts/artifact-opener-fixture.sh"
expect_rc mismatch 1 "$VALIDATOR" check --callback-text "DONE task-mismatch bead=flywheel-parent evidence=$bad_evidence" --dispatch-file "$TMP/dispatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/mismatch.out" '.decision == "REFUSE" and .reason == "evidence_artifact_mismatch" and (.evidence_missing_artifacts | length) == 3' "evidence_artifact_mismatch_refuses"

for file in "$TMP/missing.out" "$TMP/subbytes.out" "$TMP/badschema.out" "$TMP/nonexec.out" "$TMP/norequired.out" "$TMP/mismatch.out"; do validate_payload "$file"; done
pass "refusal_json_shapes_valid"

ledger_count="$(wc -l <"$ORCH_CALLBACK_ARTIFACT_LEDGER" | tr -d ' ')"
[[ "$ledger_count" -eq 7 ]] || fail "ledger row count expected 7 got $ledger_count"
jq empty "$ORCH_CALLBACK_ARTIFACT_LEDGER" && pass "ledger_row_appended_on_every_decision"

before_lines="$(wc -l <"$TMP/repo/.beads/issues.jsonl" | tr -d ' ')"
"$OPENER" --repo "$TMP/repo" --task-id idem-task --bead flywheel-parent --reason artifact_missing --dispatch-file "$TMP/dispatch.md" --artifact-list "missing.sh" --json >"$TMP/idem1.json"
"$OPENER" --repo "$TMP/repo" --task-id idem-task --bead flywheel-parent --reason artifact_missing --dispatch-file "$TMP/dispatch.md" --artifact-list "missing.sh" --json >"$TMP/idem2.json"
after_lines="$(wc -l <"$TMP/repo/.beads/issues.jsonl" | tr -d ' ')"
[[ "$((after_lines - before_lines))" -eq 1 ]] || fail "idempotent opener wrote duplicate issues"
assert_jq "$TMP/idem2.json" '.action == "reused" and (.fix_bead_id | startswith("flywheel-fix-"))' "fix_bead_opener_idempotent"

expect_rc wrapper_pass 0 env ORCH_CALLBACK_ARTIFACT_DISPATCH_FILE="$TMP/dispatch.md" ORCH_CALLBACK_ARTIFACT_LEDGER="$TMP/wrapper-ledger.jsonl" ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER="$TMP/wrapper-fix-ledger.jsonl" "$WRAPPER" --repo "$TMP/repo" <<<"DONE task-wrapper bead=flywheel-parent evidence=$evidence"
pass "wrapper_callable_pass_silent"

printf 'PASS cases=10 assertions=%s failures=0\n' "$pass_count"
