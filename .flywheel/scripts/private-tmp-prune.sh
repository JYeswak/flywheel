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

SCAFFOLD_SCHEMA_VERSION="private-tmp-prune/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/private-tmp-prune-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: private-tmp-prune.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "private-tmp-prune.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "private-tmp-prune.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"private-tmp-prune.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"private-tmp-prune.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"private-tmp-prune.sh doctor --json"}'
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
            && cli_emit_completion_bash "private-tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "private-tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
SCRIPT_VERSION="private-tmp-prune.v2"
APPLY=0
JSON_OUT=0
IDEMPOTENCY_KEY="${PRIVATE_TMP_PRUNE_IDEMPOTENCY_KEY:-}"
MIN_AGE_HOURS="${PRIVATE_TMP_PRUNE_MIN_AGE_HOURS:-6}"
TARGET_DIR="${PRIVATE_TMP_PRUNE_TARGET:-/private/tmp}"
LEDGER="${PRIVATE_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/private-tmp-prune.jsonl}"
NTM_BIN="${NTM_BIN:-ntm}"

ALLOWLIST_PATTERNS=(
  "jsm-auth-isolation." "jsm-health-sandbox." "jsm-doctor-" "jsm-wrapper-"
  "beads-rust-" "beads_rust-" "mobile-eats-next-dev-cache-" "mobile-eats-next-failed-density-"
  "mobile-eats-next-cache-" "mobile-eats-next-stale-" "mobile-eats-next-dev-stale-"
  "mobile-eats-*-validate*" "mobile-eats-*-verify*" "mobile-eats-*-build-*"
  "mobile-eats-*-check" "mobile-eats-stale-*" "alps-demo-smoke-"
  "alpsinsurance-demo-" "alpsinsurance-smoke-"
  "br_recovery.archived-" "beads-pre-nuclear-restart-" "issues.jsonl.pre-nuclear-"
  "beads.db.pre-nuclear-" "beads-recovery-sandbox."
)

usage() { printf '%s\n' "Usage: private-tmp-prune.sh [--dry-run|--apply --idempotency-key KEY] [--json] [--min-age-hours N] [--target DIR]" "Default dry-run; ntm temp cleanup delegates to ntm cleanup."; }

while [ $# -gt 0 ]; do
  case "$1" in
    doctor|health|run) shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --min-age-hours) MIN_AGE_HOURS="$2"; shift 2 ;;
    --target) TARGET_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    completion) printf '%s\n' 'complete -W "doctor health run --json --dry-run --apply --idempotency-key --min-age-hours --target completion --help" private-tmp-prune.sh'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$TARGET_DIR" in /private/tmp|/tmp|/var/folders/*|/var/tmp/*) ;; *) echo "ERROR: refused target: $TARGET_DIR" >&2; exit 2 ;; esac
[ -d "$TARGET_DIR" ] || { echo "ERROR: target dir missing: $TARGET_DIR" >&2; exit 2; }
if [ "$APPLY" -eq 1 ] && [ -z "$IDEMPOTENCY_KEY" ]; then
  echo "ERROR: --apply requires --idempotency-key KEY" >&2
  exit 2
fi

is_allowlisted() {
  local name="$1" pattern
  for pattern in "${ALLOWLIST_PATTERNS[@]}"; do
    case "$pattern" in
      *[\*\?\[]*) case "$name" in $pattern) return 0 ;; esac ;;
    *) case "$name" in "${pattern}"*) return 0 ;; esac ;;
    esac
  done
  return 1
}

age_hours() { local now mtime; now="$(date +%s)"; mtime="$(stat -f %m "$1" 2>/dev/null || echo "$now")"; echo $(((now - mtime) / 3600)); }

has_open_handles() { lsof "$1" 2>/dev/null | tail -n +2 | grep -q .; }

