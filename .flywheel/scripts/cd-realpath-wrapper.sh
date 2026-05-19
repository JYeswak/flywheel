#!/usr/bin/env bash
# cd-realpath-wrapper.sh — drop-in safe replacement for `cd` in dispatch packets.
#
# Layer-1 PREVENTION primitive for the clobbered_doctrine_docs class
# (flywheel-tpprm sibling). Recovery primitive: clobber-recovery.sh.
#
# Class signature: worker fails `cd "$WORK_TMP"` (special-char escape or
# WORK_TMP unset), naked `cd "$WORK_TMP" && printf > target.md` keeps the
# OLD pwd, the redirect lands in repo root, doctrine docs get truncated.
#
# This wrapper:
#   - Resolves the target via realpath BEFORE attempting cd
#   - Verifies resolved path is inside an expected sandbox (TMPDIR / scratch)
#   - Aborts with explicit error + non-zero exit code if cd would fail
#   - Writes receipt to .flywheel/cd-realpath-wrapper-log.jsonl naming the
#     failed-cd event so the orch can detect the prevention firing
#
# Usage as drop-in replacement (source first, then call):
#   source .flywheel/scripts/cd-realpath-wrapper.sh
#   cd_realpath "$WORK_TMP"
#
# Or as standalone executable (cd in subshell, exit propagates):
#   .flywheel/scripts/cd-realpath-wrapper.sh "$WORK_TMP" && cd "$_"
#
# Modes:
#   cd-realpath-wrapper.sh PATH                 # resolve+verify, print resolved path on stdout, exit 0 on safe
#   cd-realpath-wrapper.sh --doctor [--json]    # self-check
#   cd-realpath-wrapper.sh --info|--schema|--examples|--help
#
# Exit codes:
#   0 — path resolves, sandbox check passes, cd would succeed (resolved path on stdout)
#   1 — usage / arg error
#   2 — path does not exist or fails realpath
#   3 — path resolves but escapes the expected sandbox (write would clobber)

set -uo pipefail

VERSION="cd-realpath-wrapper.v1"
LEDGER="${CD_REALPATH_WRAPPER_LEDGER:-/Users/josh/Developer/flywheel/.flywheel/cd-realpath-wrapper-log.jsonl}"

# Allowed sandbox prefixes. A resolved path MUST start with one of these to
# pass the sandbox check. Defaults cover canonical worker scratch + TMPDIR
# variants; operator can extend via CD_REALPATH_WRAPPER_ALLOW (colon-separated).
DEFAULT_SANDBOXES=(
  "/tmp/"
  "/private/tmp/"
  "/var/folders/"  # macOS mktemp default
  "/private/var/folders/"  # macOS APFS firmlink expansion of /var/folders
  "${TMPDIR:-/tmp/}"
  "/Users/josh/Developer/flywheel/.flywheel/"  # repo-local scratch dirs
  "/Users/josh/.local/state/flywheel-"  # autoloop/loop state dirs
  "/Users/josh/.local/state/flywheel/"
)

# Append operator-supplied sandboxes (colon-separated)
if [[ -n "${CD_REALPATH_WRAPPER_ALLOW:-}" ]]; then
  IFS=':' read -ra _extra <<<"$CD_REALPATH_WRAPPER_ALLOW"
  DEFAULT_SANDBOXES+=("${_extra[@]}")
  unset _extra
fi

usage() {
  cat <<'USAGE'
usage: cd-realpath-wrapper.sh PATH [--quiet]
       cd-realpath-wrapper.sh --doctor [--json]
       cd-realpath-wrapper.sh --info|--schema|--examples|--help

Resolves PATH via realpath, verifies it's inside an expected sandbox prefix,
emits the resolved path on stdout (rc=0). Refuses with non-zero exit if the
path doesn't exist (rc=2) or escapes the sandbox (rc=3).

Default sandbox prefixes:
  /tmp/, /private/tmp/, /var/folders/ (macOS mktemp), $TMPDIR,
  /Users/josh/Developer/flywheel/.flywheel/,
  /Users/josh/.local/state/flywheel/, /Users/josh/.local/state/flywheel-*

Extend via env: CD_REALPATH_WRAPPER_ALLOW="prefix1:prefix2:..."

Failed-cd events are logged to:
  .flywheel/cd-realpath-wrapper-log.jsonl

Sister doctrine: clobber-recovery.sh (recovery primitive; this wrapper is
prevention).
USAGE
}

