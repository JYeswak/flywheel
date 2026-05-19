#!/usr/bin/env bash
set -euo pipefail

VERSION="substrate-loop-contract-validator.v1.0.0"
SCHEMA_VERSION="substrate-loop-contract.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${SUBSTRATE_LOOP_CONTRACT_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${SUBSTRATE_LOOP_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
FUCKUP_LOG="${SUBSTRATE_LOOP_CONTRACT_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
PRIMITIVES_FILE="${SUBSTRATE_LOOP_CONTRACT_PRIMITIVES_FILE:-}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"

MODE=""
JSON_OUT=0
APPLY=0
DRY_RUN=1
WATCH=0
WATCH_INTERVAL=5
REPAIR_SCOPE="all"
WHY_ID=""
SCHEMA_TOPIC="contract"
COMPLETION_SHELL=""
VALIDATE_TARGET="ledger"
IDEMPOTENCY_KEY=""
WIDTH=100

usage() {
  cat <<'EOF'
usage:
  substrate-loop-contract-validator.sh --doctor [--json]
  substrate-loop-contract-validator.sh --health [--watch] [--interval N] [--json]
  substrate-loop-contract-validator.sh --repair [--scope self-row|missing-primitives|all] [--dry-run|--apply] [--json]
  substrate-loop-contract-validator.sh validate ledger [--json]
  substrate-loop-contract-validator.sh audit [--json]
  substrate-loop-contract-validator.sh why PRIMITIVE [--json]
  substrate-loop-contract-validator.sh schema contract|doctor|repair [--json]
  substrate-loop-contract-validator.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}

now_iso() {
  printf '%s\n' "${SUBSTRATE_LOOP_CONTRACT_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

info_json() {
  jq -nc \
    --arg name "substrate-loop-contract-validator.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg repo "$REPO_ROOT" \
    --arg ledger "$LEDGER" \
    --arg fuckup_log "$FUCKUP_LOG" \
    --arg jsonl_append_lib "$JSONL_APPEND_LIB" \
    '{name:$name,version:$version,schema_version:$schema_version,repo:$repo,ledger:$ledger,fuckup_log:$fuckup_log,jsonl_append_lib:$jsonl_append_lib,exit_codes:{"0":"all required contracts present","1":"missing or invalid substrate-loop contract rows","2":"usage error","3":"append primitive unavailable or failed"},required_contract_fields:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version","bootstrap_seed_v1"]}'
}

examples_text() {
  cat <<'EOF'
substrate-loop-contract-validator.sh --doctor --json
substrate-loop-contract-validator.sh repair --scope all --dry-run --json
substrate-loop-contract-validator.sh repair --scope all --apply --json
substrate-loop-contract-validator.sh why auto-l112-gate --json
EOF
}

quickstart_text() {
  cat <<'EOF'
1. Run --doctor --json to bootstrap the validator self-row and inspect missing primitive rows.
2. Run repair --dry-run --json to review missing-primitive fuckup rows.
3. Run repair --apply --json to append the self-row and missing-primitive rows.
4. Wire flywheel-loop doctor --scope substrate-loop-contract into close/install checks.
EOF
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    contract)
      jq -nc --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,required:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version","bootstrap_seed_v1"]}' ;;
    doctor)
      jq -nc --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,required:["substrate_loop_contract_self_row_present","substrate_loop_contract_primitives_audited","substrate_loop_contract_primitives_missing","substrate_loop_contract_schema_version"]}' ;;
    repair)
      jq -nc --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,required:["planned_actions","actual_actions","dry_run","apply"]}' ;;
    *)
      echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2
      return 2 ;;
  esac
}

completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_substrate_loop_contract_validator_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--doctor --health --repair --scope --dry-run --apply validate audit why schema --info --examples quickstart help completion --json" -- "$cur") )
}
complete -F _substrate_loop_contract_validator_completion substrate-loop-contract-validator.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --doctor --health --repair --scope --dry-run --apply validate audit why schema --info --examples quickstart help completion --json\n'
      ;;
    *)
      echo "ERR: completion shell must be bash or zsh" >&2
      return 2 ;;
  esac
}

