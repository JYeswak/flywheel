#!/usr/bin/env bash
# dispatch-surface-conflict-probe.sh — close flywheel-x6h.1.
#
# Detects when a candidate dispatch packet would write the same on-disk surface
# as another in-flight dispatch in the recent window. Replaces per-bead-only
# dedupe with per-write-surface dedupe so two beads pointing at the same file
# can't be assigned to two panes concurrently.
#
# Inputs:
#   --candidate-task-file PATH    dispatch packet path (preferred)
#   --candidate-text-file PATH    arbitrary text file (any markdown with paths)
#   --lookback-minutes N          how far back to look in dispatch-log (default 30)
#   --dispatch-log PATH           override default ~/.flywheel/dispatch-log.jsonl
#   --extra-surface-pattern RE    regex to match additional surface paths
#                                 (default: /Users/josh/[A-Za-z0-9_./-]+)
#   --self-task-id ID             ignore in-flight rows whose task_id matches
#                                 (so re-running the probe on a packet that
#                                 already lives in dispatch-log is clean)
#   --json                        emit JSON receipt (default for CI use)
#   --doctor|--health|--info|--schema   canonical-cli-scoping triad
#
# Output JSON shape:
#   {
#     verdict: "ok" | "conflict",
#     candidate_task_file, candidate_bead_id, candidate_surfaces[],
#     in_flight_count,
#     conflicts: [{ bead_id, task_id, task_file, overlapping_surfaces[] }]
#   }
#
# Exit codes:
#   0  no conflict (verdict=ok)
#   1  conflict detected (verdict=conflict)
#   2  config / usage error
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-1fk5f.2) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-1fk5f.2)
#
# Surface-specific logic for the dispatch-surface conflict probe:
#   doctor   probes substrate (dispatch-log present, candidate file paths,
#            jq/grep/awk/mktemp deps, audit log dir, repo root, helper-lib)
#   health   summarizes last-run state from $SCAFFOLD_AUDIT_LOG (pass rate over 50)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: candidate-packet PATH (run probe, report conflict count) | audit-row JSONL
#   audit    routes through cli_emit_audit_tail (default 20 rows)
#   why      provenance lookup — id is row index (numeric, neg=tail) or
#            substring match against status / candidate / conflicting_task fields
#
# NOTE: legacy substantive probe logic stays intact (~lines 240+). Scaffold stubs
# above provide canonical envelope shape; legacy reachable via dash-prefix forms.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-surface-conflict-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-surface-conflict-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-surface-conflict-probe.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: candidate-packet PATH | audit-row JSONL
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-surface-conflict-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-surface-conflict-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-surface-conflict-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-surface-conflict-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-surface-conflict-probe.sh doctor --json"}'
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
          schema_version:"string",command:"\"validate\"",subject:"\"candidate-packet\"|\"audit-row\"",
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
    doctor)   printf 'topic: doctor — probes substrate (dispatch-log present, jq/grep/awk/mktemp deps, audit log dir, repo root, helper-lib, surface-pattern regex valid). Pass = probe ready; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 probe runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: candidate-packet PATH (run probe on a candidate dispatch packet, report conflict_count + conflicting_tasks); audit-row JSONL_LINE (verify ts/status fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, candidate, conflict_count.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / candidate / conflicting_task fields.\n' ;;
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
            && cli_emit_completion_bash "dispatch-surface-conflict-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-surface-conflict-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-1fk5f.2) ----------

