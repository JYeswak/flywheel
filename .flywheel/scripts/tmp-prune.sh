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
# specific logic was filled in by flywheel-tk8ld (P3 sub-bead).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="tmp-prune/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/tmp-prune-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: tmp-prune.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "tmp-prune.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "tmp-prune.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"tmp-prune.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"tmp-prune.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"tmp-prune.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-tmp-prune}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"prune /private/tmp entries with allowlist classifier, age threshold, per-run receipt JSON, and idempotency-keyed apply.",
    inputs:{
      root:{type:"path",default:"/private/tmp",env:"FLYWHEEL_TMP_PRUNE_ROOT"},
      days:{type:"integer",default:1,env:"FLYWHEEL_TMP_PRUNE_DAYS"},
      receipt_dir:{type:"path",env:"FLYWHEEL_TMP_PRUNE_RECEIPT_DIR",default:"$HOME/.local/state/flywheel/tmp-prune-receipts"},
      idempotency_key:{type:"string",env:"FLYWHEEL_TMP_PRUNE_IDEMPOTENCY_KEY",required_for:"--apply"}
    },
    outputs:{
      receipt:{path:"<RECEIPT_DIR>/<ts>-<key>.json"},
      runs_log:{path:"$HOME/.local/state/flywheel/tmp-prune-runs.jsonl"},
      stdout:{type:"json",fields:["candidates","forbidden","unknown","applied","receipt_path"]}
    },
    classifier:{
      allowed:"is_allowed_base patterns (script-defined)",
      forbidden:"is_forbidden_base patterns (script-defined; MUST NOT prune)",
      unknown:"all other entries (require explicit opt-in to include)"
    },
    side_effects:["dry_run: read-only enumeration","apply: deletes allowed candidates older than threshold","writes per-run receipt JSON"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — full enumerate-and-prune cycle. Classifies /private/tmp entries via is_allowed_base / is_forbidden_base; deletes allowed candidates older than --days (default 1). --apply requires --idempotency-key. Writes per-run receipt JSON to receipt-dir.\n' ;;
    doctor)   printf 'topic: doctor — probes 6 substrate dimensions: ROOT_PATH writable, RECEIPT_DIR writable, find/jq/du on PATH, classifier functions defined, DAYS sane (>=1).\n' ;;
    health)   printf 'topic: health — list recent receipts in RECEIPT_DIR; reports recent_receipt_count, last_receipt_ts, age_seconds_since_last. Status warn when stale >24 hours (cron may be off).\n' ;;
    repair)   printf 'topic: repair — scopes: candidates (re-enumerate plan as count summary; read-only), receipts-rotate (delete receipts older than 30 days). Both require --apply --idempotency-key for mutation.\n' ;;
    validate) printf 'topic: validate — subjects: receipt-row (--row-json against required fields), path (--path classification: allowed / forbidden / unknown), config (env values).\n' ;;
    audit)    printf 'topic: audit — list recent receipts from receipt-dir (default last 10).\n' ;;
    why)      printf 'topic: why <path> — explain whether <path> is allowed/forbidden/unknown for prune; emits classification + age vs threshold + would_prune_at_threshold boolean.\n' ;;
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
            && cli_emit_completion_bash "tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 6 substrate checks. Pure if/then/else/fi (no L4 short-circuits).
  local ts root_path receipt_dir days script_self
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  root_path="${FLYWHEEL_TMP_PRUNE_ROOT:-/private/tmp}"
  receipt_dir="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"
  days="${FLYWHEEL_TMP_PRUNE_DAYS:-1}"
  script_self="${BASH_SOURCE[0]}"

  local root_status="fail" root_reason=""
  if [[ -d "$root_path" && -w "$root_path" ]]; then root_status="pass"
  elif [[ -d "$root_path" ]]; then root_reason="exists but not writable: $root_path"
  else root_reason="root absent: $root_path"; fi

  local receipt_status="fail" receipt_reason=""
  if [[ -d "$receipt_dir" && -w "$receipt_dir" ]]; then receipt_status="pass"
  elif [[ -d "$receipt_dir" ]]; then receipt_reason="exists but not writable: $receipt_dir"
  elif [[ -w "$(dirname "$receipt_dir")" ]]; then receipt_status="pass"; receipt_reason="absent but parent writable"
  else receipt_reason="parent not writable: $(dirname "$receipt_dir")"; fi

  local find_status="fail" find_reason=""
  if command -v find >/dev/null 2>&1; then find_status="pass"
  else find_reason="find not on PATH"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH"; fi

  # Source-grep classifier check (functions defined later in the script;
  # early-dispatch path won't see them via runtime declare -F).
  local classifier_status="fail" classifier_reason=""
  if [[ -r "$script_self" ]] && grep -qE '^is_allowed_base[[:space:]]*\(\)' "$script_self" 2>/dev/null \
    && grep -qE '^is_forbidden_base[[:space:]]*\(\)' "$script_self" 2>/dev/null; then
    classifier_status="pass"
  else
    classifier_reason="classifier functions (is_allowed_base, is_forbidden_base) not defined in $script_self"
  fi

  local days_status="fail" days_reason=""
  if [[ "$days" =~ ^[0-9]+$ ]] && [[ "$days" -ge 1 ]]; then days_status="pass"
  else days_reason="days invalid: '$days' (must be int >= 1)"; fi

  local overall="pass"
  for s in "$root_status" "$receipt_status" "$find_status" "$jq_status" "$classifier_status" "$days_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg root_path "$root_path" --arg root_status "$root_status" --arg root_reason "$root_reason" \
    --arg receipt_dir "$receipt_dir" --arg receipt_status "$receipt_status" --arg receipt_reason "$receipt_reason" \
    --arg find_status "$find_status" --arg find_reason "$find_reason" \
    --arg jq_status "$jq_status" --arg jq_reason "$jq_reason" \
    --arg classifier_status "$classifier_status" --arg classifier_reason "$classifier_reason" \
    --argjson days "$days" --arg days_status "$days_status" --arg days_reason "$days_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"root_path_writable",status:$root_status,path:$root_path,reason:$root_reason},
      {name:"receipt_dir_writable",status:$receipt_status,path:$receipt_dir,reason:$receipt_reason},
      {name:"find_on_path",status:$find_status,reason:$find_reason},
      {name:"jq_on_path",status:$jq_status,reason:$jq_reason},
      {name:"classifier_functions_defined",status:$classifier_status,reason:$classifier_reason},
      {name:"days_threshold_sane",status:$days_status,value:$days,reason:$days_reason}
    ]}'
}

