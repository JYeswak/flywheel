#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ev-backward-compat.XXXXXX")"
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
  printf '# Audit\n\nNo EV anchors here.\n' >"$repo/.flywheel/plans/$slug/03-AUDIT-FINDINGS.md"
  jq -nc '{evidence_items:[{path:"fixture",claim:"old-format evidence"}]}' >"$pack/evidence.json"
  jq -nc '{compliance_score:744,findings:[]}' >"$pack/compliance.json"
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
    hypothesis_slate:[
      {id:"H1",strategy:"Old compliance packs keep passing.",kill_condition:"Old-format pack fails from missing evidence array.",is_third_alternative:false,status:"active",killed_by:null,adopted_at_phase:null},
      {id:"H2",strategy:"EV evidence is mandatory everywhere.",kill_condition:"The additive field remains optional.",is_third_alternative:true,status:"active",killed_by:null,adopted_at_phase:null}
    ]
  }' >"$repo/.flywheel/plans/$slug/STATE.json"
}

repo="$TMP/repo"
slug="ev-backward-compatible"
ledger="$TMP/quality-bar-close-gate.jsonl"
contract="$TMP/substrate-loop-contract.jsonl"
mkdir -p "$repo/.flywheel/plans/$slug"
write_fixture "$repo" "$slug"

bash -n "$SCRIPT"
expect_rc old_pack 0 env QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER="$contract" "$SCRIPT" --repo "$repo" --ledger "$ledger" --plan-slug "$slug" --json
assert_jq "$TMP/old_pack.out" '.decision == "pass" and .ev_anchor_status == "not_present" and .ev_evidence_rows_count == 0' "old_format_pack_still_passes"

printf 'OK compliance pack backward compat tests pass=%s/1\n' "$pass_count"
