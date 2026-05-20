#!/usr/bin/env bash
# sync-doctrine-clean-wt-gate.sh — smoke test for the clean-WT HARD GATE.
#
# Bead: flywheel-k8pee
# Contract: --apply must REFUSE when consumer has unrelated dirty files,
# and must SUCCEED after operator commits/stashes those files.

set -euo pipefail

SCRIPT="/Users/josh/Developer/flywheel/.flywheel/scripts/flywheel-sync-doctrine.sh"
UPSTREAM_REAL="${HOME}/Developer/flywheel/.flywheel/doctrine"

if [[ ! -x "$SCRIPT" ]]; then
  echo "FAIL: script not executable: $SCRIPT" >&2
  exit 1
fi
if [[ ! -d "$UPSTREAM_REAL" ]]; then
  echo "FAIL: no real upstream doctrine at $UPSTREAM_REAL" >&2
  exit 1
fi

TMP="$(mktemp -d -t sync-doctrine-test-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Set up tmp consumer repo
cd "$TMP"
git init -q
git config user.email "test@flywheel.local"
git config user.name "sync-doctrine-test"

mkdir -p src
echo "// initial" > src/main.txt
git add src/main.txt
git commit -q -m "initial"

# Pre-create a doctrine dir so the consumer "tracks" something realistic
mkdir -p .flywheel/doctrine

# Pick first upstream doctrine doc as a tracked target
SAMPLE_NAME="$(find "$UPSTREAM_REAL" -maxdepth 1 -type f -name '*.md' | head -1 | xargs basename)"
if [[ -z "$SAMPLE_NAME" ]]; then
  echo "FAIL: no sample doctrine doc found in $UPSTREAM_REAL" >&2
  exit 1
fi

cat > .flywheel/DOCTRINE-MANIFEST.json <<EOF
{
  "version": "v1",
  "tracked_doctrines": ["$SAMPLE_NAME"],
  "pin_policy": "latest",
  "consumer_overrides_dir": ".flywheel/doctrine-overrides/"
}
EOF
git add .flywheel/DOCTRINE-MANIFEST.json
git commit -q -m "add manifest"

# === PHASE 1: introduce unrelated dirty file, expect REFUSAL ===
echo "// dirty unrelated change" >> src/main.txt
echo
echo "=== PHASE 1: --apply with dirty unrelated file (expect REFUSE) ==="
set +e
"$SCRIPT" --apply
RC=$?
set -e
if [[ $RC -ne 3 ]]; then
  echo "FAIL: expected exit 3 (apply-refused), got $RC" >&2
  exit 1
fi

# Inspect latest receipt
RECEIPT="$(ls -t .flywheel/evidence/sync-doctrine-*.json | head -1)"
if ! grep -q '"mode": "apply-refused"' "$RECEIPT"; then
  echo "FAIL: receipt does not record apply-refused mode" >&2
  cat "$RECEIPT" >&2
  exit 1
fi
if ! grep -q 'src/main.txt' "$RECEIPT"; then
  echo "FAIL: receipt does not name the dirty file" >&2
  cat "$RECEIPT" >&2
  exit 1
fi
echo "PHASE 1 OK — refused with reason naming src/main.txt"

# === PHASE 2: discard dirty file, retry, expect SUCCESS ===
git checkout -- src/main.txt
echo
echo "=== PHASE 2: --apply after cleaning WT (expect SUCCESS) ==="
"$SCRIPT" --apply
RECEIPT2="$(ls -t .flywheel/evidence/sync-doctrine-*.json | head -1)"
if ! grep -q '"mode": "apply"' "$RECEIPT2"; then
  echo "FAIL: receipt does not record apply mode" >&2
  cat "$RECEIPT2" >&2
  exit 1
fi
if [[ ! -f ".flywheel/doctrine/$SAMPLE_NAME" ]]; then
  echo "FAIL: doctrine doc was not copied: .flywheel/doctrine/$SAMPLE_NAME" >&2
  exit 1
fi
echo "PHASE 2 OK — apply succeeded, doc copied"

# === PHASE 3: dirty file INSIDE .flywheel/doctrine/ is allowed-scope ===
# (the gate only blocks UNRELATED dirty files)
echo "// stray edit inside doctrine" >> ".flywheel/doctrine/$SAMPLE_NAME"
echo
echo "=== PHASE 3: --dry-run with dirty doctrine file (should not refuse — dry-run ignores gate) ==="
"$SCRIPT" --dry-run
echo "PHASE 3 OK — dry-run does not gate"

echo
echo "ALL PHASES PASS — sync-doctrine clean-WT gate works"
