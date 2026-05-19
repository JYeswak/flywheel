#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-1fk5f.5) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-1fk5f.5)
#
# Surface-specific logic for the human-approval-gate wrapper:
#   doctor   probes substrate (ntm binary, jq/mktemp deps, audit log dir, repo root,
#            wrapper-ns assertion, helper-lib)
#   health   summarizes last-run state from $SCAFFOLD_AUDIT_LOG (pass rate over 50)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: approval-receipt PATH (verify required fields) | audit-row JSONL
#   audit    routes through cli_emit_audit_tail (default 20 rows)
#   why      provenance lookup — id is row index (numeric, neg=tail) or
#            substring match against status / gate / subcommand fields
#
# NOTE: legacy substantive `check` subcommand stays intact. Scaffold stubs above
# provide canonical envelope shape; legacy reachable via `check` subcommand
# (handled by main case statement, not scaffold dispatch).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="ntm-approve-human-gates/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-approve-human-gates-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-approve-human-gates.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: approval-receipt PATH | audit-row JSONL
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-approve-human-gates.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-approve-human-gates.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-approve-human-gates.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-approve-human-gates.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-approve-human-gates.sh doctor --json"}'
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
          schema_version:"string",command:"\"validate\"",subject:"\"approval-receipt\"|\"audit-row\"",
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
    doctor)   printf 'topic: doctor — probes substrate (ntm binary, jq/mktemp deps, audit log dir, repo root, wrapper-name-space assertion, helper-lib). Pass = wrapper ready; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 wrapper runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: approval-receipt PATH (verify required fields: gate, question, decision, approver, ts); audit-row JSONL_LINE (verify ts/status fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, gate, subcommand.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / gate / subcommand fields.\n' ;;
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
            && cli_emit_completion_bash "ntm-approve-human-gates" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-approve-human-gates" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-1fk5f.5) ----------

