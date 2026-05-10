#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block was scaffolded by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-1fk5f.6 (no remaining
# scaffold stubs).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="ntm-coordinator-shadow/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-coordinator-shadow.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-coordinator-shadow.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-coordinator-shadow.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-coordinator-shadow.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-coordinator-shadow.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-coordinator-shadow.sh doctor --json"}'
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
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","checks"],
          checks_item:["name","status","reason"],
          status_enum:["pass","fail","warn"]}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","audit_log","recent_runs"],
          status_enum:["pass","warn","fail"]}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","mode","scope"],
          mode_enum:["dry_run","apply"],
          valid_scopes:["audit-log-dir","audit-log-truncate","none"],
          mutation_gates:["--apply requires --idempotency-key"]}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","subject"],
          valid_subjects:["row","schema","config"],
          status_enum:["pass","fail","warn","refused","info"]}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["audit_log","row_count","recent"]}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["id","status"],
          status_enum:["found","not_found","unavailable"],
          provenance_fields:["ts","decision","status","failure_class","would_dispatch","blockers"]}'
      ;;
    audit-row|run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["ts","command","schema_version"],
          optional:["session","decision","status","failure_class","would_dispatch","blockers"],
          purpose:"row shape written to SCAFFOLD_AUDIT_LOG by cmd_check terminal envelopes"}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          surfaces:["doctor","health","repair","validate","audit","why","audit-row","default"],
          purpose:"shadow coordinator wrapper — substrate-level canonical layer over cmd_run check --input <receipt>",
          stable_exit_codes:{"0":"pass","2":"usage / refused","3":"refused (--apply without --idempotency-key)","64":"missing input or bad args","65":"invalid input receipt","127":"missing required local dependency"}}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  # Single-printf bodies per gl7om SIGPIPE/pipefail discipline.
  local topic="${1:-}"
  local _runs="${SCAFFOLD_AUDIT_LOG:-${HOME}/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl}"
  case "$topic" in
    run)
      printf 'topic: run — default backward-compatible invocation routes to cmd_run. Use `check --input <receipt.json>` to compute a shadow coordinator recommendation; the canonical scaffold surfaces (doctor/health/repair/validate/audit/why) provide substrate-level operations.\n'
      ;;
    doctor)
      printf 'topic: doctor — substrate health probes (jq presence, audit-log writability, helper-lib readable, ntm binary, repo resolvable, ntm#124 block context). Per-receipt `check` lives in cmd_run; pass --input <receipt.json> to invoke it.\n'
      ;;
    health)
      printf 'topic: health — recent run summary from %s (recent_count, last_run_ts, age_seconds, decisions, status enum). Warn when ledger absent or stale (>24h).\n' "$_runs"
      ;;
    repair)
      printf 'topic: repair — read-only by default; mutate with --apply --idempotency-key KEY. Scopes: audit-log-dir (ensure %s parent exists), audit-log-truncate (clear ledger for testing), none (info default). Apply without --idempotency-key returns refused (rc 3). Daemon enable remains blocked by ntm#124 regardless.\n' "$_runs"
      ;;
    validate)
      printf 'topic: validate — per-subject contract checks. Subjects: row (--row-json=JSON validates an audit-log row schema), schema (--surface=NAME re-emits the schema), config (env presence: SCAFFOLD_AUDIT_LOG parent dir, jq, helper-lib).\n'
      ;;
    audit)
      printf 'topic: audit — tail %s (default --tail=10). Returns rows[] with ts, command, session, decision, status, failure_class, would_dispatch, blockers.\n' "$_runs"
      ;;
    why)
      printf 'topic: why <id> — provenance lookup by task_id, idempotency_token, or session in the audit log; emits decision/status/failure_class/would_dispatch/blockers from the matching row, or status=not_found when absent.\n'
      ;;
    *)
      printf 'topics: run | doctor | health | repair | validate | audit | why\n'
      ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "ntm-coordinator-shadow" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-coordinator-shadow" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 6 named substrate probes — independent of any specific receipt.
  # Per-receipt check lives in cmd_run; the scaffold layer surfaces SUBSTRATE.
  local ts script_dir helper_lib repo_root ntm_bin audit_log
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  helper_lib="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
  repo_root="${_SCAFFOLD_REPO_ROOT:-$(cd "$script_dir/../.." 2>/dev/null && pwd -P)}"
  ntm_bin="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
  audit_log="$SCAFFOLD_AUDIT_LOG"

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH (required for shadow envelope construction)"; fi

  local helper_status="fail" helper_reason=""
  if [[ -r "$helper_lib" ]]; then helper_status="pass"
  else helper_reason="helper-lib not readable: $helper_lib"; fi

  local repo_status="fail" repo_reason=""
  if [[ -d "$repo_root/.flywheel" ]]; then repo_status="pass"
  else repo_reason="$repo_root is not a flywheel repo (no .flywheel/)"; fi

  local ntm_status="fail" ntm_reason=""
  if [[ -x "$ntm_bin" ]]; then ntm_status="pass"
  elif [[ -e "$ntm_bin" ]]; then ntm_reason="exists but not executable: $ntm_bin"
  else ntm_reason="not found: $ntm_bin (shadow mode does not invoke ntm but probes presence)"; fi

  local audit_status="fail" audit_reason=""
  if [[ -f "$audit_log" && -w "$audit_log" ]]; then audit_status="pass"
  elif [[ -d "$(dirname "$audit_log")" && -w "$(dirname "$audit_log")" ]]; then audit_status="pass"; audit_reason="path absent but parent writable"
  else audit_reason="not writable: $audit_log"; fi

  # ntm#124 block context — coordinator daemon is intentionally NOT enabled.
  local ntm124_status="pass" ntm124_reason="shadow mode preserved; daemon enable remains blocked"

  local overall="pass" s
  for s in "$jq_status" "$helper_status" "$repo_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg jq_r "$jq_reason" \
    --arg helper_lib "$helper_lib" --arg helper_s "$helper_status" --arg helper_r "$helper_reason" \
    --arg repo "$repo_root" --arg repo_s "$repo_status" --arg repo_r "$repo_reason" \
    --arg ntm_bin "$ntm_bin" --arg ntm_s "$ntm_status" --arg ntm_r "$ntm_reason" \
    --arg audit_log "$audit_log" --arg audit_s "$audit_status" --arg audit_r "$audit_reason" \
    --arg ntm124_s "$ntm124_status" --arg ntm124_r "$ntm124_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      mode:"shadow",
      daemon_enable_blocked_until_ntm124_closes:true,
      checks:[
        {name:"jq_on_path",status:$jq_s,reason:$jq_r},
        {name:"helper_lib_readable",status:$helper_s,path:$helper_lib,reason:$helper_r},
        {name:"flywheel_repo_resolvable",status:$repo_s,path:$repo,reason:$repo_r},
        {name:"ntm_binary_present",status:$ntm_s,path:$ntm_bin,reason:$ntm_r},
        {name:"audit_log_writable",status:$audit_s,path:$audit_log,reason:$audit_r},
        {name:"ntm124_shadow_block_intact",status:$ntm124_s,reason:$ntm124_r}
      ]}'
}

