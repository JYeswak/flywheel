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
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="storage-pause-auto-resume/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-pause-auto-resume-runs.jsonl}"

# Module-load env vars (also re-resolved in cmd_run for backward compat).
# Visible to canonical-cli stubs which run BEFORE cmd_run dispatches.
STATE_FILE="${STATE_FILE:-${FLYWHEEL_STORAGE_PAUSE_STATE:-$HOME/.local/state/flywheel/storage-pause-active.json}}"
RECLAIM_DIR="${RECLAIM_DIR:-${FLYWHEEL_RECLAIM_RECEIPT_DIR:-$HOME/.local/state/flywheel/reclaim-receipts}}"

scaffold_usage() {
  cat <<'USG'
usage: storage-pause-auto-resume.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "storage-pause-auto-resume.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "storage-pause-auto-resume.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"storage-pause-auto-resume.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"storage-pause-auto-resume.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"storage-pause-auto-resume.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "storage-pause-auto-resume" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "storage-pause-auto-resume" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Probe storage-pause-auto-resume substrate.
  local checks
  checks="$(jq -cs '.' <(
    if [[ -f "$STATE_FILE" ]]; then
      jq -nc --arg p "$STATE_FILE" '{check:"state_file",path:$p,status:"pass",present:true}'
    else
      jq -nc --arg p "$STATE_FILE" '{check:"state_file",path:$p,status:"pass",present:false,note:"no active pause"}'
    fi
    if [[ -d "$RECLAIM_DIR" ]]; then
      jq -nc --arg p "$RECLAIM_DIR" '{check:"reclaim_dir",path:$p,status:"pass"}'
    else
      jq -nc --arg p "$RECLAIM_DIR" '{check:"reclaim_dir",path:$p,status:"warn",reason:"missing — repair --scope state will create"}'
    fi
    if command -v df >/dev/null 2>&1; then
      jq -nc '{check:"df",status:"pass",dependency:"disk-space-probe"}'
    else
      jq -nc '{check:"df",status:"fail",reason:"df required for headroom signal"}'
    fi
    if command -v "${KILL_BIN:-kill}" >/dev/null 2>&1; then
      jq -nc --arg b "${KILL_BIN:-kill}" '{check:"kill_bin",bin:$b,status:"pass"}'
    else
      jq -nc --arg b "${KILL_BIN:-kill}" '{check:"kill_bin",bin:$b,status:"fail",reason:"kill bin missing — pause/resume disabled"}'
    fi
    if command -v jq >/dev/null 2>&1; then
      jq -nc '{check:"core_deps",status:"pass",found:["jq"]}'
    else
      jq -nc '{check:"core_deps",status:"fail",reason:"jq required"}'
    fi
  ))"
  local fails warns
  fails="$(jq -r '[.[] | select(.status=="fail")] | length' <<<"$checks")"
  warns="$(jq -r '[.[] | select(.status=="warn")] | length' <<<"$checks")"
  local status
  if [[ "$fails" -gt 0 ]]; then
    status="fail"
  elif [[ "$warns" -gt 0 ]]; then
    status="warn"
  else
    status="pass"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --argjson checks "$checks" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:$checks}'
}

