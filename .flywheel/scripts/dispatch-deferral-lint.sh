#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-bqvpa) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-bqvpa)
#
# Surface-specific logic for the dispatch-deferral lint
# (rejects question-shaped dispatch drafts when data already selects an action):
#   doctor   probes substrate (ntm/br/bv binaries, DOCTOR_BIN, BV_READINESS_PROBE,
#            jq/awk/grep, audit log dir writability, repo root)
#   health   summarizes last-run state from $SCAFFOLD_AUDIT_LOG (pass rate over 50)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: dispatch-draft PATH (run lint, report verdict) | audit-row JSONL
#   audit    routes through cli_emit_audit_tail (default 20 rows)
#   why      provenance lookup — id is row index (numeric, neg=tail) or
#            substring match against fail_reason / verdict / draft_path

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-deferral-lint/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-deferral-lint-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-deferral-lint.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: dispatch-draft PATH | audit-row JSONL
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-deferral-lint.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-deferral-lint.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-deferral-lint.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-deferral-lint.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-deferral-lint.sh doctor --json"}'
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
          schema_version:"string",command:"\"validate\"",subject:"\"dispatch-draft\"|\"audit-row\"",
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
    doctor)   printf 'topic: doctor — probes lint substrate (ntm/br/bv binaries, flywheel-loop doctor, bv-readiness-probe sister, jq/awk/grep, audit log dir, repo root). Pass = lint can run; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 lint runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: dispatch-draft PATH (run lint, report verdict + fail_reason); audit-row JSONL_LINE (verify ts/verdict fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, draft_path, verdict, fail_reason.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against fail_reason / verdict / draft_path.\n' ;;
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
            && cli_emit_completion_bash "dispatch-deferral-lint" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-deferral-lint" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-bqvpa) ----------

# Bind load-bearing paths once. Mirror the legacy globals declared below the
# scaffold END marker; the scaffold layer cannot read those directly because
# the early-dispatch intercept short-circuits before they're set.
SCAFFOLD_NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SCAFFOLD_BR_BIN="${BR_BIN:-/Users/josh/.cargo/bin/br}"
SCAFFOLD_BV_BIN="${BV_BIN:-/opt/homebrew/bin/bv}"
SCAFFOLD_DOCTOR_BIN="${DOCTOR_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
SCAFFOLD_BV_READINESS_PROBE="${BV_READINESS_PROBE:-$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/bv-readiness-probe.sh}"

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/ddl-doctor.XXXXXX")"
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

  for pair in "ntm:$SCAFFOLD_NTM_BIN" "br:$SCAFFOLD_BR_BIN" "bv:$SCAFFOLD_BV_BIN" "flywheel_loop:$SCAFFOLD_DOCTOR_BIN"; do
    local name="${pair%%:*}" path="${pair#*:}"
    if [[ -x "$path" ]]; then
      add_check "${name}_executable" pass "$path"
    elif [[ -f "$path" ]]; then
      add_check "${name}_executable" warn "exists but not executable: $path"
    else
      add_check "${name}_executable" warn "missing: $path"
    fi
  done

  if [[ -x "$SCAFFOLD_BV_READINESS_PROBE" ]]; then
    add_check bv_readiness_probe_executable pass "$SCAFFOLD_BV_READINESS_PROBE"
  elif [[ -f "$SCAFFOLD_BV_READINESS_PROBE" ]]; then
    add_check bv_readiness_probe_executable warn "exists but not executable: $SCAFFOLD_BV_READINESS_PROBE"
  else
    add_check bv_readiness_probe_executable warn "sister probe missing: $SCAFFOLD_BV_READINESS_PROBE"
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
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no lint runs recorded yet"}'
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
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/ddl-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/ddl-repair-applied.XXXXXX")"
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
    dispatch-draft)
      local path="${1:-}"
      if [[ -z "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"dispatch-draft",status:"refused",reason:"path required"}'
        return 64
      fi
      if [[ ! -r "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"dispatch-draft",status:"fail",path:$p,reason:"path not readable"}'
        return 1
      fi
      local lint_out lint_rc=0
      lint_out="$("$0" --draft "$path" --json 2>/dev/null)" || lint_rc=$?
      local verdict reason
      verdict="$(jq -r '.status // "unknown"' <<<"$lint_out" 2>/dev/null)"
      reason="$(jq -r '.reason // ""' <<<"$lint_out" 2>/dev/null)"
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg p "$path" \
        --arg verdict "$verdict" \
        --arg reason "$reason" \
        --argjson rc "$lint_rc" \
        --argjson detail "${lint_out:-null}" \
        '{schema_version:$sv,command:"validate",subject:"dispatch-draft",status:(if $verdict=="pass" then "pass" else "fail" end),path:$p,verdict:$verdict,fail_reason:(if $reason=="" then null else $reason end),lint_exit_code:$rc,detail:$detail}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["dispatch-draft","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["dispatch-draft","audit-row"]}'
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
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.fail_reason // "") | contains($id)) or ((.verdict // "") | contains($id)) or ((.draft_path // "") | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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
VERSION="dispatch-deferral-lint.v1"
REPO="$PWD"
SESSION="${SESSION:-flywheel}"
PANES="${PANES:-2,3,4}"
DRAFT="-"
SIGNALS=""
RECEIPT=""
JSON_OUT=0
THRESHOLD=3
REQUIRE_CANONICAL=0
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
BR_BIN="${BR_BIN:-/Users/josh/.cargo/bin/br}"
BV_BIN="${BV_BIN:-/opt/homebrew/bin/bv}"
DOCTOR_BIN="${DOCTOR_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
BV_READINESS_PROBE="${BV_READINESS_PROBE:-$(cd "$(dirname "$0")" && pwd)/bv-readiness-probe.sh}"

usage() {
  cat <<'EOF'
usage: dispatch-deferral-lint.sh [--draft FILE|-] [--repo PATH] [--session NAME] [--panes LIST] [--signals FILE] [--receipt FILE] [--require-canonical-dispatch] [--json]

Rejects question-shaped dispatch drafts when data already selects an action.
EOF
}

json_bool() {
  case "$1" in
    1|true|TRUE|yes|YES) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --draft)
      DRAFT="${2:?--draft requires FILE}"
      shift 2
      ;;
    --repo)
      REPO="${2:?--repo requires PATH}"
      shift 2
      ;;
    --session)
      SESSION="${2:?--session requires NAME}"
      shift 2
      ;;
    --panes)
      PANES="${2:?--panes requires LIST}"
      shift 2
      ;;
    --signals)
      SIGNALS="${2:?--signals requires FILE}"
      shift 2
      ;;
    --receipt)
      RECEIPT="${2:?--receipt requires FILE}"
      shift 2
      ;;
    --threshold)
      THRESHOLD="${2:?--threshold requires INT}"
      shift 2
      ;;
    --require-canonical-dispatch)
      REQUIRE_CANONICAL=1
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    *)
      printf 'ERR: unknown arg: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

