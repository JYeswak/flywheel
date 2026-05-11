#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.20)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# Coexistence design: python heredoc has a stub --info (primitive_invoked
# + refusal_reasons) and no other canonical surfaces. tests/topology-tick-refresh.sh
# does NOT assert on --info, so we override --info with AG3 envelope.
# Bash adds full canonical surfaces (doctor/health/repair/validate/audit/
# why/quickstart/completion/help). All operational flags (--topology,
# --ntm-bin, --ledger, --apply, --json, --lock, --now, --fresh-max-age-sec)
# fall through to python verbatim.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="topology-tick-refresh/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/topology-tick-refresh.jsonl}"
SCAFFOLD_TOPOLOGY="${SCAFFOLD_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
SCAFFOLD_NTM_BIN="${SCAFFOLD_NTM_BIN:-/Users/josh/.local/bin/ntm}"

scaffold_usage() {
  cat <<'USG'
usage: topology-tick-refresh.sh [SUBCOMMAND] [OPTIONS]

Default flag-form invocation routes to the python refresh logic which
refreshes session-topology.jsonl freshness when live NTM shape is
unchanged. --apply mutates topology; --dry-run is default for safety.

Canonical CLI surfaces (intercepted before the python heredoc):
  doctor [--json]          probe substrate health
  health [--json]          last-run status (ledger tail + topology freshness)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, topology-prime
  validate <subject> [...] subjects: row, schema, config, topology, ledger
  audit [--json]           recent run history (ledger tail)
  why <id>                 explain provenance (run_id|refusal_reason|session)
  quickstart [--json]      operator orientation
  help <topic>             topic help
  completion <shell>       emit shell completion

Introspection:
  --info --json            AG3-compliant envelope (replaces python stub)
  --schema [<surface>]     JSON Schema for envelopes
  --examples --json        curated workflow examples
  --help / -h              this help

Operational flags (python — unchanged):
  --topology PATH | --ntm-bin PATH | --ledger PATH | --lock PATH
  --now ISO | --fresh-max-age-sec N | --apply | --json
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "topology-tick-refresh.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "topology-tick-refresh.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG,SCAFFOLD_TOPOLOGY,SCAFFOLD_NTM_BIN" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default dry-run refresh",invocation:"topology-tick-refresh.sh --json",purpose:"check if topology needs refresh (no mutation)"}'
)"$'\n'"$(jq -nc '{name:"apply refresh",invocation:"topology-tick-refresh.sh --apply --json",purpose:"refresh topology jsonl freshness when shape unchanged"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"topology-tick-refresh.sh doctor --json",purpose:"probe python3/jq/ntm/topology/ledger/root"}'
)"$'\n'"$(jq -nc '{name:"validate topology",invocation:"topology-tick-refresh.sh validate --topology",purpose:"probe session-topology.jsonl row count + freshness"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"topology-tick-refresh.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"check freshness",command:"topology-tick-refresh.sh validate --topology"}'
)"$'\n'"$(jq -nc '{step:3,action:"apply refresh",command:"topology-tick-refresh.sh --apply --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","topology_row_count","refresh_count","refusal_count"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","topology-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","topology?","row_count?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","topology","ledger"],fields:["status","subject","valid?","missing?","reason?","topology?","ledger?","row_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"run_id|refusal_reason|session"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["schema_version","ts","status","run_id"],optional:["refusal_reason","topology_shape_hash","max_age_sec_before","max_age_sec_after"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"topology-tick-refresh: refreshes session-topology.jsonl freshness when live NTM shape is unchanged"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — python refresh logic; reads --topology jsonl, queries live ntm panes for current shape, hashes both, refreshes topology row ts if shape matches. --apply mutates; --dry-run is default. 7 refusal classes track shape drift.\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: python3, jq, ntm bin executable, topology readable, ledger writable, flywheel root.\n' ;;
    health)   printf 'topic: health — tails ledger; counts refresh vs refusal rows + topology row freshness.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), topology-prime (read-only — probes session-topology.jsonl shape).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --topology, --ledger.\n' ;;
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
            && cli_emit_completion_bash "topology-tick-refresh" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--topology,--ntm-bin,--ledger,--lock,--now,--fresh-max-age-sec" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "topology-tick-refresh" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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

  if [[ -x "$SCAFFOLD_NTM_BIN" ]]; then
    checks+="$(jq -nc --arg p "$SCAFFOLD_NTM_BIN" '{name:"ntm_bin_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_NTM_BIN" '{name:"ntm_bin_executable",status:"fail",value:$p,detail:"required to probe live pane shape"}')"$'\n'
    overall="fail"
  fi

  local topo_present=false topo_rows=0
  if [[ -r "$SCAFFOLD_TOPOLOGY" ]]; then
    topo_present=true
    topo_rows="$(wc -l < "$SCAFFOLD_TOPOLOGY" 2>/dev/null | tr -d ' ' || echo 0)"
  fi
  local topo_status="pass"; [[ "$topo_present" != true ]] && topo_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_TOPOLOGY" --arg s "$topo_status" --argjson present "$topo_present" --argjson rows "${topo_rows:-0}" \
    '{name:"topology_readable",status:$s,value:$p,present:$present,row_count:$rows}')"$'\n'

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
  local topology_rows=0 refresh_count=0 refusal_count=0
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
    refresh_count="$(grep -c '"status":"refreshed"' "$log" 2>/dev/null; true)"
    refusal_count="$(grep -c '"status":"refused"' "$log" 2>/dev/null; true)"
  fi
  [[ -r "$SCAFFOLD_TOPOLOGY" ]] && topology_rows="$(wc -l < "$SCAFFOLD_TOPOLOGY" 2>/dev/null | tr -d ' ' || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson tr "${topology_rows:-0}" --argjson rc "${refresh_count:-0}" --argjson rfc "${refusal_count:-0}" \
    --arg topo "$SCAFFOLD_TOPOLOGY" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,topology:$topo,topology_row_count:$tr,refresh_count:$rc,refusal_count:$rfc}'
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
    topology-prime)
      local present=false rows=0 size_bytes=0
      if [[ -r "$SCAFFOLD_TOPOLOGY" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_TOPOLOGY" 2>/dev/null | tr -d ' ' || echo 0)"
        size_bytes="$(stat -f '%z' "$SCAFFOLD_TOPOLOGY" 2>/dev/null || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg topo "$SCAFFOLD_TOPOLOGY" --arg s "$status" \
        --argjson present "$present" --argjson rows "${rows:-0}" --argjson sz "${size_bytes:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,topology:$topo,present:$present,row_count:$rows,size_bytes:$sz,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","topology-prime"]}'
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
      --topology) subject="topology"; shift ;;
      --ledger) subject="ledger"; shift ;;
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
      for f in schema_version ts status run_id; do
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
      local py_ok=false jq_ok=false ntm_ok=false topo_ok=false ledger_dir_ok=false root_ok=false
      command -v python3 >/dev/null 2>&1 && py_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -x "$SCAFFOLD_NTM_BIN" ]] && ntm_ok=true
      [[ -r "$SCAFFOLD_TOPOLOGY" ]] && topo_ok=true
      [[ -d "$(dirname "$SCAFFOLD_AUDIT_LOG")" ]] && ledger_dir_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$py_ok" != true || "$jq_ok" != true || "$ntm_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson py "$py_ok" --argjson jqq "$jq_ok" --argjson ntm "$ntm_ok" \
        --argjson topo "$topo_ok" --argjson ld "$ledger_dir_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg topo_p "$SCAFFOLD_TOPOLOGY" --arg ledger "$SCAFFOLD_AUDIT_LOG" --arg ntm_p "$SCAFFOLD_NTM_BIN" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,python3_present:$py,jq_present:$jqq,ntm_bin_present:$ntm,topology_readable:$topo,ledger_dir_present:$ld,flywheel_root_present:$rt,flywheel_root:$root,topology:$topo_p,ledger:$ledger,ntm_bin:$ntm_p}'
      ;;
    topology)
      local present=false rows=0 last_row=null last_row_valid=false
      if [[ -r "$SCAFFOLD_TOPOLOGY" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_TOPOLOGY" 2>/dev/null | tr -d ' ' || echo 0)"
        local raw; raw="$(tail -n 1 "$SCAFFOLD_TOPOLOGY" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          if printf '%s' "$raw" | jq -e 'has("session")' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg topo "$SCAFFOLD_TOPOLOGY" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"topology",status:$s,topology:$topo,present:$present,row_count:$rows,last_row:$lr,last_row_valid:$lrv}'
      ;;
    ledger)
      local present=false rows=0 last_row=null last_row_valid=false
      local refresh_count=0 refusal_count=0
      if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
        present=true
        rows="$(wc -l < "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        refresh_count="$(grep -c '"status":"refreshed"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        refusal_count="$(grep -c '"status":"refused"' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null; true)"
        local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          if printf '%s' "$raw" | jq -e 'has("schema_version") and has("ts") and has("status") and has("run_id")' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg ledger "$SCAFFOLD_AUDIT_LOG" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson rc "${refresh_count:-0}" --argjson rfc "${refusal_count:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"ledger",status:$s,ledger:$ledger,present:$present,row_count:$rows,refresh_count:$rc,refusal_count:$rfc,last_row:$lr,last_row_valid:$lrv}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","topology","ledger"],usage:"validate --row-json JSON or --schema or --config or --topology or --ledger"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","topology","ledger"]}'
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
import argparse, fcntl, hashlib, json, os, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA="topology-tick-refresh.result.v1"
LEDGER_SCHEMA="topology-tick-refresh.ledger.v1"
REFUSALS=["extra_agent_pane","malformed_topology_row","missing_live_session","no_topology_row","pane_count_changed","worker_kind_changed","worker_pane_missing"]

