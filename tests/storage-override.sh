#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
STORAGE_LIB="${FLYWHEEL_STORAGE_LIB:-$HOME/.claude/skills/.flywheel/lib/storage.sh}"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/storage-override.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/storage-override-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

schema_validate() {
  local receipt="$1" label="$2"
  if python3 - "$SCHEMA" "$receipt" <<'PY'
import json
import sys

from jsonschema import Draft202012Validator, FormatChecker

schema_path, receipt_path = sys.argv[1], sys.argv[2]
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)
with open(receipt_path, encoding="utf-8") as f:
    receipt = json.load(f)

Draft202012Validator.check_schema(schema)
Draft202012Validator(schema, format_checker=FormatChecker()).validate(receipt)
PY
  then
    pass "$label"
  else
    fail "$label"
    jq . "$receipt" || true
  fi
}

schema_reject() {
  local receipt="$1" label="$2"
  if python3 - "$SCHEMA" "$receipt" <<'PY'
import json
import sys

from jsonschema import Draft202012Validator, FormatChecker, ValidationError

schema_path, receipt_path = sys.argv[1], sys.argv[2]
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)
with open(receipt_path, encoding="utf-8") as f:
    receipt = json.load(f)

Draft202012Validator.check_schema(schema)
try:
    Draft202012Validator(schema, format_checker=FormatChecker()).validate(receipt)
except ValidationError:
    sys.exit(0)
sys.exit(1)
PY
  then
    pass "$label"
  else
    fail "$label"
    jq . "$receipt" || true
  fi
}

fixture() {
  local path="$1" pct="$2"
  jq -nc \
    --argjson pct "$pct" \
    '{
      disk_total_gb:926,
      disk_free_gb:(926 * $pct / 100),
      disk_free_pct:$pct,
      developer_dir_gb:328,
      local_state_gb:2.1,
      stale_baks_count:0,
      stale_baks_size_mb:0,
      qdrant_volumes_size_mb:217,
      tmp_dispatch_artifacts_count:0
    }' >"$path"
}

make_repo() {
  local name="$1" repo
  repo="$TMP/$name"
  mkdir -p "$repo/.flywheel/reports" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  jq -nc --arg repo "$repo" '{repo:$repo,active:true}' >"$repo/.flywheel/loop.json"
  printf '# Daily\n' >"$repo/.flywheel/reports/daily-2026-05-04.md"
  printf '%s\n' "$repo"
}

write_receipt() {
  local dir="$1" name="$2" issued="$3" expires="$4" min_free="$5" applies="$6"
  mkdir -p "$dir"
  jq -nc \
    --arg name "$name" \
    --arg issued "$issued" \
    --arg expires "$expires" \
    --arg min_free "$min_free" \
    --argjson applies "$applies" \
    '{
      schema_version:"storage-override/v1",
      issued_at:$issued,
      expires_at:$expires,
      issuer:"{operator}",
      scope:"fleet",
      min_free_gb_override:40,
      min_free_pct_override:($min_free | tonumber),
      applies_to:$applies,
      rotation_reason:"fixture storage headroom override",
      auto_clear_signal:"STORAGE-CLEARED",
      rollback_guard:{
        requires_event:"STORAGE-CLEARED",
        rollback_id:("storage-override-fixture-" + $name),
        before_state:{
          storage_gate:"base",
          min_free_gb:50,
          min_free_pct:10
        },
        after_state:{
          storage_gate:"override",
          min_free_gb:40,
          min_free_pct:($min_free | tonumber)
        },
        idempotency_key:("storage-override-fixture-" + $name),
        timestamp:$issued,
        failure_class:"rollback_failed",
        failure_taxonomy_ref:".flywheel/doctrine/failure-taxonomy.md",
        recovery_hint:"If STORAGE-CLEARED is not recorded before expiry, restore the base storage threshold."
      }
    }' >"$dir/$name.json"
}

run_doctor() {
  local repo="$1" fixture_file="$2" overrides="$3" out="$4" min_gb="${5:-50}" min_pct="${6:-10}"
  FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
    FLYWHEEL_STORAGE_PROBE_FIXTURE="$fixture_file" \
    FLYWHEEL_STORAGE_OVERRIDES_DIR="$overrides" \
    FLYWHEEL_STORAGE_OVERRIDE_EVENTS="$overrides/events.jsonl" \
    FLYWHEEL_STORAGE_OVERRIDE_NOW="2026-05-04T02:20:00Z" \
    FLYWHEEL_TMP_ENTRY_ROOT="$TMP/tmp-root" \
    REPO_ABS="$repo" \
    bash -c '
      set -euo pipefail
      source "$1"
      min_gb="$2"
      min_pct="$3"
      storage_override="$(storage_override_doctor_json "$min_gb" "$min_pct")"
      effective_gb="$(jq -r --arg fallback "$min_gb" ".effective_min_free_gb // \$fallback" <<<"$storage_override")"
      effective_pct="$(jq -r --arg fallback "$min_pct" ".effective_min_free_pct // \$fallback" <<<"$storage_override")"
      storage="$(storage_doctor_json "$effective_gb" "$effective_pct")"
      storage_override_clear_if_recovered "$storage_override" "$storage" "$min_gb" "$min_pct"
      storage_override="$(storage_override_doctor_json "$min_gb" "$min_pct")"
      effective_gb="$(jq -r --arg fallback "$min_gb" ".effective_min_free_gb // \$fallback" <<<"$storage_override")"
      effective_pct="$(jq -r --arg fallback "$min_pct" ".effective_min_free_pct // \$fallback" <<<"$storage_override")"
      storage="$(storage_doctor_json "$effective_gb" "$effective_pct")"
      jq -nc --argjson storage "$storage" --argjson storage_override "$storage_override" \
        "{storage:\$storage, storage_override:\$storage_override, storage_override_active_count:(\$storage_override.storage_override_active_count // 0), storage_override_expiring_in_min:(\$storage_override.storage_override_expiring_in_min // null)}"
    ' _ "$STORAGE_LIB" "$min_gb" "$min_pct" >"$out" 2>"$out.err" || true
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
    [[ -f "$file.err" ]] && cat "$file.err" || true
  fi
}

