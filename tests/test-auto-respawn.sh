#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/worker-auto-respawn-watchdog.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/auto-respawn.XXXXXX")"
trap 'find "$TMP" -mindepth 1 -delete; rmdir "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'PASS %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail + 1)); }
assert_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; cat "$1" >&2; }; }

cat >"$TMP/topology.jsonl" <<'JSONL'
{"session":"fixture","effective_at":"2026-05-07T00:00:00Z","human_pane":0,"orchestrator_pane":1,"callback_pane":1,"worker_panes":[2,3]}
JSONL

cat >"$TMP/ntm" <<'SHIM'
#!/usr/bin/env bash
set -euo pipefail
log="${FAKE_NTM_LOG:?}"
case "${1:-}" in
  wait)
    session="${2:?}"; shift 2; pane=""; condition=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --pane=*) pane="${1#*=}"; shift ;;
        --pane) pane="${2:?}"; shift 2 ;;
        --condition=*) condition="${1#*=}"; shift ;;
        --condition) condition="${2:?}"; shift 2 ;;
        --timeout) shift 2 ;;
        --json) shift ;;
        *) shift ;;
      esac
    done
    printf 'wait %s %s %s\n' "$session" "$pane" "$condition" >>"$log"
    if [[ "$condition" == "DEAD" && "$pane" == "2" ]]; then
      jq -nc --arg session "$session" --arg pane "$pane" '{condition_met:true,condition:"DEAD",session:$session,pane:($pane|tonumber)}'
      exit 0
    fi
    jq -nc --arg session "$session" --arg pane "$pane" '{condition_met:false,condition:"DEAD",session:$session,pane:($pane|tonumber)}'
    exit 1
    ;;
  respawn)
    session="${2:?}"; shift 2; pane=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --panes=*) pane="${1#*=}"; shift ;;
        --panes) pane="${2:?}"; shift 2 ;;
        --json) shift ;;
        *) shift ;;
      esac
    done
    printf 'respawn %s %s\n' "$session" "$pane" >>"$log"
    jq -nc --arg session "$session" --arg pane "$pane" '{status:"respawned",session:$session,pane:($pane|tonumber)}'
    ;;
  *) printf 'unexpected ntm args: %s\n' "$*" >&2; exit 64 ;;
esac
SHIM
chmod +x "$TMP/ntm"
chmod +x "$SCRIPT"
bash -n "$SCRIPT" && ok script_syntax || bad script_syntax
"$SCRIPT" --info --json --ntm-bin "$TMP/ntm" | jq -e '.native_commands | index("ntm wait --condition=DEAD")' >/dev/null && ok info_native_contract || bad info_native_contract

FAKE_NTM_LOG="$TMP/ntm.log" "$SCRIPT" --apply --json --topology "$TMP/topology.jsonl" --attempts "$TMP/attempts.jsonl" --ntm-bin "$TMP/ntm" >"$TMP/apply.json" || rc=$?
assert_jq "$TMP/apply.json" '.status=="auto_respawn_fired" and .auto_respawns_fired==1 and (.results[] | select(.pane==2 and .action=="auto_respawn_fired")) and (.results[] | select(.pane==3 and .action=="none"))' dead_invokes_respawn_non_dead_does_not
[[ "$(grep -c '^respawn fixture 2$' "$TMP/ntm.log")" == "1" ]] && ok respawn_called_once_for_dead_pane || bad respawn_called_once_for_dead_pane
! grep -q '^respawn fixture 3$' "$TMP/ntm.log" && ok non_dead_no_respawn || bad non_dead_no_respawn
jq -e 'select(.action=="respawn_attempt" and .session=="fixture" and .pane==2)' "$TMP/attempts.jsonl" >/dev/null && ok attempt_receipt_written || bad attempt_receipt_written

: >"$TMP/ntm-pane3.log"
FAKE_NTM_LOG="$TMP/ntm-pane3.log" "$SCRIPT" --apply --json --session fixture --pane 3 --topology "$TMP/topology.jsonl" --attempts "$TMP/pane3-attempts.jsonl" --ntm-bin "$TMP/ntm" >"$TMP/pane3.json"
assert_jq "$TMP/pane3.json" '.status=="no_action_needed" and .auto_respawns_fired==0 and .results[0].pane==3 and .results[0].action=="none"' pane_filter_non_dead_no_action
! grep -q '^respawn ' "$TMP/ntm-pane3.log" && ok pane_filter_non_dead_no_respawn || bad pane_filter_non_dead_no_respawn

printf 'RESULT pass=%s fail=%s\n' "$pass" "$fail"
[[ "$fail" == "0" ]]
