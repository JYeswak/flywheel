#!/usr/bin/env bash
# dispatch-trigger-gated-precheck.sh
# Pre-check for trigger-gated beads. Consults the named watchtower BEFORE
# build-dispatch-packet.sh emits a packet, so a worker round-trip is not
# wasted probing the trigger only to return BLOCKED.
#
# A bead is trigger-gated when its body declares an external trigger via:
#   external_trigger_watchtower=<name>      (canonical, structured)
#
# Prose-only signals ("Operational trigger is ...", "Depends on ... release
# announcement") are detected as a WARNING that nags the bead author to add
# the structured field. They do not refuse dispatch.
#
# The pre-check runs the watchtower once and reads
#   .watchlists.<name>.status
# A status of `release_available`, `released`, `target_released`, or
# `newer_than_target` means the trigger has fired. Anything else
# (`public_no_release`, `not_found`, `hold_target_not_released`, `unknown`,
# missing) means the bead must wait.
#
# Doctrine: .flywheel/doctrine/trigger-gated-bead-precheck.md
# Sister: flywheel-g6xaw, flywheel-ubrb5 (watchtower author).
#
# CLI matrix per canonical-cli-scoping:
#   doctor / health / repair triad: doctor (operator view), health (single status), repair (--dry-run|--apply)
#   validate / audit / why subsidiary: validate (one bead), audit (jsonl), why (one bead, verbose)
#   schema / examples / info / completion: standard introspection

