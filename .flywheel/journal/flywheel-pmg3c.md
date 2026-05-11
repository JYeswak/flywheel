---
bead: flywheel-pmg3c
title: skill-promotion-N4 forward-link-doctrine-doc-recipe → canonical surface via auto-route hook
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P2
mission_fitness: adjacent
disposition: Option C SHIPPED — recipe doctrine doc + auto-injector wired into build-dispatch-packet.sh
recurrence_at_promotion: 7 (threshold N≥4 met)
substrate_self_improving_loop: CLOSED for memory-without-cross-link class
---

# Journey: flywheel-pmg3c

## What the bead asked for

P2 skill-promotion-N4: promote the forward-link-doctrine-doc recipe pattern to
a canonical surface after 4+ confirmed instances. Choose between:
- A. Standalone skill at `~/.claude/skills/forward-link-doctrine-doc-recipe/`
- B. Add to existing flywheel skill
- C. Auto-route hook in dispatch packet (bead's framing: "highest-leverage")

## Decision: Option C with canonical-doctrine source-of-truth

Selected C because:
1. **Zero re-discovery** per bead — recipe lives in dispatch loop
2. **Single source-of-truth** in `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md`; injector references it; in-packet block summarizes it
3. **Substrate-loop alignment** (Axiom 8 Accretive Leverage)
4. **Lowest cognitive cost** — workers see recipe in-band, no Skill tool invocation
5. **Builder-pattern alignment** — follows existing `inject-l-rule-hints.sh` / `inject-skill-auto-routes.sh` / `inject-memory-hits.sh` shape

## Recurrence at promotion: N=7

Instances confirmed across 2 workers (MistyCliff + MagentaPond) across 5
memory classes:

| # | Bead | Memory | Worker | Sub-pattern |
|---|---|---|---|---|
| 1 | flywheel-2xdi.93 | test-files-corpus | MistyCliff | 1:1 forward-link |
| 2 | flywheel-2xdi.109 | dispatch-post-send-verify | MistyCliff | 1:1 forward-link |
| 3 | flywheel-2xdi.116 | jeff-corpus-substrate-lifecycle | MistyCliff | 1:1 forward-link |
| 4 | flywheel-2xdi.118 | jsm-canonical-auth-contract | MistyCliff | 1:1 forward-link |
| 5 | flywheel-2xdi.110 | parallel-impl-self-validates-via-p2-receipts | MagentaPond | 1:1 forward-link |
| 6 | flywheel-2xdi.117 | jeff-response-shape-5-reshaped | MagentaPond | NOT-YET-PROMOTED (introduced) |
| 7 | flywheel-2xdi.125 | l91-auto-retry-helper-failed | MagentaPond | CLUSTER-ANCHOR (introduced) |

3 sub-patterns emerged organically during this session arc:
- **1:1 forward-link** (default; 5 of 7)
- **CLUSTER-ANCHOR** (2xdi.125; single doctrine doc anchors 5-memory cluster)
- **NOT-YET-PROMOTED** (2xdi.117; memory's own promotion threshold not met)

## What I shipped

### Canonical recipe doctrine doc
`.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` (240+ lines):
- N=7 instance table at promotion
- 4-step recipe (read memory → create doctrine → verify → commit/close/callback)
- 3 sub-patterns with exemplars
- Anti-patterns (4 explicit) + sister doctrine cross-links (5)
- Substrate-self-improving loop integration narrative

### Auto-injector script
`.flywheel/scripts/inject-forward-link-recipe.sh` (160+ lines):
- Canonical-CLI triad: `--help` / `--info` / `--schema` / `--examples` / `--doctor`
- Trigger detection: `[gap-memory-without-cross-link]` in bead title
- Injection point: before `## METADATA` (preserves canonical block ordering)
- Mechanism: awk file-read into recipe block
- Env-var escape: `FORWARD_LINK_RECIPE_DISABLED=1` for passthrough
- Sister pattern: inject-l-rule-hints.sh shape adopted, adds `--doctor` probe

### Wire-in
`.flywheel/scripts/build-dispatch-packet.sh` (3-line addition at line 936-938):
- Placed after `inject-l-rule-hints.sh` invocation
- Same `if [[ -x SCRIPT ]] && SCRIPT BODY ARGS >OUTPUT 2>/dev/null` shape
- Zero invasive changes

## End-to-end verification

5-step verification chain (all pass):
1. Syntax checks (both scripts: pass)
2. Canonical-CLI triad self-test (--info, --schema, --doctor all return clean JSON; doctor confirms `doctrine_doc: present, builder_wired: wired`)
3. Trigger detection positive case (real memory-without-cross-link dispatch: 0 → 1 FORWARD-LINK block; 54 lines added; placement before METADATA confirmed)
4. Trigger detection negative case (wired-but-cold class: 0 FORWARD-LINK blocks; correct passthrough)
5. Live packet generation via build-dispatch-packet.sh --apply: packet contains FORWARD-LINK block at line 212, METADATA at line 266, L-RULE HINTS at line 338 (correct ordering)

## Substrate-self-improving loop CLOSED

Per the dispatch packet auto-injection flow:
- Future `gap-memory-without-cross-link` bead → dispatch packet → auto-injects recipe → worker applies sub-pattern → doctrine ships → next probe clears the gap

The recipe lives in the dispatch loop, not in workers' memory. Workers do not
need to know the recipe before reading the dispatch packet. The substrate is
now self-teaching for this class.

This validates the entire substrate-self-improving loop framework:
1. faqj2 (meta-substrate Phase 1-3) — self-calibration probe
2. xbsd8 (semantically-embedded class harvest)
3. flywheel-pmg3c (THIS) — pattern→recipe→auto-route promotion

## Compliance

- AG receipt: 8/8
- Quality bar (P2): canonical-CLI triad complete + sister-injector pattern
  followed + end-to-end verification 5-step chain
- L52: 0 new beads filed; pattern promoted to substrate (no follow-up bead needed)
- Boundary preservation: only `.flywheel/doctrine/` + `.flywheel/scripts/` + `.flywheel/audit/` + journal
- L107: MCP-skipped (no live shared-surface conflicts; injector script + doctrine doc are new files)
- compliance_score: 1000/1000

## Future maintenance

When 8th+ instance recurs:
- No bead needed (substrate handles it auto-injection)
- Update N=7 → N=N+1 in `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` instance table (or defer to N=10 batch refresh)
- If a NEW sub-pattern emerges (4th beyond 1:1 / CLUSTER-ANCHOR / NOT-YET-PROMOTED): add to doctrine + injector recipe block

## Related substrate work

- `flywheel-faqj2` — meta-substrate self-calibration probe (Phase 1-3 shipped)
- `flywheel-xbsd8` — semantically-embedded-discipline harvest class
- `flywheel-ugali` — wired-but-cold corpus-1 self-ref class (sister-but-distinct)
- 7 sibling forward-link doctrine docs in `.flywheel/doctrine/`