append_validated() {
  local path="$1" row="$2"
  if [[ ! -r "$JSONL_APPEND_LIB" ]]; then
    echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2
    return 3
  fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$path" "$row"
}

rows_json() {
  if [[ -s "$LEDGER" ]]; then
    jq -s -c 'map(select(type == "object"))' "$LEDGER"
  else
    printf '[]\n'
  fi
}

fuckup_rows_json() {
  if [[ -s "$FUCKUP_LOG" ]]; then
    jq -s -c 'map(select(type == "object"))' "$FUCKUP_LOG"
  else
    printf '[]\n'
  fi
}

self_row_json() {
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg schema_version "$SCHEMA_VERSION" \
    '{primitive_name:"substrate-loop-contract-validator",declares_loop:"yes",self_repair_action:"validator --repair --apply",measurement_field:"substrate_loop_contract_self_row_present",escalation_path:"fuckup-log:class=substrate-loop-contract-missing",schema_version:$schema_version,bootstrap_seed_v1:"validator audits itself: this row IS the proof",ts:$ts}'
}

default_primitives_json() {
  if [[ -n "$PRIMITIVES_FILE" ]]; then
    jq -c 'map(if type == "string" then {primitive_name:.} else . end)' "$PRIMITIVES_FILE"
    return
  fi
  cat <<'EOF' | jq -R -s -c '
    split("\n")
    | map(select(length > 0))
    | map(split("|"))
    | map({
        primitive_name:.[0],
        self_repair_action:.[1],
        measurement_field:.[2],
        escalation_path:.[3]
      })
  '
auto-l112-gate|auto-l112-gate.sh --repair --apply|auto_l112_gate_pass_rate_24h|fuckup-log:class=auto-l112-gate-failure
quality-bar-close-gate|quality-bar-close-gate.sh --repair --scope all --apply|plan_state_quality_bar_pending_count|fuckup-log:class=phase5-quality-bar-close-gate
watcher-isomorphic-probe|watcher-isomorphic-probe.sh repair --dry-run|watcher_isomorphic_fleet_status|fuckup-log:class=watcher-isomorphic-red
check-trauma-class-substrate|check-trauma-class-substrate.sh --json|trauma_class_substrate_missing_count|fuckup-log:class=trauma-class-substrate-missing
mission-anchor-dispatch-license|mission-anchor-dispatch-license.sh repair --apply|mission_anchor_license_status|fuckup-log:class=mission-anchor-license-missing
launchctl-guard|flywheel-loop doctor --scope launchctl-guard --json|launchctl_guard_status|fuckup-log:class=launchctl-guard-gap
flywheel-watchers|flywheel-watchers doctor --json|fleet_watcher_coverage_count|fuckup-log:class=watcher-coverage-gap
closed-bead-redispatch-guard|closed-bead-artifact-scan.py --json|closed_bead_artifact_missing_count|fuckup-log:class=closed-bead-artifact-missing
plist-allowlist|flywheel-watchers-allowlist-test.sh|plist_allowlist_status|fuckup-log:class=plist-allowlist-drift
EOF
}

