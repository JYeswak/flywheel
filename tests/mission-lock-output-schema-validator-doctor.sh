#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/mission-lock-output.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-output-doctor.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

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
  pass "syntax"
else
  fail "syntax"
fi

"$SCRIPT" --info >"$TMP/info.json"
assert_jq "$TMP/info.json" '(.canonical_cli_flags | index("doctor")) and (.canonical_cli_flags | index("--doctor")) and .doctor_schema == "mission-lock-output-schema-validator.doctor.v1"' "info advertises doctor"

if "$SCRIPT" --help | grep -Fq 'doctor|--doctor'; then
  pass "help advertises doctor"
else
  fail "help advertises doctor"
fi

"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.examples | index("mission-lock-output-schema-validator.sh doctor --json")' "examples include doctor"

"$SCRIPT" --mission "$TMP/missing.md" --schema "$SCHEMA" doctor --json >"$TMP/doctor-warn.json"
assert_jq "$TMP/doctor-warn.json" '.schema_version == "mission-lock-output-schema-validator.doctor.v1" and .command == "doctor" and .status == "warn" and .mode == "read_only" and .mutates == false and ([.checks[] | select(.name == "mission_input_readable").status][0] == "warn")' "doctor read-only warns on missing mission"

"$SCRIPT" --doctor --schema "$SCHEMA" --json >"$TMP/doctor-alias.json"
assert_jq "$TMP/doctor-alias.json" '.command == "doctor" and .mutates == false and (.checks | length == 4)' "--doctor alias"

sha="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
cat >"$TMP/valid.json" <<EOF
{
  "schema_version": "mission-lock-output/v1",
  "mission_anchor_rev": 1,
  "lock_hash": "$sha",
  "locked_at": "2026-05-15T14:10:00Z",
  "status": "locked",
  "mission_anchor_text": "fixture mission",
  "mission_license": {
    "vendors_approved": ["fixture-vendor"],
    "platforms_approved": ["fixture-platform"],
    "tier_per_vendor": {"fixture-vendor": "test"},
    "budget_envelope_usd_monthly": 0,
    "tos_accepted_at": [{"vendor": "fixture-vendor", "ts": "2026-05-15T14:10:00Z"}],
    "secrets_provisioned_at_lock_time": [],
    "auto_rotate_allowed": []
  },
  "negative_invariants": [{"id": "N1", "surface": "fixture", "forbidden_action": "skip receipts", "enforcement": "test"}],
  "cross_cutting_concerns_addressed": [{"concern": "safety", "status": "addressed", "evidence": "fixture"}],
  "surface_principal_metadata": [{"surface": "fixture", "secret_source_of_truth": "none", "principal_type": "none", "allowed_operations": [], "forbidden_principals": [], "service_role_policy": "none"}],
  "skill_surface_map": [{"surface": "fixture", "skill": "mission-lock", "decision": "ADOPT", "source": "fixture"}],
  "failure_mode_matrix": [{"failure_mode": "missing schema", "risk": "bad output", "guard": "validator", "evidence": "fixture"}],
  "receipt_identity_envelope": {
    "idempotency_key": "$sha",
    "replay_detection_hash": "$sha",
    "transaction_boundary": {"begin": true, "commit": true, "abort": false},
    "receipt_completeness": {}
  },
  "provenance": {"created_by": "test", "last_modified_by": "test"}
}
EOF

"$SCRIPT" --mission "$TMP/valid.json" --schema "$SCHEMA" --json >"$TMP/valid.out"
assert_jq "$TMP/valid.out" '.status == "pass" and .valid == true and .error_count == 0 and .extract_source == "json"' "valid fixture passes"

cat >"$TMP/invalid.json" <<'EOF'
{"schema_version":"mission-lock-output/v1"}
EOF
set +e
"$SCRIPT" --mission "$TMP/invalid.json" --schema "$SCHEMA" --json >"$TMP/invalid.out"
rc=$?
set -e
if [[ "$rc" -eq 1 ]]; then
  pass "invalid fixture returns rc 1"
else
  fail "invalid fixture rc=$rc"
fi
assert_jq "$TMP/invalid.out" '.status == "fail" and .valid == false and .error_count > 0 and ([.errors[].code] | index("missing_mission_anchor_rev"))' "invalid fixture reports missing fields"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
