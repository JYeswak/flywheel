#!/usr/bin/env bash
# cross-session-worker-borrow.sh — dry-run dispatcher + protocol
# enforcer for the team-roster B06 cross-session worker borrowing
# protocol. See `.flywheel/doctrine/cross-session-worker-borrow-protocol.md`
# for the full specification.
#
# Owns: bead flywheel-cgjo. Sister: flywheel-4vg3 (B05 roster-resolved
# Agent Mail notify). Default mode is `--dry-run`; live `--apply`
# borrow execution is out-of-scope for this bead (it belongs to a
# B05 follow-up implementation bead).
#
# Stable exit codes: 0 ok | 1 domain | 64 usage | 77 missing dep
# Triad: doctor / info / schema; --json default for robot consumers.

set -uo pipefail

VERSION="cross-session-worker-borrow.v1"
SCRIPT_VERSION="2026-05-09.1"

ROSTER_LEDGER="${BORROW_ROSTER_LEDGER:-$HOME/.local/state/flywheel/team-roster.jsonl}"
LEDGER="${BORROW_LEDGER:-$HOME/.local/state/flywheel/cross-session-worker-borrow.jsonl}"
PULSE_MAX_AGE="${BORROW_PULSE_MAX_AGE:-300}"          # seconds
DEFAULT_TTL_MIN="${BORROW_TTL_MINUTES:-60}"
DEFAULT_WINDOW_MIN="${BORROW_WINDOW_MINUTES:-60}"
NTM_BIN="${NTM_BIN:-$HOME/.local/bin/ntm}"
PROTECTED_PATTERN="${BORROW_PROTECTED_PATTERN:-^client_|^protected_}"

MODE="run"        # run | check-eligibility | release | list | doctor | info | schema
ACTION=""         # request | release | list
JSON_OUT=0
DRY_RUN=1
APPLY=0
REQUESTOR_SESSION=""
REQUESTOR_PANE="1"
TARGET_SESSION=""
TARGET_PANE=""
TASK_ID=""
TASK_SHA256=""
BORROW_ID=""
TTL_MIN=""
WINDOW_MIN=""
FIXTURE=""

usage() {
  cat <<'USAGE'
Usage:
  cross-session-worker-borrow.sh --request \
      --requestor <session> [--requestor-pane N] \
      --target <session> --target-pane N \
      --task-id <id> [--task-sha256 <sha>] \
      [--ttl-minutes 60] [--window-minutes 60] \
      [--apply] [--json] [--from-fixture <path>]
  cross-session-worker-borrow.sh --check-eligibility --target <session> --target-pane N [--json]
  cross-session-worker-borrow.sh --release --borrow-id <id> [--apply] [--json]
  cross-session-worker-borrow.sh --list [--target <session>] [--json]
  cross-session-worker-borrow.sh --doctor [--json]
  cross-session-worker-borrow.sh --info [--json]
  cross-session-worker-borrow.sh --schema [--json]
  cross-session-worker-borrow.sh --help

Cross-session worker borrowing protocol enforcer (B06). Default is
--dry-run (no ledger write, no Agent Mail, no NTM dispatch). Use
--apply only when the Joshua-approved borrow flow is wired (out of
scope for flywheel-cgjo; live borrowing belongs to a B05 follow-up).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --request) ACTION="request"; shift ;;
    --check-eligibility) ACTION="check-eligibility"; shift ;;
    --release) ACTION="release"; shift ;;
    --list) ACTION="list"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --requestor) REQUESTOR_SESSION="${2:?}"; shift 2 ;;
    --requestor=*) REQUESTOR_SESSION="${1#*=}"; shift ;;
    --requestor-pane) REQUESTOR_PANE="${2:?}"; shift 2 ;;
    --requestor-pane=*) REQUESTOR_PANE="${1#*=}"; shift ;;
    --target) TARGET_SESSION="${2:?}"; shift 2 ;;
    --target=*) TARGET_SESSION="${1#*=}"; shift ;;
    --target-pane) TARGET_PANE="${2:?}"; shift 2 ;;
    --target-pane=*) TARGET_PANE="${1#*=}"; shift ;;
    --task-id) TASK_ID="${2:?}"; shift 2 ;;
    --task-id=*) TASK_ID="${1#*=}"; shift ;;
    --task-sha256) TASK_SHA256="${2:?}"; shift 2 ;;
    --task-sha256=*) TASK_SHA256="${1#*=}"; shift ;;
    --borrow-id) BORROW_ID="${2:?}"; shift 2 ;;
    --borrow-id=*) BORROW_ID="${1#*=}"; shift ;;
    --ttl-minutes) TTL_MIN="${2:?}"; shift 2 ;;
    --window-minutes) WINDOW_MIN="${2:?}"; shift 2 ;;
    --from-fixture) FIXTURE="${2:?}"; shift 2 ;;
    --from-fixture=*) FIXTURE="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "cross-session-worker-borrow.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() {
  if [[ $JSON_OUT -eq 1 || $MODE == "info" || $MODE == "schema" || $MODE == "doctor" ]]; then
    printf '%s\n' "$1"
  fi
}

