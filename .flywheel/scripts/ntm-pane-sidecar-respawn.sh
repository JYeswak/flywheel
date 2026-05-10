#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled (bead flywheel-1fk5f.8)
#
# Filled by flywheel-1fk5f.8: doctor probes the substrate (jq/ntm/audit
# log dir); health/audit/why bind to the run-history audit log written
# by cmd_run via cli_audit_append; validate enforces row schema; repair
# manages audit_log_dir + audit_log_truncate scopes.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="ntm-pane-sidecar-respawn/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-pane-sidecar-respawn-runs.jsonl}"
# Module-scope lift so canonical-cli stubs resolve cmd_run substrate.
SCAFFOLD_NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-pane-sidecar-respawn.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-pane-sidecar-respawn.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-pane-sidecar-respawn.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-pane-sidecar-respawn.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-pane-sidecar-respawn.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-pane-sidecar-respawn.sh doctor --json"}'
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
          optional_extra_fields:["session","pane","cwd","apply","rollback","run_status"],
          run_status_enum:["dry_run","planned","applied","apply_failed","usage_error"],
          appended_by:"cmd_run via cli_audit_append after emit_plan or run_apply"}' ;;
    run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"run",
          required_args:["--session","--pane"],
          optional_args:["--command-path","--command-arg","--cwd","--env","--config-override","--rollback","--apply"],
          mutation_default:"dry-run",
          native_surfaces:["ntm respawn <session> --panes=<n> --force --json","ntm send <session> --pane=<n> <cmd> --json","ntm health <session> --pane <n> --json"],
          terminal_status_enum:["dry_run","planned","applied","apply_failed"]}' ;;
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
      printf 'topic: run — `ntm-pane-sidecar-respawn.sh --session NAME --pane N --command-path PATH [--apply] [--json]` respawns exactly one pane via `ntm respawn` then sends the launch command via `ntm send` and probes via `ntm health`. --rollback skips the send and returns the pane to the recorded command. Default --dry-run; mutate via --apply. Each invocation appends one row to %s.\n' "$SCAFFOLD_AUDIT_LOG"
      ;;
    doctor)
      printf 'topic: doctor — probes the substrate this respawn wrapper depends on: jq, ntm binary executable, audit log directory writability, repo_root resolution. Emits {checks:[{check,status:ok|fail|warn,detail}],status}.\n'
      ;;
    health)
      printf 'topic: health — summarizes the run-history audit log: total_rows, applied_count, apply_failed_count, dry_run_count, last_status, last_ts, freshness_seconds. status: ok | empty | not_initialized.\n'
      ;;
    repair)
      printf 'topic: repair — scopes: audit_log_dir (ensure log directory exists), audit_log_truncate (backup-then-truncate; requires --apply --idempotency-key), none (no-op probe). Default --dry-run.\n'
      ;;
    validate)
      printf 'topic: validate — subjects: audit-row (each row has ts, action, status, sha256; respawn-action rows have run_status in {dry_run, planned, applied, apply_failed}).\n'
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
            && cli_emit_completion_bash "ntm-pane-sidecar-respawn" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-pane-sidecar-respawn" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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

  # 2. ntm binary executable
  if [[ -x "$SCAFFOLD_NTM_BIN" ]]; then
    checks_jsonl+="$(emit_check ntm ok "$SCAFFOLD_NTM_BIN")"$'\n'
  else
    checks_jsonl+="$(emit_check ntm fail "ntm not executable: $SCAFFOLD_NTM_BIN (override via NTM_BIN)")"$'\n'
  fi

  # 3. ntm respawn / send / health subcommands present
  local ntm_help
  if [[ -x "$SCAFFOLD_NTM_BIN" ]]; then
    ntm_help="$("$SCAFFOLD_NTM_BIN" --help 2>&1 || true)"
    if printf '%s' "$ntm_help" | grep -qE 'respawn'; then
      checks_jsonl+="$(emit_check ntm_subcommands ok "respawn/send/health subcommands available")"$'\n'
    else
      checks_jsonl+="$(emit_check ntm_subcommands warn "could not confirm respawn subcommand from --help output")"$'\n'
    fi
  else
    checks_jsonl+="$(emit_check ntm_subcommands fail "ntm not executable; cannot probe subcommands")"$'\n'
  fi

  # 4. repo_root resolved
  if [[ -n "${_SCAFFOLD_REPO_ROOT:-}" && -d "${_SCAFFOLD_REPO_ROOT:-/nonexistent}" ]]; then
    checks_jsonl+="$(emit_check repo_root ok "$_SCAFFOLD_REPO_ROOT")"$'\n'
  else
    checks_jsonl+="$(emit_check repo_root fail "repo root not resolved: ${_SCAFFOLD_REPO_ROOT:-<unset>}")"$'\n'
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

  local last_row last_ts last_status applied_count apply_failed_count dry_run_count last_epoch freshness_seconds
  last_row="$(tail -n1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || printf '')"
  last_ts="$(printf '%s' "$last_row" | jq -r '.ts // ""' 2>/dev/null || printf '')"
  last_status="$(printf '%s' "$last_row" | jq -r '.status // ""' 2>/dev/null || printf '')"
  applied_count="$({ grep -c '"run_status":"applied"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  apply_failed_count="$({ grep -c '"run_status":"apply_failed"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  dry_run_count="$({ grep -c '"run_status":"dry_run"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  applied_count="${applied_count:-0}"
  apply_failed_count="${apply_failed_count:-0}"
  dry_run_count="${dry_run_count:-0}"

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
    --argjson applied_count "$applied_count" \
    --argjson apply_failed_count "$apply_failed_count" \
    --argjson dry_run_count "$dry_run_count" \
    --arg last_status "$last_status" \
    --arg last_ts "$last_ts" \
    --argjson freshness_seconds "$freshness_seconds" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log_path:$path,
      total_rows:$total_rows,applied_count:$applied_count,apply_failed_count:$apply_failed_count,
      dry_run_count:$dry_run_count,last_status:$last_status,last_ts:$last_ts,
      freshness_seconds:$freshness_seconds}'
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
            '{schema_version:$sv,command:"repair",ts:$ts,status:"dry_run",mode:"dry_run",scope:$scope,planned_actions:[],idempotent_no_op:true,note:"audit log absent"}'
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
          # respawn-action rows must have run_status in the enum.
          if ! printf '%s' "$line" | jq -e 'if .action == "respawn" then (.run_status | IN("dry_run","planned","applied","apply_failed")) else true end' >/dev/null 2>&1; then
            row_pass=false
            row_offending="respawn_action_run_status_not_in_enum"
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
    printf 'ERR: why requires <id> argument (audit row ts, session:pane "name:N", or 1-based row index)\n' >&2
    return 64
  fi
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",audit_log_path:$log,reason:"audit log absent (no respawns recorded yet)"}'
    return 0
  fi

  # Resolution order: numeric row index → ts exact → session:pane match.
  local row="" resolution=""
  if [[ "$id" =~ ^[0-9]+$ ]]; then
    row="$(sed -n "${id}p" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    [[ -n "$row" ]] && resolution="row_index"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select(.ts == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="ts_exact"
  fi
  if [[ -z "$row" && "$id" == *:* ]]; then
    local sess pane
    sess="${id%%:*}"
    pane="${id##*:}"
    row="$(jq -c --arg s "$sess" --argjson p "$pane" 'select(.session == $s and .pane == $p)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="session_pane_first_match"
  fi

  if [[ -n "$row" ]]; then
    printf '%s' "$row" | jq -c \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --arg resolution "$resolution" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log_path:$log,resolution:$resolution,row:.,
        provenance:{action:.action,run_status:(.run_status // null),session:(.session // null),pane:(.pane // null),rollback:(.rollback // null)}}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log_path:$log,reason:"no audit row matched by row-index, ts, or session:pane"}'
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
VERSION="ntm-pane-sidecar-respawn/v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION=""
PANE=""
CWD=""
COMMAND_PATH=""
RAW_COMMAND=""
JSON=0
APPLY=0
ROLLBACK=0
ENV_OVERRIDES='[]'
CONFIG_OVERRIDES='[]'
COMMAND_ARGS='[]'

usage() {
  cat <<'USAGE'
Usage:
  ntm-pane-sidecar-respawn.sh --session NAME --pane N --command-path PATH [--command-arg ARG ...] [--cwd PATH] [--env KEY=VALUE ...] [--config-override KEY=VALUE ...] [--dry-run|--apply] [--json]
  ntm-pane-sidecar-respawn.sh --session NAME --pane N --rollback [--dry-run|--apply] [--json]
  ntm-pane-sidecar-respawn.sh health|doctor|validate|audit|why|schema|examples|--info

Default mode is dry-run. Apply restarts exactly one pane through ntm respawn.
Rollback uses only the recorded-command ntm respawn path for that pane.
USAGE
}

fail() {
  local reason="$1" code="${2:-2}"
  if [[ "$JSON" -eq 1 ]]; then
    jq -nc --arg schema "$VERSION" --arg reason "$reason" \
      '{schema_version:$schema,status:"usage_error",success:false,reason:$reason}'
  else
    printf 'usage_error: %s\n' "$reason" >&2
  fi
  exit "$code"
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing dependency: $1" 2
}

shell_quote() {
  local quoted
  printf -v quoted '%q' "$1"
  printf '%s' "$quoted"
}

json_append_string() {
  local json="$1" value="$2"
  jq -c --arg value "$value" '. + [$value]' <<<"$json"
}

json_append_env() {
  local json="$1" pair="$2" name value
  [[ "$pair" == *=* ]] || fail "--env requires KEY=VALUE"
  name="${pair%%=*}"
  value="${pair#*=}"
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid env name: $name"
  jq -c --arg name "$name" --argjson length "${#value}" \
    '. + [{name:$name,value_redacted:"<redacted>",value_length:$length}]' <<<"$json"
}

json_or_raw() {
  local tmp err rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/ntm-pane-sidecar.XXXXXX")"
  err="$tmp.err"
  set +e
  "$@" >"$tmp" 2>"$err"
  rc=$?
  set -e
  if jq -e . "$tmp" >/dev/null 2>&1; then
    jq -c --argjson rc "$rc" '{exit_code:$rc,payload:.}' "$tmp"
  else
    jq -nc --argjson rc "$rc" --rawfile stdout "$tmp" --rawfile stderr "$err" \
      '{exit_code:$rc,stdout:$stdout,stderr:$stderr}'
  fi
  rm -f "$tmp" "$err"
}

join_parts() {
  local out="" part
  for part in "$@"; do
    if [[ -z "$out" ]]; then
      out="$part"
    else
      out+=" && $part"
    fi
  done
  printf '%s' "$out"
}

build_launch_command() {
  local redact_env="${1:-0}" parts=() arg_count config_count i value key cmd
  if [[ -n "$RAW_COMMAND" ]]; then
    cmd="$RAW_COMMAND"
  else
    [[ -n "$COMMAND_PATH" ]] || fail "--command-path is required unless --rollback is set"
    cmd="$(shell_quote "$COMMAND_PATH")"
    arg_count="$(jq 'length' <<<"$COMMAND_ARGS")"
    for ((i = 0; i < arg_count; i++)); do
      value="$(jq -r ".[$i]" <<<"$COMMAND_ARGS")"
      cmd+=" $(shell_quote "$value")"
    done
    config_count="$(jq 'length' <<<"$CONFIG_OVERRIDES")"
    for ((i = 0; i < config_count; i++)); do
      value="$(jq -r ".[$i]" <<<"$CONFIG_OVERRIDES")"
      cmd+=" -c $(shell_quote "$value")"
    done
  fi

  if [[ -n "$CWD" ]]; then
    parts+=("cd $(shell_quote "$CWD")")
  fi
  local env_count
  env_count="$(jq 'length' <<<"$ENV_OVERRIDES")"
  for ((i = 0; i < env_count; i++)); do
    key="$(jq -r ".[$i].name" <<<"$ENV_OVERRIDES")"
    value="${ENV_VALUES[$key]}"
    if [[ "$redact_env" -eq 1 ]]; then
      value="<redacted>"
    fi
    parts+=("export $key=$(shell_quote "$value")")
  done
  parts+=("exec $cmd")
  join_parts "${parts[@]}"
}

emit_plan() {
  local dry_run="$1" launch_command="$2"
  local apply_bool rollback_bool
  apply_bool="$([[ "$APPLY" -eq 1 ]] && printf true || printf false)"
  rollback_bool="$([[ "$ROLLBACK" -eq 1 ]] && printf true || printf false)"
  jq -nc \
    --arg schema "$VERSION" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg cwd "$CWD" \
    --arg command_path "$COMMAND_PATH" \
    --arg launch_command_redacted "$launch_command" \
    --argjson env_overrides "$ENV_OVERRIDES" \
    --argjson config_overrides "$CONFIG_OVERRIDES" \
    --argjson command_args "$COMMAND_ARGS" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_bool" \
    --argjson rollback "$rollback_bool" \
    '{
      schema_version:$schema,
      success:true,
      status:(if $dry_run then "dry_run" else "planned" end),
      dry_run:$dry_run,
      apply:$apply,
      rollback:$rollback,
      rollback_returns_to_recorded_command:$rollback,
      respawn_only_target_pane:true,
      target:{session:$session,pane:$pane},
      cwd:$cwd,
      command:{path:$command_path,args:$command_args},
      env_overrides:$env_overrides,
      config_overrides:$config_overrides,
      launch_command_redacted:$launch_command_redacted,
      planned_actions:[
        ("ntm respawn " + $session + " --panes=" + ($pane|tostring) + " --force --json"),
        (if $rollback then "recorded-command rollback: no sidecar send" else "ntm send " + $session + " --pane=" + ($pane|tostring) + " <sidecar launch command>" end),
        ("ntm health " + $session + " --pane " + ($pane|tostring) + " --json"),
        "ntm version --json"
      ]
    }'
}

run_apply() {
  local launch_command="$1" launch_command_redacted="$2" respawn send send_rc health version
  local rollback_bool
  rollback_bool="$([[ "$ROLLBACK" -eq 1 ]] && printf true || printf false)"
  respawn="$(json_or_raw "$NTM_BIN" respawn "$SESSION" "--panes=$PANE" --force --json)"
  if [[ "$ROLLBACK" -eq 0 ]]; then
    set +e
    send="$(printf 'y\n' | "$NTM_BIN" send "$SESSION" "--pane=$PANE" "$launch_command" --json 2>&1)"
    send_rc=$?
    set -e
  else
    send='recorded-command rollback: sidecar send skipped'
    send_rc=0
  fi
  health="$(json_or_raw "$NTM_BIN" health "$SESSION" --pane "$PANE" --json)"
  version="$(json_or_raw "$NTM_BIN" version --json)"
  jq -nc \
    --arg schema "$VERSION" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg cwd "$CWD" \
    --arg command_path "$COMMAND_PATH" \
    --arg launch_command_redacted "$launch_command_redacted" \
    --arg send_output "$send" \
    --argjson send_rc "$send_rc" \
    --argjson env_overrides "$ENV_OVERRIDES" \
    --argjson config_overrides "$CONFIG_OVERRIDES" \
    --argjson command_args "$COMMAND_ARGS" \
    --argjson rollback "$rollback_bool" \
    --argjson respawn "$respawn" \
    --argjson health "$health" \
    --argjson version "$version" \
    '{
      schema_version:$schema,
      success:($respawn.exit_code == 0 and $send_rc == 0 and $health.exit_code == 0),
      status:(if ($respawn.exit_code == 0 and $send_rc == 0 and $health.exit_code == 0) then "applied" else "apply_failed" end),
      dry_run:false,
      apply:true,
      rollback:$rollback,
      rollback_returns_to_recorded_command:$rollback,
      respawn_only_target_pane:true,
      target:{session:$session,pane:$pane},
      cwd:$cwd,
      command:{path:$command_path,args:$command_args},
      env_overrides:$env_overrides,
      config_overrides:$config_overrides,
      launch_command_redacted:$launch_command_redacted,
      respawn_evidence:$respawn,
      sidecar_send_evidence:{exit_code:$send_rc,stdout:$send_output},
      health_evidence:$health,
      binary_version_evidence:$version
    }'
}

emit_static() {
  local verb="$1"
  case "$verb" in
    health|doctor)
      local ntm_status="ok"
      [[ -x "$NTM_BIN" ]] || ntm_status="missing"
      jq -nc --arg schema "$VERSION" --arg ntm "$NTM_BIN" --arg ntm_status "$ntm_status" \
        '{schema_version:$schema,status:(if $ntm_status=="ok" then "pass" else "fail" end),ntm_bin:$ntm,ntm_status:$ntm_status,requires:["jq","ntm"]}'
      ;;
    validate|audit)
      jq -nc --arg schema "$VERSION" \
        '{schema_version:$schema,status:"pass",checks:["single-pane target required","dry-run default","apply requires --apply","rollback skips sidecar send","health and version evidence emitted"]}'
      ;;
    why)
      jq -nc --arg schema "$VERSION" \
        '{schema_version:$schema,why:"Provides a pane-scoped NTM-only sidecar respawn surface while preserving recorded-command rollback through native ntm respawn."}'
      ;;
    schema)
      jq -nc --arg schema "$VERSION" \
        '{schema_version:$schema,required:["--session","--pane","--command-path unless --rollback"],modes:["dry-run","apply","rollback"],exit_codes:{"0":"ok","1":"apply failed","2":"usage"}}'
      ;;
    examples)
      jq -nc --arg schema "$VERSION" '{schema_version:$schema,examples:[
        ".flywheel/scripts/ntm-pane-sidecar-respawn.sh --session flywheel --pane 2 --command-path /opt/homebrew/bin/codex --command-arg --dangerously-bypass-approvals-and-sandbox --cwd /Users/josh/Developer/flywheel --env CODEX_HOME=/tmp/codex-sidecar --config-override model=\"gpt-5.5\" --dry-run --json",
        ".flywheel/scripts/ntm-pane-sidecar-respawn.sh --session flywheel --pane 2 --rollback --apply --json"
      ]}'
      ;;
    info|--info)
      jq -nc --arg schema "$VERSION" --arg ntm "$NTM_BIN" \
        '{schema_version:$schema,name:"ntm-pane-sidecar-respawn",ntm_bin:$ntm,mutation_default:"dry-run",native_surfaces:["ntm respawn","ntm send","ntm health","ntm version"]}'
      ;;
  esac
}

