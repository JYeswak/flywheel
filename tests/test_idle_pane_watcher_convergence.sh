#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/idle-state-probe.sh"
WATCHER="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idle-pane-watcher-convergence.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_fake_br() {
  mkdir -p "$TMP/bin"
  cat >"$TMP/bin/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  ready)
    [[ "${2:-}" == "--json" ]] || exit 2
    cat "${FAKE_BR_READY:?}"
    ;;
  *) exit 2 ;;
esac
SH
  chmod +x "$TMP/bin/br"
}

write_fake_ntm() {
  cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_ARGV:?}"
case "${1:-}" in
  wait)
    if [[ "${FAKE_NTM_WAIT_TIMEOUT:-0}" == "1" ]]; then
      jq -nc '{success:false,condition:"idle",matched:false,reason:"timeout"}'
      exit 1
    fi
    jq -nc '{success:true,condition:"idle",matched:true}'
    ;;
  assign)
    jq -nc '{success:true,data:{assignments:[{bead_id:"flywheel-p0",pane:2}],skipped:[]}}'
    ;;
  --robot-activity=*)
    if [[ "${FAKE_NTM_NO_LIVE:-0}" == "1" ]]; then
      jq -nc '{success:true,agents:[{pane_idx:2,state:"THINKING",capture_provenance:"live"}]}'
    else
      jq -nc '{success:true,agents:[{pane_idx:2,state:"WAITING",capture_provenance:"live",capture_collected_at:"2026-05-11T00:00:00Z"}]}'
    fi
    ;;
  *) exit 2 ;;
esac
SH
  chmod +x "$TMP/ntm"
}

write_ready_default() {
  cat >"$TMP/ready.json" <<'JSON'
[
  {"id":"flywheel-p0","priority":0,"created_at":"2026-05-01T00:00:00Z","title":"P0 dispatch"},
  {"id":"flywheel-p1","priority":1,"created_at":"2026-05-01T00:01:00Z","title":"P1 dispatch"},
  {"id":"flywheel-p2","priority":2,"created_at":"2026-05-01T00:02:00Z","title":"P2 not dispatchable"},
  {"id":"flywheel-epic","priority":1,"created_at":"2026-05-01T00:03:00Z","title":"EPIC: parent rollup"}
]
JSON
}

write_activity_three() {
  cat >"$TMP/activity.json" <<'JSON'
{"agents":[
  {"pane_idx":2,"state":"WAITING","capture_provenance":"live","state_since_epoch":100},
  {"pane_idx":3,"state":"WAITING","capture_provenance":"live","state_since_epoch":100},
  {"pane_idx":4,"state":"WAITING","capture_provenance":"live","state_since_epoch":100}
]}
JSON
}

run_probe() {
  local out="$1" repo="$TMP/repo-probe"
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  env -i \
    HOME="$TMP/home-probe" \
    USER=josh \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    FLYWHEEL_BR_BIN="$TMP/bin/br" \
    FAKE_BR_READY="$TMP/ready.json" \
    "$PROBE" --json --session fixture --repo "$repo" \
      --activity-fixture "$TMP/activity.json" \
      --pane-last-fired "$TMP/probe-pane-last-fired" \
      --bead-fired "$TMP/probe-bead-fired" \
      --now-epoch 1000 >"$out"
}

