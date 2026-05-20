#!/usr/bin/env bash
# developer-cache-janitor.sh — Daily janitor for ~/Developer regenerable build artifacts.
#
# Joshua-direct 2026-05-20T20:00Z: "this needs to be a scripted process - you cannot expect
# me to come in every single day and run this type of stuff to clean up projects trash"
#
# Reaps from ~/Developer/* (all repos):
#   - Cargo target/ dirs older than --target-age-days (default 7) — regenerable via cargo build
#   - .next build caches older than --next-age-days (default 14) — regenerable via next build
#   - node_modules in repos not git-touched in --node-modules-stale-days (default 30) —
#     regenerable via pnpm/npm/yarn install
#   - dist/, build/, .turbo/, .cache/ dirs (regenerable build outputs) older than 14d
#   - Python .venv in repos not git-touched in 60d — regenerable via uv/pip install
#   - .DS_Store cleanup (always safe)
#
# Plus system-level safe ops:
#   - Empty ~/.Trash (via Finder for compatibility)
#   - APFS local snapshot thinning
#   - brew cleanup --prune=7
#
# Trauma class: storage-pressure-blocks-substrate. Sister to temp-janitor.sh which covers /private/tmp.
# Wires into the foundational storage philosophy 5-tier model.
#
# Exit codes:
#   0 = ok (any amount reaped, including zero)
#   1 = config error
#   2 = disk still critical post-reap (alert path; tier still >=3)

set -euo pipefail

# Defaults — conservative; can be tuned per-cron via flags
TARGET_AGE_DAYS="${DEV_JANITOR_TARGET_AGE_DAYS:-7}"
NEXT_AGE_DAYS="${DEV_JANITOR_NEXT_AGE_DAYS:-14}"
NODE_MODULES_STALE_DAYS="${DEV_JANITOR_NODE_MODULES_STALE_DAYS:-30}"
BUILD_AGE_DAYS="${DEV_JANITOR_BUILD_AGE_DAYS:-14}"
VENV_STALE_DAYS="${DEV_JANITOR_VENV_STALE_DAYS:-60}"
CRITICAL_PCT="${DEV_JANITOR_CRITICAL_PCT:-90}"
DEVELOPER_DIR="${DEV_JANITOR_DEVELOPER_DIR:-$HOME/Developer}"
JSON_OUT=false
DRY_RUN=false
SKIP_TRASH=false
SKIP_BREW=false
SKIP_SNAPSHOT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --target-age-days) TARGET_AGE_DAYS="$2"; shift 2 ;;
    --next-age-days) NEXT_AGE_DAYS="$2"; shift 2 ;;
    --node-modules-stale-days) NODE_MODULES_STALE_DAYS="$2"; shift 2 ;;
    --build-age-days) BUILD_AGE_DAYS="$2"; shift 2 ;;
    --venv-stale-days) VENV_STALE_DAYS="$2"; shift 2 ;;
    --critical-pct) CRITICAL_PCT="$2"; shift 2 ;;
    --skip-trash) SKIP_TRASH=true; shift ;;
    --skip-brew) SKIP_BREW=true; shift ;;
    --skip-snapshot) SKIP_SNAPSHOT=true; shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

[[ -d "$DEVELOPER_DIR" ]] || { echo "DEVELOPER_DIR does not exist: $DEVELOPER_DIR" >&2; exit 1; }

NOW_TS=$(date -u +%s)
START_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Disk capacity probe (before)
data_pct_before="$(df -P /System/Volumes/Data 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}' || echo 0)"
free_before_kb="$(df -k /System/Volumes/Data 2>/dev/null | awk 'NR==2{print $4}' || echo 0)"
free_before_gb=$(( free_before_kb / 1024 / 1024 ))

reap_count=0
freed_target_count=0
freed_next_count=0
freed_node_modules_count=0
freed_build_count=0
freed_venv_count=0

log() { [[ "$JSON_OUT" == "true" ]] && return 0; printf '%s\n' "$1" >&2; }

log "=== developer-cache-janitor — $START_TS ==="
log "  DEVELOPER_DIR=$DEVELOPER_DIR dry_run=$DRY_RUN"
log "  data_volume_pct_before=${data_pct_before}% free_before=${free_before_gb}GiB"

