#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.12)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# Coexistence design (mirrors flywheel-5ke66.9 pattern): python heredoc
# already exposes --info / --examples / --schema flag-form surfaces that
# tests/fleet-process-gap-detector.sh asserts on. Bash early-dispatch
# intercepts --info / --schema / --examples with HAND-ROLLED envelopes
# preserving the python-shape fields (.name, .doctor_fields,
# .properties.process_health_score.maximum) plus AG3 .version. The new
# no-dash subcommands (doctor, health, repair, validate, audit, why) add
# canonical surfaces. Default flag-form invocation (--apply / --dry-run /
# --idempotency-key / --json) falls through to python's gap detector.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fleet-process-gap-detector/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/process-gap-detector/runs.jsonl}"
SCAFFOLD_FUCKUP_LOG="${SCAFFOLD_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
SCAFFOLD_TICK_DIR="${SCAFFOLD_TICK_DIR:-$HOME/.local/state/flywheel-loop}"
SCAFFOLD_STATE_DIR="${SCAFFOLD_STATE_DIR:-$HOME/.local/state/flywheel/process-gap-detector}"

scaffold_usage() {
  cat <<'USG'
usage: fleet-process-gap-detector.sh [SUBCOMMAND] [OPTIONS]

Default flag-form invocation routes to the python gap detector (build_payload
+ optional br create on --apply --idempotency-key). Tests/fleet-process-gap-detector.sh
exercises --info / --examples / --schema / default-run; those keep their
existing shapes.

Canonical CLI surfaces (intercepted before the python heredoc):
  doctor [--json]          probe substrate health (python3/jq/br/fuckup-log/tick-dir/root)
  health [--json]          last-run status (state-dir + fuckup-log + tick-dir freshness)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, state-dir-prime
  validate <subject> [...] validate per-subject contract
                            Subjects: row, schema, config, fuckup-log, tick-dir
  audit [--json]           recent run history (state-dir tail)
  why <id>                 explain provenance for a given id
                            (id matches class / repo / bead reference)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection (backward-compat shape preserved):
  --info --json            keeps .name + .doctor_fields + .canonical_flags;
                           adds AG3 .version + .subcommands
  --schema [<surface>]     keeps JSON-Schema shape with
                           .properties.process_health_score.maximum=100
  --examples --json        backward-compat invocations + new canonical examples
  --help / -h              this help
USG
}

