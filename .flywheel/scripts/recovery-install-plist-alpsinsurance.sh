#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled in by flywheel-wzjo9.2.4)
# doctor-mode-tier: filled (bead flywheel-wzjo9.2.4 over flywheel-ws02m scaffold)
#
# This block was APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch (Python heredoc that installs the LaunchAgent) runs
# unchanged when no canonical-cli verb is present. Surface-specific logic
# was filled in per .flywheel/audit/flywheel-wzjo9.2.4/apply-spec.md.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="recovery-install-plist-alpsinsurance/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-install-plist-alpsinsurance-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: recovery-install-plist-alpsinsurance.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "recovery-install-plist-alpsinsurance.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "recovery-install-plist-alpsinsurance.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"recovery-install-plist-alpsinsurance.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"recovery-install-plist-alpsinsurance.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"recovery-install-plist-alpsinsurance.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["log_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},fields:{scope:"string",mode:"dry_run|apply",idempotency_key:"string when apply"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["plist-config","repo-path","audit-row"],contract:{rejects_with_rc1:"on missing required fields",label_pattern:"com.zeststream.<session>.watcher"}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string",status:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR idempotency_key OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","scope","mode","idempotency_key"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"recovery-install-plist-alpsinsurance.sh = install com.zeststream.alpsinsurance.watcher LaunchAgent for the alpsinsurance flywheel session"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation: install com.zeststream.alpsinsurance.watcher LaunchAgent (Python heredoc); flags handled by Python argparse (see --help via the Python heredoc)\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: python3 available, launchctl available, launch_agents_dir_writable (~/Library/LaunchAgents), repo_exists (DEFAULT_REPO=/Users/josh/Developer/alpsinsurance), ntm_executable, audit_script_executable, plist_label_valid (com.zeststream.<session>.watcher pattern); thresholds env: none\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/recovery-install-plist-alpsinsurance-runs.jsonl); reports last_run_ts, age_seconds, recent_runs (last 20), total_runs; status=warn if last run >24h old; status=warn if log unreadable\n' ;;
    repair)   printf 'topic: repair --scope <log_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: log_dir (mkdir -p ~/.local/state/flywheel/logs), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: plist-config (label matches com.zeststream.<session>.watcher; plist path resolves under ~/Library/LaunchAgents), repo-path (DEFAULT_REPO exists + is git repo), audit-row (JSONL row shape: ts + action required); rc=1 on schema violation, rc=0 on pass\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail with positional (path, schema, limit); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/idempotency_key/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "recovery-install-plist-alpsinsurance" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "recovery-install-plist-alpsinsurance" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local label="com.zeststream.alpsinsurance.watcher"
  local default_repo="/Users/josh/Developer/alpsinsurance"
  local default_ntm="/Users/josh/.local/bin/ntm"
  local default_audit_script=".flywheel/scripts/recovery-preinstall-audit.sh"
  local launch_agents_dir="$HOME/Library/LaunchAgents"
  local python3_status="fail" launchctl_status="fail" la_dir_status="fail"
  local repo_status="fail" ntm_status="fail" audit_script_status="fail"
  local label_valid="fail" overall="pass"

  if command -v python3 >/dev/null 2>&1; then python3_status="pass"; fi
  if command -v launchctl >/dev/null 2>&1; then launchctl_status="pass"; fi
  if [[ -d "$launch_agents_dir" && -w "$launch_agents_dir" ]]; then la_dir_status="pass"; fi
  if [[ -d "$default_repo" ]]; then repo_status="pass"; fi
  if [[ -x "$default_ntm" ]]; then ntm_status="pass"; fi
  if [[ -x "$_SCAFFOLD_REPO_ROOT/$default_audit_script" ]]; then audit_script_status="pass"; fi
  if [[ "$label" =~ ^com\.zeststream\.[a-z0-9_-]+\.watcher$ ]]; then label_valid="pass"; fi

  for st in "$python3_status" "$launchctl_status" "$la_dir_status" "$label_valid"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$repo_status" "$ntm_status" "$audit_script_status"; do
      if [[ "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg python3_status "$python3_status" \
    --arg launchctl_status "$launchctl_status" \
    --arg la_dir "$launch_agents_dir" --arg la_dir_status "$la_dir_status" \
    --arg repo "$default_repo" --arg repo_status "$repo_status" \
    --arg ntm "$default_ntm" --arg ntm_status "$ntm_status" \
    --arg audit_script "$default_audit_script" --arg audit_script_status "$audit_script_status" \
    --arg label "$label" --arg label_valid "$label_valid" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"python3_available",status:$python3_status},
        {name:"launchctl_available",status:$launchctl_status},
        {name:"launch_agents_dir_writable",status:$la_dir_status,path:$la_dir},
        {name:"repo_exists",status:$repo_status,path:$repo},
        {name:"ntm_executable",status:$ntm_status,path:$ntm},
        {name:"audit_script_executable",status:$audit_script_status,path:$audit_script},
        {name:"plist_label_valid",status:$label_valid,detail:$label}
      ],
      session:"alpsinsurance"
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-install-plist-alpsinsurance-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${RECOVERY_INSTALL_PLIST_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
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
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-install-plist-alpsinsurance-runs.jsonl}"
  local log_dir_path="$HOME/.local/state/flywheel/logs"
  local audit_log_dir; audit_log_dir="$(dirname "$audit_log")"
  local action="" status="ok"
  case "$scope" in
    log_dir)
      if [[ -d "$log_dir_path" ]]; then
        action="log_dir_exists_noop"
      elif [[ "$mode" == "apply" ]]; then
        if mkdir -p "$log_dir_path" 2>/dev/null; then action="log_dir_created"; else action="log_dir_create_failed"; status="fail"; fi
      else
        action="log_dir_create_planned"
      fi
      ;;
    audit_log_dir)
      if [[ -d "$audit_log_dir" ]]; then
        action="audit_log_dir_exists_noop"
      elif [[ "$mode" == "apply" ]]; then
        if mkdir -p "$audit_log_dir" 2>/dev/null; then action="audit_log_dir_created"; else action="audit_log_dir_create_failed"; status="fail"; fi
      else
        action="audit_log_dir_create_planned"
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"repair",status:"refused",reason:"--scope required",valid_scopes:["log_dir","audit_log_dir"]}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",reason:"unknown scope",scope_in:$scope,valid_scopes:["log_dir","audit_log_dir"]}'
      return 64
      ;;
  esac
  local envelope
  envelope="$(jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" --arg action "$action" --arg status "$status" \
    '{schema_version:$sv,command:"repair",status:$status,mode:$mode,scope:$scope,idempotency_key:$idem,action:$action}')"
  printf '%s\n' "$envelope"
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$audit_log" "repair" "$status" \
      "$(jq -nc --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" --arg act "$action" \
          '{scope:$scope,mode:$mode,idempotency_key:$idem,action:$act}')"
  fi
}

