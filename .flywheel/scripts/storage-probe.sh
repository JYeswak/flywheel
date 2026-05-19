#!/usr/bin/env bash
# shellcheck disable=SC2034
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

SCAFFOLD_SCHEMA_VERSION="storage-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-probe-runs.jsonl}"

# Module-load env vars (also re-resolved in cmd_run for backward compat).
# Visible to canonical-cli stubs which run BEFORE cmd_run dispatches.
DISK_PATH="${DISK_PATH:-/}"
HISTORY="${HISTORY:-${FLYWHEEL_STORAGE_HISTORY:-$HOME/.local/state/flywheel/storage-history.jsonl}}"

scaffold_usage() {
  cat <<'USG'
usage: storage-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "storage-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "storage-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"storage-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"storage-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"storage-probe.sh doctor --json"}'
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
            && cli_emit_completion_bash "storage-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "storage-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Probe storage-probe substrate: df + jq + JSONL append lib + history file + disk path.
  local checks
  checks="$(jq -cs '.' <(
    if command -v df >/dev/null 2>&1; then
      jq -nc '{check:"df",status:"pass",dependency:"disk-space-probe"}'
    else
      jq -nc '{check:"df",status:"fail",reason:"df required for storage probe"}'
    fi
    if command -v jq >/dev/null 2>&1; then
      jq -nc '{check:"jq",status:"pass"}'
    else
      jq -nc '{check:"jq",status:"fail",reason:"jq required"}'
    fi
    if [[ -d "$DISK_PATH" ]]; then
      jq -nc --arg p "$DISK_PATH" '{check:"disk_path",path:$p,status:"pass"}'
    else
      jq -nc --arg p "$DISK_PATH" '{check:"disk_path",path:$p,status:"fail",reason:"disk path not a directory"}'
    fi
    local hist_dir
    hist_dir="$(dirname "$HISTORY")"
    if [[ -d "$hist_dir" ]]; then
      jq -nc --arg p "$hist_dir" '{check:"history_dir",path:$p,status:"pass"}'
    else
      jq -nc --arg p "$hist_dir" '{check:"history_dir",path:$p,status:"warn",reason:"missing — repair --scope state will create"}'
    fi
    if [[ -f "$HISTORY" ]]; then
      local row_count
      row_count="$(wc -l <"$HISTORY" 2>/dev/null | tr -d ' ')"
      jq -nc --arg p "$HISTORY" --argjson n "${row_count:-0}" '{check:"history_file",path:$p,status:"pass",row_count:$n}'
    else
      jq -nc --arg p "$HISTORY" '{check:"history_file",path:$p,status:"warn",reason:"history not yet written"}'
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
  # Health: tail history; report most-recent free_pct + age + run count.
  local row_count=0 latest_ts="" latest_free_pct=null age_seconds=null status="empty"
  if [[ -r "$HISTORY" ]]; then
    row_count="$(wc -l <"$HISTORY" 2>/dev/null | tr -d ' ')"
    if [[ "${row_count:-0}" -gt 0 ]]; then
      local last_row
      last_row="$(tail -1 "$HISTORY" 2>/dev/null)"
      latest_ts="$(jq -r '.ts // .timestamp // empty' <<<"$last_row" 2>/dev/null)"
      latest_free_pct="$(jq -r '.free_pct // .disk.free_pct // empty' <<<"$last_row" 2>/dev/null)"
      [[ -z "$latest_free_pct" ]] && latest_free_pct=null
      if [[ -n "$latest_ts" ]]; then
        local now_epoch last_epoch
        now_epoch="$(date -u +%s 2>/dev/null)"
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$latest_ts" +%s 2>/dev/null || date -u -d "$latest_ts" +%s 2>/dev/null || echo "")"
        if [[ -n "$now_epoch" && -n "$last_epoch" ]]; then
          age_seconds=$((now_epoch - last_epoch))
        fi
      fi
      status="ok"
    fi
  else
    status="not_initialized"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --arg latest_ts "$latest_ts" \
    --argjson row_count "$row_count" \
    --argjson latest_free_pct "$latest_free_pct" \
    --argjson age_seconds "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,history_row_count:$row_count,latest_history_ts:(if $latest_ts=="" then null else $latest_ts end),latest_free_pct:$latest_free_pct,latest_history_age_seconds:$age_seconds}'
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
  # repair --scope state: ensure HISTORY parent dir + audit log dir exist.
  local hist_dir audit_dir planned applied
  hist_dir="$(dirname "$HISTORY")"
  audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  planned="$(jq -cs '.' <(
    if [[ "$scope" != "state" ]]; then
      jq -nc --arg s "$scope" '{action:"none",reason:"unsupported scope (state only)",scope:$s}'
    else
      if [[ ! -d "$hist_dir" ]]; then
        jq -nc --arg p "$hist_dir" '{action:"mkdir",path:$p,mode:"0755"}'
      fi
      if [[ ! -d "$audit_dir" ]]; then
        jq -nc --arg p "$audit_dir" '{action:"mkdir",path:$p,mode:"0755"}'
      fi
    fi
  ))"
  applied='[]'
  if [[ "$mode" == "apply" && "$scope" == "state" ]]; then
    local applied_rows=()
    if [[ ! -d "$hist_dir" ]]; then
      mkdir -p "$hist_dir" && chmod 755 "$hist_dir" 2>/dev/null
      applied_rows+=("$(jq -nc --arg p "$hist_dir" --arg key "$idem_key" '{action:"mkdir",path:$p,mode:"0755",idempotency_key:$key}')")
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
  local subject="${1:-history}"
  if [[ "$subject" == "-h" || "$subject" == "--help" ]]; then
    scaffold_emit_topic_help validate
    return 0
  fi
  shift 2>/dev/null || true
  local results status
  case "$subject" in
    history)
      # Validate every row of HISTORY has a timestamp + free percentage.
      # Accepts ts|timestamp for time and disk_free_pct|free_pct|disk.free_pct
      # for the free percentage (production rows use disk_free_pct).
      if [[ ! -f "$HISTORY" ]]; then
        results="$(jq -nc '[{check:"present",status:"pass",note:"history not yet written"}]')"
      else
        local total_rows malformed_rows schema_pass schema_fail
        total_rows="$(wc -l <"$HISTORY" 2>/dev/null | tr -d ' ')"
        total_rows="${total_rows:-0}"
        set +o pipefail
        malformed_rows="$(grep -c -v '^{' "$HISTORY" 2>/dev/null || true)"
        schema_pass="$(jq -s '[.[] | select((.ts? // .timestamp? // null) != null and (.disk_free_pct? // .free_pct? // .disk.free_pct? // null) != null)] | length' "$HISTORY" 2>/dev/null || echo 0)"
        set -o pipefail
        malformed_rows="${malformed_rows:-0}"
        schema_pass="${schema_pass:-0}"
        schema_fail=$(( total_rows - schema_pass ))
        results="$(jq -nc \
          --arg p "$HISTORY" \
          --argjson total "$total_rows" \
          --argjson malformed "$malformed_rows" \
          --argjson sp "$schema_pass" \
          --argjson sf "$schema_fail" \
          '[
            {check:"present",path:$p,status:"pass"},
            {check:"row_count",total:$total,status:(if $total > 0 then "pass" else "warn" end)},
            {check:"malformed_lines",count:$malformed,status:(if $malformed == 0 then "pass" else "fail" end)},
            {check:"schema_conformance",total:$total,passing:$sp,failing:$sf,status:(if $sf == 0 then "pass" else "fail" end)}
          ]')"
      fi
      ;;
    *)
      results="$(jq -nc --arg s "$subject" '[{status:"unsupported",subject:$s,supported:["history"]}]')"
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
  # <id> is a history-row timestamp (e.g. "2026-05-10T16:00:00Z"). Look up
  # the matching row by ts/timestamp field.
  if [[ ! -r "$HISTORY" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg p "$HISTORY" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"history not yet written",path:$p}'
    return 0
  fi
  local hit
  hit="$(jq -c --arg id "$id" 'select((.ts // .timestamp // "") == $id)' "$HISTORY" 2>/dev/null | head -1)"
  if [[ -n "$hit" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg p "$HISTORY" --argjson row "$hit" \
      '{schema_version:$sv,command:"why",id:$id,status:"found",path:$p,row:$row}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg p "$HISTORY" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",path:$p,note:"timestamp not present in history"}'
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
VERSION="storage-probe.v1"
REPO="/Users/josh/Developer/flywheel"
DISK_PATH="/"
HISTORY="${FLYWHEEL_STORAGE_HISTORY:-$HOME/.local/state/flywheel/storage-history.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
JSONL_APPEND_AVAILABLE=0
FIXTURE=""
JSON_OUT=1
RECORD_HISTORY=0
NOTIFY_LOW=0
MIN_FREE_PCT="${FLYWHEEL_STORAGE_MIN_FREE_PCT:-10}"
FIRE_FREE_PCT="${FLYWHEEL_STORAGE_FIRE_FREE_PCT:-5}"
NOTIFY_BIN="${NOTIFY_BIN:-$HOME/.local/bin/notify}"
PROBE_WARNINGS_FILE="$(mktemp "${TMPDIR:-/tmp}/storage-probe-warnings.XXXXXX")"
trap 'rm -f "$PROBE_WARNINGS_FILE"' EXIT

if [[ -f "$JSONL_APPEND_LIB" ]]; then
  # shellcheck disable=SC1090,SC1091
  if source "$JSONL_APPEND_LIB" && declare -F fw_jsonl_append_validated >/dev/null; then
    JSONL_APPEND_AVAILABLE=1
  fi
fi

usage() {
  printf '%s\n' \
    "Usage:" \
    "  storage-probe.sh [--json] [--repo PATH] [--record-history] [--notify]" \
    "  storage-probe.sh --fixture PATH [--json] [--record-history] [--notify]" \
    "  storage-probe.sh capabilities --json" \
    "  storage-probe.sh robot-docs" \
    "  storage-probe.sh --schema|--info|--examples|--help" \
    "" \
    "Agent automation: start with capabilities --json, then run --json. Use" \
    "--record-history only when intentionally appending storage history." \
    "Exit codes: 0 success, 1 dependency/probe failure, 2 usage error." \
    "" \
    "Fields: disk_free_gb, disk_free_pct, developer_dir_gb, local_state_gb," \
    "stale_baks_count, stale_baks_size_mb, qdrant_volumes_size_mb, tmp_dispatch_artifacts_count."
}

examples() {
  printf '%s\n' \
    "Examples:" \
    "  .flywheel/scripts/storage-probe.sh --json" \
    "  .flywheel/scripts/storage-probe.sh --record-history --json" \
    "  .flywheel/scripts/storage-probe.sh --fixture tests/fixtures/storage-low.json --json"
}

schema_json() {
  jq -nc '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"flywheel storage probe",
    type:"object",
    required:["version","ts","status","disk_free_gb","disk_free_pct","developer_dir_gb","local_state_gb","stale_baks_count","stale_baks_size_mb","qdrant_volumes_size_mb","tmp_dispatch_artifacts_count","errors","warnings"],
    properties:{
      status:{enum:["ok","warn","fail"]},
      disk_free_gb:{type:"number"},
      disk_free_pct:{type:"number"},
      stale_baks_count:{type:"integer"}
    }
  }'
}

capabilities_json() {
  jq -nc --arg version "$VERSION" --arg history "$HISTORY" '{
    schema_version:"storage-probe.capabilities.v1",
    command:"capabilities",
    version:$version,
    contract_version:"1",
    features:["json_output","fixture_mode","history_append_opt_in","thresholds","robot_docs"],
    commands:{
      probe:{command:"storage-probe.sh --json",read_only:true},
      fixture:{command:"storage-probe.sh --fixture PATH --json",read_only:true},
      record_history:{command:"storage-probe.sh --record-history --json",read_only:false},
      schema:{command:"storage-probe.sh --schema",read_only:true}
    },
    exit_codes:{"0":"success","1":"dependency/probe failure","2":"usage error"},
    env_vars:{
      FLYWHEEL_STORAGE_HISTORY:$history,
      FLYWHEEL_STORAGE_MIN_FREE_PCT:"minimum free percentage before fail",
      FLYWHEEL_STORAGE_FIRE_FREE_PCT:"fire threshold for notification"
    }
  }'
}

robot_docs() {
  cat <<'EOF'
Storage probe robot guide:
1. Discover: storage-probe.sh capabilities --json
2. Read current state: storage-probe.sh --json
3. Test with fixture: storage-probe.sh --fixture PATH --json
4. Append history only when requested: storage-probe.sh --record-history --json
5. Treat stdout as JSON data; diagnostics and usage errors go to stderr.
EOF
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

have() {
  command -v "$1" >/dev/null 2>&1
}

num_or_zero() {
  awk -v n="${1:-0}" 'BEGIN { if (n == "" || n == "null") n = 0; printf "%.2f", n + 0 }'
}

int_or_zero() {
  awk -v n="${1:-0}" 'BEGIN { if (n == "" || n == "null") n = 0; printf "%d", n + 0 }'
}

du_gb() {
  local path="$1" kb
  if [ ! -e "$path" ]; then
    printf '0.00'
    return 0
  fi
  kb="$(du -sk "$path" 2>/dev/null | awk '{print $1}' || printf 0)"
  awk -v kb="${kb:-0}" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }'
}

warn_probe() {
  printf '%s\n' "$1" >>"$PROBE_WARNINGS_FILE"
}

append_jsonl_best_effort() {
  local path="$1" row="$2" label="$3" rc
  if [[ "$JSONL_APPEND_AVAILABLE" -ne 1 ]] || ! declare -F fw_jsonl_append_validated >/dev/null; then
    printf 'WARN: %s append skipped; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2
    return 0
  fi
  if fw_jsonl_append_validated "$path" "$row"; then
    return 0
  else
    rc=$?
    printf 'WARN: %s append failed rc=%s path=%s\n' "$label" "$rc" "$path" >&2
    return 0
  fi
}

cached_metric() {
  local field="$1"
  if [ -s "$HISTORY" ]; then
    tail -100 "$HISTORY" 2>/dev/null | jq -rs --arg field "$field" 'map(select(.[$field] != null)) | last | .[$field] // empty' 2>/dev/null
  fi
}

quick_du_gb() {
  local path="$1" field="$2" cached tmp pid i kb
  cached="$(cached_metric "$field")"
  if [ -n "$cached" ] && [ "$cached" != "null" ]; then
    printf '%s\n' "$cached"
    return 0
  fi
  if [ ! -e "$path" ]; then
    printf '0.00'
    return 0
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/storage-du.XXXXXX")"
  du -sk "$path" >"$tmp" 2>/dev/null &
  pid=$!
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if [ -s "$tmp" ]; then
      wait "$pid" 2>/dev/null || true
      kb="$(awk '{print $1}' "$tmp" 2>/dev/null || printf 0)"
      rm -f "$tmp"
      awk -v kb="${kb:-0}" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }'
      return 0
    fi
    sleep 0.1
  done
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  rm -f "$tmp"
  warn_probe "${field}_du_timeout"
  printf '0.00'
}

