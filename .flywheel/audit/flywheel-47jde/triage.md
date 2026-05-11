# Jeff signal triage: letter_learning_game — flywheel-47jde

**Date**: 2026-05-11 | **Bead**: flywheel-47jde (P3) | **Identity**: MistyCliff
**Source signal**: `github-repos` detector @ 2026-05-10T12:04:06Z
**Signal class**: `new-tool` (auto-classified)
**Upstream**: https://github.com/Dicklesworthstone/letter_learning_game

## Repo shape

Per `gh repo view`:
- Primary language: **HTML** (545,667 bytes — single index.html)
- Description: "Educational game for children learning letters and the alphabet"
- Stars: 1 | Created: 2025-09-08 | Last push: 2026-03-22

Contents (per GitHub API):
- index.html (545,667 bytes — single-file app per README)
- README.md, CHANGELOG.md, LICENSE
- package.json (188 bytes) — `"build": "echo 'Static site - no build needed'"`
- gh_og_share_image.png (social preview)

Per README: "single-file app: everything is implemented in `index.html`". Modes: Find Letters, Word Builder, Tracing Practice. Uses browser SpeechSynthesis API + localStorage. NO backend, NO build pipeline, NO scripts.

## Signal-class correction

Detector classified as `new-tool`. **Misclassification — same class as flywheel-j6z2e (kissinger_undergraduate_thesis)**: detector treats any new Jeff repo as `new-tool`, but this is a **single-page web app** (child-facing educational toy), not a developer tool.

## Disposition: NO ACTION

4-hypothesis evaluation matrix:

| Apply-to-flywheel hypothesis | Verdict | Reason |
|---|---|---|
| Mirror for flywheel reuse | NO | Single HTML file, no scripts, no automation surface |
| Extract doctrine | NO | Child education subject matter; no fleet/orchestration doctrine |
| Substrate upgrade | NO | No substrate primitives (just a kids' game) |
| Skill upgrade | NO | Game logic is child-pedagogy specific (phonics flow, letter tracing) — not transferable to flywheel skills |

## Recommendations

1. **Detector tuning**: same finding as flywheel-j6z2e — the `github-repos` `new-tool` classifier doesn't filter out **single-file static web apps** (HTML-primary, no build pipeline, no scripts directory). Two j6z2e/47jde false positives in the same detector batch is convergent evidence.
2. **Skip-list candidate**: add `letter_learning_game` alongside `kissinger_undergraduate_thesis` to the detector's skip set.
3. **Anti-pattern signature**: when primary_language == "HTML" AND package.json contains "Static site - no build needed" AND no scripts directory exists, classify as `static-content` not `new-tool`.

## Acceptance

Generic bead AC ("evaluate this Jeff signal"). Evaluation complete:

- ✅ Repo identified and inspected (gh repo view + contents listing)
- ✅ Substrate-relevance assessed across 4 hypotheses (mirror/doctrine/substrate/skill); all NO
- ✅ Convergent-with-j6z2e finding captured (same detector false-positive class)
- ✅ Skip-list recommendation + anti-pattern signature for detector tuning

## Artifacts

- `upstream-repo-metadata.json` — `gh repo view` JSON
- `upstream-file-listing.txt` — GitHub API contents listing
- `triage.md` (this file) — disposition + reasoning
