# MP-40 — Outside-observer goal contract

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 5+

## Essence

Goals and dispatches are contracts for an outside observer: success must be falsifiable from named artifacts, commands, and receipts without trusting the author's intent.

## Where it applies

Goal authoring, dispatch packets, cross-orch handoffs, callback receipts, extracted pattern packages, durable artifacts.

## Adoption signal

Work packet names success bars, artifacts, validation commands, evidence paths, and observer-readable plain-language success state.

## Exemplar skills (≥5)

- `~/.claude/skills/goal-build/SKILL.md:8` — a goal is a contract with an outside observer.
- `~/.claude/skills/goal-build/SKILL.md:43` — canonical gates are falsifiable hard bars.
- `~/.claude/skills/goal-build/SKILL.md:47` — hard bars anchor in real artifacts.
- `~/.claude/skills/goal-build/SKILL.md:111` — someone else must be able to verify progress by running the validation command.
- `~/.claude/skills/dispatch-tool-contracts/SKILL.md:85` — dispatch packets carry K count, bead anatomy, explicit files, and proof commands.
- `~/.claude/skills/dispatch-tool-contracts/SKILL.md:102` — workers get proof-of-work commands before reporting DONE.
- `~/.claude/skills/artifact-schema-envelope/SKILL.md:8` — durable artifacts crossing orch boundaries must conform.
- `~/.claude/skills/cross-orch-handoff/SKILL.md:72` — handoffs include provenance and schema verification commands.

## Adoption recipes

**Recipe 1 — Observer test:** before dispatch, ask whether a fresh operator could verify completion from artifacts alone.

**Recipe 2 — Hard-bar fields:** receipts include `success_bar`, `artifact_path`, `validation_command`, and `observed_result`.

**Recipe 3 — Plain-English close:** final callback states what changed in operator-visible terms, not just internal labels.

## Compliance test

```bash
grep -E "(outside observer|falsifiable hard bar|validation command|proof-of-work|artifact.*success)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-12 — three-spaces reasoning:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-12-three-spaces-reasoning.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
