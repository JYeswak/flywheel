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
# specific logic was filled in by flywheel-al24y (P3 sub-bead).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="storage-pressure-doctor/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-pressure-doctor-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: storage-pressure-doctor.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "storage-pressure-doctor.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "storage-pressure-doctor.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"storage-pressure-doctor.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"storage-pressure-doctor.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"storage-pressure-doctor.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-storage-pressure-doctor}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"diagnose storage pressure: disk usage via storage-probe.sh delegate, top consumers, /private/tmp aggregate, snapshot inventory, recommendations.",
    inputs:{
      storage_probe:{type:"path",default:"$ROOT/.flywheel/scripts/storage-probe.sh"},
      tmp_prune_ledger:{type:"path",env:"FLYWHEEL_TMP_PRUNE_LEDGER",default:"$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl"},
      storage_fixture:{type:"path",env:"FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE",description:"override storage-probe output for testing"}
    },
    outputs:{
      runs_log:{path:"$HOME/.local/state/flywheel/storage-pressure-doctor-runs.jsonl"},
      stdout:{type:"json",fields:["ts","storage","top_consumers","snapshots","private_tmp","recommendations"]}
    },
    side_effects:["read-only by default","invokes storage-probe.sh as delegate","reads tmp-prune ledger"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default invocation runs the full storage diagnostic: delegates to storage-probe.sh, computes top disk consumers, scans /private/tmp aggregate, lists APFS snapshots, emits recommendations. Read-only.\n' ;;
    doctor)   printf 'topic: doctor — probes 6 substrate dimensions: storage-probe.sh executable, df present, jq present, tmp-prune ledger writable, runs ledger writable, ROOT is a flywheel repo.\n' ;;
    health)   printf 'topic: health — tail tmp-prune ledger; reports recent prune count, last prune ts, age_seconds_since_last. Status warn when stale >24 hours (cron may be off).\n' ;;
    repair)   printf 'topic: repair — scopes: stale-prune (re-run private-tmp-prune via canonical script), runs-log-rotate (rotate scaffold runs ledger when >5MB). --apply requires --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: storage-probe-output (--probe-json=JSON; check required fields), tmp-prune-row (--row-json against ts/path/action), config (env values).\n' ;;
    audit)    printf 'topic: audit — tail recent rows from the runs ledger. --tail=N (default 10).\n' ;;
    why)      printf 'topic: why <path> — explain whether <path> is a top consumer; if it appears in tmp-prune-ledger, emit prune provenance.\n' ;;
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
            && cli_emit_completion_bash "storage-pressure-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "storage-pressure-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 6 substrate checks. Pure if/then/else/fi (no L4 short-circuits).
  local ts script_dir storage_probe tmp_prune_ledger runs_log root
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
  storage_probe="$root/.flywheel/scripts/storage-probe.sh"
  tmp_prune_ledger="${FLYWHEEL_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl}"
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-pressure-doctor-runs.jsonl}"

  local probe_status="fail" probe_reason=""
  if [[ -x "$storage_probe" ]]; then probe_status="pass"
  elif [[ -e "$storage_probe" ]]; then probe_reason="exists but not executable: $storage_probe"
  else probe_reason="storage-probe.sh absent: $storage_probe"; fi

  local df_status="fail" df_reason=""
  if command -v df >/dev/null 2>&1; then df_status="pass"
  else df_reason="df not on PATH"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH"; fi

  local tmp_status="fail" tmp_reason=""
  if [[ -f "$tmp_prune_ledger" && -r "$tmp_prune_ledger" ]]; then tmp_status="pass"
  elif [[ -f "$tmp_prune_ledger" ]]; then tmp_reason="exists but not readable: $tmp_prune_ledger"
  elif [[ -d "$(dirname "$tmp_prune_ledger")" ]]; then tmp_status="pass"; tmp_reason="absent but parent dir exists"
  else tmp_reason="parent dir absent: $(dirname "$tmp_prune_ledger")"; fi

  local runs_status="fail" runs_reason=""
  if [[ -f "$runs_log" && -w "$runs_log" ]]; then runs_status="pass"
  elif [[ -f "$runs_log" ]]; then runs_reason="exists but not writable: $runs_log"
  elif [[ -w "$(dirname "$runs_log")" ]]; then runs_status="pass"; runs_reason="absent but parent writable"
  else runs_reason="parent not writable: $(dirname "$runs_log")"; fi

  local root_status="fail" root_reason=""
  if [[ -d "$root/.flywheel" ]]; then root_status="pass"
  else root_reason="$root is not a flywheel repo (no .flywheel/)"; fi

  local overall="pass"
  for s in "$probe_status" "$df_status" "$jq_status" "$tmp_status" "$runs_status" "$root_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg storage_probe "$storage_probe" --arg probe_status "$probe_status" --arg probe_reason "$probe_reason" \
    --arg df_status "$df_status" --arg df_reason "$df_reason" \
    --arg jq_status "$jq_status" --arg jq_reason "$jq_reason" \
    --arg tmp_log "$tmp_prune_ledger" --arg tmp_status "$tmp_status" --arg tmp_reason "$tmp_reason" \
    --arg runs_log "$runs_log" --arg runs_status "$runs_status" --arg runs_reason "$runs_reason" \
    --arg root "$root" --arg root_status "$root_status" --arg root_reason "$root_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"storage_probe_executable",status:$probe_status,path:$storage_probe,reason:$probe_reason},
      {name:"df_on_path",status:$df_status,reason:$df_reason},
      {name:"jq_on_path",status:$jq_status,reason:$jq_reason},
      {name:"tmp_prune_ledger_readable",status:$tmp_status,path:$tmp_log,reason:$tmp_reason},
      {name:"runs_ledger_writable",status:$runs_status,path:$runs_log,reason:$runs_reason},
      {name:"flywheel_root_resolvable",status:$root_status,path:$root,reason:$root_reason}
    ]}'
}

