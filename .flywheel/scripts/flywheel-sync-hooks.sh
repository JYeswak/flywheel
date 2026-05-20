#!/usr/bin/env bash
# flywheel-sync-hooks.sh — consumer-initiated pull of canonical flywheel hooks.
#
# SLB-3 (skillos:1 + flywheel:1 CONCUR 2026-05-20T22:55Z).
# DOCTRINE: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/hook-manifest-schema-v1.md
# SCHEMA:   .flywheel/schemas/HOOK-MANIFEST.schema.json (skillos.hook_manifest.v1)
# SISTER:   flywheel-sync-doctrine.sh
#
# Defense-in-depth (matches sync-doctrine contract):
#   * Default --dry-run; --apply hard-gated on clean WT outside managed paths.
#   * No HOOK-MANIFEST.json in consumer → fall back to "sync ALL canonical hooks".
#   * Upstream canonical .flywheel/hooks/ unreachable → fail-open (no-op).
#   * Honors hook_opt_out[] entries with reason logging.
#   * Receipt JSON at .flywheel/evidence/sync-hooks-<ts>.json.
#
# Per consumer-sovereignty rule (upstream_never_writes_into_consumer_trees),
# this script runs FROM the consumer repo. It reads canonical hooks from
# the local flywheel checkout and writes into the consumer's hook locations
# (.git/hooks/ for git hooks, ~/.claude/hooks/ for tool hooks).

set -euo pipefail

VERSION="flywheel-sync-hooks/v1"

# ---------- helpers ----------
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { [[ "$QUIET" == "1" ]] && return 0; printf '[sync-hooks] %s\n' "$*" >&2; }
err() { printf '[sync-hooks] ERROR: %s\n' "$*" >&2; }

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

expand_path() {
  # expand leading ~ and $HOME
  local p="$1"
  p="${p/#\~/$HOME}"
  printf '%s' "$p"
}

# ---------- argparse ----------
MODE="dry-run"
MANIFEST=""
QUIET=0
SCHEMA_MIGRATE=0

while (( $# > 0 )); do
  case "$1" in
    --dry-run)        MODE="dry-run";   shift ;;
    --diff-only)      MODE="diff-only"; shift ;;
    --apply)          MODE="apply";     shift ;;
    --manifest)       MANIFEST="${2:?--manifest needs path}"; shift 2 ;;
    --schema-migrate) SCHEMA_MIGRATE=1; shift ;;
    --quiet)          QUIET=1; shift ;;
    -h|--help)
      cat <<'EOF'
flywheel-sync-hooks.sh — consumer-initiated canonical hook pull

USAGE:
  flywheel-sync-hooks.sh [--dry-run|--diff-only|--apply]
                         [--manifest <path>] [--schema-migrate] [--quiet]

DEFAULT: --dry-run, manifest=.flywheel/HOOK-MANIFEST.json (auto-default if missing)
RECEIPT: .flywheel/evidence/sync-hooks-<ts>.json

Doctrine: skillos.hook_manifest.v1
SLB-3:    skillos:1 + flywheel:1 CONCUR 2026-05-20T22:55Z
EOF
      exit 0 ;;
    *) err "unknown arg: $1"; exit 2 ;;
  esac
done

require_tool git
require_tool jq

# ---------- locate consumer + upstream ----------
CONSUMER_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$CONSUMER_ROOT" ]]; then
  err "not inside a git repo — sync-hooks must run from inside the consumer repo"
  exit 2
fi

UPSTREAM_CANDIDATES=(
  "${HOME}/Developer/flywheel/.flywheel/hooks"
  "${HOME}/.flywheel/hooks"
)
UPSTREAM=""
for c in "${UPSTREAM_CANDIDATES[@]}"; do
  if [[ -d "$c" ]]; then UPSTREAM="$c"; break; fi
done

EVIDENCE_DIR="$CONSUMER_ROOT/.flywheel/evidence"
mkdir -p "$EVIDENCE_DIR"
TS_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RECEIPT="$EVIDENCE_DIR/sync-hooks-$TS_STAMP.json"

if [[ -z "$UPSTREAM" ]]; then
  # fail-open: write a no-op receipt and exit 0
  log "upstream canonical hooks unreachable (none of: ${UPSTREAM_CANDIDATES[*]}) — fail-open no-op"
  cat >"$RECEIPT" <<EOF
{
  "version": "$VERSION",
  "ts": "$(ts)",
  "mode": "$MODE",
  "consumer_root": "$CONSUMER_ROOT",
  "no_op_reason": "upstream-unreachable",
  "tracked": [],
  "applied_count": 0,
  "opted_out": []
}
EOF
  log "receipt: $RECEIPT"
  exit 0
