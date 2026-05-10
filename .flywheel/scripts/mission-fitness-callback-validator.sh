#!/usr/bin/env bash
set -euo pipefail

VERSION="mission-fitness-callback-validator.v1"
REPO="${MISSION_FITNESS_CALLBACK_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)}"
LOG_PATH="${MISSION_FITNESS_CALLBACK_LOG:-}"
DISPATCH_LOG="${MISSION_FITNESS_DISPATCH_LOG:-}"
ALERT_LOG="${MISSION_FITNESS_DRIFT_ALERT_LOG:-$HOME/.local/state/flywheel/peer-orch-drift-alerts.jsonl}"
JSON_OUT=0
APPLY=0
DRY_RUN=1
EXPLAIN=0
CALLBACK_TEXT=""
CALLBACK_FILE=""
COMMAND="validate"
WHY_ID=""
WIDTH=100
ARGS=()

usage() {
  cat <<'EOF'
usage: mission-fitness-callback-validator.sh [validate] (--callback TEXT|--callback-file PATH|CALLBACK_OR_FILE) [options]

Commands:
  validate     Validate one DONE/BLOCKED callback (default).
  doctor       Diagnose validator inputs and ledgers.
  health       Lightweight health probe.
  repair       Dry-run-only repair planner.
  audit        Print recent validation decisions.
  why ID       Print validation decisions for a task id.
  --info       Print CLI info.
  --examples   Print callback examples.
  --schema     Print decision schema.
  quickstart   Print a short operator workflow.
  help [topic] Print topic help.
  completion <bash|zsh>

Options:
  --repo PATH
  --callback TEXT
  --callback-file PATH
  --dispatch-log PATH
  --log PATH
  --alert-log PATH
  --dry-run
  --apply
  --json
  --explain
  --no-color --no-emoji --width N

Exit codes: 0=accept, 1=warn_infra_recursion, 2=reject_malformed, 3=reject_drift.
EOF
}

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

repo_defaults() {
  REPO="$(cd "$REPO" 2>/dev/null && pwd -P || printf '%s\n' "$REPO")"
  LOG_PATH="${LOG_PATH:-$REPO/.flywheel/callback-validation-log.jsonl}"
  DISPATCH_LOG="${DISPATCH_LOG:-$REPO/.flywheel/dispatch-log.jsonl}"
}

json_or_text() {
  local json="$1" text="$2"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$json" | jq -cS .
  else
    printf '%s\n' "$text"
  fi
}

info() {
  repo_defaults
  jq -ncS \
    --arg schema "$VERSION.info" \
    --arg command "info" \
    --arg name "mission-fitness-callback-validator" \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg log "$LOG_PATH" \
    --arg dispatch_log "$DISPATCH_LOG" \
    --arg alert_log "$ALERT_LOG" \
    '{schema_version:$schema,command:$command,name:$name,version:$version,repo:$repo,paths:{validation_log:$log,dispatch_log:$dispatch_log,drift_alert_log:$alert_log},required_callback_fields:["task_id","mission_fitness","mission_fitness_evidence","journey_entry_path"],valid_mission_fitness:["direct","adjacent","infrastructure","drift"]}'
}

schema_json() {
  jq -ncS '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    schema_version:"mission-fitness-callback-decision.schema.v1",
    title:"mission fitness callback validator decision",
    type:"object",
    required:["schema_version","decision","task_id","mission_fitness","evidence","evidence_class"],
    properties:{
      schema_version:{const:"mission-fitness-callback-decision.v1"},
      decision:{enum:["accept","reject_malformed","reject_drift","warn_infra_recursion"]},
      task_id:{type:["string","null"]},
      mission_fitness:{enum:["direct","adjacent","infrastructure","drift",null]},
      evidence:{type:["string","null"]},
      evidence_class:{enum:["bead_id","artifact","sentence","missing"]},
      missing_fields:{type:"array",items:{type:"string"}},
      log_written:{type:"boolean"},
      dispatch_log_updated:{type:"integer"},
      drift_alert_written:{type:"boolean"}
    }
  }'
}

