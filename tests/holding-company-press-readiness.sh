#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-press-readiness-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-press-readiness.schema.json"
LEDGER="$ROOT/state/holding-company-press-readiness.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-press-readiness.XXXXXX")"
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
jq empty "$LEDGER" && pass "ledger json valid" || fail "ledger json valid"

"$SCRIPT" --ledger "$LEDGER" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .presses[0].press_readiness_gate_status == "blocked"' "current ledger validates and blocks PRESS"

jq '
  .clear_count = 1
  | .presses[0].status = "press_clear"
  | .presses[0].release_version = "v0.1"
  | .presses[0].v0_1_release_ref = "urn:release:v0.1"
  | .presses[0].skillos_hardening_ref = "urn:skillos-hardening:fixture"
  | .presses[0].signed_equity_ref = "urn:signed-equity:fixture"
' "$LEDGER" >"$TMP/press-clear.json"
"$SCRIPT" --ledger "$TMP/press-clear.json" --json >"$TMP/press-clear.out.json"
assert_jq "$TMP/press-clear.out.json" '.status == "pass" and .clear_count == 1 and .presses[0].press_readiness_gate_status == "clear"' "PRESS clear with v0.1 and required refs passes"

jq '.presses[0].status = "formation_ready" | .presses[0].release_version = "v0.1.1"' "$TMP/press-clear.json" >"$TMP/formation-ready.json"
"$SCRIPT" --ledger "$TMP/formation-ready.json" --json >"$TMP/formation-ready.out.json"
assert_jq "$TMP/formation-ready.out.json" '.status == "pass" and .clear_count == 1 and .presses[0].press_readiness_gate_status == "clear"' "formation ready accepts v0.1 patch release"

jq '.presses[0].release_version = "v0.2"' "$TMP/press-clear.json" >"$TMP/wrong-version.json"
if "$SCRIPT" --ledger "$TMP/wrong-version.json" --json >"$TMP/wrong-version.out.json" 2>/dev/null; then
  fail "non-v0.1 release rejected"
else
  assert_jq "$TMP/wrong-version.out.json" '.status == "fail" and (.failures[] | select(.code == "press_clear_without_v0_1_release_version"))' "non-v0.1 release rejected"
fi

jq '.presses[0].signed_equity_ref = null' "$TMP/press-clear.json" >"$TMP/no-equity.json"
if "$SCRIPT" --ledger "$TMP/no-equity.json" --json >"$TMP/no-equity.out.json" 2>/dev/null; then
  fail "PRESS clear without signed equity rejected"
else
  assert_jq "$TMP/no-equity.out.json" '.status == "fail" and (.failures[] | select(.code == "press_clear_missing_required_refs" and (.missing_refs | index("signed_equity_ref"))))' "PRESS clear without signed equity rejected"
fi

jq '.presses[0].skillos_hardening_ref = null' "$TMP/press-clear.json" >"$TMP/no-skillos.json"
if "$SCRIPT" --ledger "$TMP/no-skillos.json" --json >"$TMP/no-skillos.out.json" 2>/dev/null; then
  fail "PRESS clear without SkillOS hardening rejected"
else
  assert_jq "$TMP/no-skillos.out.json" '.status == "fail" and (.failures[] | select(.code == "press_clear_missing_required_refs" and (.missing_refs | index("skillos_hardening_ref"))))' "PRESS clear without SkillOS hardening rejected"
fi

jq '.presses[0].substrate_share_receipt = null' "$TMP/press-clear.json" >"$TMP/no-substrate.json"
if "$SCRIPT" --ledger "$TMP/no-substrate.json" --json >"$TMP/no-substrate.out.json" 2>/dev/null; then
  fail "PRESS clear without substrate-share receipt rejected"
else
  assert_jq "$TMP/no-substrate.out.json" '.status == "fail" and (.failures[] | select(.code == "press_clear_missing_required_refs" and (.missing_refs | index("substrate_share_receipt"))))' "PRESS clear without substrate-share receipt rejected"
fi

jq '.clear_count = 2' "$TMP/press-clear.json" >"$TMP/mismatch.json"
if "$SCRIPT" --ledger "$TMP/mismatch.json" --json >"$TMP/mismatch.out.json" 2>/dev/null; then
  fail "clear count mismatch rejected"
else
  assert_jq "$TMP/mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "press_readiness_clear_count_mismatch"))' "clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