info_block() {
  cat <<'EOF'
cd-realpath-wrapper is the Layer-1 PREVENTION primitive for the
clobbered_doctrine_docs class (recovery: clobber-recovery.sh).

Pre-prevention pattern (UNSAFE):
  cd "$WORK_TMP" && printf '%s' "$content" > target.md
  # If WORK_TMP unset or cd fails: redirect lands in repo root, clobbers MISSION/STATE/GOAL.

Post-prevention pattern (SAFE):
  RESOLVED=$(.flywheel/scripts/cd-realpath-wrapper.sh "$WORK_TMP") || exit 1
  cd "$RESOLVED" || exit 1
  printf '%s' "$content" > target.md
  # cd-realpath-wrapper enforces realpath resolution + sandbox check
  # BEFORE the cd, so a failed cd cannot silently leave the worker in
  # repo root.

Sandbox enforcement: the resolved path must start with a prefix in the
DEFAULT_SANDBOXES allowlist (or CD_REALPATH_WRAPPER_ALLOW extension).
Targets outside the sandbox return rc=3 with explicit error — no cd attempted.

Failed-cd events log to .flywheel/cd-realpath-wrapper-log.jsonl with
{ts, requested, resolved (if any), rc, reason} for orch detection of the
prevention firing.
EOF
}

schema_block() {
  cat <<'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "cd-realpath-wrapper.event",
  "description": "Receipt row for a cd-realpath-wrapper invocation. Append-only ledger at .flywheel/cd-realpath-wrapper-log.jsonl.",
  "type": "object",
  "required": ["ts", "schema_version", "requested", "rc"],
  "properties": {
    "schema_version": {"type": "string", "const": "cd-realpath-wrapper.v1"},
    "ts": {"type": "string", "format": "date-time"},
    "requested": {"type": "string", "description": "the path argument passed to the wrapper"},
    "resolved": {"type": ["string", "null"], "description": "realpath() output if it succeeded"},
    "rc": {"type": "integer", "enum": [0, 1, 2, 3]},
    "reason": {"type": ["string", "null"], "enum": ["ok", "missing_arg", "realpath_failed", "outside_sandbox", null]},
    "sandbox_match": {"type": ["string", "null"], "description": "the matching sandbox prefix if rc=0"}
  },
  "additionalProperties": true
}
EOF
}

examples_block() {
  cat <<'EOF'
# As a guard before cd in a worker script:
RESOLVED=$(/Users/josh/Developer/flywheel/.flywheel/scripts/cd-realpath-wrapper.sh "$WORK_TMP") || exit 1
cd "$RESOLVED" || exit 1
printf '%s' "$content" > target.md   # safe — cd is guaranteed correct

# Sourceable function form (defines cd_realpath in caller's shell):
source /Users/josh/Developer/flywheel/.flywheel/scripts/cd-realpath-wrapper.sh
cd_realpath "$WORK_TMP" || exit 1   # changes directory; aborts on failure

# Self-check
.flywheel/scripts/cd-realpath-wrapper.sh --doctor --json

# Inspect the prevention ledger
tail -3 .flywheel/cd-realpath-wrapper-log.jsonl | jq -c '{ts, requested, rc, reason}'

# Extend sandbox prefixes (e.g., for a per-task scratch root)
CD_REALPATH_WRAPPER_ALLOW="/Users/josh/Developer/flywheel/scratch/" \
  /Users/josh/Developer/flywheel/.flywheel/scripts/cd-realpath-wrapper.sh /Users/josh/Developer/flywheel/scratch/foo
EOF
}

# Append a row to the prevention ledger (best-effort; never blocks success).
log_event() {
  local requested="$1" resolved="${2:-}" rc="$3" reason="${4:-}" sandbox_match="${5:-}"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -nc \
      --arg version "$VERSION" \
      --arg ts "$ts" \
      --arg requested "$requested" \
      --arg resolved "$resolved" \
      --argjson rc "$rc" \
      --arg reason "$reason" \
      --arg sandbox_match "$sandbox_match" \
      '{
        schema_version: $version,
        ts: $ts,
        requested: $requested,
        resolved: (if $resolved == "" then null else $resolved end),
        rc: $rc,
        reason: (if $reason == "" then null else $reason end),
        sandbox_match: (if $sandbox_match == "" then null else $sandbox_match end)
      }' >>"$LEDGER" 2>/dev/null || true
  fi
}

