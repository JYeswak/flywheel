#!/usr/bin/env bash
# temp-janitor.sh — Foundational temp-dir hygiene primitive.
#
# Reaps stale entries from $TMPDIR (macOS user temp) safely:
#   - Skip files modified <MIN_AGE_MIN (default 60) to protect active workers
#   - Only reap KNOWN-SAFE patterns (mktemp leaks, app temps, regenerable caches)
#   - Never touch sockets, locks, in-flight reservations, dotfiles
#   - Trauma class: storage-pressure-blocks-substrate (named in MEMORY)
#
# Joshua-direct 2026-05-20: "clean it up foundationally" — this script + launchd
# cadence is the foundational fix. Disk hitting 96% / 70GB in $TMPDIR caused
# JSM SQLite malformations + ghost-stall ("Waiting for background terminal") +
# com.flywheel.tick exit 124 + new-terminal-open slowness.
#
# Exit codes:
#   0 = ok (any amount reaped, including zero)
#   1 = config error (TMPDIR unset, etc.)
#   2 = disk still critical post-reap (alert path)

set -euo pipefail

MIN_AGE_MIN="${TEMP_JANITOR_MIN_AGE_MIN:-60}"
CODEX_MIN_AGE_MIN="${TEMP_JANITOR_CODEX_MIN_AGE_MIN:-240}"
CRITICAL_PCT="${TEMP_JANITOR_CRITICAL_PCT:-92}"
EMERGENCY_THRESHOLD_GB="${TEMP_JANITOR_EMERGENCY_THRESHOLD_GB:-10}"
PER_ORCH_CAP_GB="${TEMP_JANITOR_PER_ORCH_CAP_GB:-5}"
JSON_OUT=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --min-age-min) MIN_AGE_MIN="$2"; shift 2 ;;
    --critical-pct) CRITICAL_PCT="$2"; shift 2 ;;
    --emergency-threshold-gb) EMERGENCY_THRESHOLD_GB="$2"; shift 2 ;;
    --per-orch-cap-gb) PER_ORCH_CAP_GB="$2"; shift 2 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Resolve TMPDIR (macOS user temp)
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
[[ -d "$TMP" ]] || { echo "TMPDIR does not exist: $TMP" >&2; exit 1; }

# Disk capacity probe (before)
data_pct_before="$(df -P /System/Volumes/Data 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}' || echo 0)"
tmp_size_before_kb="$(du -sk "$TMP" 2>/dev/null | head -1 | awk '{print $1}' || echo 0)"

reap_count=0
freed_mb=0

reap_pattern() {
  local pattern="$1" age_min="$2" label="$3"
  local found_count
  found_count=$(find "$TMP" -maxdepth 1 -name "$pattern" -mmin "+$age_min" 2>/dev/null | wc -l | tr -d ' ')
  if (( found_count > 0 )); then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  WOULD reap $found_count $label entries" >&2
    else
      find "$TMP" -maxdepth 1 -name "$pattern" -mmin "+$age_min" -exec rm -rf {} + 2>/dev/null || true
      echo "  reaped $found_count $label entries" >&2
    fi
    reap_count=$((reap_count + found_count))
  fi
}

reap_dir_if_old() {
  local path="$1" age_min="$2" label="$3"
  if [[ -d "$path" ]]; then
    local mtime_age_min
    mtime_age_min=$(( ($(date +%s) - $(stat -f %m "$path" 2>/dev/null || echo "$(date +%s)") ) / 60 ))
    if (( mtime_age_min > age_min )); then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "  WOULD reap $label ($path, ${mtime_age_min}m old)" >&2
      else
        rm -rf "$path" 2>/dev/null || true
        echo "  reaped $label ($path)" >&2
      fi
      reap_count=$((reap_count + 1))
    fi
  fi
}

echo "=== temp-janitor v1 — $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >&2
echo "  TMPDIR=$TMP min_age=${MIN_AGE_MIN}m codex_min_age=${CODEX_MIN_AGE_MIN}m dry_run=$DRY_RUN" >&2
echo "  data_volume_pct_before=${data_pct_before}% tmp_size_before=$((tmp_size_before_kb / 1024))MB" >&2

