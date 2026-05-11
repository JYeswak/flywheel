#!/usr/bin/env bash
# codex-budget-watchdog.sh — when fleet is draining AND all codex panes idle,
# auto-rotate to next caam profile.
#
# Run as a launchd job every 60s OR via flywheel:tick.
#
# Decision tree:
#   1. read codex-budget state
#   2. if fleet_state=ready → no-op
#   3. if fleet_state=draining or limit_hit:
#      a. check ALL codex panes across ALL ntm sessions
#      b. if any THINKING/GENERATING → wait (let in-flight finish)
#      c. if all WAITING → invoke rotate-codex with next profile
#      d. log decision to ledger

set -euo pipefail

STATE_FILE="${CODEX_BUDGET_STATE:-$HOME/.local/state/flywheel/codex-account-budget.json}"
LEDGER="$HOME/.local/state/flywheel/codex-budget-watchdog.jsonl"
ROTATE="$HOME/.local/bin/rotate-codex"
APPLY=0
NEXT_PROFILE="${CODEX_NEXT_PROFILE:-}"

mkdir -p "$(dirname "$LEDGER")"


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.5)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is inserted between the original env wiring and the original
# argparse loop. Default invocation (no canonical subcommand / intro flag)
# falls through to the original watchdog logic (now exposed as `cmd_run`).
# Canonical subcommands intercept BEFORE the original `while` arg loop runs.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="codex-budget-watchdog/v1"
# The watchdog's existing LEDGER is the audit log for this surface — health
# and audit bind to it directly per AG3 ("health binds audit log"). Override
# via SCAFFOLD_AUDIT_LOG if a probe wants a distinct path.
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$LEDGER}"

scaffold_usage() {
  cat <<'USG'
usage: codex-budget-watchdog.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
watchdog (now exposed as `cmd_run`) — reads codex-account-budget.json,
checks all codex panes via ntm, and rotates to next caam profile when
fleet is draining/limit_hit AND every codex pane is idle.

Canonical CLI surfaces:
  doctor [--json]          probe substrate health (jq/ntm/rotate-codex/ledger)
  health [--json]          last-run status (ledger tail + fleet_state)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, state-file-prime
  validate <subject> [...] validate per-subject contract
                            Subjects: row, schema, config, state-file, ledger
  audit [--json]           recent run history (ledger tail)
  why <id>                 explain provenance for a given id
                            (id matches profile, action, or any ledger field)
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "codex-budget-watchdog.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "codex-budget-watchdog.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG,CODEX_BUDGET_STATE,CODEX_NEXT_PROFILE" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run (dry-run)",invocation:"codex-budget-watchdog.sh",purpose:"check fleet state; skip if ready; wait if any codex pane THINKING"}'
)"$'\n'"$(jq -nc '{name:"apply rotate",invocation:"codex-budget-watchdog.sh --apply --next-profile gpt-5-mini",purpose:"invoke ~/.local/bin/rotate-codex when fleet draining + all codex idle"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"codex-budget-watchdog.sh doctor --json",purpose:"probe jq/ntm/rotate-codex/ledger writable"}'
)"$'\n'"$(jq -nc '{name:"why",invocation:"codex-budget-watchdog.sh why gpt-5-mini",purpose:"search ledger for rotate_invoked rows with that profile"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"codex-budget-watchdog.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"check current decision",command:"codex-budget-watchdog.sh health --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"dry-run rotate",command:"codex-budget-watchdog.sh --next-profile gpt-5-mini"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","state_file","fleet_state?"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","state-file-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","state_file?","fleet_state?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","state-file","ledger"],fields:["status","subject","valid?","missing?","reason?","state_file?","ledger?","row_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"action|profile|detail-substring"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["ts","action"],optional:["detail"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"codex-budget-watchdog: rotates caam profile when fleet draining + codex panes idle; ledger at ~/.local/state/flywheel/codex-budget-watchdog.jsonl"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — original watchdog logic; reads $CODEX_BUDGET_STATE, checks all codex panes via ntm --robot-activity, rotates profile via ~/.local/bin/rotate-codex when fleet draining/limit_hit AND every codex pane idle. --apply requires --next-profile (or env CODEX_NEXT_PROFILE).\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: jq, /Users/josh/.local/bin/ntm, ~/.local/bin/rotate-codex, state-file parent dir, ledger writable, flywheel root.\n' ;;
    health)   printf 'topic: health — tails ledger (= audit log); warn stale >7d. Also reports state-file fleet_state.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), state-file-prime (read-only — probes codex-account-budget.json shape).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --state-file (probes codex-account-budget.json shape), --ledger (probes codex-budget-watchdog.jsonl row schema).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "codex-budget-watchdog" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--next-profile" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "codex-budget-watchdog" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (filled-in per flywheel-5ke66.5) ----------

