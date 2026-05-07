#!/usr/bin/env bash
# session-residue-prune.sh — clear stale session-start residue from flywheel repo
#
# Targets:
#   - .flywheel/*.preview.* (lock-skill preview drafts)
#   - .flywheel/.STATE.md.preview.*
#   - .flywheel/.reconcile-*.diff
#   - .flywheel/{AGENTS-CANONICAL,MISSION,GOAL}.md.bak.*
#   - .beads.bak.* directories
#   - .beads.failed.* directories
#
# Safety contract:
#   - Dry-run by default; --apply requires --idempotency-key
#   - Refuses to run outside ~/Developer/flywheel
#   - Refuses to touch tracked files (git ls-files filter)
#   - --min-age-days N (default 1) skips files newer than N days
#   - JSON receipt to stdout when --json passed
#
# Usage:
#   .flywheel/scripts/session-residue-prune.sh                          # dry-run
#   .flywheel/scripts/session-residue-prune.sh --json                   # dry-run + JSON
#   .flywheel/scripts/session-residue-prune.sh --apply --idempotency-key "$(date -u +%Y%m%dT%H%M%SZ)"
#
# Exit codes:
#   0 success (or no targets)
#   2 wrong working dir
#   3 --apply without --idempotency-key
#   4 idempotency-key replay (already ran with this key)

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-/Users/josh/Developer/flywheel}"
DRY_RUN=1
APPLY=0
JSON=0
IDEMPOTENCY_KEY=""
MIN_AGE_DAYS=1
RECEIPT_DIR="${REPO_ROOT}/.flywheel/receipts/session-residue-prune"

usage() {
  sed -n '2,30p' "$0"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --json) JSON=1; shift ;;
    --min-age-days) MIN_AGE_DAYS="${2:-1}"; shift 2 ;;
    --repo) REPO_ROOT="${2:-$REPO_ROOT}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Refuse to run anywhere except the flywheel repo
if [[ ! -d "${REPO_ROOT}/.flywheel" ]] || [[ ! -d "${REPO_ROOT}/.git" ]]; then
  echo "ERR: --repo must be a flywheel repo with .flywheel/ and .git/" >&2
  exit 2
fi

# Apply requires idempotency key
if (( APPLY )) && [[ -z "$IDEMPOTENCY_KEY" ]]; then
  echo "ERR: --apply requires --idempotency-key <key>" >&2
  exit 3
fi

# Idempotency replay guard
if (( APPLY )); then
  mkdir -p "$RECEIPT_DIR"
  RECEIPT_PATH="${RECEIPT_DIR}/${IDEMPOTENCY_KEY}.json"
  if [[ -e "$RECEIPT_PATH" ]]; then
    echo "ERR: idempotency-key '$IDEMPOTENCY_KEY' already ran (receipt at $RECEIPT_PATH)" >&2
    exit 4
  fi
fi

cd "$REPO_ROOT"

# Collect candidate paths. Each pattern returns 0+ matches; suppress no-match errors.
shopt -s nullglob
declare -a CANDIDATES=()

for p in .flywheel/*.preview.* \
         .flywheel/.STATE.md.preview.* \
         .flywheel/.reconcile-*.diff \
         .flywheel/AGENTS-CANONICAL.md.bak.* \
         .flywheel/MISSION.md.bak.* \
         .flywheel/GOAL.md.bak.* \
         .beads.bak.* \
         .beads.failed.* ; do
  [[ -e "$p" ]] && CANDIDATES+=("$p")
done

# Filter: skip anything tracked by git (defense in depth — these patterns shouldn't match tracked files)
declare -a FILTERED=()
for c in "${CANDIDATES[@]}"; do
  if git ls-files --error-unmatch "$c" &>/dev/null; then
    continue  # tracked, skip
  fi
  # Age filter (find with -mtime +N => modified more than N days ago)
  # Use -prune to handle directories and -mindepth -maxdepth 0 trick
  AGE_OK=$(find "$c" -maxdepth 0 -mtime +"$((MIN_AGE_DAYS - 1))" -print -quit 2>/dev/null)
  [[ -n "$AGE_OK" ]] && FILTERED+=("$c")
done

# Compute size
TOTAL_BYTES=0
declare -a SIZES_OUT=()
for f in "${FILTERED[@]}"; do
  SZ=$(du -sk "$f" 2>/dev/null | awk '{print $1*1024}')
  SZ="${SZ:-0}"
  TOTAL_BYTES=$((TOTAL_BYTES + SZ))
  SIZES_OUT+=("$f|$SZ")
done

# Apply (delete) or report
declare -a DELETED=()
declare -a SKIPPED=()
if (( APPLY )); then
  for f in "${FILTERED[@]}"; do
    if [[ -d "$f" ]]; then
      if rm -rf -- "$f" 2>/dev/null; then
        DELETED+=("$f")
      else
        SKIPPED+=("$f")
      fi
    elif [[ -f "$f" ]]; then
      if rm -f -- "$f" 2>/dev/null; then
        DELETED+=("$f")
      else
        SKIPPED+=("$f")
      fi
    fi
  done
fi

# Receipt
TS_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MODE=$([ $APPLY -eq 1 ] && echo apply || echo dry-run)

if (( JSON )); then
  printf '{"ts":"%s","mode":"%s","repo":"%s","min_age_days":%d,"candidate_count":%d,"deleted_count":%d,"skipped_count":%d,"total_bytes":%d,"idempotency_key":"%s","candidates":[' \
    "$TS_UTC" "$MODE" "$REPO_ROOT" "$MIN_AGE_DAYS" "${#FILTERED[@]}" "${#DELETED[@]}" "${#SKIPPED[@]}" "$TOTAL_BYTES" "$IDEMPOTENCY_KEY"
  first=1
  for entry in "${SIZES_OUT[@]}"; do
    path="${entry%|*}"
    sz="${entry##*|}"
    [[ $first -eq 0 ]] && printf ','
    first=0
    printf '{"path":"%s","bytes":%s}' "$path" "$sz"
  done
  printf ']}\n'
else
  echo "session-residue-prune mode=${MODE} repo=${REPO_ROOT}"
  echo "  min_age_days=${MIN_AGE_DAYS}"
  echo "  candidates: ${#FILTERED[@]}  total_bytes: ${TOTAL_BYTES}"
  for entry in "${SIZES_OUT[@]}"; do
    path="${entry%|*}"
    sz="${entry##*|}"
    printf '  - %s (%s bytes)\n' "$path" "$sz"
  done
  if (( APPLY )); then
    echo "  deleted=${#DELETED[@]}  skipped=${#SKIPPED[@]}"
  else
    echo "  (dry-run; pass --apply --idempotency-key <key> to delete)"
  fi
fi

# Persist receipt on apply
if (( APPLY )); then
  {
    printf '{"ts":"%s","mode":"apply","repo":"%s","idempotency_key":"%s","deleted":%d,"skipped":%d,"total_bytes":%d,"min_age_days":%d}\n' \
      "$TS_UTC" "$REPO_ROOT" "$IDEMPOTENCY_KEY" "${#DELETED[@]}" "${#SKIPPED[@]}" "$TOTAL_BYTES" "$MIN_AGE_DAYS"
  } > "$RECEIPT_PATH"
fi
