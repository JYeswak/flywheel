#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ev-anchor-resolution.XXXXXX")"
trap 'find "$TMP" -depth -mindepth 1 -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

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

make_pack() {
  local repo="$1" slug="$2" pack="$repo/.flywheel/plans/$slug/compliance-packs/$slug"
  mkdir -p "$pack"
  jq -nc --arg slug "$slug" '{bead_id:$slug,acceptance_criteria:[]}' >"$pack/spec.json"
  jq -nc --arg source "$repo/.flywheel/plans/$slug/source.md" '{
    evidence:[
      {ev_id:"EV-001",source:($source + ":1"),excerpt:"alpha supports claim",relation:"supports",target_finding_id:"F-001"},
      {ev_id:"EV-002",source:($source + ":2"),excerpt:"beta informs claim",relation:"informs",target_finding_id:"F-001"},
      {ev_id:"EV-003",source:($source + ":3"),excerpt:"gamma refutes closed finding",relation:"refutes",target_finding_id:"F-002"}
    ],
    evidence_items:[{path:"fixture",claim:"fixture compliance evidence"}]
  }' >"$pack/evidence.json"
  jq -nc '{compliance_score:744,findings:[{id:"F-001",status:"active"},{id:"F-002",status:"closed"}]}' >"$pack/compliance.json"
  jq -nc '{theater_signals:[]}' >"$pack/theater.json"
  jq -nc '{test_depth:"fixture"}' >"$pack/test_depth.json"
  jq -nc '{convergence:{streak:2}}' >"$pack/manifest.json"
  printf '# Scorecard\n\n**Score: 744/1000**\n' >"$pack/scorecard.md"
  printf '# Compliance Report\n\nFixture pack.\n' >"$pack/REPORT.md"
  printf '%s\n' "$pack"
}

write_plan() {
  local repo="$1" slug="$2" pack="$3"
  mkdir -p "$repo/.flywheel/plans/$slug"
  printf '%s\n%s\n%s\n' "alpha supports claim" "beta informs claim" "gamma refutes closed finding" >"$repo/.flywheel/plans/$slug/source.md"
  printf '# Audit\n\nFinding F-001 is supported [EV-001] and informed [EV-002]. Closed F-002 has refuting evidence [EV-003].\n' >"$repo/.flywheel/plans/$slug/03-AUDIT-FINDINGS.md"
  jq -nc --arg slug "$slug" --arg pack "$pack" '{
    slug:$slug,current_phase:"polish",audit_disposition:"auto_advance",quality_bar_passed:false,
    convergence_streak:2,audit_findings_by_severity:{critical:0,high:0,medium:0,low:0},
    quality_bar_evidence:[{artifact:"fixture",compliance_pack_path:$pack,compliance_score:744,compliance_threshold:700,convergence_streak:2,graded_at:"2026-05-07T20:30:00Z"}],
    schema_version:5,
    hypotheses:[
      {id:"H1",claim:"EV anchors resolve.",kill_condition:"Resolved anchors fail close.",decisive_test:"Run close gate."},
      {id:"H_alt",claim:"Plain compliance packs are enough.",kill_condition:"Relations are required for anchor audits.",decisive_test:"Run close gate."}
    ],
    third_alternative:{id:"H_alt",reason:"Typed evidence relations make the audit graph queryable."},
    acceptance_when_killed:{all_killed:"plan = REJECT",exactly_one_survives:"plan = COMMIT to that hypothesis",two_or_more_survive:"plan = re-decompose with sharper kill_conditions"}
  }' >"$repo/.flywheel/plans/$slug/STATE.json"
}

repo="$TMP/repo"
slug="ev-anchor-pass"
ledger="$TMP/quality-bar-close-gate.jsonl"
contract="$TMP/substrate-loop-contract.jsonl"
mkdir -p "$repo/.flywheel/plans/$slug"
pack="$(make_pack "$repo" "$slug")"
write_plan "$repo" "$slug" "$pack"

bash -n "$SCRIPT"
expect_rc ev_pass 0 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug "$slug" --json
assert_jq "$TMP/ev_pass.out" '.decision == "pass" and .ev_anchor_status == "pass" and .ev_anchor_cited_count == 3 and .ev_evidence_rows_count == 3' "ev_anchors_resolve"

printf 'OK EV anchor resolution tests pass=%s/1\n' "$pass_count"
