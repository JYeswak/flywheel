#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/polish-gate/run-grader.py"
SHIM="$ROOT/polish-gate/run-grader.sh"
RESULT_SCHEMA="$ROOT/polish-gate/v1/grade-run-result.schema.json"
RECEIPT_SCHEMA="$ROOT/polish-gate/v1/grade-receipt.schema.json"
SUMMARY_SCHEMA="$ROOT/polish-gate/v1/latest-summary.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-gate-runner.XXXXXX")"
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

write_manifest() {
  local repo="$1" mode="$2"
  mkdir -p "$repo/.flywheel/polish-gate"
  jq -n --arg mode "$mode" '{
    version:"1",
    mode:$mode,
    scope:"repo_local_flywheel",
    legacy_bootstrap_policy:"warn_until_touched",
    blocking_when:["malformed_gate"],
    grade_storage:".flywheel/polish-gate/grades.jsonl",
    latest_summary:".flywheel/polish-gate/latest.json"
  }' >"$repo/.flywheel/polish-gate/manifest.json"
}

make_repo() {
  local repo="$1" mode="${2:-audit_only}"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/docs" "$repo/src/domain"
  write_manifest "$repo" "$mode"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$repo/.flywheel/scripts/status-doctor.sh"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$repo/.flywheel/scripts/sub-bar-doctor.sh"
  printf '# Flywheel README\n' >"$repo/.flywheel/README.md"
  printf 'domain = true\n' >"$repo/src/domain/app.py"
  chmod +x "$repo/.flywheel/scripts/status-doctor.sh" "$repo/.flywheel/scripts/sub-bar-doctor.sh"
}

validate_json_schema() {
  python3 -c 'import json, sys; from jsonschema import Draft202012Validator; Draft202012Validator.check_schema(json.load(open(sys.argv[1], encoding="utf-8")))' "$1"
}

validate_payload() {
  python3 -c 'import json, sys; from jsonschema import Draft202012Validator; schema=json.load(open(sys.argv[1], encoding="utf-8")); payload=json.load(open(sys.argv[2], encoding="utf-8")); Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)' "$1" "$2"
}

validate_jsonl() {
  python3 -c 'import json, sys; from jsonschema import Draft202012Validator; schema=json.load(open(sys.argv[1], encoding="utf-8")); validator=Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER); [validator.validate(json.loads(line)) for line in open(sys.argv[2], encoding="utf-8") if line.strip()]' "$1" "$2"
}

run_case shim_syntax bash -n "$SHIM"
run_case python_syntax python3 -m py_compile "$RUNNER"
run_case schema_flag_valid bash -c 'python3 "$0" --schema >"$1" && python3 -c "import json, sys; from jsonschema import Draft202012Validator; Draft202012Validator.check_schema(json.load(open(sys.argv[1], encoding=\"utf-8\")))" "$1"' "$RUNNER" "$TMP/run-result.schema.json"
run_case help_flags bash -c 'python3 "$0" --help | grep -q -- "--mode" && python3 "$0" --help | grep -q -- "--lane" && python3 "$0" --help | grep -q -- "--apply"' "$RUNNER"

repo="$TMP/repo-audit"
make_repo "$repo" audit_only
out="$TMP/audit-run.json"
python3 "$RUNNER" --repo "$repo" --manifest .flywheel/polish-gate/manifest.json --apply --json >"$out"
run_case apply_result_schema validate_payload "$RESULT_SCHEMA" "$out"
run_case writes_receipt_and_latest bash -c 'test -s "$0/.flywheel/polish-gate/grades.jsonl" && test -s "$0/.flywheel/polish-gate/latest.json"' "$repo"
run_case receipt_schema validate_jsonl "$RECEIPT_SCHEMA" "$repo/.flywheel/polish-gate/grades.jsonl"
run_case latest_summary_schema validate_payload "$SUMMARY_SCHEMA" "$repo/.flywheel/polish-gate/latest.json"

sub="$TMP/subbar"
make_repo "$sub" audit_only
audit_out="$TMP/audit-subbar.json"
python3 "$RUNNER" --repo "$sub" --manifest .flywheel/polish-gate/manifest.json --mode audit_only --surface .flywheel/scripts/sub-bar-doctor.sh --apply --json >"$audit_out"
run_case audit_only_records_not_blocks bash -c 'jq -e ".exit_code == 0 and .surfaces_failed == 1" "$0" >/dev/null' "$audit_out"
run_case audit_only_receipt_verdict bash -c 'jq -e "select(.verdict == \"AUDIT_ONLY\")" "$0" >/dev/null' "$sub/.flywheel/polish-gate/grades.jsonl"

