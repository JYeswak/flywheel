#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
TMP="$(mktemp -d -t 5gyv.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q
(cd "$repo" && "$BR_BIN" init --prefix fx >/dev/null)

jq -nc '{
  status:"warn",
  fleet_skill_discovery:{
    status:"warn",
    last_24h_discoveries:7,
    malformed_rows_count:1,
    pending_coordinator_action_count:1,
    suspicious_callback_warning_count:1,
    top_candidates:[
      {candidate_skill_name:"fixture-alpha",sighting_count:3,action:"skill_builder_bead_needed",discovery_ids:["sd-1","sd-2","sd-3"],sessions:["flywheel","{session}","{capability-control-plane}"]}
    ],
    warning_classes:["skill_discovery_coordinator_action_pending","skill_discovery_duty_skipped"]
  },
  beads_db_health:{status:"ok",leakage_count:0,wal_size_mb:0},
  canonical_root_drift:{drift:false,status:"ok"},
  storage:{status:"ok",disk_free_pct:90,stale_baks_count:0},
  agent_browser_leak:{status:"pass",headless_agent_browser_count:0,oldest_age_minutes:0},
  daily_report:{status:"pass",daily_report_age_hours:1},
  wire_or_explain:{status:"pass",unresolved_count:0,overdue_count:0,skill_candidate_backlog_count:0,skill_candidate_relay_failure_count:0},
  pane_work_signal:{status:"ok",errors:[]},
  dispatch_contract:{status:"pass",dispatch_contract_violations:0}
}' >"$TMP/doctor.json"

DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/doctor.json" \
BR_BIN="$BR_BIN" \
  "$SCRIPT" --repo "$repo" >"$TMP/first.json"

jq -e '.action == "promoted" and (.actions[] | test("created:.*:fleet_skill_discovery"))' "$TMP/first.json" >/dev/null || {
  cat "$TMP/first.json" >&2
  fail "expected fleet skill discovery promotion bead creation"
}

created="$(jq -r '.actions[] | select(test("created:.*:fleet_skill_discovery")) | split(":")[1]' "$TMP/first.json")"
[ -n "$created" ] || fail "created bead id missing"
(cd "$repo" && "$BR_BIN" show "$created" --json) | jq -e '
  .[0].title
  | contains("[auto-doctor:fleet_skill_discovery]")
  and contains("top_candidate=fixture-alpha")
' >/dev/null || fail "created bead title lacks candidate evidence"

DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/doctor.json" \
BR_BIN="$BR_BIN" \
  "$SCRIPT" --repo "$repo" >"$TMP/second.json"
jq -e --arg id "$created" '.action == "promoted" and (.actions[] | contains("matched:" + $id + ":fleet_skill_discovery"))' "$TMP/second.json" >/dev/null || {
  cat "$TMP/second.json" >&2
  fail "expected repeated warning to match existing bead"
}

printf 'OK fleet skill discovery doctor promotion\n'