examples() {
  jq -ncS '{
    schema_version:"mission-fitness-callback-validator.examples.v1",
    command:"examples",
    examples:[
      {name:"accept",callback:"DONE task_id=flywheel-abc mission_fitness=direct mission_fitness_evidence=flywheel-abc"},
      {name:"reject_malformed",callback:"DONE task_id=flywheel-missing mission_fitness=direct"},
      {name:"reject_drift",callback:"DONE task_id=flywheel-drift mission_fitness=drift mission_fitness_evidence=off_mission_peer_orch_close"}
    ]
  }'
}

quickstart() {
  jq -ncS '{
    schema_version:"mission-fitness-callback-validator.quickstart.v1",
    command:"quickstart",
    steps:[
      "Build the exact DONE/BLOCKED callback line before close.",
      "Run this validator with --dry-run --json first when debugging.",
      "Run with --apply --json in close-handler paths to persist the decision.",
      "Treat any decision other than accept as close-refusing.",
      "Use audit or why <task_id> to inspect prior decisions."
    ]
  }'
}

topic_help() {
  local topic="${1:-overview}"
  jq -ncS --arg topic "$topic" '{
    schema_version:"mission-fitness-callback-validator.help.v1",
    command:"help",
    topic:$topic,
    text:"Validates mission_fitness callback fields, writes callback-validation-log.jsonl on --apply, enriches matching dispatch-log rows, and writes peer-orch drift alerts for mission_fitness=drift."
  }'
}

completion() {
  case "${1:-}" in
    --help|-h|"") printf 'usage: mission-fitness-callback-validator.sh completion <bash|zsh>\n' ;;
    bash) printf 'complete -W "validate doctor health repair audit why quickstart help completion --info --examples --schema --repo --callback --callback-file --dispatch-log --log --alert-log --dry-run --apply --json --explain" mission-fitness-callback-validator.sh\n' ;;
    zsh) printf 'compadd -- validate doctor health repair audit why quickstart help completion --info --examples --schema --repo --callback --callback-file --dispatch-log --log --alert-log --dry-run --apply --json --explain\n' ;;
    *) printf 'unsupported shell: %s\n' "$1" >&2; exit 2 ;;
  esac
}

