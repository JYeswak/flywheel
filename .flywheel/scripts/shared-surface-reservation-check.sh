#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.18)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# CRITICAL coexistence design: this IS the L107 reservation tool used by
# every other wave-2 surface during scaffold work. The script's operational
# surfaces (--check / --reserve / --release / --list / --doctor / --health)
# MUST keep working unchanged. Existing tests/shared-surface-reservation-check.sh
# asserts:
#   --info:   .schema_version=="shared-surface-reservation/v1"
#              AND (.mutating_commands | index("--reserve"))
#   --schema: .exit_codes."1"=="reserved by another pane"
#              AND (.commands | index("--check <path>"))
#
# Strategy: bash early-dispatch ONLY intercepts canonical no-dash subcommand
# forms (`doctor`, `health`, `repair`, `validate`, `audit`, `why`, `quickstart`,
# `help`, `completion`) plus `--examples` (NEW). The dash-flag forms
# (--check / --reserve / --release / --list / --doctor / --health / --info /
# --schema) fall through to python so:
#   - --reserve / --release / --check / --list operational paths unchanged
#   - --info / --schema python output unchanged (backward-compat 100%)
#   - --doctor / --health python output unchanged
# The bash scaffold adds NEW no-dash subcommands as AG3-compliant surfaces
# alongside python's existing dash-flag surfaces. Two distinct surface
# families coexist.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="shared-surface-reservation/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/file-reservations.jsonl}"
SCAFFOLD_FUCKUP_LOG="${SCAFFOLD_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: shared-surface-reservation-check.sh [SUBCOMMAND|FLAG] [OPTIONS]

This script blocks cross-pane git-add collisions on shared flywheel
surfaces before staging.

Operational dash-flag surfaces (python — UNCHANGED; load-bearing for L107):
  --check PATH                       check if a path is reserved
  --reserve PATH --pane=N --task-id  reserve a path for a pane
  --release PATH --pane=N            release a reserved path
  --list                             list all current reservations
  --doctor                           python doctor output
  --health                           python health output
  --info --json                      python --info envelope (test:33 asserts)
  --schema --json                    python --schema envelope (test:36 asserts)

Canonical CLI surfaces (bash scaffold — NEW; coexists with dash-flags):
  doctor [--json]                    canonical AG3 doctor envelope
                                     (distinct from python's --doctor surface)
  health [--json]                    canonical AG3 health envelope
                                     (distinct from python's --health surface)
  repair --scope <s>                 repair misconfigured state
                                     Default: --dry-run; mutate with --apply --idempotency-key KEY
                                     Scopes: audit-log-rotate, ledger-prime
  validate <subject> [...]           subjects: row, schema, config, ledger, fuckup-log
  audit [--json]                     recent ledger rows
  why <id>                           explain provenance (pane | task_id | path-substring)
  quickstart [--json]                operator orientation
  help <topic>                       topic help
  completion <shell>                 emit shell completion

Introspection (NEW):
  --examples --json                  canonical examples envelope
                                     (python has no --examples today)
USG
}

scaffold_emit_examples() {
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{
      schema_version: $sv,
      command: "examples",
      examples: [
        "shared-surface-reservation-check.sh --reserve /path/to/file --pane=3 --task-id=t1 --json",
        "shared-surface-reservation-check.sh --release /path/to/file --pane=3 --json",
        "shared-surface-reservation-check.sh --check /path/to/file --pane=3 --json",
        "shared-surface-reservation-check.sh --list --json",
        "shared-surface-reservation-check.sh doctor --json",
        "shared-surface-reservation-check.sh validate --ledger --json"
      ]
    }'
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe canonical doctor",command:"shared-surface-reservation-check.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"see active reservations",command:"shared-surface-reservation-check.sh --list --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"reserve a path",command:"shared-surface-reservation-check.sh --reserve /path --pane=3 --task-id=mytask --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — load-bearing L107 reservation tool. Use --reserve/--release dash-flag forms for the actual reservation API; bash doctor/health/etc. subcommands are separate canonical introspection surfaces.\n' ;;
    doctor)   printf 'topic: doctor — canonical doctor (substrate probes). For python doctor-output use `--doctor` (with dash).\n' ;;
    health)   printf 'topic: health — canonical health (audit-log freshness). For python health-output use `--health` (with dash).\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), ledger-prime (read-only — probes file-reservations.jsonl row count).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON (reservation row schema), --schema, --config, --ledger (probes file-reservations.jsonl), --fuckup-log (probes coordination-collision fuckup rows).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh>\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "shared-surface-reservation-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--examples,--check,--reserve,--release,--list,--info,--schema,--pane,--session,--task-id" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "shared-surface-reservation-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