TMP="$(mktemp -d -t deferral-lint.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

if [ "$DRAFT" = "-" ]; then
  cat >"$TMP/draft.txt"
else
  [ -f "$DRAFT" ] || { printf 'ERR: draft not found: %s\n' "$DRAFT" >&2; exit 2; }
  cp "$DRAFT" "$TMP/draft.txt"
fi

draft_text="$(cat "$TMP/draft.txt")"
last_lines="$(awk 'NF { lines[++n]=$0 } END { start=n-4; if (start<1) start=1; for (i=start; i<=n; i++) print lines[i] }' "$TMP/draft.txt")"

question_shape=false
if printf '%s\n' "$last_lines" | grep -qiE '(^[[:space:]]*(Want me to|Should I|Do you want me to|Would you like me to|Can I|May I|What should I)\b.*\?$)|(^[[:space:]]*Joshua-decide between\b)|(^[[:space:]]*Which (one|option|path|bead|lane)\b.*\?$)|\?$'; then
  question_shape=true
fi

fail_reason=""
override_present=false

if printf '%s\n' "$draft_text" | grep -qE '(^|[[:space:]])evidence_missing([[:space:]]|$)'; then
  fail_reason="evidence_missing_named_datum_required"
fi

if printf '%s\n' "$draft_text" | grep -qE 'evidence_missing=[^[:space:]]+'; then
  override_present=true
fi

if printf '%s\n' "$draft_text" | grep -qE 'requires_joshua_decision=true'; then
  override_present=true
  blocker_reason="$(printf '%s\n' "$draft_text" | sed -nE 's/.*reason="([^"]+)".*/\1/p' | head -1)"
  case "$blocker_reason" in
    new-platform-or-vendor-not-in-mission-lock|secret-rotation-or-new-credential-creation|financial-commitment-above-mission-budget|legal-or-compliance-decision|destructive-irreversible-on-shared-state|paradigm-conflict-with-active-mission)
      ;;
    *)
      fail_reason="${fail_reason:-requires_joshua_decision_true_blocker_class_required}"
      ;;
  esac
