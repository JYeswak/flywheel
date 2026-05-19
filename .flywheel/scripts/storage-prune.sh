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
# specific logic was filled in by flywheel-bz0h3 (P3 sub-bead).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="storage-prune/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-prune-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: storage-prune.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "storage-prune.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "storage-prune.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"storage-prune.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"storage-prune.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"storage-prune.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-storage-prune}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"prune flywheel-managed storage: .beads.bak.* dirs, /tmp dispatch artifacts, .br_recovery overflow, .beads sidecars, jeff-corpus stale entries. Plan-first; --apply requires --idempotency-key.",
    inputs:{
      repo:{type:"path",default:"/Users/josh/Developer/flywheel"},
      days:{type:"integer",default:7,env:"FLYWHEEL_STORAGE_PRUNE_DAYS"},
      jeff_corpus_days:{type:"integer",default:14,env:"FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DAYS"},
      jeff_corpus_dir:{type:"path",env:"FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR",default:"$REPO/.flywheel/jeff-corpus"},
      br_recovery_max_mb:{type:"integer",default:50,env:"FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_MB"},
      br_recovery_max_entries:{type:"integer",default:1000,env:"FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_ENTRIES"},
      idempotency_key:{type:"string",env:"FLYWHEEL_STORAGE_PRUNE_IDEMPOTENCY_KEY",required_for:"--apply"}
    },
    outputs:{
      runs_log:{path:"$HOME/.local/state/flywheel/storage-prune-runs.jsonl"},
      stdout:{type:"json",fields:["plan","candidates","applied","archive_path"]}
    },
    candidate_classes:[".beads.bak.*-dirs","/tmp dispatch artifacts",".br_recovery overflow",".beads sidecars (*.aside.*, *.bak.*)","jeff-corpus stale"],
    side_effects:["dry_run: read-only enumeration","apply: deletes candidates after optional archive (--archive)","appends row to runs_log"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — full plan-and-prune cycle. Enumerates 5 candidate classes (.beads.bak.* dirs, /tmp dispatch artifacts, .br_recovery overflow, .beads sidecars, jeff-corpus stale). --apply requires --idempotency-key. Default plan-only.\n' ;;
    doctor)   printf 'topic: doctor — probes 6 substrate dimensions: REPO is flywheel, find/jq on PATH, runs ledger writable, jeff-corpus dir resolvable (or absent OK), DAYS sane (>=1), candidate paths accessible.\n' ;;
    health)   printf 'topic: health — tail runs ledger; reports recent_run_count, last_run_ts, last_apply_ts, age_seconds_since_last. Status warn when stale >7 days (cron may be off).\n' ;;
    repair)   printf 'topic: repair — scopes: candidates (re-enumerate plan; no mutation), runs-log-rotate (rotate runs ledger when >5MB). For actual pruning, use the canonical run path with --apply --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: plan-row (--plan-json against required fields), candidate-path (--path against allowlist + age threshold), config (env values).\n' ;;
    audit)    printf 'topic: audit — tail recent rows from the runs ledger. --tail=N (default 10).\n' ;;
    why)      printf 'topic: why <path> — explain whether <path> is in the prune candidate set; emits classification (.beads.bak / dispatch-artifact / br_recovery / sidecar / jeff-corpus / not-prunable) + age vs threshold.\n' ;;
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
            && cli_emit_completion_bash "storage-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "storage-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 6 substrate checks. Pure if/then/else/fi (no L4 short-circuits).
  local ts repo_root days jeff_dir jeff_days runs_log
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  repo_root="${REPO:-/Users/josh/Developer/flywheel}"
  days="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
  jeff_days="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DAYS:-14}"
  jeff_dir="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR:-$repo_root/.flywheel/jeff-corpus}"
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-prune-runs.jsonl}"

  local repo_status="fail" repo_reason=""
  if [[ -d "$repo_root/.flywheel" ]]; then repo_status="pass"
  else repo_reason="$repo_root is not a flywheel repo (no .flywheel/)"; fi

  local find_status="fail" find_reason=""
  if command -v find >/dev/null 2>&1; then find_status="pass"
  else find_reason="find not on PATH"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH"; fi

  local runs_status="fail" runs_reason=""
  if [[ -f "$runs_log" && -w "$runs_log" ]]; then runs_status="pass"
  elif [[ -f "$runs_log" ]]; then runs_reason="exists but not writable: $runs_log"
  elif [[ -w "$(dirname "$runs_log")" ]]; then runs_status="pass"; runs_reason="absent but parent writable"
  else runs_reason="parent not writable: $(dirname "$runs_log")"; fi

  local jeff_status="pass" jeff_reason=""
  if [[ ! -d "$jeff_dir" ]]; then jeff_reason="jeff-corpus dir absent (will be skipped during prune): $jeff_dir"; fi

  local days_status="fail" days_reason=""
  if [[ "$days" =~ ^[0-9]+$ ]] && [[ "$days" -ge 1 ]]; then days_status="pass"
  else days_reason="days invalid: '$days' (must be int >= 1)"; fi

  local overall="pass"
  for s in "$repo_status" "$find_status" "$jq_status" "$runs_status" "$jeff_status" "$days_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg repo "$repo_root" --arg repo_status "$repo_status" --arg repo_reason "$repo_reason" \
    --arg find_status "$find_status" --arg find_reason "$find_reason" \
    --arg jq_status "$jq_status" --arg jq_reason "$jq_reason" \
    --arg runs_log "$runs_log" --arg runs_status "$runs_status" --arg runs_reason "$runs_reason" \
    --arg jeff_dir "$jeff_dir" --arg jeff_status "$jeff_status" --arg jeff_reason "$jeff_reason" \
    --argjson days "$days" --arg days_status "$days_status" --arg days_reason "$days_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"flywheel_repo_resolvable",status:$repo_status,path:$repo,reason:$repo_reason},
      {name:"find_on_path",status:$find_status,reason:$find_reason},
      {name:"jq_on_path",status:$jq_status,reason:$jq_reason},
      {name:"runs_ledger_writable",status:$runs_status,path:$runs_log,reason:$runs_reason},
      {name:"jeff_corpus_dir",status:$jeff_status,path:$jeff_dir,reason:$jeff_reason},
      {name:"days_threshold_sane",status:$days_status,value:$days,reason:$days_reason}
    ]}'
}

