#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: one portable recovery primitive with canonical CLI, doctor, ledger, and fixture-facing recovery logic.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-qprlj) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-qprlj)
#
# Surface-specific logic for the beads-db recovery primitive:
#   doctor   probes substrate (br binary, .beads/issues.jsonl input, recovery
#            ledger, contract ledger, jsonl-append lib, jq/sqlite3/mktemp deps,
#            audit log dir writability, repo root)
#   health   summarizes last-run state from $SCAFFOLD_AUDIT_LOG (pass rate over 50)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: beads-db PATH (sqlite3 integrity check) | audit-row JSONL
#   audit    routes through cli_emit_audit_tail (default 20 rows)
#   why      provenance lookup — id is row index (numeric, neg=tail) or
#            substring match against status / repo / scope fields
#
# NOTE: the legacy substantive doctor/health/repair behavior (~lines 600+)
# stays intact. The scaffold-stub canonical-cli surface above provides the
# canonical envelope shape (.command, .checks[], .status). Operators reaching
# for the legacy behavior can use the dash-prefix forms (--doctor) which
# bypass the scaffold intercept.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="beads-db-recover/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/beads-db-recover-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: beads-db-recover.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: beads-db PATH | audit-row JSONL
  audit [--json] [N]       tail $SCAFFOLD_AUDIT_LOG (default 20 rows)
  why <id>                 provenance: id is row index (numeric, neg=tail) or substring match
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "beads-db-recover.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "beads-db-recover.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"beads-db-recover.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"beads-db-recover.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"beads-db-recover.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"doctor\"",status:"\"pass\"|\"warn\"|\"fail\"",
          checks:"[{name,status,detail}]",ts:"string(iso8601)"}}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"health\"",status:"\"pass\"|\"warn\"|\"empty\"",
          total_runs:"int",last_run_ts:"string|null",last_status:"string|null",
          pass_rate:"float|null",window:"int"}}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"repair\"",status:"\"dry_run\"|\"applied\"|\"refused\"",
          mode:"\"dry_run\"|\"apply\"",scope:"\"audit_log_dir\"|\"audit_log_truncate\"",
          idempotency_key:"string|null",planned_actions:"[obj]",applied_actions:"[obj]"}}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"validate\"",subject:"\"beads-db\"|\"audit-row\"",
          status:"\"pass\"|\"fail\"|\"refused\"",detail:"object"}}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"audit\"",status:"\"pass\"|\"empty\"|\"missing\"",
          row_count:"int",recent:"[obj]"}}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"why\"",id:"string",match_count:"int",
          matches:"[obj]"}}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          known_surfaces:["doctor","health","repair","validate","audit","why"]}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — probes recovery substrate (br binary, .beads/issues.jsonl input, recovery+contract ledgers, jsonl-append lib, jq/sqlite3/mktemp deps, audit log dir, repo root). Pass = recovery primitive ready; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 recovery runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: beads-db PATH (sqlite3 PRAGMA integrity_check on the .beads/beads.db file); audit-row JSONL_LINE (verify ts/status fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, repo, scope, integrity.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / repo / scope fields.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "beads-db-recover" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "beads-db-recover" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-qprlj) ----------

