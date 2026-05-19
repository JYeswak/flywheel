# MP-74 — Assertion-control-evidence chain

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 7+

## Essence

Regulated and risk-bearing work traces every claim from assertion to requirement, control, evidence, finding, owner, and remediation status.

## Where it applies

SOC2, HIPAA, GDPR, audits, contract review, legal research, security review, regulatory monitoring, third-party risk, and any workflow where unsupported conclusions become liability.

## Adoption signal

The skill separates evidence from advice, maps requirements to controls, classifies risk, records authority or source hierarchy, and leaves a remediation tracker with owners and deadlines.

## Exemplar skills (≥5)

- `~/.claude/skills/audit-preparation/SKILL.md:30` — audits are evidence-based assertions.
- `~/.claude/skills/audit-preparation/SKILL.md:201` — audit trail chains assertion to control to evidence to conclusion.
- `~/.claude/skills/audit-preparation/SKILL.md:218` — remediation trackers include priority, owners, and deadlines.
- `~/.claude/skills/compliance-automation/SKILL.md:26` — controls must be machine-verifiable and human-auditable.
- `~/.claude/skills/compliance-automation/SKILL.md:74` — control mappings are recorded in compliance config.
- `~/.claude/skills/legal-research/SKILL.md:19` — conclusions separate law from inference and route to human legal review.
- `~/.claude/skills/contract-review/SKILL.md:30` — contract risks cite sections and require attorney or owner approval.
- `~/.claude/skills/hipaa-compliance/SKILL.md:86` — residual re-identification risk is documented.
- `~/.claude/skills/security-review/SKILL.md:60` — security review reports mitigations with evidence and remaining risks.

## Adoption recipes

**Recipe 1 — Map the assertion:** every claim names the requirement, jurisdiction or standard, control, and evidence path.

**Recipe 2 — Classify residual risk:** findings carry severity, likelihood, impact, compensating controls, and explicit uncertainty.

**Recipe 3 — Close with owner:** remediation includes owner, due date, verification method, and proof path.

## Compliance test

```bash
grep -E "(assertion|control|evidence|requirement|authority|risk|remediation|owner|deadline)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-42-independent-evidence-convergence.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
