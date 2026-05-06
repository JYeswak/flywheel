#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/validate-callback-before-close.sh.tmpl"
RESULT_SCHEMA="$ROOT/polish-gate/v1/close-validation-result.schema.json"
GRADE_SCHEMA="$ROOT/polish-gate/v1/grade-receipt.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-close-validator.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

case_count=0

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

pass_case() {
  printf 'PASS %s\n' "$1"
  case_count=$((case_count + 1))
}

write_manifest() {
  local repo="$1" mode="$2"
  mkdir -p "$repo/.flywheel/polish-gate/v1"
  cp "$GRADE_SCHEMA" "$repo/.flywheel/polish-gate/v1/grade-receipt.schema.json"
  jq -n --arg mode "$mode" '{
    version:"1",
    mode:$mode,
    scope:"repo_local_flywheel",
    legacy_bootstrap_policy:"warn_until_touched",
    blocking_when:["new_surface","touched_required_surface","malformed_gate","expired_waiver"],
    grade_storage:".flywheel/polish-gate/grades.jsonl",
    latest_summary:".flywheel/polish-gate/latest.json"
  }' >"$repo/.flywheel/polish-gate/manifest.json"
}

make_repo() {
  local repo="$1" mode="$2" touched="$3"
  mkdir -p "$repo/.flywheel"
  git -C "$repo" init -q
  git -C "$repo" config user.email "fixture@example.test"
  git -C "$repo" config user.name "Fixture"
  (cd "$repo" && br init --prefix test >/dev/null)
  write_manifest "$repo" "$mode"
  printf '# Goal\n' >"$repo/.flywheel/GOAL.md"
  git -C "$repo" add .flywheel/GOAL.md .flywheel/polish-gate/manifest.json .flywheel/polish-gate/v1/grade-receipt.schema.json
  git -C "$repo" commit -q -m baseline
  if [[ "$touched" == "yes" ]]; then
    printf '\nTouched surface\n' >>"$repo/.flywheel/GOAL.md"
  fi
}

make_bead() {
  local repo="$1"
  cd "$repo" && br create "close validator fixture" --priority 1 --type task --description "fixture" --json | jq -r '.id'
}

write_good_evidence() {
  local path="$1" extra="${2:-}"
  {
    printf '# Evidence\n'
    printf 'did=4/4 didnt=none gaps=none tests=PASS %s\n\n' "$extra"
    printf 'Acceptance gates:\n'
    printf -- '- gate one passed with receipt line 12\n'
    printf -- '- gate two passed with `templates/flywheel-install/validate-callback-before-close.sh.tmpl`\n'
    printf -- '- gate three passed with `templates/flywheel-install/tests/test_polish_gate_close_validator.sh`\n\n'
    printf 'Run:\n'
    printf '```bash\n'
    printf 'bash templates/flywheel-install/tests/test_polish_gate_close_validator.sh\n'
    printf '```\n\n'
    printf 'Contract version: four-lens-close-validator/v1 and polish-gate/close-validation-result/v1.\n'
    printf 'Four-Lens Self-Grade: brand voice pass; Joshua sniff pass; Jeff doctrine pass; public publishability pass for Three Judges.\n'
    printf 'Outcome: shipped validator proof prevents touched surfaces from closing without a polish-gate receipt.\n'
    printf 'Result: close path blocks missing or invalid polish-gate verdicts while preserving bootstrap and audit-only modes.\n'
    printf 'Operator note: the fixture keeps the evidence above the public readability floor.\n'
    printf 'Receipt note: the test validates both JSON output and process exit code.\n'
    printf 'Mode note: blocking, audit_only, and bootstrap each get one fixture.\n'
    printf 'Lens note: the four original lenses remain present in the JSON payload.\n'
  } >"$path"
}

write_bad_evidence() {
  local path="$1"
  {
    printf 'did=1/4 didnt=3 gaps=none tests=PASS\n'
    printf 'status: robust solution\n'
  } >"$path"
}

