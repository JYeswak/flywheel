#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-20-cross-orch-handoff.md and MP-04-receipt-callback-envelope.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
set -euo pipefail

# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by flywheel-vc3zs (P3 sub-bead from flywheel-wgitr).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-and-log/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-and-log-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-and-log.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate row, tail, or task-id contracts
  audit [--json]           recent run history
  why <id>                 explain dispatch-log provenance for a task id
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-and-log.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-and-log.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-and-log.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-and-log.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-and-log.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-dispatch-and-log}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"dispatch a task to a worker pane, build canonical packet via build-dispatch-packet.sh, run ntm preflight, ntm assign+send, verify ntm wait generating, append row to dispatch-log.jsonl, update bead status",
    inputs:{
      pane:{type:"integer",required:true,description:"target worker pane index"},
      task_file:{type:"path",required:true,description:"task body file (or generated dispatch packet path)"},
      task_id:{type:"string",required:true,description:"unique task correlation id"},
      bead:{type:"string",description:"optional beads-br ID; if present, packet is built + bead status moves to in_progress"},
      callback_by:{type:"string",description:"+10m duration or absolute ISO8601 deadline"},
      pipeline:{type:"string",description:"optional pipeline slug"},
      lane:{type:"string",description:"optional lane slug"},
      session:{type:"string",default:"flywheel"}
    },
    outputs:{
      dispatch_log_row:{path:"$REPO/.flywheel/dispatch-log.jsonl",fields:["ts","session","task_id","pane","task_file","channel","native_send","canonical_packet","bead","callback_expected_by"]},
      stdout_envelope:{fields:["ts","task_id","pane","ntm_sent","log_appended","bead_status","packet_path","native_send_success"]}
    },
    side_effects:["ntm preflight --strict","ntm assign","ntm send (delivers packet to pane)","ntm wait --until=generating","appends row to dispatch-log.jsonl","br update <bead> --status=in_progress (when --bead given)"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — dispatch a task to a worker pane. Builds canonical dispatch packet (when --bead given), runs ntm assign + ntm send, appends row to .flywheel/dispatch-log.jsonl, updates bead status to in_progress. Required: --pane=N --task-file=PATH --task-id=ID. Optional: --bead=<id>, --callback-by=<+duration|ISO>, --pipeline=<slug>, --lane=<slug>, --session=<name>.\n' ;;
    doctor)   printf 'topic: doctor — probes substrate this script depends on: ntm binary executable, build-dispatch-packet.sh executable, dispatch-log.jsonl writable, repo path resolvable, br binary on PATH for bead status updates. Each check returns status pass|fail with reason. Use --json for machine-readable output.\n' ;;
    health)   printf 'topic: health — summarizes the most recent dispatches from .flywheel/dispatch-log.jsonl: tail count of recent rows, success rate (rows where native_send.success=true), distinct sessions/panes touched, freshness (seconds since last dispatch). Use to detect dispatch-log staleness or send failures.\n' ;;
    repair)   printf 'topic: repair — repair scopes: dispatch-log (deduplicate by task_id keeping latest), bead-claim (re-attempt br update for a bead). --apply requires --idempotency-key. --dry-run is the default; emits planned actions without mutation.\n' ;;
    validate) printf 'topic: validate — validate a dispatch row against the canonical schema. Subjects: row (--row-json=JSON to validate one inline row), tail (--tail=N to validate last N rows), task-id (--task-id=ID to validate that ID is present). Reports per-row pass|fail and missing-field list.\n' ;;
    audit)    printf 'topic: audit — tail recent rows from .flywheel/dispatch-log.jsonl. --tail=N (default 10) limits output. Each row is the canonical dispatch row written at run time.\n' ;;
    why)      printf 'topic: why <id> — explains why a given task_id IS or ISN'\''T in the dispatch log. Looks up <id> in dispatch-log.jsonl. Returns the row + provenance (session, pane, bead, ts) if found, or status=not_found if absent.\n' ;;
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
            && cli_emit_completion_bash "dispatch-and-log" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-and-log" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface implementation ----------

