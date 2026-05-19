# MP-109 - Measured FSM service journey

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Operational service journeys should be modeled as finite state machines with entry actions, metrics, thresholds, timeouts, rollback paths, and verification gates before billing or closure.

## Where it applies

ISP customer service, service activation, billing, network optimization, QoS monitoring, security escalation, field operations, and any service journey where unmodeled states create churn or revenue leakage.

## Adoption signal

The workflow declares states and transitions, defines success and failure thresholds, records baseline measurements, validates the field result, and prevents downstream billing or closure until verification passes.

## Exemplar skills (>=5)

- `~/.claude/skills/isp-customer-service/SKILL.md:19` - the ISP customer journey is a finite state machine with entry action, success criteria, timeout, escalation, and rollback.
- `~/.claude/skills/isp-customer-service/SKILL.md:155` - service state design lists stages, transitions, rollbacks, orphan-state checks, and timeout behavior.
- `~/.claude/skills/isp-customer-service/SKILL.md:183` - activation is gated on speed test verification before billing.
- `~/.claude/skills/isp-billing/SKILL.md:19` - ISP billing must be auditable, reversible, and reconcilable.
- `~/.claude/skills/isp-billing/SKILL.md:75` - billing before service verification is blocked by an activation gate.
- `~/.claude/skills/network-optimization/SKILL.md:20` - network optimization is constrained optimization and changes require model, simulation, and validation.
- `~/.claude/skills/network-optimization/SKILL.md:173` - target, simulation, and validation must agree or the model is wrong.
- `~/.claude/skills/qos-monitoring/SKILL.md:76` - raw metrics need topology context, cooldowns, sustained trends, and baselines.

## Adoption recipes

**Recipe 1 - State table:** define state, entry action, allowed transitions, owner, timeout, rollback, and escalation.

**Recipe 2 - Metric gate:** attach baseline, threshold, measurement method, and success/failure rule to each transition.

**Recipe 3 - Downstream block:** prevent billing, closeout, or customer promise until the verification gate is satisfied.

## Compliance test

```bash
grep -E "(finite state|state|transition|timeout|rollback|baseline|threshold|verification|billing|speed test)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-51-structured-event-lifecycle-observability.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-73-score-triggered-lifecycle-playbook.md`
