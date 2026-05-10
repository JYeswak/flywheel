#!/usr/bin/env bash
# .flywheel/audit/flywheel-0avrn/apply.sh
# Tier A umbrella apply per Joshua signoff 2026-05-10.
# Spec: .flywheel/audit/flywheel-9hnp3/storage-apply-spec.md
# Bead: flywheel-0avrn

set -euo pipefail

RECEIPT_DIR="/Users/josh/Developer/flywheel/.flywheel/receipts/flywheel-0avrn/audit"
LOG="$RECEIPT_DIR/apply.log"
RECEIPT="$RECEIPT_DIR/storage-apply-receipt.json"
ARCHIVE_DIR="/Users/josh/Developer/comfyui-archives"
ARCHIVE_DATE="$(date -u +%Y%m%d)"
ARCHIVE_PATH="$ARCHIVE_DIR/output-archive-$ARCHIVE_DATE.tar.zst"
mkdir -p "$RECEIPT_DIR" "$ARCHIVE_DIR"
exec > >(tee -a "$LOG") 2>&1

iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
section() { echo; echo "===== $1 (ts=$(iso)) ====="; }

# ---------- pre-state ----------
section "PRE-STATE"
PRE_DISK_FREE_GB="$(df -g ~/Developer | awk 'NR==2{print $4}')"
PRE_DISK_PCT_USED="$(df -h ~/Developer | awk 'NR==2{print $5}' | tr -d %)"
PRE_DISK_PCT_FREE=$((100 - PRE_DISK_PCT_USED))
echo "disk_free_gb=$PRE_DISK_FREE_GB"
echo "disk_free_pct=$PRE_DISK_PCT_FREE"

declare -A PRE_BYTES PRE_FILES
for path in \
  /Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints \
  /Users/josh/Developer/vibe_cockpit/target \
  /Users/josh/Developer/zesttube-avatars/third_party \
  /Users/josh/Developer/comfyui/output
do
  if [[ -e "$path" ]]; then
    PRE_BYTES[$path]="$(du -sk "$path" 2>/dev/null | awk '{print $1*1024}')"
    PRE_FILES[$path]="$(find "$path" -type f 2>/dev/null | wc -l | tr -d ' ')"
  else
    PRE_BYTES[$path]=0
    PRE_FILES[$path]=0
  fi
  echo "  pre $path: bytes=${PRE_BYTES[$path]} files=${PRE_FILES[$path]}"
done

# ---------- ITEM 1: zesttube langgraph-checkpoints (61G regenerable) ----------
section "ITEM 1: zesttube langgraph-checkpoints"
P1=/Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints
if [[ -d "$P1" ]]; then
  echo "Removing $P1 ..."
  rm -rf "$P1"
  echo "Removed."
else
  echo "Path absent — skipping."
fi
[[ ! -e "$P1" ]] || { echo "ITEM1 FAIL: path still exists"; exit 1; }

# ---------- ITEM 2: vibe_cockpit cargo clean (16G regenerable) ----------
section "ITEM 2: vibe_cockpit cargo clean"
P2=/Users/josh/Developer/vibe_cockpit
if [[ -d "$P2/target" ]]; then
  if command -v cargo >/dev/null; then
    (cd "$P2" && cargo clean)
    echo "cargo clean done."
  else
    echo "cargo not on PATH — falling back to rm of target/"
    rm -rf "$P2/target"
  fi
else
  echo "target/ absent — skipping."
fi
[[ ! -d "$P2/target" ]] || {
  remaining="$(du -sk "$P2/target" 2>/dev/null | awk '{print $1}')"
  if [[ "${remaining:-0}" -lt 1000 ]]; then
    echo "target/ exists but tiny ($remaining KB), acceptable"
  else
    echo "ITEM2 FAIL: target/ still has $remaining KB"
    exit 1
  fi
}

# ---------- ITEM 3: zesttube-avatars third_party (5.6G re-downloadable) ----------
section "ITEM 3: zesttube-avatars third_party"
P3=/Users/josh/Developer/zesttube-avatars/third_party
if [[ -d "$P3" ]]; then
  echo "Removing $P3 ..."
  rm -rf "$P3"
  echo "Removed."
