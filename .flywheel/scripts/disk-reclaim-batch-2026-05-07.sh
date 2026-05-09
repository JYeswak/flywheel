#!/usr/bin/env bash
# disk-reclaim-batch-2026-05-07.sh
#
# One-shot disk reclamation script for the 2026-05-07 storage emergency.
# Reclaims ~165+ GB by removing scratch directories and bulk source corpus
# while preserving all indexed/embedded data (qdrant collections, socraticode
# data, picoz live databases).
#
# DESIGN PRINCIPLE: explicit named paths only. No recursive find. No globs
# in rm. Each phase pauses for confirmation.
#
# Run from your shell (DCG blocks rm -rf inside Claude Code):
#   bash ~/Developer/flywheel/.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh
#
# WHAT GETS PRESERVED (NEVER TOUCHED):
#   - ~/.socraticode/qdrant-data/        (~669 MB indexed embeddings)
#   - ~/.knowledge/qdrant_*              (~2.5 GB OpenAI/server storage)
#   - ~/Developer/polymarket-pico-z/data/kalshi.db  (79 GB pico-z data, paused)
#   - ~/Library/Application Support/*    (app state)
#   - ~/.local/state/                    (flywheel state, ledgers, fuckup-log)
#
# WHAT GETS DELETED (ALL DISPOSABLE - either auto-regenerates or is test scratch):
#   Phase 1: jsm test scratch (~140 GB)
#   Phase 2: beads-rust + mobile-eats + alps test scratch (~17 GB)
#   Phase 3: bulk jeff-corpus source repos (~9 GB; indexed data preserved)
#
# All actions logged to ~/.local/state/flywheel/disk-reclaim-2026-05-07.jsonl

set -euo pipefail

LEDGER="$HOME/.local/state/flywheel/disk-reclaim-2026-05-07.jsonl"
mkdir -p "$(dirname "$LEDGER")"

log() {
  local action="$1" path="${2:-}" extra="${3:-}"
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$ts\",\"action\":\"$action\",\"path\":\"$path\",\"extra\":\"$extra\"}" >> "$LEDGER"
}

show_disk() {
  df -h / | tail -1
}

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) echo "skipped"; return 1 ;;
  esac
}

remove_explicit() {
  local path="$1"
  if [ ! -e "$path" ]; then
    echo "  [skip] missing: $path"
    return 0
  fi
  local size_before
  size_before=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
  if rm -rf "$path"; then
    echo "  [ok]   removed: $path  (${size_before}KB)"
    log "removed" "$path" "size_kb=$size_before"
  else
    echo "  [FAIL] $path"
    log "failed" "$path"
  fi
}

echo "================================================================"
echo "  disk-reclaim-batch-2026-05-07.sh"
echo "  Target: reclaim 165+ GB from /private/tmp + jeff-corpus source"
echo "================================================================"
echo ""
echo "BEFORE:"
show_disk
echo ""
log "start" "" "starting reclaim batch"

# ============================================================
# PHASE 1: jsm test scratch sandboxes (~140 GB)
# Confirmed by lsof: zero open handles. Confirmed by mtime: 1-3 days old.
# ============================================================
echo ""
echo "=== Phase 1: jsm test scratch (~140 GB) ==="
echo "Removes 13 jsm-auth-isolation.* + jsm-health-sandbox.* dirs"
if confirm "Proceed with Phase 1?"; then
  remove_explicit /private/tmp/jsm-auth-isolation.ZQM9pq
  remove_explicit /private/tmp/jsm-auth-isolation.G1oVHv
  remove_explicit /private/tmp/jsm-health-sandbox.QzcyWE
  remove_explicit /private/tmp/jsm-health-sandbox.oqso3K
  remove_explicit /private/tmp/jsm-health-sandbox.Gjx1J3
  remove_explicit /private/tmp/jsm-health-sandbox.Ft29hm
  remove_explicit /private/tmp/jsm-health-sandbox.BUSm5h
  remove_explicit /private/tmp/jsm-health-sandbox.9pbbfU
  remove_explicit /private/tmp/jsm-health-sandbox.m4C85z
  remove_explicit /private/tmp/jsm-health-sandbox.eVsgrC
  remove_explicit /private/tmp/jsm-health-sandbox.C7W3Og
  remove_explicit /private/tmp/jsm-health-sandbox.rJ26vj
  remove_explicit /private/tmp/jsm-health-sandbox.VgUC38
  echo ""
  echo "AFTER PHASE 1:"
  show_disk