set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block was scaffolded by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-1fk5f.3 (no remaining
# scaffold stubs).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-trigger-gated-precheck/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-trigger-gated-precheck-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-trigger-gated-precheck.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-trigger-gated-precheck.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-trigger-gated-precheck.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-trigger-gated-precheck.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-trigger-gated-precheck.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-trigger-gated-precheck.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","checks"],
          checks_item:["name","status","reason"],
          status_enum:["pass","fail","warn"]}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","audit_log","recent_runs"],
          status_enum:["pass","warn","fail"]}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","mode","scope"],
          mode_enum:["dry_run","apply"],
          valid_scopes:["audit-log-rotate","audit-log-clear"],
          mutation_gates:["--apply requires --idempotency-key"]}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","subject"],
          valid_subjects:["row","schema","config"],
          status_enum:["pass","fail","warn","refused","info"]}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["audit_log","tail_n","count","rows"]}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["id","status"],
          status_enum:["found","not_found","unavailable"],
          provenance_fields:["ts","bead","watchtower","watchtower_status","reason_code"]}'
      ;;
    audit-row|run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["ts","command","schema_version"],
          optional:["bead","watchtower","watchtower_status","reason_code","status","trigger_gated"],
          purpose:"row shape written to SCAFFOLD_AUDIT_LOG by cmd_run terminal envelopes"}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          surfaces:["doctor","health","repair","validate","audit","why","audit-row","default"],
          purpose:"trigger-gated bead pre-check (canonical-cli substrate layer over per-bead validate/why/doctor/health/repair)",
          stable_exit_codes:{"0":"success","1":"general error","2":"bead lookup failed","3":"refused or watchtower probe failed","5":"watchtower output malformed","6":"trigger not yet fired","64":"bad args"}}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  # Single-printf bodies per gl7om SIGPIPE/pipefail discipline (`set -e -o pipefail`
  # plus head -N or piped readers can SIGPIPE the printf chain). One printf per topic.
  local topic="${1:-}"
  local _runs="${SCAFFOLD_AUDIT_LOG:-${HOME}/.local/state/flywheel/dispatch-trigger-gated-precheck-runs.jsonl}"
  case "$topic" in
    run)
      printf 'topic: run — default backward-compatible invocation routes to cmd_run (per-bead validate/why/doctor/health/repair). Pass --bead-id <id> or --bead-body-file <path> to engage the per-bead trigger-gating logic; the canonical scaffold surfaces are reserved for substrate-level operations (no --bead-id present).\n'
      ;;
    doctor)
      printf 'topic: doctor — substrate health probes (watchtower binary, br binary, helper-lib, audit-log writability, jq presence, repo resolvable). Per-bead doctor lives in cmd_run; pass --bead-id to reach it.\n'
      ;;
    health)
      printf 'topic: health — recent run summary from %s (recent_count, last_run_ts, age_seconds, status enum). Warn when ledger absent or stale (>24h).\n' "$_runs"
      ;;
    repair)
      printf 'topic: repair — read-only by default; mutate with --apply --idempotency-key KEY. Scopes: audit-log-rotate (rotate %s when >5MB) and audit-log-clear (truncate ledger for testing). Apply without --idempotency-key returns refused (rc 3).\n' "$_runs"
      ;;
    validate)
      printf 'topic: validate — per-subject contract checks. Subjects: row (--row-json=JSON validates an audit-log row schema), schema (--surface=NAME re-emits the schema), config (env presence: WATCHTOWER_BIN, BR_BIN, audit-log-writable).\n'
      ;;
    audit)
      printf 'topic: audit — tail %s (default --tail=10). Returns rows[] with ts, command, bead, watchtower, watchtower_status, reason_code.\n' "$_runs"
      ;;
    why)
      printf 'topic: why <id> — provenance lookup by task_id or bead in the audit log; emits ts/bead/watchtower/status/reason or status=not_found when absent.\n'
      ;;
    *)
      printf 'topics: run | doctor | health | repair | validate | audit | why\n'
      ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "dispatch-trigger-gated-precheck" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-trigger-gated-precheck" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 5+ named substrate probes — independent of any specific bead. The per-bead
  # doctor lives in cmd_run; the scaffold layer surfaces SUBSTRATE health.
  local ts script_dir watchtower_bin br_bin audit_log helper_lib repo_root
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  watchtower_bin="${WATCHTOWER_BIN:-$script_dir/jeff-binary-version-watchtower.sh}"
  br_bin="${BR_BIN:-br}"
  audit_log="$SCAFFOLD_AUDIT_LOG"
  helper_lib="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
  repo_root="${_SCAFFOLD_REPO_ROOT:-$(cd "$script_dir/../.." 2>/dev/null && pwd -P)}"

  local wt_status="fail" wt_reason=""
  if [[ -x "$watchtower_bin" ]]; then wt_status="pass"
  elif [[ -e "$watchtower_bin" ]]; then wt_reason="exists but not executable: $watchtower_bin"
  else wt_reason="not found: $watchtower_bin"; fi

  local br_status="fail" br_reason=""
  if command -v "$br_bin" >/dev/null 2>&1; then br_status="pass"
  else br_reason="not on PATH: $br_bin"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH (required for envelope construction)"; fi

  local helper_status="fail" helper_reason=""
  if [[ -r "$helper_lib" ]]; then helper_status="pass"
  else helper_reason="helper-lib not readable: $helper_lib"; fi

  local audit_status="fail" audit_reason=""
  if [[ -f "$audit_log" && -w "$audit_log" ]]; then audit_status="pass"
  elif [[ -d "$(dirname "$audit_log")" && -w "$(dirname "$audit_log")" ]]; then audit_status="pass"; audit_reason="path absent but parent writable"
  else audit_reason="not writable: $audit_log"; fi

  local repo_status="fail" repo_reason=""
  if [[ -d "$repo_root/.flywheel" ]]; then repo_status="pass"
  else repo_reason="$repo_root is not a flywheel repo (no .flywheel/)"; fi

  local overall="pass" s
  for s in "$wt_status" "$br_status" "$jq_status" "$helper_status" "$repo_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg wt_bin "$watchtower_bin" --arg wt_s "$wt_status" --arg wt_r "$wt_reason" \
    --arg br_bin "$br_bin" --arg br_s "$br_status" --arg br_r "$br_reason" \
    --arg jq_s "$jq_status" --arg jq_r "$jq_reason" \
    --arg helper_lib "$helper_lib" --arg helper_s "$helper_status" --arg helper_r "$helper_reason" \
    --arg audit_log "$audit_log" --arg audit_s "$audit_status" --arg audit_r "$audit_reason" \
    --arg repo "$repo_root" --arg repo_s "$repo_status" --arg repo_r "$repo_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"watchtower_binary_executable",status:$wt_s,path:$wt_bin,reason:$wt_r},
      {name:"br_binary_on_path",status:$br_s,path:$br_bin,reason:$br_r},
      {name:"jq_on_path",status:$jq_s,reason:$jq_r},
      {name:"helper_lib_readable",status:$helper_s,path:$helper_lib,reason:$helper_r},
      {name:"audit_log_writable",status:$audit_s,path:$audit_log,reason:$audit_r},
      {name:"flywheel_repo_resolvable",status:$repo_s,path:$repo,reason:$repo_r}
    ]}'
}

