#!/usr/bin/env bash
set -euo pipefail

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
