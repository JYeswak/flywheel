#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.14)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# Coexistence design (mirrors flywheel-5ke66.{9,12}): python heredoc
# already exposes --info / --examples / --schema asserted by
# tests/orch-worker-identity-manifest.sh. Bash early-dispatch intercepts
# those with HAND-ROLLED hybrid envelopes preserving:
#   --info       — .dry_run_supported, .apply_supported, .no_raw_tokens (all true)
#   --schema     — .properties.workers.type=="array",
#                  .properties.schema_version.const=="orch-worker-identity/v1"
#   --examples   — .examples | length >= 3

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="orch-worker-identity-manifest/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/orch-worker-identity-manifest-runs.jsonl}"
SCAFFOLD_OUT_DIR="${SCAFFOLD_OUT_DIR:-$HOME/.local/state/flywheel/orch-worker-identity}"
SCAFFOLD_LOOP_DIR="${SCAFFOLD_LOOP_DIR:-$HOME/.flywheel/loops}"
SCAFFOLD_TOPOLOGY="${SCAFFOLD_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
SCAFFOLD_AGENT_MAIL_DIR="${SCAFFOLD_AGENT_MAIL_DIR:-$HOME/.local/state/flywheel/agent-mail}"

scaffold_usage() {
  cat <<'USG'
usage: orch-worker-identity-manifest.sh [SUBCOMMAND] [OPTIONS]

Default flag-form invocation routes to the python manifest builder.
Canonical subcommands (doctor / health / repair / validate / audit / why)
intercept BEFORE python; introspection flags (--info / --schema /
--examples) are hybrid envelopes preserving python-shape fields for
existing tests/orch-worker-identity-manifest.sh assertions.

Canonical CLI surfaces (intercepted before the python heredoc):
  doctor [--json]          probe substrate health
  health [--json]          last-run status (manifest count + topology rows)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, out-dir-prime
  validate <subject> [...] subjects: row, schema, config, topology, manifests
  audit [--json]           recent run history (audit log tail)
  why <id>                 explain provenance (session/pane/identity)
  quickstart [--json]      operator orientation
  help <topic>             topic help
  completion <shell>       emit shell completion

Introspection (backward-compat shape preserved):
  --info --json            keeps .dry_run_supported/.apply_supported/.no_raw_tokens
                           + .idempotency_key + .summary + .name; adds AG3
                           .version + .subcommands
  --schema [<surface>]     default preserves JSON-Schema with
                           .properties.workers.type="array"
  --examples --json        3 backward-compat invocations + 2 new canonical
  --help / -h              this help
USG
}

scaffold_emit_info() {
  local sha; sha="$(cli_sha_self "${BASH_SOURCE[0]}" 2>/dev/null || echo)"
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg name "orch-worker-identity-manifest" \
    --arg version "scaffolded-v0" \
    --arg sha "$sha" \
    --arg out_dir "$SCAFFOLD_OUT_DIR" \
    '{
      schema_version: $sv,
      command: "info",
      name: $name,
      version: $version,
      sha256: $sha,
      summary: "Builds derived per-orchestrator worker identity manifests from live loop markers, session topology, and Agent Mail identity rows.",
      apply_supported: true,
      dry_run_supported: true,
      no_raw_tokens: true,
      idempotency_key: "session",
      subcommands: ["doctor","health","repair","validate","audit","why","quickstart","help","completion"],
      canonical_flags: ["--info","--examples","--schema","--json","--apply","--dry-run","--fleet","--session"],
      canonical_cli_surfaces: ["doctor","health","repair","validate","audit","why","quickstart","help","completion","--info","--schema","--examples","--json","--apply","--dry-run","--fleet","--session"],
      env_vars: ["SCAFFOLD_AUDIT_LOG","SCAFFOLD_OUT_DIR","SCAFFOLD_LOOP_DIR","SCAFFOLD_TOPOLOGY","SCAFFOLD_AGENT_MAIL_DIR"],
      dependencies: ["bash","python3","jq","date","shasum"],
      out_dir: $out_dir
    }'
}

