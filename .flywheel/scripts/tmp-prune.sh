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

SCAFFOLD_SCHEMA_VERSION="tmp-prune/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/tmp-prune-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: tmp-prune.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "tmp-prune.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "tmp-prune.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"tmp-prune.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"tmp-prune.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"tmp-prune.sh doctor --json"}'
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
            && cli_emit_completion_bash "tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "tmp-prune" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
ROOT_PATH="${FLYWHEEL_TMP_PRUNE_ROOT:-/private/tmp}"
RECEIPT_DIR="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"
DAYS="${FLYWHEEL_TMP_PRUNE_DAYS:-1}"
APPLY=0
JSON_OUT=0
IDEMPOTENCY_KEY="${FLYWHEEL_TMP_PRUNE_IDEMPOTENCY_KEY:-}"
TMP_PRUNE_WORKDIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CLI_REGISTRY_EMIT="${FLYWHEEL_CLI_REGISTRY_EMIT:-$SCRIPT_DIR/cli-registry-emit.sh}"

usage() {
  if [ -x "$CLI_REGISTRY_EMIT" ]; then
    "$CLI_REGISTRY_EMIT" tmp-prune.sh --mode help
    return
  fi
  printf '%s\n' \
    "Usage: tmp-prune.sh [--root PATH] [--days N] [--dry-run|--apply --idempotency-key KEY] [--json]" \
    "Default is dry-run. Candidates are limited to explicit fleet scratch prefixes under the selected tmp root."
}

json_bool() {
  if [ "$1" -eq 1 ]; then printf 'true'; else printf 'false'; fi
}

is_allowed_base() {
  case "$1" in
    alps.*|alpsinsurance*|flywheel-*|beads.*|beads_*|claude-skills-sync|mobile-eats-*|br-*) return 0 ;;
    *) return 1 ;;
  esac
}

is_forbidden_base() {
  case "$1" in
    com.apple.*|launchd-*) return 0 ;;
    *) return 1 ;;
  esac
}

validate_days() {
  case "$DAYS" in
    ''|*[!0-9]*) printf 'ERROR: --days must be a non-negative integer\n' >&2; exit 2 ;;
  esac
}

validate_root() {
  case "$ROOT_PATH" in
    /private/tmp|/private/tmp/*|/tmp/*|/var/folders/*) ;;
    *) printf 'ERROR: root is outside allowed tmp roots: %s\n' "$ROOT_PATH" >&2; exit 2 ;;
  esac
  [ -d "$ROOT_PATH" ] || { printf 'ERROR: root is not a directory: %s\n' "$ROOT_PATH" >&2; exit 2; }
}

candidate_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \
    \( -name 'alps.*' -o -name 'alpsinsurance*' -o -name 'flywheel-*' -o -name 'beads.*' -o -name 'beads_*' -o -name 'claude-skills-sync' -o -name 'mobile-eats-*' -o -name 'br-*' \) \
    -mtime "+$DAYS" -print 2>/dev/null | sort
}

forbidden_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \( -name 'com.apple.*' -o -name 'launchd-*' \) -mtime "+$DAYS" -print 2>/dev/null | sort
}

unknown_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \
    ! \( -name 'alps.*' -o -name 'alpsinsurance*' -o -name 'flywheel-*' -o -name 'beads.*' -o -name 'beads_*' -o -name 'claude-skills-sync' -o -name 'mobile-eats-*' -o -name 'br-*' -o -name 'com.apple.*' -o -name 'launchd-*' \) \
    -mtime "+$DAYS" -print 2>/dev/null | sort
}

path_bytes() {
  du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
}

path_mtime() {
  stat -f '%m' "$1" 2>/dev/null || printf '0'
}

append_path_object() {
  local path="$1" out="$2" base bytes mtime
  base="${path##*/}"
  if is_forbidden_base "$base"; then
    printf 'ERROR: forbidden tmp prefix reached candidate set: %s\n' "$path" >&2
    exit 3
  fi
  if ! is_allowed_base "$base"; then
    printf 'ERROR: unknown tmp prefix reached candidate set: %s\n' "$path" >&2
    exit 3
  fi
  bytes="$(path_bytes "$path")"
  mtime="$(path_mtime "$path")"
  jq -nc \
    --arg path "$path" \
    --arg base "$base" \
    --argjson bytes "${bytes:-0}" \
    --argjson mtime "${mtime:-0}" \
    '{path:$path,basename:$base,bytes:$bytes,mtime_epoch:$mtime}' >>"$out"
}