fi

if printf '%s\n' "$draft_text" | grep -qE 'tie_between='; then
  override_present=true
  if ! printf '%s\n' "$draft_text" | grep -qE 'tie_between=[^[:space:],]+,[^[:space:]]+'; then
    fail_reason="${fail_reason:-tie_between_two_options_required}"
  elif ! printf '%s\n' "$draft_text" | grep -qE 'reason="[^"]+"' && ! printf '%s\n' "$draft_text" | grep -qE 'reason=[^[:space:]]+'; then
    fail_reason="${fail_reason:-tie_between_reason_required}"
  fi
fi

idle_worker_count=0
ready_work_count=0
pagerank_alignment=false
doctor_alignment=false
selected_action=""
doctor_status="unknown"

if [ -n "$SIGNALS" ]; then
  idle_worker_count="$(jq -r '.idle_worker_count // .idle_workers // 0' "$SIGNALS")"
  ready_work_count="$(jq -r '.ready_work_count // .ready_bead_count // 0' "$SIGNALS")"
  pagerank_alignment="$(jq -r 'if (.pagerank_alignment == true or (.pagerank_pick // "") != "") then "true" else "false" end' "$SIGNALS")"
  doctor_alignment="$(jq -r 'if (.doctor_alignment == true or .doctor_safe == true or (.doctor_action // "") != "") then "true" else "false" end' "$SIGNALS")"
  selected_action="$(jq -r '.selected_action // .suggested_action // .pagerank_pick // .doctor_action // empty' "$SIGNALS")"
  doctor_status="$(jq -r '.doctor_status // "fixture"' "$SIGNALS")"
else
  if command -v "$NTM_BIN" >/dev/null 2>&1; then
    "$NTM_BIN" --robot-activity="$SESSION" --panes="$PANES" >"$TMP/robot.json" 2>/dev/null || printf '{}\n' >"$TMP/robot.json"
    idle_worker_count="$(jq '[.agents[]? | select((.state == "WAITING") or (.activity == "idle"))] | length' "$TMP/robot.json" 2>/dev/null || printf '0')"
  fi
  if [ -x "$BV_READINESS_PROBE" ]; then
    "$BV_READINESS_PROBE" --repo "$REPO" --json >"$TMP/readiness.json" 2>/dev/null || printf '{"ready_count":0}\n' >"$TMP/readiness.json"
    ready_work_count="$(jq -r '.ready_count // 0' "$TMP/readiness.json" 2>/dev/null || printf '0')"
    selected_action="$(jq -r '.selected_id // empty' "$TMP/readiness.json" 2>/dev/null || true)"
  elif command -v "$BR_BIN" >/dev/null 2>&1; then
    (cd "$REPO" && "$BR_BIN" ready --json) >"$TMP/ready.json" 2>/dev/null || printf '[]\n' >"$TMP/ready.json"
    ready_work_count="$(jq 'length' "$TMP/ready.json" 2>/dev/null || printf '0')"
    selected_action="$(jq -r '.[0].id // empty' "$TMP/ready.json" 2>/dev/null || true)"
  fi
  if command -v "$BV_BIN" >/dev/null 2>&1; then
    (cd "$REPO" && "$BV_BIN" --robot-next) >"$TMP/bv.txt" 2>/dev/null || true
    if [ -s "$TMP/bv.txt" ]; then
      pagerank_alignment=true
      [ -n "$selected_action" ] || selected_action="$(head -1 "$TMP/bv.txt" | cut -c1-120)"
    fi
  fi
  if command -v "$DOCTOR_BIN" >/dev/null 2>&1; then
    "$DOCTOR_BIN" doctor --repo "$REPO" --json >"$TMP/doctor.json" 2>/dev/null || printf '{}\n' >"$TMP/doctor.json"
    doctor_status="$(jq -r '.status // .decision // "unknown"' "$TMP/doctor.json" 2>/dev/null || printf 'unknown')"
    if jq -e '(.status // "") | IN("pass","ok","warn","healthy")' "$TMP/doctor.json" >/dev/null 2>&1 || jq -e '(.action // .next_action // "") != ""' "$TMP/doctor.json" >/dev/null 2>&1; then
      doctor_alignment=true
    fi
  fi
fi

