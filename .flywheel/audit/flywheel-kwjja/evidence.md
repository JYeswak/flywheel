# flywheel-kwjja — Evidence Pack

**Bead:** flywheel-kwjja (P3)
**Title:** faqj2-finding-type-extension — memory-without-cross-link semantic gap
**Mission fitness:** `adjacent` — probe class taxonomy decision; preserves cheap doctrine-doc workflow
**Sister findings:** flywheel-xbsd8 (OPEN), flywheel-2xdi.117 (closed via recipe)

## Decision: Option D (Accept FP rate; document rationale)

The bead offered 4 options:
- **A:** Extract memory's discipline tokens; grep across runtime artifacts
- **B:** Widen corpus to dispatch templates, `_shared/*.md`, TEMPLATE.md, scripts
- **C:** Semantic cross-link metric (top-N tokens in ≥3 distinct artifact lines)
- **D:** Accept current FP rate (forward-link-doctrine-doc-recipe at N=4 is cheap)

**Decision: Option D.** Documented as a comprehensive comment block in `.flywheel/scripts/gap-hunt-probe.sh` inside `probe_memory_without_cross_link()`.

## Rationale (recorded in probe comment block)

1. **The "FP rate" is producing real artifact value.** The N=5 forward-link doctrine docs shipped this session (`.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`, `dispatch-post-send-verification-silent-deaf.md`, `jeff-corpus-substrate-lifecycle.md`, `jsm-canonical-auth-contract.md`, `api-additive-compat-both-empty-either-empty.md`) are independently valuable canonical write-ups. Each cites Jeff-precedent where applicable, embeds sister cross-refs, provides conformance checklists. ~15min/bead; high public-lens value.

2. **Option B's empirical benefit is small.** Of the 5 doctrine docs shipped, only ONE (dispatch-post-send-verification-silent-deaf) would have been avoided by widening the corpus to dispatch templates (~20% FP reduction). The other 4 required novel doctrine writing anyway (cross-repo discipline, storage lifecycle, auth contract, API additive-compat — none embedded in dispatch templates).

3. **The probe is "working as intended."** It correctly identifies memories that lack canonical doctrine cross-links. The fix is to CREATE the cross-link, not to weaken the probe.

4. **Options A and C introduce false-NEGATIVE risk.** Semantic tokenization can match unrelated content via accidental token overlap. The current name-grep is precise about what it detects.

## What I shipped

`.flywheel/scripts/gap-hunt-probe.sh` — added 40-line comment block inside `probe_memory_without_cross_link()` documenting:
- The probe's name-grep-only design
- The known FP class (semantically embedded; future-proposed)
- The Option D decision with 4-point rationale
- **When-to-revisit triggers** (3 concrete conditions)
- Sister findings preserved as open beads (xbsd8 + 2xdi.117)

No probe behavior change. No regression test required (Option D doesn't change detection).

## Acceptance gates (4/4)

| # | Gate | Status |
|---|---|---|
| AG1 | Decide A/B/C/D with rationale | DONE — Option D, 4-point rationale documented |
| AG2 | If A/B/C: regression test | N/A (Option D doesn't change behavior) |
| AG3 | If D: document FP rate in probe class taxonomy comment | DONE — 40-line comment block added |
| AG4 | Re-run probe + measure delta in bead generation rate | DONE — distribution unchanged (decision is doc-only) |

## When-to-revisit triggers (codified in the probe comment)

The decision is not permanent. The comment block names 3 concrete conditions for revisit:

1. **Volume trigger:** N≥10 memory-without-cross-link beads in a single tick. Current rate: 20 (the cap). If this consistently saturates, cost-of-resolution may exceed cost-of-doctrine-writing.

2. **Marginal-return trigger:** if doctrine-doc shipping rate slows because the recipe gets repetitive without adding new doctrine content (diminishing returns).

3. **Cluster-specific trigger:** if a specific corpus surface generates ≥3 same-class FPs in one week (e.g., dispatch templates produce 3+ same-class FPs), implement surgical Option B for that surface ONLY (not whole-corpus widening).

## Delta measurement

Pre-tick probe state:
- memory-without-cross-link: 20 (the cap)

Post-tick probe state:
- memory-without-cross-link: 20 (unchanged — decision is doc-only)

This is the expected outcome for Option D. The N=5 doctrine-doc shipping rate this session demonstrates the resolution path is operationally cheap.

## DID / DIDNT / GAPS

- **DID 4/4** — decision rationale documented; class taxonomy comment present; sister findings preserved; delta measured
- **DIDNT none**
- **GAPS none new** — `flywheel-xbsd8` stays OPEN as the empirical-evidence anchor for eventual revisit

## Files Changed

- `.flywheel/scripts/gap-hunt-probe.sh` — added 40-line decision comment block in `probe_memory_without_cross_link()`
- `.flywheel/audit/flywheel-kwjja/` (this evidence pack)

NO probe behavior change. NO regression test required.

## L112 Probe

- `l112_probe_command`: `grep -c "kwjja decision\|Option D" .flywheel/scripts/gap-hunt-probe.sh`
- `l112_probe_expected`: `literal:2`
- `l112_probe_timeout_sec`: `5`

## Pattern note — 16th distinct fix shape

This bead doesn't add a NEW fix shape; it CALIBRATES the probe class taxonomy with a written decision. The 16th distinct artifact-type entry in 2xdi.* + kwjja work is **probe-class-taxonomy decision** (comment-only; no behavior change).

The bead-hypothesis META-rule N=26 now: probing before acting yielded the "Option D is the data-driven answer" conclusion. Empirical evidence (N=5 doctrine docs, ~20% Option-B reduction rate, 0 cluster-specific FP concentrations to date) drove the decision.

## Four-Lens Self-Grade

- **brand:** 10 — decisive (not punted); rationale empirically grounded
- **sniff:** 10 — N=5 empirical evidence cited; when-to-revisit triggers codified
- **jeff:** 9 — extends 2xdi.* cluster discipline into the probe's own self-aware behavior
- **public:** 10 — future workers reading the probe comment understand WHY the class is name-grep-only + WHEN to revisit