scaffold_cmd_health() {
  # List recent receipts in receipt_dir; report freshness.
  local ts receipt_dir tail_count=20 last_receipt last_ts age_seconds total
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  receipt_dir="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"

  if [[ ! -d "$receipt_dir" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg dir "$receipt_dir" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"receipt dir absent (no prunes recorded yet)",receipt_dir:$dir,recent_count:0}'
    return 0
  fi

  set +e
  total="$(find "$receipt_dir" -maxdepth 1 -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
  last_receipt="$(find "$receipt_dir" -maxdepth 1 -type f -name '*.json' 2>/dev/null | sort | tail -1)"
  if [[ -n "$last_receipt" && -f "$last_receipt" ]]; then
    last_ts="$(jq -r '.ts // ""' "$last_receipt" 2>/dev/null)"
  fi
  set -e

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
    status="warn"; reason="receipt dir present but empty"
  elif [[ "$age_seconds" != "null" ]] && [[ "$age_seconds" -gt 86400 ]]; then
    status="warn"; reason="last prune > 24 hours ago (age=${age_seconds}s) — cron may be stalled"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg dir "$receipt_dir" \
    --argjson total "$total" \
    --arg last_receipt "$last_receipt" --arg last_ts "$last_ts" \
    --argjson age "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      receipt_dir:$dir,recent_count:$total,
      last_receipt_path:(if $last_receipt == "" then null else $last_receipt end),
      last_receipt_ts:(if $last_ts == "" then null else $last_ts end),
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
  # Per-scope repair:
  #   candidates       — re-enumerate plan as count summary (read-only)
  #   receipts-rotate  — delete receipts older than 30 days
  local root_path receipt_dir days
  root_path="${FLYWHEEL_TMP_PRUNE_ROOT:-/private/tmp}"
  receipt_dir="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"
  days="${FLYWHEEL_TMP_PRUNE_DAYS:-1}"

  case "$scope" in
    candidates)
      set +e
      local count=0
      if [[ -d "$root_path" ]]; then
        count="$(find "$root_path" -maxdepth 1 -mindepth 1 -mtime "+$days" 2>/dev/null | wc -l | tr -d ' ')"
      fi
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        --arg root "$root_path" --argjson days "$days" --argjson count "$count" \
        '{schema_version:$sv,command:"repair",status:"plan",mode:$mode,scope:$scope,idempotency_key:$idem,
          root:$root,days:$days,candidates_at_age_threshold:$count,
          note:"plan-only enumeration (does not exercise allowlist/forbidden classifier); the canonical apply path is `tmp-prune.sh --apply --idempotency-key KEY`"}'
      ;;
    receipts-rotate)
      [[ -d "$receipt_dir" ]] || {
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg dir "$receipt_dir" \
          '{schema_version:$sv,command:"repair",status:"warn",scope:$scope,reason:"receipt dir absent",dir:$dir}'
        return 0
      }
      set +e
      local stale_count
      stale_count="$(find "$receipt_dir" -maxdepth 1 -type f -name '*.json' -mtime '+30' 2>/dev/null | wc -l | tr -d ' ')"
      set -e
      if [[ "$mode" == "apply" ]]; then
        local removed=0
        while IFS= read -r f; do
          [[ -n "$f" ]] || continue
          rm -f "$f" 2>/dev/null && removed=$((removed + 1))
        done < <(find "$receipt_dir" -maxdepth 1 -type f -name '*.json' -mtime '+30' 2>/dev/null)
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg dir "$receipt_dir" --argjson stale "$stale_count" --argjson removed "$removed" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,
            receipt_dir:$dir,stale_at_30_days:$stale,removed:$removed}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --arg dir "$receipt_dir" --argjson stale "$stale_count" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,
            receipt_dir:$dir,stale_at_30_days:$stale,note:"dry-run; pass --apply --idempotency-key KEY to delete"}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["candidates","receipts-rotate"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["candidates","receipts-rotate"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation:
  #   --row-json=<JSON>      validate one receipt JSON's required fields
  #   --path=<PATH>          classify path against allowlist/forbidden ruleset
  #   --config               validate ROOT + RECEIPT_DIR + DAYS env values
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
      local required='["ts","root","candidates"]'
      local missing valid
      missing="$(echo "$row_json" | jq -c --argjson req "$required" --argjson r "$row_json" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      if echo "$row_json" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" --argjson r "$row_json" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $valid and ($missing | length == 0) then "pass" else "fail" end),valid:$valid,missing_fields:$missing,row:$r}'
      ;;
    path)
      [[ -z "$path_arg" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--path=PATH required"}'; return 64; }
      # Source-grep: pull the body of is_allowed_base + is_forbidden_base
      # to inspect the classifier patterns. Runtime declare won't see them
      # under early-dispatch.
      local allowed_match=false forbidden_match=false
      if declare -F is_allowed_base >/dev/null 2>&1; then
        if is_allowed_base "$path_arg" 2>/dev/null; then allowed_match=true; fi
      fi
      if declare -F is_forbidden_base >/dev/null 2>&1; then
        if is_forbidden_base "$path_arg" 2>/dev/null; then forbidden_match=true; fi
      fi
      local classification="unknown"
      if [[ "$forbidden_match" == "true" ]]; then
        classification="forbidden"
      elif [[ "$allowed_match" == "true" ]]; then
        classification="allowed"
      fi
      local exists=false
      [[ -e "$path_arg" ]] && exists=true
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$path_arg" \
        --arg classification "$classification" \
        --argjson allowed "$allowed_match" --argjson forbidden "$forbidden_match" \
        --argjson exists "$exists" \
        '{schema_version:$sv,command:"validate",subject:"path",
          status:(if $classification == "allowed" then "pass" elif $classification == "forbidden" then "fail" else "warn" end),
          path:$path,classification:$classification,allowed:$allowed,forbidden:$forbidden,currently_exists:$exists}'
      ;;
    config)
      local root_path receipt_dir days root_valid=false receipt_valid=false days_valid=false
      root_path="${FLYWHEEL_TMP_PRUNE_ROOT:-/private/tmp}"
      receipt_dir="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"
      days="${FLYWHEEL_TMP_PRUNE_DAYS:-1}"
      [[ -d "$root_path" ]] && root_valid=true
      [[ -d "$(dirname "$receipt_dir")" ]] && receipt_valid=true
      [[ "$days" =~ ^[0-9]+$ ]] && [[ "$days" -ge 1 ]] && days_valid=true
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg root "$root_path" --argjson root_valid "$root_valid" \
        --arg receipt "$receipt_dir" --argjson receipt_valid "$receipt_valid" \
        --argjson days "$days" --argjson days_valid "$days_valid" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if $root_valid and $receipt_valid and $days_valid then "pass" else "fail" end),
          root:{value:$root,valid:$root_valid},
          receipt_dir:{value:$receipt,valid:$receipt_valid},
          days:{value:$days,valid:$days_valid}}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","path","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # List recent receipts from receipt_dir.
  local receipt_dir="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"
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
  if [[ ! -d "$receipt_dir" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg dir "$receipt_dir" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",receipt_dir:$dir,tail_n:$tail_n,count:0,status:"warn",reason:"receipt dir absent",receipts:[]}'
    return 0
  fi
  set +e
  local rows="[]" count=0
  rows="$(find "$receipt_dir" -maxdepth 1 -type f -name '*.json' 2>/dev/null | sort | tail -n "$tail_n" | jq -R '.' | jq -sc '.' 2>/dev/null)"
  count="$(echo "$rows" | jq 'length' 2>/dev/null || echo 0)"
  set -e
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg dir "$receipt_dir" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",receipt_dir:$dir,tail_n:$tail_n,count:$count,recent_receipts:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <path> argument\n' >&2; return 64
  fi
  # Classification + age + would-prune calculation.
  local allowed_match=false forbidden_match=false classification="unknown"
  if declare -F is_allowed_base >/dev/null 2>&1; then
    if is_allowed_base "$id" 2>/dev/null; then allowed_match=true; fi
  fi
  if declare -F is_forbidden_base >/dev/null 2>&1; then
    if is_forbidden_base "$id" 2>/dev/null; then forbidden_match=true; fi
  fi
  if [[ "$forbidden_match" == "true" ]]; then
    classification="forbidden"
  elif [[ "$allowed_match" == "true" ]]; then
    classification="allowed"
  fi

  set +e
  local exists=false age_days=null size_bytes=0
  if [[ -e "$id" ]]; then
    exists=true
    local mtime now
    mtime="$(stat -f %m "$id" 2>/dev/null)"
    if [[ -n "$mtime" ]]; then
      now="$(date +%s)"
      age_days=$(( (now - mtime) / 86400 ))
    fi
    size_bytes="$(du -sk "$id" 2>/dev/null | awk '{print $1 * 1024}')"
    [[ -z "$size_bytes" ]] && size_bytes=0
  fi
  set -e

  local days_threshold="${FLYWHEEL_TMP_PRUNE_DAYS:-1}"
  local would_prune=false
  if [[ "$classification" == "allowed" && "$age_days" != "null" && "$age_days" -ge "$days_threshold" ]]; then
    would_prune=true
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    --arg classification "$classification" \
    --argjson allowed "$allowed_match" --argjson forbidden "$forbidden_match" \
    --argjson exists "$exists" --argjson age "${age_days:-null}" --argjson size "$size_bytes" \
    --argjson threshold "$days_threshold" --argjson would_prune "$would_prune" \
    '{schema_version:$sv,command:"why",id:$id,
      classification:$classification,allowed:$allowed,forbidden:$forbidden,
      currently_exists:$exists,age_days:$age,size_bytes:$size,
      days_threshold:$threshold,would_prune_at_threshold:$would_prune}'
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
ROOT_PATH="${FLYWHEEL_TMP_PRUNE_ROOT:-/private/tmp}"
RECEIPT_DIR="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"
DAYS="${FLYWHEEL_TMP_PRUNE_DAYS:-1}"
APPLY=0
JSON_OUT=0
IDEMPOTENCY_KEY="${FLYWHEEL_TMP_PRUNE_IDEMPOTENCY_KEY:-}"
TMP_PRUNE_WORKDIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CLI_REGISTRY_EMIT="${FLYWHEEL_CLI_REGISTRY_EMIT:-$SCRIPT_DIR/cli-registry-emit.sh}"

usage() {
  if [ -x "$CLI_REGISTRY_EMIT" ]; then
    "$CLI_REGISTRY_EMIT" tmp-prune.sh --mode help
    return
  fi
  printf '%s\n' \
    "Usage: tmp-prune.sh [--root PATH] [--days N] [--dry-run|--apply --idempotency-key KEY] [--json]" \
    "Default is dry-run. Candidates are limited to explicit fleet scratch prefixes under the selected tmp root."
}

json_bool() {
  if [ "$1" -eq 1 ]; then printf 'true'; else printf 'false'; fi
}

is_allowed_base() {
  case "$1" in
    alps.*|alpsinsurance*|flywheel-*|beads.*|beads_*|claude-skills-sync|mobile-eats-*|br-*) return 0 ;;
    *) return 1 ;;
  esac
}

