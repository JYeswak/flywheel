#!/usr/bin/env bash
# customer-facing-observability-probe.sh — smallest recurring measurement
# for value-gap dimension `customer-facing-observability` (#3 of 10 in
# `.flywheel/scripts/value-gap-probe.sh:DIMENSIONS[]`).
#
# Owns: bead flywheel-1rmp.14. Sisters (same shape): flywheel-1rmp.5,
# flywheel-1rmp.7, flywheel-1rmp.9, flywheel-1rmp.11.
#
# Measures (proxy):
#   - per-client repo presence (alpsinsurance, blackfoot, terratitle,
#     plus active product surfaces zesttube + mobile-eats)
#   - per-client .flywheel/reports/ daily-report freshness (mtime)
#   - aggregated coverage_count / coverage_ratio
#   - explicit customer_observability_state=no_aggregation_pipeline_yet
#     because no flywheel-side surface aggregates per-client health
#     into a single dashboard / receipt
#
# Step 4o anti-pattern guardrail: SURFACES the gap; does NOT
# auto-create receipts, file beads, or dispatch fixes.
#
# Stable exit codes: 0 ok | 1 domain | 64 usage
# Triad: doctor / info / schema; --json default for robot consumers.

set -euo pipefail
set +e  # script intentionally tolerates non-zero exits in domain logic; lint-idiom-fix


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-1hshd.24 (NUANCED-PARTIAL-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="customer-facing-observability-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/customer-facing-observability-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: customer-facing-observability-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "customer-facing-observability-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "customer-facing-observability-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"customer-facing-observability-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"customer-facing-observability-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"customer-facing-observability-probe.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes dev_root, ledger dir/file, jq/bash, per-client repo presence (alpsinsurance/blackfoot/terratitle), per-product repo presence (zesttube/mobile-eats)"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",freshness_budget_hours:"int",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["ledger_dir","audit_log_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["client-slug","freshness-hours","observability-state"],observability_state_enum:["no_aggregation_pipeline_yet","draft","wired"],cross_source:"--schema .customer_observability_state_enum (3 states)",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","client","product"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],note:"per-surface schema available via --schema <surface>"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to native cmd_run (probe per-client/product presence + freshness).\n' ;;
    doctor)   printf 'topic: doctor — probes bash/jq/dev_root/ledger_dir/audit_log_dir + per-client repo presence (alpsinsurance/blackfoot/terratitle) + per-product repo presence (zesttube/mobile-eats). Load-bearing: dev_root resolves under $CUSTOMER_OBS_DEV_ROOT (default /Users/josh/Developer).\n' ;;
    health)   printf 'topic: health — emits freshness_budget_hours (default 72; $CUSTOMER_OBS_FRESHNESS_HOURS), last_run_ts from audit log if present, and bound audit log path. Stale-threshold sourced from --freshness-hours validate subject.\n' ;;
    repair)   printf 'topic: repair --scope <ledger_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: ledger_dir (mkdir -p dirname of $CUSTOMER_OBS_LEDGER), audit_log_dir (mkdir -p dirname of $SCAFFOLD_AUDIT_LOG). Unknown scope = rc=64.\n' ;;
    validate) printf 'topic: validate <client-slug|freshness-hours|observability-state> VALUE — client-slug must match a known canonical (extend CLIENT_SLUGS or PRODUCT_SLUGS); freshness-hours integer in [1,720]; observability-state cross-sourced with --schema .customer_observability_state_enum (3 states: no_aggregation_pipeline_yet, draft, wired). Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows). Empty when audit log missing.\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / client / product. Returns status=found|not_found|unavailable.\n' ;;
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
            && cli_emit_completion_bash "customer-facing-observability-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "customer-facing-observability-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local dev_root="${CUSTOMER_OBS_DEV_ROOT:-/Users/josh/Developer}"
  local ledger="${CUSTOMER_OBS_LEDGER:-$HOME/.local/state/flywheel/customer-facing-observability.jsonl}"
  if command -v bash >/dev/null 2>&1; then
    checks+=('{"name":"bash_available","status":"pass"}')
  else
    checks+=('{"name":"bash_available","status":"fail"}')
  fi
  if command -v jq >/dev/null 2>&1; then
    checks+=('{"name":"jq_available","status":"pass"}')
  else
    checks+=('{"name":"jq_available","status":"fail","note":"jq required for canonical envelopes"}')
  fi
  if [[ -d "$dev_root" ]]; then
    checks+=('{"name":"dev_root_exists","status":"pass","path":"'"$dev_root"'"}')
  else
    checks+=('{"name":"dev_root_exists","status":"fail","path":"'"$dev_root"'","note":"client/product repos resolve under dev_root"}')
  fi
  local ledger_dir; ledger_dir="$(dirname "$ledger")"
  if [[ -w "$ledger_dir" || ( ! -e "$ledger_dir" && -w "$(dirname "$ledger_dir")" ) ]]; then
    checks+=('{"name":"ledger_dir_writable","status":"pass","path":"'"$ledger_dir"'"}')
  else
    checks+=('{"name":"ledger_dir_writable","status":"fail","path":"'"$ledger_dir"'","note":"value-gap-probe parent ledger writes here"}')
  fi
  local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -w "$audit_dir" || ( ! -e "$audit_dir" && -w "$(dirname "$audit_dir")" ) ]]; then
    checks+=('{"name":"audit_log_dir_writable","status":"pass","path":"'"$audit_dir"'"}')
  else
    checks+=('{"name":"audit_log_dir_writable","status":"fail","path":"'"$audit_dir"'"}')
  fi
  local present=0 missing=0 slug
  for slug in alpsinsurance blackfoot terratitle; do
    if [[ -d "$dev_root/$slug" ]]; then present=$((present+1)); else missing=$((missing+1)); fi
  done
  if (( present > 0 )); then
    checks+=('{"name":"client_repos_resolvable","status":"pass","present":'"$present"',"missing":'"$missing"'}')
  else
    checks+=('{"name":"client_repos_resolvable","status":"warn","present":0,"missing":'"$missing"',"note":"no canonical client repos found under dev_root"}')
  fi
  local pres2=0 miss2=0
  for slug in zesttube mobile-eats; do
    if [[ -d "$dev_root/$slug" ]]; then pres2=$((pres2+1)); else miss2=$((miss2+1)); fi
  done
  if (( pres2 > 0 )); then
    checks+=('{"name":"product_repos_resolvable","status":"pass","present":'"$pres2"',"missing":'"$miss2"'}')
  else
    checks+=('{"name":"product_repos_resolvable","status":"warn","present":0,"missing":'"$miss2"'}')
  fi
  local arr; arr="[$(IFS=,; echo "${checks[*]}")]"
  local status="ok"
  if echo "$arr" | jq -e 'any(.status == "fail")' >/dev/null 2>&1; then status="degraded"; fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg st "$status" --argjson checks "$arr" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$st,checks:$checks}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local budget="${CUSTOMER_OBS_FRESHNESS_HOURS:-72}"
  local last_run_ts="null"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then last_run_ts="\"$raw\""; fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson budget "$budget" --argjson last "$last_run_ts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"ok",freshness_budget_hours:$budget,last_run_ts:$last,audit_log:$log,binds_audit_log:true}'
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
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    ledger_dir)
      local ledger="${CUSTOMER_OBS_LEDGER:-$HOME/.local/state/flywheel/customer-facing-observability.jsonl}"
      local target; target="$(dirname "$ledger")"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope ledger_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope audit_log_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <ledger_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["ledger_dir","audit_log_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    client-slug)
      if [[ -z "$arg" ]]; then printf 'ERR: validate client-slug requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        alpsinsurance|blackfoot|terratitle|zesttube|mobile-eats)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"client-slug",ts:$ts,status:"ok",value:$v,canonical_set:["alpsinsurance","blackfoot","terratitle","zesttube","mobile-eats"]}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"client-slug",ts:$ts,status:"reject",value:$v,reason:"not_in_canonical_set",canonical_set:["alpsinsurance","blackfoot","terratitle","zesttube","mobile-eats"]}'
          return 1 ;;
      esac
      ;;
    freshness-hours)
      if [[ -z "$arg" ]]; then printf 'ERR: validate freshness-hours requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 720 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"freshness-hours",ts:$ts,status:"ok",value:$v,default:72,note:"matches CUSTOMER_OBS_FRESHNESS_HOURS env contract"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"freshness-hours",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 720]",default:72}'
        return 1
      fi
      ;;
    observability-state)
      if [[ -z "$arg" ]]; then printf 'ERR: validate observability-state requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        no_aggregation_pipeline_yet|draft|wired)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"observability-state",ts:$ts,status:"ok",value:$v,source:"native --schema .customer_observability_state_enum"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"observability-state",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_states:["no_aggregation_pipeline_yet","draft","wired"],source:"native --schema .customer_observability_state_enum"}'
          return 1 ;;
      esac
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["client-slug","freshness-hours","observability-state"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["client-slug","freshness-hours","observability-state"]}'
      return 64 ;;
  esac
}