scaffold_cmd_health() {
  # Tail runs ledger for recent prune activity.
  local ts runs_log tail_count=20 tail_lines total last_ts last_apply_ts age_seconds
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-prune-runs.jsonl}"

  if [[ ! -f "$runs_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$runs_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"runs ledger absent (no prunes recorded yet)",runs_log:$log,recent_count:0}'
    return 0
  fi

  set +e
  tail_lines="$(tail -n "$tail_count" "$runs_log" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || echo 0)"
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  last_apply_ts="$(printf '%s\n' "$tail_lines" | jq -r 'select(.mode == "apply" or .applied == true) | .ts' 2>/dev/null | tail -1)"
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
    status="warn"; reason="runs ledger present but empty"
  elif [[ "$age_seconds" != "null" ]] && [[ "$age_seconds" -gt 604800 ]]; then
    status="warn"; reason="last prune > 7 days ago (age=${age_seconds}s) — cron may be stalled"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg runs_log "$runs_log" \
    --argjson total "$total" \
    --arg last_ts "$last_ts" --arg last_apply "$last_apply_ts" \
    --argjson age "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      runs_log:$runs_log,recent_count:$total,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      last_apply_ts:(if $last_apply == "" then null else $last_apply end),
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
  #   candidates       — re-enumerate the prune plan (read-only count summary)
  #   runs-log-rotate  — rotate runs ledger when >5MB
  local runs_log repo_root
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-prune-runs.jsonl}"
  repo_root="${REPO:-/Users/josh/Developer/flywheel}"

  case "$scope" in
    candidates)
      # Re-enumerate plan as a quick count summary (read-only).
      local days="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
      set +e
      local beads_bak_count=0 dispatch_count=0
      if [[ -d "$repo_root" ]]; then
        beads_bak_count="$(find "$repo_root" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "+$days" 2>/dev/null | wc -l | tr -d ' ')"
      fi
      dispatch_count="$(find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "+$days" 2>/dev/null | wc -l | tr -d ' ')"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        --arg repo "$repo_root" --argjson days "$days" \
        --argjson beads "$beads_bak_count" --argjson dispatch "$dispatch_count" \
        '{schema_version:$sv,command:"repair",status:"plan",mode:$mode,scope:$scope,idempotency_key:$idem,
          repo:$repo,days:$days,
          candidate_counts:{beads_bak_dirs:$beads,tmp_dispatch_artifacts:$dispatch},
          note:"plan-only enumeration; the canonical apply path is `storage-prune.sh --apply --idempotency-key KEY`"}'
      ;;
    runs-log-rotate)
      local size=0 rotate_threshold=5242880  # 5 MB
      if [[ -f "$runs_log" ]]; then
        size="$(wc -c <"$runs_log" | tr -d ' ')"
      fi
      local needs_rotate=false
      if [[ "$size" -gt "$rotate_threshold" ]]; then needs_rotate=true; fi
      if [[ "$mode" == "apply" && "$needs_rotate" == "true" ]]; then
        local rotated="${runs_log}.$(date -u +%Y%m%dT%H%M%SZ)"
        mv "$runs_log" "$rotated" 2>/dev/null
        : > "$runs_log"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg runs_log "$runs_log" --arg rotated "$rotated" --argjson size "$size" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,runs_log:$runs_log,rotated_to:$rotated,old_size_bytes:$size}'
      elif [[ "$mode" == "apply" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg runs_log "$runs_log" --argjson size "$size" --argjson threshold "$rotate_threshold" \
          '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,runs_log:$runs_log,size_bytes:$size,threshold_bytes:$threshold,reason:"under threshold; no rotation needed"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --arg runs_log "$runs_log" --argjson size "$size" --argjson threshold "$rotate_threshold" --argjson needs "$needs_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,runs_log:$runs_log,size_bytes:$size,threshold_bytes:$threshold,needs_rotate:$needs}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["candidates","runs-log-rotate"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["candidates","runs-log-rotate"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation:
  #   --plan-json=<JSON>     validate a plan envelope row's required fields
  #   --path=<PATH>          classify path against the prune candidate ruleset
  #   --config               validate REPO + DAYS + JEFF_CORPUS env values
  local subject="" plan_json="" path_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plan-json=*) plan_json="${1#--plan-json=}"; subject="plan"; shift ;;
      --path=*) path_arg="${1#--path=}"; subject="path"; shift ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    plan)
      [[ -z "$plan_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--plan-json=JSON required"}'; return 64; }
      local required='["plan","candidates"]'
      local missing valid
      missing="$(echo "$plan_json" | jq -c --argjson req "$required" --argjson r "$plan_json" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      if echo "$plan_json" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" --argjson r "$plan_json" \
        '{schema_version:$sv,command:"validate",subject:"plan",status:(if $valid and ($missing | length == 0) then "pass" else "fail" end),valid:$valid,missing_fields:$missing,plan:$r}'
      ;;
    path)
      [[ -z "$path_arg" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--path=PATH required"}'; return 64; }
      # Classify path against the prune ruleset
      local classification="not-prunable" matched_rule=""
      if [[ "$path_arg" =~ /\.beads\.bak\. ]]; then
        classification="prunable"; matched_rule=".beads.bak.* dir"
      elif [[ "$path_arg" =~ ^/tmp/(dispatch_|.*dispatch.*\.(txt|md)$) ]]; then
        classification="prunable"; matched_rule="/tmp dispatch artifact"
      elif [[ "$path_arg" =~ /\.br_recovery ]]; then
        classification="prunable"; matched_rule=".br_recovery (size/entry limited)"
      elif [[ "$path_arg" =~ /\.beads/.+\.(aside|bak)\. ]]; then
        classification="prunable"; matched_rule=".beads sidecar"
      elif [[ "$path_arg" =~ jeff-corpus ]]; then
        classification="prunable"; matched_rule="jeff-corpus stale"
      fi
      local exists=false
      [[ -e "$path_arg" ]] && exists=true
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$path_arg" \
        --arg classification "$classification" --arg rule "$matched_rule" \
        --argjson exists "$exists" \
        '{schema_version:$sv,command:"validate",subject:"path",status:(if $classification == "prunable" then "pass" else "warn" end),
          path:$path,classification:$classification,matched_rule:(if $rule == "" then null else $rule end),currently_exists:$exists}'
      ;;
    config)
      local repo_root days jeff_dir repo_valid=false days_valid=false jeff_valid=true
      repo_root="${REPO:-/Users/josh/Developer/flywheel}"
      days="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
      jeff_dir="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR:-$repo_root/.flywheel/jeff-corpus}"
      [[ -d "$repo_root/.flywheel" ]] && repo_valid=true
      [[ "$days" =~ ^[0-9]+$ ]] && [[ "$days" -ge 1 ]] && days_valid=true
      # jeff dir is allowed to be absent (skip semantics); always-valid unless path expression is malformed
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg repo "$repo_root" --argjson repo_valid "$repo_valid" \
        --argjson days "$days" --argjson days_valid "$days_valid" \
        --arg jeff "$jeff_dir" --argjson jeff_valid "$jeff_valid" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if $repo_valid and $days_valid and $jeff_valid then "pass" else "fail" end),
          repo:{value:$repo,valid:$repo_valid},
          days:{value:$days,valid:$days_valid},
          jeff_corpus_dir:{value:$jeff,valid:$jeff_valid,note:"absent dir is OK; will be skipped during prune"}}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["plan","path","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail the runs ledger.
  local runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-prune-runs.jsonl}"
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
  if [[ ! -f "$runs_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$runs_log" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:0,status:"warn",reason:"runs ledger absent",rows:[]}'
    return 0
  fi
  local rows count
  rows="$(tail -n "$tail_n" "$runs_log" | jq -sc '.' 2>/dev/null || echo '[]')"
  count="$(echo "$rows" | jq 'length')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$runs_log" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <path> argument\n' >&2; return 64
  fi
  # Classify path against the prune ruleset + check filesystem state.
  local classification="not-prunable" matched_rule=""
  if [[ "$id" =~ /\.beads\.bak\. ]]; then
    classification="prunable"; matched_rule=".beads.bak.* dir"
  elif [[ "$id" =~ ^/tmp/(dispatch_|.*dispatch.*\.(txt|md)$) ]]; then
    classification="prunable"; matched_rule="/tmp dispatch artifact"
  elif [[ "$id" =~ /\.br_recovery ]]; then
    classification="prunable"; matched_rule=".br_recovery (size/entry-limited)"
  elif [[ "$id" =~ /\.beads/.+\.(aside|bak)\. ]]; then
    classification="prunable"; matched_rule=".beads sidecar"
  elif [[ "$id" =~ jeff-corpus ]]; then
    classification="prunable"; matched_rule="jeff-corpus stale"
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

  local days_threshold="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
  if [[ "$id" =~ jeff-corpus ]]; then
    days_threshold="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DAYS:-14}"
  fi
  local would_prune=false
  if [[ "$classification" == "prunable" && "$age_days" != "null" && "$age_days" -ge "$days_threshold" ]]; then
    would_prune=true
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    --arg classification "$classification" --arg rule "$matched_rule" \
    --argjson exists "$exists" --argjson age "${age_days:-null}" --argjson size "$size_bytes" \
    --argjson threshold "$days_threshold" --argjson would_prune "$would_prune" \
    '{schema_version:$sv,command:"why",id:$id,
      classification:$classification,
      matched_rule:(if $rule == "" then null else $rule end),
      currently_exists:$exists,
      age_days:$age,
      size_bytes:$size,
      days_threshold:$threshold,
      would_prune_at_threshold:$would_prune}'
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
REPO="${REPO:-/Users/josh/Developer/flywheel}"
APPLY=0
JSON_OUT=0
DAYS="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
IDEMPOTENCY_KEY="${FLYWHEEL_STORAGE_PRUNE_IDEMPOTENCY_KEY:-manual}"
BR_RECOVERY_MAX_MB="${FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_MB:-50}"
BR_RECOVERY_MAX_ENTRIES="${FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_ENTRIES:-1000}"
JEFF_CORPUS_DAYS="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DAYS:-14}"
JEFF_CORPUS_DIR="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR:-$REPO/.flywheel/jeff-corpus}"