du_mb() {
  local path="$1" kb
  if [ ! -e "$path" ]; then
    printf '0.00'
    return 0
  fi
  kb="$(du -sk "$path" 2>/dev/null | awk '{print $1}' || printf 0)"
  awk -v kb="${kb:-0}" 'BEGIN { printf "%.2f", kb / 1024 }'
}

disk_json() {
  local line total_kb free_kb
  line="$(df -Pk "$DISK_PATH" 2>/dev/null | awk 'NR==2 {print $2 "\t" $4}')"
  total_kb="$(awk '{print $1}' <<<"$line")"
  free_kb="$(awk '{print $2}' <<<"$line")"
  if [ -z "${total_kb:-}" ] || [ -z "${free_kb:-}" ] || [ "${total_kb:-0}" -le 0 ]; then
    jq -nc '{disk_total_gb:0,disk_free_gb:0,disk_free_pct:0,warning:"df_failed"}'
    return 0
  fi
  jq -nc \
    --argjson total "$total_kb" \
    --argjson free "$free_kb" \
    '{
      disk_total_gb:((($total / 1024 / 1024) * 100 | round) / 100),
      disk_free_gb:((($free / 1024 / 1024) * 100 | round) / 100),
      disk_free_pct:((($free / $total * 100) * 100 | round) / 100)
    }'
}

