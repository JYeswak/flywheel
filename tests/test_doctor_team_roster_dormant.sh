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
jq -nc '{agents:[]}'
SH
chmod +x "$TMP/ntm"

jq -nc '{ts:"2026-05-07T00:00:00Z",event:"session_dormant",session:"beta",orchestrator:{pane:1,kind:"codex"},workers:[{pane:2,kind:"codex"}]}' >"$TMP/roster.jsonl"
jq -nc '{session:"beta",effective_at:"2026-05-07T00:00:00Z",orchestrator_pane:1,worker_panes:[2]}' >"$TMP/topology.jsonl"
: >"$TMP/pulse.jsonl"

TEAM_ROSTER="$TMP/roster.jsonl" \
SESSION_TOPOLOGY="$TMP/topology.jsonl" \
FLYWHEEL_TEAM_PULSE="$TMP/pulse.jsonl" \
FLYWHEEL_TEAM_ROSTER_NTM_BIN="$TMP/ntm" \
FLYWHEEL_TEAM_ROSTER_NOW="2026-05-07T04:00:00Z" \
  bash -lc 'source "$HOME/.claude/skills/.flywheel/lib/session.sh"; doctor_check_team_roster_freshness' >"$TMP/out.json"

assert_jq "$TMP/out.json" '.status == "pass"' "dormant_passes"
assert_jq "$TMP/out.json" '.status_per_session.beta == "DORMANT"' "dormant_status"
assert_jq "$TMP/out.json" '.team_roster_dead_count == 0 and .team_roster_dormant_count == 1' "dormant_not_dead"
assert_jq "$TMP/out.json" '.sessions[] | select(.session=="beta" and .reason=="session_dormant")' "dormant_reason"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
