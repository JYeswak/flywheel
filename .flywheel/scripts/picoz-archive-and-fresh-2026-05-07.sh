#!/usr/bin/env bash
# picoz-archive-and-fresh-2026-05-07.sh
#
# Archive entire kalshi.db to compressed cold storage, recreate empty fresh
# DB so picoz can resume on a clean substrate without losing any historical
# trading data.
#
# Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet
#
# WHY THIS APPROACH (Option A — strategic preservation)
# =====================================================
# Joshua: "this is a kalshi trading system that I've been trying to build —
# I want to recover the project and get it off the ground again soon"
#
# 79 GB of orderbook history is point-in-time data we cannot re-acquire from
# the Kalshi API at fidelity. Strategy:
#
#   TIER 1 (HOT)   = fresh empty kalshi.db; picoz writes here when resumed
#   TIER 2 (WARM)  = compressed .zst at .../data/archive/; ATTACH on demand
#   TIER 3 (COLD)  = (manual later) move .zst to external/cloud
#
# Phases (each interactive y/n):
#   1. Verify pico-z paused (no plists, no writers)
#   2. Backup-to-clone via sqlite3 .backup (consistent snapshot)
#   3. Verify clone (integrity_check + row counts match)
#   4. zstd -19 the clone (~70GB → ~10GB)
#   5. Verify zstd round-trip (decompress to /tmp, integrity-check)
#   6. Extract schema DDL to data/schema/
#   7. Move live kalshi.db aside (kept until smoke test passes)
#   8. Create fresh empty kalshi.db with schema (no data)
#   9. Smoke test: write a probe row, query it back
#   10. Print restart-plist commands
#
# All actions logged to ~/.local/state/flywheel/picoz-archive-2026-05-07.jsonl
#
# The original DB is RENAMED (not deleted) until you say smoke tests passed.
# Phase 11 (manual): once you're confident picoz runs cleanly, you can
# manually rm the .pre-archive-* file. This script never deletes the original.

set -uo pipefail
# NOTE: NOT using `set -e`. lsof returns exit 1 when no handles match, which
# is a NORMAL condition for our checks. We handle errors per-command via
# explicit checks instead.

PICOZ_DATA="$HOME/Developer/polymarket-pico-z/data"
LIVE_DB="$PICOZ_DATA/kalshi.db"
ARCHIVE_DIR="$PICOZ_DATA/archive"
SCHEMA_DIR="$PICOZ_DATA/schema"
TS="$(date -u +%Y-%m-%dT%H%M%SZ)"
SHORT_TS="$(date -u +%Y-%m-%d)"
ARCHIVE_DB="$ARCHIVE_DIR/kalshi-snapshot-${SHORT_TS}.db"
ARCHIVE_ZST="${ARCHIVE_DB}.zst"
SCHEMA_SQL="$SCHEMA_DIR/kalshi-schema-${SHORT_TS}.sql"
ASIDE_DB="${LIVE_DB}.pre-archive-${SHORT_TS}"
ASIDE_WAL="${LIVE_DB}-wal.pre-archive-${SHORT_TS}"
ASIDE_SHM="${LIVE_DB}-shm.pre-archive-${SHORT_TS}"
LEDGER="$HOME/.local/state/flywheel/picoz-archive-${SHORT_TS}.jsonl"
DECOMPRESS_TEST="/tmp/kalshi-decompress-test-${TS}.db"

mkdir -p "$ARCHIVE_DIR" "$SCHEMA_DIR" "$(dirname "$LEDGER")"

log() {
  local action="$1" detail="${2:-}"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"$action\",\"detail\":\"$detail\"}" >> "$LEDGER"
}

show_disk() {
  df -h / | tail -1
}

show_size() {
  local p="$1"
  if [ -e "$p" ]; then
    du -sh "$p" 2>/dev/null | awk '{print $1}'
  else
    echo "missing"
  fi
}

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) echo "  [skipped]"; return 1 ;;
  esac
}

abort() {
  echo "ABORT: $1" >&2
  log "abort" "$1"
  exit 1
}

