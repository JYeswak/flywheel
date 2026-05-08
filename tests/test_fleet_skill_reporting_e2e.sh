#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
COORDINATOR="$ROOT/.flywheel/scripts/skillos-discovery-coordinator.py"
NOTIFY="$ROOT/.flywheel/scripts/skillos-notify.py"
CALLBACK_VALIDATOR="$ROOT/.flywheel/scripts/validate-skill-discovery-callback.sh"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
TMP="$(mktemp -d -t 5hnh.XXXXXX)"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q
(cd "$repo" && "$BR_BIN" init --prefix fx >/dev/null)

ledger="$TMP/state/skill-discoveries.jsonl"
pulse="$TMP/state/team-pulse.jsonl"
dispatch_log="$TMP/state/dispatch-log.jsonl"
topology="$TMP/state/session-topology.jsonl"
threads="$TMP/state/skill-discovery-threads.jsonl"
mkdir -p "$TMP/state"

export FLYWHEEL_SKILL_DISCOVERY_PATH="$ledger"
export APPEND_SAFE_WRITE="$ROOT/.flywheel/scripts/append-safe-write.sh"

"$LOOP" skill-discovery init --json >"$TMP/init.json"
assert_jq "$TMP/init.json" '.schema_version == "skill-discovery/v1" and .status == "ok"' "init_creates_skill_discovery_ledger"

"$LOOP" skill-discovery append \
  --candidate-skill-name reusable-fixture-skill \
  --discovery-kind pattern-emerged \
  --session flywheel \
  --worker-pane 4 \
  --worker-kind codex \
  --task-context "5hnh e2e fixture" \
  --evidence-json '{"source":"fixture","snippet":"reusable coordinator chain"}' \
  --promotion-signal first_sighting \
  --should-become skill-candidate \
  --json >"$TMP/append.json"
assert_jq "$TMP/append.json" '.dry_run == false and (.row.discovery_id | startswith("sd-")) and .row.candidate_skill_name == "reusable-fixture-skill"' "append_writes_one_discovery"
sd_id="$(jq -r '.row.discovery_id' "$TMP/append.json")"
[[ "$(wc -l <"$ledger" | tr -d ' ')" == "1" ]] && pass "ledger_has_one_row" || fail "ledger_has_one_row"

callback="DONE flywheel-5hnh-fixture task_id=fixture did=1/1 evidence=$TMP/append.json tests=PASS skill_discoveries=1 sd_ids=$sd_id"
"$CALLBACK_VALIDATOR" --callback "$callback" --json >"$TMP/callback.json"
assert_jq "$TMP/callback.json" '.status == "pass" and .skill_discoveries == 1 and (.sd_ids | startswith("sd-"))' "callback_skill_discovery_fields_validate"

"$COORDINATOR" \
  --discoveries "$ledger" \
  --pulse "$pulse" \
  --repo "$repo" \
  --br-bin "$BR_BIN" \
  --dry-run \
  --json >"$TMP/coordinator.json"
assert_jq "$TMP/coordinator.json" '.dry_run == true and .candidate_count == 1 and .candidates[0].action == "log_only" and .pulse_row.schema_version == "fleet-skill-pulse/v1"' "coordinator_dry_run_groups_candidate"
assert_jq "$pulse" '.schema_version == "fleet-skill-pulse/v1" and .candidate_count == 1 and .discovery_count == 1' "coordinator_writes_pulse_row"

jq -nc '{schema_version:2,event:"dispatch_sent",task_id:"fixture",ts:"2026-05-08T00:00:00Z"}' >"$dispatch_log"
jq -nc --arg sd "$sd_id" '{schema_version:2,event:"worker_callback",task_id:"fixture",callback_status:"DONE",ts:"2026-05-08T00:30:00Z",skill_discoveries:1,sd_ids:$sd,task_duration_seconds:1800}' >>"$dispatch_log"
FLYWHEEL_SKILL_DISCOVERY_PATH="$ledger" \
FLYWHEEL_SKILL_DISCOVERY_DISPATCH_LOG="$dispatch_log" \
  "$LOOP" doctor --repo "$repo" --json >"$TMP/doctor.json" 2>/dev/null || true
assert_jq "$TMP/doctor.json" '.fleet_skill_discovery.schema_version == "fleet-skill-discovery-doctor/v1" and .fleet_skill_discovery.last_24h_discoveries >= 1 and .fleet_skill_discovery.total_discoveries == 1' "doctor_exposes_fleet_skill_discovery_json"

jq -nc '{session:"skillos",effective_at:"2026-05-08T00:00:00Z",orchestrator_pane:4,repo_path:"/Users/josh/Developer/skillos"}' >"$topology"
tail -n 1 "$ledger" >"$TMP/discovery.json"
"$NOTIFY" \
  --discovery-json "$TMP/discovery.json" \
  --topology "$topology" \
  --thread-state "$threads" \
  --dry-run \
  --json >"$TMP/notify.json"
assert_jq "$TMP/notify.json" '.status == "dry_run" and .target.session == "skillos" and .target.pane == 4 and .agent_mail_thread.thread_key == "[skill-discovery] reusable-fixture-skill" and .mutations.ntm_sent == false' "skillos_notify_dry_run_targets_skillos"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
