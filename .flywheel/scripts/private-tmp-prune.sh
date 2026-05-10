#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by flywheel-gam2k (P3 sub-bead from flywheel-wgitr).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="private-tmp-prune/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/private-tmp-prune-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: private-tmp-prune.sh [SUBCOMMAND] [OPTIONS]

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
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "private-tmp-prune.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "private-tmp-prune.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"private-tmp-prune.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"private-tmp-prune.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"private-tmp-prune.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-private-tmp-prune}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"prune /private/tmp/ entries older than MIN_AGE_HOURS, with allowlist guard, open-handle skip, and audit ledger",
    inputs:{
      target_dir:{type:"path",default:"/private/tmp",env:"PRIVATE_TMP_PRUNE_TARGET"},
      min_age_hours:{type:"integer",default:6,env:"PRIVATE_TMP_PRUNE_MIN_AGE_HOURS"},
      apply:{type:"boolean",default:false,description:"--apply mutates; default --dry-run"},
      idempotency_key:{type:"string",description:"required when --apply (env: PRIVATE_TMP_PRUNE_IDEMPOTENCY_KEY)"}
    },
    outputs:{
      ledger:{path:"$HOME/.local/state/flywheel/private-tmp-prune.jsonl",fields:["ts","path","action","age_hours","apply","idempotency_key"]},
      scaffold_audit:{path:"$HOME/.local/state/flywheel/private-tmp-prune-runs.jsonl"},
      stdout:{type:"json",description:"--json emits structured run report"}
    },
    safety:["allowlist guard via is_allowlisted","skip entries with open file handles (lsof)","skip entries newer than min_age_hours","--apply requires --idempotency-key"],
    side_effects:["delegates to ntm cleanup --max-age","appends row to ledger jsonl"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation. Probes /private/tmp/ for entries older than --min-age-hours (default 6); skips allowlisted paths and entries with open file handles. --dry-run lists candidates; --apply --idempotency-key KEY actually prunes (delegates to `ntm cleanup`).\n' ;;
    doctor)   printf 'topic: doctor — probes 6 substrate dimensions: target dir exists+writable, ntm binary executable, lsof on PATH, ledger jsonl writable, min-age-hours sane (>=1), allowlist function defined.\n' ;;
    health)   printf 'topic: health — tails the ledger jsonl; reports recent_prune_count, last_prune_ts, age_seconds_since_last, distinct_paths_pruned. Status warn when ledger absent or staler than 7 days; pass otherwise.\n' ;;
    repair)   printf 'topic: repair — scopes: stale-tmp (force-prune older than threshold ignoring lower min-age-hours; --apply required), ledger-rotate (rotate ledger jsonl when >10MB to ledger.jsonl.<ts>; --apply required). --apply requires --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: ledger-row (--row-json=JSON; check required fields ts/path/action), target-allowlisted (--path=PATH; checks is_allowlisted gate), config (validates MIN_AGE_HOURS and TARGET_DIR env values).\n' ;;
    audit)    printf 'topic: audit — tail recent rows from the ledger. --tail=N (default 10).\n' ;;
    why)      printf 'topic: why <id> — explain why <id> (a path or audit-row id) is/isn'\''t in the ledger. Returns provenance row with ts, action, age_hours, apply, idempotency_key.\n' ;;
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
            && cli_emit_completion_bash "private-tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "private-tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Probe 6 substrate dimensions. Pure if/then/else/fi (no L4 short-circuits).
  local ts target_dir min_age ntm_bin ledger
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  target_dir="${PRIVATE_TMP_PRUNE_TARGET:-/private/tmp}"
  min_age="${PRIVATE_TMP_PRUNE_MIN_AGE_HOURS:-6}"
  ntm_bin="${NTM_BIN:-ntm}"
  ledger="${PRIVATE_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/private-tmp-prune.jsonl}"

  local target_status="fail" target_reason=""
  if [[ -d "$target_dir" ]]; then
    if [[ -w "$target_dir" ]]; then target_status="pass"
    else target_reason="exists but not writable: $target_dir"; fi
  else target_reason="target dir absent: $target_dir"; fi

  local ntm_status="fail" ntm_reason=""
  if command -v "$ntm_bin" >/dev/null 2>&1; then ntm_status="pass"
  else ntm_reason="ntm not on PATH: $ntm_bin"; fi

  local lsof_status="fail" lsof_reason=""
  if command -v lsof >/dev/null 2>&1; then lsof_status="pass"
  else lsof_reason="lsof not on PATH (needed for open-handle skip)"; fi

  local ledger_status="fail" ledger_reason=""
  if [[ -f "$ledger" && -w "$ledger" ]]; then ledger_status="pass"
  elif [[ -f "$ledger" ]]; then ledger_reason="ledger exists but not writable: $ledger"
  elif [[ -w "$(dirname "$ledger")" ]]; then ledger_status="pass"; ledger_reason="ledger absent but parent writable"
  else ledger_reason="ledger parent not writable: $(dirname "$ledger")"; fi

  local age_status="fail" age_reason=""
  if [[ "$min_age" =~ ^[0-9]+$ ]] && [[ "$min_age" -ge 1 ]]; then age_status="pass"
  else age_reason="min_age_hours invalid: '$min_age' (must be int >= 1)"; fi

  # Check is_allowlisted via source-file grep (the function is defined later
  # in the file, after the early-dispatch intercept; it's not available in
  # the doctor's runtime scope but the source-of-truth check is whether it
  # exists in the script file).
  local allowlist_status="fail" allowlist_reason=""
  local script_self="${BASH_SOURCE[0]}"
  if [[ -r "$script_self" ]] && grep -qE '^is_allowlisted[[:space:]]*\(\)' "$script_self" 2>/dev/null; then
    allowlist_status="pass"
  else
    allowlist_reason="is_allowlisted function not defined in $script_self (allowlist guard missing)"
  fi

  local overall="pass"
  for s in "$target_status" "$ntm_status" "$lsof_status" "$ledger_status" "$age_status" "$allowlist_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg target_dir "$target_dir" --arg target_status "$target_status" --arg target_reason "$target_reason" \
    --arg ntm_bin "$ntm_bin" --arg ntm_status "$ntm_status" --arg ntm_reason "$ntm_reason" \
    --arg lsof_status "$lsof_status" --arg lsof_reason "$lsof_reason" \
    --arg ledger "$ledger" --arg ledger_status "$ledger_status" --arg ledger_reason "$ledger_reason" \
    --argjson min_age "$min_age" --arg age_status "$age_status" --arg age_reason "$age_reason" \
    --arg allowlist_status "$allowlist_status" --arg allowlist_reason "$allowlist_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"target_dir_writable",status:$target_status,path:$target_dir,reason:$target_reason},
      {name:"ntm_on_path",status:$ntm_status,bin:$ntm_bin,reason:$ntm_reason},
      {name:"lsof_on_path",status:$lsof_status,reason:$lsof_reason},
      {name:"ledger_writable",status:$ledger_status,path:$ledger,reason:$ledger_reason},
      {name:"min_age_hours_sane",status:$age_status,value:$min_age,reason:$age_reason},
      {name:"allowlist_function_defined",status:$allowlist_status,reason:$allowlist_reason}
    ]}'
}