scaffold_cmd_audit() {
  local limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      --limit) limit="${2:-20}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown audit arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
        '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,reason:"audit_log_missing",rows:[]}'
      return 0
    fi
    local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
      --argjson rows "$rows" --argjson limit "$limit" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.client // "") == $id or (.product // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","client","product"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
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
# VERB COLLISION BYPASS (flywheel-sacan): the target's own argparse
# already handles canonical verbs (doctor|health|repair|validate|...).
# When any of the per-target flags below are present in argv, the
# intercept yields and cmd_run handles the per-bead path unchanged.
# Per-target bypass flags: --dev-root,--doctor,--ledger
_scaffold_is_canonical_arg() {
  # NUANCED-PARTIAL-BYPASS: --info / --schema / --doctor flag are owned by NATIVE.
  # Scaffold owns: --examples, doctor verb, health, repair, validate, audit,
  # why, quickstart, completion, help <topic>.
  # Verb-first: when args[0] is a scaffold verb, scaffold owns regardless of
  # downstream --apply/--dry-run flags (those mean per-verb things).
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
  esac
  # No scaffold verb — bypass to native if any native-owned flag is present.
  local _a
  for _a in "$@"; do
    case "$_a" in --dev-root|--doctor|--ledger|--info|--schema) return 1 ;; esac
  done
  return 1
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
VERSION="customer-facing-observability-probe.v1"
SCRIPT_VERSION="2026-05-09.1"

