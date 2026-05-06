#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/incidents-evidence-link-validator.sh"
FIXTURES="$ROOT/tests/fixtures/incidents-evidence-link-validator"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/incidents-evidence-link.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
"$SCRIPT" --help >/dev/null && pass "help exits 0" || fail "help exits 0"
"$SCRIPT" --info | jq -e '.signal == "incidents_evidence_missing_count"' >/dev/null && pass "info exposes signal" || fail "info exposes signal"
"$SCRIPT" --schema | jq -e '.schema_version == "incidents-evidence-link-validator/v1"' >/dev/null && pass "schema exits 0" || fail "schema exits 0"
"$SCRIPT" --examples >/dev/null && pass "examples exits 0" || fail "examples exits 0"
"$SCRIPT" --version >/dev/null && pass "version exits 0" || fail "version exits 0"

"$SCRIPT" --json "$FIXTURES/pass.md" >"$TMP/pass.json"
assert_jq "$TMP/pass.json" '.status == "pass" and .files_checked == 1 and .entries_checked == 2 and .incidents_evidence_missing_count == 0' "pass fixture passes"

"$SCRIPT" --json "$FIXTURES/fail.md" >"$TMP/fail.json" && fail_rc=0 || fail_rc=$?
if [[ "${fail_rc:-0}" -ne 0 ]] && jq -e '.status == "fail" and .files_checked == 1 and .entries_checked == 1 and .incidents_evidence_missing_count == 1 and .rows[0].reason == "missing_evidence_block"' "$TMP/fail.json" >/dev/null; then
  pass "fail fixture fails"
else
  fail "fail fixture fails"
  jq . "$TMP/fail.json" || true
fi

"$SCRIPT" --warn-only --json "$FIXTURES/fail.md" >"$TMP/warn.json"
assert_jq "$TMP/warn.json" '.status == "warn" and .incidents_evidence_missing_count == 1' "warn-only reports but exits zero"

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
cp "$FIXTURES/pass.md" "$repo/INCIDENTS.md"
"$SCRIPT" --repo "$repo" --changed --json >"$TMP/changed.json"
assert_jq "$TMP/changed.json" '.status == "pass" and .files_checked == 1 and .entries_checked == 2' "changed discovery scans INCIDENTS.md"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
