#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/reconcile-polish-gate.sh"
SCHEMA="$ROOT/polish-gate/v1/reconcile-output.schema.json"
FIXTURES="$ROOT/tests/fixtures/polish-gate-reconcile"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-gate-reconcile.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS: %s\n' "$*"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

copy_fixture() {
  local name="$1" dest="$2"
  mkdir -p "$dest"
  cp -R "$FIXTURES/$name/." "$dest/"
}

assert_jq_file() {
  local file="$1" filter="$2" label="$3"
  jq -e "$filter" "$file" >/dev/null || fail "$label"
}

validate_result() {
  local payload="$1" label="$2"
  python3 - "$SCHEMA" "$payload" <<'PY' || exit 1
import json
import sys
from jsonschema import Draft202012Validator

with open(sys.argv[1], encoding="utf-8") as handle:
    schema = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    payload = json.load(handle)
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)
PY
  printf 'PASS: %s\n' "$label"
}

backup_ts_from_result() {
  jq -r '.files_modified[0].backup_path | capture("[.]bak[.](?<ts>.+)$").ts' "$1"
}

bash -n "$SCRIPT"
"$SCRIPT" --schema | jq -e '.title == "Polish gate reconcile output v1"' >/dev/null
validate_result <(jq -n '{
  ts:"<timestamp>",
  repo_path:"/tmp/repo",
  action:"detect",
  prior_state:"reconciled",
  target_state:"reconciled",
  already_reconciled:true,
  files_modified:[],
  mode_applied:"audit_only",
  manifest_validates:true,
  errors:[],
  diff:[]
}') "schema validates reconcile output"

fresh="$TMP/fresh"
copy_fixture fresh "$fresh"
"$SCRIPT" --repo "$fresh" --detect --json >"$TMP/fresh-detect.json"
assert_jq_file "$TMP/fresh-detect.json" '.already_reconciled == true and .prior_state == "reconciled" and .manifest_validates == true' "fresh detect result"
pass "fresh-template repo detects already reconciled"

pre="$TMP/pre"
copy_fixture pre-polish-gate "$pre"
set +e
"$SCRIPT" --repo "$pre" --detect --json >"$TMP/pre-detect.json"
pre_detect_rc=$?
set -e
[[ "$pre_detect_rc" == "2" ]] || fail "pre-polish detect rc expected 2 got $pre_detect_rc"
assert_jq_file "$TMP/pre-detect.json" '.prior_state == "no_polish_gate" and .target_state == "reconciled"' "pre detect state"

before_sha="$(shasum -a 256 "$pre/.flywheel/MISSION.md" | awk '{print $1}')"
"$SCRIPT" --repo "$pre" --dry-run --json >"$TMP/pre-dry.json"
after_dry_sha="$(shasum -a 256 "$pre/.flywheel/MISSION.md" | awk '{print $1}')"
[[ "$before_sha" == "$after_dry_sha" ]] || fail "dry-run mutated MISSION.md"
assert_jq_file "$TMP/pre-dry.json" '.diff | any(contains("polish_gate_mode: audit_only"))' "dry-run diff includes mission mode"

"$SCRIPT" --repo "$pre" --apply --json >"$TMP/pre-apply.json"
validate_result "$TMP/pre-apply.json" "apply output validates schema"
assert_jq_file "$TMP/pre-apply.json" '.manifest_validates == true and (.files_modified | length) == 3 and .mode_applied == "audit_only"' "apply modified three files"
grep -qF 'polish_gate_mode: audit_only' "$pre/.flywheel/MISSION.md" || fail "MISSION missing audit_only mode"
grep -qF 'Preserve this mission paragraph verbatim.' "$pre/.flywheel/MISSION.md" || fail "MISSION body not preserved"
grep -qF 'Preserve this state note verbatim.' "$pre/.flywheel/STATE.md" || fail "STATE body not preserved"
jq -e '.polish_gate.mode == "audit_only" and .polish_gate.scope == "all_declared"' "$pre/.flywheel/loop.json" >/dev/null || fail "loop polish_gate not reconciled"

