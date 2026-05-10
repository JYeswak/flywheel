#!/usr/bin/env bash
# dispatch-log-v2-violations-doctor.sh
# Bounded read-only wrapper around dispatch-log-schema-validator.sh that emits
# a doctor packet exposing dispatch_log_v2_violations_count for the last N
# rows of .flywheel/dispatch-log.jsonl. Wires into flywheel-loop doctor and
# tick Step 4z.1. Bead: flywheel-yu8g.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-hpirw) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-hpirw)
#
# Surface-specific logic for the dispatch-log v2 violations doctor
# (read-only wrapper around dispatch-log-schema-validator.sh):
#   doctor   probes substrate (validator binary, dispatch-log.jsonl, jq, mktemp,
#            audit log dir writability, repo root, TAIL_N sanity)
#   health   summarizes last-run state from $SCAFFOLD_AUDIT_LOG (pass rate over 50)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: dispatch-log PATH (run validator, report violation count) | audit-row JSONL
#   audit    routes through cli_emit_audit_tail (default 20 rows)
#   why      provenance lookup — id is row index (numeric, neg=tail) or
#            substring match against status / dispatch_log_v2_violations_count fields

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-log-v2-violations-doctor/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-v2-violations-doctor-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-log-v2-violations-doctor.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: dispatch-log PATH | audit-row JSONL
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-log-v2-violations-doctor.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-log-v2-violations-doctor.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-log-v2-violations-doctor.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-log-v2-violations-doctor.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-log-v2-violations-doctor.sh doctor --json"}'
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
          schema_version:"string",command:"\"validate\"",subject:"\"dispatch-log\"|\"audit-row\"",
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
    doctor)   printf 'topic: doctor — probes substrate (validator binary at .flywheel/scripts/dispatch-log-schema-validator.sh, dispatch-log.jsonl, jq, mktemp, audit log dir, repo root, TAIL_N sanity). Pass = wrapper ready to run; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 doctor runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: dispatch-log PATH (run validator, report violation count); audit-row JSONL_LINE (verify ts/status fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, log_path, violations_count.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / log_path / violations_count.\n' ;;
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
            && cli_emit_completion_bash "dispatch-log-v2-violations-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-log-v2-violations-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-hpirw) ----------