is_forbidden_base() {
  case "$1" in
    com.apple.*|launchd-*) return 0 ;;
    *) return 1 ;;
  esac
}

validate_days() {
  case "$DAYS" in
    ''|*[!0-9]*) printf 'ERROR: --days must be a non-negative integer\n' >&2; exit 2 ;;
  esac
}

validate_root() {
  case "$ROOT_PATH" in
    /private/tmp|/private/tmp/*|/tmp/*|/var/folders/*) ;;
    *) printf 'ERROR: root is outside allowed tmp roots: %s\n' "$ROOT_PATH" >&2; exit 2 ;;
  esac
  [ -d "$ROOT_PATH" ] || { printf 'ERROR: root is not a directory: %s\n' "$ROOT_PATH" >&2; exit 2; }
}

candidate_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \
    \( -name 'alps.*' -o -name 'alpsinsurance*' -o -name 'flywheel-*' -o -name 'beads.*' -o -name 'beads_*' -o -name 'claude-skills-sync' -o -name 'mobile-eats-*' -o -name 'br-*' \) \
    -mtime "+$DAYS" -print 2>/dev/null | sort
}

forbidden_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \( -name 'com.apple.*' -o -name 'launchd-*' \) -mtime "+$DAYS" -print 2>/dev/null | sort
}

unknown_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \
    ! \( -name 'alps.*' -o -name 'alpsinsurance*' -o -name 'flywheel-*' -o -name 'beads.*' -o -name 'beads_*' -o -name 'claude-skills-sync' -o -name 'mobile-eats-*' -o -name 'br-*' -o -name 'com.apple.*' -o -name 'launchd-*' \) \
    -mtime "+$DAYS" -print 2>/dev/null | sort
}

path_bytes() {
  du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
}

path_mtime() {
  stat -f '%m' "$1" 2>/dev/null || printf '0'
}

append_path_object() {
  local path="$1" out="$2" base bytes mtime
  base="${path##*/}"
  if is_forbidden_base "$base"; then
    printf 'ERROR: forbidden tmp prefix reached candidate set: %s\n' "$path" >&2
    exit 3
  fi
  if ! is_allowed_base "$base"; then
    printf 'ERROR: unknown tmp prefix reached candidate set: %s\n' "$path" >&2
    exit 3
  fi
  bytes="$(path_bytes "$path")"
  mtime="$(path_mtime "$path")"
  jq -nc \
    --arg path "$path" \
    --arg base "$base" \
    --argjson bytes "${bytes:-0}" \
    --argjson mtime "${mtime:-0}" \
    '{path:$path,basename:$base,bytes:$bytes,mtime_epoch:$mtime}' >>"$out"
}

