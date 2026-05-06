#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/quality-bar-close-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

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

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
    exit 1
  fi
}

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  local got=$?
  set -e
  if [[ "$got" -ne "$want" ]]; then
    fail "$name rc expected=$want got=$got"
    cat "$TMP/$name.out" >&2 || true
    cat "$TMP/$name.err" >&2 || true
    exit 1
  fi
}

make_state() {
  local repo="$1" slug="$2" phase="$3" quality="$4" jeff="$5" donella="$6" joshua="$7" composite="$8" critical="$9"
  mkdir -p "$repo/.flywheel/plans/$slug"
  jq -nc \
    --arg slug "$slug" \
    --arg phase "$phase" \
    --argjson quality "$quality" \
    --argjson jeff "$jeff" \
    --argjson donella "$donella" \
    --argjson joshua "$joshua" \
    --argjson composite "$composite" \
    --argjson critical "$critical" \
    '{
      slug:$slug,
      current_phase:$phase,
      audit_disposition:"auto_advance",
      quality_bar_passed:$quality,
      audit_findings_by_severity:{critical:$critical,high:0,medium:0,low:0},
      quality_bar_evidence:[{
        artifact:"fixture",
        jeff_score:$jeff,
        donella_score:$donella,
        joshua_score:$joshua,
        composite:$composite,
        graded_at:"2026-05-05T03:45:00Z"
      }],
      schema_version:3
    }' >"$repo/.flywheel/plans/$slug/STATE.json"
}

write_audit() {
  local repo="$1" slug="$2" jeff="$3" donella="$4" joshua="$5" composite="$6" critical="$7"
  cat >"$repo/.flywheel/plans/$slug/03-AUDIT-FINDINGS.md" <<EOF
# Audit Findings

jeff_score=$jeff
donella_score=$donella
joshua_score=$joshua
composite=$composite
critical_findings=$critical
EOF
}

repo="$TMP/repo"
ledger="$TMP/quality-bar-close-gate.jsonl"
contract="$TMP/substrate-loop-contract.jsonl"
mkdir -p "$repo/.flywheel/plans"

bash -n "$SCRIPT"
"$SCRIPT" --info --json | jq -e '.schema_version == "quality-bar-close-gate.v1"' >/dev/null
"$SCRIPT" --examples --json | jq -e '(.examples | length) >= 4' >/dev/null
"$SCRIPT" quickstart --json | jq -e '(.steps | length) >= 4' >/dev/null
"$SCRIPT" schema doctor --json | jq -e '.required | index("plan_state_quality_bar_pending_count")' >/dev/null
"$SCRIPT" completion bash | rg -q 'quality-bar-close-gate'

make_state "$repo" pass-plan polish true 9.6 9.7 9.6 9.64 0
write_audit "$repo" pass-plan 9.6 9.7 9.6 9.64 0
expect_rc pass_plan 0 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug pass-plan --json
assert_jq "$TMP/pass_plan.out" '.decision == "pass" and .result == "PASS" and .three_judges_evidence_present == true' "synthetic_pass_plan"

make_state "$repo" pending-plan polish true 9.6 9.6 9.6 9.6 0
expect_rc pending_plan 1 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug pending-plan --json
assert_jq "$TMP/pending_plan.out" '.decision == "pending" and (.reasons | index("audit_findings_missing"))' "synthetic_pending_missing_audit"

make_state "$repo" low-score-plan polish true 8.9 9.6 9.6 9.4 0
write_audit "$repo" low-score-plan 8.9 9.6 9.6 9.4 0
expect_rc low_score_plan 1 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug low-score-plan --json
assert_jq "$TMP/low_score_plan.out" '.decision == "fail" and (.reasons | index("jeff_score_below_9")) and (.reasons | index("composite_below_9_5"))' "synthetic_fail_low_score"

make_state "$repo" critical-plan polish true 9.6 9.6 9.6 9.6 1
write_audit "$repo" critical-plan 9.6 9.6 9.6 9.6 1
expect_rc critical_plan 1 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug critical-plan --json
assert_jq "$TMP/critical_plan.out" '.decision == "fail" and (.reasons | index("critical_findings_present"))' "synthetic_fail_critical_finding"

state_hash_before="$(shasum -a 256 "$repo/.flywheel/plans/pass-plan/STATE.json" | awk '{print $1}')"
expect_rc dry_run 0 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug pass-plan --dry-run --json
state_hash_after="$(shasum -a 256 "$repo/.flywheel/plans/pass-plan/STATE.json" | awk '{print $1}')"
if [[ "$state_hash_before" == "$state_hash_after" && ! -e "$ledger" ]]; then
  pass "dry_run_does_not_write_ledger_or_state"
else
  fail "dry_run_does_not_write_ledger_or_state"
  exit 1
fi

expect_rc apply_pass 0 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug pass-plan --apply --json
state_hash_after_apply="$(shasum -a 256 "$repo/.flywheel/plans/pass-plan/STATE.json" | awk '{print $1}')"
jq -e 'select(.schema_version == "quality-bar-close-gate.ledger.v1" and .plan_slug == "pass-plan" and .decision == "pass")' "$ledger" >/dev/null
"$SCRIPT" --repo "$repo" --ledger "$ledger" --contract-ledger "$contract" --doctor --json >"$TMP/doctor.out"
jq -e '.schema_version == "quality-bar-close-gate.doctor.v1" and .plan_state_quality_bar_pending_count == 1 and .plan_state_quality_bar_failed_count == 2 and .plan_state_quality_bar_passed_count >= 1' "$TMP/doctor.out" >/dev/null
jq -e 'select(.primitive_name == "quality-bar-close-gate" and .schema_version == "substrate-loop-contract.v1")' "$contract" >/dev/null
if [[ "$state_hash_before" == "$state_hash_after_apply" ]]; then
  pass "apply_writes_ledger_and_contract_not_state"
else
  fail "apply_writes_ledger_and_contract_not_state"
  exit 1
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAILED quality-bar-close-gate tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK quality-bar-close-gate tests pass=%s/6\n' "$pass_count"
