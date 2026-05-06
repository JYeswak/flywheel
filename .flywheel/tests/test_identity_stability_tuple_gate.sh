#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/identity-stability-tuple-validator.sh"
FIX="$ROOT/.flywheel/tests/fixtures/identity-stability-tuple"
HOOK="$HOME/.claude/hooks/flywheel-orch-identity-stability-tuple-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/identity-stability-tuple.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
case_pass=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
case_ok() { pass "$1"; case_pass=$((case_pass + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

make_tokens() {
  local dir="$1"; shift
  mkdir -p "$dir"
  local name
  for name in "$@"; do
    printf 'fixture-token-%s\n' "$name" >"$dir/$name.token"
    chmod 600 "$dir/$name.token"
  done
}

run_validator() {
  local label="$1" expected="$2" ids="$3" tokens="$4"
  local out="$TMP/$label.json" rc
  set +e
  "$SCRIPT" --identity-tokens "$ids" --topology "$FIX/topology.jsonl" --token-dir "$tokens" --strict --json >"$out"
  rc=$?
  set -e
  if [[ "$rc" -eq "$expected" ]]; then
    printf '%s\n' "$out"
    return 0
  fi
  fail "$label rc expected=$expected actual=$rc"
  jq . "$out" >&2 || true
  printf '%s\n' "$out"
  return 1
}

assert_hook_warns() {
  local label="$1" payload="$2" want="$3" out rc
  out="$TMP/$label.json"
  set +e
  printf '%s\n' "$payload" | "$HOOK" --json >"$out"
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "$label hook rc=$rc"
  if [[ "$want" == warn ]]; then
    assert_jq "$out" '.decision == "warn"' "$label"
  elif [[ ! -s "$out" ]]; then
    pass "$label"
  else
    fail "$label expected no warning"
    jq . "$out" >&2 || true
  fi
}

bash -n "$SCRIPT" && pass "validator_syntax" || fail "validator_syntax"
"$SCRIPT" --info --json | jq -e '.read_only == true and (.canonical_cli | index("--tuple"))' >/dev/null && pass "validator_info" || fail "validator_info"
"$SCRIPT" --examples >/dev/null && pass "validator_examples" || fail "validator_examples"
if [[ -x "$HOOK" ]]; then
  bash -n "$HOOK" && pass "hook_syntax" || fail "hook_syntax"
  "$HOOK" --info --json | jq -e '.mode == "advisory" and .blocks == false' >/dev/null && pass "hook_info" || fail "hook_info"
fi

tokens="$TMP/stable-tokens"; make_tokens "$tokens" StableAlpha
out="$(run_validator stable 0 "$FIX/stable.identity-tokens.jsonl" "$tokens")"
assert_jq "$out" '.success == true and .status == "stable" and .rotation_count == 0' "stable_tuple_json"
case_ok "case_1_stable_tuple"

tokens="$TMP/rotation-tokens"; make_tokens "$tokens" NewAlpha
out="$(run_validator rotation 0 "$FIX/rotation.identity-tokens.jsonl" "$tokens")"
assert_jq "$out" '.success == true and .rotation_count == 1 and .identity_chain_max_length == 1' "rotation_tuple_json"
case_ok "case_2_stable_rotation"

tokens="$TMP/missing-pred-tokens"; make_tokens "$tokens" NewAlpha
out="$(run_validator missing-predecessor 1 "$FIX/missing-predecessor.identity-tokens.jsonl" "$tokens")"
assert_jq "$out" '.success == false and (.drift_types | index("missing_predecessor"))' "missing_predecessor_drift"
case_ok "case_3_missing_predecessor"

tokens="$TMP/duplicate-tokens"; make_tokens "$tokens" SharedAlpha
out="$(run_validator duplicate 1 "$FIX/duplicate-current.identity-tokens.jsonl" "$tokens")"
assert_jq "$out" '.success == false and (.drift_types | index("duplicate_current_pointer"))' "duplicate_current_pointer_drift"
case_ok "case_4_duplicate_current_pointer"

tokens="$TMP/orphan-tokens"; make_tokens "$tokens" StableAlpha OrphanAlpha
out="$(run_validator orphan 1 "$FIX/stable.identity-tokens.jsonl" "$tokens")"
assert_jq "$out" '.success == false and (.drift_types | index("orphan_token"))' "orphan_token_drift"
case_ok "case_5_orphan_token"

out="$TMP/malformed-tuple.json"
set +e
"$SCRIPT" --identity-tokens "$FIX/stable.identity-tokens.jsonl" --topology "$FIX/topology.jsonl" --token-dir "$tokens" --tuple badtuple --json >"$out"
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then case_ok "case_6_malformed_tuple"; else fail "case_6_malformed_tuple rc=$rc"; fi

if [[ -x "$HOOK" ]]; then
  assert_hook_warns "case_7_hook_warns_hardcoded_name" '{"tool_name":"Bash","tool_response":{"stdout":"DONE x agent_name=RubyCreek"}}' warn
  case_pass=$((case_pass + 1))
  assert_hook_warns "hook_allows_tuple_proof" '{"tool_name":"Bash","tool_response":{"stdout":"DONE x agent_name=RubyCreek identity_primary_key=flywheel:1:/repo"}}' allow
else
  fail "case_7_hook_warns_hardcoded_name missing hook"
fi

printf 'Identity stability tuple cases: %s/7 passed\n' "$case_pass"
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$case_pass" -eq 7 && "$fail_count" -eq 0 ]]