def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00","Z")

def parse_ts(value):
    if not value: return None
    try: return datetime.fromisoformat(str(value).replace("Z","+00:00"))
    except ValueError: return None

def age(now_dt, value):
    parsed=parse_ts(value)
    return None if parsed is None else max(0, int((now_dt-parsed).total_seconds()))

def emit(payload, json_mode, rc):
    print(json.dumps(payload, sort_keys=True, separators=(",",":")) if json_mode else f"topology-tick-refresh status={payload.get('status')}")
    raise SystemExit(rc)

def append_jsonl(path, row):
    if not isinstance(row, dict): raise ValueError("row_not_object")
    target=Path(path).expanduser(); target.parent.mkdir(parents=True, exist_ok=True)
    with target.with_suffix(target.suffix+".lock").open("a+") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        data=json.dumps(row, sort_keys=True, separators=(",",":"))+"\n"
        with target.open("a", encoding="utf-8") as handle:
            handle.write(data); handle.flush(); os.fsync(handle.fileno())

def read_latest(path):
    latest={}
    if not Path(path).exists(): return latest
    for line_no,line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(),1):
        if not line.strip(): continue
        try: row=json.loads(line)
        except json.JSONDecodeError as exc: raise ValueError(f"malformed_topology_row line={line_no} {exc}") from exc
        ts=row.get("effective_at") or row.get("ts") if isinstance(row,dict) else None
        if not isinstance(row,dict) or not row.get("session") or not parse_ts(ts): raise ValueError(f"malformed_topology_row line={line_no}")
        session=str(row["session"]); previous=latest.get(session)
        if previous is None or str(ts)>str(previous.get("effective_at") or previous.get("ts")): latest[session]=row
    return latest

