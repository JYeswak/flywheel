#!/usr/bin/env bash
# file-triage-review.sh — Interactive review loop for file-triage-scan output.
#
# Reads a scan JSONL, walks Joshua through top-N items, prompts y/n/z/a/d/q
# per item. Resumable (state in ~/.local/state/flywheel/file-triage/review-state.json).
#
# Joshua-direct primitive (2026-05-20).
#
# Usage:
#   file-triage-review.sh [--scan PATH] [--top N] [--auto-yes ACTION] [--reset]
#                         [--include-classes c1,c2,...]

set -euo pipefail

STATE_DIR="${HOME}/.local/state/flywheel/file-triage"
mkdir -p "$STATE_DIR"
KEEP_LIST="${STATE_DIR}/keep-list.txt"
DEL_LIST="${STATE_DIR}/auto-delete-list.txt"
REVIEW_STATE="${STATE_DIR}/review-state.json"
COLD_BASE="${HOME}/Cold"

SCAN=""
TOP_N=200
AUTO_YES=""           # if set, non-interactive: every prompt → this answer (for tests)
INCLUDE_CLASSES="REVIEW,ARCHIVE-CANDIDATE,LIKELY-TRASH"
RESET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scan)            SCAN="$2"; shift 2 ;;
    --top)             TOP_N="$2"; shift 2 ;;
    --auto-yes)        AUTO_YES="$2"; shift 2 ;;
    --include-classes) INCLUDE_CLASSES="$2"; shift 2 ;;
    --reset)           RESET=1; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

# Pick latest scan if not given
if [[ -z "$SCAN" ]]; then
  SCAN=$(ls -t "$STATE_DIR"/scan-*.jsonl 2>/dev/null | head -n 1 || true)
  if [[ -z "$SCAN" ]]; then
    echo "no scan files found in $STATE_DIR; run file-triage-scan.sh first" >&2
    exit 2
  fi
fi
[[ -f "$SCAN" ]] || { echo "scan not found: $SCAN" >&2; exit 2; }

if [[ "$RESET" == "1" ]]; then rm -f "$REVIEW_STATE"; fi

# Load resume cursor
CURSOR=0
LAST_SCAN=""
if [[ -f "$REVIEW_STATE" ]]; then
  LAST_SCAN=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("scan",""))' "$REVIEW_STATE" 2>/dev/null || echo "")
  if [[ "$LAST_SCAN" == "$SCAN" ]]; then
    CURSOR=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("cursor",0))' "$REVIEW_STATE" 2>/dev/null || echo 0)
  fi
fi

# Available disk (KB) — for running freed-total
disk_avail_kb() { df -k "$HOME" | awk 'NR==2 {print $4}'; }

START_AVAIL=$(disk_avail_kb)

# Filter rows: drop header + classes not requested
TMP_ROWS="$(mktemp -t file-triage-rows.XXXXXX)"
trap 'rm -f "$TMP_ROWS"' EXIT

python3 - "$SCAN" "$INCLUDE_CLASSES" "$TOP_N" > "$TMP_ROWS" <<'PY'
import json,sys
scan,classes,topn=sys.argv[1],sys.argv[2].split(","),int(sys.argv[3])
out=[]
with open(scan) as f:
    for line in f:
        line=line.strip()
        if not line: continue
        try: r=json.loads(line)
        except: continue
        if r.get("_header"): continue
        if r.get("classification") not in classes: continue
        out.append(r)
        if len(out)>=topn: break
for r in out: print(json.dumps(r))
PY

TOTAL_ROWS=$(wc -l < "$TMP_ROWS" | tr -d ' ')
if (( TOTAL_ROWS == 0 )); then
  echo "no rows to review in $SCAN (classes=$INCLUDE_CLASSES)"
  exit 0
fi

# Counters
n_delete=0; n_keep=0; n_zip=0; n_skip=0; n_addkeep=0; n_adddel=0

save_state() {
  python3 - "$REVIEW_STATE" "$SCAN" "$1" "$n_delete" "$n_keep" "$n_zip" "$n_skip" <<'PY'
import json,sys
path,scan,cur,d,k,z,s=sys.argv[1:]
open(path,"w").write(json.dumps({
  "scan":scan,"cursor":int(cur),
  "n_delete":int(d),"n_keep":int(k),"n_zip":int(z),"n_skip":int(s),
}))
PY
}

