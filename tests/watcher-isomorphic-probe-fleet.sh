#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/watcher-isomorphic-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/watcher-isomorphic-fleet.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_plist() {
  local path="$1" label="$2"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array><string>/bin/echo</string><string>fixture</string></array>
</dict>
</plist>
XML
}

seed_repo() {
  local repo="$1" mode="${2:-pass}" fixture
  fixture="$repo/.flywheel/watcher-isomorphic-fixtures"
  mkdir -p "$fixture/state" "$fixture/LaunchAgents" "$fixture/LaunchAgents/.disabled"
  printf '%s\n' \
    '{"fixture_cases":[{"fixture_id":"G_post_completion_buffer_no_autosubmit","status":"pass"}]}' \
    >"$fixture/selftest.json"
  printf '%s\n' \
    '{"ts":"2026-05-05T02:00:00Z","event":"recovery","false_positive":false}' \
    >"$fixture/recovery.jsonl"
  write_plist "$fixture/LaunchAgents/ai.zeststream.fixture.plist" "ai.zeststream.fixture"
  printf '%s\n' \
    '{"ts":"2026-05-05T02:00:00Z","action":"register","label":"ai.zeststream.fixture","reason":"fixture watcher proof bead flywheel-johd3"}' \
    >"$fixture/registry.jsonl"
  printf '%s\n' \
    '[{"id":"flywheel-open","status":"open"},{"id":"flywheel-progress","status":"in_progress"}]' \
    >"$fixture/ready.json"
  printf '%s\n' \
    '{"total":116,"by_class":{"silent-write":45,"destructive-default":64,"unregistered-process":7}}' \
    >"$fixture/trauma.json"
  printf '%s\n' \
    '[{"id":"action-1","has_receipt":true}]' \
    >"$fixture/receipts.json"
  if [[ "$mode" == "fail" ]]; then
    printf '%s\n' '[{"id":"flywheel-closed","status":"closed"}]' >"$fixture/ready.json"
  fi
}

write_loop() {
  local loops_dir="$1" session="$2" repo="$3"
  mkdir -p "$loops_dir"
  jq -nc --arg session "$session" --arg repo "$repo" \
    '{session:$session,active:true,repo:$repo,orchestrator_pane:1}' >"$loops_dir/$session.json"
}

write_topology_row() {
  local topology="$1" session="$2" effective_at="$3"
  jq -nc --arg session "$session" --arg effective_at "$effective_at" \
    '{session:$session,effective_at:$effective_at,session_status:"live",orchestrator_pane:1,callback_pane:1,worker_panes:[2]}' >>"$topology"
}

run_fleet() {
  local topology="$1" loops_dir="$2" outfile="$3"
  WATCHER_ISOMORPHIC_NOW="2026-05-05T02:30:00Z" \
    "$SCRIPT" --fleet --json --topology "$topology" --loops-dir "$loops_dir" --fleet-timeout 20 >"$outfile"
}

if bash -n "$SCRIPT"; then
  pass "probe syntax"
else
  fail "probe syntax"
fi

mixed_topology="$TMP/mixed-topology.jsonl"
mixed_loops="$TMP/mixed-loops"
alpha="$TMP/repos/alpha"
beta="$TMP/repos/beta"
gamma="$TMP/repos/gamma-missing"
mkdir -p "$alpha" "$beta"
seed_repo "$alpha" pass
seed_repo "$beta" fail
write_loop "$mixed_loops" alpha "$alpha"
write_loop "$mixed_loops" beta "$beta"
write_loop "$mixed_loops" gamma "$gamma"
write_topology_row "$mixed_topology" alpha "2026-05-05T01:00:00Z"
write_topology_row "$mixed_topology" beta "2026-05-05T01:00:00Z"
write_topology_row "$mixed_topology" gamma "2026-05-05T01:00:00Z"
jq -nc '{session:"alpha",effective_at:"2026-05-04T23:00:00Z",session_status:"metadata_only_not_live",orchestrator_pane:null,worker_panes:[]}' >>"$mixed_topology"
run_fleet "$mixed_topology" "$mixed_loops" "$TMP/mixed.json"
assert_jq "$TMP/mixed.json" '.schema_version == "watcher-isomorphic-probe-fleet.v1" and .status == "mixed"' "mixed fleet schema"
assert_jq "$TMP/mixed.json" '.fleet_summary.total_sessions == 3 and .fleet_summary.passing == 1 and .fleet_summary.failing == 1 and .fleet_summary.missing_tooling == 1' "mixed fleet counts"
assert_jq "$TMP/mixed.json" '.fleet_summary.fleet_watcher_reenable_recommendation == "yellow" and .watcher_isomorphic_fleet_status == "yellow"' "mixed fleet recommendation yellow"
assert_jq "$TMP/mixed.json" '.sessions.alpha.topology_effective_at == "2026-05-05T01:00:00Z"' "latest effective_at wins"

pass_topology="$TMP/pass-topology.jsonl"
pass_loops="$TMP/pass-loops"
pass_a="$TMP/repos/pass-a"
pass_b="$TMP/repos/pass-b"
mkdir -p "$pass_a" "$pass_b"
seed_repo "$pass_a" pass
seed_repo "$pass_b" pass
write_loop "$pass_loops" pass_a "$pass_a"
write_loop "$pass_loops" pass_b "$pass_b"
write_topology_row "$pass_topology" pass_a "2026-05-05T01:00:00Z"
write_topology_row "$pass_topology" pass_b "2026-05-05T01:00:00Z"
run_fleet "$pass_topology" "$pass_loops" "$TMP/pass.json"
assert_jq "$TMP/pass.json" '.status == "pass" and .fleet_summary.fleet_watcher_reenable_recommendation == "green"' "all-pass fleet green"

fail_topology="$TMP/fail-topology.jsonl"
fail_loops="$TMP/fail-loops"
fail_a="$TMP/repos/fail-a"
fail_b="$TMP/repos/fail-b"
mkdir -p "$fail_a" "$fail_b"
seed_repo "$fail_a" fail
seed_repo "$fail_b" fail
write_loop "$fail_loops" fail_a "$fail_a"
write_loop "$fail_loops" fail_b "$fail_b"
write_topology_row "$fail_topology" fail_a "2026-05-05T01:00:00Z"
write_topology_row "$fail_topology" fail_b "2026-05-05T01:00:00Z"
run_fleet "$fail_topology" "$fail_loops" "$TMP/fail.json"
assert_jq "$TMP/fail.json" '.status == "fail" and .fleet_summary.fleet_watcher_reenable_recommendation == "red"' "all-fail fleet red"

"$SCRIPT" --examples | grep -q -- "--fleet" && pass "examples include fleet" || fail "examples include fleet"

if [[ "$fail_count" -ne 0 ]]; then
  printf 'FAILED watcher-isomorphic-probe-fleet tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK watcher-isomorphic-probe-fleet tests pass=%s\n' "$pass_count"
