#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by flywheel-5kjez (P3 sub-bead from flywheel-wgitr).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-delivery-verify/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-delivery-verify-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-delivery-verify.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate row, task-id, or config contracts
  audit [--json]           recent run history
  why <id>                 explain delivery verification for a task id
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-delivery-verify.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-delivery-verify.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-delivery-verify.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-delivery-verify.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-delivery-verify.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-dispatch-delivery-verify}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"verify that an ntm-dispatched task actually landed in the target pane via ntm history + activity + changes/conflicts probes; append to delivery-verify ledger.",
    inputs:{
      session:{type:"string",required:true,description:"target ntm session"},
      pane:{type:"integer",required:true,description:"target pane index"},
      task_id:{type:"string",required:true,description:"task correlation id to search history for"},
      ntm_bin:{type:"binary",env:"DISPATCH_DELIVERY_VERIFY_NTM",default:"/Users/josh/.local/bin/ntm"}
    },
    outputs:{
      ledger:{path:"$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl"},
      stdout_envelope:{fields:["schema_version","verified","task_id","session","pane","reason","matched_at_line","history_evidence","activity_evidence","changes_evidence","conflicts_evidence"]}
    },
    side_effects:["read-only ntm probes (history/activity/changes/conflicts)","appends row to ledger","logs fuckup-row when verified=false"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — verify a specific task_id landed in a session:pane via ntm history grep + activity + changes + conflicts probes. Appends to ledger; logs fuckup-row when not verified. Required: --session NAME --pane N --task-id ID.\n' ;;
    doctor)   printf 'topic: doctor — probes 5 substrate dimensions: ntm binary executable, jq present, ledger writable, fuckup-log writable, history/activity/changes/conflicts subcommands present in ntm --help.\n' ;;
    health)   printf 'topic: health — tail delivery-verify ledger; reports recent_count, verified_count, recent_failure_count, last_run_ts, age_seconds_since_last. Status warn when recent failure rate >50%% or stale >24h.\n' ;;
    repair)   printf 'topic: repair — scopes: re-verify (re-attempt verification for a recent unverified task — points at canonical run path) + ledger-rotate (rotate ledger when >5MB).\n' ;;
    validate) printf 'topic: validate — subjects: row (--row-json against required ts/task_id/session/pane/verified), task-id (--task-id ID; check ledger for verification entry), config (env values).\n' ;;
    audit)    printf 'topic: audit — tail recent rows from the ledger. --tail=N (default 10).\n' ;;
    why)      printf 'topic: why <task_id> — explain why a task_id is/isn'\''t verified; emits ledger row + reason if found, or status=not_in_ledger if absent.\n' ;;
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
            && cli_emit_completion_bash "dispatch-delivery-verify" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-delivery-verify" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface implementation ----------

scaffold_cmd_doctor() {
  # 5 substrate checks. Pure if/then/else/fi.
  local ts ntm_bin ledger fuckup_log
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  ntm_bin="${DISPATCH_DELIVERY_VERIFY_NTM:-/Users/josh/.local/bin/ntm}"
  ledger="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
  fuckup_log="${DISPATCH_DELIVERY_VERIFY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"

  local ntm_status="fail" ntm_reason=""
  if [[ -x "$ntm_bin" ]]; then ntm_status="pass"
  elif [[ -e "$ntm_bin" ]]; then ntm_reason="exists but not executable: $ntm_bin"
  else ntm_reason="ntm not found: $ntm_bin"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH"; fi

  local ledger_status="fail" ledger_reason=""
  if [[ -f "$ledger" && -w "$ledger" ]]; then ledger_status="pass"
  elif [[ -f "$ledger" ]]; then ledger_reason="exists but not writable: $ledger"
  elif [[ -w "$(dirname "$ledger")" ]]; then ledger_status="pass"; ledger_reason="absent but parent writable"
  else ledger_reason="parent not writable: $(dirname "$ledger")"; fi

  local fuckup_status="fail" fuckup_reason=""
  if [[ -f "$fuckup_log" && -w "$fuckup_log" ]]; then fuckup_status="pass"
  elif [[ -w "$(dirname "$fuckup_log")" ]]; then fuckup_status="pass"; fuckup_reason="absent but parent writable"
  else fuckup_reason="parent not writable: $(dirname "$fuckup_log")"; fi

  local probes_status="fail" probes_reason=""
  if [[ -x "$ntm_bin" ]]; then
    set +e
    local help_out
    help_out="$("$ntm_bin" --help 2>&1)"
    set -e
    local missing=()
    for cmd in history activity changes conflicts; do
      grep -qE "^\s+$cmd\b" <<<"$help_out" || missing+=("$cmd")
    done
    if [[ "${#missing[@]}" -eq 0 ]]; then probes_status="pass"
    else probes_reason="ntm missing required subcommands: ${missing[*]}"; fi
  else
    probes_reason="ntm not executable; cannot check subcommand availability"
  fi

  local overall="pass"
  for s in "$ntm_status" "$jq_status" "$ledger_status" "$fuckup_status" "$probes_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg ntm "$ntm_bin" --arg ntm_status "$ntm_status" --arg ntm_reason "$ntm_reason" \
    --arg jq_status "$jq_status" --arg jq_reason "$jq_reason" \
    --arg ledger "$ledger" --arg ledger_status "$ledger_status" --arg ledger_reason "$ledger_reason" \
    --arg fuckup "$fuckup_log" --arg fuckup_status "$fuckup_status" --arg fuckup_reason "$fuckup_reason" \
    --arg probes_status "$probes_status" --arg probes_reason "$probes_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"ntm_binary_executable",status:$ntm_status,path:$ntm,reason:$ntm_reason},
      {name:"jq_on_path",status:$jq_status,reason:$jq_reason},
      {name:"ledger_writable",status:$ledger_status,path:$ledger,reason:$ledger_reason},
      {name:"fuckup_log_writable",status:$fuckup_status,path:$fuckup,reason:$fuckup_reason},
      {name:"ntm_probe_subcommands_present",status:$probes_status,reason:$probes_reason}
    ]}'
}