# Hand-rolled --info envelope preserving python-shape fields
# (.name, .doctor_fields, .canonical_flags) AND AG3 fields (.version, .subcommands).
scaffold_emit_info() {
  local sha; sha="$(cli_sha_self "${BASH_SOURCE[0]}" 2>/dev/null || echo)"
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg name "fleet-process-gap-detector" \
    --arg version "scaffolded-v0" \
    --arg sha "$sha" \
    --arg ledger "$SCAFFOLD_AUDIT_LOG" \
    '{
      schema_version: $sv,
      command: "info",
      name: $name,
      version: $version,
      sha256: $sha,
      summary: "Aggregates recurring fleet failures into process-gap rows and optional fix-bead plans.",
      doctor_fields: ["fleet_process_gap_detector","fleet_process_open_gap_count","fleet_process_stuck_class_count","fleet_process_health_score","fleet_process_top_gap_class"],
      subcommands: ["doctor","health","repair","validate","audit","why","quickstart","help","completion"],
      canonical_flags: ["--info","--examples","--schema","--json","--apply","--dry-run","--idempotency-key"],
      canonical_cli_surfaces: ["doctor","health","repair","validate","audit","why","quickstart","help","completion","--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key"],
      env_vars: ["SCAFFOLD_AUDIT_LOG","SCAFFOLD_FUCKUP_LOG","SCAFFOLD_TICK_DIR","SCAFFOLD_STATE_DIR"],
      dependencies: ["bash","python3","jq","date","shasum"],
      mutation_requires: "--apply requires a stable class marker; actual br create requires --idempotency-key",
      audit_log: $ledger
    }'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default detector run",invocation:"fleet-process-gap-detector.sh --json",purpose:"aggregate recurring fleet failures into process-gap rows"}'
)"$'\n'"$(jq -nc '{name:"dry-run fix-bead plan",invocation:"fleet-process-gap-detector.sh --apply --dry-run --json",purpose:"propose fix-bead create actions without mutating beads.jsonl"}'
)"$'\n'"$(jq -nc '{name:"apply fix-beads",invocation:"fleet-process-gap-detector.sh --apply --idempotency-key process-gap-20260511 --json",purpose:"actually br create fix beads from gap rows"}'
)"$'\n'"$(jq -nc '{name:"doctor (canonical)",invocation:"fleet-process-gap-detector.sh doctor --json",purpose:"substrate probe: python3/jq/br/fuckup-log/tick-dir/root"}'
)"$'\n'"$(jq -nc '{name:"validate tick-dir",invocation:"fleet-process-gap-detector.sh validate --tick-dir",purpose:"probe tick-dir state + receipt freshness"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"fleet-process-gap-detector.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"see fuckup-log + tick-dir state",command:"fleet-process-gap-detector.sh validate --tick-dir"}'
)"$'\n'"$(jq -nc '{step:3,action:"dry-run gap aggregation",command:"fleet-process-gap-detector.sh --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

# Hand-rolled --schema envelope. Default branch preserves python's JSON-Schema
# shape (with .properties.process_health_score.maximum=100) so the existing
# tests/fleet-process-gap-detector.sh:89 assertion keeps passing.
scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","fuckup_log_rows","tick_dir_receipts"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","state-dir-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","state_dir?","run_count?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","fuckup-log","tick-dir"],fields:["status","subject","valid?","missing?","reason?","fuckup_log?","tick_dir?","row_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"class|repo|bead-id"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["schema_version","checked_at","open_gap_count","top_gaps","stuck_class_count","process_health_score"]}' ;;
    *)
      # Default — preserve python's JSON Schema shape for test backward-compat.
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{
          "$schema":"https://json-schema.org/draft/2020-12/schema",
          schema_version:$sv,
          command:"schema",
          surface:$surface,
          type:"object",
          required:["schema_version","checked_at","open_gap_count","top_gaps","stuck_class_count","process_health_score"],
          properties:{
            schema_version:{const:$sv},
            checked_at:{type:"string"},
            open_gap_count:{type:"integer"},
            stuck_class_count:{type:"integer"},
            process_health_score:{type:"integer",minimum:0,maximum:100},
            top_gaps:{type:"array"}
          }
        }' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — python gap detector; aggregates fuckup-log + tick-dir doctor JSONs across fleet repos, scores process health 0-100, emits top gaps. --apply with --idempotency-key creates fix beads via br.\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: python3, jq, br binary, fuckup-log readable, tick-dir readable, flywheel root.\n' ;;
    health)   printf 'topic: health — tails state-dir runs jsonl (= audit log); warn stale >7d. Reports fuckup-log row count + tick-dir receipt count for freshness.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), state-dir-prime (read-only — probes state-dir contents).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON (gap-row schema), --schema, --config, --fuckup-log (probes fuckup-log.jsonl row count + last-row schema), --tick-dir (probes ~/.local/state/flywheel-loop receipt JSONs).\n' ;;
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
            && cli_emit_completion_bash "fleet-process-gap-detector" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--repo,--fuckup-log,--tick-dir,--state-dir,--now,--lookback-hours,--max-gaps" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fleet-process-gap-detector" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (filled-in per flywheel-5ke66.12) ----------

