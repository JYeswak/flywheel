#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/substrate-loop-contract-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/substrate-loop-contract.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  local got=$?
  set -e
  if [[ "$got" -ne "$want" ]]; then
    fail "$name rc expected=$want got=$got"
    cat "$TMP/$name.out" >&2 || true
    cat "$TMP/$name.err" >&2 || true
    exit 1
  fi
}

write_primitives() {
  local path="$1"
  cat >"$path" <<'JSON'
[
  {
    "primitive_name": "full-contract",
    "self_repair_action": "full --repair --apply",
    "measurement_field": "full_status",
    "escalation_path": "fuckup-log:class=full-missing"
  },
  {
    "primitive_name": "missing-schema",
    "self_repair_action": "missing --repair --apply",
    "measurement_field": "missing_status",
    "escalation_path": "fuckup-log:class=missing-schema"
  },
  {
    "primitive_name": "absent-contract",
    "self_repair_action": "absent --repair --apply",
    "measurement_field": "absent_status",
    "escalation_path": "fuckup-log:class=absent"
  }
]
JSON
}

append_valid_contract() {
  local ledger="$1" primitive="$2"
  jq -nc --arg primitive "$primitive" --arg ts "2026-05-05T03:30:00Z" '{
    primitive_name:$primitive,
    declares_loop:"yes",
    self_repair_action:"repair --apply",
    measurement_field:($primitive + "_status"),
    escalation_path:"fuckup-log:class=fixture",
    schema_version:"substrate-loop-contract.v1",
    bootstrap_seed_v1:"fixture contract row",
    ts:$ts
  }' >>"$ledger"
}

append_missing_schema_contract() {
  local ledger="$1"
  jq -nc --arg ts "2026-05-05T03:31:00Z" '{
    primitive_name:"missing-schema",
    declares_loop:"yes",
    self_repair_action:"missing --repair --apply",
    measurement_field:"missing_status",
    escalation_path:"fuckup-log:class=missing-schema",
    bootstrap_seed_v1:"fixture row missing schema version",
    ts:$ts
  }' >>"$ledger"
}

bash -n "$SCRIPT"
"$SCRIPT" --info --json | jq -e '.schema_version == "substrate-loop-contract.v1"' >/dev/null
"$SCRIPT" --examples --json | jq -e '(.examples | length) >= 4' >/dev/null
"$SCRIPT" quickstart --json | jq -e '(.steps | length) >= 4' >/dev/null
"$SCRIPT" schema doctor --json | jq -e '.required | index("substrate_loop_contract_self_row_present")' >/dev/null
"$SCRIPT" completion bash | rg -q 'substrate-loop-contract-validator'
pass "canonical_cli_surfaces"

empty_primitives="$TMP/empty-primitives.json"
printf '[]\n' >"$empty_primitives"
fresh_ledger="$TMP/fresh-contract.jsonl"
fresh_fuckup="$TMP/fresh-fuckup.jsonl"
expect_rc fresh_bootstrap 0 env \
  SUBSTRATE_LOOP_CONTRACT_LEDGER="$fresh_ledger" \
  SUBSTRATE_LOOP_CONTRACT_FUCKUP_LOG="$fresh_fuckup" \
  SUBSTRATE_LOOP_CONTRACT_PRIMITIVES_FILE="$empty_primitives" \
  SUBSTRATE_LOOP_CONTRACT_NOW="2026-05-05T03:32:00Z" \
  "$SCRIPT" --doctor --json
assert_jq "$TMP/fresh_bootstrap.out" '.substrate_loop_contract_self_row_present == true and .bootstrap_action == "appended" and .status == "pass"' "fresh_install_bootstraps_self_row"

primitives="$TMP/primitives.json"
ledger="$TMP/contracts.jsonl"
fuckup="$TMP/fuckups.jsonl"
write_primitives "$primitives"
append_valid_contract "$ledger" "full-contract"
append_missing_schema_contract "$ledger"

expect_rc synthetic_missing 1 env \
  SUBSTRATE_LOOP_CONTRACT_LEDGER="$ledger" \
  SUBSTRATE_LOOP_CONTRACT_FUCKUP_LOG="$fuckup" \
  SUBSTRATE_LOOP_CONTRACT_PRIMITIVES_FILE="$primitives" \
  SUBSTRATE_LOOP_CONTRACT_NOW="2026-05-05T03:33:00Z" \
  "$SCRIPT" --doctor --json
assert_jq "$TMP/synthetic_missing.out" '.substrate_loop_contract_self_row_present == true and .substrate_loop_contract_primitives_audited == 4 and (.substrate_loop_contract_primitives_missing | index("missing-schema")) and (.substrate_loop_contract_primitives_missing | index("absent-contract")) and ((.substrate_loop_contract_primitives_missing | index("full-contract")) | not)' "synthetic_three_primitives_classified"

assert_jq "$TMP/synthetic_missing.out" '.substrate_loop_contract_primitives_schema_drift == ["missing-schema"]' "schema_version_drift_detected"

before_contract_hash="$(shasum -a 256 "$ledger" | awk '{print $1}')"
before_fuckup_hash="$(if [[ -f "$fuckup" ]]; then shasum -a 256 "$fuckup" | awk '{print $1}'; else printf absent; fi)"
expect_rc repair_dry_run 0 env \
  SUBSTRATE_LOOP_CONTRACT_LEDGER="$ledger" \
  SUBSTRATE_LOOP_CONTRACT_FUCKUP_LOG="$fuckup" \
  SUBSTRATE_LOOP_CONTRACT_PRIMITIVES_FILE="$primitives" \
  "$SCRIPT" repair --scope all --dry-run --json
after_contract_hash="$(shasum -a 256 "$ledger" | awk '{print $1}')"
after_fuckup_hash="$(if [[ -f "$fuckup" ]]; then shasum -a 256 "$fuckup" | awk '{print $1}'; else printf absent; fi)"
if [[ "$before_contract_hash" == "$after_contract_hash" && "$before_fuckup_hash" == "$after_fuckup_hash" ]]; then
  pass "dry_run_does_not_mutate"
else
  fail "dry_run_does_not_mutate"
fi

apply_ledger="$TMP/apply-contracts.jsonl"
apply_fuckup="$TMP/apply-fuckups.jsonl"
append_valid_contract "$apply_ledger" "full-contract"
append_missing_schema_contract "$apply_ledger"
expect_rc repair_apply 0 env \
  SUBSTRATE_LOOP_CONTRACT_LEDGER="$apply_ledger" \
  SUBSTRATE_LOOP_CONTRACT_FUCKUP_LOG="$apply_fuckup" \
  SUBSTRATE_LOOP_CONTRACT_PRIMITIVES_FILE="$primitives" \
  SUBSTRATE_LOOP_CONTRACT_NOW="2026-05-05T03:34:00Z" \
  "$SCRIPT" repair --scope all --apply --json
jq -e 'select(.primitive_name == "substrate-loop-contract-validator" and .schema_version == "substrate-loop-contract.v1")' "$apply_ledger" >/dev/null
jq -s -e '[.[] | select(.trauma_class == "substrate-loop-contract-missing")] | length == 2' "$apply_fuckup" >/dev/null
pass "apply_writes_self_row_and_missing_primitive_rows"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAILED substrate-loop-contract-validator tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK substrate-loop-contract-validator tests pass=%s/6\n' "$pass_count"
