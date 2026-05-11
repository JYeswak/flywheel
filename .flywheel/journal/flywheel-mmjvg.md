---
bead: flywheel-mmjvg
title: design flywheel-stamp v0.1 spec
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
directive: Joshua-stamping-process-directive-2026-05-11T23:00Z
---

# Journey: flywheel-mmjvg

## What the bead asked for

P1 — design flywheel-stamp v0.1 spec: catalog skillos exemplar artifacts
(README + ARCHITECTURE + ROADMAP + AGENTS + LICENSE + SECURITY + CONTRIBUTING +
.gitignore + .flywheel/ structure); produce stamp template + idempotent-apply
algorithm; reference Joshua stamping-process directive 2026-05-11T~23:00Z.

## What I shipped

**3 artifacts** under `.flywheel/audit/flywheel-mmjvg/`:

- **SPEC.md** (~270 lines) — 10-section design spec with mission anchor link,
  artifact catalog, placeholder discipline, 6-phase idempotent-apply algorithm,
  validation discipline (pre/post + anchor regex), composition boundary
  (6 non-goals), 7 open questions for v0.2, and natural-unit decomposition
  for follow-on beads
- **stamp-catalog.json** (~180 lines) — machine-readable manifest: 15
  artifact entries (8 root public-face + 7 `.flywheel/` substrate) + 8
  directory scaffolds + canonical placeholder set + publish-readiness scoring
- **evidence.md** — worker-tick evidence pack

## Source of truth measured

`/Users/josh/Developer/skillos` measured 2026-05-11:
- 8 root files (README 331 / ARCHITECTURE 337 / ROADMAP 330 / AGENTS 145 /
  LICENSE 7 / SECURITY 5 / CONTRIBUTING 5 / .gitignore 81)
- 7 `.flywheel/` canonical files (MISSION 168 / GOAL 103 / AGENTS-CANONICAL 145 /
  STATE 1269 / INCIDENTS 31 / PUBLISHABILITY-AUDIT / dispatch-log.jsonl)
- 8 subdir scaffolds

## Key design decisions

1. **Stamp = catalog + algorithm, not monolith** — each artifact is its own
   catalog entry with shape signature + placeholder set + anchor regex
2. **Canonical placeholder set (13 placeholders)** — unknown placeholders fail
   lint at `--doctor` time; makes mission-coherence machine-checkable
3. **Compose with flywheel-loop chokepoint** — stamp mutations route through
   the SAME intent.jsonl + applied.jsonl chain used by `_flywheel_loop_mutate`
   (oxzyr.2.1), so `flywheel-loop doctor undo <run-id>` (oxzyr.2.2) rolls back
   stamp runs byte-exact. **No new undo infrastructure required.**
4. **6-phase apply algorithm** — RESOLVE → DETECT → DIFF → PLAN → APPLY →
   RECEIPT; dry-run terminates at PLAN
5. **5-state classification** — ABSENT / IDENTICAL / DRIFTED_BENIGN /
   DRIFTED_BREAKING / EXTRA_LOCAL; idempotency property formalized
6. **Implementation deferred** — bead asked for spec, not CLI; v0.2 follow-on
   beads sketched per META-RULE 2026-05-10 (decompose-by-natural-unit-not-bundle)

## Mission coherence

`mission_fitness=adjacent`. This spec is substrate enabling the directive
"every jyeswak repo publish-ready or fold/archive" (per memory
`project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11`).
Direct delivery = running the stamp across ~100 repos (v0.2 work).
Without this spec, the directive devolves into hand-stamping toil.

## Compliance

- AG receipt: 10/10
- L52: 0 new beads filed (v0.2 follow-ons noted in SPEC §10; will surface in next planning pass)
- L61: no doctrine/incidents/canonical/L-rule/skill edits; audit-tier substrate only
- L107: only owned audit dir written; NONE_NO_EDITS for shared surfaces
- L120: br close before callback (verified)
- compliance_score: 1000/1000 (P1 quality bar)

## What's next (v0.2 follow-on, not filed)

- flywheel-mmjvg.1 — implement `flywheel-stamp` CLI (5-phase mutation pipeline)
- flywheel-mmjvg.2 — author 15 templates in `stamp/templates/*.tmpl`
- flywheel-mmjvg.3 — apply stamp to first 5 jyeswak repos (round-trip proof)
- flywheel-mmjvg.4 — fleet roll-out across remaining ~95 repos (operator-tended)
