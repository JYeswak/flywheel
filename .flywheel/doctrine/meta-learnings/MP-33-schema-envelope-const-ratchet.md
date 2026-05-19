# MP-33 — Schema-envelope const ratchet

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 6+

## Essence

Durable artifacts need a versioned envelope with required fields and a validator; unversioned JSON/Markdown cannot safely cross sessions, agents, or repos.

## Where it applies

Callback receipts, handoffs, generated assets, dispatch packets, extracted pattern packages, storyboards, GitHub Actions artifacts.

## Adoption signal

Artifact includes `schema_version` or contract fields, validates against a schema, and rejects unknown or missing required fields.

## Exemplar skills (≥5)

- `~/.claude/skills/artifact-schema-envelope/SKILL.md:8` — every durable JSON artifact crossing orch boundaries must conform.
- `~/.claude/skills/artifact-schema-envelope/SKILL.md:12` — envelope is backed by JSON Schema with `additionalProperties: false`.
- `~/.claude/skills/artifact-schema-envelope/SKILL.md:18` — `schema_version` is a const string.
- `~/.claude/skills/cross-orch-handoff/SKILL.md:66` — cross-boundary contracts freeze schema/envelope shape and include a version field.
- `~/.claude/skills/dispatch-tool-contracts/SKILL.md:122` — callbacks carry stable fields like commit, tests, K count, and verdict.
- `~/.claude/skills/generating-images-multi-provider/SKILL.md:122` — generated images return a typed `GeneratedAsset` contract.
- `~/.claude/skills/authoring-zest-feed-storyboards/SKILL.md:16` — storyboard JSON is Zod schema-validated before render.
- `~/.claude/skills/codebase-pattern-extraction/SKILL.md:166` — reusable packages include specific output schemas.

## Adoption recipes

**Recipe 1 — Envelope first:** new durable artifacts start with `schema_version`, `created_at`, `status`, and `replay_command` or equivalent.

**Recipe 2 — Validator command:** every envelope has a local validator and negative fixture.

**Recipe 3 — Const ratchet:** schema_version is a const until a migration path exists; do not silently widen shapes.

## Compliance test

```bash
grep -E "(schema_version|JSON Schema|Zod|contract|required fields|additionalProperties)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