# Bind load-bearing paths once. Mirror legacy globals declared below the
# scaffold END marker; scaffold layer can't read those directly because the
# early-dispatch intercept short-circuits before they're set.
SCAFFOLD_REPO="${BEADS_DB_RECOVER_REPO:-$_SCAFFOLD_REPO_ROOT}"
SCAFFOLD_BR_BIN="${BEADS_DB_RECOVER_BR_BIN:-br}"
SCAFFOLD_LEDGER="${BEADS_DB_RECOVER_LEDGER:-$HOME/.local/state/flywheel/beads-recovery.jsonl}"
SCAFFOLD_CONTRACT_LEDGER="${BEADS_DB_RECOVER_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
SCAFFOLD_JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
SCAFFOLD_BEADS_JSONL="$SCAFFOLD_REPO/.beads/issues.jsonl"
SCAFFOLD_BEADS_DB="$SCAFFOLD_REPO/.beads/beads.db"

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/bdr-doctor.XXXXXX")"
  trap 'rm -f "$checks_tmp"' RETURN
  local status="pass"
  add_check() {
    local name="$1" stat="$2" detail="$3"
    jq -nc --arg n "$name" --arg s "$stat" --arg d "$detail" \
      '{name:$n,status:$s,detail:$d}' >>"$checks_tmp"
    if [[ "$stat" == "fail" ]]; then status="fail"
    elif [[ "$stat" == "warn" && "$status" != "fail" ]]; then status="warn"
    fi
    return 0
  }

  if command -v "$SCAFFOLD_BR_BIN" >/dev/null 2>&1; then
    add_check br_executable pass "$(command -v "$SCAFFOLD_BR_BIN")"
  elif [[ -x "$SCAFFOLD_BR_BIN" ]]; then
    add_check br_executable pass "$SCAFFOLD_BR_BIN"
  else
    add_check br_executable fail "br binary not found: $SCAFFOLD_BR_BIN"
  fi

  if [[ -f "$SCAFFOLD_BEADS_JSONL" && -r "$SCAFFOLD_BEADS_JSONL" ]]; then
    local rows; rows="$(wc -l <"$SCAFFOLD_BEADS_JSONL" 2>/dev/null | tr -d ' ')"
    add_check beads_jsonl_present pass "$SCAFFOLD_BEADS_JSONL (rows=${rows:-0})"
  elif [[ -d "$SCAFFOLD_REPO/.beads" ]]; then
    add_check beads_jsonl_present warn "issues.jsonl absent in $SCAFFOLD_REPO/.beads (fresh repos may legitimately have none)"
  else
    add_check beads_jsonl_present warn ".beads dir missing in $SCAFFOLD_REPO"
  fi

  if [[ -d "$(dirname "$SCAFFOLD_LEDGER")" ]]; then
    add_check recovery_ledger_dir_present pass "$(dirname "$SCAFFOLD_LEDGER")"
  else
    add_check recovery_ledger_dir_present warn "missing dir: $(dirname "$SCAFFOLD_LEDGER")"
  fi

  if [[ -d "$(dirname "$SCAFFOLD_CONTRACT_LEDGER")" ]]; then
    add_check contract_ledger_dir_present pass "$(dirname "$SCAFFOLD_CONTRACT_LEDGER")"
  else
    add_check contract_ledger_dir_present warn "missing dir: $(dirname "$SCAFFOLD_CONTRACT_LEDGER")"
  fi

  if [[ -r "$SCAFFOLD_JSONL_APPEND_LIB" ]]; then
    add_check jsonl_append_lib_readable pass "$SCAFFOLD_JSONL_APPEND_LIB"
  else
    add_check jsonl_append_lib_readable warn "missing: $SCAFFOLD_JSONL_APPEND_LIB (recovery uses fallback append path)"
  fi

  for tool in jq sqlite3 mktemp grep awk; do
    if command -v "$tool" >/dev/null 2>&1; then
      add_check "${tool}_available" pass "$(command -v "$tool")"
    else
      add_check "${tool}_available" fail "not on PATH"
    fi
  done

  local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$audit_dir" && -w "$audit_dir" ]]; then
    add_check audit_log_dir_writable pass "$audit_dir"
  elif [[ -d "$audit_dir" ]]; then
    add_check audit_log_dir_writable warn "exists but not writable: $audit_dir"
  else
    add_check audit_log_dir_writable warn "missing dir; repair --scope audit_log_dir will create"
  fi

  if [[ -d "$_SCAFFOLD_REPO_ROOT" ]]; then
    add_check repo_root_resolved pass "$_SCAFFOLD_REPO_ROOT"
  else
    add_check repo_root_resolved fail "did not resolve: $_SCAFFOLD_REPO_ROOT"
  fi

  if command -v cli_emit_info >/dev/null 2>&1; then
    add_check helper_lib_loaded pass "$_SCAFFOLD_HELPER_LIB"
  else
    add_check helper_lib_loaded warn "helper lib symbols absent — fallback paths active"
  fi

  jq -cs \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg status "$status" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",status:$status,ts:$ts,checks:.}' \
    "$checks_tmp"

  [[ "$status" != "fail" ]]
}