scaffold_cmd_validate() {
  local subject="${1:-}" target="${2:-}"
  case "$subject" in
    plist-config)
      local label="com.zeststream.alpsinsurance.watcher"
      local plist_path="$HOME/Library/LaunchAgents/${label}.plist"
      if [[ ! "$label" =~ ^com\.zeststream\.[a-z0-9_-]+\.watcher$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg label "$label" \
          '{schema_version:$sv,command:"validate",subject:"plist-config",status:"fail",label:$label,reason:"label_pattern_mismatch"}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg label "$label" --arg plist "$plist_path" \
        '{schema_version:$sv,command:"validate",subject:"plist-config",status:"pass",label:$label,plist_path:$plist,plist_exists:'"$([[ -f "$plist_path" ]] && echo true || echo false)"'}'
      return 0
      ;;
    repo-path)
      local repo="${target:-/Users/josh/Developer/alpsinsurance}"
      if [[ ! -d "$repo" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$repo" \
          '{schema_version:$sv,command:"validate",subject:"repo-path",status:"fail",path:$p,reason:"missing_or_unreadable"}'
        return 1
      fi
      if [[ ! -d "$repo/.git" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$repo" \
          '{schema_version:$sv,command:"validate",subject:"repo-path",status:"fail",path:$p,reason:"not_a_git_repo"}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$repo" \
        '{schema_version:$sv,command:"validate",subject:"repo-path",status:"pass",path:$p}'
      return 0
      ;;
    audit-row)
      local row="${target:-}"
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"row_required"}'
        return 1
      fi
      if jq -e '.ts and .action' >/dev/null 2>&1 <<<"$row"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"pass"}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"missing_required_fields:ts,action"}'
      return 1
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"--subject required",valid_subjects:["plist-config","repo-path","audit-row"]}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["plist-config","repo-path","audit-row"]}'
      return 64
      ;;
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
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
    return 0
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",audit_log:$log,status:"warn",reason:"audit_log_missing",rows:[]}'
    return 0
  fi
  local rows
  rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s '.' 2>/dev/null || echo '[]')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rows "$rows" --argjson limit "$limit" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"pass",limit:$limit,rows:$rows,row_count:($rows|length)}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match
  match="$(jq -c --arg id "$id" 'select(.ts == $id or (.idempotency_key // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tail -1)"
  if [[ -n "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$match" \
      '{schema_version:$sv,command:"why",id:$id,status:"found",row:$row}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"not_found"}'
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
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
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
import argparse
import json
import os
import plistlib
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

LABEL = "com.zeststream.alpsinsurance.watcher"
SESSION = "alpsinsurance"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
DEFAULT_PLIST = "~/Library/LaunchAgents/com.zeststream.alpsinsurance.watcher.plist"
DEFAULT_STATUS = ".flywheel/receipts/recovery-install-alpsinsurance-status.json"
DEFAULT_AUDIT = "/tmp/preinstall-alpsinsurance.json"
DEFAULT_REPO = "/Users/josh/Developer/alpsinsurance"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
DEFAULT_NTM_CONFIG = "/Users/josh/.config/ntm/config.toml"
DEFAULT_AUDIT_SCRIPT = ".flywheel/scripts/recovery-preinstall-audit.sh"
DEFAULT_LOG_DIR = "~/.local/state/flywheel/logs"


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def ep(path):
    return Path(path).expanduser()


def abs_path(path):
    return str(ep(path).resolve(strict=False))


def run_cmd(args, timeout=10):
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=timeout)
        return {"ok": proc.returncode == 0, "rc": proc.returncode, "stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}
    except FileNotFoundError:
        return {"ok": False, "rc": 127, "stdout": "", "stderr": "command_not_found"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "rc": 124, "stdout": "", "stderr": "timeout"}


def write_json(path, payload):
    p = ep(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def launchctl_label_count(launchctl_bin, label):
    result = run_cmd([launchctl_bin, "list"], timeout=8)
    if not result["ok"]:
        return {"ok": False, "count": 0, "rows": [], "result": {k: result[k] for k in ("ok", "rc", "stderr")}}
    rows = [line for line in result["stdout"].splitlines() if label in line]
    return {"ok": True, "count": len(rows), "rows": rows, "result": {"ok": True, "rc": result["rc"], "stderr": result["stderr"]}}


def run_audit(args):
    audit_path = ep(args.audit_receipt)
    cmd = [
        args.audit_script,
        f"--session={args.session}",
        "--json",
        "--confidence-min",
        str(args.confidence_min),
        "--output",
        str(audit_path),
    ]
    result = run_cmd(cmd, timeout=45)
    if not audit_path.exists() and result["stdout"]:
        try:
            parsed = json.loads(result["stdout"])
            write_json(audit_path, parsed)
        except json.JSONDecodeError:
            pass
    if not audit_path.exists():
        return None, result
    try:
        return json.loads(audit_path.read_text(encoding="utf-8")), result
    except json.JSONDecodeError as exc:
        return {"parse_error": str(exc)}, result


def readiness(args, plist_payload, lint):
    ntm = ep(plist_payload["ProgramArguments"][0])
    config = ep(args.ntm_config)
    repo = ep(args.repo)
    logs_dir = Path(plist_payload["StandardOutPath"]).parent
    return {
        "path": {"value": plist_payload["EnvironmentVariables"]["PATH"], "ready": True},
        "home": {"value": str(Path.home()), "ready": Path.home().is_dir()},
        "ntm_binary": {"path": str(ntm), "exists": ntm.is_file(), "executable": os.access(ntm, os.X_OK)},
        "ntm_config": {"path": abs_path(args.ntm_config), "exists": config.is_file()},
        "repo": {"path": abs_path(args.repo), "exists": repo.is_dir(), "writable": os.access(repo, os.W_OK)},
        "logs_dir": {"path": str(logs_dir), "exists": logs_dir.is_dir(), "writable": os.access(logs_dir, os.W_OK)},
        "plutil": lint,
    }


def readiness_pass(r):
    return (
        r["path"]["ready"]
        and r["home"]["ready"]
        and r["ntm_binary"]["exists"]
        and r["ntm_binary"]["executable"]
        and r["ntm_config"]["exists"]
        and r["repo"]["exists"]
        and r["repo"]["writable"]
        and r["logs_dir"]["exists"]
        and r["logs_dir"]["writable"]
        and r["plutil"]["ok"]
    )


def build_plist(args):
    log_dir = ep(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    env_path = "/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    return {
        "Label": LABEL,
        "ProgramArguments": [
            abs_path(args.ntm_bin),
            "watch",
            args.session,
            "--activity",
            "--interval",
            "2s",
            "--tail",
            "20",
            "--no-color",
            "--no-timestamps",
            "--config",
            abs_path(args.ntm_config),
        ],
        "WorkingDirectory": abs_path(args.repo),
        "StandardOutPath": str(log_dir / "alpsinsurance.watcher.out.log"),
        "StandardErrorPath": str(log_dir / "alpsinsurance.watcher.err.log"),
        "EnvironmentVariables": {
            "PATH": env_path,
            "HOME": str(Path.home()),
            "NTM_CONFIG": abs_path(args.ntm_config),
            "ALPSINSURANCE_REPO": abs_path(args.repo),
        },
        "KeepAlive": {"SuccessfulExit": False},
        "RunAtLoad": True,
        "ThrottleInterval": 10,
    }


def main(argv):
    parser = argparse.ArgumentParser(description="Install the alpsinsurance recovery watcher plist without activating it.")
    parser.add_argument("--session", default=SESSION)
    parser.add_argument("--repo", default=DEFAULT_REPO)
    parser.add_argument("--plist", default=DEFAULT_PLIST)
    parser.add_argument("--status", default=DEFAULT_STATUS)
    parser.add_argument("--audit-receipt", default=DEFAULT_AUDIT)
    parser.add_argument("--audit-script", default=DEFAULT_AUDIT_SCRIPT)
    parser.add_argument("--ntm-bin", default=DEFAULT_NTM)
    parser.add_argument("--ntm-config", default=DEFAULT_NTM_CONFIG)
    parser.add_argument("--launchctl-bin", default="/bin/launchctl")
    parser.add_argument("--plutil-bin", default="/usr/bin/plutil")
    parser.add_argument("--log-dir", default=DEFAULT_LOG_DIR)
    parser.add_argument("--confidence-min", type=int, default=70)
    parser.add_argument("--json", action="store_true", help="Compatibility flag; output is always JSON.")
    args = parser.parse_args(argv)

    audit, audit_result = run_audit(args)
    confidence = None
    if isinstance(audit, dict):
        confidence = (audit.get("confidence_per_session") or {}).get(args.session)

    status = {
        "schema_version": "recovery-session-watcher-install/v1",
        "generated_at": now_iso(),
        "source_plan": SOURCE_PLAN,
        "label": LABEL,
        "session": args.session,
        "audit_receipt_path": str(ep(args.audit_receipt)),
        "audit_command": {k: audit_result[k] for k in ("ok", "rc", "stderr")},
        "audit_confidence": confidence,
        "plist_path": str(ep(args.plist)),
        "dry_run_pass": False,
        "exactly_one_label": False,
        "reboot_recovery_claimed": False,
        "launchctl_load_attempted": False,
        "alpsinsurance_repo_path_validated": ep(args.repo).is_dir(),
    }

    if confidence is None or confidence < args.confidence_min:
        status["status"] = "blocked"
        status["block_reason"] = "low_preinstall_confidence"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 4

    label_state = launchctl_label_count(args.launchctl_bin, LABEL)
    status["launchctl_label_state"] = label_state
    status["exactly_one_label"] = bool(label_state.get("ok") and label_state.get("count", 0) <= 1)
    if not status["exactly_one_label"]:
        status["status"] = "blocked"
        status["block_reason"] = "duplicate_launchd_label"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 5

    plist_path = ep(args.plist)
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    plist_payload = build_plist(args)
    with plist_path.open("wb") as fh:
        plistlib.dump(plist_payload, fh, sort_keys=False)

    lint = run_cmd([args.plutil_bin, "-lint", str(plist_path)], timeout=8)
    ready = readiness(args, plist_payload, lint)
    status.update({
        "status": "installed_not_loaded",
        "dry_run_pass": readiness_pass(ready),
        "readiness": ready,
        "launchd_readiness": ready,
        "program_arguments": plist_payload["ProgramArguments"],
        "working_directory": plist_payload["WorkingDirectory"],
        "stdout_path": plist_payload["StandardOutPath"],
        "stderr_path": plist_payload["StandardErrorPath"],
        "environment": plist_payload["EnvironmentVariables"],
    })
    write_json(args.status, status)
    print(json.dumps(status, sort_keys=True))
    return 0 if status["dry_run_pass"] else 6


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