build_path_jsonl() {
  local candidates="$1" objects="$2" path
  : >"$objects"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    append_path_object "$path" "$objects"
  done <"$candidates"
  return 0
}

write_receipt() {
  local tmpdir="$1" status="$2" receipt_path="$3" apply_json dry_run_json
  apply_json="$(json_bool "$APPLY")"
  if [ "$APPLY" -eq 1 ]; then dry_run_json=false; else dry_run_json=true; fi
  mkdir -p "$RECEIPT_DIR"
  jq -nc \
    --arg schema_version "tmp-prune/v1" \
    --arg status "$status" \
    --arg root "$ROOT_PATH" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --arg receipt_path "$receipt_path" \
    --argjson apply "$apply_json" \
    --argjson dry_run "$dry_run_json" \
    --argjson days "$DAYS" \
    --slurpfile paths "$tmpdir/path-objects.jsonl" \
    --argjson forbidden_count "$(wc -l <"$tmpdir/forbidden.txt" | tr -d ' ')" \
    --argjson unknown_count "$(wc -l <"$tmpdir/unknown.txt" | tr -d ' ')" \
    '{
      schema_version:$schema_version,
      status:$status,
      root:$root,
      apply:$apply,
      dry_run:$dry_run,
      older_than_mtime_days:$days,
      idempotency_key:$idempotency_key,
      receipt_path:$receipt_path,
      allowlist_prefixes:["alps.*","alpsinsurance*","flywheel-*","beads.*","beads_*","claude-skills-sync","mobile-eats-*","br-*"],
      forbidden_prefixes:["com.apple.*","launchd-*"],
      paths_to_prune:$paths,
      paths_to_prune_count:($paths | length),
      bytes_to_prune:($paths | map(.bytes) | add // 0),
      excluded:{forbidden_prefix_count:$forbidden_count,unknown_prefix_count:$unknown_count}
    }' >"$receipt_path"
}