run_watcher() {
  local name="$1"; shift
  local repo="$TMP/repo-$name"
  local -a env_extra=()
  while [[ $# -gt 0 && "$1" == *=* ]]; do
    env_extra+=("$1")
    shift
  done
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  env -i \
    HOME="$TMP/home-$name" \
    USER=josh \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    FAKE_NTM_ARGV="$TMP/$name.argv" \
    "${env_extra[@]}" \
    "$WATCHER" --session fixture --repo "$repo" --ntm-bin "$TMP/ntm" "$@" --json >"$TMP/$name.json"
}

write_fake_br
write_fake_ntm
write_ready_default
write_activity_three

run_probe "$TMP/probe-default.json"
if jq -e '.br_ready_count == 4 and .br_ready_p0_p1_count == 3 and .idle_state_summary.dispatching == 3 and ([.idle_state_class[].ready_p0_p1_count] | unique == [2])' "$TMP/probe-default.json" >/dev/null; then
  pass "probe_converges_with_br_ready_under_minimal_path"
else
  fail "probe_converges_with_br_ready_under_minimal_path"
fi

run_watcher dry --dry-run
if jq -e '.schema_version == "idle-pane-auto-dispatch/v3" and .status == "assigned" and .dry_run == true and .apply == false and .wait.exit_code == 0 and .assign.exit_code == 0' "$TMP/dry.json" >/dev/null \
  && grep -q '^wait fixture --until=idle --any --timeout=1s --json$' "$TMP/dry.argv" \
  && grep -q '^--robot-activity=fixture --json$' "$TMP/dry.argv" \
  && grep -q '^assign fixture --repo '"$TMP"'/repo-dry --json --limit=1 --dry-run$' "$TMP/dry.argv"; then
  pass "watcher_delegates_dry_run_to_native_ntm_assign"
else
  fail "watcher_delegates_dry_run_to_native_ntm_assign"
fi

run_watcher apply --apply
if jq -e '.status == "assigned" and .apply == true and (.assign.native_command | contains("--auto"))' "$TMP/apply.json" >/dev/null \
  && grep -q '^assign fixture --repo '"$TMP"'/repo-apply --json --limit=1 --auto$' "$TMP/apply.argv"; then
  pass "watcher_apply_delegates_to_native_ntm_assign_auto"
else
  fail "watcher_apply_delegates_to_native_ntm_assign_auto"
fi

run_watcher timeout FAKE_NTM_WAIT_TIMEOUT=1 --dry-run
if jq -e '.status == "no_idle_wait_timeout" and .wait.exit_code == 1 and .assign == null' "$TMP/timeout.json" >/dev/null; then
  pass "wait_timeout_prevents_assign"
else
  fail "wait_timeout_prevents_assign"
fi

run_watcher no-live FAKE_NTM_NO_LIVE=1 --dry-run
if jq -e '.status == "no_capture_live_panes" and .blocked_native_dependency.reason == "no_capture_live_panes"' "$TMP/no-live.json" >/dev/null; then
  pass "capture_provenance_gate_blocks_without_live_waiting_panes"
else
  fail "capture_provenance_gate_blocks_without_live_waiting_panes"
fi

cat >"$TMP/ready.json" <<'JSON'
{"issues":[{"id":"flywheel-envelope","priority":0,"created_at":"2026-05-01T00:00:00Z","title":"Envelope ready bead"}]}
JSON
run_probe "$TMP/probe-envelope.json"
if jq -e '.br_ready_count == 1 and .idle_state_class[0].dispatch_candidate == "flywheel-envelope"' "$TMP/probe-envelope.json" >/dev/null; then
  pass "br_ready_object_envelope_normalizes_to_ready_inventory"
else
  fail "br_ready_object_envelope_normalizes_to_ready_inventory"
fi

cat >"$TMP/ready.json" <<'JSON'
[{"id":"flywheel-epicenter","priority":0,"created_at":"2026-05-01T00:00:00Z","title":"epicenter probe convergence"}]
JSON
run_probe "$TMP/probe-epicenter.json"
if jq -e '.br_ready_count == 1 and .idle_state_class[0].dispatch_candidate == "flywheel-epicenter" and .idle_state_class[0].ready_p0_p1_count == 1' "$TMP/probe-epicenter.json" >/dev/null; then
  pass "epic_negative_filter_does_not_match_substrings"
else
  fail "epic_negative_filter_does_not_match_substrings"
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "7" && "$fail_count" == "0" ]]