write_waiver() {
  local repo="$1" path="$2"
  mkdir -p "$(dirname "$path")"
  jq -n '{
    schema_version:"polish-gate/grade-receipt/v1",
    ts:"2026-05-05T00:00:00Z",
    surface_path:".flywheel/GOAL.md",
    surface_name:"GOAL.md",
    mode:"blocking",
    skills:{"ubs":8.0,"simplify":8.0,"extreme-opt":8.0,"readme":8.0,"canonical-cli":8.0},
    composite:8.0,
    verdict:"WAIVED",
    evidence_paths:[".flywheel/polish-gate/waivers/goal-waiver.json"],
    grader:"fixture",
    waiver:{reason:"fixture waiver",expires_at:"2026-12-31T00:00:00Z",approver:"fixture-owner"},
    mission_anchor_hash:"sha256:fixture"
  }' >"$path"
}

validator="$TMP/validate-callback-before-close.sh"
cp "$TEMPLATE" "$validator"
chmod +x "$validator"

bash -n "$validator" || fail "template syntax"
python3 -c 'import json, sys; from jsonschema import Draft202012Validator; Draft202012Validator.check_schema(json.load(open(sys.argv[1], encoding="utf-8")))' "$RESULT_SCHEMA" || fail "result schema invalid"

run_validator() {
  local name="$1" repo="$2" bead="$3" evidence="$4"
  set +e
  "$validator" --repo "$repo" --bead "$bead" --evidence "$evidence" --json >"$TMP/$name.json"
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$TMP/$name.rc"
}

schema_validate_result() {
  python3 -c 'import json, sys; from jsonschema import Draft202012Validator; schema=json.load(open(sys.argv[1], encoding="utf-8")); payload=json.load(open(sys.argv[2], encoding="utf-8")); Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)' "$RESULT_SCHEMA" "$1"
}

repo="$TMP/untouched"
make_repo "$repo" blocking no
bead="$(make_bead "$repo")"
evidence="$TMP/untouched.md"
write_good_evidence "$evidence"
run_validator untouched "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/untouched.rc")" -eq 0 ]] || fail "untouched should pass"
jq -e '.touched_surfaces == [] and .polish_gate_lens_passed == true' "$TMP/untouched.json" >/dev/null || fail "untouched JSON wrong"
schema_validate_result "$TMP/untouched.json"
pass_case untouched_clean_callback_allowed

repo="$TMP/missing"
make_repo "$repo" blocking yes
bead="$(make_bead "$repo")"
evidence="$TMP/missing.md"
write_good_evidence "$evidence"
run_validator missing "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/missing.rc")" -eq 2 ]] || fail "missing verdict should exit 2"
jq -e '.exit_code == 2 and .polish_gate_lens_passed == false' "$TMP/missing.json" >/dev/null || fail "missing verdict JSON wrong"
schema_validate_result "$TMP/missing.json"
pass_case blocking_missing_verdict_refused

repo="$TMP/pass"
make_repo "$repo" blocking yes
bead="$(make_bead "$repo")"
evidence="$TMP/pass.md"
write_good_evidence "$evidence" "polish_gate_verdict=PASS"
run_validator pass "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/pass.rc")" -eq 0 ]] || fail "PASS verdict should pass"
jq -e '.polish_gate_verdict == "PASS" and .composite_verdict == "PASS"' "$TMP/pass.json" >/dev/null || fail "PASS JSON wrong"
pass_case blocking_pass_verdict_allowed

repo="$TMP/audit-block"
make_repo "$repo" blocking yes
bead="$(make_bead "$repo")"
evidence="$TMP/audit-block.md"
write_good_evidence "$evidence" "polish_gate_verdict=AUDIT_ONLY"
run_validator audit_block "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/audit_block.rc")" -eq 1 ]] || fail "AUDIT_ONLY should fail in blocking mode"
jq -e '.exit_code == 1 and any(.failures[]; contains("polish_gate_audit_only_blocks_close"))' "$TMP/audit_block.json" >/dev/null || fail "AUDIT_ONLY blocking JSON wrong"
pass_case blocking_audit_only_refused