scaffold_emit_examples() {
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{
      schema_version: $sv,
      command: "examples",
      examples: [
        ".flywheel/scripts/orch-worker-identity-manifest.sh --fleet --dry-run --json",
        ".flywheel/scripts/orch-worker-identity-manifest.sh --session flywheel --apply --json",
        "jq '\''.workers[] | select(.pane == 2)'\'' ~/.local/state/flywheel/orch-worker-identity/flywheel.json",
        ".flywheel/scripts/orch-worker-identity-manifest.sh doctor --json",
        ".flywheel/scripts/orch-worker-identity-manifest.sh validate --manifests"
      ]
    }'
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"orch-worker-identity-manifest.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"see fleet topology + manifests",command:"orch-worker-identity-manifest.sh validate --manifests"}'
)"$'\n'"$(jq -nc '{step:3,action:"dry-run fleet manifest build",command:"orch-worker-identity-manifest.sh --fleet --dry-run --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","manifest_count","topology_row_count"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","out-dir-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","out_dir?","manifest_count?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","topology","manifests"],fields:["status","subject","valid?","missing?","reason?","topology?","out_dir?","row_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"session|pane|fleet_mail_identity"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["schema_version","session","generated_at","orchestrator","workers","validation"]}' ;;
    *)
      # Default — preserve python's JSON Schema shape for test backward-compat.
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{
          "$schema":"https://json-schema.org/draft/2020-12/schema",
          schema_version:$sv,
          command:"schema",
          surface:$surface,
          title:"Flywheel orch-worker identity manifest",
          type:"object",
          required:["schema_version","session","generated_at","orchestrator","workers","validation"],
          properties:{
            schema_version:{const:"orch-worker-identity/v1"},
            session:{type:"string"},
            generated_at:{type:"string"},
            orchestrator:{type:"object",required:["pane","agent_kind","fleet_mail_identity"]},
            workers:{type:"array",items:{type:"object",required:["pane","agent_kind","model","effort","fleet_mail_identity","fleet_mail_token_path","registered_at","registration_status"]}},
            validation:{type:"object",required:["all_workers_registered","unregistered_count","topology_source_line"]}
          }
        }' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — python manifest builder; reads loop markers, session topology, agent-mail identity rows; emits per-session manifests under ~/.local/state/flywheel/orch-worker-identity/.\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: python3, jq, loop-dir present, topology readable, agent-mail dir present, out-dir writable, flywheel root.\n' ;;
    health)   printf 'topic: health — tails audit log; warn stale >7d. Reports manifest_count (out-dir) + topology_row_count.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), out-dir-prime (read-only — manifest count probe).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON (manifest schema 6 fields), --schema, --config, --topology, --manifests.\n' ;;
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
            && cli_emit_completion_bash "orch-worker-identity-manifest" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--fleet,--session" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "orch-worker-identity-manifest" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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

  local loop_present=false loop_count=0
  if [[ -d "$SCAFFOLD_LOOP_DIR" ]]; then
    loop_present=true
    loop_count="$(find "$SCAFFOLD_LOOP_DIR" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  fi
  local loop_status="pass"; [[ "$loop_present" != true ]] && loop_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_LOOP_DIR" --arg s "$loop_status" --argjson present "$loop_present" --argjson count "${loop_count:-0}" \
    '{name:"loop_dir_readable",status:$s,value:$p,present:$present,marker_count:$count}')"$'\n'

  local topo_present=false topo_rows=0
  if [[ -r "$SCAFFOLD_TOPOLOGY" ]]; then
    topo_present=true
    topo_rows="$(wc -l < "$SCAFFOLD_TOPOLOGY" 2>/dev/null | tr -d ' ' || echo 0)"
  fi
  local topo_status="pass"; [[ "$topo_present" != true ]] && topo_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_TOPOLOGY" --arg s "$topo_status" --argjson present "$topo_present" --argjson rows "${topo_rows:-0}" \
    '{name:"topology_readable",status:$s,value:$p,present:$present,row_count:$rows}')"$'\n'

  local am_present=false
  [[ -d "$SCAFFOLD_AGENT_MAIL_DIR" ]] && am_present=true
  local am_status="pass"; [[ "$am_present" != true ]] && am_status="warn"
  checks+="$(jq -nc --arg p "$SCAFFOLD_AGENT_MAIL_DIR" --arg s "$am_status" --argjson present "$am_present" \
    '{name:"agent_mail_dir_present",status:$s,value:$p,present:$present}')"$'\n'

  if [[ -d "$SCAFFOLD_OUT_DIR" && -w "$SCAFFOLD_OUT_DIR" ]] || mkdir -p "$SCAFFOLD_OUT_DIR" 2>/dev/null; then
    local mc=0
    mc="$(find "$SCAFFOLD_OUT_DIR" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$SCAFFOLD_OUT_DIR" --argjson mc "${mc:-0}" '{name:"out_dir_writable",status:"pass",value:$p,manifest_count:$mc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$SCAFFOLD_OUT_DIR" '{name:"out_dir_writable",status:"fail",value:$p}')"$'\n'
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
  local manifest_count=0 topology_rows=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.generated_at // .ts // empty' 2>/dev/null || true)"
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
  [[ -d "$SCAFFOLD_OUT_DIR" ]] && manifest_count="$(find "$SCAFFOLD_OUT_DIR" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  [[ -r "$SCAFFOLD_TOPOLOGY" ]] && topology_rows="$(wc -l < "$SCAFFOLD_TOPOLOGY" 2>/dev/null | tr -d ' ' || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson mc "${manifest_count:-0}" --argjson tr "${topology_rows:-0}" \
    --arg out_dir "$SCAFFOLD_OUT_DIR" --arg topo "$SCAFFOLD_TOPOLOGY" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,out_dir:$out_dir,manifest_count:$mc,topology:$topo,topology_row_count:$tr}'
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
    out-dir-prime)
      local present=false manifest_count=0
      if [[ -d "$SCAFFOLD_OUT_DIR" ]]; then
        present=true
        manifest_count="$(find "$SCAFFOLD_OUT_DIR" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg od "$SCAFFOLD_OUT_DIR" --arg s "$status" \
        --argjson present "$present" --argjson mc "${manifest_count:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,out_dir:$od,present:$present,manifest_count:$mc,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","out-dir-prime"]}'
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
      --manifests) subject="manifests"; shift ;;
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
      for f in schema_version session generated_at orchestrator workers validation; do
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
      local py_ok=false jq_ok=false loop_ok=false topo_ok=false am_ok=false out_ok=false root_ok=false
      command -v python3 >/dev/null 2>&1 && py_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -d "$SCAFFOLD_LOOP_DIR" ]] && loop_ok=true
      [[ -r "$SCAFFOLD_TOPOLOGY" ]] && topo_ok=true
      [[ -d "$SCAFFOLD_AGENT_MAIL_DIR" ]] && am_ok=true
      [[ -d "$SCAFFOLD_OUT_DIR" ]] && out_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$py_ok" != true || "$jq_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson py "$py_ok" --argjson jqq "$jq_ok" --argjson loop "$loop_ok" \
        --argjson topo "$topo_ok" --argjson am "$am_ok" --argjson out "$out_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg loop_dir "$SCAFFOLD_LOOP_DIR" --arg topo_p "$SCAFFOLD_TOPOLOGY" --arg am_p "$SCAFFOLD_AGENT_MAIL_DIR" --arg out_p "$SCAFFOLD_OUT_DIR" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,python3_present:$py,jq_present:$jqq,loop_dir_present:$loop,topology_readable:$topo,agent_mail_dir_present:$am,out_dir_present:$out,flywheel_root_present:$rt,flywheel_root:$root,loop_dir:$loop_dir,topology:$topo_p,agent_mail_dir:$am_p,out_dir:$out_p}'
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
    manifests)
      local present=false manifest_count=0 sessions_json="[]"
      if [[ -d "$SCAFFOLD_OUT_DIR" ]]; then
        present=true
        manifest_count="$(find "$SCAFFOLD_OUT_DIR" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
        sessions_json="$(find "$SCAFFOLD_OUT_DIR" -maxdepth 1 -name '*.json' 2>/dev/null -exec basename {} .json \; 2>/dev/null | jq -R . | jq -sc '.' 2>/dev/null || echo '[]')"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg od "$SCAFFOLD_OUT_DIR" \
        --argjson present "$present" --argjson mc "${manifest_count:-0}" --argjson sessions "$sessions_json" \
        '{schema_version:$sv,command:"validate",subject:"manifests",status:$s,out_dir:$od,present:$present,manifest_count:$mc,sessions:$sessions}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","topology","manifests"],usage:"validate --row-json JSON or --schema or --config or --topology or --manifests"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","topology","manifests"]}'
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
import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "orch-worker-identity/v1"
DEFAULT_LOOP_DIR = Path.home() / ".flywheel/loops"
DEFAULT_TOPOLOGY = Path.home() / ".local/state/flywheel/session-topology.jsonl"
DEFAULT_AGENT_MAIL = Path.home() / ".local/state/flywheel/agent-mail"
DEFAULT_OUT_DIR = Path.home() / ".local/state/flywheel/orch-worker-identity"


