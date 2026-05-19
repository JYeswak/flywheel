#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled in by flywheel-kz7o0)
# doctor-mode-tier: filled (bead flywheel-kz7o0 over flywheel-ws02m scaffold)
#
# This block was APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch (Python heredoc probing fleet comms substrate) runs
# unchanged when no canonical-cli verb is present. Surface-specific logic
# was filled in per .flywheel/audit/flywheel-jloib/wave-1-apply-spec.md.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fleet-comms-health-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fleet-comms-health-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: fleet-comms-health-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "fleet-comms-health-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "fleet-comms-health-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"fleet-comms-health-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"fleet-comms-health-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"fleet-comms-health-probe.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["state_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["session-topology-row","ledger-path","audit-row"],contract:{rejects_with_rc1:"on schema violation",ledger_path_constraint:"under ~/.local/state/flywheel/ AND .jsonl extension"}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR session OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","session","scope","mode","idempotency_key"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"fleet-comms-health-probe.sh = probe loops dir + agent-mail state + ntm tokens + coordination/peer-orch/productivity ledgers; bash wrapper around Python heredoc"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation: bash wrapper invokes Python heredoc that probes ~/.flywheel/loops/, ~/.local/state/flywheel/agent-mail/, ntm tokens, coordination ledger, peer-orch blockers, productivity escalations; flags handled by Python argparse\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: python3 available, jq available, repo_root resolvable, loops_dir present (~/.flywheel/loops/), agent_mail_state_dir present (~/.local/state/flywheel/agent-mail/), ntm executable, audit_log_dir writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/fleet-comms-health-probe-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >24h stale\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p ~/.local/state/flywheel), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: session-topology-row (JSONL row from session-topology.jsonl: session+orchestrator_pane+orchestrator_kind+effective_at required), ledger-path (under ~/.local/state/flywheel/ AND .jsonl extension), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/session/run_id; states: found / not_found / unavailable\n' ;;
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
            && cli_emit_completion_bash "fleet-comms-health-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fleet-comms-health-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root; repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  local home="$HOME"
  local loops_dir="$home/.flywheel/loops"
  local am_state_dir="$home/.local/state/flywheel/agent-mail"
  local ntm_path="$home/.local/bin/ntm"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"

  local python3_status="fail" jq_status="fail" repo_status="fail"
  local loops_status="warn" am_status="warn" ntm_status="fail" audit_dir_status="fail"
  local overall="pass"

  if command -v python3 >/dev/null 2>&1; then python3_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if [[ -n "$repo_root" ]]; then repo_status="pass"; fi
  if [[ -d "$loops_dir" ]]; then loops_status="pass"; fi
  if [[ -d "$am_state_dir" ]]; then am_status="pass"; fi
  if [[ -x "$ntm_path" ]]; then ntm_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$python3_status" "$jq_status" "$repo_status" "$ntm_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$loops_status" "$am_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg python3_status "$python3_status" \
    --arg jq_status "$jq_status" \
    --arg repo "$repo_root" --arg repo_status "$repo_status" \
    --arg loops "$loops_dir" --arg loops_status "$loops_status" \
    --arg am "$am_state_dir" --arg am_status "$am_status" \
    --arg ntm "$ntm_path" --arg ntm_status "$ntm_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"python3_available",status:$python3_status},
        {name:"jq_available",status:$jq_status},
        {name:"repo_root_resolvable",status:$repo_status,detail:$repo},
        {name:"loops_dir_present",status:$loops_status,path:$loops},
        {name:"agent_mail_state_dir_present",status:$am_status,path:$am},
        {name:"ntm_executable",status:$ntm_status,path:$ntm},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fleet-comms-health-probe-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${FLEET_COMMS_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
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
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fleet-comms-health-probe-runs.jsonl}"
  local state_dir="$HOME/.local/state/flywheel"
  local audit_log_dir; audit_log_dir="$(dirname "$audit_log")"
  local action="" status="ok"
  case "$scope" in
    state_dir)
      if [[ -d "$state_dir" ]]; then
        action="state_dir_exists_noop"
      elif [[ "$mode" == "apply" ]]; then
        if mkdir -p "$state_dir" 2>/dev/null; then action="state_dir_created"; else action="state_dir_create_failed"; status="fail"; fi
      else
        action="state_dir_create_planned"
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
        '{schema_version:$sv,command:"repair",status:"refused",reason:"--scope required",valid_scopes:["state_dir","audit_log_dir"]}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",reason:"unknown scope",scope_in:$scope,valid_scopes:["state_dir","audit_log_dir"]}'
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
    session-topology-row)
      local row="${target:-}"
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"session-topology-row",status:"fail",reason:"row_required"}'
        return 1
      fi
      if jq -e '.session and .orchestrator_pane and .orchestrator_kind and .effective_at' >/dev/null 2>&1 <<<"$row"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"session-topology-row",status:"pass"}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"session-topology-row",status:"fail",reason:"missing_required_fields:session,orchestrator_pane,orchestrator_kind,effective_at"}'
      return 1
      ;;
    ledger-path)
      if [[ -z "$target" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"ledger-path",status:"fail",reason:"path_required"}'
        return 1
      fi
      local home_state="$HOME/.local/state/flywheel"
      if [[ "$target" != "$home_state"/* ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$target" --arg constraint "$home_state" \
          '{schema_version:$sv,command:"validate",subject:"ledger-path",status:"fail",path:$p,reason:"not_under_state_dir",constraint:$constraint}'
        return 1
      fi
      if [[ "$target" != *.jsonl ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$target" \
          '{schema_version:$sv,command:"validate",subject:"ledger-path",status:"fail",path:$p,reason:"not_jsonl_extension",constraint:"*.jsonl"}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$target" \
        '{schema_version:$sv,command:"validate",subject:"ledger-path",status:"pass",path:$p,exists:'"$([[ -e "$target" ]] && echo true || echo false)"'}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"--subject required",valid_subjects:["session-topology-row","ledger-path","audit-row"]}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["session-topology-row","ledger-path","audit-row"]}'
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
  match="$(jq -c --arg id "$id" 'select(.ts == $id or (.idempotency_key // "") == $id or (.session // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tail -1)"
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
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

VERSION = "fleet-comms-health/v1"
DEFAULT_LOOPS_DIR = Path.home() / ".flywheel" / "loops"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel"
DEFAULT_AGENT_MAIL_DIR = DEFAULT_STATE_DIR / "agent-mail"
DEFAULT_TOKEN_JSON_DIR = DEFAULT_STATE_DIR / "agent-mail-tokens"
DEFAULT_COORD = DEFAULT_STATE_DIR / "cross-orch-coordination.jsonl"
DEFAULT_PEER_BLOCKER = DEFAULT_STATE_DIR / "peer-orch-blocker-watch.jsonl"
DEFAULT_PRODUCTIVITY = DEFAULT_STATE_DIR / "productivity-escalations.jsonl"
DEFAULT_LEDGER = DEFAULT_STATE_DIR / "fleet-comms-health.jsonl"
DEFAULT_TOPOLOGY = DEFAULT_STATE_DIR / "session-topology.jsonl"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
TOKEN_WARN_SECONDS = 7 * 86400
TOKEN_FAIL_SECONDS = 30 * 86400
PACKET_WARN_SECONDS = 24 * 3600
PACKET_FAIL_SECONDS = 72 * 3600
UNREAD_ESCALATION_SECONDS = 3600

BLOCKER_RE = re.compile(r"(blocker|blocked|doctor_error|xpane_blocker|flywheel_class)", re.I)
ACK_RE = re.compile(r"(ack|unblock|fixed|ratified|response|resolved|broadcast|consumed)", re.I)
PENDING_PRODUCTIVITY_EVENTS = {"productivity_escalation_sent", "true_josh_blocker_notify"}
RESOLVED_PRODUCTIVITY_RE = re.compile(r"(ack|consumed|resolved|closed|fixed)", re.I)


def parse_ts(value):
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(float(value), timezone.utc)
    text = str(value).strip()
    if not text:
        return None
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def now_utc(override):
    return parse_ts(override) or datetime.now(timezone.utc)


def load_json(path, default):
    try:
        with Path(path).open(encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def load_jsonl(path):
    rows = []
    path = Path(path)
    if not path.exists():
        return rows
    try:
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        return rows
    for line_no, line in enumerate(lines, 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            row["__line"] = line_no
            rows.append(row)
    return rows


def intish(value, default=0):
    try:
        return int(value)
    except Exception:
        return default


def run_json(cmd, default, timeout=8):
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=timeout)
        return json.loads(out)
    except Exception:
        return default


def append_jsonl(path, row):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def session_name_from_path(path):
    return Path(path).stem


def loop_sessions(args):
    loops_dir = Path(args.loops_dir)
    sessions = []
    if loops_dir.exists():
        for path in sorted(loops_dir.glob("*.json")):
            data = load_json(path, {})
            if not isinstance(data, dict) or data.get("active") is False:
                continue
            session = data.get("session") or session_name_from_path(path)
            if args.session and session != args.session:
                continue
            if not args.fleet and not args.session and session != "flywheel":
                continue
            sessions.append({"session": session, "loop": data, "loop_path": str(path)})
    if args.session and not any(s["session"] == args.session for s in sessions):
        sessions.append({"session": args.session, "loop": {"session": args.session}, "loop_path": None})
    return sessions


def latest_topology(rows, session):
    matches = [r for r in rows if r.get("session") == session]
    if not matches:
        return {}
    return sorted(matches, key=lambda r: str(r.get("effective_at") or r.get("ts") or ""))[-1]


def text_values(value):
    if value is None:
        return []
    if isinstance(value, list):
        out = []
        for item in value:
            out.extend(text_values(item))
        return out
    if isinstance(value, dict):
        out = []
        for item in value.values():
            out.extend(text_values(item))
        return out
    return [str(value)]


def row_mentions_session(row, session):
    candidates = []
    for key in ("session", "source_session", "target_session", "sender", "from", "receiver", "to", "target", "row_key"):
        candidates.extend(text_values(row.get(key)))
    if any(v == session or v.startswith(session + ":") for v in candidates):
        return True
    compact = json.dumps(row, sort_keys=True, default=str)
    return bool(re.search(r"(^|[^A-Za-z0-9_.-])" + re.escape(session) + r"(:|[^A-Za-z0-9_.-]|$)", compact))


def row_ts(row):
    for key in ("ts", "created_at", "created_ts", "time", "timestamp", "sent_at"):
        parsed = parse_ts(row.get(key))
        if parsed:
            return parsed
    return None


def axis(name, score, status, value=None, reason=None, **extra):
    payload = {"name": name, "score": int(score), "status": status}
    if value is not None:
        payload["value"] = value
    if reason:
        payload["reason"] = reason
    payload.update(extra)
    return payload


def registry_rows(agent_mail_dir, session):
    session_dir = Path(agent_mail_dir) / "sessions"
    rows = []
    if not session_dir.exists():
        return rows
    for path in sorted(session_dir.glob("*.json")):
        row = load_json(path, {})
        if not isinstance(row, dict):
            continue
        if row.get("session") != session:
            continue
        row = dict(row)
        row["_path"] = str(path)
        rows.append(row)
    return rows


def token_candidates(row, args):
    identity = row.get("identity_name")
    candidates = []
    if row.get("token_path"):
        candidates.append(Path(str(row["token_path"])).expanduser())
    if identity:
        candidates.append(Path(args.agent_mail_dir) / "tokens" / f"{identity}.token")
        candidates.append(Path(args.token_json_dir) / f"{identity}.json")
    return candidates


def token_axis(rows, args, now_epoch):
    active = [r for r in rows if r.get("status") == "active" and r.get("identity_name")]
    if not active:
        if rows:
            return axis("token_freshness", 0, "red", reason="no_active_identity_token_rows", token_age_seconds=None)
        return axis("token_freshness", 0, "red", reason="missing_identity_registry_row", token_age_seconds=None)
    samples = []
    missing = []
    for row in active:
        found = None
        for candidate in token_candidates(row, args):
            if candidate.exists():
                found = candidate
                break
        if not found:
            missing.append(row.get("identity_name"))
            continue
        try:
            age = max(0, int(now_epoch - found.stat().st_mtime))
        except OSError:
            missing.append(row.get("identity_name"))
            continue
        samples.append({"identity_name": row.get("identity_name"), "token_path": str(found), "age_seconds": age})
    if missing and not samples:
        return axis("token_freshness", 0, "red", reason="token_missing", token_age_seconds=None, missing_identities=missing)
    max_age = max([s["age_seconds"] for s in samples] or [TOKEN_FAIL_SECONDS + 1])
    if missing or max_age > TOKEN_FAIL_SECONDS:
        status, score, reason = "red", 0, "token_expired_beyond_recovery" if max_age > TOKEN_FAIL_SECONDS else "token_missing"
    elif max_age > TOKEN_WARN_SECONDS:
        status, score, reason = "yellow", 50, "token_stale_warn"
    else:
        status, score, reason = "green", 100, "token_fresh"
    return axis("token_freshness", score, status, value=max_age, reason=reason, token_age_seconds=max_age, token_samples=samples, missing_identities=missing)


def identity_axis(rows):
    if any(r.get("status") == "active" and r.get("identity_name") for r in rows):
        return axis("identity_registry_liveness", 100, "green", reason="active_identity_row_present", rows_checked=len(rows))
    if rows:
        statuses = sorted({str(r.get("status") or "unknown") for r in rows})
        return axis("identity_registry_liveness", 50, "yellow", reason="identity_row_not_active", statuses=statuses, rows_checked=len(rows))
    return axis("identity_registry_liveness", 0, "red", reason="orphaned_session_no_identity_row", rows_checked=0)


def packet_axis(coord_rows, session, now_epoch):
    matches = [r for r in coord_rows if row_mentions_session(r, session) and row_ts(r)]
    if not matches:
        return axis("cross_orch_packet_age", 0, "red", reason="no_cross_orch_packet", packet_age_seconds=None)
    latest = max(matches, key=lambda r: row_ts(r).timestamp())
    age = max(0, int(now_epoch - row_ts(latest).timestamp()))
    if age > PACKET_FAIL_SECONDS:
        status, score, reason = "red", 0, "silent_over_72h"
    elif age > PACKET_WARN_SECONDS:
        status, score, reason = "yellow", 50, "silent_over_24h"
    else:
        status, score, reason = "green", 100, "recent_packet"
    return axis("cross_orch_packet_age", score, status, value=age, reason=reason, packet_age_seconds=age, latest_line=latest.get("__line"))


def event_text(row):
    return " ".join(str(row.get(k) or "") for k in ("event", "action", "blocker_type", "blocker_class", "trauma_class", "doctor_error", "reason", "message", "text"))


def has_later_ack(rows, session, blocker_ts):
    for row in rows:
        ts = row_ts(row)
        if not ts or ts.timestamp() < blocker_ts.timestamp():
            continue
        if not row_mentions_session(row, session):
            continue
        if ACK_RE.search(event_text(row)):
            return True
    return False


def unread_escalations(coord_rows, peer_rows, session, now_epoch):
    count = 0
    details = []
    for row in coord_rows:
        ts = row_ts(row)
        if not ts or not row_mentions_session(row, session):
            continue
        text = event_text(row)
        if ACK_RE.search(text):
            continue
        if not (str(row.get("blocker_type") or "") == "flywheel_class" or BLOCKER_RE.search(text)):
            continue
        age = max(0, int(now_epoch - ts.timestamp()))
        if age < UNREAD_ESCALATION_SECONDS:
            continue
        if has_later_ack(coord_rows, session, ts):
            continue
        count += 1
        details.append({"source": "cross_orch_coordination", "line": row.get("__line"), "age_seconds": age})
    for row in peer_rows:
        if not row_mentions_session(row, session):
            continue
        ts = row_ts(row)
        age = max(0, int(now_epoch - ts.timestamp())) if ts else UNREAD_ESCALATION_SECONDS
        if age < UNREAD_ESCALATION_SECONDS:
            continue
        if row.get("acked") is True or row.get("resolved") is True:
            continue
        if ACK_RE.search(event_text(row)):
            continue
        count += 1
        details.append({"source": "peer_orch_blocker_watch", "line": row.get("__line"), "age_seconds": age})
    if count == 0:
        return axis("unread_escalations", 100, "green", value=0, reason="no_unread_escalations", unread_count=0)
    if count <= 2:
        return axis("unread_escalations", 50, "yellow", value=count, reason="unread_escalations_warn", unread_count=count, examples=details[:5])
    return axis("unread_escalations", 0, "red", value=count, reason="unread_escalations_red", unread_count=count, examples=details[:5])


def productivity_axis(rows, session):
    session_rows = [r for r in rows if row_mentions_session(r, session) and str(r.get("event") or "") in PENDING_PRODUCTIVITY_EVENTS]
    resolved_rows = [r for r in rows if row_mentions_session(r, session) and RESOLVED_PRODUCTIVITY_RE.search(event_text(r))]
    pending = []
    for row in session_rows:
        ts = row_ts(row)
        if ts and any((row_ts(r) and row_ts(r).timestamp() >= ts.timestamp()) for r in resolved_rows):
            continue
        pending.append(row)
    count = len(pending)
    if count == 0:
        return axis("productivity_escalation_pending", 100, "green", value=0, reason="no_pending_productivity_escalations", pending_count=0)
    if count <= 2:
        return axis("productivity_escalation_pending", 50, "yellow", value=count, reason="productivity_escalations_pending", pending_count=count)
    return axis("productivity_escalation_pending", 0, "red", value=count, reason="productivity_escalations_over_threshold", pending_count=count)


def activity_json(session, args):
    if args.activity_dir:
        path = Path(args.activity_dir) / f"{session}.json"
        if path.exists():
            return load_json(path, {"agents": []})
    return run_json([args.ntm, f"--robot-activity={session}", "--activity-type=codex,claude"], {"agents": []}, timeout=args.activity_timeout)


def multi_frame_alive(activity):
    agents = activity.get("agents") if isinstance(activity, dict) else []
    if not isinstance(agents, list):
        return False
    live_states = {"WAITING", "THINKING", "GENERATING", "WORKING", "RUNNING", "IDLE"}
    for agent in agents:
        state = str(agent.get("state") or agent.get("status") or "").upper()
        provenance = str(agent.get("capture_provenance") or "live")
        process = str(agent.get("process_status") or "").lower()
        if state in live_states and provenance == "live":
            return True
        if process == "running":
            return True
    return False


def load_broadcast_report(args):
    if args.broadcast_classifier:
        payload = load_json(args.broadcast_classifier, {})
        return payload if isinstance(payload, (dict, list)) else {}
    script = Path(args.broadcast_script)
    if not script.exists():
        return {}
    return run_json([str(script), "--doctor", "--json"], {}, timeout=args.broadcast_timeout)


def classifier_for_session(payload, session):
    if isinstance(payload, dict):
        if "sessions" in payload and isinstance(payload["sessions"], dict):
            return payload["sessions"].get(session, {})
        if payload.get("session") == session:
            return payload
        if session in payload:
            return payload[session]
        for row in payload.get("results") or []:
            if isinstance(row, dict) and row.get("session") == session:
                return row
    if isinstance(payload, list):
        for row in payload:
            if isinstance(row, dict) and row.get("session") == session:
                return row
    return {}


def classifier_axis(classifier, activity):
    action = str(classifier.get("action") or classifier.get("classification") or classifier.get("status") or "").lower()
    dead = bool(classifier.get("dead") is True or action in {"dead", "dead_session", "deferred_dead_session", "session_not_running"})
    alive = multi_frame_alive(activity)
    false_positive = bool(dead and alive)
    if false_positive:
        return axis("multi_frame_liveness_classifier", 0, "red", reason="false_positive_classifier", false_positive_classifier=True, broadcast_dead=True, multi_frame_alive=True)
    if dead and not alive:
        return axis("multi_frame_liveness_classifier", 100, "green", reason="classifier_agrees_dead", false_positive_classifier=False, broadcast_dead=True, multi_frame_alive=False)
    if not classifier:
        return axis("multi_frame_liveness_classifier", 100, "green", reason="broadcast_classifier_unavailable_no_mismatch", false_positive_classifier=False, broadcast_dead=False, multi_frame_alive=alive)
    return axis("multi_frame_liveness_classifier", 100, "green", reason="classifier_agrees_live", false_positive_classifier=False, broadcast_dead=False, multi_frame_alive=alive)


def composite_status(score):
    if score >= 80:
        return "green"
    if score >= 50:
        return "yellow"
    return "red"


def row_status(axes, score):
    if any(a["status"] == "red" for a in axes):
        return "red"
    if any(a["status"] == "yellow" for a in axes):
        return "yellow"
    return composite_status(score)


def build_session_row(item, args, shared):
    session = item["session"]
    loop = item.get("loop") or {}
    topo = latest_topology(shared["topology_rows"], session)
    orch_pane = intish(topo.get("orchestrator_pane") or loop.get("orchestrator_pane") or 1, 1)
    rows = registry_rows(args.agent_mail_dir, session)
    activity = activity_json(session, args)
    classifier = classifier_for_session(shared["broadcast_report"], session)
    axes = [
        token_axis(rows, args, shared["now_epoch"]),
        packet_axis(shared["coord_rows"], session, shared["now_epoch"]),
        unread_escalations(shared["coord_rows"], shared["peer_rows"], session, shared["now_epoch"]),
        productivity_axis(shared["productivity_rows"], session),
        identity_axis(rows),
        classifier_axis(classifier, activity),
    ]
    score = round(sum(a["score"] for a in axes) / len(axes)) if axes else 0
    status = row_status(axes, score)
    return {
        "session": session,
        "orchestrator_pane": orch_pane,
        "loop_path": item.get("loop_path"),
        "score": score,
        "status": status,
        "healthy": status == "green",
        "axes": {a["name"]: a for a in axes},
    }


def planned_actions(rows):
    actions = []
    for row in rows:
        packet_axis_value = row["axes"]["cross_orch_packet_age"]
        token_axis_value = row["axes"]["token_freshness"]
        classifier_axis_value = row["axes"]["multi_frame_liveness_classifier"]
        if packet_axis_value["status"] in {"yellow", "red"}:
            actions.append({"type": "xpane_comms_ping", "session": row["session"], "target_pane": row["orchestrator_pane"], "reason": packet_axis_value["reason"]})
        if token_axis_value["status"] == "red" and token_axis_value.get("reason") == "token_expired_beyond_recovery":
            actions.append({"type": "josh_notify_token_expired_beyond_recovery", "session": row["session"], "reason": token_axis_value["reason"]})
        if classifier_axis_value.get("false_positive_classifier"):
            actions.append({"type": "log_false_positive_classifier", "session": row["session"], "reason": classifier_axis_value["reason"]})
    return actions


def apply_actions(actions, args, checked_at):
    actual = []
    for action in actions:
        session = action["session"]
        if action["type"] == "xpane_comms_ping":
            body = "\n".join([
                f"COMMS_HEALTH_PING session={session} source=fleet-comms-health-observatory",
                "No action required if this pane is live; this ping refreshes cross-orch liveness after a silent comms window.",
                f"reason={action['reason']}",
            ])
            ok = subprocess.call([args.ntm, "send", session, f"--pane={action['target_pane']}", "--no-cass-check", body]) == 0
            result = {**action, "ok": ok}
            append_jsonl(args.ledger, {"ts": checked_at, "event": "fleet_comms_ping_sent", **result})
            actual.append(result)
        elif action["type"] == "josh_notify_token_expired_beyond_recovery":
            title = f"Fleet comms token expired: {session}"
            body = f"{session} Agent Mail token is older than 30d; comms substrate may be corrupt."
            notify_ok = False
            if not args.no_notify:
                notify_ok = subprocess.call(["bash", "-lc", f"command -v notify >/dev/null && notify {json.dumps(title)} {json.dumps(body)}"], stderr=subprocess.DEVNULL) == 0
                subprocess.call(["osascript", "-e", f'display notification {json.dumps(body)} with title {json.dumps(title)}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            result = {**action, "notify_ok": notify_ok}
            append_jsonl(args.ledger, {"ts": checked_at, "event": "fleet_comms_token_expired_notify", **result})
            actual.append(result)
        elif action["type"] == "log_false_positive_classifier":
            result = {**action, "ok": True}
            append_jsonl(args.ledger, {"ts": checked_at, "event": "fleet_comms_false_positive_classifier", **result})
            actual.append(result)
    return actual


def make_report(args):
    checked_at_dt = now_utc(args.now)
    checked_at = iso(checked_at_dt)
    now_epoch = int(checked_at_dt.timestamp() if args.now_epoch is None else float(args.now_epoch))
    sessions = loop_sessions(args)
    shared = {
        "now_epoch": now_epoch,
        "coord_rows": load_jsonl(args.coordination_log),
        "peer_rows": load_jsonl(args.peer_blocker_log),
        "productivity_rows": load_jsonl(args.productivity_log),
        "topology_rows": load_jsonl(args.topology),
        "broadcast_report": load_broadcast_report(args),
    }
    rows = [build_session_row(item, args, shared) for item in sessions]
    actions = planned_actions(rows)
    actual = apply_actions(actions, args, checked_at) if args.apply else []
    min_score = min([r["score"] for r in rows] or [100])
    worst = sorted(rows, key=lambda r: (r["score"], r["session"]))[0]["session"] if rows else None
    silent_count = sum(1 for r in rows if r["axes"]["cross_orch_packet_age"]["status"] in {"yellow", "red"})
    stale_count = sum(1 for r in rows if r["axes"]["token_freshness"]["status"] in {"yellow", "red"})
    unread_count = sum(int(r["axes"]["unread_escalations"].get("unread_count") or 0) for r in rows)
    healthy = sum(1 for r in rows if r["healthy"])
    status = composite_status(round(sum(r["score"] for r in rows) / len(rows)) if rows else 100)
    if any(r["status"] == "red" for r in rows):
        status = "red"
    elif any(r["status"] == "yellow" for r in rows):
        status = "yellow"
    return {
        "schema_version": VERSION,
        "checked_at": checked_at,
        "status": status,
        "healthy_count": healthy,
        "total_count": len(rows),
        "fleet_comms_silent_session_count": silent_count,
        "fleet_comms_token_stale_count": stale_count,
        "fleet_comms_escalation_unread_count": unread_count,
        "fleet_comms_min_score": min_score,
        "fleet_comms_worst_session": worst,
        "sessions": rows,
        "planned_actions": actions,
        "actual_actions": actual,
        "signals": [
            {
                "name": "fleet_comms_min_score",
                "producer": ".flywheel/scripts/fleet-comms-health-probe.sh --fleet --json",
                "measurement": "weighted mean of Agent Mail token freshness, cross-orch packet age, unread escalations, productivity pending, identity registry liveness, and multi-frame classifier agreement",
                "threshold": "red below 50 or any red session; yellow below 80",
                "gate_behavior": "doctor status warning/fail; --apply pings silent sessions and only notifies Joshua for token-expired substrate corruption",
            }
        ],
    }


def info_json():
    return {
        "schema_version": VERSION,
        "command": "fleet-comms-health-probe.sh",
        "purpose": "Measure fleet communication health instead of assuming open lines are healthy.",
        "mutates_only_with": "--apply",
        "dry_run_default": True,
        "axes": [
            "token_freshness",
            "cross_orch_packet_age",
            "unread_escalations",
            "productivity_escalation_pending",
            "identity_registry_liveness",
            "multi_frame_liveness_classifier",
        ],
        "donella_leverage_points": [2, 4, 6],
    }


def schema_json():
    return {
        "schema_version": VERSION,
        "output_fields": [
            "fleet_comms_health",
            "fleet_comms_silent_session_count",
            "fleet_comms_token_stale_count",
            "fleet_comms_escalation_unread_count",
            "fleet_comms_min_score",
            "fleet_comms_worst_session",
            "sessions[].axes",
        ],
        "canonical_cli_flags": ["--info", "--examples", "--schema", "--json", "--dry-run", "--apply", "--session=<name>", "--fleet"],
        "status_enum": ["green", "yellow", "red"],
        "thresholds": {
            "token_warn_seconds": TOKEN_WARN_SECONDS,
            "token_fail_seconds": TOKEN_FAIL_SECONDS,
            "packet_warn_seconds": PACKET_WARN_SECONDS,
            "packet_fail_seconds": PACKET_FAIL_SECONDS,
            "unread_escalation_seconds": UNREAD_ESCALATION_SECONDS,
        },
    }


def examples_text():
    return "\n".join([
        "fleet-comms-health-probe.sh --fleet --json",
        "fleet-comms-health-probe.sh --session=alpsinsurance --json",
        "fleet-comms-health-probe.sh --fleet --apply --json",
        "fleet-comms-health-probe.sh --schema --json",
    ])


def print_text(report):
    print(f"Fleet comms: {report['healthy_count']}/{report['total_count']} healthy | silent={report['fleet_comms_silent_session_count']} | stale-tokens={report['fleet_comms_token_stale_count']} | unread-esc={report['fleet_comms_escalation_unread_count']}")
    for row in report["sessions"]:
        print(f"- {row['session']}: {row['status']} score={row['score']}")


def parse_args(argv):
    p = argparse.ArgumentParser(description="Fleet communication health observatory")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--schema", action="store_true")
    p.add_argument("--doctor", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--dry-run", action="store_true", default=True)
    p.add_argument("--apply", action="store_true")
    p.add_argument("--no-notify", action="store_true", default=os.environ.get("FLYWHEEL_COMMS_NO_NOTIFY", "0") == "1")
    p.add_argument("--fleet", action="store_true")
    p.add_argument("--session")
    p.add_argument("--loops-dir", default=os.environ.get("FLYWHEEL_COMMS_LOOPS_DIR", str(DEFAULT_LOOPS_DIR)))
    p.add_argument("--state-dir", default=os.environ.get("FLYWHEEL_COMMS_STATE_DIR", str(DEFAULT_STATE_DIR)))
    p.add_argument("--agent-mail-dir", default=os.environ.get("FLYWHEEL_COMMS_AGENT_MAIL_DIR", str(DEFAULT_AGENT_MAIL_DIR)))
    p.add_argument("--token-json-dir", default=os.environ.get("FLYWHEEL_COMMS_TOKEN_JSON_DIR", str(DEFAULT_TOKEN_JSON_DIR)))
    p.add_argument("--coordination-log", default=os.environ.get("FLYWHEEL_COMMS_COORDINATION_LOG", str(DEFAULT_COORD)))
    p.add_argument("--peer-blocker-log", default=os.environ.get("FLYWHEEL_COMMS_PEER_BLOCKER_LOG", str(DEFAULT_PEER_BLOCKER)))
    p.add_argument("--productivity-log", default=os.environ.get("FLYWHEEL_COMMS_PRODUCTIVITY_LOG", str(DEFAULT_PRODUCTIVITY)))
    p.add_argument("--topology", default=os.environ.get("FLYWHEEL_COMMS_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    p.add_argument("--activity-dir", default=os.environ.get("FLYWHEEL_COMMS_ACTIVITY_DIR"))
    p.add_argument("--broadcast-classifier", default=os.environ.get("FLYWHEEL_COMMS_BROADCAST_CLASSIFIER"))
    p.add_argument("--broadcast-script", default=os.environ.get("FLYWHEEL_COMMS_BROADCAST_SCRIPT", "/Users/josh/Developer/flywheel/.flywheel/scripts/agentmail-registration-broadcast.sh"))
    p.add_argument("--ledger", default=os.environ.get("FLYWHEEL_COMMS_LEDGER", str(DEFAULT_LEDGER)))
    p.add_argument("--ntm", default=os.environ.get("FLYWHEEL_COMMS_NTM", DEFAULT_NTM))
    p.add_argument("--activity-timeout", type=int, default=int(os.environ.get("FLYWHEEL_COMMS_ACTIVITY_TIMEOUT", "5")))
    p.add_argument("--broadcast-timeout", type=int, default=int(os.environ.get("FLYWHEEL_COMMS_BROADCAST_TIMEOUT", "8")))
    p.add_argument("--now")
    p.add_argument("--now-epoch")
    return p.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.info:
        payload = info_json()
        print(json.dumps(payload, sort_keys=True) if args.json else "\n".join(f"{k}: {v}" for k, v in payload.items()))
        return 0
    if args.schema:
        payload = schema_json()
        print(json.dumps(payload, sort_keys=True) if args.json else json.dumps(payload, indent=2, sort_keys=True))
        return 0
    if args.examples:
        print(json.dumps({"examples": examples_text().splitlines()}, sort_keys=True) if args.json else examples_text())
        return 0
    report = make_report(args)
    if args.json or args.doctor:
        print(json.dumps(report, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