idx=0
while IFS= read -r row; do
  idx=$((idx+1))
  if (( idx <= CURSOR )); then continue; fi

  # One python call: dump tab-separated fields for shell consumption.
  fields=$(python3 - "$row" <<'PY'
import json,sys
r=json.loads(sys.argv[1])
s=r["scores"]
scores=f'size={s["size"]} age={s["age"]} red={s["redundancy"]} ref={s["reference"]} content={s["content_value"]} -> total={s["total"]}/50'
print("\t".join([
  r["path"], str(r["size_bytes"]), r["size_human"],
  str(r["atime_age_days"]), r["classification"],
  scores, r["rationale"], r["suggested_action"],
]))
PY
)
  IFS=$'\t' read -r path size size_h atime_d cls scores rationale suggested <<< "$fields"

  # Skip if not present anymore
  if [[ ! -e "$path" ]]; then
    n_skip=$((n_skip+1)); save_state "$idx"; continue
  fi

  echo "────────────────────────────────────────"
  printf "[%d/%d]  %s\n" "$idx" "$TOTAL_ROWS" "$path"
  printf "Size: %s · Untouched: %d days · Classification: %s\n" "$size_h" "$atime_d" "$cls"
  printf "Scores: %s\n" "$scores"
  printf "Rationale: %s\n" "$rationale"
  printf "Suggested: %s\n" "$suggested"
  echo ""
  echo "[y] delete now   [n] keep (skip)   [z] zip+cold-store"
  echo "[a] always-keep prefix   [d] delete-prefix always   [q] quit"

  if [[ -n "$AUTO_YES" ]]; then
    choice="$AUTO_YES"
    echo "Choice (auto): $choice"
  else
    read -r -p "Choice [y/n/z/a/d/q]: " choice </dev/tty || choice="q"
  fi

  case "$choice" in
    y|Y)
      # Big-delete safety
      if (( size >= 10737418240 )); then
        if [[ -n "$AUTO_YES" ]]; then
          confirm="DELETE"
        else
          read -r -p "Item >10GB. Type DELETE to confirm: " confirm </dev/tty || confirm=""
        fi
        if [[ "$confirm" != "DELETE" ]]; then
          echo "  cancelled (no DELETE confirmation)"; n_skip=$((n_skip+1)); save_state "$idx"; continue
        fi
      fi
      if [[ -f "$path" ]]; then
        rm -- "$path" && echo "  deleted $path" || { echo "  rm failed: $path" >&2; n_skip=$((n_skip+1)); save_state "$idx"; continue; }
      else
        rm -rf -- "$path" && echo "  deleted dir $path" || { echo "  rm failed: $path" >&2; n_skip=$((n_skip+1)); save_state "$idx"; continue; }
      fi
      n_delete=$((n_delete+1))
      ;;
    z|Z)
      year=$(date +%Y)
      cold_dir="${COLD_BASE}/${year}"
      mkdir -p "$cold_dir"
      base=$(basename "$path")
      dir=$(dirname "$path")
      zip_path="${cold_dir}/${base}.zip"
      if ( cd "$dir" && zip -qr "$zip_path" "$base" ); then
        if [[ -s "$zip_path" ]]; then
          rm -rf -- "$path" && echo "  zipped → $zip_path; original removed"
          n_zip=$((n_zip+1))
        else
          echo "  zip empty; refusing to delete original: $path" >&2
          n_skip=$((n_skip+1))
        fi
      else
        echo "  zip failed; original kept: $path" >&2
        n_skip=$((n_skip+1))
      fi
      ;;
    a|A)
      echo "$path" >> "$KEEP_LIST"; n_addkeep=$((n_addkeep+1)); n_keep=$((n_keep+1))
      echo "  → keep-list: $path"
      ;;
    d|D)
      echo "$path" >> "$DEL_LIST"; n_adddel=$((n_adddel+1))
      if [[ -f "$path" ]]; then rm -- "$path"; else rm -rf -- "$path"; fi
      n_delete=$((n_delete+1))
      echo "  → auto-delete-list + removed: $path"
      ;;
    q|Q)
      echo "quit (resume on next run from item $idx)"
      save_state "$((idx-1))"; break
      ;;
    *)
      n_keep=$((n_keep+1))
      echo "  skipped"
      ;;
  esac

  now_avail=$(disk_avail_kb)
  freed_mb=$(( (now_avail - START_AVAIL) / 1024 ))
  echo "  running freed: ${freed_mb} MB"
  save_state "$idx"
done < "$TMP_ROWS"

echo ""
echo "────── Review Summary ──────"
echo "  Reviewed (this run): $idx of $TOTAL_ROWS"
echo "  Deleted:  $n_delete"
echo "  Zipped:   $n_zip"
echo "  Kept:     $n_keep"
echo "  Skipped:  $n_skip"
echo "  Added to keep-list:        $n_addkeep   ($KEEP_LIST)"
echo "  Added to auto-delete-list: $n_adddel   ($DEL_LIST)"
final_avail=$(disk_avail_kb)
total_freed_mb=$(( (final_avail - START_AVAIL) / 1024 ))
echo "  Total freed: ${total_freed_mb} MB"