def iso_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def parse_ts(value):
    if not value:
        return datetime.min.replace(tzinfo=timezone.utc)
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return datetime.min.replace(tzinfo=timezone.utc)


def latest_topology_rows(path):
    rows = {}
    line_numbers = {}
    if not path.exists():
        return rows, line_numbers
    for idx, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        session = row.get("session")
        if not session:
            continue
        current = rows.get(session)
        if current is None or parse_ts(row.get("effective_at")) >= parse_ts(current.get("effective_at")):
            rows[session] = row
            line_numbers[session] = idx
    return rows, line_numbers


def live_sessions(loop_dir):
    sessions = []
    if not loop_dir.exists():
        return sessions
    for path in sorted(loop_dir.glob("*.json")):
        if ".bak" in path.name:
            continue
        payload = read_json(path)
        if not isinstance(payload, dict):
            continue
        session = payload.get("session") or payload.get("project") or path.stem
        if payload.get("active") is True:
            sessions.append(str(session))
    return sessions


def registry_row(agent_mail_dir, session, pane):
    path = agent_mail_dir / "sessions" / f"{session}:{int(pane)}.json"
    payload = read_json(path)
    if isinstance(payload, dict):
        payload["_path"] = str(path)
        return payload
    return None


def identity_status(row):
    if not row:
        return "missing"
    status = row.get("status") or "missing"
    token_path = row.get("token_path")
    if status == "active" and token_path:
        return "active" if Path(token_path).expanduser().exists() else "stale"
    if status == "needs_registration":
        return "needs_registration"
    if status == "active":
        return "stale"
    return status if status in {"stale", "missing"} else "stale"


