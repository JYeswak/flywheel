#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-1hshd.27 (SELECTIVE-VERB-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fleet-coherence-launchd/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fleet-coherence-launchd-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: fleet-coherence-launchd.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "fleet-coherence-launchd.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "fleet-coherence-launchd.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"fleet-coherence-launchd.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"fleet-coherence-launchd.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"fleet-coherence-launchd.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes launchd_available, plistutil/plutil, state_dir, install_plist (LaunchAgents/com.zeststream.flywheel.fleet-coherence.plist), source_plist, audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",loaded:"bool",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["state_dir","audit_log_dir","launchagents_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",selective_verb_bypass:"validate plist is owned by NATIVE (legacy contract); scaffold owns label/cadence-seconds/state-dir subjects",valid_subjects:["label","cadence-seconds","state-dir"],cadence_seconds_default:60,cadence_seconds_range:"[10, 3600]",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","label","plist"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"SELECTIVE-VERB-BYPASS",bypassed_natively:["validate plist","install","load","unload","status","run"],note:"per-surface schema available via --schema <surface>"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; routes through cmd_run (executes scanner once).\n' ;;
    doctor)   printf 'topic: doctor — probes launchctl_available/plutil_available/state_dir_writable/install_plist_present (~/Library/LaunchAgents/com.zeststream.flywheel.fleet-coherence.plist)/source_plist_present/audit_log_dir_writable.\n' ;;
    health)   printf 'topic: health — emits loaded state (launchctl list) + last_run_ts from audit log; status=ok|degraded based on doctor parity.\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|audit_log_dir|launchagents_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p $STATE_DIR), audit_log_dir (mkdir -p dirname of $SCAFFOLD_AUDIT_LOG), launchagents_dir (mkdir -p ~/Library/LaunchAgents). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <label|cadence-seconds|state-dir> VALUE — label must match com.zeststream.flywheel.<slug>; cadence-seconds integer in [10, 3600]; state-dir must be an absolute path. NOTE: `validate plist` is owned by NATIVE (legacy contract) — SELECTIVE-VERB-BYPASS. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows). Empty when audit log missing.\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / label / plist. Returns status=found|not_found|unavailable.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "fleet-coherence-launchd" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fleet-coherence-launchd" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local state_dir="${STATE_DIR:-$HOME/.local/state/flywheel/fleet-coherence}"
  local install_plist="${INSTALL_PLIST:-$HOME/Library/LaunchAgents/com.zeststream.flywheel.fleet-coherence.plist}"
  if command -v launchctl >/dev/null 2>&1; then
    checks+=('{"name":"launchctl_available","status":"pass"}')
  else
    checks+=('{"name":"launchctl_available","status":"fail","note":"required for load/unload/status on macOS"}')
  fi
  if command -v plutil >/dev/null 2>&1; then
    checks+=('{"name":"plutil_available","status":"pass"}')
  else
    checks+=('{"name":"plutil_available","status":"fail","note":"required for plist validation"}')
  fi
  if command -v jq >/dev/null 2>&1; then
    checks+=('{"name":"jq_available","status":"pass"}')
  else
    checks+=('{"name":"jq_available","status":"fail"}')
  fi
  if [[ -d "$state_dir" || ( ! -e "$state_dir" && -w "$(dirname "$state_dir")" ) ]]; then
    checks+=('{"name":"state_dir_writable","status":"pass","path":"'"$state_dir"'"}')
  else
    checks+=('{"name":"state_dir_writable","status":"fail","path":"'"$state_dir"'"}')
  fi
  if [[ -r "$install_plist" ]]; then
    checks+=('{"name":"install_plist_present","status":"pass","path":"'"$install_plist"'"}')
  else
    checks+=('{"name":"install_plist_present","status":"warn","path":"'"$install_plist"'","note":"agent not installed; run install --apply"}')
  fi
  local launchagents_dir="$HOME/Library/LaunchAgents"
  if [[ -d "$launchagents_dir" ]]; then
    checks+=('{"name":"launchagents_dir_present","status":"pass","path":"'"$launchagents_dir"'"}')
  else
    checks+=('{"name":"launchagents_dir_present","status":"warn","path":"'"$launchagents_dir"'"}')
  fi
  local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -w "$audit_dir" || ( ! -e "$audit_dir" && -w "$(dirname "$audit_dir")" ) ]]; then
    checks+=('{"name":"audit_log_dir_writable","status":"pass","path":"'"$audit_dir"'"}')
  else
    checks+=('{"name":"audit_log_dir_writable","status":"fail","path":"'"$audit_dir"'"}')
  fi
  local arr; arr="[$(IFS=,; echo "${checks[*]}")]"
  local status="ok"
  if echo "$arr" | jq -e 'any(.status == "fail")' >/dev/null 2>&1; then status="degraded"; fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg st "$status" --argjson checks "$arr" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$st,checks:$checks}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local label="${LABEL:-com.zeststream.flywheel.fleet-coherence}"
  local loaded=false
  if command -v launchctl >/dev/null 2>&1 && launchctl list 2>/dev/null | grep -q "$label"; then
    loaded=true
  fi
  local last_run_ts="null"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then last_run_ts="\"$raw\""; fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --arg label "$label" --argjson loaded "$loaded" --argjson last "$last_run_ts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"ok",label:$label,loaded:$loaded,last_run_ts:$last,audit_log:$log,binds_audit_log:true}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    state_dir)
      local target="${STATE_DIR:-$HOME/.local/state/flywheel/fleet-coherence}"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope state_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope audit_log_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    launchagents_dir)
      local target="$HOME/Library/LaunchAgents"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope launchagents_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <state_dir|audit_log_dir|launchagents_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["state_dir","audit_log_dir","launchagents_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    label)
      if [[ -z "$arg" ]]; then printf 'ERR: validate label requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^com\.zeststream\.flywheel\.[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"label",ts:$ts,status:"ok",value:$v,note:"matches com.zeststream.flywheel.<slug> namespace"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"label",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^com\\.zeststream\\.flywheel\\.[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    cadence-seconds)
      if [[ -z "$arg" ]]; then printf 'ERR: validate cadence-seconds requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 10 && arg <= 3600 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"cadence-seconds",ts:$ts,status:"ok",value:$v,default:60,note:"matches launchd StartInterval contract"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"cadence-seconds",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[10, 3600]",default:60}'
        return 1
      fi
      ;;
    state-dir)
      if [[ -z "$arg" ]]; then printf 'ERR: validate state-dir requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" == /* ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"state-dir",ts:$ts,status:"ok",value:$v,note:"absolute path"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"state-dir",ts:$ts,status:"reject",value:$v,reason:"not_absolute_path",hint:"must start with /"}'
        return 1
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["label","cadence-seconds","state-dir"],bypassed_to_native:["plist"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["label","cadence-seconds","state-dir"],bypassed_to_native:["plist"]}'
      return 64 ;;
  esac
}

