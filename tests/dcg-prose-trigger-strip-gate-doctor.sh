#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dcg-prose-trigger-strip-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dcg-prose-doctor.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

memory_rule="$TMP/memory-rule.md"
printf 'fixture memory rule\n' >"$memory_rule"
export DCG_PROSE_TRIGGER_MEMORY_RULE="$memory_rule"

if bash -n "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

"$SCRIPT" --info >"$TMP/info.json"
assert_jq "$TMP/info.json" '(.flags | index("doctor")) and (.flags | index("--doctor")) and .doctor_schema == "dcg-prose-trigger-strip-gate.doctor.v1"' "info advertises doctor"

if "$SCRIPT" --help | grep -Fq 'doctor|--doctor'; then
  pass "help advertises doctor"
else
  fail "help advertises doctor"
fi

if "$SCRIPT" --examples | grep -Fq 'dcg-prose-trigger-strip-gate.sh doctor --json'; then
  pass "examples include doctor"
else
  fail "examples include doctor"
fi

"$SCRIPT" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.schema_version == "dcg-prose-trigger-strip-gate.doctor.v1" and .command == "doctor" and .status == "pass" and .mode == "read_only" and .mutates == false and .pattern_count == 8 and (.checks | length == 3)' "doctor read-only pass envelope"

"$SCRIPT" --doctor --json >"$TMP/doctor-alias.json"
assert_jq "$TMP/doctor-alias.json" '.command == "doctor" and .mutates == false' "--doctor alias"

printf 'safe prose about the all-paths flag\n' >"$TMP/safe.md"
"$SCRIPT" --file "$TMP/safe.md" --json >"$TMP/safe.json"
assert_jq "$TMP/safe.json" '.status == "safe" and (.matches | length == 0)' "safe prose still passes"

printf 'bad prose says git add -A and rm -rf\n' >"$TMP/danger.md"
set +e
"$SCRIPT" --file "$TMP/danger.md" --json >"$TMP/danger.json"
rc=$?
set -e
if [[ "$rc" -eq 1 ]]; then
  pass "dangerous prose returns rc 1"
else
  fail "dangerous prose rc=$rc"
fi
assert_jq "$TMP/danger.json" '.status == "dangerous_substring_detected" and ([.matches[].substring] | index("git add -A")) and ([.matches[].substring] | index("rm -rf"))' "dangerous prose still reports matches"

set +e
"$SCRIPT" --apply --json >"$TMP/apply.out" 2>"$TMP/apply.err"
rc=$?
set -e
if [[ "$rc" -eq 2 ]] && grep -Fq 'apply mode is reserved' "$TMP/apply.err"; then
  pass "apply remains reserved/refused"
else
  fail "apply remains reserved/refused rc=$rc"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