fi

# ---------- manifest ----------
MANIFEST="${MANIFEST:-$CONSUMER_ROOT/.flywheel/HOOK-MANIFEST.json}"
HAS_MANIFEST=0
if [[ -f "$MANIFEST" ]]; then
  HAS_MANIFEST=1
fi

# ---------- determine tracked set ----------
# Default if no manifest: every *.sh in upstream is "required", install into ~/.claude/hooks/
declare -a TRACKED_IDS=()
declare -a TRACKED_CANONICAL=()
declare -a TRACKED_INSTALLED=()
declare -a TRACKED_STATUS=()
declare -a OPT_OUT_IDS=()
declare -A OPT_OUT_REASON=()
DEFAULT_INSTALL_DIR="$HOME/.claude/hooks"

if (( HAS_MANIFEST == 1 )); then
  log "reading manifest: $MANIFEST"
  schema_v=$(jq -r '.schema_version // empty' "$MANIFEST" 2>/dev/null || true)
  if [[ -n "$schema_v" && "$schema_v" != "skillos.hook_manifest.v1" ]]; then
    if (( SCHEMA_MIGRATE == 0 )); then
      err "manifest schema_version=$schema_v but expected skillos.hook_manifest.v1; re-run with --schema-migrate"
      exit 2
    fi
    log "--schema-migrate: rewriting manifest schema_version to skillos.hook_manifest.v1"
    tmpm="$(mktemp)"
    jq '.schema_version="skillos.hook_manifest.v1"' "$MANIFEST" > "$tmpm" && cp "$tmpm" "$MANIFEST" && rm -f "$tmpm"
  fi

  cldir=$(jq -r '.consumer_local_hooks_dir // empty' "$MANIFEST" 2>/dev/null || true)
  [[ -n "$cldir" ]] && DEFAULT_INSTALL_DIR="$(expand_path "$cldir")"

  # tracked hooks
  while IFS=$'\t' read -r id canpath instpath status; do
    [[ -z "$id" ]] && continue
    TRACKED_IDS+=("$id")
    TRACKED_CANONICAL+=("$canpath")
    TRACKED_INSTALLED+=("$(expand_path "$instpath")")
    TRACKED_STATUS+=("${status:-required}")
  done < <(jq -r '.tracked_hooks[]? | [.id, .canonical_path, .installed_path, (.status // "required")] | @tsv' "$MANIFEST" 2>/dev/null || true)

  # opt-out
  while IFS=$'\t' read -r id reason; do
    [[ -z "$id" ]] && continue
    OPT_OUT_IDS+=("$id")
    OPT_OUT_REASON["$id"]="$reason"
  done < <(jq -r '.hook_opt_out[]? | [.id, (.reason // "no-reason")] | @tsv' "$MANIFEST" 2>/dev/null || true)
fi