scaffold_cmd_health() {
  # Summarize recent run state from $SCAFFOLD_AUDIT_LOG (per-run ledger written
  # by cmd_run terminal envelopes via cli_audit_append). Reports recent_count,
  # last_run_ts, age_seconds, distinct beads/watchtowers. Status warn when
  # ledger absent or stale (>24h).
  local ts log_path tail_n=20 tail_lines total last_ts age_seconds distinct_beads distinct_watchtowers
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_path="$SCAFFOLD_AUDIT_LOG"

  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log_path" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"audit ledger absent (no historical runs yet)",audit_log:$log,recent_runs:0}'
    return 0
  fi

  tail_lines="$(tail -n "$tail_n" "$log_path" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || true)"
  if [[ -z "$total" ]]; then total=0; fi
  set +e
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  distinct_beads="$(printf '%s\n' "$tail_lines" | jq -r '.bead // .bead_id // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  distinct_watchtowers="$(printf '%s\n' "$tail_lines" | jq -r '.watchtower // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
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
    status="warn"; reason="empty tail"
  elif [[ "$age_seconds" != "null" && "$age_seconds" -gt 86400 ]]; then
    status="warn"; reason="last run >24h ago (stale)"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$log_path" \
    --argjson total "${total:-0}" \
    --arg last_ts "$last_ts" \
    --argjson age "${age_seconds:-null}" \
    --arg beads "$distinct_beads" --arg watchtowers "$distinct_watchtowers" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      audit_log:$log,recent_runs:$total,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      last_run_age_seconds:$age,
      recent_beads:($beads | split(",") | map(select(length > 0))),
      recent_watchtowers:($watchtowers | split(",") | map(select(length > 0)))}'
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
  # Per-scope repair actions. Scopes: audit-log-rotate (rotate ledger when
  # >5MB, append-only) and audit-log-clear (truncate for testing).
  local log_path
  log_path="$SCAFFOLD_AUDIT_LOG"
  case "$scope" in
    audit-log-rotate)
      if [[ ! -f "$log_path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg log "$log_path" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"dry_run",scope:$scope,reason:"audit ledger absent — nothing to rotate",log_path:$log}'
        return 0
      fi
      local size threshold=5242880 lines
      size="$(stat -f%z "$log_path" 2>/dev/null || stat -c%s "$log_path" 2>/dev/null || echo 0)"
      lines="$(wc -l <"$log_path" | tr -d ' ')"
      if [[ "$mode" == "apply" ]]; then
        if [[ "$size" -lt "$threshold" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
            --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
            '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,
              size_bytes:$size,threshold_bytes:$threshold,lines:$lines,note:"under threshold — no rotation needed"}'
        else
          local rotated="${log_path%.jsonl}.$(date -u +%Y%m%dT%H%M%SZ).jsonl"
          mv "$log_path" "$rotated"
          : > "$log_path"
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
            --arg rotated "$rotated" --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
            '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,
              rotated_to:$rotated,size_bytes:$size,threshold_bytes:$threshold,lines:$lines}'
        fi
      else
        local will_rotate="false"
        if [[ "$size" -ge "$threshold" ]]; then will_rotate="true"; fi
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
          --argjson will "$will_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,
            size_bytes:$size,threshold_bytes:$threshold,lines:$lines,will_rotate:$will,
            planned_actions:["rotate audit-log when --apply --idempotency-key KEY passed; mv to <log>.<UTC>.jsonl + truncate live log"]}'
      fi
      ;;
    audit-log-clear)
      # Testing helper — truncate ledger to zero rows.
      if [[ ! -f "$log_path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg log "$log_path" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"dry_run",scope:$scope,reason:"audit ledger absent — nothing to clear",log_path:$log}'
        return 0
      fi
      local clear_lines
      clear_lines="$(wc -l <"$log_path" | tr -d ' ')"
      if [[ "$mode" == "apply" ]]; then
        : > "$log_path"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --argjson cleared "$clear_lines" --arg log "$log_path" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,
            log_path:$log,rows_cleared:$cleared}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --argjson lines "$clear_lines" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,
            current_lines:$lines,
            planned_actions:["truncate audit-log to zero rows when --apply --idempotency-key KEY passed"]}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["audit-log-rotate","audit-log-clear"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit-log-rotate","audit-log-clear"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject contract checks. Subjects: row, schema, config.
  local subject="" row_json="" surface_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --row-json) row_json="${2:-}"; subject="row"; shift 2 ;;
      --surface=*) surface_arg="${1#--surface=}"; subject="schema"; shift ;;
      --surface) surface_arg="${2:-}"; subject="schema"; shift 2 ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    row)
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required for subject=row"}'
        return 64
      fi
      local required='["ts","command","schema_version"]'
      local valid missing
      set +e
      valid="$(printf '%s' "$row_json" | jq -e '. | type == "object"' >/dev/null 2>&1 && echo true || echo false)"
      missing="$(printf '%s' "$row_json" | jq -c --argjson req "$required" '[$req[] as $f | select(. as $f | (. | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      # The above filter is order-sensitive in jq; recompute via simpler form
      missing="$(printf '%s' "$row_json" | jq -c --argjson req "$required" '$req - keys' 2>/dev/null || echo "[]")"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" \
        '{schema_version:$sv,command:"validate",subject:"row",
          status:(if ($valid and ($missing | length == 0)) then "pass" else "fail" end),
          valid:$valid,missing_required:$missing}'
      ;;
    schema)
      if [[ -z "$surface_arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--surface=NAME required for subject=schema"}'
        return 64
      fi
      local schema_out
      schema_out="$(scaffold_emit_schema "$surface_arg")"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surf "$surface_arg" --argjson schema "$schema_out" \
        '{schema_version:$sv,command:"validate",subject:"schema",surface:$surf,status:"pass",schema:$schema}'
      ;;
    config)
      local watchtower_bin br_bin audit_log
      watchtower_bin="${WATCHTOWER_BIN:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/jeff-binary-version-watchtower.sh}"
      br_bin="${BR_BIN:-br}"
      audit_log="$SCAFFOLD_AUDIT_LOG"
      local missing=()
      [[ -x "$watchtower_bin" ]] || missing+=("watchtower_bin:$watchtower_bin")
      command -v "$br_bin" >/dev/null 2>&1 || missing+=("br_bin:$br_bin")
      [[ -d "$(dirname "$audit_log")" ]] || missing+=("audit_log_parent:$(dirname "$audit_log")")
      local missing_json
      if [[ ${#missing[@]} -eq 0 ]]; then
        missing_json='[]'
      else
        missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc .)"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg wt "$watchtower_bin" --arg br "$br_bin" --arg log "$audit_log" \
        --argjson missing "$missing_json" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if ($missing | length) == 0 then "pass" else "fail" end),
          watchtower_bin:$wt,br_bin:$br,audit_log:$log,missing:$missing}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","schema","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail SCAFFOLD_AUDIT_LOG via the helper-lib's cli_emit_audit_tail when
  # available (path-then-schema positional order per b9dfv contract).
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
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi
  # Fallback when helper-lib is not loaded.
  if [[ ! -f "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,status:"warn",reason:"audit ledger absent",rows:[],count:0}'
    return 0
  fi
  local rows count
  set +e
  rows="$(tail -n "$tail_n" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '.' 2>/dev/null)"
  set -e
  if [[ -z "$rows" ]]; then rows='[]'; fi
  count="$(echo "$rows" | jq 'length' 2>/dev/null || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # Provenance lookup: search SCAFFOLD_AUDIT_LOG for matching task_id|bead.
  # Returns found|not_found|unavailable per apply-spec contract.
  local log_path="$SCAFFOLD_AUDIT_LOG"
  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"audit ledger absent",audit_log:$log}'
    return 0
  fi
  local row
  row="$(grep -E "\"(task_id|bead|bead_id)\":\"$id\"" "$log_path" 2>/dev/null | tail -1 || true)"
  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",reason:"id not in audit ledger",audit_log:$log}'
    return 0
  fi
  if ! printf '%s' "$row" | jq -e . >/dev/null 2>&1; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg raw "$(printf '%s' "$row" | head -c 512)" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"matched row is not valid JSON",raw_preview:$raw}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      provenance:{
        ts:($row.ts // null),
        bead:($row.bead // $row.bead_id // null),
        watchtower:($row.watchtower // null),
        watchtower_status:($row.watchtower_status // null),
        reason_code:($row.reason_code // null),
        trigger_gated:($row.trigger_gated // null),
        precheck_status:($row.status // null)
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
#
# IMPORTANT: this surface's cmd_run already provides per-bead validate /
# why / doctor / health / repair (with --bead-id / --bead-body-file). The
# canonical scaffold layer operates at the SUBSTRATE level (audit-log
# tail, helper-lib + binary probes). When --bead-id or --bead-body-file
# is present in argv, defer to cmd_run so the per-bead path runs unchanged.
_scaffold_is_canonical_arg() {
  local a
  for a in "$@"; do
    case "$a" in
      --bead-id|--bead-body-file|--bead-id=*|--bead-body-file=*|--explain|--watchtower-fixture|--watchtower-bin|--watchtower-json-fixture|--br-bin)
        return 1 ;;
    esac
  done
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
VERSION="dispatch-trigger-gated-precheck.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WATCHTOWER_BIN="${WATCHTOWER_BIN:-$SCRIPT_DIR/jeff-binary-version-watchtower.sh}"
BR_BIN="${BR_BIN:-br}"

# Statuses that count as "trigger has fired" / release_available.
RELEASE_AVAILABLE_STATUSES=(release_available released target_released newer_than_target)

usage() {
  cat <<EOF
$VERSION - dispatch-time pre-check for trigger-gated beads

USAGE
  dispatch-trigger-gated-precheck.sh <command> [flags]

COMMANDS
  validate --bead-id <id>                  Probe one bead. Exit 0 ok, 6 trigger not yet fired.
  validate --bead-body-file <path>         Probe a bead-body file (no br lookup).
  why     --bead-id <id> [--json]          Verbose explain output.
  doctor  [--bead-id <id>] [--json]        Operator view; health summary plus row.
  health  [--bead-id <id>] [--json]        Single status: ok | trigger_not_yet_fired | not_trigger_gated.
  repair  --bead-id <id> --dry-run|--apply Suggest re-disposition (no auto-mutation).
  schema                                   JSON output schema.
  examples                                 Minimal example commands.
  info                                     Surface name and supported watchlists.
  completion                               Shell completion text.
  help                                     This message.

FLAGS
  --watchtower-fixture <path>          Use fixture for FRANKENTERM_RELEASE_FIXTURE.
  --watchtower-bin <path>              Override watchtower binary.
  --watchtower-json-fixture <path>     Inline pre-computed watchtower --json output.
  --br-bin <path>                      Override br binary.
  --json                               Emit JSON output (default for validate).
  --explain                            Equivalent to validate --json with verbose narrative.

EXIT CODES
  0  ok (not trigger-gated, OR trigger has fired)
  1  bad args / usage
  2  bead lookup failed
  3  watchtower probe failed
  5  watchtower output malformed
  6  trigger-gated bead, watchtower not yet at release_available
EOF
}

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

# --- introspection ---
info() { jq -nc --arg v "$VERSION" '{command:"dispatch-trigger-gated-precheck",version:$v,canonical_field:"external_trigger_watchtower",supported_watchlists:["frankenterm_release","codex_release"],release_available_statuses:["release_available","released","target_released","newer_than_target"]}'; }
examples() {
  cat <<EOF
EXAMPLES:
  dispatch-trigger-gated-precheck.sh validate --bead-id flywheel-g6xaw
  dispatch-trigger-gated-precheck.sh validate --bead-body-file /tmp/bead.txt --watchtower-json-fixture /tmp/watch.json
  dispatch-trigger-gated-precheck.sh why --bead-id flywheel-g6xaw --json
  dispatch-trigger-gated-precheck.sh doctor --json
EOF
}
schema() {
  cat <<'EOF'
{"title":"dispatch-trigger-gated-precheck output (--json)","type":"object","required":["schema_version","status","trigger_gated","reason_code"],"properties":{"schema_version":{"const":"dispatch-trigger-gated-precheck.v1"},"status":{"enum":["ok","trigger_not_yet_fired","not_trigger_gated","watchtower_unreachable","malformed"]},"trigger_gated":{"type":"boolean"},"watchtower":{"type":"string"},"watchtower_status":{"type":["string","null"]},"reason_code":{"type":"string"},"warnings":{"type":"array","items":{"type":"string"}},"prose_signals":{"type":"array","items":{"type":"string"}}}}
EOF
}
completion() { printf '%s\n' 'complete -W "validate why doctor health repair schema examples info completion help --bead-id --bead-body-file --watchtower-fixture --watchtower-bin --watchtower-json-fixture --br-bin --json --explain --dry-run --apply" dispatch-trigger-gated-precheck.sh'; }

# --- argument parsing ---
COMMAND=""
BEAD_ID=""
BEAD_BODY_FILE=""
WATCHTOWER_FIXTURE=""
WATCHTOWER_JSON_FIXTURE=""
JSON_OUT=0
EXPLAIN=0
REPAIR_MODE=""

if [[ $# -eq 0 ]]; then usage >&2; exit 1; fi

case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  schema) schema; exit 0 ;;
  examples|--examples) examples; exit 0 ;;
  info|--info) info; exit 0 ;;
  completion) completion; exit 0 ;;
esac

COMMAND="$1"
shift
case "$COMMAND" in
  validate|why|doctor|health|repair) ;;
  *) usage >&2; die "unknown command: $COMMAND" 1 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bead-id) BEAD_ID="$2"; shift 2 ;;
    --bead-body-file) BEAD_BODY_FILE="$2"; shift 2 ;;
    --watchtower-fixture) WATCHTOWER_FIXTURE="$2"; shift 2 ;;
    --watchtower-bin) WATCHTOWER_BIN="$2"; shift 2 ;;
    --watchtower-json-fixture) WATCHTOWER_JSON_FIXTURE="$2"; shift 2 ;;
    --br-bin) BR_BIN="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --explain) EXPLAIN=1; JSON_OUT=1; shift ;;
    --dry-run) REPAIR_MODE="dry-run"; shift ;;
    --apply) REPAIR_MODE="apply"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown flag: $1" 1 ;;
  esac
