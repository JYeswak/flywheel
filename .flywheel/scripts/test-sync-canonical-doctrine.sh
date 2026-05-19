#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2317
# Synthetic regression test for sync-canonical-doctrine.sh.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m, fillin flywheel-zjm8v) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-zjm8v)
#
# Surface-specific logic for the test-sync-canonical-doctrine harness:
#   doctor   probes substrate (sync-canonical-doctrine.sh, jq, shasum, mktemp,
#            tmp writability, repo root)
#   health   summarizes last-run state from $SCAFFOLD_AUDIT_LOG (pass rate over 50)
#   repair   scopes: audit_log_dir | audit_log_truncate
#   validate subjects: sync-binary | fixture-state PATH
#   audit    routes through cli_emit_audit_tail (default 20 rows)
#   why      provenance lookup — id is a row index (numeric, neg=tail) or
#            substring match against fixture path / status field

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="test-sync-canonical-doctrine/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/test-sync-canonical-doctrine-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: test-sync-canonical-doctrine.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: sync-binary | fixture-state PATH
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "test-sync-canonical-doctrine.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "test-sync-canonical-doctrine.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"test-sync-canonical-doctrine.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"test-sync-canonical-doctrine.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"test-sync-canonical-doctrine.sh doctor --json"}'
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
          schema_version:"string",command:"\"validate\"",subject:"\"sync-binary\"|\"fixture-state\"",
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
    doctor)   printf 'topic: doctor — probes harness substrate (sync-canonical-doctrine.sh executable, jq/shasum/mktemp on PATH, $TMPDIR writable, repo root resolved, helper-lib loaded). Pass = ready to run; warn = recoverable; fail = harness blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 harness runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: sync-binary (verify .flywheel/scripts/sync-canonical-doctrine.sh is executable bash with --apply/--dry-run/--json); fixture-state PATH (verify a TMP fixture has the expected canonical/repos/no-loops layout).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, run_outcome.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / fixture / outcome.\n' ;;
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
            && cli_emit_completion_bash "test-sync-canonical-doctrine" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "test-sync-canonical-doctrine" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface (filled in by flywheel-zjm8v) ----------

