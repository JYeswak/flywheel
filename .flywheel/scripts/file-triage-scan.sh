#!/usr/bin/env bash
# file-triage-scan.sh — System-wide file scoring + JSONL inventory.
#
# Walks specified roots, scores each item >min-size against a 5-axis rubric
# (size, age, redundancy, reference, content_value), classifies into
# KEEP-VITAL / KEEP-LIKELY / REVIEW / ARCHIVE-CANDIDATE / LIKELY-TRASH,
# and emits a ranked JSONL stream Joshua can review with file-triage-review.sh.
#
# Joshua-direct primitive (2026-05-20): system-wide content triage that
# complements the cleanable-substrate cron janitors. Read-only. No mutations.
#
# Usage:
#   file-triage-scan.sh [--root PATH ...] [--exclude PATTERN ...]
#                       [--max-depth N] [--top N] [--min-size BYTES]
#                       [--out PATH]

set -euo pipefail

# ---------- Defaults ----------
ROOTS=()
EXCLUDES=(target node_modules .next .git .venv __pycache__ .pytest_cache dist build .cargo .rustup)
MAX_DEPTH=5
TOP_N=200
MIN_SIZE=$((10 * 1024 * 1024))  # 10MB
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DEFAULT="${HOME}/.local/state/flywheel/file-triage/scan-${TS}.jsonl"
OUT="${OUT_DEFAULT}"

# ---------- Arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)        ROOTS+=("$2"); shift 2 ;;
    --exclude)     EXCLUDES+=("$2"); shift 2 ;;
    --max-depth)   MAX_DEPTH="$2"; shift 2 ;;
    --top)         TOP_N="$2"; shift 2 ;;
    --min-size)    MIN_SIZE="$2"; shift 2 ;;
    --out)         OUT="$2"; shift 2 ;;
    --json)        shift ;;  # always JSONL; flag accepted for spec parity
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ ${#ROOTS[@]} -eq 0 ]]; then ROOTS=("${HOME}"); fi

mkdir -p "$(dirname "$OUT")"

NOW_EPOCH=$(date +%s)

# ---------- Helpers ----------

human_size() {
  local b="$1"
  if   (( b >= 1073741824 )); then awk -v b="$b" 'BEGIN{printf "%.1fGB", b/1073741824}'
  elif (( b >= 1048576 ));    then awk -v b="$b" 'BEGIN{printf "%.1fMB", b/1048576}'
  elif (( b >= 1024 ));       then awk -v b="$b" 'BEGIN{printf "%.1fKB", b/1024}'
  else echo "${b}B"
  fi
}

# JSON-escape a string for safe embedding in JSONL.
json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n")))'
}

# Score: size (0-10) based on log10(bytes). 1MB=2, 100MB=4, 1GB=5, 10GB=8, 100GB=10
size_score() {
  local b="$1"
  awk -v b="$b" 'BEGIN{
    if (b<=0) { print 0; exit }
    s = log(b)/log(10);
    # tuned so 1GB(=9.03)->5, 10GB(=10.0)->8, 100GB(=11.0)->10
    if (s <= 6) v = 1;
    else if (s <= 9) v = 1 + (s-6) * (5-1)/3.0;        # 6..9 -> 1..5
    else if (s <= 10) v = 5 + (s-9) * (8-5)/1.0;       # 9..10 -> 5..8
    else if (s <= 11) v = 8 + (s-10) * (10-8)/1.0;     # 10..11 -> 8..10
    else v = 10;
    if (v < 0) v = 0; if (v > 10) v = 10;
    printf "%d", (v + 0.5);
  }'
}

age_score() {
  # atime_days
  local a="$1"
  if   (( a < 30 ));  then echo 0
  elif (( a < 90 ));  then echo 4
  elif (( a < 365 )); then echo 7
  else echo 10
  fi
}

# ---------- Path classifiers ----------

