#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/substrate-share-receipt-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/substrate-share-receipt.schema.json"
RECEIPT="$ROOT/state/substrate-share/mobile-eats-20260517T0654Z.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/substrate-share-receipt.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

if python3 -m py_compile "$SCRIPT"; then
  pass "validator py_compile"
else
  fail "validator py_compile"
fi

jq empty "$SCHEMA" && pass "schema json valid" || fail "schema json valid"
jq empty "$RECEIPT" && pass "receipt json valid" || fail "receipt json valid"

"$SCRIPT" "$RECEIPT" --check-paths --check-manifest --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .company_slug == "mobile-eats" and .counts.production_packages == 26 and .counts.development_packages == 1 and .counts.total_packages == 27' "current mobile-eats substrate receipt passes"

jq '.counts.total_packages = 99' "$RECEIPT" >"$TMP/bad-count.json"
if "$SCRIPT" "$TMP/bad-count.json" --json >"$TMP/bad-count.out.json" 2>/dev/null; then
  fail "count mismatch rejected"
else
  assert_jq "$TMP/bad-count.out.json" '.status == "fail" and (.failures[] | select(.code == "count_mismatch:total_packages"))' "count mismatch rejected"
fi

jq '.packages = .packages[:-1]' "$RECEIPT" >"$TMP/bad-manifest.json"
if "$SCRIPT" "$TMP/bad-manifest.json" --check-manifest --json >"$TMP/bad-manifest.out.json" 2>/dev/null; then
  fail "manifest mismatch rejected"
else
  assert_jq "$TMP/bad-manifest.out.json" '.status == "fail" and (.failures[] | select(.code == "count_mismatch:development_packages")) and (.failures[] | select(.code == "manifest_package_set_mismatch"))' "manifest mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
