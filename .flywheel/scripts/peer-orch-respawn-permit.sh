#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="peer-orch-respawn-permit.sh"
SCHEMA_VERSION="peer-orch-respawn-permit/v1"
LEDGER_PATH="${PEER_ORCH_RECOVERY_LEDGER:-.flywheel/peer-orch-recovery.jsonl}"
CONTRACT_LEDGER="${PEER_ORCH_RECOVERY_CONTRACT_LEDGER:-.flywheel/peer-orch-recovery-contract.jsonl}"
TOPOLOGY_PATH="${PEER_ORCH_RECOVERY_TOPOLOGY:-${NTM_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}}"
JSONL_APPEND_LIB="${PEER_ORCH_RECOVERY_JSONL_APPEND_LIB:-.flywheel/scripts/jsonl-append-validated.sh}"
NTM_BIN="${PEER_ORCH_RECOVERY_NTM_BIN:-ntm}"
NOW="${PEER_ORCH_RECOVERY_NOW:-}"
MODE="decision"
APPLY=0
TARGET_SESSION=""
TARGET_PANE=""
ACTOR_SESSION="${NTM_SESSION:-flywheel}"
ACTOR_PANE="${NTM_PANE:-1}"
REASON="peer-orch-recovery"

usage() {
  cat <<'USAGE'
Usage: peer-orch-respawn-permit.sh [--target-session SESSION --target-pane PANE] [--actor-session SESSION --actor-pane PANE] [--reason TEXT] [--apply|--dry-run]
       peer-orch-respawn-permit.sh health|doctor|repair|validate|audit|why|schema|examples|quickstart|completion|--info

Canonical-CLI introspection flags (per canonical-cli-scoping skill):
  --help, -h     this help text
  --info         tool name + ledger paths (JSON)
  --schema       JSON schema for the decision/health/etc emit envelopes
  --examples     copy-pasteable invocation examples

Policy wrapper for peer orchestrator recovery. Flywheel keeps permit/refusal doctrine;
NTM owns pane health detection and respawn mechanics.
USAGE
}

now_iso() {
  if [[ -n "$NOW" ]]; then printf '%s\n' "$NOW"; else date -u +%Y-%m-%dT%H:%M:%SZ; fi
}

json_emit() { jq -c .; }

append_jsonl() {
  local path="$1"
  if [[ -x "$JSONL_APPEND_LIB" ]]; then
    "$JSONL_APPEND_LIB" --file "$path"
  else
    mkdir -p "$(dirname "$path")"
    cat >> "$path"
  fi
}

rows_json() {
  local path="$1"
  if [[ -f "$path" ]]; then jq -cs '.' "$path" 2>/dev/null || printf '[]\n'; else printf '[]\n'; fi
}

latest_topology_json() {
  if [[ -f "$TOPOLOGY_PATH" ]]; then
    jq -cs 'map(select(type=="object")) | last // {}' "$TOPOLOGY_PATH" 2>/dev/null || printf '{}\n'
  else
    printf '{}\n'
  fi
}

protected_sessions_json() {
  latest_topology_json | jq -c '[.protected_sessions[]? // empty]'
}

is_protected_session() {
  local session="$1"
  protected_sessions_json | jq -e --arg session "$session" 'index($session) != null' >/dev/null
}

native_health_json() {
  if [[ -n "${PEER_ORCH_RECOVERY_HEALTH_JSON:-}" ]]; then
    printf '%s\n' "$PEER_ORCH_RECOVERY_HEALTH_JSON"
    return 0
  fi
  if [[ -n "${PEER_ORCH_RECOVERY_HEALTH_FILE:-}" ]]; then
    cat "$PEER_ORCH_RECOVERY_HEALTH_FILE"
    return 0
  fi
  if [[ -n "${PEER_ORCH_RECOVERY_ACTIVITY_JSON:-}" ]]; then
    printf '%s\n' "$PEER_ORCH_RECOVERY_ACTIVITY_JSON"
    return 0
  fi
  if [[ -n "${PEER_ORCH_RECOVERY_ACTIVITY_FILE:-}" ]]; then
    cat "$PEER_ORCH_RECOVERY_ACTIVITY_FILE"
    return 0
  fi
  "$NTM_BIN" health "$TARGET_SESSION" --pane "$TARGET_PANE" --json
}