stale_baks_json() {
  local count=0 size_mb=0 path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    count=$((count + 1))
    size_mb="$(awk -v a="$size_mb" -v b="$(du_mb "$path")" 'BEGIN { printf "%.2f", a + b }')"
  done < <(find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' 2>/dev/null | sort)
  jq -nc --argjson count "$count" --argjson size "$size_mb" '{stale_baks_count:$count,stale_baks_size_mb:$size}'
}

qdrant_mb() {
  local total=0 path root
  for root in "$HOME/.orbstack/data/docker/volumes" "$HOME/.docker/volumes" "/var/lib/docker/volumes"; do
    [ -d "$root" ] || continue
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      total="$(awk -v a="$total" -v b="$(du_mb "$path")" 'BEGIN { printf "%.2f", a + b }')"
    done < <(find "$root" -maxdepth 1 -type d -iname '*qdrant*' 2>/dev/null)
  done
  printf '%s\n' "$total"
}

tmp_dispatch_count() {
  find /tmp -maxdepth 1 \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -type f 2>/dev/null | wc -l | tr -d ' '
}

fixture_json() {
  local raw
  raw="$(cat "$FIXTURE")"
  jq -c '.' <<<"$raw"
}

live_json() {
  local disk stale developer_gb local_state_gb qdrant tmp_count disk_warning probe_warnings
  disk="$(disk_json)"
  stale="$(stale_baks_json)"
  developer_gb="$(quick_du_gb "$HOME/Developer" "developer_dir_gb")"
  local_state_gb="$(quick_du_gb "$HOME/.local/state" "local_state_gb")"
  qdrant="$(qdrant_mb)"
  tmp_count="$(tmp_dispatch_count)"
  disk_warning="$(jq -r '.warning // ""' <<<"$disk")"
  probe_warnings="$(if [ -s "$PROBE_WARNINGS_FILE" ]; then jq -R . "$PROBE_WARNINGS_FILE" | jq -s .; else printf '[]'; fi)"
  jq -nc \
    --argjson disk "$disk" \
    --argjson stale "$stale" \
    --argjson developer "$developer_gb" \
    --argjson local_state "$local_state_gb" \
    --argjson qdrant "$qdrant" \
    --argjson tmp_count "$tmp_count" \
    --argjson probe_warnings "$probe_warnings" \
    --arg disk_warning "$disk_warning" \
    '$disk + $stale + {
      developer_dir_gb:$developer,
      local_state_gb:$local_state,
      qdrant_volumes_size_mb:$qdrant,
      tmp_dispatch_artifacts_count:$tmp_count,
      probe_warnings:($probe_warnings + (if $disk_warning == "" then [] else [$disk_warning] end))
    }'
}