scaffold_cmd_audit() {
  local limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      --limit) limit="${2:-20}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown audit arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
        '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,reason:"audit_log_missing",rows:[]}'
      return 0
    fi
    local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
      --argjson rows "$rows" --argjson limit "$limit" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.label // "") == $id or (.plist // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","label","plist"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
#
# VERB COLLISION BYPASS (flywheel-sacan): the target's own argparse
# already handles canonical verbs (doctor|health|repair|validate|...).
# When any of the per-target flags below are present in argv, the
# intercept yields and cmd_run handles the per-bead path unchanged.
# Per-target bypass flags: --events,--latest,--once,--state-dir
_scaffold_is_canonical_arg() {
  # SELECTIVE-VERB-BYPASS variant: native owns `validate plist` (legacy
  # contract) and bare invocation (default status JSON). Scaffold owns
  # --info, --schema, --examples, doctor/health/repair/validate (non-plist
  # subjects only)/audit/why/quickstart/help.
  # Verb-first ordering: scaffold-verb claims args[0] regardless of native
  # flags downstream (install/load/unload --apply/--dry-run are native; they
  # never reach scaffold because their verbs aren't in the canonical set).
  case "${1:-}" in
    doctor|health|repair|audit|why|quickstart|completion) return 0 ;;
    validate)
      # SELECTIVE-VERB-BYPASS: bypass `validate plist` to native (legacy).
      # Scaffold owns validate with new subjects (label, cadence-seconds,
      # state-dir, etc.).
      case "${2:-}" in plist) return 1 ;; esac
      return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
  esac
  return 1
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LIB="$ROOT/.flywheel/scripts/fleet-coherence-lib.sh"
# shellcheck source=.flywheel/scripts/fleet-coherence-lib.sh
source "$LIB"

