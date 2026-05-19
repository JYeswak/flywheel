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
# specific logic stays as scaffold-marker stubs — fillin replaces them with concrete impls.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="polish-preflight-quality-gate/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: polish-preflight-quality-gate.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "polish-preflight-quality-gate.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "polish-preflight-quality-gate.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"polish-preflight-quality-gate.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"polish-preflight-quality-gate.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"polish-preflight-quality-gate.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","latest_ledger_row?"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","lock-dir-prune"],fields:["status","mode","scope","idempotency_key?","rotated?","locks_pruned?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","plan-slug","gate-state"],fields:["status","subject","valid?","missing?","reason?","plan_slug?","gate_state?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"plan-slug|gate-name|ledger-ts"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["ts","command","schema_version"],optional:["plan_slug","gates","apply"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"polish-preflight-quality-gate: 8-gate Phase 5 preflight check (cmd_run shape preserved); ledger + idempotency + lock dir substrate"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — bare invocation runs 8-gate Phase 5 quality-bar preflight; emits jsonl to POLISH_PREFLIGHT_LEDGER + idempotency check; --apply mode is NON-mutating per gate_version v1 contract.\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: jq, ROOT path, ledger dir writable, idempotency-ledger dir writable, lock dir writable, plan_slug env state.\n' ;;
    health)   printf 'topic: health — tails POLISH_PREFLIGHT_LEDGER for most recent gate-row; warn stale >24h (preflight is operator-triggered per ship attempt).\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), lock-dir-prune (>14d stale locks → rm; observational by default).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --plan-slug <slug> (probes whether STATE.json exists), --gate-state (replays a no-op preflight check).\n' ;;
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
            && cli_emit_completion_bash "polish-preflight-quality-gate" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "polish-preflight-quality-gate" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Substrate: jq (envelopes), ROOT resolvable, ledger + idempotency dirs writable, lock dir writable, plan_slug env.
  local script_root; script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  local ledger_dir idemp_dir lock_dir checks="" overall="pass"
  ledger_dir="$(dirname "${POLISH_PREFLIGHT_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate.jsonl}")"
  idemp_dir="$(dirname "${POLISH_PREFLIGHT_IDEMPOTENCY_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-idempotency.jsonl}")"
  lock_dir="${POLISH_PREFLIGHT_LOCK_DIR:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-locks}"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail",detail:"jq required for envelopes"}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$script_root" ]]; then
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"flywheel_root_resolvable",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    checks+="$(jq -nc --arg p "$ledger_dir" '{name:"ledger_dir_writable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$ledger_dir" '{name:"ledger_dir_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$idemp_dir" ]] || mkdir -p "$idemp_dir" 2>/dev/null; then
    checks+="$(jq -nc --arg p "$idemp_dir" '{name:"idempotency_dir_writable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$idemp_dir" '{name:"idempotency_dir_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$lock_dir" ]] || mkdir -p "$lock_dir" 2>/dev/null; then
    checks+="$(jq -nc --arg p "$lock_dir" '{name:"lock_dir_writable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$lock_dir" '{name:"lock_dir_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local ledger="${POLISH_PREFLIGHT_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate.jsonl}"
  # Health probes BOTH the SCAFFOLD_AUDIT_LOG (canonical layer) AND the cmd_run ledger.
  local last_row="null" stale_seconds=-1 status="warn" latest_ledger_row="null"
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
          if [[ "$stale_seconds" -le 86400 ]]; then status="pass"; fi
        fi
      fi
    fi
  fi
  if [[ -r "$ledger" ]]; then
    local lrow; lrow="$(tail -n 1 "$ledger" 2>/dev/null || true)"
    if [[ -n "$lrow" ]] && printf '%s' "$lrow" | jq -e '.' >/dev/null 2>&1; then
      latest_ledger_row="$lrow"
    fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson lrow "$latest_ledger_row" --arg ledger "$ledger" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,polish_preflight_ledger:$ledger,latest_ledger_row:$lrow}'
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
    lock-dir-prune)
      # Read-only by default: probe lock dir for stale locks (>14d). Apply mode prunes them.
      local lock_dir="${POLISH_PREFLIGHT_LOCK_DIR:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-locks}"
      local lock_count=0 stale_count=0 pruned_count=0
      if [[ -d "$lock_dir" ]]; then
        lock_count="$(find "$lock_dir" -type f 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
        stale_count="$(find "$lock_dir" -type f -mtime +14 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
        if [[ "$mode" == "apply" && "$stale_count" -gt 0 ]]; then
          while IFS= read -r f; do
            [[ -n "$f" ]] && rm -f "$f" 2>/dev/null && pruned_count=$((pruned_count + 1))
          done < <(find "$lock_dir" -type f -mtime +14 2>/dev/null)
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg ld "$lock_dir" \
        --argjson lc "$lock_count" --argjson sc "$stale_count" --argjson pc "$pruned_count" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,lock_dir:$ld,lock_count:$lc,stale_count:$sc,locks_pruned:$pc,stale_threshold_days:14}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","lock-dir-prune"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json="" plan_slug_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --plan-slug) subject="plan-slug"; plan_slug_arg="${2:-}"; shift 2 ;;
      --plan-slug=*) subject="plan-slug"; plan_slug_arg="${1#--plan-slug=}"; shift ;;
      --gate-state) subject="gate-state"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  local script_root; script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
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
      for f in ts command schema_version; do
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
      local jq_ok=false root_ok=false ledger_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -d "$script_root" ]] && root_ok=true
      [[ -d "$(dirname "${POLISH_PREFLIGHT_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate.jsonl}")" ]] && ledger_ok=true
      local overall=pass
      [[ "$jq_ok" != true || "$root_ok" != true || "$ledger_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson rt "$root_ok" --argjson ldg "$ledger_ok" \
        --arg root "$script_root" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,flywheel_root_present:$rt,ledger_dir_present:$ldg,flywheel_root:$root}'
      ;;
    plan-slug)
      # quality-gate-specific: probes whether the named plan exists.
      if [[ -z "$plan_slug_arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"plan-slug",status:"fail",reason:"--plan-slug <slug> required"}'
        return 0
      fi
      local plan_dir="$script_root/.plans/$plan_slug_arg"
      local state_file="$plan_dir/STATE.json"
      local plan_exists=false state_exists=false
      [[ -d "$plan_dir" ]] && plan_exists=true
      [[ -r "$state_file" ]] && state_exists=true
      local status="pass"
      [[ "$plan_exists" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" \
        --arg slug "$plan_slug_arg" --arg pd "$plan_dir" --arg sf "$state_file" \
        --argjson pe "$plan_exists" --argjson se "$state_exists" \
        '{schema_version:$sv,command:"validate",subject:"plan-slug",status:$s,plan_slug:$slug,plan_dir:$pd,state_file:$sf,plan_dir_present:$pe,state_file_present:$se}'
      ;;
    gate-state)
      # quality-gate-specific: emit a no-op preflight snapshot (configured plan_slug + ledger state)
      local default_plan="mission-lock-paradigm-extension-2026-05-06"
      local ledger="${POLISH_PREFLIGHT_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate.jsonl}"
      local ledger_present=false ledger_row_count=0
      if [[ -r "$ledger" ]]; then
        ledger_present=true
        ledger_row_count="$(wc -l < "$ledger" 2>/dev/null | tr -d ' ' || echo 0)"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg dp "$default_plan" --arg lg "$ledger" \
        --argjson lp "$ledger_present" --argjson rc "$ledger_row_count" \
        '{schema_version:$sv,command:"validate",subject:"gate-state",status:"pass",default_plan_slug:$dp,polish_preflight_ledger:$lg,ledger_present:$lp,ledger_row_count:$rc,gate_version:"v1",gates_count:8}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","plan-slug","gate-state"],usage:"validate --row-json JSON or --schema or --config or --plan-slug <slug> or --gate-state"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","plan-slug","gate-state"]}'
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
  # Search audit log for matching plan-slug, gate-name, or ledger-ts.
  local matches="[]" status="not_found"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    matches="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '. // []' 2>/dev/null || echo '[]')"
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    [[ "$n" -gt 0 ]] && status="found"
  else
    status="unavailable"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m}'
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
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN_SLUG="mission-lock-paradigm-extension-2026-05-06"
MODE=check; JSON_OUT=0; APPLY=0; VERSION=v1
LEDGER="${POLISH_PREFLIGHT_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate.jsonl}"
IDEMP="${POLISH_PREFLIGHT_IDEMPOTENCY_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-idempotency.jsonl}"
LOCK_DIR="${POLISH_PREFLIGHT_LOCK_DIR:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-locks}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) MODE=info; shift ;;
    --check) MODE=check; shift ;;
    --json) JSON_OUT=1; shift ;;
    --plan-slug) PLAN_SLUG="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --help|-h) echo "polish-preflight-quality-gate.sh [--info] [--check] [--json] [--plan-slug <slug>] [--apply]"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == info ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg v "$VERSION" --arg p "$PLAN_SLUG" '{name:"polish-preflight-quality-gate",gate_version:$v,plan_slug:$p,gates:8,apply_mutates_state:false}'
  else
    printf 'polish-preflight-quality-gate %s\nplan_slug=%s\ngates=8\n' "$VERSION" "$PLAN_SLUG"
  fi
  exit 0