idle_point=0
ready_point=0
pagerank_point=0
doctor_point=0
[ "${idle_worker_count:-0}" -ge 1 ] 2>/dev/null && idle_point=1
[ "${ready_work_count:-0}" -ge 1 ] 2>/dev/null && ready_point=1
[ "$pagerank_alignment" = "true" ] && pagerank_point=1
[ "$doctor_alignment" = "true" ] && doctor_point=1
alignment_score=$((idle_point + ready_point + pagerank_point + doctor_point))

data_answers=false
if [ "$idle_point" -eq 1 ] && [ "$ready_point" -eq 1 ] && [ "$alignment_score" -ge "$THRESHOLD" ]; then
  data_answers=true
fi

canonical_ok=true
if [ "$REQUIRE_CANONICAL" -eq 1 ]; then
  canonical_ok=false
  if printf '%s\n' "$draft_text" | grep -q 'dispatch_skill_version=flywheel-dispatch/v2' \
    && printf '%s\n' "$draft_text" | grep -q 'callback_delivery_verified=true' \
    && printf '%s\n' "$draft_text" | grep -qE 'socraticode_queries=[0-9]+' \
    && printf '%s\n' "$draft_text" | grep -qE 'indexed_chunks_observed=[0-9]+' \
    && printf '%s\n' "$draft_text" | grep -qE 'files_reserved=' \
    && printf '%s\n' "$draft_text" | grep -qE 'files_released='; then
    canonical_ok=true
  else
    fail_reason="${fail_reason:-canonical_dispatch_contract_missing}"
  fi
fi

status="pass"
reason="ok"
if [ -n "$fail_reason" ]; then
  status="fail"
  reason="$fail_reason"
elif [ "$question_shape" = "true" ] && [ "$data_answers" = "true" ] && [ "$override_present" = "false" ]; then
  status="fail"
  reason="data_backed_deferral_violation"
elif [ "$question_shape" = "true" ] && [ "$override_present" = "true" ]; then
  reason="question_allowed_with_named_override"
elif [ "$data_answers" = "true" ]; then
  reason="data_answers_dispatch_directly"
fi

out="$(jq -nc \
  --arg schema_version "dispatch-deferral-lint/v1" \
  --arg version "$VERSION" \
  --arg status "$status" \
  --arg reason "$reason" \
  --arg selected_action "$selected_action" \
  --arg doctor_status "$doctor_status" \
  --argjson question_shape "$(json_bool "$question_shape")" \
  --argjson data_answers "$(json_bool "$data_answers")" \
  --argjson override_present "$(json_bool "$override_present")" \
  --argjson canonical_ok "$(json_bool "$canonical_ok")" \
  --argjson idle_worker_count "${idle_worker_count:-0}" \
  --argjson ready_work_count "${ready_work_count:-0}" \
  --argjson pagerank_alignment "$(json_bool "$pagerank_alignment")" \
  --argjson doctor_alignment "$(json_bool "$doctor_alignment")" \
  --argjson alignment_score "$alignment_score" \
  --argjson threshold "$THRESHOLD" \
  '{schema_version:$schema_version,version:$version,status:$status,reason:$reason,question_shape:$question_shape,data_answers:$data_answers,override_present:$override_present,idle_worker_count:$idle_worker_count,ready_work_count:$ready_work_count,pagerank_alignment:$pagerank_alignment,doctor_alignment:$doctor_alignment,doctor_status:$doctor_status,alignment_score:$alignment_score,threshold:$threshold,selected_action:$selected_action,canonical_dispatch_required:true,canonical_dispatch_contract_ok:$canonical_ok,flywheel_28v_selected_action:($selected_action != ""),flywheel_8i5_canonical_required:true}')"

if [ -n "$RECEIPT" ]; then
  mkdir -p "$(dirname "$RECEIPT")"
  printf '%s\n' "$out" >"$RECEIPT"
fi

if [ "$JSON_OUT" -eq 1 ]; then
  printf '%s\n' "$out"
else
  printf '%s %s\n' "$status" "$reason"
fi

# Append run record to audit log so audit/health/why subcommands have data.
# Best-effort; never fail the lint because of telemetry.
if command -v cli_audit_append >/dev/null 2>&1; then
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "lint" "$status" \
    "$(jq -nc --arg p "${DRAFT:-}" --arg v "$status" --arg r "$reason" \
       '{draft_path:$p,verdict:$v,fail_reason:$r}')" 2>/dev/null || true
fi

[ "$status" = "pass" ]

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