def as_int_list(value):
    if not isinstance(value, list):
        return []
    out = []
    for item in value:
        try:
            out.append(int(item))
        except Exception:
            continue
    return out


def topology_workers(row):
    for key in ("worker_panes", "workers"):
        workers = as_int_list(row.get(key))
        if workers:
            return workers
    return []


def build_manifest(session, row, line_no, agent_mail_dir, generated_at):
    if not isinstance(row, dict):
        return {
            "schema_version": SCHEMA_VERSION,
            "session": session,
            "generated_at": generated_at,
            "orchestrator": {
                "pane": None,
                "agent_kind": "unknown",
                "fleet_mail_identity": "unrecorded",
            },
            "workers": [],
            "validation": {
                "all_workers_registered": False,
                "unregistered_count": 0,
                "topology_source_line": None,
                "topology_status": "missing",
            },
        }

    orch_pane = row.get("orchestrator_pane")
    if orch_pane is None:
        orch_pane = row.get("callback_pane")
    worker_panes = topology_workers(row)
    worker_model = row.get("worker_model") or row.get("model")
    worker_effort = row.get("worker_effort") or row.get("effort")

    workers = []
    for pane in worker_panes:
        reg = registry_row(agent_mail_dir, session, pane)
        status = identity_status(reg)
        workers.append({
            "pane": pane,
            "agent_kind": row.get("worker_agent_kind") or row.get("agent_kind") or "unknown",
            "model": worker_model,
            "effort": worker_effort,
            "fleet_mail_identity": (reg or {}).get("identity_name") or "unregistered",
            "fleet_mail_token_path": (reg or {}).get("token_path"),
            "registered_at": (reg or {}).get("registered_ts"),
            "registration_status": status,
            "registry_source": (reg or {}).get("_path"),
        })

    unregistered = sum(1 for worker in workers if worker["registration_status"] != "active")
    return {
        "schema_version": SCHEMA_VERSION,
        "session": session,
        "generated_at": generated_at,
        "orchestrator": {
            "pane": orch_pane,
            "agent_kind": row.get("agent_kind") or "unknown",
            "fleet_mail_identity": row.get("fleet_mail_identity") or "unrecorded",
        },
        "workers": workers,
        "validation": {
            "all_workers_registered": unregistered == 0,
            "unregistered_count": unregistered,
            "topology_source_line": line_no,
            "topology_status": "found",
        },
    }


def write_json_atomic(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, sort_keys=True, separators=(",", ":"))
        handle.write("\n")
    os.replace(tmp_name, path)