fi

PLAN_STATE="$ROOT/.flywheel/PLANS/$PLAN_SLUG/STATE.json"
if [[ -z "$PLAN_SLUG" || ! -f "$PLAN_STATE" ]]; then
  r="$(jq -nc --arg p "$PLAN_SLUG" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg v "$VERSION" '{gate_status:"PENDING",plan_slug:$p,gates_run:[],first_fire_reason:"plan state missing",composite_health_score:0,all_audit_findings_closed:false,ts:$ts,gate_version:$v}')"
  [[ "$JSON_OUT" -eq 1 ]] && echo "$r" || echo "PENDING plan state missing"
  exit 2
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-preflight.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
GATES="$TMP/gates.jsonl"; FIRST_FIRE=""; PASS_COUNT=0; TOTAL_GATES=8

make_fixtures() {
  python3 - "$TMP" <<'PY'
import hashlib, json, pathlib, sys
t=pathlib.Path(sys.argv[1]); t.mkdir(parents=True, exist_ok=True)
slug="mission-lock-paradigm-extension-2026-05-06"; bead="flywheel-phase5-polish-preflight-quality-gate-2026-05-06"
(t/"substrate").mkdir()
(t/"substrate/tokens.json").write_text('{"tokens":true}\n')
payload={"schema_version":"mission-lock-output/v1","mission_anchor_rev":1,"lock_hash":"sha256:"+"a"*64,"locked_at":"2026-05-06T16:00:00Z","status":"locked","mission_anchor_text":"polish preflight quality gate terminal close","mission_license":{"vendors_approved":["OpenAI"],"platforms_approved":["macOS"],"tier_per_vendor":{"OpenAI":"team"},"budget_envelope_usd_monthly":500,"tos_accepted_at":[{"vendor":"OpenAI","ts":"2026-05-06T16:00:00Z"}],"secrets_provisioned_at_lock_time":["infisical:/openai"],"auto_rotate_allowed":["OpenAI"],"secret_vendor_map":{"OpenAI":"infisical:/openai"}},"negative_invariants":[{"id":"SEC-006","surface":"mission-lock","forbidden_action":"state_mutation_from_apply","enforcement":"fail_close"}],"cross_cutting_concerns_addressed":[{"concern":"preflight","status":"addressed","evidence":"eight sub-gates"}],"surface_principal_metadata":[{"surface":"quality-gate","secret_source_of_truth":"infisical","principal_type":"worker","allowed_operations":["audit"],"forbidden_principals":["anonymous"],"service_role_policy":"no service-role mutation"}],"skill_surface_map":[{"surface":"quality-gate","skill":"testing-conformance-harnesses","decision":"ADOPT","source":"dispatch packet"}],"failure_mode_matrix":[{"failure_mode":"false shipped state","risk":"terminal close without preflight","guard":"polish preflight quality gate","evidence":"receipt"}],"receipt_identity_envelope":{"idempotency_key":"sha256:"+"b"*64,"replay_detection_hash":"sha256:"+"c"*64,"transaction_boundary":{"begin":True,"commit":True,"abort":False},"receipt_completeness":{"SEC":True,"IDEM":True,"CSR":True}},"provenance":{"created_by":"polish-preflight-quality-gate","last_modified_by":"polish-preflight-quality-gate","source":"contract fixture"}}
(t/"mission.json").write_text(json.dumps(payload)+"\n")
sections={
"Mission Source":f"plan_slug: {slug}\nbead_id: {bead}\n",
"North-Star Outcome":"Durable terminal plan close substrate.\n",
"Primary Beneficiary":"Flywheel workers.\n",
"Explicit Non-Goals":"No runtime STATE mutation from --apply.\n",
"Safety And Privacy Boundaries":"No secret payloads.\n",
"Evidence That Would Change The Mission":"Owner review.\n",
"Owner-Review Cadence":"Quarterly.\n",
"Lock Receipt":"Locked for polish preflight validation.\n",
"Negative invariants (security)":"- do not rotate secrets.\n- do not mutate STATE from --apply.\n",
"Substrate inventory":"- design tokens: `substrate/tokens.json`\n"}
mission="# Mission Lock Fixture\n\n"+"".join(f"## {k}\n\n{v}\n" for k,v in sections.items())
for name in ["Mission Source","Negative invariants (security)"]:
    body=sections[name].strip()+"\n"; mission+=f"<!-- section_hash: {name} sha256:{hashlib.sha256(body.encode()).hexdigest()} -->\n"
(t/"MISSION.md").write_text(mission)
(t/"MISSION.md.json").write_text(json.dumps(payload)+"\n")
p=t/"plan"; p.mkdir()
(p/"STATE.json").write_text(json.dumps({"lens_merge_rows":[{"lens":"security-negative-invariants","ts":"2026-05-06T16:00:00Z","state_observed_sha":"sha256:"+"d"*64,"state_written_sha":"sha256:"+"e"*64,"audit_lens_identity_key":"sha256:"+"f"*64}],"phase5_ready":True,"audit_findings_count":18})+"\n")
d=f"""# Dispatch fixture
Task ID: wave4-polish-preflight-quality-gate-2026-05-06
To: flywheel:3 codex
dispatch_class_merge_order: bead_labels,touched_files,mission_surfaces,socraticode,override
strictest_invariant_wins=true
collision_policy=resolved
discovery_precedence: exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem
required_overlays: canonical-cli-scoping, readme-writing, de-slopify, simplify, socraticode, agent-mail, agent-monitoring, cost-attribution, search-tool-routing-doctrine
secret_values_allowed=false
route_receipt_schema_version=dispatch-author-route-receipt/v1
skill_routing: present
skill_receipts[] required_fields: receipt_identity_key, skill, source, action_taken, policy_version, evidence, alias_of, not_applicable_reason
dispatch_receipt required_fields: idempotency_key, replay_detection_hash, transaction_boundary, receipt_completeness
selected_skill_count: 9
prompt_budget_policy: names-plus-one-line-why; excerpts <= 25 percent or 1200 tokens
"""
(t/"dispatch.md").write_text(d)
self_body=f"# DISPATCH\n\nTask ID: wave4-polish-preflight-quality-gate-2026-05-06\nTo: flywheel:3 codex\nidempotency_key: sha256:{hashlib.sha256(b'preflight').hexdigest()}\n"
(t/"self-test.md").write_text(self_body)
observed="OK_wave4_polish_preflight_quality_gate_dag_closed"; command="bash wave4-polish-preflight-quality-gate"
sh=lambda s:"sha256:"+hashlib.sha256(s.encode()).hexdigest()
close={"status":"DONE","ref_id":bead,"task_id":"wave4-polish-preflight-quality-gate-2026-05-06","close_identity_key":"close-key-polish-preflight","dedupe_policy":"latest-row-by-ref_id-event","skill_receipts":[{"schema_version":"skill-receipt/v1","receipt_identity_key":"skill-receipt:polish-preflight","skill":"socraticode","resolved_to":"socraticode","source":"local-skill-root","path":"/Users/josh/.claude/skills/socraticode/SKILL.md","sha":"sha256:"+"a"*64,"version":"2026-05-06","freshness_status":"fresh","route_allowed":True,"checked_at":"2026-05-06T16:00:00Z","action_taken":"applied","policy_version":"close-validator-receipt-contract/v1","credential_touch":False,"secret_value_allowed":False,"safe_wrapper":"n/a"}],"l112":{"command":command,"command_hash":sh(command),"observed":observed,"expected":observed,"output_hash":sh(observed)},"evidence":[{"type":"path","value":".flywheel/scripts/polish-preflight-quality-gate.sh"}]}
(t/"close.json").write_text(json.dumps(close)+"\n")
(t/"dispatch-log.jsonl").write_text("")
PY
}

