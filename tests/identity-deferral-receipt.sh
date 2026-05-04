#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/identity-registration-deferral.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/identity-deferral.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

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

write_topology() {
  local path="$1" session="$2" pane="$3"
  jq -nc \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg project "/tmp/$session-project" \
    '{session:$session,orchestrator_pane:$pane,worker_panes:[],project_key:$project,effective_at:"2026-05-04T00:00:00Z"}' \
    >>"$path"
}

write_row() {
  local dir="$1" session="$2" pane="$3" status="$4"
  mkdir -p "$dir/sessions" "$dir/tokens"
  jq -nc \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg status "$status" \
    --arg project "/tmp/$session-project" \
    '{
      schema_version:"agent-mail-identity-registry/v2",
      session:$session,
      pane:$pane,
      role:"orch",
      identity_name:($session + "Identity"),
      token_path:null,
      token_sha256:null,
      registered_ts:"2026-05-04T00:00:00Z",
      last_used_ts:"2026-05-04T00:00:00Z",
      fleet_mail_project_key:$project,
      predecessor_identity:null,
      rotation_reason:null,
      status:$status,
      identity_resolved:true,
      agent_mail_ready:false
    }' >"$dir/sessions/$session:$pane.json"
}

write_receipt() {
  local dir="$1" name="$2" session="$3" pane="$4" issued="$5" expires="$6"
  mkdir -p "$dir"
  jq -nc \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg issued "$issued" \
    --arg expires "$expires" \
    --arg project "/tmp/$session-project" \
    '{
      schema_version:"identity-registration-deferral/v1",
      issued_at:$issued,
      expires_at:$expires,
      issuer:"fixture",
      rotation_reason:"session not live in fixture",
      deferred_rows:[{
        session:$session,
        pane:$pane,
        fleet_mail_project_key:$project,
        live_state:"session_not_running",
        auto_register_when_live:true,
        tracking_bead:"flywheel-2uin"
      }],
      rollback_guard:"expires_at or auto-register-when-live"
    }' >"$dir/$name.json"
}

run_doctor() {
  local state="$1" topology="$2" deferrals="$3" out="$4"
  FLYWHEEL_AGENT_MAIL_STATE_DIR="$state" \
    FLYWHEEL_SESSION_TOPOLOGY="$topology" \
    FLYWHEEL_IDENTITY_DEFERRALS_DIR="$deferrals" \
    FLYWHEEL_IDENTITY_DEFERRAL_NOW="2026-05-04T01:00:00Z" \
    "$LOOP" identity --doctor --json >"$out" 2>"$out.err" || true
}

bash -n "$LOOP" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"
jq -e '.properties.schema_version.const == "identity-registration-deferral/v1" and (.required | index("deferred_rows"))' "$SCHEMA" >/dev/null \
  && pass "schema_declares_identity_deferral_v1" || fail "schema_declares_identity_deferral_v1"

valid_state="$TMP/valid-state"
valid_topology="$TMP/valid-topology.jsonl"
valid_deferrals="$TMP/valid-deferrals"
write_topology "$valid_topology" deferred 1
write_row "$valid_state" deferred 1 needs_registration
write_receipt "$valid_deferrals" valid deferred 1 "2026-05-04T00:00:00Z" "2026-05-05T00:00:00Z"
run_doctor "$valid_state" "$valid_topology" "$valid_deferrals" "$TMP/valid.json"
assert_jq "$TMP/valid.json" '.status == "pass" and .drift_count == 0 and .raw_drift_count == 1 and .deferred_count == 1 and (.deferred_rows == ["deferred:1"]) and .receipt_honored == true' "valid_receipt_covers_all_drift"

expired_state="$TMP/expired-state"
expired_topology="$TMP/expired-topology.jsonl"
expired_deferrals="$TMP/expired-deferrals"
write_topology "$expired_topology" expired 1
write_row "$expired_state" expired 1 needs_registration
write_receipt "$expired_deferrals" expired expired 1 "2026-05-03T00:00:00Z" "2026-05-04T00:30:00Z"
run_doctor "$expired_state" "$expired_topology" "$expired_deferrals" "$TMP/expired.json"
assert_jq "$TMP/expired.json" '.status == "fail" and .drift_count == 1 and .deferred_count == 0 and .receipt_honored == false' "expired_receipt_drift_remains"

partial_state="$TMP/partial-state"
partial_topology="$TMP/partial-topology.jsonl"
partial_deferrals="$TMP/partial-deferrals"
write_topology "$partial_topology" partiala 1
write_topology "$partial_topology" partialb 1
write_row "$partial_state" partiala 1 needs_registration
write_row "$partial_state" partialb 1 needs_registration
write_receipt "$partial_deferrals" partial partiala 1 "2026-05-04T00:00:00Z" "2026-05-05T00:00:00Z"
run_doctor "$partial_state" "$partial_topology" "$partial_deferrals" "$TMP/partial.json"
assert_jq "$TMP/partial.json" '.status == "fail" and .raw_drift_count == 2 and .drift_count == 1 and .deferred_count == 1 and .receipt_honored == false' "partial_cover_drift_remains"

missing_state="$TMP/missing-state"
missing_topology="$TMP/missing-topology.jsonl"
missing_deferrals="$TMP/missing-deferrals"
mkdir -p "$missing_deferrals"
write_topology "$missing_topology" missing 1
write_row "$missing_state" missing 1 needs_registration
run_doctor "$missing_state" "$missing_topology" "$missing_deferrals" "$TMP/missing.json"
assert_jq "$TMP/missing.json" '.status == "fail" and .drift_count == 1 and .deferred_count == 0 and .receipt_honored == false' "missing_receipt_drift_remains"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
