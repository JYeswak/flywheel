# INTENT: skill-handoff-to-skillos

**Originator:** Joshua (flywheel orch session, 2026-05-03)
**Trigger:** info-source-watchtower meta-skill shipped 2026-05-03 18:44Z (commit pending). No fleet-mail handoff sent to skillos. Joshua flagged: skill creation in any flywheel-managed session must accretively flow into the canonical skill pack ecosystem that skillos curates. Skillos perceived to be under-investing in pack curation.

## Verbatim prompt

> note all skills that we create need to get sent over to skillos to bring into our system accretively - we should have proper dispatch template to send over to them - it needs run through full process and brough tinto our skill pack ecosytem. I dont think skillos is putting anywhere near enough attention on the skill pack ecosystem.

## Five required deliverables

1. Reusable dispatch template — flywheel/.flywheel/templates/skill-handoff-to-skillos.md
2. Acceptance gate added to flywheel canonical dispatch template requiring handoff for any skill-creation dispatch
3. Skillos-side intake validation schema (matches existing `state/canonical-cli-scoping-v0.2-2026-05-01.json` shape)
4. Backfill audit: every skill ~/.claude/skills/* with mtime in last 30d that bypassed handoff
5. Learning signal class: `skill-shipped-without-skillos-handoff` registered in fuckup-log heuristics

## Mode

Plan-space only. File beads. **Do not dispatch** until current ready queue drains (currently 4 in-progress + 14 ready beads as of 18:50Z).

## Proven precedent (load-bearing)

- **LavenderGlen → FoggyBear fleet-mail handoff** (canonical-cli-scoping v0.1.0 → v0.2.0) produced skillos bead `skillos-fhj`, full hardening receipt, ownership-policy adjudication, and qdrant catalog refresh. Receipt at `~/Developer/skillos/state/canonical-cli-scoping-v0.2-2026-05-01.json`.
- **Doctrine-relay intake pipeline** (skillos bead `skillos-2j8`, 2026-05-01) routes 13 doctrine messages from fleet-mail into skill-pack creation/amendment decisions.
- The pattern works. We are codifying, not inventing.

## Out of scope

- Touching skillos's own loop or rotating its GOAL (that's skillos orch's job; we surface concerns via agent-mail)
- Reviewing/hardening info-source-watchtower itself (that's the receiving side)
- Changing the qdrant catalog or skill-search-mcp (skillos owns)
- Any skillos-side code edits (cross-orch boundary violation per memory feedback)
