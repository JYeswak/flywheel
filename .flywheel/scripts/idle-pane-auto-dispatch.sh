#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2317
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled (bead flywheel-1fk5f.4)
#
# Filled by flywheel-1fk5f.4: doctor probes the substrate this wrapper
# depends on (jq/ntm/surface_probe/audit_log_dir); health/audit/why bind
# to the run-history audit log written by cmd_run via cli_audit_append;
# validate enforces row schema; repair manages audit_log_dir +
# audit_log_truncate scopes.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="idle-pane-auto-dispatch/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/idle-pane-auto-dispatch-runs.jsonl}"
# Module-scope lift of cmd_run substrate paths so canonical-cli stubs
# resolve them before the original arg parser runs.
SCAFFOLD_NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SCAFFOLD_SURFACE_PROBE="${FLYWHEEL_SURFACE_PROBE:-$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/dispatch-surface-conflict-probe.sh}"

scaffold_usage() {
  cat <<'USG'
usage: idle-pane-auto-dispatch.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "idle-pane-auto-dispatch.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "idle-pane-auto-dispatch.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}' \
    | jq '. + {native_surface:[
        "ntm wait <session> --until=idle --any --json",
        "ntm assign <session> --repo <path> --dry-run --json",
        "ntm assign <session> --watch --auto --json"
      ]}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"idle-pane-auto-dispatch.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"idle-pane-auto-dispatch.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"idle-pane-auto-dispatch.sh doctor --json"}'
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
    audit-row|default)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",
          format:"jsonl",path:$log,
          required_fields:["ts","action","status","sha256"],
          optional_extra_fields:["session","repo","apply","watch","run_status"],
          run_status_enum:["assigned","assign_failed","no_idle_wait_timeout","wait_failed","refused_watch_dependency_open","refused_surface_conflict"],
          appended_by:"cmd_run via cli_audit_append at run_dispatch terminal"}' ;;
    run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"run",
          required_args:["--session"],
          optional_args:["--repo","--apply","--watch","--timeout","--limit","--ntm-bin"],
          mutation_default:"dry-run",
          native_surfaces:["ntm wait <session> --until=idle --any","ntm assign <session> --repo <path> --auto|--dry-run"],
          terminal_status_enum:["assigned","assign_failed","no_idle_wait_timeout","wait_failed","refused_watch_dependency_open","refused_surface_conflict"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,status:"unknown_surface",known_surfaces:["audit-row","run"]}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  # Single-printf bodies (gl7om SIGPIPE/pipefail discipline).
  case "$topic" in
    run)
      printf 'topic: run — `idle-pane-auto-dispatch.sh --session NAME [--repo PATH] [--dry-run|--apply] [--watch] [--json]` chains `ntm wait <session> --until=idle` then `ntm assign --repo <path> --dry-run|--auto`. Pre-flight surface-conflict probe (closes flywheel-x6h.1). Each invocation appends one row to %s. Default --dry-run; mutate via --apply.\n' "$SCAFFOLD_AUDIT_LOG"
      ;;
    doctor)
      printf 'topic: doctor — probes the substrate this wrapper depends on: jq, ntm binary (NTM_BIN override), surface-conflict probe script, audit log directory writability, repo_root resolution. Emits {checks:[{check,status:ok|fail|warn,detail}],status}.\n'
      ;;
    health)
      printf 'topic: health — summarizes the run-history audit log: total_rows, last_status, last_ts, assigned_count / refused_count / failed_count, freshness_seconds. status: ok | empty | not_initialized.\n'
      ;;
    repair)
      printf 'topic: repair — scopes: audit_log_dir (ensure log directory exists), audit_log_truncate (backup-then-truncate; requires --apply --idempotency-key), none (no-op probe). Default --dry-run.\n'
      ;;
    validate)
      printf 'topic: validate — subjects: audit-row (each row has ts, action, status, sha256; run-action rows have run_status in {assigned, assign_failed, no_idle_wait_timeout, wait_failed, refused_watch_dependency_open, refused_surface_conflict}).\n'
      ;;
    *) printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "idle-pane-auto-dispatch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "idle-pane-auto-dispatch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local checks_jsonl="" overall="ok"
  local emit_check
  emit_check() {
    local name="$1" status="$2" detail="$3"
    if [[ "$status" == "fail" ]]; then overall="fail"; fi
    jq -nc --arg c "$name" --arg s "$status" --arg d "$detail" '{check:$c,status:$s,detail:$d}'
  }

  # 1. jq
  if command -v jq >/dev/null 2>&1; then
    checks_jsonl+="$(emit_check jq ok "$(command -v jq)")"$'\n'
  else
    checks_jsonl+="$(emit_check jq fail "jq not on PATH")"$'\n'
  fi

  # 2. ntm binary
  if [[ -x "$SCAFFOLD_NTM_BIN" ]]; then
    checks_jsonl+="$(emit_check ntm ok "$SCAFFOLD_NTM_BIN")"$'\n'
  else
    checks_jsonl+="$(emit_check ntm fail "ntm not executable: $SCAFFOLD_NTM_BIN (override via NTM_BIN)")"$'\n'
  fi

  # 3. surface-conflict probe (used pre-flight by run_dispatch)
  if [[ -x "$SCAFFOLD_SURFACE_PROBE" ]]; then
    checks_jsonl+="$(emit_check surface_probe ok "$SCAFFOLD_SURFACE_PROBE")"$'\n'
  else
    checks_jsonl+="$(emit_check surface_probe warn "surface-conflict probe not executable: $SCAFFOLD_SURFACE_PROBE (pre-flight check will be skipped)")"$'\n'
  fi

  # 4. repo_root resolved
  if [[ -n "${_SCAFFOLD_REPO_ROOT:-}" && -d "${_SCAFFOLD_REPO_ROOT:-/nonexistent}" ]]; then
    checks_jsonl+="$(emit_check repo_root ok "$_SCAFFOLD_REPO_ROOT")"$'\n'
  else
    checks_jsonl+="$(emit_check repo_root fail "repo root not resolved or missing: ${_SCAFFOLD_REPO_ROOT:-<unset>}")"$'\n'
  fi

  # 5. audit log dir writable / absent-creatable
  local audit_dir
  audit_dir="$(dirname -- "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$audit_dir" && -w "$audit_dir" ]]; then
    checks_jsonl+="$(emit_check audit_log_dir ok "$audit_dir")"$'\n'
  elif [[ ! -e "$audit_dir" ]]; then
    checks_jsonl+="$(emit_check audit_log_dir warn "absent (created on first run): $audit_dir")"$'\n'
  else
    checks_jsonl+="$(emit_check audit_log_dir fail "exists but not writable: $audit_dir")"$'\n'
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks_jsonl" | jq -sc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts now_epoch
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  now_epoch="$(date -u +%s)"

  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"not_initialized",audit_log_path:$path,total_rows:0}'
    return 0
  fi

  local total_rows
  total_rows="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || printf '0')"
  total_rows="${total_rows:-0}"

  if [[ "$total_rows" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"empty",audit_log_path:$path,total_rows:0}'
    return 0
  fi

  local last_row last_ts last_status assigned_count refused_count failed_count last_epoch freshness_seconds
  last_row="$(tail -n1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || printf '')"
  last_ts="$(printf '%s' "$last_row" | jq -r '.ts // ""' 2>/dev/null || printf '')"
  last_status="$(printf '%s' "$last_row" | jq -r '.status // ""' 2>/dev/null || printf '')"
  assigned_count="$({ grep -c '"run_status":"assigned"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  refused_count="$({ grep -cE '"run_status":"refused_(watch_dependency_open|surface_conflict)"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  failed_count="$({ grep -cE '"run_status":"(assign_failed|wait_failed|no_idle_wait_timeout)"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  assigned_count="${assigned_count:-0}"
  refused_count="${refused_count:-0}"
  failed_count="${failed_count:-0}"

  if [[ -n "$last_ts" ]]; then
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_ts" '+%s' 2>/dev/null || date -u -d "$last_ts" '+%s' 2>/dev/null || printf '0')"
    if [[ "$last_epoch" -gt 0 ]]; then
      freshness_seconds=$((now_epoch - last_epoch))
    else
      freshness_seconds=-1
    fi
  else
    freshness_seconds=-1
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$ts" \
    --arg status "ok" \
    --arg path "$SCAFFOLD_AUDIT_LOG" \
    --argjson total_rows "$total_rows" \
    --argjson assigned_count "$assigned_count" \
    --argjson refused_count "$refused_count" \
    --argjson failed_count "$failed_count" \
    --arg last_status "$last_status" \
    --arg last_ts "$last_ts" \
    --argjson freshness_seconds "$freshness_seconds" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log_path:$path,
      total_rows:$total_rows,assigned_count:$assigned_count,refused_count:$refused_count,failed_count:$failed_count,
      last_status:$last_status,last_ts:$last_ts,freshness_seconds:$freshness_seconds}'
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

  local ts audit_dir
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  audit_dir="$(dirname -- "$SCAFFOLD_AUDIT_LOG")"

  case "$scope" in
    audit_log_dir)
      if [[ "$mode" == "dry_run" ]]; then
        local actions_jsonl=""
        if [[ ! -d "$audit_dir" ]]; then
          actions_jsonl+="$(jq -nc --arg p "$audit_dir" '{action:"mkdir_p",path:$p,reason:"audit log directory absent"}')"$'\n'
        fi
        if [[ -z "$actions_jsonl" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true}'
        else
          printf '%s' "$actions_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:.,idempotent_no_op:false}'
        fi
        return 0
      fi
      local applied_jsonl="" idempotent_no_op=true
      if [[ ! -d "$audit_dir" ]]; then
        if mkdir -p "$audit_dir" 2>/dev/null; then
          applied_jsonl+="$(jq -nc --arg p "$audit_dir" '{action:"mkdir_p",path:$p,result:"created"}')"$'\n'
          idempotent_no_op=false
        else
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg dir "$audit_dir" --arg idem "$idem_key" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"failed",mode:"apply",scope:$scope,idempotency_key:$idem,error:"mkdir_p failed",path:$dir}'
          return 1
        fi
      fi
      if [[ -z "$applied_jsonl" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true}'
      else
        printf '%s' "$applied_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" --argjson noop "$idempotent_no_op" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:.,idempotent_no_op:$noop}'
      fi
      ;;
    audit_log_truncate)
      if [[ "$mode" == "dry_run" ]]; then
        local planned_jsonl=""
        if [[ -e "$SCAFFOLD_AUDIT_LOG" ]]; then
          local row_count
          row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || printf '0')"
          row_count="${row_count:-0}"
          planned_jsonl+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" --argjson rc "$row_count" \
            '{action:"backup_then_truncate",path:$p,row_count_before:$rc,backup_path_pattern:"<path>.bak.<ts>"}')"$'\n'
        fi
        if [[ -z "$planned_jsonl" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true,note:"audit log absent — nothing to truncate"}'
        else
          printf '%s' "$planned_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:.,idempotent_no_op:false}'
        fi
        return 0
      fi
      if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true,note:"audit log absent"}'
        return 0
      fi
      local backup_ts backup_path
      backup_ts="$(date -u +%Y%m%dT%H%M%SZ)"
      backup_path="${SCAFFOLD_AUDIT_LOG}.bak.${backup_ts}"
      if cp -p "$SCAFFOLD_AUDIT_LOG" "$backup_path" 2>/dev/null && : >"$SCAFFOLD_AUDIT_LOG" 2>/dev/null; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" --arg bp "$backup_path" --arg p "$SCAFFOLD_AUDIT_LOG" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,
            applied_actions:[{action:"backup",backup_path:$bp,result:"created"},{action:"truncate",path:$p,result:"emptied"}],
            idempotent_no_op:false}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"failed",mode:"apply",scope:$scope,idempotency_key:$idem,error:"backup_or_truncate_failed"}'
        return 1
      fi
      ;;
    none)
      if [[ "$mode" == "dry_run" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg idem "$idem_key" \
          '{schema_version:$sv,command:"repair",ts:$ts,status:"applied",mode:"apply",scope:$scope,idempotency_key:$idem,applied_actions:[],idempotent_no_op:true,note:"no-op scope"}'
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,reason:"--scope <audit_log_dir|audit_log_truncate|none> required"}'
      return 64
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",known_scopes:["audit_log_dir","audit_log_truncate","none"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --*) shift ;;
      *) if [[ -z "$subject" ]]; then subject="$1"; fi; shift ;;
    esac
  done
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  case "$subject" in
    audit-row|"")
      subject="audit-row"
      if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg path "$SCAFFOLD_AUDIT_LOG" \
          '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,audit_log_path:$path,status:"empty",results:[],pass:0,fail:0}'
        return 0
      fi
      local lineno=0 pass=0 fail=0 results_jsonl="" row_pass row_offending line
      while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        [[ -z "$line" ]] && continue
        row_pass=true
        row_offending="none"
        if printf '%s' "$line" | jq -e '
          (has("ts") and (.ts | type == "string") and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")))
          and (has("action") and (.action | type == "string"))
          and (has("status") and (.status | type == "string"))
          and (has("sha256") and (.sha256 | type == "string"))
        ' >/dev/null 2>&1; then
          # run-action rows must have run_status in the enum.
          if ! printf '%s' "$line" | jq -e 'if .action == "run" then (.run_status | IN("assigned","assign_failed","no_idle_wait_timeout","wait_failed","refused_watch_dependency_open","refused_surface_conflict")) else true end' >/dev/null 2>&1; then
            row_pass=false
            row_offending="run_action_run_status_not_in_enum"
          fi
        else
          row_pass=false
          row_offending="missing_or_malformed_required_field"
        fi
        if $row_pass; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
        results_jsonl+="$(jq -nc --argjson lineno "$lineno" --arg pass "$row_pass" --arg offending "$row_offending" \
          '{lineno:$lineno,pass:($pass=="true"),offending_field:$offending}')"$'\n'
      done <"$SCAFFOLD_AUDIT_LOG"

      local status="ok"
      if [[ "$fail" -gt 0 ]]; then status="fail"; fi
      printf '%s' "$results_jsonl" | jq -sc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" --arg path "$SCAFFOLD_AUDIT_LOG" \
        --arg status "$status" --argjson pass "$pass" --argjson fail "$fail" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,audit_log_path:$path,status:$status,pass:$pass,fail:$fail,results:.}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg subject "$subject" \
        '{schema_version:$sv,command:"validate",ts:$ts,subject:$subject,status:"unknown_subject",known_subjects:["audit-row"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_audit() {
  local tail_n=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail) tail_n="${2:-20}"; shift 2 ;;
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit 2>/dev/null || printf 'topic: audit — tail run history\n'; return 0 ;;
      *) shift ;;
    esac
  done

  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"not_initialized",tail_n:$tail_n,rows:[]}'
    return 0
  fi
  local rows_jsonl
  rows_jsonl="$(tail -n "$tail_n" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || printf '')"
  if [[ -z "$rows_jsonl" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"empty",tail_n:$tail_n,rows:[]}'
  else
    printf '%s\n' "$rows_jsonl" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",ts:$ts,audit_log:$log,status:"ok",tail_n:$tail_n,row_count:length,rows:.}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument (audit row ts, run_status string, or 1-based row index)\n' >&2
    return 64
  fi
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",audit_log_path:$log,reason:"audit log absent (no runs recorded yet)"}'
    return 0
  fi

  # Resolution order: numeric row index → ts exact → run_status exact (returns first match).
  local row="" resolution=""
  if [[ "$id" =~ ^[0-9]+$ ]]; then
    row="$(sed -n "${id}p" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    [[ -n "$row" ]] && resolution="row_index"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select(.ts == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="ts_exact"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select(.run_status == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="run_status_first_match"
  fi

  if [[ -n "$row" ]]; then
    printf '%s' "$row" | jq -c \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --arg resolution "$resolution" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log_path:$log,resolution:$resolution,row:.,
        provenance:{action:.action,run_status:(.run_status // null),session:(.session // null),repo:(.repo // null)}}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log_path:$log,reason:"no audit row matched by row-index, ts, or run_status"}'
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
VERSION="idle-pane-auto-dispatch/v3"
SURFACE_PROBE="${FLYWHEEL_SURFACE_PROBE:-/Users/josh/Developer/flywheel/.flywheel/scripts/dispatch-surface-conflict-probe.sh}"
SURFACE_LOOKBACK_MIN="${FLYWHEEL_SURFACE_LOOKBACK_MIN:-30}"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="flywheel"
REPO=""
JSON_OUT=0
APPLY=0
DRY_RUN=1
WATCH=0
WAIT_TIMEOUT="${FLYWHEEL_IDLE_WAIT_TIMEOUT:-1s}"
WATCH_INTERVAL="${FLYWHEEL_IDLE_WATCH_INTERVAL:-30s}"
LIMIT="${FLYWHEEL_IDLE_ASSIGN_LIMIT:-1}"
NTM_124_STATUS="${FLYWHEEL_NTM_124_STATUS:-closed}"

usage() {
  cat <<'USAGE'
Usage:
  idle-pane-auto-dispatch.sh --session NAME [--repo PATH] [--dry-run|--apply] [--watch] [--json]
  idle-pane-auto-dispatch.sh --info [--json]
  idle-pane-auto-dispatch.sh --examples [--json]
  idle-pane-auto-dispatch.sh --schema [--json]
  idle-pane-auto-dispatch.sh --help

Thin wrapper around native NTM:
  1. ntm wait <session> --until=idle --any --timeout=<duration> --json
  2. ntm assign <session> --repo <path> --dry-run|--auto [--watch] --json

Default is dry-run. --apply mutates only through ntm assign.
USAGE
}

session_repo() {
  case "$1" in
    flywheel) printf '%s\n' "/Users/josh/Developer/flywheel" ;;
    alpsinsurance|alps) printf '%s\n' "/Users/josh/Developer/alpsinsurance" ;;
    skillos) printf '%s\n' "/Users/josh/Developer/skillos" ;;
    mobile-eats) printf '%s\n' "/Users/josh/Developer/mobile-eats" ;;
    vrtx) printf '%s\n' "/Users/josh/Developer/vrtx" ;;
    *) printf '%s\n' "" ;;
  esac
}

