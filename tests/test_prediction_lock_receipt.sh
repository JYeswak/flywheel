#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/prediction-lock-receipt.XXXXXX")"
trap 'find "$TMP" -depth -mindepth 1 -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  local got=$?
  set -e
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL %s rc expected=%s got=%s\n' "$name" "$want" "$got" >&2
    cat "$TMP/$name.out" >&2 || true
    cat "$TMP/$name.err" >&2 || true
    exit 1
  fi
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    printf 'FAIL %s\n' "$label" >&2
    jq . "$file" >&2 || cat "$file" >&2
    exit 1
  fi
}

make_compliance_pack() {
  local repo="$1" slug="$2" score="$3"
  local pack="$repo/.flywheel/plans/$slug/compliance-packs/$slug"
  mkdir -p "$pack"
  jq -nc --arg slug "$slug" '{bead_id:$slug,acceptance_criteria:[]}' >"$pack/spec.json"
  jq -nc '{evidence_items:[{path:"fixture",claim:"fixture compliance evidence"}]}' >"$pack/evidence.json"
  jq -nc --argjson score "$score" '{compliance_score:$score,findings:[]}' >"$pack/compliance.json"
  jq -nc '{theater_signals:[]}' >"$pack/theater.json"
  jq -nc '{test_depth:"fixture"}' >"$pack/test_depth.json"
  jq -nc '{convergence:{streak:2}}' >"$pack/manifest.json"
  printf '# Scorecard\n\n**Score: %s/1000**\n' "$score" >"$pack/scorecard.md"
  printf '# Compliance Report\n\nFixture pack.\n' >"$pack/REPORT.md"
  printf '%s\n' "$pack"
}

write_state_v5() {
  local repo="$1" slug="$2" pack
  mkdir -p "$repo/.flywheel/plans/$slug"
  pack="$(make_compliance_pack "$repo" "$slug" 744)"
  jq -nc \
    --arg slug "$slug" \
    --arg pack "$pack" \
    '{
      slug:$slug,
      current_phase:"polish",
      audit_disposition:"auto_advance",
      quality_bar_passed:false,
      convergence_streak:2,
      audit_findings_by_severity:{critical:0,high:0,medium:0,low:0},
      quality_bar_evidence:[{
        artifact:"fixture",
        compliance_pack_path:$pack,
        compliance_score:744,
        compliance_threshold:700,
        convergence_streak:2,
        graded_at:"2026-05-07T20:30:00Z"
      }],
      schema_version:5,
      hypothesis_slate:[
        {
          id:"H1",
          strategy:"Prediction locks make Phase 2 hypotheses falsifiable.",
          kill_condition:"A mutated receipt can still pass the close gate.",
          is_third_alternative:false,
          status:"active",
          killed_by:null,
          adopted_at_phase:null
        },
        {
          id:"H2",
          strategy:"Compliance packs alone are enough to prevent post-hoc plan edits.",
          kill_condition:"A post-lock prediction mutation is detected without a receipt.",
          is_third_alternative:true,
          status:"active",
          killed_by:null,
          adopted_at_phase:null
        }
      ]
    }' >"$repo/.flywheel/plans/$slug/STATE.json"
}

repo="$TMP/repo"
slug="prediction-lock-happy"
ledger="$TMP/quality-bar-close-gate.jsonl"
contract="$TMP/substrate-loop-contract.jsonl"
predictions="$TMP/predictions.json"
mkdir -p "$repo/.flywheel/plans"

bash -n "$SCRIPT"
write_state_v5 "$repo" "$slug"
jq -nc '[
  "Phase 3 audit will reject any plan whose hypothesis slate lacks a third alternative.",
  "Phase 5 close will require a compliance pack with convergence streak >= 2.",
  "Prediction receipts will detect text edits made after Phase 2 convergence."
]' >"$predictions"

expect_rc lock_predictions 0 env \
  QUALITY_BAR_CLOSE_GATE_NOW="2026-05-07T21:00:00Z" \
  QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" \
  "$SCRIPT" --repo "$repo" lock-predictions --plan-slug "$slug" --predictions-file "$predictions" --applies-at-phase phase3 --apply --json
assert_jq "$TMP/lock_predictions.out" '.status == "pass" and .prediction_lock_count == 3 and .apply == true' "lock_command_reports_three_predictions"
assert_jq "$repo/.flywheel/plans/$slug/STATE.json" '.prediction_lock.locked_at == "2026-05-07T21:00:00Z" and (.predictions | length == 3) and all(.predictions[]; (.hash | test("^[0-9a-f]{64}$")))' "state_receipt_created_with_hashes"

expect_rc close_gate 0 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug "$slug" --json
assert_jq "$TMP/close_gate.out" '.decision == "pass" and .prediction_lock_status == "pass" and .prediction_lock_count == 3' "close_gate_accepts_matching_prediction_hashes"

printf 'OK prediction lock receipt tests pass=%s/3\n' "$pass_count"
