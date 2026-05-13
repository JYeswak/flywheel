#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/peer-orch-respawn-permit.sh"
TMP="$(mktemp -d)"
PASS=0

assert_jq() {
  local name="$1" file="$2" expr="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    PASS=$((PASS + 1))
  else
    printf 'FAIL %s\n' "$name" >&2
    cat "$file" >&2
    exit 1
  fi
}

assert_cmd() {
  local name="$1"; shift
  if "$@" >/dev/null; then
    PASS=$((PASS + 1))
  else
    printf 'FAIL %s\n' "$name" >&2
    exit 1
  fi
}

cat > "$TMP/topology.jsonl" <<'JSON'
{"protected_sessions":["{session}","{session}"]}
JSON

cat > "$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
log="${FAKE_NTM_LOG:?}"
cmd="$1"; shift
case "$cmd" in
  health)
    session="$1"; shift
    pane=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --pane) pane="$2"; shift 2 ;;
        --json) shift ;;
        *) shift ;;
      esac
    done
    printf 'health %s %s\n' "$session" "$pane" >> "$log"
    state="${FAKE_HEALTH_STATE:-ERROR}"
    status="${FAKE_HEALTH_STATUS:-error}"
    process="${FAKE_PROCESS_STATUS:-running}"
    jq -nc --argjson pane "$pane" --arg state "$state" --arg status "$status" --arg process_status "$process" '{status:$status,agents:[{pane_idx:$pane,state:$state,status:$status,process_status:$process_status}]}'
    ;;
  respawn)
    session="$1"; shift
    panes=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --panes=*) panes="${1#--panes=}"; shift ;;
        --force|--json) shift ;;
        *) shift ;;
      esac
    done
    printf 'respawn %s %s\n' "$session" "$panes" >> "$log"
    jq -nc --arg session "$session" --arg panes "$panes" '{status:"ok",session:$session,panes:$panes}'
    ;;
  *) printf 'unexpected ntm command %s\n' "$cmd" >&2; exit 64 ;;
esac
SH
chmod +x "$TMP/ntm"
: > "$TMP/ntm.log"

common_env=(
  PEER_ORCH_RECOVERY_TOPOLOGY="$TMP/topology.jsonl"
  PEER_ORCH_RECOVERY_LEDGER="$TMP/recovery.jsonl"
  PEER_ORCH_RECOVERY_CONTRACT_LEDGER="$TMP/contract.jsonl"
  PEER_ORCH_RECOVERY_JSONL_APPEND_LIB="$ROOT/.flywheel/scripts/jsonl-append-validated.sh"
  PEER_ORCH_RECOVERY_NTM_BIN="$TMP/ntm"
  PEER_ORCH_RECOVERY_NOW="2026-05-07T00:00:00Z"
  FAKE_NTM_LOG="$TMP/ntm.log"
)

assert_cmd syntax bash -n "$SCRIPT"
assert_cmd info env "${common_env[@]}" "$SCRIPT" --info
assert_cmd examples env "${common_env[@]}" "$SCRIPT" examples
assert_cmd quickstart env "${common_env[@]}" "$SCRIPT" quickstart
assert_cmd schema env "${common_env[@]}" "$SCRIPT" schema
assert_cmd completion env "${common_env[@]}" "$SCRIPT" completion

env "${common_env[@]}" "$SCRIPT" --target-session flywheel --target-pane 1 --actor-session flywheel --actor-pane 1 --dry-run > "$TMP/self.json"
assert_jq self_refuse "$TMP/self.json" '.decision=="refuse" and .reason=="self_orch_respawn_refused"'

env "${common_env[@]}" "$SCRIPT" --target-session {capability-control-plane} --target-pane 1 --actor-session flywheel --actor-pane 1 --apply --reason frozen-peer > "$TMP/permit.json"
assert_jq {capability-control-plane}_permit "$TMP/permit.json" '.decision=="permit" and .native_health_delegated==true and .native_respawn_delegated==true and .respawn_rc==0'
grep -q '^health {capability-control-plane} 1$' "$TMP/ntm.log"
PASS=$((PASS + 1))
grep -q '^respawn {capability-control-plane} 1$' "$TMP/ntm.log"
PASS=$((PASS + 1))
assert_jq ledger_written "$TMP/recovery.jsonl" '.decision=="permit" and .reason=="frozen-peer"'

env "${common_env[@]}" "$SCRIPT" --target-session {session} --target-pane 1 --actor-session flywheel --actor-pane 1 --dry-run > "$TMP/protected.json"
assert_jq alps_refuse "$TMP/protected.json" '.decision=="refuse" and .reason=="protected_session_refused"'

env "${common_env[@]}" FAKE_HEALTH_STATE=WAITING FAKE_HEALTH_STATUS=ok "$SCRIPT" --target-session {capability-control-plane} --target-pane 1 --actor-session flywheel --actor-pane 1 --dry-run > "$TMP/not-frozen.json"
assert_jq not_frozen "$TMP/not-frozen.json" '.decision=="refuse" and .reason=="peer_not_frozen" and .evidence.method=="ntm_health"'

env "${common_env[@]}" "$SCRIPT" --target-session {capability-control-plane} --target-pane 1 --actor-session flywheel --actor-pane 1 --dry-run > "$TMP/dry-run.json"
assert_jq dry_run_no_mutation "$TMP/dry-run.json" '.decision=="permit"'
[[ "$(wc -l < "$TMP/recovery.jsonl")" -eq 1 ]]
PASS=$((PASS + 1))

env "${common_env[@]}" "$SCRIPT" doctor > "$TMP/doctor.json"
assert_jq doctor_fields "$TMP/doctor.json" '.peer_orch_recovery_count_24h==1 and .contract_rows>=1 and .native_respawn=="ntm respawn --json"'

env "${common_env[@]}" "$SCRIPT" health --target-session {capability-control-plane} --target-pane 1 > "$TMP/health.json"
assert_jq health_delegates "$TMP/health.json" '.native_health.agents[0].pane_idx==1'

printf 'OK peer-orch-respawn-permit tests pass=%s\n' "$PASS"
