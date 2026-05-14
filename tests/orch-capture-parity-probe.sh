#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/orch-capture-parity-probe.py"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-capture-parity.XXXXXX")"
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

write_fixture() {
  local dir="$1"
  mkdir -p "$dir"
  cat >"$dir/topology.jsonl" <<'EOF'
{"session":"flywheel","orchestrator_pane":1,"orchestrator_kind":"claude","effective_at":"2026-05-03T23:00:00Z"}
{"session":"{proof-product}","orchestrator_pane":1,"orchestrator_kind":"codex","effective_at":"2026-05-03T23:00:00Z"}
{"session":"{capability-control-plane}","orchestrator_pane":1,"orchestrator_kind":"codex","capture_path":"agent-mail","capture_evidence_refs":["agent_context_callback:/tmp/{capability-control-plane}-capture.json"],"effective_at":"2026-05-03T23:00:00Z"}
{"session":"legacy-shell","orchestrator_pane":4,"orchestrator_kind":"shell","capture_participation":"non_participating","capture_non_participation_reason":"not an orchestrator owner runtime","effective_at":"2026-05-03T23:00:00Z"}
{"session":"stale-codex","orchestrator_pane":2,"orchestrator_kind":"codex","effective_at":"2026-05-03T23:00:00Z"}
{"session":"scrollback-codex","orchestrator_pane":3,"orchestrator_kind":"codex","capture_path":"pane_scrollback","effective_at":"2026-05-03T23:00:00Z"}
{"session":"dormant-codex","orchestrator_pane":2,"orchestrator_kind":"codex","effective_at":"2026-05-03T23:00:00Z"}
EOF
  cat >"$dir/josh-requests.jsonl" <<'EOF'
{"schema_version":2,"id":"jr-flywheel-001","captured_at":"2026-05-03T23:30:00Z","source_session":"flywheel","source_pane":1,"prompt_hash":"sha256:flywheel-001","source_message_id":"claude-message-1","sanitized_excerpt":"fixture claude request"}
{"schema_version":2,"id":"jr-stale-001","captured_at":"2026-05-01T00:00:00Z","source_session":"stale-codex","source_pane":2,"prompt_hash":"sha256:stale-001","source_message_id":"codex-message-stale","sanitized_excerpt":"fixture stale request"}
EOF
  cat >"$dir/coordination.jsonl" <<'EOF'
{"ts":"2026-05-03T23:45:00Z","event":"mobile_eats_orch_ack","session":"{proof-product}"}
{"ts":"2026-05-03T23:50:00Z","event":"{capability-control-plane}_agent_mail","source_session":"{capability-control-plane}"}
EOF
  cat >"$dir/team-roster.jsonl" <<'EOF'
{"ts":"2026-05-03T23:55:00Z","event":"session_dormant","session":"dormant-codex","orchestrator":{"kind":"codex","pane":2}}
EOF
  cat >"$dir/settings.json" <<'EOF'
{"hooks":{"UserPromptSubmit":[{"matcher":"*","hooks":[{"type":"command","command":"$HOME/.claude/hooks/josh-request-capture.sh"}]}]}}
EOF
  cat >"$dir/wezterm.json" <<'EOF'
[
  {"window_id":1,"tab_id":1,"pane_id":22,"title":"stale-codex","cwd":"file:///tmp/stale-codex/","tty_name":"/dev/ttys022","is_active":true},
  {"window_id":2,"tab_id":2,"pane_id":23,"title":"notes","cwd":"file:///tmp/notes/","tty_name":"/dev/ttys023","is_active":true}
]
EOF
}