build_path_jsonl() {
  local candidates="$1" objects="$2" path
  : >"$objects"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    append_path_object "$path" "$objects"
  done <"$candidates"
}

write_receipt() {
  local tmpdir="$1" status="$2" receipt_path="$3" apply_json dry_run_json
  apply_json="$(json_bool "$APPLY")"
  if [ "$APPLY" -eq 1 ]; then dry_run_json=false; else dry_run_json=true; fi
  mkdir -p "$RECEIPT_DIR"
  jq -nc \
    --arg schema_version "tmp-prune/v1" \
    --arg status "$status" \
    --arg root "$ROOT_PATH" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --arg receipt_path "$receipt_path" \
    --argjson apply "$apply_json" \
    --argjson dry_run "$dry_run_json" \
    --argjson days "$DAYS" \
    --slurpfile paths "$tmpdir/path-objects.jsonl" \
    --argjson forbidden_count "$(wc -l <"$tmpdir/forbidden.txt" | tr -d ' ')" \
    --argjson unknown_count "$(wc -l <"$tmpdir/unknown.txt" | tr -d ' ')" \
    '{
      schema_version:$schema_version,
      status:$status,
      root:$root,
      apply:$apply,
      dry_run:$dry_run,
      older_than_mtime_days:$days,
      idempotency_key:$idempotency_key,
      receipt_path:$receipt_path,
      allowlist_prefixes:["alps.*","alpsinsurance*","flywheel-*","beads.*","beads_*","claude-skills-sync","mobile-eats-*","br-*"],
      forbidden_prefixes:["com.apple.*","launchd-*"],
      paths_to_prune:$paths,
      paths_to_prune_count:($paths | length),
      bytes_to_prune:($paths | map(.bytes) | add // 0),
      excluded:{forbidden_prefix_count:$forbidden_count,unknown_prefix_count:$unknown_count}
    }' >"$receipt_path"
}

apply_candidates() {
  local candidates="$1" path base
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    base="${path##*/}"
    is_allowed_base "$base" || { printf 'ERROR: unknown tmp prefix reached apply set: %s\n' "$path" >&2; exit 3; }
    is_forbidden_base "$base" && { printf 'ERROR: forbidden tmp prefix reached apply set: %s\n' "$path" >&2; exit 3; }
    case "$path" in
      "$ROOT_PATH"/*) rm -rf -- "$path" ;;
      *) printf 'ERROR: candidate outside tmp root: %s\n' "$path" >&2; exit 3 ;;
    esac
  done <"$candidates"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --root) [ $# -ge 2 ] || { printf 'ERROR: --root requires PATH\n' >&2; exit 2; }; ROOT_PATH="$2"; shift 2 ;;
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
  local tmpdir ts receipt_path status
  parse_args "$@"
  validate_days
  validate_root
  if [ "$APPLY" -eq 1 ] && [ -z "$IDEMPOTENCY_KEY" ]; then
    printf 'ERROR: --apply requires --idempotency-key\n' >&2
    exit 2
  fi
  if [ -z "$IDEMPOTENCY_KEY" ]; then
    IDEMPOTENCY_KEY="dry-run"
  fi

  tmpdir="$(mktemp -d -t tmp-prune.XXXXXX)"
  TMP_PRUNE_WORKDIR="$tmpdir"
  trap 'if [ -n "${TMP_PRUNE_WORKDIR:-}" ]; then rm -rf "$TMP_PRUNE_WORKDIR"; fi' EXIT
  candidate_find >"$tmpdir/candidates.txt"
  forbidden_find >"$tmpdir/forbidden.txt"
  unknown_find >"$tmpdir/unknown.txt"
  build_path_jsonl "$tmpdir/candidates.txt" "$tmpdir/path-objects.jsonl"

  status="dry_run"
  if [ "$APPLY" -eq 1 ]; then
    apply_candidates "$tmpdir/candidates.txt"
    status="applied"
  fi

  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  receipt_path="$RECEIPT_DIR/$ts.json"
  if [ -e "$receipt_path" ]; then
    receipt_path="$RECEIPT_DIR/$ts.$$.json"
  fi
  write_receipt "$tmpdir" "$status" "$receipt_path"
  if [ "$JSON_OUT" -eq 1 ]; then
    cat "$receipt_path"
  else
    jq -r '"tmp-prune status=\(.status) paths_to_prune=\(.paths_to_prune_count) bytes_to_prune=\(.bytes_to_prune) receipt=\(.receipt_path)"' "$receipt_path"
  fi
}

main "$@"
