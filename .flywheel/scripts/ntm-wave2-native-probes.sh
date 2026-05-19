#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-32-executable-probe-source-of-truth.md and MP-36-cross-platform-matrix-proof.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="ntm-wave2-native-probes/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-wave2-native-probes-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-wave2-native-probes.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-wave2-native-probes.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-wave2-native-probes.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-wave2-native-probes.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-wave2-native-probes.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-wave2-native-probes.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
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
            && cli_emit_completion_bash "ntm-wave2-native-probes" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-wave2-native-probes" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
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
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
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
VERSION="ntm-wave2-native-probes/v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="${NTM_WAVE2_SESSION:-flywheel}"
TASK_TITLE="${NTM_WAVE2_TASK_TITLE:-flywheel native surface probe}"

usage() {
  cat <<'USAGE'
usage: ntm-wave2-native-probes.sh <surface> [--json]
surfaces: agents analytics cass config extract get-all-session-text memory resume

Agent automation:
  ntm-wave2-native-probes.sh capabilities --json
  ntm-wave2-native-probes.sh agents --json
  ntm-wave2-native-probes.sh robot-docs
  Exit codes: 0 success, 2 usage error. Missing native ntm data is returned as null fields, not a hard failure.
USAGE
}

capabilities() {
  jq -nc --arg version "$VERSION" '{
    schema_version:$version,
    command:"capabilities",
    contract_version:"1",
    features:["json_output","native_probe_bundle","null_on_native_failure","robot_docs"],
    surfaces:["agents","analytics","cass","config","extract","get-all-session-text","memory","resume"],
    commands:{
      agents:{command:"ntm-wave2-native-probes.sh agents --json",read_only:true},
      analytics:{command:"ntm-wave2-native-probes.sh analytics --json",read_only:true},
      robot_docs:{command:"ntm-wave2-native-probes.sh robot-docs",read_only:true}
    },
    exit_codes:{"0":"success","2":"usage error"},
    env_vars:{NTM_BIN:"override ntm binary",NTM_WAVE2_SESSION:"session for session-scoped probes",NTM_WAVE2_TASK_TITLE:"task title for recommendation probes"}
  }'
}

robot_docs() {
  cat <<'EOF'
NTM wave-2 native probe robot guide:
1. Discover: ntm-wave2-native-probes.sh capabilities --json
2. Probe one surface: ntm-wave2-native-probes.sh agents --json
3. Probe session text: NTM_WAVE2_SESSION=flywheel ntm-wave2-native-probes.sh extract --json
4. Treat null native payloads as unavailable native data, not script failure.
EOF
}

json_or_null() {
  local tmp rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/ntm-wave2.XXXXXX")"
  set +e
  "$@" >"$tmp" 2>/dev/null
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]] && jq -e . "$tmp" >/dev/null 2>&1; then
    jq -c . "$tmp"
  else
    printf 'null\n'
  fi
  rm -f "$tmp"
}

surface_agents() {
  local profiles stats recommendation
  profiles="$(json_or_null "$NTM_BIN" agents list --json)"
  stats="$(json_or_null "$NTM_BIN" agents stats --json)"
  recommendation="$(json_or_null "$NTM_BIN" agents recommend --title "$TASK_TITLE" --type task --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "agents" \
    --argjson profiles "$profiles" \
    --argjson stats "$stats" \
    --argjson recommendation "$recommendation" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm agents list --json","ntm agents stats --json","ntm agents recommend --json"],profiles:$profiles,stats:$stats,recommendation:$recommendation}'
}

surface_analytics() {
  local summary sessions prometheus
  summary="$(json_or_null "$NTM_BIN" analytics --format json --days 7 --json)"
  sessions="$(json_or_null "$NTM_BIN" analytics --format json --sessions --days 7 --json)"
  prometheus="$(json_or_null "$NTM_BIN" analytics --format prometheus --days 7 --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "analytics" \
    --argjson summary "$summary" \
    --argjson sessions "$sessions" \
    --argjson prometheus "$prometheus" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm analytics --format json --days 7 --json","ntm analytics --format json --sessions --json","ntm analytics --format prometheus --json"],summary:$summary,sessions:$sessions,prometheus:$prometheus}'
}

surface_cass() {
  local status search insights
  status="$(json_or_null "$NTM_BIN" cass status --json)"
  search="$(json_or_null "$NTM_BIN" cass search "substrate amnesia" --limit 5 --workspace "$PWD" --json)"
  insights="$(json_or_null "$NTM_BIN" cass insights --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "cass" \
    --argjson status_json "$status" \
    --argjson search "$search" \
    --argjson insights "$insights" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm cass status --json","ntm cass search --json","ntm cass insights --json"],cass_status:$status_json,search:$search,insights:$insights}'
}