scaffold_cmd_doctor() {
  # Probe substrate this script depends on. Returns per-check status array.
  local ts script_dir ntm_bin packet_bin log_path repo_root
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  ntm_bin="${FLYWHEEL_NTM_BIN:-${NTM:-/Users/josh/.local/bin/ntm}}"
  packet_bin="${BUILD_DISPATCH_PACKET:-$script_dir/build-dispatch-packet.sh}"
  log_path="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
  repo_root="${FLYWHEEL_REPO:-$(cd "$script_dir/../.." 2>/dev/null && pwd -P)}"

  local ntm_status="fail" ntm_reason=""
  if [[ -x "$ntm_bin" ]]; then ntm_status="pass"
  elif [[ -e "$ntm_bin" ]]; then ntm_reason="exists but not executable: $ntm_bin"
  else ntm_reason="not found: $ntm_bin"; fi

  local packet_status="fail" packet_reason=""
  if [[ -x "$packet_bin" ]]; then packet_status="pass"
  else packet_reason="not found or not executable: $packet_bin"; fi

  local log_status="fail" log_reason=""
  if [[ -f "$log_path" && -w "$log_path" ]]; then log_status="pass"
  elif [[ -f "$log_path" ]]; then log_reason="exists but not writable: $log_path"
  elif [[ -w "$(dirname "$log_path")" ]]; then log_status="pass"; log_reason="path absent but parent writable"
  else log_reason="not writable: $log_path"; fi

  local repo_status="fail" repo_reason=""
  if [[ -d "$repo_root/.flywheel" ]]; then repo_status="pass"
  else repo_reason="$repo_root is not a flywheel repo (no .flywheel/)"; fi

  local br_status="fail" br_reason=""
  if command -v br >/dev/null 2>&1; then br_status="pass"
  else br_reason="br not on PATH"; fi

  local overall="pass"
  for s in "$ntm_status" "$packet_status" "$log_status" "$repo_status" "$br_status"; do
    [[ "$s" == "fail" ]] && overall="fail"
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg ntm_bin "$ntm_bin" --arg ntm_status "$ntm_status" --arg ntm_reason "$ntm_reason" \
    --arg packet_bin "$packet_bin" --arg packet_status "$packet_status" --arg packet_reason "$packet_reason" \
    --arg log_path "$log_path" --arg log_status "$log_status" --arg log_reason "$log_reason" \
    --arg repo_root "$repo_root" --arg repo_status "$repo_status" --arg repo_reason "$repo_reason" \
    --arg br_status "$br_status" --arg br_reason "$br_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"ntm_binary_executable",status:$ntm_status,path:$ntm_bin,reason:$ntm_reason},
      {name:"build_dispatch_packet_executable",status:$packet_status,path:$packet_bin,reason:$packet_reason},
      {name:"dispatch_log_writable",status:$log_status,path:$log_path,reason:$log_reason},
      {name:"flywheel_repo_resolvable",status:$repo_status,path:$repo_root,reason:$repo_reason},
      {name:"br_on_path",status:$br_status,reason:$br_reason}
    ]}'
}

