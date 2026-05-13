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
EOF
  cat >"$dir/josh-requests.jsonl" <<'EOF'
{"schema_version":2,"id":"jr-flywheel-001","captured_at":"2026-05-03T23:30:00Z","source_session":"flywheel","source_pane":1,"prompt_hash":"sha256:flywheel-001","source_message_id":"claude-message-1","sanitized_excerpt":"fixture claude request"}
{"schema_version":2,"id":"jr-stale-001","captured_at":"2026-05-01T00:00:00Z","source_session":"stale-codex","source_pane":2,"prompt_hash":"sha256:stale-001","source_message_id":"codex-message-stale","sanitized_excerpt":"fixture stale request"}
EOF
  cat >"$dir/coordination.jsonl" <<'EOF'
{"ts":"2026-05-03T23:45:00Z","event":"mobile_eats_orch_ack","session":"{proof-product}"}
{"ts":"2026-05-03T23:50:00Z","event":"{capability-control-plane}_agent_mail","source_session":"{capability-control-plane}"}
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
  --now "2026-05-04T00:00:00Z" \
  --stale-hours 24 \
  --json >"$probe_out"

assert_jq "$probe_out" '(.rows | length == 6) and all(.rows[]; has("session") and has("pane") and has("runtime") and has("participation_state") and has("capture_path") and has("last_capture_ts") and has("last_josh_input_seen_ts") and has("gap_reason") and has("evidence_refs"))' "B13_AG1 probe emits required row fields"
assert_jq "$probe_out" '.rows[] | select(.session == "flywheel" and .runtime == "claude" and .participation_state == "captured")' "B13_AG2 Claude hook capture present fixture"
assert_jq "$probe_out" '.active_owner_bead == "flywheel-vk9ox" and all(.approved_remediation_tracks[]; .owner_bead == "flywheel-vk9ox" and .supersedes_owner_bead == "flywheel-xap2")' "B13_AG7 remediation tracks route to active owner"
assert_jq "$probe_out" '.rows[] | select(.session == "{proof-product}" and .runtime == "codex" and .participation_state == "capture_gap" and .gap_reason == "missing_canonical_capture")' "B13_AG2 Codex capture missing fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "{capability-control-plane}" and .runtime == "codex" and .participation_state == "captured" and (.evidence_refs[0] | test("agent_context_callback")))' "B13_AG2 Codex agent-context capture fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "legacy-shell" and .participation_state == "non_participating")' "B13_AG2 explicit non-participating runtime fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "stale-codex" and .participation_state == "stale_capture" and .gap_reason == "stale_capture_row")' "B13_AG2 stale capture fixture"
assert_jq "$probe_out" '.rows[] | select(.session == "scrollback-codex" and .gap_reason == "pane_scrollback_not_canonical_capture")' "B13_AG4 pane scrollback alone rejected"
assert_jq "$probe_out" '.approved_remediation_tracks | length == 3 and any(.[]; .track == "primary_agent_mail_cross_orch_route") and any(.[]; .track == "secondary_ntm_send_wrapper_capture") and any(.[]; .track == "tertiary_pane_tail_poller" and has("fragility_note"))' "B13_AG5 dry-run remediation tracks"

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
assert_jq "$dup_out" '(.duplicate_capture_policy | test("prompt_hash")) and .rows[0].gap_reason == "duplicate_capture_rows" and (.rows[0].duplicate_capture_groups[0].count == 2)' "B13_AG6 duplicate capture prevention is specified and detected"

repo="$(make_repo)"
doctor_out="$TMP/doctor.json"
strict_out="$TMP/doctor-strict.json"
FLYWHEEL_SESSION_TOPOLOGY="$fixture/topology.jsonl" \
FLYWHEEL_JOSH_REQUESTS_LOG="$fixture/josh-requests.jsonl" \
FLYWHEEL_CROSS_ORCH_COORDINATION_LOG="$fixture/coordination.jsonl" \
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  "$BIN" doctor --repo "$repo" --json >"$doctor_out" 2>"$TMP/doctor.err" || true
FLYWHEEL_SESSION_TOPOLOGY="$fixture/topology.jsonl" \
FLYWHEEL_JOSH_REQUESTS_LOG="$fixture/josh-requests.jsonl" \
FLYWHEEL_CROSS_ORCH_COORDINATION_LOG="$fixture/coordination.jsonl" \
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