if (( ${#TRACKED_IDS[@]} == 0 )); then
  if (( HAS_MANIFEST == 1 )); then
    log "manifest present but tracked_hooks empty — defaulting to ALL canonical hooks"
  else
    log "no manifest — defaulting to ALL canonical hooks → $DEFAULT_INSTALL_DIR"
  fi
  while IFS= read -r f; do
    base="$(basename "$f")"
    id="${base%.sh}"
    TRACKED_IDS+=("$id")
    TRACKED_CANONICAL+=(".flywheel/hooks/$base")
    TRACKED_INSTALLED+=("$DEFAULT_INSTALL_DIR/$base")
    TRACKED_STATUS+=("required")
  done < <(find "$UPSTREAM" -maxdepth 1 -type f -name '*.sh' | sort)
fi

is_opted_out() {
  local id="$1"
  for o in "${OPT_OUT_IDS[@]}"; do
    [[ "$o" == "$id" ]] && return 0
  done
  return 1
}

# ---------- compute per-hook deltas ----------
PER_HOOK_JSON="["
FIRST=1
CHANGED=0
NEW=0
SAME=0
MISSING_UP=0
OPTED=0

emit_per_hook() {
  local id="$1" up_sha="$2" lo_sha="$3" status="$4" inst="$5" canpath="$6" opt_reason="$7"
  (( FIRST )) || PER_HOOK_JSON+=","
  FIRST=0
  PER_HOOK_JSON+=$(jq -nc \
    --arg id "$id" --arg up "$up_sha" --arg lo "$lo_sha" \
    --arg st "$status" --arg inst "$inst" --arg can "$canpath" --arg orr "$opt_reason" \
    '{id:$id, upstream_sha:$up, installed_sha:$lo, status:$st, installed_path:$inst, canonical_path:$can, opt_out_reason:$orr}')
}

for i in "${!TRACKED_IDS[@]}"; do
  id="${TRACKED_IDS[$i]}"
  canrel="${TRACKED_CANONICAL[$i]}"
  inst="${TRACKED_INSTALLED[$i]}"
  # resolve canonical absolute (canpath under flywheel root)
  upabs="${HOME}/Developer/flywheel/${canrel}"
  [[ ! -f "$upabs" ]] && upabs="$UPSTREAM/$(basename "$canrel")"

  if is_opted_out "$id"; then
    emit_per_hook "$id" "" "" "opted_out" "$inst" "$canrel" "${OPT_OUT_REASON[$id]}"
    OPTED=$((OPTED+1))
    continue
  fi

  if [[ ! -f "$upabs" ]]; then
    emit_per_hook "$id" "" "" "missing_upstream" "$inst" "$canrel" ""
    MISSING_UP=$((MISSING_UP+1))
    continue
  fi
  up_sha="$(sha_file "$upabs")"
  if [[ -f "$inst" ]]; then
    lo_sha="$(sha_file "$inst")"
    if [[ "$up_sha" == "$lo_sha" ]]; then
      emit_per_hook "$id" "$up_sha" "$lo_sha" "same" "$inst" "$canrel" ""
      SAME=$((SAME+1))
    else
      emit_per_hook "$id" "$up_sha" "$lo_sha" "changed" "$inst" "$canrel" ""
      CHANGED=$((CHANGED+1))
    fi
  else
    emit_per_hook "$id" "$up_sha" "" "new" "$inst" "$canrel" ""
    NEW=$((NEW+1))
  fi
done
PER_HOOK_JSON+="]"

# ---------- mode-specific behavior ----------
REFUSAL_REASON=""
DIRTY_FILES_JSON="[]"
APPLIED_COUNT=0
GIT_STATUS_PRE="$(git -C "$CONSUMER_ROOT" status --porcelain --untracked-files=all || true)"
GIT_STATUS_POST=""
NO_OP_REASON=""

case "$MODE" in
  dry-run)
    log "would-change: changed=$CHANGED new=$NEW same=$SAME opted_out=$OPTED missing_upstream=$MISSING_UP"
    log "(--diff-only for file diffs, --apply to install)"
    if (( CHANGED == 0 && NEW == 0 )); then
      NO_OP_REASON="nothing-new"
    fi
    ;;

  diff-only)
    for i in "${!TRACKED_IDS[@]}"; do
      id="${TRACKED_IDS[$i]}"
      canrel="${TRACKED_CANONICAL[$i]}"
      inst="${TRACKED_INSTALLED[$i]}"
      upabs="${HOME}/Developer/flywheel/${canrel}"
      [[ ! -f "$upabs" ]] && upabs="$UPSTREAM/$(basename "$canrel")"
      is_opted_out "$id" && continue
      [[ -f "$upabs" ]] || continue
      if [[ ! -f "$inst" ]]; then
        printf '\n=== %s (NEW) ===\n' "$id"
        printf '+++ %s (would be created)\n' "$inst"
        continue
      fi
      if ! diff -q "$inst" "$upabs" >/dev/null 2>&1; then
        printf '\n=== %s ===\n' "$id"
        diff -u "$inst" "$upabs" || true
      fi
    done
    ;;

  apply)
    # HARD GATE: clean WT outside .flywheel/evidence/sync-hooks-* and HOOK-MANIFEST.json
    DIRTY_OUTSIDE=()
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      path="${entry:3}"
      path="${path%% -> *}"
      case "$path" in
        .flywheel/evidence/sync-hooks-*) : ;;
        .flywheel/evidence/) : ;;
        .flywheel/evidence) : ;;
        .flywheel/HOOK-MANIFEST.json) : ;;
        *) DIRTY_OUTSIDE+=("$path") ;;
      esac
    done <<< "$GIT_STATUS_PRE"

    if (( ${#DIRTY_OUTSIDE[@]} > 0 )); then
      REFUSAL_REASON="unrelated dirty files: ${DIRTY_OUTSIDE[*]}"
      DIRTY_FILES_JSON=$(printf '%s\n' "${DIRTY_OUTSIDE[@]}" | jq -R . | jq -s .)
      err "REFUSE --apply: ${#DIRTY_OUTSIDE[@]} unrelated dirty file(s)"
      err "  files: ${DIRTY_OUTSIDE[*]}"
      err "  fix: commit / stash / checkout, then retry"
      MODE="apply-refused"
      NO_OP_REASON="clean-WT-violated"
    else
      for i in "${!TRACKED_IDS[@]}"; do
        id="${TRACKED_IDS[$i]}"
        canrel="${TRACKED_CANONICAL[$i]}"
        inst="${TRACKED_INSTALLED[$i]}"
        upabs="${HOME}/Developer/flywheel/${canrel}"
        [[ ! -f "$upabs" ]] && upabs="$UPSTREAM/$(basename "$canrel")"
        if is_opted_out "$id"; then
          log "SKIP opted-out: $id (reason: ${OPT_OUT_REASON[$id]})"
          continue
        fi
        [[ -f "$upabs" ]] || { log "SKIP missing-upstream: $id"; continue; }
        if [[ -f "$inst" ]] && [[ "$(sha_file "$upabs")" == "$(sha_file "$inst")" ]]; then
          continue
        fi
        mkdir -p "$(dirname "$inst")"
        cp "$upabs" "$inst"
        chmod +x "$inst"
        APPLIED_COUNT=$((APPLIED_COUNT+1))
        log "installed $id → $inst"
      done
      log "applied=$APPLIED_COUNT"
      GIT_STATUS_POST="$(git -C "$CONSUMER_ROOT" status --porcelain --untracked-files=all || true)"

      # Update manifest audit fields if manifest exists
      if (( HAS_MANIFEST == 1 )); then
        last_sha="$(git -C "$HOME/Developer/flywheel" rev-parse HEAD 2>/dev/null || echo unknown)"
        tmpm="$(mktemp)"
        jq --arg ts "$(ts)" --arg sha "$last_sha" --arg cmd "$VERSION --apply" \
          '.last_sync_ts=$ts | .last_sync_sha=$sha | .audit = (.audit // {}) | .audit.last_sync_at=$ts | .audit.last_sync_command=$cmd | .audit.last_conformance_status="conformant"' \
          "$MANIFEST" > "$tmpm" && cp "$tmpm" "$MANIFEST" && rm -f "$tmpm"
      fi
    fi
    ;;
esac

# ---------- opt-out list JSON ----------
OPT_OUT_JSON="["
fo=1
for id in "${OPT_OUT_IDS[@]}"; do
  (( fo )) || OPT_OUT_JSON+=","
  fo=0
  OPT_OUT_JSON+=$(jq -nc --arg id "$id" --arg reason "${OPT_OUT_REASON[$id]}" '{id:$id, reason:$reason}')
done
OPT_OUT_JSON+="]"

# ---------- emit receipt ----------
DASHBOARD_LINE=""
case "$MODE" in
  apply)
    DASHBOARD_LINE="hooks: applied=$APPLIED_COUNT changed=$CHANGED new=$NEW opt_out=$OPTED missing=$MISSING_UP"
    ;;
  apply-refused)
    DASHBOARD_LINE="hooks: REFUSED (clean-WT violated)"
    ;;
  *)
    DASHBOARD_LINE="hooks: dry-run changed=$CHANGED new=$NEW same=$SAME opt_out=$OPTED"
    ;;