scaffold_cmd_health() {
  local window=50 total_runs=0 last_run_ts="" last_status="" pass_count=0 status="pass"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson w "$window" \
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no recovery runs recorded yet"}'
    return 0
  fi
  total_runs="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
  [[ -z "$total_runs" ]] && total_runs=0
  if [[ "$total_runs" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson w "$window" \
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w}'
    return 0
  fi
  last_run_ts="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.ts // ""' 2>/dev/null)"
  last_status="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.status // "unknown"' 2>/dev/null)"
  pass_count="$(tail -n "$window" "$SCAFFOLD_AUDIT_LOG" | jq -s '[.[] | select(.status == "pass")] | length' 2>/dev/null)"
  [[ -z "$pass_count" ]] && pass_count=0
  local sample
  if [[ "$total_runs" -lt "$window" ]]; then sample="$total_runs"; else sample="$window"; fi
  local pass_rate="null"
  if [[ "$sample" -gt 0 ]]; then
    pass_rate="$(awk -v p="$pass_count" -v s="$sample" 'BEGIN{printf "%.4f", p/s}')"
  fi
  if [[ "$last_status" == "fail" ]]; then status="warn"; fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg status "$status" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson total "$total_runs" \
    --arg last_ts "$last_run_ts" \
    --arg last_s "$last_status" \
    --argjson rate "$pass_rate" \
    --argjson w "$sample" \
    '{schema_version:$sv,command:"health",status:$status,ts:$ts,total_runs:$total,last_run_ts:(if $last_ts=="" then null else $last_ts end),last_status:(if $last_s=="" then null else $last_s end),pass_rate:$rate,window:$w}'
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
  # Apply contract gate runs FIRST: missing --idempotency-key wins rc=3
  # regardless of scope validity.
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  case "$scope" in
    audit_log_dir|audit_log_truncate) ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:null,reason:"--scope required",valid_scopes:["audit_log_dir","audit_log_truncate"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit_log_dir","audit_log_truncate"]}'
      return 0 ;;
  esac

  local planned_tmp applied_tmp
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/bdr-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/bdr-repair-applied.XXXXXX")"
  trap 'rm -f "$planned_tmp" "$applied_tmp"' RETURN
  : >"$planned_tmp"; : >"$applied_tmp"

  case "$scope" in
    audit_log_dir)
      local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      if [[ ! -d "$audit_dir" ]]; then
        jq -nc --arg dir "$audit_dir" '{action:"mkdir_audit_dir",target:$dir}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          mkdir -p "$audit_dir"
          jq -nc --arg dir "$audit_dir" '{action:"mkdir_audit_dir",target:$dir,result:"ok"}' >>"$applied_tmp"
        fi
      fi
      ;;
    audit_log_truncate)
      local keep=1000 row_count=0
      if [[ -f "$SCAFFOLD_AUDIT_LOG" ]]; then
        row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
      fi
      [[ -z "$row_count" ]] && row_count=0
      if [[ "$row_count" -gt "$keep" ]]; then
        local trim=$((row_count - keep))
        jq -nc --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rc "$row_count" --argjson keep "$keep" --argjson trim "$trim" \
          '{action:"truncate_audit_log",target:$log,row_count:$rc,keep:$keep,rows_to_drop:$trim}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          local tmp; tmp="$(mktemp "${SCAFFOLD_AUDIT_LOG}.trunc.XXXXXX")"
          tail -n "$keep" "$SCAFFOLD_AUDIT_LOG" >"$tmp" && mv "$tmp" "$SCAFFOLD_AUDIT_LOG"
          jq -nc --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rc "$row_count" --argjson keep "$keep" \
            '{action:"truncate_audit_log",target:$log,kept:$keep,dropped:($rc - $keep),result:"ok"}' >>"$applied_tmp"
        fi
      fi
      ;;
  esac

  local final_status
  if [[ "$mode" == "apply" ]]; then
    final_status="applied"
    if command -v cli_audit_append >/dev/null 2>&1; then
      cli_audit_append "$SCAFFOLD_AUDIT_LOG" "repair" "applied" \
        "$(jq -nc --arg s "$scope" --arg k "$idem_key" '{scope:$s,idempotency_key:$k}')"
    fi
  else
    final_status="dry_run"
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg status "$final_status" \
    --arg mode "$mode" \
    --arg scope "$scope" \
    --arg key "$idem_key" \
    --slurpfile planned "$planned_tmp" \
    --slurpfile applied "$applied_tmp" \
    '{schema_version:$sv,command:"repair",status:$status,mode:$mode,scope:$scope,idempotency_key:(if $key=="" then null else $key end),planned_actions:$planned,applied_actions:$applied}'
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  case "$subject" in
    beads-db)
      local path="${1:-$SCAFFOLD_BEADS_DB}"
      if [[ ! -r "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"beads-db",status:"fail",path:$p,reason:"path not readable"}'
        return 1
      fi
      if ! command -v sqlite3 >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"beads-db",status:"fail",path:$p,reason:"sqlite3 not on PATH"}'
        return 1
      fi
      local integrity row_count_query row_count
      integrity="$(sqlite3 "$path" 'PRAGMA integrity_check;' 2>&1)"
      row_count_query="$(sqlite3 "$path" "SELECT COUNT(*) FROM issues;" 2>/dev/null)"
      row_count="${row_count_query:-0}"
      local status="pass"
      if [[ "$integrity" != "ok" ]]; then status="fail"; fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg status "$status" \
        --arg p "$path" \
        --arg integrity "$integrity" \
        --argjson row_count "$row_count" \
        '{schema_version:$sv,command:"validate",subject:"beads-db",status:$status,path:$p,integrity:$integrity,issue_row_count:$row_count}'
      [[ "$status" == "pass" ]]
      ;;
    audit-row)
      local row="${1:-}"
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"refused",reason:"jsonl row required"}'
        return 64
      fi
      if ! jq -e . >/dev/null 2>&1 <<<"$row"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"row is not valid JSON"}'
        return 1
      fi
      local missing=()
      for f in ts status; do
        jq -e --arg f "$f" 'has($f)' >/dev/null 2>&1 <<<"$row" || missing+=("$f")
      done
      if (( ${#missing[@]} == 0 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson row "$row" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"pass",row:$row}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson row "$row" \
          --argjson missing "$(printf '%s\n' "${missing[@]}" | jq -R . | jq -cs .)" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"missing required fields",missing:$missing,row:$row}'
        return 1
      fi
      ;;
    ""|--json|--help|-h)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["beads-db","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["beads-db","audit-row"]}'
      return 0 ;;
  esac
}

scaffold_cmd_audit() {
  local limit="${1:-20}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    case "$limit" in --json) limit="${2:-20}" ;; *) limit=20 ;; esac
  fi
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
    return 0
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",status:"missing",audit_log:$log,row_count:0,recent:[]}'
    return 0
  fi
  local row_count; row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  if [[ "$row_count" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      '{schema_version:$sv,command:"audit",status:"empty",row_count:0,recent:[]}'
    return 0
  fi
  local recent
  recent="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -cs '.' 2>/dev/null)"
  [[ -z "$recent" ]] && recent='[]'
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --argjson rc "$row_count" \
    --argjson rows "$recent" \
    '{schema_version:$sv,command:"audit",status:"pass",row_count:$rc,recent:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument (numeric row index or substring)\n' >&2; return 64
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"missing",match_count:0,matches:[],reason:"audit log absent"}'
    return 0
  fi
  local matches="[]"
  if [[ "$id" =~ ^-?[0-9]+$ ]]; then
    local row_count; row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    local idx="$id"
    if [[ "$idx" -lt 0 ]]; then idx=$((row_count + idx + 1)); fi
    if [[ "$idx" -ge 1 && "$idx" -le "$row_count" ]]; then
      matches="$(sed -n "${idx}p" "$SCAFFOLD_AUDIT_LOG" | jq -cs '.' 2>/dev/null)"
    fi
  else
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.repo // "") | contains($id)) or ((.scope // "") | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
  fi
  [[ -z "$matches" ]] && matches='[]'
  local count; count="$(jq 'length' <<<"$matches" 2>/dev/null)"
  [[ -z "$count" ]] && count=0
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg id "$id" \
    --argjson matches "$matches" \
    --argjson c "$count" \
    '{schema_version:$sv,command:"why",id:$id,status:(if $c>0 then "pass" else "miss" end),match_count:$c,matches:$matches}'
  return 0
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
VERSION="beads-db-recover.v1.0.0"
SCHEMA_VERSION="beads-db-recover/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${BEADS_DB_RECOVER_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${BEADS_DB_RECOVER_LEDGER:-$HOME/.local/state/flywheel/beads-recovery.jsonl}"
CONTRACT_LEDGER="${BEADS_DB_RECOVER_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
BR_BIN="${BEADS_DB_RECOVER_BR_BIN:-br}"
ALT_BR_BIN="${BEADS_DB_RECOVER_ALT_BR_BIN:-}"
NOW_OVERRIDE="${BEADS_DB_RECOVER_NOW:-}"

MODE="recover"
JSON_OUT=0
APPLY=0
DRY_RUN=1
FORCE=0
WATCH=0
WATCH_INTERVAL=5
REPAIR_SCOPE="openread"
VALIDATE_TARGET="repo"
WHY_ID=""
SCHEMA_TOPIC="doctor"
HELP_TOPIC=""
COMPLETION_SHELL=""
WIDTH=100
EXPLAIN=0
IDEMPOTENCY_KEY=""

usage() {
  cat <<'EOF'
usage:
  beads-db-recover.sh --repo PATH [--dry-run|--apply] [--force] [--json]
  beads-db-recover.sh doctor|--doctor [--repo PATH] [--json]
  beads-db-recover.sh health [--repo PATH] [--watch] [--interval N] [--json]
  beads-db-recover.sh repair --scope openread|substrate-contract|all [--dry-run|--apply] [--repo PATH] [--json]
  beads-db-recover.sh validate repo|ledger [--repo PATH] [--json]
  beads-db-recover.sh audit [--json]
  beads-db-recover.sh why ID [--json]
  beads-db-recover.sh schema recovery|doctor|ledger|contract [--json]
  beads-db-recover.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

now_iso() {
  if [[ -n "$NOW_OVERRIDE" ]]; then
    printf '%s\n' "$NOW_OVERRIDE"
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

append_validated() {
  local path="$1" row="$2"
  [[ -r "$JSONL_APPEND_LIB" ]] || { echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2; return 3; }
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$path" "$row"
}

repo_abs() {
  local repo="$1"
  if [[ -d "$repo" ]]; then
    (cd "$repo" && pwd -P)
  else
    python3 - "$repo" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).expanduser())
PY
  fi
}

br_version() {
  local bin="$1"
  "$bin" --version 2>&1 | head -1 || printf 'unknown\n'
}

integrity_json() {
  local repo="$1" db out status
  db="$repo/.beads/beads.db"
  if [[ ! -f "$db" ]]; then
    jq -nc --arg db "$db" '{db_path:$db,beads_db_integrity_check_status:"missing_db",integrity_output:"missing_db",status:"missing_db"}'
    return 0
  fi
  if ! command -v sqlite3 >/dev/null 2>&1; then
    jq -nc --arg db "$db" '{db_path:$db,beads_db_integrity_check_status:"sqlite3_missing",integrity_output:"sqlite3_missing",status:"error"}'
    return 0
  fi
  out="$(sqlite3 "$db" 'PRAGMA integrity_check;' 2>&1 || true)"
  if [[ "$out" == "ok" ]]; then status="ok"; else status="$out"; fi
  jq -nc --arg db "$db" --arg status "$status" --arg out "$out" \
    '{db_path:$db,beads_db_integrity_check_status:$status,integrity_output:$out,status:(if $status=="ok" then "ok" else "error" end)}'
}

ledger_summary_json() {
  local now
  now="$(now_iso)"
  python3 - "$LEDGER" "$now" <<'PY'
from __future__ import annotations
import json, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

ledger = Path(sys.argv[1]).expanduser()
now_raw = sys.argv[2]

def parse_dt(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None

now = parse_dt(now_raw) or datetime.now(timezone.utc)
rows = []
if ledger.exists():
    for line in ledger.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
last_ts = None
count_24h = 0
for row in rows:
    ts = parse_dt(row.get("ts"))
    if ts is None:
        continue
    if last_ts is None or ts > last_ts:
        last_ts = ts
    if ts >= now - timedelta(hours=24):
        count_24h += 1
print(json.dumps({
    "beads_db_recovery_last_24h_count": count_24h,
    "beads_db_recovery_last_ts": last_ts.isoformat().replace("+00:00", "Z") if last_ts else None,
    "ledger_path": str(ledger),
}, separators=(",", ":")))
PY
}

doctor_json() {
  local repo_abs_path summary integrity status
  repo_abs_path="$(repo_abs "$REPO")"
  summary="$(ledger_summary_json)"
  integrity="$(integrity_json "$repo_abs_path")"
  status="$(jq -r --argjson summary "$summary" '
    if .beads_db_integrity_check_status != "ok" and .beads_db_integrity_check_status != "missing_db" then "error"
    elif ($summary.beads_db_recovery_last_24h_count // 0) >= 2 then "warn"
    else "pass" end
  ' <<<"$integrity")"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION.doctor" \
    --arg version "$VERSION" \
    --arg repo "$repo_abs_path" \
    --arg status "$status" \
    --argjson summary "$summary" \
    --argjson integrity "$integrity" \
    '{schema_version:$schema_version,version:$version,command:"doctor",scope:"beads-db-recovery",repo:$repo,status:$status,
      beads_db_recovery_last_24h_count:($summary.beads_db_recovery_last_24h_count // 0),
      beads_db_recovery_last_ts:$summary.beads_db_recovery_last_ts,
      beads_db_integrity_check_status:$integrity.beads_db_integrity_check_status,
      integrity_output:$integrity.integrity_output,
      ledger_path:$summary.ledger_path,
      thresholds:{recurring_warn_last_24h:2,integrity_error:"beads_db_integrity_check_status != ok"},
      warnings:(if (($summary.beads_db_recovery_last_24h_count // 0) >= 2) then [{code:"beads_db_recovery_recurring",message:"two or more Beads DB recoveries in 24h"}] else [] end),
      errors:(if ($integrity.beads_db_integrity_check_status != "ok" and $integrity.beads_db_integrity_check_status != "missing_db") then [{code:"beads_db_integrity_check_failed",message:$integrity.integrity_output}] else [] end)}'
}

health_json() {
  local doc
  doc="$(doctor_json)"
  jq -c '{schema_version:"beads-db-recover.health.v1",command:"health",status:.status,repo:.repo,beads_db_integrity_check_status:.beads_db_integrity_check_status,beads_db_recovery_last_24h_count:.beads_db_recovery_last_24h_count}' <<<"$doc"
}

active_lock_reason() {
  local repo="$1"
  if [[ -e "$repo/.beads/.lock" ]]; then
    printf 'active_lock:%s\n' "$repo/.beads/.lock"
    return 0
  fi
  if command -v pgrep >/dev/null 2>&1 && pgrep -fl '(^|/)br([[:space:]]|$)' >/dev/null 2>&1; then
    pgrep -fl '(^|/)br([[:space:]]|$)' | head -3 | tr '\n' ';'
    return 0
  fi
  return 1
}

recovery_plan_json() {
  local repo="$1" integrity
  integrity="$(integrity_json "$repo")"
  jq -nc --arg repo "$repo" --arg ledger "$LEDGER" --argjson integrity "$integrity" '{
    schema_version:"beads-db-recover.plan.v1",
    command:"recover",
    dry_run:true,
    repo:$repo,
    ledger_path:$ledger,
    integrity_check_pre:$integrity.integrity_output,
    planned_actions:[
      "halt_check_no_active_beads_lock_or_br_process",
      "backup_.beads/beads.db",
      "probe_sqlite_integrity_check",
      "remove_db_wal_shm_and_br_init",
      "br_sync_import_only_rebuild_force_with_fk_orphan_tolerance",
      "sqlite_vacuum",
      "verify_integrity_check_ok",
      "br_ready_and_dep_cycles_smoke",
      "try_alternative_br_version_if_smoke_fails"
    ],
    would_write:[],
    would_delete:[],
    would_call_external:["br init","br sync --import-only --rebuild --force","sqlite3 VACUUM","br ready --json","br dep cycles --json"],
    blocked_by:[]
  }'
}

append_recovery_row() {
  local repo="$1" trigger="$2" backup="$3" step="$4" pre="$5" post="$6" fk="$7" brv="$8" success="$9" wall="${10}" reason="${11:-}"
  local row
  row="$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg repo "$repo" \
    --arg trigger "$trigger" \
    --arg backup_path "$backup" \
    --arg integrity_pre "$pre" \
    --arg integrity_post "$post" \
    --arg br_version_used "$brv" \
    --arg reason "$reason" \
    --argjson step_completed "$step" \
    --argjson fk_errors_count "$fk" \
    --argjson success "$success" \
    --argjson recovery_walltime_sec "$wall" \
    '{ts:$ts,repo:$repo,trigger:$trigger,backup_path:$backup_path,step_completed:$step_completed,integrity_check_pre:$integrity_pre,integrity_check_post:$integrity_post,fk_errors_count:$fk_errors_count,br_version_used:$br_version_used,success:$success,recovery_walltime_sec:$recovery_walltime_sec} + (if $reason != "" then {reason:$reason} else {} end)')"
  append_validated "$LEDGER" "$row"
}

run_cmd_capture() {
  local outfile="$1"; shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  return "$rc"
}

run_recovery() {
  local repo_abs_path db jsonl lock_reason pre_json pre backup="" start end wall brv trigger="openread_storage_cursor_root_page_unknown"
  local sync_out sync_rc sync_retry_out sync_retry_rc fk_errors=0 post post_json ready_out cycles_out step=0 rc=0 reason=""
  repo_abs_path="$(repo_abs "$REPO")"
  db="$repo_abs_path/.beads/beads.db"
  jsonl="$repo_abs_path/.beads/issues.jsonl"
  brv="$(br_version "$BR_BIN")"

  [[ -d "$repo_abs_path" ]] || { emit "$(jq -nc --arg repo "$repo_abs_path" '{schema_version:"beads-db-recover.run.v1",status:"fail",reason:"repo_missing",repo:$repo}')" "FAIL reason=repo_missing repo=$repo_abs_path" 1; return 1; }

  if [[ "$DRY_RUN" -eq 1 ]]; then
    emit "$(recovery_plan_json "$repo_abs_path")" "DRY-RUN repo=$repo_abs_path" 0
    return 0
  fi

  if [[ ! -s "$jsonl" ]]; then
    reason="no_jsonl_to_sync_from"
    append_recovery_row "$repo_abs_path" "$trigger" "" 0 "" "" 0 "$brv" false 0 "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,step_completed:0}')" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi

  if [[ "$FORCE" -ne 1 ]] && lock_reason="$(active_lock_reason "$repo_abs_path")"; then
    reason="active_lock"
    append_recovery_row "$repo_abs_path" "$trigger" "" 1 "" "" 0 "$brv" false 0 "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" --arg detail "$lock_reason" '{schema_version:"beads-db-recover.run.v1",status:"blocked",success:false,repo:$repo,reason:$reason,detail:$detail,step_completed:1}')" "BLOCKED reason=$reason detail=$lock_reason" 1
    return 1
  fi
  step=1

  if [[ ! -f "$db" ]]; then
    reason="no_db_to_backup"
    append_recovery_row "$repo_abs_path" "$trigger" "" "$step" "" "" 0 "$brv" false 0 "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,step_completed:1}')" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi

  start="$(date +%s)"
  backup="$repo_abs_path/.beads/beads.db.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp "$db" "$backup"
  step=2

  pre_json="$(integrity_json "$repo_abs_path")"
  pre="$(jq -r '.integrity_output' <<<"$pre_json")"
  step=3

  rm -f "$db" "$repo_abs_path/.beads/beads.db-wal" "$repo_abs_path/.beads/beads.db-shm"
  (cd "$repo_abs_path" && "$BR_BIN" init --force --json >/dev/null)
  step=4

  sync_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-sync.XXXXXX")"
  set +e
  (cd "$repo_abs_path" && "$BR_BIN" sync --import-only --rebuild --force --json) >"$sync_out" 2>&1
  sync_rc=$?
  set -e
  if [[ "$sync_rc" -ne 0 ]] && rg -qi 'foreign key|fk|orphan' "$sync_out"; then
    fk_errors="$(rg -ci 'foreign key|fk|orphan' "$sync_out" || printf '0')"
    sync_retry_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-sync-retry.XXXXXX")"
    set +e
    (cd "$repo_abs_path" && "$BR_BIN" sync --import-only --rebuild --force --orphans skip --json) >"$sync_retry_out" 2>&1
    sync_retry_rc=$?
    set -e
    cat "$sync_retry_out" >>"$sync_out"
    sync_rc="$sync_retry_rc"
  fi
  fk_errors="$(rg -ci 'foreign key|fk|orphan' "$sync_out" || printf '0')"
  if [[ "$sync_rc" -ne 0 ]]; then
    reason="sync_import_failed"
    end="$(date +%s)"; wall=$((end - start))
    append_recovery_row "$repo_abs_path" "$trigger" "$backup" 5 "$pre" "" "$fk_errors" "$brv" false "$wall" "$reason" || true
    emit "$(jq -Rs --arg repo "$repo_abs_path" --arg reason "$reason" --arg backup "$backup" --argjson fk "$fk_errors" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,backup_path:$backup,fk_errors_count:$fk,step_completed:5,sync_output:.}' <"$sync_out")" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi
  step=5

  sqlite3 "$db" 'VACUUM;'
  step=6

  post_json="$(integrity_json "$repo_abs_path")"
  post="$(jq -r '.integrity_output' <<<"$post_json")"
  if [[ "$post" != "ok" ]]; then
    reason="post_integrity_check_failed"
    end="$(date +%s)"; wall=$((end - start))
    append_recovery_row "$repo_abs_path" "$trigger" "$backup" 7 "$pre" "$post" "$fk_errors" "$brv" false "$wall" "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" --arg backup "$backup" --arg pre "$pre" --arg post "$post" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,backup_path:$backup,integrity_check_pre:$pre,integrity_check_post:$post,step_completed:7}')" "FAIL reason=$reason integrity=$post" 1
    return 1
  fi
  step=7

  ready_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-ready.XXXXXX")"
  cycles_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-cycles.XXXXXX")"
  run_cmd_capture "$ready_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$BR_BIN") ready --json" || rc=$?
  run_cmd_capture "$cycles_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$BR_BIN") dep cycles --json" || rc=$?
  if [[ "$rc" -ne 0 && -n "$ALT_BR_BIN" && -x "$ALT_BR_BIN" ]]; then
    brv="$(br_version "$ALT_BR_BIN")"
    run_cmd_capture "$ready_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$ALT_BR_BIN") ready --json" || rc=$?
    run_cmd_capture "$cycles_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$ALT_BR_BIN") dep cycles --json" || rc=$?
  fi
  if [[ "$rc" -ne 0 ]]; then
    reason="br_smoke_failed"
    end="$(date +%s)"; wall=$((end - start))
    append_recovery_row "$repo_abs_path" "$trigger" "$backup" 8 "$pre" "$post" "$fk_errors" "$brv" false "$wall" "$reason" || true
    emit "$(jq -Rs --arg repo "$repo_abs_path" --arg reason "$reason" --arg backup "$backup" --arg pre "$pre" --arg post "$post" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,backup_path:$backup,integrity_check_pre:$pre,integrity_check_post:$post,step_completed:8,smoke_output:.}' <"$ready_out")" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi
  step=9

  end="$(date +%s)"; wall=$((end - start))
  append_recovery_row "$repo_abs_path" "$trigger" "$backup" "$step" "$pre" "$post" "$fk_errors" "$brv" true "$wall"
  emit "$(jq -nc \
    --arg repo "$repo_abs_path" \
    --arg backup "$backup" \
    --arg ledger "$LEDGER" \
    --arg pre "$pre" \
    --arg post "$post" \
    --arg brv "$brv" \
    --argjson fk "$fk_errors" \
    --argjson wall "$wall" \
    '{schema_version:"beads-db-recover.run.v1",status:"pass",success:true,repo:$repo,backup_path:$backup,ledger_path:$ledger,step_completed:9,integrity_check_pre:$pre,integrity_check_post:$post,fk_errors_count:$fk,br_version_used:$brv,recovery_walltime_sec:$wall,actual_actions:["halt_check","backup","integrity_pre","reinit","jsonl_import","vacuum","integrity_post","br_ready_and_dep_cycles","alt_br_fallback_if_needed"]}')" \
    "PASS repo=$repo_abs_path backup=$backup"
}

contract_row_json() {
  jq -nc --arg ts "$(now_iso)" '{
    primitive_name:"beads-db-recover",
    declares_loop:"yes",
    self_repair_action:"recover --apply",
    measurement_field:"beads_db_recovery_last_24h_count",
    escalation_path:"doctor scope beads-db-recovery error -> fuckup-log:class=beads-db-corruption-recurring",
    schema_version:"substrate-loop-contract.v1",
    bootstrap_seed_v1:"see flywheel-jnc7a",
    ts:$ts
  }'
}

repair_contract() {
  local row
  row="$(contract_row_json)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    emit "$(jq -nc --argjson row "$row" '{schema_version:"beads-db-recover.repair.v1",command:"repair",scope:"substrate-contract",dry_run:true,would_write:[$row],actual_actions:[]}')" "DRY-RUN scope=substrate-contract" 0
    return 0
  fi
  append_validated "$CONTRACT_LEDGER" "$row"
  emit "$(jq -nc --arg ledger "$CONTRACT_LEDGER" --argjson row "$row" '{schema_version:"beads-db-recover.repair.v1",command:"repair",scope:"substrate-contract",dry_run:false,status:"pass",ledger_path:$ledger,actual_actions:["append_substrate_loop_contract_row"],row:$row}')" "PASS scope=substrate-contract ledger=$CONTRACT_LEDGER" 0
}

validate_json() {
  local repo_abs_path payload rc=0 jsonl_present=0
  repo_abs_path="$(repo_abs "$REPO")"
  case "$VALIDATE_TARGET" in
    repo)
      payload="$(integrity_json "$repo_abs_path")"
      if [[ -s "$repo_abs_path/.beads/issues.jsonl" ]]; then jsonl_present=1; else rc=1; fi
      jq -c --arg repo "$repo_abs_path" --argjson jsonl_present "$(json_bool "$jsonl_present")" \
        '. + {schema_version:"beads-db-recover.validate.v1",command:"validate",target:"repo",repo:$repo,jsonl_present:$jsonl_present}' <<<"$payload"
      return "$rc"
      ;;
    ledger)
      if [[ ! -f "$LEDGER" ]]; then
        jq -nc --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.validate.v1",command:"validate",target:"ledger",ledger_path:$ledger,status:"missing",parseable:true,row_count:0}'
        return 0
      fi
      jq -s -c --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.validate.v1",command:"validate",target:"ledger",ledger_path:$ledger,status:"pass",parseable:true,row_count:length}' "$LEDGER"
      ;;
    *)
      echo "ERR: unknown validate target: $VALIDATE_TARGET" >&2
      return 2 ;;
  esac
}