write_duplicate_fixture() {
  local dir="$1"
  mkdir -p "$dir"
  cat >"$dir/topology.jsonl" <<'EOF'
{"session":"flywheel","orchestrator_pane":1,"orchestrator_kind":"claude","effective_at":"2026-05-03T23:00:00Z"}
EOF
  cat >"$dir/josh-requests.jsonl" <<'EOF'
{"schema_version":2,"id":"jr-dup-001","captured_at":"2026-05-03T23:30:00Z","source_session":"flywheel","source_pane":1,"prompt_hash":"sha256:dup","source_message_id":null,"sanitized_excerpt":"fixture dup one"}
{"schema_version":2,"id":"jr-dup-002","captured_at":"2026-05-03T23:31:00Z","source_session":"flywheel","source_pane":1,"prompt_hash":"sha256:dup","source_message_id":null,"sanitized_excerpt":"fixture dup two"}
EOF
  : >"$dir/coordination.jsonl"
}

make_repo() {
  local repo="$TMP/repo"
  rm -rf "$repo"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  cp "$PROBE" "$repo/.flywheel/scripts/orch-capture-parity-probe.py"
  chmod +x "$repo/.flywheel/scripts/orch-capture-parity-probe.py"
  printf '%s\n' "$repo"
}

fixture="$TMP/fixture"
write_fixture "$fixture"
export FLYWHEEL_CLAUDE_SETTINGS="$fixture/settings.json"
export FLYWHEEL_ORCH_CAPTURE_WEZTERM=0

schema_out="$TMP/schema.json"
python3 "$PROBE" --schema --json >"$schema_out"
assert_jq "$schema_out" '.schema_version == "orch-capture-parity/v1" and (.row_required_fields | index("session")) and (.row_required_fields | index("evidence_refs"))' "B13_AG1 schema names required row fields"

examples_out="$TMP/examples.json"
python3 "$PROBE" --examples --json >"$examples_out"
assert_jq "$examples_out" '(.xap2_boundary | test("flywheel-xap2")) and .active_owner_bead == "flywheel-vk9ox" and (.active_owner_boundary | test("flywheel-vk9ox"))' "B13_AG7 active owner and xap2 boundary are explicit"

probe_out="$TMP/probe.json"
python3 "$PROBE" \
  --topology "$fixture/topology.jsonl" \
  --josh-requests "$fixture/josh-requests.jsonl" \
  --coordination-log "$fixture/coordination.jsonl" \
  --team-roster "$fixture/team-roster.jsonl" \
  --wezterm-list "$fixture/wezterm.json" \
  --now "2026-05-04T00:00:00Z" \
  --stale-hours 24 \
  --json >"$probe_out"

assert_jq "$probe_out" '(.rows | length == 7) and all(.rows[]; has("session") and has("pane") and has("runtime") and has("participation_state") and has("capture_path") and has("last_capture_ts") and has("latest_transcript_prompt_ts") and has("latest_transcript_prompt") and has("last_josh_input_seen_ts") and has("gap_reason") and has("evidence_refs") and has("team_roster_event") and has("team_roster_participation") and has("wezterm_live") and has("wezterm_panes"))' "B13_AG1 probe emits required row fields"
assert_jq "$probe_out" '.rows[] | select(.session == "flywheel" and .runtime == "claude" and .participation_state == "captured")' "B13_AG2 Claude hook capture present fixture"
assert_jq "$probe_out" '.active_owner_bead == "flywheel-vk9ox" and all(.approved_remediation_tracks[]; .owner_bead == "flywheel-vk9ox" and .supersedes_owner_bead == "flywheel-xap2")' "B13_AG7 remediation tracks route to active owner"
assert_jq "$probe_out" '.rows[] | select(.session == "{proof-product}" and .runtime == "codex" and .participation_state == "capture_gap" and .gap_reason == "missing_canonical_capture")' "B13_AG2 Codex capture missing fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "{capability-control-plane}" and .runtime == "codex" and .participation_state == "captured" and (.evidence_refs[0] | test("agent_context_callback")))' "B13_AG2 Codex agent-context capture fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "legacy-shell" and .participation_state == "non_participating")' "B13_AG2 explicit non-participating runtime fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "dormant-codex" and .participation_state == "non_participating" and .gap_reason == "team_roster_session_dormant" and .team_roster_participation == "dormant")' "B13_AG2 dormant roster runtime fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "stale-codex" and .participation_state == "stale_capture" and .gap_reason == "stale_capture_row")' "B13_AG2 stale capture fixture"
assert_jq "$probe_out" '(.wezterm_visibility.source == "fixture") and any(.rows[]; .session == "stale-codex" and .wezterm_live == true and .wezterm_panes[0].pane_id == 22)' "B13_AG9 WezTerm live visibility is exposed but not capture proof"
assert_jq "$probe_out" '.rows[] | select(.session == "scrollback-codex" and .gap_reason == "pane_scrollback_not_canonical_capture")' "B13_AG4 pane scrollback alone rejected"
assert_jq "$probe_out" '.approved_remediation_tracks | length == 3 and any(.[]; .track == "primary_agent_mail_cross_orch_route") and any(.[]; .track == "secondary_ntm_send_wrapper_capture") and any(.[]; .track == "tertiary_pane_tail_poller" and has("fragility_note"))' "B13_AG5 dry-run remediation tracks"
assert_jq "$probe_out" '.capture_substrate.status == "pass" and .capture_substrate.claude_user_prompt_submit_hook_registered == true and .capture_substrate.latest_capture_ts == "2026-05-03T23:30:00Z"' "B13_AG9 capture substrate reports hook and log freshness"