def run_ntm(ntm,args):
    proc=subprocess.run([ntm,*args], text=True, capture_output=True)
    if proc.returncode!=0: raise RuntimeError((proc.stderr or proc.stdout or f"ntm rc={proc.returncode}")[-500:])
    return json.loads(proc.stdout or "{}")

def live_sessions(ntm):
    payload=run_ntm(ntm,["list","--json"]); sessions=payload if isinstance(payload,list) else payload.get("sessions",[])
    return {str(i.get("name") or i.get("session")):i for i in sessions if isinstance(i,dict) and (i.get("name") or i.get("session"))}

def kind(value):
    low=str(value or "unknown").lower()
    return {"cc":"claude","cod":"codex"}.get(low,low)

def activity(ntm, session):
    payload=run_ntm(ntm,[f"--robot-activity={session}"]); agents=payload if isinstance(payload,list) else payload.get("agents",[])
    out={}
    for agent in agents or []:
        pane=agent.get("pane_idx", agent.get("pane"))
        if pane is not None: out[str(pane)]=kind(agent.get("agent_type") or agent.get("type"))
    return out

def panes(values):
    return {str(v) for v in (values or []) if v is not None}

def shape_hash(row, live, agents):
    payload={"session":row.get("session"),"expected_pane_count":row.get("expected_pane_count"),"orchestrator_pane":row.get("orchestrator_pane"),"callback_pane":row.get("callback_pane"),"human_pane":row.get("human_pane"),"shell_panes":sorted(panes(row.get("shell_panes"))),"worker_panes":sorted(panes(row.get("worker_panes"))),"worker_kinds":row.get("worker_kinds") or {},"live_pane_count":live.get("pane_count"),"live_agents":agents}
    return hashlib.sha256(json.dumps(payload,sort_keys=True,separators=(",",":")).encode()).hexdigest()

