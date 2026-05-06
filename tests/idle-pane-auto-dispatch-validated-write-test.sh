#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idle-pane-auto-dispatch-write.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_fixture_tools() {
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
}

run_case() {
  local name="$1" mode="$2" extra_env="${3:-}"
  local repo="$TMP/repo-$name" state="$TMP/state-$name"
  local -a env_args=(
    "HOME=$TMP/home-$name"
    "FAKE_NTM_STATE=$TMP/ntm-$name"
    "FLYWHEEL_JSONL_APPEND_LIB=$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh"
    "FLYWHEEL_STALE_ERROR_AUTO_PING=$TMP/missing-stale-ping"
    "FLYWHEEL_WORKER_STALL_ALERT_PROBE=$TMP/missing-stall-alert"
    "FLYWHEEL_SESSION_TOPOLOGY=$TMP/missing-topology.jsonl"
    "FLYWHEEL_IDLE_WATCHER_NOW_EPOCH=1777850000"
  )
  [[ -z "$extra_env" ]] || env_args+=("$extra_env")
  mkdir -p "$repo/.flywheel"
  env "${env_args[@]}" \
    "$SCRIPT" --session fixture --repo "$repo" --state-dir "$state" --probe "$TMP/probe" --ntm-bin "$TMP/ntm" "$mode" --json \
    >"$TMP/$name.json" 2>"$TMP/$name.err"
}

write_fixture_tools

grep -F -- '"$NTM_BIN" send "$SESSION" --pane="$pane" --no-cass-check --file "$dispatch_file"' "$SCRIPT" >/dev/null \
  && pass "dispatch_send_no_cass_check_argv_order" || fail "dispatch_send_no_cass_check_argv_order"

run_case dry --dry-run
if jq -e '.status == "dry_run_candidate" and .dry_run == true' "$TMP/dry.json" >/dev/null \
  && [[ ! -e "$TMP/state-dry" ]] \
  && [[ ! -e "$TMP/repo-dry/.flywheel/dispatch-log.jsonl" ]]; then
  pass "dry_run_writes_no_cooldown_or_dispatch_log"
else
  fail "dry_run_writes_no_cooldown_or_dispatch_log"
fi

run_case apply --apply
if jq -e '.status == "dispatched" and .delivery_receipt.transport_accepted == true' "$TMP/apply.json" >/dev/null \
  && grep -qx '2:1777850000' "$TMP/state-apply/pane-last-fired" \
  && grep -qx 'flywheel-fixture:1777850000' "$TMP/state-apply/bead-fired" \
  && jq -e '.event == "idle_pane_auto_dispatch" and .bead_id == "flywheel-fixture" and .target_pane == 2 and .delivery_receipt.transport_accepted == true' "$TMP/repo-apply/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "apply_writes_cooldowns_and_valid_dispatch_log"
else
  fail "apply_writes_cooldowns_and_valid_dispatch_log"
fi

run_case empty --apply "FLYWHEEL_IDLE_DISPATCH_FORCE_EMPTY_LOG_ROW=1"
if [[ ! -s "$TMP/repo-empty/.flywheel/dispatch-log.jsonl" ]] \
  && grep -q 'dispatch-log append failed rc=1' "$TMP/empty.err"; then
  pass "empty_log_row_rejected_without_dispatch_log_write"
else
  fail "empty_log_row_rejected_without_dispatch_log_write"
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "4" && "$fail_count" == "0" ]]
