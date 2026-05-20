#!/usr/bin/env bash
# Tail skillos routing decisions without writing to skillos-owned routed JSONL.
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

SCAFFOLD_SCHEMA_VERSION="skillos-routed-tail/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/skillos-routed-tail-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: skillos-routed-tail.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "skillos-routed-tail.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "skillos-routed-tail.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"skillos-routed-tail.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"skillos-routed-tail.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"skillos-routed-tail.sh doctor --json"}'
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
            && cli_emit_completion_bash "skillos-routed-tail" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "skillos-routed-tail" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="2026-05-03"
ROUTED_FILE="${SKILLOS_ROUTED_PATH:-$HOME/.local/state/flywheel/skillos-routed.jsonl}"
MARKER_FILE="${SKILLOS_MARKER_PATH:-$HOME/.local/state/flywheel/skillos-routed-tail.last_seen}"

since=""
source_session=""
json=0
since_override=0
mode="run"

usage() {
  cat <<'EOF'
Usage: skillos-routed-tail.sh [--since <iso>] [--source-session <name>] [--json]

Options:
  --since <iso>              Read rows newer than this timestamp instead of marker.
  --source-session <name>    Filter rows that include matching source_session.
  --json                     Machine-readable summary with rows and decisions.
  --info                     Print version, paths, env defaults, and exit codes.
  --examples                 Print usage examples.
  --schema                   Emit output schema.
  --no-color                 Accepted for deterministic logs.
  --no-emoji                 Accepted for deterministic logs.
  --width <n>                Accepted for deterministic logs.

Exit codes:
  0 rows found
  1 no rows
  2 usage error
EOF
}

examples() {
  cat <<'EOF'
# Tick integration: read new skillos routing decisions and advance marker
skillos-routed-tail.sh --json

# Audit without touching marker
skillos-routed-tail.sh --since 2026-05-03T00:00:00Z --json

# Filter rows that carry source_session
skillos-routed-tail.sh --source-session flywheel --json
EOF
}

schema() {
  cat <<'EOF'
{
  "type": "object",
  "required": ["status", "count", "since", "routed_file", "marker_file", "rows", "decisions"],
  "properties": {
    "status": {"enum": ["rows_found", "no_rows"]},
    "count": {"type": "integer"},
    "since": {"type": "string"},
    "routed_file": {"type": "string"},
    "marker_file": {"type": "string"},
    "marker_advanced_to": {"type": ["string", "null"]},
    "rows": {"type": "array"},
    "decisions": {"type": "array", "items": {"type": "object"}}
  }
}
EOF
}

info() {
  if [ "$json" -eq 1 ]; then
    jq -nc --arg version "$VERSION" --arg routed_file "$ROUTED_FILE" --arg marker_file "$MARKER_FILE" \
      '{name:"skillos-routed-tail.sh", version:$version, routed_file:$routed_file, marker_file:$marker_file, exit_codes:{rows_found:0, no_rows:1, usage:2}}'
  else
    cat <<EOF
skillos-routed-tail.sh $VERSION
routed_file=$ROUTED_FILE
marker_file=$MARKER_FILE
env_overrides=SKILLOS_ROUTED_PATH,SKILLOS_MARKER_PATH
exit_codes=0 rows found; 1 no rows; 2 usage
EOF
  fi
}

die_usage() {
  echo "ERROR: $1" >&2
  usage >&2
  exit 2
}

need_value() {
  if [ "$#" -lt 2 ] || [[ "$2" == --* ]]; then
    die_usage "$1 requires a value"
  fi
}

safe_stamp() {
  date -u +%Y%m%dT%H%M%SZ
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --since=*) since="${1#*=}"; since_override=1; shift ;;
    --since) need_value "$@"; since="$2"; since_override=1; shift 2 ;;
    --source-session=*) source_session="${1#*=}"; shift ;;
    --source-session) need_value "$@"; source_session="$2"; shift 2 ;;
    --json) json=1; shift ;;
    --info) mode="info"; shift ;;
    --examples) mode="examples"; shift ;;
    --schema) mode="schema"; shift ;;
    --no-color|--no-emoji) shift ;;
    --width=*) shift ;;
    --width) need_value "$@"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

