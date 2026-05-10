#!/usr/bin/env bash
# Synthetic regression test for sync-canonical-doctrine.sh.
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

SCAFFOLD_SCHEMA_VERSION="test-sync-canonical-doctrine/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/test-sync-canonical-doctrine-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: test-sync-canonical-doctrine.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "test-sync-canonical-doctrine.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "test-sync-canonical-doctrine.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"test-sync-canonical-doctrine.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"test-sync-canonical-doctrine.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"test-sync-canonical-doctrine.sh doctor --json"}'
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
            && cli_emit_completion_bash "test-sync-canonical-doctrine" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "test-sync-canonical-doctrine" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
ROOT="/Users/josh/Developer/flywheel"
SYNC="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
BEGIN="<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
END="<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-canonical-doctrine-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

CANONICAL="$TMP/source/AGENTS.md"
mkdir -p "$(dirname "$CANONICAL")"
printf '# Canonical doctrine\n\n## L61 - synthetic ecosystem rule\nbody\n\n## L70 - synthetic no-punt rule\nbody\n' >"$CANONICAL"

for repo in repo-a repo-b repo-c; do
  mkdir -p "$TMP/repos/$repo/.flywheel"
done
cp "$CANONICAL" "$TMP/repos/repo-a/.flywheel/AGENTS-CANONICAL.md"
printf 'old doctrine\n' >"$TMP/repos/repo-b/.flywheel/AGENTS-CANONICAL.md"
printf 'older doctrine\n' >"$TMP/repos/repo-c/.flywheel/AGENTS-CANONICAL.md"

printf '# Repo A local instructions\n\nKeep this line.\n' >"$TMP/repos/repo-a/AGENTS.md"
printf '# Repo B local instructions\n\n%s\nstale block\n%s\n\nKeep after block.\n' "$BEGIN" "$END" >"$TMP/repos/repo-b/AGENTS.md"

rc=0
dry="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json 2>&1)" || rc=$?
if [[ "$rc" -ne 1 ]]; then
  printf 'FAIL: dry-run expected rc=1 for drift, got %s\n%s\n' "$rc" "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.canonical_drifted_count' <<<"$dry")" != "2" ]]; then
  printf 'FAIL: dry-run expected canonical_drifted_count=2\n%s\n' "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.root_drifted_count' <<<"$dry")" != "3" ]]; then
  printf 'FAIL: dry-run expected root_drifted_count=3\n%s\n' "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '[.root_details[] | select(.status=="drifted" and (.missing_rules | index("L70")))] | length' <<<"$dry")" != "3" ]]; then
  printf 'FAIL: dry-run expected L70 root drift detection for all repos\n%s\n' "$dry" >&2
  exit 1
fi

apply="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --apply --json)"
if [[ "$(jq -r '.status' <<<"$apply")" != "ok" || "$(jq -r '.canonical_synced_count' <<<"$apply")" != "2" || "$(jq -r '.root_synced_count' <<<"$apply")" != "3" ]]; then
  printf 'FAIL: apply expected status=ok canonical_synced_count=2 root_synced_count=3\n%s\n' "$apply" >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-b/.flywheel"/AGENTS-CANONICAL.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-b canonical snapshot backup missing before overwrite\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'old doctrine' "$TMP/repos/repo-b/.flywheel"/AGENTS-CANONICAL.md.bak.*; then
  printf 'FAIL: repo-b canonical snapshot backup did not preserve prior content\n' >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-a"/AGENTS.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-a root AGENTS.md backup missing before canonical block insert\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'Keep this line.' "$TMP/repos/repo-a"/AGENTS.md.bak.*; then
  printf 'FAIL: repo-a root AGENTS.md backup did not preserve prior content\n' >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-b"/AGENTS.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-b root AGENTS.md backup missing before canonical block replace\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'stale block' "$TMP/repos/repo-b"/AGENTS.md.bak.*; then
  printf 'FAIL: repo-b root AGENTS.md backup did not preserve prior block\n' >&2
  exit 1
fi

for repo in repo-a repo-b repo-c; do
  if ! diff -q "$CANONICAL" "$TMP/repos/$repo/.flywheel/AGENTS-CANONICAL.md" >/dev/null 2>&1; then
    printf 'FAIL: %s target did not match canonical after apply\n' "$repo" >&2
    exit 1
  fi
  if [[ "$(grep -c 'L70' "$TMP/repos/$repo/AGENTS.md")" -lt 1 ]]; then
    printf 'FAIL: %s root AGENTS.md missing L70 after apply\n' "$repo" >&2
    exit 1
  fi
done
if ! grep -q 'Keep this line.' "$TMP/repos/repo-a/AGENTS.md"; then
  printf 'FAIL: repo-a root AGENTS.md lost local content outside canonical block\n' >&2
  exit 1
fi
if ! grep -q 'Keep after block.' "$TMP/repos/repo-b/AGENTS.md"; then
  printf 'FAIL: repo-b root AGENTS.md lost trailing content outside canonical block\n' >&2
  exit 1
fi

post="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json)"
if [[ "$(jq -r '.status' <<<"$post")" != "ok" || "$(jq -r '.drifted_count' <<<"$post")" != "0" ]]; then
  printf 'FAIL: post-apply dry-run expected clean status\n%s\n' "$post" >&2
  exit 1
fi

before_hash="$(shasum -a 256 "$TMP/repos/repo-a/AGENTS.md" | awk '{print $1}')"
rerun="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --apply --json)"
after_hash="$(shasum -a 256 "$TMP/repos/repo-a/AGENTS.md" | awk '{print $1}')"
if [[ "$(jq -r '.synced_count' <<<"$rerun")" != "0" || "$before_hash" != "$after_hash" ]]; then
  printf 'FAIL: idempotent re-run changed root AGENTS.md\n%s\n' "$rerun" >&2
  exit 1
fi

missing_rc=0
missing="$(SYNC_CANONICAL_SOURCE="$TMP/missing/AGENTS.md" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json 2>&1)" || missing_rc=$?
if [[ "$missing_rc" -ne 2 ]]; then
  printf 'FAIL: missing source expected rc=2, got %s\n%s\n' "$missing_rc" "$missing" >&2
  exit 1
fi
if [[ "$(jq -r '.errors[0].code // empty' <<<"$missing")" != "source_missing" ]]; then
  printf 'FAIL: missing source expected source_missing code\n%s\n' "$missing" >&2
  exit 1
fi

printf 'PASS: sync-canonical-doctrine synthetic test passed\n'