json_bool() {
  if [[ "$1" -eq 1 ]]; then printf 'true'; else printf 'false'; fi
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" --arg ntm "$NTM_BIN" '{
      schema_version:$version,
      command:"idle-pane-auto-dispatch.sh",
      mutation_default:"dry-run",
      native_surface:["ntm wait <session> --until=idle --any --json","ntm assign <session> --repo <path> --dry-run|--auto --json","ntm assign <session> --watch --auto --json"],
      ntm:$ntm,
      canonical_flags:["--help","--info","--examples","--schema","--dry-run","--apply","--watch","--json","--session","--repo","--timeout","--limit"],
      dependency_status:{ntm_124:"closed"},
      blocked_native_dependency:null
    }'
  else
    printf '%s\n' "$VERSION"
    printf 'mutation_default=dry-run\n'
    printf 'native_surface=ntm wait + ntm assign\n'
  fi
}

emit_examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{
      examples:[
        "idle-pane-auto-dispatch.sh --session flywheel --dry-run --json",
        "idle-pane-auto-dispatch.sh --session flywheel --apply --json",
        "idle-pane-auto-dispatch.sh --session flywheel --apply --watch --json"
      ]
    }'
  else
    printf '%s\n' \
      "idle-pane-auto-dispatch.sh --session flywheel --dry-run --json" \
      "idle-pane-auto-dispatch.sh --session flywheel --apply --json" \
      "idle-pane-auto-dispatch.sh --session flywheel --apply --watch --json"
  fi
}

emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"idle-pane-auto-dispatch result",
    type:"object",
    required:["schema_version","session","repo","dry_run","apply","watch","status","wait","assign","blocked_native_dependency"],
    properties:{
      schema_version:{const:$version},
      session:{type:"string"},
      repo:{type:"string"},
      dry_run:{type:"boolean"},
      apply:{type:"boolean"},
      watch:{type:"boolean"},
      status:{type:"string"},
      wait:{type:"object"},
      assign:{type:["object","null"]},
      blocked_native_dependency:{type:["object","null"]}
    }
  }'
}

json_payload() {
  local status="$1" wait_json="$2" assign_json="$3" blocked_json="$4"
  jq -nc \
    --arg schema_version "$VERSION" \
    --arg session "$SESSION" \
    --arg repo "$REPO" \
    --arg status "$status" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson watch "$(json_bool "$WATCH")" \
    --argjson wait "$wait_json" \
    --argjson assign "$assign_json" \
    --argjson blocked "$blocked_json" \
    '{
      schema_version:$schema_version,
      session:$session,
      repo:$repo,
      dry_run:$dry_run,
      apply:$apply,
      watch:$watch,
      status:$status,
      wait:$wait,
      assign:$assign,
      blocked_native_dependency:$blocked
    }'
}

probe_capture_live_panes() {
  # Per L153 CAPTURE-PROVENANCE-CANONICAL: dispatch only to panes whose ntm
  # --robot-activity capture meets BOTH preconditions:
  #   capture_provenance=="live" AND state=="WAITING"
  # Closes parent flywheel-ef8m AG2; producers documented in
  # .flywheel/rules/L104-L153-capture-provenance-canonical.md.
  local activity_json rc=0
  activity_json="$("$NTM_BIN" --robot-activity="$SESSION" --json 2>/dev/null)" || rc=$?
  if [[ "$rc" -ne 0 ]] || ! jq -e . >/dev/null 2>&1 <<<"$activity_json"; then
    # Activity probe unavailable — emit empty array; caller treats as
    # no_capture_live_panes per L153 disposition (unavailable → infrastructure
    # problem; route to flywheel-respawn or flywheel-recovery).
    printf '[]\n'
    return 0
  fi
  # Canonical filter (literal strings preserved for tests/pane-capture-provenance.sh
  # rg checks): capture_provenance=="live" AND state=="WAITING".
  jq -c '[.agents[] | select(.state=="WAITING" and .capture_provenance=="live") | .pane_idx]' <<<"$activity_json"
}

