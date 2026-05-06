#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orch-donella-trace-gate.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/orch-donella-trace-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-donella-trace-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || cat "$file" >&2
    fail "$label"
  fi
}

schema_validate() {
  local file="$1"
  python3 -c 'import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)' "$SCHEMA" "$file"
}

run_gate() {
  local name="$1" expected_rc="$2" text="$3"
  local out="$TMP/$name.out"
  set +e
  ORCH_DONELLA_LEDGER="$TMP/ledger.jsonl" \
    "$SCRIPT" check --text-stdin --session fixture --json <<<"$text" >"$out"
  rc=$?
  set -e
  [[ "$rc" -eq "$expected_rc" ]] || { cat "$out" >&2 || true; fail "$name expected rc=$expected_rc got rc=$rc"; }
  jq empty "$out" >/dev/null || fail "$name JSON parse"
  schema_validate "$out" || fail "$name schema validation"
  pass "${name}_schema"
}

command -v jq >/dev/null 2>&1 || fail "missing jq"
bash -n "$SCRIPT" && pass "script_syntax"
jq empty "$SCHEMA" >/dev/null && pass "schema_json_parses"
"$SCRIPT" --help >/dev/null && pass "help"
"$SCRIPT" --info | jq -e '.name == "orch-donella-trace-gate.sh" and .required_keywords == 5' >/dev/null && pass "info_json"
"$SCRIPT" --examples | grep -q -- '--text-stdin' && pass "examples"

run_gate josh_refuse 1 "Should we deploy this?"
assert_jq "$TMP/josh_refuse.out" '.decision == "refuse" and .reason == "joshua_disposes_without_donella_trace" and .joshua_disposes_pattern == "should we" and .donella_keywords_found == 0' "case1_refuse_no_keywords"

run_gate trace5_allow 0 "Boundary: dispatch substrate. Stock: idle worker pane. Flow: bead queue. Loop: feedback. Leverage: structural gate. Should we deploy this?"
assert_jq "$TMP/trace5_allow.out" '.decision == "allow" and .reason == "donella_trace_present" and .donella_keywords_found == 5' "case2_allow_5_keywords"

run_gate trace7_allow 0 "Boundary: dispatch substrate. Stock: idle worker pane. Flow: bead queue. Loop: feedback. Leverage: structural gate. Intervention: Stop hook. Measurement: refusal ledger. Do we ship this?"
assert_jq "$TMP/trace7_allow.out" '.decision == "allow" and .reason == "donella_trace_present" and .donella_keywords_found == 7' "case3_allow_7_keywords"

run_gate blocker_allow 0 "Want me to rotate the Vercel API key now?"
assert_jq "$TMP/blocker_allow.out" '.decision == "allow" and .blocker_class_matched == "credential_or_secret_rotation"' "case4_allow_blocker_class"

run_gate no_pattern_allow 0 "Callback evidence is attached and validation passed."
assert_jq "$TMP/no_pattern_allow.out" '.decision == "allow" and .reason == "no_donella_gated_pattern" and .joshua_disposes_pattern == null' "case5_allow_no_pattern"

missing_out="$TMP/missing-file.out"
ORCH_DONELLA_LEDGER="$TMP/ledger.jsonl" "$SCRIPT" check --text-file "$TMP/does-not-exist" --session fixture --json >"$missing_out"
schema_validate "$missing_out" || fail "missing text-file schema validation"
assert_jq "$missing_out" '.decision == "allow" and .reason == "text_file_unreadable_fail_open" and (.warnings[0] | test("text_file_unreadable_fail_open"))' "case6_allow_missing_text_file"

run_gate action_refuse 1 "I will wire the Stop hook gate in settings after this."
assert_jq "$TMP/action_refuse.out" '.decision == "refuse" and .reason == "substrate_action_without_donella_trace" and .action_without_trace_pattern == "substrate action"' "case7_refuse_action_without_trace"

run_gate action_trace_allow 0 "Boundary: hook output. Stock: Joshua-disposes prompts. Flow: assistant turns. Loop: Stop gate feedback. Leverage: rules. I will wire the Stop hook gate in settings after this."
assert_jq "$TMP/action_trace_allow.out" '.decision == "allow" and .reason == "donella_trace_present" and .action_without_trace_pattern == "substrate action"' "case8_allow_action_with_trace"

ledger_count="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
[[ "$ledger_count" -eq 8 ]] || fail "expected 8 ledger rows, got $ledger_count"
while IFS= read -r row; do
  jq empty <<<"$row" >/dev/null || fail "ledger row is not JSON"
done <"$TMP/ledger.jsonl"
pass "ledger_row_appended_on_every_decision"

printf 'Summary: %s passed\n' "$pass_count"
