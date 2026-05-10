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

SCAFFOLD_SCHEMA_VERSION="validate-skill-discovery-callback/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/validate-skill-discovery-callback-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: validate-skill-discovery-callback.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "validate-skill-discovery-callback.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "validate-skill-discovery-callback.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"validate-skill-discovery-callback.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"validate-skill-discovery-callback.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"validate-skill-discovery-callback.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?"]}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","example-callback-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","example_callback?"]}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","envelope","sd-id-format"],fields:["status","subject","valid?","missing?","reason?","sd_ids?","skill_discoveries?"]}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"sd-<token>|reason_code"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["ts","command","schema_version"],optional:["status","reason_code","skill_discoveries","sd_ids"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"validate-skill-discovery-callback: structural validator for callback envelope skill_discoveries+ sd_ids fields"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — original validator: --callback STR or --callback-file PATH validates skill_discoveries + sd_ids field presence + sd-<token> format.\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: jq, awk, tr, bash version (4+ required for readarray), audit log readability.\n' ;;
    health)   printf 'topic: health — tails audit log; warns if no row in >7d (validator runs per callback close, not on a cadence).\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), example-callback-prime (read-only — emit known-good callback template). --apply requires --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: --row-json <JSON>, --schema, --config, --envelope <STR> (structural callback parse), --sd-id-format <ID> (sd-<token> regex).\n' ;;
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
            && cli_emit_completion_bash "validate-skill-discovery-callback" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "validate-skill-discovery-callback" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Substrate: jq (envelopes), awk (field_value extraction), tr (callback splitting),
  # bash 4+ (readarray + IFS read -r -a sd_ids), and audit log directory presence.
  local checks=""
  local overall="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail",detail:"jq required for envelope emission"}')"$'\n'
    overall="fail"
  fi

  if command -v awk >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v awk)" '{name:"awk_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"awk_on_path",status:"fail",detail:"awk required for field_value extraction"}')"$'\n'
    overall="fail"
  fi

  if command -v tr >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v tr)" '{name:"tr_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"tr_on_path",status:"fail",detail:"tr required for callback splitting"}')"$'\n'
    overall="fail"
  fi

  # bash 4+ required for IFS=',' read -r -a (associative-like array)
  local bash_major="${BASH_VERSION%%.*}"
  if [[ -n "$bash_major" && "$bash_major" -ge 4 ]]; then
    checks+="$(jq -nc --arg v "$BASH_VERSION" '{name:"bash_version_4_plus",status:"pass",value:$v}')"$'\n'
  else
    checks+="$(jq -nc --arg v "${BASH_VERSION:-unknown}" '{name:"bash_version_4_plus",status:"fail",detail:"bash 4+ required for IFS read -r -a",value:$v}')"$'\n'
    overall="fail"
  fi

  # Audit log directory present (writable parent so cli_audit_append can land)
  local log_dir; log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$log_dir" || -w "$(dirname "$log_dir")" ]]; then
    checks+="$(jq -nc --arg p "$log_dir" '{name:"audit_log_dir_writable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$log_dir" '{name:"audit_log_dir_writable",status:"warn",detail:"audit log dir + parent both missing",value:$p}')"$'\n'
  fi

  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  # Tail audit log; warn if no row in >7d (validator runs per-callback, not on cadence).
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  if [[ ! -r "$log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,stale_seconds:null,reason:"audit_log_missing"}'
    return 0
  fi
  local last_row last_ts last_epoch now_epoch stale_seconds status
  last_row="$(tail -n 1 "$log" 2>/dev/null || true)"
  if [[ -z "$last_row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,stale_seconds:null,reason:"audit_log_empty"}'
    return 0
  fi
  last_ts="$(printf '%s' "$last_row" | jq -r '.ts // empty' 2>/dev/null || true)"
  now_epoch="$(date -u +%s)"
  if [[ -n "$last_ts" ]]; then
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
    if [[ "$last_epoch" -gt 0 ]]; then
      stale_seconds=$((now_epoch - last_epoch))
    else
      stale_seconds=-1
    fi
  else
    stale_seconds=-1
  fi
  if [[ "$stale_seconds" -lt 0 ]]; then
    status="warn"
  elif [[ "$stale_seconds" -gt 604800 ]]; then
    status="warn"
  else
    status="pass"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row}'
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
      if [[ -r "$log" ]]; then
        size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      fi
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
    example-callback-prime)
      # Read-only: emit a known-good callback envelope template that this
      # validator will accept. Useful for operators authoring new callbacks.
      local example_pass="DONE flywheel-example task_id=example skill_discoveries=1 sd_ids=sd-example-pattern"
      local example_zero="DONE flywheel-example task_id=example skill_discoveries=0 sd_ids=none"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg ep "$example_pass" --arg ez "$example_zero" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,example_callback_with_discovery:$ep,example_callback_zero_discoveries:$ez,note:"read-only template emit; pipe into validator via --callback to confirm"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","example-callback-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json="" envelope="" sd_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --envelope) subject="envelope"; envelope="${2:-}"; shift 2 ;;
      --envelope=*) subject="envelope"; envelope="${1#--envelope=}"; shift ;;
      --sd-id-format) subject="sd-id-format"; sd_id="${2:-}"; shift 2 ;;
      --sd-id-format=*) subject="sd-id-format"; sd_id="${1#--sd-id-format=}"; shift ;;
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
      local jq_ok=false awk_ok=false tr_ok=false bash_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      command -v awk >/dev/null 2>&1 && awk_ok=true
      command -v tr >/dev/null 2>&1 && tr_ok=true
      local bash_major="${BASH_VERSION%%.*}"
      if [[ -n "$bash_major" && "$bash_major" -ge 4 ]]; then bash_ok=true; fi
      local overall=pass
      if [[ "$jq_ok" != true || "$awk_ok" != true || "$tr_ok" != true || "$bash_ok" != true ]]; then
        overall=fail
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson aw "$awk_ok" --argjson trr "$tr_ok" --argjson bv "$bash_ok" \
        --arg bashv "${BASH_VERSION:-unknown}" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,awk_present:$aw,tr_present:$trr,bash_version_4_plus:$bv,bash_version:$bashv}'
      ;;
    envelope)
      # Structural callback parse: looks for skill_discoveries= + sd_ids= tokens.
      if [[ -z "$envelope" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"envelope",status:"fail",reason:"--envelope <STR> required"}'
        return 0
      fi
      local sd_count sd_ids_val has_sd_count="false" has_sd_ids="false"
      sd_count="$(printf '%s' "$envelope" | tr ' ' '\n' | awk -F= '$1 == "skill_discoveries" {print substr($0, length($1)+2); exit}')"
      sd_ids_val="$(printf '%s' "$envelope" | tr ' ' '\n' | awk -F= '$1 == "sd_ids" {print substr($0, length($1)+2); exit}')"
      [[ -n "$sd_count" ]] && has_sd_count="true"
      [[ -n "$sd_ids_val" ]] && has_sd_ids="true"
      local valid="false" reason=""
      if [[ "$has_sd_count" == "true" && "$has_sd_ids" == "true" ]]; then
        valid="true"; reason="ok"
      elif [[ "$has_sd_count" != "true" ]]; then
        reason="missing_skill_discoveries"
      else
        reason="missing_sd_ids"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" \
        --arg c "$sd_count" --arg i "$sd_ids_val" --arg r "$reason" \
        '{schema_version:$sv,command:"validate",subject:"envelope",status:(if $v then "pass" else "fail" end),valid:$v,skill_discoveries:$c,sd_ids:$i,reason:$r}'
      ;;
    sd-id-format)
      if [[ -z "$sd_id" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"sd-id-format",status:"fail",reason:"--sd-id-format <ID> required"}'
        return 0
      fi
      local sd_valid="false"
      if [[ "$sd_id" =~ ^sd-[A-Za-z0-9._-]+$ ]]; then sd_valid="true"; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$sd_valid" --arg id "$sd_id" \
        '{schema_version:$sv,command:"validate",subject:"sd-id-format",status:(if $v then "pass" else "fail" end),valid:$v,sd_id:$id,pattern:"^sd-[A-Za-z0-9._-]+$"}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","envelope","sd-id-format"],usage:"validate --row-json JSON or --schema or --config or --envelope STR or --sd-id-format ID"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","envelope","sd-id-format"]}'
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
      --argjson rows "$rows" --argjson count "$count" \
      '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # Search audit log for matching sd-id token or reason_code in past validator runs.
  local matches="[]" status="not_found"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    matches="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '. // []' 2>/dev/null || echo '[]')"
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    if [[ "$n" -gt 0 ]]; then status="found"; fi
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
json=0
callback=""
callback_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --callback) callback="${2:-}"; shift 2 ;;
    --callback-file) callback_file="${2:-}"; shift 2 ;;
    --json) json=1; shift ;;
    *) printf 'ERR unknown_arg=%s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ -n "$callback_file" ]]; then
  callback="$(<"$callback_file")"
