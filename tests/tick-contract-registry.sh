#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
REGISTRY="$ROOT/.flywheel/tick-contract-registry/v1/registry.json"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/tick-receipt.schema.json"

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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/tick-contract-registry.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

bash -n "$BIN" && pass "flywheel-loop syntax" || fail "flywheel-loop syntax"
jq empty "$REGISTRY" && pass "registry json valid" || fail "registry json valid"
jq empty "$SCHEMA" && pass "tick receipt schema json valid" || fail "tick receipt schema json valid"

assert_jq "$SCHEMA" '.properties.tick_contract and .properties.tick_contract_checks and .properties.tick_contract_graduation' "receipt schema exposes tick contract fields"
assert_jq "$REGISTRY" '.cadence_tiers.doctrine.interval == "12h" and .cadence_tiers.active_high.interval == "5m" and .cadence_tiers.active_normal.interval == "30m" and .cadence_tiers.inactive.interval == "manual"' "registry encodes cadence tiers"
assert_jq "$REGISTRY" 'all(.checks[]; has("owner_class") and has("source_rule") and has("default_mode") and has("failure_class") and has("producer") and has("measurement") and has("consumer") and has("promotion_path"))' "registry rows carry required fields"
assert_jq "$REGISTRY" '[.checks[] | select(.owner_class == "orchestrator" and .phase == "A")] | map(.id) | sort == ["autoloop-receipts-read","learn-review-when-unprocessed","worker-pane-state-verified"]' "registry includes Phase A orchestrator checks"
assert_jq "$REGISTRY" '[.checks[] | select(.owner_class == "worker" and .phase == "B")] | map(.id) | sort == ["commits-l52-formatted","modified-files-have-agent-mail-reservations","socraticode-k-at-least-10"]' "registry includes Phase B worker checks"

"$BIN" tick-contract --schema --json >"$TMP/command-schema.json"
assert_jq "$TMP/command-schema.json" '.cadence_tiers.doctrine.interval == "12h" and .cadence_tiers.active_high.interval == "5m" and .cadence_tiers.active_normal.interval == "30m"' "tick-contract command emits cadence tiers"
assert_jq "$TMP/command-schema.json" '(.check_registry_fields | index("promotion_path")) and (.receipt_fields | index("tick_contract_checks")) and (.checks | length) >= 16' "tick-contract command emits registry schema"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