scaffold_cmd_health() {
  # Tail tmp-prune ledger and report freshness.
  local ts tmp_log tail_count=20 tail_lines total last_ts age_seconds
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp_log="${FLYWHEEL_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl}"

  if [[ ! -f "$tmp_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$tmp_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"tmp-prune ledger absent (no prune cron runs yet)",ledger:$log,recent_count:0}'
    return 0
  fi

  set +e
  tail_lines="$(tail -n "$tail_count" "$tmp_log" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || echo 0)"
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
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
    status="warn"; reason="tmp-prune ledger present but empty"
  elif [[ "$age_seconds" != "null" ]] && [[ "$age_seconds" -gt 86400 ]]; then
    status="warn"; reason="last prune > 24 hours ago (age=${age_seconds}s) — cron may be stalled"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$tmp_log" \
    --argjson total "$total" \
    --arg last_ts "$last_ts" --argjson age "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      ledger:$log,recent_count:$total,
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
  # Per-scope repair:
  #   stale-prune       — point at canonical private-tmp-prune.sh path
  #   runs-log-rotate   — rotate scaffold runs ledger when >5MB
  local runs_log script_dir root prune_script
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-pressure-doctor-runs.jsonl}"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
  prune_script="$root/.flywheel/scripts/private-tmp-prune.sh"

  case "$scope" in
    stale-prune)
      local prune_present=false
      if [[ -x "$prune_script" ]]; then prune_present=true; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        --arg prune "$prune_script" --argjson prune_present "$prune_present" \
        '{schema_version:$sv,command:"repair",status:"plan",mode:$mode,scope:$scope,idempotency_key:$idem,canonical_prune_script:$prune,prune_script_present:$prune_present,note:"plan-only emitted; the canonical apply path is `private-tmp-prune.sh --apply --idempotency-key KEY` (filed as flywheel-gam2k surface; this scope merely points at it)"}'
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
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["stale-prune","runs-log-rotate"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["stale-prune","runs-log-rotate"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation:
  #   --probe-json=<JSON>    validate storage-probe.sh output against required fields
  #   --row-json=<JSON>      validate one tmp-prune ledger row
  #   --config               validate env vars + paths
  local subject="" probe_json="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --probe-json=*) probe_json="${1#--probe-json=}"; subject="probe"; shift ;;
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    probe)
      [[ -z "$probe_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--probe-json=JSON required"}'; return 64; }
      local required='["filesystem","size","used","available","use_percent"]'
      local missing valid
      missing="$(echo "$probe_json" | jq -c --argjson req "$required" --argjson r "$probe_json" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      if echo "$probe_json" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" --argjson r "$probe_json" \
        '{schema_version:$sv,command:"validate",subject:"probe",status:(if $valid and ($missing | length == 0) then "pass" else "fail" end),valid:$valid,missing_fields:$missing,probe:$r}'
      ;;
    row)
      [[ -z "$row_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required"}'; return 64; }
      local required='["ts","action"]'
      local missing valid
      missing="$(echo "$row_json" | jq -c --argjson req "$required" --argjson r "$row_json" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      if echo "$row_json" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" --argjson r "$row_json" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $valid and ($missing | length == 0) then "pass" else "fail" end),valid:$valid,missing_fields:$missing,row:$r}'
      ;;
    config)
      local script_dir root storage_probe tmp_log probe_valid=false log_valid=false root_valid=false
      script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
      root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
      storage_probe="$root/.flywheel/scripts/storage-probe.sh"
      tmp_log="${FLYWHEEL_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl}"
      [[ -x "$storage_probe" ]] && probe_valid=true
      [[ -d "$(dirname "$tmp_log")" ]] && log_valid=true
      [[ -d "$root/.flywheel" ]] && root_valid=true
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg probe "$storage_probe" --argjson probe_valid "$probe_valid" \
        --arg log "$tmp_log" --argjson log_valid "$log_valid" \
        --arg root "$root" --argjson root_valid "$root_valid" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if $probe_valid and $log_valid and $root_valid then "pass" else "fail" end),
          storage_probe:{value:$probe,valid:$probe_valid},
          tmp_prune_ledger:{value:$log,valid:$log_valid},
          repo_root:{value:$root,valid:$root_valid}}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["probe","row","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail the runs ledger.
  local runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-pressure-doctor-runs.jsonl}"
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
  # 2-tier provenance: tmp-prune ledger lookup + filesystem existence/size
  local tmp_log="${FLYWHEEL_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl}"

  set +e
  local row=""
  if [[ -f "$tmp_log" ]]; then
    row="$(grep -F "$id" "$tmp_log" 2>/dev/null | tail -1)"
  fi
  local exists=false size_bytes=0
  if [[ -e "$id" ]]; then
    exists=true
    size_bytes="$(du -sk "$id" 2>/dev/null | awk '{print $1 * 1024}')"
    [[ -z "$size_bytes" ]] && size_bytes=0
  fi
  set -e

  if [[ -n "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
      --argjson exists "$exists" --argjson size "$size_bytes" \
      '{schema_version:$sv,command:"why",id:$id,status:"found_in_tmp_prune_ledger",
        provenance:{ts:$row.ts,action:$row.action,row:$row},
        currently_exists:$exists,
        current_size_bytes:$size}'
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      --argjson exists "$exists" --argjson size "$size_bytes" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_in_ledger",
        currently_exists:$exists,
        current_size_bytes:$size,
        reason:"id not found in tmp-prune ledger; reporting filesystem state only"}'
  fi
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
VERSION="storage-pressure-doctor.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
STORAGE_PROBE="$ROOT/.flywheel/scripts/storage-probe.sh"
TMP_PRUNE_LEDGER="${FLYWHEEL_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl}"
JSON_OUT=0
MODE="doctor"
STORAGE_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE:-}"
TOP_CONSUMERS_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE:-}"
SNAPSHOT_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_SNAPSHOT_FIXTURE:-}"
TMP_LEDGER_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_TMP_LEDGER_FIXTURE:-}"
PRIVATE_TMP_GIB_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_PRIVATE_TMP_GIB_FIXTURE:-}"
AVAIL_WARN_GB="${FLYWHEEL_STORAGE_PRESSURE_AVAIL_WARN_GB:-20}"