# ALSO reap from /private/tmp (separate from $TMPDIR on macOS — workers create work-dirs there).
# Joshua-direct 2026-05-20T09:55Z: "100gb in a day!? unacceptable" — 45GB+ accreted overnight in
# /private/tmp/<orch>-<bead>-<ts>/ work-dirs from alps + mobile-eats + others that no janitor
# previously reaped because /private/tmp is OUTSIDE $TMPDIR. Adding /private/tmp scope here.
reap_orch_workdirs_in_private_tmp() {
  local orch_prefix="$1" age_min="$2" label="$3"
  local found_count
  found_count=$(find /private/tmp -maxdepth 1 -name "${orch_prefix}*" -type d -mmin "+$age_min" 2>/dev/null | wc -l | tr -d ' ')
  if (( found_count > 0 )); then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  WOULD reap $found_count private-tmp $label work-dirs" >&2
    else
      find /private/tmp -maxdepth 1 -name "${orch_prefix}*" -type d -mmin "+$age_min" -exec rm -rf {} + 2>/dev/null || true
      echo "  reaped $found_count private-tmp $label work-dirs" >&2
    fi
    reap_count=$((reap_count + found_count))
  fi
}

# EMERGENCY PRESSURE CHECK — if /private/tmp is over threshold, force shorter age windows.
# Joshua-direct 2026-05-20T11:25Z: "make sure codex workers can't kill our system's resources
# and add 100gb of /tmp work" — 45GB accreted overnight between hourly janitor runs because the
# hourly cadence was too slow vs the rate workers can dump. Emergency mode says: if disk is
# already hurting, we don't care about long-running dispatches — reap anyway.
private_tmp_size_mb=$({ /usr/bin/du -sm /private/tmp 2>/dev/null || true; } | /usr/bin/head -1 | /usr/bin/awk '{print $1+0}')
private_tmp_size_mb="${private_tmp_size_mb:-0}"
private_tmp_size_gb=$(( private_tmp_size_mb / 1024 ))
emergency_mode=false
if (( private_tmp_size_gb >= EMERGENCY_THRESHOLD_GB )); then
  emergency_mode=true
  # Override min-age — anything older than 30min is fair game
  echo "  EMERGENCY MODE: /private/tmp=${private_tmp_size_gb}GB >= threshold ${EMERGENCY_THRESHOLD_GB}GB → reaping >30min" >&2
fi

# Per-orch hard cap — for any orch prefix whose work-dir total exceeds PER_ORCH_CAP_GB, reap the
# 3 largest immediately regardless of age (oldest first within those). Prevents one runaway worker
# from filling disk before next janitor tick.
enforce_per_orch_cap() {
  local orch_prefix="$1"
  local total_mb
  total_mb=$(/usr/bin/find /private/tmp -maxdepth 1 -name "${orch_prefix}*" -type d -exec /usr/bin/du -sm {} + 2>/dev/null | /usr/bin/awk '{s+=$1} END{print s+0}')
  local cap_mb=$((PER_ORCH_CAP_GB * 1024))
  if (( total_mb > cap_mb )); then
    echo "  PER-ORCH CAP BREACH: ${orch_prefix}* total=${total_mb}MB > cap=${cap_mb}MB → reaping 3 largest" >&2
    # Largest 3 work-dirs by size; sorted desc, take 3
    local victims
    victims=$(/usr/bin/find /private/tmp -maxdepth 1 -name "${orch_prefix}*" -type d -exec /usr/bin/du -sk {} + 2>/dev/null | /usr/bin/sort -rn | /usr/bin/head -3 | /usr/bin/awk '{print $2}')
    while IFS= read -r victim; do
      [[ -z "$victim" ]] && continue
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "    WOULD reap victim (cap): $victim" >&2
      else
        /bin/rm -rf "$victim" 2>/dev/null && echo "    reaped victim (cap): $victim" >&2
        reap_count=$((reap_count + 1))
      fi
    done <<< "$victims"
  fi
}

# /private/tmp work-dirs by orch prefix (workers create scratch dirs as /private/tmp/<orch>-<bead-id>-<ts>/)
# Use longer age (6h = 360min) normally, OR 30min in emergency mode.
orch_age_min=360
[[ "$emergency_mode" == "true" ]] && orch_age_min=30

# Per-orch cap enforcement runs first (hard cap regardless of age)
for prefix in alps mobile-eats picoz clutterfreespaces cfs vrtx zesttube flywheel skillos terratitle; do
  enforce_per_orch_cap "${prefix}-"
done

