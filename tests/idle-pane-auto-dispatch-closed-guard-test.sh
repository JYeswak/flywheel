#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idle-pane-auto-dispatch-closed-guard.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_fixture_tools() {
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

  cat >"$TMP/probe" <<'EOF'
#!/usr/bin/env bash
jq -nc '{
  schema_version:"idle-state-probe/v1",
  status:"pass",
  session:"fixture",
  repo:"fixture",
  idle_state_class:[{
    pane:2,
    state:"WAITING",
    capture_provenance:"live",
    idle_state_class:"dispatching",
    dispatch_candidate:"flywheel-fixture",
    dispatch_priority:1,
    age_seconds:900
  }],
  idle_state_summary:{dispatching:1,cooldown:0,light_queue:0,saturated:0,disabled_class:0,not_waiting:0},
  idle_dispatching_over_threshold_count:1
}'
EOF
  chmod +x "$TMP/probe"

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
    printf '{"session":"%s","pane":"%s","file":"%s"}\n' "$session" "$pane" "$file" >"$state/send.json"
    printf 'sent\n'
    ;;
  --robot-tail=*)
    text="$(cat "$state/last_prompt" 2>/dev/null || true)"
    jq -nc --arg text "$text" '{success:true,panes:[{pane:2,text:$text}],source_health:{status:"fixture"}}'
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

  mkdir -p "$TMP/bin"
  cat >"$TMP/bin/br" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_BR_LOG:?}"
case "${1:-}" in
  show)
    case "${FAKE_BR_SHOW_MODE:?}" in
      closed)
        jq -nc '{status:"closed",closed_at:"2026-05-04T03:43Z",close_reason:"PASS_WITH_UNRELATED_GAP_FIXED"}'
        ;;
      open)
        jq -nc '{status:"open",closed_at:"",close_reason:""}'
        ;;
      fail)
        exit 19
        ;;
      *)
        printf 'unsupported FAKE_BR_SHOW_MODE=%s\n' "$FAKE_BR_SHOW_MODE" >&2
        exit 2
        ;;
    esac
    ;;
  update)
    exit 0
    ;;
  *)
    printf 'unsupported fake br args: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF
  chmod +x "$TMP/bin/br"
}

run_case() {
  local name="$1" mode="$2"
  local repo="$TMP/repo-$name" state="$TMP/state-$name"
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  env \
    "HOME=$TMP/home-$name" \
    "PATH=$TMP/bin:$PATH" \
    "FLYWHEEL_BR_BIN=$TMP/bin/br" \
    "FAKE_NTM_STATE=$TMP/ntm-$name" \
    "FAKE_BR_LOG=$TMP/br-$name.log" \
    "FAKE_BR_SHOW_MODE=$mode" \
    "FLYWHEEL_JSONL_APPEND_LIB=$TMP/jsonl-append.sh" \
    "FLYWHEEL_STALE_ERROR_AUTO_PING=$TMP/missing-stale-ping" \
    "FLYWHEEL_WORKER_STALL_ALERT_PROBE=$TMP/missing-stall-alert" \
    "FLYWHEEL_SESSION_TOPOLOGY=$TMP/missing-topology.jsonl" \
    "FLYWHEEL_IDLE_WATCHER_NOW_EPOCH=1777850000" \
    "$SCRIPT" --session fixture --repo "$repo" --state-dir "$state" --probe "$TMP/probe" --ntm-bin "$TMP/ntm" --apply --json \
    >"$TMP/$name.json" 2>"$TMP/$name.err"
}

write_fixture_tools

run_case closed closed
if jq -e '.status == "skipped_closed_bead" and .reason == "closed_bead_guard" and .closed_bead_guard.observed_status == "closed" and .delivery_receipt.skipped == true' "$TMP/closed.json" >/dev/null \
  && ! grep -q '^update ' "$TMP/br-closed.log" \
  && [[ ! -e "$TMP/ntm-closed/send.json" ]] \
  && jq -e '.action == "skipped" and .reason == "closed_bead_guard" and .bead_id == "flywheel-fixture" and .delivery_receipt.skipped == true' "$TMP/repo-closed/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "closed_bead_skips_update_send_and_logs_guard"
else
  fail "closed_bead_skips_update_send_and_logs_guard"
fi

run_case open open
if jq -e '.status == "dispatched" and .delivery_receipt.transport_accepted == true' "$TMP/open.json" >/dev/null \
  && grep -qx 'update flywheel-fixture --status in_progress' "$TMP/br-open.log" \
  && [[ -e "$TMP/ntm-open/send.json" ]] \
  && jq -e '.event == "idle_pane_auto_dispatch" and .bead_id == "flywheel-fixture" and .target_pane == 2 and .delivery_receipt.transport_accepted == true' "$TMP/repo-open/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "open_bead_keeps_normal_dispatch_path"
else
  fail "open_bead_keeps_normal_dispatch_path"
fi

run_case fail fail
if jq -e '.status == "skipped_status_probe_failed" and .reason == "status_probe_failed" and .closed_bead_guard.status_probe_rc == 19 and .delivery_receipt.skipped == true' "$TMP/fail.json" >/dev/null \
  && ! grep -q '^update ' "$TMP/br-fail.log" \
  && [[ ! -e "$TMP/ntm-fail/send.json" ]] \
  && jq -e '.action == "skipped" and .reason == "status_probe_failed" and .bead_id == "flywheel-fixture" and .delivery_receipt.skipped == true' "$TMP/repo-fail/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "status_probe_failure_skips_update_send_and_logs_probe_failure"
else
  fail "status_probe_failure_skips_update_send_and_logs_probe_failure"
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "3" && "$fail_count" == "0" ]]
