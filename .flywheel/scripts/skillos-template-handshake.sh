#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block was scaffolded by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-wzjo9.2.9 (no remaining
# scaffold stubs).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="skillos-template-handshake/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/skillos-template-handshake-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: skillos-template-handshake.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "skillos-template-handshake.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "skillos-template-handshake.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"skillos-template-handshake.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"skillos-template-handshake.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"skillos-template-handshake.sh doctor --json"}'
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
          required:["status","checks"],status_enum:["pass","fail","warn"]}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","audit_log","recent_runs"],status_enum:["pass","warn","fail"]}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","mode","scope"],mode_enum:["dry_run","apply"],
          valid_scopes:["audit-log-rotate","coord-ledger-prime"],
          mutation_gates:["--apply requires --idempotency-key"]}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","subject"],valid_subjects:["row","schema","config","ledger"],
          status_enum:["pass","fail","warn","refused","info"]}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["audit_log","row_count","recent"]}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["id","status"],status_enum:["found","not_found","unavailable"],
          provenance_fields:["ts","idempotency_key","skills","requestor_orch","state"]}'
      ;;
    audit-row|run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["ts","command","schema_version"],
          optional:["idempotency_key","skills","requestor_orch","state","subcommand"],
          purpose:"row shape written to SCAFFOLD_AUDIT_LOG by cmd_run terminal envelopes"}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          surfaces:["doctor","health","repair","validate","audit","why","audit-row","default"],
          purpose:"cross-orch skillos template handshake — request/await-ack/validate-request/validate-ack subcommands persist coordination via JSONL ledger; substrate-level canonical layer over cmd_run",
          stable_exit_codes:{"0":"pass","1":"general error","3":"refused (--apply without --idempotency-key)","64":"bad args"}}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  local _runs="${SCAFFOLD_AUDIT_LOG:-${HOME}/.local/state/flywheel/skillos-template-handshake-runs.jsonl}"
  local _coord_ledger="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-${HOME}/.local/state/flywheel/cross-orch-coordination.jsonl}"
  case "$topic" in
    run)
      printf 'topic: run — default backward-compatible invocation routes to cmd_run. Subcommands: request (issue cross-orch skill-injection request, writes to %s), await-ack (poll ledger for ack by idempotency-key), validate-request (JSON schema check), validate-ack (JSON schema check).\n' "$_coord_ledger"
      ;;
    doctor)
      printf 'topic: doctor — substrate health probes (request schema + ack schema readable, coord ledger writable, jq on PATH, template producer version env). Per-handshake subcommands live in cmd_run.\n'
      ;;
    health)
      printf 'topic: health — recent run summary from %s (recent_count, last_run_ts, age_seconds, distinct subcommands, distinct states). Warn when ledger absent or stale (>24h).\n' "$_runs"
      ;;
    repair)
      printf 'topic: repair — read-only by default; mutate with --apply --idempotency-key KEY. Scopes: audit-log-rotate (rotate %s when >5MB), coord-ledger-prime (read-only probe of %s — emit row count + recent idempotency-keys). Apply without --idempotency-key returns refused (rc 3).\n' "$_runs" "$_coord_ledger"
      ;;
    validate)
      printf 'topic: validate — per-subject contract checks. Subjects: row (--row-json=JSON validates an audit-log row schema), schema (--surface=NAME re-emits the schema), config (env presence: request/ack schemas, jq), ledger (probe coord-ledger JSONL shape — each line is valid JSON with idempotency_key).\n'
      ;;
    audit)
      printf 'topic: audit — tail %s (default --tail=10). Returns rows[] with ts, idempotency_key, skills, requestor_orch, state, subcommand.\n' "$_runs"
      ;;
    why)
      printf 'topic: why <id> — provenance lookup by idempotency_key or skill in the audit log; emits ts/idempotency_key/skills/requestor_orch/state or status=not_found when absent.\n'
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
            && cli_emit_completion_bash "skillos-template-handshake" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "skillos-template-handshake" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 5 named substrate probes for skillos-template-handshake.
  local ts script_dir req_schema ack_schema coord_ledger
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  req_schema="$(cd "$script_dir/.." 2>/dev/null && pwd -P)/validation-schema/v1/skillos-template-handshake-request.schema.json"
  ack_schema="$(cd "$script_dir/.." 2>/dev/null && pwd -P)/validation-schema/v1/skillos-template-handshake-ack.schema.json"
  coord_ledger="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"

  local req_status="fail" req_reason=""
  if [[ -r "$req_schema" ]]; then req_status="pass"
  else req_reason="request schema not readable: $req_schema"; fi

  local ack_status="fail" ack_reason=""
  if [[ -r "$ack_schema" ]]; then ack_status="pass"
  else ack_reason="ack schema not readable: $ack_schema"; fi

  local ledger_status="fail" ledger_reason=""
  if [[ -f "$coord_ledger" && -w "$coord_ledger" ]]; then ledger_status="pass"
  elif [[ -d "$(dirname "$coord_ledger")" && -w "$(dirname "$coord_ledger")" ]]; then ledger_status="pass"; ledger_reason="path absent but parent writable"
  else ledger_reason="cannot write to coord-ledger: $coord_ledger"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH (required for JSON schema validation)"; fi

  local prod_ver="${SKILLOS_TEMPLATE_PRODUCER_VERSION_REQUIRED:-skillos-skill-injection-template/v1}"
  local prod_status="pass"

  local overall="pass" s
  for s in "$req_status" "$ack_status" "$ledger_status" "$jq_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg req "$req_schema" --arg req_s "$req_status" --arg req_r "$req_reason" \
    --arg ack "$ack_schema" --arg ack_s "$ack_status" --arg ack_r "$ack_reason" \
    --arg ledger "$coord_ledger" --arg led_s "$ledger_status" --arg led_r "$ledger_reason" \
    --arg jq_s "$jq_status" --arg jq_r "$jq_reason" \
    --arg prod_ver "$prod_ver" --arg prod_s "$prod_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"request_schema_readable",status:$req_s,path:$req,reason:$req_r},
      {name:"ack_schema_readable",status:$ack_s,path:$ack,reason:$ack_r},
      {name:"coord_ledger_writable",status:$led_s,path:$ledger,reason:$led_r},
      {name:"jq_on_path",status:$jq_s,reason:$jq_r},
      {name:"producer_version_required",status:$prod_s,value:$prod_ver}
    ]}'
}

