# MP-13 — Living documentation (LATEST.md + auto-refresh)

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Documentation drifts unless it has an explicit refresh cadence + auto-detector. Every skill ships a LATEST.md (or equivalent) summarizing recent changes since last refresh, kept current by a sister script.

## Where it applies

Skill maintenance, doctrine, public-facing docs, API references, release notes.

## Adoption signal

Skill has a `LATEST.md` file with timestamp + auto-update mention OR ships with a `references/` directory updated on each version.

## Exemplar skills (≥5)

- `~/.claude/skills/living-documentation/SKILL.md:1` — direct exemplar
- `~/.claude/skills/changelog-md-workmanship/SKILL.md:1` — CHANGELOG discipline
- `~/.claude/skills/zs-counsel-surface-inventory/LATEST.md:1` — LATEST.md exemplar
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/CHANGELOG.md:1` — extensive changelog
- `~/.claude/skills/agent-ergonomics-cli/CHANGELOG.md:1` — versioned changelog
- `~/.claude/skills/readme-writing/SKILL.md:1` — README authoring framework

## Adoption recipes

**Recipe 1 — LATEST.md per skill:** every skill ships LATEST.md auto-updated on each version bump.

**Recipe 2 — Changelog discipline:** CHANGELOG.md follows semver + lists every modification with date.

**Recipe 3 — Drift detector:** sister script scans for stale docs (> 90 days) and surfaces in repo's doctor output.

## Compliance test

```bash
# Skills MUST have LATEST.md or CHANGELOG.md updated within 180 days.
test -f LATEST.md -o -f CHANGELOG.md || fail
```