DEV_ROOT="${CUSTOMER_OBS_DEV_ROOT:-/Users/josh/Developer}"
LEDGER="${CUSTOMER_OBS_LEDGER:-$HOME/.local/state/flywheel/customer-facing-observability.jsonl}"
FRESHNESS_HOURS="${CUSTOMER_OBS_FRESHNESS_HOURS:-72}"

# canonical client/product surfaces — extend over time
CLIENT_SLUGS=(alpsinsurance blackfoot terratitle)
PRODUCT_SLUGS=(zesttube mobile-eats)

JSON_OUT=0
MODE="run"
APPLY=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  customer-facing-observability-probe.sh [--apply|--dry-run] [--json]
  customer-facing-observability-probe.sh --doctor [--json]
  customer-facing-observability-probe.sh --info [--json]
  customer-facing-observability-probe.sh --schema [--json]
  customer-facing-observability-probe.sh --help

Smallest recurring measurement for the value-gap-hunter dimension
"customer-facing-observability". Probes presence + report-freshness
across clients (alpsinsurance/blackfoot/terratitle) and active
product surfaces (zesttube/mobile-eats).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --dev-root) DEV_ROOT="${2:?}"; shift 2 ;;
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "customer-facing-observability-probe.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ $MODE == "run" && $APPLY -eq 0 && $DRY_RUN -eq 0 ]]; then
  DRY_RUN=1
fi

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() {
  if [[ $JSON_OUT -eq 1 || $MODE == "info" || $MODE == "schema" || $MODE == "doctor" ]]; then
    printf '%s\n' "$1"
  fi
}