scaffold_cmd_doctor() {
  # Substrate: python3, jq, br, fuckup-log readable, tick-dir readable, flywheel root.
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local br_bin="${BR_BIN:-/Users/josh/.cargo/bin/br}"
  local checks="" overall="pass"

  if command -v python3 >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v python3)" '{name:"python3_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"python3_on_path",status:"fail",detail:"python3 required for heredoc dispatcher"}')"$'\n'
    overall="fail"
  fi

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if [[ -x "$br_bin" ]]; then
    checks+="$(jq -nc --arg p "$br_bin" '{name:"br_bin_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$br_bin" '{name:"br_bin_executable",status:"warn",value:$p,detail:"br invoked on --apply --idempotency-key path; warn if missing for --json reporting mode"}')"$'\n'
  fi

  local fl_rows=0 fl_present=false
  if [[ -r "$SCAFFOLD_FUCKUP_LOG" ]]; then
    fl_present=true
    fl_rows="$(wc -l < "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
  fi
  local fl_status="pass"
  [[ "$fl_present" != true ]] && fl_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_FUCKUP_LOG" --arg s "$fl_status" --argjson present "$fl_present" --argjson rows "${fl_rows:-0}" \
    '{name:"fuckup_log_readable",status:$s,value:$p,present:$present,row_count:$rows}')"$'\n'

  local td_count=0 td_present=false
  if [[ -d "$SCAFFOLD_TICK_DIR" ]]; then
    td_present=true
    td_count="$(find "$SCAFFOLD_TICK_DIR" -maxdepth 3 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  fi
  local td_status="pass"
  [[ "$td_present" != true ]] && td_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_TICK_DIR" --arg s "$td_status" --argjson present "$td_present" --argjson count "${td_count:-0}" \
    '{name:"tick_dir_readable",status:$s,value:$p,present:$present,receipt_count:$count}')"$'\n'

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
  local fuckup_rows=0 tick_receipts=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.checked_at // .ts // empty' 2>/dev/null || true)"
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
  [[ -r "$SCAFFOLD_FUCKUP_LOG" ]] && fuckup_rows="$(wc -l < "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
  [[ -d "$SCAFFOLD_TICK_DIR" ]] && tick_receipts="$(find "$SCAFFOLD_TICK_DIR" -maxdepth 3 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson fl "${fuckup_rows:-0}" --argjson tr "${tick_receipts:-0}" \
    --arg fuckup "$SCAFFOLD_FUCKUP_LOG" --arg tick "$SCAFFOLD_TICK_DIR" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,fuckup_log:$fuckup,fuckup_log_rows:$fl,tick_dir:$tick,tick_dir_receipts:$tr}'
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
    state-dir-prime)
      # Read-only: probe DEFAULT_STATE_DIR contents.
      local sd_present=false run_count=0
      if [[ -d "$SCAFFOLD_STATE_DIR" ]]; then
        sd_present=true
        run_count="$(find "$SCAFFOLD_STATE_DIR" -maxdepth 2 -type f 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      fi
      local status="pass"
      [[ "$sd_present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg sd "$SCAFFOLD_STATE_DIR" --arg s "$status" \
        --argjson present "$sd_present" --argjson rc "${run_count:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,state_dir:$sd,present:$present,run_count:$rc,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","state-dir-prime"]}'
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
      --fuckup-log) subject="fuckup-log"; shift ;;
      --tick-dir) subject="tick-dir"; shift ;;
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
      # Gap-row contract from python's emit_schema: required fields.
      for f in schema_version checked_at open_gap_count top_gaps stuck_class_count process_health_score; do
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
      local py_ok=false jq_ok=false br_ok=false fl_ok=false td_ok=false root_ok=false
      command -v python3 >/dev/null 2>&1 && py_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -x "${BR_BIN:-/Users/josh/.cargo/bin/br}" ]] && br_ok=true
      [[ -r "$SCAFFOLD_FUCKUP_LOG" ]] && fl_ok=true
      [[ -d "$SCAFFOLD_TICK_DIR" ]] && td_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$py_ok" != true || "$jq_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson py "$py_ok" --argjson jqq "$jq_ok" --argjson br "$br_ok" \
        --argjson fl "$fl_ok" --argjson td "$td_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg fuckup "$SCAFFOLD_FUCKUP_LOG" --arg tick "$SCAFFOLD_TICK_DIR" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,python3_present:$py,jq_present:$jqq,br_bin_present:$br,fuckup_log_present:$fl,tick_dir_present:$td,flywheel_root_present:$rt,flywheel_root:$root,fuckup_log:$fuckup,tick_dir:$tick}'
      ;;
    fuckup-log)
      # surface-specific: probe fuckup-log.jsonl shape.
      local present=false rows=0 last_row=null last_row_valid=false
      if [[ -r "$SCAFFOLD_FUCKUP_LOG" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        local raw; raw="$(tail -n 1 "$SCAFFOLD_FUCKUP_LOG" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          # fuckup-log rows minimally need ts and class/code/message.
          if printf '%s' "$raw" | jq -e 'has("ts") and (has("class") or has("code") or has("message"))' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg fl "$SCAFFOLD_FUCKUP_LOG" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"fuckup-log",status:$s,fuckup_log:$fl,present:$present,row_count:$rows,last_row:$lr,last_row_valid:$lrv}'
      ;;
    tick-dir)
      # surface-specific: probe tick-dir receipts.
      local present=false receipts=0
      if [[ -d "$SCAFFOLD_TICK_DIR" ]]; then
        present=true
        receipts="$(find "$SCAFFOLD_TICK_DIR" -maxdepth 3 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg td "$SCAFFOLD_TICK_DIR" \
        --argjson present "$present" --argjson r "${receipts:-0}" \
        '{schema_version:$sv,command:"validate",subject:"tick-dir",status:$s,tick_dir:$td,present:$present,receipt_count:$r}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","fuckup-log","tick-dir"],usage:"validate --row-json JSON or --schema or --config or --fuckup-log or --tick-dir"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","fuckup-log","tick-dir"]}'
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

python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "fleet-process-gap-detector/v1"
DEFAULT_FUCKUP_LOG = Path.home() / ".local/state/flywheel/fuckup-log.jsonl"
DEFAULT_TICK_DIR = Path.home() / ".local/state/flywheel-loop"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel/process-gap-detector"
DEFAULT_ROSTER = Path.home() / ".local/state/flywheel/fleet-roster.json"
DEFAULT_REPOS = [
    "/Users/josh/Developer/flywheel",
    "/Users/josh/Developer/mobile-eats",
    "/Users/josh/Developer/skillos",
    "/Users/josh/Developer/alpsinsurance",
    "/Users/josh/Desktop/Projects/clients/alps-insurance",
    "/Users/josh/Developer/vrtx",
]
SEVERITY_RANK = {"low": 1, "medium": 2, "high": 3}


