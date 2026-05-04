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

jq -nc '{agent_name:"RubyCreek",project_key:"/Users/josh/Developer/flywheel",registration_token:"ruby-token"}' >"$FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR/rubycreek.json"
jq -nc '{identity_id:108,name:"FoggyBear",project_key:"/Users/josh/.local/state/flywheel/fleet-mail-project",token:"foggy-token"}' >"$FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR/foggybear.json"
jq -nc '{agent_name:"LavenderGlen",project_key:"/Users/josh/.local/state/flywheel/fleet-mail-project",registration_token:"lavender-token"}' >"$FLYWHEEL_LEGACY_AGENT_MAIL_TOKEN_DIR/lavenderglen.json"

jq -nc '{session:"flywheel",orchestrator_pane:1,effective_at:"2026-05-04T00:00:00Z"}' >>"$FLYWHEEL_SESSION_TOPOLOGY"
jq -nc '{session:"mobile-eats",orchestrator_pane:1,effective_at:"2026-05-04T00:00:00Z"}' >>"$FLYWHEEL_SESSION_TOPOLOGY"

zsh -n "$LOOP" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"
jq empty "$ROOT/.flywheel/validation-schema/v1/agent-mail-identity-registry.schema.json" && pass "schema_json_valid" || fail "schema_json_valid"

"$LOOP" identity --migrate-existing --json >"$TMP/migrate.json"
assert_jq "$TMP/migrate.json" '.tokens_migrated >= 3 and .sessions_registered >= 1' "migrate_existing_tokens_and_known_sessions"

"$LOOP" identity --session flywheel --pane 1 --json >"$TMP/resolve.json"
assert_jq "$TMP/resolve.json" '.status == "active" and .identity_name == "RubyCreek" and .identity_resolved == true and (.token_path | test("RubyCreek.token$"))' "resolve_existing_identity"

token="$TMP/new.token"
printf '%s\n' 'new-token' >"$token"
chmod 600 "$token"
"$LOOP" identity --session flywheel --pane 3 --register --identity CyanBadger --token-path "$token" --project-key /Users/josh/Developer/flywheel --json >"$TMP/register.json"
assert_jq "$TMP/register.json" '.status == "active" and .identity_name == "CyanBadger"' "register_identity"

rotated="$TMP/rotated.token"
printf '%s\n' 'rotated-token' >"$rotated"
chmod 600 "$rotated"
"$LOOP" identity --session skillos --pane 1 --register --identity BrightLake --token-path "$rotated" --project-key /Users/josh/Developer/skillos --predecessor-identity FoggyBear --rotation-reason compaction --json >"$TMP/rotate.json"
assert_jq "$TMP/rotate.json" '.predecessor_identity == "FoggyBear" and .rotation_reason == "compaction" and .status == "active"' "rotation_records_predecessor"

"$LOOP" identity --doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.schema_version == "agent-mail-identity-registry-doctor/v1" and .total_registered >= 3 and .drift_count >= 1 and .orphan_token_count >= 0 and (.signals[0].name == "agentmail_identity_drift")' "doctor_reports_drift_and_orphans"

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
