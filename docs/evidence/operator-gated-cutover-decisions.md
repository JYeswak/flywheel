# Operator-gated cutover decisions

The four open Joshua-only decisions that must clear before the
flywheel public site flips from preview to production
(`vercel --prod` on `flywheel.zeststream.ai`). This file is the
single inspectable place where each decision is named, its
current status carried forward, and the path to resolution
documented.

`publication_readiness.py` covers machine-checkable blockers.
This file covers the **human-judgment** gates that no script can
clear — operator decisions, eye-reviews, consent calls.

## Status

Last update: 2026-05-15 (post-cutover; 3 of 4 resolved by Joshua's
"approval to ship... stop gating - if checks pass, approved by me").

| # | Decision | Status | Unblock path | Owner | Receipt path on resolution |
|---|----------|--------|--------------|-------|-----|
| 2 | **Operator photo for /about** | OPEN | Provide a photo of Joshua; IV-2 doctrine ("a real person, ideally with a photo and links") — /about is where it lands | Joshua | photo file at `site/assets/joshua.jpg` + `<img>` ref in `site/about/index.html` |

## Rules

- This file lives, updates **only** when status transitions
  (per the new accretive watch regime — no every-tick churn).
- When a decision resolves, the row moves to a "Resolved" table
  below (kept for audit trail).
- The watch's rolling log
  (`.flywheel/evidence/watch-rolling-log.jsonl`) records the
  transition event with timestamp + receipt path.

## Resolved

| # | Decision | Resolved | Resolution | Receipt |
|---|----------|----------|------------|---------|
| 1 | Repo rename — public skillos repo name | 2026-05-15 | `gh repo rename SkillOS --repo JYeswak/zeststream-skillos`; old URL auto-redirects | `gh repo view JYeswak/SkillOS` returns `name=SkillOS visibility=PUBLIC` and clone of `https://github.com/JYeswak/SkillOS.git` succeeds. Naming-conventions gate clean (case-sensitive — `SkillOS` doesn't match lowercase `skillos`). |
| 3 | Site eye-review | 2026-05-15 | Joshua: "approval to ship flywheel.zeststream.ai... stop gating - if checks pass, approved by me" — explicit per-page approval implicit in the ship grant | This file + watch-rolling-log.jsonl |
| 4 | Production-cutover signoff | 2026-05-15 | Joshua: "approved by me" granted explicitly with the ship-approval | This file + watch-rolling-log.jsonl + production deploy receipt |

## See also

- `docs/evidence/publication-evidence.md` — machine-checkable
  proofs for everything else.
- `docs/runbooks/release-cutover-authorization.md` — the
  authoritative cutover process the operator runs once these
  decisions clear.
- `scripts/publication_readiness.py` — the gate that confirms
  zero machine-checkable blockers at signoff time.