# Bind load-bearing paths once. Mirror legacy globals declared below the
# scaffold END marker; scaffold layer can't read those directly because the
# early-dispatch intercept short-circuits before they're set.
SCAFFOLD_VALIDATOR="${FLYWHEEL_DISPATCH_LOG_VALIDATOR:-$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/dispatch-log-schema-validator.sh}"
SCAFFOLD_LOG_PATH="${FLYWHEEL_DISPATCH_LOG_PATH:-$_SCAFFOLD_REPO_ROOT/.flywheel/dispatch-log.jsonl}"
SCAFFOLD_TAIL_N="${FLYWHEEL_DISPATCH_LOG_V2_TAIL:-100}"

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/dl2vd-doctor.XXXXXX")"
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

  if [[ -x "$SCAFFOLD_VALIDATOR" ]]; then
    add_check validator_executable pass "$SCAFFOLD_VALIDATOR"
  elif [[ -f "$SCAFFOLD_VALIDATOR" ]]; then
    add_check validator_executable warn "exists but not executable: $SCAFFOLD_VALIDATOR"
  else
    add_check validator_executable fail "missing: $SCAFFOLD_VALIDATOR"
  fi

  if [[ -f "$SCAFFOLD_LOG_PATH" && -r "$SCAFFOLD_LOG_PATH" ]]; then
    local rows; rows="$(wc -l <"$SCAFFOLD_LOG_PATH" 2>/dev/null | tr -d ' ')"
    add_check dispatch_log_present pass "$SCAFFOLD_LOG_PATH (rows=${rows:-0})"
  elif [[ -d "$(dirname "$SCAFFOLD_LOG_PATH")" ]]; then
    add_check dispatch_log_present warn "log absent (expected at $SCAFFOLD_LOG_PATH); fresh repos may legitimately have no rows yet"
  else
    add_check dispatch_log_present warn "log parent dir missing: $(dirname "$SCAFFOLD_LOG_PATH")"
  fi

  for tool in jq mktemp awk grep; do
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

  if [[ "$SCAFFOLD_TAIL_N" =~ ^[0-9]+$ ]] && [[ "$SCAFFOLD_TAIL_N" -ge 1 ]]; then
    add_check tail_n_sane pass "TAIL_N=$SCAFFOLD_TAIL_N"
  else
    add_check tail_n_sane fail "TAIL_N invalid: '$SCAFFOLD_TAIL_N' (must be int >= 1)"
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
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no doctor runs recorded yet"}'
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
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/dl2vd-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/dl2vd-repair-applied.XXXXXX")"
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
    dispatch-log)
      local path="${1:-$SCAFFOLD_LOG_PATH}"
      if [[ ! -r "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"dispatch-log",status:"fail",path:$p,reason:"path not readable"}'
        return 1
      fi
      if [[ ! -x "$SCAFFOLD_VALIDATOR" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg v "$SCAFFOLD_VALIDATOR" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"dispatch-log",status:"fail",path:$p,validator:$v,reason:"validator not executable"}'
        return 1
      fi
      local lint_out lint_rc=0
      lint_out="$(bash "$SCAFFOLD_VALIDATOR" validate --repo "$_SCAFFOLD_REPO_ROOT" --tail "$SCAFFOLD_TAIL_N" --json 2>/dev/null)" || lint_rc=$?
      local invalid total
      invalid="$(jq -r '.invalid // 0' <<<"$lint_out" 2>/dev/null)"
      total="$(jq -r '.total // 0' <<<"$lint_out" 2>/dev/null)"
      [[ -z "$invalid" ]] && invalid=0
      [[ -z "$total" ]] && total=0
      local status="pass"
      if [[ "$invalid" -gt 0 ]]; then status="fail"; fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg status "$status" \
        --arg p "$path" \
        --argjson invalid "$invalid" \
        --argjson total "$total" \
        --argjson rc "$lint_rc" \
        --argjson detail "${lint_out:-null}" \
        '{schema_version:$sv,command:"validate",subject:"dispatch-log",status:$status,path:$p,invalid:$invalid,total:$total,validator_exit_code:$rc,detail:$detail}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["dispatch-log","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["dispatch-log","audit-row"]}'
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
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.log_path // "") | contains($id)) or (((.violations_count // 0) | tostring) | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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
VERSION="dispatch-log-v2-violations-doctor/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REPO="$ROOT"
TAIL_N="${FLYWHEEL_DISPATCH_LOG_V2_TAIL:-100}"
JSON_OUT=0
COMMAND="doctor"

usage() {
  cat <<'EOF'
usage:
  dispatch-log-v2-violations-doctor.sh [doctor|health|validate|info|schema|why|help]
                                       [--repo PATH] [--tail N] [--json]

flags:
  --tail N    rows to validate from the end of dispatch-log.jsonl
              (default: 100, env FLYWHEEL_DISPATCH_LOG_V2_TAIL overrides)

exit codes: 0=report emitted (PASS/INFO), 1=violations found, 2=usage error
EOF
}

info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg tail "$TAIL_N" \
    '{name:"dispatch-log-v2-violations-doctor.sh",version:$version,repo:$repo,default_tail:($tail|tonumber),mutates:"none",delegates_to:".flywheel/scripts/dispatch-log-schema-validator.sh",commands:["doctor","health","validate","info","schema","why","help"],flags:["--repo PATH","--tail N","--json"]}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

subcmd="${1:-}"
case "$subcmd" in
  doctor|health|validate)
    COMMAND="$subcmd"; shift ;;
  why)
    cat <<'EOF'
why: surfaces the count of dispatch-log v2 schema violations from the most
recent N rows so flywheel-loop doctor and tick Step 4z.1 can fail closed
when worker-emitted v2 rows drop required fields.
EOF
    exit 0 ;;
  info)
    info; exit 0 ;;
  schema)
    cat "$REPO/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"; exit 0 ;;
  help|-h|--help)
    usage; exit 0 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --tail) [[ $# -ge 2 ]] || die_usage "--tail requires N"; TAIL_N="$2"; shift 2 ;;
    --tail=*) TAIL_N="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
done

[[ "$TAIL_N" =~ ^[0-9]+$ ]] || die_usage "--tail must be a non-negative integer: $TAIL_N"

# The wrapper script and the validator ship together; use $ROOT (this script's
# own repo) to find the validator binary, while $REPO is the target whose
# dispatch-log.jsonl + schema are read.
VALIDATOR="${FLYWHEEL_DISPATCH_LOG_VALIDATOR:-$ROOT/.flywheel/scripts/dispatch-log-schema-validator.sh}"
LOG_PATH="$REPO/.flywheel/dispatch-log.jsonl"

if [[ ! -x "$VALIDATOR" ]]; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"warn",dispatch_log_v2_violations_count:0,tail_size:0,log_present:false,errors:[{code:"validator_missing",message:"dispatch-log-schema-validator.sh is not executable"}],warnings:[]}'
  exit 0
