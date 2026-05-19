---
title: "Option E: Cross-Orch Fuckup-Log Fold-Up (Mechanization Axis)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
n_trigger: 3
n_instances: 3
trigger_beads: flywheel-v38e1.1, flywheel-v38e1.3, flywheel-v38e1.4
status: canonical
canonical_class: mechanization-axis
mechanization_axis: E
sister_axes: A (full-automation), B (cluster-detection-in-gap-hunt-probe), C (intermediate), D (cheapest-doctrine-doc-first)
---

# Option E: Cross-Orch Fuckup-Log Fold-Up (Mechanization Axis)

Version: `option-e-cross-orch-fuckup-log-fold-up/v1`
Owner: flywheel:1 (canonical-locator orchestrator for fleet-wide doctrine)
Status: canonical, N=3 promotion-confirmed 2026-05-11
Source bead: `flywheel-nk0r0` (this bead)
N=3 trigger instances: `flywheel-v38e1.1`, `flywheel-v38e1.3`, `flywheel-v38e1.4`

## TL;DR

When N≥3 durable rules from a sister-orch's `~/.local/state/flywheel/fuckup-log.jsonl` promote to flywheel canonical doctrine via the same cohort dispatch wave (e.g. `v38e1.1/.2/.3/.4`), recognize the wave itself as a canonical mechanization pattern. Cross-orch fuckup-log fold-up is **Option E** in the mechanization-axis taxonomy. The fold-up doctrine names the meta-shape so future waves dispatch via the same scaffold.

## The mechanization-axis taxonomy

Established progressively across N=3 cluster-promotion arcs:

| Axis | Pattern | Source bead |
|------|---------|-------------|
| **A** | full automation (script-driven detection + filing) | reserved (no N=3 instance yet) |
| **B** | cluster-detection in gap-hunt-probe (auto-cluster-bead emit) | `cluster-maintainer-pattern.md` (follow-up candidate) |
| **C** | intermediate (partial mechanization) | reserved |
| **D** | cheapest mechanization (doctrine doc FIRST; automation later) | `kwjja` precedent, applied by `cluster-maintainer-pattern.md` |
| **E** | **cross-orch fuckup-log fold-up** (cohort-dispatch wave codifies sister-orch durable rules as flywheel-canonical) | `flywheel-nk0r0` (this doctrine) |

Axes are not mutually exclusive; a single arc may invoke multiple (e.g. v38e1 wave is D for individual rules + E at the cohort level).

## Rule (canonical)

```text
When N≥3 sibling beads in a flywheel-vXXXX.N cohort promote
distinct durable rules from a sister-orch's fuckup-log to flywheel
canonical doctrine WITHIN THE SAME SESSION, the wave invokes
Option E. The flywheel orch SHOULD:

  1. Confirm N≥3 sibling cohort closures (br show <parent>)
  2. Author a fold-up doctrine doc at .flywheel/doctrine/
     naming the meta-pattern (this doc is the v1 exemplar)
  3. Cross-reference EVERY sibling doctrine in the fold-up doc
  4. Add a 'mechanization_axis: E' frontmatter field to each
     sibling for forward-link reciprocity (deferred to v38e1.5)
  5. File a forward-link bead for the NEXT cohort wave so the
     scaffold dispatches faster on N+1 occurrence
```

## When to apply

- N≥3 sibling cohort beads (`<parent>.1`, `<parent>.2`, `<parent>.3`) all close DONE within a single session
- Each sibling promotes a distinct durable rule from a single sister-orch's `fuckup-log.jsonl`
- The cohort parent (`v38e1`) is explicit about "fleet-canonical N durable rules wave"
- The fold-up doctrine doesn't already exist

## Why it exists

The N=3 cluster-maintainer threshold catches recurring patterns. But cross-orch fuckup-log promotion is a **distinct shape** from the in-session cluster-fix pattern that `cluster-maintainer-pattern.md` codifies:

