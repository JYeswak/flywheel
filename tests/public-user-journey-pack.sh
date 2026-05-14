#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/validate_user_journey_pack.py"
PACK="$ROOT/docs/runbooks/public-user-journey-pack.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-user-journey-pack.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then pass "syntax"; else fail "syntax"; fi

if python3 "$SCRIPT" --pack "$PACK" --json >"$TMP/pass.json" \
  && jq -e '.status == "pass" and .row_count >= 12 and (.errors | length) == 0' "$TMP/pass.json" >/dev/null; then
  pass "default pack passes"
else
  fail "default pack passes"
fi

cp "$PACK" "$TMP/no-column.md"
perl -0pi -e 's/\\| visible_wording //' "$TMP/no-column.md"
perl -0pi -e 's/\\|---\\|---\\|---\\|---\\|---\\|---\\|---\\|---\\|---\\|---\\|---\\|/|---|---|---|---|---|---|---|---|---|---|/' "$TMP/no-column.md"
if python3 "$SCRIPT" --pack "$TMP/no-column.md" --json >"$TMP/no-column.json"; then
  fail "missing required column fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "JOURNEY_SPEC_MISSING")' "$TMP/no-column.json" >/dev/null; then
  pass "missing required column fails"
else
  fail "missing required column failure code"
fi

cp "$PACK" "$TMP/no-visual.md"
perl -0pi -e 's/Owner-scene hero, bounded route-pressure board, missing-route stakes section, Joshua-as-guide proof, free Peel session plan, recent-work proof cards, trust controls, and fit-filter note/ /' "$TMP/no-visual.md"
if python3 "$SCRIPT" --pack "$TMP/no-visual.md" --json >"$TMP/no-visual.json"; then
  fail "missing visual cue fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "STEP_VISUAL_CUE_MISSING")' "$TMP/no-visual.json" >/dev/null; then
  pass "missing visual cue fails"
else
  fail "missing visual cue failure code"
fi

cp "$PACK" "$TMP/no-proof.md"
perl -0pi -e 's#tests/website-static\.sh; tests/website-accessibility\.sh; docs/runbooks/public-site-message-architecture\.md; \.flywheel/doctrine/frontend-design-and-story-principles\.md#none#' "$TMP/no-proof.md"
if python3 "$SCRIPT" --pack "$TMP/no-proof.md" --json >"$TMP/no-proof.json"; then
  fail "missing evidence fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "CLAIM_WITHOUT_EVIDENCE")' "$TMP/no-proof.json" >/dev/null; then
  pass "missing evidence fails"
else
  fail "missing evidence failure code"
fi

cp "$PACK" "$TMP/bad-proof-ref.md"
perl -0pi -e 's#tests/website-static\.sh; tests/website-accessibility\.sh; docs/runbooks/public-site-message-architecture\.md; \.flywheel/doctrine/frontend-design-and-story-principles\.md#tests/website-static.sh; docs/evidence/not-a-real-proof.json#' "$TMP/bad-proof-ref.md"
if python3 "$SCRIPT" --pack "$TMP/bad-proof-ref.md" --json >"$TMP/bad-proof-ref.json"; then
  fail "missing proof ref file fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "CLAIM_WITHOUT_EVIDENCE" and .field == "required_proof_refs")' "$TMP/bad-proof-ref.json" >/dev/null; then
  pass "missing proof ref file fails"
else
  fail "missing proof ref file failure code"
fi

cp "$PACK" "$TMP/no-mapping.md"
perl -0pi -e 's#docs/evidence/publication-blocker-coverage\.md# #g' "$TMP/no-mapping.md"
if python3 "$SCRIPT" --pack "$TMP/no-mapping.md" --json >"$TMP/no-mapping.json"; then
  fail "missing e2e mapping fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "E2E_MAPPING_MISSING")' "$TMP/no-mapping.json" >/dev/null; then
  pass "missing e2e mapping fails"
else
  fail "missing e2e mapping failure code"
fi

cp "$PACK" "$TMP/bad-blocker-ref.md"
perl -0pi -e 's#docs/evidence/publication-blocker-coverage\.md#docs/evidence/not-a-real-blocker.md#g' "$TMP/bad-blocker-ref.md"
if python3 "$SCRIPT" --pack "$TMP/bad-blocker-ref.md" --json >"$TMP/bad-blocker-ref.json"; then
  fail "missing blocker ref file fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "E2E_MAPPING_MISSING" and .field == "blocker_or_skip_receipt_ref")' "$TMP/bad-blocker-ref.json" >/dev/null; then
  pass "missing blocker ref file fails"
else
  fail "missing blocker ref file failure code"
fi

cp "$PACK" "$TMP/wrong-source.md"
perl -0pi -e 's/user-journey-wireframe-pack/bad-source-pack/g' "$TMP/wrong-source.md"
if python3 "$SCRIPT" --pack "$TMP/wrong-source.md" --json >"$TMP/wrong-source.json"; then
  fail "wrong source pack fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "JOURNEY_SPEC_MISSING" and .field == "source_pack_id")' "$TMP/wrong-source.json" >/dev/null; then
  pass "wrong source pack fails"
else
  fail "wrong source pack failure code"
fi

cp "$PACK" "$TMP/private.md"
printf '\n/Users/josh/private\n' >>"$TMP/private.md"
if python3 "$SCRIPT" --pack "$TMP/private.md" --json >"$TMP/private.json"; then
  fail "private state leak fails"
elif jq -e '.status == "fail" and any(.errors[]?; .code == "PRIVATE_STATE_LEAK")' "$TMP/private.json" >/dev/null; then
  pass "private state leak fails"
else
  fail "private state leak failure code"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
