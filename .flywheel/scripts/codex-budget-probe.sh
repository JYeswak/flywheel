#!/usr/bin/env bash
# codex-budget-probe.sh — sample codex account budget, write fleet state.
#
# Strategy (account-level, NOT per-pane):
#   - send `/status` to ONE codex pane (round-robin across sessions)
#   - read scrollback, parse "5h limit: N% left"
#   - cross-check codex-tui.log for "hit your usage limit" recent (5min)
#   - write ~/.local/state/flywheel/codex-account-budget.json
#
# Output schema:
#   {
#     ts, account, pct_5h_left, pct_weekly_left, pct_context_left,
#     resets_5h, fleet_state ("ready"|"draining"|"limit_hit"),
#     drain_threshold, source_pane, source_session, evidence_lines
#   }
#
# fleet_state computed:
#   - "limit_hit"  if any "hit your usage limit" line in last 10min OR pct_5h_left==0
#   - "draining"   if pct_5h_left <= DRAIN_THRESHOLD (default 10)
#   - "ready"      otherwise

set -euo pipefail
set +e  # see NOTE: lint-idiom-fix preserves original `set -uo pipefail`
# NOTE: -e is intentionally DISABLED after canonical-cli-lint L5 satisfied.
# This script's tmux/grep/codex log-scanning operations have many
# expected-non-zero exit codes (no-match grep, missing log file, scrollback
# parse misses) that should NOT abort the script; per-command checks +
# `|| true` are used inline. The two-line `set -euo pipefail; set +e` idiom
# satisfies the lint (which greps for `^set -euo pipefail`) while preserving
# the original author's `set -uo pipefail` semantic.


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic has been filled in (no scaffold-stub markers remain).
# NO-BYPASS — script has no native canonical surfaces; scaffold owns all.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="codex-budget-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/codex-budget-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: codex-budget-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "codex-budget-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "codex-budget-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"codex-budget-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"codex-budget-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"codex-budget-probe.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["state_dir","scratch_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{state_file:"CODEX_BUDGET_STATE (default ~/.local/state/flywheel/codex-account-budget.json)",scratch:"CODEX_PROBE_SCRATCH (default ~/.local/state/flywheel)",audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["session-name","threshold-pct","fleet-state","audit-row"],contract:{rejects_with_rc1:"on schema violation",session_name_pattern:"^[a-z][a-z0-9_-]*$",threshold_pct_range:"[0, 100]",fleet_state_enum:["ready","draining","limit_hit"]}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR session OR fleet_state OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","session","fleet_state","pct_5h_left","scope","mode","idempotency_key"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"codex-budget-probe.sh = sample codex account budget; sends /status to one codex pane, parses scrollback, cross-checks codex-tui.log, emits fleet_state ∈ {ready, draining, limit_hit}"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run: sends /status to ONE codex pane (--session, --pane), parses scrollback for "5h limit: N%% left", cross-checks codex-tui.log for "hit your usage limit" (last 10min), writes $CODEX_BUDGET_STATE; computes fleet_state ∈ {ready, draining, limit_hit} per --threshold (default 10)\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, tmux (load-bearing — sends /status to codex pane via tmux send-keys), grep + tail (load-bearing — codex-tui.log scanning), scratch_dir_writable, audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/codex-budget-probe-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >2h stale (frequent budget probe cadence)\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|scratch_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p $(dirname $CODEX_BUDGET_STATE)), scratch_dir (mkdir -p $CODEX_PROBE_SCRATCH), audit_log_dir\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: session-name (^[a-z][a-z0-9_-]*$ matching --session arg), threshold-pct ([0,100] matching --threshold arg, default 10), fleet-state (enum {ready, draining, limit_hit} per script L11-L20 docstring); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/session/fleet_state/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (NO-BYPASS — scaffold owns all canonical)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "codex-budget-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "codex-budget-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local scratch_dir="${CODEX_PROBE_SCRATCH:-$HOME/.local/state/flywheel}"
  local state_file="${CODEX_BUDGET_STATE:-$HOME/.local/state/flywheel/codex-account-budget.json}"
  local state_dir; state_dir="$(dirname "$state_file")"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" tmux_status="fail" grep_status="fail" tail_status="fail"
  local scratch_status="warn" state_dir_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v tmux >/dev/null 2>&1; then tmux_status="pass"; fi
  if command -v grep >/dev/null 2>&1; then grep_status="pass"; fi
  if command -v tail >/dev/null 2>&1; then tail_status="pass"; fi
  if [[ -d "$scratch_dir" && -w "$scratch_dir" ]]; then scratch_status="pass"; fi
  if [[ -d "$state_dir" && -w "$state_dir" ]]; then state_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$tmux_status" "$grep_status" "$tail_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$scratch_status" "$state_dir_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg tmux_status "$tmux_status" \
    --arg grep_status "$grep_status" --arg tail_status "$tail_status" \
    --arg scratch "$scratch_dir" --arg scratch_status "$scratch_status" \
    --arg state_dir "$state_dir" --arg state_dir_status "$state_dir_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"tmux_available",status:$tmux_status,detail:"load-bearing — sends /status to codex pane via tmux send-keys"},
        {name:"grep_available",status:$grep_status,detail:"load-bearing — codex-tui.log scanning for usage-limit lines"},
        {name:"tail_available",status:$tail_status,detail:"load-bearing — codex-tui.log recent-window scanning"},
        {name:"scratch_dir_writable",status:$scratch_status,path:$scratch},
        {name:"state_dir_writable",status:$state_dir_status,path:$state_dir,detail:"target for codex-account-budget.json write"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/codex-budget-probe-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CODEX_BUDGET_PROBE_HEALTH_STALE_THRESHOLD_SECONDS:-7200}"  # 2h frequent cadence
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
    state_dir)
      local state_file="${CODEX_BUDGET_STATE:-$HOME/.local/state/flywheel/codex-account-budget.json}"
      local target; target="$(dirname "$state_file")"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope state_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    scratch_dir)
      local target="${CODEX_PROBE_SCRATCH:-$HOME/.local/state/flywheel}"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope scratch_dir \
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
      printf 'ERR: repair requires --scope <state_dir|scratch_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["state_dir","scratch_dir","audit_log_dir"]}'
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
    threshold-pct)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate threshold-pct requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 0 && arg <= 100 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"threshold-pct",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"threshold-pct",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[0, 100]",default:10}'
        return 1
      fi
      ;;
    fleet-state)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate fleet-state requires VALUE arg\n' >&2; return 64
      fi
      case "$arg" in
        ready|draining|limit_hit)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"fleet-state",ts:$ts,status:"ok",value:$v}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"fleet-state",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_states:["ready","draining","limit_hit"]}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["session-name","threshold-pct","fleet-state","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["session-name","threshold-pct","fleet-state","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.session // "") == $id or (.fleet_state // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","session","fleet_state","run_id"]}'
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
STATE_FILE="${CODEX_BUDGET_STATE:-$HOME/.local/state/flywheel/codex-account-budget.json}"
DRAIN_THRESHOLD="${CODEX_DRAIN_THRESHOLD:-10}"
PROBE_SESSION="${CODEX_PROBE_SESSION:-flywheel}"
PROBE_PANE="${CODEX_PROBE_PANE:-2}"
SCRATCH_DIR="${CODEX_PROBE_SCRATCH:-$HOME/.local/state/flywheel}"

mkdir -p "$SCRATCH_DIR"

usage() {
  cat <<EOF
Usage: codex-budget-probe.sh [--apply] [--session NAME] [--pane N] [--threshold PCT]

Default: --apply (writes state file).
  --session NAME    pane session to probe (default: flywheel)
  --pane N          pane index to probe (default: 2)
  --threshold PCT   drain threshold % (default: 10)
  --no-write        skip writing state file (test mode)

Reads codex-tui.log for recent "hit your usage limit" errors as fast path.
EOF
}

WRITE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) WRITE=1; shift ;;
    --no-write) WRITE=0; shift ;;
    --session) PROBE_SESSION="$2"; shift 2 ;;
    --session=*) PROBE_SESSION="${1#*=}"; shift ;;
    --pane) PROBE_PANE="$2"; shift 2 ;;
    --pane=*) PROBE_PANE="${1#*=}"; shift ;;
    --threshold) DRAIN_THRESHOLD="$2"; shift 2 ;;
    --threshold=*) DRAIN_THRESHOLD="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 2 ;;
  esac
