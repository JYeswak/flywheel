#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_FLEET_SHUTDOWN_BIN_UNDER_TEST:-$HOME/.local/bin/flywheel-fleet-shutdown}"
SCHEMA="$PWD/.flywheel/scripts/fleet-shutdown-recovery-manifest.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-shutdown-recovery.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

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
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

assert_file() {
  local file="$1" label="$2"
  if [[ -e "$file" ]]; then pass "$label"; else fail "$label"; fi
}

repo="$TMP/repo"
state="$TMP/state"
home="$TMP/home"
loops="$TMP/loops"
topology="$state/session-topology.jsonl"
broadcast="$TMP/broadcast.jsonl"
cycle="2026-05-05T05:55:00Z"
mkdir -p "$repo/.beads" "$state" "$home" "$loops"

cat >"$repo/.beads/issues.jsonl" <<'JSONL'
{"id":"fixture-1","title":"fixture in progress","status":"in_progress"}
JSONL

cat >"$topology" <<'JSONL'
{"session":"repo","orchestrator_pane":1,"orchestrator_kind":"claude","worker_panes":[2,3],"worker_kinds":{"2":"codex","3":"codex"},"shell_panes":[0],"effective_at":"2026-05-05T00:00:00Z"}
JSONL

env_base=(
  "FLYWHEEL_FLEET_SHUTDOWN_HOME=$home"
  "FLYWHEEL_FLEET_SHUTDOWN_STATE_DIR=$state"
  "FLYWHEEL_FLEET_SHUTDOWN_LOOPS_DIR=$loops"
  "FLYWHEEL_FLEET_SHUTDOWN_TOPOLOGY=$topology"
  "FLYWHEEL_FLEET_SHUTDOWN_BROADCAST_LOG=$broadcast"
  "FLYWHEEL_FLEET_SHUTDOWN_NOW=$cycle"
)

bash -n "$BIN"

env "${env_base[@]}" "$BIN" prepare --dry-run --repo "$repo" --cycle-id "$cycle" --json >"$TMP/prepare-dry.json"
jq '.manifests[0]' "$TMP/prepare-dry.json" >"$TMP/dry-manifest.json"
assert_jq "$TMP/dry-manifest.json" '.schema_version == "fleet-shutdown-recovery.v1" and (.sessions | length) >= 1 and .trigger_reason == "planned host reboot"' "prepare_dry_run_manifest_valid"
if [[ ! -e "$repo/.flywheel/reboot-recovery" ]]; then pass "prepare_dry_run_no_mutation"; else fail "prepare_dry_run_no_mutation"; fi

env APPROVE=yes "${env_base[@]}" "$BIN" prepare --apply --repo "$repo" --cycle-id "$cycle" --json >"$TMP/prepare-apply.json"
manifest_path="$(jq -r '.manifests[0].recovery_dir + "/manifest.json"' "$TMP/prepare-apply.json")"
recovery_dir="$(dirname "$manifest_path")"
assert_file "$manifest_path" "prepare_apply_writes_manifest"
assert_file "$recovery_dir/README.md" "prepare_apply_writes_readme"
assert_file "$recovery_dir/state-tarball.tar.zst" "prepare_apply_writes_tarball"
assert_file "$recovery_dir/RESUME_PENDING" "prepare_apply_writes_pending_sentinel"
assert_file "$repo/.flywheel/reboot-recovery/LATEST" "prepare_apply_updates_latest"
assert_jq "$broadcast" '.event == "agent_mail_pause_broadcast" and .repo_count == 1' "prepare_apply_broadcasts_pause_mock"

set +e
env "${env_base[@]}" "$BIN" execute --dry-run --repo "$repo" --in-flight-count 1 --json >"$TMP/execute-blocked.json"
blocked_rc=$?
set -e
if [[ "$blocked_rc" -eq 4 ]]; then pass "execute_dry_run_blocks_inflight"; else fail "execute_dry_run_blocks_inflight"; fi
assert_jq "$TMP/execute-blocked.json" '.status == "blocked" and .in_flight_count == 1' "execute_blocked_shape"

env "${env_base[@]}" "$BIN" execute --dry-run --repo "$repo" --in-flight-count 1 --override-inflight APPROVE=yes --json >"$TMP/execute-override-dry.json"
assert_jq "$TMP/execute-override-dry.json" '.status == "planned" and .override == true and .dry_run == true' "execute_override_dry_run_plans_without_mutation"
assert_jq "$manifest_path" '.shutdown_clean == false' "execute_override_dry_run_keeps_manifest_clean_false"

env APPROVE=yes "${env_base[@]}" "$BIN" execute --apply --repo "$repo" --json >"$TMP/execute-apply.json"
assert_jq "$TMP/execute-apply.json" '.status == "pass" and .shutdown_clean == true' "execute_apply_marks_shutdown_clean"
assert_jq "$manifest_path" '.shutdown_clean == true and .shutdown_completed_at != null' "shutdown_clean_sentinel_only_after_terminal_state"

env APPROVE=yes "${env_base[@]}" "$BIN" reboot-prep --apply --repo "$repo" --json >"$TMP/reboot-prep.json"
assert_file "$state/shutdown-recovery/RESUME_PENDING" "reboot_prep_writes_global_resume_sentinel"
env "${env_base[@]}" "$BIN" resume --apply --auto --repo "$repo" --json >"$TMP/resume1.json"
env "${env_base[@]}" "$BIN" resume --apply --auto --repo "$repo" --json >"$TMP/resume2.json"
assert_jq "$TMP/resume1.json" '.status == "resumed"' "resume_first_run_resumes"
assert_jq "$TMP/resume2.json" '.status == "noop"' "resume_second_run_noop"
assert_jq "$manifest_path" '.resume_completed == true and .resume_verification.ntm_activity_verified == true' "resume_simulated_reboot_verifies_activity"

env "${env_base[@]}" "$BIN" doctor --json --repo "$repo" >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '(.ready_to_shutdown | type == "boolean") and (.in_flight_count | type == "number") and (.blockers | type == "array") and .last_shutdown_clean_at != null and .last_resume_completed_at != null' "doctor_json_shape"

env "${env_base[@]}" "$BIN" validate "$manifest_path" --json >"$TMP/validate-manifest.json"
assert_jq "$TMP/validate-manifest.json" '.status == "pass"' "manifest_schema_validates"
env "${env_base[@]}" "$BIN" validate "$SCHEMA" --json >"$TMP/validate-schema.json"
assert_jq "$TMP/validate-schema.json" '.status == "pass" and .schema_document == true' "schema_document_validates"

if find "$recovery_dir" \( -name '.tmp.*' -o -name '*.lock' \) -print -quit | grep -q .; then
  fail "reservation_release_no_tmp_or_lockfiles"
else
  pass "reservation_release_no_tmp_or_lockfiles"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL fleet-shutdown-recovery pass=%d/10 fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK fleet-shutdown-recovery tests_passed=10/10 assertions=%d\n' "$pass_count"
