# MP-57 — Regulated evidence redaction chain

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Compliance evidence must be useful, preserved, and redacted at capture time; audit trails that leak secrets or omit custody, retention, and chain verification create a new incident.

## Where it applies

HIPAA/SOC2 FastAPI audits, e-discovery, request logs, TLS/DNS go-live checks, validation evidence, security reviews, and regulated customer operations.

## Adoption signal

Skill requires audit logging, preservation/hold policy, redaction before transcript or evidence write, chain/certificate verification, and explicit custody of evidence artifacts.

## Exemplar skills (≥5)

- `~/.claude/skills/hipaa-soc2-fastapi-hardening/SKILL.md:8` — regulated FastAPI/Postgres/Redis backends are the target surface.
- `~/.claude/skills/hipaa-soc2-fastapi-hardening/SKILL.md:10` — run the audit at the start of every new FastAPI project; no rediscovery.
- `~/.claude/skills/e-discovery/SKILL.md:16` — e-discovery covers preservation, processing, review, production, and quality control.
- `~/.claude/skills/e-discovery/SKILL.md:25` — legal hold is a first-class trigger.
- `~/.claude/skills/request-response-logging/SKILL.md:18` — logs support debugging, audit trails, baselines, and compliance evidence.
- `~/.claude/skills/request-response-logging/SKILL.md:27` — redaction prevents PII and secret leakage.
- `~/.claude/skills/safety-stack-gate/SKILL.md:51` — validation evidence collection needs redaction discipline.
- `~/.claude/skills/dns-ssl-configuration/SKILL.md:139` — TLS deployment verifies the full certificate chain.

## Adoption recipes

**Recipe 1 — Evidence class:** classify artifact as audit, legal, diagnostic, or validation evidence before capture.

**Recipe 2 — Redact on write:** scrub PII, PHI, tokens, and secrets before evidence enters logs, callbacks, or transcripts.

**Recipe 3 — Custody proof:** receipts include owner, retention rule, source command, redaction method, and verification command.

## Compliance test

```bash
grep -E "(audit logging|legal hold|redaction|PII|PHI|compliance evidence|certificate chain)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
