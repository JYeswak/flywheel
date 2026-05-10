#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled in by flywheel-lrdum)
# doctor-mode-tier: filled (bead flywheel-lrdum over flywheel-ws02m scaffold)
#
# This block was APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch (Python heredoc indexing .flywheel/audit/<bead>/ +
# .flywheel/journal/) runs unchanged when no canonical-cli verb is present.
# Surface-specific logic was filled in per .flywheel/audit/flywheel-jloib/wave-1-apply-spec.md.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="bead-evidence-indexer/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/bead-evidence-indexer-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: bead-evidence-indexer.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "bead-evidence-indexer.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "bead-evidence-indexer.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"bead-evidence-indexer.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"bead-evidence-indexer.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"bead-evidence-indexer.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["bead-id","evidence-path","audit-row"],contract:{rejects_with_rc1:"on schema violation",bead_id_pattern:"^flywheel-[a-z0-9]+(\\.[0-9]+)*$"}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR bead_id OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","scope","mode","idempotency_key","bead_id"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"bead-evidence-indexer.sh = index .flywheel/audit/<bead>/ + .flywheel/journal/ artifacts; bash wrapper around Python heredoc"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation: bash wrapper invokes Python heredoc that scans .flywheel/audit/<bead>/ + .flywheel/journal/ for evidence artifacts; flags handled by Python argparse (run with --help for full list)\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: python3 available, jq available, repo_root resolvable, beads_dir present (.beads/), state_dir writable (~/.local/state/flywheel/), audit_log_dir writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/bead-evidence-indexer-runs.jsonl); reports last_run_ts, age_seconds, recent_runs (last 20), total_runs; status=warn at >24h stale\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p ~/.local/state/flywheel), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: bead-id (canonical br id pattern), evidence-path (under .flywheel/audit/<bead>/ OR .flywheel/journal/), audit-row (JSONL: ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/bead_id/run_id; states: found / not_found / unavailable\n' ;;
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
            && cli_emit_completion_bash "bead-evidence-indexer" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "bead-evidence-indexer" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root; repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  local state_dir="$HOME/.local/state/flywheel"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local python3_status="fail" jq_status="fail" repo_status="fail"
  local beads_status="warn" state_dir_status="fail" audit_dir_status="fail"
  local overall="pass"

  if command -v python3 >/dev/null 2>&1; then python3_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if [[ -n "$repo_root" ]]; then repo_status="pass"; fi
  if [[ -d "$repo_root/.beads" ]]; then beads_status="pass"; fi
  if [[ -d "$state_dir" && -w "$state_dir" ]]; then state_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$python3_status" "$jq_status" "$repo_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$beads_status" "$state_dir_status" "$audit_dir_status"; do
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
    --arg beads "$repo_root/.beads" --arg beads_status "$beads_status" \
    --arg state_dir "$state_dir" --arg state_dir_status "$state_dir_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"python3_available",status:$python3_status},
        {name:"jq_available",status:$jq_status},
        {name:"repo_root_resolvable",status:$repo_status,detail:$repo},
        {name:"beads_dir_present",status:$beads_status,path:$beads},
        {name:"state_dir_writable",status:$state_dir_status,path:$state_dir},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/bead-evidence-indexer-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${BEI_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
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
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/bead-evidence-indexer-runs.jsonl}"
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
    bead-id)
      if [[ -z "$target" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"bead-id",status:"fail",reason:"id_required"}'
        return 1
      fi
      if [[ "$target" =~ ^flywheel-[a-z0-9]+(\.[0-9]+)*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$target" \
          '{schema_version:$sv,command:"validate",subject:"bead-id",status:"pass",bead_id:$id}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$target" \
        '{schema_version:$sv,command:"validate",subject:"bead-id",status:"fail",bead_id:$id,reason:"pattern_mismatch",pattern:"^flywheel-[a-z0-9]+(\\.[0-9]+)*$"}'
      return 1
      ;;
    evidence-path)
      if [[ -z "$target" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"evidence-path",status:"fail",reason:"path_required"}'
        return 1
      fi
      local repo_root; repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
      local rel="${target#"$repo_root"/}"
      if [[ "$rel" == .flywheel/audit/flywheel-* || "$rel" == .flywheel/journal/* ]]; then
        if [[ -e "$target" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$target" \
            '{schema_version:$sv,command:"validate",subject:"evidence-path",status:"pass",path:$p}'
          return 0
        fi
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$target" \
          '{schema_version:$sv,command:"validate",subject:"evidence-path",status:"fail",path:$p,reason:"not_found_on_disk"}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$target" \
        '{schema_version:$sv,command:"validate",subject:"evidence-path",status:"fail",path:$p,reason:"not_under_canonical_evidence_dirs",canonical_dirs:[".flywheel/audit/flywheel-<id>/",".flywheel/journal/"]}'
      return 1
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"--subject required",valid_subjects:["bead-id","evidence-path","audit-row"]}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["bead-id","evidence-path","audit-row"]}'
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
  match="$(jq -c --arg id "$id" 'select(.ts == $id or (.idempotency_key // "") == $id or (.bead_id // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tail -1)"
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
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = "bead-evidence-index/v1"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel"


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def expand(path: str | Path) -> Path:
    return Path(path).expanduser()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def read_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    if not path.exists():
        return rows
    with path.open(encoding="utf-8", errors="ignore") as handle:
        for line_no, line in enumerate(handle, 1):
            text = line.strip()
            if not text:
                continue
            try:
                row = json.loads(text)
            except Exception:
                continue
            if isinstance(row, dict):
                row["_line"] = line_no
                rows.append(row)
    return rows


def append_jsonl(path: Path, row: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(row, sort_keys=True, separators=(",", ":"))
    with path.open("a", encoding="utf-8") as handle:
        handle.write(encoded + "\n")


def callback_evidence_path(text: str) -> str | None:
    match = re.search(r"(?:^|\s)evidence=([^ \t\n]+)", text)
    if match:
        return match.group(1)
    match = re.search(r"(?:^|\s)evidence_path=([^ \t\n]+)", text)
    if match:
        return match.group(1)
    return None


def callback_bead_id(text: str) -> str | None:
    match = re.search(r"\b(?:DONE|BLOCKED)\s+(flywheel-[A-Za-z0-9._-]+)\b", text)
    if match:
        return match.group(1)
    match = re.search(r"\bbead_id=(flywheel-[A-Za-z0-9._-]+)\b", text)
    if match:
        return match.group(1)
    return None


def existing_latest(index_path: Path) -> dict[str, dict]:
    latest: dict[str, dict] = {}
    for row in read_jsonl(index_path):
        bead_id = str(row.get("bead_id") or "")
        if bead_id:
            latest[bead_id] = row
    return latest


def resolve_candidate(raw: str | None, repo: Path) -> Path | None:
    if not raw:
        return None
    path = expand(raw)
    if not path.is_absolute():
        path = repo / path
    return path


def source_from_callback_file(path: Path, repo: Path) -> tuple[Path, str] | None:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return None
    raw = callback_evidence_path(text)
    candidate = resolve_candidate(raw, repo)
    if candidate and candidate.exists() and candidate.is_file():
        return candidate, "callback_evidence_field"
    return None


def scan_tmp_for_evidence(bead_id: str, tmp_dir: Path, repo: Path) -> tuple[Path, str] | None:
    suffix = bead_id.removeprefix("flywheel-")
    candidates: list[Path] = []
    for pattern in (f"*{bead_id}*", f"*{suffix}*"):
        candidates.extend(path for path in tmp_dir.glob(pattern) if path.is_file())
    unique = sorted(set(candidates), key=lambda p: (
        0 if "evidence" in p.name else 1,
        0 if p.suffix in {".md", ".txt", ".json"} else 1,
        len(p.name),
        p.name,
    ))
    for path in unique:
        if "callback" in path.name:
            resolved = source_from_callback_file(path, repo)
            if resolved:
                return resolved
        if "evidence" in path.name or bead_id in path.name or suffix in path.name:
            return path, "tmp_scan"
    return None


def durable_name(bead_id: str, source: Path) -> str:
    suffix = source.suffix if source.suffix else ".evidence"
    return f"{bead_id}{suffix}"


def build_records_from_dispatch_log(args: argparse.Namespace) -> list[dict]:
    dispatch_log = expand(args.dispatch_log)
    if not dispatch_log.is_absolute():
        dispatch_log = expand(args.repo).resolve() / dispatch_log
    rows = read_jsonl(dispatch_log)
    records: list[dict] = []
    for row in rows:
        if row.get("event") != "closed":
            continue
        bead_id = str(row.get("bead_id") or "")
        if not bead_id:
            continue
        if args.bead and bead_id != args.bead:
            continue
        raw = row.get("evidence_path") or row.get("evidence") or row.get("jeff_issue_body") or row.get("report_path")
        records.append({
            "bead_id": bead_id,
            "task_id": row.get("task_id"),
            "dispatch_ts": row.get("ts"),
            "dispatch_line": row.get("_line"),
            "raw_source": raw,
            "record_source": "dispatch_log",
        })
    return records


def build_records_from_callback(args: argparse.Namespace) -> list[dict]:
    text = ""
    if args.callback:
        text = args.callback
    elif args.callback_file:
        text = expand(args.callback_file).read_text(encoding="utf-8", errors="ignore")
    if not text:
        return []
    bead_id = args.bead or callback_bead_id(text)
    if not bead_id:
        return []
    return [{
        "bead_id": bead_id,
        "task_id": None,
        "dispatch_ts": None,
        "dispatch_line": None,
        "raw_source": callback_evidence_path(text),
        "record_source": "callback",
    }]


def index_record(record: dict, args: argparse.Namespace, latest: dict[str, dict], now: str) -> dict:
    repo = expand(args.repo).resolve()
    tmp_dir = expand(args.tmp_dir)
    evidence_dir = expand(args.evidence_dir)
    index_path = expand(args.index)
    bead_id = record["bead_id"]

    source_kind = "missing"
    source_path = resolve_candidate(record.get("raw_source"), repo)
    if source_path and source_path.exists() and source_path.is_file():
        source_kind = "dispatch_field" if record["record_source"] == "dispatch_log" else "callback_field"
    else:
        scanned = scan_tmp_for_evidence(bead_id, tmp_dir, repo)
        if scanned:
            source_path, source_kind = scanned

    base = {
        "schema_version": SCHEMA,
        "ts": now,
        "bead_id": bead_id,
        "task_id": record.get("task_id"),
        "dispatch_ts": record.get("dispatch_ts"),
        "dispatch_line": record.get("dispatch_line"),
        "record_source": record.get("record_source"),
        "source_kind": source_kind,
        "apply": bool(args.apply),
    }

    if not source_path or not source_path.exists() or not source_path.is_file():
        row = {**base, "status": "missing", "source_path": str(source_path) if source_path else None}
        if args.apply:
            append_jsonl(index_path, row)
        return row

    source_hash = sha256_file(source_path)
    dest = evidence_dir / durable_name(bead_id, source_path)
    previous = latest.get(bead_id)
    if previous and previous.get("source_sha256") == source_hash and previous.get("durable_path"):
        return {
            **base,
            "status": "already_indexed",
            "source_path": str(source_path),
            "source_sha256": source_hash,
            "durable_path": previous.get("durable_path"),
        }

    row = {
        **base,
        "status": "indexed" if args.apply else "would_index",
        "source_path": str(source_path),
        "source_sha256": source_hash,
        "source_bytes": source_path.stat().st_size,
        "durable_path": str(dest),
    }
    if args.apply:
        evidence_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, dest)
        append_jsonl(index_path, row)
        latest[bead_id] = row
    return row


def run_once(args: argparse.Namespace) -> dict:
    now = iso_now()
    index_path = expand(args.index)
    latest = existing_latest(index_path)
    records = build_records_from_callback(args) or build_records_from_dispatch_log(args)
    rows = [index_record(record, args, latest, now) for record in records]
    status_counts: dict[str, int] = {}
    for row in rows:
        status_counts[row["status"]] = status_counts.get(row["status"], 0) + 1
    missing_count = status_counts.get("missing", 0)
    return {
        "schema_version": SCHEMA,
        "mode": "apply" if args.apply else "dry-run",
        "status": "missing_evidence" if missing_count else "ok",
        "record_count": len(rows),
        "status_counts": status_counts,
        "index_path": str(index_path),
        "evidence_dir": str(expand(args.evidence_dir)),
        "rows": rows[: args.limit] if args.limit else rows,
    }


def doctor(args: argparse.Namespace) -> dict:
    args.apply = False
    result = run_once(args)
    return {
        "schema_version": SCHEMA,
        "status": "warn" if result["status_counts"].get("missing", 0) else "ok",
        "closed_records_observed": result["record_count"],
        "missing_evidence_count": result["status_counts"].get("missing", 0),
        "indexed_count": len(existing_latest(expand(args.index))),
        "index_path": str(expand(args.index)),
        "evidence_dir": str(expand(args.evidence_dir)),
    }


def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"{payload.get('status', 'ok')}: {payload.get('record_count', payload.get('indexed_count', 0))}")


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Persist durable evidence paths for closed flywheel beads.")
    p.add_argument("--repo", default=os.getcwd())
    p.add_argument("--dispatch-log", default=".flywheel/dispatch-log.jsonl")
    p.add_argument("--state-dir", default=str(DEFAULT_STATE_DIR))
    p.add_argument("--evidence-dir", default=None)
    p.add_argument("--index", default=None)
    p.add_argument("--tmp-dir", default="/tmp")
    p.add_argument("--bead")
    p.add_argument("--callback")
    p.add_argument("--callback-file")
    p.add_argument("--apply", action="store_true")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--watch", action="store_true")
    p.add_argument("--sleep-seconds", type=float, default=5.0)
    p.add_argument("--max-cycles", type=int, default=0)
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--doctor", action="store_true")
    p.add_argument("--repair", action="store_true")
    p.add_argument("--info", action="store_true")
    p.add_argument("--schema", action="store_true")
    return p


def main() -> int:
    args = parser().parse_args()
    state_dir = expand(args.state_dir)
    if args.evidence_dir is None:
        args.evidence_dir = str(state_dir / "bead-evidence")
    if args.index is None:
        args.index = str(state_dir / "bead-evidence-index.jsonl")
    if args.repair:
        args.apply = True

    if args.info:
        emit({
            "schema_version": SCHEMA,
            "commands": ["--doctor", "--repair", "--watch", "--apply", "--dry-run"],
            "default_mode": "dry-run",
            "mutates_only_with": "--apply or --repair",
            "index_path": args.index,
            "evidence_dir": args.evidence_dir,
        }, args.json)
        return 0
    if args.schema:
        emit({
            "schema_version": SCHEMA,
            "row_required": ["schema_version", "ts", "bead_id", "status", "source_kind", "durable_path"],
            "statuses": ["would_index", "indexed", "already_indexed", "missing"],
            "exit_codes": {"0": "completed", "1": "doctor found missing evidence", "2": "usage error"},
        }, args.json)
        return 0
    if args.doctor:
        payload = doctor(args)
        emit(payload, args.json)
        return 1 if payload["status"] == "warn" else 0

    cycles = 0
    last_payload: dict | None = None
    while True:
        last_payload = run_once(args)
        cycles += 1
        if not args.watch or (args.max_cycles and cycles >= args.max_cycles):
            break
        time.sleep(args.sleep_seconds)
    emit(last_payload or {}, args.json)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(0)
PY
