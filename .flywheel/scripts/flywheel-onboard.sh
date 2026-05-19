#!/usr/bin/env bash
set -euo pipefail

VERSION="flywheel-onboard.v0.2.0"
CONTRACT_VERSION="2026-05-07.ntm-native.1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
DEFAULT_SHELL="${FLYWHEEL_ONBOARD_SHELL:-zsh}"

usage() {
  cat <<'USAGE'
Usage:
  flywheel-onboard.sh [doctor|health|repair] [--repo PATH] [--dry-run] [--json]
  flywheel-onboard.sh validate|audit|why|schema|examples|quickstart|completion [options]
  flywheel-onboard.sh --info [--json]

Default is --dry-run. Mutating ntm setup/init/spawn commands are planned unless
--apply is passed. Fixtures may set FLYWHEEL_ONBOARD_FIXTURE_INVOKE_DRY_RUN=1.
USAGE
}

schema_json() {
  jq -nc --arg contract "$CONTRACT_VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    "$id":"https://zeststream.ai/schemas/flywheel/onboard-contract.schema.json",
    type:"object",
    required:["schema_version","contract_version","repo","project","dry_run","status","native_surfaces","planned_commands","native_results"],
    properties:{
      schema_version:{const:"flywheel.onboard.contract.v1"}, contract_version:{const:$contract},
      repo:{type:"string"}, project:{type:"string"}, dry_run:{type:"boolean"},
      status:{enum:["HEALTHY","PARTIAL","BLOCKED"]},
      native_surfaces:{type:"array",items:{type:"string"}}, planned_commands:{type:"array"}, native_results:{type:"array"}
    }
  }'
}

examples() {
  cat <<'EXAMPLES'
.flywheel/scripts/flywheel-onboard.sh --repo /Users/josh/Developer/flywheel --dry-run --json
.flywheel/scripts/flywheel-onboard.sh doctor --repo /Users/josh/Developer/mobile-eats --json
.flywheel/scripts/flywheel-onboard.sh repair --repo /Users/josh/Developer/skillos --dry-run --json
EXAMPLES
}