| Shape | Trigger | Scope |
|-------|---------|-------|
| Cluster-maintainer | N=3 same-skill batch fix | one skill, one session |
| Option E fold-up | N=3 promotion from sister-orch fuckup-log | cross-orch, multi-session (originated at sister-orch session, promoted at flywheel session) |

Without Option E codified, each cohort wave re-derives its own scaffold (rule-doc per sibling + ad-hoc cross-references). Option E freezes the scaffold + assigns ownership: every future `vXXXX.N` cohort gets the same fold-up doc + reciprocal frontmatter.

## v38e1 wave: the canonical N=3 instance

The Option E pattern crystallized when these 3 siblings (of 4 total in the wave) closed in sequence on 2026-05-11:

| Sibling | Source rule ts | Sister doctrine file |
|---------|----------------|----------------------|
| `flywheel-v38e1.1` | 12:12Z | `closure-evidence-contract-version-anchor.md` |
| `flywheel-v38e1.3` | 17:00Z | `inbox-discipline-missed-during-deep-burndown-motion.md` |
| `flywheel-v38e1.4` | 22:30Z | `outbox-discipline-cross-orch-ship-notification.md` |

(`flywheel-v38e1.2` is the 4th cohort member at 14:50Z; the N=3 trigger fires at 3 closures, and v38e1.2 is the +1 that bonds the wave.)

Each sibling cites the original skillos fuckup-log entry verbatim, includes a mechanization snippet, and cross-references its sister doctrines. The cohort parent `flywheel-v38e1` titled "fleet-canonical 4 durable rules from skillos fuckup-log → flywheel doctrine wave" was authored with explicit fold-up intent — this doctrine canonicalizes that intent.

## Forward-link to next wave

When the next `vXXXX` cohort emerges (e.g. another sister-orch fuckup-log batch), the flywheel orch dispatches:

```bash
# Hypothetical next wave: zXXXX cohort
br create --title "fleet-canonical N durable rules from <sister-orch> fuckup-log → flywheel doctrine wave" \
  --type task --priority 1
# Then N subordinates per rule per Option E scaffold
```

The scaffold:
1. Parent bead names cohort + sister-orch + count
2. N subordinate beads, one per durable rule, each promoting one rule
3. After N≥3 closures, author the fold-up doctrine doc (this one)
4. v38e1.5-style follow-up bead authors reciprocal cross-reference stubs

## Conformance

A fold-up doctrine conforms via:
- Body cites this Option E doctrine + N=3 sibling exemplars
- Each sibling doctrine has reciprocal cross-reference back to fold-up
- v38e1.5-style stubs catalog complete the link graph
- Promotion-from-sister-orch metadata preserved (ts + original handoff path)

## Lifecycle

This is canonical for cross-orch fuckup-log promotion waves. The pattern is empirically stable at N=3 (this session). When N=5 (next 2 cohort waves land in the fleet), promote to skill: `pattern-emerged-cross-orch-fuckup-log-fold-up-cohort-dispatch-scaffold`.

## Cross-references

- `cluster-maintainer-pattern.md` (sister mechanization axis, Option D)
- `inbox-discipline-missed-during-deep-burndown-motion.md` (sibling, v38e1.3 target)
- `outbox-discipline-cross-orch-ship-notification.md` (sibling, v38e1.4 target)
- `closure-evidence-contract-version-anchor.md` (sibling, v38e1.1 target)
- `closure-evidence-public-lens-anchor-discipline.md` (cohort member, v38e1.2 target)
- `forward-link-doctrine-doc-recipe.md` (related: forward-link discipline)
- `meta-aggregation-family.md` (related: cross-orch META-doctrine family)

## Sister-orch reference

The original 4 durable rules logged at `~/.local/state/flywheel/fuckup-log.jsonl` by `skillos:1` on 2026-05-11. Cohort promotion request landed via skillos handoff `20260512T000000Z-from-skillos-1-to-flywheel-1-WAVE-2-DOCTRINE-COHORT-PROMOTION-READY.md`. The 4 durable rules + this Option E fold-up doctrine together codify the bilateral cross-orch communication protocol that the v38e1 wave hardens.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
