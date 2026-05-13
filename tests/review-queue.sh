#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/review_queue.py"
FIXTURE="$ROOT/fixtures/review-queue/manual-review.jsonl"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-review-queue.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

if python3 "$SCRIPT" --queue "$FIXTURE" --json >"$TMP/summary.json" \
  && jq -e '.status == "pass" and .total_rows == 5 and .unsigned_rows == 4 and .reason_counts."mode_a_codemod_sufficient" == 2' "$TMP/summary.json" >/dev/null; then
  pass "summary counts"
else
  fail "summary counts"
fi

if python3 "$SCRIPT" --queue "$FIXTURE" --out "$TMP/signed.jsonl" --sign-safe --json >"$TMP/sign.json" \
  && jq -e '.status == "pass" and .total_rows == 5 and .safe_signed_rows == 3 and .unsigned_rows == 1 and .unsigned_reason_counts."mode_b_pattern_rewrite_required" == 1' "$TMP/sign.json" >/dev/null \
  && jq -s -e '
    (map(select(.reason == "mode_a_codemod_sufficient" and .signed_off_by == "policy:codemod-and-staging-scan-clean")) | length) == 2
    and (map(select((.reason | startswith("denylist:")) and .signed_off_by == "policy:excluded-from-staging-by-denylist")) | length) == 1
    and (map(select(.reason == "mode_b_pattern_rewrite_required" and (.signed_off_by == null))) | length) == 1
  ' "$TMP/signed.jsonl" >/dev/null; then
  pass "safe signoff"
else
  fail "safe signoff"
fi

if python3 "$SCRIPT" --queue "$FIXTURE" --out "$TMP/signed-mode-b.jsonl" --sign-safe --mode-b-evidence "fixture staging scan clean" --json >"$TMP/sign-mode-b.json" \
  && jq -e '.status == "pass" and .total_rows == 5 and .safe_signed_rows == 4 and .unsigned_rows == 0' "$TMP/sign-mode-b.json" >/dev/null \
  && jq -s -e '
    (map(select(.reason == "mode_b_pattern_rewrite_required" and .signed_off_by == "policy:mode-b-reviewed-with-clean-staging-scan" and .evidence == "fixture staging scan clean")) | length) == 1
  ' "$TMP/signed-mode-b.jsonl" >/dev/null; then
  pass "mode-b evidence signoff"
else
  fail "mode-b evidence signoff"
fi

if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$SCRIPT" --json >"$TMP/script-scan.json" \
  && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/script-scan.json" >/dev/null; then
  pass "script depersonalization clean"
else
  fail "script depersonalization clean"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