fi

emit() {
  local status="$1" reason="$2" count="$3" ids="$4"
  if [[ "$json" -eq 1 ]]; then
    jq -nc \
      --arg status "$status" \
      --arg reason_code "$reason" \
      --arg skill_discoveries "$count" \
      --arg sd_ids "$ids" \
      '{
        schema_version:"skill-discovery-callback-validator/v1",
        status:$status,
        reason_code:$reason_code,
        skill_discoveries:($skill_discoveries|tonumber?),
        sd_ids:$sd_ids
      }'
  else
    printf 'status=%s reason_code=%s skill_discoveries=%s sd_ids=%s\n' "$status" "$reason" "$count" "$ids"
  fi
}

field_value() {
  local key="$1"
  tr ' ' '\n' <<<"$callback" | awk -F= -v key="$key" '$1 == key {print substr($0, length(key) + 2); found=1; exit} END {if (!found) exit 1}'
}

count="$(field_value skill_discoveries 2>/dev/null || true)"
ids="$(field_value sd_ids 2>/dev/null || true)"

if [[ -z "$count" ]]; then
  emit fail missing_skill_discoveries 0 "${ids:-missing}"
  exit 1
fi
if [[ -z "$ids" ]]; then
  emit fail missing_sd_ids "$count" missing
  exit 1
fi
if [[ ! "$count" =~ ^[0-9]+$ ]]; then
  emit fail skill_discoveries_not_numeric 0 "$ids"
  exit 1
fi
if [[ "$count" -eq 0 ]]; then
  if [[ "$ids" == "none" ]]; then
    emit pass ok "$count" "$ids"
    exit 0
  fi
  emit fail sd_ids_present_with_zero "$count" "$ids"
  exit 1
fi
if [[ "$ids" == "none" ]]; then
  emit fail skill_discovery_ids_missing "$count" "$ids"
  exit 1
fi

IFS=',' read -r -a id_array <<<"$ids"
if [[ "${#id_array[@]}" -ne "$count" ]]; then
  emit fail sd_ids_count_mismatch "$count" "$ids"
  exit 1
fi
for id in "${id_array[@]}"; do
  if [[ ! "$id" =~ ^sd-[A-Za-z0-9._-]+$ ]]; then
    emit fail sd_id_invalid "$count" "$ids"
    exit 1
  fi
done

emit pass ok "$count" "$ids"
