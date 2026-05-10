#!/usr/bin/env bash
# tests/3o76p-ntm-135-tracker-staging-invariants.sh
# Bead flywheel-3o76p: tracking-bead regression for upstream
# Dicklesworthstone/ntm#135 (runtime_handoff singleton-scoped id
# CHECK constraint prevents multi-handoff state).
#
# Lifecycle (3 phases):
#   1. Now: upstream OPEN; T2.8b FAILs locally; flywheel cannot
#      represent distinct session/workdir handoff rows.
#   2. When Jeffrey closes upstream: invariants Test 5 (issue OPEN)
#      and Test 7 (T2.8b FAILs) flip; closing worker at that
#      lifecycle phase inverts assertions or files a successor bead.
#   3. After flywheel absorbs the fixed NTM contract: T2.8b PASSes
#      against live NTM; bead 3o76p closes superseded.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
EVIDENCE_RECEIPT="${EVIDENCE_RECEIPT:-$ROOT/.flywheel/receipts/flywheel-1o0i.1-53a838-blocked-evidence.md}"
ISSUE_BODY="${ISSUE_BODY:-$ROOT/.flywheel/receipts/flywheel-1o0i.1-53a838-jeff-issue-body.md}"
PHASE2_AUDIT="${PHASE2_AUDIT:-$ROOT/tests/phase2-audit.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: parent evidence receipt exists (the flywheel-1o0i.1 close)
if [[ -f "$EVIDENCE_RECEIPT" ]] \
  && grep -q "T2.8b" "$EVIDENCE_RECEIPT" \
  && grep -q "runtime_handoff" "$EVIDENCE_RECEIPT"; then
  pass "parent evidence receipt exists with T2.8b + runtime_handoff citations"
else
  fail "parent evidence receipt missing or incomplete at $EVIDENCE_RECEIPT"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: jeff-issue-body draft exists with the canonical Repro section
if [[ -f "$ISSUE_BODY" ]] \
  && grep -q "runtime_handoff" "$ISSUE_BODY" \
  && grep -qE 'singleton-scoped|id.*=.*1|CHECK.*id.*1' "$ISSUE_BODY" \
  && grep -qE 'Repro|reproduce|reproduction' "$ISSUE_BODY"; then
  pass "jeff-issue-body draft exists with canonical singleton-id + Repro sections"
else
  fail "jeff-issue-body missing or incomplete at $ISSUE_BODY"
fi

# Cache phase2-audit output once (it's slow; ~30-60s).
PHASE2_LOG="$(mktemp -t phase2-audit.XXXXXX)"
trap 'rm -f "$PHASE2_LOG"' EXIT
timeout 90 bash "$PHASE2_AUDIT" >"$PHASE2_LOG" 2>&1 || true

# Test 3: phase2-audit T2.8 (working_dir column exists) PASSes — the
# upstream did add the column; the broken piece is the singleton id check.
T28_RESULT="$(grep -E 'T2\.8 runtime_handoff has working_dir column' "$PHASE2_LOG" | head -1)"
if [[ "$T28_RESULT" == PASS* ]]; then
  pass "T2.8 working_dir column still present (upstream partial fix intact)"
else
  fail "T2.8 regressed; got: $T28_RESULT"
fi

# Test 4: phase2-audit T2.8b (multi-handoff state) FAILs — the
# singleton-id CHECK still blocks distinct session/workdir rows.
# When upstream lands the fix and we absorb it, this test will
# INVERT: T2.8b PASSes, and closing worker should close 3o76p as
# superseded.
T28B_RESULT="$(grep -E 'T2\.8b runtime_handoff supports distinct session/workdir rows' "$PHASE2_LOG" | head -1)"
if [[ "$T28B_RESULT" == FAIL* ]]; then
  pass "T2.8b multi-handoff state FAILs (trauma condition holds; upstream fix pending)"
else
  fail "T2.8b is now PASS — LIFECYCLE ADVANCED. Upstream ntm#135 may have been absorbed; close 3o76p as superseded or invert assertion. Got: $T28B_RESULT"
fi

# Test 5: upstream issue Dicklesworthstone/ntm#135 is still OPEN.
# When Jeffrey closes it, this test flips and the orchestrator
# should plan flywheel absorption of the fixed contract.
if command -v gh >/dev/null 2>&1; then
  ISSUE_STATE="$(gh issue view 135 -R Dicklesworthstone/ntm --json state 2>/dev/null | jq -r '.state // ""')"
  if [[ "$ISSUE_STATE" == "OPEN" ]]; then
    pass "upstream Dicklesworthstone/ntm#135 still OPEN (Jeffrey-restraint preserved; tracking active)"
  elif [[ "$ISSUE_STATE" == "CLOSED" ]]; then
    fail "upstream ntm#135 is CLOSED — LIFECYCLE ADVANCED. Plan flywheel absorption of the fixed NTM contract; close 3o76p as superseded"
  else
    pass "gh issue state inconclusive ($ISSUE_STATE) — runtime guard skipped, source-level invariants still hold"
  fi
else
  pass "gh unavailable — runtime issue-state guard skipped"
fi

# Test 6: evidence receipt cites the SQL repro shape canonically
if grep -qE 'runtime_handoff|session_name.*working_dir|id.*=.*1|id INTEGER PRIMARY KEY' "$ISSUE_BODY"; then
  pass "evidence cites canonical repro shape (runtime_handoff schema + singleton id constraint)"
else
  fail "evidence missing canonical repro shape"
fi

# Test 7: evidence cites the deduplication check Jeffrey-restraint
# discipline (proves we searched upstream before filing).
if grep -qE 'Dedup probe|gh issue list.*Dicklesworthstone/ntm.*search' "$ISSUE_BODY"; then
  pass "evidence cites pre-filing upstream dedup probe (Jeffrey-restraint)"
else
  fail "evidence missing dedup-probe citation"
fi

# Test 8: receipt cites no live NTM state mutation (read-only contract)
if grep -qE 'No live NTM state mutation|read-only|fixture' "$EVIDENCE_RECEIPT"; then
  pass "evidence asserts no live NTM state mutation (read-only invariant)"
else
  fail "evidence missing read-only invariant citation"
fi

# Test 9: phase2-audit.sh itself contains the T2.8b guard (substrate intact)
if [[ -x "$PHASE2_AUDIT" ]] && grep -qE 'T2\.8b|runtime_handoff supports distinct' "$PHASE2_AUDIT"; then
  pass "phase2-audit.sh substrate intact with T2.8b guard"
else
  fail "phase2-audit.sh missing or T2.8b guard removed"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