scaffold_cmd_doctor() {
  # Substrate: jq, ntm bin, rotate-codex bin, state-file parent dir, ledger writable, flywheel root.
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local ntm_bin="/Users/josh/.local/bin/ntm"
  local rotate_bin="$ROTATE"
  local checks="" overall="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$ntm_bin" ]]; then
    checks+="$(jq -nc --arg p "$ntm_bin" '{name:"ntm_bin_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$ntm_bin" '{name:"ntm_bin_executable",status:"fail",value:$p,detail:"used for --robot-activity codex pane state probe"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$rotate_bin" ]]; then
    checks+="$(jq -nc --arg p "$rotate_bin" '{name:"rotate_codex_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$rotate_bin" '{name:"rotate_codex_executable",status:"fail",value:$p,detail:"invoked under --apply --next-profile"}')"$'\n'
    overall="fail"
  fi

  local state_dir; state_dir="$(dirname "$STATE_FILE")"
  if [[ -d "$state_dir" && -w "$state_dir" ]] || mkdir -p "$state_dir" 2>/dev/null; then
    local state_present="false"; [[ -r "$STATE_FILE" ]] && state_present="true"
    checks+="$(jq -nc --arg p "$STATE_FILE" --argjson sp "$state_present" '{name:"state_file_dir_writable",status:"pass",value:$p,state_file_present:$sp}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$STATE_FILE" '{name:"state_file_dir_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$LEDGER" ]] && row_count="$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$LEDGER" --argjson rc "${row_count:-0}" '{name:"ledger_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$LEDGER" '{name:"ledger_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$script_root" ]]; then
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local last_row="null" stale_seconds=-1 status="warn"
  local fleet_state="null" state_present=false
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // empty' 2>/dev/null || true)"
      if [[ -n "$last_ts" ]]; then
        local last_epoch now_epoch
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date -u +%s)"
        if [[ "$last_epoch" -gt 0 ]]; then
          stale_seconds=$((now_epoch - last_epoch))
          if [[ "$stale_seconds" -le 604800 ]]; then status="pass"; fi
        fi
      fi
    fi
  fi
  if [[ -r "$STATE_FILE" ]]; then
    state_present=true
    fleet_state="$(jq -r '.fleet_state // "unknown"' "$STATE_FILE" 2>/dev/null || echo unknown)"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --arg sf "$STATE_FILE" --argjson sp "$state_present" --arg fs "$fleet_state" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,state_file:$sf,state_file_present:$sp,fleet_state:$fs}'
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
    audit-log-rotate)
      local log="$SCAFFOLD_AUDIT_LOG"
      local size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        if mv "$log" "$rotated_path" 2>/dev/null; then
          : > "$log" 2>/dev/null || true
          rotated=true
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    state-file-prime)
      # Read-only: probe codex-account-budget.json shape.
      local present=false parseable=false has_fleet_state=false fleet_state=null has_fleet_panes=false
      if [[ -r "$STATE_FILE" ]]; then
        present=true
        if jq -e '.' "$STATE_FILE" >/dev/null 2>&1; then
          parseable=true
          if jq -e '.fleet_state' "$STATE_FILE" >/dev/null 2>&1; then
            has_fleet_state=true
            fleet_state="$(jq -c '.fleet_state' "$STATE_FILE" 2>/dev/null || echo null)"
          fi
          if jq -e '.fleet_panes' "$STATE_FILE" >/dev/null 2>&1; then
            has_fleet_panes=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true || "$parseable" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg sf "$STATE_FILE" --arg s "$status" \
        --argjson present "$present" --argjson parseable "$parseable" \
        --argjson hfs "$has_fleet_state" --argjson hfp "$has_fleet_panes" --argjson fs "$fleet_state" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,state_file:$sf,present:$present,parseable:$parseable,has_fleet_state:$hfs,has_fleet_panes:$hfp,fleet_state:$fs,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","state-file-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --state-file) subject="state-file"; shift ;;
      --ledger) subject="ledger"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  case "$subject" in
    row)
      local valid=true missing=""
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"--row-json required"}'
        return 0
      fi
      if ! printf '%s' "$row_json" | jq -e '.' >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"invalid_json"}'
        return 0
      fi
      for f in ts action; do
        if ! printf '%s' "$row_json" | jq -e --arg k "$f" 'has($k)' >/dev/null 2>&1; then
          valid=false; missing="${missing}${f},"
        fi
      done
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" --arg m "${missing%,}" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $v then "pass" else "fail" end),valid:$v,missing:$m}'
      ;;
    schema)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"schema",status:"pass",surfaces:["doctor","health","repair","validate","audit","why","audit-row"]}'
      ;;
    config)
      local jq_ok=false ntm_ok=false rotate_ok=false state_dir_ok=false ledger_dir_ok=false root_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -x "/Users/josh/.local/bin/ntm" ]] && ntm_ok=true
      [[ -x "$ROTATE" ]] && rotate_ok=true
      [[ -d "$(dirname "$STATE_FILE")" ]] && state_dir_ok=true
      [[ -d "$(dirname "$LEDGER")" ]] && ledger_dir_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$jq_ok" != true || "$ntm_ok" != true || "$rotate_ok" != true || "$state_dir_ok" != true || "$ledger_dir_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson ntm "$ntm_ok" --argjson rot "$rotate_ok" \
        --argjson sd "$state_dir_ok" --argjson ld "$ledger_dir_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg sf "$STATE_FILE" --arg ledger "$LEDGER" --arg rotbin "$ROTATE" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,ntm_bin_present:$ntm,rotate_codex_present:$rot,state_dir_present:$sd,ledger_dir_present:$ld,flywheel_root_present:$rt,flywheel_root:$root,state_file:$sf,ledger:$ledger,rotate_bin:$rotbin}'
      ;;
    state-file)
      # surface-specific: probe codex-account-budget.json shape.
      local present=false parseable=false has_fleet_state=false fleet_state=null has_fleet_panes=false size_bytes=0
      if [[ -r "$STATE_FILE" ]]; then
        present=true
        size_bytes="$(stat -f '%z' "$STATE_FILE" 2>/dev/null || echo 0)"
        if jq -e '.' "$STATE_FILE" >/dev/null 2>&1; then
          parseable=true
          if jq -e '.fleet_state' "$STATE_FILE" >/dev/null 2>&1; then
            has_fleet_state=true
            fleet_state="$(jq -c '.fleet_state' "$STATE_FILE" 2>/dev/null || echo null)"
          fi
          if jq -e '.fleet_panes' "$STATE_FILE" >/dev/null 2>&1; then
            has_fleet_panes=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$parseable" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg sf "$STATE_FILE" \
        --argjson present "$present" --argjson parseable "$parseable" \
        --argjson hfs "$has_fleet_state" --argjson hfp "$has_fleet_panes" --argjson fs "$fleet_state" \
        --argjson sz "${size_bytes:-0}" \
        '{schema_version:$sv,command:"validate",subject:"state-file",status:$s,state_file:$sf,present:$present,parseable:$parseable,has_fleet_state:$hfs,has_fleet_panes:$hfp,fleet_state:$fs,size_bytes:$sz}'
      ;;
    ledger)
      # surface-specific: probe ledger row count + last row schema.
      local present=false rows=0 last_row=null last_row_valid=false rotate_invoked_count=0
      if [[ -r "$LEDGER" ]]; then
        present=true
        rows="$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ' || echo 0)"
        rotate_invoked_count="$(grep -c '"action":"rotate_invoked"' "$LEDGER" 2>/dev/null; true)"
        local raw; raw="$(tail -n 1 "$LEDGER" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          if printf '%s' "$raw" | jq -e 'has("ts") and has("action")' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg ledger "$LEDGER" \
        --argjson present "$present" --argjson r "${rows:-0}" --argjson ric "${rotate_invoked_count:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"ledger",status:$s,ledger:$ledger,present:$present,row_count:$r,rotate_invoked_count:$ric,last_row:$lr,last_row_valid:$lrv}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","state-file","ledger"],usage:"validate --row-json JSON or --schema or --config or --state-file or --ledger"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","state-file","ledger"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local limit=50
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="${2:-50}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) shift ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local rows="[]" count=0
    if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -sc '. // []' 2>/dev/null || echo '[]')"
      count="$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)"
    fi
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rows "$rows" --argjson count "$count" \
      '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local matches="[]" status="not_found"
  local any_source_present=false
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    any_source_present=true
    local raw
    raw="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
      matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
    fi
  fi
  if [[ "$any_source_present" != true ]]; then
    status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

