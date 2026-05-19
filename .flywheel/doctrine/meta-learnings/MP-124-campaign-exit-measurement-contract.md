# MP-124 - Campaign exit measurement contract

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Growth automations need one job per message or offer, explicit segmentation, provider fit, exit rules, measurement, and a no-live-send boundary.

## Where it applies

Email sequences, referral programs, promo-code research, lifecycle campaigns, provider selection, deliverability setup, campaign A/B tests, and any outbound or incentive workflow.

## Adoption signal

The skill defines the campaign trigger, audience segment, one primary action, provider or channel decision, authentication and deliverability prerequisites, exit conditions, experiment plan, and approval boundary before sending or redeeming anything.

## Exemplar skills (>=5)

- `~/.claude/skills/email-sequence/SKILL.md:26` - each email has one job and value comes before the ask.
- `~/.claude/skills/email-sequence/SKILL.md:42` - sequence design includes map, timing, segmentation, exit conditions, and measurement.
- `~/.claude/skills/email-sequence/SKILL.md:107` - exit conditions are a first-class sequence concern.
- `~/.claude/skills/email-sequence/SKILL.md:121` - deliverability depends on SPF, DKIM, DMARC, list hygiene, and warmup.
- `~/.claude/skills/email-sequence/SKILL.md:160` - A/B tests change one element over a defined window.
- `~/.claude/skills/referral-program/SKILL.md:10` - referral workflow assesses fit, selects type, designs incentives, implements, and tracks success.
- `~/.claude/skills/referral-program/SKILL.md:33` - shareability, value, friction, incentives, tracking, and fraud determine success.
- `~/.claude/skills/mailchimp-and-alternatives/SKILL.md:25` - provider fit uses audience complexity, sender reputation, and broadcast versus transactional needs.
- `~/.claude/skills/promo-code-finder/SKILL.md:40` - promo-code workflows must never fabricate, redeem, or ignore source truth.

## Adoption recipes

**Recipe 1 - Campaign contract:** define trigger, segment, primary CTA, cadence, exit conditions, and owner approval for live actions.

**Recipe 2 - Channel/provider fit:** choose provider by audience complexity, reputation, transactional needs, pricing, and API limits.

**Recipe 3 - Measurement loop:** predeclare metrics, A/B variable, observation window, fraud checks, and success threshold.

## Compliance test

```bash
grep -E "(segment|one job|exit|measurement|deliverability|SPF|DKIM|DMARC|A/B|provider|approval)" SKILL.md || exit 1
```
