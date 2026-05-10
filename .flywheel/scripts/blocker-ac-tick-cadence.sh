#!/usr/bin/env bash
# blocker-ac-tick-cadence.sh — orch tick wrapper that fires
# flywheel_replay_verify --blocker-ac on stale blockers every Nth tick.
#
# Per blocker-discipline.md (substrate-hygiene-doctrine-cluster):
#   "ac_check_interval_ticks (optional) — per-blocker override for AC
#    re-evaluation cadence. Default: 4 (every 4 ticks)."
#
# This wrapper is the orch-side enforcement of that mandate. It:
#
#   1. Increments a per-repo tick counter ($SCAFFOLD_COUNTER_FILE).
#   2. Discovers blocker JSON files at $SCAFFOLD_BLOCKER_GLOB
#      (default: .flywheel/state/blockers/*.json).
#   3. For each blocker:
#      - Read ac_check_interval_ticks (default $SCAFFOLD_DEFAULT_N = 4).
#      - Read last_verified_at; skip if not stale (default <24h).
#      - If counter MOD N == 0: invoke flywheel_replay_verify --blocker-ac
#        on the blocker file.
#      - Append per-blocker verdict row to $SCAFFOLD_AUDIT_LOG.
#   4. Emit composite envelope summarizing fire/skip/error counts.
#
# Wired into orch per-tick chain via .flywheel/scripts/tick-driver-manifest.json.
#
# Bead: flywheel-e4ulf (blocker-ac tick-wire-in)
# Source: .flywheel/scripts/flywheel_replay_verify.py (flywheel-5m9gp)
# Doctrine: .flywheel/doctrine/blocker-discipline.md (worker rule #4)
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-e4ulf) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-e4ulf)

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="blocker-ac-tick-cadence/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/blocker-ac-tick-cadence-runs.jsonl}"
SCAFFOLD_COUNTER_FILE="${BLOCKER_AC_COUNTER_FILE:-$HOME/.local/state/flywheel/blocker-ac-tick-counter.json}"
SCAFFOLD_BLOCKER_GLOB="${BLOCKER_AC_BLOCKER_GLOB:-$_SCAFFOLD_REPO_ROOT/.flywheel/state/blockers/*.json}"
SCAFFOLD_REPLAY_VERIFY="${BLOCKER_AC_REPLAY_VERIFY:-$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/flywheel_replay_verify.py}"
SCAFFOLD_DEFAULT_N="${BLOCKER_AC_DEFAULT_N:-4}"
SCAFFOLD_STALE_THRESHOLD_HOURS="${BLOCKER_AC_STALE_HOURS:-24}"