audit_json() {
  if [[ ! -f "$LEDGER" ]]; then
    jq -nc --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.audit.v1",command:"audit",ledger_path:$ledger,rows:[]}'
    return 0
  fi
  jq -s -c --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.audit.v1",command:"audit",ledger_path:$ledger,rows:(.[-20:] // [])}' "$LEDGER"
}

why_json() {
  if [[ ! -f "$LEDGER" ]]; then
    jq -nc --arg id "$WHY_ID" --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.why.v1",command:"why",id:$id,ledger_path:$ledger,match:null}'
    return 0
  fi
  jq -s -c --arg id "$WHY_ID" --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.why.v1",command:"why",id:$id,ledger_path:$ledger,match:(map(select((.repo // "" | contains($id)) or (.trigger // "" | contains($id)) or (.backup_path // "" | contains($id)))) | last // null)}' "$LEDGER"
}

info_json() {
  jq -nc --arg version "$VERSION" --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO" --arg ledger "$LEDGER" --arg contract "$CONTRACT_LEDGER" --arg br "$BR_BIN" --arg br_version "$(br_version "$BR_BIN")" --arg jsonl_append_lib "$JSONL_APPEND_LIB" \
    '{name:"beads-db-recover.sh",version:$version,schema_version:$schema_version,repo:$repo,ledger_path:$ledger,substrate_loop_contract_ledger:$contract,br_bin:$br,br_version:$br_version,jsonl_append_lib:$jsonl_append_lib,exit_codes:{"0":"success","1":"domain failure or doctor error","2":"usage error","3":"append primitive unavailable"},canonical_cli_surfaces:["doctor","health","repair","validate","audit","why","schema","--info","--examples","quickstart","help","completion"],mutation_requires:"--apply",force_gate:"--force bypasses halt check only"}'
}