# Bind load-bearing paths once. Mirror legacy globals declared below the
# scaffold END marker.
SCAFFOLD_DISPATCH_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
SCAFFOLD_DEFAULT_PATTERN='/Users/josh/[A-Za-z0-9_./-]+'

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/dscp-doctor.XXXXXX")"
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

  if [[ -f "$SCAFFOLD_DISPATCH_LOG" && -r "$SCAFFOLD_DISPATCH_LOG" ]]; then
    local rows; rows="$(wc -l <"$SCAFFOLD_DISPATCH_LOG" 2>/dev/null | tr -d ' ')"
    add_check dispatch_log_present pass "$SCAFFOLD_DISPATCH_LOG (rows=${rows:-0})"
  elif [[ -d "$(dirname "$SCAFFOLD_DISPATCH_LOG")" ]]; then
    add_check dispatch_log_present warn "log absent (probe will report no in-flight overlaps): $SCAFFOLD_DISPATCH_LOG"
  else
    add_check dispatch_log_present warn "log parent dir missing: $(dirname "$SCAFFOLD_DISPATCH_LOG")"
  fi

  for tool in jq grep awk mktemp sed; do
    if command -v "$tool" >/dev/null 2>&1; then
      add_check "${tool}_available" pass "$(command -v "$tool")"
    else
      add_check "${tool}_available" fail "not on PATH"
    fi
  done

  if [[ "$SCAFFOLD_DEFAULT_PATTERN" =~ ^/[A-Za-z0-9_./[:space:]\\^$+*?{}()|-]+$ ]]; then
    add_check surface_pattern_valid pass "$SCAFFOLD_DEFAULT_PATTERN"
  else
    add_check surface_pattern_valid warn "default pattern shape unexpected: $SCAFFOLD_DEFAULT_PATTERN"
  fi

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
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no probe runs recorded yet"}'
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
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/dscp-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/dscp-repair-applied.XXXXXX")"
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
    candidate-packet)
      local path="${1:-}"
      if [[ -z "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"candidate-packet",status:"refused",reason:"path required"}'
        return 64
      fi
      if [[ ! -r "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"candidate-packet",status:"fail",path:$p,reason:"path not readable"}'
        return 1
      fi
      local probe_out probe_rc=0
      probe_out="$("$0" --candidate-task-file "$path" --json 2>/dev/null)" || probe_rc=$?
      local conflict_count
      conflict_count="$(jq -r '.conflict_count // 0' <<<"$probe_out" 2>/dev/null)"
      [[ -z "$conflict_count" ]] && conflict_count=0
      local status="pass"
      if [[ "$conflict_count" -gt 0 ]]; then status="fail"; fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg status "$status" \
        --arg p "$path" \
        --argjson cc "$conflict_count" \
        --argjson rc "$probe_rc" \
        --argjson detail "${probe_out:-null}" \
        '{schema_version:$sv,command:"validate",subject:"candidate-packet",status:$status,path:$p,conflict_count:$cc,probe_exit_code:$rc,detail:$detail}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["candidate-packet","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["candidate-packet","audit-row"]}'
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
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.candidate // "") | contains($id)) or ((.conflicting_task // "") | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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
SCHEMA_VERSION="dispatch-surface-conflict-probe.v1"
DEFAULT_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
DEFAULT_PATTERN='/Users/josh/[A-Za-z0-9_./-]+'

CANDIDATE_TASK_FILE=""
CANDIDATE_TEXT_FILE=""
LOOKBACK_MIN=30
LOG_PATH="$DEFAULT_LOG"
EXTRA_PATTERN="$DEFAULT_PATTERN"
SELF_TASK_ID=""
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: dispatch-surface-conflict-probe.sh
         (--candidate-task-file PATH | --candidate-text-file PATH)
         [--lookback-minutes N]
         [--dispatch-log PATH]
         [--extra-surface-pattern RE]
         [--self-task-id ID]
         [--json]
       dispatch-surface-conflict-probe.sh --doctor|--health|--info|--schema [--json]

Detects whether a candidate dispatch packet's write surfaces overlap with
any in-flight dispatch in the recent window.

Default lookback: 30 minutes. Default surface regex: /Users/josh/[A-Za-z0-9_./-]+

Exit 0 = no conflict, 1 = conflict, 2 = config error.
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$log,
      log_present:($log | (. as $p | "" + $p) | test("\\.jsonl$")),
      reads_only:true,
      enforces:["per-write-surface dedupe across panes"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      verdict_classes:["ok","conflict"],
      surface_extraction:"absolute /Users/josh/... paths in candidate body, sorted+unique",
      in_flight_window:"dispatch-log rows with event=dispatch_sent in lookback window"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        verdict:{enum:["ok","conflict"]},
        candidate_task_file:{type:["string","null"]},
        candidate_bead_id:{type:["string","null"]},
        candidate_surfaces:{type:"array"},
        in_flight_count:{type:"integer"},
        conflicts:{type:"array"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --candidate-task-file) CANDIDATE_TASK_FILE="${2:?--candidate-task-file requires PATH}"; shift 2;;
    --candidate-text-file) CANDIDATE_TEXT_FILE="${2:?--candidate-text-file requires PATH}"; shift 2;;
    --lookback-minutes) LOOKBACK_MIN="${2:?--lookback-minutes requires N}"; shift 2;;
    --dispatch-log) LOG_PATH="${2:?--dispatch-log requires PATH}"; shift 2;;
    --extra-surface-pattern) EXTRA_PATTERN="${2:?--extra-surface-pattern requires RE}"; shift 2;;
    --self-task-id) SELF_TASK_ID="${2:?--self-task-id requires ID}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