record_gate() {
  local n="$1" s="$2" e="$3" l="$4" why="${5:-}"
  jq -nc --arg name "$n" --arg status "$s" --arg evidence_path "$e" --argjson latency_ms "$l" '{name:$name,status:$status,evidence_path:$evidence_path,latency_ms:$latency_ms}' >> "$GATES"
  if [[ "$s" == PASS ]]; then PASS_COUNT=$((PASS_COUNT+1)); elif [[ -z "$FIRST_FIRE" ]]; then FIRST_FIRE="${why:-$n failed}"; fi
}

run_gate() {
  local n="$1" expr="$2" out="$TMP/$1.json" rc; shift 2
  if [[ "${POLISH_PREFLIGHT_FORCE_FAIL:-}" == "$n" ]]; then
    jq -nc --arg name "$n" '{forced_failure:$name}' > "$out"; record_gate "$n" FAIL "$out" 0 "$n forced failure"; return
  fi
  set +e; "$@" > "$out" 2>"$TMP/$n.err"; rc=$?; set -e
  if [[ "$rc" -eq 0 ]] && jq -e "$expr" "$out" >/dev/null 2>&1; then record_gate "$n" PASS "$out" 0; else record_gate "$n" FAIL "$out" 0 "$n failed"; fi
}

apply_receipt() {
  local r="$1" ident guard status line marked
  mkdir -p "$(dirname "$LEDGER")" "$(dirname "$IDEMP")" "$LOCK_DIR"
  ident="$(jq -c '{plan_slug,gate_version,gate_status,gates:(.gates_run|map(.name))}' <<<"$r")"
  guard="$(bash "$ROOT/.flywheel/scripts/idempotency-replay-guard.sh" --input "$ident" --ledger "$IDEMP" --lock-dir "$LOCK_DIR" --json)"
  status="$(jq -r '.status' <<<"$guard")"
  if [[ "$status" == already_completed ]]; then
    jq -c --arg ledger "$LEDGER" '.+{applied:false,ledger_path:$ledger,idempotency_status:"already_completed"}' <<<"$r"; return
  fi
  printf '%s\n' "$r" >> "$LEDGER"; line="$(wc -l < "$LEDGER" | tr -d ' ')"
  marked="$(bash "$ROOT/.flywheel/scripts/idempotency-replay-guard.sh" --input "$ident" --ledger "$IDEMP" --lock-dir "$LOCK_DIR" --mark-completed --receipt-ref "$LEDGER#L$line" --json)"
  jq -c --arg ledger "$LEDGER" --arg line "$line" --arg status "$(jq -r '.status' <<<"$marked")" '.+{applied:true,ledger_path:$ledger,ledger_line:($line|tonumber),idempotency_status:$status}' <<<"$r"
}