done

# --- helpers ---
load_bead_body() {
  if [[ -n "$BEAD_BODY_FILE" ]]; then
    [[ -r "$BEAD_BODY_FILE" ]] || die "bead-body-file unreadable: $BEAD_BODY_FILE" 2
    cat "$BEAD_BODY_FILE"
    return 0
  fi
  [[ -n "$BEAD_ID" ]] || die "either --bead-id or --bead-body-file required" 1
  local raw
  raw="$("$BR_BIN" show "$BEAD_ID" --json 2>/dev/null || true)"
  [[ -n "$raw" ]] || die "br show $BEAD_ID failed" 2
  echo "$raw" | jq -r 'if type=="array" then (.[0].description // .[0].body // "") else (.description // .body // "") end' 2>/dev/null
}

# Parse bead body for the structured field. Returns watchtower name on stdout (empty if absent).
parse_external_trigger() {
  local body="$1"
  printf '%s\n' "$body" \
    | grep -Eo 'external_trigger_watchtower=[A-Za-z0-9_]+' \
    | head -1 \
    | sed -E 's/^external_trigger_watchtower=//' \
    || true
}

# Detect prose-only signals. Emits one signal-name per line.
parse_prose_signals() {
  local body="$1"
  {
    grep -iEo 'operational trigger[^.]*' <<<"$body" 2>/dev/null || true
    grep -iEo 'depends on[^.]*release announcement[^.]*' <<<"$body" 2>/dev/null || true
    grep -iEo 'await(s|ing)?[^.]*release[^.]*' <<<"$body" 2>/dev/null || true
    grep -iEo 'gated on[^.]*release[^.]*' <<<"$body" 2>/dev/null || true
  } | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//' | grep -v '^$' | head -3 || true
}

