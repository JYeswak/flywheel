#!/usr/bin/env bash
# flywheel-sync-doctrine.sh — consumer-initiated pull of upstream doctrine.
#
# DOCTRINE: doctrine-pull-ownership-inversion (bead flywheel-k8pee).
# JOSHUA-DIRECT 2026-05-20T19:48Z via zesttube:2 governance proposal.
# META-RULE: feedback_upstream_never_writes_into_consumer_working_trees.md
#
# This script runs FROM the consumer repo's perspective. It reads canonical
# upstream doctrine on local disk and writes into the LOCAL consumer
# .flywheel/doctrine/ tree. Because every mutation is same-repo, the DCG
# cross-repo write-guard hook is preserved as the outer enforcement.
#
# Modes:
#   --dry-run   (default) enumerate would-change files + sha256 deltas + sizes
#   --diff-only show full `diff -u` per file
#   --apply     copy upstream into local doctrine. Hard-gated on clean WT.
#
# Receipt: .flywheel/evidence/sync-doctrine-<ts>.json

set -euo pipefail

VERSION="flywheel-sync-doctrine/v1"

# ---------- helpers ----------
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { printf '[sync-doctrine] %s\n' "$*" >&2; }
err() { printf '[sync-doctrine] ERROR: %s\n' "$*" >&2; }

require_tool() {
  command -v "$1" >/dev/null 2>&1 || { err "missing required tool: $1"; exit 2; }
}

sha_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    err "no shasum/sha256sum available"; exit 2
  fi
}

# ---------- argparse ----------
MODE="dry-run"
MANIFEST=""
SURFACE="doctrine"

while (( $# > 0 )); do
  case "$1" in
    --dry-run)   MODE="dry-run";   shift ;;
    --diff-only) MODE="diff-only"; shift ;;
    --apply)     MODE="apply";     shift ;;
    --manifest)  MANIFEST="${2:?--manifest needs path}"; shift 2 ;;
    --surface)   SURFACE="${2:?--surface needs value}"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
flywheel-sync-doctrine.sh — consumer-initiated doctrine pull

USAGE:
  flywheel-sync-doctrine.sh [--dry-run|--diff-only|--apply]
                            [--manifest <path>]
                            [--surface doctrine|skills|scripts|plans]

DEFAULT: --dry-run, surface=doctrine, manifest=.flywheel/DOCTRINE-MANIFEST.json
RECEIPT: .flywheel/evidence/sync-doctrine-<ts>.json

Bead: flywheel-k8pee
EOF
      exit 0 ;;
    *) err "unknown arg: $1"; exit 2 ;;
  esac
done

if [[ "$SURFACE" != "doctrine" ]]; then
  err "surface=$SURFACE not yet wired (only doctrine in v1)"; exit 2
fi

require_tool git

# ---------- locate consumer + upstream ----------
CONSUMER_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$CONSUMER_ROOT" ]]; then
  err "not inside a git repo — sync-doctrine must run from inside the consumer repo"
  exit 2
fi

UPSTREAM_CANDIDATES=(
  "${HOME}/Developer/flywheel/.flywheel/doctrine"
  "${HOME}/.flywheel/doctrine"
)
UPSTREAM=""
for c in "${UPSTREAM_CANDIDATES[@]}"; do
  if [[ -d "$c" ]]; then UPSTREAM="$c"; break; fi
done
if [[ -z "$UPSTREAM" ]]; then
  err "no upstream doctrine found in: ${UPSTREAM_CANDIDATES[*]}"
  exit 2
fi

CONSUMER_DOC_DIR="$CONSUMER_ROOT/.flywheel/doctrine"
MANIFEST="${MANIFEST:-$CONSUMER_ROOT/.flywheel/DOCTRINE-MANIFEST.json}"
EVIDENCE_DIR="$CONSUMER_ROOT/.flywheel/evidence"
mkdir -p "$EVIDENCE_DIR" "$CONSUMER_DOC_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
RECEIPT="$EVIDENCE_DIR/sync-doctrine-$TS.json"