def parse_ts(value: Any):
    if not value:
        return None
    text = str(value).strip()
    if not text:
        return None
    for candidate in (text, text.replace("Z", "+00:00")):
        try:
            parsed = datetime.fromisoformat(candidate)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            pass
    return None


def now_utc(override: str | None):
    return parse_ts(override) or datetime.now(timezone.utc)


def iso(dt: datetime | None):
    if not dt:
        return None
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path):
    try:
        data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
        return data if isinstance(data, dict) else None
    except Exception:
        return None


def read_jsonl(path: Path):
    rows = []
    if not path.exists():
        return rows
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except Exception:
        return rows
    for line_no, line in enumerate(lines, start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            row["_source_line"] = line_no
            rows.append(row)
    return rows


def event_ts(row: dict[str, Any]):
    for key in ("ts", "checked_at", "generated_at", "created_at", "updated_at", "callback_received_at", "validated_at"):
        parsed = parse_ts(row.get(key))
        if parsed:
            return parsed
    doctor = row.get("doctor")
    if isinstance(doctor, dict):
        for key in ("ts", "checked_at", "generated_at", "created_at"):
            parsed = parse_ts(doctor.get(key))
            if parsed:
                return parsed
    return None


def normalize_error(item: Any):
    if isinstance(item, dict):
        value = item.get("code") or item.get("class") or item.get("issue") or item.get("message")
    else:
        value = item
    text = str(value or "").strip()
    if not text:
        return None
    text = re.sub(r"\s+", "_", text.lower())
    text = re.sub(r"[^a-z0-9_.:-]+", "_", text).strip("_")
    return text[:120] or None


def extract_errors(payload: dict[str, Any]):
    errors = []
    for source in (payload, payload.get("doctor") if isinstance(payload.get("doctor"), dict) else {}):
        for item in source.get("errors") or []:
            norm = normalize_error(item)
            if norm:
                errors.append(norm)
    return sorted(set(errors))


def doctor_payload(row: dict[str, Any]):
    doctor = row.get("doctor")
    return doctor if isinstance(doctor, dict) else row


def doctor_samples(args):
    rows = []
    for raw in args.doctor_json:
        path = Path(raw).expanduser()
        data = read_json(path)
        if data:
            rows.append((event_ts(data) or parse_ts(data.get("checked_at")) or datetime.fromtimestamp(path.stat().st_mtime, timezone.utc), str(data.get("repo") or path.stem), doctor_payload(data), str(path)))
    tick_dir = Path(args.tick_dir).expanduser()
    if tick_dir.exists():
        for path in sorted(tick_dir.rglob("*.json")):
            try:
                if path.stat().st_size > 2_000_000:
                    continue
            except OSError:
                continue
            data = read_json(path)
            if not data:
                continue
            payload = doctor_payload(data)
            repo = payload.get("repo") or data.get("repo") or data.get("project") or data.get("session") or path.stem
            ts = event_ts(data) or datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
            rows.append((ts, str(repo), payload, str(path)))
    return rows


def severity_for_class(name: str, source: str, occurrences: int, explicit: str | None = None):
    if explicit in SEVERITY_RANK:
        return explicit
    text = f"{name} {source}".lower()
    if any(token in text for token in ("secret", "identity", "sticky_doctor", "doctor_error", "canonical_drift")):
        return "high"
    if occurrences >= 3 or any(token in text for token in ("closed_bead", "watcher", "promotion")):
        return "medium"
    return "low"


def remediation_skill(name: str):
    text = name.lower()
    if "agent" in text or "identity" in text:
        return "agent-mail"
    if "bead" in text or "br" in text:
        return "beads-workflow"
    if "doctor" in text or "sticky" in text:
        return "flywheel-doctor-author"
    if "watcher" in text or "slo" in text:
        return "observability-platform"
    if "drift" in text or "canonical" in text:
        return "canonical-cli-scoping"
    return "flywheel-recovery"


def proposed_remediation(name: str, source: str):
    if name.startswith("sticky_doctor_error:"):
        return "Route the sticky doctor error into a fix-bead and add/repair its consumer gate."
    if name.startswith("three_surface_drift:"):
        return "Backfill the drifting doctrine surface and add it to the 3-surface sync path."
    if name.startswith("unprocessed_promotion:"):
        return "Promote or explicitly reject the stale promotion candidate through the L56 ladder."
    if name == "closed_bead_audit_gap":
        return "Run bead-quality mining and file or close audit-gap beads for the top class."
    if name == "fleet_identity_drift":
        return "Repair tuple-key identity registry drift and sweep orphan token residue."
    if name == "fleet_watcher_coverage_hole":
        return "Restore watcher coverage or record an explicit non-participating session receipt."
    return "File a process fix-bead that changes the gate rather than handling one symptom."


def add_gap(gaps: dict[str, dict[str, Any]], name: str, source: str, first_seen, occurrences: int, severity: str | None = None, evidence: dict[str, Any] | None = None):
    if not name:
        return
    severity = severity_for_class(name, source, occurrences, severity)
    existing = gaps.get(name)
    if existing:
        existing["occurrences"] += occurrences
        if first_seen and (not existing["_first_seen_dt"] or first_seen < existing["_first_seen_dt"]):
            existing["_first_seen_dt"] = first_seen
            existing["first_seen"] = iso(first_seen)
        if SEVERITY_RANK[severity] > SEVERITY_RANK[existing["severity"]]:
            existing["severity"] = severity
        if evidence:
            existing.setdefault("evidence", []).append(evidence)
        return
    gaps[name] = {
        "class": name,
        "severity": severity,
        "_first_seen_dt": first_seen,
        "first_seen": iso(first_seen),
        "occurrences": int(occurrences),
        "proposed_remediation": proposed_remediation(name, source),
        "remediation_skill": remediation_skill(name),
        "source": source,
        "evidence": [evidence] if evidence else [],
    }


def repeating_fuckups(args, gaps, now):
    rows = read_jsonl(Path(args.fuckup_log).expanduser())
    start = now - timedelta(hours=args.lookback_hours)
    by_class: dict[str, list[dict[str, Any]]] = {}
    promotion_rows: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        cls = str(row.get("trauma_class") or row.get("class") or row.get("source_event_id") or "").strip()
        if not cls:
            continue
        ts = event_ts(row)
        if ts and start <= ts <= now:
            by_class.setdefault(cls, []).append(row)
        promote = row.get("promote") is True or row.get("promotion_ready") is True or row.get("should_promote") is True
        processed = row.get("processed") is True or row.get("promoted") is True or row.get("promoted_at") or row.get("l_rule_id")
        if promote and not processed:
            promotion_rows.setdefault(cls, []).append(row)
    for cls, items in by_class.items():
        if len(items) >= 2:
            first = min((event_ts(item) for item in items if event_ts(item)), default=None)
            explicit = max((str(item.get("severity") or "low") for item in items), key=lambda s: SEVERITY_RANK.get(s, 0), default=None)
            add_gap(gaps, cls, "repeating_fuckup_class", first, len(items), explicit, {"source": str(args.fuckup_log), "lines": [i.get("_source_line") for i in items[:5]]})
    for cls, items in promotion_rows.items():
        first = min((event_ts(item) for item in items if event_ts(item)), default=None)
        if first and first <= now - timedelta(hours=24):
            add_gap(gaps, f"unprocessed_promotion:{cls}", "unprocessed_promotion_candidate", first, len(items), "medium", {"source": str(args.fuckup_log), "lines": [i.get("_source_line") for i in items[:5]]})


def sticky_doctor_errors(samples, gaps):
    by_repo: dict[str, list[tuple[datetime, set[str], str]]] = {}
    for ts, repo, payload, path in samples:
        errors = set(extract_errors(payload))
        by_repo.setdefault(repo, []).append((ts, errors, path))
    seen = set()
    for repo, rows in by_repo.items():
        rows.sort(key=lambda item: item[0])
        for idx in range(0, max(0, len(rows) - 2)):
            window = rows[idx:idx + 3]
            common = set.intersection(*(item[1] for item in window)) if all(item[1] for item in window) else set()
            for code in common:
                key = (repo, code)
                if key in seen:
                    continue
                seen.add(key)
                occurrences = sum(1 for _, errors, _ in rows if code in errors)
                add_gap(gaps, f"sticky_doctor_error:{code}", "sticky_doctor_error", window[0][0], occurrences, "high", {"repo": repo, "paths": [item[2] for item in window]})


def count_l_rules(path: Path):
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return 0
    return len(re.findall(r"^## L\d+\b", text, flags=re.MULTILINE))


def roster_repos():
    rows = []
    data = read_json(DEFAULT_ROSTER)
    if not data:
        return rows
    for item in (data.get("repos") or []) + (data.get("members") or []):
        if isinstance(item, dict):
            value = item.get("repo") or item.get("repo_realpath")
            if value:
                rows.append(value)
    return rows


def fleet_repos(args):
    values = list(args.fleet_repo)
    for root_raw in args.fleet_root:
        root = Path(root_raw).expanduser()
        if root.exists():
            for child in sorted(root.iterdir()):
                if child.is_dir() and ((child / "AGENTS.md").exists() or (child / ".flywheel/loop.json").exists()):
                    values.append(str(child))
    if not values:
        values.extend(roster_repos())
    if not values:
        values.extend(DEFAULT_REPOS)
    seen = set()
    repos = []
    for value in values:
        path = Path(value).expanduser()
        try:
            path = path.resolve()
        except Exception:
            pass
        if path.exists() and str(path) not in seen:
            seen.add(str(path))
            repos.append(path)
    return repos or [Path(args.repo).expanduser().resolve()]


def doctrine_drift(args, gaps, now):
    for repo in fleet_repos(args):
        agents = repo / "AGENTS.md"
        template = repo / "templates/flywheel-install/AGENTS.md"
        agents_count = count_l_rules(agents)
        template_count = count_l_rules(template)
        delta = abs(agents_count - template_count)
        if delta > 5:
            add_gap(
                gaps,
                f"three_surface_drift:{repo.name}",
                "three_surface_rule_count_delta",
                now,
                delta,
                "high" if delta > 10 else "medium",
                {"repo": str(repo), "agents_count": agents_count, "template_count": template_count, "delta": delta},
            )


def latest_value_gap(samples, key_names):
    hits = []
    for ts, repo, payload, path in samples:
        value = None
        for key in key_names:
            if key in payload:
                value = payload.get(key)
                break
        try:
            value_int = int(value or 0)
        except Exception:
            value_int = 0
        if value_int > 0:
            hits.append((ts, repo, payload, path, value_int))
    if not hits:
        return None
    hits.sort(key=lambda item: item[0])
    latest = hits[-1]
    first = hits[0][0]
    total = max(item[4] for item in hits)
    return first, latest, total


def doctor_field_gaps(samples, gaps, now):
    closed = latest_value_gap(samples, ["closed_bead_audit_gap_count"])
    if closed:
        first, latest, total = closed
        add_gap(gaps, "closed_bead_audit_gap", "doctor_closed_bead_audit_gap_count", first, total, "medium", {"repo": latest[1], "path": latest[3], "count": total})
    identity = latest_value_gap(samples, ["fleet_identity_drift_count", "identity_registry_drift"])
    if identity:
        first, latest, total = identity
        add_gap(gaps, "fleet_identity_drift", "doctor_identity_drift", first, total, "high", {"repo": latest[1], "path": latest[3], "count": total})

    watcher_hits = []
    for ts, repo, payload, path in samples:
        try:
            total = int(payload.get("fleet_watcher_coverage_total") or 0)
            count = int(payload.get("fleet_watcher_coverage_count") or 0)
        except Exception:
            continue
        deficit = max(0, total - count)
        age = payload.get("fleet_watcher_coverage_hole_age_seconds")
        try:
            age = int(age or 0)
        except Exception:
            age = 0
        if deficit > 0:
            watcher_hits.append((ts, repo, payload, path, deficit, age))
    if watcher_hits:
        watcher_hits.sort(key=lambda item: item[0])
        latest = watcher_hits[-1]
        first = watcher_hits[0][0]
        age_ok = first <= now - timedelta(hours=24) or latest[5] >= 86400
        if age_ok:
            add_gap(gaps, "fleet_watcher_coverage_hole", "doctor_watcher_coverage_deficit", first, latest[4], "medium", {"repo": latest[1], "path": latest[3], "deficit": latest[4]})


def marker_for(cls: str):
    return hashlib.sha1(cls.encode("utf-8")).hexdigest()[:12]


def issue_status_open(status: str):
    return str(status or "").lower() not in {"closed", "done", "resolved", "cancelled", "wontfix"}


def existing_bead(repo: Path, marker: str, ledger: Path):
    for row in read_jsonl(ledger):
        if row.get("marker") == marker and row.get("bead_id"):
            return {"source": "ledger", "bead_id": row.get("bead_id"), "title": row.get("title")}
    issues = repo / ".beads/issues.jsonl"
    for row in read_jsonl(issues):
        title = str(row.get("title") or row.get("summary") or "")
        if marker in title and issue_status_open(str(row.get("status") or row.get("state") or "")):
            return {"source": "beads", "bead_id": row.get("id"), "title": title}
    return None


def bead_description(gap: dict[str, Any], idempotency_key: str | None):
    return f"""## Goal
Fix the process gap `{gap['class']}` by changing the detector, gate, or routing rule that let it recur.

## Context
The fleet process-gap detector found this as a meta-level process leak, not an individual-agent failure.
Severity: {gap['severity']}
Occurrences: {gap['occurrences']}
First seen: {gap.get('first_seen') or 'unknown'}
Recommended skill: {gap['remediation_skill']}

## Inputs / Outputs
INPUTS: fleet-process-gap-detector/v1 evidence and related doctor/fuckup rows.
OUTPUTS: one durable gate, probe, doctrine, or routing repair.

## Acceptance Criteria
- The class no longer appears in `fleet-process-gap-detector.sh --json`.
- If the class is expected to recur, it routes to a named doctor/status/bead consumer.
- Dedupe marker remains in the bead title.

## Testing Obligations
- Run the relevant probe/test for the repaired substrate.
- Report detector before/after JSON.

## Definition of Done
COMMIT: fix(process): close {gap['class']}
AUTONOMY: autonomous
IDEMPOTENCY_KEY: {idempotency_key or 'stable-class-marker'}
"""


def apply_plan(args, top_gaps):
    repo = Path(args.repo).expanduser().resolve()
    state_dir = Path(args.state_dir).expanduser()
    ledger = state_dir / "process-gap-fix-beads.jsonl"
    planned = []
    actual = []
    filed = []
    blocked = []
    for gap in top_gaps:
        marker = f"auto-process-gap:{marker_for(gap['class'])}"
        title = f"[{marker}] Fix process gap: {gap['class']}"[:180]
        existing = existing_bead(repo, marker, ledger)
        argv = [args.br_bin, "create", title, "--type", "task", "--priority", "P2", "--description", bead_description(gap, args.idempotency_key), "--json"]
        action = {"class": gap["class"], "marker": marker, "title": title, "br_argv": argv, "existing": existing}
        if existing:
            action["action"] = "existing"
        else:
            action["action"] = "create"
        planned.append(action)
    if not args.apply:
        return {"planned_actions": [], "actual_actions": [], "fix_beads_filed": [], "blocked_by": []}
    if args.dry_run:
        return {"planned_actions": planned, "actual_actions": [], "fix_beads_filed": [], "blocked_by": []}
    if not args.idempotency_key:
        return {"planned_actions": planned, "actual_actions": [], "fix_beads_filed": [], "blocked_by": ["missing_idempotency_key"]}
    state_dir.mkdir(parents=True, exist_ok=True)
    def is_beads_db_failure(stderr: str) -> bool:
        text = stderr.lower()
        return any(
            needle in text
            for needle in (
                "database disk image is malformed",
                "b-tree",
                "btree",
                "invalid b-tree page",
                "export_hashes",
                "sqlite",
            )
        )

    for action in planned:
        if action["existing"]:
            actual.append({**action, "applied": False, "reason": "deduped_existing_bead"})
            continue
        br_path = shutil.which(action["br_argv"][0]) or action["br_argv"][0]
        cmd = [br_path] + action["br_argv"][1:]
        proc = subprocess.run(cmd, cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        fallback_used = False
        fallback_cmd = None
        if proc.returncode != 0 and is_beads_db_failure(proc.stderr):
            fallback_cmd = [br_path, "--no-db"] + action["br_argv"][1:]
            proc = subprocess.run(fallback_cmd, cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
            fallback_used = True
        bead_id = None
        if proc.stdout.strip():
            try:
                data = json.loads(proc.stdout)
                bead_id = data.get("id") or (data.get("issue") or {}).get("id")
            except Exception:
                pass
        if proc.returncode == 0 and bead_id:
            filed.append(bead_id)
            row = {
                "ts": iso(datetime.now(timezone.utc)),
                "marker": action["marker"],
                "class": action["class"],
                "bead_id": bead_id,
                "title": action["title"],
                "idempotency_key": args.idempotency_key,
                "fallback_used": fallback_used,
            }
            with ledger.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(row, separators=(",", ":")) + "\n")
            actual.append({**action, "applied": True, "bead_id": bead_id, "fallback_used": fallback_used, "fallback_argv": fallback_cmd})
        else:
            blocked.append({"class": action["class"], "returncode": proc.returncode, "stderr": proc.stderr[-500:]})
            actual.append({**action, "applied": False, "returncode": proc.returncode, "fallback_used": fallback_used, "fallback_argv": fallback_cmd})
    return {"planned_actions": planned, "actual_actions": actual, "fix_beads_filed": filed, "blocked_by": blocked}


def build_payload(args):
    now = now_utc(args.now)
    gaps: dict[str, dict[str, Any]] = {}
    samples = doctor_samples(args)
    repeating_fuckups(args, gaps, now)
    sticky_doctor_errors(samples, gaps)
    doctrine_drift(args, gaps, now)
    doctor_field_gaps(samples, gaps, now)
    all_gaps = list(gaps.values())
    for gap in all_gaps:
        gap.pop("_first_seen_dt", None)
    all_gaps.sort(key=lambda item: (-SEVERITY_RANK.get(item["severity"], 0), -int(item["occurrences"]), item.get("first_seen") or ""))
    top_gaps = all_gaps[: args.max_gaps]
    high = sum(1 for gap in all_gaps if gap["severity"] == "high")
    medium = sum(1 for gap in all_gaps if gap["severity"] == "medium")
    low = sum(1 for gap in all_gaps if gap["severity"] == "low")
    score = max(0, min(100, 100 - high * 25 - medium * 12 - low * 5))
    stuck = sum(1 for gap in all_gaps if gap["severity"] == "high" or gap["occurrences"] >= 3)
    apply_result = apply_plan(args, top_gaps)
    return {
        "schema_version": SCHEMA_VERSION,
        "checked_at": iso(now),
        "open_gap_count": len(all_gaps),
        "top_gaps": top_gaps,
        "stuck_class_count": stuck,
        "process_health_score": score,
        "signals_implemented": [
            "repeating_fuckup_classes",
            "sticky_doctor_errors",
            "three_surface_drift",
            "unprocessed_promotion_candidates",
            "closed_bead_audit_gaps",
            "identity_drift",
            "watcher_coverage_holes",
        ],
        "signal_counts": {"high": high, "medium": medium, "low": low},
        "source_counts": {"doctor_samples": len(samples), "fleet_repos": len(fleet_repos(args))},
        **apply_result,
    }


def emit_info(json_out: bool):
    payload = {
        "schema_version": "canonical-cli-info/v1",
        "name": "fleet-process-gap-detector",
        "summary": "Aggregates recurring fleet failures into process-gap rows and optional fix-bead plans.",
        "doctor_fields": [
            "fleet_process_gap_detector",
            "fleet_process_open_gap_count",
            "fleet_process_stuck_class_count",
            "fleet_process_health_score",
            "fleet_process_top_gap_class",
        ],
        "canonical_flags": ["--info", "--examples", "--schema", "--json", "--apply", "--dry-run", "--idempotency-key"],
        "mutation": "--apply requires a stable class marker; actual br create requires --idempotency-key",
    }
    print(json.dumps(payload, separators=(",", ":")) if json_out else payload["summary"])


def emit_examples(json_out: bool):
    examples = [
        "fleet-process-gap-detector.sh --json",
        "fleet-process-gap-detector.sh --apply --dry-run --json",
        "fleet-process-gap-detector.sh --apply --idempotency-key process-gap-20260504 --json",
    ]
    payload = {"schema_version": SCHEMA_VERSION, "examples": examples}
    print(json.dumps(payload, separators=(",", ":")) if json_out else "\n".join(examples))


def emit_schema():
    print(json.dumps({
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "schema_version": SCHEMA_VERSION,
        "type": "object",
        "required": ["schema_version", "checked_at", "open_gap_count", "top_gaps", "stuck_class_count", "process_health_score"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "checked_at": {"type": "string"},
            "open_gap_count": {"type": "integer"},
            "stuck_class_count": {"type": "integer"},
            "process_health_score": {"type": "integer", "minimum": 0, "maximum": 100},
            "top_gaps": {"type": "array"},
        },
    }, separators=(",", ":")))


def main():
    parser = argparse.ArgumentParser(prog="fleet-process-gap-detector.sh")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--fuckup-log", default=str(DEFAULT_FUCKUP_LOG))
    parser.add_argument("--tick-dir", default=str(DEFAULT_TICK_DIR))
    parser.add_argument("--state-dir", default=str(DEFAULT_STATE_DIR))
    parser.add_argument("--now")
    parser.add_argument("--lookback-hours", type=int, default=24)
    parser.add_argument("--max-gaps", type=int, default=3)
    parser.add_argument("--fleet-root", action="append", default=[])
    parser.add_argument("--fleet-repo", action="append", default=[])
    parser.add_argument("--doctor-json", action="append", default=[])
    parser.add_argument("--br-bin", default="br")
    args = parser.parse_args()

    if args.info:
        emit_info(args.json)
        return
    if args.examples:
        emit_examples(args.json)
        return
    if args.schema:
        emit_schema()
        return
    payload = build_payload(args)
    if args.json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        top = payload["top_gaps"][0]["class"] if payload["top_gaps"] else "none"
        print(f"Fleet process: health={payload['process_health_score']} open-gaps={payload['open_gap_count']} top={top}")
    if payload.get("blocked_by"):
        sys.exit(1)


if __name__ == "__main__":
    main()
PY
