#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/three-q-surface-audit.py"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/three-q-surface-audit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

make_repo() {
  local repo="$TMP/repo"
  rm -rf "$repo"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/three-q-surface-registry/v1/fixtures" \
    "$repo/.flywheel/validation-receipts" "$repo/.flywheel/runtime/flywheel-loop" \
    "$repo/evidence" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  printf 'ok\n' >"$repo/evidence/complete.txt"
  cp "$PROBE" "$repo/.flywheel/scripts/three-q-surface-audit.py"
  cp "$ROOT/.flywheel/three-q-surface-registry/v1/fixtures/mixed-registry.json" "$repo/.flywheel/three-q-surface-registry/v1/registry.json"
  chmod +x "$repo/.flywheel/scripts/three-q-surface-audit.py"
  printf '%s\n' "$repo"
}

schema_out="$TMP/schema.json"
python3 "$PROBE" --schema --json >"$schema_out"
assert_jq "$schema_out" '.schema_version == "three-q-surface-registry/v1" and (.required_surface_fields | index("surface_id")) and (.required_surface_fields | index("q1_validated")) and (.evidence_ref_prefixes | index("path:"))' "B14_AG1 schema describes required surface fields"

live_out="$TMP/live.json"
python3 "$PROBE" --repo "$ROOT" --json >"$live_out"
assert_jq "$live_out" '.categories_count >= 17 and .checked_surfaces_count >= 17 and (.categories | index("l_rules")) and (.categories | index("cross_orch_propagation"))' "B14_AG2 live registry covers Lane A taxonomy"
assert_jq "$live_out" '.rows[] | select(.surface_id == "flywheel-learn-slash-command" and .category == "cli_surfaces" and .status == "pass")' "B14_AG2 live registry covers /flywheel:learn slash command"
assert_jq "$live_out" '.status == "pass" and .three_q_unaudited_count == 0' "B14_AG3 live registry passes non-strict audit"
assert_jq "$live_out" 'all(.rows[]; (.automated_probe != "" or (.manual_or_external_reason // "") != ""))' "B14_AG5 every live surface has probe or manual reason"
assert_jq "$live_out" '.rows[] | select(.surface_id == "josh-requests-capture" and (.runtime_scope | index("claude")) and (.runtime_scope | index("codex")) and (.q_results.q1_validated.runtime_checked | has("claude")) and (.q_results.q1_validated.runtime_checked | has("codex")))' "B14_AG9 runtime-dependent surfaces model Claude and Codex separately"

category_out="$TMP/category.json"
python3 "$PROBE" --repo "$ROOT" --category doctor_signals --json >"$category_out"
assert_jq "$category_out" '.checked_surfaces_count >= 1 and all(.rows[]; .category == "doctor_signals")' "B14_AG8 category filter"

owner_out="$TMP/owner.json"
python3 "$PROBE" --repo "$ROOT" --owner flywheel-m5kg --json >"$owner_out"
assert_jq "$owner_out" '.checked_surfaces_count >= 1 and all(.rows[]; (.owner_bead == "flywheel-m5kg" or .owner == "flywheel-m5kg"))' "B14_AG8 owner filter"