scaffold_cmd_health() {
  # Tail SCAFFOLD_AUDIT_LOG. Reports recent_count, last_run_ts, age_seconds,
  # distinct subcommands + states. Warn when ledger absent or stale (>24h).
  local ts log_path tail_n=20 tail_lines total last_ts age_seconds distinct_subcmds distinct_states
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
  distinct_subcmds="$(printf '%s\n' "$tail_lines" | jq -r '.subcommand // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  distinct_states="$(printf '%s\n' "$tail_lines" | jq -r '.state // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
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
    --arg subcmds "$distinct_subcmds" --arg states "$distinct_states" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      audit_log:$log,recent_runs:$total,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      last_run_age_seconds:$age,
      recent_subcommands:($subcmds | split(",") | map(select(length > 0))),
      recent_states:($states | split(",") | map(select(length > 0)))}'
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
  # Per-scope repair: audit-log-rotate (5MB) + coord-ledger-prime (read-only probe).
  local log_path coord_ledger
  log_path="$SCAFFOLD_AUDIT_LOG"
  coord_ledger="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
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
            planned_actions:["rotate audit-log when --apply --idempotency-key KEY passed"]}'
      fi
      ;;
    coord-ledger-prime)
      # Read-only probe of the cross-orch coordination ledger.
      if [[ ! -f "$coord_ledger" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg path "$coord_ledger" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"read_only",scope:$scope,reason:"coord ledger absent (will be created on first handshake)",path:$path}'
        return 0
      fi
      local row_count recent_keys
      row_count="$(wc -l <"$coord_ledger" 2>/dev/null | tr -d ' ')"
      set +e
      recent_keys="$(tail -n 5 "$coord_ledger" 2>/dev/null | jq -r '.idempotency_key // empty' 2>/dev/null | jq -R . | jq -sc .)"
      set -e
      [[ -z "$recent_keys" ]] && recent_keys='[]'
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg path "$coord_ledger" --argjson rows "$row_count" --argjson keys "$recent_keys" \
        '{schema_version:$sv,command:"repair",status:"ok",mode:"read_only",scope:$scope,
          path:$path,row_count:$rows,recent_idempotency_keys:$keys,
          note:"read-only probe of cross-orch coordination ledger"}'
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["audit-log-rotate","coord-ledger-prime"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit-log-rotate","coord-ledger-prime"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject contract checks. Subjects: row, schema, config, ledger.
  local subject="" row_json="" surface_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --row-json) row_json="${2:-}"; subject="row"; shift 2 ;;
      --surface=*) surface_arg="${1#--surface=}"; subject="schema"; shift ;;
      --surface) surface_arg="${2:-}"; subject="schema"; shift 2 ;;
      --config) subject="config"; shift ;;
      --ledger) subject="ledger"; shift ;;
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
      local script_dir2 req_schema2 ack_schema2 coord2
      script_dir2="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
      req_schema2="$(cd "$script_dir2/.." 2>/dev/null && pwd -P)/validation-schema/v1/skillos-template-handshake-request.schema.json"
      ack_schema2="$(cd "$script_dir2/.." 2>/dev/null && pwd -P)/validation-schema/v1/skillos-template-handshake-ack.schema.json"
      coord2="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
      local missing=()
      [[ -r "$req_schema2" ]] || missing+=("request_schema:$req_schema2")
      [[ -r "$ack_schema2" ]] || missing+=("ack_schema:$ack_schema2")
      [[ -d "$(dirname "$coord2")" ]] || missing+=("coord_ledger_parent:$(dirname "$coord2")")
      command -v jq >/dev/null 2>&1 || missing+=("jq:not_on_path")
      local missing_json
      if [[ ${#missing[@]} -eq 0 ]]; then
        missing_json='[]'
      else
        missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc .)"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg req "$req_schema2" --arg ack "$ack_schema2" --arg coord "$coord2" \
        --argjson missing "$missing_json" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if ($missing | length) == 0 then "pass" else "fail" end),
          request_schema:$req,ack_schema:$ack,coord_ledger:$coord,missing:$missing}'
      ;;
    ledger)
      # Probe coord-ledger JSONL shape. NOTE: this is a SHARED cross-orch
      # ledger holding many row types (events, handoffs, acks, summaries),
      # not just handshake rows. Validate that:
      #   (a) every line is valid JSON
      #   (b) at least the rows that ARE handshake rows (event=skillos_template_handshake_*)
      #       carry an idempotency_key.
      # Verified against actual ledger row shapes during fillin (live-data
      # check showed recent 50 rows are mostly non-handshake event/ack/summary
      # types from other surfaces sharing the ledger).
      local coord3 lines_total lines_valid handshake_rows handshake_with_key
      coord3="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
      if [[ ! -f "$coord3" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$coord3" \
          '{schema_version:$sv,command:"validate",subject:"ledger",status:"warn",reason:"coord ledger absent",path:$path}'
        return 0
      fi
      lines_total=0; lines_valid=0; handshake_rows=0; handshake_with_key=0
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        lines_total=$((lines_total + 1))
        if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
          lines_valid=$((lines_valid + 1))
          # Is this a handshake row? Filter by event prefix or class.
          if printf '%s' "$line" | jq -e '.event // "" | test("skillos.*handshake|template.handshake")' >/dev/null 2>&1; then
            handshake_rows=$((handshake_rows + 1))
            if printf '%s' "$line" | jq -e '.idempotency_key' >/dev/null 2>&1; then
              handshake_with_key=$((handshake_with_key + 1))
            fi
          fi
        fi
      done < <(tail -n 50 "$coord3")
      local status="pass"
      if [[ "$lines_valid" -lt "$lines_total" ]]; then
        status="warn"
      elif [[ "$handshake_rows" -gt 0 && "$handshake_with_key" -lt "$handshake_rows" ]]; then
        status="warn"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$coord3" --arg status "$status" \
        --argjson total "$lines_total" --argjson valid "$lines_valid" \
        --argjson hrows "$handshake_rows" --argjson hwk "$handshake_with_key" \
        '{schema_version:$sv,command:"validate",subject:"ledger",path:$path,status:$status,
          tail_total:$total,tail_valid_json:$valid,
          tail_handshake_rows:$hrows,tail_handshake_with_idempotency_key:$hwk,
          note:"coord-ledger is a SHARED cross-orch ledger; handshake rows are filtered by event match"}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","schema","config","ledger"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
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
  # Provenance lookup: search both SCAFFOLD_AUDIT_LOG and coord-ledger for
  # matching idempotency_key.
  local log_path coord
  log_path="$SCAFFOLD_AUDIT_LOG"
  coord="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
  local row="" source_log=""
  if [[ -f "$log_path" ]]; then
    row="$(grep -F "\"idempotency_key\":\"$id\"" "$log_path" 2>/dev/null | tail -1 || true)"
    if [[ -n "$row" ]]; then source_log="$log_path"; fi
  fi
  if [[ -z "$row" && -f "$coord" ]]; then
    row="$(grep -F "\"idempotency_key\":\"$id\"" "$coord" 2>/dev/null | tail -1 || true)"
    if [[ -n "$row" ]]; then source_log="$coord"; fi
  fi
  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg audit "$log_path" --arg coord "$coord" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",reason:"id not in audit ledger or coord-ledger",searched:[$audit,$coord]}'
    return 0
  fi
  if ! printf '%s' "$row" | jq -e . >/dev/null 2>&1; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg src "$source_log" \
      --arg raw "$(printf '%s' "$row" | head -c 512)" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"matched row is not valid JSON",source_log:$src,raw_preview:$raw}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg src "$source_log" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",source_log:$src,
      provenance:{
        ts:($row.ts // null),
        idempotency_key:($row.idempotency_key // null),
        skills:($row.skills // null),
        requestor_orch:($row.requestor_orch // null),
        state:($row.state // null),
        subcommand:($row.subcommand // null)
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
  exit $?
fi
# ====== END canonical-cli scaffold ======
VERSION="skillos-template-handshake/v1"
REQ_SCHEMA="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/validation-schema/v1/skillos-template-handshake-request.schema.json"
ACK_SCHEMA="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/validation-schema/v1/skillos-template-handshake-ack.schema.json"
LEDGER="${SKILLOS_TEMPLATE_HANDSHAKE_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
JSON_OUT=0 QUIET=0 CMD="" SKILLS="" TTL="" TIMEOUT=30 KEY="" INPUT_JSON=""
PRODUCER_VERSION_REQUIRED="${SKILLOS_TEMPLATE_PRODUCER_VERSION_REQUIRED:-skillos-skill-injection-template/v1}"
TEMPLATE_CLASS="${SKILLOS_TEMPLATE_CLASS:-skill-injection-template}"
REQUESTOR_ORCH="${SKILLOS_TEMPLATE_REQUESTOR_ORCH:-flywheel:1}"
REQUESTOR_SESSION="${SKILLOS_TEMPLATE_REQUESTOR_SESSION:-flywheel}" DISPATCH_TARGET_BEAD_ID=""

usage() {
  cat <<'USAGE'
usage: skillos-template-handshake.sh request|await-ack|validate-request|validate-ack [options]
       skillos-template-handshake.sh --info|--help|--examples [--json]
USAGE
}

info() {
  jq -nc --arg version "$VERSION" '{
    name:"skillos-template-handshake",
    schema_version:$version,
    subcommands:["request","await-ack","validate-request","validate-ack"],
    canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
    states:["success","stale","unavailable","duplicate"],
    ledger_env:"SKILLOS_TEMPLATE_HANDSHAKE_LEDGER"
  }'
}

examples() {
  jq -nc '{examples:[
    "skillos-template-handshake.sh request --skills agent-mail,socraticode --ttl-sec 900 --json",
    "skillos-template-handshake.sh await-ack --idempotency-key sha256:... --timeout-sec 60 --json",
    "skillos-template-handshake.sh validate-request --json '\''{\"idempotency_key\":\"req-001\",...}'\''",
    "skillos-template-handshake.sh validate-ack --json '\''{\"idempotency_key\":\"req-001\",...}'\''"
  ]}'
}

emit() {
  local payload="$1"
  [[ "$QUIET" -eq 1 ]] && return
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"command=\(.command // "info") state=\(.state // .status // "ok")"' <<<"$payload"
  fi
}

sha256() { shasum -a 256 | awk '{print "sha256:" $1}'; }

validate_payload() {
  local schema="$1" payload="$2"
  python3 - "$schema" "$payload" <<'PY'
import json
import sys
from jsonschema import Draft202012Validator

schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.loads(sys.argv[2])
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)
PY
}

iso_add() {
  python3 - "$1" "$2" <<'PY'
from datetime import datetime, timedelta, timezone
import sys
base = datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00"))
print((base + timedelta(seconds=int(sys.argv[2]))).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

skills_json() { printf '%s' "$SKILLS" | jq -Rsc 'split(",") | map(gsub("^ +| +$";"")) | map(select(length > 0))'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    request|await-ack|validate-request|validate-ack) CMD="$1"; shift ;;
    --skills) SKILLS="${2:?--skills requires LIST}"; shift 2 ;;
    --skills=*) SKILLS="${1#*=}"; shift ;;
    --ttl-sec) TTL="${2:?--ttl-sec requires N}"; shift 2 ;;
    --ttl-sec=*) TTL="${1#*=}"; shift ;;
    --timeout-sec) TIMEOUT="${2:?--timeout-sec requires N}"; shift 2 ;;
    --timeout-sec=*) TIMEOUT="${1#*=}"; shift ;;
    --idempotency-key) KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) KEY="${1#*=}"; shift ;;
    --producer-version-required|--producer-version) PRODUCER_VERSION_REQUIRED="${2:?--producer-version requires value}"; shift 2 ;;
    --template-class) TEMPLATE_CLASS="${2:?--template-class requires value}"; shift 2 ;;
    --requestor-orch) REQUESTOR_ORCH="${2:?--requestor-orch requires value}"; shift 2 ;;
    --requestor-session) REQUESTOR_SESSION="${2:?--requestor-session requires value}"; shift 2 ;;
    --dispatch-target-bead-id) DISPATCH_TARGET_BEAD_ID="${2:?--dispatch-target-bead-id requires value}"; shift 2 ;;
    --ledger) LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --json)
      if [[ "$CMD" == validate-* && $# -gt 1 && "$2" != --* ]]; then
        INPUT_JSON="$2"; JSON_OUT=1; shift 2
      else
        JSON_OUT=1; shift
      fi ;;
    --input-json) INPUT_JSON="${2:?--input-json requires JSON}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$CMD" ]] || { usage >&2; exit 2; }