scaffold_cmd_health() {
  # Tail the ledger jsonl and summarize recent prune activity.
  local ts ledger tail_count=20 tail_lines total last_ts age_seconds distinct_paths apply_count
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  ledger="${PRIVATE_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/private-tmp-prune.jsonl}"

  if [[ ! -f "$ledger" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$ledger" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"ledger absent (no prunes recorded yet)",ledger:$log,recent_count:0}'
    return 0
  fi

  tail_lines="$(tail -n "$tail_count" "$ledger" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || echo 0)"
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  apply_count="$(printf '%s\n' "$tail_lines" | jq -r 'select(.apply == true or .apply == 1) | .ts' 2>/dev/null | wc -l | tr -d ' ')"
  distinct_paths="$(printf '%s\n' "$tail_lines" | jq -r '.path // empty' 2>/dev/null | sort -u | wc -l | tr -d ' ')"

  if [[ -n "$last_ts" ]]; then
    local now_epoch last_epoch
    now_epoch="$(date -u +%s)"
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo "$now_epoch")"
    age_seconds=$((now_epoch - last_epoch))
  else
    age_seconds=null
  fi

  local status="pass" reason=""
  if [[ "$total" -eq 0 ]]; then
    status="warn"; reason="ledger present but empty"
  elif [[ "$age_seconds" != "null" ]] && [[ "$age_seconds" -gt 604800 ]]; then
    status="warn"; reason="last prune > 7 days ago (age=${age_seconds}s) — cron may be stalled"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg ledger "$ledger" \
    --argjson total "$total" --argjson apply "$apply_count" --argjson distinct "$distinct_paths" \
    --arg last_ts "$last_ts" --argjson age "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      ledger:$ledger,recent_count:$total,apply_count:$apply,distinct_paths_pruned:$distinct,
      last_prune_ts:(if $last_ts == "" then null else $last_ts end),
      age_seconds_since_last:$age}'
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
  # Per-scope repair actions. Default scopes:
  #   stale-tmp     — force-prune /private/tmp/ entries older than min-age,
  #                   bypassing the standard probe path. Honors allowlist.
  #   ledger-rotate — rotate ledger jsonl when it exceeds 10 MB.
  local target_dir min_age ledger
  target_dir="${PRIVATE_TMP_PRUNE_TARGET:-/private/tmp}"
  min_age="${PRIVATE_TMP_PRUNE_MIN_AGE_HOURS:-6}"
  ledger="${PRIVATE_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/private-tmp-prune.jsonl}"

  case "$scope" in
    stale-tmp)
      local count=0
      if [[ -d "$target_dir" ]]; then
        count="$(find "$target_dir" -maxdepth 1 -mindepth 1 -mmin "+$((min_age * 60))" 2>/dev/null | wc -l | tr -d ' ')"
      fi
      if [[ "$mode" == "apply" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg target "$target_dir" --argjson count "$count" --argjson min_age "$min_age" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"apply",scope:$scope,idempotency_key:$idem,target:$target,min_age_hours:$min_age,candidates:$count,note:"plan-only emitted; the canonical apply path is `private-tmp-prune.sh --apply --idempotency-key KEY` which exercises allowlist + open-handle skip in cmd_run"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --arg target "$target_dir" --argjson count "$count" --argjson min_age "$min_age" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,target:$target,min_age_hours:$min_age,candidates:$count,note:"dry-run: pass --apply --idempotency-key KEY to use the canonical run path"}'
      fi
      ;;
    ledger-rotate)
      local size=0 rotate_threshold=10485760  # 10 MB
      if [[ -f "$ledger" ]]; then
        size="$(wc -c <"$ledger" | tr -d ' ')"
      fi
      local needs_rotate=false
      if [[ "$size" -gt "$rotate_threshold" ]]; then needs_rotate=true; fi
      if [[ "$mode" == "apply" && "$needs_rotate" == "true" ]]; then
        local rotated="${ledger}.$(date -u +%Y%m%dT%H%M%SZ)"
        mv "$ledger" "$rotated" 2>/dev/null
        : > "$ledger"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg ledger "$ledger" --arg rotated "$rotated" --argjson size "$size" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,ledger:$ledger,rotated_to:$rotated,old_size_bytes:$size}'
      elif [[ "$mode" == "apply" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg ledger "$ledger" --argjson size "$size" --argjson threshold "$rotate_threshold" \
          '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,ledger:$ledger,size_bytes:$size,threshold_bytes:$threshold,reason:"under threshold; no rotation needed"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --arg ledger "$ledger" --argjson size "$size" --argjson threshold "$rotate_threshold" --argjson needs "$needs_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,ledger:$ledger,size_bytes:$size,threshold_bytes:$threshold,needs_rotate:$needs}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["stale-tmp","ledger-rotate"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["stale-tmp","ledger-rotate"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation. Subjects:
  #   --row-json=<JSON>      validate one ledger row against required fields
  #   --path=<PATH>          check is_allowlisted gate against a target path
  #   --config               validate MIN_AGE_HOURS + TARGET_DIR env values
  local subject="" row_json="" path_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --path=*) path_arg="${1#--path=}"; subject="path"; shift ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    row)
      [[ -z "$row_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required"}'; return 64; }
      local required='["ts","path","action"]'
      local missing valid
      missing="$(echo "$row_json" | jq -c --argjson req "$required" --argjson r "$row_json" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      if echo "$row_json" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" --argjson r "$row_json" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $valid and ($missing | length == 0) then "pass" else "fail" end),valid:$valid,missing_fields:$missing,row:$r}'
      ;;
    path)
      [[ -z "$path_arg" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--path=PATH required"}'; return 64; }
      local allowed
      if declare -F is_allowlisted >/dev/null 2>&1; then
        if is_allowlisted "$path_arg" 2>/dev/null; then allowed=true; else allowed=false; fi
      else
        allowed=null
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$path_arg" --argjson allowed "$allowed" \
        '{schema_version:$sv,command:"validate",subject:"path",status:(if $allowed == true then "pass" elif $allowed == false then "fail" else "warn" end),path:$path,allowlisted:$allowed}'
      ;;
    config)
      local target_dir min_age age_valid target_valid
      target_dir="${PRIVATE_TMP_PRUNE_TARGET:-/private/tmp}"
      min_age="${PRIVATE_TMP_PRUNE_MIN_AGE_HOURS:-6}"
      if [[ "$min_age" =~ ^[0-9]+$ ]] && [[ "$min_age" -ge 1 ]]; then age_valid=true; else age_valid=false; fi
      if [[ -d "$target_dir" ]]; then target_valid=true; else target_valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg target "$target_dir" --argjson target_valid "$target_valid" \
        --argjson min_age "$min_age" --argjson age_valid "$age_valid" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if $target_valid and $age_valid then "pass" else "fail" end),
          target_dir:{value:$target,valid:$target_valid},
          min_age_hours:{value:$min_age,valid:$age_valid}}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","path","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail the ledger jsonl. Default tail=10. --tail=N overrides.
  local ledger="${PRIVATE_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/private-tmp-prune.jsonl}"
  local tail_n=10
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --tail) tail_n="${2:-10}"; shift 2 ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) printf 'ERR: unknown audit arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ ! -f "$ledger" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$ledger" \
      '{schema_version:$sv,command:"audit",audit_log:$log,status:"warn",reason:"ledger absent",rows:[]}'
    return 0
  fi
  local rows count
  rows="$(tail -n "$tail_n" "$ledger" | jq -sc '.' 2>/dev/null || echo '[]')"
  count="$(echo "$rows" | jq 'length')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$ledger" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument (path or audit-row id)\n' >&2; return 64
  fi
  # Look up <id> in ledger (matches as either path or substring of any field).
  local ledger="${PRIVATE_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/private-tmp-prune.jsonl}"
  if [[ ! -f "$ledger" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"warn",reason:"ledger absent"}'
    return 0
  fi
  local row
  row="$(grep -F "$id" "$ledger" 2>/dev/null | tail -1 || true)"
  if [[ -z "$row" ]]; then
    # Not in ledger; check if currently exists in target dir + would it be allowlisted
    local target_dir="${PRIVATE_TMP_PRUNE_TARGET:-/private/tmp}"
    local exists=false allowed=null
    if [[ -e "$target_dir/$id" || -e "$id" ]]; then exists=true; fi
    if declare -F is_allowlisted >/dev/null 2>&1; then
      if is_allowlisted "$id" 2>/dev/null; then allowed=true; else allowed=false; fi
    fi
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      --argjson exists "$exists" --argjson allowed "$allowed" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_in_ledger",
        currently_exists:$exists,would_be_allowlisted:$allowed,
        reason:"id not found in ledger; reporting filesystem + allowlist status"}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      provenance:{ts:$row.ts,path:$row.path,action:$row.action,age_hours:$row.age_hours,apply:$row.apply,idempotency_key:$row.idempotency_key},
      row:$row}'
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
SCRIPT_VERSION="private-tmp-prune.v2"
APPLY=0
JSON_OUT=0
IDEMPOTENCY_KEY="${PRIVATE_TMP_PRUNE_IDEMPOTENCY_KEY:-}"
MIN_AGE_HOURS="${PRIVATE_TMP_PRUNE_MIN_AGE_HOURS:-6}"
TARGET_DIR="${PRIVATE_TMP_PRUNE_TARGET:-/private/tmp}"
LEDGER="${PRIVATE_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/private-tmp-prune.jsonl}"
NTM_BIN="${NTM_BIN:-ntm}"