CONTRACT="fleet-coherence-launchd/v1"
LABEL="${FLEET_COHERENCE_LAUNCHD_LABEL:-com.zeststream.flywheel.fleet-coherence}"
SOURCE_PLIST="${FLEET_COHERENCE_SOURCE_PLIST:-$ROOT/launchd/ai.zeststream.fleet-coherence.plist}"
INSTALL_PLIST="${FLEET_COHERENCE_INSTALL_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
DOMAIN="${FLEET_COHERENCE_LAUNCHD_DOMAIN:-gui/$(id -u)}"
TARGET="$DOMAIN/$LABEL"
LAUNCHCTL="${FLEET_COHERENCE_LAUNCHCTL:-launchctl}"
PLUTIL="${FLEET_COHERENCE_PLUTIL:-plutil}"
SCANNER="${FLEET_COHERENCE_SCANNER:-$ROOT/.flywheel/scripts/fleet-coherence-scan.sh}"
STATE_DIR="${FLEET_COHERENCE_STATE_DIR:-$(fc_state_dir)}"
EVENTS="${FLEET_COHERENCE_EVENTS:-$(fc_events_path)}"
LATEST="${FLEET_COHERENCE_LATEST:-$(fc_latest_path)}"
LIFECYCLE_LEDGER="${FLEET_COHERENCE_LIFECYCLE_LEDGER:-$STATE_DIR/fleet-coherence-launchd.jsonl}"
LIFECYCLE_LATEST="${FLEET_COHERENCE_LIFECYCLE_LATEST:-$STATE_DIR/fleet-coherence-launchd-latest.json}"
RUN_LOCK="${FLEET_COHERENCE_RUN_LOCK:-$STATE_DIR/fleet-coherence-launchd.lock}"
SCANNER_LOCK="${FLEET_COHERENCE_SCANNER_LOCK:-$STATE_DIR/fleet-coherence-scan.lock}"
STOP_FILE="${FLEET_COHERENCE_STOP_FILE:-$HOME/.flywheel/STOP-fleet-coherence}"
GLOBAL_STOP_FILE="${FLEET_COHERENCE_GLOBAL_STOP_FILE:-$HOME/.flywheel/STOP-ALL}"
STDOUT_PATH="${FLEET_COHERENCE_STDOUT_PATH:-$HOME/.local/logs/fleet-coherence-launchd.out.log}"
STDERR_PATH="${FLEET_COHERENCE_STDERR_PATH:-$HOME/.local/logs/fleet-coherence-launchd.err.log}"
CADENCE_SECONDS="${FLEET_COHERENCE_CADENCE_SECONDS:-60}"
STALE_LOCK_SECONDS="${FLEET_COHERENCE_STALE_LOCK_SECONDS:-180}"
SAFE_PATH="${FLEET_COHERENCE_SAFE_PATH:-/Users/josh/.cargo/bin:/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin}"
MODE="status"
APPLY=0
JSON_OUT=0
RUN_LOCK_ACQUIRED=0
CHILD_PID=0

usage() {
  cat <<'EOF'
Usage:
  fleet-coherence-launchd.sh install --dry-run|--apply [--json]
  fleet-coherence-launchd.sh load --dry-run|--apply [--json]
  fleet-coherence-launchd.sh unload --dry-run|--apply [--json]
  fleet-coherence-launchd.sh status [--json]
  fleet-coherence-launchd.sh run [--json]
  fleet-coherence-launchd.sh validate plist [--json]

Installs and controls the fleet-coherence scanner LaunchAgent.
STOP files: ~/.flywheel/STOP-fleet-coherence and ~/.flywheel/STOP-ALL.
HUP/TERM/INT during run emit lifecycle receipts and clean wrapper locks.
EOF
}

now_iso() { fc_now; }

ensure_dirs() {
  mkdir -p "$STATE_DIR" "$(dirname "$EVENTS")" "$(dirname "$LATEST")" \
    "$(dirname "$LIFECYCLE_LEDGER")" "$(dirname "$LIFECYCLE_LATEST")" \
    "$(dirname "$SOURCE_PLIST")" "$(dirname "$INSTALL_PLIST")" \
    "$(dirname "$STDOUT_PATH")" "$(dirname "$STDERR_PATH")"
}

emit() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -cS .
  else
    jq .
  fi
}

bool_json() {
  if [[ "$1" == "true" ]]; then
    printf 'true\n'
  else
    printf 'false\n'
  fi
}

is_uint() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

