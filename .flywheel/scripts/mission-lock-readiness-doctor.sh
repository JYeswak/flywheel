#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: mission-lock readiness keeps scaffold, native readiness aggregation, validator composition, and fixture-facing CLI in one portable operator surface.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic is filled in below for this mission-lock readiness surface.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="mission-lock-readiness-doctor/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/mission-lock-readiness-doctor-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: mission-lock-readiness-doctor.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --exit-codes             document domain exit codes
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "mission-lock-readiness-doctor.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "mission-lock-readiness-doctor.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"mission-lock-readiness-doctor.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"mission-lock-readiness-doctor.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"mission-lock-readiness-doctor.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{status:"pass|warn|fail",checks:"[{name,status,detail}]",ts:"iso8601"}}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{status:"pass|warn|empty",total_runs:"integer",last_run_ts:"iso8601|null",last_status:"string|null",pass_rate:"number|null"}}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit_log_dir","audit_log_truncate"],apply_requires_idempotency_key:true}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["readiness-state","audit-row"],required:{readiness_state:["mission_lock_readiness_health_score","blocked_surfaces","phase0_scaffold_bead_suggestions","repair_receipt_identity_fields"],audit_row:["ts","action","status"]}}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{status:"pass|empty|missing",row_count:"integer",recent:"array"}}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,lookup:"numeric row index, negative tail index, or substring matched against audit rows"}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,known_surfaces:["doctor","health","repair","validate","audit","why"]}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — probes jq, python3, repo root, default mission file, three upstream validators, audit-log writability, and helper-lib load state.\n' ;;
    health)   printf 'topic: health — summarizes the last 50 mission-lock readiness audit rows from %s.\n' "$SCAFFOLD_AUDIT_LOG" ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (create audit parent), audit_log_truncate (keep last 1000 rows). Default dry-run; --apply requires --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: readiness-state JSON and audit-row JSON. Both are pure-read schema checks.\n' ;;
    audit)    printf 'topic: audit — tails %s (default 20 rows).\n' "$SCAFFOLD_AUDIT_LOG" ;;
    why)      printf 'topic: why — lookup an audit row by numeric index, negative tail index, or substring.\n' ;;
    completion) printf 'topic: completion — emit bash or zsh completion helpers for mission-lock-readiness-doctor.\n' ;;
    exit-codes) scaffold_emit_exit_codes ;;
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
            && cli_emit_completion_bash "mission-lock-readiness-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "mission-lock-readiness-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

scaffold_emit_exit_codes() {
  cat <<'EOF'
0 success: command completed or readiness is fully healthy.
1 validation/domain failure: readiness incomplete, malformed row, or repair failed.
2 usage error: missing argument or unknown subject/scope.
3 transient retry: upstream validator, filesystem, or audit substrate temporarily unavailable.
4 blocked by gate: explicit readiness or idempotency gate prevents mutation.
EOF
}

# ---------- canonical-cli filled surfaces (bead flywheel-5wuhe) ----------