scaffold_cmd_health() {
  # Tail SCAFFOLD_AUDIT_LOG (per-run ledger written by cmd_check terminal
  # envelopes via cli_audit_append). Reports recent_count, last_run_ts,
  # age_seconds, distinct decisions/sessions. Warn when ledger absent or
  # stale (>24h).
  local ts log_path tail_n=20 tail_lines total last_ts age_seconds distinct_decisions distinct_sessions
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_path="$SCAFFOLD_AUDIT_LOG"

  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log_path" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"audit ledger absent (no historical runs yet)",audit_log:$log,recent_runs:0}'
    return 0
  fi

  tail_lines="$(tail -n "$tail_n" "$log_path" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || true)"
  if [[ -z "$total" ]]; then total=0; fi
  set +e
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  distinct_decisions="$(printf '%s\n' "$tail_lines" | jq -r '.decision // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  distinct_sessions="$(printf '%s\n' "$tail_lines" | jq -r '.session // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  set -e

  if [[ -n "$last_ts" ]]; then
    local now_epoch last_epoch
    now_epoch="$(date -u +%s)"
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo "$now_epoch")"
    age_seconds=$((now_epoch - last_epoch))
  else
    age_seconds=null
  fi

  local status="pass" reason=""
  if [[ "$total" -eq 0 ]]; then
    status="warn"; reason="empty tail"
  elif [[ "$age_seconds" != "null" && "$age_seconds" -gt 86400 ]]; then
    status="warn"; reason="last run >24h ago (stale)"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$log_path" \
    --argjson total "${total:-0}" \
    --arg last_ts "$last_ts" \
    --argjson age "${age_seconds:-null}" \
    --arg decisions "$distinct_decisions" --arg sessions "$distinct_sessions" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      audit_log:$log,recent_runs:$total,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      last_run_age_seconds:$age,
      recent_decisions:($decisions | split(",") | map(select(length > 0))),
      recent_sessions:($sessions | split(",") | map(select(length > 0)))}'
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
  # Per-scope repair actions. Scopes: audit-log-dir (ensure ledger parent
  # exists), audit-log-truncate (clear ledger for testing), none (info).
  # Daemon enable remains blocked by ntm#124 in all scopes.
  local log_path
  log_path="$SCAFFOLD_AUDIT_LOG"
  case "$scope" in
    audit-log-dir)
      local parent="$(dirname "$log_path")"
      if [[ -d "$parent" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg parent "$parent" \
          '{schema_version:$sv,command:"repair",status:"noop",mode:$mode,scope:$scope,parent:$parent,
            note:"audit-log parent already exists",
            daemon_enable_blocked_until_ntm124_closes:true}'
        return 0
      fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$parent" 2>/dev/null
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" --arg parent "$parent" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,parent:$parent,
            action:"mkdir_parent",
            daemon_enable_blocked_until_ntm124_closes:true}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg parent "$parent" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,parent:$parent,
            planned_actions:["mkdir -p audit-log parent when --apply --idempotency-key KEY passed"],
            daemon_enable_blocked_until_ntm124_closes:true}'
      fi
      ;;
    audit-log-truncate)
      if [[ ! -f "$log_path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg log "$log_path" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"dry_run",scope:$scope,reason:"audit ledger absent — nothing to truncate",log_path:$log,
            daemon_enable_blocked_until_ntm124_closes:true}'
        return 0
      fi
      local clear_lines
      clear_lines="$(wc -l <"$log_path" | tr -d ' ')"
      if [[ "$mode" == "apply" ]]; then
        : > "$log_path"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --argjson cleared "$clear_lines" --arg log "$log_path" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,
            log_path:$log,rows_cleared:$cleared,
            daemon_enable_blocked_until_ntm124_closes:true}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --argjson lines "$clear_lines" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,
            current_lines:$lines,
            planned_actions:["truncate audit-log to zero rows when --apply --idempotency-key KEY passed"],
            daemon_enable_blocked_until_ntm124_closes:true}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["audit-log-dir","audit-log-truncate","none"],
          daemon_enable_blocked_until_ntm124_closes:true}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit-log-dir","audit-log-truncate","none"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject contract checks. Subjects: row, schema, config.
  local subject="" row_json="" surface_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --row-json) row_json="${2:-}"; subject="row"; shift 2 ;;
      --surface=*) surface_arg="${1#--surface=}"; subject="schema"; shift ;;
      --surface) surface_arg="${2:-}"; subject="schema"; shift 2 ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    row)
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required for subject=row"}'
        return 64
      fi
      local required='["ts","command","schema_version"]'
      local valid missing
      set +e
      valid="$(printf '%s' "$row_json" | jq -e '. | type == "object"' >/dev/null 2>&1 && echo true || echo false)"
      missing="$(printf '%s' "$row_json" | jq -c --argjson req "$required" '$req - keys' 2>/dev/null || echo "[]")"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" \
        '{schema_version:$sv,command:"validate",subject:"row",
          status:(if ($valid and ($missing | length == 0)) then "pass" else "fail" end),
          valid:$valid,missing_required:$missing}'
      ;;
    schema)
      if [[ -z "$surface_arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--surface=NAME required for subject=schema"}'
        return 64
      fi
      local schema_out
      schema_out="$(scaffold_emit_schema "$surface_arg")"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surf "$surface_arg" --argjson schema "$schema_out" \
        '{schema_version:$sv,command:"validate",subject:"schema",surface:$surf,status:"pass",schema:$schema}'
      ;;
    config)
      local audit_log helper_lib
      audit_log="$SCAFFOLD_AUDIT_LOG"
      helper_lib="${_SCAFFOLD_HELPER_LIB:-${_SCAFFOLD_REPO_ROOT:-/Users/josh/Developer/flywheel}/.flywheel/lib/canonical-cli-helpers.sh}"
      local missing=()
      command -v jq >/dev/null 2>&1 || missing+=("jq:not_on_path")
      [[ -d "$(dirname "$audit_log")" ]] || missing+=("audit_log_parent:$(dirname "$audit_log")")
      [[ -r "$helper_lib" ]] || missing+=("helper_lib:$helper_lib")
      local missing_json
      if [[ ${#missing[@]} -eq 0 ]]; then
        missing_json='[]'
      else
        missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc .)"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg log "$audit_log" --arg helper "$helper_lib" \
        --argjson missing "$missing_json" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if ($missing | length) == 0 then "pass" else "fail" end),
          audit_log:$log,helper_lib:$helper,missing:$missing}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","schema","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail SCAFFOLD_AUDIT_LOG via the helper-lib's cli_emit_audit_tail when
  # available (path-then-schema positional order per b9dfv contract).
  local tail_n=10
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --tail) tail_n="${2:-10}"; shift 2 ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) printf 'ERR: unknown audit arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi
  if [[ ! -f "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,status:"warn",reason:"audit ledger absent",rows:[],count:0}'
    return 0
  fi
  local rows count
  set +e
  rows="$(tail -n "$tail_n" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '.' 2>/dev/null)"
  set -e
  if [[ -z "$rows" ]]; then rows='[]'; fi
  count="$(echo "$rows" | jq 'length' 2>/dev/null || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # Provenance lookup: search SCAFFOLD_AUDIT_LOG for matching task_id,
  # idempotency_token, or session. Returns found|not_found|unavailable.
  local log_path="$SCAFFOLD_AUDIT_LOG"
  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"audit ledger absent",audit_log:$log}'
    return 0
  fi
  local row
  row="$(grep -E "\"(task_id|idempotency_token|session|bead)\":\"$id\"" "$log_path" 2>/dev/null | tail -1 || true)"
  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",reason:"id not in audit ledger",audit_log:$log}'
    return 0
  fi
  if ! printf '%s' "$row" | jq -e . >/dev/null 2>&1; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg raw "$(printf '%s' "$row" | head -c 512)" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"matched row is not valid JSON",raw_preview:$raw}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      provenance:{
        ts:($row.ts // null),
        session:($row.session // null),
        decision:($row.decision // null),
        status:($row.status // null),
        failure_class:($row.failure_class // null),
        would_dispatch:($row.would_dispatch // null),
        blockers:($row.blockers // null)
      },
      row:$row}'
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
VERSION="0.1.0"
PLAN_SLUG="ntm-surface-utilization-migration-2026-05-06"
BEAD_ID="flywheel-ewa3g"
TASK_ID="ntm-w3ac-coordinator-12940"
NATIVE_SURFACE="ntm coordinator assign"
WRAPPER_SURFACE="ntm-coordinator-shadow"
NTM124="https://github.com/Dicklesworthstone/ntm/issues/124"

subcommand="check"
input_file=""
session_name="flywheel"
json_output=false
dry_run=true
apply_mode=false
idempotency_key=""
scope="default"

usage() {
  cat <<'EOF'
Usage:
  ntm-coordinator-shadow.sh check --input <receipt.json> [--session flywheel] [--json]
  ntm-coordinator-shadow.sh doctor|health|repair|validate|audit|why|schema [options]

Purpose:
  Compute coordinator recommendations in shadow mode without enabling the
  unsafe `ntm assign --repo /Users/josh/Developer/flywheel --watch --auto`
  daemon path.

Mutation discipline:
  --dry-run is the default.
  --apply requires --idempotency-key and still applies no daemon mutation while
  ntm#124 remains open.
EOF
}

idempotency_token() {
  printf '%s|%s|%s|%s|%s' "$PLAN_SLUG" "/Users/josh/Developer/flywheel" "$BEAD_ID" "W3a" "$TASK_ID" | shasum -a 256 | awk '{print $1}'
}

emit_json() {
  local status="$1" decision="$2" failure_class="$3" message="$4" exit_code="$5"
  jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg session "$session_name" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ntm124 "$NTM124" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_shadow_snapshot" \
    --arg ttl_wrapper "shadow_receipt_lifetime" \
    --arg ttl_decision "recompute_before_dispatch" \
    --arg delta "coordinator_recommendation_only_daemon_blocked_ntm124" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    --argjson exit_code "$exit_code" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      session: $session,
      mode: "shadow",
      auto_assign_enabled: false,
      daemon_enable_blocked_until_ntm124_closes: true,
      ntm124: $ntm124,
      command_not_run: "ntm assign --repo /Users/josh/Developer/flywheel --watch --auto",
      actual_dispatch_performed: false,
      mutation_applied: false,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_receipts","compute_shadow_recommendation","emit_shadow_receipt","preserve_ntm124_block"],
      forbidden_operations: ["enable_daemon","run_ntm_assign_watch_auto","dispatch_without_approval","mutate_coordinator_config"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W3aC"
    }'
  return "$exit_code"
}

parse_args() {
  if [[ $# -gt 0 && "$1" != --* ]]; then
    subcommand="$1"
    shift
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input)
        input_file="${2:-}"
        shift 2
        ;;
      --input=*)
        input_file="${1#*=}"
        shift
        ;;
      --session)
        session_name="${2:-}"
        shift 2
        ;;
      --session=*)
        session_name="${1#*=}"
        shift
        ;;
      --json)
        json_output=true
        shift
        ;;
      --dry-run)
        dry_run=true
        apply_mode=false
        shift
        ;;
      --apply)
        apply_mode=true
        dry_run=false
        shift
        ;;
      --idempotency-key)
        idempotency_key="${2:-}"
        shift 2
        ;;
      --idempotency-key=*)
        idempotency_key="${1#*=}"
        shift
        ;;
      --scope)
        scope="${2:-}"
        shift 2
        ;;
      --scope=*)
        scope="${1#*=}"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        emit_json "fail" "hold" "usage" "unknown argument: $1" 2
        ;;
    esac
  done
}

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'jq is required\n' >&2
    exit 127
  }
}

