#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-1fk5f.7) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-1fk5f.7)
#
# Surface-specific logic for the ntm fleet-health wrapper:
#   doctor   probes substrate (ntm binary, jsonl-append lib, topology file,
#            out file dir, lock file dir, jq/mktemp deps, audit log dir,
#            repo root, helper-lib)
#   health   summarizes last-run state from $SCAFFOLD_AUDIT_LOG (pass rate over 50)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: ntm-bin (verify ntm executable + ntm health subcommand) | audit-row JSONL
#   audit    routes through cli_emit_audit_tail (default 20 rows)
#   why      provenance lookup — id is row index (numeric, neg=tail) or
#            substring match against status / threshold / restart fields
#
# NOTE: legacy main is a single-pass health probe that delegates to `ntm health`.
# Scaffold stubs above provide canonical envelope shape; legacy reachable via
# the no-subcommand default (the script's main parser accepts only flags).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="ntm-fleet-health/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-fleet-health-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-fleet-health.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: ntm-bin | audit-row JSONL
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-fleet-health.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-fleet-health.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-fleet-health.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-fleet-health.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-fleet-health.sh doctor --json"}'
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
          schema_version:"string",command:"\"validate\"",subject:"\"ntm-bin\"|\"audit-row\"",
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
    doctor)   printf 'topic: doctor — probes substrate (ntm binary, jsonl-append lib, topology file, out file dir, lock file dir, jq/mktemp deps, audit log dir, repo root, helper-lib). Pass = wrapper ready; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 fleet-health probes from %s. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' "$SCAFFOLD_AUDIT_LOG" ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: ntm-bin (verify ntm executable + ntm health subcommand recognized); audit-row JSONL_LINE (verify ts/status fields).\n' ;;
    audit)    printf 'topic: audit — tails %s (default 20 rows, override with audit N). Each row: ts, action, status, sha256, threshold, restart.\n' "$SCAFFOLD_AUDIT_LOG" ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / threshold / restart fields.\n' ;;
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
            && cli_emit_completion_bash "ntm-fleet-health" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-fleet-health" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-1fk5f.7) ----------