completion_script() {
  cat <<'COMPLETE'
_flywheel_onboard_complete() {
  COMPREPLY=($(compgen -W "--repo --dry-run --apply --json --explain --info --schema --examples --help --version doctor health repair validate audit why completion quickstart" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _flywheel_onboard_complete flywheel-onboard.sh
COMPLETE
}

json_message() {
  local mode="$1" status="$2" message="$3"
  jq -nc --arg version "$VERSION" --arg mode "$mode" --arg status "$status" --arg message "$message" \
    '{success:($status=="ok"),schema_version:"flywheel.onboard.message.v1",version:$version,mode:$mode,status:$status,message:$message}'
}

command_json() {
  printf '%s\n' "$@" | jq -R . | jq -sc .
}

append_json_line() {
  local file="$1"
  shift
  jq -nc "$@" >>"$file"
}

require_ntm() {
  if [[ -x "$NTM_BIN" ]]; then
    return 0
  fi
  [[ "$JSON_OUT" -eq 1 ]] && json_message "$COMMAND" fail "ntm binary is not executable: $NTM_BIN" || echo "ERR: ntm binary is not executable: $NTM_BIN" >&2
  exit 127
}

should_run() {
  local kind="$1"
  [[ "$DRY_RUN" -eq 0 || "${FLYWHEEL_ONBOARD_FIXTURE_INVOKE_DRY_RUN:-0}" == "1" || "$kind" == "read" ]]
}

run_native() {
  local id="$1" surface="$2" kind="$3"
  shift 3
  local cmd=("$NTM_BIN" "$@") cmd_json stdout_file stderr_file rc
  cmd_json="$(command_json "${cmd[@]}")"

  append_json_line "$PLANNED_FILE" --arg id "$id" --arg surface "$surface" --arg kind "$kind" --argjson command "$cmd_json" \
    '{id:$id,surface:$surface,kind:$kind,command:$command}'

  if ! should_run "$kind"; then
    append_json_line "$RESULTS_FILE" --arg id "$id" --arg surface "$surface" --argjson command "$cmd_json" \
      '{id:$id,surface:$surface,executed:false,skipped_reason:"dry_run_mutation",exit_code:null,command:$command}'
    append_json_line "$SKIPPED_FILE" --arg id "$id" --arg surface "$surface" --argjson command "$cmd_json" \
      '{id:$id,surface:$surface,reason:"dry_run_mutation",command:$command}'
    return 0
  fi

  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  set +e
  "${cmd[@]}" >"$stdout_file" 2>"$stderr_file"
  rc=$?
  set -e
  append_json_line "$RESULTS_FILE" \
    --arg id "$id" \
    --arg surface "$surface" \
    --argjson command "$cmd_json" \
    --arg stdout "$(head -c 4000 "$stdout_file")" \
    --arg stderr "$(head -c 2000 "$stderr_file")" \
    --argjson exit_code "$rc" \
    '{id:$id,surface:$surface,executed:true,exit_code:$exit_code,stdout:$stdout,stderr:$stderr,command:$command}'
  rm -f "$stdout_file" "$stderr_file"
  [[ "$kind" == "read" ]] && return 0
  return "$rc"
}

coordinator_daemon_probe() {
  local script="$REPO_ABS/.flywheel/scripts/install-coordinator-daemon.sh" stdout_file stderr_file rc
  if [[ ! -x "$script" ]]; then
    jq -nc --arg script "$script" '{available:false,script:$script,success:false,skipped_reason:"script_not_executable"}'
    return 0
  fi

  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  set +e
  "$script" doctor --all-sessions --json >"$stdout_file" 2>"$stderr_file"
  rc=$?
  set -e
  if jq empty "$stdout_file" >/dev/null 2>&1; then
    jq --argjson rc "$rc" --arg stderr "$(head -c 2000 "$stderr_file")" '. + {available:true,probe_exit_code:$rc,stderr:$stderr}' "$stdout_file"
  else
    jq -nc --arg script "$script" --argjson rc "$rc" --arg stdout "$(head -c 2000 "$stdout_file")" --arg stderr "$(head -c 2000 "$stderr_file")" \
      '{available:true,script:$script,success:false,probe_exit_code:$rc,stdout:$stdout,stderr:$stderr}'
  fi
  rm -f "$stdout_file" "$stderr_file"
}

hygiene_targets_probe() {
  local yaml_path="$REPO_ABS/.flywheel/hygiene-targets.yaml"
  local schema_path="/Users/josh/Developer/flywheel/templates/flywheel-install/hygiene-targets.schema.json"
  if [[ ! -f "$yaml_path" ]]; then
    jq -nc --arg path "$yaml_path" '{present:false,valid:false,path:$path,reason:"missing"}'
    return 0
  fi
  if python3 - "$schema_path" "$yaml_path" >/dev/null 2>&1 <<'PY'
import json, sys
import yaml
from jsonschema import Draft202012Validator
with open(sys.argv[1], encoding="utf-8") as f:
    schema = json.load(f)
with open(sys.argv[2], encoding="utf-8") as f:
    data = yaml.safe_load(f)
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(data)
PY
  then
    jq -nc --arg path "$yaml_path" '{present:true,valid:true,path:$path,reason:null}'
  else
    jq -nc --arg path "$yaml_path" '{present:true,valid:false,path:$path,reason:"schema_validation_failed"}'
  fi
}

stash_health_probe() {
  local count status mode recommendation warning
  if ! git -C "$REPO_ABS" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    jq -nc --arg repo "$REPO_ABS" '{repo:$repo,status:"UNKNOWN",stash_count:null,warnings:["not_a_git_work_tree"]}'
    return 0
  fi
  count="$(git -C "$REPO_ABS" stash list 2>/dev/null | wc -l | tr -d '[:space:]')"
  case "$count" in
    ''|*[!0-9]*) count=0 ;;
  esac
  status="HEALTHY"
  mode="manual"
  recommendation=""
  warning=""
  if [[ "$count" -ge 80 ]]; then
    status="WARN"
    mode="comprehensive"
    recommendation="/git-stash-janitor"
    warning="stash_count_requires_git_stash_janitor"
  elif [[ "$count" -ge 10 ]]; then
    status="WARN"
    mode="standard"
    recommendation="/git-stash-janitor"
    warning="stash_count_requires_git_stash_janitor"
  elif [[ "$count" -ge 5 ]]; then
    mode="quick"
    recommendation="/git-stash-janitor"
  fi
  jq -nc \
    --arg repo "$REPO_ABS" \
    --arg status "$status" \
    --arg mode "$mode" \
    --arg recommendation "$recommendation" \
    --arg warning "$warning" \
    --argjson stash_count "$count" \
    '{
      repo:$repo,
      status:$status,
      stash_count:$stash_count,
      recommended_mode:$mode,
      recommended_skill:(if $recommendation == "" then null else $recommendation end),
      recommend_before_continue:($stash_count >= 10),
      manual_threshold:"<5",
      quick_threshold:"5-9",
      standard_threshold:"10-80",
      comprehensive_threshold:"80+",
      warnings:(if $warning == "" then [] else [$warning] end)
    }'
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" --arg contract "$CONTRACT_VERSION" --arg ntm "$NTM_BIN" '{
      success:true,
      schema_version:"flywheel.onboard.info.v1",
      version:$version,
      contract_version:$contract,
      ntm_bin:$ntm,
      native_surfaces:["deps","setup","init","shell","completion","bind","spawn","coordinator-daemon","repo-hygiene"],
      default_dry_run:true
    }'
  else
    printf '%s contract=%s ntm=%s default_dry_run=true\n' "$VERSION" "$CONTRACT_VERSION" "$NTM_BIN"
  fi
}