ALLOWLIST_PATTERNS=(
  "jsm-auth-isolation." "jsm-health-sandbox." "jsm-doctor-" "jsm-wrapper-"
  "beads-rust-" "beads_rust-" "mobile-eats-next-dev-cache-" "mobile-eats-next-failed-density-"
  "mobile-eats-next-cache-" "mobile-eats-next-stale-" "mobile-eats-next-dev-stale-"
  "mobile-eats-*-validate*" "mobile-eats-*-verify*" "mobile-eats-*-build-*"
  "mobile-eats-*-check" "mobile-eats-stale-*" "alps-demo-smoke-"
  "alpsinsurance-demo-" "alpsinsurance-smoke-"
  "br_recovery.archived-" "beads-pre-nuclear-restart-" "issues.jsonl.pre-nuclear-"
  "beads.db.pre-nuclear-" "beads-recovery-sandbox."
)

usage() { printf '%s\n' "Usage: private-tmp-prune.sh [--dry-run|--apply --idempotency-key KEY] [--json] [--min-age-hours N] [--target DIR]" "Default dry-run; ntm temp cleanup delegates to ntm cleanup."; }

while [ $# -gt 0 ]; do
  case "$1" in
    doctor|health|run) shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --min-age-hours) MIN_AGE_HOURS="$2"; shift 2 ;;
    --target) TARGET_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    completion) printf '%s\n' 'complete -W "doctor health run --json --dry-run --apply --idempotency-key --min-age-hours --target completion --help" private-tmp-prune.sh'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$TARGET_DIR" in /private/tmp|/tmp|/var/folders/*|/var/tmp/*) ;; *) echo "ERROR: refused target: $TARGET_DIR" >&2; exit 2 ;; esac