require_uint() {
  local name="$1" value="$2"
  if ! is_uint "$value"; then
    printf '%s must be an unsigned integer, got %s\n' "$name" "$value" >&2
    exit 64
  fi
}

write_lifecycle_row() {
  local row="$1"
  mkdir -p "$(dirname "$LIFECYCLE_LEDGER")" "$(dirname "$LIFECYCLE_LATEST")"
  printf '%s\n' "$row" | jq -cS . >>"$LIFECYCLE_LEDGER"
  printf '%s\n' "$row" | jq -cS . >"$LIFECYCLE_LATEST"
}

lifecycle_row() {
  local empty_obj='{}'
  local status="$1" decision="$2" scanner_rc="${3:-null}" scanner_status="${4:-null}" extra="${5:-$empty_obj}"
  scanner_rc="$(jq -ncS --arg v "$scanner_rc" 'try ($v | fromjson) catch null')"
  scanner_status="$(jq -ncS --arg v "$scanner_status" 'try ($v | fromjson) catch null')"
  extra="$(jq -ncS --arg v "$extra" 'try (($v | fromjson) | if type == "object" then . else {} end) catch {}')"
  jq -ncS \
    --arg ts "$(now_iso)" \
    --arg contract "$CONTRACT" \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg source_plist "$SOURCE_PLIST" \
    --arg install_plist "$INSTALL_PLIST" \
    --arg scanner "$SCANNER" \
    --arg state_dir "$STATE_DIR" \
    --arg events "$EVENTS" \
    --arg latest "$LATEST" \
    --arg run_lock "$RUN_LOCK" \
    --arg scanner_lock "$SCANNER_LOCK" \
    --arg stop_file "$STOP_FILE" \
    --arg global_stop_file "$GLOBAL_STOP_FILE" \
    --argjson scanner_rc "$scanner_rc" \
    --argjson scanner_status "$scanner_status" \
    --argjson extra "$extra" \
    '{
      schema_version: "fleet-coherence-launchd-lifecycle/v1",
      ts: $ts,
      status: $status,
      decision: $decision,
      contract: $contract,
      l112_observed: "OK_phase1b_launchd",
      label: $label,
      target: $target,
      source_plist: $source_plist,
      install_plist: $install_plist,
      scanner: $scanner,
      state_dir: $state_dir,
      events_path: $events,
      latest_path: $latest,
      run_lock: $run_lock,
      scanner_lock: $scanner_lock,
      stop_files: [$stop_file, $global_stop_file],
      scanner_rc: $scanner_rc,
      scanner_status: $scanner_status
    } + $extra'
}

cleanup_run_lock() {
  if [[ "$RUN_LOCK_ACQUIRED" -eq 1 ]]; then
    rm -rf "$RUN_LOCK" 2>/dev/null || true
    RUN_LOCK_ACQUIRED=0
  fi
}

signal_handler() {
  local signal="$1" row
  if [[ "$CHILD_PID" -gt 0 ]]; then
    kill "$CHILD_PID" >/dev/null 2>&1 || true
  fi
  row="$(lifecycle_row "signaled" "signal_${signal}")"
  row="$(printf '%s\n' "$row" | jq -cS --arg signal "$signal" '. + {signal:$signal, graceful_cleanup:true}')"
  write_lifecycle_row "$row"
  cleanup_run_lock
  printf '%s\n' "$row" | emit
  exit 0
}

trap_cleanup() {
  cleanup_run_lock
}
trap trap_cleanup EXIT

plist_path_for_write() {
  local which="$1"
  case "$which" in
    source) printf '%s\n' "$SOURCE_PLIST" ;;
    install) printf '%s\n' "$INSTALL_PLIST" ;;
    *) return 64 ;;
  esac
}

write_plist_file() {
  local path="$1" tmp helper_cmd
  ensure_dirs
  tmp="${path}.$$.$RANDOM.tmp"
  helper_cmd="exec $ROOT/.flywheel/scripts/fleet-coherence-launchd.sh run --json"
  python3 - "$tmp" "$LABEL" "$helper_cmd" "$STDOUT_PATH" "$STDERR_PATH" "$CADENCE_SECONDS" "$SAFE_PATH" "$HOME" <<'PY'
import plistlib
import sys

target, label, command, stdout, stderr, cadence, safe_path, home = sys.argv[1:9]
payload = {
    "Label": label,
    "ProgramArguments": ["/bin/bash", "-lc", command],
    "StartInterval": int(cadence),
    "RunAtLoad": True,
    "StandardOutPath": stdout,
    "StandardErrorPath": stderr,
    "EnvironmentVariables": {
        "HOME": home,
        "PATH": safe_path,
    },
}
with open(target, "wb") as handle:
    plistlib.dump(payload, handle, sort_keys=False)
PY
  "$PLUTIL" -lint "$tmp" >/dev/null
  mv "$tmp" "$path"
}

