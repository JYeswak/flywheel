---
bead: flywheel-kk08x
title: AGENTS.md catalog sweep — doctrine inventory + 6 new entries + 9 xref-skillos stubs
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P2
mission_fitness: adjacent
---

# kk08x evidence pack — AGENTS.md catalog sweep

## What this bead ships

Syncs the flywheel doctrine catalog inventory across the two AGENTS.md surfaces (`AGENTS.md` canonical operational doctrine + `.flywheel/AGENTS.md` repo-local doctrine artifact) and the doctrine catalog README (`.flywheel/doctrine/README.md`). Adds a Doctrine catalog section to `.flywheel/AGENTS.md` listing the 6 new canonical doctrines from the 2026-05-11 cohort wave + the 9 cross-reference stubs to skillos-canonical META-doctrines.

## Inventory probe (live counts)

```bash
ls -1 .flywheel/doctrine/*.md | wc -l                        # 89 total
for f in .flywheel/doctrine/*.md; do
  head -10 "$f" | grep -q "type: doctrine-cross-reference-stub" && echo "$f"
done | wc -l                                                 # 9 stubs
# canonical = 89 - 9 = 80
```

## Acceptance gates (implicit; bead body empty)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Update doctrine count in AGENTS catalog surface | DID | `.flywheel/AGENTS.md` new section: 89 total / 80 canonical / 9 stubs |
| 2 | Add 6 new doctrine entries (4 v38e1 + option-e + single-axis-reframe-meta) | DID | `.flywheel/AGENTS.md` Recent additions list + `./doctrine/README.md` Recent additions table |
| 3 | Add 9 xref-skillos stubs reference | DID | `./doctrine/README.md` Recent additions table includes 9-row stub list; `.flywheel/AGENTS.md` cross-references the discipline |
| 4 | Sync inventory to `.flywheel/doctrine/` | DID | `./doctrine/README.md` frontmatter updated: `inventory_as_of: 2026-05-11`, `total_doctrines: 89`, `canonical_doctrines: 80`, `cross_reference_stubs: 9`, `update_bead: flywheel-kk08x` |
| 5 | Preserve existing L-rule index + STORAGE-OVERRIDE/CLOSED-BEAD-AUDIT sections | DID | additive edit only; no removals from `.flywheel/AGENTS.md` |
| 6 | Frontmatter parseable in updated README | DID | YAML frontmatter updated with new keys; existing keys preserved |
| 7 | Link cross-references between AGENTS.md surfaces and doctrine catalog | DID | `.flywheel/AGENTS.md` references `./doctrine/README.md`; README references both `../../AGENTS.md` + `../AGENTS.md` |

`did=7/7`, `didnt=none`, `gaps=none`.

## L112 probe

```bash
grep -c "flywheel-v38e1\|flywheel-nk0r0\|flywheel-0mw8v\|flywheel-kk08x" /Users/josh/Developer/flywheel/.flywheel/AGENTS.md /Users/josh/Developer/flywheel/.flywheel/doctrine/README.md | awk -F: '{s+=$2} END{print s}'
```

Expected: numeric >=10 (catalog references all 6 new doctrines + kk08x in both surfaces).

## Files changed

- `.flywheel/AGENTS.md` — append Doctrine catalog section (additive only, +31 lines)
- `.flywheel/doctrine/README.md` — frontmatter update + Inventory snapshot section + Recent additions tables (+44 lines, -1)
- `.flywheel/audit/flywheel-kk08x/evidence.md` — this evidence pack
- `.flywheel/audit/flywheel-kk08x/compliance-pack.md` — compliance breakdown

## Mission fitness

`mission_fitness=adjacent`. Catalog sweep keeps the doctrine inventory navigable for the fleet (workers + orchs use the catalog to locate canonical rules). Specifically supports the bilateral cross-orch protocol by surfacing the 4 v38e1 cohort doctrines + Option E + single-axis-reframe trauma class at the AGENTS surface.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. Catalog sweep is procedural inventory work; no new pattern surfaced.

## Four-Lens Self-Grade

- Brand: 9/10 — additive edits preserve existing structure; new section follows scaffold convention
- Sniff: 9/10 — 7/7 implicit gates DID; live counts probed empirically (89/80/9)
- Jeff: 9/10 — cross-repo consumer-vs-mutator discipline preserved (9 stubs remain at skillos canonical-locator, no upstream mutation)
- Public: 8/10 — three judges: skeptical operator sees count + recent additions; maintainer can extend per scaffold; future worker can locate any doctrine via the catalog