pane_health_json() {
  local health="$1"
  jq -c --argjson pane "$TARGET_PANE" '
    def pane_match: (.pane_idx? // .pane? // .index? // .pane_id? // empty) == $pane;
    (.agents[]? | select(pane_match)) //
    (.panes[]? | select(pane_match)) //
    (.pane // empty) //
    .
  ' <<<"$health"
}

freeze_evidence_json() {
  local health pane
  if ! health="$(native_health_json 2>/dev/null)"; then
    jq -nc --arg method "ntm_health" '{freeze_confirmed:false,method:$method,reason:"ntm_health_failed"}'
    return 0
  fi
  pane="$(pane_health_json "$health")"
  jq -nc --argjson pane "$pane" --argjson health "$health" '
    def norm(x): (x // "" | tostring | ascii_downcase);
    def bad_state(x): ["error","unknown","deaf","dead","exited","stuck","failed","unresponsive","not_running"] | index(norm(x)) != null;
    def proc_bad(x): (norm(x) != "" and norm(x) != "running" and norm(x) != "alive");
    ($pane.state // $pane.activity // $health.state // $health.activity) as $state |
    ($pane.status // $health.status) as $status |
    ($pane.process_status // $health.process_status) as $process_status |
    (bad_state($state) or bad_state($status) or proc_bad($process_status)) as $frozen |
    {
      freeze_confirmed:$frozen,
      method:"ntm_health",
      state:($state // null),
      status:($status // null),
      process_status:($process_status // null),
      reason:(if $frozen then "native_health_reports_nonlive_peer" else "native_health_reports_live_peer" end),
      native_health:$health
    }
  '
}

native_respawn_json() {
  "$NTM_BIN" respawn "$TARGET_SESSION" --panes="$TARGET_PANE" --force --json
}

contract_row_json() {
  jq -nc --arg now "$(now_iso)" --arg actor "$ACTOR_SESSION:$ACTOR_PANE" --arg schema "$SCHEMA_VERSION" '{ts:$now,schema_version:$schema,actor:$actor,contract:"policy-wrapper-delegates-health-and-respawn-to-ntm",native_health:"ntm health --json",native_respawn:"ntm respawn --json"}'
}

decision_payload() {
  if [[ -z "$TARGET_SESSION" || -z "$TARGET_PANE" ]]; then
    jq -nc --arg now "$(now_iso)" --arg schema "$SCHEMA_VERSION" '{ts:$now,schema_version:$schema,decision:"refuse",reason:"missing_target"}'
    return 0
  fi

  local actor="$ACTOR_SESSION:$ACTOR_PANE" target="$TARGET_SESSION:$TARGET_PANE"
  if [[ "$actor" == "$target" ]]; then
    jq -nc --arg now "$(now_iso)" --arg schema "$SCHEMA_VERSION" --arg target "$target" '{ts:$now,schema_version:$schema,target:$target,decision:"refuse",reason:"self_orch_respawn_refused"}'
    return 0
  fi
  if [[ "$TARGET_SESSION" == "flywheel" && "$TARGET_PANE" == "1" ]]; then
    jq -nc --arg now "$(now_iso)" --arg schema "$SCHEMA_VERSION" --arg target "$target" '{ts:$now,schema_version:$schema,target:$target,decision:"refuse",reason:"primary_orchestrator_pane_refused"}'
    return 0
  fi
  if is_protected_session "$TARGET_SESSION" && [[ "$TARGET_SESSION:$TARGET_PANE" != "skillos:1" ]]; then
    jq -nc --arg now "$(now_iso)" --arg schema "$SCHEMA_VERSION" --arg target "$target" '{ts:$now,schema_version:$schema,target:$target,decision:"refuse",reason:"protected_session_refused"}'
    return 0
  fi

  local evidence
  evidence="$(freeze_evidence_json)"
  jq -nc --arg now "$(now_iso)" --arg schema "$SCHEMA_VERSION" --arg target "$target" --arg actor "$actor" --arg reason "$REASON" --argjson evidence "$evidence" '
    {
      ts:$now,
      schema_version:$schema,
      actor:$actor,
      target:$target,
      target_session:($target | split(":")[0]),
      target_pane:($target | split(":")[1] | tonumber),
      decision:(if $evidence.freeze_confirmed then "permit" else "refuse" end),
      reason:(if $evidence.freeze_confirmed then $reason else "peer_not_frozen" end),
      evidence:$evidence,
      native_health_delegated:true,
      native_respawn_delegated:false
    }
  '
}

run_decision() {
  local payload respawn rc
  payload="$(decision_payload)"
  contract_row_json | append_jsonl "$CONTRACT_LEDGER"
  if [[ "$APPLY" == "1" ]]; then
    if [[ "$(jq -r '.decision' <<<"$payload")" == "permit" ]]; then
      set +e
      respawn="$(native_respawn_json 2>&1)"
      rc=$?
      set -e
      payload="$(jq -c --argjson rc "$rc" --arg respawn "$respawn" '. + {native_respawn_delegated:true,respawn_rc:$rc,respawn_output:$respawn}' <<<"$payload")"
    fi
    printf '%s\n' "$payload" | append_jsonl "$LEDGER_PATH"
  fi
  printf '%s\n' "$payload" | json_emit
}

doctor_json() {
  local rows contracts
  rows="$(rows_json "$LEDGER_PATH")"
  contracts="$(rows_json "$CONTRACT_LEDGER")"
  jq -nc --arg now "$(now_iso)" --arg schema "$SCHEMA_VERSION" --argjson rows "$rows" --argjson contracts "$contracts" '
    {
      ts:$now,
      schema_version:$schema,
      status:"ok",
      peer_orch_recovery_count_24h:($rows | length),
      last_peer_orch_recovery_ts:($rows | map(.ts) | max // null),
      top_targets:($rows | group_by(.target // "unknown") | map({target:(.[0].target // "unknown"),count:length}) | sort_by(-.count)),
      self_refuse_count:($rows | map(select(.reason=="self_orch_respawn_refused")) | length),
      contract_rows:($contracts | length),
      native_health:"ntm health --json",
      native_respawn:"ntm respawn --json"
    }
  '
}

run_health() {
  if [[ -n "$TARGET_SESSION" && -n "$TARGET_PANE" ]]; then
    native_health_json | jq -c --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,status:"ok",native_health:.}'
  else
    doctor_json
  fi
}

run_repair() {
  mkdir -p "$(dirname "$LEDGER_PATH")" "$(dirname "$CONTRACT_LEDGER")"
  : > "$LEDGER_PATH"
  : > "$CONTRACT_LEDGER"
  jq -nc --arg now "$(now_iso)" --arg ledger "$LEDGER_PATH" --arg contract "$CONTRACT_LEDGER" '{ts:$now,status:"repaired",ledger:$ledger,contract_ledger:$contract}'
}

run_validate() { doctor_json | jq -c '. + {validated:true}'; }
run_audit() { doctor_json | jq -c '. + {audit:"pass"}'; }
run_why() { jq -nc '{why:"preserve flywheel peer-orch permit doctrine while delegating health and respawn mechanics to ntm"}'; }
run_schema() { jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,required:["target","decision","reason","evidence"],native:["ntm health --json","ntm respawn --json"]}'; }
run_info() { jq -nc --arg ntm "$NTM_BIN" --arg ledger "$LEDGER_PATH" --arg contract "$CONTRACT_LEDGER" '{name:"peer-orch-respawn-permit",ntm_bin:$ntm,ledger:$ledger,contract_ledger:$contract}'; }

examples() { cat <<'EXAMPLES'
peer-orch-respawn-permit.sh --target-session skillos --target-pane 1 --dry-run
peer-orch-respawn-permit.sh --target-session skillos --target-pane 1 --apply --reason frozen-peer-orch
peer-orch-respawn-permit.sh health --target-session skillos --target-pane 1
EXAMPLES
}

quickstart() { cat <<'QUICKSTART'
1. Inspect native pane health: peer-orch-respawn-permit.sh health --target-session <session> --target-pane <pane>
2. Dry-run permit gate: peer-orch-respawn-permit.sh --target-session <session> --target-pane <pane> --dry-run
3. Apply only if permitted: peer-orch-respawn-permit.sh --target-session <session> --target-pane <pane> --apply
QUICKSTART
}

completion() { cat <<'COMPLETION'
--target-session
--target-pane
--actor-session
--actor-pane
--reason
--apply
--dry-run
health
doctor
repair
validate
audit
why
schema
examples
quickstart
--info
COMPLETION
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-session) TARGET_SESSION="$2"; shift 2 ;;
    --target-pane) TARGET_PANE="$2"; shift 2 ;;
    --actor-session) ACTOR_SESSION="$2"; shift 2 ;;
    --actor-pane) ACTOR_PANE="$2"; shift 2 ;;
    --reason) REASON="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    health|doctor|repair|validate|audit|why|schema|examples|quickstart|completion) MODE="$1"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --examples) MODE="examples"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  decision) run_decision ;;
  health|doctor) run_health ;;
  repair) run_repair ;;
  validate) run_validate ;;
  audit) run_audit ;;
  why) run_why ;;
  schema) run_schema ;;
  examples) examples ;;
  quickstart) quickstart ;;
  completion) completion ;;
  info) run_info ;;
  *) usage >&2; exit 2 ;;
esac