scaffold_cmd_health() {
  # Summarize last-run state from dispatch-log.jsonl: recent send success rate,
  # freshness, distinct panes/sessions touched.
  local ts log_path tail_count=20 tail_lines total sent_ok last_ts age_seconds distinct_sessions distinct_panes
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_path="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"

  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log_path" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"dispatch-log absent",log_path:$log,recent_count:0}'
    return 0
  fi

  tail_lines="$(tail -n "$tail_count" "$log_path" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || echo 0)"
  sent_ok="$(printf '%s\n' "$tail_lines" | jq -r 'select(.native_send.success == true) | .task_id' 2>/dev/null | wc -l | tr -d ' ')"
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"

  if [[ -n "$last_ts" ]]; then
    local now_epoch last_epoch
    now_epoch="$(date -u +%s)"
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo "$now_epoch")"
    age_seconds=$((now_epoch - last_epoch))
  else
    age_seconds=null
  fi

  distinct_sessions="$(printf '%s\n' "$tail_lines" | jq -r '.session // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  distinct_panes="$(printf '%s\n' "$tail_lines" | jq -r '.pane // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"

  local status="pass" reason=""
  if [[ "$total" -eq 0 ]]; then
    status="warn"; reason="empty tail"
  elif [[ "$sent_ok" -lt "$total" ]]; then
    local fail=$((total - sent_ok))
    status="warn"; reason="$fail of $total recent rows have native_send.success != true"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$log_path" \
    --argjson total "$total" --argjson sent_ok "$sent_ok" \
    --arg last_ts "$last_ts" \
    --argjson age "${age_seconds:-null}" \
    --arg sessions "$distinct_sessions" --arg panes "$distinct_panes" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      log_path:$log,recent_count:$total,recent_send_success:$sent_ok,
      last_dispatch_ts:(if $last_ts == "" then null else $last_ts end),
      last_dispatch_age_seconds:$age,
      recent_sessions:($sessions | split(",") | map(select(length > 0))),
      recent_panes:($panes | split(",") | map(select(length > 0)) | map(tonumber? // .))}'
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
  # Per-scope repair actions. Default scopes: dispatch-log (deduplicate
  # rows by task_id keeping latest), bead-claim (re-attempt br update for
  # the latest unclaimed bead in the log).
  local log_path planned
  log_path="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"

  case "$scope" in
    dispatch-log)
      # Dedupe rows in-place by task_id, keeping the LAST occurrence.
      if [[ ! -f "$log_path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"dispatch-log",scope:$scope,reason:"dispatch-log absent — nothing to dedupe"}'
        return 0
      fi
      local before after dups
      before="$(wc -l <"$log_path" | tr -d ' ')"
      # Plan via reverse-tail-uniq-by-task_id, then forward-restore order
      planned="$(tac "$log_path" 2>/dev/null | jq -c 'select(.task_id != null) | {task_id, ts}' | awk '!seen[$0]++' | wc -l | tr -d ' ')"
      after="$planned"
      dups=$((before - after))
      if [[ "$mode" == "apply" ]]; then
        local tmp
        tmp="$(mktemp)"
        # Collect last occurrence per task_id, preserving original order
        awk 'NR==FNR{
          if (match($0, /"task_id":"([^"]+)"/, m)) keep[m[1]] = NR
          next
        }
        FNR <= NR {
          if (match($0, /"task_id":"([^"]+)"/, m)) {
            if (keep[m[1]] == FNR) print
          } else {
            print
          }
        }' "$log_path" "$log_path" > "$tmp"
        mv "$tmp" "$log_path"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --argjson before "$before" --argjson after "$after" --argjson dups "$dups" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,
            before_lines:$before,after_lines:$after,duplicates_removed:$dups,note:"deduplicated dispatch-log by task_id (kept latest)"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --argjson before "$before" --argjson after "$after" --argjson dups "$dups" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,
            before_lines:$before,after_lines:$after,duplicates_to_remove:$dups,note:"dry-run: pass --apply --idempotency-key KEY to dedupe"}'
      fi
      ;;
    bead-claim)
      # Re-attempt br update for any in-log bead that's not yet in_progress.
      # Read-only by default; --apply runs br update.
      if ! command -v br >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          '{schema_version:$sv,command:"repair",status:"fail",mode:$mode_,scope:$scope,reason:"br not on PATH"}' \
          --arg mode_ "$mode"
        return 0
      fi
      local recent_beads
      recent_beads="$(tail -n 50 "$log_path" 2>/dev/null | jq -r '.bead // empty' | sort -u | grep -v '^$' || true)"
      if [[ "$mode" == "apply" ]]; then
        local fixed=0 attempts=0
        for bid in $recent_beads; do
          attempts=$((attempts + 1))
          br update "$bid" --status=in_progress >/dev/null 2>&1 && fixed=$((fixed + 1)) || true
        done
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --argjson attempts "$attempts" --argjson fixed "$fixed" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,attempts:$attempts,beads_re_claimed:$fixed}'
      else
        local count
        count="$(echo "$recent_beads" | grep -c . || echo 0)"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --argjson count "$count" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,beads_to_re_claim:$count,note:"dry-run: pass --apply --idempotency-key KEY to re-attempt br update"}'
      fi
      ;;
    ""|none)
      # Canonical envelope shape: emit even when no scope chosen so callers
      # exercising the surface get the structured response.
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["dispatch-log","bead-claim"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["dispatch-log","bead-claim"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation against the canonical dispatch row schema.
  # Subjects: row (--row-json=JSON), tail (--tail=N), task-id (--task-id=ID).
  local subject="" row_json="" tail_n="10" task_id_arg="" log_path
  log_path="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --tail=*) tail_n="${1#--tail=}"; subject="tail"; shift ;;
      --task-id=*) task_id_arg="${1#--task-id=}"; subject="task-id"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  # The canonical required fields a dispatch row MUST carry (per the run path
  # at the bottom of this script that emits ROW).
  local required='["ts","session","task_id","pane","task_file","channel","native_send","canonical_packet"]'

  validate_one_row() {
    local r="$1"
    local missing
    missing="$(echo "$r" | jq -c --argjson req "$required" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' --argjson r "$r" 2>/dev/null || echo "[]")"
    local valid
    valid="$(echo "$r" | jq -e '. | type == "object"' >/dev/null 2>&1 && echo true || echo false)"
    jq -nc --argjson valid "$valid" --argjson missing "$missing" --argjson r "$r" \
      '{valid:($valid and ($missing | length == 0)),missing_fields:$missing,row:$r}'
  }

  case "$subject" in
    row)
      [[ -z "$row_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required for subject=row"}'; return 64; }
      local result
      result="$(validate_one_row "$row_json")"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson r "$result" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $r.valid then "pass" else "fail" end),result:$r}'
      ;;
    tail)
      [[ -f "$log_path" ]] || { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$log_path" '{schema_version:$sv,command:"validate",subject:"tail",status:"warn",reason:"dispatch-log absent",log_path:$log}'; return 0; }
      local total=0 valid_count=0 results="[]"
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        total=$((total + 1))
        local result
        result="$(validate_one_row "$line")"
        if echo "$result" | jq -e '.valid' >/dev/null 2>&1; then
          valid_count=$((valid_count + 1))
        fi
        results="$(echo "$results" | jq -c --argjson r "$result" '. + [$r]')"
      done < <(tail -n "$tail_n" "$log_path")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson tail_n "$tail_n" \
        --argjson total "$total" --argjson valid "$valid_count" --argjson results "$results" \
        '{schema_version:$sv,command:"validate",subject:"tail",tail_n:$tail_n,
          total_rows:$total,valid_rows:$valid,
          status:(if $total == 0 then "warn" elif $valid == $total then "pass" else "fail" end),
          per_row:$results}'
      ;;
    task-id)
      [[ -z "$task_id_arg" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--task-id=ID required for subject=task-id"}'; return 64; }
      [[ -f "$log_path" ]] || { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"task-id",status:"warn",reason:"dispatch-log absent"}'; return 0; }
      local row
      row="$(grep -F "\"task_id\":\"$task_id_arg\"" "$log_path" 2>/dev/null | tail -1 || true)"
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$task_id_arg" \
          '{schema_version:$sv,command:"validate",subject:"task-id",task_id:$id,status:"fail",reason:"task_id not found in dispatch-log"}'
      else
        local result
        result="$(validate_one_row "$row")"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$task_id_arg" --argjson r "$result" \
          '{schema_version:$sv,command:"validate",subject:"task-id",task_id:$id,status:(if $r.valid then "pass" else "fail" end),result:$r}'
      fi
      ;;
    "")
      # Canonical envelope shape: emit even when no subject chosen so callers
      # exercising the surface get a structured response.
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","tail","task-id"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail dispatch-log.jsonl rows. Default tail=10. --tail=N overrides.
  local log_path="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
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
  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$log_path" \
      '{schema_version:$sv,command:"audit",audit_log:$log,status:"warn",reason:"dispatch-log absent",rows:[]}'
    return 0
  fi
  local rows
  rows="$(tail -n "$tail_n" "$log_path" | jq -sc '.' 2>/dev/null || echo '[]')"
  local count
  count="$(echo "$rows" | jq 'length')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$log_path" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # Look up <id> in dispatch-log.jsonl and emit provenance.
  local log_path="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"warn",reason:"dispatch-log absent"}'
    return 0
  fi
  local row
  row="$(grep -F "\"task_id\":\"$id\"" "$log_path" 2>/dev/null | tail -1 || true)"
  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",reason:"task_id not in dispatch-log"}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      provenance:{
        ts:$row.ts,
        session:$row.session,
        pane:$row.pane,
        bead:$row.bead,
        task_file:$row.task_file,
        canonical_packet_path:$row.packet_path,
        ntm_send_success:$row.native_send.success,
        callback_expected_by:$row.callback_expected_by
      },
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
  # shellcheck disable=SC2317
  exit $?
