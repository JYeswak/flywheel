#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-tfgt3) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-tfgt3)
#
# This block is APPENDED by scaffold-canonical-cli.sh and FILLED IN by
# flywheel-tfgt3 with surface-specific logic for dispatch-author-contract-probe:
#   doctor   probes substrate (helper-lib, jq/awk/grep, audit log dir, repo root)
#   health   summarizes last-run state from audit log (run count, pass rate)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: dispatch-packet PATH | audit-row JSONL
#   audit    tails $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail
#   why      provenance lookup — id matches dispatch_path or row index in audit log

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-author-contract-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-author-contract-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-author-contract-probe.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: dispatch-packet PATH | audit-row JSONL
  audit [--json] [N]       tail $SCAFFOLD_AUDIT_LOG (default 20 rows)
  why <id>                 provenance: id is dispatch_path (substring match) or row index
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-author-contract-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-author-contract-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-author-contract-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-author-contract-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-author-contract-probe.sh doctor --json"}'
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
          total_runs:"int",last_run_ts:"string|null",last_verdict:"string|null",
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
          schema_version:"string",command:"\"validate\"",subject:"\"dispatch-packet\"|\"audit-row\"",
          status:"\"pass\"|\"fail\"",detail:"object"}}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"audit\"",status:"\"pass\"|\"empty\"|\"missing\"",
          row_count:"int",recent:"[obj]"}}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"why\"",id:"string",match_count:"int",
          matches:"[{ts,verdict,dispatch_path,checks}]"}}' ;;
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
    doctor)   printf 'topic: doctor — probes substrate (helper-lib loaded, jq/awk/grep on PATH, audit-log dir writable, repo root resolved). Pass = all green; warn = recoverable (use repair); fail = blocked (probe will not run).\n' ;;
    health)   printf 'topic: health — summarizes last 50 runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_verdict, pass_rate. status=empty when log absent or zero rows.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: dispatch-packet PATH (run probe in dry mode and report verdict), audit-row JSONL_LINE (verify schema_version + required fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, dispatch_path, verdict.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = dispatch_path substring OR row index (1-based, negative = from end). Emits provenance row(s).\n' ;;
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
            && cli_emit_completion_bash "dispatch-author-contract-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-author-contract-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-tfgt3) ----------

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/dacp-doctor.XXXXXX")"
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

  if [[ -r "$_SCAFFOLD_HELPER_LIB" ]] && command -v cli_emit_info >/dev/null 2>&1; then
    add_check helper_lib_loaded pass "$_SCAFFOLD_HELPER_LIB"
  elif [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
    add_check helper_lib_loaded warn "readable but cli_emit_info absent: $_SCAFFOLD_HELPER_LIB"
  else
    add_check helper_lib_loaded fail "missing: $_SCAFFOLD_HELPER_LIB"
  fi

  for tool in jq awk grep; do
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
    add_check repo_root_resolved fail "did not resolve to a directory: $_SCAFFOLD_REPO_ROOT"
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
  local window=50 total_runs=0 last_run_ts="" last_verdict="" pass_count=0 status="pass"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson w "$window" \
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_verdict:null,pass_rate:null,window:$w,note:"audit log absent — no runs recorded yet"}'
    return 0
  fi
  total_runs="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
  [[ -z "$total_runs" ]] && total_runs=0
  if [[ "$total_runs" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson w "$window" \
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_verdict:null,pass_rate:null,window:$w}'
    return 0
  fi
  last_run_ts="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.ts // ""' 2>/dev/null)"
  last_verdict="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.verdict // .status // "unknown"' 2>/dev/null)"
  pass_count="$(tail -n "$window" "$SCAFFOLD_AUDIT_LOG" | jq -s '[.[] | select((.verdict // .status) == "pass")] | length' 2>/dev/null)"
  [[ -z "$pass_count" ]] && pass_count=0
  local sample
  if [[ "$total_runs" -lt "$window" ]]; then sample="$total_runs"; else sample="$window"; fi
  local pass_rate="null"
  if [[ "$sample" -gt 0 ]]; then
    pass_rate="$(awk -v p="$pass_count" -v s="$sample" 'BEGIN{printf "%.4f", p/s}')"
  fi
  if [[ "$last_verdict" == "fail" ]]; then status="warn"; fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg status "$status" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson total "$total_runs" \
    --arg last_ts "$last_run_ts" \
    --arg last_v "$last_verdict" \
    --argjson rate "$pass_rate" \
    --argjson w "$sample" \
    '{schema_version:$sv,command:"health",status:$status,ts:$ts,total_runs:$total,last_run_ts:(if $last_ts=="" then null else $last_ts end),last_verdict:(if $last_v=="" then null else $last_v end),pass_rate:$rate,window:$w}'
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
  # Apply-contract gate runs first so missing --idempotency-key wins rc=3
  # regardless of scope validity (canonical-cli refusal hierarchy).
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  # Unknown / missing scope returns rc=0 with structured envelope; the scope
  # field surfaces the bad value and valid_scopes documents the contract.
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
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/dacp-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/dacp-repair-applied.XXXXXX")"
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
    dispatch-packet)
      local path="${1:-}"
      if [[ -z "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"dispatch-packet",status:"refused",reason:"path required"}'
        return 64
      fi
      if [[ ! -r "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"dispatch-packet",status:"fail",path:$p,reason:"path not readable"}'
        return 1
      fi
      local probe_out probe_rc=0
      probe_out="$("$0" --json "$path" 2>/dev/null)" || probe_rc=$?
      local verdict
      verdict="$(jq -r '.verdict // "unknown"' <<<"$probe_out" 2>/dev/null)"
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg p "$path" \
        --arg verdict "$verdict" \
        --argjson rc "$probe_rc" \
        --argjson detail "${probe_out:-null}" \
        '{schema_version:$sv,command:"validate",subject:"dispatch-packet",status:(if $verdict=="pass" then "pass" else "fail" end),path:$p,verdict:$verdict,probe_exit_code:$rc,detail:$detail}'
      [[ "$verdict" == "pass" ]]
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
      for f in ts action status; do
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["dispatch-packet","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["dispatch-packet","audit-row"]}'
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
    printf 'ERR: why requires <id> argument (dispatch_path substring or row index)\n' >&2; return 64
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
    matches="$(jq -cs --arg id "$id" '[.[] | select((.dispatch_path // "") | contains($id))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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
VERSION="dispatch-author-skill-routing-contract/v1"
MAX_SKILLS=10
JSON_OUT=0
QUIET=0
MODE=probe
DISPATCH_PATH=""

usage() {
  cat <<'USAGE'
usage: dispatch-author-contract-probe.sh [--json] [--quiet] [--max-skills N] --dispatch PATH
       dispatch-author-contract-probe.sh [--json] [--quiet] [--max-skills N] PATH
       dispatch-author-contract-probe.sh --info|--help|--examples [--json]
USAGE
}

info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" '{
      name:"dispatch-author-contract-probe",
      schema_version:$version,
      canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
      checks:["deterministic_class_merge","discovery_precedence","required_overlays","secret_value_bans","route_receipts_schema","prompt_budget_within_limit"],
      verdicts:["pass","partial","fail"]
    }'
  else
    printf '%s\n' \
      "name=dispatch-author-contract-probe" \
      "schema=$VERSION" \
      "verbs=--info,--help,--examples,--json,--quiet" \
      "verdicts=pass,partial,fail"
  fi
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "dispatch-author-contract-probe.sh --json /tmp/dispatch.md",
      "dispatch-author-contract-probe.sh --dispatch /tmp/dispatch.md --quiet",
      "dispatch-author-contract-probe.sh --max-skills 12 --json /tmp/dispatch.md"
    ]}'
  else
    printf '%s\n' \
      "dispatch-author-contract-probe.sh --json /tmp/dispatch.md" \
      "dispatch-author-contract-probe.sh --dispatch /tmp/dispatch.md --quiet" \
      "dispatch-author-contract-probe.sh --max-skills 12 --json /tmp/dispatch.md"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --max-skills) MAX_SKILLS="${2:?--max-skills requires N}"; shift 2 ;;
    --max-skills=*) MAX_SKILLS="${1#*=}"; shift ;;
    --dispatch|--file) DISPATCH_PATH="${2:?--dispatch requires PATH}"; shift 2 ;;
    --dispatch=*|--file=*) DISPATCH_PATH="${1#*=}"; shift ;;
    --info) MODE=info; shift ;;
    --examples) MODE=examples; shift ;;
    --help|-h) usage; exit 0 ;;
    --*) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) DISPATCH_PATH="$1"; shift ;;
  esac