if [[ -z "$CANDIDATE_TASK_FILE" && -z "$CANDIDATE_TEXT_FILE" ]]; then
  echo "ERR: must pass --candidate-task-file or --candidate-text-file" >&2
  usage >&2; exit 2
fi
[[ -f "$LOG_PATH" ]] || { echo "ERR: dispatch-log not found: $LOG_PATH" >&2; exit 2; }

CANDIDATE_PATH="${CANDIDATE_TASK_FILE:-$CANDIDATE_TEXT_FILE}"
[[ -f "$CANDIDATE_PATH" ]] || { echo "ERR: candidate file not found: $CANDIDATE_PATH" >&2; exit 2; }

extract_surfaces() {
  # Match candidates, then strip trailing prose punctuation that the regex's
  # `+` quantifier may have absorbed (e.g. `.md.` at end-of-sentence).
  local file="$1"
  grep -oE "$EXTRA_PATTERN" "$file" 2>/dev/null \
    | sed -E 's/[.,;:)>"'"'"'\)]+$//' \
    | sort -u
}

CANDIDATE_BEAD_ID=""
if [[ -n "$CANDIDATE_TASK_FILE" ]]; then
  CANDIDATE_BEAD_ID="$(grep -oE '^# Bead: [a-zA-Z0-9._-]+' "$CANDIDATE_TASK_FILE" 2>/dev/null | head -1 | awk '{print $3}' || echo "")"
fi

CANDIDATE_SURFACES_RAW="$(extract_surfaces "$CANDIDATE_PATH")"
CANDIDATE_SURFACES_JSON="$(printf '%s\n' "$CANDIDATE_SURFACES_RAW" | jq -R -s 'split("\n") | map(select(length > 0))')"

# Window cutoff in epoch seconds
NOW_EPOCH="$(date -u +%s)"
WINDOW_CUTOFF=$((NOW_EPOCH - LOOKBACK_MIN * 60))

# Read in-flight rows (event=dispatch_sent within window).
IN_FLIGHT_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-conflict-inflight.XXXXXX")"
trap 'rm -f "$IN_FLIGHT_TMP"' EXIT

while IFS= read -r row; do
  ev="$(jq -r '.event // ""' <<<"$row" 2>/dev/null)"
  [[ "$ev" == "dispatch_sent" ]] || continue
  ts_iso="$(jq -r '.ts // ""' <<<"$row")"
  [[ -n "$ts_iso" ]] || continue
  row_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${ts_iso%%.*}Z" +%s 2>/dev/null \
            || date -u -d "$ts_iso" +%s 2>/dev/null \
            || echo 0)"
  [[ "$row_epoch" -ge "$WINDOW_CUTOFF" ]] || continue
  rid="$(jq -r '.task_id // ""' <<<"$row")"
  [[ -n "$SELF_TASK_ID" && "$rid" == "$SELF_TASK_ID" ]] && continue
  printf '%s\n' "$row" >>"$IN_FLIGHT_TMP"