def compare(row, live, agents):
    expected=row.get("expected_pane_count")
    if expected is not None:
        actual=len(agents) if row.get("pane_count_semantics")=="agent_panes_excludes_user_pane0" else live.get("pane_count")
        if actual is not None and int(actual)!=int(expected): return False,"pane_count_changed"
    workers=panes(row.get("worker_panes")); kinds={str(k):kind(v) for k,v in (row.get("worker_kinds") or {}).items()}
    for pane in sorted(workers, key=int):
        if pane not in agents: return False,"worker_pane_missing"
        if kinds.get(pane) and agents[pane]!=kinds[pane]: return False,"worker_kind_changed"
    protected=panes([row.get("orchestrator_pane"),row.get("callback_pane"),row.get("human_pane")]) | panes(row.get("shell_panes"))
    return (False,"extra_agent_pane") if [p for p in agents if p not in (workers|protected)] else (True,None)

def ledger(base, sessions, status, reason, extra=None):
    row=dict(base); row.update(extra or {})
    row.update({"schema_version":LEDGER_SCHEMA,"event":"topology_tick_refresh_fire","status":status,"refusal_reason":reason,"session_statuses":sessions})
    return row

def main():
    parser=argparse.ArgumentParser(description="Refresh session topology freshness when live NTM shape is unchanged.")
    parser.add_argument("--topology",default=str(Path.home()/".local/state/flywheel/session-topology.jsonl"))
    parser.add_argument("--ntm-bin",default="/Users/josh/.local/bin/ntm")
    parser.add_argument("--ledger",default=str(Path.home()/".local/state/flywheel/topology-tick-refresh.jsonl"))
    parser.add_argument("--lock",default=""); parser.add_argument("--now",default="")
    parser.add_argument("--fresh-max-age-sec",type=int,default=300)
    parser.add_argument("--apply",action="store_true"); parser.add_argument("--json",action="store_true"); parser.add_argument("--info",action="store_true")
    args=parser.parse_args()
    if args.info: emit({"schema_version":SCHEMA,"primitive_invoked":"topology-tick-refresh","refusal_reasons":REFUSALS},args.json,0)
    stamp=args.now or now_iso(); now_dt=parse_ts(stamp); run_id=hashlib.sha256(f"{stamp}:{os.getpid()}:{time.time_ns()}".encode()).hexdigest()[:24]
    topology=str(Path(args.topology).expanduser()); lock_path=args.lock or f"{topology}.topology-refresh.lock"
    base={"run_id":run_id,"invocation_id":run_id,"ts":stamp,"primitive_invoked":"topology-tick-refresh","topology_path":topology,"source_path":".flywheel/scripts/topology-tick-refresh.sh","profile":"default","idempotency_key":f"topology-tick-refresh:{run_id}","lock_path":lock_path,"ledger_path":str(Path(args.ledger).expanduser()),"apply":args.apply,"dry_run":not args.apply,"timeout_sec":None}
    lock_file=Path(lock_path).expanduser(); lock_file.parent.mkdir(parents=True, exist_ok=True)
    with lock_file.open("a+") as lock:
        try: fcntl.flock(lock.fileno(), fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            append_jsonl(args.ledger, ledger(base, [], "lock_held", "lock_held"))
            emit(dict(base, schema_version=SCHEMA, status="lock_held", refreshed_count=0, refused_count=0, max_age_sec_before=None, max_age_sec_after=None, topology_shape_hash=None, post_check={"ledger_row_written":True,"topology_rows_appended":0}), args.json, 1)
        sessions=[]; appended=refreshed=refused=already=skipped=0; hashes=[]; reason=None
        try:
            latest=read_latest(topology); live=live_sessions(args.ntm_bin)
        except Exception as exc:
            status="malformed"; reason="malformed_topology_row"; sessions.append({"session":None,"status":status,"refusal_reason":reason,"error":str(exc)})
        else:
            for session,row in sorted(latest.items()):
                row_age=age(now_dt,row.get("effective_at") or row.get("ts"))
                if session not in live:
                    sessions.append({"session":session,"status":"refused","refusal_reason":"missing_live_session","age_sec_before":row_age}); refused+=1; continue
                agents=activity(args.ntm_bin,session); ok,bad=compare(row,live[session],agents); h=shape_hash(row,live[session],agents); hashes.append(h)
                if not ok:
                    sessions.append({"session":session,"status":"refused","refusal_reason":bad,"topology_shape_hash":h,"age_sec_before":row_age}); refused+=1; continue
                if row_age is not None and row_age<=args.fresh_max_age_sec:
                    sessions.append({"session":session,"status":"already_fresh","topology_shape_hash":h,"age_sec_before":row_age,"age_sec_after":row_age}); already+=1; continue
                if not args.apply:
                    sessions.append({"session":session,"status":"skipped","refusal_reason":"dry_run","topology_shape_hash":h,"age_sec_before":row_age}); skipped+=1; continue
                new_row=dict(row,effective_at=stamp,registered_by="topology-tick-refresh",refresh_of_effective_at=row.get("effective_at") or row.get("ts"),refresh_reason="pure_freshness",topology_shape_hash=h,run_id=run_id)
                append_jsonl(topology,new_row); appended+=1; refreshed+=1
                sessions.append({"session":session,"status":"refreshed","topology_shape_hash":h,"age_sec_before":row_age,"age_sec_after":0})
            for session in sorted(set(live)-set(latest)):
                sessions.append({"session":session,"status":"refused","refusal_reason":"no_topology_row"}); refused+=1
            status="refreshed" if refreshed else "refused" if refused else "already_fresh" if already else "skipped"
            reason=next((s.get("refusal_reason") for s in sessions if s.get("refusal_reason") and s.get("refusal_reason")!="dry_run"),None)
        before=[s.get("age_sec_before") for s in sessions if isinstance(s.get("age_sec_before"),int)]
        after=[s.get("age_sec_after",s.get("age_sec_before")) for s in sessions if isinstance(s.get("age_sec_after",s.get("age_sec_before")),int)]
        overall=hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest() if hashes else None
        result=dict(base,schema_version=SCHEMA,status=status,refreshed_count=refreshed,refused_count=refused,already_fresh_count=already,skipped_count=skipped,max_age_sec_before=max(before) if before else None,max_age_sec_after=max(after) if after else None,topology_shape_hash=overall,refusal_reason=reason,sessions=sessions,post_check={"ledger_row_written":False,"topology_rows_appended":appended})
        append_jsonl(args.ledger, ledger(base, sessions, status, reason, {"topology_shape_hash":overall,"max_age_sec_before":result["max_age_sec_before"],"max_age_sec_after":result["max_age_sec_after"]}))
        result["post_check"]["ledger_row_written"]=True
        emit(result,args.json,0 if status in {"refreshed","already_fresh","skipped"} else 2)

if __name__=="__main__":
    main()
PY