done

case "$MODE" in
  info) info; exit 0 ;;
  examples) examples; exit 0 ;;
esac

[[ "$MAX_SKILLS" =~ ^[0-9]+$ ]] || { printf 'ERR --max-skills must be numeric\n' >&2; exit 2; }
[[ -n "$DISPATCH_PATH" && -r "$DISPATCH_PATH" ]] || { usage >&2; exit 2; }

BODY="$(cat "$DISPATCH_PATH")"
TMP_CHECKS="$(mktemp "${TMPDIR:-/tmp}/dispatch-author-contract-checks.XXXXXX")"
TMP_VIOLATIONS="$(mktemp "${TMPDIR:-/tmp}/dispatch-author-contract-violations.XXXXXX")"
trap 'rm -f "$TMP_CHECKS" "$TMP_VIOLATIONS"' EXIT
: >"$TMP_CHECKS"
: >"$TMP_VIOLATIONS"

has_fixed() { grep -Fqi -- "$1" <<<"$BODY"; }
has_regex() { grep -Eqi -- "$1" <<<"$BODY"; }
check() {
  jq -nc --arg name "$1" --arg status "$2" --arg detail "$3" \
    '{name:$name,status:$status,detail:$detail}' >>"$TMP_CHECKS"
}
violation() {
  jq -nc --arg code "$1" --arg severity "$2" --arg check "$3" \
    --arg detail "$4" --arg recommendation "$5" \
    '{code:$code,severity:$severity,check:$check,detail:$detail,recommendation:$recommendation}' >>"$TMP_VIOLATIONS"
}