declare -A ENV_VALUES=()

if [[ $# -gt 0 ]]; then
  case "$1" in
    health|doctor|validate|audit|why|schema|examples)
      verb="$1"
      shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --ntm-bin) NTM_BIN="${2:-}"; shift 2 ;;
          --json) JSON=1; shift ;;
          --help|-h) usage; exit 0 ;;
          *) fail "unknown argument for $verb: $1" ;;
        esac
      done
      need jq
      emit_static "$verb"
      exit 0
      ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:-}"; shift 2 ;;
    --pane) PANE="${2:-}"; shift 2 ;;
    --cwd) CWD="${2:-}"; shift 2 ;;
    --command-path) COMMAND_PATH="${2:-}"; shift 2 ;;
    --command) RAW_COMMAND="${2:-}"; COMMAND_PATH="${2%% *}"; shift 2 ;;
    --command-arg) COMMAND_ARGS="$(json_append_string "$COMMAND_ARGS" "${2:-}")"; shift 2 ;;
    --env)
      pair="${2:-}"
      ENV_OVERRIDES="$(json_append_env "$ENV_OVERRIDES" "$pair")"
      ENV_VALUES["${pair%%=*}"]="${pair#*=}"
      shift 2
      ;;
    --config-override) CONFIG_OVERRIDES="$(json_append_string "$CONFIG_OVERRIDES" "${2:-}")"; shift 2 ;;
    --ntm-bin) NTM_BIN="${2:-}"; shift 2 ;;
    --dry-run) APPLY=0; shift ;;
    --apply) APPLY=1; shift ;;
    --rollback) ROLLBACK=1; shift ;;
    --json) JSON=1; shift ;;
    --info) need jq; emit_static info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