usage() {
  printf '%s\n' \
    "Usage: storage-prune.sh [--repo PATH] [--days N] [--dry-run|--apply] [--json] --idempotency-key KEY" \
    "Default is dry-run. Removes stale .beads.bak.* dirs, tmp dispatch artifacts, stale Beads sidecars, and archives recovery/corpus bloat." \
    "Docker dangling cleanup is reported as a manual command; this script never prunes docker volumes."
}

cutoff_find_args() {
  local days="${1:-$DAYS}"
  printf '%s\n' "+${days}"
}

br_recovery_candidates() {
  local path size_kb entries max_kb
  max_kb=$((BR_RECOVERY_MAX_MB * 1024))
  for path in "$REPO/.br_recovery" "$REPO/.beads/.br_recovery"; do
    [ -d "$path" ] || continue
    size_kb="$(du -sk "$path" 2>/dev/null | awk '{print $1+0}')"
    entries="$(find "$path" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$size_kb" -gt "$max_kb" ] || [ "$entries" -gt "$BR_RECOVERY_MAX_ENTRIES" ]; then
      printf '%s\n' "$path"
    fi
  done
  return 0
}

sidecar_candidates() {
  [ -d "$REPO/.beads" ] || return 0
  find "$REPO/.beads" -maxdepth 1 -type f \( -name '*.aside.*' -o -name '*.bak.*' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort
}

jeff_corpus_candidates() {
  [ -d "$JEFF_CORPUS_DIR" ] || return 0
  find "$JEFF_CORPUS_DIR" -mindepth 1 -maxdepth 1 -mtime "$(cutoff_find_args "$JEFF_CORPUS_DAYS")" 2>/dev/null | sort
}

safe_archive_name() {
  printf '%s' "$1" | tr '/ ' '__' | tr -c 'A-Za-z0-9._-' '_'
}

plan_json() {
  local tmp_dirs tmp_files tmp_recovery tmp_sidecars tmp_jeff
  local bak_count file_count recovery_count sidecar_count jeff_count
  tmp_dirs="$(mktemp "${TMPDIR:-/tmp}/storage-prune-dirs.XXXXXX")"
  tmp_files="$(mktemp "${TMPDIR:-/tmp}/storage-prune-files.XXXXXX")"
  tmp_recovery="$(mktemp "${TMPDIR:-/tmp}/storage-prune-recovery.XXXXXX")"
  tmp_sidecars="$(mktemp "${TMPDIR:-/tmp}/storage-prune-sidecars.XXXXXX")"
  tmp_jeff="$(mktemp "${TMPDIR:-/tmp}/storage-prune-jeff.XXXXXX")"
  find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort >"$tmp_dirs"
  find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort >"$tmp_files"
  br_recovery_candidates >"$tmp_recovery"
  sidecar_candidates >"$tmp_sidecars"
  jeff_corpus_candidates >"$tmp_jeff"
  bak_count="$(wc -l <"$tmp_dirs" | tr -d ' ')"
  file_count="$(wc -l <"$tmp_files" | tr -d ' ')"
  recovery_count="$(wc -l <"$tmp_recovery" | tr -d ' ')"
  sidecar_count="$(wc -l <"$tmp_sidecars" | tr -d ' ')"
  jeff_count="$(wc -l <"$tmp_jeff" | tr -d ' ')"
  jq -nc \
    --arg repo "$REPO" \
    --arg key "$IDEMPOTENCY_KEY" \
    --arg jeff_corpus_dir "$JEFF_CORPUS_DIR" \
    --argjson apply "$APPLY" \
    --argjson days "$DAYS" \
    --argjson jeff_days "$JEFF_CORPUS_DAYS" \
    --argjson br_recovery_max_mb "$BR_RECOVERY_MAX_MB" \
    --argjson br_recovery_max_entries "$BR_RECOVERY_MAX_ENTRIES" \
    --argjson bak_count "$bak_count" \
    --argjson file_count "$file_count" \
    --argjson recovery_count "$recovery_count" \
    --argjson sidecar_count "$sidecar_count" \
    --argjson jeff_count "$jeff_count" \
    --argjson bak_dirs "$(jq -R . "$tmp_dirs" | jq -s .)" \
    --argjson tmp_files_json "$(jq -R . "$tmp_files" | jq -s .)" \
    --argjson br_recovery_dirs "$(jq -R . "$tmp_recovery" | jq -s .)" \
    --argjson stale_sidecars "$(jq -R . "$tmp_sidecars" | jq -s .)" \
    --argjson jeff_corpus_entries "$(jq -R . "$tmp_jeff" | jq -s .)" \
    '{
      status:"ok",
      apply:($apply==1),
      repo:$repo,
      idempotency_key:$key,
      older_than_days:$days,
      thresholds:{br_recovery_max_mb:$br_recovery_max_mb,br_recovery_max_entries:$br_recovery_max_entries,jeff_corpus_older_than_days:$jeff_days},
      planned:{stale_bak_dirs:$bak_count,tmp_dispatch_artifacts:$file_count,br_recovery_archives:$recovery_count,stale_beads_sidecars:$sidecar_count,jeff_corpus_archives:$jeff_count},
      paths:{stale_bak_dirs:$bak_dirs,tmp_dispatch_artifacts:$tmp_files_json,br_recovery_dirs:$br_recovery_dirs,stale_beads_sidecars:$stale_sidecars,jeff_corpus_entries:$jeff_corpus_entries},
      jeff_corpus_dir:$jeff_corpus_dir,
      docker_manual_command:"docker system prune --force",
      docker_volumes_pruned:false
    }'
  rm -f "$tmp_dirs" "$tmp_files" "$tmp_recovery" "$tmp_sidecars" "$tmp_jeff"
}