usage() {
  printf '%s\n' \
    "Usage:" \
    "  storage-pressure-doctor.sh --doctor --json" \
    "  storage-pressure-doctor.sh --schema|--info|--examples|--help" \
    "" \
    "Read-only doctor. Aggregates storage-probe, top consumers, APFS snapshot" \
    "signals, and tmp prune ledger state. Recommends action when free space <20Gi."
}

examples() {
  printf '%s\n' \
    ".flywheel/scripts/storage-pressure-doctor.sh --doctor --json" \
    "FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE=tests/fixtures/storage-pressure/low-storage.json \\" \
    "  FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE=tests/fixtures/storage-pressure/top-consumers.txt \\" \
    "  .flywheel/scripts/storage-pressure-doctor.sh --doctor --json"
}

schema_json() {
  jq -nc '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"storage-pressure-doctor/v1",
    type:"object",
    required:["schema_version","status","storage","top_consumers","snapshots","private_tmp","recommendations"],
    properties:{
      schema_version:{const:"storage-pressure-doctor/v1"},
      status:{enum:["ok","warn","fail"]},
      storage:{type:"object"},
      top_consumers:{type:"array"},
      snapshots:{type:"object"},
      private_tmp:{type:"object"},
      recommendations:{type:"array"}
    }
  }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