scaffold_now() {
  if command -v iso_now >/dev/null 2>&1; then
    iso_now
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

scaffold_append_audit() {
  local action="$1" status="$2" detail="${3:-{}}"
  mkdir -p "$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "$action" "$status" "$detail"
  else
    jq -nc \
      --arg ts "$(scaffold_now)" \
      --arg action "$action" \
      --arg status "$status" \
      --argjson detail "$detail" \
      '{ts:$ts,action:$action,status:$status,detail:$detail}' >>"$SCAFFOLD_AUDIT_LOG"
  fi
}

scaffold_cmd_doctor() {
  local checks_tmp status mission schema_validator scaffold_validator lens_merge audit_dir
  checks_tmp="$(mktemp "${TMPDIR:-/tmp}/mission-lock-doctor.XXXXXX")"
  trap 'rm -f "$checks_tmp"' RETURN
  : >"$checks_tmp"
  status="pass"
  add_check() {
    local name="$1" stat="$2" detail="$3"
    jq -nc --arg name "$name" --arg status "$stat" --arg detail "$detail" \
      '{name:$name,status:$status,detail:$detail}' >>"$checks_tmp"
    if [[ "$stat" == "fail" ]]; then
      status="fail"
    elif [[ "$stat" == "warn" && "$status" != "fail" ]]; then
      status="warn"
    fi
  }

  mission="$_SCAFFOLD_REPO_ROOT/.flywheel/MISSION.md"
  schema_validator="$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh"
  scaffold_validator="$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/mission-lock-scaffold-validator.sh"
  lens_merge="$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/plan-state-lens-merge.sh"
  audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"

  command -v jq >/dev/null 2>&1 && add_check jq_available pass "$(command -v jq)" || add_check jq_available fail "jq not on PATH"
  command -v python3 >/dev/null 2>&1 && add_check python3_available pass "$(command -v python3)" || add_check python3_available warn "python3 not on PATH"
  [[ -d "$_SCAFFOLD_REPO_ROOT/.flywheel" ]] && add_check flywheel_dir_present pass "$_SCAFFOLD_REPO_ROOT/.flywheel" || add_check flywheel_dir_present fail "$_SCAFFOLD_REPO_ROOT/.flywheel missing"
  [[ -r "$mission" ]] && add_check mission_default_readable pass "$mission" || add_check mission_default_readable fail "$mission missing or unreadable"
  [[ -x "$schema_validator" ]] && add_check schema_validator_executable pass "$schema_validator" || add_check schema_validator_executable warn "$schema_validator missing or not executable"
  [[ -x "$scaffold_validator" ]] && add_check scaffold_validator_executable pass "$scaffold_validator" || add_check scaffold_validator_executable warn "$scaffold_validator missing or not executable"
  [[ -x "$lens_merge" ]] && add_check lens_merge_executable pass "$lens_merge" || add_check lens_merge_executable warn "$lens_merge missing or not executable"
  if [[ -d "$audit_dir" && -w "$audit_dir" ]]; then
    add_check audit_log_dir_writable pass "$audit_dir"
  elif [[ -d "$audit_dir" ]]; then
    add_check audit_log_dir_writable warn "$audit_dir exists but is not writable"
  else
    add_check audit_log_dir_writable warn "$audit_dir missing; repair --scope audit_log_dir will create it"
  fi
  if command -v cli_emit_info >/dev/null 2>&1; then
    add_check helper_lib_loaded pass "$_SCAFFOLD_HELPER_LIB"
  else
    add_check helper_lib_loaded warn "$_SCAFFOLD_HELPER_LIB not loaded"
  fi

  jq -cs --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(scaffold_now)" --arg status "$status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}' "$checks_tmp"
  [[ "$status" != "fail" ]]
}