# Resolve fixture-or-live for the latest roster row of <session>
roster_row() {
  local session="$1"
  if [[ -n "$FIXTURE" && -f "$FIXTURE" ]]; then
    jq -c --arg s "$session" 'select(.kind=="roster" and .session==$s) | .row' "$FIXTURE" 2>/dev/null | tail -1
    return
  fi
  if [[ -f "$ROSTER_LEDGER" ]]; then
    grep -F "\"session\":\"$session\"" "$ROSTER_LEDGER" 2>/dev/null | tail -1
  fi
}

# Resolve fixture-or-live pane state for <session> pane <N>
pane_state() {
  local session="$1" pane="$2"
  if [[ -n "$FIXTURE" && -f "$FIXTURE" ]]; then
    jq -c --arg s "$session" --argjson p "$pane" \
      'select(.kind=="pane" and .session==$s and .pane==$p) | .state' "$FIXTURE" 2>/dev/null \
      | tr -d '"' | tail -1
    return
  fi
  if [[ -x "$NTM_BIN" ]]; then
    "$NTM_BIN" --robot-activity="$session" --activity-type=codex,claude 2>/dev/null \
      | jq -r --argjson p "$pane" \
        '(.agents // [])[] | select((.pane|tonumber? // 0) == $p) | .state // "UNKNOWN"' \
      | tail -1
  else
    echo "UNKNOWN"
  fi
}

# Idempotent borrow_id hash
borrow_id_for() {
  local r="$1" t="$2" tp="$3" tsha="$4" win="$5"
  printf 'borrow:%s:%s:%s:%s:%s' "$r" "$t" "$tp" "$tsha" "$win" \
    | shasum -a 256 | awk '{print substr($1,1,16)}'
}