field_value() {
  local key="$1" text="$2" re
  re='(^|[[:space:]])'"$key"'="([^"]*)"'
  if [[ "$text" =~ $re ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
    return 0
  fi
  re='(^|[[:space:]])'"$key"'=([^[:space:]]+)'
  if [[ "$text" =~ $re ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
  fi
}

evidence_class() {
  local value="$1"
  if [[ -z "$value" ]]; then
    printf 'missing\n'
  elif [[ "$value" =~ ^(flywheel|bd|br)-[A-Za-z0-9_.-]+$ ]]; then
    printf 'bead_id\n'
  elif [[ "$value" == */* || "$value" == *.md || "$value" == *.json || "$value" == *.jsonl ]]; then
    printf 'artifact\n'
  else
    printf 'sentence\n'
  fi
}

read_callback() {
  if [[ -n "$CALLBACK_FILE" ]]; then
    CALLBACK_TEXT="$(<"$CALLBACK_FILE")"
  elif [[ "${#ARGS[@]}" -gt 0 ]]; then
    if [[ "${#ARGS[@]}" -eq 1 && -f "${ARGS[0]}" ]]; then
      CALLBACK_TEXT="$(<"${ARGS[0]}")"
    else
      CALLBACK_TEXT="${ARGS[*]}"
    fi
  elif [[ -z "$CALLBACK_TEXT" && ! -t 0 ]]; then
    CALLBACK_TEXT="$(cat)"
  fi
  CALLBACK_TEXT="${CALLBACK_TEXT//$'\n'/ }"
}

missing_json() {
  if [[ "$#" -eq 0 ]]; then
    printf '[]\n'
  else
    printf '%s\n' "$@" | jq -R . | jq -cs .
  fi
}

last_five_infra() {
  [[ -s "$LOG_PATH" ]] || return 1
  local count infra
  count="$(tail -n 5 "$LOG_PATH" | jq -r 'select(.mission_fitness? != null) | .mission_fitness' 2>/dev/null | wc -l | tr -d ' ')"
  infra="$(tail -n 5 "$LOG_PATH" | jq -r 'select(.mission_fitness? == "infrastructure") | .mission_fitness' 2>/dev/null | wc -l | tr -d ' ')"
  [[ "$count" -ge 5 && "$infra" -ge 5 ]]
}

append_jsonl() {
  local path="$1" row="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$row" | jq -cS . >>"$path"
}

update_dispatch_log() {
  local task_id="$1" fitness="$2" evidence="$3" eclass="$4" decision="$5" ts="$6" tmp count=0 line updated
  [[ -f "$DISPATCH_LOG" ]] || { printf '0\n'; return 0; }
  tmp="$(mktemp "${DISPATCH_LOG}.XXXXXX")"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if jq -e . >/dev/null 2>&1 <<<"$line"; then
      if [[ "$(jq -r '.task_id // empty' <<<"$line")" == "$task_id" ]]; then
        updated="$(jq -cS \
          --arg fitness "$fitness" \
          --arg evidence "$evidence" \
          --arg eclass "$eclass" \
          --arg decision "$decision" \
          --arg ts "$ts" \
          '. + {mission_fitness:$fitness, mission_fitness_evidence:$evidence, mission_fitness_evidence_class:$eclass, mission_fitness_validator_decision:$decision, mission_fitness_callback_validated_at:$ts}' <<<"$line")"
        printf '%s\n' "$updated" >>"$tmp"
        count=$((count + 1))
      else
        printf '%s\n' "$line" >>"$tmp"
      fi
    else
      printf '%s\n' "$line" >>"$tmp"
    fi
  done <"$DISPATCH_LOG"
  mv "$tmp" "$DISPATCH_LOG"
  printf '%s\n' "$count"
}

build_decision() {
  repo_defaults
  read_callback
  local text="$CALLBACK_TEXT" task_id fitness evidence eclass decision rc ts missing=() missing_j drift_alert=false dispatch_updates=0 log_written=false
  task_id="$(field_value task_id "$text" || true)"
  fitness="$(field_value mission_fitness "$text" || true)"
  evidence="$(field_value mission_fitness_evidence "$text" || true)"
  journey_entry_path="$(field_value journey_entry_path "$text" || true)"
  br_close="$(field_value br_close_executed "$text" || true)"
  [[ -n "$task_id" ]] || missing+=("task_id")
  [[ -n "$fitness" ]] || missing+=("mission_fitness")
  [[ -n "$evidence" ]] || missing+=("mission_fitness_evidence")
  if [[ -n "$fitness" && ! "$fitness" =~ ^(direct|adjacent|infrastructure|drift)$ ]]; then
    missing+=("mission_fitness_valid_value")
  fi
  # journey_entry_path is required on DONE callbacks (br_close_executed=yes).
  # BLOCKED/DECLINED callbacks set br_close_executed=not_applicable and are
  # exempt — the bead remains open and the journey entry will be authored at
  # the eventual DONE close.
  if [[ "$br_close" == "yes" ]]; then
    [[ -n "$journey_entry_path" ]] || missing+=("journey_entry_path")
    if [[ -n "$journey_entry_path" && ! "$journey_entry_path" =~ \.flywheel/journal/.+\.md$ ]]; then
      missing+=("journey_entry_path_canonical_form")
    fi
  fi
  eclass="$(evidence_class "$evidence")"
  if [[ "${#missing[@]}" -gt 0 ]]; then
    decision="reject_malformed"; rc=2
  elif [[ "$fitness" == "drift" ]]; then
    decision="reject_drift"; rc=3
  elif [[ "$fitness" == "infrastructure" ]] && last_five_infra; then
    decision="warn_infra_recursion"; rc=1
  else
    decision="accept"; rc=0
  fi
  ts="$(now_iso)"
  if [[ "${#missing[@]}" -eq 0 ]]; then
    missing_j="[]"
  else
    missing_j="$(missing_json "${missing[@]}")"
  fi
  local row
  row="$(jq -ncS \
    --arg schema "mission-fitness-callback-decision.v1" \
    --arg ts "$ts" \
    --arg decision "$decision" \
    --arg task_id "$task_id" \
    --arg fitness "$fitness" \
    --arg evidence "$evidence" \
    --arg eclass "$eclass" \
    --arg repo "$REPO" \
    --arg callback "$text" \
    --argjson missing "$missing_j" \
    --argjson apply "$APPLY" \
    --argjson dry "$DRY_RUN" \
    '{schema_version:$schema,ts:$ts,decision:$decision,task_id:($task_id // null),mission_fitness:($fitness // null),evidence:($evidence // null),evidence_class:$eclass,missing_fields:$missing,repo:$repo,callback_b64:($callback|@base64),apply:$apply,dry_run:$dry,log_written:false,dispatch_log_updated:0,drift_alert_written:false,l112_observed:"OK_mission_fitness_callback_validator"}')"
  if [[ "$APPLY" -eq 1 ]]; then
    log_written=true
    if [[ -n "$task_id" ]]; then
      dispatch_updates="$(update_dispatch_log "$task_id" "$fitness" "$evidence" "$eclass" "$decision" "$ts")"
    fi
    if [[ "$decision" == "reject_drift" ]]; then
      local alert
      alert="$(jq -ncS --arg ts "$ts" --arg task_id "$task_id" --arg evidence "$evidence" '{schema_version:"peer-orch-drift-alert.v1",ts:$ts,source:"mission-fitness-callback-validator",task_id:$task_id,mission_fitness:"drift",evidence:$evidence,state:"open"}')"
      append_jsonl "$ALERT_LOG" "$alert"
      drift_alert=true
    fi
  fi
  row="$(jq -cS \
    --argjson log_written "$log_written" \
    --argjson dispatch_updates "$dispatch_updates" \
    --argjson drift_alert "$drift_alert" \
    '. + {log_written:$log_written,dispatch_log_updated:$dispatch_updates,drift_alert_written:$drift_alert}' <<<"$row")"
  if [[ "$APPLY" -eq 1 ]]; then
    append_jsonl "$LOG_PATH" "$row"
  fi
  if [[ "$EXPLAIN" -eq 1 ]]; then
    printf 'mission-fitness decision=%s task_id=%s fitness=%s evidence_class=%s\n' "$decision" "${task_id:-null}" "${fitness:-null}" "$eclass" >&2
  fi
  printf '%s\n' "$row"
  return "$rc"
}

doctor() {
  repo_defaults
  local status="pass"
  [[ -d "$REPO/.flywheel" ]] || status="warn"
  jq -ncS --arg status "$status" --arg repo "$REPO" --arg log "$LOG_PATH" --arg dispatch_log "$DISPATCH_LOG" --arg alert_log "$ALERT_LOG" '{schema_version:"mission-fitness-callback-validator.doctor.v1",command:"doctor",status:$status,repo:$repo,subsystems:{repo:{exists:($repo|length>0)},validation_log:{path:$log,exists:false},dispatch_log:{path:$dispatch_log},drift_alert_log:{path:$alert_log}}}'
}

health() {
  repo_defaults
  local status="pass"
  [[ -f "$DISPATCH_LOG" ]] || status="warn"
  jq -ncS --arg status "$status" --arg repo "$REPO" '{schema_version:"mission-fitness-callback-validator.health.v1",command:"health",status:$status,repo:$repo}'
}

repair() {
  repo_defaults
  jq -ncS --arg repo "$REPO" --arg log "$LOG_PATH" --arg dispatch_log "$DISPATCH_LOG" '{schema_version:"mission-fitness-callback-validator.repair.v1",command:"repair",status:"dry_run",dry_run:true,repo:$repo,planned_actions:["mkdir -p validation log directory","validate dispatch-log JSONL before apply"],would_write:[$log,$dispatch_log],blocked_by:[]}'
}

audit() {
  repo_defaults
  if [[ -s "$LOG_PATH" ]]; then
    tail -n 20 "$LOG_PATH" | jq -s -cS '{schema_version:"mission-fitness-callback-validator.audit.v1",command:"audit",decisions:.}'
  else
    jq -ncS '{schema_version:"mission-fitness-callback-validator.audit.v1",command:"audit",decisions:[]}'
  fi
}

why() {
  repo_defaults
  local id="$WHY_ID"
  if [[ -s "$LOG_PATH" ]]; then
    jq -cS --arg id "$id" 'select(.task_id == $id)' "$LOG_PATH" | jq -s -cS --arg id "$id" '{schema_version:"mission-fitness-callback-validator.why.v1",command:"why",task_id:$id,decisions:.}'
  else
    jq -ncS --arg id "$id" '{schema_version:"mission-fitness-callback-validator.why.v1",command:"why",task_id:$id,decisions:[]}'
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    validate|doctor|health|repair|audit|quickstart) COMMAND="$1"; shift ;;
    why) COMMAND="why"; WHY_ID="${2:-}"; shift 2 ;;
    help) COMMAND="help"; WHY_ID="${2:-overview}"; shift; [[ $# -gt 0 && "${1:-}" != --* ]] && shift || true ;;
    completion) COMMAND="completion"; WHY_ID="${2:-}"; shift; [[ $# -gt 0 && "${1:-}" != --* ]] && shift || true ;;
    --info) COMMAND="info"; shift ;;
    --examples) COMMAND="examples"; shift ;;
    --schema) COMMAND="schema"; shift ;;
    -h|--help) usage; exit 0 ;;
    --repo) REPO="${2:?--repo requires path}"; shift 2 ;;
    --callback) CALLBACK_TEXT="${2:?--callback requires text}"; shift 2 ;;
    --callback-file) CALLBACK_FILE="${2:?--callback-file requires path}"; shift 2 ;;
    --dispatch-log) DISPATCH_LOG="${2:?--dispatch-log requires path}"; shift 2 ;;
    --log) LOG_PATH="${2:?--log requires path}"; shift 2 ;;
    --alert-log) ALERT_LOG="${2:?--alert-log requires path}"; shift 2 ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --explain) EXPLAIN=1; shift ;;
    --no-color|--no-emoji) shift ;;
    --width) WIDTH="${2:-100}"; shift 2 ;;
    --idempotency-key) shift 2 ;;
    --) shift; ARGS+=("$@"); break ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

case "$COMMAND" in
  validate)
    set +e
    out="$(build_decision)"
    rc=$?
    set -e
    json_or_text "$out" "$(jq -r '"decision=\(.decision) task_id=\(.task_id // "null") mission_fitness=\(.mission_fitness // "null")"' <<<"$out")"
    exit "$rc"
    ;;
  doctor) out="$(doctor)"; json_or_text "$out" "mission-fitness-callback-validator doctor"; [[ "$(jq -r '.status' <<<"$out")" == "pass" ]] || exit 1 ;;
  health) out="$(health)"; json_or_text "$out" "mission-fitness-callback-validator health"; [[ "$(jq -r '.status' <<<"$out")" == "pass" ]] || exit 1 ;;
  repair) out="$(repair)"; json_or_text "$out" "mission-fitness-callback-validator repair dry-run" ;;
  audit) out="$(audit)"; json_or_text "$out" "$(jq -r '"decisions=\(.decisions|length)"' <<<"$out")" ;;
  why) out="$(why)"; json_or_text "$out" "$(jq -r '"task_id=\(.task_id) decisions=\(.decisions|length)"' <<<"$out")" ;;
  info) info | { if [[ "$JSON_OUT" -eq 1 ]]; then jq -cS .; else jq .; fi; } ;;
  examples) examples | { if [[ "$JSON_OUT" -eq 1 ]]; then jq -cS .; else jq -r '.examples[] | "# \(.name)\n\(.callback)\n"'; fi; } ;;
  schema) schema_json | { if [[ "$JSON_OUT" -eq 1 ]]; then jq -cS .; else jq .; fi; } ;;
  quickstart) quickstart | { if [[ "$JSON_OUT" -eq 1 ]]; then jq -cS .; else jq -r '.steps[]'; fi; } ;;
  help) topic_help "$WHY_ID" | { if [[ "$JSON_OUT" -eq 1 ]]; then jq -cS .; else jq -r '.text'; fi; } ;;
  completion) completion "$WHY_ID" ;;
  *) usage >&2; exit 2 ;;
esac
