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

Last update: 2026-05-15 (initial codification).

| # | Decision | Status | Unblock path | Owner | Receipt path on resolution |
|---|----------|--------|--------------|-------|-----|
| 1 | **Repo rename** — public skillos repo name | OPEN | `gh repo rename` `JYeswak/zeststream-skillos` → `JYeswak/SkillOS` (case-clean, gate-passing, resolves dead-link bug + naming-conventions gate in one move) | Joshua | `gh repo view JYeswak/SkillOS` post-rename + updated README/site reverts |
| 2 | **Operator photo for /about** | OPEN | Provide a photo of Joshua; IV-2 doctrine ("a real person, ideally with a photo and links") — /about is where it lands | Joshua | photo file at `site/assets/joshua.jpg` + `<img>` ref in `site/about/index.html` |
| 3 | **Site eye-review** — 6 rendered pages on preview | OPEN | Walk `flywheel-jyeswak-joshuas-projects-96d49291.vercel.app` and mark anything off; per-page approval | Joshua | per-page sign-off note appended to this file |
| 4 | **Production-cutover signoff** | OPEN — gated by 1–3 + `publication_readiness.py --release status=pass` | After 1–3 resolve, Joshua runs the cutover authorization in `docs/runbooks/release-cutover-authorization.md` | Joshua | `state/release-signoff.json` with explicit approval |

## Rules

- This file lives, updates **only** when status transitions
  (per the new accretive watch regime — no every-tick churn).
- When a decision resolves, the row moves to a "Resolved" table
  below (kept for audit trail).
- The watch's rolling log
  (`.flywheel/evidence/watch-rolling-log.jsonl`) records the
  transition event with timestamp + receipt path.

## Resolved

(none yet)

## See also

- `docs/evidence/publication-evidence.md` — machine-checkable
  proofs for everything else.
- `docs/runbooks/release-cutover-authorization.md` — the
  authoritative cutover process the operator runs once these
  decisions clear.
- `scripts/publication_readiness.py` — the gate that confirms
  zero machine-checkable blockers at signoff time.