apply_candidates() {
  local candidates="$1" path base
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    base="${path##*/}"
    is_allowed_base "$base" || { printf 'ERROR: unknown tmp prefix reached apply set: %s\n' "$path" >&2; exit 3; }
    is_forbidden_base "$base" && { printf 'ERROR: forbidden tmp prefix reached apply set: %s\n' "$path" >&2; exit 3; }
    case "$path" in
      "$ROOT_PATH"/*) rm -rf -- "$path" ;;
      *) printf 'ERROR: candidate outside tmp root: %s\n' "$path" >&2; exit 3 ;;
    esac
  done <"$candidates"
  return 0
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --root) [ $# -ge 2 ] || { printf 'ERROR: --root requires PATH\n' >&2; exit 2; }; ROOT_PATH="$2"; shift 2 ;;
      --days) [ $# -ge 2 ] || { printf 'ERROR: --days requires N\n' >&2; exit 2; }; DAYS="$2"; shift 2 ;;
      --dry-run) APPLY=0; shift ;;
      --apply) APPLY=1; shift ;;
      --json) JSON_OUT=1; shift ;;
      --idempotency-key) [ $# -ge 2 ] || { printf 'ERROR: --idempotency-key requires KEY\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
      *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  return 0
}

main() {
  local tmpdir ts receipt_path status
  parse_args "$@"
  validate_days
  validate_root
  if [ "$APPLY" -eq 1 ] && [ -z "$IDEMPOTENCY_KEY" ]; then
    printf 'ERROR: --apply requires --idempotency-key\n' >&2
    exit 2
  fi
  if [ -z "$IDEMPOTENCY_KEY" ]; then
    IDEMPOTENCY_KEY="dry-run"
  fi

  tmpdir="$(mktemp -d -t tmp-prune.XXXXXX)"
  TMP_PRUNE_WORKDIR="$tmpdir"
  trap 'if [ -n "${TMP_PRUNE_WORKDIR:-}" ]; then rm -rf "$TMP_PRUNE_WORKDIR"; fi' EXIT
  candidate_find >"$tmpdir/candidates.txt"
  forbidden_find >"$tmpdir/forbidden.txt"
  unknown_find >"$tmpdir/unknown.txt"
  build_path_jsonl "$tmpdir/candidates.txt" "$tmpdir/path-objects.jsonl"

  status="dry_run"
  if [ "$APPLY" -eq 1 ]; then
    apply_candidates "$tmpdir/candidates.txt"
    status="applied"
  fi

  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  receipt_path="$RECEIPT_DIR/$ts.json"
  if [ -e "$receipt_path" ]; then
    receipt_path="$RECEIPT_DIR/$ts.$$.json"
  fi
  write_receipt "$tmpdir" "$status" "$receipt_path"
  if [ "$JSON_OUT" -eq 1 ]; then
    cat "$receipt_path"
  else
    jq -r '"tmp-prune status=\(.status) paths_to_prune=\(.paths_to_prune_count) bytes_to_prune=\(.bytes_to_prune) receipt=\(.receipt_path)"' "$receipt_path"
  fi
}

main "$@"
