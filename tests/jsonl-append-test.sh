#!/usr/bin/env bash
set -euo pipefail

LIB="${JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jsonl-append-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# shellcheck source=/dev/null
source "$LIB"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

line_count() {
  [[ -f "$1" ]] || { printf '0'; return 0; }
  wc -l <"$1" | tr -d ' '
}

assert_rc() {
  local got="$1" want="$2" label="$3"
  if [[ "$got" == "$want" ]]; then
    pass "$label"
  else
    fail "$label rc=$got expected=$want"
  fi
}

file="$TMP/basic.jsonl"
fw_jsonl_append_validated "$file" '{"label":"alpha","ts":"test"}'
if [[ "$(jq -c . <"$file")" == '{"label":"alpha","ts":"test"}' ]] && [[ "$(fw_jsonl_count "$file")" == "1" ]]; then
  pass "valid_row_appends_and_readback_matches"
else
  fail "valid_row_appends_and_readback_matches"
fi

before="$(line_count "$file")"
set +e
fw_jsonl_append_validated "$file" '{"broken":'
rc=$?
set -e
if [[ "$rc" == "1" && "$(line_count "$file")" == "$before" ]]; then
  pass "invalid_json_exits_1_and_file_unchanged"
else
  fail "invalid_json_exits_1_and_file_unchanged"
fi

before="$(line_count "$file")"
set +e
fw_jsonl_append_validated "$file" ''
rc=$?
set -e
if [[ "$rc" == "1" && "$(line_count "$file")" == "$before" ]]; then
  pass "empty_string_exits_1_and_file_unchanged"
else
  fail "empty_string_exits_1_and_file_unchanged"
fi

missing="$TMP/nested/missing.jsonl"
fw_jsonl_append_validated "$missing" '{"label":"created"}'
if [[ -f "$missing" ]] && [[ "$(jq -c . <"$missing")" == '{"label":"created"}' ]]; then
  pass "missing_file_parent_created_and_written"
else
  fail "missing_file_parent_created_and_written"
fi

concurrent="$TMP/concurrent.jsonl"
fw_jsonl_append_validated "$concurrent" '{"id":"a"}' &
pid_a=$!
fw_jsonl_append_validated "$concurrent" '{"id":"b"}' &
pid_b=$!
wait "$pid_a"
wait "$pid_b"
if [[ "$(fw_jsonl_count "$concurrent")" == "2" ]] \
  && fw_jsonl_tail "$concurrent" 2 | jq -s -e 'map(.id) | sort == ["a","b"]' >/dev/null; then
  pass "concurrent_writes_both_present_no_corruption"
else
  fail "concurrent_writes_both_present_no_corruption"
fi

set +e
FW_JSONL_APPEND_FAULT=readback_mismatch fw_jsonl_append_validated "$TMP/fault.jsonl" '{"id":"fault"}'
rc=$?
set -e
assert_rc "$rc" "3" "synthetic_readback_mismatch_exits_3"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "6" && "$fail_count" == "0" ]]