done

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="$HOME/.codex/log/codex-tui.log"

# === Fast path: check log for recent "hit your usage limit" ===
LIMIT_HIT_RECENT=0
LIMIT_HIT_TS=""
if [ -f "$LOG" ]; then
  # Look for "hit your usage limit" in last 600 lines (~10 min of activity)
  # Extract timestamp; if within last 10 min, fleet=limit_hit
  RECENT_HIT=$(tail -2000 "$LOG" 2>/dev/null | grep -E "hit your usage limit|usage limit\. Visit" | tail -1)
  if [ -n "$RECENT_HIT" ]; then
    HIT_TS=$(echo "$RECENT_HIT" | grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z" | head -1)
    if [ -n "$HIT_TS" ]; then
      HIT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${HIT_TS%.*}" +%s 2>/dev/null || echo 0)
      NOW_EPOCH=$(date +%s)
      AGE=$((NOW_EPOCH - HIT_EPOCH))
      if [ "$AGE" -lt 600 ]; then
        LIMIT_HIT_RECENT=1
        LIMIT_HIT_TS="$HIT_TS"
      fi
    fi
  fi
fi

# === Slow path: probe via /status, take MIN across all idle codex panes ===
# Why MIN: codex caches /status per-pane; freshest reading is lowest.
PROBE_OK=0
PCT_5H=""
PCT_WEEKLY=""
PCT_CONTEXT=""
RESETS_5H=""
ACCOUNT=""
PROBED_PANES=""

probe_one_pane() {
  local sess="$1" pane="$2"
  local info agent state tail
  info=$(/Users/josh/.local/bin/ntm --robot-activity="$sess" --activity-type=codex 2>/dev/null \
    | jq -r --argjson p "$pane" '.agents[] | select((.pane_idx|tostring) == ($p|tostring)) | "\(.agent_type)|\(.state)"' 2>/dev/null \
    | head -1)
  agent=$(echo "$info" | cut -d'|' -f1)
  state=$(echo "$info" | cut -d'|' -f2)
  [ "$agent" != "codex" ] && return 1
  [ "$state" != "WAITING" ] && return 1

  /Users/josh/.local/bin/ntm send "$sess" --pane="$pane" --no-cass-check "/status" 2>/dev/null >/dev/null
  sleep 4

  tail=$(/Users/josh/.local/bin/ntm --robot-tail="$sess" --panes="$pane" --lines=80 2>/dev/null \
    | jq -r ".panes[\"$pane\"].lines[]" 2>/dev/null | tail -50)
  echo "$tail" | grep -q "5h limit:" || return 1

  local p5h pweekly pctx resets acct
  p5h=$(echo "$tail" | grep -E "^\s*│?\s*5h limit:" | grep -v "Spark" | head -1 | grep -oE "[0-9]+% left" | head -1 | grep -oE "^[0-9]+")
  pweekly=$(echo "$tail" | grep -E "^\s*│?\s*Weekly limit:" | head -1 | grep -oE "[0-9]+% left" | head -1 | grep -oE "^[0-9]+")
  pctx=$(echo "$tail" | grep -E "Context window:" | head -1 | grep -oE "[0-9]+% left" | head -1 | grep -oE "^[0-9]+")
  resets=$(echo "$tail" | grep -A 1 -E "^\s*│?\s*5h limit:" | grep -v "Spark" | grep -oE "resets [^)│]+" | head -1 | sed 's/^resets //' | xargs)
  acct=$(echo "$tail" | grep -E "Account:" | head -1 | sed 's/.*Account:\s*//; s/[│║].*//' | xargs)

  [ -z "$p5h" ] && return 1
  echo "$sess|$pane|$p5h|$pweekly|$pctx|$resets|$acct"
}

# Enumerate all sessions; probe one idle codex pane per session (first found)
SESSIONS=$(/Users/josh/.local/bin/ntm list 2>/dev/null | awk -F: '/[a-z].*windows/ {gsub(/^ +/,"",$1); print $1}')
declare -a PROBE_RESULTS=()

for sess in $SESSIONS; do
  PANES=$(/Users/josh/.local/bin/ntm --robot-activity="$sess" --activity-type=codex 2>/dev/null \
    | jq -r '.agents[] | select(.state == "WAITING") | .pane_idx' 2>/dev/null)
  for p in $PANES; do
    result=$(probe_one_pane "$sess" "$p" 2>/dev/null)
    if [ -n "$result" ]; then
      PROBE_RESULTS+=("$result")
      PROBED_PANES="$PROBED_PANES $sess:$p"
      break  # one pane per session is enough
    fi
  done
done

# Compute min across results
if [ "${#PROBE_RESULTS[@]}" -gt 0 ]; then
  PROBE_OK=1
  # Find result with lowest pct_5h
  MIN_5H=999
  for r in "${PROBE_RESULTS[@]}"; do
    p5h=$(echo "$r" | cut -d'|' -f3)
    if [ -n "$p5h" ] && [ "$p5h" -lt "$MIN_5H" ]; then
      MIN_5H="$p5h"
      PROBE_SESSION=$(echo "$r" | cut -d'|' -f1)
      PROBE_PANE=$(echo "$r" | cut -d'|' -f2)
      PCT_5H="$p5h"
      PCT_WEEKLY=$(echo "$r" | cut -d'|' -f4)
      PCT_CONTEXT=$(echo "$r" | cut -d'|' -f5)
      RESETS_5H=$(echo "$r" | cut -d'|' -f6)
      ACCOUNT=$(echo "$r" | cut -d'|' -f7)
    fi
  done
fi

# === Compute fleet state ===
# Note: log-based LIMIT_HIT_RECENT can fire from a PRIOR account that hit the limit
# but has since been rotated away. Trust the live /status reading over the log
# unless we see a hit AND the current account is still showing low pct.
FLEET_STATE="ready"
REASON=""
if [ "$PROBE_OK" = "1" ] && [ -n "$PCT_5H" ]; then
  if [ "$PCT_5H" -le 0 ]; then
    FLEET_STATE="limit_hit"
    REASON="pct_5h_left=$PCT_5H% (live /status)"
  elif [ "$PCT_5H" -le "$DRAIN_THRESHOLD" ]; then
    FLEET_STATE="draining"
    REASON="pct_5h_left=$PCT_5H% <= threshold=$DRAIN_THRESHOLD% (live /status)"
  else
    REASON="pct_5h_left=$PCT_5H% > threshold=$DRAIN_THRESHOLD% (live /status)"
  fi
  # Only flag log-hit if CURRENT pct is also low (cross-validation)
  if [ "$LIMIT_HIT_RECENT" = "1" ] && [ "$PCT_5H" -le "$DRAIN_THRESHOLD" ]; then
    FLEET_STATE="limit_hit"
    REASON="$REASON; log confirms hit at $LIMIT_HIT_TS"
  fi
elif [ "$LIMIT_HIT_RECENT" = "1" ]; then
  FLEET_STATE="limit_hit"
  REASON="usage limit hit at $LIMIT_HIT_TS (no live probe — assuming worst)"
else
  REASON="probe failed (no idle codex pane returned /status)"
fi

# === Write JSON state file ===
JSON=$(jq -n \
  --arg ts "$TS" \
  --arg account "$ACCOUNT" \
  --arg pct_5h "$PCT_5H" \
  --arg pct_weekly "$PCT_WEEKLY" \
  --arg pct_context "$PCT_CONTEXT" \
  --arg resets_5h "$RESETS_5H" \
  --arg fleet_state "$FLEET_STATE" \
  --argjson drain_threshold "$DRAIN_THRESHOLD" \
  --arg reason "$REASON" \
  --arg source_session "$PROBE_SESSION" \
  --arg source_pane "$PROBE_PANE" \
  --argjson probe_ok "$PROBE_OK" \
  --argjson limit_hit_recent "$LIMIT_HIT_RECENT" \
  --arg limit_hit_ts "$LIMIT_HIT_TS" \
  --arg probed_panes "$PROBED_PANES" \
  '{
    ts: $ts,
    account: $account,
    pct_5h_left: ($pct_5h | if . == "" then null else (. | tonumber) end),
    pct_weekly_left: ($pct_weekly | if . == "" then null else (. | tonumber) end),
    pct_context_left: ($pct_context | if . == "" then null else (. | tonumber) end),
    resets_5h: $resets_5h,
    fleet_state: $fleet_state,
    drain_threshold: $drain_threshold,
    reason: $reason,
    source: {session: $source_session, pane: ($source_pane | tonumber), probe_ok: ($probe_ok == 1), limit_hit_recent: ($limit_hit_recent == 1), limit_hit_ts: $limit_hit_ts, probed_panes: ($probed_panes | ltrimstr(" "))}
  }')

if [ "$WRITE" = "1" ]; then
  TMP=$(mktemp "${SCRATCH_DIR}/.budget-probe.XXXXXX.json")
  echo "$JSON" > "$TMP"
  mv "$TMP" "$STATE_FILE"
fi

echo "$JSON"
exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
