#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULE="$ROOT/.flywheel/rules/L113-L162-substrate-class-classifier-before-protection-halt-mandatory.md"
RULE_MANIFEST="$ROOT/.flywheel/rules/MANIFEST.json"
SUBSTRATE_MANIFEST="$ROOT/.flywheel/security/v1/substrate-class-manifest.json"
DOCTRINE="$ROOT/.flywheel/doctrine/substrate-class-classifier.md"
MISSION="$ROOT/.flywheel/MISSION.md"

pass_count=0
fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

require_file() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then pass "$label"; else fail "$label"; fi
}

require_rg() {
  local pattern="$1" path="$2" label="$3"
  if rg -q "$pattern" "$path"; then pass "$label"; else fail "$label"; fi
}

require_jq() {
  local expr="$1" path="$2" label="$3"
  if jq -e "$expr" "$path" >/dev/null; then pass "$label"; else fail "$label"; fi
}

require_file "$RULE" "L162 rule file exists"
require_rg '^id: L162$' "$RULE" "L162 rule declares canonical id"
require_rg '^status: long_term$' "$RULE" "L162 rule is long_term"
require_rg '^trauma_class: protection-mechanism-self-blindness$' "$RULE" "L162 rule declares trauma class"
require_rg 'Donella Meadows' "$RULE" "L162 rule cites Donella Meadows"
require_rg 'N=3 saturation' "$RULE" "L162 rule records N=3 saturation"
require_rg 'UNKNOWN.*halt|Unknown artifacts remain default-deny' "$RULE" "L162 rule preserves default-deny unknown behavior"

require_jq '
  .rule_count >= 113 and
  any(.rules[]; .id == "L162" and .order == 113 and .path == ".flywheel/rules/L113-L162-substrate-class-classifier-before-protection-halt-mandatory.md" and .status == "long_term" and .trauma_class == "protection-mechanism-self-blindness")
' "$RULE_MANIFEST" "rules manifest registers L162"

for surface in "$ROOT/AGENTS.md" "$ROOT/.flywheel/AGENTS-CANONICAL.md" "$ROOT/templates/flywheel-install/AGENTS.md"; do
  rel="${surface#"$ROOT/"}"
  require_rg 'L162 — SUBSTRATE-CLASS-CLASSIFIER-BEFORE-PROTECTION-HALT-MANDATORY' "$surface" "surface $rel indexes L162"
done

require_jq '
  .substrate_classes.production.protection_behavior == "full_protection" and
  (.substrate_classes.protection.protection_behavior | test("self_exempt")) and
  (.substrate_classes["test-fixture"].protection_behavior | test("suppressed_match_event_continue")) and
  (.substrate_classes["self-documentation"].protection_behavior | test("read_only")) and
  (.substrate_classes["audit-ledger"].protection_behavior | test("self_exempt"))
' "$SUBSTRATE_MANIFEST" "substrate manifest defines required class behaviors"

require_jq '
  (.test_fixture_paths | index(".flywheel/tests/fixtures/ntm-scrub-secret-scan/secret-bank.txt")) and
  (.protection_paths | index(".flywheel/security/v1/substrate-class-manifest.json")) and
  (.audit_ledger_paths | index(".flywheel/last_closeout_receipt.json"))
' "$SUBSTRATE_MANIFEST" "substrate manifest carries L162 path evidence"

require_jq '
  (._l_rule_candidate | test("L162")) and
  (._promotion_threshold | test("N=3 SATURATION reached 2026-05-14")) and
  any(._promotion_history[]; test("secret-bank.txt"))
' "$SUBSTRATE_MANIFEST" "substrate manifest records N=3 promotion truth"

require_rg '\*\*L-rule:\*\* L162 .*N=3 reached 2026-05-14' "$DOCTRINE" "doctrine names promoted L162"
require_rg 'canonical L162 promotion' "$DOCTRINE" "doctrine records canonical L162 promotion"
require_rg 'Donella Meadows' "$DOCTRINE" "doctrine cites Donella Meadows"
require_rg 'L-rule: L162 substrate-class classifier before protection halt mandatory' "$MISSION" "mission cross-reference names promoted L162"

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