# Bind load-bearing paths once. Mirror legacy globals declared below.
SCAFFOLD_NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SCAFFOLD_OUT_FILE="${NTM_FLEET_HEALTH_OUT:-$HOME/.local/state/flywheel/ntm-fleet-health.jsonl}"
SCAFFOLD_LOCK_FILE="${NTM_FLEET_HEALTH_LOCK:-$HOME/.local/state/flywheel/ntm-fleet-health.lock}"
SCAFFOLD_JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
SCAFFOLD_TOPOLOGY_FILE="${NTM_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/nfh-doctor.XXXXXX")"
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
    add_check ntm_executable fail "ntm binary not found at $SCAFFOLD_NTM_BIN"
  fi

  if [[ -r "$SCAFFOLD_JSONL_APPEND_LIB" ]]; then
    add_check jsonl_append_lib_readable pass "$SCAFFOLD_JSONL_APPEND_LIB"
  else
    add_check jsonl_append_lib_readable warn "missing: $SCAFFOLD_JSONL_APPEND_LIB (legacy append will skip with WARN)"
  fi

  if [[ -f "$SCAFFOLD_TOPOLOGY_FILE" && -r "$SCAFFOLD_TOPOLOGY_FILE" ]]; then
    add_check topology_file_readable pass "$SCAFFOLD_TOPOLOGY_FILE"
  elif [[ -d "$(dirname "$SCAFFOLD_TOPOLOGY_FILE")" ]]; then
    add_check topology_file_readable warn "topology absent: $SCAFFOLD_TOPOLOGY_FILE (probe will degrade)"
  else
    add_check topology_file_readable warn "topology parent dir missing: $(dirname "$SCAFFOLD_TOPOLOGY_FILE")"
  fi

  local out_dir; out_dir="$(dirname "$SCAFFOLD_OUT_FILE")"
  if [[ -d "$out_dir" && -w "$out_dir" ]]; then
    add_check out_file_dir_writable pass "$out_dir"
  else
    add_check out_file_dir_writable warn "out file dir not writable: $out_dir"
  fi

  local lock_dir; lock_dir="$(dirname "$SCAFFOLD_LOCK_FILE")"
  if [[ -d "$lock_dir" && -w "$lock_dir" ]]; then
    add_check lock_file_dir_writable pass "$lock_dir"
  else
    add_check lock_file_dir_writable warn "lock file dir not writable: $lock_dir"
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
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no fleet-health probes recorded yet"}'
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
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/nfh-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/nfh-repair-applied.XXXXXX")"
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
    ntm-bin)
      local missing=() exec_ok="false" health_ok="false"
      if [[ -x "$SCAFFOLD_NTM_BIN" ]]; then
        exec_ok="true"
      elif command -v ntm >/dev/null 2>&1; then
        exec_ok="true"
      else
        missing+=("not_executable")
      fi
      if [[ "$exec_ok" == "true" ]]; then
        if "$SCAFFOLD_NTM_BIN" --help 2>&1 | grep -qE '\bhealth\b' 2>/dev/null \
           || ntm --help 2>&1 | grep -qE '\bhealth\b' 2>/dev/null; then
          health_ok="true"
        else
          missing+=("health_subcommand")
        fi
      fi
      local status="pass"
      if (( ${#missing[@]} > 0 )); then status="fail"; fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg status "$status" \
        --arg path "$SCAFFOLD_NTM_BIN" \
        --argjson exec_ok "$exec_ok" \
        --argjson health_ok "$health_ok" \
        --argjson missing "$(printf '%s\n' "${missing[@]:-}" | grep -v '^$' | jq -R . | jq -cs .)" \
        '{schema_version:$sv,command:"validate",subject:"ntm-bin",status:$status,path:$path,exec_ok:$exec_ok,health_subcommand_ok:$health_ok,missing:$missing}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["ntm-bin","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["ntm-bin","audit-row"]}'
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
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.threshold // "") | contains($id)) or (((.restart // false) | tostring) | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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
  # shellcheck disable=SC2317
  exit $?
fi
# ====== END canonical-cli scaffold ======
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
OUT_FILE="${NTM_FLEET_HEALTH_OUT:-$HOME/.local/state/flywheel/ntm-fleet-health.jsonl}"
LOCK_FILE="${NTM_FLEET_HEALTH_LOCK:-$HOME/.local/state/flywheel/ntm-fleet-health.lock}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
TOPOLOGY_FILE="${NTM_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
THRESHOLD="${NTM_HEALTH_THRESHOLD:-10m}"
AUTO_RESTART_STUCK=0; APPLY=0; JSON_OUT=0

usage(){ printf '%s\n' \
  'Usage: ntm-fleet-health.sh [--auto-restart-stuck] [--apply] [--json]' \
  'Delegates to ntm health. Restart behavior is preview-only unless --apply is passed.'; }

while [[ $# -gt 0 ]]; do case "$1" in
  --auto-restart-stuck) AUTO_RESTART_STUCK=1; shift;; --apply) APPLY=1; shift;; --json) JSON_OUT=1; shift;;
  --threshold) THRESHOLD="${2:?--threshold requires value}"; shift 2;; --threshold=*) THRESHOLD="${1#*=}"; shift;;
  --out-file) OUT_FILE="${2:?--out-file requires path}"; shift 2;; --out-file=*) OUT_FILE="${1#*=}"; shift;;
  --ntm-bin) NTM_BIN="${2:?--ntm-bin requires path}"; shift 2;; --ntm-bin=*) NTM_BIN="${1#*=}"; shift;;
  --topology-file) TOPOLOGY_FILE="${2:?--topology-file requires path}"; shift 2;; --topology-file=*) TOPOLOGY_FILE="${1#*=}"; shift;;
  --help|-h) usage; exit 0;; *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64;;