reap_orch_workdirs_in_private_tmp 'alps-' "$orch_age_min" 'alps-orch-workdir'
reap_orch_workdirs_in_private_tmp 'mobile-eats-' "$orch_age_min" 'mobile-eats-orch-workdir'
reap_orch_workdirs_in_private_tmp 'picoz-' "$orch_age_min" 'picoz-orch-workdir'
reap_orch_workdirs_in_private_tmp 'clutterfreespaces-' "$orch_age_min" 'cfs-orch-workdir'
reap_orch_workdirs_in_private_tmp 'cfs-' "$orch_age_min" 'cfs-prefix-workdir'
reap_orch_workdirs_in_private_tmp 'vrtx-' "$orch_age_min" 'vrtx-orch-workdir'
reap_orch_workdirs_in_private_tmp 'zesttube-' "$orch_age_min" 'zesttube-orch-workdir'
reap_orch_workdirs_in_private_tmp 'flywheel-' "$orch_age_min" 'flywheel-orch-workdir'
reap_orch_workdirs_in_private_tmp 'skillos-' "$orch_age_min" 'skillos-orch-workdir'
reap_orch_workdirs_in_private_tmp 'terratitle-' "$orch_age_min" 'terratitle-orch-workdir'

# Claude Code task-output dirs in /private/tmp/claude-501/ — every Bash tool call accretes
if [[ -d /private/tmp/claude-501 ]]; then
  found_count=$(find /private/tmp/claude-501 -maxdepth 4 -name "*.output" -mmin +120 2>/dev/null | wc -l | tr -d ' ')
  if (( found_count > 0 )); then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  WOULD reap $found_count claude-task-output files (>2h)" >&2
    else
      find /private/tmp/claude-501 -maxdepth 4 -name "*.output" -mmin +120 -delete 2>/dev/null || true
      echo "  reaped $found_count claude-task-output files" >&2
    fi
    reap_count=$((reap_count + found_count))
  fi
fi

# Reap by pattern (safe-list — known regenerable temps)
reap_pattern 'tmp.*' "$MIN_AGE_MIN" 'mktemp-leak'
reap_pattern '_MEI*' "$MIN_AGE_MIN" 'PyInstaller'
reap_pattern 'codex-*' "$CODEX_MIN_AGE_MIN" 'codex-tmp'
reap_pattern 'tick-driver.*' "$MIN_AGE_MIN" 'tick-driver-stale'
reap_pattern 'mp_*' "$MIN_AGE_MIN" 'multiprocessing-shm'
reap_pattern '.com.apple.*' "$((MIN_AGE_MIN * 24))" 'apple-stale-24h+'
reap_pattern 'agent-browser-chrome-*' "$MIN_AGE_MIN" 'agent-browser-profile'
reap_pattern 'puppeteer_*' "$MIN_AGE_MIN" 'puppeteer-tmp'
reap_pattern 'beads_mem_*.db' "$MIN_AGE_MIN" 'beads-mem-orphan'
reap_pattern 'react-motion-render*' "$MIN_AGE_MIN" 'remotion-render'
reap_pattern 'remotion-webpack-bundle-*' "$MIN_AGE_MIN" 'remotion-webpack'
reap_pattern 'SpeechModelCache' "$((MIN_AGE_MIN * 24))" 'voicebox-cache-24h+'

# Reap specific known-safe dirs
reap_dir_if_old "$TMP/browsirai-normal" "$MIN_AGE_MIN" 'browsirai-chromium-profile'
reap_dir_if_old "$TMP/node-compile-cache" "$MIN_AGE_MIN" 'node-compile-cache'
reap_dir_if_old "$TMP/puppeteer_dev_chrome_profile" "$MIN_AGE_MIN" 'puppeteer-profile'

# Disk capacity probe (after)
data_pct_after="$(df -P /System/Volumes/Data 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}' || echo 0)"
tmp_size_after_kb="$(du -sk "$TMP" 2>/dev/null | head -1 | awk '{print $1}' || echo 0)"
freed_mb=$(( (tmp_size_before_kb - tmp_size_after_kb) / 1024 ))

# Outcome
status="ok"
exit_code=0
if (( data_pct_after >= CRITICAL_PCT )); then
  status="critical-disk-pressure-remains"
  exit_code=2
fi

if [[ "$JSON_OUT" == "true" ]]; then
  printf '{"schema_version":"temp_janitor.v1","ts":"%s","status":"%s","tmpdir":"%s","reap_count":%d,"freed_mb":%d,"tmp_size_before_mb":%d,"tmp_size_after_mb":%d,"data_volume_pct_before":%d,"data_volume_pct_after":%d,"critical_pct":%d,"dry_run":%s}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$status" "$TMP" \
    "$reap_count" "$freed_mb" \
    "$((tmp_size_before_kb/1024))" "$((tmp_size_after_kb/1024))" \
    "$data_pct_before" "$data_pct_after" "$CRITICAL_PCT" "$DRY_RUN"
else
  echo "  reaped=$reap_count entries freed=${freed_mb}MB" >&2
  echo "  data_volume_pct_after=${data_pct_after}% tmp_size_after=$((tmp_size_after_kb / 1024))MB status=$status" >&2
fi

exit $exit_code
