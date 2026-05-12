#!/usr/bin/env bash
# test_dispatch_mission_fitness_required.sh
# Verifies that /flywheel:dispatch Step 0.5 invokes mission-anchor-dispatch-license.sh
# --validate and refuses when mission_anchor_status is not filled.
#
# canonical-cli-scoping: exit 0=all pass, 1=at least one FAIL, 2=usage error
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${MISSION_LICENSE_BIN:-$ROOT/.flywheel/scripts/mission-anchor-dispatch-license.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/test-dispatch-mission-fitness.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null 2>&1; then pass "$label"; else
    fail "$label"; jq . "$file" >&2 2>/dev/null || true
  fi
}

assert_rc() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then pass "$label"; else
    fail "$label (rc=$actual expected=$expected)"
  fi
}

make_repo() {
  local dir
  dir="$(mktemp -d "$TMP/repo.XXXXXX")"
  mkdir -p "$dir/.flywheel"
  printf '%s\n' "$dir"
}

write_filled_mission() {
  local repo="$1"
  cat > "$repo/.flywheel/MISSION.md" <<'EOF'
---
status: filled
---
# Mission Anchor

## Section 3 — Phase Ladder

| Phase | Gate Criterion | Status as of 2026-05-07 |
|---|---|---|
| Phase 1 | Substrate live | IN PROGRESS |
| Phase 2 | Fleet dispatching | TODO |
EOF
}

write_unfilled_mission() {
  local repo="$1"
  cat > "$repo/.flywheel/MISSION.md" <<'EOF'
---
status: needs_owner_review
---
# Mission Anchor

- North-star: TODO
EOF
}

# ── Test 1: filled MISSION.md → validate exits 0 ─────────────────────────────
REPO_FILLED="$(make_repo)"
write_filled_mission "$REPO_FILLED"
OUT="$TMP/validate_filled.json"
bash "$BIN" --validate --repo "$REPO_FILLED" --json > "$OUT" 2>&1
RC=$?
assert_rc "$RC" "0" "validate/filled_mission_exits_0"
assert_jq "$OUT" '.status == "pass"' "validate/filled_mission_status_pass"
assert_jq "$OUT" '.mission_anchor_status == "filled"' "validate/filled_mission_anchor_status_field"

# ── Test 2: unfilled MISSION.md → validate exits 3 (transient/substrate) ─────
REPO_UNFILLED="$(make_repo)"
write_unfilled_mission "$REPO_UNFILLED"
OUT2="$TMP/validate_unfilled.json"
set +e; bash "$BIN" --validate --repo "$REPO_UNFILLED" --json > "$OUT2" 2>&1; RC2=$?; set -e
assert_rc "$RC2" "3" "validate/unfilled_mission_exits_3"

# ── Test 3: missing MISSION.md → validate exits 3 ────────────────────────────
REPO_MISSING="$(make_repo)"
OUT3="$TMP/validate_missing.json"
set +e; bash "$BIN" --validate --repo "$REPO_MISSING" --json > "$OUT3" 2>&1; RC3=$?; set -e
assert_rc "$RC3" "3" "validate/missing_mission_exits_3"

# ── Test 4: dispatch Step 0.5 command shape (invocation contract) ─────────────
# The exact invocation from dispatch.md Step 0.5:
#   bash .flywheel/scripts/mission-anchor-dispatch-license.sh --validate --repo "$PWD" --json
# Verify the script exists at the expected path and is executable.
if [[ -x "$ROOT/.flywheel/scripts/mission-anchor-dispatch-license.sh" ]]; then
  pass "dispatch_step_0.5/script_is_executable"
else
  fail "dispatch_step_0.5/script_is_executable"
fi

# ── Test 5: dispatch.md contains Step 0.5 wiring text ─────────────────────────
DISPATCH_MD="$HOME/.claude/commands/flywheel/dispatch.md"
if grep -q "mission-anchor-dispatch-license.sh" "$DISPATCH_MD" 2>/dev/null; then
  pass "dispatch_md/contains_license_invocation"
else
  fail "dispatch_md/contains_license_invocation"
fi

if grep -q "mission_fitness_score" "$DISPATCH_MD" 2>/dev/null; then
  pass "dispatch_md/persists_mission_fitness_score_to_log"
else
  fail "dispatch_md/persists_mission_fitness_score_to_log"
fi

if grep -q "mission_fitness_class" "$DISPATCH_MD" 2>/dev/null; then
  pass "dispatch_md/persists_mission_fitness_class_to_log"
else
  fail "dispatch_md/persists_mission_fitness_class_to_log"
fi

# ── Test 6: dispatch-template.md contains mission_fitness_claim field ─────────
TEMPLATE_MD="$HOME/.claude/commands/flywheel/_shared/dispatch-template.md"
if grep -q "mission_fitness_claim" "$TEMPLATE_MD" 2>/dev/null; then
  pass "dispatch_template/mission_fitness_claim_field_present"
else
  fail "dispatch_template/mission_fitness_claim_field_present"
fi

if grep -q "mission_fitness_class" "$TEMPLATE_MD" 2>/dev/null; then
  pass "dispatch_template/mission_fitness_class_field_present"
else
  fail "dispatch_template/mission_fitness_class_field_present"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n%s\n' "─────────────────────────────────────"
printf 'Results: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"

[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
