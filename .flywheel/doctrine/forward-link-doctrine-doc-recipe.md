---
title: "Forward-Link Doctrine Doc Recipe (memory-without-cross-link wire-in canonical pattern)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Forward-Link Doctrine Doc Recipe

Version: `forward-link-doctrine-doc-recipe/v1`
Owner: orchestrator + workers handling `gap-memory-without-cross-link` beads
Status: canonical, shipped 2026-05-11 (N=4+ recurrence threshold met)
Source bead: flywheel-pmg3c (P2 skill-promotion-N4)

## TL;DR

When `gap-hunt-probe` flags a memory file with `memory-without-cross-link`
class (memory not cited by sampled commands/doctrine/incidents/plans), the
canonical fix is a **forward-link doctrine doc** at `.flywheel/doctrine/`
that cites the memory by filename in the opening reference line + documents
the discipline in deployment-ready terms + lists referenced
commands/scripts/L-rules.

This recipe is **auto-injected** into dispatch packets for
`[gap-memory-without-cross-link]` beads via
`.flywheel/scripts/inject-forward-link-recipe.sh`. Workers do not need to
re-discover the recipe; it appears in the dispatch packet as
`## FORWARD-LINK DOCTRINE DOC RECIPE BLOCK`.

## Recurrence threshold (N=4+ MET)

Confirmed instances (worker / date / disposition):

| N | Bead | Memory | Worker | Disposition |
|---|---|---|---|---|
| 1 | flywheel-2xdi.93 | (test-files-corpus) | MistyCliff | 1:1 forward-link |
| 2 | flywheel-2xdi.109 | dispatch-post-send-verify-silent-deaf | MistyCliff | 1:1 forward-link |
| 3 | flywheel-2xdi.116 | jeff-corpus-substrate-lifecycle | MistyCliff | 1:1 forward-link |
| 4 | flywheel-2xdi.118 | jsm-canonical-auth-contract | MistyCliff | 1:1 forward-link |
| 5 | flywheel-2xdi.110 | parallel-impl-self-validates-via-p2-receipts | MagentaPond | 1:1 forward-link |
| 6 | flywheel-2xdi.117 | jeff-response-shape-5-reshaped | MagentaPond | NOT-YET-PROMOTED sub-pattern |
| 7 | flywheel-2xdi.125 | l91-auto-retry-helper-failed | MagentaPond | CLUSTER-ANCHOR sub-pattern (5-memory cluster) |

7 confirmed instances. Recurrence threshold N=4 deeply exceeded.

## The recipe (canonical 4-step + 3 sub-patterns)

### Base recipe (1:1 forward-link)

1. **Read memory file**
   `~/.claude/projects/-Users-josh-Developer-flywheel/memory/<name>.md`

2. **Create doctrine doc** at `.flywheel/doctrine/<descriptive-name>.md`:
   - Frontmatter: `title` / `type: doctrine` / `created: <date>` / `frontmatter_source: scaffold-doc-frontmatter`
   - Version line + owner + status + source bead
   - **TL;DR**: 1-paragraph canonical summary
   - **Canonical memory source**: explicit cite of memory filename
   - **The pattern**: Why / How to apply
   - **Anti-pattern**: what NOT to do
   - **Behavioral vs name cross-linking**: surface where the discipline IS embedded vs why probe's name-grep misses it
   - **Sister doctrine**: cross-links (3+ entries)
   - **Conformance**: 3-5 step proof contract
   - **Below-trauma-class tracking**: instance count + promotion path

3. **Verify** corpus 4 (`skill_md_corpus`) or doctrine-corpus now contains
   the memory filename via grep.

4. **Commit + br close + callback**.

### Sub-pattern A: 1:1 forward-link (default)

Use when one memory documents one discipline that is load-bearing in 1-2
runtime surfaces. Examples: 2xdi.109 (silent-deaf), 2xdi.110 (parallel-impl P2).

### Sub-pattern B: CLUSTER-ANCHOR (introduced 2xdi.125)

Use when one memory explicitly cites 3+ sibling memories as part of a
trauma-class cluster. Single doctrine doc anchors the cluster table; future
beads on sibling memories close as `MOOT-BY-CLUSTER-ANCHOR` referencing the
single anchor doctrine.

Example: 2xdi.125 anchors the 5-memory codex+tmux-stdin trauma cluster
(L91-auto-retry + rotate-stdin + chevron-visible + post-callback-input-deaf
+ enter-press-not-respawn) under one doctrine.

4x-efficient vs 1:1 forward-link when memories share a discipline class.

### Sub-pattern C: NOT-YET-PROMOTED (introduced 2xdi.117)

