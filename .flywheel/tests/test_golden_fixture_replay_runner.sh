#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/golden-fixture-replay-runner.sh"
FIXTURES="$ROOT/.flywheel/tests/fixtures/mission-lock-paradigm-extension-2026-05-06"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/golden-fixture-replay-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
test_cases=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
case_pass() { test_cases=$((test_cases + 1)); pass "$1"; }
case_fail() { test_cases=$((test_cases + 1)); fail "$1"; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

bash -n "$SCRIPT" && pass "runner syntax"
"$SCRIPT" --help >/dev/null && pass "help exits"
"$SCRIPT" --info | jq -e '.mutates == false and (.canonical_cli_verbs | length) == 5 and (.subcommands | length) == 3' >/dev/null && pass "info contract"
"$SCRIPT" --examples --json | jq -e '.examples | length == 3' >/dev/null && pass "examples contract"
"$SCRIPT" schema --json | jq -e '(.modes | length) == 5 and (.fixture_required_fields | index("finding_id"))' >/dev/null && pass "schema contract"
"$SCRIPT" list-fixtures --json >"$TMP/list.json"
assert_jq "$TMP/list.json" '.fixtures_count == 7' "lists seven fixture files"

run_fixture() {
  local fixture="$1" name out expected_verdict finding codes_json lens_json
  name="$(basename "$fixture" .json)"
  out="$TMP/$name.out.json"
  "$SCRIPT" replay --fixture "$fixture" --json >"$out"
  expected_verdict="$(jq -r '.expected.verdict' "$fixture")"
  finding="$(jq -r '.finding_id' "$fixture")"
  codes_json="$(jq -c '.expected.codes // []' "$fixture")"
  lens_json="$(jq -c '.expected.lenses // []' "$fixture")"
  if jq -e \
    --arg expected "$expected_verdict" \
    --arg finding "$finding" \
    --argjson codes "$codes_json" \
    --argjson lenses "$lens_json" \
    '.status == "pass" and .finding_id == $finding and .observed_verdict == $expected and (($codes - .codes) | length == 0) and (($lenses - .codes) | length == 0)' \
    "$out" >/dev/null; then
    case_pass "$name replay golden"
  else
    case_fail "$name replay golden"
    jq . "$out" >&2 || true
  fi
}

for fixture in "$FIXTURES"/*.json; do
  run_fixture "$fixture"
done

"$SCRIPT" replay-all --json >"$TMP/replay-all.json"
if jq -e '.status == "pass" and .fixtures_count == 7 and all(.results[]; .status == "pass")' "$TMP/replay-all.json" >/dev/null; then
  case_pass "replay-all aggregate"
else
  case_fail "replay-all aggregate"
  jq . "$TMP/replay-all.json" >&2 || true
fi

"$SCRIPT" verify-invariants --json >"$TMP/invariants.json"
if jq -e '.status == "pass" and .fixtures_count == 7 and (.missing_findings | length == 0) and (.missing_wave_artifacts | length == 0)' "$TMP/invariants.json" >/dev/null; then
  case_pass "verify-invariants covers Wave 1-3 dependencies"
else
  case_fail "verify-invariants covers Wave 1-3 dependencies"
  jq . "$TMP/invariants.json" >&2 || true
fi

quiet_out="$TMP/quiet.out"
"$SCRIPT" replay-all --quiet >"$quiet_out"
[[ ! -s "$quiet_out" ]] && pass "quiet replay-all emits no output" || fail "quiet replay-all emits no output"

printf 'RESULT pass=%s fail=%s test_cases=%s\n' "$pass_count" "$fail_count" "$test_cases"
[[ "$test_cases" -ge 9 && "$fail_count" == "0" ]]
