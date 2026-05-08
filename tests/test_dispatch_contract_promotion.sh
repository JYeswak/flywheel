#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
TMP="$(mktemp -d -t u1x3.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q
(cd "$repo" && br init --prefix fx >/dev/null)

jq -nc '{
  status:"fail",
  dispatch_contract_violations:3,
  dispatch_contract:{status:"fail",dispatch_contract_violations:3},
  beads_db_health:{status:"ok",leakage_count:0,wal_size_mb:0},
  canonical_root_drift:{drift:false,status:"ok"},
  storage:{status:"ok",disk_free_pct:90,stale_baks_count:0},
  agent_browser_leak:{status:"pass",headless_agent_browser_count:0,oldest_age_minutes:0},
  daily_report:{status:"pass",daily_report_age_hours:1},
  wire_or_explain:{status:"pass",unresolved_count:0,overdue_count:0,skill_candidate_backlog_count:0,skill_candidate_relay_failure_count:0},
  pane_work_signal:{status:"ok",errors:[]}
}' >"$TMP/doctor.json"

DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/doctor.json" \
DOCTOR_SIGNAL_DISPATCH_CONTRACT_THRESHOLD=2 \
"$SCRIPT" --repo "$repo" >"$TMP/first.json"

jq -e '.action == "promoted" and (.actions[] | test("created:.*:dispatch_contract"))' "$TMP/first.json" >/dev/null || {
  cat "$TMP/first.json" >&2
  fail "expected dispatch contract promotion bead creation"
}

created="$(jq -r '.actions[] | select(test("created:.*:dispatch_contract")) | split(":")[1]' "$TMP/first.json")"
[ -n "$created" ] || fail "created bead id missing"
(cd "$repo" && br show "$created" --json) | jq -e '.[0].title | contains("[auto-doctor:dispatch_contract]")' >/dev/null || fail "created bead title mismatch"

DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/doctor.json" \
DOCTOR_SIGNAL_DISPATCH_CONTRACT_THRESHOLD=2 \
"$SCRIPT" --repo "$repo" >"$TMP/second.json"
jq -e --arg id "$created" '.action == "promoted" and (.actions[] | contains("matched:" + $id + ":dispatch_contract"))' "$TMP/second.json" >/dev/null || {
  cat "$TMP/second.json" >&2
  fail "expected repeated violation to match existing bead"
}

printf 'OK dispatch contract doctor promotion\n'