scaffold_usage() {
  cat <<'USG'
usage: blocker-ac-tick-cadence.sh [SUBCOMMAND] [OPTIONS]

Default invocation: increment tick counter, scan blockers, fire AC re-eval
every Nth tick on stale blockers per blocker-discipline.md.

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status from $SCAFFOLD_AUDIT_LOG
  repair --scope <s>       audit_log_dir | audit_log_truncate | counter_reset
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: blocker-file PATH | counter-state | audit-row
  audit [--json] [N]       tail $SCAFFOLD_AUDIT_LOG (default 20 rows)
  why <id>                 provenance: id is row index (numeric, neg=tail) or substring match
  quickstart [--json]      operator orientation
  help <topic>             topic help
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "blocker-ac-tick-cadence.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "blocker-ac-tick-cadence.sh" \
    "v1.0.0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG,SCAFFOLD_COUNTER_FILE,SCAFFOLD_BLOCKER_GLOB,SCAFFOLD_REPLAY_VERIFY,SCAFFOLD_DEFAULT_N,SCAFFOLD_STALE_THRESHOLD_HOURS" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default tick",invocation:"blocker-ac-tick-cadence.sh --json",purpose:"increment counter + AC-fire stale blockers every Nth tick"}'
)"$'\n'"$(jq -nc '{name:"validate single blocker",invocation:"blocker-ac-tick-cadence.sh validate blocker-file /path/to/blocker.json",purpose:"shape-check blocker JSON without firing AC"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"blocker-ac-tick-cadence.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,validate"
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
          mode:"\"dry_run\"|\"apply\"",scope:"\"audit_log_dir\"|\"audit_log_truncate\"|\"counter_reset\"",
          idempotency_key:"string|null",planned_actions:"[obj]",applied_actions:"[obj]"}}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"validate\"",subject:"\"blocker-file\"|\"counter-state\"|\"audit-row\"",
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
    run|tick|default)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"tick\"",status:"\"pass\"|\"warn\"|\"fail\"",
          tick_counter:"int",default_n:"int",
          blocker_count:"int",fired:"int",skipped_not_nth:"int",skipped_fresh:"int",skipped_no_ac:"int",errors:"int",
          per_blocker:"[{blocker_id,n,counter_mod_n,verdict,reason}]"}}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          known_surfaces:["tick","doctor","health","repair","validate","audit","why"]}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run|tick) printf 'topic: tick — increments tick counter, scans blocker JSON files at $SCAFFOLD_BLOCKER_GLOB, fires flywheel_replay_verify --blocker-ac on blockers where counter MOD ac_check_interval_ticks == 0 AND last_verified_at is stale (>%sh). No-op gracefully when no blockers exist.\n' "$SCAFFOLD_STALE_THRESHOLD_HOURS" ;;
    doctor)   printf 'topic: doctor — probes substrate (replay-verify python script, blocker glob dir, counter file dir, jq/python3 deps, audit log dir, repo root, helper-lib). Pass = wrapper ready; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 cadence runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows), counter_reset (reset tick counter to 0). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: blocker-file PATH (verify required fields: acceptance_condition, last_verified_at, ac_check_interval_ticks); counter-state (emit current tick counter); audit-row JSONL (verify ts/status fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows). Each row: ts, action, status, sha256, blocker_id, verdict, ac_passes_now.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / blocker_id / verdict fields.\n' ;;
    *)        printf 'topics: tick | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) printf 'topic: completion <bash|zsh> — emit shell completion script\n'; return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "blocker-ac-tick-cadence" "doctor,health,repair,validate,audit,why,quickstart,help,completion,tick" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "blocker-ac-tick-cadence" "doctor,health,repair,validate,audit,why,quickstart,help,completion,tick" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface ----------

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/batc-doctor.XXXXXX")"
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

  if [[ -x "$SCAFFOLD_REPLAY_VERIFY" ]]; then
    add_check replay_verify_executable pass "$SCAFFOLD_REPLAY_VERIFY"
  elif [[ -f "$SCAFFOLD_REPLAY_VERIFY" ]]; then
    add_check replay_verify_executable warn "exists but not executable: $SCAFFOLD_REPLAY_VERIFY"
  else
    add_check replay_verify_executable fail "missing: $SCAFFOLD_REPLAY_VERIFY"
  fi

  local glob_dir; glob_dir="$(dirname "$SCAFFOLD_BLOCKER_GLOB")"
  if [[ -d "$glob_dir" ]]; then
    add_check blocker_glob_dir_present pass "$glob_dir"
  else
    add_check blocker_glob_dir_present warn "blocker dir absent: $glob_dir (no blockers to verify; cadence will no-op)"
  fi

  local counter_dir; counter_dir="$(dirname "$SCAFFOLD_COUNTER_FILE")"
  if [[ -d "$counter_dir" && -w "$counter_dir" ]]; then
    add_check counter_dir_writable pass "$counter_dir"
  elif [[ -d "$counter_dir" ]]; then
    add_check counter_dir_writable warn "exists but not writable: $counter_dir"
  else
    add_check counter_dir_writable warn "missing dir; will be created on first tick"
  fi

  for tool in jq python3 mktemp grep awk; do
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

  if [[ "$SCAFFOLD_DEFAULT_N" =~ ^[0-9]+$ ]] && [[ "$SCAFFOLD_DEFAULT_N" -ge 1 ]] \
     && [[ "$SCAFFOLD_STALE_THRESHOLD_HOURS" =~ ^[0-9]+$ ]] && [[ "$SCAFFOLD_STALE_THRESHOLD_HOURS" -ge 1 ]]; then
    add_check thresholds_sane pass "default_n=$SCAFFOLD_DEFAULT_N stale_hours=$SCAFFOLD_STALE_THRESHOLD_HOURS"
  else
    add_check thresholds_sane fail "thresholds invalid: default_n=$SCAFFOLD_DEFAULT_N stale_hours=$SCAFFOLD_STALE_THRESHOLD_HOURS"
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
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no cadence runs recorded yet"}'
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
    audit_log_dir|audit_log_truncate|counter_reset) ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:null,reason:"--scope required",valid_scopes:["audit_log_dir","audit_log_truncate","counter_reset"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit_log_dir","audit_log_truncate","counter_reset"]}'
      return 0 ;;
  esac

  local planned_tmp applied_tmp
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/batc-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/batc-repair-applied.XXXXXX")"
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
    counter_reset)
      if [[ -f "$SCAFFOLD_COUNTER_FILE" ]]; then
        local cur_counter; cur_counter="$(jq -r '.counter // 0' "$SCAFFOLD_COUNTER_FILE" 2>/dev/null || echo 0)"
        jq -nc --arg path "$SCAFFOLD_COUNTER_FILE" --argjson cur "$cur_counter" \
          '{action:"counter_reset",target:$path,current:$cur,new:0}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          mkdir -p "$(dirname "$SCAFFOLD_COUNTER_FILE")"
          jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{counter:0,reset_ts:$ts}' >"$SCAFFOLD_COUNTER_FILE"
          jq -nc --arg path "$SCAFFOLD_COUNTER_FILE" --argjson cur "$cur_counter" \
            '{action:"counter_reset",target:$path,was:$cur,now:0,result:"ok"}' >>"$applied_tmp"
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
    blocker-file)
      local path="${1:-}"
      if [[ -z "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"blocker-file",status:"refused",reason:"path required"}'
        return 64
      fi
      if [[ ! -r "$path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"blocker-file",status:"fail",path:$p,reason:"path not readable"}'
        return 1
      fi
      local raw; raw="$(cat "$path")"
      if ! jq -e . >/dev/null 2>&1 <<<"$raw"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" \
          '{schema_version:$sv,command:"validate",subject:"blocker-file",status:"fail",path:$p,reason:"file is not valid JSON"}'
        return 1
      fi
      local missing=()
      for f in acceptance_condition last_verified_at; do
        jq -e --arg f "$f" 'has($f)' >/dev/null 2>&1 <<<"$raw" || missing+=("$f")
      done
      if (( ${#missing[@]} == 0 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" --argjson row "$raw" \
          '{schema_version:$sv,command:"validate",subject:"blocker-file",status:"pass",path:$p,row:$row}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg p "$path" --argjson row "$raw" \
          --argjson missing "$(printf '%s\n' "${missing[@]}" | jq -R . | jq -cs .)" \
          '{schema_version:$sv,command:"validate",subject:"blocker-file",status:"fail",path:$p,reason:"missing required fields per blocker-discipline.md",missing:$missing,row:$row}'
        return 1
      fi
      ;;
    counter-state)
      local cur=0 last_ts=""
      if [[ -f "$SCAFFOLD_COUNTER_FILE" ]]; then
        cur="$(jq -r '.counter // 0' "$SCAFFOLD_COUNTER_FILE" 2>/dev/null || echo 0)"
        last_ts="$(jq -r '.last_tick_ts // ""' "$SCAFFOLD_COUNTER_FILE" 2>/dev/null || echo "")"
      fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg path "$SCAFFOLD_COUNTER_FILE" \
        --argjson cur "$cur" \
        --arg last_ts "$last_ts" \
        --argjson n "$SCAFFOLD_DEFAULT_N" \
        '{schema_version:$sv,command:"validate",subject:"counter-state",status:"pass",counter_file:$path,counter:$cur,last_tick_ts:(if $last_ts=="" then null else $last_ts end),default_n:$n,fires_on_next_tick:(($cur + 1) % $n == 0)}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["blocker-file","counter-state","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["blocker-file","counter-state","audit-row"]}'
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
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.blocker_id // "") | contains($id)) or ((.verdict // "") | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
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

# ---------- core tick primitive ----------

# Read counter (default 0), increment, write back, return new counter value via stdout.
_batc_increment_counter() {
  local cur=0
  if [[ -f "$SCAFFOLD_COUNTER_FILE" ]]; then
    cur="$(jq -r '.counter // 0' "$SCAFFOLD_COUNTER_FILE" 2>/dev/null || echo 0)"
  fi
  local new=$((cur + 1))
  mkdir -p "$(dirname "$SCAFFOLD_COUNTER_FILE")"
  jq -nc --argjson c "$new" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{counter:$c,last_tick_ts:$ts}' >"$SCAFFOLD_COUNTER_FILE"
  printf '%s\n' "$new"
}

# _batc_is_stale ISO_TS THRESHOLD_HOURS — exits 0 if stale, 1 if fresh, 2 if invalid input
_batc_is_stale() {
  local ts="$1" hours="$2"
  if [[ -z "$ts" ]]; then return 0; fi  # missing ts = stale
  local now_epoch ts_epoch
  now_epoch="$(date -u +%s)"
  ts_epoch="$(python3 -c "
import sys, datetime
try:
    s = sys.argv[1].replace('Z','+00:00')
    print(int(datetime.datetime.fromisoformat(s).timestamp()))
except Exception:
    print(0)
" "$ts" 2>/dev/null || echo 0)"
  if [[ "$ts_epoch" -eq 0 ]]; then return 2; fi
  local age=$((now_epoch - ts_epoch))
  local threshold=$((hours * 3600))
  [[ "$age" -ge "$threshold" ]]
}

batc_tick() {
  local json_out=0
  for arg in "$@"; do
    [[ "$arg" == "--json" ]] && json_out=1
  done

  # Increment counter
  local counter; counter="$(_batc_increment_counter)"

  # Discover blocker files
  local blocker_files=()
  shopt -s nullglob
  # shellcheck disable=SC2206
  blocker_files=( $SCAFFOLD_BLOCKER_GLOB )
  shopt -u nullglob

  local blocker_count=${#blocker_files[@]}
  local fired=0 skipped_not_nth=0 skipped_fresh=0 skipped_no_ac=0 errors=0
  local per_blocker_tmp; per_blocker_tmp="$(mktemp "${TMPDIR:-/tmp}/batc-perblocker.XXXXXX")"
  trap 'rm -f "$per_blocker_tmp"' RETURN
  : >"$per_blocker_tmp"

  for blocker_file in "${blocker_files[@]}"; do
    local blocker_id n last_verified ac
    blocker_id="$(jq -r '.blocker_id // .id // ""' "$blocker_file" 2>/dev/null)"
    [[ -z "$blocker_id" ]] && blocker_id="$(basename "$blocker_file" .json)"
    n="$(jq -r ".ac_check_interval_ticks // ${SCAFFOLD_DEFAULT_N}" "$blocker_file" 2>/dev/null)"
    [[ "$n" =~ ^[0-9]+$ ]] || n=$SCAFFOLD_DEFAULT_N
    [[ "$n" -lt 1 ]] && n=$SCAFFOLD_DEFAULT_N
    ac="$(jq -r '.acceptance_condition // ""' "$blocker_file" 2>/dev/null)"
    last_verified="$(jq -r '.last_verified_at // ""' "$blocker_file" 2>/dev/null)"

    if [[ -z "$ac" ]]; then
      skipped_no_ac=$((skipped_no_ac + 1))
      jq -nc --arg b "$blocker_id" --argjson n "$n" --argjson cmod "$((counter % n))" \
        '{blocker_id:$b,n:$n,counter_mod_n:$cmod,verdict:"skipped",reason:"no_acceptance_condition"}' >>"$per_blocker_tmp"
      continue
    fi

    local cmod=$((counter % n))
    if [[ "$cmod" -ne 0 ]]; then
      skipped_not_nth=$((skipped_not_nth + 1))
      jq -nc --arg b "$blocker_id" --argjson n "$n" --argjson cmod "$cmod" \
        '{blocker_id:$b,n:$n,counter_mod_n:$cmod,verdict:"skipped",reason:"not_nth_tick"}' >>"$per_blocker_tmp"
      continue
    fi

    if ! _batc_is_stale "$last_verified" "$SCAFFOLD_STALE_THRESHOLD_HOURS"; then
      skipped_fresh=$((skipped_fresh + 1))
      jq -nc --arg b "$blocker_id" --argjson n "$n" --argjson cmod "$cmod" --arg lv "$last_verified" \
        '{blocker_id:$b,n:$n,counter_mod_n:$cmod,verdict:"skipped",reason:"fresh",last_verified_at:$lv}' >>"$per_blocker_tmp"
      continue
    fi

    # Fire AC re-eval. --json must come AFTER `blocker-ac` subcommand so it
    # binds to the subparser's --json (parent --json is text-mode).
    local ac_out ac_rc=0
    ac_out="$(python3 "$SCAFFOLD_REPLAY_VERIFY" blocker-ac --json --blocker-file "$blocker_file" 2>&1)" || ac_rc=$?
    local ac_verdict ac_passes_now
    if jq -e . >/dev/null 2>&1 <<<"$ac_out"; then
      ac_verdict="$(jq -r '.verdict // "unknown"' <<<"$ac_out")"
      ac_passes_now="$(jq -r '.ac_passes_now // false' <<<"$ac_out")"
    else
      ac_verdict="error"
      ac_passes_now="false"
    fi

    if [[ "$ac_rc" -eq 0 && "$ac_verdict" == "PASS" ]]; then
      fired=$((fired + 1))
      jq -nc --arg b "$blocker_id" --argjson n "$n" --argjson cmod "$cmod" --arg verdict "$ac_verdict" --arg passes "$ac_passes_now" \
        '{blocker_id:$b,n:$n,counter_mod_n:$cmod,verdict:"fired",ac_verdict:$verdict,ac_passes_now:$passes}' >>"$per_blocker_tmp"
    else
      errors=$((errors + 1))
      jq -nc --arg b "$blocker_id" --argjson n "$n" --argjson cmod "$cmod" --arg verdict "$ac_verdict" --argjson rc "$ac_rc" \
        '{blocker_id:$b,n:$n,counter_mod_n:$cmod,verdict:"error",ac_verdict:$verdict,replay_verify_rc:$rc}' >>"$per_blocker_tmp"
    fi

    # Per-blocker audit row
    if command -v cli_audit_append >/dev/null 2>&1; then
      cli_audit_append "$SCAFFOLD_AUDIT_LOG" "blocker_ac_fire" "$ac_verdict" \
        "$(jq -nc --arg b "$blocker_id" --argjson cnt "$counter" --argjson n "$n" \
           --arg v "$ac_verdict" --arg p "$ac_passes_now" \
           '{blocker_id:$b,counter:$cnt,n:$n,verdict:$v,ac_passes_now:$p}')" 2>/dev/null || true
    fi
  done

  local status="pass"
  if [[ "$errors" -gt 0 ]]; then status="warn"; fi

  local PAYLOAD
  PAYLOAD="$(jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --argjson counter "$counter" \
    --argjson n "$SCAFFOLD_DEFAULT_N" \
    --argjson bc "$blocker_count" \
    --argjson f "$fired" \
    --argjson sn "$skipped_not_nth" \
    --argjson sf "$skipped_fresh" \
    --argjson sa "$skipped_no_ac" \
    --argjson e "$errors" \
    --slurpfile pb "$per_blocker_tmp" \
    '{schema_version:$sv,command:"tick",ts:$ts,status:$status,
      tick_counter:$counter,default_n:$n,
      blocker_count:$bc,fired:$f,skipped_not_nth:$sn,skipped_fresh:$sf,skipped_no_ac:$sa,errors:$e,
      per_blocker:$pb}')"

  if [[ "$json_out" -eq 1 ]]; then
    printf '%s\n' "$PAYLOAD"
  else
    jq -r '"blocker-ac-tick-cadence counter=\(.tick_counter) blockers=\(.blocker_count) fired=\(.fired) skipped=\(.skipped_not_nth + .skipped_fresh + .skipped_no_ac) errors=\(.errors)"' <<<"$PAYLOAD"
  fi

  # Composite-run audit row
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "tick" "$status" \
      "$(jq -nc --argjson c "$counter" --argjson f "$fired" --argjson e "$errors" \
         '{counter:$c,fired:$f,errors:$e}')" 2>/dev/null || true
  fi

  if [[ "$status" == "fail" ]]; then return 1; fi
  return 0
}

# ---------- scaffolded main dispatcher ----------

scaffold_main() {
  if [[ $# -eq 0 ]]; then
    batc_tick "$@"
    exit $?
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
    tick)         shift; batc_tick "$@"; exit $? ;;
    --json)       batc_tick "$@"; exit $? ;;
    *)
      printf 'ERR: unknown subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

scaffold_main "$@"
