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
# WZJO9.1.7 NUANCED-PARTIAL-BYPASS — only --info|--examples route to
# native; --schema + verbs route to scaffold. Sister to 5ke66.8 + 1hshd.{11,16}.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="continuous-productivity-detector-install/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/continuous-productivity-detector-install-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: continuous-productivity-detector-install.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "continuous-productivity-detector-install.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "continuous-productivity-detector-install.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"continuous-productivity-detector-install.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"continuous-productivity-detector-install.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"continuous-productivity-detector-install.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["launch_agents_dir","ledger_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{launch_agents:"CPD_LAUNCH_AGENTS_DIR (default ~/Library/LaunchAgents)",ledger:"CPD_LEDGER (default ~/.local/state/flywheel/continuous-productivity-escalations.jsonl)",audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["launchd-label","interval-seconds","audit-row"],contract:{rejects_with_rc1:"on schema violation",launchd_label_pattern:"^ai\\.zeststream\\.[a-z0-9-]+$",interval_seconds_range:"[30, 3600]"}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR label OR plist OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","label","plist","scope","mode","idempotency_key","interval_seconds"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"continuous-productivity-detector-install.sh = installs GUI-domain LaunchAgent (ai.zeststream.continuous-productivity-detector) that runs the productivity detector every 5min; native --info/--examples PASSTHRU"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run: writes plist for ai.zeststream.continuous-productivity-detector LaunchAgent under gui/$(id -u) domain; --apply enables, --dry-run shows plist contents; --run-once invokes detector immediately bypassing launchd\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, python3 (load-bearing for plistlib write_plist heredoc), launchctl (load-bearing for plist load/unload + bootstrap), detector_executable ($CPD_DETECTOR; load-bearing for what gets run), launch_agents_dir_writable (~/Library/LaunchAgents), audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/continuous-productivity-detector-install-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >30d stale (install is one-shot per upgrade; long stale acceptable)\n' ;;
    repair)   printf 'topic: repair --scope <launch_agents_dir|ledger_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: launch_agents_dir (mkdir -p $CPD_LAUNCH_AGENTS_DIR), ledger_dir (mkdir -p dirname of $CPD_LEDGER), audit_log_dir\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: launchd-label (^ai\\.zeststream\\.[a-z0-9-]+$ matching $CPD_LABEL pattern), interval-seconds ([30, 3600] matching $CPD_INTERVAL_SECONDS default 300), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/label/plist/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (NUANCED-PARTIAL-BYPASS)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "continuous-productivity-detector-install" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "continuous-productivity-detector-install" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root; repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  local detector="${CPD_DETECTOR:-$repo_root/.flywheel/scripts/continuous-productivity-detector.sh}"
  local launch_agents_dir="${CPD_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail" launchctl_status="fail"
  local detector_status="warn" launch_dir_status="fail" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if command -v launchctl >/dev/null 2>&1; then launchctl_status="pass"; fi
  if [[ -x "$detector" ]]; then detector_status="pass"; fi
  if [[ -d "$launch_agents_dir" && -w "$launch_agents_dir" ]]; then launch_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status" "$launchctl_status" "$launch_dir_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$detector_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg python_status "$python_status" --arg launchctl_status "$launchctl_status" \
    --arg detector "$detector" --arg detector_status "$detector_status" \
    --arg launch_dir "$launch_agents_dir" --arg launch_dir_status "$launch_dir_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"python3_available",status:$python_status,detail:"load-bearing for plistlib write_plist heredoc"},
        {name:"launchctl_available",status:$launchctl_status,detail:"load-bearing for plist load/unload + bootstrap"},
        {name:"detector_executable",status:$detector_status,path:$detector,detail:"load-bearing — what the LaunchAgent runs"},
        {name:"launch_agents_dir_writable",status:$launch_dir_status,path:$launch_dir,detail:"plist write target"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/continuous-productivity-detector-install-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CPD_INSTALL_HEALTH_STALE_THRESHOLD_SECONDS:-2592000}"  # 30d (one-shot install)
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
    launch_agents_dir)
      local target="${CPD_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope launch_agents_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    ledger_dir)
      local ledger="${CPD_LEDGER:-$HOME/.local/state/flywheel/continuous-productivity-escalations.jsonl}"
      local target; target="$(dirname "$ledger")"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope ledger_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
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
      printf 'ERR: repair requires --scope <launch_agents_dir|ledger_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["launch_agents_dir","ledger_dir","audit_log_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    launchd-label)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate launchd-label requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^ai\.zeststream\.[a-z0-9-]+$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg label "$arg" \
          '{schema_version:$sv,command:"validate",subject:"launchd-label",ts:$ts,status:"ok",value:$label}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg label "$arg" \
          '{schema_version:$sv,command:"validate",subject:"launchd-label",ts:$ts,status:"reject",value:$label,reason:"pattern_mismatch",pattern:"^ai\\.zeststream\\.[a-z0-9-]+$"}'
        return 1
      fi
      ;;
    interval-seconds)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate interval-seconds requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 30 && arg <= 3600 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"interval-seconds",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"interval-seconds",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[30, 3600]",default:300}'
        return 1
      fi
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["launchd-label","interval-seconds","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["launchd-label","interval-seconds","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.label // "") == $id or (.plist // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","label","plist","run_id"]}'
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
  # WZJO9.1.7 NUANCED-PARTIAL-BYPASS: continuous-productivity-detector-
  # install.sh natively implements --info (canonical envelope:
  # continuous-productivity-detector-install/v1 + label + plist + detector
  # + ledger + canonical_cli list + gui_domain bool) and --examples (text
  # invocations). Native does NOT implement --schema (errors with
  # "unknown argument"). Verb subcommands NOT natively supported.
  # Sister to 5ke66.8 + 1hshd.{11,16}.
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--examples) return 1 ;;  # NUANCED-PARTIAL-BYPASS to native
    --schema) return 0 ;;            # NOT bypassed — scaffold owns
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
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
DETECTOR="${CPD_DETECTOR:-$ROOT/.flywheel/scripts/continuous-productivity-detector.sh}"
LABEL="${CPD_LABEL:-ai.zeststream.continuous-productivity-detector}"
DOMAIN="${CPD_DOMAIN:-gui/$(id -u)}"
LAUNCH_AGENTS_DIR="${CPD_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
LEDGER="${CPD_LEDGER:-$HOME/.local/state/flywheel/continuous-productivity-escalations.jsonl}"
NTM="${CPD_NTM:-/Users/josh/.local/bin/ntm}"
LAUNCHCTL="${CPD_LAUNCHCTL:-launchctl}"
WATCHERS_BIN="${CPD_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
INTERVAL="${CPD_INTERVAL_SECONDS:-300}"
MODE="dry-run"
JSON=0
QUIET=0
NO_NOTIFY=0
usage() {
  cat <<'EOF'
usage: continuous-productivity-detector-install.sh [--apply|--dry-run] [--run-once] [--json] [--quiet] [--no-notify]
Installs a GUI-domain LaunchAgent that runs the continuous productivity
detector every five minutes. The detector is read-only; this runner owns local
ledger append, peer-orchestrator xpane send, and allowlisted Joshua notify.
EOF
}
info_json() {
  jq -nc --arg label "$LABEL" --arg domain "$DOMAIN" --arg plist "$PLIST" --arg detector "$DETECTOR" --arg ledger "$LEDGER" \
    '{schema_version:"continuous-productivity-detector-install/v1",label:$label,domain:$domain,plist:$plist,detector:$detector,ledger:$ledger,canonical_cli:["--info","--help","--examples","--json","--quiet"],gui_domain:($domain|startswith("gui/"))}'
}
examples() {
  cat <<EOF
$0 --dry-run --json
$0 --apply --json
$0 --run-once --json
EOF
}
write_plist() {
  mkdir -p "$LAUNCH_AGENTS_DIR" "$HOME/.local/logs" "$(dirname "$LEDGER")"
  python3 - "$PLIST" "$LABEL" "$SELF" "$INTERVAL" <<'PY'
import plistlib, sys
path, label, script, interval = sys.argv[1:5]
data = {
    "Label": label,
    "ProgramArguments": ["/bin/bash", script, "--run-once", "--quiet"],
    "StartInterval": int(interval),
    "RunAtLoad": False,
    "StandardOutPath": f"{__import__('os').path.expanduser('~')}/.local/logs/continuous-productivity-detector.out.log",
    "StandardErrorPath": f"{__import__('os').path.expanduser('~')}/.local/logs/continuous-productivity-detector.err.log",
}
with open(path, "wb") as handle:
    plistlib.dump(data, handle, sort_keys=False)
PY
}
append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")"
  jq -c . <<<"$row" >>"$LEDGER"
}
run_once() {
  local tmp rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/continuous-productivity.XXXXXX")"
  set +e
  "$DETECTOR" --json >"$tmp"
  rc=$?
  set -e
  if [[ "$rc" -eq 1 ]]; then
    jq -c '.sessions[] | . as $s | $s.planned_actions[] | {ts:now|todateiso8601,event:"continuous_productivity_action",session:$s.session,productivity_state:$s.productivity_state,action:.}' "$tmp" |
      while IFS= read -r row; do
        append_ledger "$row"
        type="$(jq -r '.action.type' <<<"$row")"
        if [[ "$type" == "xpane_productivity_escalation" ]]; then
          session="$(jq -r '.session' <<<"$row")"
          pane="$(jq -r '.action.target_pane' <<<"$row")"
          prompt="$(mktemp "${TMPDIR:-/tmp}/continuous-productivity-prompt.XXXXXX")"
          jq -r '.action.message' <<<"$row" >"$prompt"
          "$NTM" send "$session" --pane="$pane" --no-cass-check --file "$prompt" >/dev/null
        elif [[ "$type" == "josh_notify" && "$NO_NOTIFY" -eq 0 ]]; then
          if command -v notify >/dev/null 2>&1; then
            notify "Flywheel blocker" "$(jq -r '.session + \" \" + .action.allowlist_class' <<<"$row")" || true
          fi
        fi
      done
  fi
  if [[ "$JSON" -eq 1 && "$QUIET" -eq 0 ]]; then
    cat "$tmp"
  fi
  rm -f "$tmp"
  return "$rc"
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply|--install) MODE="apply"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --run-once) MODE="run-once"; shift ;;
    --json) JSON=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --no-notify) NO_NOTIFY=1; shift ;;
    --info) info_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done
