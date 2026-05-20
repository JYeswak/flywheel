# MP-101 - Listener ownership registry before allowlist

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Network exposure is not made safe by an allowlist row; every listener needs a declared owner, expected bind, intent, probe, and receipt before the allowlist is projected.

## Where it applies

Local dev services, MCP shims, Docker/OrbStack ports, Cloudflare Access shims, GPU vendor tunnels, reverse proxies, and any automation that opens or blesses a network socket.

## Adoption signal

The workflow probes existing listeners, records a registry row for any intentional port, projects allowlist state from that registry, and re-probes after mutation with an append-only receipt.

## Exemplar skills (>=5)

- `~/.claude/skills/docker-network-ops/SKILL.md:12` - port conflicts and socket handover are treated as the primary silent break in MCP wiring.
- `~/.claude/skills/docker-network-ops/SKILL.md:13` - both `lsof` and `docker ps` checks must be empty before binding a new host port.
- `~/.claude/skills/docker-network-ops/SKILL.md:72` - engine socket paths and context pinning are part of the binding proof.
- `~/.claude/skills/ecosystem-port-security/SKILL.md:15` - ownership precedes allowlisting.
- `~/.claude/skills/ecosystem-port-security/SKILL.md:19` - every listener must have an ownership row with intent and expected bind.
- `~/.claude/skills/ecosystem-port-security/SKILL.md:32` - the allowlist is a projection, not the source of truth.
- `~/.claude/skills/port-allowlist-manager/SKILL.md:24` - exposed ports are audited, identified, stopped, killed, or legitimized before approval.
- `~/.claude/skills/mcp-cf-access-shim/SKILL.md:55` - a fresh shim gets a new port, LaunchAgent, URL update, and health probe.

## Adoption recipes

**Recipe 1 - Listener probe:** run process-level and container-level probes before opening or blessing a port.

**Recipe 2 - Ownership row:** record owner, intent, expected bind, lifecycle, and health probe before allowlist projection.

**Recipe 3 - Projection receipt:** mutate allowlists from the registry and write a receipt that includes before/after probes.

## Compliance test

```bash
grep -E "(port|listener|allowlist|ownership|registry|lsof|docker ps|health probe|receipt)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-69-registry-risk-ledger.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-80-scope-token-operation-matrix.md`
