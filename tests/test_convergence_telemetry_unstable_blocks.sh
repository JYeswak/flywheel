#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
EMITTER="$ROOT/.flywheel/scripts/emit-polish-round-telemetry.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/convergence-telemetry-block.XXXXXX")"

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

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  local got=$?
  set -e
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL %s expected=%s got=%s\n' "$name" "$want" "$got" >&2
    sed -n '1,120p' "$TMP/$name.out" >&2 || true
    sed -n '1,120p' "$TMP/$name.err" >&2 || true
    exit 1
  fi
  pass "$name"
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
      total_beads_in_dag:9,
      audit_findings_count:5,
      audit_findings_by_severity:{critical:0,high:5,medium:0,low:0},
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
slug="complex-unstable"
pack="$repo/.flywheel/plans/$slug/compliance-pack"
mkdir -p "$repo/.flywheel/plans/$slug"
make_pack "$pack"
write_state "$repo" "$slug" "$pack"

write_delta "$TMP/r1.json" wizard-A 1 '[]'
write_delta "$TMP/r2.json" wizard-B 2 '[{"op":"KILL","kind":"test","id":"T1","reason":"Stale test.","evidence":"Round two removes it."}]'
write_delta "$TMP/r3.json" wizard-A 3 '[{"op":"ADD","kind":"risk","id":"R2","content":"New risk surfaced late.","rationale":"Late expansion means the plan is not stable."}]'

python3 "$EMITTER" --repo "$repo" --plan-slug "$slug" --round 1 --delta-stream "$TMP/r1.json" --open-findings-after 2 --json >/dev/null
python3 "$EMITTER" --repo "$repo" --plan-slug "$slug" --round 2 --delta-stream "$TMP/r2.json" --open-findings-after 1 --json >/dev/null
python3 "$EMITTER" --repo "$repo" --plan-slug "$slug" --round 3 --delta-stream "$TMP/r3.json" --open-findings-after 2 --json >/dev/null

expect_rc gate_blocks 1 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$TMP/contract.jsonl" "$GATE" --repo "$repo" --plan-slug "$slug" --json
assert_jq "$TMP/gate_blocks.out" '.decision == "fail" and (.reasons | index("convergence_telemetry_unstable")) and .convergence_telemetry_status == "unstable" and .convergence_telemetry_break_round == 3' "unstable_latest_round_blocks"

printf 'OK convergence telemetry unstable tests pass=%s/2\n' "$pass_count"
