#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled (bead flywheel-dsrq1)
#
# Filled by flywheel-dsrq1: doctor probes substrate (br binary, schema-gate,
# L112 gate, audit log dir); health/audit/why bind to the close-attempt audit
# log; validate enforces row schema; repair manages audit-log dir/truncate.
# cmd_run logs each close attempt via cli_audit_append.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="br-close-with-gate/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/br-close-with-gate-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: br-close-with-gate.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "br-close-with-gate.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "br-close-with-gate.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"br-close-with-gate.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"br-close-with-gate.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"br-close-with-gate.sh doctor --json"}'
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
          optional_extra_fields:["bead","task_id","reason","schema_rc","gate_rc","close_rc"],
          status_enum:["closed","blocked","failed"],
          appended_by:"cmd_run via cli_audit_append"}' ;;
    run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"run",
          required_args:["--bead","--task-id","--callback-envelope-file"],
          gates_run:["callback-envelope-schema-validator.sh","auto-l112-gate.sh","br close"],
          terminal_envelopes:[
            {status:"blocked",failure_class:"callback_envelope_schema_failed"},
            {status:"blocked",failure_class:"auto_l112_gate_failed"},
            {status:"failed",failure_class:"br_close_failed"},
            {status:"closed"}]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,status:"unknown_surface",known_surfaces:["audit-row","run"]}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  # Single-printf bodies (per gl7om SIGPIPE/pipefail finding: multi-printf
  # under `grep -q` consumers trip pipe-closure on first match).
  case "$topic" in
    run)
      printf 'topic: run — `br-close-with-gate.sh --bead ID --task-id ID --callback-envelope-file PATH [--reason TEXT] [--json]` runs callback-envelope-schema-validator + auto-l112-gate; only on rc=0 from both does it run `br close`. Each attempt appends one row to %s.\n' "$SCAFFOLD_AUDIT_LOG"
      ;;
    doctor)
      printf 'topic: doctor — probes the substrate this gate-runner depends on: jq, br binary, callback-envelope-schema-validator script, auto-l112-gate script, audit log directory writability. Emits {checks:[{check,status:ok|fail|warn,detail}],status}.\n'
      ;;
    health)
      printf 'topic: health — summarizes the close-attempt audit log: total_rows, last_status (closed|blocked|failed), last_ts, closed_count / blocked_count / failed_count, freshness_seconds. status: ok | empty | not_initialized.\n'
      ;;
    repair)
      printf 'topic: repair — scopes: audit_log_dir (ensure log directory exists), audit_log_truncate (backup-then-truncate; requires --apply --idempotency-key), none (no-op probe). Default --dry-run; --apply requires --idempotency-key.\n'
      ;;
    validate)
      printf 'topic: validate — subjects: audit-row (each row has ts, action, status, sha256 + status enum closed|blocked|failed; close-action rows must have bead).\n'
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
            && cli_emit_completion_bash "br-close-with-gate" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "br-close-with-gate" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
    jq -nc --arg c "$name" --arg s "$status" --arg d "$detail" \
      '{check:$c,status:$s,detail:$d}'
  }

  # 1. jq present
  if command -v jq >/dev/null 2>&1; then
    checks_jsonl+="$(emit_check jq ok "$(command -v jq)")"$'\n'
  else
    checks_jsonl+="$(emit_check jq fail "jq not on PATH")"$'\n'
  fi

  # 2. br binary present
  local br_bin="${AUTO_L112_GATE_BR_BIN:-br}"
  if command -v "$br_bin" >/dev/null 2>&1; then
    checks_jsonl+="$(emit_check br ok "$(command -v "$br_bin")")"$'\n'
  else
    checks_jsonl+="$(emit_check br fail "br binary not on PATH (override via AUTO_L112_GATE_BR_BIN)")"$'\n'
  fi

  # 3. schema gate script
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  local schema_gate="${CALLBACK_ENVELOPE_SCHEMA_VALIDATOR_BIN:-$script_dir/callback-envelope-schema-validator.sh}"
  if [[ -x "$schema_gate" ]]; then
    checks_jsonl+="$(emit_check schema_gate ok "$schema_gate")"$'\n'
  else
    checks_jsonl+="$(emit_check schema_gate fail "schema gate not executable: $schema_gate")"$'\n'
  fi

  # 4. L112 gate script
  local gate="${AUTO_L112_GATE_BIN:-$script_dir/auto-l112-gate.sh}"
  if [[ -x "$gate" ]]; then
    checks_jsonl+="$(emit_check l112_gate ok "$gate")"$'\n'
  else
    checks_jsonl+="$(emit_check l112_gate fail "L112 gate not executable: $gate")"$'\n'
  fi

  # 5. audit log dir writable / absent-creatable
  local audit_dir
  audit_dir="$(dirname -- "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$audit_dir" && -w "$audit_dir" ]]; then
    checks_jsonl+="$(emit_check audit_log_dir ok "$audit_dir")"$'\n'
  elif [[ ! -e "$audit_dir" ]]; then
    checks_jsonl+="$(emit_check audit_log_dir warn "absent (created on first append): $audit_dir")"$'\n'
  else
    checks_jsonl+="$(emit_check audit_log_dir fail "exists but not writable: $audit_dir")"$'\n'
  fi

  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks_jsonl" | jq -sc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$ts" \
    --arg status "$overall" \
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

  local last_row last_ts last_status closed_count blocked_count failed_count last_epoch freshness_seconds
  last_row="$(tail -n1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || printf '')"
  last_ts="$(printf '%s' "$last_row" | jq -r '.ts // ""' 2>/dev/null || printf '')"
  last_status="$(printf '%s' "$last_row" | jq -r '.status // ""' 2>/dev/null || printf '')"
  closed_count="$({ grep -c '"status":"closed"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  blocked_count="$({ grep -c '"status":"blocked"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  failed_count="$({ grep -c '"status":"failed"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true; } | tr -d ' \n')"
  closed_count="${closed_count:-0}"
  blocked_count="${blocked_count:-0}"
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
    --argjson closed_count "$closed_count" \
    --argjson blocked_count "$blocked_count" \
    --argjson failed_count "$failed_count" \
    --arg last_status "$last_status" \
    --arg last_ts "$last_ts" \
    --argjson freshness_seconds "$freshness_seconds" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log_path:$path,
      total_rows:$total_rows,closed_count:$closed_count,blocked_count:$blocked_count,failed_count:$failed_count,
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
      local lineno=0 pass=0 fail=0 results_jsonl=""
      local row_pass row_offending line
      while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        [[ -z "$line" ]] && continue
        row_pass=true
        row_offending="none"
        if printf '%s' "$line" | jq -e '
          (has("ts") and (.ts | type == "string") and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")))
          and (has("action") and (.action | type == "string") and (.action | length > 0))
          and (has("status") and (.status | type == "string"))
          and (has("sha256") and (.sha256 | type == "string"))
        ' >/dev/null 2>&1; then
          # close-action rows must carry a bead id
          if printf '%s' "$line" | jq -e 'if .action == "close" then (has("bead") and (.bead | type == "string") and (.bead | length > 0)) else true end' >/dev/null 2>&1; then
            # status enum check on close-action rows
            if ! printf '%s' "$line" | jq -e 'if .action == "close" then (.status | IN("closed","blocked","failed")) else true end' >/dev/null 2>&1; then
              row_pass=false
              row_offending="close_action_status_not_in_enum"
            fi
          else
            row_pass=false
            row_offending="close_action_missing_bead"
          fi
        else
          row_pass=false
          row_offending="missing_or_malformed_required_field"
        fi
        if $row_pass; then
          pass=$((pass + 1))
        else
          fail=$((fail + 1))
        fi
        results_jsonl+="$(jq -nc --argjson lineno "$lineno" --arg pass "$row_pass" --arg offending "$row_offending" \
          '{lineno:$lineno,pass:($pass=="true"),offending_field:$offending}')"$'\n'
      done <"$SCAFFOLD_AUDIT_LOG"

      local status="ok"
      if [[ "$fail" -gt 0 ]]; then status="fail"; fi
      printf '%s' "$results_jsonl" | jq -sc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg ts "$ts" \
        --arg subject "$subject" \
        --arg path "$SCAFFOLD_AUDIT_LOG" \
        --arg status "$status" \
        --argjson pass "$pass" \
        --argjson fail "$fail" \
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
      -h|--help) scaffold_emit_topic_help audit 2>/dev/null || printf 'topic: audit — tail close-attempt history\n'; return 0 ;;
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
    printf 'ERR: why requires <id> argument (audit row ts, bead id, or 1-based row index, e.g. 2026-05-10T17:00:00Z, flywheel-abc123, or 5)\n' >&2
    return 64
  fi
  local ts
  ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -e "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",audit_log_path:$log,reason:"audit log absent (no close attempts recorded yet)"}'
    return 0
  fi

  local row="" resolution=""
  # Resolution order: numeric row index (1-based) → exact ts match → exact bead match → substring match (bead/task_id/reason)
  if [[ "$id" =~ ^[0-9]+$ ]]; then
    row="$(sed -n "${id}p" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    resolution="row_index"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select(.ts == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="ts_exact"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select(.bead == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="bead_exact"
  fi
  if [[ -z "$row" ]]; then
    row="$(jq -c --arg id "$id" 'select((.bead // "") | test($id; "i")) // select((.task_id // "") | test($id; "i")) // select((.reason // "") | test($id; "i"))' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -n1 || true)"
    [[ -n "$row" ]] && resolution="substring_match"
  fi

  if [[ -n "$row" ]]; then
    printf '%s' "$row" | jq -c \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg ts "$ts" \
      --arg id "$id" \
      --arg log "$SCAFFOLD_AUDIT_LOG" \
      --arg resolution "$resolution" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log_path:$log,resolution:$resolution,row:.,
        provenance:{action:.action,status:.status,bead:(.bead // null),task_id:(.task_id // null),reason:(.reason // null)}}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log_path:$log,reason:"no audit row matched by row-index, ts, bead, or substring"}'
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
VERSION="br-close-with-gate.v1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCHEMA_GATE="${CALLBACK_ENVELOPE_SCHEMA_VALIDATOR_BIN:-$SCRIPT_DIR/callback-envelope-schema-validator.sh}"
GATE="${AUTO_L112_GATE_BIN:-$SCRIPT_DIR/auto-l112-gate.sh}"
BR_BIN="${AUTO_L112_GATE_BR_BIN:-br}"

BEAD=""
TASK_ID=""
CALLBACK_ENVELOPE_FILE=""
REASON="auto-l112-gate passed"
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: br-close-with-gate.sh --bead ID --task-id ID --callback-envelope-file PATH [--reason TEXT] [--json]

Runs callback-envelope-schema-validator before auto-l112-gate, then br close.
The bead is not closed unless both gates exit 0.
EOF
}

info() {
  jq -nc --arg version "$VERSION" --arg schema_gate "$SCHEMA_GATE" --arg gate "$GATE" --arg br "$BR_BIN" \
    '{name:"br-close-with-gate.sh",version:$version,schema_gate:$schema_gate,gate:$gate,br:$br,exit_codes:{"0":"schema gate and L112 gate passed; br close succeeded","1":"schema gate, L112 gate, or br close failed","2":"usage","3":"validated append, gate timeout, or sandbox refusal"}}'
}

examples() {
  cat <<'EOF'
br-close-with-gate.sh --bead flywheel-123 --task-id b56-example --callback-envelope-file /tmp/callback-envelope.txt --reason "L112 gate passed" --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bead) BEAD="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --callback-envelope-file) CALLBACK_ENVELOPE_FILE="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$BEAD" && -n "$TASK_ID" && -n "$CALLBACK_ENVELOPE_FILE" ]] || { usage >&2; exit 2; }

# Audit-append helper for cmd_run terminals (flywheel-dsrq1).
# Records every close attempt with per-gate exit codes so health/audit/why
# surfaces have provenance to bind to.
_audit_close_attempt() {
  local status="$1" failure_class="${2:-}" schema_rc_v="${3:-0}" gate_rc_v="${4:-0}" close_rc_v="${5:-0}"
  if ! command -v cli_audit_append >/dev/null 2>&1; then return 0; fi
  local extra_json
  extra_json="$(jq -nc \
    --arg bead "$BEAD" \
    --arg task_id "$TASK_ID" \
    --arg reason "$REASON" \
    --arg failure_class "$failure_class" \
    --argjson schema_rc "$schema_rc_v" \
    --argjson gate_rc "$gate_rc_v" \
    --argjson close_rc "$close_rc_v" \
    '{bead:$bead,task_id:$task_id,reason:$reason,failure_class:(if $failure_class == "" then null else $failure_class end),schema_rc:$schema_rc,gate_rc:$gate_rc,close_rc:$close_rc}' 2>/dev/null || printf '{}')"
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "close" "$status" "$extra_json"
}

set +e
schema_output="$("$SCHEMA_GATE" validate envelope --callback-envelope-file "$CALLBACK_ENVELOPE_FILE" --apply --json)"
schema_rc=$?
set -e
if ! jq -e . >/dev/null 2>&1 <<<"$schema_output"; then
  schema_output="$(jq -nc --arg raw "$schema_output" '{raw_output:$raw}')"
fi
if [[ "$schema_rc" -ne 0 ]]; then
  _audit_close_attempt "blocked" "callback_envelope_schema_failed" "$schema_rc" 0 0
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson schema_rc "$schema_rc" \
      '{status:"blocked",bead:$bead,failure_class:"callback_envelope_schema_failed",schema_exit_code:$schema_rc,schema:$schema}'
  else
    printf 'BLOCKED bead=%s failure=callback_envelope_schema_failed schema_exit_code=%s\n' "$BEAD" "$schema_rc"
  fi
  exit "$schema_rc"
fi

set +e
gate_output="$("$GATE" --gate --task-id "$TASK_ID" --callback-envelope-file "$CALLBACK_ENVELOPE_FILE" --json)"
gate_rc=$?
set -e
if [[ "$gate_rc" -ne 0 ]]; then
  _audit_close_attempt "blocked" "auto_l112_gate_failed" 0 "$gate_rc" 0
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson gate "$gate_output" --argjson gate_rc "$gate_rc" \
      '{status:"blocked",bead:$bead,gate_exit_code:$gate_rc,schema:$schema,gate:$gate}'
  else
    printf 'BLOCKED bead=%s gate_exit_code=%s\n' "$BEAD" "$gate_rc"
  fi
  exit "$gate_rc"
fi

set +e
close_output="$("$BR_BIN" close "$BEAD" --reason "$REASON" --lock-timeout 5000 --json 2>&1)"
close_rc=$?
set -e
if [[ "$close_rc" -ne 0 ]]; then
  _audit_close_attempt "failed" "br_close_failed" 0 0 "$close_rc"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson gate "$gate_output" --arg close_output "$close_output" \
      '{status:"failed",bead:$bead,failure_class:"br_close_failed",schema:$schema,gate:$gate,close_output:$close_output}'
  else
    printf 'FAIL bead=%s failure=br_close_failed\n%s\n' "$BEAD" "$close_output"
  fi
  exit 1
fi

_audit_close_attempt "closed" "" 0 0 0
if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson gate "$gate_output" --argjson close "$close_output" \
    '{status:"closed",bead:$bead,schema:$schema,gate:$gate,br_close:$close}'
else
  printf 'CLOSED bead=%s\n' "$BEAD"
fi
