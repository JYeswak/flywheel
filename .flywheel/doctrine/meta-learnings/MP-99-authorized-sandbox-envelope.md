# MP-99 - Authorized sandbox envelope

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 8+

## Essence

Potentially invasive agent or security work must run inside a declared authorization, permission, network, filesystem, and data boundary independent of the model prompt.

## Where it applies

Agent execution, penetration testing, secret scans, destructive commands, customer data access, multi-tenant systems, webhook handling, and untrusted tool use.

## Adoption signal

The workflow has written scope, execution-layer authorization, least-privilege credentials, deny-by-default egress, output scanning, audit trails, and a human approval path for boundary expansion.

## Exemplar skills (>=5)

- `~/.claude/skills/security-pen-testing/SKILL.md:50` - offensive testing requires written authorization and rules of engagement.
- `~/.claude/skills/agent-security/SKILL.md:27` - agents must prove identity, stay in authorized scope, resist manipulation, and protect data.
- `~/.claude/skills/agent-security/SKILL.md:142` - tool permissions are enforced at the execution layer.
- `~/.claude/skills/agent-security/SKILL.md:174` - prompt-based authorization is an anti-pattern.
- `~/.claude/skills/agent-sandboxing/SKILL.md:27` - each agent gets a sandbox proportional to trust level.
- `~/.claude/skills/agent-sandboxing/SKILL.md:97` - network policy defaults to deny.
- `~/.claude/skills/agent-sandboxing/SKILL.md:181` - paths are resolved and verified inside the sandbox boundary.
- `~/.claude/skills/mcp-secret-scanner/SKILL.md:103` - critical secret findings do not trigger auto-rotation without approval.
- `~/.claude/skills/dcg/SKILL.md:121` - blocked destructive commands should trigger alternatives before allow-once.

## Adoption recipes

**Recipe 1 - Scope packet:** record owner authorization, target systems, allowed techniques, forbidden actions, time window, and stop conditions.

**Recipe 2 - Execution-layer policy:** enforce tool, network, filesystem, and data access outside the model prompt.

**Recipe 3 - Boundary expansion receipt:** when scope must widen, capture reason, risk, approver, expiration, and rollback.

## Compliance test

```bash
grep -E "(authorization|scope|sandbox|deny|allowlist|RBAC|execution layer|approval|secret|egress)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-80-scope-token-operation-matrix.md`