scaffold_cmd_health() {
  local window total_runs last_run_ts last_status pass_count sample pass_rate status
  window=50
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(scaffold_now)" --argjson window "$window" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"empty",total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$window}'
    return 0
  fi
  total_runs="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
  [[ -z "$total_runs" ]] && total_runs=0
  if [[ "$total_runs" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(scaffold_now)" --argjson window "$window" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"empty",total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$window}'
    return 0
  fi
  last_run_ts="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.ts // ""' 2>/dev/null || true)"
  last_status="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.status // "unknown"' 2>/dev/null || true)"
  pass_count="$(tail -n "$window" "$SCAFFOLD_AUDIT_LOG" | jq -s '[.[] | select(.status == "pass" or .status == "ok" or .status == "applied")] | length' 2>/dev/null || printf 0)"
  [[ "$total_runs" -lt "$window" ]] && sample="$total_runs" || sample="$window"
  pass_rate="$(awk -v p="$pass_count" -v s="$sample" 'BEGIN{if (s>0) printf "%.4f", p/s; else printf "0"}')"
  status="pass"
  [[ "$last_status" == "fail" || "$last_status" == "refused" ]] && status="warn"
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(scaffold_now)" \
    --arg status "$status" \
    --arg last_ts "$last_run_ts" \
    --arg last_status "$last_status" \
    --argjson total "$total_runs" \
    --argjson rate "$pass_rate" \
    --argjson window "$sample" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,total_runs:$total,last_run_ts:(if $last_ts=="" then null else $last_ts end),last_status:(if $last_status=="" then null else $last_status end),pass_rate:$rate,window:$window}'
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
    audit_log_dir|audit_log_truncate) ;;
    "")
      if [[ "$mode" == "dry_run" ]]; then
        scope="audit_log_dir"
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" \
          '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:null,reason:"--scope required",valid_scopes:["audit_log_dir","audit_log_truncate"]}'
        return 0
      fi ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit_log_dir","audit_log_truncate"]}'
      return 0 ;;
  esac

  local planned_tmp applied_tmp audit_dir row_count keep
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/mission-lock-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/mission-lock-repair-applied.XXXXXX")"
  trap 'rm -f "$planned_tmp" "$applied_tmp"' RETURN
  : >"$planned_tmp"
  : >"$applied_tmp"
  case "$scope" in
    audit_log_dir)
      audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      if [[ ! -d "$audit_dir" ]]; then
        jq -nc --arg target "$audit_dir" '{action:"mkdir_audit_log_dir",target:$target}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          mkdir -p "$audit_dir"
          jq -nc --arg target "$audit_dir" '{action:"mkdir_audit_log_dir",target:$target,result:"ok"}' >>"$applied_tmp"
        fi
      fi
      ;;
    audit_log_truncate)
      keep=1000
      row_count=0
      [[ -f "$SCAFFOLD_AUDIT_LOG" ]] && row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
      [[ -z "$row_count" ]] && row_count=0
      if [[ "$row_count" -gt "$keep" ]]; then
        jq -nc --arg target "$SCAFFOLD_AUDIT_LOG" --argjson row_count "$row_count" --argjson keep "$keep" \
          '{action:"truncate_audit_log",target:$target,row_count:$row_count,keep:$keep,rows_to_drop:($row_count - $keep)}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          local tmp_file
          tmp_file="$(mktemp "${SCAFFOLD_AUDIT_LOG}.trunc.XXXXXX")"
          tail -n "$keep" "$SCAFFOLD_AUDIT_LOG" >"$tmp_file" && mv "$tmp_file" "$SCAFFOLD_AUDIT_LOG"
          jq -nc --arg target "$SCAFFOLD_AUDIT_LOG" --argjson keep "$keep" '{action:"truncate_audit_log",target:$target,kept:$keep,result:"ok"}' >>"$applied_tmp"
        fi
      fi
      ;;
  esac
  if [[ "$mode" == "apply" ]]; then
    scaffold_append_audit "repair" "applied" "$(jq -nc --arg scope "$scope" --arg key "$idem_key" '{scope:$scope,idempotency_key:$key}')"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg mode "$mode" \
    --arg scope "$scope" \
    --arg key "$idem_key" \
    --slurpfile planned "$planned_tmp" \
    --slurpfile applied "$applied_tmp" \
    '{schema_version:$sv,command:"repair",status:(if $mode=="apply" then "applied" else "dry_run" end),mode:$mode,dry_run:($mode=="dry_run"),scope:$scope,idempotency_key:(if $key=="" then null else $key end),planned_actions:$planned,applied_actions:$applied,actual_actions:$applied}'
}

scaffold_cmd_validate() {
  local subject="${1:-}"
  shift || true
  [[ "$subject" == "--json" ]] && subject=""
  case "$subject" in
    readiness-state)
      local row="${1:-}"
      [[ "$row" == "--json" ]] && row="${2:-}"
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"readiness-state",status:"refused",reason:"readiness JSON required"}'
        return 64
      fi
      if ! jq -e . >/dev/null 2>&1 <<<"$row"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"readiness-state",status:"fail",reason:"invalid JSON"}'
        return 1
      fi
      local missing
      missing="$(jq -c '[["mission_lock_readiness_health_score","blocked_surfaces","phase0_scaffold_bead_suggestions","repair_receipt_identity_fields"][] as $f | select(has($f) | not) | $f]' <<<"$row")"
      if jq -e 'length == 0' >/dev/null <<<"$missing"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson row "$row" '{schema_version:$sv,command:"validate",subject:"readiness-state",status:"pass",row:$row}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson missing "$missing" --argjson row "$row" '{schema_version:$sv,command:"validate",subject:"readiness-state",status:"fail",reason:"missing required fields",missing:$missing,row:$row}'
        return 1
      fi
      ;;
    audit-row)
      local row="${1:-}"
      [[ "$row" == "--json" ]] && row="${2:-}"
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"audit-row",status:"refused",reason:"audit row JSON required"}'
        return 64
      fi
      if ! jq -e . >/dev/null 2>&1 <<<"$row"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"invalid JSON"}'
        return 1
      fi
      local missing
      missing="$(jq -c '[["ts","action","status"][] as $f | select(has($f) | not) | $f]' <<<"$row")"
      if jq -e 'length == 0' >/dev/null <<<"$missing"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson row "$row" '{schema_version:$sv,command:"validate",subject:"audit-row",status:"pass",row:$row}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson missing "$missing" --argjson row "$row" '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"missing required fields",missing:$missing,row:$row}'
        return 1
      fi
      ;;
    ""|-h|--help)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["readiness-state","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subject "$subject" '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$subject,valid_subjects:["readiness-state","audit-row"]}'
      return 0 ;;
  esac
}