# Existing non-terminal row for a borrow_id?
existing_borrow() {
  local id="$1"
  local term="released|refused|timed_out|declined|reclaimed_pre_approve|reclaimed_in_use|worker_died"
  if [[ -f "$LEDGER" ]]; then
    grep -F "\"borrow_id\":\"$id\"" "$LEDGER" 2>/dev/null \
      | jq -sc --arg term "released refused timed_out declined reclaimed_pre_approve reclaimed_in_use worker_died" '
          map(select(.borrow_id != null))
          | (map(.state) | reverse)
          | (map(select(. != null)) | first // null)' 2>/dev/null
  fi
}

eligibility_check() {
  local target="$1" pane="$2"
  local row tier avail max_b borrow_count pulse_age pane_st pulse_ts now_epoch
  row=$(roster_row "$target")
  if [[ -z "$row" ]]; then
    jq -nc --arg target "$target" --arg pane "$pane" \
      '{eligible:false,reason:"target_not_in_roster",target:$target,target_pane:($pane|tonumber? // null)}'
    return
  fi
  tier=$(printf '%s' "$row" | jq -r '.tier // (.client | if . then "client_"+. else "" end)' | head -1 | tr -d '\n')
  avail=$(printf '%s' "$row" | jq -r '.available_for_borrow // false' | head -1 | tr -d '\n')
  max_b=$(printf '%s' "$row" | jq -r '.max_borrow_workers // 0' | head -1 | tr -d '[:space:]')
  case "$max_b" in ''|*[!0-9]*) max_b=0 ;; esac
  pulse_ts=$(printf '%s' "$row" | jq -r '.ts // empty')
  pane_st=$(pane_state "$target" "$pane")
  now_epoch=$(date -u +%s)
  if [[ -n "$pulse_ts" ]]; then
    local pulse_epoch
    pulse_epoch=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$pulse_ts" '+%s' 2>/dev/null \
                  || date -u -d "$pulse_ts" '+%s' 2>/dev/null || echo 0)
    pulse_age=$((now_epoch - pulse_epoch))
  else
    pulse_age=999999
  fi
  borrow_count=0
  if [[ -f "$LEDGER" ]]; then
    borrow_count=$(grep -F "\"target_session\":\"$target\"" "$LEDGER" 2>/dev/null \
      | jq -sc 'map(select(.state == "approved" or .state == "in_use")) | length' 2>/dev/null \
      | head -1 | tr -d '[:space:]' || echo 0)
    [[ -z "$borrow_count" ]] && borrow_count=0
    case "$borrow_count" in ''|*[!0-9]*) borrow_count=0 ;; esac
  fi

  local reason=""
  local ok=true
  if [[ "$pulse_age" -gt "$PULSE_MAX_AGE" ]]; then ok=false; reason="pulse_stale"; fi
  if [[ "$avail" != "true" ]]; then ok=false; reason="${reason:-not_available_for_borrow}"; fi
  if [[ "$max_b" -le 0 || "$borrow_count" -ge "$max_b" ]]; then
    ok=false; reason="${reason:-at_max_borrow_workers}"
  fi
  if [[ "$pane_st" == "DEAD" || "$pane_st" == "UNKNOWN" || -z "$pane_st" ]]; then
    ok=false; reason="${reason:-target_pane_dead}"
  fi
  local override
  override=$(printf '%s' "$row" | jq -r '.borrow_policy_override // "none"')
  if [[ "$override" != "explicit_lend_ok" ]]; then
    if [[ -n "$tier" ]] && [[ "$tier" =~ $PROTECTED_PATTERN ]]; then
      ok=false
      if [[ "$tier" =~ ^client_ ]]; then
        reason="${reason:-client_tier_no_override}"
      else
        reason="${reason:-protected_session_no_override}"
      fi
    fi
  fi
  jq -nc \
    --arg target "$target" \
    --argjson pane "$pane" \
    --argjson eligible "$ok" \
    --arg reason "${reason:-eligible}" \
    --arg tier "$tier" \
    --argjson avail "$avail" \
    --argjson max_b "$max_b" \
    --argjson borrow_count "$borrow_count" \
    --argjson pulse_age "$pulse_age" \
    --arg pane_st "$pane_st" \
    --arg override "$override" \
    '{eligible:$eligible,reason:$reason,target:$target,target_pane:$pane,
      policy_check:{tier:$tier,available_for_borrow:$avail,max_borrow_workers:$max_b,
        currently_borrowed_count:$borrow_count,pulse_age_seconds:$pulse_age,
        pane_state:$pane_st,borrow_policy_override:$override}}'
}

write_row() {
  local row="$1"
  if [[ $APPLY -eq 1 ]]; then
    mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
    printf '%s\n' "$row" >> "$LEDGER" 2>/dev/null
  fi
}

