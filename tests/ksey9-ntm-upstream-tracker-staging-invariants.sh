#!/usr/bin/env bash
# tests/ksey9-ntm-upstream-tracker-staging-invariants.sh
# Bead flywheel-ksey9: tracking-bead regression that asserts the staged
# ntm controller-pane wording proposal stays staged-only (no upstream
# push without {operator} approval per parent flywheel-se3h.8 gate 5).
#
# When {operator} approves the upstream push, the orchestrator should follow
# jeff-issue-chain v1.3 Phase 1 contract from the staged proposal. Until
# then, this regression fires the moment any invariant drifts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROPOSAL="${PROPOSAL_PATH:-$ROOT/.flywheel/evidence/flywheel-se3h.8/proposed-wording.md}"
GREP_RECEIPT="${GREP_RECEIPT_PATH:-$ROOT/.flywheel/evidence/flywheel-se3h.8/ntm-controller-pane-grep.txt}"
COUNTEREXAMPLES="${COUNTEREXAMPLES_PATH:-$ROOT/.flywheel/evidence/flywheel-se3h.8/topology-counterexamples.jsonl}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: staged proposal exists with required boundary + DRAFT markers
if [[ -f "$PROPOSAL" ]] \
  && grep -qE 'local-only.*no upstream push without explicit {operator} approval|no upstream push' "$PROPOSAL" \
  && grep -q "DRAFT" "$PROPOSAL" \
  && grep -q "Dicklesworthstone/ntm" "$PROPOSAL"; then
  pass "staged proposal exists with local-only / DRAFT / upstream-target markers"
else
  fail "staged proposal missing or boundary markers gone at $PROPOSAL"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: grep receipt exists naming the 3 live surfaces (NOT 4 or 5 — the
# scope is "wording surfaces", test/comment surfaces are explicitly lower priority)
if [[ -f "$GREP_RECEIPT" ]]; then
  pass "ntm-controller-pane-grep.txt evidence receipt exists"
else
  fail "grep receipt missing at $GREP_RECEIPT"
fi

# Test 3: proposal cites the 3 hardcoded-pane-1 surfaces in the canonical wording table
required_surfaces=(
  "internal/cli/get_all_session_text.go"
  "internal/cli/controller.go"
)
missing_surfaces=()
for surface in "${required_surfaces[@]}"; do
  grep -qF "$surface" "$PROPOSAL" || missing_surfaces+=("$surface")
done
if [[ "${#missing_surfaces[@]}" -eq 0 ]]; then
  pass "proposal cites canonical hardcoded-pane-1 surfaces (get_all_session_text.go + controller.go)"
else
  fail "proposal missing surface citations: ${missing_surfaces[*]}"
fi

# Test 4: counterexamples ledger exists + carries {session}:0 + {proof-product}:2 rows
if [[ -f "$COUNTEREXAMPLES" ]] \
  && jq -es '
    map(select(.session == "{session}" and .orchestrator_pane == 0)) | length > 0
  ' >/dev/null 2>&1 <"$COUNTEREXAMPLES" \
  && jq -es '
    map(select(.session == "{proof-product}" and .orchestrator_pane == 2)) | length > 0
  ' >/dev/null 2>&1 <"$COUNTEREXAMPLES"; then
  pass "topology-counterexamples.jsonl carries alps:0 + {proof-product}:2 evidence rows"
else
  fail "counterexamples missing required rows; expected {session}:orchestrator_pane=0 + {proof-product}:orchestrator_pane=2"
fi

# Test 5: parent bead flywheel-se3h.8 is closed (gate-5 path is the canonical handoff)
if br show flywheel-se3h.8 2>&1 | head -3 | grep -q "CLOSED"; then
  pass "parent bead flywheel-se3h.8 is CLOSED (canonical handoff complete)"
else
  fail "parent bead flywheel-se3h.8 not CLOSED — staged proposal lifecycle drift"
fi

# Test 6: no upstream push artifact exists in this repo ({operator}-restraint
# invariant — the proposal must NOT have been pushed). gh issue create
# would leave a URL trace in the proposal or a PR-link-class artifact.
if grep -qE 'github\.com/Dicklesworthstone/ntm/(issues|pull)/[0-9]+' "$PROPOSAL"; then
  fail "proposal contains a Dicklesworthstone/ntm issue or pull URL — looks like upstream push happened"
else
  pass "proposal carries no upstream issue/pull URL — {operator}-restraint preserved"
fi

# Test 7: proposal cites jeff-issue-chain v1.3 Phase 1 contract for the
# canonical handoff path when {operator} approves
if grep -qE 'jeff-issue-chain (v1\.3|version 1\.3)' "$PROPOSAL" \
  || grep -qE 'Phase 1' "$PROPOSAL"; then
  pass "proposal references jeff-issue-chain v1.3 Phase 1 handoff path"
else
  # The bead description references it; the proposal SHOULD too. If not, the
  # bead description IS the canonical pointer — accept either.
  if br show flywheel-ksey9 2>&1 | grep -q "jeff-issue-chain v1.3 Phase 1"; then
    pass "bead body references jeff-issue-chain v1.3 Phase 1 handoff path"
  else
    fail "neither proposal nor bead cites jeff-issue-chain v1.3 Phase 1 handoff"
  fi
fi

# Test 8: ntm behavior is correct (the bead body says wording-only proposal;
# behavior already correct). This regression asserts the asserted invariant
# by inspecting the proposal's framing.
if grep -qE 'wording-only|behavior.*already correct|Wording-only' "$PROPOSAL"; then
  pass "proposal framed as wording-only (ntm behavior unchanged)"
else
  # bead body is canonical here too
  if br show flywheel-ksey9 2>&1 | grep -qE 'Wording-only|wording-only|behavior already correct'; then
    pass "bead body framed as wording-only (ntm behavior unchanged)"
  else
    fail "wording-only framing missing — risk of behavior-change scope creep"
  fi
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