# Bind the harness's load-bearing paths once so doctor / repair / validate can
# reference them without re-deriving each time.
SCAFFOLD_SYNC_BIN="${SCAFFOLD_SYNC_BIN:-/Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh}"

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/tscd-doctor.XXXXXX")"
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

  if [[ -x "$SCAFFOLD_SYNC_BIN" ]]; then
    add_check sync_binary_executable pass "$SCAFFOLD_SYNC_BIN"
  elif [[ -f "$SCAFFOLD_SYNC_BIN" ]]; then
    add_check sync_binary_executable warn "exists but not executable: $SCAFFOLD_SYNC_BIN"
  else
    add_check sync_binary_executable fail "missing: $SCAFFOLD_SYNC_BIN"
  fi

  for tool in jq shasum mktemp diff awk grep; do
    if command -v "$tool" >/dev/null 2>&1; then
      add_check "${tool}_available" pass "$(command -v "$tool")"
    else
      add_check "${tool}_available" fail "not on PATH"
    fi
  done

  local tdir="${TMPDIR:-/tmp}"
  if [[ -d "$tdir" && -w "$tdir" ]]; then
    add_check tmpdir_writable pass "$tdir"
  else
    add_check tmpdir_writable fail "not writable: $tdir"
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
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no harness runs recorded yet"}'
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
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/tscd-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/tscd-repair-applied.XXXXXX")"
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
    sync-binary)
      local missing=() syntax_ok="false" flags_ok="false"
      if [[ ! -x "$SCAFFOLD_SYNC_BIN" ]]; then
        missing+=("not_executable")
      fi
      if [[ -f "$SCAFFOLD_SYNC_BIN" ]]; then
        if bash -n "$SCAFFOLD_SYNC_BIN" 2>/dev/null; then syntax_ok="true"; fi
        if grep -qE -- '--apply' "$SCAFFOLD_SYNC_BIN" \
           && grep -qE -- '--dry-run' "$SCAFFOLD_SYNC_BIN" \
           && grep -qE -- '--json' "$SCAFFOLD_SYNC_BIN"; then
          flags_ok="true"
        fi
      else
        missing+=("file_missing")
      fi
      [[ "$syntax_ok" == "true" ]] || missing+=("bash_syntax")
      [[ "$flags_ok" == "true" ]]   || missing+=("required_flags")
      local status="pass"
      if (( ${#missing[@]} > 0 )); then status="fail"; fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg status "$status" \
        --arg path "$SCAFFOLD_SYNC_BIN" \
        --argjson syntax_ok "$syntax_ok" \
        --argjson flags_ok "$flags_ok" \
        --argjson missing "$(printf '%s\n' "${missing[@]:-}" | grep -v '^$' | jq -R . | jq -cs .)" \
        '{schema_version:$sv,command:"validate",subject:"sync-binary",status:$status,path:$path,syntax_ok:$syntax_ok,flags_ok:$flags_ok,missing:$missing}'
      [[ "$status" == "pass" ]]
      ;;
    fixture-state)
      local path="${1:-}"
      if [[ -z "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"fixture-state",status:"refused",reason:"path required"}'
        return 64
      fi
      if [[ ! -d "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"fixture-state",status:"fail",path:$p,reason:"path not a directory"}'
        return 1
      fi
      local missing=()
      [[ -f "$path/source/AGENTS.md" ]] || missing+=("source/AGENTS.md")
      [[ -d "$path/repos" ]] || missing+=("repos/")
      local status="pass"
      if (( ${#missing[@]} > 0 )); then status="fail"; fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg status "$status" \
        --arg p "$path" \
        --argjson missing "$(printf '%s\n' "${missing[@]:-}" | grep -v '^$' | jq -R . | jq -cs .)" \
        '{schema_version:$sv,command:"validate",subject:"fixture-state",status:$status,path:$p,missing:$missing}'
      [[ "$status" == "pass" ]]
      ;;
    ""|--json|--help|-h)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["sync-binary","fixture-state"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["sync-binary","fixture-state"]}'
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
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.action // "") | contains($id)) or ((.outcome // "") | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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
ROOT="/Users/josh/Developer/flywheel"
SYNC="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
BEGIN="<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
END="<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-canonical-doctrine-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
export SYNC_CANONICAL_LEDGER="$TMP/doctrine-sync-ledger.jsonl"

CANONICAL="$TMP/source/AGENTS.md"
mkdir -p "$(dirname "$CANONICAL")"
printf '# Canonical doctrine\n\n## L61 - synthetic ecosystem rule\nbody\n\n## L70 - synthetic no-punt rule\nbody\n' >"$CANONICAL"

for repo in repo-a repo-b repo-c; do
  mkdir -p "$TMP/repos/$repo/.flywheel"
  cat >"$TMP/repos/$repo/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "flywheel",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "flywheel"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "flywheel"},
    {"path": ".flywheel/rules", "owner_class": "flywheel"},
    {"path": ".flywheel/doctrine", "owner_class": "flywheel"},
    {"path": ".flywheel/scripts", "owner_class": "flywheel"},
    {"path": ".flywheel/launchd", "owner_class": "flywheel"},
    {"path": ".flywheel/validation-schema", "owner_class": "flywheel"},
    {"path": ".claude/settings.json", "owner_class": "flywheel"}
  ]
}
JSON
done
cp "$CANONICAL" "$TMP/repos/repo-a/.flywheel/AGENTS-CANONICAL.md"
printf 'old doctrine\n' >"$TMP/repos/repo-b/.flywheel/AGENTS-CANONICAL.md"
printf 'older doctrine\n' >"$TMP/repos/repo-c/.flywheel/AGENTS-CANONICAL.md"

printf '# Repo A local instructions\n\nKeep this line.\n' >"$TMP/repos/repo-a/AGENTS.md"
printf '# Repo B local instructions\n\n%s\nstale block\n%s\n\nKeep after block.\n' "$BEGIN" "$END" >"$TMP/repos/repo-b/AGENTS.md"

rc=0
dry="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json 2>&1)" || rc=$?
if [[ "$rc" -ne 1 ]]; then
  printf 'FAIL: dry-run expected rc=1 for drift, got %s\n%s\n' "$rc" "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.canonical_drifted_count' <<<"$dry")" != "2" ]]; then
  printf 'FAIL: dry-run expected canonical_drifted_count=2\n%s\n' "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.root_drifted_count' <<<"$dry")" != "3" ]]; then
  printf 'FAIL: dry-run expected root_drifted_count=3\n%s\n' "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '[.root_details[] | select(.status=="drifted" and (.missing_rules | index("L70")))] | length' <<<"$dry")" != "3" ]]; then
  printf 'FAIL: dry-run expected L70 root drift detection for all repos\n%s\n' "$dry" >&2
  exit 1
fi

apply="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --apply --idempotency-key synthetic-apply-1 --json)"
if [[ "$(jq -r '.status' <<<"$apply")" != "ok" || "$(jq -r '.canonical_synced_count' <<<"$apply")" != "2" || "$(jq -r '.root_synced_count' <<<"$apply")" != "3" ]]; then
  printf 'FAIL: apply expected status=ok canonical_synced_count=2 root_synced_count=3\n%s\n' "$apply" >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-b/.flywheel"/AGENTS-CANONICAL.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-b canonical snapshot backup missing before overwrite\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'old doctrine' "$TMP/repos/repo-b/.flywheel"/AGENTS-CANONICAL.md.bak.*; then
  printf 'FAIL: repo-b canonical snapshot backup did not preserve prior content\n' >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-a"/AGENTS.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-a root AGENTS.md backup missing before canonical block insert\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'Keep this line.' "$TMP/repos/repo-a"/AGENTS.md.bak.*; then
  printf 'FAIL: repo-a root AGENTS.md backup did not preserve prior content\n' >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-b"/AGENTS.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-b root AGENTS.md backup missing before canonical block replace\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'stale block' "$TMP/repos/repo-b"/AGENTS.md.bak.*; then
  printf 'FAIL: repo-b root AGENTS.md backup did not preserve prior block\n' >&2
  exit 1