# Helper: reap dir if --apply, else just log
maybe_reap_dir() {
  local path="$1" label="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "  WOULD reap $label: $path"
  else
    rm -rf "$path" 2>/dev/null || true
    log "  reaped $label: $path"
  fi
  reap_count=$((reap_count + 1))
}

# Helper: compute repo last-commit age in days
repo_age_days() {
  local repo="$1"
  local last_commit
  last_commit=$(git -C "$repo" log -1 --format=%ct 2>/dev/null || echo 0)
  [[ "$last_commit" == "0" ]] && echo 9999 && return
  echo $(( (NOW_TS - last_commit) / 86400 ))
}

# === STAGE A: Cargo target/ dirs older than --target-age-days ===
log ""
log "--- Stage A: Cargo target/ (age >${TARGET_AGE_DAYS}d) ---"
while IFS= read -r d; do
  [[ -z "$d" ]] && continue
  mtime_age_days=$(( (NOW_TS - $(stat -f %m "$d" 2>/dev/null || echo "$NOW_TS")) / 86400 ))
  if (( mtime_age_days > TARGET_AGE_DAYS )); then
    maybe_reap_dir "$d" "cargo-target-${mtime_age_days}d"
    freed_target_count=$((freed_target_count + 1))
  fi
done < <(find "$DEVELOPER_DIR" -maxdepth 4 -type d -name target -path "*/Developer/*/target" 2>/dev/null)
log "  cargo target dirs candidate/reaped: $freed_target_count"

# === STAGE B: .next build caches older than --next-age-days ===
log ""
log "--- Stage B: .next build cache (age >${NEXT_AGE_DAYS}d) ---"
while IFS= read -r d; do
  [[ -z "$d" ]] && continue
  mtime_age_days=$(( (NOW_TS - $(stat -f %m "$d" 2>/dev/null || echo "$NOW_TS")) / 86400 ))
  if (( mtime_age_days > NEXT_AGE_DAYS )); then
    maybe_reap_dir "$d" "next-build-${mtime_age_days}d"
    freed_next_count=$((freed_next_count + 1))
  fi
done < <(find "$DEVELOPER_DIR" -maxdepth 5 -type d -name ".next" 2>/dev/null)
log "  .next dirs candidate/reaped: $freed_next_count"

# === STAGE C: node_modules in repos not git-touched >--node-modules-stale-days ===
log ""
log "--- Stage C: node_modules in stale repos (git-untouched >${NODE_MODULES_STALE_DAYS}d) ---"
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  [[ ! -d "$repo/.git" ]] && continue
  age_days=$(repo_age_days "$repo")
  if (( age_days > NODE_MODULES_STALE_DAYS )); then
    # Reap top-level node_modules + any nested ones
    while IFS= read -r nm; do
      [[ -z "$nm" ]] && continue
      maybe_reap_dir "$nm" "node-modules-stale-repo-${age_days}d"
      freed_node_modules_count=$((freed_node_modules_count + 1))
    done < <(find "$repo" -maxdepth 4 -type d -name node_modules 2>/dev/null)
  fi