ntm_cleanup() { if [ "$APPLY" -eq 1 ]; then TMPDIR="$TARGET_DIR" "$NTM_BIN" cleanup --max-age "$MIN_AGE_HOURS" --json; else TMPDIR="$TARGET_DIR" "$NTM_BIN" cleanup --dry-run --max-age "$MIN_AGE_HOURS" --json; fi; }

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NTM_JSON="$(ntm_cleanup 2>/dev/null || jq -nc '{error:"ntm_cleanup_failed"}')"
CANDIDATES_JSONL="$(mktemp "${TMPDIR:-/tmp}/private-tmp-prune.XXXXXX")"
trap 'rm -f "$CANDIDATES_JSONL"' EXIT
SKIP_NOT_ALLOWLISTED=0; SKIP_TOO_YOUNG=0; SKIP_OPEN=0; SKIP_NOT_DIR=0

for path in "$TARGET_DIR"/*; do
  [ -e "$path" ] || continue
  name="$(basename "$path")"
  if ! is_allowlisted "$name"; then SKIP_NOT_ALLOWLISTED=$((SKIP_NOT_ALLOWLISTED + 1)); continue; fi
  if [ ! -d "$path" ]; then SKIP_NOT_DIR=$((SKIP_NOT_DIR + 1)); continue; fi
  age="$(age_hours "$path")"
  if [ "$age" -lt "$MIN_AGE_HOURS" ]; then SKIP_TOO_YOUNG=$((SKIP_TOO_YOUNG + 1)); continue; fi
  if [ "$APPLY" -eq 1 ] && has_open_handles "$path"; then SKIP_OPEN=$((SKIP_OPEN + 1)); continue; fi
  jq -nc --arg path "$path" --argjson age "$age" '{path:$path,age_hours:$age,size_kb:0}' >>"$CANDIDATES_JSONL"
done

if [ "$APPLY" -eq 1 ] && [ -s "$CANDIDATES_JSONL" ]; then
  mkdir -p "$(dirname "$LEDGER")"
  while IFS= read -r row; do
    path="$(jq -r '.path' <<<"$row")"
    case "$path" in
      "$TARGET_DIR"/*)
        /usr/bin/python3 -c 'import os, shutil, sys; p=sys.argv[1]; shutil.rmtree(p) if os.path.isdir(p) else os.unlink(p)' "$path" &&
          jq -nc --arg ts "$TS" --arg key "$IDEMPOTENCY_KEY" --arg path "$path" '{ts:$ts,action:"removed",idempotency_key:$key,path:$path}' >>"$LEDGER"
        ;;
    esac
  done <"$CANDIDATES_JSONL"
fi

RESULT="$(jq -sc \
  --arg schema "$SCRIPT_VERSION" --arg ts "$TS" --arg target "$TARGET_DIR" --argjson apply "$APPLY" \
  --argjson min_age "$MIN_AGE_HOURS" --argjson ntm "$NTM_JSON" --argjson skip_na "$SKIP_NOT_ALLOWLISTED" \
  --argjson skip_young "$SKIP_TOO_YOUNG" --argjson skip_open "$SKIP_OPEN" --argjson skip_nd "$SKIP_NOT_DIR" \
  '{schema_version:$schema,ts:$ts,target:$target,apply:($apply == 1),dry_run:($apply != 1),min_age_hours:$min_age,
    ntm_cleanup:$ntm,flywheel_candidates:.,flywheel_candidates_count:length,
    flywheel_total_size_kb:(map(.size_kb // 0) | add // 0),
    skipped:{not_allowlisted:$skip_na,too_young:$skip_young,open_handles:$skip_open,not_dir:$skip_nd},
    split_contract:{ntm_temp_cleanup:"ntm cleanup",flywheel_allowlist_cleanup:"private-tmp-prune.sh"}}' "$CANDIDATES_JSONL")"

if [ "$JSON_OUT" -eq 1 ]; then
  printf '%s\n' "$RESULT"
else
  jq -r '"private-tmp-prune dry_run=\(.dry_run) ntm_files=\(.ntm_cleanup.total_files // 0) flywheel_candidates=\(.flywheel_candidates_count) flywheel_size_kb=\(.flywheel_total_size_kb)"' <<<"$RESULT"
fi