if bash -n "$BIN"; then
  pass "flywheel_loop_syntax"
else
  fail "flywheel_loop_syntax"
fi
if [[ -r "$STORAGE_LIB" ]]; then
  pass "storage_lib_present"
else
  fail "storage_lib_present"
fi
if jq -e '.["$id"] and .required and (.properties.schema_version.const == "storage-override/v1") and (.properties.rollback_guard.type == "object") and (.properties.rollback_guard.required | index("rollback_id")) and (.properties.rollback_guard.properties.failure_class.enum | index("rollback_failed"))' "$SCHEMA" >/dev/null; then
  pass "schema_declares_storage_override_v1"
else
  fail "schema_declares_storage_override_v1"
fi
schema_validate "$ROOT/tests/fixtures/storage-override/valid-rollback-guard.json" "static_valid_rollback_guard_schema"
schema_reject "$ROOT/tests/fixtures/storage-override/invalid-rollback-guard.json" "static_invalid_rollback_guard_schema"

low="$TMP/low.json"
above="$TMP/above.json"
mkdir -p "$TMP/tmp-root"
fixture "$low" 5.2
fixture "$above" 42

repo="$(make_repo storage-override-repo)"
valid="$TMP/valid-overrides"
write_receipt "$valid" valid "2026-05-04T02:10:00Z" "2026-05-04T03:18:00Z" 8 "[\"$repo\",\"storage-override-repo\"]"
schema_validate "$valid/valid.json" "valid_receipt_schema"
run_doctor "$repo" "$low" "$valid" "$TMP/valid-low.out"
assert_jq "$TMP/valid-low.out" '.storage_override_active_count == 1 and .storage_override.effective_min_free_pct == 8 and .storage.status != "fail" and (.storage.errors | map(.code) | index("storage_low_headroom") | not)' "valid_receipt_lowers_low_storage_gate"
assert_jq "$TMP/valid-low.out" '.storage_override.auto_clear_signal == "STORAGE-CLEARED" and .storage_override.rows[0].auto_clear_signal == "STORAGE-CLEARED"' "doctor_exposes_auto_clear_signal"

expired="$TMP/expired-overrides"
write_receipt "$expired" expired "2026-05-04T01:00:00Z" "2026-05-04T02:00:00Z" 8 "[\"$repo\"]"
schema_validate "$expired/expired.json" "expired_receipt_schema"
run_doctor "$repo" "$low" "$expired" "$TMP/expired-low.out"
assert_jq "$TMP/expired-low.out" '.storage_override_active_count == 0 and .storage.status == "fail" and any(.storage.errors[]?; .code == "storage_low_headroom")' "expired_receipt_fails_closed"

wrong_target="$TMP/wrong-target-overrides"
write_receipt "$wrong_target" wrong "2026-05-04T02:10:00Z" "2026-05-04T03:18:00Z" 8 "[\"other-repo\"]"
schema_validate "$wrong_target/wrong.json" "wrong_target_receipt_schema"
run_doctor "$repo" "$low" "$wrong_target" "$TMP/wrong-target.out"
assert_jq "$TMP/wrong-target.out" '.storage_override_active_count == 0 and .storage.status == "fail" and any(.storage.errors[]?; .code == "storage_low_headroom")' "missing_applies_to_fails_closed"

clear="$TMP/clear-overrides"
write_receipt "$clear" clear "2026-05-04T02:10:00Z" "2026-05-04T03:18:00Z" 8 "[\"*\"]"
schema_validate "$clear/clear.json" "auto_clear_receipt_schema"
run_doctor "$repo" "$above" "$clear" "$TMP/clear.out"
assert_jq "$TMP/clear.out" '.storage_override_active_count == 0 and .storage.status == "ok" and .storage_override.effective_min_free_pct == 10' "receipt_above_threshold_auto_reverts"
if grep -q '"STORAGE-CLEARED"' "$clear/events.jsonl"; then
  pass "storage_cleared_event_written"
else
  fail "storage_cleared_event_written"
fi

cli_overrides="$TMP/no-overrides"
mkdir -p "$cli_overrides"
run_doctor "$repo" "$low" "$cli_overrides" "$TMP/cli.out" 40 8
assert_jq "$TMP/cli.out" '.storage_override_active_count == 0 and .storage_override.effective_min_free_pct == 8 and .storage.status != "fail"' "cli_flag_storage_min_free_pct"

env_overrides="$TMP/env-overrides"
mkdir -p "$env_overrides"
run_doctor "$repo" "$low" "$env_overrides" "$TMP/env.out" 40 8
assert_jq "$TMP/env.out" '.storage_override_active_count == 0 and .storage_override.effective_min_free_pct == 8 and .storage.status != "fail"' "env_var_storage_min_free_pct"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