scaffold_cmd_health() {
  # Health: pause active? + last reclaim receipt + audit log freshness.
  local pause_active="false" pause_ts="" reclaim_count=0 latest_reclaim="" latest_reclaim_ts=""
  local audit_row_count=0 last_audit_ts=""
  if [[ -f "$STATE_FILE" ]]; then
    pause_active="true"
    pause_ts="$(jq -r '.ts // empty' "$STATE_FILE" 2>/dev/null)"
  fi
  if [[ -d "$RECLAIM_DIR" ]]; then
    reclaim_count="$(find "$RECLAIM_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null | wc -l | tr -d ' ')"
    latest_reclaim="$(find "$RECLAIM_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null | sort | tail -1)"
    if [[ -n "$latest_reclaim" && -r "$latest_reclaim" ]]; then
      latest_reclaim_ts="$(jq -r '.ts // empty' "$latest_reclaim" 2>/dev/null)"
    fi
  fi
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    audit_row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
    last_audit_ts="$(tail -1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null)"
  fi
  local status
  if [[ "$pause_active" == "true" ]]; then
    status="paused"
  elif [[ "${audit_row_count:-0}" -gt 0 || "${reclaim_count:-0}" -gt 0 ]]; then
    status="ok"
  else
    status="not_initialized"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --arg pause_ts "$pause_ts" \
    --arg latest_reclaim "$latest_reclaim" \
    --arg latest_reclaim_ts "$latest_reclaim_ts" \
    --arg last_audit_ts "$last_audit_ts" \
    --argjson pause_active "$pause_active" \
    --argjson reclaim_count "$reclaim_count" \
    --argjson audit_row_count "$audit_row_count" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,pause_active:$pause_active,pause_ts:(if $pause_ts=="" then null else $pause_ts end),reclaim_count:$reclaim_count,latest_reclaim_path:(if $latest_reclaim=="" then null else $latest_reclaim end),latest_reclaim_ts:(if $latest_reclaim_ts=="" then null else $latest_reclaim_ts end),audit_row_count:$audit_row_count,last_audit_ts:(if $last_audit_ts=="" then null else $last_audit_ts end)}'
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
  # repair --scope state: ensure RECLAIM_DIR + audit log dir exist; clear stale STATE_FILE if expired.
  local audit_dir planned applied
  audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  planned="$(jq -cs '.' <(
    if [[ "$scope" != "state" ]]; then
      jq -nc --arg s "$scope" '{action:"none",reason:"unsupported scope (state only)",scope:$s}'
    else
      if [[ ! -d "$RECLAIM_DIR" ]]; then
        jq -nc --arg p "$RECLAIM_DIR" '{action:"mkdir",path:$p,mode:"0755"}'
      fi
      if [[ ! -d "$audit_dir" ]]; then
        jq -nc --arg p "$audit_dir" '{action:"mkdir",path:$p,mode:"0755"}'
      fi
    fi
  ))"
  applied='[]'
  if [[ "$mode" == "apply" && "$scope" == "state" ]]; then
    local applied_rows=()
    if [[ ! -d "$RECLAIM_DIR" ]]; then
      mkdir -p "$RECLAIM_DIR" && chmod 755 "$RECLAIM_DIR" 2>/dev/null
      applied_rows+=("$(jq -nc --arg p "$RECLAIM_DIR" --arg key "$idem_key" '{action:"mkdir",path:$p,mode:"0755",idempotency_key:$key}')")
    fi
    if [[ ! -d "$audit_dir" ]]; then
      mkdir -p "$audit_dir" && chmod 755 "$audit_dir" 2>/dev/null
      applied_rows+=("$(jq -nc --arg p "$audit_dir" --arg key "$idem_key" '{action:"mkdir",path:$p,mode:"0755",idempotency_key:$key}')")
    fi
    if [[ "${#applied_rows[@]}" -eq 0 ]]; then
      applied='[]'
    else
      applied="$(printf '%s\n' "${applied_rows[@]}" | jq -cs '.')"
    fi
    if command -v cli_audit_append >/dev/null; then
      cli_audit_append "$SCAFFOLD_AUDIT_LOG" "repair_state_apply" "ok" \
        "$(jq -nc --arg key "$idem_key" --argjson actions "$applied" '{idempotency_key:$key,actions:$actions}')"
    fi
  fi
  local status
  if [[ "$mode" == "apply" ]]; then
    status="applied"
  else
    status="dry_run"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg scope "$scope" \
    --arg mode "$mode" \
    --arg idem "$idem_key" \
    --arg status "$status" \
    --argjson planned "$planned" \
    --argjson applied "$applied" \
    '{schema_version:$sv,command:"repair",status:$status,mode:$mode,scope:$scope,idempotency_key:$idem,planned_actions:$planned,applied_actions:$applied}'
}

scaffold_cmd_validate() {
  local subject="${1:-state_file}"
  if [[ "$subject" == "-h" || "$subject" == "--help" ]]; then
    scaffold_emit_topic_help validate
    return 0
  fi
  shift 2>/dev/null || true
  local results status
  case "$subject" in
    state_file)
      # Validate STATE_FILE shape: when present, must carry timestamp +
      # paused_workers[] + reason. Accepts ts/generated_at for the timestamp
      # and paused_pids/paused_workers/pids for the worker list (production
      # state files use generated_at + paused_workers).
      if [[ ! -f "$STATE_FILE" ]]; then
        results="$(jq -nc '[{check:"present",status:"pass",note:"no active pause (state file absent)"}]')"
      else
        local has_ts has_workers has_reason
        has_ts="false"; has_workers="false"; has_reason="false"
        if jq -e 'has("ts") or has("generated_at")' "$STATE_FILE" >/dev/null 2>&1; then has_ts="true"; fi
        if jq -e '(.paused_pids // .paused_workers // .pids // []) | type == "array"' "$STATE_FILE" >/dev/null 2>&1; then has_workers="true"; fi
        if jq -e 'has("reason")' "$STATE_FILE" >/dev/null 2>&1; then has_reason="true"; fi
        results="$(jq -nc \
          --arg p "$STATE_FILE" \
          --argjson hts "$has_ts" \
          --argjson hw "$has_workers" \
          --argjson hr "$has_reason" \
          '[
            {check:"present",path:$p,status:"pass"},
            {check:"timestamp_field",status:(if $hts then "pass" else "fail" end),accepts:["ts","generated_at"]},
            {check:"paused_workers_array",status:(if $hw then "pass" else "fail" end),accepts:["paused_pids","paused_workers","pids"]},
            {check:"reason_field",status:(if $hr then "pass" else "fail" end)}
          ]')"
      fi
      ;;
    *)
      results="$(jq -nc --arg s "$subject" '[{status:"unsupported",subject:$s,supported:["state_file"]}]')"
      ;;
  esac
  local fails
  fails="$(jq -r '[.[] | select(.status=="fail")] | length' <<<"$results")"
  if [[ "$fails" -gt 0 ]]; then
    status="fail"
  else
    status="pass"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg subject "$subject" \
    --arg status "$status" \
    --argjson results "$results" \
    '{schema_version:$sv,command:"validate",subject:$subject,status:$status,results:$results}'
}

