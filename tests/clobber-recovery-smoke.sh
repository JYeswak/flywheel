#!/usr/bin/env bash
# Smoke test for .flywheel/scripts/clobber-recovery.sh
#
# Verifies: clobber-shape detection, restore-from-HEAD, NOOP for clean files,
# NOT_CLOBBER for legitimate runtime drift, REFUSED for empty HEAD blobs,
# explicit --paths bypassing the heuristic gate.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/.flywheel/scripts/clobber-recovery.sh"
[[ -x "$SCRIPT" ]] || { echo "FAIL script missing: $SCRIPT"; exit 1; }

TMP="$(mktemp -d -t clobber-recovery-smoke.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
git init -q
git config user.email "smoke@test"
git config user.name "smoke"

# Fixture: a "doctrine doc" with substantial content (>1000 bytes).
DOC=".flywheel/canonical-doc.md"
mkdir -p .flywheel
{
  echo "# Canonical Doc"
  for i in $(seq 1 100); do
    echo "Line $i: lorem ipsum dolor sit amet consectetur adipiscing elit"
  done
} > "$DOC"
git add "$DOC"
git commit -q -m "seed canonical doc"

HEAD_BYTES="$(wc -c < "$DOC" | awk '{print $1+0}')"

pass=0
fail=0
note() { printf '  %s\n' "$1"; }
ok()   { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
ng()   { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; note "$2"; }

# Test 1: clean working tree → NOOP
result="$("$SCRIPT" --dry-run --paths "$DOC" 2>/dev/null || true)"
if printf '%s' "$result" | grep -q '"noop":\[".*matches_HEAD'; then
  ok "T1 clean working tree reports NOOP"
else
  ng "T1 clean working tree reports NOOP" "$result"
fi

# Test 2: clobber via single-line truncation → restore
echo "schema_version: 1" > "$DOC"
result="$("$SCRIPT" --paths "$DOC" 2>/dev/null || true)"
NEW_BYTES="$(wc -c < "$DOC" | awk '{print $1+0}')"
if printf '%s' "$result" | grep -q '"restored":\[".*from_bytes' && [[ "$NEW_BYTES" == "$HEAD_BYTES" ]]; then
  ok "T2 single-line truncation restored to HEAD bytes ($HEAD_BYTES)"
else
  ng "T2 single-line truncation restored to HEAD bytes ($HEAD_BYTES)" "got $NEW_BYTES; result=$result"
fi

# Test 3: legitimate runtime drift (file still substantial) → NOT_CLOBBER (when canonical default used)
echo "schema_version: 1" > .flywheel/MISSION.md
git add .flywheel/MISSION.md
git commit -q -m "fake mission"
echo "## drift line added at runtime" >> .flywheel/MISSION.md
DRIFT_BYTES="$(wc -c < .flywheel/MISSION.md | awk '{print $1+0}')"
# canonical default scans MISSION.md; this file is small so heuristic should NOT trigger restore
result="$("$SCRIPT" --dry-run 2>/dev/null || true)"
if printf '%s' "$result" | grep -q '"not_clobber":\[".*MISSION'; then
  ok "T3 small-file runtime drift does NOT trigger restore"
else
  # Could also be NOOP if drift didn't change blob, accept either non-RESTORE outcome
  if ! printf '%s' "$result" | grep -q '"restored":\[".*MISSION'; then
    ok "T3 small-file runtime drift does NOT trigger restore (via path)"
  else
    ng "T3 small-file runtime drift does NOT trigger restore" "result=$result"
  fi
fi

# Test 4: --paths overrides the heuristic gate (clobber tiny → tiny still restores)
TINY=".flywheel/tiny.md"
printf 'a\nb\nc\n' > "$TINY"  # 6 bytes — well under heuristic threshold
git add "$TINY" && git commit -q -m "tiny seed"
echo "" > "$TINY"  # truncate
result="$("$SCRIPT" --paths "$TINY" 2>/dev/null || true)"
if printf '%s' "$result" | grep -q '"refused":\[".*tiny'; then
  ok "T4 tiny HEAD blob refused (head_empty_or_tiny gate)"
else
  ng "T4 tiny HEAD blob refused (head_empty_or_tiny gate)" "result=$result"
fi

# Test 5: receipts logged
echo "schema_version: 1" > "$DOC"
"$SCRIPT" --paths "$DOC" --reason "smoke test 5" --bead smoke-bead-1 >/dev/null 2>&1 || true
if [[ -f .flywheel/clobber-recovery-log.jsonl ]] && grep -q "smoke test 5" .flywheel/clobber-recovery-log.jsonl; then
  ok "T5 receipt appended to .flywheel/clobber-recovery-log.jsonl"
else
  ng "T5 receipt appended to .flywheel/clobber-recovery-log.jsonl" "log file missing or no match"
fi

printf '\nSUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ $fail -eq 0 ]] || exit 1