done < <(tail -n 500 "$LOG_PATH")

CONFLICTS_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-conflict-out.XXXXXX")"
trap 'rm -f "$IN_FLIGHT_TMP" "$CONFLICTS_TMP"' EXIT
: >"$CONFLICTS_TMP"

IN_FLIGHT_COUNT=0
while IFS= read -r row; do
  IN_FLIGHT_COUNT=$((IN_FLIGHT_COUNT + 1))
  task_id="$(jq -r '.task_id // ""' <<<"$row")"
  bead_id="$(jq -r '.bead_id // ""' <<<"$row")"
  task_file="$(jq -r '.task_file // ""' <<<"$row")"

  [[ -n "$task_file" && -f "$task_file" ]] || continue

  in_flight_surfaces="$(extract_surfaces "$task_file")"
  [[ -n "$in_flight_surfaces" ]] || continue

  overlap="$(comm -12 <(printf '%s\n' "$CANDIDATE_SURFACES_RAW" | sort -u) \
                       <(printf '%s\n' "$in_flight_surfaces" | sort -u))"
  if [[ -n "$overlap" ]]; then
    overlap_json="$(printf '%s\n' "$overlap" | jq -R -s 'split("\n") | map(select(length > 0))')"
    jq -nc \
      --arg bead_id "$bead_id" \
      --arg task_id "$task_id" \
      --arg task_file "$task_file" \
      --argjson overlap "$overlap_json" \
      '{bead_id:$bead_id, task_id:$task_id, task_file:$task_file, overlapping_surfaces:$overlap}' \
      >>"$CONFLICTS_TMP"
  fi
done <"$IN_FLIGHT_TMP"

CONFLICT_COUNT="$(wc -l <"$CONFLICTS_TMP" | tr -d ' ')"
VERDICT=ok
EXIT_CODE=0
[[ "$CONFLICT_COUNT" -gt 0 ]] && { VERDICT=conflict; EXIT_CODE=1; }

CONFLICTS_JSON="$(jq -s '.' "$CONFLICTS_TMP")"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg verdict "$VERDICT" \
  --arg candidate_path "$CANDIDATE_PATH" \
  --arg candidate_bead "$CANDIDATE_BEAD_ID" \
  --argjson candidate_surfaces "$CANDIDATE_SURFACES_JSON" \
  --argjson in_flight "$IN_FLIGHT_COUNT" \
  --argjson conflicts "$CONFLICTS_JSON" \
  '{schema_version:$schema, success:($verdict == "ok"),
    mode:"run", verdict:$verdict,
    candidate_task_file:$candidate_path,
    candidate_bead_id:(if $candidate_bead == "" then null else $candidate_bead end),
    candidate_surfaces:$candidate_surfaces,
    in_flight_count:$in_flight,
    conflicts:$conflicts}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"dispatch-surface-conflict verdict=\(.verdict) candidate=\(.candidate_bead_id // "?") candidate_surfaces=\(.candidate_surfaces | length) in_flight=\(.in_flight_count) conflicts=\(.conflicts | length)"' <<<"$PAYLOAD"
fi

# Append run record to audit log so audit/health/why subcommands have data.
# Best-effort; never fail the probe because of telemetry.
if command -v cli_audit_append >/dev/null 2>&1; then
  _conflict_count="$(jq -r '.conflicts | length' <<<"$PAYLOAD" 2>/dev/null)"
  _conflicting_task="$(jq -r '[.conflicts[]?.task_id // ""] | join(",")' <<<"$PAYLOAD" 2>/dev/null)"
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "probe" "$VERDICT" \
    "$(jq -nc --arg c "$CANDIDATE_PATH" --arg v "$VERDICT" \
       --argjson cc "${_conflict_count:-0}" \
       --arg ct "${_conflicting_task:-}" \
       '{candidate:$c,verdict:$v,conflict_count:$cc,conflicting_task:$ct}')" 2>/dev/null || true
fi

exit "$EXIT_CODE"
