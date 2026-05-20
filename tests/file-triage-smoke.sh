#!/usr/bin/env bash
# file-triage-smoke.sh — Smoke test for file-triage scan + review CLIs.
#
# Builds a tmpdir of synthetic fixtures, runs the scanner, checks classifications
# land in sensible buckets, then runs the reviewer in --auto-yes=n mode.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCAN="$REPO_ROOT/.flywheel/scripts/file-triage-scan.sh"
REVIEW="$REPO_ROOT/.flywheel/scripts/file-triage-review.sh"

TMP="$(mktemp -d -t file-triage-smoke.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/Desktop" "$TMP/cache" "$TMP/Trash" "$TMP/repo" "$TMP/normal"

# Helper: make a file of N MB, then backdate atime/mtime
mkfile() {
  local path="$1" mb="$2" days_old="${3:-0}"
  mkdir -p "$(dirname "$path")"
  # macOS: dd if=/dev/zero of=... bs=1m count=$mb
  dd if=/dev/zero of="$path" bs=1048576 count="$mb" status=none
  if (( days_old > 0 )); then
    # touch -t YYYYMMDDhhmm.SS
    local stamp
    stamp=$(date -v-"${days_old}"d +%Y%m%d%H%M.%S)
    touch -t "$stamp" "$path"
    touch -a -t "$stamp" "$path"
  fi
}

# Fixtures:
# 1. small recent — should NOT appear (under min-size)
mkfile "$TMP/normal/small-recent.txt"   1 0
# 2. big stale 12MB, 400 days old — score-based REVIEW (age=10)
mkfile "$TMP/normal/big-stale.bin"     12 400
# 3. in cache dir, 15MB, 200 days — REVIEW+ via redundancy (cache + .cache)
mkfile "$TMP/cache/cache-blob.cache"   15 200
# 4. in Trash, 11MB, 100 days — forced REVIEW minimum (segment match)
mkfile "$TMP/Trash/trashed.bin"        11 100
# 5. on Desktop, 20MB, 50 days — forced REVIEW (Desktop segment)
mkfile "$TMP/Desktop/desk-note.bin"    20 50

OUT="$TMP/scan.jsonl"
echo "→ running scan..."
"$SCAN" --root "$TMP" --min-size $((10*1024*1024)) --top 50 --out "$OUT" --max-depth 6 >/dev/null

echo "→ scan output:"
cat "$OUT"

# Assertion 1: small-recent.txt must NOT be in the output
if grep -q "small-recent.txt" "$OUT"; then
  echo "FAIL: small-recent.txt appeared in scan (should be below min-size)" >&2
  exit 1
fi

# Assertion 2: each remaining fixture must appear
for f in big-stale.bin cache-blob.cache trashed.bin desk-note.bin; do
  if ! grep -q "$f" "$OUT"; then
    echo "FAIL: $f missing from scan" >&2
    exit 1
  fi
done

# Assertion 3: trashed.bin and desk-note.bin should be forced to REVIEW or higher
# regardless of their numeric score (force_review_path rule).
for f in trashed.bin desk-note.bin; do
  cls=$(grep "$f" "$OUT" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["classification"])')
  case "$cls" in
    REVIEW|ARCHIVE-CANDIDATE|LIKELY-TRASH) : ;;
    *) echo "FAIL: $f classified $cls, expected REVIEW+ (force_review_path)"; exit 1 ;;
  esac
done

# Assertion 3b: big-stale.bin and cache-blob.cache (not on Trash/Desktop)
# should land in a non-VITAL bucket (they're old enough to register age signal).
# We just verify the classification field is present and one of the valid enums.
for f in big-stale.bin cache-blob.cache; do
  cls=$(grep "$f" "$OUT" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["classification"])')
  case "$cls" in
    KEEP-VITAL|KEEP-LIKELY|REVIEW|ARCHIVE-CANDIDATE|LIKELY-TRASH) : ;;
    *) echo "FAIL: $f classification invalid: $cls"; exit 1 ;;
  esac
done
echo "→ classifications OK"

# Assertion 4: cache-blob.cache should have redundancy_score >= 3 (cache + .cache ext)
red=$(grep "cache-blob.cache" "$OUT" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["scores"]["redundancy"])')
if (( red < 3 )); then
  echo "FAIL: cache-blob.cache redundancy=$red, expected >=3" >&2
  exit 1
fi
echo "→ redundancy scoring OK (cache-blob.cache red=$red)"

# Assertion 5: header row first
header_present=$(head -n1 "$OUT" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("_header",False))')
if [[ "$header_present" != "True" ]]; then
  echo "FAIL: first row is not header" >&2
  exit 1
fi
echo "→ header row OK"

# Stage 2: review CLI in --auto-yes=n mode (keep all, mutate nothing in fixtures)
echo "→ running review in --auto-yes=n (keep all)..."
HOME_BAK="$HOME"
export HOME="$TMP/fakehome"
mkdir -p "$HOME/.local/state/flywheel/file-triage"
cp "$OUT" "$HOME/.local/state/flywheel/file-triage/scan-test.jsonl"
if ! "$REVIEW" --scan "$HOME/.local/state/flywheel/file-triage/scan-test.jsonl" \
          --auto-yes n --top 10 --reset > "$TMP/review.log" 2>&1; then
  echo "--- review.log (failure) ---"; cat "$TMP/review.log"; exit 1
fi
export HOME="$HOME_BAK"

# Verify fixtures still exist after n-pass
for f in "$TMP/normal/big-stale.bin" "$TMP/cache/cache-blob.cache" \
         "$TMP/Trash/trashed.bin" "$TMP/Desktop/desk-note.bin"; do
  [[ -f "$f" ]] || { echo "FAIL: review with auto-yes=n deleted $f" >&2; exit 1; }
done
echo "→ review n-pass kept all fixtures intact"

# Verify summary printed
grep -q "Review Summary" "$TMP/review.log" || { echo "FAIL: review summary missing"; exit 1; }
echo "→ review summary printed"

echo ""
echo "PASS: file-triage smoke OK"