fi

if [[ ! -f "$LOG_PATH" ]]; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"pass",dispatch_log_v2_violations_count:0,tail_size:0,log_present:false,errors:[],warnings:[{code:"log_missing",message:"dispatch-log.jsonl not present"}]}'
  exit 0
fi

VAL_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-log-v2-violations-doctor.XXXXXX")"
trap 'rm -f "$VAL_TMP"' EXIT

# Validator exits 1 when invalid > 0 under validate; we always want to read its
# JSON and decide here, so swallow the exit and inspect the summary.
if ! bash "$VALIDATOR" validate --repo "$REPO" --tail "$TAIL_N" --json >"$VAL_TMP" 2>/dev/null; then
  :
fi

if ! jq -e . >/dev/null 2>&1 <"$VAL_TMP"; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"warn",dispatch_log_v2_violations_count:0,tail_size:0,log_present:true,errors:[{code:"validator_invalid_json",message:"validator emitted non-JSON output"}],warnings:[]}'
  exit 0
fi

PACKET="$(jq -c \
  --arg version "$VERSION" \
  --argjson tail_n "$TAIL_N" \
  '{
    schema_version: $version,
    status: (if (.invalid // 0) > 0 then "fail" else "pass" end),
    dispatch_log_v2_violations_count: (.invalid // 0),
    dispatch_log_v2_total_rows_checked: (.total // 0),
    dispatch_log_v2_malformed_count: (.malformed_count // 0),
    dispatch_log_v2_missing_fitness_class_count: (.missing_fitness_class // 0),
    dispatch_log_v2_missing_fitness_claim_count: (.missing_fitness_claim // 0),
    tail_size: $tail_n,
    log_present: (.log_present // true),
    expected_mission_anchor: (.expected_mission_anchor // ""),
    schema_id: (.schema_id // null),
    errors: [],
    warnings: (if (.invalid // 0) > 0 then [{code:"v2_violations_present",message:("invalid=" + ((.invalid // 0)|tostring) + " of " + ((.total // 0)|tostring) + " rows checked")}] else [] end)
  }' "$VAL_TMP")"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$PACKET"
else
  jq -r '"dispatch_log_v2_violations_count=\(.dispatch_log_v2_violations_count) tail_size=\(.tail_size) total=\(.dispatch_log_v2_total_rows_checked) status=\(.status)"' <<<"$PACKET"
fi

_doctor_status="$(jq -r '.status' <<<"$PACKET")"
_doctor_count="$(jq -r '.dispatch_log_v2_violations_count' <<<"$PACKET")"

# Append run record to audit log so audit/health/why subcommands have data.
# Best-effort; never fail the doctor because of telemetry.
if command -v cli_audit_append >/dev/null 2>&1; then
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "doctor" "$_doctor_status" \
    "$(jq -nc --arg log "$LOG_PATH" --argjson vc "$_doctor_count" \
       '{log_path:$log,violations_count:$vc}')" 2>/dev/null || true
fi

if [[ "$COMMAND" == "doctor" || "$COMMAND" == "validate" ]]; then
  [[ "$_doctor_count" == "0" ]] || exit 1
fi
exit 0