fi
# ====== END canonical-cli scaffold ======
SESSION="${SESSION:-flywheel}"
LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
NTM="${FLYWHEEL_NTM_BIN:-${NTM:-/Users/josh/.local/bin/ntm}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${FLYWHEEL_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
BUILD_DISPATCH_PACKET="${BUILD_DISPATCH_PACKET:-$SCRIPT_DIR/build-dispatch-packet.sh}"
PANE=""; TASK_FILE=""; TASK_ID=""; BEAD=""; CALLBACK_BY=""; PIPELINE=""; LANE=""; PREFLIGHT_OVERRIDE_REASON=""
MODE="${FLYWHEEL_DISPATCH_MODE:-manual}"
ORIGIN_TASK_ID="${FLYWHEEL_ORIGIN_TASK_ID:-}"
GOAL_ID="${FLYWHEEL_GOAL_ID:-}"
SPRINT_ID="${FLYWHEEL_SPRINT_ID:-}"
TICK_ID="${FLYWHEEL_TICK_ID:-}"
GOAL_CONTRACT="${FLYWHEEL_GOAL_CONTRACT:-}"
iso_from_epoch() {
  date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
    date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null
}
callback_expected_json() {
  local raw="$1" base_epoch="$2" amount unit seconds deadline
  if [[ -z "$raw" ]]; then
    jq -nc '{value:null,input:null,legacy_duration:null,parse_status:"empty"}'; return
  fi
  if [[ "$raw" =~ ^\+([0-9]+)(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours)$ ]]; then
    amount="${BASH_REMATCH[1]}"; unit="${BASH_REMATCH[2]}"
    case "$unit" in
      s|sec|secs|second|seconds) seconds="$amount" ;;
      m|min|mins|minute|minutes) seconds=$((amount * 60)) ;;
      h|hr|hrs|hour|hours) seconds=$((amount * 3600)) ;;
    esac
    if deadline="$(iso_from_epoch "$((base_epoch + seconds))")"; then
      jq -nc --arg value "$deadline" --arg input "$raw" '{value:$value,input:$input,legacy_duration:$input,parse_status:"duration"}'
    else
      jq -nc --arg input "$raw" '{value:null,input:$input,legacy_duration:$input,parse_status:"unknown"}'
    fi; return
  fi
  if [[ "$raw" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    jq -nc --arg value "$raw" '{value:$value,input:$value,legacy_duration:null,parse_status:"absolute"}'; return
  fi
  jq -nc --arg input "$raw" '{value:null,input:$input,legacy_duration:null,parse_status:"unknown"}'
}
json_attempt() {
  local label="$1"; shift
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [[ $rc -eq 0 ]] && jq -e . >/dev/null 2>&1 <<<"$out"; then
    jq -nc --arg label "$label" --argjson data "$(jq -c . <<<"$out")" '{command:$label,success:true,json:$data,raw:null,rc:0}'
  elif [[ $rc -eq 0 ]]; then
    jq -nc --arg label "$label" --arg raw "$out" '{command:$label,success:true,json:null,raw:$raw,rc:0}'
  else
    jq -nc --arg label "$label" --arg raw "$out" --argjson rc "$rc" '{command:$label,success:false,json:null,raw:$raw,rc:$rc}'
  fi
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pane=*) PANE="${1#*=}" ;;
    --task-file=*) TASK_FILE="${1#*=}" ;;
    --task-id=*) TASK_ID="${1#*=}" ;;
    --bead=*) BEAD="${1#*=}" ;;
    --callback-by=*) CALLBACK_BY="${1#*=}" ;;
    --pipeline=*) PIPELINE="${1#*=}" ;;
    --lane=*) LANE="${1#*=}" ;;
    --mode) MODE="${2:-}"; shift ;;
    --mode=*) MODE="${1#*=}" ;;
    --origin-task-id) ORIGIN_TASK_ID="${2:-}"; shift ;;
    --origin-task-id=*) ORIGIN_TASK_ID="${1#*=}" ;;
    --goal-id) GOAL_ID="${2:-}"; shift ;;
    --goal-id=*) GOAL_ID="${1#*=}" ;;
    --sprint-id) SPRINT_ID="${2:-}"; shift ;;
    --sprint-id=*) SPRINT_ID="${1#*=}" ;;
    --tick-id) TICK_ID="${2:-}"; shift ;;
    --tick-id=*) TICK_ID="${1#*=}" ;;
    --goal-contract) GOAL_CONTRACT="${2:-}"; shift ;;
    --goal-contract=*) GOAL_CONTRACT="${1#*=}" ;;
    --session=*) SESSION="${1#*=}" ;;
    --preflight-override=*) PREFLIGHT_OVERRIDE_REASON="${1#*=}" ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac; shift
