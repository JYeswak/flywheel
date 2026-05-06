#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agentmail-identity-canonical-validator.sh"
FIX="$ROOT/.flywheel/tests/fixtures/agentmail-identity-canonical"
HOOK="$HOME/.claude/hooks/flywheel-orch-agentmail-identity-canonical-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agentmail-identity-canonical.XXXXXX")"
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
  local name="$1" expected_rc="$2" topology="$3" tokens="$4" identity="${5:-$FIX/canonical.identity-tokens.jsonl}"
  local out="$TMP/$name.json" rc
  set +e
  "$SCRIPT" --topology "$topology" --identity-tokens "$identity" --token-dir "$tokens" --strict --json >"$out"
  rc=$?
  set -e
  if [[ "$rc" -eq "$expected_rc" ]]; then
    printf '%s\n' "$out"
    return 0
  fi
  fail "$name rc expected=$expected_rc actual=$rc"
  jq . "$out" >&2 || true
  printf '%s\n' "$out"
  return 1
}

bash -n "$SCRIPT" && pass "validator_syntax" || fail "validator_syntax"
"$SCRIPT" --info --json | jq -e '.read_only == true and (.canonical_cli | index("--apply"))' >/dev/null && pass "validator_info" || fail "validator_info"
"$SCRIPT" --examples >/dev/null && pass "validator_examples" || fail "validator_examples"
if [[ -x "$HOOK" ]]; then bash -n "$HOOK" && pass "hook_syntax" || fail "hook_syntax"; fi

tokens="$TMP/canonical-tokens"; make_tokens "$tokens" AlphaIdentity BetaIdentity
out="$(run_validator canonical 0 "$FIX/canonical.topology.jsonl" "$tokens")"
assert_jq "$out" '.success == true and .status == "canonical" and .drift_count == 0' "canonical_state_json"
case_ok "case_1_canonical_state"

tokens="$TMP/missing-tokens"; make_tokens "$tokens" AlphaIdentity
out="$(run_validator missing-token 1 "$FIX/missing-token.topology.jsonl" "$tokens")"
assert_jq "$out" '.success == false and (.drift_types | index("missing_token"))' "missing_token_drift"
case_ok "case_2_missing_token"

tokens="$TMP/orphan-tokens"; make_tokens "$tokens" AlphaIdentity OrphanIdentity
out="$(run_validator orphan-token 1 "$FIX/orphan-token.topology.jsonl" "$tokens")"
assert_jq "$out" '.success == false and (.drift_types | index("orphan_token"))' "orphan_token_drift"
case_ok "case_3_orphan_token"

tokens="$TMP/non-append-tokens"; make_tokens "$tokens" AlphaIdentity
out="$(run_validator non-append 1 "$FIX/orphan-token.topology.jsonl" "$tokens" "$FIX/non-append.identity-tokens.jsonl")"
assert_jq "$out" '.success == false and (.drift_types | index("non_append_only"))' "non_append_only_drift"
case_ok "case_4_non_append_only"

tokens="$TMP/duplicate-tokens"; make_tokens "$tokens" SharedIdentity
out="$(run_validator duplicate-identity 1 "$FIX/duplicate-identity.topology.jsonl" "$tokens")"
assert_jq "$out" '.success == false and (.drift_types | index("duplicate_identity"))' "duplicate_identity_drift"
case_ok "case_5_duplicate_identity"

tokens="$TMP/apply-tokens"; make_tokens "$tokens" AlphaIdentity BetaIdentity
before_topology="$(shasum -a 256 "$FIX/canonical.topology.jsonl" | awk '{print $1}')"
before_identity="$(shasum -a 256 "$FIX/canonical.identity-tokens.jsonl" | awk '{print $1}')"
before_tokens="$(find "$tokens" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')"
out="$TMP/apply.json"
"$SCRIPT" --topology "$FIX/canonical.topology.jsonl" --identity-tokens "$FIX/canonical.identity-tokens.jsonl" --token-dir "$tokens" --strict --apply --json >"$out"
after_topology="$(shasum -a 256 "$FIX/canonical.topology.jsonl" | awk '{print $1}')"
after_identity="$(shasum -a 256 "$FIX/canonical.identity-tokens.jsonl" | awk '{print $1}')"
after_tokens="$(find "$tokens" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')"
assert_jq "$out" '.success == true and .apply == true and .read_only_verified == true' "apply_reports_read_only"
if [[ "$before_topology:$before_identity:$before_tokens" == "$after_topology:$after_identity:$after_tokens" ]]; then
  case_ok "case_6_apply_no_mutation"
else
  fail "case_6_apply_no_mutation"
fi

printf 'AgentMail identity canonical cases: %s/6 passed\n' "$case_pass"
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$case_pass" -eq 6 && "$fail_count" -eq 0 ]]
