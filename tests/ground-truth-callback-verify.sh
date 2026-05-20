#!/usr/bin/env bash
# Smoke test for ground-truth-callback-verify.sh (Duty 5b, bead flywheel-vy1yz).
#
# Verifies the script:
#   1) PASSES a callback whose claims all resolve to real ground truth
#   2) FAILS a callback claiming phantom beads / commits / files

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/ground-truth-callback-verify.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "FAIL: $SCRIPT not executable"
  exit 1
fi

HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD)"
TMPDIR="$(mktemp -d -t gtcv-smoke.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT
EVIDENCE="$TMPDIR/real-evidence.txt"
printf 'real evidence\n' >"$EVIDENCE"

pass_rc=0
fail_rc=0

set +e
"$SCRIPT" --callback "DONE flywheel-vy1yz beads_filed=flywheel-vy1yz commit_sha=$HEAD_SHA evidence=$EVIDENCE" --json >"$TMPDIR/pass.json"
pass_rc=$?
"$SCRIPT" --callback "DONE phantom beads_filed=flywheel-phantom-doesnotexist commit_sha=deadbeefdeadbeef evidence=$TMPDIR/missing.txt" --json >"$TMPDIR/fail.json"
fail_rc=$?
set -e

errs=0

if [[ "$pass_rc" -ne 0 ]]; then
  echo "FAIL: pass-case exit was $pass_rc (expected 0)"
  cat "$TMPDIR/pass.json"
  errs=$((errs+1))
fi
if ! jq -e '.verified == true' "$TMPDIR/pass.json" >/dev/null; then
  echo "FAIL: pass-case verified != true"
  errs=$((errs+1))
fi

if [[ "$fail_rc" -ne 1 ]]; then
  echo "FAIL: fail-case exit was $fail_rc (expected 1)"
  cat "$TMPDIR/fail.json"
  errs=$((errs+1))
fi
if ! jq -e '.verified == false' "$TMPDIR/fail.json" >/dev/null; then
  echo "FAIL: fail-case verified != false"
  errs=$((errs+1))
fi
if ! jq -e '(.reasons_for_failure | length) >= 3' "$TMPDIR/fail.json" >/dev/null; then
  echo "FAIL: fail-case expected >=3 fail reasons"
  jq '.reasons_for_failure' "$TMPDIR/fail.json"
  errs=$((errs+1))
fi

if [[ "$errs" -eq 0 ]]; then
  echo "OK: ground-truth-callback-verify smoke (pass+fail) green"
  exit 0
fi
echo "FAIL: $errs assertion(s) failed"
exit 1