done
if [[ -z "$PANE" || -z "$TASK_FILE" || -z "$TASK_ID" ]]; then
  echo "required: --pane=N --task-file=PATH --task-id=ID" >&2
  exit 2
fi
[[ -f "$TASK_FILE" ]] || { echo "task file does not exist: $TASK_FILE" >&2; exit 3; }
case "$MODE" in
  loop|goal|manual|watcher|unknown) ;;
  *) echo "invalid --mode=$MODE (expected loop|goal|manual|watcher|unknown)" >&2; exit 2 ;;
esac
[[ -n "$ORIGIN_TASK_ID" ]] || ORIGIN_TASK_ID="$TASK_ID"
if [[ "$MODE" == "loop" && -z "$TICK_ID" ]]; then TICK_ID="$ORIGIN_TASK_ID"; fi
TS_EPOCH="${FLYWHEEL_DISPATCH_AND_LOG_NOW_EPOCH:-$(date -u +%s)}"
TS="$(iso_from_epoch "$TS_EPOCH")" || { echo "could not compute dispatch timestamp" >&2; exit 5; }
CALLBACK_EXPECTED="$(callback_expected_json "$CALLBACK_BY" "$TS_EPOCH")"
ntm_preflight_attempt() {
  local file="$1" override_reason="${2:-}" raw rc parsed error_count warning_count status allowed
  set +e
  raw="$("$NTM" preflight --strict --json "$(cat "$file")" 2>&1)"
  rc=$?
  set -e

  parsed="null"
  error_count=0
  warning_count=0
  if jq -e . >/dev/null 2>&1 <<<"$raw"; then
    parsed="$(jq -c . <<<"$raw")"
    error_count="$(jq -r '(.error_count // ([.findings[]? | select((.severity // .level // "") == "error")] | length) // 0) | tonumber? // 0' <<<"$parsed")"
    warning_count="$(jq -r '(.warning_count // ([.findings[]? | select((.severity // .level // "") == "warning")] | length) // 0) | tonumber? // 0' <<<"$parsed")"
    if [[ -n "$override_reason" ]]; then
      status="override"
      allowed=true
    elif [[ "$rc" -ne 0 || "$error_count" -gt 0 ]]; then
      status="blocked"
      allowed=false
    else
      status="clean"
      allowed=true
    fi
  else
    status="skipped"
    allowed=true
  fi

  jq -nc \
    --arg command "ntm preflight" \
    --arg raw "$raw" \
    --argjson rc "$rc" \
    --argjson json "$parsed" \
    --arg status "$status" \
    --argjson allowed "$allowed" \
    --argjson error_count "$error_count" \
    --argjson warning_count "$warning_count" \
    --arg override_reason "$override_reason" \
    '{
      command:$command,
      rc:$rc,
      json:$json,
      raw:(if $json == null then $raw else null end),
      status:$status,
      dispatch_allowed:$allowed,
      error_count:$error_count,
      warning_count:$warning_count,
      override_reason:(if $override_reason == "" then null else $override_reason end)
    }'
}