examples_json() {
  jq -nc '{command:"examples",examples:[
    {name:"dry-run current repo",command:".flywheel/scripts/beads-db-recover.sh --repo /Users/josh/Developer/flywheel --dry-run --json"},
    {name:"apply after confirming backup",command:".flywheel/scripts/beads-db-recover.sh --repo /path/to/repo --apply --json"},
    {name:"doctor scope",command:"~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --scope beads-db-recovery --json"},
    {name:"append self-row",command:".flywheel/scripts/beads-db-recover.sh repair --scope substrate-contract --apply --json"},
    {name:"audit recoveries",command:".flywheel/scripts/beads-db-recover.sh audit --json"}
  ]}'
}

quickstart_json() {
  jq -nc '{command:"quickstart",status:"ok",steps:[
    "Run doctor to inspect current integrity and 24h recovery frequency.",
    "Run dry-run to see the planned backup/rebuild/import/vacuum sequence.",
    "Use --apply only on the affected repo after file reservations and no active br locks.",
    "Keep the backup path from the JSON output.",
    "Run audit or flywheel-loop doctor --scope beads-db-recovery after recovery."
  ]}'
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    recovery) jq -nc '{schema_version:"beads-db-recover.recovery.schema.v1",required:["repo","backup_path","step_completed","integrity_check_pre","integrity_check_post","fk_errors_count","br_version_used","success","recovery_walltime_sec"]}' ;;
    doctor) jq -nc '{schema_version:"beads-db-recover.doctor.schema.v1",required:["beads_db_recovery_last_24h_count","beads_db_recovery_last_ts","beads_db_integrity_check_status"]}' ;;
    ledger) jq -nc '{schema_version:"beads-db-recover.ledger.schema.v1",required:["ts","repo","trigger","backup_path","step_completed","integrity_check_pre","integrity_check_post","fk_errors_count","br_version_used","success","recovery_walltime_sec"]}' ;;
    contract) jq -nc '{schema_version:"substrate-loop-contract.v1",required:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version"]}' ;;
    *) echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2; return 2 ;;
  esac
}

