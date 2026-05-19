# MP-41 — Gate-class separation

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Separate gate classes before acting; "ready", "blocked", and "unblocked" are invalid until code, operation, process, math, stock, and flow gates are named independently.

## Where it applies

Dispatch readiness, protected recovery, trading authorization, release validation, callback acceptance, and any workflow where one green surface can hide another red surface.

## Adoption signal

Skill requires a gate taxonomy, reports each gate status separately, and forbids claiming ready from a single process or command success.

## Exemplar skills (≥5)

- `~/.claude/skills/gate-truth-separation/SKILL.md:15` — prior failures collapsed several gate types into one "ready" label.
- `~/.claude/skills/gate-truth-separation/SKILL.md:18` — durable separation names CODE vs OP, process vs math, stock vs flow.
- `~/.claude/skills/gate-truth-separation/SKILL.md:29` — first step is naming the gate class before fixing.
- `~/.claude/skills/gate-truth-separation/SKILL.md:35` — "ready/unblocked" is banned until all gate classes are green.
- `~/.claude/skills/orchestrator-validation-discipline/SKILL.md:14` — validation begins by reading dispatch and bead acceptance gates.
- `~/.claude/skills/protected-session-recovery/SKILL.md:11` — protected recovery defaults to dry-run and evidence gates.
- `~/.claude/skills/money-path-input-integrity/SKILL.md:18` — money decisions need input gates, not just execution-envelope gates.

## Adoption recipes

**Recipe 1 — Gate matrix:** require `gate_class`, `evidence`, `status`, and `next_action` fields for every readiness claim.

**Recipe 2 — Word ban:** reject callbacks that say "ready", "unblocked", or "done" without enumerating all relevant gate classes.

**Recipe 3 — One-red rule:** if any gate class is red or unknown, route to that gate owner instead of patching the downstream symptom.

## Compliance test

```bash
grep -E "(gate_class|CODE.*OP|process.*math|stock.*flow|ready.*all.*gate)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-74-assertion-control-evidence-chain.md`
