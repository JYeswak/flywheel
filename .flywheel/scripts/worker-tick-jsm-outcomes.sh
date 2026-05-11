#!/usr/bin/env bash
# worker-tick-jsm-outcomes.sh - bridge Phase B worker receipts into jsm outcome

set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.21)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# Coexistence design: python heredoc had no canonical surfaces at all
# (only --receipt / --receipt-dir / --jsm-bin / --apply / --dry-run /
# --online / --json operational flags). tests/test_worker_tick_jsm_outcomes.sh
# does NOT assert on --info/--schema/--examples — safe to add full
# canonical scaffold. Operational flags fall through to python verbatim.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="worker-tick-jsm-outcomes/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/worker-tick-jsm-outcomes-runs.jsonl}"
SCAFFOLD_DEFAULT_RECEIPT_DIR="${SCAFFOLD_DEFAULT_RECEIPT_DIR:-$HOME/.local/state}"
SCAFFOLD_JSM_BIN="${SCAFFOLD_JSM_BIN:-jsm}"

scaffold_usage() {
  cat <<'USG'
usage: worker-tick-jsm-outcomes.sh [SUBCOMMAND] [OPTIONS]

Default flag-form invocation routes to the python bridge which converts
Phase B worker tick receipts into jsm outcome events. --apply mutates
jsm state; --dry-run is default for safety.

Canonical CLI surfaces (intercepted before the python heredoc):
  doctor [--json]          probe substrate health (python3/jq/jsm/receipt-dir/ledger/root)
  health [--json]          last-run status (audit log tail + receipt scan count)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, receipt-dir-prime
  validate <subject> [...] subjects: row, schema, config, jsm-bin, receipts
  audit [--json]           recent run history (audit log tail)
  why <id>                 explain provenance (skill | session | pane | receipt-path)
  quickstart [--json]      operator orientation
  help <topic>             topic help
  completion <shell>       emit shell completion

Introspection:
  --info --json            AG3-compliant envelope
  --schema [<surface>]     JSON Schema for envelopes
  --examples --json        curated workflow examples
  --help / -h              this help

Operational flags (python — unchanged):
  --receipt PATH           Phase B worker tick receipt (repeatable)
  --receipt-dir PATH       directory to scan for receipts (repeatable)
  --jsm-bin PATH           jsm binary (default: jsm)
  --apply                  actually send jsm outcome events
  --dry-run                preview events without sending (default)
  --online                 do NOT pass --offline to jsm
  --json                   emit JSON envelope
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "worker-tick-jsm-outcomes.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "worker-tick-jsm-outcomes.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG,SCAFFOLD_DEFAULT_RECEIPT_DIR,SCAFFOLD_JSM_BIN" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"dry-run bridge",invocation:"worker-tick-jsm-outcomes.sh --receipt ~/.local/state/flywheel-worker-3/last_tick.json --dry-run --json",purpose:"preview jsm outcome events without sending"}'
)"$'\n'"$(jq -nc '{name:"apply bridge",invocation:"worker-tick-jsm-outcomes.sh --receipt-dir ~/.local/state --apply --json",purpose:"send jsm outcome events for all Phase B receipts in a directory"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"worker-tick-jsm-outcomes.sh doctor --json",purpose:"probe python3/jq/jsm/receipt-dir/ledger/root"}'
)"$'\n'"$(jq -nc '{name:"validate receipts",invocation:"worker-tick-jsm-outcomes.sh validate --receipts",purpose:"count receipts in default scan path"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"worker-tick-jsm-outcomes.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"see receipts available",command:"worker-tick-jsm-outcomes.sh validate --receipts"}'
)"$'\n'"$(jq -nc '{step:3,action:"dry-run bridge",command:"worker-tick-jsm-outcomes.sh --receipt-dir ~/.local/state --dry-run --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  [[ "$surface" == "--json" ]] && surface="default"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","receipt_dir_count"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","receipt-dir-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","receipt_dir?","receipt_count?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","jsm-bin","receipts"],fields:["status","subject","valid?","missing?","reason?","jsm_bin?","receipt_dir?","receipt_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"skill|session|pane|receipt-path"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["schema_version","mode","planned_count"],optional:["applied_count","drift_count","applied[]","planned[]"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"worker-tick-jsm-outcomes: bridges Phase B worker tick receipts into jsm outcome events; --apply mutates jsm state, --dry-run is default"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — python bridge; reads Phase B worker tick receipts (--receipt PATH or --receipt-dir PATH), extracts skill consultation evidence, emits jsm outcome events. --apply sends events; --dry-run is default. Validates skill names against ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$.\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: python3, jq, jsm bin executable, default receipt-dir present, ledger writable, flywheel root.\n' ;;
    health)   printf 'topic: health — tails audit log; counts receipts in default scan path for freshness.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), receipt-dir-prime (read-only — counts last_tick.json files in default scan paths).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON (bridge output schema), --schema, --config, --jsm-bin (probes jsm executable), --receipts (scans default dir for last_tick.json).\n' ;;
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
            && cli_emit_completion_bash "worker-tick-jsm-outcomes" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--receipt,--receipt-dir,--jsm-bin,--online" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "worker-tick-jsm-outcomes" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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

  if command -v "$SCAFFOLD_JSM_BIN" >/dev/null 2>&1 || [[ -x "$SCAFFOLD_JSM_BIN" ]]; then
    local jsm_path; jsm_path="$(command -v "$SCAFFOLD_JSM_BIN" 2>/dev/null || echo "$SCAFFOLD_JSM_BIN")"
    checks+="$(jq -nc --arg p "$jsm_path" '{name:"jsm_bin_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_JSM_BIN" '{name:"jsm_bin_on_path",status:"warn",value:$p,detail:"jsm invoked under --apply; warn if missing"}')"$'\n'
  fi

  local rd_present=false rd_count=0
  if [[ -d "$SCAFFOLD_DEFAULT_RECEIPT_DIR" ]]; then
    rd_present=true
    rd_count="$(find "$SCAFFOLD_DEFAULT_RECEIPT_DIR" -maxdepth 4 -name 'last_tick.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  fi
  local rd_status="pass"; [[ "$rd_present" != true ]] && rd_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_DEFAULT_RECEIPT_DIR" --arg s "$rd_status" --argjson present "$rd_present" --argjson count "${rd_count:-0}" \
    '{name:"receipt_dir_readable",status:$s,value:$p,present:$present,receipt_count:$count}')"$'\n'

  local ledger_dir; ledger_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$SCAFFOLD_AUDIT_LOG" ]] && row_count="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" --argjson rc "${row_count:-0}" '{name:"ledger_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_AUDIT_LOG" '{name:"ledger_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
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
  local receipt_count=0
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
  fi
  [[ -d "$SCAFFOLD_DEFAULT_RECEIPT_DIR" ]] && receipt_count="$(find "$SCAFFOLD_DEFAULT_RECEIPT_DIR" -maxdepth 4 -name 'last_tick.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson rc "${receipt_count:-0}" --arg rd "$SCAFFOLD_DEFAULT_RECEIPT_DIR" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,receipt_dir:$rd,receipt_count:$rc}'
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
    receipt-dir-prime)
      local present=false receipt_count=0
      if [[ -d "$SCAFFOLD_DEFAULT_RECEIPT_DIR" ]]; then
        present=true
        receipt_count="$(find "$SCAFFOLD_DEFAULT_RECEIPT_DIR" -maxdepth 4 -name 'last_tick.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg rd "$SCAFFOLD_DEFAULT_RECEIPT_DIR" --arg s "$status" \
        --argjson present "$present" --argjson rc "${receipt_count:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,receipt_dir:$rd,present:$present,receipt_count:$rc,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","receipt-dir-prime"]}'
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
      --jsm-bin) subject="jsm-bin"; shift ;;
      --receipts) subject="receipts"; shift ;;
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
      # Bridge output row schema (mode + planned_count are always emitted).
      for f in schema_version mode planned_count; do
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
      local py_ok=false jq_ok=false jsm_ok=false rd_ok=false ledger_dir_ok=false root_ok=false
      command -v python3 >/dev/null 2>&1 && py_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      if command -v "$SCAFFOLD_JSM_BIN" >/dev/null 2>&1 || [[ -x "$SCAFFOLD_JSM_BIN" ]]; then jsm_ok=true; fi
      [[ -d "$SCAFFOLD_DEFAULT_RECEIPT_DIR" ]] && rd_ok=true
      [[ -d "$(dirname "$SCAFFOLD_AUDIT_LOG")" ]] && ledger_dir_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$py_ok" != true || "$jq_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson py "$py_ok" --argjson jqq "$jq_ok" --argjson jsm "$jsm_ok" \
        --argjson rd "$rd_ok" --argjson ld "$ledger_dir_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg rd_p "$SCAFFOLD_DEFAULT_RECEIPT_DIR" --arg jsm_p "$SCAFFOLD_JSM_BIN" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,python3_present:$py,jq_present:$jqq,jsm_bin_present:$jsm,receipt_dir_present:$rd,ledger_dir_present:$ld,flywheel_root_present:$rt,flywheel_root:$root,receipt_dir:$rd_p,jsm_bin:$jsm_p}'
      ;;
    jsm-bin)
      local jsm_path="" jsm_present=false
      if command -v "$SCAFFOLD_JSM_BIN" >/dev/null 2>&1; then
        jsm_path="$(command -v "$SCAFFOLD_JSM_BIN")"
        jsm_present=true
      elif [[ -x "$SCAFFOLD_JSM_BIN" ]]; then
        jsm_path="$SCAFFOLD_JSM_BIN"
        jsm_present=true
      fi
      local status="pass"
      [[ "$jsm_present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg jsm "$SCAFFOLD_JSM_BIN" --arg jsm_p "$jsm_path" \
        --argjson present "$jsm_present" \
        '{schema_version:$sv,command:"validate",subject:"jsm-bin",status:$s,jsm_bin:$jsm,resolved_path:$jsm_p,present:$present}'
      ;;
    receipts)
      local present=false receipt_count=0 sample_json="[]"
      if [[ -d "$SCAFFOLD_DEFAULT_RECEIPT_DIR" ]]; then
        present=true
        receipt_count="$(find "$SCAFFOLD_DEFAULT_RECEIPT_DIR" -maxdepth 4 -name 'last_tick.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
        sample_json="$(find "$SCAFFOLD_DEFAULT_RECEIPT_DIR" -maxdepth 4 -name 'last_tick.json' 2>/dev/null | head -5 | jq -R . | jq -sc '.' 2>/dev/null || echo '[]')"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg rd "$SCAFFOLD_DEFAULT_RECEIPT_DIR" \
        --argjson present "$present" --argjson rc "${receipt_count:-0}" --argjson sample "$sample_json" \
        '{schema_version:$sv,command:"validate",subject:"receipts",status:$s,receipt_dir:$rd,present:$present,receipt_count:$rc,sample_paths:$sample}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","jsm-bin","receipts"],usage:"validate --row-json JSON or --schema or --config or --jsm-bin or --receipts"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","jsm-bin","receipts"]}'
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
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)
      shift
      local _surface="${1:-default}"
      [[ "$_surface" == "--json" ]] && _surface="default"
      scaffold_emit_schema "$_surface"; exit 0 ;;
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
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

