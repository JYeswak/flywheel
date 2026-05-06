#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REPLAY="$ROOT/polish-gate/replay-to-ledger.py"
SHIM="$ROOT/polish-gate/replay-to-ledger.sh"
SCHEMA="$ROOT/polish-gate/v1/replay-output.schema.json"
VERIFIER="$ROOT/../../.flywheel/scripts/wire-or-explain-chain-verifier.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-gate-replay.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

run_case() {
  local label="$1"
  shift
  if "$@"; then
    pass "$label"
  else
    fail "$label"
  fi
}

validate_schema() {
  python3 -c 'import json, sys; from jsonschema import Draft202012Validator; Draft202012Validator.check_schema(json.load(open(sys.argv[1], encoding="utf-8")))' "$1"
}

validate_payload() {
  python3 -c 'import json, sys; from jsonschema import Draft202012Validator; schema=json.load(open(sys.argv[1], encoding="utf-8")); payload=json.load(open(sys.argv[2], encoding="utf-8")); Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)' "$1" "$2"
}

write_receipts() {
  local path="$1"
  python3 - "$path" <<'PY'
import json
import sys

path = sys.argv[1]
lanes = {
    "ubs": 9.2,
    "simplify": 9.1,
    "extreme-opt": 9.3,
    "readme": 9.4,
    "canonical-cli": 9.5,
}
rows = []
for idx in range(5):
    ts = f"2026-05-05T00:0{idx}:00Z"
    rows.append({
        "schema_version": "polish-gate/grade-receipt/v1",
        "ts": ts,
        "surface_path": f".flywheel/surface-{idx}.md",
        "surface_name": f"surface-{idx}.md",
        "mode": "audit_only",
        "skills": lanes,
        "composite": 9.3,
        "verdict": "AUDIT_ONLY",
        "evidence_paths": [f".flywheel/polish-gate/evidence/surface-{idx}.json"],
        "grader": "fixture-grader",
        "mission_anchor_hash": "sha256:fixture",
    })
with open(path, "w", encoding="utf-8") as handle:
    for row in rows:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
PY
}

write_receipts "$TMP/grades.jsonl"

bash -n "$SHIM" && pass "shim_syntax" || fail "shim_syntax"
python3 -m py_compile "$REPLAY" && pass "python_syntax" || fail "python_syntax"
python3 "$REPLAY" --schema >"$TMP/schema.json"
run_case schema_flag_valid validate_schema "$TMP/schema.json"
run_case help_flags bash -c 'python3 "$0" --help | grep -q -- "--source" && python3 "$0" --help | grep -q -- "--target-ledger" && python3 "$0" --help | grep -q -- "--apply-to-live" && python3 "$0" --help | grep -q -- "--from-ts" && python3 "$0" --help | grep -q -- "--dry-run" && python3 "$0" --help | grep -q -- "--apply" && python3 "$0" --help | grep -q -- "--json" && python3 "$0" --help | grep -q -- "--schema" && python3 "$0" --help | grep -q -- "--explain"' "$REPLAY"

python3 "$REPLAY" --source "$TMP/grades.jsonl" --target-ledger "$TMP/dry-ledger.jsonl" --dry-run --json --explain >"$TMP/dry.json"
run_case dry_run_five_translations bash -c 'jq -e ".rows_loaded == 5 and .rows_translated == 5 and .chain_verify_post == \"PASS\" and (.translations | length) == 5" "$0" >/dev/null && test ! -e "$1"' "$TMP/dry.json" "$TMP/dry-ledger.jsonl"
run_case dry_run_output_schema validate_payload "$SCHEMA" "$TMP/dry.json"

target="$TMP/test-ledger.jsonl"
python3 "$REPLAY" --source "$TMP/grades.jsonl" --target-ledger "$target" --apply --json --explain >"$TMP/apply.json"
run_case apply_writes_five bash -c 'jq -e ".rows_loaded == 5 and .rows_translated == 5 and .chain_verify_post == \"PASS\"" "$0" >/dev/null && test "$(wc -l <"$1" | tr -d " ")" = "5"' "$TMP/apply.json" "$target"
run_case verifier_confirms_integrity bash -c 'bash "$0" --ledger "$1" --json | jq -e ".status == \"pass\" and .row_count == 5" >/dev/null' "$VERIFIER" "$target"

before_sha="$(shasum -a 256 "$target" | awk '{print $1}')"
python3 "$REPLAY" --source "$TMP/grades.jsonl" --target-ledger "$target" --apply --json --explain >"$TMP/idempotent.json"
after_sha="$(shasum -a 256 "$target" | awk '{print $1}')"
run_case idempotent_apply bash -c 'test "$0" = "$1" && jq -e ".rows_translated == 0 and .rows_skipped.dup == 5" "$2" >/dev/null' "$before_sha" "$after_sha" "$TMP/idempotent.json"

python3 "$REPLAY" --source "$TMP/grades.jsonl" --target-ledger "$TMP/from-ledger.jsonl" --from-ts "2026-05-05T00:02:00Z" --dry-run --json --explain >"$TMP/from.json"
run_case from_ts_filters_strictly_after bash -c 'jq -e ".rows_translated == 2 and .rows_skipped[\"pre-from-ts\"] == 3" "$0" >/dev/null' "$TMP/from.json"

corrupt="$TMP/corrupt-live.jsonl"
python3 "$REPLAY" --source "$TMP/grades.jsonl" --target-ledger "$corrupt" --apply --json >/dev/null
jq -c 'if .sequence_num == 1 then .checksum = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" else . end' "$corrupt" >"$TMP/corrupt.tmp"
mv "$TMP/corrupt.tmp" "$corrupt"
set +e
python3 "$REPLAY" --source "$TMP/grades.jsonl" --target-ledger "$corrupt" --apply --apply-to-live --json >"$TMP/corrupt.json"
corrupt_rc=$?
set -e
run_case apply_to_live_refuses_corrupt_prestate bash -c 'test "$0" -eq 1 && jq -e ".exit_code == 1 and .chain_verify_pre == \"FAIL\" and .chain_verify_post == \"N/A\"" "$1" >/dev/null' "$corrupt_rc" "$TMP/corrupt.json"

cp "$TMP/grades.jsonl" "$TMP/schema-fail.jsonl"
jq -nc '{"schema_version":"polish-gate/grade-receipt/v1","ts":"2026-05-05T00:06:00Z","surface_path":".flywheel/bad.md"}' >>"$TMP/schema-fail.jsonl"
python3 "$REPLAY" --source "$TMP/schema-fail.jsonl" --target-ledger "$TMP/schema-fail-ledger.jsonl" --dry-run --json >"$TMP/schema-fail.json"
run_case schema_fail_row_skipped bash -c 'jq -e ".exit_code == 0 and .rows_loaded == 6 and .rows_translated == 5 and .rows_skipped[\"schema-fail\"] == 1" "$0" >/dev/null' "$TMP/schema-fail.json"

run_case checked_in_output_schema validate_schema "$SCHEMA"
run_case apply_output_schema validate_payload "$SCHEMA" "$TMP/apply.json"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

[[ "$pass_count" -eq 14 ]] || { printf 'FAIL expected 14 assertions, got %d\n' "$pass_count" >&2; exit 1; }
printf 'PASS: polish gate ledger replay cases=9 assertions=%d\n' "$pass_count"
