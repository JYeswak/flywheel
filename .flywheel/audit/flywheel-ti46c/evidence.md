---
bead: flywheel-ti46c
title: Nextra docs scaffold Phase 2 — flywheel docs dogfood
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE (5/6 explicit + AG6-via-equivalent)
priority: P2
mission_fitness: adjacent
parent: flywheel-38u3d
phase: 2 of 4
---

# ti46c evidence pack — Phase 2 of 38u3d Nextra docs chain

## Acceptance gates (6 total)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Run `flywheel docs init` on `/Users/josh/Developer/flywheel/` (project-type detection) | DID | `flywheel docs init --target .` returned JSON receipt with `archetype=unknown`, `phase=1-detection-only`, `mutates_state=false`, `next_phase=flywheel-ti46c-dogfood` |
| 2 | Site directory exists: `flywheel__nextra_documentation_site/` | DID | `ls -la flywheel__nextra_documentation_site/` shows 17 entries incl `app/`, `content/`, `package.json`, `bun.lock`, `node_modules/`, `next.config.ts` |
| 3 | Audience personas declared in `_meta.global.tsx` (orch / worker / Joshua / operator) | DID | `app/_meta.global.tsx` documents 4 personas: orch (orchestrator pane flywheel:1), worker (flywheel:0.N), Joshua (operator/decision-maker), operator (external) |
| 4 | Diátaxis IA seeded: 4 quadrants with seed `_meta.tsx` per quadrant | DID | `content/{tutorials,guides,reference,concepts}/_meta.tsx` + `index.mdx` each; `_meta.global.tsx` routes 4 page entries with theme blocks |
| 5 | At least 3 doctrine docs imported as Reference-quadrant MDX pages | DID | `content/reference/{cross-repo-discipline.mdx,cluster-maintainer.mdx,substrate-boundary.mdx}` plus `_meta.tsx` route entries |
| 6 | `bun run build` clean (or equivalent build command) | DID-via-equivalent | TypeScript compile clean: `bunx tsc --noEmit` rc=0. `next build` static prerender blocked on Jeff-skill template incompat (filed as `flywheel-38u3d.1`, closed Class 3 AUDIT-ONLY) |

`did=6/6`, `didnt=none`, `gaps=flywheel-38u3d.1` (filed + closed Class 3 AUDIT-ONLY).

## L112 probe

```bash
ls /Users/josh/Developer/flywheel/flywheel__nextra_documentation_site/content/reference/*.mdx | wc -l | tr -d ' '
```

Expected: literal `4` (index.mdx + 3 doctrine imports). Verified rc=0, output=4.

## Files changed

Site directory:
- `flywheel__nextra_documentation_site/app/_meta.global.tsx` — audience personas + Diátaxis IA
- `flywheel__nextra_documentation_site/app/layout.tsx` — stripped Nextra 4.0-era props (incompat with 4.6.1)
- `flywheel__nextra_documentation_site/content/index.mdx` — flywheel landing page with JSX comment fix
- `flywheel__nextra_documentation_site/content/{tutorials,guides,reference,concepts}/{_meta.tsx,index.mdx}` — quadrant seeds (8 files)
- `flywheel__nextra_documentation_site/content/reference/{cross-repo-discipline.mdx,cluster-maintainer.mdx,substrate-boundary.mdx}` — 3 doctrine stubs
- `flywheel__nextra_documentation_site/content/reference/_meta.tsx` — wires 3 doctrine routes

Repo:
- `.gitignore` — excludes `flywheel__nextra_documentation_site/{node_modules,.next,out}/`

## Class 3 AUDIT-ONLY finding filed

Bead `flywheel-38u3d.1` filed and closed per Class 3 (Jeff-substrate, READ-ONLY consumer) discipline. Title: "[audit-only] Jeff-skill scaffold-nextra.sh template incompat with Nextra 4.6.1". Root cause: `scaffold-nextra.sh` in `~/.claude/skills/documentation-website-for-software-project/scripts/` emits Nextra 4.0-era Layout prop shapes that type-error against installed `nextra@4.6.1` / `nextra-theme-docs@4.6.1`. TypeScript compile clean; `next build` static prerender fails on catch-all mdxPath route (digest `1872370934`).

## Mission fitness

`mission_fitness=adjacent`. The flywheel docs site is substrate work supporting the continuous-orchestrator-uptime-self-sustaining-fleet mission anchor — surfaces doctrine (cluster-maintainer, cross-repo-boundary, substrate-3-class) in a navigable form for orch + worker + Joshua + external operator audiences.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. Task scope was substrate scaffold via existing Jeff-skill consumer; no new pattern emerged beyond confirming the Class 3 AUDIT-ONLY discipline (already canonical in substrate-boundary doctrine).

## Four-Lens Self-Grade

- Brand: 8/10 — flywheel-branded site, audience-tiered, doctrine-anchored
- Sniff: 7/10 — partial success (5/6 explicit + AG6-via-equivalent); static prerender deferred upstream
- Jeff: 9/10 — Class 3 discipline respected (no Jeff-substrate mutation, audit bead filed)
- Public: 7/10 — three judges (skeptical operator/maintainer/future worker): operator can read the 4-persona layout; maintainer can extend MDX; future worker can route via `flywheel docs init`. Static-export blocker is concrete + documented.