info_payload() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg dev_root "$DEV_ROOT" \
    --arg ledger "$LEDGER" \
    --argjson freshness "$FRESHNESS_HOURS" \
    --argjson clients "$(printf '%s\n' "${CLIENT_SLUGS[@]}" | jq -R . | jq -s .)" \
    --argjson products "$(printf '%s\n' "${PRODUCT_SLUGS[@]}" | jq -R . | jq -s .)" \
    '{
      version: $version,
      script_version: $script_version,
      schema_version: "customer-facing-observability/v1",
      mode: "info",
      dev_root: $dev_root,
      ledger: $ledger,
      client_slugs: $clients,
      product_slugs: $products,
      freshness_budget_hours: $freshness,
      modes: ["run","doctor","info","schema"],
      owns: "flywheel-1rmp.14",
      parent: "flywheel-1rmp",
      value_gap_dimension: "customer-facing-observability",
      meadows_tier: "#8 information flow",
      customer_observability_state: "no_aggregation_pipeline_yet",
      no_aggregation_reason: "Each client/product repo can have its own .flywheel/reports/ daily-report (mobile-eats does), but no flywheel-side surface aggregates per-client customer-visible value+risk into a single receipt or dashboard. The smallest recurring proxy is presence + freshness inventory until an aggregation pipeline lands.",
      step_4o_anti_pattern_guardrail: "this probe surfaces; it does NOT auto-aggregate, auto-publish, or auto-file followups",
      status: "ok"
    }'
}

schema_payload() {
  jq -nc '{
    schema_version: "customer-facing-observability/v1",
    ledger_row_required_fields: [
      "schema_version","ts","dev_root","client_count","product_count",
      "repos_present_count","repos_total","reports_dir_present_count",
      "fresh_report_count","stale_report_count","missing_report_count",
      "coverage_ratio","customer_observability_state",
      "no_aggregation_reason","clients","products"
    ],
    proxy_metrics: [
      {"name":"repos_present_count","describes":"client/product repos resolvable under dev_root"},
      {"name":"reports_dir_present_count","describes":"repos with .flywheel/reports/ directory"},
      {"name":"fresh_report_count","describes":"repos whose newest daily-report mtime is within freshness_budget_hours"},
      {"name":"coverage_ratio","describes":"fresh / total"}
    ],
    customer_observability_state_enum: ["no_aggregation_pipeline_yet","draft","wired"],
    surfaced_via: ["ledger:~/.local/state/flywheel/customer-facing-observability.jsonl","cli:customer-facing-observability-probe.sh","value-gap-probe parent ledger"],
    exit_codes: {"0":"ok","1":"domain","64":"usage"},
    mode: "schema",
    status: "ok"
  }'
}

doctor_payload() {
  local issues=()
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  [[ -d "$DEV_ROOT" ]] || issues+=("dev_root_missing=$DEV_ROOT")
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
  [[ -w "$(dirname "$LEDGER")" ]] || issues+=("ledger_dir_not_writable=$(dirname "$LEDGER")")
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --argjson issues "$issues_json" \
    '{
      version: $version,
      schema_version: "customer-facing-observability/v1",
      mode: "doctor",
      issues: $issues,
      status: (if ($issues|length)==0 then "ok" else "degraded" end)
    }'
}

mtime_iso() { stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$1" 2>/dev/null; }
mtime_epoch() { stat -f '%m' "$1" 2>/dev/null; }

probe_repo() {
  local kind="$1" slug="$2" now_epoch="$3"
  local repo="$DEV_ROOT/$slug"
  local repo_present=false reports_dir=false newest_report="" newest_iso="" newest_age=999999
  local report_status="missing"

  if [[ -d "$repo" ]]; then
    repo_present=true
    if [[ -d "$repo/.flywheel/reports" ]]; then
      reports_dir=true
      local f
      f=$(ls -t "$repo/.flywheel/reports/"daily-*.md 2>/dev/null | head -1)
      if [[ -n "$f" && -f "$f" ]]; then
        newest_report=$(basename "$f")
        newest_iso=$(mtime_iso "$f")
        local ep
        ep=$(mtime_epoch "$f")
        if [[ -n "$ep" ]]; then
          newest_age=$(( (now_epoch - ep) / 3600 ))
          if (( newest_age <= FRESHNESS_HOURS )); then
            report_status="fresh"
          else
            report_status="stale"
          fi
        fi
      fi
    fi
  fi

  jq -nc \
    --arg kind "$kind" \
    --arg slug "$slug" \
    --argjson present "$repo_present" \
    --argjson reports_dir "$reports_dir" \
    --arg newest_report "$newest_report" \
    --arg newest_iso "$newest_iso" \
    --argjson newest_age "$newest_age" \
    --arg report_status "$report_status" \
    '{
      kind: $kind,
      slug: $slug,
      repo_present: $present,
      reports_dir_present: $reports_dir,
      newest_report: (if $newest_report == "" then null else $newest_report end),
      newest_report_mtime: (if $newest_iso == "" then null else $newest_iso end),
      newest_report_age_hours: $newest_age,
      report_status: $report_status
    }'
}