scaffold_cmd_audit() {
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" 20
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",audit_log:$log,status:"helper_lib_missing"}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # <id> is a reclaim receipt timestamp basename (e.g. "20260510T160000Z").
  local receipt="$RECLAIM_DIR/$id.json"
  if [[ -r "$receipt" ]]; then
    jq -nc \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg id "$id" \
      --arg path "$receipt" \
      --argjson body "$(cat "$receipt")" \
      '{schema_version:$sv,command:"why",id:$id,status:"found",receipt_path:$path,reclaim:$body}'
  else
    jq -nc \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg id "$id" \
      --arg dir "$RECLAIM_DIR" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",reclaim_dir:$dir,note:"id not present in reclaim receipt dir"}'
  fi
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
STATE_FILE="${FLYWHEEL_STORAGE_PAUSE_STATE:-$HOME/.local/state/flywheel/storage-pause-active.json}"
RECLAIM_DIR="${FLYWHEEL_RECLAIM_RECEIPT_DIR:-$HOME/.local/state/flywheel/reclaim-receipts}"
APPLY=0
JSON_OUT=0
KILL_BIN="${KILL_BIN:-kill}"

usage() {
  cat <<'EOF'
usage: storage-pause-auto-resume.sh [--state PATH] [--reclaim-dir PATH] [--dry-run|--apply] [--json]

Resumes SIGSTOP-paused storage-growth workers when a reclaim receipt exists
newer than the active storage-pause signal. Default is dry-run.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --state) STATE_FILE="$2"; shift 2 ;;
    --reclaim-dir) RECLAIM_DIR="$2"; shift 2 ;;
    --dry-run) APPLY=0; shift ;;
    --apply) APPLY=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ ! -f "$STATE_FILE" ]; then
  jq -nc '{schema_version:"storage-pause-auto-resume/v1",status:"no_active_pause",resumed_count:0}'
  exit 0
fi

latest_reclaim="$(find "$RECLAIM_DIR" -type f -name '*.json' -print 2>/dev/null | sort | tail -1 || true)"
if [ -z "$latest_reclaim" ]; then
  jq -nc --arg state "$STATE_FILE" '{schema_version:"storage-pause-auto-resume/v1",status:"waiting_for_reclaim_receipt",state_path:$state,resumed_count:0}'
  exit 0
fi

reclaim_ts="$(jq -r '.issued_at // .created_at // .ts // empty' "$latest_reclaim" 2>/dev/null || true)"
pause_ts="$(jq -r '.generated_at // empty' "$STATE_FILE" 2>/dev/null || true)"
if [ -n "$reclaim_ts" ] && [ -n "$pause_ts" ] && [[ "$reclaim_ts" < "$pause_ts" ]]; then
  jq -nc --arg state "$STATE_FILE" --arg reclaim "$latest_reclaim" '{schema_version:"storage-pause-auto-resume/v1",status:"reclaim_receipt_stale",state_path:$state,reclaim_receipt:$reclaim,resumed_count:0}'
  exit 0
fi

pids="$(jq -r '.paused_workers[]? | .pids[]?' "$STATE_FILE" 2>/dev/null | sort -n | uniq || true)"
resumed_count=0
failed_count=0
resumed_json="[]"
failed_json="[]"

while IFS= read -r pid; do
  [ -n "$pid" ] || continue
  if [ "$APPLY" -eq 1 ]; then
    if "$KILL_BIN" -CONT "$pid" 2>/dev/null; then
      resumed_count=$((resumed_count + 1))
      resumed_json="$(jq -nc --argjson old "$resumed_json" --arg pid "$pid" '$old + [$pid]')"
    else
      failed_count=$((failed_count + 1))
      failed_json="$(jq -nc --argjson old "$failed_json" --arg pid "$pid" '$old + [$pid]')"
    fi
  else
    resumed_json="$(jq -nc --argjson old "$resumed_json" --arg pid "$pid" '$old + [$pid]')"
  fi
done <<EOF
$pids
EOF

status="would_resume"
if [ "$APPLY" -eq 1 ]; then
  if [ "$failed_count" -gt 0 ]; then
    status="partial"
  else
    status="resumed"
  fi
fi

jq -nc \
  --arg status "$status" \
  --arg state "$STATE_FILE" \
  --arg reclaim "$latest_reclaim" \
  --argjson apply "$APPLY" \
  --argjson resumed_count "$resumed_count" \
  --argjson failed_count "$failed_count" \
  --argjson resumed "$resumed_json" \
  --argjson failed "$failed_json" \
  '{schema_version:"storage-pause-auto-resume/v1",status:$status,apply:($apply==1),state_path:$state,reclaim_receipt:$reclaim,resumed_count:$resumed_count,failed_count:$failed_count,pids:$resumed,failed_pids:$failed}'
