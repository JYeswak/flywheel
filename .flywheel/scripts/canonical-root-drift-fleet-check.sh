#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016,SC2317
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
# native; --schema + verbs route to scaffold. See _scaffold_is_canonical_arg.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="canonical-root-drift-fleet-check/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/canonical-root-drift-fleet-check-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: canonical-root-drift-fleet-check.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "canonical-root-drift-fleet-check.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "canonical-root-drift-fleet-check.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"canonical-root-drift-fleet-check.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"canonical-root-drift-fleet-check.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"canonical-root-drift-fleet-check.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["audit_log_dir","sync_helper_path"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{sync_helper:"CANONICAL_ROOT_DRIFT_SYNC (or default sync-canonical-doctrine.sh)",audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["root-path","timeout-seconds","audit-row"],contract:{rejects_with_rc1:"on schema violation",root_path_must_be_absolute:true,timeout_seconds_min_inclusive:1,timeout_seconds_max_inclusive:300}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR root_path OR repo OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","root_path","repo","scope","mode","idempotency_key","drift_count","exit_code"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"canonical-root-drift-fleet-check.sh = per-fleet probe of canonical AGENTS.md drift; calls sync-canonical-doctrine.sh per repo root and aggregates drift signals; native --info+--examples PASSTHRU"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run: walks --root paths (default $HOME/Developer), invokes $CANONICAL_ROOT_DRIFT_SYNC (default sync-canonical-doctrine.sh) per repo, aggregates drift signals; --timeout (default 10s) bounds per-repo helper exec; exits 0 on no drift, 1 on drift, 2 on usage err, 124 on bounded helper timeout (per native --info exit_codes)\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, sync_helper_executable (load-bearing — script invokes this per repo), canonical_source_readable (default AGENTS.md path), audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/canonical-root-drift-fleet-check-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >12h stale (intra-day drift cadence)\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|sync_helper_path> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname), sync_helper_path (verify $CANONICAL_ROOT_DRIFT_SYNC executable; report-only — does NOT install)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: root-path (must be absolute path; matches --root arg semantic), timeout-seconds (integer in [1,300] matching --timeout arg semantic; default 10), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/root_path/repo/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (NUANCED-PARTIAL-BYPASS: --info/--examples flags route to native, --schema + verbs route to scaffold)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "canonical-root-drift-fleet-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "canonical-root-drift-fleet-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root; repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  local sync_helper="${CANONICAL_ROOT_DRIFT_SYNC:-$repo_root/.flywheel/scripts/sync-canonical-doctrine.sh}"
  local canonical_source="${CANONICAL_ROOT_DRIFT_SOURCE:-$repo_root/AGENTS.md}"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail"
  local sync_status="fail" canonical_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if [[ -x "$sync_helper" ]]; then sync_status="pass"; fi
  if [[ -r "$canonical_source" ]]; then canonical_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$sync_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$canonical_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" \
    --arg sync "$sync_helper" --arg sync_status "$sync_status" \
    --arg canonical "$canonical_source" --arg canonical_status "$canonical_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"sync_helper_executable",status:$sync_status,path:$sync,detail:"load-bearing — invoked per repo for drift detection"},
        {name:"canonical_source_readable",status:$canonical_status,path:$canonical,detail:"AGENTS.md baseline; warn if missing"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/canonical-root-drift-fleet-check-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CANONICAL_ROOT_DRIFT_FLEET_CHECK_HEALTH_STALE_THRESHOLD_SECONDS:-43200}"
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
    sync_helper_path)
      # REPORT-ONLY scope — does NOT install the helper, only reports
      # whether the configured path is executable. Installation is
      # outside this surface's authority (helper lives elsewhere in the
      # repo and may have its own install workflow).
      local repo_root; repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
      local target="${CANONICAL_ROOT_DRIFT_SYNC:-$repo_root/.flywheel/scripts/sync-canonical-doctrine.sh}"
      local existed="false"; local executable="false"
      if [[ -f "$target" ]]; then existed="true"; fi
      if [[ -x "$target" ]]; then executable="true"; fi
      if [[ "$mode" == "apply" ]]; then
        cli_audit_append --action repair --status report --scope sync_helper_path \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" \
        --arg existed "$existed" --arg executable "$executable" \
        '{schema_version:$sv,command:"repair",status:"report",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed:($existed == "true"),executable:($executable == "true"),note:"REPORT-ONLY scope — does NOT install; check report fields and install via the helper'\''s own workflow if needed"}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|sync_helper_path>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","sync_helper_path"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    root-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate root-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == /* ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"root-path",ts:$ts,status:"ok",value:$p}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"root-path",ts:$ts,status:"reject",value:$p,reason:"not_absolute_path",contract:"--root arg must be an absolute path"}'
        return 1
      fi
      ;;
    timeout-seconds)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate timeout-seconds requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 300 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"timeout-seconds",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"timeout-seconds",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 300]",default:10}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["root-path","timeout-seconds","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["root-path","timeout-seconds","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.root_path // "") == $id or (.repo // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","root_path","repo","run_id"]}'
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
  # WZJO9.1.7 NUANCED-PARTIAL-BYPASS: canonical-root-drift-fleet-check.sh
  # natively implements --info (canonical envelope: schema_version
  # canonical-root-drift-fleet-check/v1 + .canonical_source + .exit_codes)
  # and --examples (text invocation lines). Native does NOT implement
  # --schema (errors with `unknown argument`) so scaffold owns it. Verb
  # subcommands also NOT natively supported. Bypass list: {--info, --examples}
  # only — same NUANCED variant as 5ke66.8 freshness-probe.
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
VERSION="canonical-root-drift-fleet-check.v1.0.0"
SCHEMA_VERSION="canonical-root-drift-fleet-check/v1"
SYNC="${CANONICAL_ROOT_DRIFT_SYNC:-/Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh}"
SOURCE="${CANONICAL_ROOT_DRIFT_SOURCE:-/Users/josh/Developer/flywheel/AGENTS.md}"
TIMEOUT_SECONDS="${CANONICAL_ROOT_DRIFT_TIMEOUT_SECONDS:-60}"
JSON_OUT=0
ROOTS=()
MODE="check"

usage() {
  cat <<'EOF'
usage: canonical-root-drift-fleet-check.sh [--json] [--sync PATH] [--source PATH] [--root PATH ...] [--timeout SECONDS]
       canonical-root-drift-fleet-check.sh --info|--examples|--help

Runs a bounded canonical-root-drift verification across flywheel-installed repos.
This intentionally checks the close-relevant canonical-root signal without
running the full flywheel-loop doctor monolith.
EOF
}

examples() {
  cat <<'EOF'
canonical-root-drift-fleet-check.sh --json
canonical-root-drift-fleet-check.sh --root /Users/josh/Developer --timeout 20 --json
CANONICAL_ROOT_DRIFT_SYNC=/tmp/fake-sync.sh canonical-root-drift-fleet-check.sh --timeout 1 --json
EOF
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema "$SCHEMA_VERSION" \
    --arg sync "$SYNC" \
    --arg source "$SOURCE" \
    '{
      name:"canonical-root-drift-fleet-check.sh",
      version:$version,
      schema_version:$schema,
      sync_helper:$sync,
      canonical_source:$source,
      bounded:true,
      close_relevant_signal:"canonical_root_drift",
      exit_codes:{"0":"no canonical root drift","1":"canonical root drift or helper-reported errors","2":"usage/config error","124":"bounded helper timeout"}
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --sync) SYNC="${2:?}"; shift 2 ;;
    --sync=*) SYNC="${1#*=}"; shift ;;
    --source) SOURCE="${2:?}"; shift 2 ;;
    --source=*) SOURCE="${1#*=}"; shift ;;
    --root) ROOTS+=("${2:?}"); shift 2 ;;
    --root=*) ROOTS+=("${1#*=}"); shift ;;
    --timeout) TIMEOUT_SECONDS="${2:?}"; shift 2 ;;
    --timeout=*) TIMEOUT_SECONDS="${1#*=}"; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    -h|--help) MODE="help"; shift ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  info) info_json; exit 0 ;;
  examples) examples; exit 0 ;;
  help) usage; exit 0 ;;
esac

[[ "$TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]] || { printf 'ERR: --timeout must be positive integer\n' >&2; exit 2; }
if [[ ! -x "$SYNC" ]]; then
  payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg sync "$SYNC" '{schema_version:$schema,status:"error",classification:"sync_helper_missing",sync_helper:$sync,timed_out:false}')"
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$payload" || jq -r '"status=\(.status) classification=\(.classification)"' <<<"$payload"
  exit 2
fi

# When no explicit --root is supplied, auto-populate from the active loop
# registry (~/.flywheel/loops/*.json). This bounds the default fleet check
# to flywheel-loop-registered repos, triggers the explicit-root
# short-circuit in sync-canonical-doctrine.sh (flywheel-fppjx fix), and
# avoids the broad /Users/josh/Developer recursive scan that exceeded
# dispatch budgets in flywheel-g0qv9. Operators who want a full-disk scan
# can still pass --root /Users/josh/Developer explicitly.
LOOPS_DIR="${CANONICAL_ROOT_DRIFT_LOOPS_DIR:-$HOME/.flywheel/loops}"
if [[ "${#ROOTS[@]}" -eq 0 && -d "$LOOPS_DIR" ]]; then
  while IFS= read -r loop_json; do
    [[ -f "$loop_json" ]] || continue
    repo_path="$(jq -r '.repo_path // .repo // .project_path // empty' "$loop_json" 2>/dev/null || true)"
    [[ -n "$repo_path" && "$repo_path" != "null" ]] || continue
    [[ -f "$repo_path/.flywheel/AGENTS-CANONICAL.md" ]] || continue
    ROOTS+=("$repo_path")
  done < <(find "$LOOPS_DIR" -maxdepth 1 -name '*.json' -not -name '*.bak.*' -type f -print 2>/dev/null | sort)
fi

OUT="$(mktemp "${TMPDIR:-/tmp}/canonical-root-drift-fleet-check.out.XXXXXX")"
ERR="$(mktemp "${TMPDIR:-/tmp}/canonical-root-drift-fleet-check.err.XXXXXX")"
META="$(mktemp "${TMPDIR:-/tmp}/canonical-root-drift-fleet-check.meta.XXXXXX")"
trap 'rm -f "$OUT" "$ERR" "$META"' EXIT

cmd=("$SYNC" --check --json --source "$SOURCE")
for root in "${ROOTS[@]}"; do
  cmd+=(--root "$root")
done

python3 - "$TIMEOUT_SECONDS" "$OUT" "$ERR" "$META" "${cmd[@]}" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

timeout = int(sys.argv[1])
out_path, err_path, meta_path = map(Path, sys.argv[2:5])
cmd = sys.argv[5:]
try:
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    out_path.write_text(proc.stdout, encoding="utf-8")
    err_path.write_text(proc.stderr, encoding="utf-8")
    meta = {"timed_out": False, "rc": proc.returncode}
except subprocess.TimeoutExpired as exc:
    out_path.write_text(exc.stdout or "", encoding="utf-8")
    err_path.write_text(exc.stderr or "", encoding="utf-8")
    meta = {"timed_out": True, "rc": 124}
meta_path.write_text(json.dumps(meta, separators=(",", ":")), encoding="utf-8")
PY

meta="$(cat "$META")"
timed_out="$(jq -r '.timed_out' <<<"$meta")"
sync_rc="$(jq -r '.rc' <<<"$meta")"
stderr_short="$(tr '\n' ' ' <"$ERR" | cut -c1-500)"

if [[ "$timed_out" == "true" ]]; then
  payload="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg sync "$SYNC" \
    --arg source "$SOURCE" \
    --arg stderr "$stderr_short" \
    --argjson timeout "$TIMEOUT_SECONDS" \
    '{
      schema_version:$schema,
      version:$version,
      status:"error",
      classification:"sync_helper_timeout",
      timed_out:true,
      timeout_seconds:$timeout,
      sync_helper:$sync,
      canonical_source:$source,
      stderr:$stderr
    }')"
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$payload" || jq -r '"status=\(.status) classification=\(.classification) timeout_seconds=\(.timeout_seconds)"' <<<"$payload"
  exit 124
fi

if ! jq -e . "$OUT" >/dev/null 2>&1; then
  payload="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg sync "$SYNC" \
    --arg source "$SOURCE" \
    --arg stderr "$stderr_short" \
    --argjson rc "$sync_rc" \
    '{
      schema_version:$schema,
      version:$version,
      status:"error",
      classification:"sync_helper_invalid_json",
      timed_out:false,
      sync_rc:$rc,
      sync_helper:$sync,
      canonical_source:$source,
      stderr:$stderr
    }')"
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$payload" || jq -r '"status=\(.status) classification=\(.classification)"' <<<"$payload"
  exit 2
fi

payload="$(jq -c \
  --arg schema "$SCHEMA_VERSION" \
  --arg version "$VERSION" \
  --arg sync "$SYNC" \
  --arg source "$SOURCE" \
  --argjson timeout "$TIMEOUT_SECONDS" \
  --argjson sync_rc "$sync_rc" \
  '{
    schema_version:$schema,
    version:$version,
    status:(if ((.root_drifted_count // 0) == 0 and (.errors_count // 0) == 0) then "pass" else "fail" end),
    timed_out:false,
    timeout_seconds:$timeout,
    sync_rc:$sync_rc,
    sync_helper:$sync,
    canonical_source:$source,
    target_count:(.target_count // 0),
    root_target_count:(.root_target_count // 0),
    canonical_root_drift_count:(.root_drifted_count // 0),
    canonical_snapshot_drift_count:(.canonical_drifted_count // 0),
    errors_count:(.errors_count // 0),
    source_hash:(.source_hash // null),
    checked_repos:[(.root_details // [])[] | {repo,target,status,drift,block_present,missing_rules}],
    drifted_repos:[(.root_details // [])[] | select((.drift // false) == true) | {repo,target,status,missing_rules}],
    errors:(.errors // []),
    evidence_source:"sync-canonical-doctrine.sh --check --json"
  }' "$OUT")"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"status=\(.status) canonical_root_drift_count=\(.canonical_root_drift_count) root_target_count=\(.root_target_count) timed_out=\(.timed_out)"' <<<"$payload"
fi

[[ "$(jq -r '.status' <<<"$payload")" == "pass" ]]

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