if has_fixed "collision_policy=unresolved"; then
  check deterministic_class_merge fail "class collision is marked unresolved"
  violation "class_collision_unresolved" error deterministic_class_merge "collision_policy=unresolved" "run dispatch-skill-router-collision-resolver.sh and preserve its collision receipt"
elif has_fixed "dispatch_class_merge_order" && has_fixed "strictest_invariant_wins=true" && has_fixed "collision_policy=resolved"; then
  check deterministic_class_merge pass "merge order and resolved collision policy present"
else
  check deterministic_class_merge fail "missing merge order, resolved collision policy, or strictest-invariant marker"
  violation "deterministic_class_merge_missing" error deterministic_class_merge "required class-merge markers are missing" "add dispatch_class_merge_order, collision_policy=resolved, and strictest_invariant_wins=true"
fi

expected_precedence="exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem"
if has_fixed "$expected_precedence"; then
  check discovery_precedence pass "canonical precedence order present"
else
  check discovery_precedence fail "canonical precedence order missing or reversed"
  violation "discovery_precedence_invalid" error discovery_precedence "source precedence is not canonical" "use exact/local before semantic, external install-only, then rg fallback"
fi

missing_overlays=()
for token in canonical-cli-scoping readme-writing de-slopify simplify socraticode agent-mail agent-monitoring cost-attribution search-tool-routing-doctrine; do
  has_fixed "$token" || missing_overlays+=("$token")