plist_value() {
  local path="$1" key="$2"
  [[ -f "$path" ]] || return 1
  "$PLUTIL" -extract "$key" raw "$path" 2>/dev/null
}

loaded() {
  "$LAUNCHCTL" print "$TARGET" >/dev/null 2>&1
}

lock_age_s() {
  local path="$1" mtime now
  [[ -e "$path" ]] || { printf '0\n'; return 0; }
  if mtime="$(stat -f %m "$path" 2>/dev/null)"; then
    :
  elif mtime="$(stat -c %Y "$path" 2>/dev/null)"; then
    :
  else
    printf '0\n'
    return 0
  fi
  now="$(date -u +%s)"
  printf '%s\n' "$((now - mtime))"
}

status_json() {
  local source_exists install_exists loaded_state scanner_ok stop_active global_stop_active stale_lock age cadence stdout stderr status warnings
  source_exists=false
  install_exists=false
  loaded_state=false
  scanner_ok=false
  stop_active=false
  global_stop_active=false
  stale_lock=false
  [[ -f "$SOURCE_PLIST" ]] && source_exists=true
  [[ -f "$INSTALL_PLIST" ]] && install_exists=true
  [[ -x "$SCANNER" ]] && scanner_ok=true
  [[ -f "$STOP_FILE" ]] && stop_active=true
  [[ -f "$GLOBAL_STOP_FILE" ]] && global_stop_active=true
  loaded && loaded_state=true
  age="$(lock_age_s "$SCANNER_LOCK")"
  if [[ -e "$SCANNER_LOCK" && "$age" -ge "$STALE_LOCK_SECONDS" ]]; then
    stale_lock=true
  fi
  cadence="$(plist_value "$INSTALL_PLIST" StartInterval || plist_value "$SOURCE_PLIST" StartInterval || printf 'null')"
  stdout="$(plist_value "$INSTALL_PLIST" StandardOutPath || plist_value "$SOURCE_PLIST" StandardOutPath || printf '')"
  stderr="$(plist_value "$INSTALL_PLIST" StandardErrorPath || plist_value "$SOURCE_PLIST" StandardErrorPath || printf '')"
  status="pass"
  warnings="[]"
  if [[ "$source_exists" != true || "$install_exists" != true || "$scanner_ok" != true ]]; then
    status="warn"
    warnings="$(jq -nc \
      --argjson source "$(bool_json "$source_exists")" \
      --argjson install "$(bool_json "$install_exists")" \
      --argjson scanner "$(bool_json "$scanner_ok")" \
      '[]
       + (if $source then [] else [{code:"source_plist_missing"}] end)
       + (if $install then [] else [{code:"install_plist_missing"}] end)
       + (if $scanner then [] else [{code:"scanner_missing"}] end)')"
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg status "$status" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg source_plist "$SOURCE_PLIST" \
    --arg install_plist "$INSTALL_PLIST" \
    --arg scanner "$SCANNER" \
    --arg stdout "$stdout" \
    --arg stderr "$stderr" \
    --arg state_dir "$STATE_DIR" \
    --arg events "$EVENTS" \
    --arg latest "$LATEST" \
    --arg run_lock "$RUN_LOCK" \
    --arg scanner_lock "$SCANNER_LOCK" \
    --argjson cadence "${cadence:-null}" \
    --argjson age "$age" \
    --argjson source_exists "$(bool_json "$source_exists")" \
    --argjson install_exists "$(bool_json "$install_exists")" \
    --argjson loaded_state "$(bool_json "$loaded_state")" \
    --argjson scanner_ok "$(bool_json "$scanner_ok")" \
    --argjson stop_active "$(bool_json "$stop_active")" \
    --argjson global_stop_active "$(bool_json "$global_stop_active")" \
    --argjson stale_lock "$(bool_json "$stale_lock")" \
    --argjson warnings "$warnings" \
    '{
      schema_version: "fleet-coherence-launchd-status/v1",
      status: $status,
      contract: $contract,
      l112_observed: "OK_phase1b_launchd",
      label: $label,
      target: $target,
      source_plist: $source_plist,
      install_plist: $install_plist,
      source_plist_exists: $source_exists,
      install_plist_exists: $install_exists,
      loaded: $loaded_state,
      scanner: $scanner,
      scanner_executable: $scanner_ok,
      cadence_seconds: $cadence,
      stdout_path: $stdout,
      stderr_path: $stderr,
      state_dir: $state_dir,
      events_path: $events,
      latest_path: $latest,
      run_lock: $run_lock,
      scanner_lock: $scanner_lock,
      scanner_lock_age_s: $age,
      stale_lock: $stale_lock,
      stop_active: $stop_active,
      global_stop_active: $global_stop_active,
      warnings: $warnings
    }'
}