[ -d "$TARGET_DIR" ] || { echo "ERROR: target dir missing: $TARGET_DIR" >&2; exit 2; }
if [ "$APPLY" -eq 1 ] && [ -z "$IDEMPOTENCY_KEY" ]; then
  echo "ERROR: --apply requires --idempotency-key KEY" >&2
  exit 2
fi

is_allowlisted() {
  local name="$1" pattern
  for pattern in "${ALLOWLIST_PATTERNS[@]}"; do
    case "$pattern" in
      *[\*\?\[]*) case "$name" in $pattern) return 0 ;; esac ;;
    *) case "$name" in "${pattern}"*) return 0 ;; esac ;;
    esac
  done
  return 1
}

age_hours() { local now mtime; now="$(date +%s)"; mtime="$(stat -f %m "$1" 2>/dev/null || echo "$now")"; echo $(((now - mtime) / 3600)); }

has_open_handles() { lsof "$1" 2>/dev/null | tail -n +2 | grep -q .; }

ntm_cleanup() { if [ "$APPLY" -eq 1 ]; then TMPDIR="$TARGET_DIR" "$NTM_BIN" cleanup --max-age "$MIN_AGE_HOURS" --json; else TMPDIR="$TARGET_DIR" "$NTM_BIN" cleanup --dry-run --max-age "$MIN_AGE_HOURS" --json; fi; }

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NTM_JSON="$(ntm_cleanup 2>/dev/null || jq -nc '{error:"ntm_cleanup_failed"}')"
CANDIDATES_JSONL="$(mktemp "${TMPDIR:-/tmp}/private-tmp-prune.XXXXXX")"
trap 'rm -f "$CANDIDATES_JSONL"' EXIT
SKIP_NOT_ALLOWLISTED=0; SKIP_TOO_YOUNG=0; SKIP_OPEN=0; SKIP_NOT_DIR=0

