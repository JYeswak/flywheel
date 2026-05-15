#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RECEIPT="$ROOT/.flywheel/evidence/flywheel-4vfa/flagship-onboarding-proof-20260515T070116Z.json"
CROSSLINK="$ROOT/.flywheel/evidence/flywheel-6kew/flagship-onboarding-proof-ref-20260515T070116Z.json"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

if [[ -f "$RECEIPT" ]]; then
  pass "receipt exists"
else
  fail "receipt exists"
fi

if [[ -f "$CROSSLINK" ]]; then
  pass "flagship crosslink exists"
else
  fail "flagship crosslink exists"
fi

assert_jq "$RECEIPT" '.schema_version == "flywheel.flagship_onboarding_proof.v2.sanitized"' "receipt schema is v2 sanitized"
assert_jq "$RECEIPT" '.bead == "flywheel-4vfa" and .flagship_anchor == "flywheel-6kew"' "receipt links bead and flagship anchor"
assert_jq "$RECEIPT" '.status == "pass" and .under_30min == true and .elapsed_seconds < 1800' "timed proof is under 30 minutes"
assert_jq "$RECEIPT" '(.commands | length) >= 6 and (.commands[] | contains("<fixture>"))' "commands are recorded with fixture redaction"
assert_jq "$RECEIPT" '(.client_doctrine_path | index("AGENTS.md")) and (.client_doctrine_path | index("README.md")) and (.client_doctrine_path | index(".flywheel/MISSION.md")) and (.client_doctrine_path | index(".flywheel/GOAL.md")) and (.client_doctrine_path | index(".flywheel/STATE.md"))' "client doctrine path is complete"
assert_jq "$RECEIPT" '.generated_artifacts.agents_md_exists == true and .generated_artifacts.mission_exists == true and .generated_artifacts.goal_exists == true and .generated_artifacts.state_exists == true' "generated artifact flags are present"
assert_jq "$RECEIPT" '.dry_run_boundary.no_hand_roll_create_attach == true and (.dry_run_boundary.mutating_ntm_commands_skipped | length) == 3' "dry-run boundary records skipped mutations"
assert_jq "$RECEIPT" '(.notes | join(" ") | test("excludes raw shell/completion output"))' "receipt excludes raw local command output"
assert_jq "$CROSSLINK" '.status == "pass" and .flagship_anchor == "flywheel-6kew" and .bead == "flywheel-4vfa" and (.proof_ref | test("flagship-onboarding-proof"))' "crosslink points flagship criterion at proof"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