fi

for repo in repo-a repo-b repo-c; do
  if ! diff -q "$CANONICAL" "$TMP/repos/$repo/.flywheel/AGENTS-CANONICAL.md" >/dev/null 2>&1; then
    printf 'FAIL: %s target did not match canonical after apply\n' "$repo" >&2
    exit 1
  fi
  if [[ "$(grep -c 'L70' "$TMP/repos/$repo/AGENTS.md")" -lt 1 ]]; then
    printf 'FAIL: %s root AGENTS.md missing L70 after apply\n' "$repo" >&2
    exit 1
  fi
done
if ! grep -q 'Keep this line.' "$TMP/repos/repo-a/AGENTS.md"; then
  printf 'FAIL: repo-a root AGENTS.md lost local content outside canonical block\n' >&2
  exit 1
fi
if ! grep -q 'Keep after block.' "$TMP/repos/repo-b/AGENTS.md"; then
  printf 'FAIL: repo-b root AGENTS.md lost trailing content outside canonical block\n' >&2
  exit 1
fi

post="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json)"
if [[ "$(jq -r '.status' <<<"$post")" != "ok" || "$(jq -r '.drifted_count' <<<"$post")" != "0" ]]; then
  printf 'FAIL: post-apply dry-run expected clean status\n%s\n' "$post" >&2
  exit 1
fi

before_hash="$(shasum -a 256 "$TMP/repos/repo-a/AGENTS.md" | awk '{print $1}')"
rerun="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --apply --idempotency-key synthetic-apply-2 --json)"
after_hash="$(shasum -a 256 "$TMP/repos/repo-a/AGENTS.md" | awk '{print $1}')"
if [[ "$(jq -r '.synced_count' <<<"$rerun")" != "0" || "$before_hash" != "$after_hash" ]]; then
  printf 'FAIL: idempotent re-run changed root AGENTS.md\n%s\n' "$rerun" >&2
  exit 1
fi

missing_rc=0
missing_output="$(SYNC_CANONICAL_SOURCE="$TMP/missing/AGENTS.md" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json 2>&1)" || missing_rc=$?
if [[ "$missing_rc" -ne 2 ]]; then
  printf 'FAIL: missing source expected rc=2, got %s\n%s\n' "$missing_rc" "$missing_output" >&2
  exit 1
fi
if [[ "$(jq -r '.errors[0].code // empty' <<<"$missing_output")" != "source_missing" ]]; then
  printf 'FAIL: missing source expected source_missing code\n%s\n' "$missing_output" >&2
  exit 1
fi

mkdir -p "$TMP/blocked/repo-skillos/.flywheel"
printf 'old doctrine\n' >"$TMP/blocked/repo-skillos/.flywheel/AGENTS-CANONICAL.md"
printf '# SkillOS local instructions\n' >"$TMP/blocked/repo-skillos/AGENTS.md"
cat >"$TMP/blocked/repo-skillos/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "skillos",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "skillos"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "skillos"}
  ]
}
JSON
blocked_rc=0
blocked="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/blocked" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --apply --idempotency-key blocked-ownership --json 2>&1)" || blocked_rc=$?
if [[ "$blocked_rc" -ne 2 ]]; then
  printf 'FAIL: blocked ownership apply expected rc=2, got %s\n%s\n' "$blocked_rc" "$blocked" >&2
  exit 1
fi
if [[ "$(jq -r '.ownership_blocked_count' <<<"$blocked")" -lt 1 ]]; then
  printf 'FAIL: blocked ownership apply expected ownership_blocked_count > 0\n%s\n' "$blocked" >&2
  exit 1
fi
if [[ "$(jq -r '.errors[0].code // empty' <<<"$blocked")" != "canonical_ownership_gate_blocked" ]]; then
  printf 'FAIL: blocked ownership apply expected canonical_ownership_gate_blocked error\n%s\n' "$blocked" >&2
  exit 1
fi
if grep -q 'L70' "$TMP/blocked/repo-skillos/AGENTS.md" || grep -q 'L70' "$TMP/blocked/repo-skillos/.flywheel/AGENTS-CANONICAL.md"; then
  printf 'FAIL: ownership-blocked repo was mutated\n%s\n' "$blocked" >&2
  exit 1
fi

printf 'PASS: sync-canonical-doctrine synthetic test passed\n'

# Append harness-run record to audit log so audit / health / why subcommands
# have data to work with. Best-effort; never fail the test because of telemetry.
if command -v cli_audit_append >/dev/null 2>&1; then
  cli_audit_append "$SCAFFOLD_AUDIT_LOG" "harness_run" "pass" \
    "$(jq -nc --arg outcome "synthetic_test_passed" '{outcome:$outcome,fixture_canonical_drifted:2,fixture_root_drifted:3}')" 2>/dev/null || true
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
