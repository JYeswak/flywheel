#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HANDOFF="$ROOT/.flywheel/handoffs/skillos-meadows-mission-goal-lock-in-20260515.md"
RECEIPT="$ROOT/.flywheel/evidence/flywheel-7crg/closeout-receipt-20260515T0322Z.json"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

require_file() {
  local path="$1" label="$2"
  [[ -f "$path" ]] && pass "$label" || fail "$label"
}

require_text() {
  local file="$1" pattern="$2" label="$3"
  grep -F -- "$pattern" "$file" >/dev/null && pass "$label" || fail "$label"
}

require_file "$HANDOFF" "handoff_exists"
require_text "$HANDOFF" "STOCK: skills and packs that meet the Jeff-derived doctrine/code-pattern bar." "stock_named"
require_text "$HANDOFF" "Meadows #2 Paradigms" "meadows_paradigm_cited"
require_text "$HANDOFF" "Meadows #3 Goals" "meadows_goal_cited"
require_text "$HANDOFF" "Meadows #5 Rules" "meadows_rule_cited"
require_text "$HANDOFF" "idempotency-key-fail-closed" "adopt_pattern_idempotency"
require_text "$HANDOFF" "testing-fixture-conventions" "adopt_pattern_fixture"
require_text "$HANDOFF" "lock-file-convention" "adopt_pattern_lock"
require_text "$HANDOFF" "frontmatter-validation" "adopt_pattern_frontmatter"
require_text "$HANDOFF" "skillos-skill-author-checklist-jeff-doctrine" "followup_bead_spec"
require_text "$HANDOFF" "flywheel-hcazt" "handoff_bead_id"
require_text "$HANDOFF" "Do not apply from Flywheel" "ownership_boundary"

require_file "$RECEIPT" "receipt_exists"
jq -e '
  .schema_version == "flywheel.bead_closeout_receipt.v1"
  and .bead_id == "flywheel-7crg"
  and .handoff_bead_id == "flywheel-hcazt"
  and .skillos_mutated == false
  and (.validation[] | select(.command == "bash tests/skillos-meadows-lock-in-handoff.sh" and .status == "pass"))
' "$RECEIPT" >/dev/null && pass "receipt_schema" || fail "receipt_schema"

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