scaffold_cmd_doctor() {
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local checks="" overall="pass"

  if command -v python3 >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v python3)" '{name:"python3_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"python3_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  local ledger_dir; ledger_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$SCAFFOLD_AUDIT_LOG" ]] && row_count="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" --argjson rc "${row_count:-0}" '{name:"ledger_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" '{name:"ledger_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local fl_present=false fl_rows=0
  if [[ -r "$SCAFFOLD_FUCKUP_LOG" ]]; then
    fl_present=true
    fl_rows="$(wc -l < "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
  fi
  local fl_status="pass"; [[ "$fl_present" != true ]] && fl_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_FUCKUP_LOG" --arg s "$fl_status" --argjson present "$fl_present" --argjson rows "${fl_rows:-0}" \
    '{name:"fuckup_log_present",status:$s,value:$p,present:$present,row_count:$rows}')"$'\n'

  # ntm bin probe (used by --check for ntm conflicts native surface).
  local ntm_bin="/Users/josh/.local/bin/ntm"
  if [[ -x "$ntm_bin" ]]; then
    checks+="$(jq -nc --arg p "$ntm_bin" '{name:"ntm_bin_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$ntm_bin" '{name:"ntm_bin_executable",status:"warn",value:$p,detail:"used by --check for ntm conflicts probe"}')"$'\n'
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
  local active_reservations=0 release_count=0 collision_count=0
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
    active_reservations="$(grep -c '"action":"reserve"' "$log" 2>/dev/null; true)"
    release_count="$(grep -c '"action":"release"' "$log" 2>/dev/null; true)"
  fi
  [[ -r "$SCAFFOLD_FUCKUP_LOG" ]] && collision_count="$(grep -c '"trauma_class":"coordination-collision-detected"' "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null; true)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson ar "${active_reservations:-0}" --argjson rc "${release_count:-0}" --argjson cc "${collision_count:-0}" \
    --arg fuckup "$SCAFFOLD_FUCKUP_LOG" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,reserve_count:$ar,release_count:$rc,fuckup_log:$fuckup,collision_count:$cc}'
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
    ledger-prime)
      local present=false rows=0 reserves=0 releases=0
      if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        reserves="$(grep -c '"action":"reserve"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        releases="$(grep -c '"action":"release"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg log "$SCAFFOLD_AUDIT_LOG" --arg s "$status" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson reserves "${reserves:-0}" --argjson releases "${releases:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,ledger:$log,present:$present,row_count:$rows,reserve_count:$reserves,release_count:$releases,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","ledger-prime"]}'
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
      --ledger) subject="ledger"; shift ;;
      --fuckup-log) subject="fuckup-log"; shift ;;
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
      # Reservation row schema from python's --schema ledger_row.
      for f in action pane path session task_id ts; do
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
      local py_ok=false jq_ok=false ledger_dir_ok=false fuckup_ok=false root_ok=false
      command -v python3 >/dev/null 2>&1 && py_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -d "$(dirname "$SCAFFOLD_AUDIT_LOG")" ]] && ledger_dir_ok=true
      [[ -r "$SCAFFOLD_FUCKUP_LOG" ]] && fuckup_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$py_ok" != true || "$jq_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson py "$py_ok" --argjson jqq "$jq_ok" \
        --argjson ld "$ledger_dir_ok" --argjson fl "$fuckup_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg log "$SCAFFOLD_AUDIT_LOG" --arg fuckup "$SCAFFOLD_FUCKUP_LOG" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,python3_present:$py,jq_present:$jqq,ledger_dir_present:$ld,fuckup_log_present:$fl,flywheel_root_present:$rt,flywheel_root:$root,ledger:$log,fuckup_log:$fuckup}'
      ;;
    ledger)
      local present=false rows=0 reserves=0 releases=0 last_row=null last_row_valid=false
      if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        reserves="$(grep -c '"action":"reserve"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        releases="$(grep -c '"action":"release"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          if printf '%s' "$raw" | jq -e 'has("action") and has("pane") and has("path") and has("ts")' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg log "$SCAFFOLD_AUDIT_LOG" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson reserves "${reserves:-0}" --argjson releases "${releases:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"ledger",status:$s,ledger:$log,present:$present,row_count:$rows,reserve_count:$reserves,release_count:$releases,last_row:$lr,last_row_valid:$lrv}'
      ;;
    fuckup-log)
      local present=false rows=0 collisions=0
      if [[ -r "$SCAFFOLD_FUCKUP_LOG" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        collisions="$(grep -c '"trauma_class":"coordination-collision-detected"' "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null; true)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg fl "$SCAFFOLD_FUCKUP_LOG" \
        --argjson present "$present" --argjson rows "${rows:-0}" --argjson collisions "${collisions:-0}" \
        '{schema_version:$sv,command:"validate",subject:"fuckup-log",status:$s,fuckup_log:$fl,present:$present,row_count:$rows,collision_count:$collisions}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","ledger","fuckup-log"],usage:"validate --row-json JSON or --schema or --config or --ledger or --fuckup-log"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","ledger","fuckup-log"]}'
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

scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
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

# IMPORTANT: this matcher does NOT include --info / --schema / -h / --help
# because the python heredoc owns those dash-flag forms and existing
# tests/shared-surface-reservation-check.sh asserts on their exact shape.
# Only no-dash subcommand forms + --examples (which python doesn't have)
# are intercepted.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --examples) return 0 ;;
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

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import fcntl
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

VERSION = "shared-surface-reservation/v1"
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/file-reservations.jsonl"
DEFAULT_FUCKUP_LOG = Path.home() / ".local/state/flywheel/fuckup-log.jsonl"


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_ts(value):
    if not value:
        return None
    text = str(value)
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def normalize_path(path: str, cwd: str | None = None) -> str:
    raw = Path(path).expanduser()
    if not raw.is_absolute():
        raw = Path(cwd or os.getcwd()) / raw
    return str(raw.resolve(strict=False))


def read_rows(path: Path):
    rows = []
    malformed = []
    if not path.exists():
        return rows, malformed
    with path.open(encoding="utf-8", errors="ignore") as handle:
        for line_no, line in enumerate(handle, 1):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except Exception:
                malformed.append({"line": line_no, "raw": line[:160]})
                continue
            if not isinstance(row, dict):
                malformed.append({"line": line_no, "raw": line[:160]})
                continue
            row["__line"] = line_no
            rows.append(row)
    return rows, malformed


def current_holders(rows):
    state: dict[str, list[dict]] = {}
    for row in rows:
        action = row.get("action")
        path = row.get("path")
        pane = str(row.get("pane", ""))
        if not path or not pane:
            continue
        if action == "reserve":
            state.setdefault(path, [])
            if not any(str(item.get("pane")) == pane for item in state[path]):
                state[path].append(row)
        elif action == "release":
            state[path] = [item for item in state.get(path, []) if str(item.get("pane")) != pane]
    return {path: holders for path, holders in state.items() if holders}


def ntm_conflicts_snapshot(args, path: str | None = None) -> dict | None:
    ntm_bin = os.environ.get("NTM_BIN", "/Users/josh/.local/bin/ntm")
    cmd = [ntm_bin, "conflicts", args.session, "--json", "--limit", "50"]
    try:
        proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=8, check=False)
    except Exception as exc:
        return {"status": "unavailable", "error": str(exc), "native_surface": "ntm conflicts --json"}
    try:
        payload = json.loads(proc.stdout or "null")
    except Exception:
        payload = None
    if payload is None:
        return {"status": "ok", "raw": None, "exit_code": proc.returncode, "native_surface": "ntm conflicts --json"}
    conflict_count = 0
    path_hit = False
    conflicts = payload.get("conflicts") if isinstance(payload, dict) else []
    if isinstance(conflicts, list):
        conflict_count = len(conflicts)
        if path:
            path_hit = any(path in json.dumps(row, sort_keys=True) for row in conflicts)
    return {
        "status": payload.get("status", "ok") if isinstance(payload, dict) else "ok",
        "exit_code": proc.returncode,
        "conflict_count": conflict_count,
        "path_hit": path_hit,
        "native_surface": "ntm conflicts --json",
        "raw": payload,
    }