scaffold_cmd_health() {
  # Tail ledger; report recent verified vs failed rate + freshness.
  local ts ledger tail_count=20 tail_lines total verified failed last_ts age_seconds
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  ledger="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"

  if [[ ! -f "$ledger" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$ledger" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"ledger absent (no verifications recorded yet)",ledger:$log,recent_count:0}'
    return 0
  fi

  set +e
  tail_lines="$(tail -n "$tail_count" "$ledger" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || echo 0)"
  verified="$(printf '%s\n' "$tail_lines" | jq -r 'select(.verified == true) | .task_id' 2>/dev/null | wc -l | tr -d ' ')"
  failed="$(printf '%s\n' "$tail_lines" | jq -r 'select(.verified == false) | .task_id' 2>/dev/null | wc -l | tr -d ' ')"
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
    status="warn"; reason="ledger present but empty"
  elif [[ "$failed" -gt 0 && "$total" -gt 0 ]] && [[ $((failed * 100 / total)) -gt 50 ]]; then
    status="warn"; reason="recent failure rate >50% ($failed of $total)"
  elif [[ "$age_seconds" != "null" ]] && [[ "$age_seconds" -gt 86400 ]]; then
    status="warn"; reason="last verify > 24 hours ago (age=${age_seconds}s)"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$ledger" \
    --argjson total "$total" --argjson verified "$verified" --argjson failed "$failed" \
    --arg last_ts "$last_ts" --argjson age "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      ledger:$log,recent_count:$total,verified_count:$verified,failed_count:$failed,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
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
  #   re-verify       — point at canonical run path for re-verification
  #   ledger-rotate   — rotate ledger when >5MB
  local ledger
  ledger="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"

  case "$scope" in
    re-verify)
      # Find recent unverified rows; report task_ids that need re-attempt
      set +e
      local unverified_count=0 last_failed_task=""
      if [[ -f "$ledger" ]]; then
        unverified_count="$(tail -n 50 "$ledger" 2>/dev/null | jq -r 'select(.verified == false) | .task_id' 2>/dev/null | wc -l | tr -d ' ')"
        last_failed_task="$(tail -n 50 "$ledger" 2>/dev/null | jq -r 'select(.verified == false) | .task_id' 2>/dev/null | tail -1)"
      fi
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        --argjson count "$unverified_count" --arg last_failed "$last_failed_task" \
        '{schema_version:$sv,command:"repair",status:"plan",mode:$mode,scope:$scope,idempotency_key:$idem,
          recent_unverified_count:$count,last_failed_task:(if $last_failed == "" then null else $last_failed end),
          note:"plan-only; the canonical apply path is `dispatch-delivery-verify.sh --session NAME --pane N --task-id ID` for each unverified row"}'
      ;;
    ledger-rotate)
      local size=0 rotate_threshold=5242880
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
          '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,ledger:$ledger,size_bytes:$size,threshold_bytes:$threshold,reason:"under threshold"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --arg ledger "$ledger" --argjson size "$size" --argjson threshold "$rotate_threshold" --argjson needs "$needs_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,ledger:$ledger,size_bytes:$size,threshold_bytes:$threshold,needs_rotate:$needs}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["re-verify","ledger-rotate"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["re-verify","ledger-rotate"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation:
  #   --row-json=<JSON>      validate one ledger row's required fields
  #   --task-id=<ID>         check ledger for verification of a task_id
  #   --config               validate env values
  local subject="" row_json="" task_id_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --task-id=*) task_id_arg="${1#--task-id=}"; subject="task-id"; shift ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    row)
      [[ -z "$row_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required"}'; return 64; }
      local required='["ts","task_id","session","pane","verified"]'
      local missing valid
      missing="$(echo "$row_json" | jq -c --argjson req "$required" --argjson r "$row_json" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      if echo "$row_json" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" --argjson r "$row_json" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $valid and ($missing | length == 0) then "pass" else "fail" end),valid:$valid,missing_fields:$missing,row:$r}'
      ;;
    task-id)
      [[ -z "$task_id_arg" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--task-id=ID required"}'; return 64; }
      local ledger
      ledger="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
      [[ -f "$ledger" ]] || { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"task-id",status:"warn",reason:"ledger absent"}'; return 0; }
      set +e
      local row
      row="$(grep -F "\"task_id\":\"$task_id_arg\"" "$ledger" 2>/dev/null | tail -1)"
      set -e
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$task_id_arg" \
          '{schema_version:$sv,command:"validate",subject:"task-id",task_id:$id,status:"fail",reason:"task_id not found in ledger"}'
      else
        local verified
        verified="$(echo "$row" | jq -r '.verified // false')"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$task_id_arg" --argjson row "$row" --arg verified "$verified" \
          '{schema_version:$sv,command:"validate",subject:"task-id",task_id:$id,status:(if $verified == "true" then "pass" else "fail" end),verified:($verified == "true"),row:$row}'
      fi
      ;;
    config)
      local ntm_bin ledger ntm_valid=false ledger_valid=false
      ntm_bin="${DISPATCH_DELIVERY_VERIFY_NTM:-/Users/josh/.local/bin/ntm}"
      ledger="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
      [[ -x "$ntm_bin" ]] && ntm_valid=true
      [[ -d "$(dirname "$ledger")" ]] && ledger_valid=true
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg ntm "$ntm_bin" --argjson ntm_valid "$ntm_valid" \
        --arg ledger "$ledger" --argjson ledger_valid "$ledger_valid" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if $ntm_valid and $ledger_valid then "pass" else "fail" end),
          ntm_bin:{value:$ntm,valid:$ntm_valid},
          ledger:{value:$ledger,valid:$ledger_valid}}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","task-id","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail the ledger.
  local ledger="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$ledger" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:0,status:"warn",reason:"ledger absent",rows:[]}'
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
    printf 'ERR: why requires <task_id> argument\n' >&2; return 64
  fi
  # Look up task_id in ledger; emit verification provenance.
  local ledger="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
  if [[ ! -f "$ledger" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"warn",reason:"ledger absent"}'
    return 0
  fi
  set +e
  local row
  row="$(grep -F "\"task_id\":\"$id\"" "$ledger" 2>/dev/null | tail -1)"
  set -e
  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_in_ledger",reason:"task_id not found in delivery-verify ledger"}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      provenance:{ts:$row.ts,session:$row.session,pane:$row.pane,verified:$row.verified,reason:$row.reason,matched_at_line:$row.matched_at_line},
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
VERSION="dispatch-delivery-verify/v1"
NTM="${DISPATCH_DELIVERY_VERIFY_NTM:-/Users/josh/.local/bin/ntm}"
LEDGER="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
FUCKUP_LOG="${DISPATCH_DELIVERY_VERIFY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
SESSION=""; PANE=""; TASK_ID=""; TIMEOUT_SEC=10; JSON_OUT=0

