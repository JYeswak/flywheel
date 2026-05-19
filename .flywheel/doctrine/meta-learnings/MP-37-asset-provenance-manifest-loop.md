# MP-37 — Asset-provenance manifest loop

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 5+

## Essence

Media assets are durable state, not throwaway files: bind them by manifest ID, preserve provenance, re-grade after changes, and supersede instead of deleting.

## Where it applies

Generated images, generated video clips, storyboards, asset curation, OG images, brand media libraries.

## Adoption signal

Asset workflow writes manifest entries with UUID/source/model/prompt hash, validates binding by ID, and records supersession or grading state.

## Exemplar skills (≥5)

- `~/.claude/skills/generating-images-multi-provider/SKILL.md:21` — image providers return a `GeneratedAsset` record for manifest insertion.
- `~/.claude/skills/generating-images-multi-provider/SKILL.md:124` — every provider returns the same dataclass.
- `~/.claude/skills/generating-images-multi-provider/SKILL.md:133` — generated assets carry a prompt hash.
- `~/.claude/skills/generating-videos-multi-provider/SKILL.md:97` — video clips have a `GeneratedAsset` output contract.
- `~/.claude/skills/authoring-zest-feed-storyboards/SKILL.md:18` — storyboard scenes bind assets by UUID, not inline path.
- `~/.claude/skills/asset-library-curator/SKILL.md:47` — passing regenerated assets are added to the manifest and old assets are superseded.
- `~/.claude/skills/asset-library-curator/SKILL.md:133` — successful regen must not delete old assets.
- `~/.claude/skills/authoring-zest-feed-beat-boards/SKILL.md:35` — narration claims carry a provenance ledger.

## Adoption recipes

**Recipe 1 — Manifest IDs:** media consumers reference UUIDs, never ad hoc paths.

**Recipe 2 — Provenance fields:** generated assets include provider, model, prompt hash, brand-pack version, and source intent.

**Recipe 3 — Supersede state:** replacement marks old asset superseded and preserves it for audit/reuse.

## Compliance test

```bash
grep -E "(GeneratedAsset|prompt_hash|manifest.yaml|asset_id|SUPERSEDED|provenance ledger)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
