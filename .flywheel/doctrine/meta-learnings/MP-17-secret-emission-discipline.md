# MP-17 — Secret emission discipline

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Stdout-safe by default. Never emit secret-shaped strings; redact early, often, and at all output boundaries. Secret-class trauma promoted on N=1 (per MP-08 sister rule).

## Where it applies

Any skill that handles env vars, vault data, API keys, OAuth tokens, customer PII, financial credentials.

## Adoption signal

Skill cites redaction policy AND has a redact-helper OR uses an envelope that excludes secret fields.

## Exemplar skills (≥5)

- `~/.claude/skills/secret-emission-discipline/SKILL.md:1` — direct exemplar
- `~/.claude/skills/agent-security/SKILL.md:1` — agent security framework
- `~/.claude/skills/infisical-secrets/SKILL.md:1` — secret vault operations
- `~/.claude/skills/mcp-secret-scanner/SKILL.md:1` — secret pattern scanner
- `~/.claude/skills/cryptography-and-auth/SKILL.md:1` — crypto + auth
- `~/.claude/skills/data-deidentification/SKILL.md:1` — PII removal

## Adoption recipes

**Recipe 1 — Redact-at-output:** every command emitting JSON has a redact-pass before emit; receipts hash-only for secret-shaped fields.

**Recipe 2 — Stdin-only writes:** never echo a secret on the command line; use stdin pipes.

**Recipe 3 — N=1 promotion rule:** any secret-leak event triggers immediate doctrine update + canonical-rule promotion (skip the standard 3-strike cadence).

## Compliance test

```bash
# Skills handling secrets MUST cite redaction.
grep -iE "(redact|secret.safe|no.print|stdin.only)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-4 so every skillos doctrine file cites the relevant MP lessons directly.

- **MP-08 — trauma-class promotion:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-08-trauma-class-promotion.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