human_to_gib() {
  awk -v raw="$1" '
    BEGIN {
      n = raw
      unit = substr(n, length(n), 1)
      sub(/[KMGTP]$/, "", n)
      val = n + 0
      if (unit == "T") val *= 1024
      else if (unit == "G") val *= 1
      else if (unit == "M") val /= 1024
      else if (unit == "K") val /= 1024 / 1024
      else if (unit == "P") val *= 1024 * 1024
      printf "%.2f", val
    }'
}

storage_json() {
  if [ -n "$STORAGE_FIXTURE" ]; then
    jq -c '.' "$STORAGE_FIXTURE"
    return 0
  fi
  "$STORAGE_PROBE" --json 2>/dev/null || true
}

top_consumers_json() {
  local source line size path gib count=0 tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-top.XXXXXX")"
  if [ -n "$TOP_CONSUMERS_FIXTURE" ]; then
    cp "$TOP_CONSUMERS_FIXTURE" "$tmp"
  else
    du -sh "$HOME"/Developer/* "$HOME"/.socraticode/* "$HOME"/.knowledge/* "$HOME"/Library/Caches/* /private/tmp/* /private/var/folders/* 2>/dev/null \
      | sort -rh \
      | head -30 >"$tmp" || true
  fi
  {
    printf '['
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      size="$(awk '{print $1}' <<<"$line")"
      path="$(awk '{print $2}' <<<"$line")"
      gib="$(human_to_gib "$size")"
      [ "$count" -eq 0 ] || printf ','
      jq -nc --arg size "$size" --arg path "$path" --argjson gib "$gib" '{size:$size,size_gib:$gib,path:$path}'
      count=$((count + 1))
    done <"$tmp"
    printf ']'
  } | jq -c '.'
  rm -f "$tmp"
}

snapshot_json() {
  if [ -n "$SNAPSHOT_FIXTURE" ]; then
    jq -c '.' "$SNAPSHOT_FIXTURE"
    return 0
  fi
  local tm_file disk_file tm_count disk_count sealed_count
  tm_file="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-tm.XXXXXX")"
  disk_file="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-diskutil.XXXXXX")"
  tmutil listlocalsnapshots / >"$tm_file" 2>/dev/null || true
  diskutil apfs list >"$disk_file" 2>/dev/null || true
  tm_count="$(grep -c '^com\\.apple\\.TimeMachine\\.' "$tm_file" 2>/dev/null || true)"
  disk_count="$(grep -c 'Snapshot:' "$disk_file" 2>/dev/null || true)"
  sealed_count="$(grep -c 'Snapshot Sealed:[[:space:]]*Yes' "$disk_file" 2>/dev/null || true)"
  jq -nc \
    --argjson tm_count "${tm_count:-0}" \
    --argjson disk_count "${disk_count:-0}" \
    --argjson sealed_count "${sealed_count:-0}" \
    --argjson tm_snapshots "$(grep '^com\\.apple\\.TimeMachine\\.' "$tm_file" 2>/dev/null | jq -R . | jq -s .)" \
    '{
      tm_local_snapshot_count:$tm_count,
      apfs_snapshot_count:$disk_count,
      sealed_system_snapshot_count:$sealed_count,
      tm_local_snapshots:$tm_snapshots,
      evidence:"tmutil listlocalsnapshots /; diskutil apfs list"
    }'
  rm -f "$tm_file" "$disk_file"
}

private_tmp_json() {
  local ledger="$TMP_PRUNE_LEDGER" last="null" ledger_exists=false entry_count=0 total_gib=0 kb=0
  if [ -n "$TMP_LEDGER_FIXTURE" ]; then
    ledger="$TMP_LEDGER_FIXTURE"
  fi
  if [ -s "$ledger" ]; then
    ledger_exists=true
    last="$(tail -n 1 "$ledger" | jq -c '.' 2>/dev/null || printf 'null')"
  fi
  entry_count="$(find /private/tmp -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
  if [ -n "$PRIVATE_TMP_GIB_FIXTURE" ]; then
    total_gib="$PRIVATE_TMP_GIB_FIXTURE"
  else
    kb="$(du -sk /private/tmp 2>/dev/null | awk '{print $1+0}' || printf 0)"
    total_gib="$(awk -v kb="${kb:-0}" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }')"
  fi
  jq -nc \
    --arg ledger "$ledger" \
    --argjson exists "$ledger_exists" \
    --argjson last "$last" \
    --argjson total_gib "$total_gib" \
    --argjson entry_count "${entry_count:-0}" \
    '{ledger_path:$ledger,ledger_exists:$exists,last_run:$last,private_tmp_total_gib:$total_gib,private_tmp_entry_count:$entry_count}'
}

recommendations_json() {
  local storage="$1" consumers="$2" snapshots="$3" tmp_json="$4"
  jq -nc \
    --argjson storage "$storage" \
    --argjson consumers "$consumers" \
    --argjson snapshots "$snapshots" \
    --argjson tmp "$tmp_json" \
    --argjson warn_gb "$AVAIL_WARN_GB" \
    '
      ($storage.disk_free_gb // 999999) as $free_gb
      | ($storage.disk_free_pct // 100) as $free_pct
      | [
          (if $free_gb < $warn_gb or $free_pct < 5 then {
            code:"storage_pressure_active",
            severity:(if $free_pct < 5 then "fire" elif $free_gb < $warn_gb then "critical" else "warn" end),
            action:"Pause growth-heavy clone/index jobs; run storage-health L1 and re-probe before L2+."
          } else empty end),
          (if ($snapshots.tm_local_snapshot_count // 0) > 0 and ($free_gb < $warn_gb) then {
            code:"tm_snapshots_present_under_pressure",
            severity:"warn",
            action:"Use apfs-snapshot-ops to inspect/thin Time Machine local snapshots; do not delete sealed system snapshots."
          } else empty end),
          (if (($tmp.ledger_exists // false) | not) then {
            code:"tmp_prune_ledger_missing",
            severity:"warn",
            action:"Verify ai.zeststream.tmp-aggressive-prune launchd wiring; ledger is missing."
          } else empty end),
          (if (($tmp.private_tmp_total_gib // 0) > 50) then {
            code:"private_tmp_large",
            severity:(if $free_gb < $warn_gb or $free_pct < 5 then "critical" else "warn" end),
            action:"/private/tmp is large even after the cron wrapper; inspect protected/recent tmp roots before widening prune age or patterns."
          } else empty end),
          (if ($consumers | length) > 0 then {
            code:"top_consumer_review",
            severity:"info",
            action:("Largest visible consumer: " + ($consumers[0].path // "unknown") + " (" + (($consumers[0].size // "unknown")|tostring) + ").")
          } else empty end)
        ]'
}

doctor_json() {
  local storage consumers snapshots tmp_json recs status
  storage="$(storage_json)"
  consumers="$(top_consumers_json)"
  snapshots="$(snapshot_json)"
  tmp_json="$(private_tmp_json)"
  recs="$(recommendations_json "$storage" "$consumers" "$snapshots" "$tmp_json")"
  status="$(jq -nr --argjson storage "$storage" --argjson recs "$recs" '
    if ($storage.status // "ok") == "fail" then "fail"
    elif any($recs[]?; .severity == "critical" or .severity == "fire") then "fail"
    elif (($recs | length) > 0 or ($storage.status // "ok") == "warn") then "warn"
    else "ok" end')"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg status "$status" \
    --argjson storage "$storage" \
    --argjson consumers "$consumers" \
    --argjson snapshots "$snapshots" \
    --argjson tmp_json "$tmp_json" \
    --argjson recs "$recs" \
    '{
      schema_version:"storage-pressure-doctor/v1",
      version:"storage-pressure-doctor.v1",
      ts:$ts,
      status:$status,
      storage:$storage,
      top_consumers:$consumers,
      snapshots:$snapshots,
      private_tmp:$tmp_json,
      recommendations:$recs
    }'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --doctor|doctor) MODE="doctor"; shift ;;
      --json) JSON_OUT=1; shift ;;
      --schema) schema_json; exit 0 ;;
      --info) jq -nc --arg version "$VERSION" --arg probe "$STORAGE_PROBE" '{version:$version,storage_probe:$probe,mutates:[]}'; exit 0 ;;
      --examples) examples; exit 0 ;;
      --help|-h) usage; exit 0 ;;
      *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  return 0
}

main() {
  local out
  parse_args "$@"
  case "$MODE" in
    doctor) out="$(doctor_json)" ;;
    *) printf 'ERROR: unknown mode: %s\n' "$MODE" >&2; exit 2 ;;
  esac
  if [ "$JSON_OUT" -eq 1 ]; then
    printf '%s\n' "$out"
  else
    jq -r '"storage_pressure status=\(.status) free_gb=\(.storage.disk_free_gb // "unknown") recommendations=\(.recommendations | length)"' <<<"$out"
  fi
  [ "$(jq -r '.status' <<<"$out")" != "fail" ]
}

main "$@"