# ---------- scaffolded main dispatcher ----------

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
# original `while [ $# -gt 0 ]` argparse loop sees the args.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
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

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --next-profile) NEXT_PROFILE="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 2 ;;
  esac
done

log() {
  local action="$1" detail="${2:-}"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"$action\",\"detail\":\"$detail\"}" >> "$LEDGER"
}

if [ ! -f "$STATE_FILE" ]; then
  log "skip" "no_state_file"
  exit 0
fi

FLEET_STATE=$(jq -r '.fleet_state // "ready"' "$STATE_FILE")

if [ "$FLEET_STATE" = "ready" ]; then
  log "skip" "fleet_state=ready"
  exit 0
fi

# === fleet is draining or limit_hit — check all codex panes idle ===
# `|| true` keeps set -e from exiting when ntm/awk pipeline returns non-zero
# (e.g., empty sessions list); empty $SESSIONS just skips the loop body.
SESSIONS=$(/Users/josh/.local/bin/ntm list 2>/dev/null | awk -F: '/[a-z].*windows/ {gsub(/^ +/,"",$1); print $1}' || true)

THINKING_PANES=""
TOTAL_CODEX=0
IDLE_CODEX=0

for sess in $SESSIONS; do
  PANES=$(/Users/josh/.local/bin/ntm --robot-activity="$sess" --activity-type=codex 2>/dev/null | jq -r '.agents[] | "\(.pane_idx)|\(.state)"' 2>/dev/null || true)
  if [ -z "$PANES" ]; then continue; fi
  while IFS='|' read -r pane state; do
    [ -z "$pane" ] && continue
    TOTAL_CODEX=$((TOTAL_CODEX + 1))
    case "$state" in
      WAITING) IDLE_CODEX=$((IDLE_CODEX + 1)) ;;
      THINKING|GENERATING) THINKING_PANES="$THINKING_PANES $sess:$pane" ;;
    esac
  done <<< "$PANES"