wait_generating_ok() {
  jq -e '
    .success == true
    and (
      (.json | type) != "object"
      or (((.json.status // .json.result // "ok") | ascii_downcase)
        | test("^(generating|thinking|working|running|healthy|ok|pass|ready)$"))
    )
  ' >/dev/null
}

SEND_FILE="$TASK_FILE"
PACKET_JSON="$(jq -nc '{status:"not_applicable",packet_path:null,packet_sha256:null,validation_status:null}')"
if [[ -n "$BEAD" ]]; then
  PACKET_ARGS=(--bead-id "$BEAD" --target-pane "$PANE" --target-session "$SESSION" --task-id "$TASK_ID" --apply --json)
  [[ -z "$GOAL_CONTRACT" ]] || PACKET_ARGS+=(--goal-contract "$GOAL_CONTRACT")
  PACKET_OUT="$("$BUILD_DISPATCH_PACKET" "${PACKET_ARGS[@]}" 2>&1)"
  PACKET_RC=$?
  [[ $PACKET_RC -eq 0 ]] || { echo "build-dispatch-packet failed (rc=$PACKET_RC): $PACKET_OUT" >&2; exit 6; }
  jq -e '.validation_status == "pass" and (.packet_path | type == "string")' >/dev/null 2>&1 <<<"$PACKET_OUT" ||
    { echo "build-dispatch-packet returned invalid packet json: $PACKET_OUT" >&2; exit 7; }
  PACKET_JSON="$(jq -c . <<<"$PACKET_OUT")"
  SEND_FILE="$(jq -r '.packet_path' <<<"$PACKET_JSON")"
fi
PREFLIGHT_JSON="$(ntm_preflight_attempt "$SEND_FILE" "$PREFLIGHT_OVERRIDE_REASON")"
if ! jq -e '.dispatch_allowed == true' >/dev/null <<<"$PREFLIGHT_JSON"; then
  echo "ntm preflight blocked dispatch: errors=$(jq -r '.error_count' <<<"$PREFLIGHT_JSON") warnings=$(jq -r '.warning_count' <<<"$PREFLIGHT_JSON")" >&2
  jq -c '.json.findings // []' <<<"$PREFLIGHT_JSON" >&2 || true
  exit 8
fi
if [[ -n "$BEAD" ]]; then
  ASSIGN_JSON="$(json_attempt "ntm assign" "$NTM" assign "$SESSION" --repo "$REPO" --pane="$PANE" --beads="$BEAD" --prompt="$TASK_ID" --dry-run --json)"
else
  ASSIGN_JSON="$(json_attempt "ntm assign" "$NTM" assign "$SESSION" --repo "$REPO" --dry-run --limit=1 --json)"
fi
SEND_JSON="$(json_attempt "ntm send" "$NTM" send "$SESSION" --pane="$PANE" --no-cass-check --file="$SEND_FILE" --json)"
if ! jq -e '.success == true' >/dev/null <<<"$SEND_JSON"; then
  echo "ntm send failed: $(jq -r '.raw' <<<"$SEND_JSON")" >&2
  exit 4
fi
WAIT_GENERATING_JSON="$(json_attempt "ntm wait generating" "$NTM" wait "$SESSION" --pane="$PANE" --until=generating --timeout="${FLYWHEEL_DISPATCH_WAIT_GENERATING_TIMEOUT:-15s}" --json)"
DISPATCH_STATUS="generating_verified"
if ! wait_generating_ok <<<"$WAIT_GENERATING_JSON"; then
  DISPATCH_STATUS="generating_wait_failed"
fi
HISTORY_JSON="$(json_attempt "ntm history" "$NTM" history --session="$SESSION" --search="$TASK_ID" --limit=5 --json)"
HISTORY_COUNT="$(jq -r 'if .success and (.json|type) == "array" then (.json|length) elif .success then 1 else 0 end' <<<"$HISTORY_JSON")"
ROW="$(jq -nc \
  --arg ts "$TS" --arg session "$SESSION" --arg task_id "$TASK_ID" --arg pane "$PANE" \
  --arg task_file "$TASK_FILE" --arg bead "$BEAD" --arg pipeline "$PIPELINE" --arg lane "$LANE" \
  --arg mode "$MODE" --arg origin_task_id "$ORIGIN_TASK_ID" --arg goal_id "$GOAL_ID" --arg sprint_id "$SPRINT_ID" --arg tick_id "$TICK_ID" \
  --arg dispatch_status "$DISPATCH_STATUS" \
  --argjson callback "$CALLBACK_EXPECTED" --argjson packet "$PACKET_JSON" \
  --argjson preflight "$PREFLIGHT_JSON" --argjson assign "$ASSIGN_JSON" --argjson send "$SEND_JSON" --argjson wait_generating "$WAIT_GENERATING_JSON" --argjson history "$HISTORY_JSON" --argjson history_count "$HISTORY_COUNT" \
  '{ts:$ts,event:"dispatch_sent",session:$session,task_id:$task_id,pane:($pane|tonumber),task_file:$task_file,mode:$mode,origin_task_id:$origin_task_id,goal_id:(if $goal_id == "" then null else $goal_id end),sprint_id:(if $sprint_id == "" then null else $sprint_id end),tick_id:(if $tick_id == "" then null else $tick_id end),channel:"ntm",pane_state_source:"ntm_wait",pane_state:$dispatch_status,dispatch_status:$dispatch_status,native_preflight:$preflight,preflight_status:$preflight.status,preflight_errors:$preflight.error_count,preflight_warnings:$preflight.warning_count,native_assignment:$assign,native_send:$send,native_wait_generating:$wait_generating,wait_generating_success:($wait_generating.success == true),native_history:$history,history_entry_count:$history_count,canonical_packet:$packet,goal_contract:($packet.fields_resolved.goal_contract // null),packet_path:$packet.packet_path,packet_sha256:$packet.packet_sha256,packet_validation_status:$packet.validation_status,bead:(if $bead == "" then null else $bead end),callback_expected_by:$callback.value,callback_expected_by_input:$callback.input,callback_expected_by_legacy_duration:$callback.legacy_duration,callback_expected_by_parse_status:$callback.parse_status,pipeline_slug:(if $pipeline == "" then null else $pipeline end),lane:(if $lane == "" then null else $lane end)}')"
printf '%s\n' "$ROW" >>"$LOG"
if [[ "$DISPATCH_STATUS" != "generating_verified" ]]; then
  echo "ntm wait generating failed: $(jq -r '.raw // (.json | tostring)' <<<"$WAIT_GENERATING_JSON")" >&2
  exit 9
fi
BEAD_RESULT="skipped"
if [[ -n "$BEAD" ]]; then
  br update "$BEAD" --status=in_progress >/dev/null 2>&1 && BEAD_RESULT="in_progress" || BEAD_RESULT="claim_blocked"
fi
jq -nc \
  --arg ts "$TS" --arg task_id "$TASK_ID" --arg pane "$PANE" --arg bead_status "$BEAD_RESULT" \
  --argjson packet "$PACKET_JSON" --argjson preflight "$PREFLIGHT_JSON" --argjson assign "$ASSIGN_JSON" --argjson send "$SEND_JSON" --argjson wait_generating "$WAIT_GENERATING_JSON" \
  --argjson history "$HISTORY_JSON" --argjson history_count "$HISTORY_COUNT" \
  '{ts:$ts,task_id:$task_id,pane:($pane|tonumber),ntm_sent:($send.success == true),log_appended:true,bead_status:$bead_status,packet_path:$packet.packet_path,packet_validation_status:$packet.validation_status,preflight_status:$preflight.status,preflight_errors:$preflight.error_count,preflight_warnings:$preflight.warning_count,native_assign_success:($assign.success == true),native_send_success:($send.success == true),native_wait_generating_success:($wait_generating.success == true),native_history_success:($history.success == true),history_entry_count:$history_count}'
