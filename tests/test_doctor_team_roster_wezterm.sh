#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-roster-wezterm.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

mkdir -p "$TMP/bin"
cat >"$TMP/bin/wezterm" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "cli" && "${2:-}" == "list" ]]; then
  jq -nc '[
    {pane_id:7,title:"alpha",cwd:"file:///tmp/alpha",foreground_process_name:"codex"},
    {pane_id:8,title:"notes",cwd:"file:///tmp/notes",foreground_process_name:"gemini"}
  ]'
  exit 0
fi
exit 64
SH
chmod +x "$TMP/bin/wezterm"

jq -nc '{ts:"2026-05-07T00:00:00Z",event:"session_active",session:"alpha",orchestrator:{pane:1,kind:"codex"},workers:[{pane:2,kind:"codex"}]}' >"$TMP/roster.jsonl"
jq -nc '{session:"alpha",effective_at:"2026-05-07T00:00:00Z",orchestrator_pane:1,worker_panes:[2]}' >"$TMP/topology.jsonl"
jq -nc '{ts:"2026-05-07T00:05:00Z",session:"alpha"}' >"$TMP/pulse.jsonl"

PATH="$TMP/bin:$PATH" \
TEAM_ROSTER="$TMP/roster.jsonl" \
SESSION_TOPOLOGY="$TMP/topology.jsonl" \
FLYWHEEL_TEAM_PULSE="$TMP/pulse.jsonl" \
FLYWHEEL_TEAM_ROSTER_NTM_BIN="$TMP/missing-ntm" \
FLYWHEEL_TEAM_ROSTER_WEZTERM_BIN="$TMP/bin/wezterm" \
FLYWHEEL_TEAM_ROSTER_NOW="2026-05-07T00:10:00Z" \
  bash -lc 'source "$HOME/.claude/skills/.flywheel/lib/session.sh"; doctor_check_team_roster_freshness' >"$TMP/out.json"

assert_jq "$TMP/out.json" '.status == "pass"' "wezterm_fresh_passes"
assert_jq "$TMP/out.json" '.status_per_session.alpha == "FRESH"' "wezterm_fresh_status"
assert_jq "$TMP/out.json" '.sessions[] | select(.session=="alpha" and .orchestrator.proof_source=="wezterm")' "wezterm_proof_source"
assert_jq "$TMP/out.json" '.team_roster_dead_count == 0 and .team_roster_degraded_count == 0' "wezterm_not_degraded"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
