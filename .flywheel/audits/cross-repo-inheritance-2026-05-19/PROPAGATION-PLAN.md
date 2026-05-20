# Cross-Repo Inheritance Propagation Plan — 2026-05-19

Phase 4a converts the Phase 4 audit findings into owner-lane handoff packets. Flywheel filed coordination packets only; consumer repos remain read-only in this phase.

## Source Receipt

- Audit summary: `.flywheel/audits/cross-repo-inheritance-2026-05-19/INHERITANCE.md`
- Audit JSONL: `.flywheel/audits/cross-repo-inheritance-2026-05-19/inheritance.jsonl`
- Phase 4 bead: `flywheel-hcjqf`
- Phase 4a bead: `flywheel-rn2d1`

## Filed Handoffs

| Target repo | Audit action | Gap | Handoff packet |
|---|---|---|---|
| alpsinsurance | PROPAGATE | 0/70 MPs; missing adoption/discrepancies receipts | `.flywheel/handoffs/20260519T0721Z-from-flywheel-to-skillos-propagate-mp-to-alpsinsurance.md` |
| agent-bench | PROPAGATE | 0/70 MPs; missing adoption/discrepancies receipts | `.flywheel/handoffs/20260519T0721Z-from-flywheel-to-skillos-propagate-mp-to-agent-bench.md` |
| frankensqlite | PROPAGATE | 0/70 MPs; missing adoption/discrepancies receipts | `.flywheel/handoffs/20260519T0721Z-from-flywheel-to-skillos-propagate-mp-to-frankensqlite.md` |
| ntm | PROPAGATE | 0/70 MPs; missing adoption/discrepancies receipts | `.flywheel/handoffs/20260519T0721Z-from-flywheel-to-skillos-propagate-mp-to-ntm.md` |
| vrtx | RECONCILE | 30 divergent MPs: MP-41..70 | `.flywheel/handoffs/20260519T0721Z-from-flywheel-to-skillos-reconcile-mp-divergence-vrtx.md` |
| picoz | RECONCILE | 30 divergent MPs: MP-41..70 | `.flywheel/handoffs/20260519T0721Z-from-flywheel-to-skillos-reconcile-mp-divergence-picoz.md` |

## Expected Close-Loop Receipts

For each PROPAGATE handoff, SkillOS should return:

- target repo and commit SHA
- propagated MP count, expected `70`
- `META-PATTERN-ADOPTION.md` path
- `DISCREPANCIES.md` path
- rerun audit row or equivalent verifier showing coverage and receipt status

For each RECONCILE handoff, SkillOS should return:

- target repo and commit SHA, if SkillOS mutates the repo
- per-MP decision list for MP-41..70
- classification counts for `canonical_wins`, `fork_merge`, and `accepted_divergence`
- rerun audit row or equivalent verifier showing divergence count after action

## Reconcile Decision Matrix

| Decision | When to use | Required receipt |
|---|---|---|
| canonical_wins | Repo file is stale copy of an older canonical MP; replace with flywheel canonical content. | Target commit plus post-run SHA match. |
| fork_merge | Repo-specific text carries useful canonical doctrine that should be merged upstream before target replacement. | Upstream merge commit or explicit follow-up bead, then target commit. |
| accepted_divergence | Repo intentionally keeps a domain-specific MP variant. | DISCREPANCIES.md entry naming rationale, review date, and verifier/XFAIL if applicable. |

## Non-Actions

- Did not write to alpsinsurance, agent-bench, frankensqlite, ntm, vrtx, picoz, or any other consumer repo.
- Did not start Phase 5 inventory rebuild.
- Did not attempt to decide canonical-vs-fork from Flywheel; SkillOS owns reusable doctrine propagation and canonical-locator decisions.