completion() {
  if [[ -z "$COMPLETION_SHELL" || "$COMPLETION_SHELL" == "--help" || "$COMPLETION_SHELL" == "-h" ]]; then
    usage
    return 0
  fi
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_beads_db_recover_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--repo --dry-run --apply --force --json doctor --doctor health repair validate audit why schema --scope --info --examples quickstart help completion --watch --interval" -- "$cur") )
}
complete -F _beads_db_recover_completion beads-db-recover.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --repo --dry-run --apply --force --json doctor --doctor health repair validate audit why schema --scope --info --examples quickstart help completion --watch --interval\n'
      ;;
    *) echo "ERR: completion shell must be bash or zsh" >&2; return 2 ;;
  esac
}

help_json() {
  jq -nc --arg topic "$HELP_TOPIC" '{command:"help",topic:$topic,text:"Topics: recovery, doctor, repair, ledger. Recovery backs up .beads/beads.db, rebuilds from .beads/issues.jsonl, tolerates FK/orphan import fallout, vacuums, verifies integrity, and records a validated JSONL audit row."}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --force) FORCE=1; shift ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    --health|health) MODE="health"; shift ;;
    --repair|repair) MODE="repair"; shift ;;
    validate) MODE="validate"; VALIDATE_TARGET="${2:-repo}"; shift $(( $# >= 2 ? 2 : 1 )) ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; WHY_ID="${2:-}"; shift 2 ;;
    schema) MODE="schema"; SCHEMA_TOPIC="${2:-doctor}"; shift 2 ;;
    --scope) REPAIR_SCOPE="${2:-}"; shift 2 ;;
    --scope=*) REPAIR_SCOPE="${1#*=}"; shift ;;
    --watch) WATCH=1; shift ;;
    --interval|-i) WATCH_INTERVAL="${2:-5}"; shift 2 ;;
    --explain) EXPLAIN=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --no-color|--no-emoji) shift ;;
    --width) WIDTH="${2:-100}"; shift 2 ;;
    --info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help) MODE="help"; HELP_TOPIC="${2:-recovery}"; shift $(( $# >= 2 ? 2 : 1 )) ;;
    completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift $(( $# >= 2 ? 2 : 1 )) ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  recover) run_recovery ;;
  doctor)
    payload="$(doctor_json)"
    if [[ "$JSON_OUT" -eq 1 ]]; then printf '%s\n' "$payload"; else jq -r '"status=\(.status) beads_db_recovery_last_24h_count=\(.beads_db_recovery_last_24h_count) beads_db_integrity_check_status=\(.beads_db_integrity_check_status)"' <<<"$payload"; fi
    [[ "$(jq -r '.status' <<<"$payload")" != "error" ]]
    ;;
  health)
    if [[ "$WATCH" -eq 1 ]]; then
      while true; do health_json; sleep "$WATCH_INTERVAL"; done
    else
      payload="$(health_json)"
      if [[ "$JSON_OUT" -eq 1 ]]; then printf '%s\n' "$payload"; else jq -r '"status=\(.status) integrity=\(.beads_db_integrity_check_status)"' <<<"$payload"; fi
    fi
    ;;
  repair)
    case "$REPAIR_SCOPE" in
      openread|recovery|beads-db-recovery) run_recovery ;;
      substrate-contract) repair_contract ;;
      all)
        repair_contract
        ;;
      *) echo "ERR: unknown repair scope: $REPAIR_SCOPE" >&2; exit 2 ;;
    esac
    ;;
  validate) validate_json ;;
  audit) audit_json ;;
  why) why_json ;;
  schema) schema_json ;;
  info) info_json ;;
  examples) examples_json ;;
  quickstart) quickstart_json ;;
  help) if [[ "$JSON_OUT" -eq 1 ]]; then help_json; else jq -r '.text' <<<"$(help_json)"; fi ;;
  completion) completion ;;
  *) echo "ERR: unknown mode: $MODE" >&2; exit 2 ;;
esac
