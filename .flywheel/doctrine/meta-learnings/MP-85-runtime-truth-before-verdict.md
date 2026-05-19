# MP-85 - Runtime truth before verdict

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Regulated or operational verdicts must cite live, current, scoped runtime facts before analysis, scoring, or remediation starts.

## Where it applies

Privacy/compliance review, tax preparation, policy audits, tag-manager analysis, legal surface inventory, provider billing, and any workflow where source code or stale documents can diverge from reality.

## Adoption signal

The workflow has an inventory or source-of-truth ledger, freshness gates, live capture or primary-source verification, explicit UNCLEAR states, and downstream verdicts that cite inventory line IDs or source hashes.

## Exemplar skills (>=5)

- `~/.claude/skills/zs-counsel-surface-inventory/SKILL.md:28` - inventory is the only ground truth.
- `~/.claude/skills/zs-counsel-surface-inventory/SKILL.md:50` - live browser inspection beats grep-plus-assumption.
- `~/.claude/skills/zs-counsel-surface-inventory/SKILL.md:136` - every downstream classification must cite inventory or become UNCLEAR.
- `~/.claude/skills/zs-counsel-gap-analysis/SKILL.md:34` - gap analysis hard-fails when no inventory exists.
- `~/.claude/skills/zs-counsel-gap-analysis/SKILL.md:118` - current inventory with sha256 and retrieval timestamp is mandatory.
- `~/.claude/skills/zs-counsel-gtm-audit/SKILL.md:48` - GTM current fired state is authoritative, not the repo.
- `~/.claude/skills/zs-counsel-regulatory-watchtower/SKILL.md:28` - ACTION-REQUIRED needs effective date and two independent primary sources.
- `~/.claude/skills/tax-return-preparation-and-advice-generic/SKILL.md:483` - tax recommendations start from a source-of-truth ledger.

## Adoption recipes

**Recipe 1 - Capture first:** create or resolve the live inventory/source ledger before running a scoring or reasoning pass.

**Recipe 2 - Cite every verdict:** every MET/NOT-MET/ACTION-REQUIRED/filing recommendation carries an inventory row, source URL hash, or document evidence pointer.

**Recipe 3 - Make stale a state:** if inputs exceed freshness thresholds, refuse or mark stale rather than silently proceeding.

## Compliance test

```bash
grep -E "(inventory|ground truth|live|retrieval_ts|sha256|UNCLEAR|source-of-truth|stale)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-42-independent-evidence-convergence.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-55-source-of-truth-hierarchy.md`