esac; done

[[ "$AUTO_RESTART_STUCK" -eq 1 && "$APPLY" -ne 1 ]] && printf 'WARNING: --auto-restart-stuck is preview-only; pass --apply to execute ntm health mutations.\n' >&2

wrap_json(){ local raw="$1" rc="$2"; if jq -ce . >/dev/null 2>&1 <<<"$raw"; then jq -c . <<<"$raw"; else jq -cn --arg raw "$raw" --argjson exit_code "$rc" '{success:false,parse_error:true,exit_code:$exit_code,raw:$raw}'; fi; }

append_row(){
  local row="$1" label="$2" rc; [[ "${NTM_FLEET_HEALTH_FORCE_EMPTY_ROW:-0}" == "1" ]] && row=""
  if [[ ! -f "$JSONL_APPEND_LIB" ]]; then printf 'WARN: skipped %s append; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2; return 0; fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"; set +e; fw_jsonl_append_validated "$OUT_FILE" "$row"; rc=$?; set -e
  [[ "$rc" -eq 0 ]] || printf 'WARN: failed to append %s row to %s rc=%s\n' "$label" "$OUT_FILE" "$rc" >&2
}

emit(){
  [[ "$JSON_OUT" -eq 1 ]] && jq -cn --argjson row "$1" --argjson auto_restart "$2" '{schema_version:"ntm-fleet-health/result/v1",ledger_row:$row,auto_restart:$auto_restart}'
  # Append scaffold-audit-log row so canonical audit/health/why have data.
  # Best-effort; never fail the probe because of telemetry.
  if command -v cli_audit_append >/dev/null 2>&1; then
    local _emit_status; _emit_status="$(jq -r '.health.status // .event // "run"' <<<"$1" 2>/dev/null)"
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "probe" "${_emit_status:-run}" \
      "$(jq -nc --arg t "$THRESHOLD" --argjson r "$AUTO_RESTART_STUCK" \
         '{threshold:$t,restart:($r==1)}')" 2>/dev/null || true
  fi
}

auto_preview(){
  local session="$1" health="$2"
  if [[ "$AUTO_RESTART_STUCK" -ne 1 ]]; then jq -cn '{enabled:false,apply:false,action:"none"}'
  elif [[ "$APPLY" -eq 1 ]]; then jq -cn --arg session "$session" '{enabled:true,apply:true,action:"restart_invoked",session:$session}'
  else jq -cn --arg session "$session" --argjson health "$health" '[($health.stuck_panes // $health.stuck // [])[]? | select((.stuck // .needs_restart // false) == true) | (.pane // .pane_idx // .id)] as $panes | {enabled:true,apply:false,action:"would_restart",session:$session,pane:($panes[0] // null),panes:$panes,reason:"pass --apply to run ntm health --auto-restart-stuck"}'
  fi
}