if [[ "$MODE" == "run-once" ]]; then
  run_once
  exit $?
fi
if [[ "$MODE" == "apply" ]]; then
  write_plist
  if [[ -x "$WATCHERS_BIN" ]]; then "$WATCHERS_BIN" register --label "$LABEL" --owner flywheel-orch --reason "continuous productivity detector" --bead flywheel-wire-flywheel-owns-continuous-productiv-5ad20901 --apply --idempotency-key "$LABEL" --json >/dev/null; fi
  "$LAUNCHCTL" bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
  "$LAUNCHCTL" bootstrap "$DOMAIN" "$PLIST"
fi
if [[ "$JSON" -eq 1 ]]; then
  jq -nc --arg mode "$MODE" --arg label "$LABEL" --arg domain "$DOMAIN" --arg plist "$PLIST" --argjson interval "$INTERVAL" \
    '{schema_version:"continuous-productivity-detector-install/v1",mode:$mode,label:$label,domain:$domain,plist:$plist,interval_seconds:$interval,gui_domain:($domain|startswith("gui/")),would_bootstrap:($mode=="apply")}'
elif [[ "$QUIET" -eq 0 ]]; then
  printf 'label=%s domain=%s mode=%s plist=%s\n' "$LABEL" "$DOMAIN" "$MODE" "$PLIST"
fi
