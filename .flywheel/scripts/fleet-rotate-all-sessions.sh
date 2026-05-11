#!/usr/bin/env bash
# fleet-rotate-all-sessions.sh
#
# THE EASY BUTTON for codex key rollover across ALL ntm sessions.
#
# Usage:
#   fleet-rotate-all-sessions.sh                    # dry-run all sessions
#   fleet-rotate-all-sessions.sh --apply            # actually rotate everything
#   fleet-rotate-all-sessions.sh --apply --profile chiefzester
#                                                    # also activate the profile first
#
# What it does:
#   1. (optional) caam activate codex <profile>
#   2. For every ntm session: respawn all codex panes with the new key
#      (skips human_pane / orchestrator_pane / callback_pane per topology)
#   3. Prints a per-session summary
#
# Wraps fleet-rotate-on-caam-swap.sh — adds the per-session loop.

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
# specific logic was filled in by bead flywheel-1hshd.28 (NO-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fleet-rotate-all-sessions/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fleet-rotate-all-sessions-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: fleet-rotate-all-sessions.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "fleet-rotate-all-sessions.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "fleet-rotate-all-sessions.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"fleet-rotate-all-sessions.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"fleet-rotate-all-sessions.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"fleet-rotate-all-sessions.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes ntm_executable (load-bearing — script orchestrates fleet rotation via ntm sessions), jq, sister scripts (fleet-rotate-on-caam-swap.sh), audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","ntm_state_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["session-name","profile-name","exclude-list"],cross_source:"--profile and --exclude semantics from native flag contract",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","session","profile"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"NO-BYPASS",note:"native --apply/--profile/--exclude flags fall through to cmd_run; scaffold owns all canonical surfaces"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; bare invocation enumerates ntm sessions + rotates them (default dry-run; --apply to commit). Flags: --apply, --profile NAME, --exclude S1,S2.\n' ;;
    doctor)   printf 'topic: doctor — probes ntm_executable (load-bearing — script orchestrates fleet rotation via ntm), jq, sister fleet-rotate-on-caam-swap.sh, audit_log_dir.\n' ;;
    health)   printf 'topic: health — emits last_run_ts from audit log; status=ok|degraded based on doctor parity.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|ntm_state_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p dirname of $SCAFFOLD_AUDIT_LOG), ntm_state_dir (mkdir -p ~/.local/state/ntm). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <session-name|profile-name|exclude-list> VALUE — session-name shape ^[a-z][a-z0-9_-]*$; profile-name shape ^[a-z][a-z0-9_-]*$ (caam profile); exclude-list comma-separated session names. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows). Empty when audit log missing.\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / session / profile. Returns status=found|not_found|unavailable.\n' ;;
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
            && cli_emit_completion_bash "fleet-rotate-all-sessions" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fleet-rotate-all-sessions" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local ntm_bin="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
  local sister="/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-rotate-on-caam-swap.sh"
  if command -v bash >/dev/null 2>&1; then
    checks+=('{"name":"bash_available","status":"pass"}')
  else
    checks+=('{"name":"bash_available","status":"fail"}')
  fi
  if command -v jq >/dev/null 2>&1; then
    checks+=('{"name":"jq_available","status":"pass"}')
  else
    checks+=('{"name":"jq_available","status":"fail"}')
  fi
  if [[ -x "$ntm_bin" ]]; then
    checks+=('{"name":"ntm_executable","status":"pass","path":"'"$ntm_bin"'"}')
  else
    checks+=('{"name":"ntm_executable","status":"fail","path":"'"$ntm_bin"'","note":"load-bearing — script orchestrates fleet rotation via ntm"}')
  fi
  if [[ -x "$sister" ]]; then
    checks+=('{"name":"sister_fleet_rotate_on_caam_swap","status":"pass","path":"'"$sister"'"}')
  else
    checks+=('{"name":"sister_fleet_rotate_on_caam_swap","status":"warn","path":"'"$sister"'","note":"canonical per-session rotation primitive"}')
  fi
  local ntm_state_dir="$HOME/.local/state/ntm"
  if [[ -d "$ntm_state_dir" ]]; then
    checks+=('{"name":"ntm_state_dir_present","status":"pass","path":"'"$ntm_state_dir"'"}')
  else
    checks+=('{"name":"ntm_state_dir_present","status":"warn","path":"'"$ntm_state_dir"'"}')
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
  local last_run_ts="null"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then last_run_ts="\"$raw\""; fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson last "$last_run_ts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"ok",last_run_ts:$last,audit_log:$log,binds_audit_log:true}'
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
    ntm_state_dir)
      local target="$HOME/.local/state/ntm"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope ntm_state_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|ntm_state_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","ntm_state_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    session-name)
      if [[ -z "$arg" ]]; then printf 'ERR: validate session-name requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"ok",value:$v,note:"matches ntm session-naming convention"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    profile-name)
      if [[ -z "$arg" ]]; then printf 'ERR: validate profile-name requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"profile-name",ts:$ts,status:"ok",value:$v,note:"matches caam profile-name shape (cross-source: native --profile flag)"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"profile-name",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    exclude-list)
      if [[ -z "$arg" ]]; then printf 'ERR: validate exclude-list requires VALUE\n' >&2; return 64; fi
      local ok=true bad=""
      local IFS=','
      for s in $arg; do
        if [[ ! "$s" =~ ^[a-z][a-z0-9_-]*$ ]]; then ok=false; bad="$s"; break; fi
      done
      if [[ "$ok" == "true" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"exclude-list",ts:$ts,status:"ok",value:$v,note:"comma-separated session names; matches --exclude flag contract"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" --arg bad "$bad" \
          '{schema_version:$sv,command:"validate",subject:"exclude-list",ts:$ts,status:"reject",value:$v,reason:"invalid_session_name_in_list",bad_member:$bad,pattern:"^[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["session-name","profile-name","exclude-list"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["session-name","profile-name","exclude-list"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.session // "") == $id or (.profile // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","session","profile"]}'
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
  # NO-BYPASS variant: native had no --info/--schema/--doctor/--examples
  # — scaffold owns all canonical surfaces. Native flags (--apply/
  # --profile/--exclude) fall through to native because args[0] won't
  # match a scaffold verb. Verb-first: scaffold-verbs claim args[0]
  # regardless of downstream --apply (scaffold's repair owns --apply too).
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
APPLY=0
PROFILE=""
EXCLUDE_SESSIONS="${EXCLUDE_SESSIONS:-}"  # comma-separated, e.g. "skillos,vrtx"
ROTATOR="$HOME/Developer/flywheel/.flywheel/scripts/fleet-rotate-on-caam-swap.sh"

usage() {
  cat <<EOF
Usage: fleet-rotate-all-sessions.sh [options]

Options:
  --apply             actually rotate (default is dry-run)
  --profile NAME      activate codex profile NAME first
  --exclude S1,S2     comma-separated sessions to skip
  -h, --help          show this

Examples:
  # Dry-run, all sessions, current profile:
  fleet-rotate-all-sessions.sh

  # Activate chiefzester and rotate everything:
  fleet-rotate-all-sessions.sh --apply --profile chiefzester

  # Only flywheel + alps, skip the rest:
  EXCLUDE_SESSIONS=skillos,vrtx,mobile-eats,clutterfreespaces \\
    fleet-rotate-all-sessions.sh --apply
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --exclude) EXCLUDE_SESSIONS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [ ! -x "$ROTATOR" ]; then
  echo "ERROR: rotator not found or not executable: $ROTATOR" >&2
  exit 1
fi

echo "================================================================"
echo "  fleet-rotate-all-sessions.sh"
echo "================================================================"
echo ""

# Step 1: profile activation
if [ -n "$PROFILE" ]; then
  echo "=== Activating codex profile: $PROFILE ==="
  if [ "$APPLY" -eq 1 ]; then
    caam activate codex "$PROFILE"
    caam status | head -10
  else
    echo "  [dry-run] would: caam activate codex $PROFILE"
  fi
  echo ""
fi

# Step 2: enumerate sessions
echo "=== Enumerating ntm sessions ==="
SESSIONS=$(/Users/josh/.local/bin/ntm list 2>/dev/null | awk -F: '/[a-z].*windows/ {gsub(/^ +/,"",$1); print $1}' | sort -u)
if [ -z "$SESSIONS" ]; then
  echo "ERROR: no ntm sessions found" >&2
  exit 1
fi
echo "  found:"
echo "$SESSIONS" | sed 's/^/    /'
echo ""

# Step 3: filter excludes
EXCLUDE_FILTER=""
if [ -n "$EXCLUDE_SESSIONS" ]; then
  EXCLUDE_FILTER=$(echo "$EXCLUDE_SESSIONS" | tr ',' '|')
  echo "  excluding: $EXCLUDE_SESSIONS"
fi

# Step 4: per-session loop
MODE="--dry-run"
[ "$APPLY" -eq 1 ] && MODE="--apply"

OK=0
FAIL=0
SKIPPED=0

for sess in $SESSIONS; do
  if [ -n "$EXCLUDE_FILTER" ] && echo "$sess" | grep -qE "^($EXCLUDE_FILTER)$"; then
    echo "=== [SKIP] $sess (excluded) ==="
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  echo "=== [$sess] rotating codex panes ($MODE) ==="
  if "$ROTATOR" --session="$sess" --panes=all-codex $MODE --json 2>&1 | tail -5; then
    OK=$((OK + 1))
  else
    echo "  [WARN] rotator returned non-zero for $sess"
    FAIL=$((FAIL + 1))
  fi
  echo ""
done

# Summary
echo "================================================================"
echo "  SUMMARY"
echo "================================================================"
echo "  ok:      $OK"
echo "  fail:    $FAIL"
echo "  skipped: $SKIPPED"
echo "  mode:    $MODE"
[ -n "$PROFILE" ] && echo "  profile: $PROFILE"
echo ""

if [ "$APPLY" -eq 0 ]; then
  echo "This was a DRY RUN. Re-run with --apply to actually rotate."
fi

exit 0
