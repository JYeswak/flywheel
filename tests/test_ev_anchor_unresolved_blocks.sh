#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ev-anchor-unresolved.XXXXXX")"
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

write_fixture() {
  local repo="$1" slug="$2" pack="$repo/.flywheel/plans/$slug/compliance-packs/$slug"
  mkdir -p "$pack"
  printf '%s\n' "alpha supports claim" >"$repo/.flywheel/plans/$slug/source.md"
  printf '# Audit\n\nThe audit cites one missing anchor [EV-099].\n' >"$repo/.flywheel/plans/$slug/03-AUDIT-FINDINGS.md"
  jq -nc --arg source "$repo/.flywheel/plans/$slug/source.md" '{evidence:[{ev_id:"EV-001",source:($source + ":1"),excerpt:"alpha supports claim",relation:"supports",target_finding_id:"F-001"}]}' >"$pack/evidence.json"
  jq -nc '{compliance_score:744,findings:[{id:"F-001",status:"active"}]}' >"$pack/compliance.json"
  jq -nc --arg slug "$slug" '{bead_id:$slug,acceptance_criteria:[]}' >"$pack/spec.json"
  jq -nc '{theater_signals:[]}' >"$pack/theater.json"
  jq -nc '{test_depth:"fixture"}' >"$pack/test_depth.json"
  jq -nc '{convergence:{streak:2}}' >"$pack/manifest.json"
  printf '# Scorecard\n\n**Score: 744/1000**\n' >"$pack/scorecard.md"
  printf '# Compliance Report\n\nFixture pack.\n' >"$pack/REPORT.md"
  jq -nc --arg slug "$slug" --arg pack "$pack" '{
    slug:$slug,current_phase:"polish",audit_disposition:"auto_advance",quality_bar_passed:false,
    convergence_streak:2,audit_findings_by_severity:{critical:0,high:0,medium:0,low:0},
    quality_bar_evidence:[{artifact:"fixture",compliance_pack_path:$pack,compliance_score:744,compliance_threshold:700,convergence_streak:2,graded_at:"2026-05-07T20:30:00Z"}],
    schema_version:5,
    hypotheses:[
      {id:"H1",claim:"Missing EV anchors block close.",kill_condition:"A missing anchor passes.",decisive_test:"Run close gate."},
      {id:"H_alt",claim:"Missing anchors can be inferred.",kill_condition:"The validator requires exact anchors.",decisive_test:"Run close gate."}
    ],
    third_alternative:{id:"H_alt",reason:"Missing relation edges cannot be inferred from prose."},
    acceptance_when_killed:{all_killed:"plan = REJECT",exactly_one_survives:"plan = COMMIT to that hypothesis",two_or_more_survive:"plan = re-decompose with sharper kill_conditions"}
  }' >"$repo/.flywheel/plans/$slug/STATE.json"
}

repo="$TMP/repo"
slug="ev-anchor-missing"
ledger="$TMP/quality-bar-close-gate.jsonl"
contract="$TMP/substrate-loop-contract.jsonl"
mkdir -p "$repo/.flywheel/plans/$slug"
write_fixture "$repo" "$slug"

bash -n "$SCRIPT"
expect_rc ev_missing 1 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug "$slug" --json
assert_jq "$TMP/ev_missing.out" '.decision == "fail" and (.reasons | index("ev_anchor_unresolved")) and (.ev_anchor_missing | index("EV-099"))' "missing_ev_anchor_blocks_close"

printf 'OK EV anchor unresolved tests pass=%s/1\n' "$pass_count"