action_request() {
  local ttl="${TTL_MIN:-$DEFAULT_TTL_MIN}"
  local window="${WINDOW_MIN:-$DEFAULT_WINDOW_MIN}"
  local tsha="${TASK_SHA256:-$(printf '%s' "$TASK_ID" | shasum -a 256 | awk '{print $1}')}"
  local id
  id=$(borrow_id_for "$REQUESTOR_SESSION" "$TARGET_SESSION" "$TARGET_PANE" "$tsha" "$window")

  local existing
  existing=$(existing_borrow "$id")
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    local state="${existing//\"/}"
    if [[ "$state" != "released" && "$state" != "refused" && "$state" != "timed_out" \
         && "$state" != "declined" && "$state" != "reclaimed_pre_approve" \
         && "$state" != "reclaimed_in_use" && "$state" != "worker_died" ]]; then
      emit "$(jq -nc \
        --arg id "$id" --arg state "$state" \
        '{action:"request",borrow_id:$id,state:$state,reason:"idempotency_collision",new_row_written:false}')"
      return 0
    fi
  fi

  local elig
  elig=$(eligibility_check "$TARGET_SESSION" "$TARGET_PANE")
  local elig_ok elig_reason
  elig_ok=$(printf '%s' "$elig" | jq -r '.eligible')
  elig_reason=$(printf '%s' "$elig" | jq -r '.reason')

  local final_state="requested"
  if [[ "$elig_ok" != "true" ]]; then
    final_state="refused"
  fi

  local row
  row=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg id "$id" \
    --arg state "$final_state" \
    --arg rs "$REQUESTOR_SESSION" \
    --argjson rp "$REQUESTOR_PANE" \
    --arg ts_target "$TARGET_SESSION" \
    --argjson tp "$TARGET_PANE" \
    --arg task_id "$TASK_ID" \
    --arg task_sha "$tsha" \
    --argjson ttl "$ttl" \
    --arg reason "$elig_reason" \
    --argjson policy "$(printf '%s' "$elig" | jq '.policy_check')" \
    '{schema_version:"cross-session-worker-borrow/v1",
      ts:$ts,borrow_id:$id,state:$state,
      requestor_session:$rs,requestor_pane:$rp,
      target_session:$ts_target,target_pane:$tp,
      task_id:$task_id,task_sha256:$task_sha,
      ttl_minutes:$ttl,reason:$reason,policy_check:$policy}')

  write_row "$row"
  emit "$(printf '%s' "$row" | jq -c \
    --argjson written "$APPLY" \
    --arg dry_run "$([[ $DRY_RUN -eq 1 ]] && echo true || echo false)" \
    '. + {action:"request",new_row_written:($written==1),dry_run:($dry_run=="true")}')"
}

action_release() {
  if [[ -z "$BORROW_ID" ]]; then
    echo "cross-session-worker-borrow.sh: --release requires --borrow-id" >&2
    exit 64
  fi
  local row
  row=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg id "$BORROW_ID" \
    '{schema_version:"cross-session-worker-borrow/v1",
      ts:$ts,borrow_id:$id,state:"released",reason:"task_complete"}')
  write_row "$row"
  emit "$(printf '%s' "$row" | jq -c \
    --argjson written "$APPLY" \
    --arg dry_run "$([[ $DRY_RUN -eq 1 ]] && echo true || echo false)" \
    '. + {action:"release",new_row_written:($written==1),dry_run:($dry_run=="true")}')"
}

action_list() {
  if [[ ! -f "$LEDGER" ]]; then
    emit '{"action":"list","rows":[],"summary":{},"empty":true}'
    return 0
  fi
  emit "$(jq -sc '
    {action:"list", rows: ., summary: (group_by(.state) | map({state: .[0].state, count: length}))}
  ' "$LEDGER")"
}

