#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/jeff-pattern-citation-probe.sh"
FIXTURES="$ROOT/tests/fixtures/jeff-pattern-citation"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-pattern-citation.XXXXXX")"
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

bash -n "$PROBE" && pass "probe syntax" || fail "probe syntax"
"$PROBE" --help >/dev/null && pass "help exits 0" || fail "help exits 0"
"$PROBE" --info | jq -e '.signal == "jeff_pattern_uncited_count"' >/dev/null && pass "info exposes signal" || fail "info exposes signal"
"$PROBE" --schema | jq -e '.schema_version == "jeff-pattern-citation/v1"' >/dev/null && pass "schema exits 0" || fail "schema exits 0"
"$PROBE" --examples >/dev/null && pass "examples exits 0" || fail "examples exits 0"
"$PROBE" --version >/dev/null && pass "version exits 0" || fail "version exits 0"

"$PROBE" --json "$FIXTURES/valid.md" >"$TMP/valid.json"
assert_jq "$TMP/valid.json" '.status == "pass" and .jeff_pattern_uncited_count == 0 and .files_checked == 1' "valid citation passes"

"$PROBE" --json "$FIXTURES/vague.md" >"$TMP/vague.json" && vague_rc=0 || vague_rc=$?
if [[ "${vague_rc:-0}" -ne 0 ]] && jq -e '.status == "fail" and .jeff_pattern_uncited_count == 1 and .rows[0].reason == "missing_jeff_file_line_source"' "$TMP/vague.json" >/dev/null; then
  pass "vague inspired-by claim fails"
else
  fail "vague inspired-by claim fails"
  jq . "$TMP/vague.json" || true
fi

"$PROBE" --json "$FIXTURES/missing-file-line.md" >"$TMP/missing.json" && missing_rc=0 || missing_rc=$?
if [[ "${missing_rc:-0}" -ne 0 ]] && jq -e '.status == "fail" and .jeff_pattern_uncited_count == 1 and (.rows[0].text | test("Source: Jeff"))' "$TMP/missing.json" >/dev/null; then
  pass "missing file-line source fails"
else
  fail "missing file-line source fails"
  jq . "$TMP/missing.json" || true
fi

"$PROBE" --doctor --json "$FIXTURES/vague.md" "$FIXTURES/missing-file-line.md" >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "fail" and .jeff_pattern_uncited_count == 2 and (.signals[0].name == "jeff_pattern_uncited_count")' "doctor mode exposes uncited count"

rg -q 'jeff-pattern-citation-probe.sh' "$ROOT/README.md" && pass "README documents probe" || fail "README documents probe"
rg -q 'jeff_pattern_uncited_count' "$ROOT/AGENTS.md" && pass "AGENTS documents signal" || fail "AGENTS documents signal"
rg -q '^jeff_pattern_citation_probe[[:space:]]' "$ROOT/.flywheel/canonical-paths.txt" && pass "canonical path registered" || fail "canonical path registered"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