Use when the memory documents a PROPOSED future class that hasn't met its
own promotion threshold (e.g., "Promote to skill when 3rd outcome lands").
Ship the doctrine doc with `Below-trauma-class tracking` documenting the
0/N state explicitly. Defer the SKILL.md edit until threshold met (respect
the memory's own discipline).

Example: 2xdi.117's `RESHAPED-OUR-SCOPE` shape — proposed 5th Jeff-response
shape; jeff-issue-chain SKILL.md has evolved with DIFFERENT 5th + 6th shapes
(DESIGN-COLLAB v1.2 + CONFIRM-CONTRACT v1.4); memory's RESHAPED shape would
be 7th row pending 3rd RESHAPED outcome.

## Behavioral vs name cross-linking — why this recipe exists

Most of these memories' disciplines ARE load-bearing in runtime artifacts
(L-rules + scripts + canonical CLI + dispatch template), but the
gap-hunt-probe's `memory-without-cross-link` class only checks name-grep
across commands/doctrine/incidents/plans. The probe's name-grep is BLIND
to semantically-embedded discipline.

This recipe gives every flagged memory a NAME cross-link in
`.flywheel/doctrine/` so the probe class clears — without needing to
rewrite the load-bearing runtime artifacts.

Sister meta-pattern: `flywheel-xbsd8` (filed in 2xdi.110 evidence pack)
captures this `semantically-embedded-discipline-name-grep-blind-spot` for
faqj2 next-tick harvest. faqj2's self-calibration probe Phase 2 can
extend its finding-type taxonomy with
`semantically_embedded_discipline_no_memory_name_cite` to systematically
detect future instances.

## Anti-patterns

1. **Rewriting load-bearing runtime artifacts** (L-rules, scripts) just to
   inject memory-name strings — adds noise without behavior change. The
   forward-link doctrine doc IS the canonical cross-link; runtime artifacts
   stay clean.

2. **Skipping the recipe** and writing ad-hoc paragraph cites in
   AGENTS.md/INCIDENTS.md/README.md — those aren't probe-scanned at the
   same granularity. Doctrine-doc at `.flywheel/doctrine/` is the
   canonical surface.

3. **Filing N calibration beads for the recurring blind-spot class** —
   xbsd8 already owns the harvest. Per substrate-self-improving-loop, the
   3rd+ instance reinforces the class (data point), doesn't warrant a new
   bead.

4. **Bundling N memories into one doctrine doc** unless the memories are
   explicitly sister-class siblings (CLUSTER-ANCHOR sub-pattern). Each
   1:1-class memory deserves its own doctrine doc for findability.

## Sister doctrine

- `.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md`
  (instance N=2; 1:1 forward-link exemplar)
- `.flywheel/doctrine/parallel-impl-self-validates-via-p2-receipts.md`
  (instance N=5; 1:1 forward-link exemplar)
- `.flywheel/doctrine/respawn-is-canonical-recovery-for-codex-tmux-stdin-states.md`
  (instance N=7; CLUSTER-ANCHOR exemplar)
- `.flywheel/doctrine/jeff-response-shape-5-reshaped-our-scope.md`
  (instance N=6; NOT-YET-PROMOTED exemplar)
- `.flywheel/scripts/inject-forward-link-recipe.sh` (auto-injector wired
  into build-dispatch-packet.sh; this recipe lives in the dispatch loop)
- `flywheel-xbsd8` (meta-class harvest target for faqj2 next-tick)

## Conformance

A `gap-memory-without-cross-link` worker close proves conformance via:

- Dispatch packet contains `## FORWARD-LINK DOCTRINE DOC RECIPE BLOCK`
  (auto-injected via `.flywheel/scripts/inject-forward-link-recipe.sh`)
- Evidence pack lists which sub-pattern was used (1:1 / CLUSTER-ANCHOR /
  NOT-YET-PROMOTED)
- New doctrine doc exists at `.flywheel/doctrine/<name>.md` with memory
  filename cited in opening reference line
- Corpus 4 (skill_md_corpus) or doctrine-corpus now contains memory
  filename via grep (post-patch verification command)
- Callback envelope includes `journey_entry_path=.flywheel/journal/<bead>.md`
  documenting which sub-pattern + posterior shape

## Substrate-self-improving loop integration

This recipe IS the substrate-self-improving loop in action for the
memory-without-cross-link class:

1. gap-hunt-probe flags memory (instance N+1)
2. Dispatch packet auto-injects recipe (no re-discovery)
3. Worker applies recipe with appropriate sub-pattern
4. Doctrine doc ships
5. Next probe run clears the gap class

Per `feedback_accretive_leverage.md` (Axiom 8): the recipe is reusable
across workers, harvested into the substrate, no manual leverage per bead.

## Tracking metadata

- Recurrence count at promotion: 7 (N≥4 threshold MET)
- Promoted to canonical: 2026-05-11 via flywheel-pmg3c
- Auto-injection live in: `.flywheel/scripts/inject-forward-link-recipe.sh`
  (wired into `.flywheel/scripts/build-dispatch-packet.sh`)
- Skill location: this doctrine doc + injector script + meta-class harvest
  bead (xbsd8) form the canonical surface; no standalone skill at
  `~/.claude/skills/` (per option C — auto-injected, not invoke-on-demand)


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
