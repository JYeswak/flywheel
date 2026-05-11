# Jeff signal triage: kissinger_undergraduate_thesis — flywheel-j6z2e

**Date**: 2026-05-11 | **Bead**: flywheel-j6z2e (P3) | **Identity**: MistyCliff
**Source signal**: `github-repos` detector @ 2026-05-10T12:04:06Z
**Signal class**: `new-tool` (auto-classified)
**Upstream**: https://github.com/Dicklesworthstone/kissinger_undergraduate_thesis

## Repo shape (what it actually is)

Per `gh repo view`:
- Primary language: **HTML** (161,344 bytes; no other languages)
- Description: "Digital edition of Kissinger's 400-page 1950 Harvard thesis: OCR'd and LLM-cleaned from scans, with HTML/EPUB/Kindle formats, interactive mindmap, enriched footnotes, and a reader UI"
- Visibility: PUBLIC | Stars: 47 | Created: 2025-08-30 | Last push: 2025-09-03

Contents (per GitHub API):
- README.md, index.html, kissinger_thesis.{html,epub,azw3,mobi}
- *_pdf_mindmap.html, *_pdf_mindmap_outline.{html,md}, *_pdf_summary.{html,md}
- assets/ (PWA icons + social preview images)
- docs/ (Markdown sources)
- favicon.svg, site.webmanifest, safari-pinned-tab.svg

**NO scripts**, NO programmatic API, NO substrate. It is a static-content publication of a historical thesis.

## Signal-class correction

Detector classified this as `new-tool`. **Misclassification.** The repo is an **OUTPUT artifact** of two adjacent tools (cited in its README):

1. **mindmap-generator** (https://github.com/Dicklesworthstone/mindmap-generator) — the open-source tool used to generate the mindmap
2. **FixMyDocuments** (https://fixmydocuments.com) — closed/hosted service used to generate the mindmap and summary

`mindmap-generator` was already triaged in flywheel substrate research at `.flywheel/PLANS/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-B-PRIME.md:261`:

> `mindmap-generator` | Mindmap utility. | N | App/tool, not audit loop.

→ Already classified as **not flywheel-relevant** (per prior research). The Kissinger thesis repo is a downstream artifact, even less relevant than the underlying tool.

## Disposition: NO ACTION

Per per-class evaluation:

| Apply-to-flywheel hypothesis | Verdict | Reason |
|---|---|---|
| Mirror for flywheel reuse | NO | No code/scripts to mirror; static HTML content |
| Extract doctrine | NO | Subject matter (Kissinger thesis) is historical political philosophy, not fleet/orchestration doctrine |
| Substrate upgrade | NO | No substrate primitives present |
| Skill upgrade | NO | The "skill" (OCR + LLM-cleanup + mindmap generation) lives in mindmap-generator (already triaged out) + FixMyDocuments (proprietary hosted) |

## Recommendations

1. **Detector tuning** (out-of-scope for this bead but recommended): the `github-repos` detector's `new-tool` classifier should look beyond "Jeff just created a new repo" and probe whether the repo has scripts/binaries/APIs OR is just a content publication. The current classifier produced this false positive.
2. **Skip-list candidate**: add `kissinger_undergraduate_thesis` to whatever `.flywheel/state/jeff-repos-skip.json` (or equivalent) exists, so future scans don't re-file this.
3. **Adjacent signal already resolved**: `mindmap-generator` (the actual tool) was triaged in 2026-05-03 prior-research and marked not-flywheel-relevant. No follow-up needed on that path either.

## Acceptance

The bead acceptance section is generic ("evaluate this Jeff signal"). The evaluation is complete:

- ✅ Repo identified and inspected (gh repo view + contents listing)
- ✅ Substrate-relevance assessed across 4 hypotheses (mirror/doctrine/substrate/skill); all NO
- ✅ Adjacent signal cross-referenced (mindmap-generator already triaged 2026-05-03)
- ✅ Disposition documented + skip-list recommendation captured

## Artifacts

- `upstream-repo-metadata.json` — `gh repo view` JSON
- `upstream-file-listing.txt` — full GitHub API contents listing
- `triage.md` (this file) — disposition + reasoning
