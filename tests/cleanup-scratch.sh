#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cleanup-scratch.sh"
TMP="$(mktemp -d "/tmp/flywheel-cleanup-test.XXXXXX")"
trap '"$SCRIPT" --apply --json "$TMP" >/dev/null 2>&1 || true' EXIT
pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

if bash -n "$SCRIPT"; then
  pass "script_syntax"
else
  fail "script_syntax"
fi

"$SCRIPT" schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.default_mode == "dry-run" and (.mutation_modes | index("--apply")) and .stable_exit_codes."3"' "schema_shape"

"$SCRIPT" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command == "doctor" and (.status == "pass" or .status == "warn") and .subsystems.python.status == "ok"' "doctor_shape"

valid="/tmp/flywheel-valid-test.$$"
mkdir -p "$valid"
printf 'payload\n' >"$valid/payload.txt"

"$SCRIPT" --dry-run --json "$valid" >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.status == "ok" and .reason == "would_remove" and .exists == true and .action == "dry_run"' "valid_dry_run"
if [[ -e "$valid/payload.txt" ]]; then
  pass "dry_run_no_mutation"
else
  fail "dry_run_no_mutation"
fi

"$SCRIPT" --apply --json "$valid" >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "ok" and .reason == "removed" and .action == "removed"' "valid_apply"
if [[ ! -e "$valid" ]]; then
  pass "apply_removed_valid_scratch"
else
  fail "apply_removed_valid_scratch"
fi

missing="$TMP/flywheel-missing"
"$SCRIPT" --apply --json "$missing" >"$TMP/missing.json"
assert_jq "$TMP/missing.json" '.status == "ok" and .reason == "nonexistent_noop" and .exists == false' "missing_noop"

set +e
"$SCRIPT" --apply --json "/tmp/not-allowed-cleanup-test.$$" >"$TMP/invalid.json"
invalid_rc=$?
set -e
if [[ "$invalid_rc" -eq 3 ]]; then pass "invalid_rc_3"; else fail "invalid_rc_3 rc=$invalid_rc"; fi
assert_jq "$TMP/invalid.json" '.status == "refused" and .reason == "path_outside_scratch_allowlist"' "invalid_refused"

set +e
"$SCRIPT" --apply --json relative-path >"$TMP/relative.json"
relative_rc=$?
set -e
if [[ "$relative_rc" -eq 3 ]]; then pass "relative_rc_3"; else fail "relative_rc_3 rc=$relative_rc"; fi
assert_jq "$TMP/relative.json" '.status == "refused" and .reason == "path_not_absolute"' "relative_refused"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
