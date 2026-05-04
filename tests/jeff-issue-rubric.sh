#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/jeff-issue-rubric.py"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-issue-rubric.XXXXXX")"
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
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/jeff-issue-rubric/v1/receipts" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  cp "$PROBE" "$repo/.flywheel/scripts/jeff-issue-rubric.py"
  chmod +x "$repo/.flywheel/scripts/jeff-issue-rubric.py"
  printf '%s\n' "$repo"
}

python3 -m py_compile "$PROBE" && pass "rubric script syntax" || fail "rubric script syntax"
python3 "$PROBE" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "jeff-issue-rubric/v1" and (.axes | length) == 7 and .decision_policy."7_high" == "auto_post"' "AG_DOC schema exposes 7 axes and thresholds"

python3 "$PROBE" --draft "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/high-quality.md" --json >"$TMP/high.json"
assert_jq "$TMP/high.json" '.status == "pass" and .decision == "auto_post" and .high_axes_count == 7 and all(.axes[]; .passed == true)' "AG_VALIDATED high-quality fixture auto-posts"

python3 "$PROBE" --draft "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/ambiguous.md" --json >"$TMP/ambiguous.json" && ambiguous_rc=0 || ambiguous_rc=$?
if [[ "${ambiguous_rc:-0}" -ne 0 ]] && jq -e '.status == "fail" and .decision == "revise" and .high_axes_count == 6 and (.hard_fail_axes | index("signal_not_prescription"))' "$TMP/ambiguous.json" >/dev/null; then
  pass "AG_VALIDATED ambiguous fixture revises at 6/7"
else
  fail "AG_VALIDATED ambiguous fixture revises at 6/7"
  jq . "$TMP/ambiguous.json" || true
fi

python3 "$PROBE" --draft "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/low-quality.md" --json >"$TMP/low.json" && low_rc=0 || low_rc=$?
if [[ "${low_rc:-0}" -ne 0 ]] && jq -e '.status == "fail" and .decision == "withdraw" and .high_axes_count <= 5' "$TMP/low.json" >/dev/null; then
  pass "AG_VALIDATED low-quality fixture withdraws"
else
  fail "AG_VALIDATED low-quality fixture withdraws"
  jq . "$TMP/low.json" || true
fi

python3 "$PROBE" --draft "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/anti-pattern.md" --json >"$TMP/anti.json" && anti_rc=0 || anti_rc=$?
if [[ "${anti_rc:-0}" -ne 0 ]] && jq -e '.status == "fail" and .decision == "withdraw" and (.hard_fail_axes | index("no_derail")) and (.hard_fail_axes | index("jeff_thank_test_hostile"))' "$TMP/anti.json" >/dev/null; then
  pass "AG_VALIDATED anti-pattern fixture withdraws with derail and hostile failures"
else
  fail "AG_VALIDATED anti-pattern fixture withdraws with derail and hostile failures"
  jq . "$TMP/anti.json" || true
fi

live="$TMP/live.json"
python3 "$PROBE" --draft /tmp/jeff-issue-runtime-handoff-singleton.md --write-receipt --json >"$live" && live_rc=0 || live_rc=$?
assert_jq "$live" '.schema_version == "jeff-issue-rubric/v1" and (.axes | length) == 7 and .receipt_path' "AG_VALIDATED live draft produces receipt and score"

repo="$(make_repo)"
cp "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/high-quality.md" "$TMP/jeff-issue-high.md"
cp "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/low-quality.md" "$TMP/jeff-issue-low.md"
"$repo/.flywheel/scripts/jeff-issue-rubric.py" --repo "$repo" --draft "$TMP/jeff-issue-high.md" --write-receipt --json >/dev/null
"$repo/.flywheel/scripts/jeff-issue-rubric.py" --repo "$repo" --doctor --draft-glob "$TMP/jeff-issue-*.md" --json >"$TMP/doctor.json" || true
assert_jq "$TMP/doctor.json" '.jeff_drafts_unrubricd_count == 1 and (.top_unrubricd_drafts[0].draft_path | test("jeff-issue-low.md")) and (.signals[0].name == "jeff_drafts_unrubricd_count")' "AG_SURFACED doctor counts unrubriced drafts"

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_JEFF_ISSUE_DRAFT_GLOB="$TMP/jeff-issue-*.md" "$BIN" doctor --repo "$repo" --json >"$TMP/flywheel-doctor.json" 2>"$TMP/flywheel-doctor.err" || true
assert_jq "$TMP/flywheel-doctor.json" '.jeff_drafts_unrubricd_count == 1 and (.jeff_issue_rubric.top_unrubricd_drafts | length) == 1' "AG_SURFACED flywheel doctor exposes jeff_drafts_unrubricd_count"

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_JEFF_ISSUE_DRAFT_GLOB="$TMP/jeff-issue-*.md" "$BIN" doctor --strict --repo "$repo" --json >"$TMP/flywheel-doctor-strict.json" 2>"$TMP/flywheel-doctor-strict.err" && strict_rc=0 || strict_rc=$?
if [[ "$strict_rc" -ne 0 ]] && jq -e '.status == "fail" and any(.errors[]?; .code == "jeff_drafts_unrubricd_count")' "$TMP/flywheel-doctor-strict.json" >/dev/null; then
  pass "AG_SURFACED strict doctor fails on unrubriced drafts"
else
  fail "AG_SURFACED strict doctor fails on unrubriced drafts"
  jq . "$TMP/flywheel-doctor-strict.json" || true
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
