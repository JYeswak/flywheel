# MP-98 - Customer-signal to root-cause loop

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Customer-facing workflows should convert individual messages, tickets, disputes, bounces, and no-shows into structured signals for routing, SLA enforcement, and systemic root-cause detection.

## Where it applies

Support triage, billing disputes, incident communication, email delivery, appointment reminders, churn risk, account management, and service recovery.

## Adoption signal

The workflow classifies signals on multiple axes, routes by expertise and urgency, enforces SLA clocks, records evidence, and escalates repeated categories as product or process issues.

## Exemplar skills (>=5)

- `~/.claude/skills/ticket-triage/SKILL.md:46` - every ticket is classified along three independent axes before routing.
- `~/.claude/skills/ticket-triage/SKILL.md:82` - priority is a composite score from severity, tier, impact, sentiment, and recency.
- `~/.claude/skills/ticket-triage/SKILL.md:118` - escalation triggers can be detected automatically without human judgment.
- `~/.claude/skills/customer-communication/SKILL.md:58` - every customer message requires decisions across five domains.
- `~/.claude/skills/customer-communication/SKILL.md:145` - messages are personalized from available customer context.
- `~/.claude/skills/billing-dispute-resolution/SKILL.md:30` - repeated billing disputes are product, process, or communication failures.
- `~/.claude/skills/billing-dispute-resolution/SKILL.md:170` - dispute outcomes feed pattern detection after closeout.
- `~/.claude/skills/email-delivery/SKILL.md:98` - bounce, complaint, and unsubscribe webhooks must be processed.
- `~/.claude/skills/appointment-scheduling/SKILL.md:96` - high no-show risk changes reminder cadence and backfill strategy.

## Adoption recipes

**Recipe 1 - Multi-axis signal:** classify category, urgency, customer tier, sentiment, business impact, and recurrence.

**Recipe 2 - SLA clock:** attach first-response and resolution timers to priority classes with breach triggers.

**Recipe 3 - Pattern escalation:** after repeated category thresholds, create a root-cause work item beyond the individual customer response.

## Compliance test

```bash
grep -E "(classif|priority|SLA|escalat|pattern|customer|dispute|bounce|no-show|root cause)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-50-formal-feedback-friction-loop.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-08-trauma-class-promotion.md`