missing_hook="$TMP/missing-hook-settings.json"
printf '{"hooks":{"UserPromptSubmit":[]}}\n' >"$missing_hook"
missing_hook_out="$TMP/missing-hook.json"
python3 "$PROBE" \
  --topology "$fixture/topology.jsonl" \
  --josh-requests "$fixture/josh-requests.jsonl" \
  --coordination-log "$fixture/coordination.jsonl" \
  --team-roster "$fixture/team-roster.jsonl" \
  --claude-settings "$missing_hook" \
  --now "2026-05-04T00:00:00Z" \
  --stale-hours 24 \
  --json >"$missing_hook_out"
assert_jq "$missing_hook_out" '.status == "warn" and .capture_substrate.status == "warn" and any(.capture_substrate.warnings[]; .code == "claude_user_prompt_submit_capture_hook_missing")' "B13_AG9 missing hook is surfaced mechanically"

all_clear="$TMP/all-clear"
mkdir -p "$all_clear"
cat >"$all_clear/topology.jsonl" <<'EOF'
{"session":"flywheel","orchestrator_pane":1,"orchestrator_kind":"claude","effective_at":"2026-05-03T23:00:00Z"}
{"session":"{capability-control-plane}","orchestrator_pane":1,"orchestrator_kind":"codex","capture_path":"agent-mail","capture_evidence_refs":["agent_context_callback:/tmp/{capability-control-plane}-capture.json"],"effective_at":"2026-05-03T23:00:00Z"}
EOF
cat >"$all_clear/josh-requests.jsonl" <<'EOF'
{"schema_version":2,"id":"jr-flywheel-001","captured_at":"2026-05-03T23:30:00Z","source_session":"flywheel","source_pane":1,"prompt_hash":"sha256:flywheel-001","source_message_id":"claude-message-1","sanitized_excerpt":"fixture claude request"}
EOF
: >"$all_clear/coordination.jsonl"
all_clear_out="$TMP/all-clear.json"
python3 "$PROBE" --topology "$all_clear/topology.jsonl" --josh-requests "$all_clear/josh-requests.jsonl" --coordination-log "$all_clear/coordination.jsonl" --now "2026-05-04T00:00:00Z" --json >"$all_clear_out"
assert_jq "$all_clear_out" '.status == "pass" and .orchs_with_capture_gap_count == 0' "B13_AG2 all-clear fleet fixture"

