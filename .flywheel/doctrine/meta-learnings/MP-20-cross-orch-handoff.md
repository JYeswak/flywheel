# MP-20 — Cross-orch handoff protocol

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 4+

## Essence

When work crosses orchestrator boundaries (skillos:1 → flywheel:1 → mobile-eats:1 etc.), use durable handoff files with real-word-prefixed packets + ntm send pings. Never rely on conversation memory.

## Where it applies

Multi-pane fleet ops, cross-repo coordination, peer-orch escalation, bounded deferrals.

## Adoption signal

Repo has `.flywheel/handoffs/` directory with timestamped handoff files.

## Exemplar skills (≥4)

- `~/.claude/skills/cross-orch-handoff/SKILL.md:1` — direct exemplar
- `~/.claude/skills/cross-agent-session-resumer/SKILL.md:1` — session resume across agents
- `~/.claude/skills/agent-mail/SKILL.md:1` — agent-mail substrate
- `~/.claude/skills/orchestrator-validation-discipline/SKILL.md:1` — orchestrator validation
- `~/.claude/skills/orchestrator-dispatch-verification/SKILL.md:1` — dispatch verification

## Adoption recipes

**Recipe 1 — Handoff directory:** every active repo has `.flywheel/handoffs/` with `YYYYMMDDTHHMMZ-from-<src>-to-<dst>-<slug>.md` naming.

**Recipe 2 — Real-word prefix:** handoff packets prefixed with "Blocker report:" / "Bounded deferral:" / "Plan response:" / "Ratification:" etc.

**Recipe 3 — ntm send sister:** every handoff file MUST be paired with a corresponding `ntm send <session> --pane=N` notifying the receiving pane.

## Compliance test

```bash
# Multi-orch repos MUST have .flywheel/handoffs/.
test -d .flywheel/handoffs || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-04 — receipt-and-callback envelope contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md` for the canonical pattern.
- **MP-20 — cross-orch handoff:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