# Resolve a path via realpath, verify sandbox membership, emit resolved path
# on stdout. Returns rc=0 on safe; rc=2 on missing/realpath-fail; rc=3 on
# sandbox escape. All rc paths log to the ledger.
resolve_and_check() {
  local requested="$1"
  if [[ -z "$requested" ]]; then
    log_event "$requested" "" 1 "missing_arg" ""
    printf 'cd-realpath-wrapper: PATH required\n' >&2
    return 1
  fi
  local resolved=""
  if command -v realpath >/dev/null 2>&1; then
    resolved="$(realpath "$requested" 2>/dev/null)" || resolved=""
  else
    # macOS pre-realpath fallback
    resolved="$(cd "$requested" 2>/dev/null && pwd -P)" || resolved=""
  fi
  if [[ -z "$resolved" || ! -d "$resolved" ]]; then
    log_event "$requested" "$resolved" 2 "realpath_failed" ""
    printf 'cd-realpath-wrapper: realpath failed or not a directory: %s\n' "$requested" >&2
    return 2
  fi
  # Sandbox check: resolved path must start with one of the allowlist prefixes
  local matched=""
  for prefix in "${DEFAULT_SANDBOXES[@]}"; do
    [[ -z "$prefix" ]] && continue
    case "$resolved/" in
      "$prefix"*)
        matched="$prefix"
        break
        ;;
    esac
  done
  if [[ -z "$matched" ]]; then
    log_event "$requested" "$resolved" 3 "outside_sandbox" ""
    printf 'cd-realpath-wrapper: resolved path outside expected sandbox: %s (allowed prefixes: %s)\n' \
      "$resolved" "${DEFAULT_SANDBOXES[*]}" >&2
    return 3
  fi
  log_event "$requested" "$resolved" 0 "ok" "$matched"
  printf '%s\n' "$resolved"
  return 0
}

# Sourceable function form: changes directory in the caller's shell on
# success; returns non-zero (without exiting) on failure.
cd_realpath() {
  local resolved
  resolved="$(resolve_and_check "${1:-}")" || return $?
  cd "$resolved"
}

doctor() {
  local status="pass"
  local realpath_check="ok"
  if ! command -v realpath >/dev/null 2>&1; then
    realpath_check="fallback_pwd_P"  # not a fail; we have a fallback
  fi
  local jq_check="ok"
  if ! command -v jq >/dev/null 2>&1; then
    jq_check="missing_ledger_disabled"
  fi
  local ledger_dir_check="ok"
  if ! mkdir -p "$(dirname "$LEDGER")" 2>/dev/null; then
    ledger_dir_check="cannot_create"
    status="warn"
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -nc \
      --arg version "$VERSION" \
      --arg status "$status" \
      --arg realpath_check "$realpath_check" \
      --arg jq_check "$jq_check" \
      --arg ledger "$LEDGER" \
      --arg ledger_dir_check "$ledger_dir_check" \
      --argjson sandbox_count "${#DEFAULT_SANDBOXES[@]}" \
      '{
        schema_version: $version,
        status: $status,
        realpath_check: $realpath_check,
        jq_check: $jq_check,
        ledger: $ledger,
        ledger_dir_check: $ledger_dir_check,
        sandbox_prefix_count: $sandbox_count
      }'
  else
    printf 'status=%s realpath=%s jq=%s ledger=%s\n' \
      "$status" "$realpath_check" "$jq_check" "$LEDGER"
  fi
  [[ "$status" == "pass" ]]
}

# Detect sourcing: when sourced, return without executing CLI dispatcher.
# The function `cd_realpath` is now defined in the caller's shell.
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return 0 2>/dev/null || true
fi

# CLI dispatcher
case "${1:-}" in
  --help|-h|help) usage; exit 0 ;;
  --info|info) info_block; exit 0 ;;
  --schema|schema) schema_block; exit 0 ;;
  --examples|examples) examples_block; exit 0 ;;
  --doctor|doctor|--health|health) doctor; exit $? ;;
  --quiet) shift; resolve_and_check "${1:-}" >/dev/null; exit $? ;;
  "") usage >&2; exit 1 ;;
  -*)
    printf 'cd-realpath-wrapper: unknown flag: %s\n' "$1" >&2
    usage >&2
    exit 1
    ;;
  *) resolve_and_check "$1"; exit $? ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