apply_plan() {
  local path ts br_archive jeff_archive dest name
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.beads.bak.*) rm -rf "$path" ;;
    esac
  done < <(find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null)
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      /tmp/*dispatch*) rm -f "$path" ;;
    esac
  done < <(find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null)
  br_archive="/tmp/br_recovery.archived-$ts"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.br_recovery|"$REPO"/.beads/.br_recovery)
        mkdir -p "$br_archive"
        name="$(safe_archive_name "${path#"$REPO"/}")"
        dest="$br_archive/$name"
        [ -e "$dest" ] && dest="$dest.$$"
        mv "$path" "$dest"
        ;;
    esac
  done < <(br_recovery_candidates)
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.beads/*.aside.*|"$REPO"/.beads/*.bak.*) rm -f -- "$path" ;;
    esac
  done < <(sidecar_candidates)
  jeff_archive="/tmp/jeff-corpus.archived-$ts"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$JEFF_CORPUS_DIR"/*)
        mkdir -p "$jeff_archive"
        dest="$jeff_archive/$(basename "$path")"
        [ -e "$dest" ] && dest="$dest.$$"
        mv "$path" "$dest"
        ;;
    esac
  done < <(jeff_corpus_candidates)
  return 0
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --repo) [ $# -ge 2 ] || { printf 'ERROR: --repo requires PATH\n' >&2; exit 2; }; REPO="$2"; shift 2 ;;
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
  parse_args "$@"
  if [ -z "${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR+x}" ]; then
    JEFF_CORPUS_DIR="$REPO/.flywheel/jeff-corpus"
  fi
  if [ "$APPLY" -eq 1 ] && [ "$IDEMPOTENCY_KEY" = "manual" ]; then
    printf 'ERROR: --apply requires --idempotency-key\n' >&2
    exit 2
  fi
  [ "$APPLY" -eq 0 ] || apply_plan
  if [ "$JSON_OUT" -eq 1 ]; then
    plan_json
  else
    plan_json | jq -r '"storage-prune apply=\(.apply) stale_bak_dirs=\(.planned.stale_bak_dirs) tmp_dispatch_artifacts=\(.planned.tmp_dispatch_artifacts)"'
  fi
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
