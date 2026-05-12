#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orch-handshakes-never-gate-on-joshua-gate.sh"
HOOK="$HOME/.claude/hooks/flywheel-orch-handshakes-never-gate-on-joshua-gate.sh"
DETECTOR="$ROOT/.flywheel/scripts/memory-rule-gate-parity-detector.sh"
MEMORY="$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_handshakes_never_gate_on_joshua.md"
export MEMORY
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-handshakes-never-gate.XXXXXX")"
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

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
bash -n "$HOOK" && pass "hook_syntax" || fail "hook_syntax"
"$SCRIPT" --info --json | jq -e '.rule_id == "orch-handshakes-never-gate-on-joshua" and .mode == "advisory"' >/dev/null && pass "info_shape" || fail "info_shape"
"$SCRIPT" --examples >/dev/null && pass "examples" || fail "examples"

"$SCRIPT" --check-text "Agent Mail contact approval fallback Option C: ask Joshua to approve the orch handshake." --json >"$TMP/warn.json"
assert_jq "$TMP/warn.json" '.decision == "warn" and (.reason | contains("orch-handshakes-never-gate-on-joshua"))' "gate_catches_joshua_gated_handshake"

"$SCRIPT" --check-text "Agent Mail contact approval fallback Option C: file-based sidechannel, no Joshua approval." --json >"$TMP/allow.out"
if [[ ! -s "$TMP/allow.out" ]]; then
  pass "gate_allows_file_sidechannel"
else
  fail "gate_allows_file_sidechannel"
  cat "$TMP/allow.out" >&2
fi

jq -nc --arg text "Agent Mail contact approval fallback Option C: ask Joshua to approve the orch handshake." '{transcript:$text}' \
  | "$HOOK" --json >"$TMP/hook.json"
assert_jq "$TMP/hook.json" '.decision == "warn"' "hook_wrapper_warns"

MEMORY_RULE_GATE_PARITY_LEDGER="$TMP/parity-ledger.jsonl" \
  "$DETECTOR" check --memory-dir "$(dirname "$MEMORY")" --json >"$TMP/parity.json"
assert_jq "$TMP/parity.json" '.rules[] | select(.rule_id == "orch-handshakes-never-gate-on-joshua" and .classification == "WIRED" and .evidence_count >= 3)' "parity_detector_marks_rule_wired"
assert_jq "$TMP/parity.json" 'all(.unwired_rules[]?; .memory_path != env.MEMORY)' "target_memory_not_unwired"

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