# Run watchtower or use fixture, return JSON on stdout.
load_watchtower_json() {
  if [[ -n "$WATCHTOWER_JSON_FIXTURE" ]]; then
    [[ -r "$WATCHTOWER_JSON_FIXTURE" ]] || die "watchtower-json-fixture unreadable: $WATCHTOWER_JSON_FIXTURE" 3
    cat "$WATCHTOWER_JSON_FIXTURE"
    return 0
  fi
  [[ -x "$WATCHTOWER_BIN" ]] || die "watchtower not executable: $WATCHTOWER_BIN" 3
  local args=(--json)
  [[ -n "$WATCHTOWER_FIXTURE" ]] && args+=(--frankenterm-release-fixture "$WATCHTOWER_FIXTURE")
  "$WATCHTOWER_BIN" "${args[@]}" 2>/dev/null || die "watchtower probe failed" 3
}

# Lookup .watchlists.<name>.status from watchtower JSON.
lookup_status() {
  local watchtower_json="$1" name="$2"
  echo "$watchtower_json" | jq -r --arg n "$name" '.watchlists[$n].status // "missing"' 2>/dev/null
}

is_release_available() {
  local status="$1" s
  for s in "${RELEASE_AVAILABLE_STATUSES[@]}"; do
    [[ "$status" == "$s" ]] && return 0
  done
  return 1
}

