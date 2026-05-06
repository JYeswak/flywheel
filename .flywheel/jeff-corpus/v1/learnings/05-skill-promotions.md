# Jeff Corpus Skill And L-Rule Promotion Staging - Phase 5
bead: flywheel-w3pr.3
generated_at: 2026-05-04T10:26:00Z
status: approval_only_staged

## Receipt
- Phase 4 synthesis: `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`
- Staging root: `.flywheel/jeff-corpus/v1/promotions/`
- Live skills modified: none
- Live AGENTS.md modified: no
- Staged skill drafts: 5
- Candidate L-rule artifact: `.flywheel/jeff-corpus/v1/promotions/l-rules/candidate-l-rules.md`

## Staged Skill Drafts
| draft | Phase 4 verdict | staged path | promotion dependency |
|---|---|---|---|
| validation-fixture-contract | ADOPT | `.flywheel/jeff-corpus/v1/promotions/skills/validation-fixture-contract/SKILL.md` | `flywheel-0egk` |
| doctor-repair-triad | EXTEND | `.flywheel/jeff-corpus/v1/promotions/skills/doctor-repair-triad/SKILL.md` | `flywheel-hn8e` |
| mutation-safety-contract | EXTEND | `.flywheel/jeff-corpus/v1/promotions/skills/mutation-safety-contract/SKILL.md` | `flywheel-l1vl` |
| failure-taxonomy-receipts | ADOPT | `.flywheel/jeff-corpus/v1/promotions/skills/failure-taxonomy-receipts/SKILL.md` | `flywheel-esdx` |
| cli-surface-registry | ADOPT | `.flywheel/jeff-corpus/v1/promotions/skills/cli-surface-registry/SKILL.md` | `flywheel-ryzt` |

Each staged skill draft includes at least three repo/file/line citations and
its Phase 4 verdict. These are review artifacts only; do not install them into
`~/.claude/skills/` without Joshua approval.

## Candidate L-Rules
| candidate | Phase 4 verdict | dependency | staged path |
|---|---|---|---|
| Mutation Surfaces Must Carry Safety Receipts | EXTEND | `flywheel-l1vl` | `.flywheel/jeff-corpus/v1/promotions/l-rules/candidate-l-rules.md` |
| Active Runtime Parity Requires Runtime-Verified Proof | EXTEND | `flywheel-8qix` | `.flywheel/jeff-corpus/v1/promotions/l-rules/candidate-l-rules.md` |
| Corpus Work Is Not Done Until It Is Consumable | EXTEND | existing Jeff corpus tests plus recurrence threshold | `.flywheel/jeff-corpus/v1/promotions/l-rules/candidate-l-rules.md` |
| Validation Claims Require Replayable Fixtures | ADOPT | `flywheel-0egk` | `.flywheel/jeff-corpus/v1/promotions/l-rules/candidate-l-rules.md` |
| Operational Substrate Must Expose Doctor, Health, And Repair | EXTEND | `flywheel-hn8e` | `.flywheel/jeff-corpus/v1/promotions/l-rules/candidate-l-rules.md` |

These are not numbered canonical L-rules. They are candidate text for a future
Joshua-approved doctrine bead after local implementation evidence lands.

## No-Promotion Reasons
| high-frequency pattern | Phase 4 verdict | no-promotion reason |
|---|---|---|
| Generic callback envelope shape | DIVERGE | Flywheel must preserve DONE/BLOCKED, DID/DIDNT/GAPS, delivery verification, no-bead, and fuckup fields. Promote validation helpers, not a generic envelope replacement. |
| Generic success/status semantics | DIVERGE | Flywheel validation has richer states: pass, fail, unknown, missing artifact, invalid callback, context drift, no-bead reason, tick-punted, and callback-delivery-verified. |
| Bottom-ranked conceptual/demo repos | AVOID | Many are essays, demos, or tiny experiments; useful conceptually, but not operational substrate exemplars without separate validation. |
| Prose-only documentation as proof | AVOID | Three-Q doctrine already rejects documentation without mechanical validation and surfacing. No new promotion is needed beyond enforcing existing L71/L80/L81. |
| One-off scripts without runnable repair/test surfaces | AVOID | Treat as anti-pattern until a doctor/health/repair or fixture-backed surface exists. |

## Promotion Preconditions
- Joshua approval for live skill installation or canonical L-rule numbering.
- The dependency bead for each candidate has passed its own acceptance gates.
- Each live promotion keeps the source citations and adds local flywheel evidence.
- Any JSM-managed live skill update must use the JSM workflow, not direct edits.

## Three-Q Check
- VALIDATED: staged paths exist, each staged candidate cites Phase 4 verdict plus three or more source citations, and live doctrine/skills were not modified.
- DOCUMENTED: this file and `.flywheel/jeff-corpus/v1/promotions/README.md` define approval-only staging.
- SURFACED: promotion dependencies are mapped to existing or newly filed `jeff-corpus-derived` beads from Phase 4.