done < <(find "$DEVELOPER_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
log "  node_modules reaped in stale repos: $freed_node_modules_count"

# === STAGE D: dist/, build/, .turbo/, .cache/ dirs older than --build-age-days ===
log ""
log "--- Stage D: build artifact dirs (dist/build/.turbo/.cache age >${BUILD_AGE_DAYS}d) ---"
for pattern in dist build .turbo .cache; do
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    # Skip if inside node_modules (those die with parent reap)
    [[ "$d" == *"/node_modules/"* ]] && continue
    mtime_age_days=$(( (NOW_TS - $(stat -f %m "$d" 2>/dev/null || echo "$NOW_TS")) / 86400 ))
    if (( mtime_age_days > BUILD_AGE_DAYS )); then
      maybe_reap_dir "$d" "build-artifact-${pattern}-${mtime_age_days}d"
      freed_build_count=$((freed_build_count + 1))
    fi
  done < <(find "$DEVELOPER_DIR" -maxdepth 5 -type d -name "$pattern" 2>/dev/null)
done
log "  build artifact dirs reaped: $freed_build_count"

# === STAGE E: Python .venv in repos not git-touched >--venv-stale-days ===
log ""
log "--- Stage E: Python .venv in stale repos (git-untouched >${VENV_STALE_DAYS}d) ---"
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  [[ ! -d "$repo/.git" ]] && continue
  age_days=$(repo_age_days "$repo")
  if (( age_days > VENV_STALE_DAYS )); then
    for venv_name in .venv venv .env env; do
      if [[ -d "$repo/$venv_name" ]] && [[ -f "$repo/$venv_name/pyvenv.cfg" ]]; then
        maybe_reap_dir "$repo/$venv_name" "python-venv-stale-repo-${age_days}d"
        freed_venv_count=$((freed_venv_count + 1))
      fi
    done
  fi
done < <(find "$DEVELOPER_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
log "  python .venv reaped: $freed_venv_count"

# === STAGE F: .DS_Store cleanup (always safe) ===
log ""
log "--- Stage F: .DS_Store cleanup ---"
ds_count=$(find "$DEVELOPER_DIR" -name ".DS_Store" -type f 2>/dev/null | wc -l | tr -d ' ')
if (( ds_count > 0 )); then
  if [[ "$DRY_RUN" == "true" ]]; then
    log "  WOULD reap $ds_count .DS_Store files"
  else
    find "$DEVELOPER_DIR" -name ".DS_Store" -type f -delete 2>/dev/null || true
    log "  reaped $ds_count .DS_Store files"
  fi
fi

# === STAGE G: system-level safe ops ===
if [[ "$SKIP_TRASH" != "true" ]]; then
  log ""
  log "--- Stage G1: empty Trash ---"
  if [[ "$DRY_RUN" == "true" ]]; then
    trash_size=$(du -sh "$HOME/.Trash" 2>/dev/null | awk '{print $1}' || echo "0")
    log "  WOULD empty Trash (size: $trash_size)"
  else
    osascript -e 'tell application "Finder" to empty trash' 2>/dev/null || true
    log "  Trash emptied"
  fi
fi

if [[ "$SKIP_SNAPSHOT" != "true" ]]; then
  log ""
  log "--- Stage G2: APFS snapshot thinning ---"
  if [[ "$DRY_RUN" == "true" ]]; then
    snap_count=$(tmutil listlocalsnapshots / 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    log "  WOULD thin $snap_count APFS local snapshots"
  else
    tmutil thinlocalsnapshots / 50000000000 1 2>/dev/null | tail -1 >&2 || true
  fi
fi

if [[ "$SKIP_BREW" != "true" ]] && command -v brew >/dev/null 2>&1; then
  log ""
  log "--- Stage G3: brew cleanup ---"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "  WOULD run brew cleanup --prune=7"
  else
    brew cleanup --prune=7 2>&1 | tail -3 >&2 || true
  fi
fi

# Disk capacity probe (after)
data_pct_after="$(df -P /System/Volumes/Data 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}' || echo 0)"
free_after_kb="$(df -k /System/Volumes/Data 2>/dev/null | awk 'NR==2{print $4}' || echo 0)"
free_after_gb=$(( free_after_kb / 1024 / 1024 ))
freed_gb=$(( free_after_gb - free_before_gb ))

# Outcome
status="ok"
exit_code=0
if (( data_pct_after >= CRITICAL_PCT )); then
  status="critical-disk-pressure-remains"
  exit_code=2
fi

if [[ "$JSON_OUT" == "true" ]]; then
  printf '{"schema_version":"developer_cache_janitor.v1","ts":"%s","status":"%s","developer_dir":"%s","dry_run":%s,"reap_count":%d,"freed_gb":%d,"by_stage":{"cargo_target":%d,"next_build":%d,"node_modules":%d,"build_artifacts":%d,"python_venv":%d,"ds_store":%d},"data_volume_pct_before":%d,"data_volume_pct_after":%d,"free_before_gb":%d,"free_after_gb":%d,"critical_pct":%d}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$status" "$DEVELOPER_DIR" "$DRY_RUN" \
    "$reap_count" "$freed_gb" \
    "$freed_target_count" "$freed_next_count" "$freed_node_modules_count" "$freed_build_count" "$freed_venv_count" "$ds_count" \
    "$data_pct_before" "$data_pct_after" "$free_before_gb" "$free_after_gb" "$CRITICAL_PCT"
else
  log ""
  log "=== SUMMARY ==="
  log "  reaped=$reap_count entries  freed=${freed_gb}GiB"
  log "  data_volume_pct_after=${data_pct_after}%  free_after=${free_after_gb}GiB  status=$status"
fi

exit $exit_code
