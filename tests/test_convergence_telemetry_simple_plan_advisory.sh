#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
EMITTER="$ROOT/.flywheel/scripts/emit-polish-round-telemetry.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/convergence-telemetry-simple.XXXXXX")"

cleanup() {
  find "$TMP" -type f -delete 2>/dev/null || true
  find "$TMP" -depth -type d -empty -delete 2>/dev/null || true
}
trap cleanup EXIT

pass_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    printf 'FAIL %s\n' "$label" >&2
    jq . "$file" >&2 || true
    exit 1
  fi
}

make_pack() {
  local pack="$1"
  mkdir -p "$pack"
  jq -nc '{bead_id:"fixture",acceptance_criteria:[]}' >"$pack/spec.json"
  jq -nc '{evidence_items:[{path:"fixture",claim:"fixture evidence"}]}' >"$pack/evidence.json"
  jq -nc '{compliance_score:744,findings:[]}' >"$pack/compliance.json"
  jq -nc '{theater_signals:[]}' >"$pack/theater.json"
  jq -nc '{test_depth:"fixture"}' >"$pack/test_depth.json"
  jq -nc '{convergence:{streak:2}}' >"$pack/manifest.json"
  printf '# Scorecard\n\n**Score: 744/1000**\n' >"$pack/scorecard.md"
  printf '# Compliance Report\n\nFixture pack.\n' >"$pack/REPORT.md"
}

write_state() {
  local repo="$1" slug="$2" pack="$3"
  mkdir -p "$repo/.flywheel/plans/$slug"
  jq -nc \
    --arg slug "$slug" \
    --arg pack "$pack" \
    '{
      slug:$slug,
      current_phase:"polish",
      audit_disposition:"auto_advance",
      quality_bar_passed:false,
      convergence_streak:2,
      total_beads_in_dag:2,
      audit_findings_count:1,
      audit_findings_by_severity:{critical:0,high:1,medium:0,low:0},
      quality_bar_evidence:[{
        compliance_pack_path:$pack,
        compliance_score:744,
        compliance_threshold:700,
        convergence_streak:2,
        graded_at:"2026-05-07T22:00:00Z"
      }],
      schema_version:4
    }' >"$repo/.flywheel/plans/$slug/STATE.json"
}

write_delta() {
  local path="$1" wizard="$2" round="$3" body="$4"
  jq -nc \
    --arg wizard "$wizard" \
    --argjson round "$round" \
    --argjson deltas "$body" \
    '{wizard:$wizard,round:$round,deltas:$deltas,ts:"2026-05-07T22:00:00Z"}' >"$path"
}

repo="$TMP/repo"
slug="simple-advisory"
pack="$repo/.flywheel/plans/$slug/compliance-pack"
mkdir -p "$repo/.flywheel/plans/$slug"
make_pack "$pack"
write_state "$repo" "$slug" "$pack"

write_delta "$TMP/r1.json" wizard-A 1 '[{"op":"ADD","kind":"risk","id":"R2","content":"Late risk on a simple plan.","rationale":"Simple plans record but do not block on telemetry."}]'
python3 "$EMITTER" --repo "$repo" --plan-slug "$slug" --round 1 --delta-stream "$TMP/r1.json" --open-findings-after 1 --json >"$TMP/emitter.out"
assert_jq "$repo/.flywheel/plans/$slug/05-POLISH-r1.json" '.deltas.adds == 1 and .stability.no_new_deltas == false' "simple_artifact_emitted"

QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$TMP/contract.jsonl" "$GATE" --repo "$repo" --plan-slug "$slug" --json >"$TMP/gate.out"
assert_jq "$TMP/gate.out" '.decision == "pass" and .convergence_telemetry_required == false and .convergence_telemetry_status == "advisory"' "simple_plan_telemetry_advisory"

printf 'OK convergence telemetry simple advisory tests pass=%s/2\n' "$pass_count"