need jq
[[ -n "$SESSION" ]] || fail "--session is required"
[[ -n "$PANE" ]] || fail "--pane is required"
[[ "$PANE" =~ ^[0-9]+$ ]] || fail "--pane must be one pane index"
[[ "$PANE" != "0" ]] || fail "pane 0 is reserved for the user pane"
[[ "$ROLLBACK" -eq 1 || -n "$COMMAND_PATH" || -n "$RAW_COMMAND" ]] || fail "--command-path is required unless --rollback is set"
[[ "$ROLLBACK" -eq 0 || -z "$RAW_COMMAND$COMMAND_PATH" ]] || COMMAND_PATH=""
[[ -n "$CWD" ]] || CWD="$PWD"

launch_command=""
launch_command_redacted=""
if [[ "$ROLLBACK" -eq 0 ]]; then
  launch_command="$(build_launch_command 0)"
  launch_command_redacted="$(build_launch_command 1)"
fi

# flywheel-1fk5f.8: per-invocation audit-append helper. Records every
# respawn attempt (dry-run + apply) so health/audit/why surfaces have
# real provenance. Helper handles missing-dir + write-failure silently.
_audit_respawn_attempt() {
  local payload="$1"
  if ! command -v cli_audit_append >/dev/null 2>&1 || [[ -z "$payload" ]]; then return 0; fi
  local run_status
  run_status="$(printf '%s' "$payload" | jq -r '.status // "unknown"' 2>/dev/null || printf 'unknown')"
  local rollback_bool
  rollback_bool="$([[ "$ROLLBACK" -eq 1 ]] && printf true || printf false)"
  local apply_bool
  apply_bool="$([[ "$APPLY" -eq 1 ]] && printf true || printf false)"
  local extra_json
  extra_json="$(jq -nc \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg cwd "$CWD" \
    --arg command_path "$COMMAND_PATH" \
    --argjson rollback "$rollback_bool" \
    --argjson apply "$apply_bool" \
    --arg run_status "$run_status" \
    '{session:$session,pane:$pane,cwd:$cwd,command_path:$command_path,rollback:$rollback,apply:$apply,run_status:$run_status}' 2>/dev/null || printf '{}')"
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "respawn" "$run_status" "$extra_json"
}

if [[ "$APPLY" -eq 0 ]]; then
  __plan_payload="$(emit_plan true "$launch_command_redacted")"
  _audit_respawn_attempt "$__plan_payload"
  printf '%s\n' "$__plan_payload"
  exit 0
fi

[[ -x "$NTM_BIN" ]] || fail "ntm binary is not executable: $NTM_BIN" 2
out="$(run_apply "$launch_command" "$launch_command_redacted")"
_audit_respawn_attempt "$out"
printf '%s\n' "$out"
jq -e '.success == true' >/dev/null <<<"$out" || exit 1
