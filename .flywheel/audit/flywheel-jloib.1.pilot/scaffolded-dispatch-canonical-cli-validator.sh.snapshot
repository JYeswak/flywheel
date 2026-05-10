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
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-canonical-cli-validator/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-canonical-cli-validator-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-canonical-cli-validator.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-canonical-cli-validator.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-canonical-cli-validator.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-canonical-cli-validator.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-canonical-cli-validator.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-canonical-cli-validator.sh doctor --json"}'
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
            && cli_emit_completion_bash "dispatch-canonical-cli-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-canonical-cli-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="dispatch-canonical-cli-validator/v1"
SCHEMA_VERSION="dispatch-canonical-cli-decision/v1"
LEDGER="${DISPATCH_CANONICAL_CLI_LEDGER:-$HOME/.local/state/flywheel/dispatch-canonical-cli-validator-ledger.jsonl}"
DISPATCH_FILE=""
DISPATCH_STDIN=0
JSON_OUT=0

usage() {
  cat <<'USAGE'
usage:
  dispatch-canonical-cli-validator.sh check --dispatch-file PATH [--json]
  dispatch-canonical-cli-validator.sh check --dispatch-stdin [--json]
  dispatch-canonical-cli-validator.sh --info|--help|--examples [--json]

Validates that dispatch packets introducing CLI surfaces include canonical
CLI scoping acceptance gates before dispatch is sent.

Exit codes:
  0  allow
  1  refuse
  2  usage error or malformed dispatch packet fail-open
USAGE
}

examples() {
  cat <<'EXAMPLES'
dispatch-canonical-cli-validator.sh check --dispatch-file /tmp/dispatch_abc123.md --json
dispatch-canonical-cli-validator.sh check --dispatch-stdin --json < /tmp/dispatch_abc123.md
DISPATCH_CANONICAL_CLI_LEDGER=/tmp/ledger.jsonl dispatch-canonical-cli-validator.sh check --dispatch-file fixture.md
EXAMPLES
}

info() {
  jq -nc \
    --arg name "dispatch-canonical-cli-validator.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger "$LEDGER" \
    '{
      name:$name,
      version:$version,
      schema_version:$schema_version,
      ledger:$ledger,
      purpose:"pre-dispatch canonical-cli-scoping acceptance gate",
      output_schema:".flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json",
      exit_codes:{"0":"allow","1":"refuse","2":"usage or malformed dispatch fail-open"}
    }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")"
  jq -c . <<<"$row" >>"$LEDGER"
}

missing_array_json() {
  if [[ "$#" -eq 0 ]]; then
    printf '[]'
    return 0
  fi
  printf '%s\n' "$@" | jq -R -s -c 'split("\n")[:-1]'
}

emit_decision() {
  local decision="$1" introduces_cli="$2" reason="$3" exit_code="$4"
  shift 4
  local missing_json payload
  missing_json="$(missing_array_json "$@")"
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg decision "$decision" \
    --argjson introduces_cli "$introduces_cli" \
    --argjson missing_elements "$missing_json" \
    --arg reason "$reason" \
    --arg ledger "$LEDGER" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      decision:$decision,
      introduces_cli:$introduces_cli,
      missing_elements:$missing_elements,
      reason:$reason,
      ledger_appended:$ledger
    }')"
  append_ledger "$payload" || true
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"decision=\(.decision) introduces_cli=\(.introduces_cli) reason=\(.reason) missing=\(.missing_elements|join(","))"' <<<"$payload"
  fi
  exit "$exit_code"
}

contains_ci() {
  grep -Eiq "$1" <<<"$2"
}

has_markdown_shape() {
  [[ "${#1}" -ge 20 ]] && grep -Eq '^#{1,6}[[:space:]]+' <<<"$1"
}

introduces_cli_surface() {
  local text="$1"
  if contains_ci '(^|[[:space:]`"])\.flywheel/scripts/[^[:space:]`")]+\.sh' "$text"; then
    return 0
  fi
  if contains_ci '(^|[[:space:]])--(info|help|examples|json)([[:space:]|,`.)]|$)' "$text"; then
    return 0
  fi
  if contains_ci '\b(CLI|command|flag|subcommand|operator-facing tool)\b' "$text"; then
    return 0
  fi
  return 1
}

has_info_help_examples() {
  local text="$1"
  if grep -Fq -- '--info|--help|--examples' <<<"$text"; then
    return 0
  fi
  grep -Fq -- '--info' <<<"$text" \
    && grep -Fq -- '--help' <<<"$text" \
    && grep -Fq -- '--examples' <<<"$text"
}

has_json_output() {
  local text="$1"
  grep -Fq -- '--json' <<<"$text" \
    && contains_ci '(json output|output[^[:alpha:]]+.*--json|--json.*output|machine-readable)' "$text"
}

has_exit_codes() {
  local text="$1"
  if contains_ci '(canonical-cli-scoping.*exit codes stable|exit codes stable.*canonical-cli-scoping)' "$text"; then
    return 0
  fi
  contains_ci 'exit[- ]codes?' "$text" \
    && contains_ci '(^|[^0-9])0[[:space:]]*[:=]' "$text" \
    && contains_ci '(^|[^0-9])1[[:space:]]*[:=]' "$text" \
    && contains_ci '(^|[^0-9])2[[:space:]]*[:=]' "$text"
}

has_canonical_skill() {
  local text="$1"
  grep -Fqi -- 'canonical-cli-scoping' <<<"$text" \
    && contains_ci '(skill|SKILL\.md|skills consulted|acceptance gate)' "$text"
}

run_check() {
  local body missing=()
  if [[ -n "$DISPATCH_FILE" ]]; then
    [[ -r "$DISPATCH_FILE" ]] || fail_usage "dispatch file not readable: $DISPATCH_FILE"
    body="$(<"$DISPATCH_FILE")"
  elif [[ "$DISPATCH_STDIN" -eq 1 ]]; then
    body="$(cat)"
  else
    fail_usage "check requires --dispatch-file or --dispatch-stdin"
  fi

  if ! has_markdown_shape "$body"; then
    emit_decision "allow" "false" "malformed_dispatch_packet_fail_open" 2
  fi

  if ! introduces_cli_surface "$body"; then
    emit_decision "allow" "false" "not_introducing_cli" 0
  fi

  has_info_help_examples "$body" || missing+=("info_help_examples")
  has_json_output "$body" || missing+=("json")
  has_exit_codes "$body" || missing+=("exit_codes")
  has_canonical_skill "$body" || missing+=("canonical_cli_skill")

  if [[ "${#missing[@]}" -eq 0 ]]; then
    emit_decision "allow" "true" "canonical_cli_acceptance_present" 0
  fi
  emit_decision "refuse" "true" "dispatch_packet_missing_canonical_cli_acceptance" 1 "${missing[@]}"
}

if [[ "$#" -eq 0 ]]; then
  fail_usage "missing command"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) shift ;;
    --dispatch-file) DISPATCH_FILE="${2:-}"; shift 2 ;;
    --dispatch-file=*) DISPATCH_FILE="${1#*=}"; shift ;;
    --dispatch-stdin) DISPATCH_STDIN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

[[ "$DISPATCH_STDIN" -eq 0 || -z "$DISPATCH_FILE" ]] || fail_usage "use either --dispatch-file or --dispatch-stdin"
run_check