dup="$TMP/duplicate"
write_duplicate_fixture "$dup"
dup_out="$TMP/duplicate.json"
python3 "$PROBE" --topology "$dup/topology.jsonl" --josh-requests "$dup/josh-requests.jsonl" --coordination-log "$dup/coordination.jsonl" --now "2026-05-04T00:00:00Z" --json >"$dup_out"
assert_jq "$dup_out" '(.duplicate_capture_policy | test("prompt_hash")) and .status == "pass" and .orchs_with_capture_gap_count == 0 and .rows[0].participation_state == "captured" and .rows[0].gap_reason == "duplicate_capture_rows_non_blocking" and (.rows[0].duplicate_capture_groups[0].count == 2)' "B13_AG6 duplicate capture history is detected but non-blocking when capture exists"

transcript="$TMP/transcript-aware"
mkdir -p "$transcript/repos/quiet-claude" "$transcript/repos/missed-claude" "$transcript/claude-projects"
quiet_repo="$transcript/repos/quiet-claude"
missed_repo="$transcript/repos/missed-claude"
quiet_project="$transcript/claude-projects/$(printf '%s' "$quiet_repo" | sed 's#/#-#g')"
missed_project="$transcript/claude-projects/$(printf '%s' "$missed_repo" | sed 's#/#-#g')"
mkdir -p "$quiet_project" "$missed_project"
jq -nc --arg repo "$quiet_repo" '{session:"quiet-claude",repo_path:$repo,orchestrator_pane:1,orchestrator_kind:"claude",effective_at:"2026-05-03T23:00:00Z"}' >"$transcript/topology.jsonl"
jq -nc --arg repo "$missed_repo" '{session:"missed-claude",repo_path:$repo,orchestrator_pane:1,orchestrator_kind:"claude",effective_at:"2026-05-03T23:00:00Z"}' >>"$transcript/topology.jsonl"
cat >"$transcript/josh-requests.jsonl" <<'EOF'
{"schema_version":2,"id":"jr-quiet-001","captured_at":"2026-05-01T00:00:00Z","source_session":"quiet-claude","source_pane":1,"prompt_hash":"sha256:quiet","source_message_id":"quiet-message","sanitized_excerpt":"quiet captured request"}
{"schema_version":2,"id":"jr-missed-001","captured_at":"2026-05-01T00:00:00Z","source_session":"missed-claude","source_pane":1,"prompt_hash":"sha256:missed-old","source_message_id":"missed-old-message","sanitized_excerpt":"old captured request"}
EOF
cat >"$quiet_project/quiet.jsonl" <<'EOF'
{"type":"user","message":{"role":"user","content":"quiet captured request"},"uuid":"quiet-message","timestamp":"2026-05-01T00:00:00.000Z","cwd":"/tmp/quiet-claude","sessionId":"quiet-session","isSidechain":false}
{"type":"user","message":{"role":"user","content":"<command-name>/login</command-name>\n<command-message>login</command-message>\n<command-args></command-args>"},"uuid":"quiet-command-message","timestamp":"2026-05-03T00:00:00.000Z","cwd":"/tmp/quiet-claude","sessionId":"quiet-session","isSidechain":false}
{"type":"user","message":{"role":"user","content":"<command-message>flywheel:handoff</command-message>\n<command-name>/flywheel:handoff</command-name>"},"uuid":"quiet-command-message-alt","timestamp":"2026-05-03T01:00:00.000Z","cwd":"/tmp/quiet-claude","sessionId":"quiet-session","isSidechain":false}
EOF
cat >"$missed_project/missed.jsonl" <<'EOF'
{"type":"user","message":{"role":"user","content":"old captured request"},"uuid":"missed-old-message","timestamp":"2026-05-01T00:00:00.000Z","cwd":"/tmp/missed-claude","sessionId":"missed-session","isSidechain":false}
{"type":"user","message":{"role":"user","content":"please capture this newer request"},"uuid":"missed-new-message","timestamp":"2026-05-02T00:00:00.000Z","cwd":"/tmp/missed-claude","sessionId":"missed-session","isSidechain":false}
{"type":"user","message":{"role":"user","content":"<task-notification>\n<task-id>ignored</task-id>\n</task-notification>"},"uuid":"missed-task-notification","timestamp":"2026-05-03T00:00:00.000Z","cwd":"/tmp/missed-claude","sessionId":"missed-session","isSidechain":false}
{"type":"user","message":{"role":"user","content":"CODEX_WATCHTOWER_HIGH new_issues=1"},"uuid":"missed-watchtower","timestamp":"2026-05-03T01:00:00.000Z","cwd":"/tmp/missed-claude","sessionId":"missed-session","isSidechain":false}
EOF
: >"$transcript/coordination.jsonl"
: >"$transcript/team-roster.jsonl"
transcript_out="$TMP/transcript-aware.json"
python3 "$PROBE" \
  --topology "$transcript/topology.jsonl" \
  --josh-requests "$transcript/josh-requests.jsonl" \
  --coordination-log "$transcript/coordination.jsonl" \
  --team-roster "$transcript/team-roster.jsonl" \
  --claude-projects-root "$transcript/claude-projects" \
  --disable-wezterm \
  --now "2026-05-04T00:00:00Z" \
  --json >"$transcript_out"