scaffold_cmd_audit() {
  local limit="${1:-20}"
  [[ "$limit" == "--json" ]] && limit="${2:-20}"
  [[ "$limit" =~ ^[0-9]+$ ]] || limit=20
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
    return 0
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" '{schema_version:$sv,command:"audit",status:"missing",audit_log:$log,row_count:0,recent:[]}'
    return 0
  fi
  local row_count recent
  row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  if [[ "$row_count" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" '{schema_version:$sv,command:"audit",status:"empty",audit_log:$log,row_count:0,recent:[]}'
    return 0
  fi
  recent="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -cs '.' 2>/dev/null || printf '[]')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",status:"pass",audit_log:$log,row_count:$count,recent:$recent}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" '{schema_version:$sv,command:"why",id:$id,status:"missing",match_count:0,matches:[],reason:"audit log absent"}'
    return 0
  fi
  local matches row_count idx count
  matches="[]"
  if [[ "$id" =~ ^-?[0-9]+$ ]]; then
    row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    idx="$id"
    [[ "$idx" -lt 0 ]] && idx=$((row_count + idx + 1))
    if [[ "$idx" -ge 1 && "$idx" -le "$row_count" ]]; then
      matches="$(sed -n "${idx}p" "$SCAFFOLD_AUDIT_LOG" | jq -cs '.' 2>/dev/null || printf '[]')"
    fi
  else
    matches="$(jq -cs --arg id "$id" '[.[] | select((.action // "" | tostring | contains($id)) or (.status // "" | tostring | contains($id)) or (.detail // {} | tostring | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || printf '[]')"
  fi
  count="$(jq 'length' <<<"$matches" 2>/dev/null || printf 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson matches "$matches" --argjson count "$count" \
    '{schema_version:$sv,command:"why",id:$id,status:(if $count > 0 then "pass" else "miss" end),match_count:$count,matches:$matches}'
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
    --exit-codes) shift; scaffold_emit_exit_codes; exit 0 ;;
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
    --exit-codes) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|completion|exit-codes|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
VERSION="mission-lock-readiness-doctor/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MISSION_PATH="$ROOT/.flywheel/MISSION.md"
PLAN_PATH="$ROOT/.flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06"
COMMAND="doctor"
JSON_OUT=0
QUIET=0
for arg in "$@"; do [[ "$arg" == "--json" ]] && JSON_OUT=1; done

usage() {
  printf '%s\n' \
    'usage:' \
    '  mission-lock-readiness-doctor.sh [doctor|health|validate|audit|schema] [--mission MISSION.md] [--plan PLAN_DIR] [--json] [--quiet]' \
    '  mission-lock-readiness-doctor.sh --info|--help|--examples [--json]'
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:["mission-lock-readiness-doctor.sh --json","mission-lock-readiness-doctor.sh doctor --mission .flywheel/MISSION.md --json","mission-lock-readiness-doctor.sh validate --plan .flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06 --json"]}'
  else
    printf '%s\n' 'mission-lock-readiness-doctor.sh --json' 'mission-lock-readiness-doctor.sh doctor --mission .flywheel/MISSION.md --json' 'mission-lock-readiness-doctor.sh validate --plan .flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06 --json'
  fi
}

info() {
  jq -nc --arg version "$VERSION" '{name:"mission-lock-readiness-doctor.sh",version:$version,mutates:false,audit_only_default:true,canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],canonical_cli_verbs:["doctor","health","validate","audit","schema"],doctor_fields:["mission_lock_readiness_health_score","blocked_surfaces","phase0_scaffold_bead_suggestions","repair_receipt_identity_fields"],exit_codes:{"0":"healthy","1":"readiness_incomplete","2":"usage"}}'
}