fi

# ============================================================
# PHASE 2: beads-rust + mobile-eats + alps scratch (~17 GB)
# ============================================================
echo ""
echo "=== Phase 2: beads/mobile-eats/alps scratch (~17 GB) ==="
if confirm "Proceed with Phase 2?"; then
  remove_explicit /private/tmp/beads-rust-2k0fd
  remove_explicit /private/tmp/beads-rust-1l4fw
  remove_explicit /private/tmp/beads_rust-f505-build
  remove_explicit /private/tmp/mobile-eats-next-dev-cache-20260506151112-953
  remove_explicit /private/tmp/mobile-eats-next-failed-density-20260506122512
  remove_explicit /private/tmp/alps-demo-smoke-fix-pass
  remove_explicit /private/tmp/alpsinsurance-demo-dryrun-smoke-v2
  echo ""
  echo "AFTER PHASE 2:"
  show_disk
fi

# ============================================================
# PHASE 3: jeff-corpus bulk source removal (~9 GB)
# Joshua: "we don't want to delete jeff-corpus - we want the indexed stuff
#  to stay but the bulk of the repos - as long as our indexed data doesn't
#  leave - can go"
#
# Indexed data (PRESERVED — never touched):
#   ~/.socraticode/qdrant-data         (669 MB) socraticode collections
#   ~/.knowledge/qdrant_server_storage  (1.7 GB) jeff-stack collections
#   ~/.knowledge/qdrant_storage_openai  (703 MB) openai-embedded collections
#
# Bulk source (REMOVED — repos can be re-cloned anytime; indices already mined):
#   ~/Developer/jeff-corpus/<180 repos>  (~9 GB)
#
# Strategy: remove the directory itself. If you want to re-clone any specific
# repo, the indexed embeddings still answer questions about it — you only
# need to re-clone if you want to *modify* it.
# ============================================================
echo ""
echo "=== Phase 3: jeff-corpus bulk source removal (~9 GB) ==="
echo "PRESERVES: ~/.socraticode/qdrant-data + ~/.knowledge/qdrant_*"
echo "REMOVES: ~/Developer/jeff-corpus/ (180 repos source code)"
echo ""
echo "Verifying indexed data is intact BEFORE deletion..."
if [ -d "$HOME/.socraticode/qdrant-data" ] && [ -d "$HOME/.knowledge/qdrant_server_storage" ]; then
  echo "  [ok] indexed data confirmed present"
  du -sh "$HOME/.socraticode/qdrant-data" "$HOME/.knowledge/qdrant_server_storage" "$HOME/.knowledge/qdrant_storage_openai" 2>/dev/null
else
  echo "  [ABORT] indexed data missing — refusing to delete source corpus"
  echo "          fix indexed data first, then re-run Phase 3"
  exit 1
fi
echo ""
if confirm "Proceed with Phase 3 (jeff-corpus source removal)?"; then
  remove_explicit "$HOME/Developer/jeff-corpus"
  echo ""
  echo "AFTER PHASE 3:"
  show_disk
fi

# ============================================================
# DONE
# ============================================================
echo ""
echo "================================================================"
echo "  COMPLETE"
echo "================================================================"
echo ""
echo "FINAL:"
show_disk
echo ""
echo "Ledger: $LEDGER"
log "complete" "" "batch complete"

exit 0
