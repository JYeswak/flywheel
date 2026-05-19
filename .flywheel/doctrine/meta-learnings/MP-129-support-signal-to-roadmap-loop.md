# MP-129 - Support signal to roadmap loop

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Support and community reports are signals to verify, correlate, disposition, and feed back into product work; they are not facts, fixes, or customer messages until approved.

## Where it applies

Support queues, GitHub issues and PRs, ISP trouble tickets, customer feedback analysis, VoC programs, outage triage, feature requests, refunds, public replies, and OSS maintenance.

## Adoption signal

The workflow maps support surfaces, fetches ground truth, independently verifies claims, correlates repeated signals, drafts with owner confirmation, tracks disposition, and routes product intelligence with revenue or impact context.

## Exemplar skills (>=5)

- `~/.claude/skills/user-support-triage-for-saas-and-open-source-projects/SKILL.md:31` - triage without a support map produces hallucinated APIs and wrong policies.
- `~/.claude/skills/user-support-triage-for-saas-and-open-source-projects/SKILL.md:43` - the triage cycle fetches ground truth and creates an owner-review draft bundle without sending.
- `~/.claude/skills/user-support-triage-for-saas-and-open-source-projects/SKILL.md:82` - owner confirmation and de-slopify are hard floors before any send.
- `~/.claude/skills/user-support-triage-for-saas-and-open-source-projects/SKILL.md:90` - user reports are hints, not facts.
- `~/.claude/skills/gh-triage-ru.old_a9cec496-b94c-40ca-993b-e5ca3e47d207/SKILL.md:19` - every bug report, feature request, and PR must be independently verified.
- `~/.claude/skills/gh-triage-ru.old_a9cec496-b94c-40ca-993b-e5ca3e47d207/SKILL.md:27` - PRs are intel, not contributions.
- `~/.claude/skills/trouble-ticket-automation/SKILL.md:19` - ISP tickets should attempt remote resolution before dispatch.
- `~/.claude/skills/trouble-ticket-automation/SKILL.md:75` - outage work correlates tickets by topology and time window.
- `~/.claude/skills/voice-of-customer/SKILL.md:78` - cross-channel aggregation is non-negotiable.
- `~/.claude/skills/voice-of-customer/SKILL.md:99` - feedback needs a disposition and loop closure.

## Adoption recipes

**Recipe 1 - Surface map:** inventory queues, policies, channels, owners, data fields, and approval boundaries before triage.

**Recipe 2 - Verify and correlate:** reproduce claims, inspect code or telemetry, group repeated signals by root cause, time, topology, account, or theme.

**Recipe 3 - Disposition loop:** record acknowledged, planned, declined, shipped, escalated, or blocked status and close the loop with approved customer or roadmap communication.

## Compliance test

```bash
grep -E "(support map|ground truth|verify|correlate|owner|approval|disposition|roadmap|feature request|cross-channel)" SKILL.md || exit 1
```
