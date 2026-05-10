#!/usr/bin/env bash
# br-authority-probe.sh — flywheel-side diagnostic equivalent of the upstream
# `br authority` command sketched in `bead-isolation-fix-2026-04-30.md` Change
# 4.3. Reports DB path, mutability, discovery method, source_repo (last-touched),
# and walk-up status without requiring an upstream patch in beads_rust.
#
# Boundary: read-only against the local `br` install + the current working
# directory's `.beads/` resolution path. Never writes to any beads DB.
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

SCAFFOLD_SCHEMA_VERSION="br-authority-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/br-authority-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: br-authority-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "br-authority-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "br-authority-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"br-authority-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"br-authority-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"br-authority-probe.sh doctor --json"}'
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
            && cli_emit_completion_bash "br-authority-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "br-authority-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  # Canonical pattern (per L4 lint rule — NEVER use `[[ ]] && X || Y`
  # as the last expression of a helper; use if/then/else/fi):
  #   if [[ -d "$ROOT/.flywheel" ]]; then
  #     printf '{"check":"flywheel-dir","status":"pass"}\n'
  #   else
  #     printf '{"check":"flywheel-dir","status":"fail"}\n'
  #   fi
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
SCHEMA_VERSION="br-authority-probe.v1"
BR_BIN="${BR_AUTHORITY_BR_BIN:-$(command -v br 2>/dev/null || echo /Users/josh/.cargo/bin/br)}"
TARGET_DIR="${BR_AUTHORITY_TARGET_DIR:-$PWD}"

MODE=run
JSON_OUT=0

usage() {
  cat <<'USAGE'
usage: br-authority-probe.sh [--target-dir PATH] [--json]
       br-authority-probe.sh --doctor|--health|--schema|--info [--json]

Reports authority/discovery metadata for the local br install + a target
directory's .beads resolution path:

  - br_bin:           path to the resolved br executable
  - br_version:       output of `br --version`
  - target_dir:       resolved absolute path of the target directory
  - db_path:          .beads/beads.db path discovered from target_dir
  - db_writable:      whether the discovered DB file is writable by the user
  - discovery_method: local | walk-up | none | strict-error
  - walk_up_distance: directory levels traversed to find .beads (0 = same dir)
  - walk_up_dirs:     ordered list of paths walked
  - source_repo_last: source_repo field on the most-recent-touched row, if any
  - is_symlink:       whether the resolved .beads is a symlink
  - symlink_target:   resolved target if .beads is a symlink (absolute)
  - cross_tree:       true if symlink target is outside target_dir tree
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg bin "$BR_BIN" \
    '{schema_version:$schema, success:true, mode:"doctor",
      br_bin_present:($bin | test("^/")),
      native_surface:["br --version","br where","br list --json"],
      reads_only:true}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      fields:["br_bin","br_version","target_dir","db_path","db_writable","discovery_method","walk_up_distance","walk_up_dirs","source_repo_last","is_symlink","symlink_target","cross_tree"]}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        br_bin:{type:"string"},
        br_version:{type:"string"},
        target_dir:{type:"string"},
        db_path:{type:["string","null"]},
        db_writable:{type:"boolean"},
        discovery_method:{type:"string", enum:["local","walk-up","none","strict-error"]},
        walk_up_distance:{type:"integer"},
        walk_up_dirs:{type:"array"},
        source_repo_last:{type:["string","null"]},
        is_symlink:{type:"boolean"},
        symlink_target:{type:["string","null"]},
        cross_tree:{type:"boolean"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir) TARGET_DIR="${2:?--target-dir requires PATH}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -x "$BR_BIN" ]] || { echo "ERR: br binary not executable: $BR_BIN" >&2; exit 2; }

TARGET_DIR_ABS="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
  echo "ERR: target dir does not exist: $TARGET_DIR" >&2; exit 2; }

BR_VERSION="$("$BR_BIN" --version 2>/dev/null | head -1 || echo unknown)"

# Walk up from TARGET_DIR_ABS until .beads is found or root reached.
DB_PATH=""
DISCOVERY_METHOD="none"
WALK_UP_DISTANCE=0
WALK_UP_DIRS_TMP="$(mktemp "${TMPDIR:-/tmp}/br-authority.XXXXXX")"
trap 'rm -f "$WALK_UP_DIRS_TMP"' EXIT
: >"$WALK_UP_DIRS_TMP"