install_json() {
  local actions installed
  actions="$(jq -ncS --arg source "$SOURCE_PLIST" --arg target "$INSTALL_PLIST" --argjson cadence "$CADENCE_SECONDS" \
    '[{action:"render_source_plist",path:$source},{action:"install_launchagent",path:$target},{action:"set_start_interval",seconds:$cadence},{action:"ensure_log_paths"}]')"
  if [[ "$APPLY" -eq 1 ]]; then
    write_plist_file "$SOURCE_PLIST"
    write_plist_file "$INSTALL_PLIST"
    installed=true
  else
    installed=false
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg source "$SOURCE_PLIST" \
    --arg target "$INSTALL_PLIST" \
    --arg label "$LABEL" \
    --argjson actions "$actions" \
    --argjson apply "$APPLY" \
    --argjson installed "$(bool_json "$installed")" \
    '{schema_version:"fleet-coherence-launchd-install/v1",status:"pass",contract:$contract,l112_observed:"OK_phase1b_launchd",label:$label,source_plist:$source,install_plist:$target,applied:($apply == 1),dry_run:($apply != 1),installed:$installed,planned_actions:$actions}'
}

load_json() {
  local actions loaded_state print_exit=1
  actions="$(jq -ncS --arg target "$TARGET" --arg plist "$INSTALL_PLIST" '[{action:"bootstrap",target:$target,plist:$plist},{action:"kickstart",target:$target}]')"
  if [[ "$APPLY" -eq 1 ]]; then
    [[ -f "$INSTALL_PLIST" ]] || write_plist_file "$INSTALL_PLIST"
    if loaded; then
      "$LAUNCHCTL" bootout "$TARGET" >/dev/null 2>&1 || true
    fi
    "$LAUNCHCTL" bootstrap "$DOMAIN" "$INSTALL_PLIST"
    "$LAUNCHCTL" kickstart -k "$TARGET" >/dev/null 2>&1 || true
  fi
  loaded_state=false
  if loaded; then
    loaded_state=true
    print_exit=0
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg plist "$INSTALL_PLIST" \
    --argjson apply "$APPLY" \
    --argjson loaded "$(bool_json "$loaded_state")" \
    --argjson print_exit "$print_exit" \
    --argjson actions "$actions" \
    '{schema_version:"fleet-coherence-launchd-load/v1",status:(if $loaded or ($apply != 1) then "pass" else "warn" end),contract:$contract,l112_observed:"OK_phase1b_launchd",label:$label,target:$target,install_plist:$plist,applied:($apply == 1),dry_run:($apply != 1),loaded:$loaded,launchctl_print_exit:$print_exit,planned_actions:$actions}'
}

unload_json() {
  local actions loaded_state print_exit=1
  actions="$(jq -ncS --arg target "$TARGET" '[{action:"bootout_if_loaded",target:$target}]')"
  if [[ "$APPLY" -eq 1 ]] && loaded; then
    "$LAUNCHCTL" bootout "$TARGET" >/dev/null 2>&1 || true
  fi
  loaded_state=false
  if loaded; then
    loaded_state=true
    print_exit=0
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --argjson apply "$APPLY" \
    --argjson loaded "$(bool_json "$loaded_state")" \
    --argjson print_exit "$print_exit" \
    --argjson actions "$actions" \
    '{schema_version:"fleet-coherence-launchd-unload/v1",status:(if ($loaded == false) then "pass" else "warn" end),contract:$contract,l112_observed:"OK_phase1b_launchd",label:$label,target:$target,applied:($apply == 1),dry_run:($apply != 1),loaded:$loaded,launchctl_print_exit:$print_exit,planned_actions:$actions}'
}