run_wait() {
  local output rc=0
  output="$("$NTM_BIN" wait "$SESSION" --until=idle --any --timeout="$WAIT_TIMEOUT" --json 2>&1)" || rc=$?
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c --argjson rc "$rc" '. + {exit_code:$rc, native_command:"ntm wait <session> --until=idle --any --timeout --json"}' <<<"$output"
  else
    jq -nc --arg output "$output" --argjson rc "$rc" '{exit_code:$rc,native_command:"ntm wait <session> --until=idle --any --timeout --json",raw:$output}'
  fi
  return "$rc"
}

run_assign() {
  local output rc=0
  local -a cmd=("$NTM_BIN" assign "$SESSION" --repo "$REPO" --json --limit="$LIMIT")
  if [[ "$WATCH" -eq 1 ]]; then
    cmd+=(--watch --stop-when-done --watch-interval="$WATCH_INTERVAL")
  fi
  if [[ "$APPLY" -eq 1 ]]; then
    cmd+=(--auto)
  else
    cmd+=(--dry-run)
  fi

  output="$("${cmd[@]}" 2>&1)" || rc=$?
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c --argjson rc "$rc" --arg command "${cmd[*]}" '. + {exit_code:$rc,native_command:$command}' <<<"$output"
  else
    jq -nc --arg output "$output" --argjson rc "$rc" --arg command "${cmd[*]}" '{exit_code:$rc,native_command:$command,raw:$output}'
  fi
  return "$rc"
}