SKILL_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")


def read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("receipt_not_object")
    return value


def compact(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, str):
        return [part.strip() for part in value.split(",") if part.strip()]
    return [value]


def receipt_paths(args: argparse.Namespace) -> list[Path]:
    paths: list[Path] = [Path(item).expanduser() for item in args.receipt]
    for root in args.receipt_dir:
        root_path = Path(root).expanduser()
        if root_path.is_file():
            paths.append(root_path)
        elif root_path.exists():
            paths.extend(sorted(root_path.rglob("last_tick.json")))
            paths.extend(sorted(path for path in root_path.rglob("*.json") if path.name != "last_tick.json"))
    seen: set[str] = set()
    unique: list[Path] = []
    for path in paths:
        key = str(path.resolve())
        if key not in seen:
            seen.add(key)
            unique.append(path)
    return unique


def phase_b_valid(receipt: dict[str, Any]) -> bool:
    return (
        receipt.get("schema_version") == "flywheel-worker-tick/v1"
        and receipt.get("mode") == "worker-mode"
        and receipt.get("harness") in {"claude", "codex", "gemini", "unknown"}
        and isinstance(receipt.get("check_results"), list)
    )


def skills_from_receipt(receipt: dict[str, Any]) -> list[str]:
    raw: list[Any] = []
    raw.extend(as_list(receipt.get("skills_used")))
    raw.extend(as_list(receipt.get("skills_consulted")))
    raw.extend(as_list(receipt.get("skill_consultations")))
    for row in receipt.get("check_results") or []:
        if not isinstance(row, dict):
            continue
        if row.get("id") != "skill-tool-call-presence":
            continue
        observed = row.get("observed") if isinstance(row.get("observed"), dict) else {}
        raw.extend(as_list(observed.get("skills_consulted")))
        raw.extend(as_list(observed.get("skill_consultations")))
    skills: list[str] = []
    for item in raw:
        skill = str(item).strip()
        if not skill or skill == "NONE_FOUND":
            continue
        if skill not in skills:
            skills.append(skill)
    return skills