role_split(){
  jq -cn --argjson t "$1" --argjson h "$2" 'def panes:$h.panes//$h.agents//[]; def pid:.pane//.pane_idx//.id//null; def bad:((.status//.process_status//"unknown")|tostring|ascii_downcase|test("error|exited|failed|dead|stuck|unhealthy")); def role:(pid|tostring) as $p | ((.agent_type//.type//"")|tostring|ascii_downcase) as $k | if (($t.human_pane//null)!=null and $p==($t.human_pane|tostring)) or $k=="user" then "user" elif (($t.orchestrator_pane//null)!=null and $p==($t.orchestrator_pane|tostring)) or (($t.callback_pane//null)!=null and $p==($t.callback_pane|tostring)) or (($t.worker_panes//[]|map(tostring)|index($p))!=null) or ($k|test("^(cod|codex|cc|claude)$")) then "agent" else "other" end; def source:(pid|tostring) as $p | ((.agent_type//.type//"")|tostring|ascii_downcase) as $k | if (($t.human_pane//null)!=null and $p==($t.human_pane|tostring)) then "topology.human_pane" elif $k=="user" then "ntm.agent_type" elif (($t.orchestrator_pane//null)!=null and $p==($t.orchestrator_pane|tostring)) then "topology.orchestrator_pane" elif (($t.callback_pane//null)!=null and $p==($t.callback_pane|tostring)) then "topology.callback_pane" elif (($t.worker_panes//[]|map(tostring)|index($p))!=null) then "topology.worker_panes" elif ($k|test("^(cod|codex|cc|claude)$")) then "ntm.agent_type" else "unknown" end; def deco:panes[]|{pane:pid,role:role,role_source:source,status:(.status//.process_status//"unknown"),process_status:(.process_status//null),agent_type:(.agent_type//.type//null),activity:(.activity//.state//null),unhealthy:bad}; def summary($r):[deco|select(.role==$r)] as $rows|($rows|map(select(.unhealthy))) as $bad|{status:(if ($rows|length)==0 then "unknown" elif ($bad|length)>0 then "error" else "ok" end),total:($rows|length),unhealthy_count:($bad|length),panes:$rows}; {schema_version:"ntm-health-role-split/v1",agent_pane_health:summary("agent"),user_pane_health:summary("user"),other_pane_health:summary("other")}'
}

