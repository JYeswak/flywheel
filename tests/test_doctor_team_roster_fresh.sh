#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-roster.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  --robot-activity=alpha)
    jq -nc '{agents:[{pane:1,agent_type:"codex",state:"THINKING"},{pane:2,agent_type:"codex",state:"WAITING"}]}'
    ;;
  *)
    jq -nc '{agents:[]}'
    ;;
esac
SH
chmod +x "$TMP/ntm"

jq -nc '{ts:"2026-05-07T00:00:00Z",event:"session_active",session:"alpha",orchestrator:{pane:1,kind:"codex"},workers:[{pane:2,kind:"codex"}],available_for_borrow:true}' >"$TMP/roster.jsonl"
jq -nc '{session:"alpha",effective_at:"2026-05-07T00:00:00Z",orchestrator_pane:1,worker_panes:[2],worker_kinds:{"2":"codex"}}' >"$TMP/topology.jsonl"
jq -nc '{ts:"2026-05-07T00:05:00Z",session:"alpha"}' >"$TMP/pulse.jsonl"

TEAM_ROSTER="$TMP/roster.jsonl" \
SESSION_TOPOLOGY="$TMP/topology.jsonl" \
FLYWHEEL_TEAM_PULSE="$TMP/pulse.jsonl" \
FLYWHEEL_TEAM_ROSTER_NTM_BIN="$TMP/ntm" \
FLYWHEEL_TEAM_ROSTER_NTM_TIMEOUT_SECONDS=2 \
FLYWHEEL_TEAM_ROSTER_NOW="2026-05-07T00:10:00Z" \
  bash -lc 'source "$HOME/.claude/skills/.flywheel/lib/session.sh"; doctor_check_team_roster_freshness' >"$TMP/out.json"

assert_jq "$TMP/out.json" '.schema_version == "team-roster-freshness-doctor/v1"' "schema"
assert_jq "$TMP/out.json" '.status == "pass" and .status_per_session.alpha == "FRESH"' "fresh_status"
assert_jq "$TMP/out.json" '.counts_per_status.FRESH == 1 and .team_roster_dead_count == 0' "fresh_counts"
assert_jq "$TMP/out.json" '.fleet_capacity.total_workers == 1 and .fleet_capacity.alive_workers == 1 and .fleet_capacity.borrowable_workers == 1' "capacity_counts"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