COMMAND="doctor"
REPO=""
JSON_OUT=0
DRY_RUN=1
APPLY=0
EXPLAIN=0
WHY_ID="onboarding"

if [[ $# -gt 0 ]]; then
  case "$1" in
    doctor|health|repair|validate|audit|why|schema|examples|quickstart|completion|help)
      COMMAND="$1"
      shift
      ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ -n "${2:-}" ]] || { echo "ERR: --repo requires PATH" >&2; exit 2; }
      REPO="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --apply)
      DRY_RUN=0; APPLY=1; shift ;;
    --doctor)
      COMMAND="doctor"; shift ;;
    --json)
      JSON_OUT=1; shift ;;
    --explain)
      EXPLAIN=1; shift ;;
    --info)
      COMMAND="info"; shift ;;
    --schema)
      COMMAND="schema"; shift ;;
    --examples)
      COMMAND="examples"; shift ;;
    --id)
      [[ -n "${2:-}" ]] || { echo "ERR: --id requires ID" >&2; exit 2; }
      WHY_ID="$2"; shift 2 ;;
    --help|-h)
      usage; exit 0 ;;
    --version)
      printf '%s contract=%s\n' "$VERSION" "$CONTRACT_VERSION"; exit 0 ;;
    --stamp|--sync|--upgrade)
      COMMAND="doctor"; shift ;;
    --idempotency-key|--scope|--width)
      [[ -n "${2:-}" ]] || { echo "ERR: $1 requires a value" >&2; exit 2; }
      shift 2 ;;
    --no-color|--no-emoji)
      shift ;;
    -*)
      echo "ERR: unknown argument: $1" >&2; exit 2 ;;
    *)
      [[ -z "$REPO" ]] || { echo "ERR: unexpected argument: $1" >&2; exit 2; }
      REPO="$1"; shift ;;
  esac
done

case "$COMMAND" in
  help)
    usage; exit 0 ;;
  schema)
    schema_json; exit 0 ;;
  examples)
    examples; exit 0 ;;
  quickstart)
    echo "Run --dry-run --json first; use --apply only when native ntm mutations should execute."; exit 0 ;;
  completion)
    completion_script; exit 0 ;;
  info)
    emit_info; exit 0 ;;
  validate)
    schema_json | jq empty >/dev/null
    [[ "$JSON_OUT" -eq 1 ]] && json_message validate ok "schema valid" || echo "schema valid"
    exit 0 ;;
  audit)
    [[ "$JSON_OUT" -eq 1 ]] && jq -nc --arg version "$VERSION" '{success:true,schema_version:"flywheel.onboard.audit.v1",version:$version,entries:[]}' || echo "No onboarding audit entries emitted by this native wrapper."
    exit 0 ;;
  why)
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg id "$WHY_ID" '{success:true,schema_version:"flywheel.onboard.why.v1",id:$id,explanation:"Onboarding delegates mechanics to native ntm deps/setup/init/shell/completion/bind/spawn surfaces; this wrapper only orders them and preserves dry-run/apply discipline."}'
    else
      echo "Onboarding delegates mechanics to native ntm setup surfaces and preserves dry-run/apply discipline."
    fi
    exit 0 ;;
esac

[[ -n "$REPO" ]] || REPO="$PWD"
if ! REPO_ABS="$(cd "$REPO" 2>/dev/null && pwd -P)"; then
  echo "ERR: repo path not found: $REPO" >&2
  exit 2
fi
require_ntm

PROJECT="$(basename "$REPO_ABS")"
PLANNED_FILE="$(mktemp)"
RESULTS_FILE="$(mktemp)"
SKIPPED_FILE="$(mktemp)"
trap 'rm -f "$PLANNED_FILE" "$RESULTS_FILE" "$SKIPPED_FILE"' EXIT

run_native "deps" "deps" "read" deps --json
run_native "setup-status" "setup" "read" setup status --json
run_native "setup" "setup" "mutate" setup
run_native "init" "init" "mutate" init "$REPO_ABS" --non-interactive --no-hooks
run_native "shell" "shell" "read" shell "$DEFAULT_SHELL"
run_native "completion" "completion" "read" completion "$DEFAULT_SHELL"
run_native "bind-show" "bind" "read" bind --show
run_native "spawn" "spawn" "mutate" spawn "$PROJECT" --no-user --json