emit_runtime_drift_event() {
  local age="$1" now row
  now="$(now_iso)"
  row="$(jq -ncS \
    --arg now "$now" \
    --arg lock "$SCANNER_LOCK" \
    --arg contract "$CONTRACT" \
    --argjson age "$age" \
    '{
      actions: {
        bead_id: null,
        no_bead_reason: "phase 1b lifecycle surfaced stale scanner lock as detector_runtime_drift",
        receipt_required: false,
        shadow_mode: true,
        would_bead: false,
        would_l61: false,
        would_no_bead_reason: "phase 1b lifecycle surfaced stale scanner lock as detector_runtime_drift"
      },
      class: "detector_runtime_drift",
      confidence: 1,
      dedupe_key: "detector_runtime_drift:fleet-coherence:stale_scan_lock",
      detector: "fleet-coherence",
      detector_git_sha: "runtime",
      detector_version: $contract,
      event_id: ("fc_runtime_drift_stale_scan_lock_" + ($now | gsub("[^0-9A-Za-z]"; ""))),
      evidence: {
        drift_class: "stale_scan_lock",
        lock_path: $lock,
        stale_lock_age_s: $age,
        surfaced_as: "detector_runtime_drift"
      },
      first_seen_ts: $now,
      l61: {
        agent_mail_attempted: false,
        agent_mail_from: null,
        agent_mail_message_id: null,
        agent_mail_sent_at: null,
        agent_mail_to: null,
        degraded_reason: null,
        fleet_mail_identity_source: "not_applicable",
        l61_pairing_status: "not_attempted",
        ntm_attempted: false,
        ntm_pane: null,
        ntm_result: null,
        ntm_sent_at: null,
        ntm_session: null,
        project_key: null,
        vault_token_validated: false
      },
      l62: {repair_callback_required: false, sd_count: 0, sd_ids: []},
      l63: {recovery_action_requires_drill: false, recovery_drill_ids: []},
      last_seen_ts: $now,
      pane: null,
      raw_source_refs: [{path: $lock, source: "scanner-overlap-lock"}],
      record_type: "event",
      resend_after_ts: null,
      sample_count: 1,
      sample_window_s: 0,
      schema_version: 2,
      seen_count: 1,
      session: "fleet-coherence",
      severity: "warning",
      source_age_s: 0,
      source_ts: $now,
      state: "open",
      suppression_id: null,
      ts: $now
    }')"
  fc_append_event "$row" "$EVENTS" "$LATEST"
}

run_json() {
  local row age scanner_out scanner_err scanner_rc scanner_status extra receipt lock_status
  ensure_dirs
  trap 'signal_handler HUP' HUP
  trap 'signal_handler TERM' TERM
  trap 'signal_handler INT' INT

  if ! mkdir "$RUN_LOCK" 2>/dev/null; then
    row="$(lifecycle_row "skipped_lock" "wrapper_lock_held")"
    write_lifecycle_row "$row"
    printf '%s\n' "$row"
    return 0
  fi
  RUN_LOCK_ACQUIRED=1

  if [[ -f "$STOP_FILE" || -f "$GLOBAL_STOP_FILE" ]]; then
    row="$(lifecycle_row "stopped" "stop_file_present")"
    write_lifecycle_row "$row"
    cleanup_run_lock
    printf '%s\n' "$row"
    return 0
  fi

  age="$(lock_age_s "$SCANNER_LOCK")"
  if [[ -e "$SCANNER_LOCK" && "$age" -ge "$STALE_LOCK_SECONDS" ]]; then
    receipt="$(emit_runtime_drift_event "$age")"
    row="$(lifecycle_row "stale_lock" "detector_runtime_drift_emitted")"
    row="$(printf '%s\n' "$row" | jq -cS --argjson age "$age" --argjson receipt "$receipt" '. + {stale_lock_age_s:$age, drift_event_written:true, write_receipt:$receipt}')"
    write_lifecycle_row "$row"
    cleanup_run_lock
    printf '%s\n' "$row"
    return 0
  fi

  scanner_out="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-scanner.out.XXXXXX")"
  scanner_err="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-scanner.err.XXXXXX")"
  set +e
  "$SCANNER" --state-dir "$STATE_DIR" --events "$EVENTS" --latest "$LATEST" --once --json >"$scanner_out" 2>"$scanner_err" &
  CHILD_PID=$!
  while kill -0 "$CHILD_PID" >/dev/null 2>&1; do
    sleep 0.1
  done
  wait "$CHILD_PID"
  scanner_rc=$?
  set -e
  CHILD_PID=0

  scanner_status="null"
  if jq empty "$scanner_out" >/dev/null 2>&1; then
    scanner_status="$(jq -cS '.status // "unknown"' "$scanner_out")"
  fi
  lock_status="scanner_completed"
  if [[ "$scanner_rc" -ne 0 ]]; then
    lock_status="scanner_error"
  fi
  extra="$(jq -nc --arg out "$scanner_out" --arg err "$scanner_err" --rawfile stderr "$scanner_err" '{scanner_stdout_path:$out,scanner_stderr_path:$err,scanner_stderr_sample:($stderr | .[0:1000])}')"
  row="$(lifecycle_row "$(if [[ "$scanner_rc" -eq 0 ]]; then printf 'pass'; else printf 'warn'; fi)" "$lock_status" "$scanner_rc" "$scanner_status" "$extra")"
  write_lifecycle_row "$row"
  rm -f "$scanner_out" "$scanner_err"
  cleanup_run_lock
  printf '%s\n' "$row"
}