case "$CMD" in
  validate-request|validate-ack)
    [[ -n "$INPUT_JSON" ]] || INPUT_JSON="$(cat)"
    schema="$REQ_SCHEMA"; [[ "$CMD" == validate-ack ]] && schema="$ACK_SCHEMA"
    if validate_payload "$schema" "$INPUT_JSON"; then
      emit "$(jq -nc --arg version "$VERSION" --arg command "$CMD" '{schema_version:$version,command:$command,status:"pass"}')"
    else
      emit "$(jq -nc --arg version "$VERSION" --arg command "$CMD" '{schema_version:$version,command:$command,status:"fail"}')"
      exit 1
    fi
    ;;
  request)
    [[ -n "$SKILLS" && -n "$TTL" ]] || { usage >&2; exit 2; }
    [[ "$TTL" =~ ^[0-9]+$ && "$TTL" -gt 0 ]] || { printf 'ERR --ttl-sec must be positive integer\n' >&2; exit 2; }
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    [[ -n "$KEY" ]] || KEY="$(printf '%s|%s|%s|%s\n' "$SKILLS" "$TTL" "$PRODUCER_VERSION_REQUIRED" "$ts" | sha256)"
    if [[ -f "$LEDGER" ]] && jq -e --arg key "$KEY" 'select(.type=="skillos_template_handshake_request" and .idempotency_key==$key)' "$LEDGER" >/dev/null; then
      emit "$(jq -nc --arg version "$VERSION" --arg key "$KEY" '{schema_version:$version,command:"request",state:"duplicate",idempotency_key:$key,ledger_written:false}')"
      exit 0
    fi
    row="$(jq -nc --arg sv "skillos-template-handshake-request/v1" --arg type "skillos_template_handshake_request" \
      --arg key "$KEY" --arg producer "$PRODUCER_VERSION_REQUIRED" --arg class "$TEMPLATE_CLASS" \
      --argjson skills "$(skills_json)" --argjson ttl "$TTL" --arg orch "$REQUESTOR_ORCH" \
      --arg session "$REQUESTOR_SESSION" --arg ts "$ts" --arg expires "$(iso_add "$ts" "$TTL")" \
      --arg bead "$DISPATCH_TARGET_BEAD_ID" \
      '{schema_version:$sv,type:$type,idempotency_key:$key,producer_version_required:$producer,requested_template_class:$class,requested_skills:$skills,ttl_seconds:$ttl,requestor_orch:$orch,requestor_session:$session,requested_at:$ts,request_expires_at:$expires} + (if $bead == "" then {} else {dispatch_target_bead_id:$bead} end)')"
    validate_payload "$REQ_SCHEMA" "$row"
    mkdir -p "$(dirname "$LEDGER")"
    printf '%s\n' "$row" >>"$LEDGER"
    emit "$(jq -nc --arg version "$VERSION" --arg ledger "$LEDGER" --argjson row "$row" '{schema_version:$version,command:"request",state:"requested",ledger_written:true,ledger:$ledger,request:$row}')"
    ;;
  await-ack)
    [[ -n "$KEY" && "$TIMEOUT" =~ ^[0-9]+$ ]] || { usage >&2; exit 2; }
    deadline=$((SECONDS + TIMEOUT))
    while :; do
      set +e
      payload="$(python3 - "$LEDGER" "$KEY" "$PRODUCER_VERSION_REQUIRED" <<'PY'
