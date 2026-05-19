# MP-84 - Stable interactive surface geometry

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 7+

## Essence

Interactive surfaces stay usable when geometry, focus, state ownership, performance budgets, and fallback tiers are explicit contracts rather than emergent render behavior.

## Where it applies

TUIs, dashboards, visualization pages, console-style React apps, responsive panels, charts, and any operator surface with live state or large data.

## Adoption signal

The surface caches hit regions, models focus as data, gates optional panels by available area, separates pure state from runtime hooks, lazy-loads heavy visuals, and proves performance with measurement.

## Exemplar skills (>=5)

- `~/.claude/skills/frankentui/SKILL.md:128` - pane geometry is modeled explicitly and pointer position maps to active pane.
- `~/.claude/skills/frankentui/SKILL.md:167` - screens degrade gracefully and keep meaningful content in tight terminals.
- `~/.claude/skills/frankentui/SKILL.md:309` - layout rectangles are stored during view and read during update for hit-testing.
- `~/.claude/skills/frankentui/SKILL.md:324` - focus is modeled as an enum with next/previous cycling.
- `~/.claude/skills/cfs-zustand-discipline/SKILL.md:29` - state is split into per-concern slices.
- `~/.claude/skills/cfs-zustand-discipline/SKILL.md:30` - pure layer and bound runtime layer are separated.
- `~/.claude/skills/interactive-visualization-creator/SKILL.md:32` - heavy visualizations use lazy initialization.
- `~/.claude/skills/interactive-visualization-creator/SKILL.md:37` - refs carry high-frequency state while React state carries UI state.
- `~/.claude/skills/data-visualization/SKILL.md:241` - large data views use virtualized or windowed rendering.
- `~/.claude/skills/cfs-performance-discipline/SKILL.md:43` - performance work is alert-driven, not vibes-driven.

## Adoption recipes

**Recipe 1 - Geometry as state:** store rectangles, breakpoints, focus targets, and hit regions as inspectable state.

**Recipe 2 - Split state by cadence:** high-frequency animation/input data uses refs or engine state; persistent/user-visible UI state uses stores or React state.

**Recipe 3 - Minimum viable surface:** define tiny, small, and full layouts so optional panels disappear before core controls do.

## Compliance test

```bash
grep -E "(layout|geometry|hit|focus|slice|pure layer|lazy|virtual|performance|fallback)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-56-ui-state-permission-boundary.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-65-generated-visual-inspection-loop.md`