repo="$(make_repo)"
fixture_out="$TMP/fixture.json"
python3 "$repo/.flywheel/scripts/three-q-surface-audit.py" --repo "$repo" --registry .flywheel/three-q-surface-registry/v1/registry.json --now 2026-05-04T00:00:00Z --json >"$fixture_out"
assert_jq "$fixture_out" '.three_q_unaudited_count == 6 and .bead_promotion_required == true' "B14_AG6 fixture failures count and bead-promotion threshold"
assert_jq "$fixture_out" '.rows[] | select(.surface_id == "complete" and .status == "pass")' "B14_AG6 complete fixture"
assert_jq "$fixture_out" '.rows[] | select(.surface_id == "documented-only" and .q1_missing == true and .q2_missing == false and .q3_missing == true)' "B14_AG6 documented-only fixture"
assert_jq "$fixture_out" '.rows[] | select(.surface_id == "validated-only" and .q1_missing == false and .q2_missing == true and .q3_missing == true)' "B14_AG6 validated-only fixture"
assert_jq "$fixture_out" '.rows[] | select(.surface_id == "surfaced-only" and .q1_missing == true and .q2_missing == true and .q3_missing == false)' "B14_AG6 surfaced-only fixture"
assert_jq "$fixture_out" '.rows[] | select(.surface_id == "stale-evidence" and .stale == true and .q1_missing == true)' "B14_AG6 stale-evidence fixture"
assert_jq "$fixture_out" '.rows[] | select(.surface_id == "missing-artifact" and (.missing_evidence_refs[] | test("missing_path")))' "B14_AG6 missing-artifact fixture"
assert_jq "$fixture_out" '.rows[] | select(.surface_id == "unknown-runtime" and (.runtime_specific_gap | index("codex")))' "B14_AG6 unknown-runtime fixture"

python3 "$repo/.flywheel/scripts/three-q-surface-audit.py" --repo "$repo" --registry .flywheel/three-q-surface-registry/v1/registry.json --strict --now 2026-05-04T00:00:00Z --json >"$TMP/strict.json" && strict_rc=0 || strict_rc=$?
if [[ "$strict_rc" -ne 0 ]]; then
  pass "B14_AG3 strict exits nonzero on required surface gaps"
else
  fail "B14_AG3 strict exits nonzero on required surface gaps"
fi

receipt_out="$TMP/receipt.json"
python3 "$repo/.flywheel/scripts/three-q-surface-audit.py" --repo "$repo" --registry .flywheel/three-q-surface-registry/v1/registry.json --write-receipt --receipt-dir .flywheel/validation-receipts --now 2026-05-04T00:00:00Z --json >"$receipt_out"
assert_jq "$receipt_out" '.validation_receipt_path and .learn_route.route == "review"' "B14_AG7 receipt exposes B09 learn route"

learn_out="$TMP/learn.json"
"$BIN" validation-learn --repo "$repo" --receipt "$(jq -r '.validation_receipt_path' "$receipt_out")" --apply --json >"$learn_out" 2>"$TMP/learn.err"
assert_jq "$learn_out" '.results[0].receipt.learn_route == "review" and .results[0].applied == true and .results[0].action == "logged_fuckup"' "B14_AG7 B09 routes three-Q failure once"
"$BIN" validation-learn --repo "$repo" --receipt "$(jq -r '.validation_receipt_path' "$receipt_out")" --apply --json >"$TMP/learn2.json" 2>"$TMP/learn2.err"
assert_jq "$TMP/learn2.json" '.results[0].action == "linked_existing" and .results[0].applied == false' "B14_AG7 B09 dedupes repeated three-Q receipt"

doctor_out="$TMP/doctor.json"
strict_doctor_out="$TMP/doctor-strict.json"
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$BIN" doctor --repo "$repo" --json >"$doctor_out" 2>"$TMP/doctor.err" || true
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$BIN" doctor --strict --repo "$repo" --json >"$strict_doctor_out" 2>"$TMP/doctor-strict.err" && strict_doctor_rc=0 || strict_doctor_rc=$?
assert_jq "$doctor_out" '.three_q_unaudited_count == 6 and .surfaces_unwired_count >= 6 and (.three_q_surface_audit.top_failing_surfaces | length) > 0' "B14_AG4 doctor exposes three_q_unaudited_count and top failures"
if [[ "$strict_doctor_rc" -ne 0 ]] && jq -e '.status == "fail" and any(.errors[]?; .code == "three_q_unaudited_count")' "$strict_doctor_out" >/dev/null; then
  pass "B14_AG4 strict doctor fails on three_q_unaudited_count"
else
  fail "B14_AG4 strict doctor fails on three_q_unaudited_count"
  jq . "$strict_doctor_out" || true
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