usage(){ printf '%s\n' \
  'Usage: dispatch-delivery-verify.sh --session NAME --pane N --task-id ID [--timeout-sec 10] [--json]' \
  'Verifies L91 delivery via ntm history + ntm activity; no scrollback capture.'; }
examples(){ printf '%s\n' 'dispatch-delivery-verify.sh --session flywheel --pane 2 --task-id ntm-wire-in-123 --json'; }
now_iso(){ date -u +%Y-%m-%dT%H:%M:%SZ; }
tail_text(){ printf '%s' "$1" | tail -c 2000; }

info(){
  jq -nc --arg schema "$VERSION" --arg ntm "$NTM" --arg ledger "$LEDGER" \
    '{schema_version:$schema,command:"dispatch-delivery-verify.sh",ntm:$ntm,ledger:$ledger,native_surfaces:["ntm changes --json","ntm conflicts --json","ntm history --json","ntm activity --json"],output_schema:".flywheel/validation-schema/v1/dispatch-delivery-verify.schema.json",exit_codes:{"0":"verified","1":"not verified / fail closed","2":"usage"}}'
}

append_jsonl(){ local path="$1" row="$2"; mkdir -p "$(dirname "$path")"; jq -e -c . <<<"$row" >>"$path"; }

log_fuckup_row(){
  local reason="$1" stderr="$2" row
  row="$(jq -nc --arg ts "$(now_iso)" --arg session "$SESSION" --argjson pane "$PANE" --arg task_id "$TASK_ID" --arg reason "$reason" --arg stderr "$stderr" \
    '{ts:$ts,trauma_class:"dispatch-delivery-verify-native-probe-failed",class:"dispatch-delivery-verify-native-probe-failed",severity:"high",session:$session,pane:$pane,task_id:$task_id,reason:$reason,what_happened:"dispatch delivery verification failed closed before native prompt visibility proof",stderr:$stderr}')"
  append_jsonl "$FUCKUP_LOG" "$row" 2>/dev/null || true
}

