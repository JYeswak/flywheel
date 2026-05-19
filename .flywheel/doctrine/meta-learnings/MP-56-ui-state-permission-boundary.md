# MP-56 — UI state/permission boundary

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Frontend correctness comes from classifying state and permissions at the boundary: the UI may reveal, cache, or stage intent, but the server owns authority and impossible states must be unrepresentable.

## Where it applies

React apps, admin panels, RBAC UI, TanStack Query/Form/Table, API validation, dashboards, route guards, and destructive UI flows.

## Adoption signal

Skill classifies state type, uses server-state tooling, derives URL/bookmarkable state, checks granular permissions, and validates requests server-side.

## Exemplar skills (≥5)

- `~/.claude/skills/state-management/SKILL.md:12` — every piece of state belongs to exactly one category.
- `~/.claude/skills/state-management/SKILL.md:23` — server state should not live in Redux/Zustand.
- `~/.claude/skills/state-management/SKILL.md:115` — state machines make impossible states impossible.
- `~/.claude/skills/role-based-access-ui/SKILL.md:16` — UI progressively discloses while the server enforces authorization.
- `~/.claude/skills/role-based-access-ui/SKILL.md:34` — check permissions, not role names.
- `~/.claude/skills/role-based-access-ui/SKILL.md:266` — frontend hides elements while server rejects unauthorized requests.
- `~/.claude/skills/tanstack/SKILL.md:49` — TanStack Query owns server state, caching, optimistic updates, and pagination.
- `~/.claude/skills/request-validation/SKILL.md:24` — request bodies are parsed against strict schemas at API boundaries.

## Adoption recipes

**Recipe 1 — State inventory:** label each UI value as UI, shared UI, server, URL, form, or derived.

**Recipe 2 — Permission primitive:** expose granular permission checks and derive navigation/rendering from those, not role strings.

**Recipe 3 — Boundary enforcement:** pair every UI guard with a server-side validation or authorization check.

## Compliance test

```bash
grep -E "(server state|URL state|permission|authorization|strict schemas|impossible states)" SKILL.md || fail
```