else
  echo "Path absent — skipping."
fi
[[ ! -e "$P3" ]] || { echo "ITEM3 FAIL: path still exists"; exit 1; }

# ---------- ITEM 4: comfyui output age-based archive (31G; 100% >30d) ----------
section "ITEM 4: comfyui output archive-then-prune"
P4=/Users/josh/Developer/comfyui/output
FILELIST="$RECEIPT_DIR/item4-archive-filelist.txt"
if [[ -d "$P4" ]]; then
  echo "Building >30d filelist for $P4 ..."
  ( cd /Users/josh/Developer/comfyui && find output -type f -mtime +30 ) > "$FILELIST"
  ARCHIVE_COUNT="$(wc -l < "$FILELIST" | tr -d ' ')"
  echo "filelist=$FILELIST count=$ARCHIVE_COUNT"
  if [[ "$ARCHIVE_COUNT" -eq 0 ]]; then
    echo "Nothing to archive (all files <=30d)."
  else
    echo "Building archive at $ARCHIVE_PATH ..."
    # tar from filelist, pipe to zstd. -T- reads from stdin.
    ( cd /Users/josh/Developer/comfyui && tar -cf - -T "$FILELIST" ) | zstd -T0 -3 -o "$ARCHIVE_PATH"
    [[ -s "$ARCHIVE_PATH" ]] || { echo "ITEM4 FAIL: archive empty/missing"; exit 1; }
    ARCHIVE_BYTES="$(stat -f %z "$ARCHIVE_PATH")"
    echo "archive_bytes=$ARCHIVE_BYTES"
    echo "Verifying archive (zstd --test) ..."
    zstd --test "$ARCHIVE_PATH"
    echo "Verify also: tar listing readable"
    zstd -dc "$ARCHIVE_PATH" | tar -tf - | head -3
    LISTED_COUNT="$(zstd -dc "$ARCHIVE_PATH" | tar -tf - | wc -l | tr -d ' ')"
    echo "listed_count=$LISTED_COUNT (expected=$ARCHIVE_COUNT)"
    [[ "$LISTED_COUNT" -ge "$ARCHIVE_COUNT" ]] || { echo "ITEM4 FAIL: archived count mismatch"; exit 1; }
    echo "Removing archived source files only ..."
    ( cd /Users/josh/Developer/comfyui && xargs -I{} rm "{}" < "$FILELIST" )
    # Remove emptied directories under output/
    find "$P4" -depth -type d -empty -delete 2>/dev/null || true
    POST_OUTPUT_FILES="$(find "$P4" -type f 2>/dev/null | wc -l | tr -d ' ')"
    echo "post_output_files=$POST_OUTPUT_FILES"
  fi
else
  echo "Path absent — skipping."
fi

# ---------- post-state ----------
section "POST-STATE"
POST_DISK_FREE_GB="$(df -g ~/Developer | awk 'NR==2{print $4}')"
POST_DISK_PCT_USED="$(df -h ~/Developer | awk 'NR==2{print $5}' | tr -d %)"
POST_DISK_PCT_FREE=$((100 - POST_DISK_PCT_USED))
echo "disk_free_gb=$POST_DISK_FREE_GB"
echo "disk_free_pct=$POST_DISK_PCT_FREE"

declare -A POST_BYTES POST_FILES
for path in \
  /Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints \
  /Users/josh/Developer/vibe_cockpit/target \
  /Users/josh/Developer/zesttube-avatars/third_party \
  /Users/josh/Developer/comfyui/output
do
  if [[ -e "$path" ]]; then
    POST_BYTES[$path]="$(du -sk "$path" 2>/dev/null | awk '{print $1*1024}')"
    POST_FILES[$path]="$(find "$path" -type f 2>/dev/null | wc -l | tr -d ' ')"
  else
    POST_BYTES[$path]=0
    POST_FILES[$path]=0
  fi
  echo "  post $path: bytes=${POST_BYTES[$path]} files=${POST_FILES[$path]}"
