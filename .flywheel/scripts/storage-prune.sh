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

SCAFFOLD_SCHEMA_VERSION="storage-prune/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-prune-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: storage-prune.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "storage-prune.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "storage-prune.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"storage-prune.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"storage-prune.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"storage-prune.sh doctor --json"}'
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
            && cli_emit_completion_bash "storage-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "storage-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
REPO="${REPO:-/Users/josh/Developer/flywheel}"
APPLY=0
JSON_OUT=0
DAYS="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
IDEMPOTENCY_KEY="${FLYWHEEL_STORAGE_PRUNE_IDEMPOTENCY_KEY:-manual}"
BR_RECOVERY_MAX_MB="${FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_MB:-50}"
BR_RECOVERY_MAX_ENTRIES="${FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_ENTRIES:-1000}"
JEFF_CORPUS_DAYS="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DAYS:-14}"
JEFF_CORPUS_DIR="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR:-$REPO/.flywheel/jeff-corpus}"

usage() {
  printf '%s\n' \
    "Usage: storage-prune.sh [--repo PATH] [--days N] [--dry-run|--apply] [--json] --idempotency-key KEY" \
    "Default is dry-run. Removes stale .beads.bak.* dirs, tmp dispatch artifacts, stale Beads sidecars, and archives recovery/corpus bloat." \
    "Docker dangling cleanup is reported as a manual command; this script never prunes docker volumes."
}

cutoff_find_args() {
  local days="${1:-$DAYS}"
  printf '%s\n' "+${days}"
}

br_recovery_candidates() {
  local path size_kb entries max_kb
  max_kb=$((BR_RECOVERY_MAX_MB * 1024))
  for path in "$REPO/.br_recovery" "$REPO/.beads/.br_recovery"; do
    [ -d "$path" ] || continue
    size_kb="$(du -sk "$path" 2>/dev/null | awk '{print $1+0}')"
    entries="$(find "$path" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$size_kb" -gt "$max_kb" ] || [ "$entries" -gt "$BR_RECOVERY_MAX_ENTRIES" ]; then
      printf '%s\n' "$path"
    fi
  done
}

sidecar_candidates() {
  [ -d "$REPO/.beads" ] || return 0
  find "$REPO/.beads" -maxdepth 1 -type f \( -name '*.aside.*' -o -name '*.bak.*' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort
}

jeff_corpus_candidates() {
  [ -d "$JEFF_CORPUS_DIR" ] || return 0
  find "$JEFF_CORPUS_DIR" -mindepth 1 -maxdepth 1 -mtime "$(cutoff_find_args "$JEFF_CORPUS_DAYS")" 2>/dev/null | sort
}

safe_archive_name() {
  printf '%s' "$1" | tr '/ ' '__' | tr -c 'A-Za-z0-9._-' '_'
}

plan_json() {
  local tmp_dirs tmp_files tmp_recovery tmp_sidecars tmp_jeff
  local bak_count file_count recovery_count sidecar_count jeff_count
  tmp_dirs="$(mktemp "${TMPDIR:-/tmp}/storage-prune-dirs.XXXXXX")"
  tmp_files="$(mktemp "${TMPDIR:-/tmp}/storage-prune-files.XXXXXX")"
  tmp_recovery="$(mktemp "${TMPDIR:-/tmp}/storage-prune-recovery.XXXXXX")"
  tmp_sidecars="$(mktemp "${TMPDIR:-/tmp}/storage-prune-sidecars.XXXXXX")"
  tmp_jeff="$(mktemp "${TMPDIR:-/tmp}/storage-prune-jeff.XXXXXX")"
  find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort >"$tmp_dirs"
  find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort >"$tmp_files"
  br_recovery_candidates >"$tmp_recovery"
  sidecar_candidates >"$tmp_sidecars"
  jeff_corpus_candidates >"$tmp_jeff"
  bak_count="$(wc -l <"$tmp_dirs" | tr -d ' ')"
  file_count="$(wc -l <"$tmp_files" | tr -d ' ')"
  recovery_count="$(wc -l <"$tmp_recovery" | tr -d ' ')"
  sidecar_count="$(wc -l <"$tmp_sidecars" | tr -d ' ')"
  jeff_count="$(wc -l <"$tmp_jeff" | tr -d ' ')"
  jq -nc \
    --arg repo "$REPO" \
    --arg key "$IDEMPOTENCY_KEY" \
    --arg jeff_corpus_dir "$JEFF_CORPUS_DIR" \
    --argjson apply "$APPLY" \
    --argjson days "$DAYS" \
    --argjson jeff_days "$JEFF_CORPUS_DAYS" \
    --argjson br_recovery_max_mb "$BR_RECOVERY_MAX_MB" \
    --argjson br_recovery_max_entries "$BR_RECOVERY_MAX_ENTRIES" \
    --argjson bak_count "$bak_count" \
    --argjson file_count "$file_count" \
    --argjson recovery_count "$recovery_count" \
    --argjson sidecar_count "$sidecar_count" \
    --argjson jeff_count "$jeff_count" \
    --argjson bak_dirs "$(jq -R . "$tmp_dirs" | jq -s .)" \
    --argjson tmp_files_json "$(jq -R . "$tmp_files" | jq -s .)" \
    --argjson br_recovery_dirs "$(jq -R . "$tmp_recovery" | jq -s .)" \
    --argjson stale_sidecars "$(jq -R . "$tmp_sidecars" | jq -s .)" \
    --argjson jeff_corpus_entries "$(jq -R . "$tmp_jeff" | jq -s .)" \
    '{
      status:"ok",
      apply:($apply==1),
      repo:$repo,
      idempotency_key:$key,
      older_than_days:$days,
      thresholds:{br_recovery_max_mb:$br_recovery_max_mb,br_recovery_max_entries:$br_recovery_max_entries,jeff_corpus_older_than_days:$jeff_days},
      planned:{stale_bak_dirs:$bak_count,tmp_dispatch_artifacts:$file_count,br_recovery_archives:$recovery_count,stale_beads_sidecars:$sidecar_count,jeff_corpus_archives:$jeff_count},
      paths:{stale_bak_dirs:$bak_dirs,tmp_dispatch_artifacts:$tmp_files_json,br_recovery_dirs:$br_recovery_dirs,stale_beads_sidecars:$stale_sidecars,jeff_corpus_entries:$jeff_corpus_entries},
      jeff_corpus_dir:$jeff_corpus_dir,
      docker_manual_command:"docker system prune --force",
      docker_volumes_pruned:false
    }'
  rm -f "$tmp_dirs" "$tmp_files" "$tmp_recovery" "$tmp_sidecars" "$tmp_jeff"
}

