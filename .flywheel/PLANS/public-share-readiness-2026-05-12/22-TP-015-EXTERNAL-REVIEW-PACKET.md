# TP-015 External Review Packet

Status: closed for current seven-surface public trust set.
Owner: Flywheel
Bead: `flywheel-kmyn1`
Registry row: TP-015

2026-05-13 update: Agent Mail contact requests are pending from `BoldDog` to
`JadeFinch` and `mobile-eats-pane2-bridge`. The review request body is ready,
but Agent Mail contact policy blocked delivery until the recipients approve.

2026-05-13 follow-up: `BoldDog` also routed the same review request through
WezTerm to the live SkillOS pane (`pane_id=1`) and Mobile Eats pane
(`pane_id=4`) so reviewers can respond outside Agent Mail without weakening the
review-log validator. At that point, TP-015 remained open until the JSONL
review log passed.

2026-05-13 closure: `.flywheel/PLANS/public-share-readiness-2026-05-12/review-log.jsonl`
contains two distinct external-agent review rows:
`skillos-codex-mistycompass` and `mobile-eats-codex-slateharbor`. Both verdicts
are `approved_with_followups`, both `blocking_findings` arrays are empty, and
the then-current `python3 scripts/validate_external_review.py --release --json`
returned `status=pass`. Non-blocking followups are tracked in Bead
`flywheel-9d1fd`.

2026-05-13 supplemental update: after the first review, Flywheel added
`docs/evidence/publication-evidence.md` and
`docs/runbooks/release-cutover-authorization.md` as public trust surfaces.
Those surfaces materially affect release trust, so the validator now requires
them. Existing review rows remain useful historical evidence but no longer close
TP-015 until two reviewers cover the expanded surface set.

2026-05-13 supplemental closure: SkillOS and Mobile Eats returned two distinct
supplemental external-agent review rows covering the expanded six-surface set.
Both verdicts are `approved_with_followups`, both `blocking_findings` arrays are
empty, and `python3 scripts/validate_external_review.py --release --json`
returns `status=pass` again. The sanitized public evidence copy at
`docs/evidence/external-review-log.jsonl` also validates in release mode.

2026-05-13 second supplemental update: Flywheel added
`docs/evidence/publication-blocker-coverage.md` as a public blocker-code
ownership and closure-proof surface. That page materially affects external
trust, so the validator now requires it. Existing six-surface rows remain useful
historical evidence but no longer close TP-015 until two distinct reviewers
cover the seven-surface set.

2026-05-13 second supplemental progress: Mobile Eats found stale six-surface
wording in `docs/runbooks/public-release-runbook.md`; Flywheel patched that
runbook and added an external-review regression that the runbook lists every
validator-required surface. Mobile Eats then returned one current seven-surface
row with empty `blocking_findings`. SkillOS has not yet returned a current
seven-surface row, so the release validator remained blocked with
`valid_review_count=1`.

2026-05-13 second supplemental closure: Gemini CLI completed a separate
read-only cold review and returned the second current seven-surface row. The
private working log and sanitized public evidence log both validate in release
mode with `valid_review_count=2`, `distinct_reviewer_count=2`, and empty
`errors`.

TP-015 remains closed only while
`.flywheel/PLANS/public-share-readiness-2026-05-12/review-log.jsonl` contains
exactly two distinct non-Joshua, non-`flywheel:1` review rows whose verdicts are
`approved` or `approved_with_followups`, whose `blocking_findings` arrays are
empty, whose `reviewed_at` values are ISO-8601 UTC timestamps ending in `Z`, and
whose required fields are complete.

## Surfaces To Review

Review these public-entry and trust surfaces as a cold outside reader:

1. `README.md`
2. `CHARTER.md`
3. `docs/getting-started/first-run.md`
4. `docs/evidence/publication-evidence.md`
5. `docs/evidence/publication-blocker-coverage.md`
6. `docs/runbooks/release-cutover-authorization.md`
7. `docs/runbooks/public-release-runbook.md`

Optional supporting context:

- `docs/runbooks/agent-lane-compatibility.md`
- `docs/runbooks/context-and-model-routing.md`
- `docs/stories/public-journey-and-redaction.md`

## Review Questions

Answer as someone who landed from social media or GitHub and is deciding
whether this project is trustworthy enough to inspect or try.

1. Does the README explain what Flywheel is without requiring private context?
2. Does the first-run guide make the public reduced-mode journey runnable?
3. Are Claude, Codex, Gemini, and OpenClaw claims honest about compatibility
   versus runtime proof?
4. Does the repo show enough receipts, tests, and gates to trust the method?
5. Are any claims too broad, too private, or not backed by a command?

## Acceptable Verdicts

- `approved`: no release-blocking changes requested.
- `approved_with_followups`: release may proceed after named followups are
  tracked or classified non-blocking.

Any `changes_requested`, `unclear`, missing verdict, missing reviewer metadata,
or non-empty `blocking_findings` array reopens or keeps TP-015 open.

## Review Log Row Shape

Start from the pending template if useful:

```bash
cp .flywheel/PLANS/public-share-readiness-2026-05-12/review-log.template.jsonl \
  .flywheel/PLANS/public-share-readiness-2026-05-12/review-log.jsonl
```

Append exactly one JSON object per reviewer:

```json
{
  "schema_version": "flywheel.external_review.v0",
  "reviewer_id": "stable-non-joshua-reviewer-id",
  "reviewer_kind": "external_agent_or_human",
  "reviewed_at": "2026-05-13T00:00:00Z",
  "verdict": "approved_with_followups",
  "reviewed_surfaces": [
    "README.md",
    "CHARTER.md",
    "docs/getting-started/first-run.md",
    "docs/evidence/publication-evidence.md",
    "docs/evidence/publication-blocker-coverage.md",
    "docs/runbooks/release-cutover-authorization.md",
    "docs/runbooks/public-release-runbook.md"
  ],
  "blocking_findings": [],
  "followups": [
    "short concrete followup, or empty array"
  ],
  "comments": [
    "short rationale"
  ]
}
```

Validate with:

```bash
python3 scripts/validate_external_review.py --json
python3 scripts/validate_external_review.py --release --json
bash tests/external-review-gate.sh
```

The normal validator mode may return `status=blocked` with exit code 20 while
reviews are pending. Release mode must return exit 0 before TP-015 closes.