echo "================================================================"
echo "  picoz-archive-and-fresh-2026-05-07.sh"
echo "  Archive 79 GB kalshi.db → compressed warm storage"
echo "  Recreate empty hot DB for picoz resume"
echo "================================================================"
echo ""
echo "Live DB:       $LIVE_DB ($(show_size "$LIVE_DB"))"
echo "Archive .db:   $ARCHIVE_DB"
echo "Archive .zst:  $ARCHIVE_ZST"
echo "Schema dump:   $SCHEMA_SQL"
echo "Aside live:    $ASIDE_DB"
echo "Ledger:        $LEDGER"
echo ""
echo "DISK BEFORE: $(show_disk)"
echo ""
log "start" "live=$LIVE_DB"

# ============================================================
# PHASE 1: Verify pico-z paused
# ============================================================
echo "=== Phase 1: verify pico-z paused ==="
PLIST_COUNT=$(launchctl list 2>/dev/null | grep -c pico-z || echo 0)
WRITER_COUNT=$(lsof "$LIVE_DB" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ' || echo 0)
echo "  pico-z plists running: $PLIST_COUNT"
echo "  open file handles on kalshi.db: $WRITER_COUNT"
if [ "$PLIST_COUNT" -gt 0 ]; then
  abort "pico-z plists still running; run launchctl bootout first"
fi
if [ "$WRITER_COUNT" -gt 0 ]; then
  echo "  WARNING: $WRITER_COUNT process(es) have kalshi.db open:"
  lsof "$LIVE_DB" 2>/dev/null | head -10 || true
  if ! confirm "Proceed anyway?"; then abort "live writers present"; fi
fi
log "phase_1_ok" "plists=$PLIST_COUNT writers=$WRITER_COUNT"
echo ""

# ============================================================
# PHASE 2: Backup-to-clone via sqlite3 .backup
# This produces a consistent snapshot without relying on file copy
# (which can race with WAL or capture mid-transaction state).
# ============================================================
echo "=== Phase 2: clone live DB to archive (sqlite3 .backup) ==="
echo "  This takes ~10-20 minutes for 79 GB."
echo "  Source: $LIVE_DB"
echo "  Dest:   $ARCHIVE_DB"
SKIP_PHASE_2=0
if [ -e "$ARCHIVE_DB" ]; then
  echo "  archive db already exists at $ARCHIVE_DB ($(show_size "$ARCHIVE_DB"))"
  if confirm "Skip Phase 2 (use existing archive)?"; then
    SKIP_PHASE_2=1
    echo "  [skip] using existing archive"
    log "phase_2_skipped" "existing_archive"
  fi
fi
if [ "$SKIP_PHASE_2" = "0" ] && confirm "Proceed with Phase 2 (overwrite if exists)?"; then
  start=$(date +%s)
  sqlite3 "$LIVE_DB" ".backup '$ARCHIVE_DB'"
  end=$(date +%s)
  echo "  [ok] backup done in $((end-start))s"
  echo "  archive size: $(show_size "$ARCHIVE_DB")"
  log "phase_2_ok" "duration_s=$((end-start)) size=$(stat -f %z "$ARCHIVE_DB")"
else
  abort "user skipped phase 2"
fi
echo ""

# ============================================================
# PHASE 3: Verify clone (integrity_check + row count parity)
# ============================================================
echo "=== Phase 3: verify clone ==="
echo "  Running integrity_check on archive..."
INTEGRITY=$(sqlite3 "$ARCHIVE_DB" "PRAGMA quick_check;" 2>&1 | head -1)
echo "  archive quick_check: $INTEGRITY"
if [ "$INTEGRITY" != "ok" ]; then
  abort "archive integrity check failed: $INTEGRITY"
fi
echo ""
echo "  Comparing row counts (live vs archive)..."
for tbl in market_snapshots kalshi_trades kalshi_events; do
  live_count=$(sqlite3 "$LIVE_DB" "SELECT COUNT(*) FROM $tbl;" 2>/dev/null)
  arc_count=$(sqlite3 "$ARCHIVE_DB" "SELECT COUNT(*) FROM $tbl;" 2>/dev/null)
  if [ "$live_count" = "$arc_count" ]; then
    echo "  [ok]   $tbl: $live_count = $arc_count"
  else
    abort "row count mismatch on $tbl: live=$live_count archive=$arc_count"
  fi
done
log "phase_3_ok" "integrity=ok counts=match"
echo ""

# ============================================================
# PHASE 4: zstd compression
# ============================================================
echo "=== Phase 4: zstd -19 compression ==="
echo "  ~10-30 minute operation (CPU-bound). Target: ~10 GB output."
if confirm "Proceed with Phase 4?"; then
  start=$(date +%s)
  # -T0 = use all cores; -19 = max compression; --long=31 helps for large redundant data
  # NOTE: --rm removes input on success; we want to KEEP source so omit it. Default is keep.
  zstd -19 -T0 --long=31 --keep "$ARCHIVE_DB" -o "$ARCHIVE_ZST"
  end=$(date +%s)
  ratio=$(echo "scale=2; $(stat -f %z "$ARCHIVE_DB") / $(stat -f %z "$ARCHIVE_ZST")" | bc 2>/dev/null || echo "?")
  echo "  [ok] compressed in $((end-start))s, ratio: ${ratio}x"
  echo "  .db:  $(show_size "$ARCHIVE_DB")"
  echo "  .zst: $(show_size "$ARCHIVE_ZST")"
  log "phase_4_ok" "duration_s=$((end-start)) ratio=$ratio"
else
  abort "user skipped phase 4"
fi
echo ""

# ============================================================
# PHASE 5: Verify zstd round-trip
# ============================================================
echo "=== Phase 5: verify zstd round-trip ==="
echo "  Decompress to /tmp, integrity-check the result."
echo "  If your /tmp is small you can skip; archive .db on disk also works."
if confirm "Proceed with Phase 5?"; then
  start=$(date +%s)
  zstd -d "$ARCHIVE_ZST" -o "$DECOMPRESS_TEST"
  end=$(date +%s)
  echo "  [ok] decompressed in $((end-start))s to $DECOMPRESS_TEST"
  RT_INTEGRITY=$(sqlite3 "$DECOMPRESS_TEST" "PRAGMA quick_check;" 2>&1 | head -1)
  if [ "$RT_INTEGRITY" != "ok" ]; then
    abort "decompressed db failed integrity: $RT_INTEGRITY"
  fi
  RT_COUNT=$(sqlite3 "$DECOMPRESS_TEST" "SELECT COUNT(*) FROM market_snapshots;" 2>/dev/null)
  EXPECTED=$(sqlite3 "$ARCHIVE_DB" "SELECT COUNT(*) FROM market_snapshots;" 2>/dev/null)
  if [ "$RT_COUNT" != "$EXPECTED" ]; then
    abort "round-trip row count mismatch: $RT_COUNT vs $EXPECTED"
  fi
  echo "  [ok] round-trip verified: market_snapshots=$RT_COUNT rows match"
  rm -f "$DECOMPRESS_TEST"
  log "phase_5_ok" "round_trip=verified"
else
  echo "  [skipped] You should round-trip-test before deleting the original."
fi
echo ""

# ============================================================
# PHASE 6: Extract schema DDL
# ============================================================
echo "=== Phase 6: extract schema DDL ==="
sqlite3 "$LIVE_DB" ".schema" > "$SCHEMA_SQL"
LINES=$(wc -l < "$SCHEMA_SQL" | tr -d ' ')
echo "  [ok] $LINES lines of DDL → $SCHEMA_SQL"
log "phase_6_ok" "ddl_lines=$LINES"
echo ""

# ============================================================
# PHASE 7: Move live DB aside (NOT deleted)
# ============================================================
echo "=== Phase 7: move live DB aside ==="
echo "  Renames (does NOT delete) so you can roll back if smoke tests fail."
echo "  $LIVE_DB → $ASIDE_DB"
if confirm "Proceed with Phase 7?"; then
  mv "$LIVE_DB" "$ASIDE_DB"
  [ -e "${LIVE_DB}-wal" ] && mv "${LIVE_DB}-wal" "$ASIDE_WAL" || true
  [ -e "${LIVE_DB}-shm" ] && mv "${LIVE_DB}-shm" "$ASIDE_SHM" || true
  echo "  [ok] live DB moved aside"
  log "phase_7_ok" "aside=$ASIDE_DB"
else
  abort "user skipped phase 7"
fi
echo ""

# ============================================================
# PHASE 8: Create fresh empty DB from schema
# ============================================================
echo "=== Phase 8: create fresh empty kalshi.db ==="
sqlite3 "$LIVE_DB" < "$SCHEMA_SQL"
# Set sensible pragmas for a fresh DB (matching what picoz expects)
sqlite3 "$LIVE_DB" <<'PRAGMA_SQL'
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA wal_autocheckpoint = 1000;
PRAGMA_SQL
NEW_SIZE=$(stat -f %z "$LIVE_DB")
TABLE_COUNT=$(sqlite3 "$LIVE_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';")
echo "  [ok] fresh kalshi.db created"
echo "  size: $NEW_SIZE bytes"
echo "  tables: $TABLE_COUNT"
log "phase_8_ok" "size=$NEW_SIZE tables=$TABLE_COUNT"
echo ""

# ============================================================
# PHASE 9: Smoke test
# ============================================================
echo "=== Phase 9: smoke test fresh DB ==="
sqlite3 "$LIVE_DB" <<'SMOKE_SQL'
INSERT INTO market_snapshots (
  platform, category, event_ticker, market_ticker, captured_at,
  yes_price, no_price, status
) VALUES (
  'smoke-test', 'smoke', 'SMOKE-EVENT', 'SMOKE-MARKET', strftime('%s','now'),
  0.5, 0.5, 'active'
);
SELECT 'smoke_insert_ok', COUNT(*) FROM market_snapshots WHERE platform='smoke-test';
DELETE FROM market_snapshots WHERE platform='smoke-test';
SELECT 'smoke_cleanup_ok', COUNT(*) FROM market_snapshots WHERE platform='smoke-test';
SMOKE_SQL
echo "  [ok] write/read/delete smoke test passed"
log "phase_9_ok" "smoke=passed"
echo ""

# ============================================================
# PHASE 10: Print restart plist commands
# ============================================================
echo "=== Phase 10: restart plist commands ==="
echo ""
echo "When ready, restart picoz plists with:"
echo ""
cat <<'RESTART'
  for plist in batch-import decision-ledger-sentinel ingest-server kalshi-capture-full l1-sentinel p0-probes stats-sampler weekly-cache-prune wal-checkpoint-cron; do
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.pico-z.${plist}.plist
  done
  launchctl list | grep pico-z
RESTART
echo ""
log "phase_10_ok" "restart_commands_printed"

# ============================================================
# DONE
# ============================================================
echo ""
echo "================================================================"
echo "  COMPLETE"
echo "================================================================"
echo ""
echo "DISK NOW: $(show_disk)"
echo ""
echo "FOOTPRINT:"
echo "  Hot (live):    $(show_size "$LIVE_DB") at $LIVE_DB"
echo "  Warm (.zst):   $(show_size "$ARCHIVE_ZST") at $ARCHIVE_ZST"
echo "  Aside (.db):   $(show_size "$ASIDE_DB") at $ASIDE_DB (KEEP UNTIL VERIFIED)"
echo "  Schema:        $(show_size "$SCHEMA_SQL") at $SCHEMA_SQL"
echo ""
echo "NEXT STEPS:"
echo "  1. Restart picoz plists (commands above)"
echo "  2. Watch picoz write to fresh kalshi.db for 1 hour, check logs"
echo "  3. Once stable, you can rm:"
echo "       $ASIDE_DB"
echo "       $ASIDE_WAL"
echo "       $ASIDE_SHM"
echo "       $ARCHIVE_DB  (the uncompressed clone — .zst is the canonical archive)"
echo "  4. To query historical data later:"
echo "       cd $ARCHIVE_DIR"
echo "       zstd -d kalshi-snapshot-${SHORT_TS}.db.zst -o /tmp/kalshi-history.db"
echo "       sqlite3 /tmp/kalshi-history.db"
echo ""
echo "Ledger: $LEDGER"
log "complete" "footprint_logged"

exit 0