topology_observer(){
  local previous_count=""
  if [[ -r "$OUT_FILE" ]]; then
    previous_count="$(tail -n 50 "$OUT_FILE" 2>/dev/null \
      | jq -rs 'map((.topology_observer? // .ledger_row?.topology_observer?) // empty) | last | .row_count // empty' 2>/dev/null || true)"
  fi
  if [[ ! -r "$TOPOLOGY_FILE" ]]; then
    jq -cn --arg path "$TOPOLOGY_FILE" --arg previous "$previous_count" \
      '{schema_version:"ntm-fleet-health.topology-observer/v1",status:"missing",path:$path,row_count:null,previous_row_count:($previous|tonumber? // null),row_count_decreased:false,regression:false,walk_in_progress:false,confirmed_rebuild:false,confirmed_via_present:false,joshua_confirmed_rows:0,confirmed_via_rows:0,walk_in_progress_rows:0}'
    return 0
  fi
  jq -cs --arg path "$TOPOLOGY_FILE" --arg previous "$previous_count" '
    def truthy:
      . == true or . == 1 or ((. // "" | tostring | ascii_downcase) | IN("true","yes","1","walk_in_progress"));
    map(select(type == "object")) as $rows
    | ($rows | length) as $row_count
    | ($previous | tonumber? // null) as $previous_count
    | ($rows | map(select((.joshua_confirmed_at // "") != "")) | length) as $joshua_rows
    | ($rows | map(select((.confirmed_via // "") != "")) | length) as $via_rows
    | ($rows | map(select((.walk_in_progress // .inferred_wipe_walk_in_progress // .topology_walk_in_progress // false | truthy) or (((.session_status // .status // "") | tostring | ascii_downcase) | test("walk.*progress|rebuild.*progress")))) | length) as $walk_rows
    | ($previous_count != null and $row_count < $previous_count) as $decreased
    | ($row_count > 0 and $joshua_rows == $row_count and $via_rows == $row_count) as $confirmed_rebuild
    | ($walk_rows > 0) as $walk_in_progress
    | ($decreased and ($confirmed_rebuild | not) and ($walk_in_progress | not)) as $regression
    | {
        schema_version:"ntm-fleet-health.topology-observer/v1",
        status:(if $regression then "regression" elif $decreased and $walk_in_progress then "walk_in_progress" elif $decreased and $confirmed_rebuild then "confirmed_rebuild" else "ok" end),
        path:$path,
        row_count:$row_count,
        previous_row_count:$previous_count,
        row_count_decreased:$decreased,
        regression:$regression,
        walk_in_progress:$walk_in_progress,
        confirmed_rebuild:$confirmed_rebuild,
        confirmed_via_present:($via_rows > 0),
        joshua_confirmed_rows:$joshua_rows,
        confirmed_via_rows:$via_rows,
        walk_in_progress_rows:$walk_rows
      }' "$TOPOLOGY_FILE"
}

mkdir -p "$(dirname "$OUT_FILE")" "$(dirname "$LOCK_FILE")"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"; flock -n 9 || { echo "another instance running"; exit 0; }
else
  if ! mkdir "$LOCK_FILE" 2>/dev/null; then echo "another instance running"; exit 0; fi
  trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT INT TERM
fi
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TOPOLOGY_OBSERVER="$(topology_observer)"

set +e; LIST_OUT="$("$NTM_BIN" list --json 2>&1)"; LIST_RC=$?; set -e
if [[ "$LIST_RC" -ne 0 ]]; then LIST_JSON="$(wrap_json "$LIST_OUT" "$LIST_RC")"; ROW="$(jq -cn --arg ts "$NOW" --argjson list "$LIST_JSON" --argjson topo "$TOPOLOGY_OBSERVER" '{ts:$ts,event:"session_discovery_failed",list:$list,topology_observer:$topo}')"; append_row "$ROW" "session_discovery_failed"; emit "$ROW" "$(jq -cn '{enabled:false,apply:false,action:"none"}')"; exit 0; fi

SESSIONS="$(jq -r 'if type=="array" then .[]? | (.name // .session // empty) elif (.sessions? | type)=="array" then .sessions[]? | (.name // .session // empty) else .name // .session // empty end' <<<"$LIST_OUT" 2>/dev/null || true)"
if [[ -z "$SESSIONS" ]]; then ROW="$(jq -cn --arg ts "$NOW" --argjson topo "$TOPOLOGY_OBSERVER" '{ts:$ts,event:"no_sessions_discovered",topology_observer:$topo}')"; append_row "$ROW" "no_sessions_discovered"; emit "$ROW" "$(jq -cn '{enabled:false,apply:false,action:"none"}')"; exit 0; fi

while IFS= read -r SESSION; do
  [[ -z "$SESSION" ]] && continue
  TOPO="null"; [[ -r "$TOPOLOGY_FILE" ]] && TOPO="$(jq -sc --arg s "$SESSION" 'map(select(.session == $s)) | sort_by(.effective_at // "") | last // null' "$TOPOLOGY_FILE" 2>/dev/null || printf 'null')"
  HEALTH_ARGS=(health "$SESSION" --json --threshold "$THRESHOLD"); [[ "$AUTO_RESTART_STUCK" -eq 1 && "$APPLY" -eq 1 ]] && HEALTH_ARGS+=(--auto-restart-stuck)
  set +e; HEALTH_OUT="$("$NTM_BIN" "${HEALTH_ARGS[@]}" 2>&1)"; HEALTH_RC=$?; set -e
  HEALTH="$(wrap_json "$HEALTH_OUT" "$HEALTH_RC")"; ROLE_SPLIT="$(role_split "$TOPO" "$HEALTH")"
  ROW="$(jq -cn --arg ts "$NOW" --arg session "$SESSION" --arg threshold "$THRESHOLD" --argjson health "$HEALTH" --argjson role "$ROLE_SPLIT" --argjson topo "$TOPOLOGY_OBSERVER" '{ts:$ts,session:$session,threshold:$threshold,health:$health,agent_pane_health:$role.agent_pane_health,user_pane_health:$role.user_pane_health,other_pane_health:$role.other_pane_health,health_role_split:$role,topology_observer:$topo}')"
  AUTO="$(auto_preview "$SESSION" "$HEALTH")"; append_row "$ROW" "health"; emit "$ROW" "$AUTO"
done <<<"$SESSIONS"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
