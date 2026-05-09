#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-security-posture.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

write_storage_fixture() {
  jq -nc '{
    disk_total_gb:926,
    disk_free_gb:400,
    disk_free_pct:43,
    developer_dir_gb:328,
    local_state_gb:2.1,
    stale_baks_count:0,
    stale_baks_size_mb:0,
    qdrant_volumes_size_mb:217,
    tmp_dispatch_artifacts_count:0
  }' >"$TMP/storage-healthy.json"
}

make_repo() {
  local name="$1" mode="$2" repo
  repo="$TMP/$name"
  rm -rf "$repo"
  mkdir -p "$repo/.flywheel/security/v1" "$repo/.flywheel/receipts/flywheel-vl9of" \
    "$repo/.flywheel/runtime/flywheel-loop" "$repo/.flywheel/validation-schema/v1" \
    "$repo/.flywheel/scripts" "$repo/.claude" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  cp "$ROOT/.flywheel/security/v1/claude-settings-deny.json" "$repo/.flywheel/security/v1/claude-settings-deny.json"
  jq -nc '{
    synthetic_only:true,
    patterns:[{
      id:"openai_api_key_canary",
      class:"openai_api_key",
      severity:"critical",
      regex:"CANARY_TEST_OPENAI_SK_[A-Za-z0-9]{24,}"
    }]
  }' >"$repo/.flywheel/security/v1/secret-patterns.json"
  cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$repo/.flywheel/validation-schema/v1/schema.json"
  cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  chmod +x "$repo/.flywheel/validation-schema/v1/parse.sh"

  case "$mode" in
    pass|fail)
      jq '{permissions:{deny:.permissions.deny}}' "$repo/.flywheel/security/v1/claude-settings-deny.json" >"$repo/.claude/settings.json"
      ;;
    warn)
      jq -nc '{permissions:{deny:[]}}' >"$repo/.claude/settings.json"
      ;;
  esac

  python3 - "$repo" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

repo = Path(sys.argv[1])
(repo / ".flywheel/receipts/flywheel-vl9of/security-settings-rollout-receipt.json").write_text(json.dumps({
    "schema_version": "security-settings-rollout/v1",
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "token_shaped_values": False,
}))
PY

  if [[ "$mode" == "fail" ]]; then
    printf 'synthetic fixture CANARY_TEST_OPENAI_SK_ABCDEFGHIJKLMNOPQRSTUVWX\n' >"$repo/leaky.txt"
  fi
  printf '%s\n' "$repo"
}

run_doctor() {
  local repo="$1" out="$2" strict="${3:-0}"
  local strict_arg=()
  [[ "$strict" == "1" ]] && strict_arg=(--strict)
  FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
    FLYWHEEL_DOCTOR_CACHE_DISABLE=1 \
    FLYWHEEL_STORAGE_PROBE_FIXTURE="$TMP/storage-healthy.json" \
    FLYWHEEL_SECURITY_PATTERN_CORPUS="$repo/.flywheel/security/v1/secret-patterns.json" \
    FLYWHEEL_SECURITY_SCAN_PATHS="${FLYWHEEL_SECURITY_SCAN_PATHS:-}" \
    "$BIN" doctor "${strict_arg[@]}" --repo "$repo" --json >"$out" 2>"$out.err" || true
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

write_storage_fixture

pass_repo="$(make_repo pass pass)"
pass_out="$TMP/pass.json"
run_doctor "$pass_repo" "$pass_out"
assert_jq "$pass_out" '.security.status == "pass" and .security.settings_deny_rules_present == true' "security posture PASS fixture"
assert_jq "$pass_out" 'all(.security.signals[]; has("producer") and has("measurement") and has("consumer") and has("promotion_path"))' "security signal metadata complete"

warn_repo="$(make_repo warn warn)"
warn_out="$TMP/warn.json"
run_doctor "$warn_repo" "$warn_out"
assert_jq "$warn_out" '.security.status == "warn" and .security.settings_deny_rules_present == false and .security.secret_path_deny_missing_count > 0' "security posture WARN fixture"

strict_out="$TMP/strict-warn.json"
run_doctor "$warn_repo" "$strict_out" 1
assert_jq "$strict_out" '.doctor_strict == true and .status == "fail" and .action == "repair_security_posture" and .security.status == "warn"' "security posture strict FAIL fixture"

fail_repo="$(make_repo fail fail)"
fail_out="$TMP/fail.json"
FLYWHEEL_SECURITY_SCAN_PATHS="$fail_repo/leaky.txt" run_doctor "$fail_repo" "$fail_out"
assert_jq "$fail_out" '.security.status == "fail" and .security.leaked_secret_pattern_count == 1 and .security.leaked_secret_pattern_classes == ["openai_api_key"]' "security posture FAIL fixture"
assert_jq "$fail_out" '.security.output_policy.matched_values_emitted == false and (.security | tostring | contains("CANARY_TEST_OPENAI_SK_") | not)' "security output omits matched values"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
