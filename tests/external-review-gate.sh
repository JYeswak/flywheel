#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/validate_external_review.py"
LIVE_LOG="$ROOT/.flywheel/PLANS/public-share-readiness-2026-05-12/review-log.jsonl"
PUBLIC_LOG="$ROOT/docs/evidence/external-review-log.jsonl"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-external-review.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

cat >"$TMP/pass.jsonl" <<'JSONL'
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-a","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[],"comments":["clear first-run path"]}
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-b","reviewer_kind":"external_human","reviewed_at":"20260513T000000Z","verdict":"approved_with_followups","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[],"comments":["followups are non-blocking"]}
JSONL

if python3 "$SCRIPT" --log "$TMP/pass.jsonl" --release --json >"$TMP/pass.out"; then
  if jq -e '.status == "pass" and .valid_review_count == 2 and .distinct_reviewer_count == 2 and (.required_surfaces | contains(["CHARTER.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"]))' "$TMP/pass.out" >/dev/null; then
    pass "valid two-review log passes"
  else
    fail "valid two-review log envelope"
  fi
else
  fail "valid two-review log command"
fi

cat >"$TMP/duplicate.jsonl" <<'JSONL'
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-a","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-a","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
JSONL

if python3 "$SCRIPT" --log "$TMP/duplicate.jsonl" --release --json >"$TMP/duplicate.out"; then
  fail "duplicate reviewers must fail release"
else
  if jq -e '.status == "blocked" and any(.errors[]?; .code == "reviewers_not_distinct")' "$TMP/duplicate.out" >/dev/null; then
    pass "duplicate reviewers blocked"
  else
    fail "duplicate reviewer failure shape"
  fi
fi

cat >"$TMP/blocked-reviewer.jsonl" <<'JSONL'
{"schema_version":"flywheel.external_review.v0","reviewer_id":"joshua","reviewer_kind":"external_human","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-b","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
JSONL

if python3 "$SCRIPT" --log "$TMP/blocked-reviewer.jsonl" --release --json >"$TMP/blocked-reviewer.out"; then
  fail "blocked reviewer must fail release"
else
  if jq -e '.status == "blocked" and any(.errors[]?; .code == "blocked_reviewer")' "$TMP/blocked-reviewer.out" >/dev/null; then
    pass "blocked reviewer rejected"
  else
    fail "blocked reviewer failure shape"
  fi
fi

cat >"$TMP/missing-surface.jsonl" <<'JSONL'
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-a","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md"],"blocking_findings":[]}
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-b","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
JSONL

if python3 "$SCRIPT" --log "$TMP/missing-surface.jsonl" --release --json >"$TMP/missing-surface.out"; then
  fail "missing first-run review must fail release"
else
  if jq -e '.status == "blocked" and any(.errors[]?; .code == "missing_required_surface_review")' "$TMP/missing-surface.out" >/dev/null; then
    pass "required surfaces enforced"
  else
    fail "required surface failure shape"
  fi
fi

cat >"$TMP/bad-reviewed-at.jsonl" <<'JSONL'
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-a","reviewer_kind":"external_agent","reviewed_at":"not-a-time","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-b","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
JSONL

if python3 "$SCRIPT" --log "$TMP/bad-reviewed-at.jsonl" --release --json >"$TMP/bad-reviewed-at.out"; then
  fail "bad reviewed_at must fail release"
else
  if jq -e '.status == "blocked" and any(.errors[]?; .code == "invalid_reviewed_at")' "$TMP/bad-reviewed-at.out" >/dev/null; then
    pass "reviewed_at timestamp enforced"
  else
    fail "reviewed_at timestamp failure shape"
  fi
fi

cat >"$TMP/bad-kind.jsonl" <<'JSONL'
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-a","reviewer_kind":"friend","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
{"schema_version":"flywheel.external_review.v0","reviewer_id":"outside-reader-b","reviewer_kind":"external_agent","reviewed_at":"20260513T000000Z","verdict":"approved","reviewed_surfaces":["README.md","CHARTER.md","docs/getting-started/first-run.md","docs/evidence/publication-evidence.md","docs/evidence/publication-blocker-coverage.md","docs/runbooks/release-cutover-authorization.md","docs/runbooks/public-release-runbook.md"],"blocking_findings":[]}
JSONL

if python3 "$SCRIPT" --log "$TMP/bad-kind.jsonl" --release --json >"$TMP/bad-kind.out"; then
  fail "bad reviewer kind must fail release"
else
  if jq -e '.status == "blocked" and any(.errors[]?; .code == "invalid_reviewer_kind")' "$TMP/bad-kind.out" >/dev/null; then
    pass "reviewer kind allowlist enforced"
  else
    fail "reviewer kind failure shape"
  fi
fi

TEMPLATE_LOG="$ROOT/.flywheel/PLANS/public-share-readiness-2026-05-12/review-log.template.jsonl"
if [[ ! -f "$TEMPLATE_LOG" ]]; then
  pass "pending template absent from public export"
elif python3 "$SCRIPT" --log "$TEMPLATE_LOG" --release --json >"$TMP/template.out"; then
  fail "pending template must fail release"
else
  if jq -e '.status == "blocked" and any(.errors[]?; .code == "invalid_verdict") and any(.errors[]?; .code == "missing_reviewed_at")' "$TMP/template.out" >/dev/null; then
    pass "pending template remains blocked"
  else
    fail "pending template failure shape"
  fi
fi

set +e
python3 "$SCRIPT" --log "$LIVE_LOG" --json >"$TMP/live.out"
live_rc=$?
set -e
if [[ "$live_rc" -eq 0 || "$live_rc" -eq 20 ]] && jq -e '.status == "blocked" or .status == "pass"' "$TMP/live.out" >/dev/null; then
  pass "live review log has explicit gate status"
else
  fail "live review log gate status rc=${live_rc}"
fi

if python3 "$SCRIPT" --log "$PUBLIC_LOG" --release --json >"$TMP/public.out"; then
  if jq -e '.status == "pass" and .valid_review_count == 2 and .distinct_reviewer_count == 2 and (.required_surfaces | index("docs/evidence/publication-blocker-coverage.md"))' "$TMP/public.out" >/dev/null; then
    pass "public external review evidence covers blocker-coverage review"
  else
    fail "public external review pass envelope"
  fi
else
  fail "public external review evidence covers blocker-coverage review"
fi

if python3 "$SCRIPT" --log "$TMP/pass.jsonl" --release --json >"$TMP/surfaces.out"; then
  missing_runbook_surface=0
  while IFS= read -r surface; do
    if ! grep -Fq "$surface" "$ROOT/docs/runbooks/public-release-runbook.md"; then
      printf 'missing runbook surface: %s\n' "$surface" >&2
      missing_runbook_surface=1
    fi
  done < <(jq -r '.required_surfaces[]' "$TMP/surfaces.out")
  if [[ "$missing_runbook_surface" -eq 0 ]]; then
    pass "public release runbook lists required review surfaces"
  else
    fail "public release runbook lists required review surfaces"
  fi
else
  fail "required surface source for runbook check"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