def event_for(path: Path, receipt: dict[str, Any], skill: str) -> dict[str, Any]:
    success = receipt.get("status") in {"ok", "pass", "passed", True}
    context = {
        "schema_version": "worker-tick-jsm-context/v1",
        "source": "worker_tick",
        "harness": receipt.get("harness"),
        "session": receipt.get("session"),
        "pane": receipt.get("pane"),
        "task_id": receipt.get("task_id"),
        "bead": receipt.get("task_id"),
        "repo": receipt.get("repo"),
        "receipt_path": str(path),
        "worker_tick_status": receipt.get("status"),
        "violations": receipt.get("violations") or [],
    }
    return {
        "skill": skill,
        "success": bool(success),
        "harness": receipt.get("harness"),
        "task_id": receipt.get("task_id"),
        "receipt_path": str(path),
        "context": context,
    }


def command_for(jsm_bin: str, event: dict[str, Any], offline: bool) -> list[str]:
    cmd = [
        jsm_bin,
        "outcome",
        "-s",
        event["skill"],
        "--success" if event["success"] else "--failure",
        "--duration",
        "0",
        "--context",
        compact(event["context"]),
        "--json",
    ]
    if offline:
        cmd.append("--offline")
    return cmd


def drift_candidates(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_skill: dict[str, dict[str, set[bool]]] = {}
    for event in events:
        harness = str(event.get("harness") or "unknown")
        by_skill.setdefault(event["skill"], {}).setdefault(harness, set()).add(bool(event["success"]))
    candidates: list[dict[str, Any]] = []
    for skill, by_harness in sorted(by_skill.items()):
        success_harnesses = sorted(h for h, outcomes in by_harness.items() if True in outcomes)
        failure_harnesses = sorted(h for h, outcomes in by_harness.items() if False in outcomes)
        if success_harnesses and failure_harnesses and set(success_harnesses) != set(failure_harnesses):
            candidates.append(
                {
                    "skill": skill,
                    "class": "harness_partitioned_drift_candidate",
                    "success_harnesses": success_harnesses,
                    "failure_harnesses": failure_harnesses,
                    "by_harness": {h: sorted(outcomes) for h, outcomes in sorted(by_harness.items())},
                }
            )
    return candidates


parser = argparse.ArgumentParser(description="Bridge worker tick receipts into jsm outcome events")
parser.add_argument("--receipt", action="append", default=[], help="Worker tick receipt path")
parser.add_argument("--receipt-dir", action="append", default=[], help="Directory to replay worker tick receipts from")
parser.add_argument("--jsm-bin", default="jsm")
parser.add_argument("--apply", action="store_true")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--online", action="store_true", help="Do not pass --offline to jsm")
parser.add_argument("--json", action="store_true")
args = parser.parse_args()

if not args.receipt and not args.receipt_dir:
    parser.error("at least one --receipt or --receipt-dir is required")

mode = "apply" if args.apply else "dry-run"
paths = receipt_paths(args)
events: list[dict[str, Any]] = []
validation_errors: list[dict[str, Any]] = []
phase_b_validated = 0

for path in paths:
    try:
        receipt = read_json(path)
    except Exception as exc:
        validation_errors.append({"receipt_path": str(path), "reason": "receipt_unreadable", "detail": str(exc)})
        continue
    if not phase_b_valid(receipt):
        validation_errors.append({"receipt_path": str(path), "reason": "phase_b_receipt_invalid"})
        continue
    phase_b_validated += 1
    for skill in skills_from_receipt(receipt):
        if not SKILL_RE.match(skill):
            validation_errors.append({"receipt_path": str(path), "reason": "invalid_skill_name", "skill": skill})
            continue
        events.append(event_for(path, receipt, skill))

commands = [command_for(args.jsm_bin, event, offline=not args.online) for event in events]
applied: list[dict[str, Any]] = []

if args.apply:
    for event, cmd in zip(events, commands):
        proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        applied.append(
            {
                "skill": event["skill"],
                "harness": event["harness"],
                "success": event["success"],
                "exit_code": proc.returncode,
                "stdout": proc.stdout.strip(),
                "stderr": proc.stderr.strip(),
            }
        )

receipt = {
    "schema_version": "worker-tick-jsm-outcomes/v1",
    "mode": mode,
    "jsm_schema_probe": {
        "command": "jsm outcome --help",
        "captured_before_implementation": True,
        "uses_context_for_harness": True,
    },
    "receipts_seen": len(paths),
    "phase_b_receipts_validated": phase_b_validated,
    "events_count": len(events),
    "planned_events": events,
    "planned_commands": commands,
    "validation_errors": validation_errors,
    "harness_drift_candidates": drift_candidates(events),
    "applied_count": len(applied),
    "applied": applied,
}

if args.json:
    print(json.dumps(receipt, sort_keys=True))
else:
    print(f"worker-tick-jsm-outcomes mode={mode} receipts={len(paths)} events={len(events)} validation_errors={len(validation_errors)}")

if any(item.get("exit_code", 0) != 0 for item in applied):
    sys.exit(1)
PY