def schema():
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "Flywheel orch-worker identity manifest",
        "type": "object",
        "required": ["schema_version", "session", "generated_at", "orchestrator", "workers", "validation"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "session": {"type": "string"},
            "generated_at": {"type": "string"},
            "orchestrator": {
                "type": "object",
                "required": ["pane", "agent_kind", "fleet_mail_identity"],
            },
            "workers": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": [
                        "pane",
                        "agent_kind",
                        "model",
                        "effort",
                        "fleet_mail_identity",
                        "fleet_mail_token_path",
                        "registered_at",
                        "registration_status",
                    ],
                },
            },
            "validation": {
                "type": "object",
                "required": ["all_workers_registered", "unregistered_count", "topology_source_line"],
            },
        },
    }


def print_payload(payload, as_json):
    if as_json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        if isinstance(payload, dict) and "summary" in payload:
            print(payload["summary"])
        else:
            print(json.dumps(payload, indent=2, sort_keys=True))


def main(argv):
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--fleet", action="store_true")
    parser.add_argument("--session")
    parser.add_argument("--loop-dir", default=os.environ.get("FLYWHEEL_LOOP_DIR", str(DEFAULT_LOOP_DIR)))
    parser.add_argument("--topology", default=os.environ.get("FLYWHEEL_SESSION_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    parser.add_argument("--agent-mail-dir", default=os.environ.get("FLYWHEEL_AGENT_MAIL_STATE_DIR", str(DEFAULT_AGENT_MAIL)))
    parser.add_argument("--out-dir", default=os.environ.get("FLYWHEEL_ORCH_WORKER_IDENTITY_DIR", str(DEFAULT_OUT_DIR)))
    args = parser.parse_args(argv)

    if args.info:
        print_payload({
            "schema_version": "canonical-cli-info/v1",
            "name": "orch-worker-identity-manifest",
            "summary": "Builds derived per-orchestrator worker identity manifests from live loop markers, session topology, and Agent Mail identity rows.",
            "dry_run_supported": True,
            "apply_supported": True,
            "idempotency_key": "session",
            "no_raw_tokens": True,
        }, args.json)
        return 0

    if args.examples:
        print_payload({
            "examples": [
                ".flywheel/scripts/orch-worker-identity-manifest.sh --fleet --dry-run --json",
                ".flywheel/scripts/orch-worker-identity-manifest.sh --session flywheel --apply --json",
                "jq '.workers[] | select(.pane == 2)' ~/.local/state/flywheel/orch-worker-identity/flywheel.json",
            ],
        }, args.json)
        return 0

    if args.schema:
        print_payload(schema(), True)
        return 0

    if args.apply and args.dry_run:
        raise SystemExit("--apply and --dry-run are mutually exclusive")
    if not args.apply and not args.dry_run:
        args.dry_run = True

    topology_path = Path(args.topology).expanduser()
    agent_mail_dir = Path(args.agent_mail_dir).expanduser()
    out_dir = Path(args.out_dir).expanduser()
    topology, line_numbers = latest_topology_rows(topology_path)

    sessions = []
    if args.fleet:
        sessions.extend(live_sessions(Path(args.loop_dir).expanduser()))
    if args.session:
        sessions.append(args.session)
    if not sessions:
        sessions = [Path.cwd().name]
    sessions = sorted(dict.fromkeys(sessions))

    generated_at = iso_now()
    manifests = []
    written = []
    for session in sessions:
        manifest = build_manifest(session, topology.get(session), line_numbers.get(session), agent_mail_dir, generated_at)
        target = out_dir / f"{session}.json"
        if args.apply:
            write_json_atomic(target, manifest)
            written.append(str(target))
        manifests.append({"path": str(target), "manifest": manifest})

    summary = {
        "schema_version": "orch-worker-identity-manifest-run/v1",
        "generated_at": generated_at,
        "mode": "apply" if args.apply else "dry-run",
        "sessions_requested": sessions,
        "manifests_written": len(written),
        "manifest_paths": [entry["path"] for entry in manifests],
        "sessions": {
            entry["manifest"]["session"]: {
                "workers": len(entry["manifest"]["workers"]),
                "registered": sum(1 for worker in entry["manifest"]["workers"] if worker["registration_status"] == "active"),
                "unregistered_count": entry["manifest"]["validation"]["unregistered_count"],
                "all_workers_registered": entry["manifest"]["validation"]["all_workers_registered"],
            }
            for entry in manifests
        },
        "manifests": manifests,
    }
    print_payload(summary, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
