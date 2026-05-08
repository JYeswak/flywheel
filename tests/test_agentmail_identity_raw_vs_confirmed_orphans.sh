#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d -t msck5.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

export FLYWHEEL_AGENT_MAIL_STATE_DIR="$TMP/agent-mail"
export FLYWHEEL_SESSION_TOPOLOGY="$TMP/session-topology.jsonl"
export FLYWHEEL_IDENTITY_NTM_HEALTH_FIXTURE_DIR="$TMP/ntm-health"

mkdir -p "$FLYWHEEL_AGENT_MAIL_STATE_DIR/sessions" "$FLYWHEEL_AGENT_MAIL_STATE_DIR/tokens" "$FLYWHEEL_IDENTITY_NTM_HEALTH_FIXTURE_DIR"

write_identity() {
  local session="$1" pane="$2" identity="$3" token
  token="$FLYWHEEL_AGENT_MAIL_STATE_DIR/tokens/$identity.token"
  printf '%s\n' "token-$identity" >"$token"
  chmod 600 "$token"
  jq -nc \
    --arg session "$session" \
    --arg identity "$identity" \
    --arg token_path "$token" \
    --arg project "/tmp/$session" \
    --argjson pane "$pane" \
    '{
      schema_version:"agent-mail-identity-registry/v2",
      session:$session,
      pane:$pane,
      role:"orch",
      identity_name:$identity,
      token_path:$token_path,
      status:"active",
      fleet_mail_project_key:$project,
      identity_resolved:true,
      agent_mail_ready:true
    }' >"$FLYWHEEL_AGENT_MAIL_STATE_DIR/sessions/$session:$pane.json"
}

write_identity fixture 1 FixtureOne
jq -nc '{session:"fixture",orchestrator_pane:1,callback_pane:1,worker_panes:[],repo_path:"/tmp/fixture",effective_at:"2026-05-08T00:00:00Z"}' >"$FLYWHEEL_SESSION_TOPOLOGY"
jq -nc '{session:"fixture",repo_path:"/tmp/fixture",effective_at:"2026-05-08T00:10:00Z",writer:"migrate-topology-add-repo-path"}' >>"$FLYWHEEL_SESSION_TOPOLOGY"
jq -nc '{status:"ok",live_panes:[1]}' >"$FLYWHEEL_IDENTITY_NTM_HEALTH_FIXTURE_DIR/fixture.json"

"$LOOP" identity --doctor --json >"$TMP/sparse-merge.json"
jq -e '
  .status == "pass"
  and .raw_topology_drift_count == 1
  and .topology_sparse_merge_count == 1
  and .topology_drift_unvalidated_count == 0
  and .confirmed_unreachable_session_count == 0
  and .agentmail_orphan_session_rows_count == 0
' "$TMP/sparse-merge.json" >/dev/null

write_identity gone 9 GoneNine
jq -nc '{status:"ok",live_panes:[]}' >"$FLYWHEEL_IDENTITY_NTM_HEALTH_FIXTURE_DIR/gone.json"

"$LOOP" identity --doctor --json >"$TMP/confirmed.json"
jq -e '
  .status == "fail"
  and .confirmed_unreachable_session_count == 1
  and .agentmail_orphan_session_rows_count == 1
  and (.confirmed_unreachable_session_rows[] | select(.session == "gone" and .pane == 9 and .live_validation_decision == "confirmed_unreachable"))
' "$TMP/confirmed.json" >/dev/null

echo "agentmail identity raw topology drift and confirmed unreachable split passes"