esac

# JSON-safe receipt assembly
jq -n \
  --arg version "$VERSION" \
  --arg ts "$(ts)" \
  --arg mode "$MODE" \
  --arg consumer "$CONSUMER_ROOT" \
  --arg upstream "$UPSTREAM" \
  --arg manifest "$MANIFEST" \
  --arg refusal "$REFUSAL_REASON" \
  --arg no_op "$NO_OP_REASON" \
  --arg gs_pre "$GIT_STATUS_PRE" \
  --arg gs_post "$GIT_STATUS_POST" \
  --arg dashboard "$DASHBOARD_LINE" \
  --argjson per_hook "$PER_HOOK_JSON" \
  --argjson opt_out "$OPT_OUT_JSON" \
  --argjson dirty "$DIRTY_FILES_JSON" \
  --argjson changed $CHANGED --argjson new $NEW --argjson same $SAME \
  --argjson opted $OPTED --argjson missing $MISSING_UP --argjson applied $APPLIED_COUNT \
  '{
    version:$version, ts:$ts, mode:$mode, slb:"SLB-3",
    consumer_root:$consumer, upstream_root:$upstream, manifest_path:$manifest,
    summary:{changed:$changed, new:$new, same:$same, opted_out:$opted, missing_upstream:$missing, applied_count:$applied},
    per_hook:$per_hook, opt_out:$opt_out,
    refusal_reason:$refusal, no_op_reason:$no_op,
    dirty_files:$dirty, git_status_pre:$gs_pre, git_status_post:$gs_post,
    dashboard_line:$dashboard
  }' > "$RECEIPT"

log "receipt: $RECEIPT"
if [[ "$QUIET" == "1" ]]; then
  cat "$RECEIPT"
fi

if [[ "$MODE" == "apply-refused" ]]; then
  exit 3
fi
exit 0
