# MP-51 — Structured event lifecycle observability

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Observe user and system behavior as structured lifecycle events with identity, context, redaction, grouping, and validation; raw logs and scattered analytics calls do not create operational truth.

## Where it applies

API middleware, crash reporting, GA4/GTM funnels, SaaS health analytics, validation envelopes, audit logs, and dashboards that drive product or reliability decisions.

## Adoption signal

Events have stable names, parameters, correlation IDs, redaction policy, release tags, validation status, and downstream consumers that can query them consistently.

## Exemplar skills (≥5)

- `~/.claude/skills/request-response-logging/SKILL.md:16` — request-response logging captures the full API interaction lifecycle.
- `~/.claude/skills/request-response-logging/SKILL.md:27` — log redaction prevents PII and secret leakage.
- `~/.claude/skills/crash-reporting/SKILL.md:58` — crash events are tied to deployments via release tags.
- `~/.claude/skills/crash-reporting/SKILL.md:89` — structured context makes errors debuggable without reproduction.
- `~/.claude/skills/ga4/SKILL.md:50` — scattered event code is replaced by a unified dataLayer pattern.
- `~/.claude/skills/ga4/SKILL.md:182` — one scalable event plus parameters avoids exploding event-name cardinality.
- `~/.claude/skills/saas-customer-analytics/SKILL.md:351` — analytics reliability depends on the event pipeline.
- `~/.claude/skills/request-validation/SKILL.md:35` — validation failures should use standardized error response formats.

## Adoption recipes

**Recipe 1 — Event contract:** define event name, required parameters, identity fields, release/deploy tags, and redaction rules.

**Recipe 2 — Lifecycle stitching:** propagate correlation ID from request log to validation envelope, crash event, analytics event, and audit trail.

**Recipe 3 — Cardinality control:** prefer stable event names with typed parameters over unbounded event-name generation.

## Compliance test

```bash
grep -E "(correlation ID|dataLayer|release:|structured context|redaction|event pipeline)" SKILL.md || fail
```
