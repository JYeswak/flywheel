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
# specific logic has been filled in (no scaffold-stub markers remain).
# WZJO9.1.7 PARTIAL-BYPASS — --info|--schema|--examples flags route to
# native; verb subcommands route to scaffold.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fleet-conformance-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fleet-conformance-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: fleet-conformance-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "fleet-conformance-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "fleet-conformance-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"fleet-conformance-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"fleet-conformance-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"fleet-conformance-probe.sh doctor --json"}'
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
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"doctor",fields:{ts:"ISO8601",status:"pass|warn|fail",checks:"array of {name,status,detail?}"}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{ts:"ISO8601",status:"pass|warn|fail",audit_log:"path",last_run_ts:"ISO8601 or null",age_seconds:"int or null",recent_runs:"int (last 20)",total_runs:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["cache_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["session-name","conformance-axis","audit-row"],contract:{rejects_with_rc1:"on schema violation",session_name_pattern:"^[a-z][a-z0-9_-]*$",conformance_axis_enum:["canonical_l_rule_coverage","doctor_status","identity_drift","meta_rule_cache_freshness","mission_lock_age","agents_mtime_age"]}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR session OR axis OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","session","axis","scope","mode","idempotency_key","conformance_score"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"fleet-conformance-probe.sh = bounded fleet conformance score per session over 6 axes; native --info/--schema/--examples PASSTHRU emits the fleet-conformance-observatory/v1 schema"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run: computes per-session fleet conformance score over 6 axes (canonical_l_rule_coverage / doctor_status / identity_drift / meta_rule_cache_freshness / mission_lock_age / agents_mtime_age); emits fleet_conformance array + red/yellow/green counts + worst session + min score; --apply --dry-run drives mutation discipline (Donella leverage points 5,6 per native --info)\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, python3 (load-bearing for fleet-conformance heredoc), loops_dir_readable (~/.flywheel/loops), canonical_agents_readable (~/.flywheel/canonical-agents.json), audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/fleet-conformance-probe-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >12h stale (intra-day cadence)\n' ;;
    repair)   printf 'topic: repair --scope <cache_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: cache_dir (mkdir -p $CACHE_DIR for the 60s default-TTL conformance cache), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: session-name (matches ^[a-z][a-z0-9_-]*$), conformance-axis (must be one of the 6 axes from native --info: canonical_l_rule_coverage|doctor_status|identity_drift|meta_rule_cache_freshness|mission_lock_age|agents_mtime_age), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/session/axis/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (PARTIAL-BYPASS: --info/--schema/--examples flags route to native)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "fleet-conformance-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fleet-conformance-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local loops_dir="$HOME/.flywheel/loops"
  local canonical_agents="$HOME/.flywheel/canonical-agents.json"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail"
  local loops_status="warn" canonical_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if [[ -d "$loops_dir" ]]; then loops_status="pass"; fi
  if [[ -r "$canonical_agents" ]]; then canonical_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$loops_status" "$canonical_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg python_status "$python_status" \
    --arg loops_dir "$loops_dir" --arg loops_status "$loops_status" \
    --arg canonical "$canonical_agents" --arg canonical_status "$canonical_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"python3_available",status:$python_status,detail:"load-bearing for fleet-conformance heredoc"},
        {name:"loops_dir_readable",status:$loops_status,path:$loops_dir,detail:"per-session loop state for conformance scoring"},
        {name:"canonical_agents_readable",status:$canonical_status,path:$canonical,detail:"identity drift baseline"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fleet-conformance-probe-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${FLEET_CONFORMANCE_PROBE_HEALTH_STALE_THRESHOLD_SECONDS:-43200}"
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$audit_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0}'
    return 0
  fi
  total_runs="$(wc -l < "$audit_log" 2>/dev/null | tr -d ' ' || echo 0)"
  recent_runs="$(tail -20 "$audit_log" 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  last_run_ts="$(tail -1 "$audit_log" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
  if [[ -n "$last_run_ts" ]]; then
    now="$(date -u +%s)"
    local last_epoch
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_run_ts" +%s 2>/dev/null \
                  || date -u -d "$last_run_ts" +%s 2>/dev/null \
                  || echo 0)"
    age_seconds=$((now - last_epoch))
    if [[ "$age_seconds" -gt "$stale_threshold" ]]; then status="warn"; fi
  else
    age_seconds=null
    status="warn"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" \
    --arg log "$audit_log" --arg last_run_ts "$last_run_ts" \
    --argjson age "${age_seconds:-null}" \
    --argjson total "$total_runs" --argjson recent "$recent_runs" \
    --argjson stale "$stale_threshold" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,
      last_run_ts:(if $last_run_ts == "" then null else $last_run_ts end),
      age_seconds:$age, recent_runs:$recent, total_runs:$total,
      stale_threshold_seconds:$stale}'
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
    cache_dir)
      local target="${FLEET_CONFORMANCE_CACHE_DIR:-$HOME/.local/state/flywheel/fleet-conformance-cache}"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope cache_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true"),note:"60s default-TTL conformance cache target"}'
      ;;
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope audit_log_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <cache_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["cache_dir","audit_log_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    session-name)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate session-name requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"ok",value:$s}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"reject",value:$s,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    conformance-axis)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate conformance-axis requires VALUE arg\n' >&2; return 64
      fi
      case "$arg" in
        canonical_l_rule_coverage|doctor_status|identity_drift|meta_rule_cache_freshness|mission_lock_age|agents_mtime_age)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"conformance-axis",ts:$ts,status:"ok",value:$v}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"conformance-axis",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_axes:["canonical_l_rule_coverage","doctor_status","identity_drift","meta_rule_cache_freshness","mission_lock_age","agents_mtime_age"],source:"native --info axes field"}'
          return 1 ;;
      esac
      ;;
    audit-row)
      if [[ -z "$arg" || ! -r "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"reject",path:$path,reason:"file_not_readable"}'
        return 1
      fi
      local bad; bad="$(jq -c 'select((.ts // empty) == "" or (.action // empty) == "") | {missing: ([(if (.ts // empty) == "" then "ts" else empty end), (if (.action // empty) == "" then "action" else empty end)])}' "$arg" 2>/dev/null | head -5 || true)"
      if [[ -n "$bad" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" --arg bad "$bad" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"reject",path:$path,reason:"missing_required_fields",sample:$bad}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
        '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"ok",path:$path}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["session-name","conformance-axis","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["session-name","conformance-axis","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.session // "") == $id or (.axis // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","session","axis","run_id"]}'
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
_scaffold_is_canonical_arg() {
  # WZJO9.1.7 PARTIAL-BYPASS: fleet-conformance-probe.sh natively
  # implements --info / --schema / --examples in its python heredoc with
  # canonical-flavored envelopes (schema_version "fleet-conformance-
  # observatory/v1", full JSON-Schema for fleet_conformance result, and
  # text example invocations). These are richer than scaffold's generic
  # introspection, so all three flags PASSTHRU to native. Verb subcommands
  # (doctor/health/repair/validate/audit/why) are NOT natively supported
  # — scaffold owns those. (The script does have a NATIVE --doctor FLAG
  # but no `doctor` SUBCOMMAND, so verb form goes scaffold cleanly.)
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 1 ;;  # PARTIAL-BYPASS to native
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

SCHEMA_VERSION = "fleet-conformance-observatory/v1"
DEFAULT_ROOT = Path("/Users/josh/Developer")
DEFAULT_LOOPS_DIR = Path.home() / ".flywheel" / "loops"
DEFAULT_CANONICAL = Path("/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md")
DEFAULT_CACHE_DIR = Path.home() / ".local/state/flywheel/fleet-conformance-cache"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
GREEN_MIN = 85
YELLOW_MIN = 60

AXIS_WEIGHTS = {
    "canonical_l_rule_coverage": 25,
    "doctor_status": 20,
    "identity_drift": 15,
    "meta_rule_cache_freshness": 15,
    "mission_lock_age": 15,
    "agents_mtime_age": 10,
}


def emit(obj: dict) -> None:
    print(json.dumps(obj, separators=(",", ":"), sort_keys=True))


def load_json(path: Path, default):
    try:
        with path.open() as f:
            return json.load(f)
    except Exception:
        return default


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + f".tmp.{os.getpid()}")
    tmp.write_text(json.dumps(payload, separators=(",", ":"), sort_keys=True), encoding="utf-8")
    tmp.replace(path)


def stable_key(args: argparse.Namespace) -> str:
    material = {
        "session": args.session,
        "fleet": args.fleet,
        "root": str(args.root),
        "loops_dir": str(args.loops_dir),
        "canonical_agents": str(args.canonical_agents),
        "skip_doctor": bool(os.environ.get("FLYWHEEL_CONFORMANCE_SKIP_DOCTOR")),
    }
    return hashlib.sha256(json.dumps(material, sort_keys=True).encode()).hexdigest()[:16]


def cache_path(args: argparse.Namespace) -> Path:
    return Path(args.cache_dir).expanduser() / f"{stable_key(args)}.json"


def cache_fresh(path: Path, ttl: int, now_epoch: int) -> bool:
    if ttl <= 0 or not path.exists():
        return False
    try:
        return now_epoch - int(path.stat().st_mtime) <= ttl
    except Exception:
        return False


def read_l_rules(path: Path) -> set[str]:
    if not path.exists():
        return set()
    rules: set[str] = set()
    pattern = re.compile(r"^## (L[0-9]+)\b")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.match(line)
        if match:
            rules.add(match.group(1))
    return rules


def sort_rules(rules: set[str]) -> list[str]:
    return sorted(rules, key=lambda item: int(item[1:]))


def intish(value, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def pct(numer: int, denom: int) -> int:
    if denom <= 0:
        return 100
    return max(0, min(100, round((numer / denom) * 100)))


def status_for_score(score: int) -> str:
    if score >= GREEN_MIN:
        return "green"
    if score >= YELLOW_MIN:
        return "yellow"
    return "red"


def axis(name: str, score: int, status: str | None = None, **details) -> dict:
    score = max(0, min(100, int(score)))
    return {
        "name": name,
        "score": score,
        "status": status or status_for_score(score),
        "weight": AXIS_WEIGHTS[name],
        **details,
    }


def run_json(cmd: list[str], timeout: int = 8):
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL, timeout=timeout)
        return json.loads(out)
    except Exception:
        return None


def loop_sessions(args: argparse.Namespace) -> list[dict]:
    loops_dir = Path(args.loops_dir).expanduser()
    sessions: dict[str, dict] = {}
    for path in sorted(loops_dir.glob("*.json")):
        data = load_json(path, {})
        if data.get("active") is False:
            continue
        session = data.get("session") or path.stem
        if args.session and session != args.session:
            continue
        repo = data.get("repo_path") or data.get("repo") or data.get("project_path")
        sessions[session] = {
            "session": session,
            "repo": str(Path(str(repo)).expanduser()) if repo else "",
            "orchestrator_pane": intish(data.get("orchestrator_pane") or 1, 1),
            "loop_file": str(path),
        }

    root = Path(args.root).expanduser()
    if root.exists():
        for candidate in sorted(root.iterdir()):
            if not candidate.is_dir():
                continue
            loop = candidate / ".flywheel" / "loop.json"
            if not loop.exists():
                continue
            data = load_json(loop, {})
            session = data.get("session") or candidate.name
            if args.session and session != args.session:
                continue
            sessions.setdefault(
                session,
                {
                    "session": session,
                    "repo": str(candidate),
                    "orchestrator_pane": intish(data.get("orchestrator_pane") or 1, 1),
                    "loop_file": str(loop),
                },
            )
    return sorted(sessions.values(), key=lambda row: row["session"])


def axis_l_rules(repo: Path, canonical_rules: set[str]) -> dict:
    target_rules = read_l_rules(repo / "AGENTS.md")
    missing = sort_rules(canonical_rules - target_rules)
    score = pct(len(canonical_rules) - len(missing), len(canonical_rules))
    return axis(
        "canonical_l_rule_coverage",
        score,
        canonical_rule_count=len(canonical_rules),
        target_rule_count=len(target_rules),
        missing_rules=missing,
        missing_count=len(missing),
    )


def axis_agents_mtime(repo: Path, now_epoch: int) -> dict:
    path = repo / "AGENTS.md"
    if not path.exists():
        return axis("agents_mtime_age", 0, "red", path=str(path), age_seconds=None, reason="missing")
    age = max(0, now_epoch - int(path.stat().st_mtime))
    week = 7 * 24 * 3600
    score = 100 if age <= week else max(0, 100 - round(((age - week) / week) * 100))
    return axis("agents_mtime_age", score, path=str(path), age_seconds=age, fresh_threshold_seconds=week)


def axis_meta_rule_cache(repo: Path, now_epoch: int) -> dict:
    path = repo / ".flywheel" / "META-RULE-CACHE.md"
    if not path.exists():
        return axis("meta_rule_cache_freshness", 0, "red", path=str(path), age_seconds=None, reason="missing")
    age = max(0, now_epoch - int(path.stat().st_mtime))
    day = 24 * 3600
    score = 100 if age <= day else max(0, 100 - round(((age - day) / day) * 100))
    return axis("meta_rule_cache_freshness", score, path=str(path), age_seconds=age, fresh_threshold_seconds=day)


def axis_mission_lock(repo: Path) -> dict:
    probe = Path("/Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-age-probe.sh")
    if not probe.exists():
        return axis("mission_lock_age", 60, "yellow", reason="mission_lock_probe_missing")
    out = run_json([str(probe), "--repo", str(repo), "--doctor", "--json"], timeout=5)
    if not isinstance(out, dict):
        return axis("mission_lock_age", 60, "yellow", reason="mission_lock_probe_invalid")
    status = out.get("mission_lock_status") or out.get("state") or "unknown"
    score = {
        "fresh": 100,
        "stale-warn": 70,
        "stale-error": 25,
        "unlocked": 0,
        "missing": 0,
    }.get(str(status), 60)
    return axis(
        "mission_lock_age",
        score,
        mission_lock_status=status,
        mission_lock_age_hours=out.get("mission_lock_age_hours"),
        lock_hash_matches_lock_log=out.get("lock_hash_matches_lock_log"),
    )


def doctor_fixture(args: argparse.Namespace, session: str):
    if not args.doctor_fixture_dir:
        return None
    path = Path(args.doctor_fixture_dir).expanduser() / f"{session}.json"
    return load_json(path, None) if path.exists() else None


def doctor_doc(args: argparse.Namespace, session: str, repo: Path):
    fixture = doctor_fixture(args, session)
    if fixture is not None:
        return fixture
    if os.environ.get("FLYWHEEL_CONFORMANCE_SKIP_DOCTOR"):
        return {"skipped": True, "reason": "recursive_doctor_guard"}
    loop_bin = "/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop"
    if not Path(loop_bin).exists():
        return {"status": "warn", "errors": [], "warnings": [{"code": "flywheel_loop_missing"}]}
    return run_json([loop_bin, "doctor", "--repo", str(repo), "--json"], timeout=8) or {
        "status": "warn",
        "errors": [],
        "warnings": [{"code": "doctor_probe_failed"}],
    }


def axis_doctor(doc: dict) -> dict:
    if doc.get("skipped"):
        return axis("doctor_status", 100, "green", skipped=True, reason=doc.get("reason"))
    errors = doc.get("errors") if isinstance(doc.get("errors"), list) else []
    warnings = doc.get("warnings") if isinstance(doc.get("warnings"), list) else []
    status = str(doc.get("status") or "")
    if errors or status == "fail":
        score = 0
    elif warnings or status in {"warn", "interrupt"}:
        score = 70
    else:
        score = 100
    return axis("doctor_status", score, doctor_status=status or "unknown", error_count=len(errors), warning_count=len(warnings))


def axis_identity(doc: dict) -> dict:
    if doc.get("skipped"):
        return axis("identity_drift", 100, "green", skipped=True, reason=doc.get("reason"))
    fields = {
        "identity_registry_drift": intish(doc.get("identity_registry_drift")),
        "fleet_identity_drift_count": intish(doc.get("fleet_identity_drift_count")),
        "orchestrator_unknown_worker_identity_count": intish(doc.get("orchestrator_unknown_worker_identity_count")),
        "identity_token_orphan_local": intish(doc.get("identity_token_orphan_local")),
        "agentmail_orphan_session_rows_count": intish(doc.get("agentmail_orphan_session_rows_count")),
    }
    total = sum(fields.values())
    score = 100 if total == 0 else max(0, 100 - min(100, total * 25))
    return axis("identity_drift", score, drift_total=total, **fields)


def score_session(args: argparse.Namespace, session: dict, canonical_rules: set[str], now_epoch: int) -> dict:
    repo = Path(session["repo"]).expanduser()
    doc = doctor_doc(args, session["session"], repo)
    axes = [
        axis_l_rules(repo, canonical_rules),
        axis_doctor(doc),
        axis_identity(doc),
        axis_meta_rule_cache(repo, now_epoch),
        axis_mission_lock(repo),
        axis_agents_mtime(repo, now_epoch),
    ]
    weight_total = sum(int(a["weight"]) for a in axes)
    composite = round(sum(int(a["score"]) * int(a["weight"]) for a in axes) / weight_total) if weight_total else 0
    status = status_for_score(composite)
    return {
        **session,
        "repo_exists": repo.exists(),
        "score": composite,
        "status": status,
        "axes": axes,
        "red_axes": [a["name"] for a in axes if a["status"] == "red"],
        "yellow_axes": [a["name"] for a in axes if a["status"] == "yellow"],
    }


def packet_for(row: dict) -> str:
    red_axes = ",".join(row.get("red_axes") or ["none"])
    return (
        "CONFORMANCE-DRIFT "
        f"session={row['session']} score={row['score']} status={row['status']} "
        f"repo={row.get('repo','')} red_axes={red_axes} "
        "action=repair_fleet_conformance_axes"
    )


def send_packets(rows: list[dict], args: argparse.Namespace) -> list[dict]:
    actions = []
    for row in rows:
        if row["status"] != "red":
            continue
        packet = packet_for(row)
        action = {
            "type": "xpane_conformance_drift",
            "session": row["session"],
            "pane": row.get("orchestrator_pane") or 1,
            "packet": packet,
            "dry_run": bool(args.dry_run or not args.apply),
        }
        if args.apply and not args.dry_run:
            try:
                subprocess.check_call(
                    [args.ntm, "send", row["session"], f"--pane={action['pane']}", "--no-cass-check", packet],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=5,
                )
                action["sent"] = True
            except Exception as exc:
                action["sent"] = False
                action["error"] = str(exc)
        actions.append(action)
    return actions


def build_payload(args: argparse.Namespace) -> dict:
    now_epoch = int(args.now_epoch or time.time())
    canonical_rules = read_l_rules(Path(args.canonical_agents).expanduser())
    sessions = loop_sessions(args)
    rows = [score_session(args, session, canonical_rules, now_epoch) for session in sessions]
    green = sum(1 for row in rows if row["status"] == "green")
    yellow = sum(1 for row in rows if row["status"] == "yellow")
    red = sum(1 for row in rows if row["status"] == "red")
    worst = min(rows, key=lambda row: row["score"], default=None)
    actions = send_packets(rows, args)
    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if red == 0 else "fail",
        "mode": "doctor" if args.doctor else "fleet",
        "checked_at_epoch": now_epoch,
        "thresholds": {"green_min_score": GREEN_MIN, "yellow_min_score": YELLOW_MIN},
        "axes_implemented": list(AXIS_WEIGHTS.keys()),
        "axis_weights": AXIS_WEIGHTS,
        "canonical_agents": str(Path(args.canonical_agents).expanduser()),
        "canonical_rule_count": len(canonical_rules),
        "fleet_conformance_green_count": green,
        "fleet_conformance_yellow_count": yellow,
        "fleet_conformance_red_count": red,
        "fleet_conformance_total_count": len(rows),
        "fleet_conformance_min_score": worst["score"] if worst else None,
        "fleet_conformance_worst_session": worst["session"] if worst else None,
        "fleet_conformance": rows,
        "planned_packets": actions,
    }
    return payload


def emit_info() -> None:
    emit(
        {
            "schema_version": SCHEMA_VERSION,
            "purpose": "Compute one bounded fleet conformance score per flywheel session.",
            "donella_leverage_points": [5, 6],
            "anti_agent_shaming": True,
            "mutates_only_with": "--apply without --dry-run",
            "cache_ttl_seconds_default": 60,
            "canonical_cli_flags": [
                "--json",
                "--fleet",
                "--session=<name>",
                "--apply",
                "--dry-run",
                "--doctor",
                "--info",
                "--examples",
                "--schema",
            ],
            "axes": list(AXIS_WEIGHTS.keys()),
        }
    )


def emit_schema() -> None:
    emit(
        {
            "schema_version": SCHEMA_VERSION,
            "type": "object",
            "required": [
                "fleet_conformance",
                "fleet_conformance_red_count",
                "fleet_conformance_yellow_count",
                "fleet_conformance_green_count",
                "fleet_conformance_worst_session",
                "fleet_conformance_min_score",
            ],
            "properties": {
                "fleet_conformance": {"type": "array"},
                "fleet_conformance_red_count": {"type": "integer"},
                "fleet_conformance_yellow_count": {"type": "integer"},
                "fleet_conformance_green_count": {"type": "integer"},
                "fleet_conformance_worst_session": {"type": ["string", "null"]},
                "fleet_conformance_min_score": {"type": ["integer", "null"]},
            },
        }
    )


def emit_examples() -> None:
    print("\n".join(
        [
            ".flywheel/scripts/fleet-conformance-probe.sh --fleet --json",
            ".flywheel/scripts/fleet-conformance-probe.sh --session flywheel --json",
            ".flywheel/scripts/fleet-conformance-probe.sh --fleet --apply --dry-run --json",
            "FLYWHEEL_CONFORMANCE_SKIP_DOCTOR=1 .flywheel/scripts/fleet-conformance-probe.sh --doctor --json",
        ]
    ))


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--fleet", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--session")
    parser.add_argument("--root", default=str(DEFAULT_ROOT))
    parser.add_argument("--loops-dir", default=str(DEFAULT_LOOPS_DIR))
    parser.add_argument("--canonical-agents", default=str(DEFAULT_CANONICAL))
    parser.add_argument("--cache-dir", default=str(DEFAULT_CACHE_DIR))
    parser.add_argument("--cache-ttl", type=int, default=60)
    parser.add_argument("--no-cache", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--ntm", default=DEFAULT_NTM)
    parser.add_argument("--doctor-fixture-dir")
    parser.add_argument("--now-epoch", type=int)
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    args = parser.parse_args(argv)
    args.root = Path(args.root)
    args.loops_dir = Path(args.loops_dir)
    args.canonical_agents = Path(args.canonical_agents)
    args.cache_dir = Path(args.cache_dir)
    if args.doctor:
        args.fleet = True
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.info:
        emit_info()
        return 0
    if args.schema:
        emit_schema()
        return 0
    if args.examples:
        emit_examples()
        return 0

    now_epoch = int(args.now_epoch or time.time())
    path = cache_path(args)
    if not args.no_cache and not args.apply and cache_fresh(path, args.cache_ttl, now_epoch):
        payload = load_json(path, None)
        if isinstance(payload, dict):
            payload["cache_hit"] = True
            emit(payload)
            return 0 if payload.get("status") != "fail" else 1

    payload = build_payload(args)
    payload["cache_hit"] = False
    if not args.no_cache and not args.apply:
        write_json(path, payload)
    emit(payload)
    return 0 if payload.get("status") != "fail" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