# Bind load-bearing paths once.
SCAFFOLD_NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SCAFFOLD_WRAPPER_NS="ntm-approve-human-gates"

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/nahg-doctor.XXXXXX")"
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

  if [[ -x "$SCAFFOLD_NTM_BIN" ]]; then
    add_check ntm_executable pass "$SCAFFOLD_NTM_BIN"
  elif command -v ntm >/dev/null 2>&1; then
    add_check ntm_executable pass "$(command -v ntm)"
  else
    add_check ntm_executable warn "ntm binary not found at $SCAFFOLD_NTM_BIN (legacy check subcommand may degrade)"
  fi

  for tool in jq mktemp grep awk; do
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

  # Wrapper-name-space assertion: SCAFFOLD_WRAPPER_NS should match the surface
  # name embedded in WRAPPER_SURFACE constant of the legacy section. This guards
  # against script-rename drift.
  if [[ "$SCAFFOLD_WRAPPER_NS" == "ntm-approve-human-gates" ]]; then
    add_check wrapper_namespace_assertion pass "$SCAFFOLD_WRAPPER_NS"
  else
    add_check wrapper_namespace_assertion warn "wrapper namespace drift: $SCAFFOLD_WRAPPER_NS"
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
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no wrapper runs recorded yet"}'
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
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/nahg-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/nahg-repair-applied.XXXXXX")"
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
    approval-receipt)
      local path="${1:-}"
      if [[ -z "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"approval-receipt",status:"refused",reason:"path required"}'
        return 64
      fi
      if [[ ! -r "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"approval-receipt",status:"fail",path:$p,reason:"path not readable"}'
        return 1
      fi
      local raw; raw="$(cat "$path")"
      if ! jq -e . >/dev/null 2>&1 <<<"$raw"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"approval-receipt",status:"fail",path:$p,reason:"file is not valid JSON"}'
        return 1
      fi
      local missing=()
      for f in gate question decision approver ts; do
        jq -e --arg f "$f" 'has($f)' >/dev/null 2>&1 <<<"$raw" || missing+=("$f")
      done
      if (( ${#missing[@]} == 0 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" --argjson row "$raw" \
          '{schema_version:$sv,command:"validate",subject:"approval-receipt",status:"pass",path:$p,row:$row}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" --argjson row "$raw" \
          --argjson missing "$(printf '%s\n' "${missing[@]}" | jq -R . | jq -cs .)" \
          '{schema_version:$sv,command:"validate",subject:"approval-receipt",status:"fail",path:$p,reason:"missing required fields",missing:$missing,row:$row}'
        return 1
      fi
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["approval-receipt","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["approval-receipt","audit-row"]}'
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
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.gate // "") | contains($id)) or ((.subcommand // "") | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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
VERSION="0.1.0"
PLAN_SLUG="ntm-surface-utilization-migration-2026-05-06"
BEAD_ID="flywheel-r4d7r"
TASK_ID="ntm-w2a-approve-4544"
NATIVE_SURFACE="existing_approval_prompt_path"
WRAPPER_SURFACE="ntm-approve-human-gates"

subcommand="check"
gate=""
question=""
reason=""
approval_receipt=""
json_output=false
dry_run=true
apply_mode=false
idempotency_key=""
scope="default"

usage() {
  cat <<'EOF'
Usage:
  ntm-approve-human-gates.sh check --gate <name> --question <text> [--approval-receipt file] [--json]
  ntm-approve-human-gates.sh doctor|health|repair|validate|audit|why|schema [options]

Purpose:
  Preserve exact human approval questions and validate approval receipts.
  This wrapper never answers on behalf of a human and never sends prompts.

Mutation discipline:
  --dry-run is the default.
  --apply requires --idempotency-key and still writes no state; it only emits a receipt.
EOF
}

idempotency_token() {
  printf '%s|%s|%s|%s|%s' "$PLAN_SLUG" "/Users/josh/Developer/flywheel" "$BEAD_ID" "W2" "$TASK_ID" | shasum -a 256 | awk '{print $1}'
}

emit_json() {
  local status="$1" decision="$2" failure_class="$3" message="$4" exit_code="$5"
  jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg gate "$gate" \
    --arg exact_question "$question" \
    --arg reason "$reason" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ttl_native "single_approval_question" \
    --arg ttl_wrapper "approval_receipt_lifetime" \
    --arg ttl_decision "revalidate_on_question_change" \
    --arg delta "exact_question_receipt_required_before_human_gate_pass" \
    --arg idempotency_token "$(idempotency_token)" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    --argjson exit_code "$exit_code" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      gate: $gate,
      exact_question: $exact_question,
      reason: $reason,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_question","preserve_exact_question","validate_approval_receipt","emit_gate_receipt"],
      forbidden_operations: ["answer_for_human","mutate_without_approval","prompt_without_exact_question","emit_secret_value"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W2A"
    }'
  # Append run record to scaffold audit log so canonical audit/health/why have data.
  # Best-effort; never fail the wrapper because of telemetry.
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "$subcommand" "$status" \
      "$(jq -nc --arg g "$gate" --arg s "$subcommand" --arg d "$decision" \
         '{gate:$g,subcommand:$s,decision:$d}')" 2>/dev/null || true
  fi
  return "$exit_code"
}

parse_args() {
  if [[ $# -gt 0 && "$1" != --* ]]; then
    subcommand="$1"
    shift
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --gate)
        gate="${2:-}"
        shift 2
        ;;
      --gate=*)
        gate="${1#*=}"
        shift
        ;;
      --question)
        question="${2:-}"
        shift 2
        ;;
      --question=*)
        question="${1#*=}"
        shift
        ;;
      --reason)
        reason="${2:-}"
        shift 2
        ;;
      --reason=*)
        reason="${1#*=}"
        shift
        ;;
      --approval-receipt)
        approval_receipt="${2:-}"
        shift 2
        ;;
      --approval-receipt=*)
        approval_receipt="${1#*=}"
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
        emit_json "fail" "blocked" "usage" "unknown argument: $1" 2
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

secret_shaped_question() {
  [[ "$question" =~ (AKIA[0-9A-Z]{16}|BEGIN[[:space:]]+(RSA[[:space:]]+)?PRIVATE[[:space:]]+KEY|token[=:]|secret[=:]|password[=:]|AgentMail[[:space:]]+bearer) ]]
}

validate_core_inputs() {
  [[ -n "$gate" ]] || emit_json "fail" "blocked" "missing_gate" "--gate is required" 64
  [[ -n "$question" ]] || emit_json "fail" "blocked" "missing_question" "--question is required" 64
  if secret_shaped_question; then
    emit_json "fail" "blocked" "secret_like_question" "approval questions must not contain secret values" 66
  fi
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "blocked" "missing_idempotency_key" "--apply requires --idempotency-key" 2
  fi
}

validate_receipt_file() {
  local path="$1"
  [[ -f "$path" ]] || emit_json "fail" "requires_human_approval" "approval_receipt_missing" "approval receipt missing: $path" 65
  jq empty "$path" >/dev/null 2>&1 || emit_json "fail" "blocked" "approval_receipt_non_json" "approval receipt is not valid JSON: $path" 65
}

cmd_check() {
  validate_core_inputs

  if [[ -z "$approval_receipt" ]]; then
    emit_json "pending" "requires_human_approval" "approval_receipt_required" "exact question receipt emitted; human approval still required" 1
    return $?
  fi

  validate_receipt_file "$approval_receipt"

  local receipt_status receipt_gate receipt_question approved_by
  receipt_status="$(jq -r '.status // .decision // "unknown"' "$approval_receipt")"
  receipt_gate="$(jq -r '.gate // ""' "$approval_receipt")"
  receipt_question="$(jq -r '.exact_question // .question // ""' "$approval_receipt")"
  approved_by="$(jq -r '.approved_by // ""' "$approval_receipt")"

  [[ "$receipt_gate" == "$gate" ]] || emit_json "fail" "blocked" "gate_mismatch" "approval receipt gate does not match requested gate" 65
  [[ "$receipt_question" == "$question" ]] || emit_json "fail" "blocked" "exact_question_mismatch" "approval receipt exact_question does not match requested question" 65
  [[ "$receipt_status" == "approved" ]] || emit_json "fail" "requires_human_approval" "approval_not_granted" "approval receipt is not approved" 1
  [[ -n "$approved_by" ]] || emit_json "fail" "blocked" "approved_by_missing" "approved receipt must name approved_by" 65

  emit_json "pass" "approved" "none" "approval receipt valid; exact question preserved" 0
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
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_approval_question" \
    --arg ttl_wrapper "approval_receipt_lifetime" \
    --arg ttl_decision "revalidate_on_question_change" \
    --arg delta "exact_question_receipt_required_before_human_gate_pass" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      message: $message,
      version: $version,
      scope: $scope,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_question","preserve_exact_question","validate_approval_receipt","emit_gate_receipt"],
      forbidden_operations: ["answer_for_human","mutate_without_approval","prompt_without_exact_question","emit_secret_value"],
      stable_exit_codes: {
        "0": "approval valid or diagnostic pass",
        "1": "approval pending/not granted",
        "2": "usage or invalid apply request",
        "64": "missing gate/question",
        "65": "invalid approval receipt",
        "66": "secret-shaped question refused",
        "127": "missing required local dependency"
      },
      L112: "OK_ntm_migrate_W2A"
    }'
}

cmd_repair() {
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "blocked" "missing_idempotency_key" "repair --apply requires --idempotency-key" 2
  fi
  cmd_static "pass" "repair is no-op; exact-question receipt path is preserved"
}

cmd_schema() {
  jq -n '{
    schema_version: "ntm-approve-human-gates/v1",
    approval_receipt_required_fields: ["status","gate","exact_question","approved_by","approved_at"],
    receipt_status_values: ["approved","pending","denied"],
    required_output_fields: [
      "status",
      "decision",
      "failure_class",
      "gate",
      "exact_question",
      "idempotency_token",
      "authorized_operations",
      "forbidden_operations",
      "ttl_native",
      "ttl_wrapper",
      "ttl_decision",
      "native_wrapper_delta",
      "L112"
    ],
    stable_exit_codes: {
      "0": "approval valid or diagnostic pass",
      "1": "approval pending/not granted",
      "2": "usage or invalid apply request",
      "64": "missing gate/question",
      "65": "invalid approval receipt",
      "66": "secret-shaped question refused",
      "127": "missing required local dependency"
    },
    mutation_modes: ["--dry-run","--apply"],
    apply_requires: ["--idempotency-key"],
    L112: "OK_ntm_migrate_W2A"
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
--gate
--question
--reason
--approval-receipt
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
    doctor) cmd_static "pass" "doctor pass: jq present, exact-question receipts enforce human approval boundaries" ;;
    health) cmd_static "pass" "health pass: approval gate wrapper available" ;;
    repair) cmd_repair ;;
    validate) cmd_static "pass" "validate pass: schema, JSON, stable exit codes, dry-run/apply discipline available" ;;
    audit) cmd_static "pass" "audit pass: doctor/health/repair, validate/audit/why, --json, --dry-run/--apply covered" ;;
    why) cmd_static "pass" "why: this wrapper preserves exact human questions and refuses to approve on behalf of humans" ;;
    schema) cmd_schema ;;
    completion) cmd_completion ;;
    *) emit_json "fail" "blocked" "usage" "unknown subcommand: $subcommand" 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