probe_dir="$TARGET_DIR_ABS"
while :; do
  printf '%s\n' "$probe_dir" >>"$WALK_UP_DIRS_TMP"
  if [[ -d "$probe_dir/.beads" ]]; then
    DB_PATH="$probe_dir/.beads/beads.db"
    if [[ "$probe_dir" == "$TARGET_DIR_ABS" ]]; then
      DISCOVERY_METHOD="local"
    else
      DISCOVERY_METHOD="walk-up"
    fi
    break
  fi
  parent="$(dirname "$probe_dir")"
  [[ "$parent" == "$probe_dir" ]] && break
  probe_dir="$parent"
  WALK_UP_DISTANCE=$((WALK_UP_DISTANCE + 1))
done

# If BEADS_STRICT_LOCAL=1 was the operating mode and discovery walked up, that's a strict-error.
if [[ "${BEADS_STRICT_LOCAL:-0}" == "1" && "$DISCOVERY_METHOD" == "walk-up" ]]; then
  DISCOVERY_METHOD="strict-error"
fi

DB_WRITABLE=false
if [[ -n "$DB_PATH" && -w "$DB_PATH" ]]; then DB_WRITABLE=true; fi

IS_SYMLINK=false
SYMLINK_TARGET=""
CROSS_TREE=false
if [[ -n "$DB_PATH" ]]; then
  beads_dir="$(dirname "$DB_PATH")"
  if [[ -L "$beads_dir" ]]; then
    IS_SYMLINK=true
    SYMLINK_TARGET="$(readlink -f "$beads_dir" 2>/dev/null || readlink "$beads_dir")"
    if [[ -n "$SYMLINK_TARGET" && "$SYMLINK_TARGET" != "$TARGET_DIR_ABS"* ]]; then
      CROSS_TREE=true
    fi
  fi
fi

SOURCE_REPO_LAST=""
if [[ "$DISCOVERY_METHOD" != "strict-error" && "$DISCOVERY_METHOD" != "none" ]]; then
  SOURCE_REPO_LAST="$(cd "$TARGET_DIR_ABS" && "$BR_BIN" list --limit 1 --json 2>/dev/null | jq -r '.issues[0].source_repo // ""' 2>/dev/null || echo "")"
fi

# Build walk_up_dirs JSON array.
WALK_UP_DIRS_JSON="$(jq -R -s 'split("\n") | map(select(length > 0))' "$WALK_UP_DIRS_TMP")"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg br_bin "$BR_BIN" \
  --arg br_version "$BR_VERSION" \
  --arg target_dir "$TARGET_DIR_ABS" \
  --arg db_path "$DB_PATH" \
  --argjson db_writable "$DB_WRITABLE" \
  --arg discovery_method "$DISCOVERY_METHOD" \
  --argjson walk_up_distance "$WALK_UP_DISTANCE" \
  --argjson walk_up_dirs "$WALK_UP_DIRS_JSON" \
  --arg source_repo_last "$SOURCE_REPO_LAST" \
  --argjson is_symlink "$IS_SYMLINK" \
  --arg symlink_target "$SYMLINK_TARGET" \
  --argjson cross_tree "$CROSS_TREE" \
  '{schema_version:$schema, success:true, mode:"run",
    br_bin:$br_bin, br_version:$br_version, target_dir:$target_dir,
    db_path:(if $db_path == "" then null else $db_path end),
    db_writable:$db_writable,
    discovery_method:$discovery_method,
    walk_up_distance:$walk_up_distance,
    walk_up_dirs:$walk_up_dirs,
    source_repo_last:(if $source_repo_last == "" then null else $source_repo_last end),
    is_symlink:$is_symlink,
    symlink_target:(if $symlink_target == "" then null else $symlink_target end),
    cross_tree:$cross_tree}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"br-authority target=\(.target_dir) db=\(.db_path // "none") method=\(.discovery_method) walk_up=\(.walk_up_distance) symlink=\(.is_symlink) cross_tree=\(.cross_tree) source_repo_last=\(.source_repo_last // "none")"' <<<"$PAYLOAD"
fi
