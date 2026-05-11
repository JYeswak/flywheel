# recovery-install-plist-canonical-cli.sh
# Shared canonical-cli helper for the recovery-install-plist-* script family.
# Sourced by per-client scripts that set SCAFFOLD_BASENAME before sourcing.
#
# Bead: flywheel-mbt3z (P3 extract from wzjo9.2.4-2.7 family)
# Family: recovery-install-plist-{alpsinsurance,clutterfreespaces,mobile-eats,skillos}.sh
#
# What this lib defines (the 6 truly-identical-across-the-family helpers):
#   scaffold_usage          — heredoc usage banner
#   scaffold_emit_info      — `--info` envelope
#   scaffold_emit_examples  — `--examples` envelope
#   scaffold_emit_quickstart — `quickstart` envelope
#   scaffold_emit_completion — bash/zsh completion emitter
#   scaffold_main           — top-level dispatcher
#
# What this lib intentionally does NOT define (these are per-client divergent
# and stay inline in each per-client script):
#   scaffold_emit_schema     — per-client schema shapes (different fields)
#   scaffold_emit_topic_help — per-client topic content
#   scaffold_cmd_doctor      — per-client substrate probes
#   scaffold_cmd_health      — per-client last-run summarization
#   scaffold_cmd_repair      — per-client repair scopes
#   scaffold_cmd_validate    — per-client validation subjects
#   scaffold_cmd_audit       — per-client audit tail
#   scaffold_cmd_why         — per-client id semantics
#
# Audit (mbt3z, 2026-05-11): post-fillin divergence analysis across the 4
# scripts shows 6 functions are byte-identical-after-name-strip; 8 functions
# diverged during 18-TODO fillin by different workers (wzjo9.2.4..2.7). The
# limited extraction preserves the per-client divergence as ACK'd by the
# bead's "defer if separate workers each take one" apply-spec.
#
# Required env (set by sourcing script BEFORE source line):
#   SCAFFOLD_BASENAME         — script filename with .sh suffix
#                                (e.g., "recovery-install-plist-alpsinsurance.sh")
#   SCAFFOLD_SCHEMA_VERSION   — schema version string for emitted envelopes
#                                (e.g., "recovery-install-plist-alpsinsurance/v1")
#
# Optional env (defaults derived):
#   SCAFFOLD_BASENAME_NOEXT   — basename sans .sh (auto-derived if unset)
#
# Bash function dispatch is dynamic by name: `scaffold_main` calls
# `scaffold_cmd_doctor` and `scaffold_emit_schema` by name; those resolve to
# whatever definitions exist in the same process when `scaffold_main` runs.
# So per-client scripts MUST define their divergent functions BEFORE calling
# `scaffold_main "$@"`.

# Derive SCAFFOLD_BASENAME_NOEXT from SCAFFOLD_BASENAME if not set.
: "${SCAFFOLD_BASENAME_NOEXT:=${SCAFFOLD_BASENAME%.sh}}"

scaffold_usage() {
  cat <<USG
usage: ${SCAFFOLD_BASENAME} [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as \`cmd_run\`).

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "$SCAFFOLD_BASENAME" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "$SCAFFOLD_BASENAME" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc --arg name "$SCAFFOLD_BASENAME" '{name:"default run",invocation:$name,purpose:"backward-compatible original behavior"}')"$'\n'"$(jq -nc --arg name "$SCAFFOLD_BASENAME" '{name:"doctor",invocation:($name + " doctor --json"),purpose:"probe substrate health"}')"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc --arg cmd "$SCAFFOLD_BASENAME doctor --json" '{step:1,action:"probe doctor",command:$cmd}')"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) if command -v cli_emit_completion_bash >/dev/null; then
            cli_emit_completion_bash "$SCAFFOLD_BASENAME_NOEXT" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples"
          else
            printf '# helper lib missing — completion unavailable\n'
          fi ;;
    zsh)  if command -v cli_emit_completion_zsh >/dev/null; then
            cli_emit_completion_zsh "$SCAFFOLD_BASENAME_NOEXT" "doctor,health,repair,validate,audit,why,quickstart,help,completion"
          else
            printf '# helper lib missing — completion unavailable\n'
          fi ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
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
