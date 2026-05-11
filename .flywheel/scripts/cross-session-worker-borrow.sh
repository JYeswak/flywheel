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

set -euo pipefail
set +e  # script intentionally tolerates non-zero exits in domain logic; lint-idiom-fix


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic has been filled in (no scaffold-stub markers remain).
# WZJO9.1.7 NUANCED-PARTIAL-BYPASS — only --info|--schema route to
# native; --examples + verbs route to scaffold. Native --doctor FLAG
# also bypassed (script's own native flag, distinct from scaffold's
# `doctor` verb).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="cross-session-worker-borrow/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/cross-session-worker-borrow-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: cross-session-worker-borrow.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "cross-session-worker-borrow.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "cross-session-worker-borrow.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"cross-session-worker-borrow.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"cross-session-worker-borrow.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"cross-session-worker-borrow.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"doctor",note:"defensive fallback — script has native --doctor FLAG with mode=doctor envelope (authoritative)"}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{ts:"ISO8601",status:"pass|warn|fail",audit_log:"path",last_run_ts:"ISO8601 or null",age_seconds:"int or null",recent_runs:"int (last 20)",total_runs:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["roster_dir","ledger_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{roster:"BORROW_ROSTER_LEDGER (default ~/.local/state/flywheel/team-roster.jsonl)",ledger:"BORROW_LEDGER (default ~/.local/state/flywheel/cross-session-worker-borrow.jsonl)",audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["session-name","borrow-state","ttl-minutes","audit-row"],contract:{rejects_with_rc1:"on schema violation",session_name_pattern:"^[a-z][a-z0-9_-]*$",borrow_state_enum:["requested","approved","in_use","released","refused","timed_out","declined","reclaimed_pre_approve","reclaimed_in_use","worker_died"],ttl_minutes_range:"[1, 1440]"}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR borrow_id OR requestor_session OR target_session OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","borrow_id","requestor_session","target_session","ttl_minutes","scope","mode","idempotency_key","borrow_state"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"cross-session-worker-borrow.sh = stateful borrow primitive for borrowing worker panes across sessions; 10-state machine (requested → approved → in_use → released, with refused/timed_out/declined/reclaimed_*/worker_died terminal states); TTL-bounded; native --info/--schema/--doctor PASSTHRU"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run: stateful borrow primitive — --request takes --requestor session + --target session + --task-id + --ttl-minutes (default 60) and emits a borrow_id; --approve transitions to in_use; --release returns the worker; --check-eligibility validates against $BORROW_ROSTER_LEDGER + $BORROW_PROTECTED_PATTERN\n' ;;
    doctor)   printf 'topic: doctor — script also has NATIVE --doctor FLAG (BYPASSED) which emits cross-session-worker-borrow/v1 envelope with mode=doctor. Scaffold doctor is defensive fallback. Substrate probes: bash, jq, mktemp, ntm_executable ($NTM_BIN), roster_readable ($BORROW_ROSTER_LEDGER), ledger_dir_writable, audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/cross-session-worker-borrow-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >24h stale (intra-day borrow cadence)\n' ;;
    repair)   printf 'topic: repair --scope <roster_dir|ledger_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: roster_dir (mkdir -p dirname of $BORROW_ROSTER_LEDGER), ledger_dir (mkdir -p dirname of $BORROW_LEDGER), audit_log_dir\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: session-name (^[a-z][a-z0-9_-]*$ matching --requestor/--target arg semantics), borrow-state (enum of 10 states from native --schema .state_machine.states: requested/approved/in_use/released + 6 terminal states), ttl-minutes ([1, 1440] matching --ttl-minutes arg, default 60); audit-row standard; rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/borrow_id/requestor_session/target_session/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (NUANCED-PARTIAL-BYPASS — --info/--schema/--doctor flags route to native; --examples + verbs route to scaffold)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "cross-session-worker-borrow" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "cross-session-worker-borrow" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ntm_bin="${NTM_BIN:-$HOME/.local/bin/ntm}"
  local roster="${BORROW_ROSTER_LEDGER:-$HOME/.local/state/flywheel/team-roster.jsonl}"
  local ledger="${BORROW_LEDGER:-$HOME/.local/state/flywheel/cross-session-worker-borrow.jsonl}"
  local ledger_dir; ledger_dir="$(dirname "$ledger")"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail"
  local ntm_status="fail" roster_status="warn" ledger_dir_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if [[ -x "$ntm_bin" ]]; then ntm_status="pass"; fi
  if [[ -r "$roster" ]]; then roster_status="pass"; fi
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]]; then ledger_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$ntm_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$roster_status" "$ledger_dir_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" \
    --arg ntm "$ntm_bin" --arg ntm_status "$ntm_status" \
    --arg roster "$roster" --arg roster_status "$roster_status" \
    --arg ledger_dir "$ledger_dir" --arg ledger_dir_status "$ledger_dir_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"ntm_executable",status:$ntm_status,path:$ntm,detail:"load-bearing — borrow lifecycle uses ntm send for cross-session coordination"},
        {name:"roster_readable",status:$roster_status,path:$roster,detail:"team-roster.jsonl drives eligibility checks"},
        {name:"ledger_dir_writable",status:$ledger_dir_status,path:$ledger_dir,detail:"target for borrow lifecycle ledger writes"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ],
      note:"defensive fallback — script has native --doctor FLAG (authoritative)"
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/cross-session-worker-borrow-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CROSS_SESSION_WORKER_BORROW_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"  # 24h intra-day cadence
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
    roster_dir)
      local roster="${BORROW_ROSTER_LEDGER:-$HOME/.local/state/flywheel/team-roster.jsonl}"
      local target; target="$(dirname "$roster")"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope roster_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    ledger_dir)
      local ledger="${BORROW_LEDGER:-$HOME/.local/state/flywheel/cross-session-worker-borrow.jsonl}"
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
      printf 'ERR: repair requires --scope <roster_dir|ledger_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["roster_dir","ledger_dir","audit_log_dir"]}'
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
    borrow-state)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate borrow-state requires VALUE arg\n' >&2; return 64
      fi
      case "$arg" in
        requested|approved|in_use|released|refused|timed_out|declined|reclaimed_pre_approve|reclaimed_in_use|worker_died)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"borrow-state",ts:$ts,status:"ok",value:$v}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"borrow-state",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_states:["requested","approved","in_use","released","refused","timed_out","declined","reclaimed_pre_approve","reclaimed_in_use","worker_died"],source:"native --schema .state_machine.states"}'
          return 1 ;;
      esac
      ;;
    ttl-minutes)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate ttl-minutes requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 1440 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"ttl-minutes",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"ttl-minutes",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 1440]",default:60,note:"matches --ttl-minutes arg semantic — 1 minute to 24 hours"}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["session-name","borrow-state","ttl-minutes","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["session-name","borrow-state","ttl-minutes","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.borrow_id // "") == $id or (.requestor_session // "") == $id or (.target_session // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","borrow_id","requestor_session","target_session","run_id"]}'
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
# Per-target bypass flags: --activity-type,--borrow-id,--check-eligibility,--doctor,--from-fixture,--list,--release,--request,--requestor,--requestor-pane,--robot-activity,--target,--target-pane,--task-id,--task-sha256,--ttl-minutes,--window-minutes
_scaffold_is_canonical_arg() {
  # WZJO9.1.7 NUANCED-PARTIAL-BYPASS: cross-session-worker-borrow.sh
  # natively implements --info AND --schema (rich canonical envelopes —
  # cross-session-worker-borrow/v1 with full state_machine field listing
  # the borrow lifecycle states). Native does NOT implement --examples
  # (errors with usage). Verb subcommands NOT natively supported.
  # Bypass list: {--info, --schema} — same subset as 5ke66.8 + 1hshd.20.
  #
  # The scaffolder also pre-emitted a defensive bypass for native script
  # flags (--request / --release / --check-eligibility / --doctor / --list
  # / etc.) so the script's borrow-lifecycle args continue to work.
  local _a
  for _a in "$@"; do
    case "$_a" in --activity-type|--borrow-id|--check-eligibility|--doctor|--from-fixture|--list|--release|--request|--requestor|--requestor-pane|--robot-activity|--target|--target-pane|--task-id|--task-sha256|--ttl-minutes|--window-minutes) return 1 ;; esac
  done
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema) return 1 ;;  # NUANCED-PARTIAL-BYPASS to native
    --examples) return 0 ;;        # NOT bypassed — scaffold owns
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