status_json() {
  local base="$1"
  jq -c \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo "$REPO" \
    --arg history "$HISTORY" \
    --argjson min_free "$MIN_FREE_PCT" \
    --argjson fire_free "$FIRE_FREE_PCT" \
    '
      . as $m
      | (($m.disk_free_pct // 0) < $min_free) as $low
      | (($m.disk_free_pct // 0) < $fire_free) as $fire
      | (($m.stale_baks_count // 0) > 5) as $many_baks
      | ($m.probe_warnings // []) as $probe_warnings
      | {
          version:$version,
          ts:$ts,
          repo:$repo,
          status:(if ($low or $many_baks) then "fail" elif (($m.disk_free_pct // 0) < 15) then "warn" else "ok" end),
          tier:(if $fire then "FIRE" elif $low then "CRITICAL" elif (($m.disk_free_pct // 0) < 15) then "SOFT_PRUNE" else "OK" end),
          disk_total_gb:(($m.disk_total_gb // 0) | tonumber),
          disk_free_gb:(($m.disk_free_gb // 0) | tonumber),
          disk_free_pct:(($m.disk_free_pct // 0) | tonumber),
          developer_dir_gb:(($m.developer_dir_gb // 0) | tonumber),
          local_state_gb:(($m.local_state_gb // 0) | tonumber),
          stale_baks_count:(($m.stale_baks_count // 0) | floor),
          stale_baks_size_mb:(($m.stale_baks_size_mb // 0) | tonumber),
          qdrant_volumes_size_mb:(($m.qdrant_volumes_size_mb // 0) | tonumber),
          tmp_dispatch_artifacts_count:(($m.tmp_dispatch_artifacts_count // 0) | floor),
          thresholds:{min_free_pct:$min_free, fire_free_pct:$fire_free, stale_baks_count:5},
          history_path:$history,
          errors:(
            (if $low then [{code:"storage_low_headroom",message:"disk_free_pct below storage minimum",disk_free_pct:(($m.disk_free_pct // 0) | tonumber),threshold_pct:$min_free}] else [] end)
            + (if $many_baks then [{code:"storage_stale_baks_high",message:"stale .beads.bak directories above threshold",stale_baks_count:(($m.stale_baks_count // 0) | floor),threshold:5}] else [] end)
          ),
          warnings:$probe_warnings
        }
    ' <<<"$base"
}

record_history() {
  local row="$1" cutoff tmp
  mkdir -p "$(dirname "$HISTORY")" 2>/dev/null || true
  append_jsonl_best_effort "$HISTORY" "$row" "storage history"
  [ -s "$HISTORY" ] || return 0
  cutoff="$(date -u -v-90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || python3 - <<'PY'
import datetime
print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=90)).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
)"
  tmp="$(mktemp "${TMPDIR:-/tmp}/storage-history.XXXXXX")"
  jq -c --arg cutoff "$cutoff" 'select((.ts // "") >= $cutoff)' "$HISTORY" >"$tmp" 2>/dev/null || cp "$HISTORY" "$tmp"
  mv "$tmp" "$HISTORY"
}

notify_if_needed() {
  local row="$1" pct gb
  pct="$(jq -r '.disk_free_pct // 100' <<<"$row")"
  if awk -v pct="$pct" -v fire="$FIRE_FREE_PCT" 'BEGIN { exit !(pct < fire) }'; then
    gb="$(jq -r '.disk_free_gb // 0' <<<"$row")"
    if [ -x "$NOTIFY_BIN" ]; then
      "$NOTIFY_BIN" --priority 1 "STORAGE LOW" "disk_free_pct=${pct}% disk_free_gb=${gb}" >/dev/null 2>&1 || true
    fi
  fi
}

build_row() {
  local base
  if [ -n "$FIXTURE" ]; then
    base="$(fixture_json)"
  else
    base="$(live_json)"
  fi
  status_json "$base"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      capabilities|--capabilities) capabilities_json; exit 0 ;;
      robot-docs|robot-docs-guide) robot_docs; exit 0 ;;
      --help|-h) usage; exit 0 ;;
      --examples) examples; exit 0 ;;
      --schema) schema_json; exit 0 ;;
      --info) jq -nc --arg version "$VERSION" --arg history "$HISTORY" --arg repo "$REPO" '{version:$version,repo:$repo,history_path:$history,mutates:["optional history append","optional notify at fire threshold"]}'; exit 0 ;;
      --json|--doctor|--health) JSON_OUT=1; shift ;;
      --repo) [ $# -ge 2 ] || { printf 'ERROR: --repo requires PATH\n' >&2; exit 2; }; REPO="$2"; shift 2 ;;
      --disk-path) [ $# -ge 2 ] || { printf 'ERROR: --disk-path requires PATH\n' >&2; exit 2; }; DISK_PATH="$2"; shift 2 ;;
      --fixture) [ $# -ge 2 ] || { printf 'ERROR: --fixture requires PATH\n' >&2; exit 2; }; FIXTURE="$2"; shift 2 ;;
      --history) [ $# -ge 2 ] || { printf 'ERROR: --history requires PATH\n' >&2; exit 2; }; HISTORY="$2"; shift 2 ;;
      --record-history) RECORD_HISTORY=1; shift ;;
      --notify) NOTIFY_LOW=1; shift ;;
      --min-free-pct) [ $# -ge 2 ] || { printf 'ERROR: --min-free-pct requires N\n' >&2; exit 2; }; MIN_FREE_PCT="$2"; shift 2 ;;
      --fire-free-pct) [ $# -ge 2 ] || { printf 'ERROR: --fire-free-pct requires N\n' >&2; exit 2; }; FIRE_FREE_PCT="$2"; shift 2 ;;
      *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  return 0
}

main() {
  local row
  if ! have jq; then
    printf '{"status":"fail","errors":[{"code":"jq_missing"}]}\n'
    exit 1
  fi
  parse_args "$@"
  row="$(build_row)"
  [ "$RECORD_HISTORY" -eq 0 ] || record_history "$row"
  [ "$NOTIFY_LOW" -eq 0 ] || notify_if_needed "$row"
  printf '%s\n' "$row"
}

main "$@"