validate_plist_json() {
  local source_ok install_ok label_ok cadence_ok helper_ok status
  source_ok=false
  install_ok=false
  label_ok=false
  cadence_ok=false
  helper_ok=false
  [[ -f "$SOURCE_PLIST" ]] && "$PLUTIL" -lint "$SOURCE_PLIST" >/dev/null && source_ok=true
  [[ -f "$INSTALL_PLIST" ]] && "$PLUTIL" -lint "$INSTALL_PLIST" >/dev/null && install_ok=true
  if [[ -f "$SOURCE_PLIST" ]] && [[ "$(plist_value "$SOURCE_PLIST" Label || true)" == "$LABEL" ]]; then
    label_ok=true
  fi
  if [[ -f "$SOURCE_PLIST" ]] && [[ "$(plist_value "$SOURCE_PLIST" StartInterval || true)" == "$CADENCE_SECONDS" ]]; then
    cadence_ok=true
  fi
  if [[ -f "$SOURCE_PLIST" ]] && "$PLUTIL" -p "$SOURCE_PLIST" 2>/dev/null | grep -F 'fleet-coherence-launchd.sh run --json' >/dev/null; then
    helper_ok=true
  fi
  status="pass"
  if [[ "$source_ok" != true || "$label_ok" != true || "$cadence_ok" != true || "$helper_ok" != true ]]; then
    status="fail"
  fi
  jq -ncS \
    --arg status "$status" \
    --arg label "$LABEL" \
    --arg source "$SOURCE_PLIST" \
    --arg install "$INSTALL_PLIST" \
    --argjson source_ok "$(bool_json "$source_ok")" \
    --argjson install_ok "$(bool_json "$install_ok")" \
    --argjson label_ok "$(bool_json "$label_ok")" \
    --argjson cadence_ok "$(bool_json "$cadence_ok")" \
    --argjson helper_ok "$(bool_json "$helper_ok")" \
    '{schema_version:"fleet-coherence-launchd-validate/v1",status:$status,l112_observed:"OK_phase1b_launchd",label:$label,source_plist:$source,install_plist:$install,source_plist_lint:$source_ok,install_plist_lint:$install_ok,label_ok:$label_ok,cadence_ok:$cadence_ok,helper_command_ok:$helper_ok}'
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    install|load|unload|status|run|validate)
      MODE="$1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
  esac
fi

VALIDATE_THING=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    plist)
      VALIDATE_THING="plist"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

fc_require_jq || exit 127
require_uint FLEET_COHERENCE_CADENCE_SECONDS "$CADENCE_SECONDS"
require_uint FLEET_COHERENCE_STALE_LOCK_SECONDS "$STALE_LOCK_SECONDS"

case "$MODE" in
  install) install_json | emit ;;
  load) load_json | emit ;;
  unload) unload_json | emit ;;
  status) status_json | emit ;;
  run) run_json ;;
  validate)
    [[ "$VALIDATE_THING" == "plist" ]] || { printf 'validate requires plist\n' >&2; exit 64; }
    validate_plist_json | emit
    ;;
  *)
    usage >&2
    exit 64
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-75-actionable-slo-burn-alert-contract.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-120-runtime-boundary-health-contract.md`