schema_payload() {
  jq -nc --arg version "$VERSION" '{schema_version:$version,score_range:[0,1],producer_inputs:["mission-lock-output-schema-validator","mission-lock-scaffold-validator","plan-state-lens-merge validate"],consumer:"flywheel-loop doctor field set",promotion:"health<1 emits Phase 0 scaffold suggestions; no mutation in audit-only mode"}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|validate|audit|schema) COMMAND="$1"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --mission) [[ $# -ge 2 ]] || die_usage "--mission requires a path"; MISSION_PATH="$2"; shift 2 ;;
    --plan) [[ $# -ge 2 ]] || die_usage "--plan requires a path"; PLAN_PATH="$2"; shift 2 ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) MISSION_PATH="$1"; shift ;;
  esac
done

if [[ "$COMMAND" == "schema" ]]; then schema_payload; exit 0; fi
[[ -r "$MISSION_PATH" ]] || die_usage "mission file not readable: $MISSION_PATH"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-readiness.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
SCHEMA_VALIDATOR="$ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh"
SCAFFOLD_VALIDATOR="$ROOT/.flywheel/scripts/mission-lock-scaffold-validator.sh"
LENS_MERGE="$ROOT/.flywheel/scripts/plan-state-lens-merge.sh"

run_json() {
  local out="$1"; shift
  set +e
  "$@" --json >"$out" 2>"$out.err"
  local rc=$?
  set -e
  return "$rc"
}

schema_rc=2
if [[ -x "$SCHEMA_VALIDATOR" ]]; then
  run_json "$TMP/schema.json" bash "$SCHEMA_VALIDATOR" --mission "$MISSION_PATH" || schema_rc=$?
  schema_rc="${schema_rc:-0}"
else
  jq -nc '{status:"skip",errors:[]}' >"$TMP/schema.json"
fi
schema_status="$(jq -r '.status // "skip"' "$TMP/schema.json" 2>/dev/null || printf 'fail')"
[[ "$schema_status" == "pass" ]] && schema_verdict=pass || schema_verdict=fail
[[ -x "$SCHEMA_VALIDATOR" ]] || schema_verdict=skip

scaffold_rc=2
if [[ -x "$SCAFFOLD_VALIDATOR" ]]; then
  run_json "$TMP/scaffold.json" bash "$SCAFFOLD_VALIDATOR" --mission "$MISSION_PATH" || scaffold_rc=$?
  scaffold_rc="${scaffold_rc:-0}"
else
  jq -nc '{verdict:"skip",blockers:[],checks:{blocked_readiness_states:[]}}' >"$TMP/scaffold.json"
fi
scaffold_verdict="$(jq -r '.verdict // "skip"' "$TMP/scaffold.json" 2>/dev/null || printf 'fail')"
[[ -x "$SCAFFOLD_VALIDATOR" ]] || scaffold_verdict=skip

if [[ -x "$LENS_MERGE" && -e "$PLAN_PATH" ]]; then
  if run_json "$TMP/lens.json" bash "$LENS_MERGE" validate --plan "$PLAN_PATH"; then
    lens_consistent=true
  else
    lens_consistent=false
  fi
else
  jq -nc '{status:"fail",malformed_count:1}' >"$TMP/lens.json"
  lens_consistent=false
fi

: >"$TMP/surfaces.txt"
: >"$TMP/suggestions.jsonl"
suggest() {
  local slug="$1" summary="$2" finding="$3"
  printf '%s\n' "$slug" >>"$TMP/surfaces.txt"
  jq -nc --arg slug "$slug" --arg summary "$summary" --arg finding "$finding" '{slug:$slug,summary:$summary,blocking_finding:$finding}' >>"$TMP/suggestions.jsonl"
}

if [[ "$schema_verdict" != "pass" ]]; then
  codes="$(jq -r '[.errors[]?.code] | unique | join(",")' "$TMP/schema.json")"
  suggest "mission-lock-output-schema" "Backfill mission-lock output schema fields and sidecar JSON until schema validator passes." "schema:${codes:-validator_unavailable}"
fi
if [[ "$scaffold_verdict" == "blocked" ]]; then
  jq -r '.blockers[]?' "$TMP/scaffold.json" | while read -r item; do [[ -n "$item" ]] && printf 'mission-lock-scaffold:%s\n' "$item" >>"$TMP/surfaces.txt"; done
  suggest "mission-lock-scaffold" "Repair required markdown sections, section hashes, substrate pointers, or negative invariants." "scaffold:blocked"
elif [[ "$scaffold_verdict" != "ready" ]]; then
  suggest "mission-lock-scaffold-backfill" "Add section-hash receipts and substrate inventory so legacy mission lock reaches ready." "scaffold:${scaffold_verdict}"
fi
if [[ "$lens_consistent" != "true" ]]; then
  suggest "plan-state-lens-merge" "Repair plan STATE lens merge rows so readiness can trust parallel audit state." "IDEM-004"
fi
jq -r '.checks.blocked_readiness_states[]?' "$TMP/scaffold.json" 2>/dev/null | while read -r item; do [[ -n "$item" ]] && printf 'blocked-readiness:%s\n' "$item" >>"$TMP/surfaces.txt"; done

score="$(python3 - "$schema_verdict" "$scaffold_verdict" "$lens_consistent" <<'PY'
import sys
schema, scaffold, lens = sys.argv[1:]
score = 1.0
if schema == "fail": score -= 0.55
elif schema == "skip": score -= 0.20
if scaffold == "blocked": score -= 0.35
elif scaffold in {"incomplete","skip","fail"}: score -= 0.15
if lens != "true": score -= 0.45
print(f"{max(0.0, min(1.0, score)):.2f}")
PY
)"
surfaces_json="$(jq -R -s -c 'split("\n")[:-1] | unique' "$TMP/surfaces.txt")"
suggestions_json="$(jq -s -c '.' "$TMP/suggestions.jsonl")"
identity_payload="$(jq -nc --arg mission_sha "$(shasum -a 256 "$MISSION_PATH" | awk '{print $1}')" --arg schema "$schema_verdict" --arg scaffold "$scaffold_verdict" --argjson lens "$lens_consistent" --argjson surfaces "$surfaces_json" '{mission_sha:$mission_sha,schema:$schema,scaffold:$scaffold,lens:$lens,surfaces:$surfaces}')"
repair_key="$(printf '%s' "$identity_payload" | shasum -a 256 | awk '{print "sha256:" $1}')"

payload="$(jq -nc \
  --arg version "$VERSION" \
  --arg command "$COMMAND" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg mission "$(cd "$(dirname "$MISSION_PATH")" && pwd -P)/$(basename "$MISSION_PATH")" \
  --arg schema "$schema_verdict" \
  --arg scaffold "$scaffold_verdict" \
  --argjson lens "$lens_consistent" \
  --argjson score "$score" \
  --argjson surfaces "$surfaces_json" \
  --argjson suggestions "$suggestions_json" \
  --arg repair_key "$repair_key" \
  --argjson schema_result "$(cat "$TMP/schema.json")" \
  --argjson scaffold_result "$(cat "$TMP/scaffold.json")" \
  --argjson lens_result "$(cat "$TMP/lens.json")" \
  '{schema_version:$version,command:$command,ts:$ts,mission_md_path:$mission,schema_validator_verdict:$schema,scaffold_validator_verdict:$scaffold,lens_merge_consistent:$lens,mission_lock_readiness_health_score:$score,blocked_surfaces:$surfaces,phase0_scaffold_bead_suggestions:$suggestions,repair_receipt_identity_fields:{repair_idempotency_key:$repair_key,expected_blocked_surfaces_resolved:$surfaces},audit_only:true,upstream_results:{schema:$schema_result,scaffold:$scaffold_result,lens_merge:$lens_result}}')"

if [[ "$QUIET" -eq 0 && "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
elif [[ "$QUIET" -eq 0 ]]; then
  jq -r '"health=\(.mission_lock_readiness_health_score) schema=\(.schema_validator_verdict) scaffold=\(.scaffold_validator_verdict) lens=\(.lens_merge_consistent)"' <<<"$payload"
fi
[[ "$(jq -r '.mission_lock_readiness_health_score == 1' <<<"$payload")" == true ]]