assert_jq "$transcript_out" '(.orchs_with_capture_gap_count == 1) and any(.rows[]; .session == "quiet-claude" and .participation_state == "captured" and .gap_reason == "no_new_prompt_since_capture" and .latest_transcript_prompt_ts == "2026-05-01T00:00:00Z")' "B13_AG10 stale wall-clock capture is OK when no newer transcript prompt exists"
assert_jq "$transcript_out" 'any(.rows[]; .session == "missed-claude" and .participation_state == "stale_capture" and .gap_reason == "latest_transcript_prompt_uncaptured" and .latest_transcript_prompt.source_message_id == "missed-new-message")' "B13_AG10 newer transcript prompt remains a capture gap"

repo="$(make_repo)"
doctor_out="$TMP/doctor.json"
strict_out="$TMP/doctor-strict.json"
FLYWHEEL_SESSION_TOPOLOGY="$fixture/topology.jsonl" \
FLYWHEEL_JOSH_REQUESTS_LOG="$fixture/josh-requests.jsonl" \
FLYWHEEL_CROSS_ORCH_COORDINATION_LOG="$fixture/coordination.jsonl" \
TEAM_ROSTER="$fixture/team-roster.jsonl" \
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  "$BIN" doctor --repo "$repo" --json >"$doctor_out" 2>"$TMP/doctor.err" || true
FLYWHEEL_SESSION_TOPOLOGY="$fixture/topology.jsonl" \
FLYWHEEL_JOSH_REQUESTS_LOG="$fixture/josh-requests.jsonl" \
FLYWHEEL_CROSS_ORCH_COORDINATION_LOG="$fixture/coordination.jsonl" \
TEAM_ROSTER="$fixture/team-roster.jsonl" \
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  "$BIN" doctor --strict --repo "$repo" --json >"$strict_out" 2>"$TMP/doctor-strict.err" && strict_rc=0 || strict_rc=$?

assert_jq "$probe_out" '.orchs_with_capture_gap_count == 3 and .status == "warn"' "B13_AG3 probe exposes orchs_with_capture_gap_count"
if [[ "$strict_rc" -ne 0 ]] && jq -e '.status == "fail" and any(.errors[]?; .code == "orchs_with_capture_gap_count")' "$strict_out" >/dev/null; then
  pass "B13_AG8 strict doctor fails when Claude passes and Codex fails"
else
  fail "B13_AG8 strict doctor fails when Claude passes and Codex fails"
  jq . "$strict_out" || true
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
