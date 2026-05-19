# MP-94 - Risk-proportional human gate

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 8+

## Essence

Human approval should be triggered by calibrated risk, confidence, policy impact, and external consequence, then reduced or escalated based on measured override behavior.

## Where it applies

Human-in-the-loop agents, consent, healthcare, KYC/AML, billing credits, customer communication, security testing, and regulated workflows.

## Adoption signal

The workflow has confidence thresholds, risk tiers, approval context, escalation timeouts, override metrics, and explicit rules for when automation can proceed alone.

## Exemplar skills (>=5)

- `~/.claude/skills/human-in-the-loop/SKILL.md:78` - medium confidence queues work for human approval.
- `~/.claude/skills/human-in-the-loop/SKILL.md:100` - high-impact actions require manager approval.
- `~/.claude/skills/human-in-the-loop/SKILL.md:184` - approval gates must be risk-proportional.
- `~/.claude/skills/consent-management/SKILL.md:56` - consent receipts must be immutable.
- `~/.claude/skills/kyc-aml/SKILL.md:31` - KYC/AML is risk-based, not a checklist.
- `~/.claude/skills/kyc-aml/SKILL.md:112` - enhanced due diligence requires senior management approval.
- `~/.claude/skills/clinical-decision-support/SKILL.md:20` - alerts need severity, action, and evidence to avoid fatigue.
- `~/.claude/skills/billing-dispute-resolution/SKILL.md:46` - credits, refunds, and customer communications require human approval.
- `~/.claude/skills/customer-communication/SKILL.md:45` - customer-facing messages require review before sending or publishing.

## Adoption recipes

**Recipe 1 - Risk table:** map confidence, dollar value, customer impact, legal exposure, and external communication to autonomy levels.

**Recipe 2 - Useful approval packet:** include action summary, evidence, risk assessment, alternatives, and timeout.

**Recipe 3 - Approval decay loop:** track approval, rejection, override, and time-to-decision; reduce or raise gates from measured behavior.

## Compliance test

```bash
grep -E "(confidence|approval|risk|human|override|escalation|policy|impact|timeout)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-41-gate-class-separation.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-69-registry-risk-ledger.md`