history_probe(){
  local out rc
  set +e; out="$("$NTM" history --session "$SESSION" --search "$TASK_ID" --json --limit 20 2>&1)"; rc=$?; set -e
  if [[ "$rc" -ne 0 ]]; then jq -nc --arg stderr "$out" --argjson rc "$rc" '{ok:false,reason:"history_failed",stderr:$stderr,ntm_rc:$rc}'; return; fi
  jq -c --arg task "$TASK_ID" --arg pane "$PANE" '
    def entries: if type=="array" then . elif (.entries? | type)=="array" then .entries else [] end;
    def body: .prompt // .text // .message // .body // "";
    def target_hit: ((.targets // .target_panes // [] | map(tostring) | index($pane)) != null) or ((.pane // null | tostring) == $pane);
    [entries[] | select((body | contains($task)))] as $hits
    | ($hits[0] // null) as $hit
    | if $hit == null then {ok:true,found:false,target_hit:false,transport_accepted:false,prompt:"",matched_at_line:null}
      else {ok:true,found:true,target_hit:($hit|target_hit),transport_accepted:(if ($hit|has("success")) then ($hit.success == true) else true end),prompt:($hit|body),matched_at_line:1} end
  ' <<<"$out" 2>/dev/null || jq -nc '{ok:false,reason:"history_parse_failed",stderr:"invalid history json",ntm_rc:0}'
}

activity_probe(){
  local out rc
  set +e; out="$("$NTM" activity "$SESSION" --pane "$PANE" --json 2>&1)"; rc=$?; set -e
  if [[ "$rc" -ne 0 ]]; then jq -nc --arg stderr "$out" --argjson rc "$rc" '{ok:false,reason:"activity_failed",stderr:$stderr,ntm_rc:$rc,state:"UNKNOWN",work_started:false}'; return; fi
  jq -c --arg pane "$PANE" '
    def agents: if (.agents? | type)=="array" then .agents elif type=="array" then . else [] end;
    [agents[] | select(((.pane // .pane_idx // .id // "") | tostring) == $pane)] as $hits
    | ($hits[0] // null) as $hit
    | ($hit.state // $hit.status // "UNKNOWN" | tostring | ascii_upcase) as $state
    | {ok:($hit != null),reason:(if $hit == null then "pane_not_found" else null end),stderr:null,ntm_rc:0,state:$state,work_started:($state | test("THINKING|GENERATING|RUNNING|WORKING"))}
  ' <<<"$out" 2>/dev/null || jq -nc '{ok:false,reason:"activity_parse_failed",stderr:"invalid activity json",ntm_rc:0,state:"UNKNOWN",work_started:false}'
}

changes_probe(){ "$NTM" changes "$SESSION" --json 2>/dev/null || printf 'null\n'; }
conflicts_probe(){ "$NTM" conflicts "$SESSION" --json --limit 50 2>/dev/null || printf 'null\n'; }

build_row(){
  local verified="$1" reason="$2" matched="$3" text="$4" attempts="$5" ntm_rc="$6" stderr="$7"
  local changes conflicts
  changes="$(changes_probe)"
  conflicts="$(conflicts_probe)"
  jq -nc --arg schema "$VERSION" --arg ts "$(now_iso)" --arg session "$SESSION" --arg task_id "$TASK_ID" --argjson pane "$PANE" \
    --argjson verified "$verified" --argjson matched_at_line "$matched" --argjson buffer_len "${#text}" --arg reason "$reason" \
    --arg buffer_tail "$(tail_text "$text")" --argjson timeout_sec "$TIMEOUT_SEC" --argjson attempts "$attempts" --argjson ntm_rc "$ntm_rc" --arg stderr "$stderr" \
    --argjson changes "$changes" --argjson conflicts "$conflicts" \
    '{schema_version:$schema,ts:$ts,session:$session,pane:$pane,task_id:$task_id,verified:$verified,matched_at_line:$matched_at_line,buffer_len:$buffer_len,reason:(if $reason=="" then null else $reason end),buffer_tail:(if $buffer_tail=="" then null else $buffer_tail end),timeout_sec:$timeout_sec,attempts:$attempts,ntm_rc:$ntm_rc,stderr:(if $stderr=="" then null else $stderr end),ntm_changes:$changes,ntm_conflicts:$conflicts}'
}

emit(){ [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$1" || jq -r '"verified=\(.verified) task_id=\(.task_id) session=\(.session) pane=\(.pane) reason=\(.reason // "none") matched_at_line=\(.matched_at_line // "none")"' <<<"$1"; }

verify(){
  local deadline attempts h a reason row prompt matched ntm_rc stderr
  deadline=$((SECONDS + TIMEOUT_SEC)); attempts=0
  while :; do
    attempts=$((attempts + 1)); h="$(history_probe)"; a="$(activity_probe)"
    if [[ "$(jq -r '.ok' <<<"$h")" != "true" ]]; then reason="$(jq -r '.reason' <<<"$h")"; ntm_rc="$(jq -r '.ntm_rc // 0' <<<"$h")"; stderr="$(jq -r '.stderr // ""' <<<"$h")"; row="$(build_row false "$reason" null "" "$attempts" "$ntm_rc" "$stderr")"; append_jsonl "$LEDGER" "$row"; log_fuckup_row "$reason" "$stderr"; emit "$row"; return 1; fi
    if [[ "$(jq -r '.ok' <<<"$a")" != "true" ]]; then reason="$(jq -r '.reason' <<<"$a")"; ntm_rc="$(jq -r '.ntm_rc // 0' <<<"$a")"; stderr="$(jq -r '.stderr // ""' <<<"$a")"; row="$(build_row false "$reason" null "$(jq -r '.prompt // ""' <<<"$h")" "$attempts" "$ntm_rc" "$stderr")"; append_jsonl "$LEDGER" "$row"; log_fuckup_row "$reason" "$stderr"; emit "$row"; return 1; fi
    prompt="$(jq -r '.prompt // ""' <<<"$h")"; matched="$(jq -r '.matched_at_line // "null"' <<<"$h")"
    if [[ "$(jq -r '.found' <<<"$h")" != "true" ]]; then reason="task_id_not_observed"
    elif [[ "$(jq -r '.transport_accepted' <<<"$h")" != "true" ]]; then reason="transport_not_accepted"
    elif [[ "$(jq -r '.target_hit' <<<"$h")" != "true" ]]; then reason="prompt_not_targeted_to_pane"
    elif [[ "$(jq -r '.work_started' <<<"$a")" != "true" ]]; then reason="work_not_started"
    else row="$(build_row true "" "$matched" "$prompt" "$attempts" 0 "")"; append_jsonl "$LEDGER" "$row"; emit "$row"; return 0; fi
    if [[ "$SECONDS" -ge "$deadline" ]]; then row="$(build_row false "$reason" "$matched" "$prompt" "$attempts" 0 "")"; append_jsonl "$LEDGER" "$row"; emit "$row"; return 1; fi
    sleep 1
  done
  return 0
}

while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:-}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:-}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;;
  --task-id) TASK_ID="${2:-}"; shift 2;; --task-id=*) TASK_ID="${1#*=}"; shift;; --timeout-sec) TIMEOUT_SEC="${2:-}"; shift 2;; --timeout-sec=*) TIMEOUT_SEC="${1#*=}"; shift;;
  --ntm) NTM="${2:-}"; shift 2;; --ntm=*) NTM="${1#*=}"; shift;; --ledger) LEDGER="${2:-}"; shift 2;; --ledger=*) LEDGER="${1#*=}"; shift;; --json) JSON_OUT=1; shift;;
  --help|-h) usage; exit 0;; --examples) examples; exit 0;; --info) info; exit 0;; *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2;;
esac; done

[[ -n "$SESSION" && -n "$PANE" && -n "$TASK_ID" ]] || { usage >&2; exit 2; }
[[ "$PANE" =~ ^[0-9]+$ && "$TIMEOUT_SEC" =~ ^[0-9]+$ ]] || { echo "ERR: --pane and --timeout-sec must be integers" >&2; exit 2; }
verify
