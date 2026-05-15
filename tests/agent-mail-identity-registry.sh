#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-identity.XXXXXX")"
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

export FLYWHEEL_AGENT_MAIL_STATE_DIR="$TMP/agent-mail"
export FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR="$TMP/legacy-tokens"
export FLYWHEEL_SESSION_TOPOLOGY="$TMP/session-topology.jsonl"
mkdir -p "$FLYWHEEL_AGENT_MAIL_STATE_DIR" "$FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR"

jq -nc '{agent_name:"RubyCreek",project_key:"<flywheel-repo>",registration_token:"ruby-token"}' >"$FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR/rubycreek.json"
jq -nc '{identity_id:108,name:"FoggyBear",project_key:"$HOME/.local/state/flywheel/fleet-mail-project",token:"foggy-token"}' >"$FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR/foggybear.json"
jq -nc '{agent_name:"LavenderGlen",project_key:"$HOME/.local/state/flywheel/fleet-mail-project",registration_token:"lavender-token"}' >"$FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR/lavenderglen.json"

jq -nc '{session:"flywheel",orchestrator_pane:1,effective_at:"2026-05-04T00:00:00Z"}' >>"$FLYWHEEL_SESSION_TOPOLOGY"
jq -nc '{session:"{proof-product}",orchestrator_pane:1,effective_at:"2026-05-04T00:00:00Z"}' >>"$FLYWHEEL_SESSION_TOPOLOGY"

zsh -n "$LOOP" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"
jq empty "$ROOT/.flywheel/validation-schema/v1/agent-mail-identity-registry.schema.json" && pass "schema_json_valid" || fail "schema_json_valid"

"$LOOP" identity --migrate-existing --json >"$TMP/migrate.json"
assert_jq "$TMP/migrate.json" '.tokens_migrated >= 3 and .sessions_registered >= 1' "migrate_existing_tokens_and_known_sessions"

"$LOOP" identity --session flywheel --pane 1 --json >"$TMP/resolve.json"
assert_jq "$TMP/resolve.json" '.status == "active" and .identity_name == "RubyCreek" and .identity_resolved == true and (.token_path | test("RubyCreek.token$"))' "resolve_existing_identity"

token="$TMP/new.token"
printf '%s\n' 'new-token' >"$token"
chmod 600 "$token"
"$LOOP" identity --session flywheel --pane 3 --register --identity CyanBadger --token-path "$token" --project-key "<flywheel-repo>" --json >"$TMP/register.json"
assert_jq "$TMP/register.json" '.status == "active" and .identity_name == "CyanBadger"' "register_identity"

legacy_tokens="$TMP/legacy-stub.identity-tokens.jsonl"
jq -nc '{ts:"2026-05-01T14:16:39Z",session:"flywheel",pane:3,identity:"StaleLocalStub",project:"<flywheel-repo>",registered_via:"local-stub"}' >"$legacy_tokens"
lookup_identity="$(
  FLYWHEEL_AGENT_MAIL_STATE_DIR="$FLYWHEEL_AGENT_MAIL_STATE_DIR" \
  FLYWHEEL_IDENTITY_TOKENS="$legacy_tokens" \
  "$ROOT/.flywheel/scripts/lookup-pane-identity.sh" flywheel 3
)"
if [[ "$lookup_identity" == "CyanBadger" ]]; then
  pass "lookup_prefers_phase2_registry_over_legacy_stub"
else
  fail "lookup_prefers_phase2_registry_over_legacy_stub got=$lookup_identity"
fi

rotated="$TMP/rotated.token"
printf '%s\n' 'rotated-token' >"$rotated"
chmod 600 "$rotated"
"$LOOP" identity --session {capability-control-plane} --pane 1 --register --identity BrightLake --token-path "$rotated" --project-key $HOME/Developer/{capability-control-plane} --predecessor-identity FoggyBear --rotation-reason compaction --json >"$TMP/rotate.json"
assert_jq "$TMP/rotate.json" '.predecessor_identity == "FoggyBear" and .rotation_reason == "compaction-continuity" and (.predecessor_identity_chain | index("FoggyBear")) and .identity_primary_key.session == "{capability-control-plane}" and .identity_primary_key.pane == 1 and .identity_primary_key.fleet_mail_project_key == (env.HOME + "/Developer/{capability-control-plane}") and .status == "active"' "rotation_records_tuple_predecessor_chain"

trigger_index=0
for trigger in agent-mail-name-policy resolver-mcp-generated-identity compaction-continuity missing-token-recovery path-canonicalization strict-mode-preallocation; do
  trigger_index=$((trigger_index + 1))
  trigger_token="$TMP/trigger-$trigger.token"
  printf '%s\n' "trigger-token-$trigger" >"$trigger_token"
  chmod 600 "$trigger_token"
  "$LOOP" identity \
    --session trigger-suite \
    --pane "$trigger_index" \
    --register \
    --identity "Trigger$trigger_index" \
    --token-path "$trigger_token" \
    --project-key /tmp/trigger-project \
    --predecessor-identity "Prior$trigger_index" \
    --rotation-reason "$trigger" \
    --role worker \
    --json >"$TMP/trigger-$trigger.json"
  assert_jq "$TMP/trigger-$trigger.json" ".rotation_reason == \"$trigger\" and .identity_primary_key_text == (\"trigger-suite:\" + (.pane | tostring) + \":/tmp/trigger-project\")" "rotation_trigger_$trigger"
done

"$LOOP" identity --sweep-orphan-tokens --dry-run --json >"$TMP/sweep.json"
assert_jq "$TMP/sweep.json" '.schema_version == "agent-mail-orphan-token-sweep/v1" and .dry_run == true and .orphan_tokens_seen_count >= 0' "orphan_sweep_dry_run_reports"

"$LOOP" identity --doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.schema_version == "agent-mail-identity-registry-doctor/v1" and .total_registered >= 3 and .raw_topology_drift_count >= 1 and .topology_drift_unvalidated_count >= 1 and .confirmed_unreachable_session_count >= 0 and .orphan_token_count >= 0 and .orphan_tokens_unswept_count >= 0 and .identity_rotation_count_24h >= 6 and .identity_chain_max_length >= 1 and (.signals[]?.name | select(. == "confirmed_unreachable_session_count"))' "doctor_reports_drift_orphans_and_churn"

fake_br="$TMP/br"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  list) printf "{\"issues\":[]}\\n" ;;' \
  '  show) printf "[]\\n" ;;' \
  '  create) printf "{\"id\":\"flywheel-agentmail-fixture\"}\\n" ;;' \
  '  update) printf "{\"id\":\"updated\"}\\n" ;;' \
  '  *) printf "{}\\n" ;;' \
  'esac' >"$fake_br"
chmod +x "$fake_br"
doctor_json="$(jq -nc --slurpfile identity_registry "$TMP/doctor.json" '{status:"fail",identity_registry:$identity_registry[0]}')"
BR_BIN="$fake_br" DOCTOR_SIGNAL_DOCTOR_JSON="$doctor_json" "$PROMOTE" "$ROOT" >"$TMP/promote.json"
assert_jq "$TMP/promote.json" '.actions[]? | test("agentmail_identity")' "doctor_promotion_agentmail_identity_symptom"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
