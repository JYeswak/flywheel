#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
PREALLOC="$ROOT/.flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/locked-worker-identities.XXXXXX")"
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
  fi
}

write_topology() {
  local workers="$1"
  : >"$FLYWHEEL_SESSION_TOPOLOGY"
  jq -nc --argjson workers "$workers" '{
    session:"flywheel",
    orchestrator_pane:1,
    callback_pane:1,
    worker_panes:$workers,
    shell_panes:[0],
    human_pane:0,
    effective_at:"2026-05-04T00:00:00Z"
  }' >>"$FLYWHEEL_SESSION_TOPOLOGY"
  jq -nc '{
    session:"skillos",
    orchestrator_pane:1,
    callback_pane:1,
    worker_panes:[2],
    shell_panes:[0],
    human_pane:0,
    effective_at:"2026-05-04T00:00:00Z"
  }' >>"$FLYWHEEL_SESSION_TOPOLOGY"
}

export FLYWHEEL_AGENT_MAIL_STATE_DIR="$TMP/agent-mail"
export FLYWHEEL_SESSION_TOPOLOGY="$TMP/session-topology.jsonl"
mkdir -p "$FLYWHEEL_AGENT_MAIL_STATE_DIR"

zsh -n "$LOOP" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"
bash -n "$PREALLOC" && pass "preallocate_script_syntax" || fail "preallocate_script_syntax"
"$PREALLOC" --help >/dev/null && pass "preallocate_help" || fail "preallocate_help"

write_topology '[2,3,4]'
"$PREALLOC" --apply --session flywheel --json >"$TMP/prealloc.json"
assert_jq "$TMP/prealloc.json" '.created_count == 4 and ([.created[].pane] | sort == [1,2,3,4])' "missing_panes_minted"

jq empty "$TMP/agent-mail/sessions/flywheel:2.json" && pass "worker_row_json_valid" || fail "worker_row_json_valid"
assert_jq "$TMP/agent-mail/sessions/flywheel:2.json" '.schema_version == "agent-mail-identity-registry/v2" and .role == "worker" and .status == "needs_registration" and (.identity_name | type == "string")' "worker_row_v2_role_status"

identity_before="$(jq -r '.identity_name' "$TMP/agent-mail/sessions/flywheel:4.json")"
registered_before="$(jq -r '.registered_ts' "$TMP/agent-mail/sessions/flywheel:4.json")"
"$PREALLOC" --apply --session flywheel --json >"$TMP/prealloc-again.json"
identity_after="$(jq -r '.identity_name' "$TMP/agent-mail/sessions/flywheel:4.json")"
registered_after="$(jq -r '.registered_ts' "$TMP/agent-mail/sessions/flywheel:4.json")"
if [[ "$identity_before" == "$identity_after" && "$registered_before" == "$registered_after" ]]; then
  pass "existing_pane_idempotent"
else
  fail "existing_pane_idempotent"
fi

write_topology '[2]'
"$PREALLOC" --apply --session flywheel --json >"$TMP/prealloc-shrunk.json"
assert_jq "$TMP/prealloc-shrunk.json" '.archived_count == 2 and ([.archived[].pane] | sort == [3,4])' "topology_shrunk_archives_orphans"
assert_jq "$TMP/agent-mail/sessions/flywheel:3.json" '.role == "archived" and .status == "inactive" and .archival_reason == "session_pane_absent_from_latest_topology"' "archived_row_marked"

write_topology '[2,3,4]'
"$PREALLOC" --apply --json >"$TMP/prealloc-cross.json"
skillos_identity_before="$(jq -r '.identity_name' "$TMP/agent-mail/sessions/skillos:2.json")"
"$PREALLOC" --apply --json >"$TMP/prealloc-cross-again.json"
skillos_identity_after="$(jq -r '.identity_name' "$TMP/agent-mail/sessions/skillos:2.json")"
if [[ "$skillos_identity_before" == "$skillos_identity_after" ]]; then
  pass "cross_session_reboot_preserves_identity"
else
  fail "cross_session_reboot_preserves_identity"
fi

"$LOOP" identity --doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.worker_identity_registered_count.flywheel == 3 and .worker_identity_registered_count.skillos == 1 and .agentmail_orphan_session_rows_count == 0 and (.signals[] | select(.name == "worker_identity_registered_count"))' "doctor_worker_counts_and_orphans"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