# ---------- determine tracked set ----------
TRACKED=()
OVERRIDES_DIR=".flywheel/doctrine-overrides/"
PIN_POLICY="latest"
if [[ -f "$MANIFEST" ]] && command -v jq >/dev/null 2>&1; then
  log "reading manifest: $MANIFEST"
  while IFS= read -r line; do TRACKED+=("$line"); done < <(jq -r '.tracked_doctrines[]?' "$MANIFEST" 2>/dev/null || true)
  PIN_POLICY="$(jq -r '.pin_policy // "latest"' "$MANIFEST" 2>/dev/null || echo latest)"
  OVERRIDES_DIR="$(jq -r '.consumer_overrides_dir // ".flywheel/doctrine-overrides/"' "$MANIFEST" 2>/dev/null || echo ".flywheel/doctrine-overrides/")"
fi
if (( ${#TRACKED[@]} == 0 )); then
  log "no manifest tracked_doctrines — defaulting to ALL upstream doctrine docs"
  while IFS= read -r f; do
    rel="${f#"$UPSTREAM"/}"
    TRACKED+=("$rel")
  done < <(find "$UPSTREAM" -type f \( -name '*.md' -o -name '*.json' -o -name '*.yaml' -o -name '*.yml' \) | sort)
fi

# ---------- compute per-doc deltas ----------
PER_DOC_JSON="["
FIRST=1
CHANGED=0
NEW=0
SAME=0
MISSING_UP=0

emit_per_doc() {
  local name="$1" up_sha="$2" lo_sha="$3" status="$4" size="$5"
  (( FIRST )) || PER_DOC_JSON+=","
  FIRST=0
  PER_DOC_JSON+=$(printf '{"name":"%s","upstream_sha":"%s","local_sha":"%s","status":"%s","size":%s}' \
                  "$name" "$up_sha" "$lo_sha" "$status" "$size")
}

for name in "${TRACKED[@]}"; do
  up="$UPSTREAM/$name"
  lo="$CONSUMER_DOC_DIR/$name"
  if [[ ! -f "$up" ]]; then
    emit_per_doc "$name" "" "" "missing_upstream" 0
    MISSING_UP=$((MISSING_UP+1))
    continue
  fi
  up_sha="$(sha_file "$up")"
  size="$(wc -c <"$up" | tr -d ' ')"
  if [[ -f "$lo" ]]; then
    lo_sha="$(sha_file "$lo")"
    if [[ "$up_sha" == "$lo_sha" ]]; then
      emit_per_doc "$name" "$up_sha" "$lo_sha" "same" "$size"
      SAME=$((SAME+1))
    else
      emit_per_doc "$name" "$up_sha" "$lo_sha" "changed" "$size"
      CHANGED=$((CHANGED+1))
    fi
  else
    emit_per_doc "$name" "$up_sha" "" "new" "$size"
    NEW=$((NEW+1))
  fi
done
PER_DOC_JSON+="]"

# ---------- mode-specific behavior ----------
REFUSAL_REASON=""
DIRTY_FILES_JSON="[]"
APPLIED_COUNT=0
GIT_STATUS_PRE="$(git -C "$CONSUMER_ROOT" status --porcelain --untracked-files=all || true)"
GIT_STATUS_POST=""

case "$MODE" in
  dry-run)
    log "would-change summary: changed=$CHANGED new=$NEW same=$SAME missing_upstream=$MISSING_UP"
    log "(run with --diff-only to see file diffs, --apply to mutate)"
    ;;

  diff-only)
    for name in "${TRACKED[@]}"; do
      up="$UPSTREAM/$name"; lo="$CONSUMER_DOC_DIR/$name"
      [[ -f "$up" ]] || continue
      if [[ ! -f "$lo" ]]; then
        printf '\n=== %s (NEW) ===\n' "$name"
        printf '+++ %s (would be created)\n' "$lo"
        continue
      fi
      if ! diff -q "$lo" "$up" >/dev/null 2>&1; then
        printf '\n=== %s ===\n' "$name"
        diff -u "$lo" "$up" || true
      fi
    done
    ;;

  apply)
    # HARD GATE: clean WT outside .flywheel/doctrine/
    DIRTY_OUTSIDE=()
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      # porcelain format: "XY path"; strip status
      path="${entry:3}"
      # strip optional rename arrow
      path="${path%% -> *}"
      case "$path" in
        .flywheel/doctrine/*) : ;;  # OK, scoped to managed surface
        .flywheel/evidence/sync-doctrine-*) : ;;  # OK, this command's own receipts
        .flywheel/evidence/) : ;;  # OK, untracked dir created by this command
        .flywheel/evidence) : ;;
        .flywheel/DOCTRINE-MANIFEST.json) : ;;  # OK, manifest updates by this command
        *) DIRTY_OUTSIDE+=("$path") ;;
      esac
    done <<< "$GIT_STATUS_PRE"

    if (( ${#DIRTY_OUTSIDE[@]} > 0 )); then
      REFUSAL_REASON="unrelated dirty files: ${DIRTY_OUTSIDE[*]}"
      DIRTY_FILES_JSON="["
      df_first=1
      for f in "${DIRTY_OUTSIDE[@]}"; do
        (( df_first )) || DIRTY_FILES_JSON+=","
        df_first=0
        DIRTY_FILES_JSON+="\"$f\""
      done
      DIRTY_FILES_JSON+="]"
      err "REFUSE --apply: ${#DIRTY_OUTSIDE[@]} unrelated dirty file(s) outside .flywheel/doctrine/"
      err "  files: ${DIRTY_OUTSIDE[*]}"
      err "  fix: git stash push -- <files>  OR  git commit -- <files>  OR  git checkout -- <files>"
      err "  then re-run: flywheel-sync-doctrine.sh --apply"
      MODE="apply-refused"
    else
      # do the copy
      for name in "${TRACKED[@]}"; do
        up="$UPSTREAM/$name"; lo="$CONSUMER_DOC_DIR/$name"
        [[ -f "$up" ]] || continue
        # skip if same
        if [[ -f "$lo" ]] && [[ "$(sha_file "$up")" == "$(sha_file "$lo")" ]]; then
          continue
        fi
        # skip if path lives under consumer-overrides
        case "$name" in
          "$OVERRIDES_DIR"*) log "skipping override-protected: $name"; continue ;;
        esac
        mkdir -p "$(dirname "$lo")"
        cp "$up" "$lo"
        APPLIED_COUNT=$((APPLIED_COUNT+1))
      done
      log "applied=$APPLIED_COUNT"
      GIT_STATUS_POST="$(git -C "$CONSUMER_ROOT" status --porcelain --untracked-files=all || true)"
    fi
    ;;
esac

# ---------- emit receipt ----------
# escape JSON via python if available; fallback to crude
json_escape() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
  else
    # crude: replace " and newlines
    sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | sed 's/^/"/; s/$/"/'
  fi
}
GS_PRE_JSON="$(printf '%s' "$GIT_STATUS_PRE" | json_escape)"
GS_POST_JSON="$(printf '%s' "$GIT_STATUS_POST" | json_escape)"
REFUSAL_JSON="$(printf '%s' "$REFUSAL_REASON" | json_escape)"

cat >"$RECEIPT" <<EOF
{
  "version": "$VERSION",
  "ts": "$(ts)",
  "mode": "$MODE",
  "bead": "flywheel-k8pee",
  "manifest_path": "$MANIFEST",
  "upstream_root": "$UPSTREAM",
  "consumer_root": "$CONSUMER_ROOT",
  "pin_policy": "$PIN_POLICY",
  "summary": {
    "changed": $CHANGED,
    "new": $NEW,
    "same": $SAME,
    "missing_upstream": $MISSING_UP,
    "applied_count": $APPLIED_COUNT
  },
  "per_doc": $PER_DOC_JSON,
  "git_status_pre": $GS_PRE_JSON,
  "git_status_post": $GS_POST_JSON,
  "refusal_reason": $REFUSAL_JSON,
  "dirty_files": $DIRTY_FILES_JSON
}
EOF

log "receipt: $RECEIPT"

# exit non-zero if refused so callers can detect
if [[ "$MODE" == "apply-refused" ]]; then
  exit 3
fi
exit 0
