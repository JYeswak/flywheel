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
# specific logic was filled in by bead flywheel-1hshd.30 (NO-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="flywheel-codex-stuck-detector-install/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/flywheel-codex-stuck-detector-install-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: flywheel-codex-stuck-detector-install.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "flywheel-codex-stuck-detector-install.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "flywheel-codex-stuck-detector-install.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"flywheel-codex-stuck-detector-install.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"flywheel-codex-stuck-detector-install.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"flywheel-codex-stuck-detector-install.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes launchctl/plutil/jq, label (ai.zeststream.flywheel-codex-stuck-detector), source_plist (.flywheel/launchd/), install_plist (~/Library/LaunchAgents/), audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",loaded:"bool",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","launchagents_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["label","plist-path","install-mode"],install_mode_enum:["dry_run","apply"],label_namespace:"ai.zeststream.*",cross_source:"native --apply/--dry-run flag contract",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","label","plist"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"NO-BYPASS",note:"native --apply/--dry-run/--json flags fall through to cmd_run; scaffold owns all canonical surfaces"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; installs codex-stuck-detector LaunchAgent (label=ai.zeststream.flywheel-codex-stuck-detector). Flags: --apply, --dry-run (default), --json.\n' ;;
    doctor)   printf 'topic: doctor — probes launchctl/plutil/jq, install_plist (~/Library/LaunchAgents/ai.zeststream.flywheel-codex-stuck-detector.plist), source_plist (.flywheel/launchd/), audit_log_dir.\n' ;;
    health)   printf 'topic: health — emits loaded state (launchctl list) + last_run_ts from audit log.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|launchagents_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p dirname of $SCAFFOLD_AUDIT_LOG), launchagents_dir (mkdir -p ~/Library/LaunchAgents). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <label|plist-path|install-mode> VALUE — label must match ai.zeststream.* namespace; plist-path must end in .plist + be readable; install-mode enum {dry_run, apply} cross-sourced with native --apply/--dry-run. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows).\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / label / plist.\n' ;;
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
            && cli_emit_completion_bash "flywheel-codex-stuck-detector-install" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "flywheel-codex-stuck-detector-install" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local label="ai.zeststream.flywheel-codex-stuck-detector"
  local install_plist="$HOME/Library/LaunchAgents/${label}.plist"
  local source_plist="/Users/josh/Developer/flywheel/.flywheel/launchd/${label}.plist"
  if command -v launchctl >/dev/null 2>&1; then checks+=('{"name":"launchctl_available","status":"pass"}')
  else checks+=('{"name":"launchctl_available","status":"fail","note":"required for load/unload on macOS"}'); fi
  if command -v plutil >/dev/null 2>&1; then checks+=('{"name":"plutil_available","status":"pass"}')
  else checks+=('{"name":"plutil_available","status":"fail","note":"required for plist validation"}'); fi
  if command -v jq >/dev/null 2>&1; then checks+=('{"name":"jq_available","status":"pass"}')
  else checks+=('{"name":"jq_available","status":"fail"}'); fi
  if [[ -r "$source_plist" ]]; then
    checks+=('{"name":"source_plist_present","status":"pass","path":"'"$source_plist"'"}')
  else
    checks+=('{"name":"source_plist_present","status":"fail","path":"'"$source_plist"'","note":"load-bearing — installer copies from .flywheel/launchd/"}')
  fi
  if [[ -r "$install_plist" ]]; then
    checks+=('{"name":"install_plist_present","status":"pass","path":"'"$install_plist"'"}')
  else
    checks+=('{"name":"install_plist_present","status":"warn","path":"'"$install_plist"'","note":"agent not installed yet; run with --apply"}')
  fi
  local launchagents_dir="$HOME/Library/LaunchAgents"
  if [[ -d "$launchagents_dir" ]]; then
    checks+=('{"name":"launchagents_dir_present","status":"pass","path":"'"$launchagents_dir"'"}')
  else
    checks+=('{"name":"launchagents_dir_present","status":"warn","path":"'"$launchagents_dir"'"}')
  fi
  local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -w "$audit_dir" || ( ! -e "$audit_dir" && -w "$(dirname "$audit_dir")" ) ]]; then
    checks+=('{"name":"audit_log_dir_writable","status":"pass","path":"'"$audit_dir"'"}')
  else
    checks+=('{"name":"audit_log_dir_writable","status":"fail","path":"'"$audit_dir"'"}')
  fi
  local arr; arr="[$(IFS=,; echo "${checks[*]}")]"
  local status="ok"
  if echo "$arr" | jq -e 'any(.status == "fail")' >/dev/null 2>&1; then status="degraded"; fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg st "$status" --argjson checks "$arr" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$st,checks:$checks}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local label="ai.zeststream.flywheel-codex-stuck-detector"
  local loaded=false
  if command -v launchctl >/dev/null 2>&1 && launchctl list 2>/dev/null | grep -q "$label"; then loaded=true; fi
  local last_run_ts="null"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then last_run_ts="\"$raw\""; fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --arg label "$label" --argjson loaded "$loaded" --argjson last "$last_run_ts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"ok",label:$label,loaded:$loaded,last_run_ts:$last,audit_log:$log,binds_audit_log:true}'
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
    launchagents_dir)
      local target="$HOME/Library/LaunchAgents"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope launchagents_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|launchagents_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","launchagents_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    label)
      if [[ -z "$arg" ]]; then printf 'ERR: validate label requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^ai\.zeststream\.[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"label",ts:$ts,status:"ok",value:$v,note:"matches ai.zeststream.* namespace"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"label",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^ai\\.zeststream\\.[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    plist-path)
      if [[ -z "$arg" ]]; then printf 'ERR: validate plist-path requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" == *.plist ]] && [[ -r "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"plist-path",ts:$ts,status:"ok",value:$v,note:"file exists + .plist extension"}'
        return 0
      elif [[ "$arg" != *.plist ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"plist-path",ts:$ts,status:"reject",value:$v,reason:"unsupported_extension",hint:"must end in .plist"}'
        return 1
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"plist-path",ts:$ts,status:"reject",value:$v,reason:"file_not_readable"}'
        return 1
      fi
      ;;
    install-mode)
      if [[ -z "$arg" ]]; then printf 'ERR: validate install-mode requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        dry_run|apply)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"install-mode",ts:$ts,status:"ok",value:$v,source:"native --apply/--dry-run flag contract"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"install-mode",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_modes:["dry_run","apply"]}'
          return 1 ;;
      esac
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["label","plist-path","install-mode"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["label","plist-path","install-mode"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.label // "") == $id or (.plist // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","label","plist"]}'
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
_scaffold_is_canonical_arg() {
  # NO-BYPASS variant (verb-first): scaffold owns all canonical surfaces;
  # native --apply/--dry-run/--json flags fall through to cmd_run for the
  # LaunchAgent install/uninstall lifecycle. Verb-first: scaffold's repair
  # verb owns --apply/--dry-run too.
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
  esac
  return 1
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
VERSION="flywheel-codex-stuck-detector-install.v1.0.0"
SCHEMA_VERSION="flywheel-codex-stuck-detector.install.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DETECTOR="${FLYWHEEL_CODEX_STUCK_DETECTOR:-$SCRIPT_DIR/codex-template-stuck-detector.sh}"
LABEL="${FLYWHEEL_CODEX_STUCK_DETECTOR_LABEL:-ai.zeststream.flywheel-codex-stuck-detector}"
LAUNCH_AGENTS_DIR="${FLYWHEEL_CODEX_STUCK_DETECTOR_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
PLIST_PATH="${FLYWHEEL_CODEX_STUCK_DETECTOR_PLIST_PATH:-$LAUNCH_AGENTS_DIR/$LABEL.plist}"
STATE_DIR="${FLYWHEEL_CODEX_STUCK_DETECTOR_STATE_DIR:-$HOME/.local/state/flywheel}"
BOOTSTRAP_DOMAIN="${FLYWHEEL_CODEX_STUCK_DETECTOR_BOOTSTRAP_DOMAIN:-gui/$UID}"
LAUNCHCTL="${FLYWHEEL_CODEX_STUCK_DETECTOR_LAUNCHCTL:-launchctl}"
PLUTIL="${FLYWHEEL_CODEX_STUCK_DETECTOR_PLUTIL:-plutil}"
APPLY=0
JSON_OUT=0

usage() { printf '%s\n' "Usage: flywheel-codex-stuck-detector-install.sh [--apply|--dry-run] [--json]"; }

write_plist() {
  local command
  mkdir -p "$LAUNCH_AGENTS_DIR" "$STATE_DIR"
  command='set -euo pipefail; topo="${TMPDIR:-/tmp}/codex-stuck-detector-flywheel-topology.jsonl"; jq -c '\''select(.session=="flywheel")'\'' "$HOME/.local/state/flywheel/session-topology.jsonl" | jq -s -c '\''group_by(.session) | map(max_by(.effective_at))[]'\'' > "$topo"; jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg session "flywheel" --arg label "'"$LABEL"'" '\''{schema_version:"codex-stuck-detector.launchd-fire.v1",event:"launchd_fire",ts:$ts,session:$session,label:$label}'\''; CODEX_STUCK_DETECTOR_TOPOLOGY="$topo" exec "'"$DETECTOR"'" --session flywheel --worker-panes-from-topology --apply --auto-recover --json'
  cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>$command</string>
  </array>
  <key>StartInterval</key>
  <integer>60</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$STATE_DIR/codex-stuck-detector.flywheel.log</string>
  <key>StandardErrorPath</key>
  <string>$STATE_DIR/codex-stuck-detector.flywheel.err</string>
</dict>
</plist>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

loaded=false
print_exit=1
plutil_exit=0
if (( APPLY )); then
  write_plist
  "$PLUTIL" -lint "$PLIST_PATH" >/dev/null || plutil_exit=$?
  "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  "$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$PLIST_PATH"
  "$LAUNCHCTL" kickstart -k "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  if "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1; then
    loaded=true
    print_exit=0
  fi
fi

payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION" --arg version "$VERSION" --arg label "$LABEL" --arg plist "$PLIST_PATH" --arg domain "$BOOTSTRAP_DOMAIN" --arg detector "$DETECTOR" --argjson apply "$APPLY" --argjson loaded "$loaded" --argjson plutil_exit "$plutil_exit" --argjson print_exit "$print_exit" '{schema_version:$schema_version,version:$version,success:($plutil_exit == 0),label:$label,plist_path:$plist,bootstrap_domain:$domain,detector:$detector,interval_seconds:60,apply:($apply == 1),dry_run:($apply == 0),loaded:$loaded,plutil_exit:$plutil_exit,launchctl_print_exit:$print_exit}')"
if (( JSON_OUT )); then
  printf '%s\n' "$payload"
else
  printf '%s\n' "$payload" | jq -r '"flywheel-codex-stuck-detector-install label=\(.label) loaded=\(.loaded) dry_run=\(.dry_run)"'
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
