#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idle-pane-work-started.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

cat >"$TMP/jsonl-append.sh" <<'SH'
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  [[ -n "$row" ]] || return 1
  jq -e 'type == "object"' >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  jq -c . <<<"$row" >>"$path"
}
SH

cat >"$TMP/probe" <<'SH'
#!/usr/bin/env bash
jq -nc '{
  schema_version:"idle-state-probe/v1",
  status:"pass",
  session:"fixture",
  repo:"fixture",
  br_ready_count:1,
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
SH
chmod +x "$TMP/probe"

cat >"$TMP/ntm" <<'SH'
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
    if [[ "${FAKE_PROMPT_VISIBLE:-0}" == "1" ]]; then
      text="$(cat "$state/last_prompt" 2>/dev/null || true)"
    else
      text="fixture pane without target prompt"
    fi
    jq -nc --arg text "$text" '{success:true,panes:[{pane:2,text:$text}],source_health:{status:"fixture"}}'
    ;;
  --robot-activity=*)
    jq -nc --arg state "${FAKE_PANE_STATE:-THINKING}" '{agents:[{pane_idx:2,state:$state}]}'
    ;;
  *)
    printf 'unsupported fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

run_case() {
  local name="$1" prompt_visible="$2" pane_state="$3"
  local repo="$TMP/repo-$name" state="$TMP/state-$name"
  mkdir -p "$repo/.flywheel"
  env \
    "FAKE_NTM_STATE=$TMP/ntm-$name" \
    "FAKE_PROMPT_VISIBLE=$prompt_visible" \
    "FAKE_PANE_STATE=$pane_state" \
    "FLYWHEEL_JSONL_APPEND_LIB=$TMP/jsonl-append.sh" \
    "FLYWHEEL_STALE_ERROR_AUTO_PING=$TMP/missing-stale-ping" \
    "FLYWHEEL_WORKER_STALL_ALERT_PROBE=$TMP/missing-stall-alert" \
    "FLYWHEEL_SESSION_TOPOLOGY=$TMP/missing-topology.jsonl" \
    "FLYWHEEL_IDLE_WATCHER_NOW_EPOCH=1777850000" \
    "$SCRIPT" --session fixture --repo "$repo" --state-dir "$state" --probe "$TMP/probe" --ntm-bin "$TMP/ntm" --apply --json \
    >"$TMP/$name.json" 2>"$TMP/$name.err"
}

run_case invalid 0 THINKING
if jq -e '
  .delivery_receipt.transport_accepted == true
  and .delivery_receipt.prompt_visible_in_target == false
  and .delivery_receipt.prompt_submitted == false
  and .delivery_receipt.pane_work_signal == true
  and .delivery_receipt.work_started == false
  and .delivery_receipt.work_started_validation_status == "invalid_missing_prompt_evidence"
' "$TMP/invalid.json" >/dev/null; then
  pass "invalid_shape_does_not_mark_work_started"
else
  fail "invalid_shape_does_not_mark_work_started"
  cat "$TMP/invalid.json" "$TMP/invalid.err" >&2 || true
fi

run_case valid 1 THINKING
if jq -e '
  .delivery_receipt.transport_accepted == true
  and .delivery_receipt.prompt_visible_in_target == true
  and .delivery_receipt.prompt_submitted == true
  and .delivery_receipt.pane_work_signal == true
  and .delivery_receipt.work_started == true
  and .delivery_receipt.work_started_validation_status == "valid_prompt_visible_and_pane_active"
' "$TMP/valid.json" >/dev/null; then
  pass "valid_prompt_visible_and_active_marks_work_started"
else
  fail "valid_prompt_visible_and_active_marks_work_started"
  cat "$TMP/valid.json" "$TMP/valid.err" >&2 || true
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "2" && "$fail_count" == "0" ]]
