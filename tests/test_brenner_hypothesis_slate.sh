#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/brenner-hypothesis-slate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

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
  local repo="$1" slug="$2" slate_mode="$3"
  local pack
  mkdir -p "$repo/.flywheel/plans/$slug"
  pack="$(make_compliance_pack "$repo" "$slug" 742)"
  jq -nc \
    --arg slug "$slug" \
    --arg pack "$pack" \
    --arg slate_mode "$slate_mode" \
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
        compliance_score:742,
        compliance_threshold:700,
        convergence_streak:2,
        graded_at:"2026-05-07T20:30:00Z"
      }],
      schema_version:5
    }
    | if $slate_mode == "valid" then
        . + {
          hypotheses:[
            {
              id:"H1",
              claim:"The native plan path is sufficient if the close gate can parse Phase 2 outputs.",
              kill_condition:"A schema v5 plan with valid Phase 2 fields still fails the close gate.",
              decisive_test:"Run quality-bar-close-gate.sh against this fixture and require PASS."
            },
            {
              id:"H_alt",
              claim:"Both template-only and validator-only approaches are insufficient.",
              kill_condition:"Either the template or the validator alone enforces every required field.",
              decisive_test:"Remove one surface and confirm the missing-slate fixture fails."
            }
          ],
          third_alternative:{
            id:"H_alt",
            reason:"The plan contract needs both author prompt pressure and close-time enforcement."
          },
          acceptance_when_killed:{
            all_killed:"plan = REJECT",
            exactly_one_survives:"plan = COMMIT to that hypothesis",
            two_or_more_survive:"plan = re-decompose with sharper kill_conditions"
          }
        }
      elif $slate_mode == "one_hypothesis" then
        . + {
          hypotheses:[
            {
              id:"H1",
              claim:"A single hypothesis is enough.",
              kill_condition:"The validator requires alternatives.",
              decisive_test:"Run the close gate."
            }
          ],
          acceptance_when_killed:{
            all_killed:"plan = REJECT",
            exactly_one_survives:"plan = COMMIT to that hypothesis",
            two_or_more_survive:"plan = re-decompose with sharper kill_conditions"
          }
        }
      else
        .
      end' >"$repo/.flywheel/plans/$slug/STATE.json"
}

repo="$TMP/repo"
ledger="$TMP/quality-bar-close-gate.jsonl"
contract="$TMP/substrate-loop-contract.jsonl"
mkdir -p "$repo/.flywheel/plans"

bash -n "$SCRIPT"
jq empty "$ROOT/templates/flywheel-install/polish-gate/v1/plan-phase2-refine.schema.json"

write_state_v5 "$repo" missing-slate missing
expect_rc missing_slate 1 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug missing-slate --json
assert_jq "$TMP/missing_slate.out" '.decision == "fail" and .hypothesis_slate_valid == "no" and (.reasons | index("hypothesis_slate_invalid"))' "fixture_without_slate_fails"

write_state_v5 "$repo" valid-slate valid
expect_rc valid_slate 0 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug valid-slate --json
assert_jq "$TMP/valid_slate.out" '.decision == "pass" and .hypothesis_slate_valid == "yes" and .hypothesis_slate_required == true' "fixture_with_valid_slate_passes"

write_state_v5 "$repo" one-hypothesis one_hypothesis
expect_rc one_hypothesis 1 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug one-hypothesis --json
assert_jq "$TMP/one_hypothesis.out" '.decision == "fail" and .hypothesis_slate_valid == "no" and (.hypothesis_slate_errors | index("hypothesis_count_not_2_to_5")) and (.hypothesis_slate_errors | index("third_alternative_missing"))' "fixture_one_hypothesis_fails"

printf 'OK brenner hypothesis slate tests pass=%s/3\n' "$pass_count"