# --- evaluation core ---
evaluate() {
  local body watchtower_name prose_signals_text watchtower_json status reason warnings
  body="$(load_bead_body)"
  watchtower_name="$(parse_external_trigger "$body")"
  prose_signals_text="$(parse_prose_signals "$body")"
  warnings=()

  if [[ -z "$watchtower_name" ]]; then
    if [[ -n "$prose_signals_text" ]]; then
      warnings+=("prose-trigger-detected-but-no-external_trigger_watchtower-field")
    fi
    local warnings_json="[]"
    if [[ ${#warnings[@]} -gt 0 ]]; then
      warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    fi
    jq -nc \
      --arg sv "$VERSION" \
      --argjson tg false \
      --arg name "" \
      --arg status "" \
      --arg reason "no_external_trigger_watchtower_field" \
      --arg signals "$prose_signals_text" \
      --argjson warnings "$warnings_json" \
      '{schema_version:$sv,status:"not_trigger_gated",trigger_gated:$tg,watchtower:$name,watchtower_status:null,reason_code:$reason,warnings:$warnings,prose_signals:($signals | split("\n") | map(select(length>0)))}'
    return 0
  fi

  watchtower_json="$(load_watchtower_json)"
  if ! echo "$watchtower_json" | jq -e . >/dev/null 2>&1; then
    jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" \
      '{schema_version:$sv,status:"malformed",trigger_gated:true,watchtower:$name,watchtower_status:null,reason_code:"watchtower_json_malformed",warnings:["watchtower output is not valid JSON"]}'
    return 5
  fi

  status="$(lookup_status "$watchtower_json" "$watchtower_name")"
  if [[ "$status" == "missing" || -z "$status" || "$status" == "null" ]]; then
    jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" \
      '{schema_version:$sv,status:"watchtower_unreachable",trigger_gated:true,watchtower:$name,watchtower_status:null,reason_code:"watchlist_not_present",warnings:[("watchlist " + $name + " not found in watchtower output")]}'
    return 3
  fi

  if is_release_available "$status"; then
    reason="trigger_has_fired"
    jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" --arg status "$status" --arg reason "$reason" \
      '{schema_version:$sv,status:"ok",trigger_gated:true,watchtower:$name,watchtower_status:$status,reason_code:$reason,warnings:[]}'
    return 0
  fi

  reason="trigger_not_yet_fired"
  jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" --arg status "$status" --arg reason "$reason" \
    '{schema_version:$sv,status:"trigger_not_yet_fired",trigger_gated:true,watchtower:$name,watchtower_status:$status,reason_code:$reason,warnings:[("watchtower says " + $name + ".status=" + $status + " — wait for release_available before dispatch")]}'
  return 6
}

# --- command dispatch ---
# Audit-append helper: appends a terminal envelope row to SCAFFOLD_AUDIT_LOG so
# the canonical scaffold layer (health, audit, why) has historical signal.
# Falls back to a direct append if the helper-lib's cli_audit_append is unavailable.
_audit_append_terminal() {
  local cmd="$1" envelope_json="$2" rc_val="$3"
  local ts bead row
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  bead="${BEAD_ID:-}"
  row="$(jq -nc --arg ts "$ts" --arg sv "${SCAFFOLD_SCHEMA_VERSION:-dispatch-trigger-gated-precheck/v1}" \
    --arg cmd "$cmd" --arg bead "$bead" --argjson rc "$rc_val" --argjson ev "${envelope_json:-null}" \
    '{ts:$ts,schema_version:$sv,command:$cmd,bead:$bead,rc:$rc,
      watchtower:($ev.watchtower // null),
      watchtower_status:($ev.watchtower_status // null),
      reason_code:($ev.reason_code // null),
      status:($ev.status // null),
      trigger_gated:($ev.trigger_gated // null)}' 2>/dev/null)"
  [[ -z "$row" ]] && return 0
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-trigger-gated-precheck-runs.jsonl}" "$cmd" "ok" "$row" >/dev/null 2>&1 || true
  else
    local log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-trigger-gated-precheck-runs.jsonl}"
    mkdir -p "$(dirname "$log")" 2>/dev/null || true
    printf '%s\n' "$row" >> "$log" 2>/dev/null || true
  fi
}

case "$COMMAND" in
  validate|why)
    set +e
    out="$(evaluate)"
    rc=$?
    set -e
    _audit_append_terminal "$COMMAND" "$out" "$rc"
    if [[ "$JSON_OUT" -eq 1 || "$COMMAND" == "why" ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"status=\(.status) trigger_gated=\(.trigger_gated) watchtower=\(.watchtower) watchtower_status=\(.watchtower_status) reason=\(.reason_code)"' <<<"$out"
    fi
    exit "$rc"
    ;;
  doctor|health)
    if [[ -n "$BEAD_ID" || -n "$BEAD_BODY_FILE" ]]; then
      set +e
      out="$(evaluate)"
      rc=$?
      set -e
      _audit_append_terminal "$COMMAND" "$out" "$rc"
      if [[ "$COMMAND" == "health" ]]; then
        if [[ "$JSON_OUT" -eq 1 ]]; then
          printf '%s\n' "$out"
        else
          jq -r '"health=\(.status)"' <<<"$out"
        fi
      else
        if [[ "$JSON_OUT" -eq 1 ]]; then
          printf '%s\n' "$out"
        else
          jq -r '"doctor: status=\(.status) reason=\(.reason_code) wt=\(.watchtower) wt_status=\(.watchtower_status)"' <<<"$out"
        fi
      fi
      exit "$rc"
    fi
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg v "$VERSION" '{schema_version:$v,status:"ok",ready:true,note:"no bead probed; surface healthy"}'
    else
      printf 'doctor: surface healthy (no bead probed)\n'
    fi
    exit 0
    ;;
  repair)
    [[ -n "$BEAD_ID" ]] || die "repair requires --bead-id" 1
    [[ "$REPAIR_MODE" == "dry-run" || "$REPAIR_MODE" == "apply" ]] || die "repair requires --dry-run or --apply" 1
    set +e
    out="$(evaluate)"
    rc=$?
    set -e
    case "$rc" in
      0) suggestion="no_change_needed" ;;
      6) suggestion="hold_dispatch_until_watchtower_flip" ;;
      3) suggestion="probe_watchtower_health" ;;
      5) suggestion="fix_watchtower_emit_or_fixture" ;;
      *) suggestion="see_validate_output" ;;
    esac
    _audit_append_terminal "$COMMAND" "$out" "$rc"
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg v "$VERSION" --arg s "$suggestion" --arg mode "$REPAIR_MODE" --argjson o "$out" '{schema_version:$v,mode:$mode,suggestion:$s,probe:$o,mutation_invoked:false}'
    else
      printf 'repair: suggestion=%s mode=%s (no mutation)\n' "$suggestion" "$REPAIR_MODE"
    fi
    exit 0
    ;;
esac

usage >&2
exit 1