repo="$TMP/audit-mode"
make_repo "$repo" audit_only yes
bead="$(make_bead "$repo")"
evidence="$TMP/audit-mode.md"
write_good_evidence "$evidence" "polish_gate_verdict=AUDIT_ONLY"
run_validator audit_mode "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/audit_mode.rc")" -eq 0 ]] || fail "AUDIT_ONLY should pass in audit_only mode"
jq -e '.mode == "audit_only" and .polish_gate_verdict == "AUDIT_ONLY"' "$TMP/audit_mode.json" >/dev/null || fail "audit_only JSON wrong"
pass_case audit_only_audit_verdict_allowed

repo="$TMP/waived"
make_repo "$repo" blocking yes
bead="$(make_bead "$repo")"
waiver="$repo/.flywheel/polish-gate/waivers/goal-waiver.json"
write_waiver "$repo" "$waiver"
evidence="$TMP/waived.md"
write_good_evidence "$evidence" "polish_gate_verdict=WAIVED polish_gate_waiver_receipt=.flywheel/polish-gate/waivers/goal-waiver.json"
run_validator waived "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/waived.rc")" -eq 0 ]] || fail "WAIVED valid receipt should pass"
jq -e '.polish_gate_verdict == "WAIVED" and .composite_verdict == "WAIVED"' "$TMP/waived.json" >/dev/null || fail "WAIVED JSON wrong"
pass_case waived_valid_receipt_allowed

repo="$TMP/waived-bad"
make_repo "$repo" blocking yes
bead="$(make_bead "$repo")"
evidence="$TMP/waived-bad.md"
write_good_evidence "$evidence" "polish_gate_verdict=WAIVED polish_gate_waiver_receipt=.flywheel/polish-gate/waivers/missing.json"
run_validator waived_bad "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/waived_bad.rc")" -eq 1 ]] || fail "WAIVED missing receipt should fail"
jq -e '.exit_code == 1 and any(.failures[]; contains("polish_gate_waiver_receipt_invalid"))' "$TMP/waived_bad.json" >/dev/null || fail "WAIVED invalid JSON wrong"
pass_case waived_invalid_receipt_refused

repo="$TMP/bootstrap"
make_repo "$repo" bootstrap yes
bead="$(make_bead "$repo")"
evidence="$TMP/bootstrap.md"
write_good_evidence "$evidence"
run_validator bootstrap "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/bootstrap.rc")" -eq 0 ]] || fail "bootstrap missing verdict should warn only"
jq -e '.mode == "bootstrap" and .polish_gate_lens_passed == true and (.warnings[] | contains("polish_gate_missing_verdict_warn_only"))' "$TMP/bootstrap.json" >/dev/null || fail "bootstrap warning JSON wrong"
pass_case bootstrap_missing_verdict_warn_only

repo="$TMP/four-lens"
make_repo "$repo" bootstrap no
bead="$(make_bead "$repo")"
evidence="$TMP/four-lens.md"
write_bad_evidence "$evidence"
run_validator four_lens "$repo" "$bead" "$evidence"
[[ "$(cat "$TMP/four_lens.rc")" -eq 1 ]] || fail "four-lens bad evidence should keep legacy exit 1"
jq -e '.exit_code == 3 and .four_lens.public.status == "fail" and .verdict == "BLOCK_CLOSE"' "$TMP/four_lens.json" >/dev/null || fail "four-lens regression JSON wrong"
pass_case four_lens_regression_preserved

[[ "$case_count" -eq 9 ]] || fail "expected 9 cases got $case_count"
printf 'PASS: polish gate close validator cases=9\n'