def append_jsonl(path: Path, row: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def emit(payload: dict, json_mode: bool):
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
    else:
        status = payload.get("status", "ok")
        detail = payload.get("detail") or payload.get("reason") or ""
        print(f"{status}{': ' + detail if detail else ''}")


def lock_ledger(ledger: Path):
    ledger.parent.mkdir(parents=True, exist_ok=True)
    lock_path = ledger.with_suffix(ledger.suffix + ".lock")
    lock_handle = lock_path.open("a+")
    fcntl.flock(lock_handle, fcntl.LOCK_EX)
    return lock_handle


def infer_pane(value):
    if value is not None:
        return str(value)
    for key in ("FLYWHEEL_PANE", "PANE", "NTM_PANE"):
        env = os.environ.get(key)
        if env:
            return str(env)
    return None


def log_collision(args, path, holders, checked_at):
    row = {
        "ts": checked_at,
        "session": args.session,
        "pane": args.pane,
        "agent": "shared-surface-reservation-check",
        "host": os.uname().nodename,
        "git_repo": str(Path.cwd()),
        "commit_sha": None,
        "trauma_class": "coordination-collision-detected",
        "severity": "medium",
        "what_happened": f"coordination-collision-detected: pane={args.pane} path={path}",
        "what_attempted": ["shared-surface-reservation-check --check"],
        "what_worked": [],
        "rule_violated_or_proven": "L107 shared-surface writes must reserve across panes",
        "evidence": [f"holder_panes={','.join(str(h.get('pane')) for h in holders)}", f"path={path}"],
        "should_become": "tool-patch",
        "processed_at": None,
        "processed_into": None,
    }
    append_jsonl(Path(args.fuckup_log), row)


def check_path(args, rows, malformed, checked_at):
    path = normalize_path(args.check, args.cwd)
    pane = infer_pane(args.pane)
    native_conflicts = ntm_conflicts_snapshot(args, path)
    holders = current_holders(rows).get(path, [])
    blockers = [h for h in holders if pane is None or str(h.get("pane")) != str(pane)]
    payload = {
        "schema_version": VERSION,
        "status": "blocked" if blockers else "free",
        "path": path,
        "pane": pane,
        "holders": holders,
        "blocking_holders": blockers,
        "ntm_conflicts": native_conflicts,
        "malformed_rows_count": len(malformed),
        "warnings": [{"code": "malformed_row_skipped", **m} for m in malformed[:5]],
    }
    if blockers:
        payload["detail"] = f"coordination-collision-detected: pane={blockers[0].get('pane')} path={path}"
        log_collision(args, path, blockers, checked_at)
        emit(payload, args.json)
        return 1
    emit(payload, args.json)
    return 0


def reserve_path(args, rows, malformed, checked_at):
    path = normalize_path(args.reserve, args.cwd)
    pane = infer_pane(args.pane)
    if pane is None:
        emit({"schema_version": VERSION, "status": "usage_error", "reason": "--pane is required for --reserve"}, args.json)
        return 2
    holders = current_holders(rows).get(path, [])
    native_conflicts = ntm_conflicts_snapshot(args, path)
    blockers = [h for h in holders if str(h.get("pane")) != str(pane)]
    if blockers:
        log_collision(args, path, blockers, checked_at)
        emit({
            "schema_version": VERSION,
            "status": "blocked",
            "path": path,
            "pane": pane,
            "blocking_holders": blockers,
            "ntm_conflicts": native_conflicts,
            "detail": f"coordination-collision-detected: pane={blockers[0].get('pane')} path={path}",
            "malformed_rows_count": len(malformed),
        }, args.json)
        return 1
    if not any(str(h.get("pane")) == str(pane) for h in holders):
        append_jsonl(Path(args.ledger), {
            "ts": checked_at,
            "session": args.session,
            "pane": pane,
            "task_id": args.task_id,
            "path": path,
            "action": "reserve",
        })
    emit({
        "schema_version": VERSION,
        "status": "reserved",
        "path": path,
        "pane": pane,
        "task_id": args.task_id,
        "ntm_conflicts": native_conflicts,
        "malformed_rows_count": len(malformed),
    }, args.json)
    return 0


def release_path(args, rows, malformed, checked_at):
    path = normalize_path(args.release, args.cwd)
    pane = infer_pane(args.pane)
    if pane is None:
        emit({"schema_version": VERSION, "status": "usage_error", "reason": "--pane is required for --release"}, args.json)
        return 2
    append_jsonl(Path(args.ledger), {
        "ts": checked_at,
        "session": args.session,
        "pane": pane,
        "task_id": args.task_id,
        "path": path,
        "action": "release",
    })
    emit({
        "schema_version": VERSION,
        "status": "released",
        "path": path,
        "pane": pane,
        "malformed_rows_count": len(malformed),
    }, args.json)
    return 0


def list_current(args, rows, malformed):
    current = current_holders(rows)
    payload = {
        "schema_version": VERSION,
        "status": "ok",
        "ledger": args.ledger,
        "reservations": [{"path": path, "holders": holders} for path, holders in sorted(current.items())],
        "active_count": sum(len(v) for v in current.values()),
        "ntm_conflicts": ntm_conflicts_snapshot(args),
        "malformed_rows_count": len(malformed),
        "warnings": [{"code": "malformed_row_skipped", **m} for m in malformed[:5]],
    }
    emit(payload, args.json)
    return 0


def doctor(args, rows, malformed):
    since = datetime.now(timezone.utc) - timedelta(hours=24)
    collisions = 0
    fuckup_rows, fuckup_malformed = read_rows(Path(args.fuckup_log))
    for row in fuckup_rows:
        if row.get("trauma_class") != "coordination-collision-detected":
            continue
        ts = parse_ts(row.get("ts"))
        if ts and ts >= since:
            collisions += 1
    payload = {
        "schema_version": VERSION,
        "status": "pass" if collisions == 0 else "warn",
        "coordination_collision_count_24h": collisions,
        "active_reservation_count": sum(len(v) for v in current_holders(rows).values()),
        "ntm_conflicts": ntm_conflicts_snapshot(args),
        "malformed_rows_count": len(malformed),
        "fuckup_malformed_rows_count": len(fuckup_malformed),
        "ledger": args.ledger,
        "fuckup_log": args.fuckup_log,
    }
    emit(payload, args.json)
    return 0


def info(args):
    payload = {
        "schema_version": VERSION,
        "command": "shared-surface-reservation-check.sh",
        "purpose": "Block cross-pane git-add collisions on shared flywheel surfaces before staging.",
        "ledger": args.ledger,
        "fuckup_log": args.fuckup_log,
        "mutating_commands": ["--reserve", "--release"],
        "native_surface": "ntm conflicts --json",
        "dry_run_default": False,
    }
    emit(payload, args.json)


def schema(args):
    payload = {
        "schema_version": VERSION,
        "ledger_row": {"ts": "ISO8601", "session": "string", "pane": "string", "task_id": "string", "path": "absolute path", "action": "reserve|release"},
        "commands": ["--check <path>", "--reserve <path> --pane=<N> --task-id=<id>", "--release <path> --pane=<N>", "--list", "--doctor"],
        "exit_codes": {"0": "free or mutation recorded", "1": "reserved by another pane", "2": "usage error"},
    }
    emit(payload, args.json)


def examples(args):
    lines = [
        "shared-surface-reservation-check.sh --reserve /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop --pane=3 --task-id=shared-surface-reservation-patch",
        "shared-surface-reservation-check.sh --check /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop --pane=3",
        "shared-surface-reservation-check.sh --release /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop --pane=3",
        "shared-surface-reservation-check.sh --doctor --json",
    ]
    if args.json:
        print(json.dumps({"schema_version": VERSION, "examples": lines}, sort_keys=True))
    else:
        print("\n".join(lines))


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Shared-surface reservation checker")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--check")
    group.add_argument("--reserve")
    group.add_argument("--release")
    group.add_argument("--list", action="store_true")
    group.add_argument("--doctor", action="store_true")
    group.add_argument("--health", action="store_true")
    group.add_argument("--info", action="store_true")
    group.add_argument("--schema", action="store_true")
    group.add_argument("--examples", action="store_true")
    parser.add_argument("--pane")
    parser.add_argument("--session", default=os.environ.get("FLYWHEEL_SESSION", "flywheel"))
    parser.add_argument("--task-id", default=os.environ.get("FLYWHEEL_TASK_ID", "unknown"))
    parser.add_argument("--ledger", default=os.environ.get("FLYWHEEL_SHARED_SURFACE_RESERVATIONS", str(DEFAULT_LEDGER)))
    parser.add_argument("--fuckup-log", default=os.environ.get("FLYWHEEL_FUCKUP_LOG", str(DEFAULT_FUCKUP_LOG)))
    parser.add_argument("--cwd", default=os.getcwd())
    parser.add_argument("--json", action="store_true")
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.info:
        info(args)
        return 0
    if args.schema:
        schema(args)
        return 0
    if args.examples:
        examples(args)
        return 0

    ledger = Path(args.ledger)
    checked_at = iso_now()
    with lock_ledger(ledger):
        rows, malformed = read_rows(ledger)
        if args.check:
            return check_path(args, rows, malformed, checked_at)
        if args.reserve:
            return reserve_path(args, rows, malformed, checked_at)
        if args.release:
            return release_path(args, rows, malformed, checked_at)
        if args.list:
            return list_current(args, rows, malformed)
        if args.doctor or args.health:
            return doctor(args, rows, malformed)
    emit({"schema_version": VERSION, "status": "usage_error", "reason": "choose one command"}, args.json)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