done

# Reclaim total
TOTAL_PRE=0; TOTAL_POST=0
for k in "${!PRE_BYTES[@]}"; do TOTAL_PRE=$((TOTAL_PRE + PRE_BYTES[$k])); done
for k in "${!POST_BYTES[@]}"; do TOTAL_POST=$((TOTAL_POST + POST_BYTES[$k])); done
RECLAIM_BYTES=$((TOTAL_PRE - TOTAL_POST))
RECLAIM_GB=$((RECLAIM_BYTES / 1024 / 1024 / 1024))
ARCHIVE_BYTES_FINAL=0
[[ -f "$ARCHIVE_PATH" ]] && ARCHIVE_BYTES_FINAL="$(stat -f %z "$ARCHIVE_PATH")"

# ---------- receipt ----------
section "RECEIPT"
cat > "$RECEIPT" <<JSON
{
  "schema_version": "flywheel.storage-apply-receipt.v1",
  "bead_id": "flywheel-0avrn",
  "task_id": "flywheel-0avrn-b6f3ce",
  "spec_path": ".flywheel/audit/flywheel-9hnp3/storage-apply-spec.md",
  "ts_completed": "$(iso)",
  "pre": {
    "disk_free_gb": $PRE_DISK_FREE_GB,
    "disk_free_pct": $PRE_DISK_PCT_FREE,
    "items": {
      "zesttube_langgraph_checkpoints": {"bytes": ${PRE_BYTES[/Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints]}, "files": ${PRE_FILES[/Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints]}},
      "vibe_cockpit_target": {"bytes": ${PRE_BYTES[/Users/josh/Developer/vibe_cockpit/target]}, "files": ${PRE_FILES[/Users/josh/Developer/vibe_cockpit/target]}},
      "zesttube_avatars_third_party": {"bytes": ${PRE_BYTES[/Users/josh/Developer/zesttube-avatars/third_party]}, "files": ${PRE_FILES[/Users/josh/Developer/zesttube-avatars/third_party]}},
      "comfyui_output": {"bytes": ${PRE_BYTES[/Users/josh/Developer/comfyui/output]}, "files": ${PRE_FILES[/Users/josh/Developer/comfyui/output]}}
    }
  },
  "post": {
    "disk_free_gb": $POST_DISK_FREE_GB,
    "disk_free_pct": $POST_DISK_PCT_FREE,
    "items": {
      "zesttube_langgraph_checkpoints": {"bytes": ${POST_BYTES[/Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints]}, "files": ${POST_FILES[/Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints]}},
      "vibe_cockpit_target": {"bytes": ${POST_BYTES[/Users/josh/Developer/vibe_cockpit/target]}, "files": ${POST_FILES[/Users/josh/Developer/vibe_cockpit/target]}},
      "zesttube_avatars_third_party": {"bytes": ${POST_BYTES[/Users/josh/Developer/zesttube-avatars/third_party]}, "files": ${POST_FILES[/Users/josh/Developer/zesttube-avatars/third_party]}},
      "comfyui_output": {"bytes": ${POST_BYTES[/Users/josh/Developer/comfyui/output]}, "files": ${POST_FILES[/Users/josh/Developer/comfyui/output]}}
    }
  },
  "archive": {
    "path": "$ARCHIVE_PATH",
    "bytes": $ARCHIVE_BYTES_FINAL,
    "zstd_test_passed": true,
    "filelist_path": "$FILELIST"
  },
  "reclaim_bytes": $RECLAIM_BYTES,
  "reclaim_gb": $RECLAIM_GB,
  "fire_tier_exit": $([ $POST_DISK_PCT_FREE -ge 5 ] && echo true || echo false),
  "ok_tier_reached": $([ $POST_DISK_PCT_FREE -ge 15 ] && echo true || echo false)
}
JSON
echo "Receipt: $RECEIPT"
cat "$RECEIPT"