"$SCRIPT" --repo "$pre" --apply --json >"$TMP/pre-apply2.json"
assert_jq_file "$TMP/pre-apply2.json" '.already_reconciled == true and (.files_modified | length) == 0' "second apply idempotent"
pass "pre-polish repo detect/dry-run/apply/idempotency"
pass "repo-local mission and state text preserved verbatim"

custom="$TMP/custom"
copy_fixture custom-mode-set "$custom"
"$SCRIPT" --repo "$custom" --apply --json >"$TMP/custom-apply.json"
grep -qF 'polish_gate_mode: blocking' "$custom/.flywheel/MISSION.md" || fail "custom mission mode overwritten"
jq -e '.polish_gate.mode == "blocking"' "$custom/.flywheel/loop.json" >/dev/null || fail "custom loop mode not preserved"
pass "custom mode is preserved"

malformed="$TMP/malformed"
copy_fixture malformed "$malformed"
set +e
"$SCRIPT" --repo "$malformed" --detect --json >"$TMP/malformed-detect.json"
malformed_detect_rc=$?
"$SCRIPT" --repo "$malformed" --apply --json >"$TMP/malformed-apply.json"
malformed_apply_rc=$?
set -e
[[ "$malformed_detect_rc" == "3" && "$malformed_apply_rc" == "3" ]] || fail "malformed rc expected 3/3 got $malformed_detect_rc/$malformed_apply_rc"
assert_jq_file "$TMP/malformed-detect.json" '.prior_state == "malformed" and (.errors | length) >= 1' "malformed detect payload"
pass "malformed MISSION refuses detect and apply"

rollback_repo="$TMP/rollback"
copy_fixture rollback "$rollback_repo"
mission_sha_before="$(shasum -a 256 "$rollback_repo/.flywheel/MISSION.md" | awk '{print $1}')"
state_sha_before="$(shasum -a 256 "$rollback_repo/.flywheel/STATE.md" | awk '{print $1}')"
loop_sha_before="$(shasum -a 256 "$rollback_repo/.flywheel/loop.json" | awk '{print $1}')"
"$SCRIPT" --repo "$rollback_repo" --apply --json >"$TMP/rollback-apply.json"
rollback_ts="$(backup_ts_from_result "$TMP/rollback-apply.json")"
"$SCRIPT" --repo "$rollback_repo" --rollback "$rollback_ts" --json >"$TMP/rollback.json"
[[ "$mission_sha_before" == "$(shasum -a 256 "$rollback_repo/.flywheel/MISSION.md" | awk '{print $1}')" ]] || fail "MISSION rollback not byte-exact"
[[ "$state_sha_before" == "$(shasum -a 256 "$rollback_repo/.flywheel/STATE.md" | awk '{print $1}')" ]] || fail "STATE rollback not byte-exact"
[[ "$loop_sha_before" == "$(shasum -a 256 "$rollback_repo/.flywheel/loop.json" | awk '{print $1}')" ]] || fail "loop rollback not byte-exact"
assert_jq_file "$TMP/rollback.json" '.target_state == "rolled_back" and (.files_modified | length) == 3' "rollback payload"
pass "rollback restores byte-exact prior state"

schema_repo="$TMP/schema-post-apply"
copy_fixture pre-polish-gate "$schema_repo"
"$SCRIPT" --repo "$schema_repo" --apply --json >"$TMP/schema-apply.json"
assert_jq_file "$TMP/schema-apply.json" '.manifest_validates == true' "manifest validates post apply"
pass "post-apply manifest validation passes"

[[ "$pass_count" == "7" ]] || fail "expected 7 case passes, got $pass_count"
printf 'PASS: polish gate reconcile cases=%s\n' "$pass_count"
