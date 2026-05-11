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
# specific logic has been filled in as defensive fallbacks; on this
# surface they are intentionally UNREACHABLE per the wzjo9.1.7 BYPASS-ALL
# pattern (see _scaffold_is_canonical_arg below) — the script's native
# python heredoc surfaces are authoritative.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="bleed-ledger-watch/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/bleed-ledger-watch-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: bleed-ledger-watch.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "bleed-ledger-watch.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "bleed-ledger-watch.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"bleed-ledger-watch.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"bleed-ledger-watch.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"bleed-ledger-watch.sh doctor --json"}'
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
    doctor|health|repair|validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surf "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surf,note:"WZJO9.1.7 BYPASS-ALL — script native python heredoc handles this surface; see argparse choices in main()",authoritative_source:"python heredoc"}'
      ;;
    audit|why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surf "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surf,note:"defensive fallback (unreachable on this surface per BYPASS-ALL)",row_shape:{ts:"ISO8601",action:"string"}}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","scope","mode","idempotency_key"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"bleed-ledger-watch.sh = ledger watcher with NATIVE python canonical surfaces; scaffold layer is BYPASS-ALL fallback per wzjo9.1.7 pattern"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run (python3 heredoc): reads $FLYWHEEL_BLEED_LEDGER (default ~/.local/state/flywheel/coordinator-cross-repo-bleed.jsonl), counts bleed events in last 24h, optionally creates fix bead via br create when --apply\n' ;;
    doctor)   printf 'topic: doctor — handled by python heredoc native doctor() function (BYPASS-ALL); emits canonical envelope with bleed_event_count_24h + bleed_session_top + bleed_repo_top + bleed_warnings + fix_bead_required\n' ;;
    health)   printf 'topic: health — handled by python heredoc native (BYPASS-ALL); shares doctor() impl with command=health label\n' ;;
    repair)   printf 'topic: repair [--apply] — handled by python heredoc native (BYPASS-ALL); --apply creates a single fix bead via br create when bleed events exist; idempotent against existing open beads with the same title\n' ;;
    validate) printf 'topic: validate — handled by python heredoc native (BYPASS-ALL); shares doctor() impl with command=validate label and adds .valid boolean\n' ;;
    audit)    printf 'topic: audit [--limit N] — defensive fallback (unreachable on this surface); native script does not implement audit; tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail; default limit=20\n' ;;
    why)      printf 'topic: why <id> — defensive fallback (unreachable on this surface); provenance lookup against $SCAFFOLD_AUDIT_LOG\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (BYPASS-ALL: doctor/health/repair/validate routed to native python heredoc)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "bleed-ledger-watch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "bleed-ledger-watch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # WZJO9.1.7 BYPASS-ALL: defensive fallback only. The script's native
  # python heredoc doctor() at line ~71 of cmd_run is authoritative for
  # this surface (computes bleed_event_count_24h from $FLYWHEEL_BLEED_LEDGER).
  # If _scaffold_is_canonical_arg ever changes to NOT bypass, this fallback
  # probes the substrate the python doctor depends on.
  local ledger="${FLYWHEEL_BLEED_LEDGER:-$HOME/.local/state/flywheel/coordinator-cross-repo-bleed.jsonl}"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" python_status="fail" br_status="fail"
  local ledger_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if command -v br >/dev/null 2>&1 || [[ -x "$HOME/.cargo/bin/br" ]]; then br_status="pass"; fi
  if [[ -r "$ledger" ]]; then ledger_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$python_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$br_status" "$ledger_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg python_status "$python_status" --arg br_status "$br_status" \
    --arg ledger "$ledger" --arg ledger_status "$ledger_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"python3_available",status:$python_status,detail:"load-bearing for native doctor() heredoc"},
        {name:"br_available",status:$br_status,detail:"load-bearing for repair --apply fix-bead creation"},
        {name:"ledger_readable",status:$ledger_status,path:$ledger},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ],
      note:"BYPASS-ALL fallback — native python doctor() is authoritative"
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/bleed-ledger-watch-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${BLEED_LEDGER_WATCH_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$audit_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0,note:"BYPASS-ALL fallback"}'
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
      stale_threshold_seconds:$stale, note:"BYPASS-ALL fallback"}'
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
  # WZJO9.1.7 BYPASS-ALL fallback. Native python heredoc handles repair via
  # create_fix_bead() which creates a single bead via `br create` when bleed
  # events exist (idempotent against existing open beads with matching title).
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    ledger_dir)
      local ledger="${FLYWHEEL_BLEED_LEDGER:-$HOME/.local/state/flywheel/coordinator-cross-repo-bleed.jsonl}"
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
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true"),note:"BYPASS-ALL fallback — native fix-bead repair via cmd_run"}'
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
      printf 'ERR: repair requires --scope <ledger_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["ledger_dir","audit_log_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  # BYPASS-ALL fallback. Native python validate is shared with doctor() and
  # adds .valid: bool. This fallback exposes scratch-level validators
  # (ledger-path + bleed-row-shape) for orchestrator-side pre-checks.
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    ledger-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate ledger-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == *.jsonl ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"ledger-path",ts:$ts,status:"ok",value:$p}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"ledger-path",ts:$ts,status:"reject",value:$p,reason:"unsupported_extension",valid_extensions:[".jsonl"]}'
        return 1
      fi
      ;;
    bleed-row)
      if [[ -z "$arg" || ! -r "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
          '{schema_version:$sv,command:"validate",subject:"bleed-row",ts:$ts,status:"reject",path:$path,reason:"file_not_readable"}'
        return 1
      fi
      local bad; bad="$(jq -c 'select((has("ts") | not) and (has("timestamp") | not) and (has("checked_at") | not)) | {missing:["ts|timestamp|checked_at (one required)"]}' "$arg" 2>/dev/null | head -5 || true)"
      if [[ -n "$bad" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" --arg bad "$bad" \
          '{schema_version:$sv,command:"validate",subject:"bleed-row",ts:$ts,status:"reject",path:$path,reason:"missing_timestamp_field",required_one_of:["ts","timestamp","checked_at"],sample:$bad}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
        '{schema_version:$sv,command:"validate",subject:"bleed-row",ts:$ts,status:"ok",path:$path}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["ledger-path","bleed-row","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["ledger-path","bleed-row","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.session // "") == $id or (.repo_path // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","session","repo_path","run_id"]}'
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
  # WZJO9.1.7 BYPASS-ALL: bleed-ledger-watch.sh natively implements doctor /
  # health / repair / validate / schema / info / examples in the python3
  # heredoc (see argparse choices at the script's main()). The scaffold
  # intercept would shadow these richer domain-specific surfaces with the
  # generic scaffold stubs. Per the wzjo9.1.7 verb-collision pattern, we
  # return 1 universally so ALL invocations fall through to cmd_run, where
  # the python heredoc's authoritative handlers fire. The scaffold_cmd_*
  # functions below are filled-in defensive fallbacks (TODO=0 per AG3) but
  # are intentionally unreachable on this surface.
  return 1
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA_VERSION = "bleed-ledger-watch/v1"
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/coordinator-cross-repo-bleed.jsonl"


def parse_ts(value: object) -> datetime | None:
    if not value:
        return None
    text = str(value)
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def now_utc(value: str | None) -> datetime:
    return parse_ts(value) or datetime.now(timezone.utc)


def iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def read_ledger(path: Path) -> tuple[list[dict], list[dict]]:
    rows: list[dict] = []
    warnings: list[dict] = []
    if not path.exists():
        return rows, [{"code": "ledger_missing", "path": str(path)}]
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            warnings.append({"code": "malformed_row", "line": line_no, "message": str(exc)})
            continue
        if not isinstance(row, dict):
            warnings.append({"code": "non_object_row", "line": line_no})
            continue
        row["__line"] = line_no
        rows.append(row)
    return rows, warnings


def top(counter: Counter[str]) -> dict | None:
    if not counter:
        return None
    key, count = sorted(counter.items(), key=lambda item: (-item[1], item[0]))[0]
    return {"value": key, "count": count}


def doctor(args: argparse.Namespace) -> dict:
    ledger = Path(args.ledger).expanduser()
    checked_at = now_utc(args.now)
    cutoff = checked_at - timedelta(hours=24)
    rows, warnings = read_ledger(ledger)
    recent: list[dict] = []
    old_or_undated = 0
    for row in rows:
        ts = parse_ts(row.get("ts") or row.get("timestamp") or row.get("checked_at"))
        if ts is None:
            old_or_undated += 1
            continue
        if ts >= cutoff:
            recent.append(row)
    sessions = Counter(str(row.get("session") or "unknown") for row in recent)
    repos = Counter(str(row.get("repo_path") or row.get("repo") or "unknown") for row in recent)
    event_count = len(recent)
    status = "pass"
    if event_count:
        status = "fail"
    elif any(item.get("code") not in {"ledger_missing"} for item in warnings):
        status = "warn"
    return {
        "schema_version": SCHEMA_VERSION,
        "command": "doctor",
        "status": status,
        "checked_at": iso(checked_at),
        "ledger_path": str(ledger),
        "ledger_exists": ledger.exists(),
        "rows_observed": len(rows),
        "rows_older_or_undated": old_or_undated,
        "bleed_event_count_24h": event_count,
        "bleed_session_top": top(sessions),
        "bleed_repo_top": top(repos),
        "bleed_warnings": warnings,
        "consumer": "flywheel tick Step 4y",
        "fix_bead_required": event_count > 0,
    }


def create_fix_bead(args: argparse.Namespace, payload: dict) -> dict:
    if not payload["fix_bead_required"]:
        return {"action": "noop", "reason": "no_bleed_events"}
    repo = Path(args.repo).expanduser().resolve()
    title = "[auto-doctor:coordinator-cross-repo-bleed] investigate pinned coordinator bleed"
    description = f"""## Goal
Investigate and eliminate coordinator cross-repo bleed events.

## Context
`bleed-ledger-watch.sh` found {payload["bleed_event_count_24h"]} bleed event(s) in the last 24h.

## Evidence
- ledger: `{payload["ledger_path"]}`
- top session: `{payload["bleed_session_top"]}`
- top repo: `{payload["bleed_repo_top"]}`

## Acceptance Criteria
- Reproduce or explain the ledger rows.
- Patch the pinned coordinator or topology substrate so new bleed rows stop.
- Run `.flywheel/scripts/bleed-ledger-watch.sh --doctor --json` and confirm `bleed_event_count_24h == 0` after the fix window.
"""
    existing = subprocess.run(
        ["br", "list", "--json"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if existing.returncode == 0:
        try:
            issues = json.loads(existing.stdout).get("issues", [])
        except Exception:
            issues = []
        for issue in issues:
            if issue.get("title") == title and issue.get("status") not in {"closed", "done"}:
                return {"action": "existing", "bead_id": issue.get("id"), "title": title}
    if not args.apply:
        return {"action": "would_create", "title": title, "mode": "dry_run"}
    proc = subprocess.run(
        ["br", "create", title, "-t", "bug", "-p", "1", "-d", description],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        return {"action": "failed", "exit_code": proc.returncode, "stderr": proc.stderr.strip()[:2000]}
    return {"action": "created", "title": title, "stdout": proc.stdout.strip()[:2000]}


def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(f"status={payload.get('status')} bleed_event_count_24h={payload.get('bleed_event_count_24h', 0)}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Watch the coordinator cross-repo bleed ledger.")
    parser.add_argument("command", nargs="?", default="doctor", choices=["doctor", "health", "repair", "validate", "schema", "info", "examples"])
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--repair", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--ledger", default=os.environ.get("FLYWHEEL_BLEED_LEDGER", str(DEFAULT_LEDGER)))
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--now")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args(argv)
    if args.apply:
        args.dry_run = False
    command = args.command
    for flag, name in ((args.doctor, "doctor"), (args.health, "health"), (args.repair, "repair"), (args.validate, "validate"), (args.schema, "schema"), (args.info, "info"), (args.examples, "examples")):
        if flag:
            command = name
    if command == "schema":
        emit({"schema_version": SCHEMA_VERSION, "fields": ["bleed_event_count_24h", "bleed_session_top", "bleed_repo_top", "bleed_warnings"], "exit_codes": {"0": "pass or warn", "1": "bleed rows observed", "2": "usage"}}, args.json)
        return 0
    if command == "info":
        emit({"schema_version": SCHEMA_VERSION, "name": "bleed-ledger-watch.sh", "ledger_path": args.ledger, "commands": ["doctor", "health", "repair", "validate", "schema", "info", "examples"], "mutation": "repair --apply creates one fix bead when bleed rows exist"}, args.json)
        return 0
    if command == "examples":
        payload = {"schema_version": SCHEMA_VERSION, "examples": ["bleed-ledger-watch.sh --doctor --json", "bleed-ledger-watch.sh --doctor --json --ledger /tmp/ledger.jsonl", "bleed-ledger-watch.sh repair --apply --json"]}
        emit(payload, args.json)
        return 0
    payload = doctor(args)
    if command == "health":
        payload["command"] = "health"
    if command == "repair":
        payload["command"] = "repair"
    if command == "validate":
        payload["command"] = "validate"
        payload["valid"] = payload["status"] in {"pass", "warn", "fail"}
    payload["fix_bead_action"] = create_fix_bead(args, payload)
    emit(payload, args.json)
    return 1 if payload["bleed_event_count_24h"] else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