if [ "$mode" = "info" ]; then
  if [ "$json" -eq 1 ]; then
    command -v jq >/dev/null 2>&1 || die_usage "jq is required for --json"
  fi
  info
  exit 0
fi
if [ "$mode" = "examples" ]; then
  examples
  exit 0
fi
if [ "$mode" = "schema" ]; then
  schema
  exit 0
fi

command -v jq >/dev/null 2>&1 || die_usage "jq is required"

if [ -z "$since" ]; then
  if [ -f "$MARKER_FILE" ]; then
    since="$(tr -d '\n' < "$MARKER_FILE")"
  else
    since="1970-01-01T00:00:00Z"
  fi
fi

if [ ! -f "$ROUTED_FILE" ]; then
  if [ "$json" -eq 1 ]; then
    jq -nc --arg since "$since" --arg routed_file "$ROUTED_FILE" --arg marker_file "$MARKER_FILE" \
      '{status:"no_rows",count:0,since:$since,routed_file:$routed_file,marker_file:$marker_file,marker_advanced_to:null,rows:[],decisions:[]}'
  fi
  exit 1
fi

rows="$(jq -c --arg since "$since" --arg source_session "$source_session" '
  select((.ts // "") > $since)
  | select($source_session == "" or ((.source_session // .source_session_name // "") == $source_session))
' "$ROUTED_FILE" 2>/dev/null || true)"

count="$(printf '%s\n' "$rows" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$count" -eq 0 ]; then
  if [ "$json" -eq 1 ]; then
    jq -nc --arg since "$since" --arg routed_file "$ROUTED_FILE" --arg marker_file "$MARKER_FILE" \
      '{status:"no_rows",count:0,since:$since,routed_file:$routed_file,marker_file:$marker_file,marker_advanced_to:null,rows:[],decisions:[]}'
  fi
  exit 1
fi

rows_json="$(printf '%s\n' "$rows" | jq -s '.')"
decisions_json="$(printf '%s\n' "$rows" | jq -s '
  group_by((.decision // "unknown") + "\u0000" + ((.target_skill_id // "") | tostring))
  | map({decision:(.[0].decision // "unknown"), target_skill_id:(.[0].target_skill_id // null), count:length})
')"
max_ts="$(printf '%s\n' "$rows" | jq -r -s 'map(.ts // empty) | max // empty')"
marker_advanced_to="null"

if [ "$since_override" -eq 0 ] && [ -n "$max_ts" ]; then
  mkdir -p "$(dirname "$MARKER_FILE")"
  if [ -f "$MARKER_FILE" ]; then
    cp "$MARKER_FILE" "$MARKER_FILE.bak.$(safe_stamp)"
  fi
  tmp="$(mktemp "${MARKER_FILE}.tmp.XXXXXX")"
  printf '%s\n' "$max_ts" > "$tmp"
  mv "$tmp" "$MARKER_FILE"
  marker_advanced_to="$max_ts"
fi

if [ "$json" -eq 1 ]; then
  jq -nc \
    --arg status "rows_found" \
    --arg since "$since" \
    --arg routed_file "$ROUTED_FILE" \
    --arg marker_file "$MARKER_FILE" \
    --arg marker_advanced_to "$marker_advanced_to" \
    --argjson count "$count" \
    --argjson rows "$rows_json" \
    --argjson decisions "$decisions_json" \
    '{status:$status,count:$count,since:$since,routed_file:$routed_file,marker_file:$marker_file,marker_advanced_to:(if $marker_advanced_to == "null" then null else $marker_advanced_to end),rows:$rows,decisions:$decisions}'
else
  printf '%s\n' "$rows"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
