## L96 — DOCTRINE-LANDS-AS-3-SURFACE-DIFF-OR-DOES-NOT-LAND

---
id: L96
title: Doctrine lands as 3-surface diff or does not land
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: canonical-doctrine-single-surface-drift
---

Any canonical L-rule edit MUST land as one coherent three-surface diff in the same commit:

1. `AGENTS.md` root canonical operating doctrine.
2. `.flywheel/AGENTS-CANONICAL.md` repo-local canonical snapshot.
3. `templates/flywheel-install/AGENTS.md` install template for new repos.

If any of the three surfaces cannot be updated and verified in the same commit, the doctrine has not landed. The worker must leave the change uncommitted or file a blocker bead; it must not report a rule as canonical from a single surface.

**Why:** L93-L95 appeared in canonical and template surfaces while the root doctrine path was treated as a separate afterthought in the orchestration narrative. That creates split-brain instructions: new repos and local snapshots can carry rules that the root AGENTS.md contract does not visibly own, or root can move ahead while installs stay stale. Donella #4 and #6: change the system rule and the information flow, not just one artifact.

**How to apply:** every doctrine commit must include a 3-surface receipt equivalent to `for f in AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md; do rg '^## L[0-9]+' "$f"; done` plus a divergence probe showing `doctrine_3_surface_divergent_count=0`. The diff review should prove the same L-rule IDs exist on all three surfaces before the commit is allowed.

Doctor must expose `doctrine_3_surface_divergent_count`, `missing_in_agents_md`, `missing_in_template`, and `missing_in_canonical`. Strict doctor fails when the divergent count is nonzero, and doctor-signal promotion files a bead automatically for the drift class.

**Forbidden outputs:**
- "L96 landed" when only one or two of the three surfaces changed.
- "Template will be updated later" without a blocker bead and explicit `blocked_by=`.
- Root-only, canonical-only, or template-only doctrine commits for active L-rules.
- Reporting doctrine propagation complete without a machine-readable 3-surface divergence receipt.

**Cross-references:** L50 (socraticode-mandatory dispatch), L56 (promotion ladder), L61 (ecosystem wire-in), L70 (same-tick chain-forward), L71 (validate-and-redispatch), L93-L95 (same-day drift evidence), `doctrine-3-surface-divergence-probe.sh`, and `feedback_no_ad_hoc_per_repo_doctrine_edits.md`.