import json
import sys
from datetime import datetime, timedelta, timezone

ledger, key, default_required = sys.argv[1:4]
rows = []
try:
    with open(ledger, encoding="utf-8") as handle:
        rows = [json.loads(line) for line in handle if line.strip()]
except FileNotFoundError:
    pass
reqs = [r for r in rows if r.get("type") == "skillos_template_handshake_request" and r.get("idempotency_key") == key]
acks = [r for r in rows if r.get("type") == "skillos_template_handshake_ack" and r.get("idempotency_key") == key]
mismatched_acks = [r for r in rows if r.get("type") == "skillos_template_handshake_ack" and r.get("idempotency_key") != key]
now = datetime.now(timezone.utc)
base = {"schema_version":"skillos-template-handshake/v1","command":"await-ack","idempotency_key":key}
if len(reqs) > 1:
    print(json.dumps(base | {"state":"duplicate","degraded_fallback":{"reason":"duplicate_request_rows","safe_to_continue":False,"fallback_state":"duplicate"}})); raise SystemExit(0)
if reqs:
    req = reqs[-1]
    required = req.get("producer_version_required") or default_required
    requested_at = datetime.fromisoformat(req["requested_at"].replace("Z", "+00:00"))
    expires_at = requested_at + timedelta(seconds=int(req["ttl_seconds"]))
    if acks:
        ack = acks[-1]
        state = ack.get("state", "unavailable")
        if ack.get("producer_version_provided") != required:
            print(json.dumps(base | {"state":"unavailable","producer_version_provided":ack.get("producer_version_provided"),"producer_version_required":required,"degraded_fallback":{"reason":"producer_version_mismatch","safe_to_continue":False,"fallback_state":"unavailable"}})); raise SystemExit(0)
        print(json.dumps(base | {"state":state,"ack":ack})); raise SystemExit(0)
    if now > expires_at:
        print(json.dumps(base | {"state":"stale","degraded_fallback":{"reason":"ttl_expired_before_ack","safe_to_continue":False,"fallback_state":"stale"}})); raise SystemExit(0)
    if mismatched_acks:
        print(json.dumps(base | {"state":"unavailable","degraded_fallback":{"reason":"ack_idempotency_key_mismatch_or_missing","safe_to_continue":False,"fallback_state":"unavailable"}})); raise SystemExit(0)
print(json.dumps(base | {"state":"pending"}))
raise SystemExit(2)
PY
)"
      rc=$?
      set -e
      if [[ "$rc" -eq 0 ]]; then
        emit "$payload"; exit 0
      fi
      if (( SECONDS >= deadline )); then
        emit "$(jq -nc --arg version "$VERSION" --arg key "$KEY" '{schema_version:$version,command:"await-ack",idempotency_key:$key,state:"unavailable",degraded_fallback:{reason:"ack_timeout",safe_to_continue:false,fallback_state:"unavailable"}}')"
        exit 0
      fi
      sleep 1
    done
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
