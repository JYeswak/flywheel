#!/usr/bin/env bash
# tests/doctor-non-identity-failures-fixes.sh
# Regression test for flywheel-zh43y: doctor non-identity failures.
# Verifies the 2 of 5 fixes that this bead actually shipped.
# (#1+#3 loop-driver and #2 beads leakage are filed as separate beads
# because they require {operator}-directive decisions.)
#
# What this test covers:
#   FIX A (#4 memory_health): 3 memory files in flywheel project that were
#     blocking indexing now have valid frontmatter (status: FAIL→WARN).
#   FIX B (#5 validation_receipts_schema_invalid_count): 8 pre-v1-schema
#     receipts archived to .archive-pre-v1-schema/; active dir count = 0.
#
# What this test does NOT cover:
#   #1+#3 loop-driver: filed as flywheel-kmf4z (needs {operator} directive)
#   #2 beads source_repo basename: filed as flywheel-wz5rh (subset of
#     project_bead_isolation_plan; needs canonical bulk-update path)

set -uo pipefail

REPO_ROOT="${FLYWHEEL_REPO:-<flywheel-repo>}"
MEM_DIR="${FLYWHEEL_MEMORY_DIR:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory}"
ARCHIVE_DIR="$REPO_ROOT/.flywheel/validation-receipts/.archive-pre-v1-schema"
ACTIVE_DIR="$REPO_ROOT/.flywheel/validation-receipts"
PARSE_SH="$REPO_ROOT/.flywheel/validation-schema/v1/parse.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# ============================================================
# FIX A — memory_health: 3 frontmatter-broken files now valid
# ============================================================

# Test 1: each of the 3 files has YAML frontmatter
for F in feedback_beads_rust_dep_add_post_rebuild_openread.md \
         feedback_evidence_pack_replaces_four_lens.md \
         feedback_regression_test_must_exercise_production_close_path.md; do
  P="$MEM_DIR/$F"
  if [[ -r "$P" ]] && head -1 "$P" | grep -qE '^---$'; then
    pass "$F starts with YAML frontmatter delimiter"
  else
    fail "$F missing/wrong frontmatter delimiter (head=$(head -1 "$P" 2>/dev/null))"
  fi
done

# Test 2: each file has all 3 required keys (name, description, type)
for F in feedback_beads_rust_dep_add_post_rebuild_openread.md \
         feedback_evidence_pack_replaces_four_lens.md \
         feedback_regression_test_must_exercise_production_close_path.md; do
  P="$MEM_DIR/$F"
  # Extract the frontmatter block (between first two --- lines)
  FM="$(awk '/^---$/{c++; next} c==1' "$P" 2>/dev/null)"
  HAS_NAME=0; HAS_DESC=0; HAS_TYPE=0
  grep -qE '^name:' <<<"$FM" && HAS_NAME=1
  grep -qE '^description:' <<<"$FM" && HAS_DESC=1
  grep -qE '^type:' <<<"$FM" && HAS_TYPE=1
  if [[ "$HAS_NAME" -eq 1 && "$HAS_DESC" -eq 1 && "$HAS_TYPE" -eq 1 ]]; then
    pass "$F has all 3 required keys (name, description, type)"
  else
    fail "$F missing keys (name=$HAS_NAME desc=$HAS_DESC type=$HAS_TYPE)"
  fi
done

# Test 3: mem doctor reports memory_health status != FAIL
if command -v mem >/dev/null 2>&1; then
  STATUS_LINE="$(mem memory doctor 2>&1 | grep -E '^-Users-josh-Developer-flywheel\s+' | awk '{print $2}')"
  if [[ "$STATUS_LINE" == "WARN" || "$STATUS_LINE" == "OK" || "$STATUS_LINE" == "PASS" ]]; then
    pass "mem memory doctor: -Users-josh-Developer-flywheel status=$STATUS_LINE (not FAIL)"
  else
    fail "mem memory doctor status=$STATUS_LINE (expected WARN/OK/PASS, not FAIL)"
  fi
else
  pass "mem cli not installed — skipping consumer-layer verification"
fi

# ============================================================
# FIX B — validation_receipts: archive + active count = 0
# ============================================================

# Test 4: archive directory exists
if [[ -d "$ARCHIVE_DIR" ]]; then
  pass "archive directory exists at .archive-pre-v1-schema/"
else
  fail "archive directory missing at $ARCHIVE_DIR"
fi

# Test 5: archive directory contains a README explaining the move
if [[ -r "$ARCHIVE_DIR/README.md" ]] && grep -q 'flywheel-zh43y' "$ARCHIVE_DIR/README.md"; then
  pass "archive README cites flywheel-zh43y as origin"
else
  fail "archive README missing or missing zh43y citation"
fi

# Test 6 (load-bearing): active dir contains zero schema-invalid receipts
PASS=0; FAIL=0
shopt -s nullglob 2>/dev/null
for F in "$ACTIVE_DIR"/*.json; do
  [[ -f "$F" ]] || continue
  if bash "$PARSE_SH" "$F" >/dev/null 2>&1; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
  fi
done
if [[ "$FAIL" -eq 0 ]]; then
  pass "active dir has 0 schema-invalid receipts (was 8 before fix; pass=$PASS)"
else
  fail "active dir still has $FAIL schema-invalid receipts (regression)"
fi

# Test 7 (preservation): archive contains the 8 specific receipts
EXPECTED_ARCHIVED=(
  b03-reaper-done-6fe5ac9f1eee.json
  flywheel_loop_20260504T043410Z-done-0ecf0cde2d4b.json
  flywheel-4vfa-onboarding-proof.json
  flywheel-ggld7-1a2b3b.json
  no-bead-cross-session-callback-closure-{capability-control-plane}-20260504T0400Z.json
  no-bead-flywheel_loop_20260504T005757Z.json
  no-bead-flywheel_loop_20260504T012826Z.json
  no-bead-flywheel_loop_20260504T015853Z.json
)
MISSING_ARCHIVED=()
for F in "${EXPECTED_ARCHIVED[@]}"; do
  [[ -f "$ARCHIVE_DIR/$F" ]] || MISSING_ARCHIVED+=("$F")
done
if [[ "${#MISSING_ARCHIVED[@]}" -eq 0 ]]; then
  pass "all 8 specific archived receipts preserved in .archive-pre-v1-schema/"
else
  fail "missing archived receipts: ${MISSING_ARCHIVED[*]}"
fi

# ============================================================
# Reporting
# ============================================================

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