done

ALL_IDLE=0
[ "$TOTAL_CODEX" -gt 0 ] && [ "$IDLE_CODEX" = "$TOTAL_CODEX" ] && ALL_IDLE=1

# === Update state file with fleet idle status ===
TMP=$(mktemp /tmp/.budget-state.XXXXXX.json)
jq --argjson total "$TOTAL_CODEX" --argjson idle "$IDLE_CODEX" --argjson all_idle "$ALL_IDLE" \
   --arg thinking "$THINKING_PANES" \
  '. + {fleet_panes: {total_codex: $total, idle_codex: $idle, all_idle: ($all_idle == 1), thinking_panes: $thinking}}' \
  "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"

# === Decision ===
if [ "$ALL_IDLE" = "0" ]; then
  log "wait_for_idle" "thinking=$THINKING_PANES idle=$IDLE_CODEX/$TOTAL_CODEX state=$FLEET_STATE"
  echo "[wait] fleet_state=$FLEET_STATE; $IDLE_CODEX/$TOTAL_CODEX codex panes idle; thinking on:$THINKING_PANES"
  exit 0
fi

# All idle — rotate
echo "[ready_to_rotate] fleet_state=$FLEET_STATE; all $TOTAL_CODEX codex panes idle"

if [ "$APPLY" = "0" ]; then
  log "would_rotate_dry_run" "all_idle=$IDLE_CODEX/$TOTAL_CODEX"
  echo "[dry-run] would invoke: $ROTATE ${NEXT_PROFILE:-<interactive>}"
  exit 0
fi

# Apply
if [ -z "$NEXT_PROFILE" ]; then
  echo "[error] --apply requires --next-profile NAME (or env CODEX_NEXT_PROFILE)" >&2
  log "abort" "no_next_profile"
  exit 1
fi

log "rotate_invoked" "profile=$NEXT_PROFILE all_idle=$IDLE_CODEX/$TOTAL_CODEX"
"$ROTATE" "$NEXT_PROFILE"
ROTATE_EXIT=$?
log "rotate_done" "exit=$ROTATE_EXIT profile=$NEXT_PROFILE"
exit $ROTATE_EXIT