is_vital_path() {
  # Always KEEP-VITAL regardless of score.
  local p="$1"
  case "$p" in
    "$HOME"/.ssh/*|"$HOME"/.ssh) return 0 ;;
    "$HOME"/.gnupg/*|"$HOME"/.gnupg) return 0 ;;
    "$HOME"/.config/*|"$HOME"/.config) return 0 ;;
    "$HOME"/Library/Keychains/*|"$HOME"/Library/Keychains) return 0 ;;
    "$HOME"/Library/Application\ Support/iCloud*) return 0 ;;
    "$HOME"/.aws/*|"$HOME"/.aws) return 0 ;;
    "$HOME"/.infisical/*) return 0 ;;
    "$HOME"/.password-store/*) return 0 ;;
  esac
  return 1
}

force_review_path() {
  # Matches segment-anywhere so test fixtures under tmpdirs still trip the rule.
  local p="$1"
  case "$p" in
    */.Trash/*|*/Trash/*) return 0 ;;
    /private/tmp/*|/tmp/*) return 0 ;;
    */Desktop/*) return 0 ;;
  esac
  return 1
}

# ---------- Per-file scoring ----------

score_one() {
  local path="$1"
  local size="$2"
  local atime_epoch="$3"
  local mtime_epoch="$4"
  local is_dir="$5"

  local atime_days=$(( (NOW_EPOCH - atime_epoch) / 86400 ))
  local mtime_days=$(( (NOW_EPOCH - mtime_epoch) / 86400 ))
  (( atime_days < 0 )) && atime_days=0
  (( mtime_days < 0 )) && mtime_days=0

  local s_size; s_size=$(size_score "$size")
  local s_age;  s_age=$(age_score "$atime_days")

  # redundancy
  local s_red=0
  local base; base=$(basename "$path")
  case "$path" in
    *"/target/"*|*"/node_modules/"*|*"/.next/"*|*"/dist/"*|*"/build/"*) s_red=$((s_red+5)) ;;
  esac
  case "$path" in
    "$HOME"/Library/Caches/*) s_red=$((s_red+5)) ;;
  esac
  case "$base" in
    *.cache|*.tmp|*.swp|*.log) s_red=$((s_red+3)) ;;
  esac
  # In a git repo with a clean origin? (cheap test — only if file is in a repo)
  local repo
  if repo=$(git -C "$(dirname "$path")" rev-parse --show-toplevel 2>/dev/null); then
    if git -C "$repo" remote get-url origin >/dev/null 2>&1; then
      # clean = no uncommitted changes in the *file itself*; cheap proxy: clean repo
      if [[ -z $(git -C "$repo" status --porcelain -- "$path" 2>/dev/null) ]]; then
        s_red=$((s_red+3))
      fi
    fi
  fi
  (( s_red > 10 )) && s_red=10

  # reference (lower-bound at 0; can subtract for "named like keepsake")
  local s_ref=0
  case "$base" in
    *-final*|*-master*|*-archive*|*-backup*|*_final*|*_master*) s_ref=$((s_ref-2)) ;;
    *-tmp*|*-test*|*-scratch*|*_tmp*|*_scratch*) s_ref=$((s_ref+3)) ;;
  esac
  # Cheap "referenced from .md/.txt/.json in last 90d" probe is too slow at scale;
  # restrict to files in $HOME/Developer/* where ripgrep-on-prefix is fast.
  if [[ "$path" == "$HOME"/Developer/* ]] && command -v rg >/dev/null 2>&1; then
    local devroot
    devroot="$HOME/Developer/$(echo "${path#$HOME/Developer/}" | cut -d/ -f1)"
    if [[ -d "$devroot" ]]; then
      if rg --max-count=1 -l --no-messages -g '*.md' -g '*.json' -g '*.txt' \
            -F "$base" "$devroot" 2>/dev/null | head -n 1 | grep -q .; then
        s_ref=$((s_ref-3))
      fi
    fi
  fi
  # Clamp 0..10
  (( s_ref < 0 )) && s_ref=0
  (( s_ref > 10 )) && s_ref=10

  # content_value
  local s_cv=0
  case "$base" in
    *.py|*.ts|*.tsx|*.js|*.rs|*.go|*.sh|*.md)
      # source in active repo lowers triage priority
      if [[ -n "${repo:-}" ]]; then s_cv=$((s_cv-5)); fi ;;
    *.mp4|*.mov|*.wav|*.mp3|*.png|*.jpg|*.jpeg)
      if [[ "$path" != *"/assets/"* && "$path" != *"/public/"* && "$path" != *"/static/"* ]]; then
        s_cv=$((s_cv+3))
      fi ;;
    *.db|*.sqlite|*.duckdb)
      if [[ "$path" != "$HOME"/Library/* ]]; then
        s_cv=$((s_cv+4))
      fi ;;
  esac
  # Files in archive dirs nudge toward ARCHIVE-CANDIDATE
  case "$path" in
    *.archived*|*/archive/*|*/archives/*|*.archive*) s_cv=$((s_cv+3)) ;;
  esac
  (( s_cv < 0 )) && s_cv=0
  (( s_cv > 10 )) && s_cv=10

  local total=$(( s_size + s_age + s_red + s_ref + s_cv ))
  (( total > 50 )) && total=50

  # Classification
  local cls
  if   (( total <= 15 )); then cls="KEEP-VITAL"
  elif (( total <= 25 )); then cls="KEEP-LIKELY"
  elif (( total <= 35 )); then cls="REVIEW"
  elif (( total <= 45 )); then cls="ARCHIVE-CANDIDATE"
  else cls="LIKELY-TRASH"
  fi

  # Overrides
  if is_vital_path "$path"; then cls="KEEP-VITAL"; fi
  if force_review_path "$path"; then
    case "$cls" in
      KEEP-VITAL|KEEP-LIKELY) cls="REVIEW" ;;
    esac
  fi
  if (( size >= 1073741824 )); then
    case "$cls" in
      KEEP-VITAL|KEEP-LIKELY) cls="REVIEW" ;;
    esac
  fi

  # Rationale
  local rationale="size=${s_size} age=${s_age}(${atime_days}d) red=${s_red} ref=${s_ref} content=${s_cv}"

  # Suggested action
  local action
  case "$cls" in
    KEEP-VITAL)        action="keep" ;;
    KEEP-LIKELY)       action="keep" ;;
    REVIEW)            action="needs-human-review" ;;
    ARCHIVE-CANDIDATE) action="zip-and-move-to-cold-storage" ;;
    LIKELY-TRASH)      action="delete" ;;
  esac

  local rollback
  case "$action" in
    delete) rollback="Restore from Time Machine; or undo in ~/.Trash if Finder-deleted" ;;
    zip-and-move-to-cold-storage) rollback="Unzip ~/Cold/<year>/${base}.zip back to original dir" ;;
    *) rollback="n/a" ;;
  esac

  local type
  if [[ "$is_dir" == "1" ]]; then type="dir"; else type="file"; fi

  # Emit JSONL row via python for safe escaping
  python3 - "$path" "$type" "$size" "$(human_size "$size")" \
                   "$atime_days" "$mtime_days" \
                   "$s_size" "$s_age" "$s_red" "$s_ref" "$s_cv" "$total" \
                   "$cls" "$rationale" "$action" "$rollback" <<'PY'
import json,sys
keys=["path","type","size_bytes","size_human","atime_age_days","mtime_age_days",
      "s_size","s_age","s_red","s_ref","s_cv","total","classification",
      "rationale","suggested_action","rollback_hint"]
v=sys.argv[1:]
row={
 "path":v[0],"type":v[1],"size_bytes":int(v[2]),"size_human":v[3],
 "atime_age_days":int(v[4]),"mtime_age_days":int(v[5]),
 "scores":{"size":int(v[6]),"age":int(v[7]),"redundancy":int(v[8]),
           "reference":int(v[9]),"content_value":int(v[10]),"total":int(v[11])},
 "classification":v[12],"rationale":v[13],
 "suggested_action":v[14],"rollback_hint":v[15],
}
print(json.dumps(row))
PY
}

# ---------- Walk ----------

# Build find exclude prune expression
PRUNE_ARGS=()
for ex in "${EXCLUDES[@]}"; do
  PRUNE_ARGS+=(-name "$ex" -prune -o)
done

TMP_RAW="$(mktemp -t file-triage-raw.XXXXXX)"
TMP_SCORED="$(mktemp -t file-triage-scored.XXXXXX)"
trap 'rm -f "$TMP_RAW" "$TMP_SCORED"' EXIT

total_items=0
total_size=0

for root in "${ROOTS[@]}"; do
  root_expanded="${root/#\~/$HOME}"
  [[ -e "$root_expanded" ]] || { echo "skip missing root: $root" >&2; continue; }
  # BSD find: -maxdepth, -prune syntax. stat -f %z %a %m
  # We want files AND dirs >MIN_SIZE. For dirs, du -sk gets recursive size — too slow at scale.
  # Strategy: only files (lighter). Optionally include dirs at depth=1 from root.
  find "$root_expanded" -maxdepth "$MAX_DEPTH" \
       "${PRUNE_ARGS[@]}" \
       -type f -print0 2>/dev/null \
  | while IFS= read -r -d '' f; do
      # Skip symlinks-to-nothing & sockets via stat
      if ! stat -f '%z %a %m' "$f" >/dev/null 2>&1; then continue; fi
      read -r sz at mt < <(stat -f '%z %a %m' "$f")
      [[ -z "$sz" ]] && continue
      if (( sz < MIN_SIZE )); then continue; fi
      printf '%s\t%s\t%s\t%s\n' "$sz" "$at" "$mt" "$f"
    done >> "$TMP_RAW"
done

# Sort by size desc; cap to a reasonable upper bound before scoring (10x TOP_N) for speed
sort -t $'\t' -k1,1 -rn "$TMP_RAW" | head -n $(( TOP_N * 10 )) > "${TMP_RAW}.top"
mv "${TMP_RAW}.top" "$TMP_RAW"

while IFS=$'\t' read -r sz at mt path; do
  [[ -z "$path" ]] && continue
  score_one "$path" "$sz" "$at" "$mt" "0" >> "$TMP_SCORED"
  total_items=$((total_items + 1))
  total_size=$((total_size + sz))
done < "$TMP_RAW"

# Sort by total score desc, head to TOP_N
sort_by_total_desc() {
  python3 -c '
import json,sys
rows=[json.loads(l) for l in sys.stdin if l.strip()]
rows.sort(key=lambda r:(-r["scores"]["total"], -r["size_bytes"]))
for r in rows: print(json.dumps(r))
'
}

# Write header + ranked rows
{
  python3 - "$TS" "${ROOTS[*]}" "${EXCLUDES[*]}" "$total_items" "$total_size" "$MIN_SIZE" "$MAX_DEPTH" <<'PY'
import json,sys
ts,roots,excludes,items,size,minsz,depth=sys.argv[1:]
print(json.dumps({
  "_header":True,
  "scan_ts":ts,
  "roots":roots.split(),
  "excludes":excludes.split(),
  "total_items_scored":int(items),
  "total_size_bytes":int(size),
  "min_size_bytes":int(minsz),
  "max_depth":int(depth),
  "tool":"file-triage-scan.sh",
  "schema_version":1,
}))
PY
  sort_by_total_desc < "$TMP_SCORED" | head -n "$TOP_N"
} > "$OUT"

echo "wrote: $OUT"
echo "items_scored: $total_items  total_size: $(human_size "$total_size")  top: $TOP_N"