blocking="$TMP/blocking"
make_repo "$blocking" blocking
set +e
python3 "$RUNNER" --repo "$blocking" --manifest .flywheel/polish-gate/manifest.json --surface .flywheel/scripts/sub-bar-doctor.sh --apply --json >"$TMP/blocking.json"
blocking_rc=$?
set -e
run_case blocking_enforces_failure bash -c 'test "$0" -eq 1 && jq -e ".exit_code == 1 and .surfaces_failed == 1" "$1" >/dev/null' "$blocking_rc" "$TMP/blocking.json"

bootstrap="$TMP/bootstrap"
make_repo "$bootstrap" bootstrap
set +e
python3 "$RUNNER" --repo "$bootstrap" --manifest .flywheel/polish-gate/manifest.json --surface .flywheel/scripts/sub-bar-doctor.sh --apply --json >"$TMP/bootstrap.json"
bootstrap_rc=$?
set -e
run_case bootstrap_warn_only bash -c 'test "$0" -eq 0 && jq -e ".exit_code == 0 and .surfaces_failed == 1" "$1" >/dev/null' "$bootstrap_rc" "$TMP/bootstrap.json"

lane="$TMP/lane"
make_repo "$lane" audit_only
python3 "$RUNNER" --repo "$lane" --manifest .flywheel/polish-gate/manifest.json --surface .flywheel/scripts/status-doctor.sh --lane ubs --apply --json >"$TMP/lane.json"
run_case lane_filtering bash -c 'jq -e ".evidence_paths == [\"passthrough:ubs:.flywheel/scripts/status-doctor.sh\"]" "$0/.flywheel/polish-gate/grades.jsonl" >/dev/null' "$lane"

single="$TMP/single"
make_repo "$single" audit_only
python3 "$RUNNER" --repo "$single" --manifest .flywheel/polish-gate/manifest.json --surface .flywheel/scripts/status-doctor.sh --json >"$TMP/single.json"
run_case surface_flag_skips_discovery bash -c 'jq -e ".surfaces_graded == 1 and .receipts_written == []" "$0" >/dev/null' "$TMP/single.json"

bad="$TMP/bad"
mkdir -p "$bad/.flywheel/polish-gate"
printf '{"version":"1","scope":"repo_local_flywheel"}\n' >"$bad/.flywheel/polish-gate/manifest.json"
set +e
python3 "$RUNNER" --repo "$bad" --manifest .flywheel/polish-gate/manifest.json --json >"$TMP/bad.json"
bad_rc=$?
set -e
run_case malformed_manifest_exit_3 bash -c 'test "$0" -eq 3 && jq -e ".exit_code == 3" "$1" >/dev/null' "$bad_rc" "$TMP/bad.json"

discover_fail="$TMP/discover-fail"
make_repo "$discover_fail" audit_only
set +e
POLISH_GATE_DISCOVER_SCRIPT="$TMP/missing-discover.py" python3 "$RUNNER" --repo "$discover_fail" --manifest .flywheel/polish-gate/manifest.json --json >"$TMP/discover-fail.json"
discover_rc=$?
set -e
run_case discovery_failure_exit_4 bash -c 'test "$0" -eq 4 && jq -e ".exit_code == 4" "$1" >/dev/null' "$discover_rc" "$TMP/discover-fail.json"

dry="$TMP/dry"
make_repo "$dry" audit_only
python3 "$RUNNER" --repo "$dry" --manifest .flywheel/polish-gate/manifest.json --dry-run --json >"$TMP/dry.json"
run_case dry_run_no_writes bash -c 'jq -e ".receipts_written == []" "$0" >/dev/null && test ! -e "$1/.flywheel/polish-gate/grades.jsonl" && test ! -e "$1/.flywheel/polish-gate/latest.json"' "$TMP/dry.json" "$dry"

run_case checked_in_result_schema validate_json_schema "$RESULT_SCHEMA"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

[[ "$pass_count" -eq 18 ]] || { printf 'FAIL expected 18 assertions, got %d\n' "$pass_count" >&2; exit 1; }
printf 'PASS: polish gate runner cases=13 assertions=%d\n' "$pass_count"