run_dispatch() {
  local wait_json wait_rc assign_json assign_rc blocked
  REPO="${REPO:-$(session_repo "$SESSION")}"
  [[ -n "$REPO" ]] || { printf 'ERR: unknown session repo for %s; pass --repo\n' "$SESSION" >&2; exit 64; }

  if [[ "$WATCH" -eq 1 && "$NTM_124_STATUS" != "closed" ]]; then
    blocked="$(jq -nc --arg status "$NTM_124_STATUS" '{issue:"ntm#124",status:$status,reason:"refusing watch mode until native assign watch is verified closed"}')"
    json_payload "refused_watch_dependency_open" '{}' 'null' "$blocked"
    return 0
  fi

  set +e
  wait_json="$(run_wait)"
  wait_rc=$?
  set -e
  if [[ "$wait_rc" -eq 1 ]]; then
    json_payload "no_idle_wait_timeout" "$wait_json" 'null' 'null'
    return 0
  elif [[ "$wait_rc" -ne 0 ]]; then
    json_payload "wait_failed" "$wait_json" 'null' 'null'
    return 0
  fi

  # L153 CAPTURE-PROVENANCE gate: refuse to dispatch unless at least one pane's
  # capture_provenance=="live" AND state=="WAITING" (per AGENTS.md L153 +
  # .flywheel/rules/L104-L153-capture-provenance-canonical.md). When the filter
  # rejects all panes, surface as no_capture_live_panes rather than dispatching
  # anyway. Closes parent flywheel-ef8m AG2 + bead flywheel-zmeir.
  local live_panes_json
  live_panes_json="$(probe_capture_live_panes)"
  if [[ "$(jq -r 'length' <<<"$live_panes_json" 2>/dev/null)" == "0" ]]; then
    local gate_json
    gate_json="$(jq -nc \
      --argjson panes "$live_panes_json" \
      '{reason:"no_capture_live_panes",
        gate:"L153_CAPTURE_PROVENANCE_CANONICAL",
        filter:"capture_provenance==\"live\" AND state==\"WAITING\"",
        live_pane_count:0,
        live_panes:$panes,
        disposition:"unavailable provenance routes to flywheel-respawn or flywheel-recovery before classifying worker"}')"
    json_payload "no_capture_live_panes" "$wait_json" 'null' "$gate_json"
    return 0
  fi

  # Surface-conflict pre-flight: dry-run assign first to peek at the candidate
  # bead's task_file, then probe for write-surface conflicts against in-flight
  # dispatches. If conflict, refuse to flip to --auto. (Closes flywheel-x6h.1.)
  local preview_json preview_rc dry_assign_rc
  if [[ "$APPLY" -eq 1 && -x "$SURFACE_PROBE" ]]; then
    set +e
    local apply_save="$APPLY"
    APPLY=0; DRY_RUN=1
    preview_json="$(run_assign)"
    preview_rc=$?
    APPLY="$apply_save"; DRY_RUN=$(( apply_save == 1 ? 0 : 1 ))
    set -e
    if [[ "$preview_rc" -eq 0 ]]; then
      local candidate_task_file
      candidate_task_file="$(jq -r '
        (.assignments // .planned_assignments // .preview // [])
        | map(.task_file // .dispatch_packet // .packet_path // empty)
        | first // empty' <<<"$preview_json" 2>/dev/null)"
      if [[ -n "$candidate_task_file" && -f "$candidate_task_file" ]]; then
        local probe_json probe_rc
        set +e
        probe_json="$("$SURFACE_PROBE" \
          --candidate-task-file "$candidate_task_file" \
          --lookback-minutes "$SURFACE_LOOKBACK_MIN" \
          --json 2>/dev/null)"
        probe_rc=$?
        set -e
        if [[ "$probe_rc" -eq 1 ]]; then
          local refused_json
          refused_json="$(jq -nc \
            --argjson probe "$probe_json" \
            '{reason:"surface_conflict_with_in_flight_dispatch", surface_probe:$probe}')"
          json_payload "refused_surface_conflict" "$wait_json" "$preview_json" "$refused_json"
          return 0
        fi
      fi
    fi
  fi

  set +e
  assign_json="$(run_assign)"
  assign_rc=$?
  set -e
  if [[ "$assign_rc" -eq 0 ]]; then
    json_payload "assigned" "$wait_json" "$assign_json" 'null'
  else
    json_payload "assign_failed" "$wait_json" "$assign_json" 'null'
  fi
}

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?--session requires NAME}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --repo) REPO="${2:?--repo requires PATH}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --ntm-bin) NTM_BIN="${2:?--ntm-bin requires PATH}"; shift 2 ;;
    --ntm-bin=*) NTM_BIN="${1#*=}"; shift ;;
    --timeout) WAIT_TIMEOUT="${2:?--timeout requires duration}"; shift 2 ;;
    --timeout=*) WAIT_TIMEOUT="${1#*=}"; shift ;;
    --limit) LIMIT="${2:?--limit requires N}"; shift 2 ;;
    --limit=*) LIMIT="${1#*=}"; shift ;;
    --watch-interval) WATCH_INTERVAL="${2:?--watch-interval requires duration}"; shift 2 ;;
    --watch-interval=*) WATCH_INTERVAL="${1#*=}"; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --watch) WATCH=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