apply_plan() {
  local path ts br_archive jeff_archive dest name
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.beads.bak.*) rm -rf "$path" ;;
    esac
  done < <(find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null)
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      /tmp/*dispatch*) rm -f "$path" ;;
    esac
  done < <(find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null)
  br_archive="/tmp/br_recovery.archived-$ts"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.br_recovery|"$REPO"/.beads/.br_recovery)
        mkdir -p "$br_archive"
        name="$(safe_archive_name "${path#"$REPO"/}")"
        dest="$br_archive/$name"
        [ -e "$dest" ] && dest="$dest.$$"
        mv "$path" "$dest"
        ;;
    esac
  done < <(br_recovery_candidates)
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.beads/*.aside.*|"$REPO"/.beads/*.bak.*) rm -f -- "$path" ;;
    esac
  done < <(sidecar_candidates)
  jeff_archive="/tmp/jeff-corpus.archived-$ts"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$JEFF_CORPUS_DIR"/*)
        mkdir -p "$jeff_archive"
        dest="$jeff_archive/$(basename "$path")"
        [ -e "$dest" ] && dest="$dest.$$"
        mv "$path" "$dest"
        ;;
    esac
  done < <(jeff_corpus_candidates)
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --repo) [ $# -ge 2 ] || { printf 'ERROR: --repo requires PATH\n' >&2; exit 2; }; REPO="$2"; shift 2 ;;
      --days) [ $# -ge 2 ] || { printf 'ERROR: --days requires N\n' >&2; exit 2; }; DAYS="$2"; shift 2 ;;
      --dry-run) APPLY=0; shift ;;
      --apply) APPLY=1; shift ;;
      --json) JSON_OUT=1; shift ;;
      --idempotency-key) [ $# -ge 2 ] || { printf 'ERROR: --idempotency-key requires KEY\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
      *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

main() {
  parse_args "$@"
  if [ -z "${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR+x}" ]; then
    JEFF_CORPUS_DIR="$REPO/.flywheel/jeff-corpus"
  fi
  if [ "$APPLY" -eq 1 ] && [ "$IDEMPOTENCY_KEY" = "manual" ]; then
    printf 'ERROR: --apply requires --idempotency-key\n' >&2
    exit 2
  fi
  [ "$APPLY" -eq 0 ] || apply_plan
  if [ "$JSON_OUT" -eq 1 ]; then
    plan_json
  else
    plan_json | jq -r '"storage-prune apply=\(.apply) stale_bak_dirs=\(.planned.stale_bak_dirs) tmp_dispatch_artifacts=\(.planned.tmp_dispatch_artifacts)"'
  fi
}

main "$@"
