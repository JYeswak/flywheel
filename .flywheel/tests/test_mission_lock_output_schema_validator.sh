#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/mission-lock-output.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-output-schema-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
HASH_A="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
HASH_B="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

base_payload() {
  jq -nc --arg h "$HASH_A" --arg r "$HASH_B" '{
    schema_version:"mission-lock-output/v1",
    mission_anchor_rev:1,
    lock_hash:$h,
    locked_at:"2026-05-06T16:00:00Z",
    status:"locked",
    mission_anchor_text:"self-sustaining-company-architecture-health",
    mission_license:{
      vendors_approved:["OpenAI"],
      platforms_approved:["macOS"],
      tier_per_vendor:{OpenAI:"team"},
      budget_envelope_usd_monthly:500,
      tos_accepted_at:[{vendor:"OpenAI",ts:"2026-05-06T16:00:00Z"}],
      secrets_provisioned_at_lock_time:["infisical:/openai"],
      auto_rotate_allowed:["OpenAI"],
      secret_vendor_map:{OpenAI:"infisical:/openai"}
    },
    negative_invariants:[{
      id:"SEC-001",
      surface:"dispatch",
      forbidden_action:"secret_values_in_packet",
      enforcement:"fail_close"
    }],
    cross_cutting_concerns_addressed:[{
      concern:"agent-mail",
      status:"addressed",
      evidence:"file reservations required before edits"
    }],
    surface_principal_metadata:[{
      surface:"dispatch",
      secret_source_of_truth:"infisical",
      principal_type:"worker",
      allowed_operations:["read_path_names"],
      forbidden_principals:["anonymous"],
      service_role_policy:"no service-role mutation from pane text"
    }],
    skill_surface_map:[{
      surface:"validator",
      skill:"testing-golden-artifacts",
      decision:"ADOPT",
      source:"dispatch packet"
    }],
    failure_mode_matrix:[{
      failure_mode:"false readiness",
      risk:"mission lock output omits gating evidence",
      guard:"schema-required fields",
      evidence:"golden negative fixture"
    }],
    receipt_identity_envelope:{
      idempotency_key:$h,
      replay_detection_hash:$r,
      transaction_boundary:{begin:true,commit:true,abort:false},
      receipt_completeness:{SEC:true,IDEM:true,CSR:true}
    },
    provenance:{created_by:"test",last_modified_by:"test",source:"golden fixture"}
  }'
}

payload_for() {
  local mutation="$1" payload
  payload="$(base_payload)"
  case "$mutation" in
    valid) printf '%s\n' "$payload" ;;
    missing_anchor) jq -c 'del(.mission_anchor_rev)' <<<"$payload" ;;
    missing_lock_hash) jq -c 'del(.lock_hash)' <<<"$payload" ;;
    bad_status) jq -c '.status="open"' <<<"$payload" ;;
    missing_negative_invariants) jq -c 'del(.negative_invariants)' <<<"$payload" ;;
    missing_cross_cutting) jq -c 'del(.cross_cutting_concerns_addressed)' <<<"$payload" ;;
    *) printf 'unknown mutation %s\n' "$mutation" >&2; return 2 ;;
  esac
}

write_mission() {
  local path="$1" mutation="$2" payload
  payload="$(payload_for "$mutation")"
  {
    printf '%s\n' '---'
    jq -r 'to_entries[] | "\(.key): \(.value|tojson)"' <<<"$payload"
    printf '%s\n' '---' '# Fixture Mission'
  } >"$path"
}

normalize() {
  jq -c '{status,valid,error_codes:(.errors | map(.code) | sort)}' "$1"
}

run_case() {
  local name="$1" mutation="$2" expect_status="$3" expect_valid="$4" expect_codes="$5"
  local fixture="$TMP/$name.md" out="$TMP/$name.out.json" golden="$TMP/$name.golden.json" rc=0 actual
  write_mission "$fixture" "$mutation"
  set +e
  "$SCRIPT" --mission "$fixture" --json >"$out"
  rc=$?
  set -e
  jq -nc --arg status "$expect_status" --argjson valid "$expect_valid" --argjson codes "$expect_codes" \
    '{status:$status,valid:$valid,error_codes:($codes | sort)}' >"$golden"
  actual="$(normalize "$out")"
  if [[ "$actual" == "$(cat "$golden")" ]] && { [[ "$expect_valid" == "true" && "$rc" -eq 0 ]] || [[ "$expect_valid" == "false" && "$rc" -eq 1 ]]; }; then
    pass "$name golden"
  else
    fail "$name golden"
    printf 'rc=%s actual=%s expected=%s\n' "$rc" "$actual" "$(cat "$golden")" >&2
    cat "$out" >&2 || true
  fi
}

schema_self_check() {
  python3 - "$SCHEMA" <<'PY'
import json, sys
try:
    from jsonschema import Draft7Validator
except ModuleNotFoundError:
    sys.exit(0)
with open(sys.argv[1], encoding="utf-8") as handle:
    Draft7Validator.check_schema(json.load(handle))
PY
}

if bash -n "$SCRIPT" && jq empty "$SCHEMA" >/dev/null && schema_self_check; then
  pass "script and schema parse"
else
  fail "script and schema parse"
fi

"$SCRIPT" --help | rg -q '^usage:' && pass "help flag"
"$SCRIPT" --info --json | jq -e '.name == "mission-lock-output-schema-validator.sh" and .mutates == false' >/dev/null && pass "info flag"
"$SCRIPT" --examples --json | jq -e '.examples | length == 3' >/dev/null && pass "examples flag"

valid_mission="$TMP/quiet-valid.md"
write_mission "$valid_mission" valid
[[ -z "$("$SCRIPT" --mission "$valid_mission" --quiet)" ]] && pass "quiet pass emits no output"

run_case "valid_mission_all_required_fields_pass" valid pass true '[]'
run_case "missing_mission_anchor_rev_fails" missing_anchor fail false '["missing_mission_anchor_rev"]'
run_case "missing_lock_hash_fails" missing_lock_hash fail false '["missing_lock_hash"]'
run_case "bad_status_enum_fails" bad_status fail false '["invalid_status"]'
run_case "missing_negative_invariants_fails" missing_negative_invariants fail false '["missing_negative_invariants"]'
run_case "missing_cross_cutting_concerns_fails" missing_cross_cutting fail false '["missing_cross_cutting_concerns_addressed"]'

sidecar_md="$TMP/sidecar.md"
sidecar_json="$TMP/sidecar.md.json"
printf '# sidecar fixture\n' >"$sidecar_md"
base_payload >"$sidecar_json"
"$SCRIPT" --mission "$sidecar_md" --json | jq -e '.status == "pass" and (.extract_source | startswith("sidecar_json:"))' >/dev/null
pass "sidecar json source passes"

printf 'RESULT pass=%s fail=%s golden_cases=6\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 11 && "$fail_count" == "0" ]]