for path in "$TARGET_DIR"/*; do
  [ -e "$path" ] || continue
  name="$(basename "$path")"
  if ! is_allowlisted "$name"; then SKIP_NOT_ALLOWLISTED=$((SKIP_NOT_ALLOWLISTED + 1)); continue; fi
  if [ ! -d "$path" ]; then SKIP_NOT_DIR=$((SKIP_NOT_DIR + 1)); continue; fi
  age="$(age_hours "$path")"
  if [ "$age" -lt "$MIN_AGE_HOURS" ]; then SKIP_TOO_YOUNG=$((SKIP_TOO_YOUNG + 1)); continue; fi
  if [ "$APPLY" -eq 1 ] && has_open_handles "$path"; then SKIP_OPEN=$((SKIP_OPEN + 1)); continue; fi
  jq -nc --arg path "$path" --argjson age "$age" '{path:$path,age_hours:$age,size_kb:0}' >>"$CANDIDATES_JSONL"
done

if [ "$APPLY" -eq 1 ] && [ -s "$CANDIDATES_JSONL" ]; then
  mkdir -p "$(dirname "$LEDGER")"
  while IFS= read -r row; do
    path="$(jq -r '.path' <<<"$row")"
    case "$path" in
      "$TARGET_DIR"/*)
        /usr/bin/python3 -c 'import os, shutil, sys; p=sys.argv[1]; shutil.rmtree(p) if os.path.isdir(p) else os.unlink(p)' "$path" &&
          jq -nc --arg ts "$TS" --arg key "$IDEMPOTENCY_KEY" --arg path "$path" '{ts:$ts,action:"removed",idempotency_key:$key,path:$path}' >>"$LEDGER"
        ;;
    esac
  done <"$CANDIDATES_JSONL"
fi

RESULT="$(jq -sc \
  --arg schema "$SCRIPT_VERSION" --arg ts "$TS" --arg target "$TARGET_DIR" --argjson apply "$APPLY" \
  --argjson min_age "$MIN_AGE_HOURS" --argjson ntm "$NTM_JSON" --argjson skip_na "$SKIP_NOT_ALLOWLISTED" \
  --argjson skip_young "$SKIP_TOO_YOUNG" --argjson skip_open "$SKIP_OPEN" --argjson skip_nd "$SKIP_NOT_DIR" \
  '{schema_version:$schema,ts:$ts,target:$target,apply:($apply == 1),dry_run:($apply != 1),min_age_hours:$min_age,
    ntm_cleanup:$ntm,flywheel_candidates:.,flywheel_candidates_count:length,
    flywheel_total_size_kb:(map(.size_kb // 0) | add // 0),
    skipped:{not_allowlisted:$skip_na,too_young:$skip_young,open_handles:$skip_open,not_dir:$skip_nd},
    split_contract:{ntm_temp_cleanup:"ntm cleanup",flywheel_allowlist_cleanup:"private-tmp-prune.sh"}}' "$CANDIDATES_JSONL")"

if [ "$JSON_OUT" -eq 1 ]; then
  printf '%s\n' "$RESULT"
else
  jq -r '"private-tmp-prune dry_run=\(.dry_run) ntm_files=\(.ntm_cleanup.total_files // 0) flywheel_candidates=\(.flywheel_candidates_count) flywheel_size_kb=\(.flywheel_total_size_kb)"' <<<"$RESULT"
fi