coordinator_probe="$(coordinator_daemon_probe)"
hygiene_probe="$(hygiene_targets_probe)"
stash_probe="$(stash_health_probe)"
planned_json="$(jq -sc '.' "$PLANNED_FILE")"
results_json="$(jq -sc '.' "$RESULTS_FILE")"
skipped_json="$(jq -sc '.' "$SKIPPED_FILE")"
failed_reads="$(jq -s '[.[] | select(.executed == true and .exit_code != 0 and (.surface == "deps" or .id == "setup-status"))] | length' "$RESULTS_FILE")"
mutation_failures="$(jq -s '[.[] | select(.executed == true and .exit_code != 0 and (.surface == "setup" or .surface == "init" or .surface == "spawn"))] | length' "$RESULTS_FILE")"
hygiene_failures="$(jq -n --argjson probe "$hygiene_probe" 'if ($probe.present == true and $probe.valid == true) then 0 else 1 end')"
stash_failures="$(jq -n --argjson probe "$stash_probe" 'if (($probe.stash_count // 0) >= 10) then 1 else 0 end')"

STATUS="HEALTHY"
[[ "$failed_reads" -gt 0 ]] && STATUS="PARTIAL"
[[ "$hygiene_failures" -gt 0 && "$STATUS" == "HEALTHY" ]] && STATUS="PARTIAL"
[[ "$stash_failures" -gt 0 && "$STATUS" == "HEALTHY" ]] && STATUS="PARTIAL"
[[ "$mutation_failures" -gt 0 ]] && STATUS="BLOCKED"

payload="$(jq -nc \
  --arg version "$VERSION" \
  --arg contract "$CONTRACT_VERSION" \
  --arg repo "$REPO_ABS" \
  --arg project "$PROJECT" \
  --arg status "$STATUS" \
  --arg dry_run "$DRY_RUN" \
  --arg apply "$APPLY" \
  --arg explain "$EXPLAIN" \
  --argjson planned "$planned_json" \
  --argjson results "$results_json" \
  --argjson skipped "$skipped_json" \
  --argjson coordinator_probe "$coordinator_probe" \
  --argjson hygiene_probe "$hygiene_probe" \
  --argjson stash_probe "$stash_probe" \
  '{
    success:($status != "BLOCKED"),
    schema_version:"flywheel.onboard.contract.v1",
    contract_version:$contract,
    version:$version,
    repo:$repo,
    project:$project,
    mode:"onboard",
    dry_run:($dry_run=="1"),
    apply:($apply=="1"),
    explain:($explain=="1"),
    status:$status,
    native_surfaces:["deps","setup","init","shell","completion","bind","spawn","coordinator-daemon","repo-hygiene"],
    planned_commands:$planned,
    native_results:$results,
    mutating_commands_skipped:$skipped,
    coordinator_daemon_probe:$coordinator_probe,
    hygiene_targets_probe:$hygiene_probe,
    stash_health_probe:$stash_probe,
    stash_count:($stash_probe.stash_count // null),
    stash_health_status:($stash_probe.status // "UNKNOWN"),
    stash_recommended_mode:($stash_probe.recommended_mode // null),
    stash_recommended_skill:($stash_probe.recommended_skill // null),
    stash_recommend_before_continue:($stash_probe.recommend_before_continue // false),
    hygiene_targets_present:($hygiene_probe.present // false),
    hygiene_targets_valid:($hygiene_probe.valid // false),
    hygiene_targets_path:($hygiene_probe.path // null),
    fleet_coordinator_daemon_coverage:($coordinator_probe.fleet_coordinator_daemon_coverage // "0/0"),
    fleet_coordinator_daemon_coverage_count:($coordinator_probe.fleet_coordinator_daemon_coverage_count // 0),
    fleet_coordinator_daemon_coverage_total:($coordinator_probe.fleet_coordinator_daemon_coverage_total // 0),
    actual_actions:($results | map(select(.executed == true))),
    no_hand_roll_create_attach:true
  }')"

if [[ "$EXPLAIN" -eq 1 ]]; then
  payload="$(jq '.explanation=[
    "Native ntm commands own setup mechanics.",
    "Dry-run records mutating commands instead of executing them.",
    "Fixture dry-runs may opt into execution with FLYWHEEL_ONBOARD_FIXTURE_INVOKE_DRY_RUN=1."
  ]' <<<"$payload")"
fi

[[ "$JSON_OUT" -eq 1 ]] && jq -c . <<<"$payload" || jq -r '"\(.project): \(.status) dry_run=\(.dry_run) planned_commands=\(.planned_commands|length) skipped_mutations=\(.mutating_commands_skipped|length)"' <<<"$payload"
[[ "$STATUS" == "BLOCKED" ]] && exit 4
exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