done
if ((${#missing_overlays[@]} == 0)); then
  check required_overlays pass "universal and cross-cutting overlays represented"
else
  check required_overlays fail "missing required overlays"
  violation "required_overlay_missing" error required_overlays "one or more required overlay tokens are absent" "represent every universal and cross-cutting overlay with applied, alias, skip, or not-applicable receipt"
fi

secret_regex='(sk-ant-[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{20,}|xai-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{35}|Bearer[[:space:]]+[A-Za-z0-9._-]{20,}|registration_token[=:][A-Za-z0-9._-]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{20,})'
if ! has_fixed "secret_values_allowed=false"; then
  check secret_value_bans fail "secret_values_allowed=false marker missing"
  violation "secret_value_ban_missing" error secret_value_bans "packet does not declare secret values forbidden" "add secret_values_allowed=false"
elif has_regex "$secret_regex"; then
  check secret_value_bans fail "secret-shaped literal detected"
  violation "secret_value_literal_present" error secret_value_bans "packet contains a forbidden secret-shaped value" "replace literal values with secret class, key name, vault path, or redacted evidence"
else
  check secret_value_bans pass "secret-value ban present and no secret-shaped literal detected"
fi

missing_receipt=()
for token in route_receipt_schema_version skill_routing "skill_receipts[]" receipt_identity_key skill source action_taken policy_version evidence alias_of not_applicable_reason idempotency_key replay_detection_hash transaction_boundary receipt_completeness; do
  has_fixed "$token" || missing_receipt+=("$token")
done
if ((${#missing_receipt[@]} == 0)); then
  check route_receipts_schema pass "route receipt fields present"
else
  check route_receipts_schema fail "route receipt schema fields missing"
  violation "route_receipt_schema_malformed" error route_receipts_schema "one or more route receipt fields are absent" "include dispatch-author-route-receipt/v1 and Wave 1 dispatch-receipt identity fields"
fi

skill_count="$(awk -F: 'tolower($1)=="selected_skill_count"{gsub(/[[:space:]]/,"",$2); print $2}' "$DISPATCH_PATH" | tail -n 1)"
[[ "$skill_count" =~ ^[0-9]+$ ]] || skill_count=0
if ! has_fixed "prompt_budget_policy"; then
  check prompt_budget_within_limit fail "prompt budget policy missing"
  violation "prompt_budget_policy_missing" error prompt_budget_within_limit "packet lacks prompt budget policy" "add names-plus-one-line-why policy and excerpt cap"
elif (( skill_count > MAX_SKILLS )); then
  check prompt_budget_within_limit fail "selected skill count exceeds budget"
  violation "prompt_budget_exceeded" warn prompt_budget_within_limit "selected skill count exceeds max-skills" "prune secondary excerpts to paths and keep only risk-bearing excerpts"
else
  check prompt_budget_within_limit pass "prompt budget policy present and skill count within limit"
fi

checks_json="$(jq -s 'map({(.name): {status:.status, detail:.detail}}) | add' "$TMP_CHECKS")"
violations_json="$(jq -s '.' "$TMP_VIOLATIONS")"
if jq -e 'any(.[]; .severity == "error")' >/dev/null <<<"$violations_json"; then
  verdict=fail
elif jq -e 'any(.[]; .severity == "warn")' >/dev/null <<<"$violations_json"; then
  verdict=partial
else
  verdict=pass
fi

payload="$(jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg path "$DISPATCH_PATH" --arg schema "$VERSION" --arg verdict "$verdict" \
  --argjson checks "$checks_json" --argjson violations "$violations_json" \
  '{schema_version:$schema,ts:$ts,dispatch_path:$path,checks:$checks,verdict:$verdict,violations:$violations}')"

if [[ "$QUIET" -eq 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 || "$MODE" == probe ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"verdict=\(.verdict) violations=\(.violations|length)"' <<<"$payload"
  fi
fi

# Append run record to audit log so audit/health/why subcommands have data.
# Best-effort; never fail the probe because of telemetry.
if command -v cli_audit_append >/dev/null 2>&1; then
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "probe" "$verdict" \
    "$(jq -nc --arg p "$DISPATCH_PATH" --arg v "$verdict" \
       --argjson vc "$(jq 'length' <<<"$violations_json")" \
       '{dispatch_path:$p,verdict:$v,violation_count:$vc}')" 2>/dev/null || true
fi

[[ "$verdict" != fail ]]

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