surface_config() {
  local show validate diff
  show="$(json_or_null "$NTM_BIN" config show --json)"
  validate="$(json_or_null "$NTM_BIN" config validate --json)"
  diff="$(json_or_null "$NTM_BIN" config diff --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "config" \
    --argjson show "$show" \
    --argjson validate "$validate" \
    --argjson diff "$diff" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm config show --json","ntm config validate --json","ntm config diff --json"],show:$show,validate:$validate,diff:$diff}'
}

surface_extract() {
  local last bash_blocks all_blocks
  last="$(json_or_null "$NTM_BIN" extract "$SESSION" --last --json --lines 120)"
  bash_blocks="$(json_or_null "$NTM_BIN" extract "$SESSION" --last --lang bash --json --lines 120)"
  all_blocks="$(json_or_null "$NTM_BIN" extract "$SESSION" --json --lines 120)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "extract" \
    --arg session "$SESSION" \
    --argjson last "$last" \
    --argjson bash_blocks "$bash_blocks" \
    --argjson all_blocks "$all_blocks" \
    '{schema_version:$version,surface:$surface,status:"ok",session:$session,native_calls:["ntm extract <session> --last --json","ntm extract <session> --lang bash --json","ntm extract <session> --json"],last:$last,bash_blocks:$bash_blocks,all_blocks:$all_blocks}'
}

surface_get_all_session_text() {
  local full compact short
  full="$(json_or_null "$NTM_BIN" get-all-session-text --lines 10 --json)"
  compact="$(json_or_null "$NTM_BIN" get-all-session-text --compact --lines 10 --json)"
  short="$(json_or_null "$NTM_BIN" get-all-session-text --lines 3 --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "get-all-session-text" \
    --argjson full "$full" \
    --argjson compact "$compact" \
    --argjson short "$short" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm get-all-session-text --lines 10 --json","ntm get-all-session-text --compact --json","ntm get-all-session-text --lines 3 --json"],full:$full,compact:$compact,short:$short}'
}

surface_memory() {
  local context outcome_privacy privacy
  context="$(json_or_null "$NTM_BIN" memory context "$TASK_TITLE" --json)"
  privacy="$(json_or_null "$NTM_BIN" memory privacy --json)"
  outcome_privacy="$(json_or_null "$NTM_BIN" memory context "callback validation substrate memory" --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "memory" \
    --argjson context "$context" \
    --argjson privacy "$privacy" \
    --argjson outcome_privacy "$outcome_privacy" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm memory context <task> --json","ntm memory privacy --json","ntm memory context callback-validation --json"],context:$context,privacy:$privacy,callback_context:$outcome_privacy}'
}

surface_resume() {
  local latest dry explicit
  latest="$(json_or_null "$NTM_BIN" resume "$SESSION" --dry-run --json)"
  dry="$(json_or_null "$NTM_BIN" resume "$SESSION" --dry-run --json)"
  if [[ -n "${NTM_WAVE2_HANDOFF_FILE:-}" ]]; then
    explicit="$(json_or_null "$NTM_BIN" resume --from "$NTM_WAVE2_HANDOFF_FILE" --dry-run --json)"
  else
    explicit='null'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "resume" \
    --arg session "$SESSION" \
    --argjson latest "$latest" \
    --argjson dry "$dry" \
    --argjson explicit "$explicit" \
    '{schema_version:$version,surface:$surface,status:"ok",session:$session,native_calls:["ntm resume <session> --dry-run --json","ntm resume <session> --dry-run --json","ntm resume --from <file> --dry-run --json"],latest:$latest,dry_run:$dry,explicit:$explicit}'
}

SURFACE="${1:-}"; [[ $# -gt 0 ]] && shift || true
JSON_OUT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$SURFACE" in
  agents) payload="$(surface_agents)" ;;
  analytics) payload="$(surface_analytics)" ;;
  cass) payload="$(surface_cass)" ;;
  config) payload="$(surface_config)" ;;
  extract) payload="$(surface_extract)" ;;
  get-all-session-text) payload="$(surface_get_all_session_text)" ;;
  memory) payload="$(surface_memory)" ;;
  resume) payload="$(surface_resume)" ;;
  capabilities|--capabilities|--info) payload="$(capabilities)" ;;
  robot-docs|robot-docs-guide) payload="$(jq -Rn --arg text "$(robot_docs)" '{schema_version:"ntm-wave2-native-probes.robot_docs/v1",command:"robot-docs",text:$text}')" ;;
  --help|-h|"") usage; exit 0 ;;
  *) echo "unknown surface: $SURFACE" >&2; usage >&2; exit 2 ;;
esac

if [[ "$JSON_OUT" == "1" ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"\(.surface) status=\(.status)"' <<<"$payload"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