make_fixtures
run_gate mission_lock_output_schema '.status=="pass" and .valid==true' bash "$ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh" --mission "$TMP/mission.json" --json
run_gate dispatch_author_contract '.verdict=="pass"' bash "$ROOT/.flywheel/scripts/dispatch-author-contract-probe.sh" --dispatch "$TMP/dispatch.md" --json
run_gate close_validator_contract '.valid==true' bash "$ROOT/.flywheel/scripts/close-validator-contract-probe.sh" --callback-file "$TMP/close.json" --json
run_gate mission_lock_scaffold '.verdict=="ready"' bash "$ROOT/.flywheel/scripts/mission-lock-scaffold-validator.sh" --mission "$TMP/MISSION.md" --json
run_gate mission_lock_readiness '.mission_lock_readiness_health_score >= 1' bash "$ROOT/.flywheel/scripts/mission-lock-readiness-doctor.sh" --mission "$TMP/MISSION.md" --plan "$TMP/plan" --json
run_gate dispatch_self_test_identity '.verdict=="proceed"' bash "$ROOT/.flywheel/scripts/dispatch-self-test-delivery-identity.sh" pretest --packet "$TMP/self-test.md" --dispatch-log "$TMP/dispatch-log.jsonl" --lock-dir "$TMP/self-test-locks" --json
run_gate golden_fixture_replay_all '.status=="pass" and .fixtures_count>=7 and ([.results[].status]|all(.=="pass"))' bash "$ROOT/.flywheel/scripts/golden-fixture-replay-runner.sh" replay-all --json
run_gate golden_fixture_verify_invariants '.status=="pass"' bash "$ROOT/.flywheel/scripts/golden-fixture-replay-runner.sh" verify-invariants --json

