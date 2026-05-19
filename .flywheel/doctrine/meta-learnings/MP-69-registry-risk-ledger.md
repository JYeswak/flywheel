# MP-69 — Registry risk ledger

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Complex real-world systems need a canonical registry plus a risk ledger: each entity, SKU, business unit, supplier, or surface has one source of truth, named alternates, public/private projection rules, and dated evidence.

## Where it applies

Hardware product scoping, portfolio registries, sales territories, vendor management, SSH host inventories, data source inventories, and any domain with external constraints that drift.

## Adoption signal

The skill names a canonical registry, one row per identity, current price or status evidence, explicit risk entries, alternates for critical dependencies, and public redaction rules.

## Exemplar skills (≥5)

- `~/.claude/skills/hardware-product-scoping/SKILL.md:21` — hardware is not scoped until all five surfaces are addressed.
- `~/.claude/skills/hardware-product-scoping/SKILL.md:35` — missing surface rules halt on breach.
- `~/.claude/skills/hardware-product-scoping/SKILL.md:39` — BOM rows use a single SKU.
- `~/.claude/skills/hardware-product-scoping/SKILL.md:92` — BOM work emits pricing history.
- `~/.claude/skills/hardware-product-scoping/SKILL.md:93` — BOM work maintains a risk register.
- `~/.claude/skills/hardware-product-scoping/SKILL.md:107` — every critical row needs a named alternate.
- `~/.claude/skills/holding-co-portfolio-registry/SKILL.md:28` — the portfolio registry is canonical.
- `~/.claude/skills/holding-co-portfolio-registry/SKILL.md:201` — public rendering strips private fields.

## Adoption recipes

**Recipe 1 — Canonical row:** define the unique registry row for each SKU, tenant, portfolio company, host, vendor, or territory.

**Recipe 2 — Drift evidence:** append dated price, status, ownership, or availability evidence instead of overwriting history.

**Recipe 3 — Alternate and projection:** critical rows name fallback choices and define which fields survive public export.

## Compliance test

```bash
grep -E "(registry|BOM|SKU|risk register|pricing history|alternate|canonical|public)" SKILL.md || fail
```
