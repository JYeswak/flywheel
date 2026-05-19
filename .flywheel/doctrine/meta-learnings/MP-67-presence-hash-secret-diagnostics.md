# MP-67 — Presence-hash secret diagnostics

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Credential workflows prove presence, tenant, scope, and round-trip behavior without exposing secret values; diagnostics use hashes, stdin, and redacted validity checks instead of stdout or argv.

## Where it applies

SaaS CLI auth, deployment secrets, SSH setup, provider tokens, CI configuration, local secret stores, and any support flow where transcripts can retain sensitive values.

## Adoption signal

The skill forbids secret echoing, verifies presence rather than value, uses stdin or secret stores for writes, avoids token-bearing URLs, and proves success through hashes or scoped API checks.

## Exemplar skills (≥5)

- `~/.claude/skills/secret-emission-discipline/SKILL.md:11` — once a secret reaches stdout it is in the transcript forever.
- `~/.claude/skills/secret-emission-discipline/SKILL.md:54` — safe alternatives verify presence or validity without revealing value.
- `~/.claude/skills/secret-emission-discipline/SKILL.md:73` — verify presence, not secret value.
- `~/.claude/skills/secret-emission-discipline/SKILL.md:94` — set secrets through stdin, not argv.
- `~/.claude/skills/secret-emission-discipline/SKILL.md:95` — verify round trip by hash.
- `~/.claude/skills/saas-cli-auth-flow/SKILL.md:18` — SaaS CLIs need three authentication paths.
- `~/.claude/skills/saas-cli-auth-flow/SKILL.md:84` — PKCE is required on every code exchange.
- `~/.claude/skills/saas-cli-auth-flow/SKILL.md:88` — tokens must never appear in URLs or logs.
- `~/.claude/skills/vercel/SKILL.md:169` — secrets belong in environment or secret stores, not config files.

## Adoption recipes

**Recipe 1 — Presence probe:** print key name, scope, tenant, length class, or boolean validity, but never the secret itself.

**Recipe 2 — Stdin write:** write secret material through stdin, native secret APIs, or environment stores, avoiding command arguments and shell history.

**Recipe 3 — Hash receipt:** prove round trip with a non-reversible hash prefix, scoped API call, or redacted token metadata.

## Compliance test

```bash
grep -E "(secret|stdin|hash|redact|PKCE|token|URL|logs|presence)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-57-regulated-evidence-redaction-chain.md`