gates_json="$(jq -s '.' "$GATES")"
if [[ "$PASS_COUNT" -eq "$TOTAL_GATES" ]]; then GATE_STATUS=PASS; SCORE=10; FIRST_JSON=null
else GATE_STATUS=FAIL; SCORE="$(jq -n --argjson p "$PASS_COUNT" --argjson t "$TOTAL_GATES" '($p/$t*10)')"; FIRST_JSON="$(jq -nc --arg v "$FIRST_FIRE" '$v')"; fi
all_closed="$(jq -e '(.audit_findings_count==18 or .total_findings_closed==18) and (.phase5_ready==true or .current_phase=="shipped")' "$PLAN_STATE" >/dev/null 2>&1 && echo true || echo false)"
if [[ "$all_closed" != true && "$GATE_STATUS" == PASS ]]; then GATE_STATUS=FAIL; SCORE=8.75; FIRST_JSON="$(jq -nc '"audit findings not closed"')"; fi

receipt="$(jq -nc --arg gate_status "$GATE_STATUS" --arg plan_slug "$PLAN_SLUG" --argjson gates_run "$gates_json" --argjson first_fire_reason "$FIRST_JSON" --argjson composite_health_score "$SCORE" --argjson all_audit_findings_closed "$all_closed" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg gate_version "$VERSION" '{gate_status:$gate_status,plan_slug:$plan_slug,gates_run:$gates_run,first_fire_reason:$first_fire_reason,composite_health_score:$composite_health_score,all_audit_findings_closed:$all_audit_findings_closed,ts:$ts,gate_version:$gate_version}')"
[[ "$APPLY" -eq 1 ]] && receipt="$(apply_receipt "$receipt")"
[[ "$JSON_OUT" -eq 1 ]] && echo "$receipt" || jq -r '"\(.gate_status) \(.plan_slug) score=\(.composite_health_score)"' <<<"$receipt"
[[ "$GATE_STATUS" == PASS ]] && exit 0
exit 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