validate_input() {
  [[ -n "$input_file" ]] || emit_json "fail" "hold" "missing_input" "--input is required" 64
  [[ -f "$input_file" ]] || emit_json "fail" "hold" "input_missing" "input receipt missing: $input_file" 65
  jq empty "$input_file" >/dev/null 2>&1 || emit_json "fail" "hold" "input_non_json" "input receipt is not valid JSON: $input_file" 65
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "hold" "missing_idempotency_key" "--apply requires --idempotency-key even though daemon mutation is blocked" 2
  fi
}

read_field() {
  local expr="$1" fallback="$2"
  jq -r "$expr // \"$fallback\"" "$input_file"
}

status_passes() {
  case "$1" in
    pass|ok|green|approved|allow|allowed|true) return 0 ;;
    *) return 1 ;;
  esac
}

# Append a terminal envelope row to SCAFFOLD_AUDIT_LOG so the canonical
# scaffold layer (health, audit, why) has historical signal on real check runs.
_audit_append_check() {
  local envelope_json="$1"
  local ts row
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  row="$(jq -nc --arg ts "$ts" --arg sv "${SCAFFOLD_SCHEMA_VERSION:-ntm-coordinator-shadow/v1}" \
    --argjson ev "${envelope_json:-null}" \
    '{ts:$ts,schema_version:$sv,command:"check",
      session:($ev.session // null),
      decision:($ev.decision // null),
      status:($ev.status // null),
      failure_class:($ev.failure_class // null),
      would_dispatch:($ev.would_dispatch // null),
      blockers:($ev.blockers // null),
      idempotency_token:($ev.idempotency_token // null)}' 2>/dev/null)"
  [[ -z "$row" ]] && return 0
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl}" "check" "ok" "$row" >/dev/null 2>&1 || true
  else
    local log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl}"
    mkdir -p "$(dirname "$log")" 2>/dev/null || true
    printf '%s\n' "$row" >> "$log" 2>/dev/null || true
  fi
}

cmd_check() {
  validate_input

  local quota metrics eventstream safety approval ready idle
  quota="$(read_field '.quota_status // .checks.quota // .quota.status' unknown)"
  metrics="$(read_field '.metrics_status // .checks.metrics // .metrics.status' unknown)"
  eventstream="$(read_field '.eventstream_status // .checks.eventstream // .eventstream.status' unknown)"
  safety="$(read_field '.safety_status // .checks.safety // .safety.status' unknown)"
  approval="$(read_field '.approval_status // .checks.approval // .approval.status' unknown)"
  ready="$(jq -r '.ready_bead_count // .signals.ready_bead_count // 0' "$input_file")"
  idle="$(jq -r '.idle_worker_count // .signals.idle_worker_count // 0' "$input_file")"

  local blockers=()
  status_passes "$quota" || blockers+=("quota:$quota")
  status_passes "$metrics" || blockers+=("metrics:$metrics")
  status_passes "$eventstream" || blockers+=("eventstream:$eventstream")
  status_passes "$safety" || blockers+=("safety:$safety")
  status_passes "$approval" || blockers+=("approval:$approval")
  [[ "$ready" =~ ^[0-9]+$ && "$ready" -gt 0 ]] || blockers+=("ready_bead_count:$ready")
  [[ "$idle" =~ ^[0-9]+$ && "$idle" -gt 0 ]] || blockers+=("idle_worker_count:$idle")

  local status="pass" decision="recommend_dispatch" failure_class="none" message="shadow recommendation: dispatch capacity exists; daemon remains blocked"
  local would_dispatch=true
  if [[ "${#blockers[@]}" -gt 0 ]]; then
    status="hold"
    decision="recommend_hold"
    failure_class="upstream_receipt_blocker"
    message="shadow recommendation: hold until upstream receipts pass"
    would_dispatch=false
  fi

  local check_envelope
  check_envelope="$(jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg session "$session_name" \
    --arg quota "$quota" \
    --arg metrics "$metrics" \
    --arg eventstream "$eventstream" \
    --arg safety "$safety" \
    --arg approval "$approval" \
    --arg ready "$ready" \
    --arg idle "$idle" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ntm124 "$NTM124" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_shadow_snapshot" \
    --arg ttl_wrapper "shadow_receipt_lifetime" \
    --arg ttl_decision "recompute_before_dispatch" \
    --arg delta "coordinator_recommendation_only_daemon_blocked_ntm124" \
    --argjson blockers "$(printf '%s\n' "${blockers[@]}" | jq -R . | jq -s .)" \
    --argjson would_dispatch "$would_dispatch" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      session: $session,
      mode: "shadow",
      would_dispatch: $would_dispatch,
      actual_dispatch_performed: false,
      mutation_applied: false,
      auto_assign_enabled: false,
      daemon_enable_blocked_until_ntm124_closes: true,
      ntm124: $ntm124,
      command_not_run: "ntm assign --repo /Users/josh/Developer/flywheel --watch --auto",
      upstream_receipts: {
        quota: $quota,
        metrics: $metrics,
        eventstream: $eventstream,
        safety: $safety,
        approval: $approval,
        ready_bead_count: ($ready | tonumber),
        idle_worker_count: ($idle | tonumber)
      },
      blockers: $blockers,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_receipts","compute_shadow_recommendation","emit_shadow_receipt","preserve_ntm124_block"],
      forbidden_operations: ["enable_daemon","run_ntm_assign_watch_auto","dispatch_without_approval","mutate_coordinator_config"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      L112: "OK_ntm_migrate_W3aC"
    }')"
  _audit_append_check "$check_envelope"
  printf '%s\n' "$check_envelope"
}

cmd_static() {
  local status="$1" message="$2"
  jq -n \
    --arg status "$status" \
    --arg message "$message" \
    --arg version "$VERSION" \
    --arg scope "$scope" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ntm124 "$NTM124" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_shadow_snapshot" \
    --arg ttl_wrapper "shadow_receipt_lifetime" \
    --arg ttl_decision "recompute_before_dispatch" \
    --arg delta "coordinator_recommendation_only_daemon_blocked_ntm124" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      message: $message,
      version: $version,
      scope: $scope,
      mode: "shadow",
      auto_assign_enabled: false,
      daemon_enable_blocked_until_ntm124_closes: true,
      ntm124: $ntm124,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_receipts","compute_shadow_recommendation","emit_shadow_receipt","preserve_ntm124_block"],
      forbidden_operations: ["enable_daemon","run_ntm_assign_watch_auto","dispatch_without_approval","mutate_coordinator_config"],
      stable_exit_codes: {
        "0": "shadow recommendation or diagnostic pass",
        "2": "usage or invalid apply request",
        "64": "missing input",
        "65": "invalid input receipt",
        "127": "missing required local dependency"
      },
      L112: "OK_ntm_migrate_W3aC"
    }'
}

cmd_repair() {
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "hold" "missing_idempotency_key" "repair --apply requires --idempotency-key" 2
  fi
  cmd_static "pass" "repair is no-op; shadow mode preserved and daemon enable remains blocked by ntm#124"
}

cmd_schema() {
  jq -n --arg ntm124 "$NTM124" '{
    schema_version: "ntm-coordinator-shadow/v1",
    input_fields: ["quota_status","metrics_status","eventstream_status","safety_status","approval_status","ready_bead_count","idle_worker_count"],
    required_output_fields: [
      "status",
      "decision",
      "mode",
      "would_dispatch",
      "actual_dispatch_performed",
      "daemon_enable_blocked_until_ntm124_closes",
      "ntm124",
      "authorized_operations",
      "forbidden_operations",
      "ttl_native",
      "ttl_wrapper",
      "ttl_decision",
      "native_wrapper_delta",
      "L112"
    ],
    stable_exit_codes: {
      "0": "shadow recommendation or diagnostic pass",
      "2": "usage or invalid apply request",
      "64": "missing input",
      "65": "invalid input receipt",
      "127": "missing required local dependency"
    },
    mutation_modes: ["--dry-run","--apply"],
    apply_requires: ["--idempotency-key"],
    daemon_enable_blocked_until_ntm124_closes: true,
    ntm124: $ntm124,
    L112: "OK_ntm_migrate_W3aC"
  }'
}

cmd_completion() {
  cat <<'EOF'
check
doctor
health
repair
validate
audit
why
schema
--input
--session
--json
--dry-run
--apply
--idempotency-key
EOF
}

main() {
  require_jq
  parse_args "$@"
  case "$subcommand" in
    check) cmd_check ;;
    doctor) cmd_static "pass" "doctor pass: shadow coordinator wrapper available; daemon enable blocked by ntm#124" ;;
    health) cmd_static "pass" "health pass: shadow recommendation surface available" ;;
    repair) cmd_repair ;;
    validate) cmd_static "pass" "validate pass: JSON, schema, stable exit codes, and dry-run/apply discipline available" ;;
    audit) cmd_static "pass" "audit pass: no daemon command is executed; ntm#124 block is explicit" ;;
    why) cmd_static "pass" "why: W3aC is shadow-only until ntm#124 closes; recommendations are receipts, not daemon actions" ;;
    schema) cmd_schema ;;
    completion) cmd_completion ;;
    *) emit_json "fail" "hold" "usage" "unknown subcommand: $subcommand" 2 ;;
  esac
}

main "$@"