# flywheel-1fk5f.4: capture run_dispatch JSON envelope, append to audit
# log via cli_audit_append, then re-emit on stdout. Preserves backward-
# compatible cmd_run output + exit code while binding health/audit/why
# surfaces to real run history.
set +e
__run_payload="$(run_dispatch)"
__run_rc=$?
set -e
if command -v cli_audit_append >/dev/null 2>&1 && [[ -n "$__run_payload" ]]; then
  __run_status="$(printf '%s' "$__run_payload" | jq -r '.status // "unknown"' 2>/dev/null || printf 'unknown')"
  # run_dispatch ran in a subshell; pull resolved repo from the payload
  # rather than from $REPO (which is still the pre-resolution value).
  __resolved_repo="$(printf '%s' "$__run_payload" | jq -r '.repo // ""' 2>/dev/null || printf '')"
  __extra_json="$(jq -nc \
    --arg session "$SESSION" \
    --arg repo "$__resolved_repo" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson watch "$(json_bool "$WATCH")" \
    --arg run_status "$__run_status" \
    '{session:$session,repo:$repo,apply:$apply,watch:$watch,run_status:$run_status}' 2>/dev/null || printf '{}')"
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "run" "$__run_status" "$__extra_json"
fi
[[ -n "$__run_payload" ]] && printf '%s\n' "$__run_payload"
exit "$__run_rc"