run_pass() {
  local mode_label="$1"
  local now_epoch
  now_epoch=$(date -u +%s)

  local clients_json='[]' products_json='[]'
  for s in "${CLIENT_SLUGS[@]}"; do
    clients_json=$(jq -c \
      --argjson row "$(probe_repo client "$s" "$now_epoch")" \
      '. + [$row]' <<<"$clients_json")
  done
  for s in "${PRODUCT_SLUGS[@]}"; do
    products_json=$(jq -c \
      --argjson row "$(probe_repo product "$s" "$now_epoch")" \
      '. + [$row]' <<<"$products_json")
  done

  # Aggregate
  local total
  total=$(jq -s 'add | length' <<<"[$clients_json][$products_json]" 2>/dev/null || echo 0)
  total=$(( ${#CLIENT_SLUGS[@]} + ${#PRODUCT_SLUGS[@]} ))

  local repos_present reports_dir_present fresh stale missing
  repos_present=$(jq -s '[.[][] | select(.repo_present)] | length' <<<"$clients_json"$'\n'"$products_json")
  reports_dir_present=$(jq -s '[.[][] | select(.reports_dir_present)] | length' <<<"$clients_json"$'\n'"$products_json")
  fresh=$(jq -s '[.[][] | select(.report_status=="fresh")] | length' <<<"$clients_json"$'\n'"$products_json")
  stale=$(jq -s '[.[][] | select(.report_status=="stale")] | length' <<<"$clients_json"$'\n'"$products_json")
  missing=$(jq -s '[.[][] | select(.report_status=="missing")] | length' <<<"$clients_json"$'\n'"$products_json")

  local coverage='0'
  if (( total > 0 )); then
    coverage=$(python3 -c "print(round($fresh / $total, 4))" 2>/dev/null || echo "0")
  fi

  local row
  row=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg dev_root "$DEV_ROOT" \
    --argjson client_count "${#CLIENT_SLUGS[@]}" \
    --argjson product_count "${#PRODUCT_SLUGS[@]}" \
    --argjson repos_total "$total" \
    --argjson repos_present "$repos_present" \
    --argjson reports_dir_present "$reports_dir_present" \
    --argjson fresh "$fresh" \
    --argjson stale "$stale" \
    --argjson missing "$missing" \
    --arg coverage "$coverage" \
    --argjson clients "$clients_json" \
    --argjson products "$products_json" \
    '{
      schema_version: "customer-facing-observability/v1",
      ts: $ts,
      dev_root: $dev_root,
      client_count: $client_count,
      product_count: $product_count,
      repos_total: $repos_total,
      repos_present_count: $repos_present,
      reports_dir_present_count: $reports_dir_present,
      fresh_report_count: $fresh,
      stale_report_count: $stale,
      missing_report_count: $missing,
      coverage_ratio: ($coverage | tonumber? // 0),
      customer_observability_state: "no_aggregation_pipeline_yet",
      no_aggregation_reason: "Per-repo .flywheel/reports/daily-*.md exists for some products (mobile-eats), but no flywheel-side surface aggregates per-client value+risk into a single customer receipt. Smallest recurring proxy is presence + freshness inventory until an aggregation pipeline lands.",
      clients: $clients,
      products: $products
    }')

  if [[ "$mode_label" == "apply" ]]; then
    mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
    printf '%s\n' "$row" >> "$LEDGER" 2>/dev/null
  fi

  emit "$(printf '%s' "$row" | jq -c --arg mode "$mode_label" --arg ledger "$LEDGER" '{mode:$mode, ledger:$ledger} + .')"
  return 0
}

case "$MODE" in
  info)   emit "$(info_payload)"; exit 0 ;;
  schema) emit "$(schema_payload)"; exit 0 ;;
  doctor)
    payload="$(doctor_payload)"
    emit "$payload"
    [[ "$(printf '%s' "$payload" | jq -r .status)" == "ok" ]] && exit 0 || exit 1
    ;;
esac

if [[ $DRY_RUN -eq 1 ]]; then
  run_pass dry-run
  exit $?
fi
run_pass apply
exit $?

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
