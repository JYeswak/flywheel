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

write_jsonl_append_lib() {
  cat >"$TMP/jsonl-append.sh" <<'EOF'
#!/usr/bin/env bash
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  [[ -n "$row" ]] || return 1
  jq -e . >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$row" >>"$path"
}
EOF
}

write_fake_br() {
  mkdir -p "$TMP/bin"
  cat >"$TMP/bin/br" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_BR_LOG:?}"
case "${1:-}" in
  ready)
    [[ "${2:-}" == "--json" ]] || exit 2
    cat "${FAKE_BR_READY:?}"
    ;;
  show)
    jq -nc '{status:"open",closed_at:"",close_reason:""}'
    ;;
  update)
    printf '%s\n' "$*" >>"${FAKE_BR_UPDATES:?}"
    ;;
  *)
    printf 'unsupported fake br args: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF
  chmod +x "$TMP/bin/br"
}

write_fake_ntm() {
  cat >"$TMP/ntm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
state="${FAKE_NTM_STATE:?}"
mkdir -p "$state"
case "${1:-}" in
  send)
    shift
    session="${1:-}"
    shift || true
    pane=""
    file=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --pane=*) pane="${1#*=}"; shift ;;
        --file) file="${2:?}"; shift 2 ;;
        --file=*) file="${1#*=}"; shift ;;
        --no-cass-check) shift ;;
        *) shift ;;
      esac
    done
    cp "$file" "$state/last_prompt"
    jq -nc --arg session "$session" --arg pane "$pane" --arg file "$file" \
      '{session:$session,pane:($pane|tonumber),file:$file}' >"$state/send.json"
    printf 'sent\n'
    ;;
  --robot-tail=*)
    text="$(cat "$state/last_prompt" 2>/dev/null || true)"
    jq -nc --arg text "$text" '{success:true,panes:[{pane:2,text:$text},{pane:3,text:$text},{pane:4,text:$text}],source_health:{status:"fixture"}}'
    ;;
  --robot-activity=*)
    jq -nc '{agents:[{pane_idx:2,state:"THINKING"}]}'
    ;;
  *)
    printf 'unsupported fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF
  chmod +x "$TMP/ntm"
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

write_activity_one() {
  cat >"$TMP/activity.json" <<'JSON'
{"agents":[{"pane_idx":2,"state":"WAITING","capture_provenance":"live","state_since_epoch":100}]}
JSON
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

write_topology() {
  local panes="${1:-[2,3,4]}"
  jq -nc --argjson panes "$panes" '{
    session:"fixture",
    worker_panes:$panes,
    worker_kinds:{"2":"codex","3":"codex","4":"codex"},
    orchestrator_pane:1,
    callback_pane:1,
    human_pane:0,
    effective_at:"2026-05-05T00:00:00Z"
  }' >"$TMP/topology.jsonl"
}

base_repo() {
  local repo="$TMP/repo"
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  printf '%s\n' "$repo"
}

run_probe_live_ready() {
  local out="$1" repo
  repo="$(base_repo)"
  env -i \
    HOME="$TMP/home-probe" \
    USER=josh \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    FLYWHEEL_BR_BIN="$TMP/bin/br" \
    FAKE_BR_READY="$TMP/ready.json" \
    FAKE_BR_LOG="$TMP/br-probe.log" \
    FAKE_BR_UPDATES="$TMP/br-probe-updates.log" \
    "$PROBE" --json --session fixture --repo "$repo" \
      --activity-fixture "$TMP/activity.json" \
      --pane-last-fired "$TMP/probe-pane-last-fired" \
      --bead-fired "$TMP/probe-bead-fired" \
      --now-epoch 1000 >"$out"
}

run_watcher_case() {
  local name="$1" mode="$2" state repo out err
  state="$TMP/state-$name"
  repo="$(base_repo)"
  out="$TMP/$name.json"
  err="$TMP/$name.err"
  env -i \
    HOME="$TMP/home-$name" \
    USER=josh \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    FLYWHEEL_BR_BIN="$TMP/bin/br" \
    FLYWHEEL_IDLE_STATE_ACTIVITY_FIXTURE="$TMP/activity.json" \
    FLYWHEEL_JSONL_APPEND_LIB="$TMP/jsonl-append.sh" \
    FLYWHEEL_STALE_ERROR_AUTO_PING="$TMP/missing-stale" \
    FLYWHEEL_WORKER_STALL_ALERT_PROBE="$TMP/missing-stall" \
    FLYWHEEL_SESSION_TOPOLOGY="$TMP/topology.jsonl" \
    FLYWHEEL_IDLE_WATCHER_NOW_EPOCH=1000 \
    FAKE_BR_READY="$TMP/ready.json" \
    FAKE_BR_LOG="$TMP/br-$name.log" \
    FAKE_BR_UPDATES="$TMP/br-$name-updates.log" \
    FAKE_NTM_STATE="$TMP/ntm-$name" \
    "$WATCHER" --session fixture --repo "$repo" --state-dir "$state" --ntm-bin "$TMP/ntm" "$mode" --json >"$out" 2>"$err"
}

