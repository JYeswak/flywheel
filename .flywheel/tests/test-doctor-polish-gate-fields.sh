#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/doctor-polish-gate-fields.schema.json"
TEMPLATE_SCHEMA_DIR="$ROOT/templates/flywheel-install/polish-gate/v1"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-polish-gate-fields.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else jq . "$file" >&2 || true; fail "$label"; fi
}

make_repo() {
  local name="$1" repo
  repo="$TMP/$name"
  mkdir -p "$repo"
  printf '%s\n' "$repo"
}

copy_schemas() {
  local repo="$1"
  mkdir -p "$repo/.flywheel/polish-gate/v1"
  cp "$TEMPLATE_SCHEMA_DIR/manifest.schema.json" "$repo/.flywheel/polish-gate/v1/manifest.schema.json"
  cp "$TEMPLATE_SCHEMA_DIR/grade-receipt.schema.json" "$repo/.flywheel/polish-gate/v1/grade-receipt.schema.json"
  cp "$TEMPLATE_SCHEMA_DIR/latest-summary.schema.json" "$repo/.flywheel/polish-gate/v1/latest-summary.schema.json"
}

write_manifest() {
  local repo="$1" mode="$2"
  mkdir -p "$repo/.flywheel/polish-gate"
  jq -n --arg mode "$mode" '{
    version:"1",
    mode:$mode,
    scope:"repo_local_flywheel",
    legacy_bootstrap_policy:"warn_until_touched",
    blocking_when:["malformed_gate","expired_waiver"],
    grade_storage:".flywheel/polish-gate/grades.jsonl",
    latest_summary:".flywheel/polish-gate/latest.json"
  }' >"$repo/.flywheel/polish-gate/manifest.json"
}

write_receipt() {
  local repo="$1" surface="$2" verdict="$3" composite="$4" mode="${5:-audit_only}"
  mkdir -p "$repo/.flywheel/polish-gate"
  jq -nc --arg surface "$surface" --arg verdict "$verdict" --arg mode "$mode" --argjson composite "$composite" '{
    schema_version:"polish-gate/grade-receipt/v1",
    ts:"2026-05-06T02:00:00Z",
    surface_path:$surface,
    surface_name:($surface | split("/")[-1]),
    mode:$mode,
    skills:{"ubs":$composite,"simplify":$composite,"extreme-opt":$composite,"readme":$composite,"canonical-cli":$composite},
    composite:$composite,
    verdict:$verdict,
    evidence_paths:["fixture"],
    grader:"doctor-polish-gate-fields-test",
    mission_anchor_hash:"sha256:fixture"
  }' >>"$repo/.flywheel/polish-gate/grades.jsonl"
}

write_summary() {
  local repo="$1" mode="$2" graded="$3" passed="$4" failed="$5" waivers="$6"
  mkdir -p "$repo/.flywheel/polish-gate"
  jq -n --arg mode "$mode" --argjson graded "$graded" --argjson passed "$passed" --argjson failed "$failed" --argjson waivers "$waivers" '{
    schema_version:"polish-gate/latest-summary/v1",
    last_run_ts:"2026-05-06T02:00:00Z",
    mode:$mode,
    surfaces_graded:$graded,
    surfaces_passed:$passed,
    surfaces_failed:$failed,
    pending_waivers:$waivers,
    composite_avg:9.4,
    min_composite:9.2,
    min_composite_surface:".flywheel/GOAL.md"
  }' >"$repo/.flywheel/polish-gate/latest.json"
}

run_scope() {
  local label="$1" repo="$2"
  set +e
  FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$BIN" doctor --scope polish-gate --repo "$repo" --json >"$TMP/$label.json" 2>"$TMP/$label.err"
  local rc=$?
  set -e
  jq empty "$TMP/$label.json" >/dev/null || { cat "$TMP/$label.err" >&2; fail "$label json_parse"; }
  printf '%s\n' "$rc" >"$TMP/$label.rc"
}

validate_payload() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(payload)
PY
}

validate_schema_file() {
  python3 - "$SCHEMA" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
Draft202012Validator.check_schema(schema)
PY
}

assert_stable_shape() {
  local file="$1" label="$2"
  assert_jq "$file" '((keys | sort) == ["doctor_scope","failures_count","mode","receipt_count","schema_status","signal","summary_path","waiver_count"])' "$label keys"
  assert_jq "$file" '(.mode|type)=="string" and (.summary_path|type)=="string" and (.receipt_count|type)=="number" and (.failures_count|type)=="number" and (.waiver_count|type)=="number" and (.schema_status|type)=="string" and (.signal|type)=="string"' "$label types"
}

bash -n "$BIN" && pass "flywheel_loop_syntax"
jq empty "$SCHEMA" && pass "schema_json_parses"
validate_schema_file && pass "schema_self_validates"

repo="$(make_repo green)"
copy_schemas "$repo"
write_manifest "$repo" audit_only
write_receipt "$repo" ".flywheel/GOAL.md" PASS 9.4
write_receipt "$repo" ".flywheel/STATE.md" PASS 9.2
write_summary "$repo" audit_only 2 2 0 0
run_scope green "$repo"
assert_jq "$TMP/green.json" '.signal == "GREEN" and .mode == "audit_only" and .schema_status == "valid" and .receipt_count == 2 and .failures_count == 0 and .waiver_count == 0 and (.summary_path | endswith(".flywheel/polish-gate/latest.json"))' "all_artifacts_green"
validate_payload "$TMP/green.json" && pass "green_schema_valid"
assert_stable_shape "$TMP/green.json" "green"

repo="$(make_repo yellow)"
copy_schemas "$repo"
write_manifest "$repo" bootstrap
write_receipt "$repo" ".flywheel/GOAL.md" PASS 9.1 bootstrap
run_scope yellow "$repo"
assert_jq "$TMP/yellow.json" '.signal == "YELLOW" and .mode == "bootstrap" and .schema_status == "valid" and .receipt_count == 1 and (.summary_path | endswith(".flywheel/polish-gate/grades.jsonl"))' "receipts_without_aggregate_yellow"
validate_payload "$TMP/yellow.json" && pass "yellow_schema_valid"
assert_stable_shape "$TMP/yellow.json" "yellow"

repo="$(make_repo missing)"
run_scope missing "$repo"
assert_jq "$TMP/missing.json" '.signal == "RED" and .mode == "bootstrap" and .schema_status == "missing" and .receipt_count == 0 and .failures_count == 0 and .waiver_count == 0' "missing_substrate_red"
validate_payload "$TMP/missing.json" && pass "missing_schema_valid"
assert_stable_shape "$TMP/missing.json" "missing"

repo="$(make_repo invalid)"
copy_schemas "$repo"
write_manifest "$repo" blocking
write_receipt "$repo" ".flywheel/GOAL.md" PASS 9.4 blocking
printf '{"$schema":"https://json-schema.org/draft/2020-12/schema","type":123}\n' >"$repo/.flywheel/polish-gate/v1/grade-receipt.schema.json"
run_scope invalid "$repo"
assert_jq "$TMP/invalid.json" '.signal == "RED" and .schema_status == "invalid" and .receipt_count == 0' "schema_invalid_red"
validate_payload "$TMP/invalid.json" && pass "invalid_schema_valid"
assert_stable_shape "$TMP/invalid.json" "invalid"

printf 'PASS cases=5 assertions=%s failures=0\n' "$pass_count"