valid_self_row_present() {
  rows_json | jq -e --arg schema "$SCHEMA_VERSION" '
    [ .[] | select(.primitive_name == "substrate-loop-contract-validator") ]
    | last
    | type == "object"
      and .declares_loop == "yes"
      and (.self_repair_action // "") != ""
      and (.measurement_field // "") == "substrate_loop_contract_self_row_present"
      and (.escalation_path // "") != ""
      and .schema_version == $schema
      and (.bootstrap_seed_v1 // "") != ""
  ' >/dev/null
}

ensure_self_row() {
  local row
  if valid_self_row_present; then
    printf 'present\n'
    return 0
  fi
  row="$(self_row_json)"
  append_validated "$LEDGER" "$row"
  printf 'appended\n'
}

audit_payload_json() {
  local bootstrap="${1:-0}" bootstrap_action="not_requested" rows primitives payload
  if [[ "$bootstrap" == "1" ]]; then
    bootstrap_action="$(ensure_self_row)"
  fi
  rows="$(rows_json)"
  primitives="$(default_primitives_json)"
  payload="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg mode "${MODE:-doctor}" \
    --arg ledger "$LEDGER" \
    --arg fuckup_log "$FUCKUP_LOG" \
    --arg repo "$REPO_ROOT" \
    --arg bootstrap_action "$bootstrap_action" \
    --argjson rows "$rows" \
    --argjson primitives "$primitives" '
    def required_ok($r):
      ($r | type) == "object"
      and (($r.primitive_name // "") != "")
      and (($r.declares_loop // "") | IN("yes","no"))
      and (($r.self_repair_action // "") != "")
      and (($r.measurement_field // "") != "")
      and (($r.escalation_path // "") != "")
      and (($r.schema_version // "") == $schema)
      and (($r.bootstrap_seed_v1 // "") != "");
    def latest($name): ([ $rows[] | select((.primitive_name // "") == $name) ] | last);
    ([{primitive_name:"substrate-loop-contract-validator"}] + $primitives | unique_by(.primitive_name)) as $specs
    | ($specs | map(.primitive_name)) as $names
    | [ $names[] as $n | latest($n) as $r | select(($r == null) or (required_ok($r) | not)) | $n ] as $missing
    | [ $names[] as $n | latest($n) as $r | select(($r != null) and (($r.schema_version // "") != $schema)) | $n ] as $drift
    | (latest("substrate-loop-contract-validator") | required_ok(.)) as $self_present
    | {
        mode:$mode,
        status:(if ($self_present and ($missing | length) == 0) then "pass" else "fail" end),
        schema_version:$schema,
        repo:$repo,
        ledger_path:$ledger,
        fuckup_log_path:$fuckup_log,
        bootstrap_action:$bootstrap_action,
        substrate_loop_contract_self_row_present:$self_present,
        substrate_loop_contract_primitives_audited:($names | length),
        substrate_loop_contract_primitives_missing:$missing,
        substrate_loop_contract_primitives_schema_drift:$drift,
        substrate_loop_contract_schema_version:$schema,
        primitives_missing_count:($missing | length),
        primitives_audited:$names,
        rows_seen_count:($rows | length),
        required_contract_fields:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version","bootstrap_seed_v1"],
        missing_primitive_fuckup_class:"substrate-loop-contract-missing"
      }')"
  printf '%s\n' "$payload"
}

missing_fuckup_row_json() {
  local primitive="$1" reason="$2"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg primitive "$primitive" \
    --arg reason "$reason" \
    --arg schema "$SCHEMA_VERSION" \
    '{ts:$ts,trauma_class:"substrate-loop-contract-missing",class:"substrate-loop-contract-missing",severity:"medium",primitive_name:$primitive,schema_version:$schema,what_happened:("substrate primitive lacks a valid " + $schema + " self-row"),reason:$reason,should_become:"bead"}'
}

fuckup_exists() {
  local primitive="$1"
  [[ -s "$FUCKUP_LOG" ]] || return 1
  jq -e --arg primitive "$primitive" --arg schema "$SCHEMA_VERSION" '
    select((.trauma_class // .class // "") == "substrate-loop-contract-missing"
      and (.primitive_name // "") == $primitive
      and (.schema_version // "") == $schema)
  ' "$FUCKUP_LOG" >/dev/null
}

run_doctor() {
  local payload status rc
  payload="$(audit_payload_json 1)"
  status="$(jq -r '.status' <<<"$payload")"
  [[ "$status" == "pass" ]] && rc=0 || rc=1
  emit "$payload" "status=$status substrate_loop_contract_self_row_present=$(jq -r '.substrate_loop_contract_self_row_present' <<<"$payload") primitives_missing=$(jq -r '.primitives_missing_count' <<<"$payload")" "$rc"
}

run_health() {
  local payload status rc
  while :; do
    payload="$(audit_payload_json 0)"
    status="$(jq -r '.status' <<<"$payload")"
    [[ "$status" == "pass" ]] && rc=0 || rc=1
    emit "$payload" "health=$status primitives_missing=$(jq -r '.primitives_missing_count' <<<"$payload")" "$rc" || true
    [[ "$WATCH" -eq 1 ]] || break
    sleep "$WATCH_INTERVAL"
  done
  return "${rc:-0}"
}

run_repair() {
  local before planned payload missing_json actual_actions="[]" planned_actions="[]" self_action="not_needed"
  case "$REPAIR_SCOPE" in
    self-row|missing-primitives|all) ;;
    *) echo "ERR: unsupported repair scope: $REPAIR_SCOPE" >&2; return 2 ;;
  esac
  before="$(audit_payload_json 0)"
  missing_json="$(jq -c '.substrate_loop_contract_primitives_missing' <<<"$before")"
  planned="$(jq -nc --argjson missing "$missing_json" --arg scope "$REPAIR_SCOPE" --arg ledger "$LEDGER" --arg fuckup_log "$FUCKUP_LOG" '{scope:$scope,would_write:([$ledger,$fuckup_log]),would_delete:[],blocked_by:[],missing_primitives:$missing}')"
  planned_actions="$(jq -nc --argjson planned "$planned" '[$planned]')"
  if [[ "$APPLY" -eq 1 ]]; then
    if [[ "$REPAIR_SCOPE" == "self-row" || "$REPAIR_SCOPE" == "all" ]]; then
      self_action="$(ensure_self_row)"
    fi
    if [[ "$REPAIR_SCOPE" == "missing-primitives" || "$REPAIR_SCOPE" == "all" ]]; then
      while IFS= read -r primitive; do
        [[ -n "$primitive" ]] || continue
        [[ "$primitive" == "substrate-loop-contract-validator" ]] && continue
        if ! fuckup_exists "$primitive"; then
          append_validated "$FUCKUP_LOG" "$(missing_fuckup_row_json "$primitive" "missing_or_invalid_contract_row")"
          actual_actions="$(jq -c --arg primitive "$primitive" '. + [{action:"append_missing_primitive_fuckup",primitive_name:$primitive}]' <<<"$actual_actions")"
        fi
      done < <(jq -r '.[]' <<<"$missing_json")
    fi
  fi
  payload="$(audit_payload_json 0 | jq -c \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --arg self_action "$self_action" \
    --argjson planned "$planned_actions" \
    --argjson actual "$actual_actions" \
    '. + {mode:"repair",dry_run:$dry_run,apply:$apply,idempotency_key:$idempotency_key,self_row_action:$self_action,planned_actions:$planned,actual_actions:$actual}')"
  emit "$payload" "repair apply=$APPLY scope=$REPAIR_SCOPE primitives_missing=$(jq -r '.primitives_missing_count' <<<"$payload")" 0
}

run_audit() {
  local payload rows
  rows="$(rows_json)"
  payload="$(audit_payload_json 0 | jq -c --argjson rows "$rows" '. + {mode:"audit",ledger_rows:($rows[-20:] // [])}')"
  emit "$payload" "audit rows=$(jq -r '.rows_seen_count' <<<"$payload") primitives_missing=$(jq -r '.primitives_missing_count' <<<"$payload")" 0
}

run_validate() {
  local payload valid rc
  payload="$(audit_payload_json 0 | jq -c '. + {mode:"validate",target:"ledger",valid:(.status == "pass")}' )"
  valid="$(jq -r '.valid' <<<"$payload")"
  [[ "$valid" == "true" ]] && rc=0 || rc=1
  emit "$payload" "valid=$valid target=$VALIDATE_TARGET" "$rc"
}

run_why() {
  local rows primitives payload
  rows="$(rows_json)"
  primitives="$(default_primitives_json)"
  payload="$(jq -nc --arg id "$WHY_ID" --arg schema "$SCHEMA_VERSION" --argjson rows "$rows" --argjson primitives "$primitives" '
    ([{primitive_name:"substrate-loop-contract-validator"}] + $primitives | unique_by(.primitive_name) | map(select(.primitive_name == $id)) | first) as $spec
    | ([ $rows[] | select(.primitive_name == $id) ] | last) as $row
    | {mode:"why",schema_version:$schema,primitive_name:$id,spec:($spec // null),latest_row:($row // null),contract_present:($row != null)}')"
  emit "$payload" "why primitive=$WHY_ID contract_present=$(jq -r '.contract_present' <<<"$payload")" 0
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --doctor|doctor) MODE="doctor"; shift ;;
      --health|health) MODE="health"; shift ;;
      --repair|repair) MODE="repair"; shift ;;
      validate) MODE="validate"; VALIDATE_TARGET="${2:-ledger}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      audit) MODE="audit"; shift ;;
      why) MODE="why"; WHY_ID="${2:-}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      schema) MODE="schema"; SCHEMA_TOPIC="${2:-contract}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      quickstart) MODE="quickstart"; shift ;;
      help) MODE="help"; SCHEMA_TOPIC="${2:-overview}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      --info) MODE="info"; shift ;;
      --examples|examples) MODE="examples"; shift ;;
      --json) JSON_OUT=1; shift ;;
      --apply) APPLY=1; DRY_RUN=0; shift ;;
      --dry-run) APPLY=0; DRY_RUN=1; shift ;;
      --scope) REPAIR_SCOPE="${2:-}"; shift 2 ;;
      --scope=*) REPAIR_SCOPE="${1#*=}"; shift ;;
      --repo) REPO_ROOT="${2:-}"; shift 2 ;;
      --repo=*) REPO_ROOT="${1#*=}"; shift ;;
      --ledger) LEDGER="${2:-}"; shift 2 ;;
      --ledger=*) LEDGER="${1#*=}"; shift ;;
      --fuckup-log) FUCKUP_LOG="${2:-}"; shift 2 ;;
      --fuckup-log=*) FUCKUP_LOG="${1#*=}"; shift ;;
      --primitives-file) PRIMITIVES_FILE="${2:-}"; shift 2 ;;
      --primitives-file=*) PRIMITIVES_FILE="${1#*=}"; shift ;;
      --watch) WATCH=1; shift ;;
      --interval) WATCH_INTERVAL="${2:-5}"; shift 2 ;;
      --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
      --width) WIDTH="${2:-100}"; shift 2 ;;
      --no-color|--no-emoji|--explain) shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
  done
  [[ -n "$MODE" ]] || MODE="doctor"
}

main() {
  parse_args "$@"
  case "$MODE" in
    doctor) run_doctor ;;
    health) run_health ;;
    repair) run_repair ;;
    validate) run_validate ;;
    audit) run_audit ;;
    why) [[ -n "$WHY_ID" ]] || { echo "ERR: why requires PRIMITIVE" >&2; exit 2; }; run_why ;;
    schema) schema_json ;;
    info) emit "$(info_json)" "substrate-loop-contract-validator $VERSION" 0 ;;
    examples) if [[ "$JSON_OUT" -eq 1 ]]; then examples_text | jq -R -s -c '{mode:"examples",examples:split("\n")|map(select(length>0))}'; else examples_text; fi ;;
    quickstart) if [[ "$JSON_OUT" -eq 1 ]]; then quickstart_text | jq -R -s -c '{mode:"quickstart",steps:split("\n")|map(select(length>0))}'; else quickstart_text; fi ;;
    help) usage ;;
    completion) completion ;;
    *) echo "ERR: unknown mode: $MODE" >&2; exit 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