write_jsonl_append_lib
write_fake_br
write_fake_ntm
write_activity_three
write_ready_default
write_topology '[2,3,4]'

run_probe_live_ready "$TMP/probe-default.json"
if jq -e '.br_ready_count == 4 and .br_ready_p0_p1_count == 3 and .idle_state_summary.dispatching == 3 and ([.idle_state_class[].ready_p0_p1_count] | unique == [2])' "$TMP/probe-default.json" >/dev/null; then
  pass "probe_converges_with_br_ready_under_minimal_path"
else
  fail "probe_converges_with_br_ready_under_minimal_path"
fi

run_watcher_case dry --dry-run
if jq -e '.status == "dry_run_candidate" and .candidate_count == 3 and .br_ready_count == 4 and .probe.br_ready_count == 4 and .candidate.dispatch_candidate == "flywheel-p0" and .candidate.pane == 2' "$TMP/dry.json" >/dev/null; then
  pass "idle_pane_dispatch_candidate_from_br_ready"
else
  fail "idle_pane_dispatch_candidate_from_br_ready"
fi

if [[ ! -e "$TMP/state-dry" && ! -e "$TMP/ntm-dry/send.json" && ! -e "$TMP/repo/.flywheel/dispatch-log.jsonl" ]]; then
  pass "dry_run_has_no_mutation"
else
  fail "dry_run_has_no_mutation"
fi

write_activity_one
mkdir -p "$TMP/state-cooldown"
printf '2:950\n' >"$TMP/state-cooldown/pane-last-fired"
run_watcher_case cooldown --dry-run
if jq -e '.status == "no_candidate" and .candidate_count == 0 and .probe.idle_state_summary.cooldown == 1 and .probe.idle_state_class[0].cooldown_remaining_seconds == 130' "$TMP/cooldown.json" >/dev/null; then
  pass "cooldown_blocks_recently_fired_pane"
else
  fail "cooldown_blocks_recently_fired_pane"
fi

write_activity_three
write_topology '[3]'
run_watcher_case topology --dry-run
if jq -e '.status == "dry_run_candidate" and .candidate_count == 1 and .candidate.pane == 3' "$TMP/topology.json" >/dev/null; then
  pass "topology_filters_to_allowed_worker_panes"
else
  fail "topology_filters_to_allowed_worker_panes"
fi

write_topology '[2,3,4]'
run_watcher_case apply --apply
if jq -e '.status == "dispatched" and .delivery_receipt.transport_accepted == true and .br_ready_count == 4' "$TMP/apply.json" >/dev/null \
  && jq -e '.pane == 2' "$TMP/ntm-apply/send.json" >/dev/null \
  && grep -qx '2:1000' "$TMP/state-apply/pane-last-fired" \
  && grep -qx 'flywheel-p0:1000' "$TMP/state-apply/bead-fired" \
  && grep -qx 'update flywheel-p0 --status in_progress' "$TMP/br-apply-updates.log" \
  && jq -e '.event == "idle_pane_auto_dispatch" and .bead_id == "flywheel-p0" and .target_pane == 2' "$TMP/repo/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "apply_dispatches_via_ntm_and_records_state"
else
  fail "apply_dispatches_via_ntm_and_records_state"
fi

cat >"$TMP/ready.json" <<'JSON'
[]
JSON
run_watcher_case empty --dry-run
if jq -e '.status == "no_candidate" and .br_ready_count == 0 and .probe.br_ready_count == 0 and .probe.idle_state_summary.light_queue == 3 and .candidate_count == 0' "$TMP/empty.json" >/dev/null; then
  pass "empty_br_ready_stays_light_queue_without_candidate"
else
  fail "empty_br_ready_stays_light_queue_without_candidate"
fi

cat >"$TMP/ready.json" <<'JSON'
{"issues":[{"id":"flywheel-envelope","priority":0,"created_at":"2026-05-01T00:00:00Z","title":"Envelope ready bead"}]}
JSON
run_probe_live_ready "$TMP/probe-envelope.json"
if jq -e '.br_ready_count == 1 and .idle_state_class[0].dispatch_candidate == "flywheel-envelope"' "$TMP/probe-envelope.json" >/dev/null; then
  pass "br_ready_object_envelope_normalizes_to_ready_inventory"
else
  fail "br_ready_object_envelope_normalizes_to_ready_inventory"
fi

cat >"$TMP/ready.json" <<'JSON'
[{"id":"flywheel-epicenter","priority":0,"created_at":"2026-05-01T00:00:00Z","title":"epicenter probe convergence"}]
JSON
run_probe_live_ready "$TMP/probe-epicenter.json"
if jq -e '.br_ready_count == 1 and .idle_state_class[0].dispatch_candidate == "flywheel-epicenter" and .idle_state_class[0].ready_p0_p1_count == 1' "$TMP/probe-epicenter.json" >/dev/null; then
  pass "epic_negative_filter_does_not_match_substrings"
else
  fail "epic_negative_filter_does_not_match_substrings"
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "9" && "$fail_count" == "0" ]]