info_payload() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg roster "$ROSTER_LEDGER" \
    --arg ledger "$LEDGER" \
    --arg ntm "$NTM_BIN" \
    --argjson pulse_max "$PULSE_MAX_AGE" \
    --argjson ttl "$DEFAULT_TTL_MIN" \
    --argjson window "$DEFAULT_WINDOW_MIN" \
    '{
      version: $version, script_version: $script_version,
      schema_version: "cross-session-worker-borrow/v1",
      mode: "info",
      roster_ledger: $roster, borrow_ledger: $ledger, ntm_bin: $ntm,
      pulse_max_age_seconds: $pulse_max,
      default_ttl_minutes: $ttl,
      default_window_minutes: $window,
      actions: ["request","check-eligibility","release","list"],
      modes: ["run","doctor","info","schema"],
      owns: "flywheel-cgjo",
      doctrine: ".flywheel/doctrine/cross-session-worker-borrow-protocol.md",
      sister: "flywheel-4vg3",
      status: "ok"
    }'
}

schema_payload() {
  jq -nc '{
    schema_version: "cross-session-worker-borrow/v1",
    state_machine: {
      states: ["requested","approved","in_use","released","refused","timed_out","declined","reclaimed_pre_approve","reclaimed_in_use","worker_died"],
      terminal: ["refused","timed_out","declined","reclaimed_pre_approve","released","reclaimed_in_use","worker_died"],
      non_terminal: ["requested","approved","in_use"]
    },
    refusal_reasons: ["pulse_stale","not_available_for_borrow","at_max_borrow_workers","target_pane_dead","protected_session_no_override","client_tier_no_override","idempotency_collision","worker_death_mid_borrow"],
    ledger_row_required_fields: ["schema_version","ts","borrow_id","state","requestor_session","requestor_pane","target_session","target_pane","task_id","task_sha256","reason"],
    idempotency_key: "sha256(\"borrow:\"+requestor_session+\":\"+target_session+\":\"+target_pane+\":\"+task_sha256+\":\"+window_minutes), truncated 16 chars",
    exit_codes: {"0":"ok","1":"domain","64":"usage","77":"missing_dep"},
    mode: "schema", status: "ok"
  }'
}

doctor_payload() {
  local issues=()
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  command -v shasum >/dev/null 2>&1 || issues+=("shasum_missing")
  [[ -f "$ROSTER_LEDGER" ]] || issues+=("roster_ledger_missing=$ROSTER_LEDGER")
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
  [[ -w "$(dirname "$LEDGER")" ]] || issues+=("borrow_ledger_dir_not_writable=$(dirname "$LEDGER")")
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --argjson issues "$issues_json" \
    '{version:$version,schema_version:"cross-session-worker-borrow/v1",mode:"doctor",issues:$issues,
      status:(if ($issues|length)==0 then "ok" else "degraded" end)}'
}

case "$MODE" in
  info)   emit "$(info_payload)"; exit 0 ;;
  schema) emit "$(schema_payload)"; exit 0 ;;
  doctor)
    payload="$(doctor_payload)"
    emit "$payload"
    [[ "$(printf '%s' "$payload" | jq -r .status)" == "ok" ]] && exit 0 || exit 1
    ;;
esac

case "$ACTION" in
  request)
    [[ -z "$REQUESTOR_SESSION" || -z "$TARGET_SESSION" || -z "$TARGET_PANE" || -z "$TASK_ID" ]] \
      && { echo "missing required: --requestor --target --target-pane --task-id" >&2; exit 64; }
    action_request
    ;;
  check-eligibility)
    [[ -z "$TARGET_SESSION" || -z "$TARGET_PANE" ]] \
      && { echo "missing required: --target --target-pane" >&2; exit 64; }
    emit "$(eligibility_check "$TARGET_SESSION" "$TARGET_PANE")"
    ;;
  release)
    action_release
    ;;
  list)
    action_list
    ;;
  *)
    usage
    exit 64
    ;;
esac
