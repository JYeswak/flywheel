# L171 — SKILL-CREATION-REQUIRES-SKILLOS-HANDOFF

---
id: L171
title: Skill creation requires SkillOS handoff
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: skill-shipped-without-skillos-handoff
---

Any dispatch, worker tick, or helper run that creates or modifies
`~/.claude/skills/<name>/` MUST complete the SkillOS handoff path after file
reservations are released and before callback.

The callback is compliant only when it includes one of these fields:

- `skillos_handoff_message_id=<int>` when `.flywheel/scripts/handoff-skill-to-skillos.sh`
  sends the handoff to SkillOS.
- `skillos_handoff_skipped_reason=<text>` when the dispatch cannot or should not
  hand off the skill, with the reason stated explicitly.

Callbacks touching `~/.claude/skills/<name>/` with both fields blank are
non-compliant under this rule.

## Why

Skill files are not the system of record for capability truth. SkillOS owns the
capability control plane: indexed catalog truth, version tracking, hardening
cycles, and reusable pack status. When a skill ships only to the local
filesystem, it can sit at `v0.1.0`, miss its hardening loop, and be rediscovered
or re-authored by future agents instead of becoming fleet substrate.

Origin incident: `info-source-watchtower` shipped without SkillOS handoff proof
and required manual orchestrator intervention to discover the gap. That incident
is recorded as `skill-shipped-without-skillos-handoff` in `INCIDENTS.md`, and the
matching heuristic is registered in `templates/fuckup-heuristics.json`.

## Mechanism

Required close path for any skill-writing dispatch:

1. Reserve the skill files before editing.
2. Release reservations after the write path is complete.
3. Run `.flywheel/scripts/handoff-skill-to-skillos.sh <skill-name> <version>` or
   record a concrete `skillos_handoff_skipped_reason`.
4. Include `skillos_handoff_message_id` or `skillos_handoff_skipped_reason` in
   the callback and dispatch-log row.
5. Treat a callback missing both fields as a contract failure, not as an
   informal follow-up.

## Evidence

- Bead: `flywheel-w307`.
- Origin gap: `info-source-watchtower` skill callback omitted SkillOS handoff
  evidence.
- Incident class: `INCIDENTS.md#skill-shipped-without-skillos-handoff`.
- Helper: `.flywheel/scripts/handoff-skill-to-skillos.sh`.
- Dispatch callback gate: `tests/skillos-handoff-dispatch-template.sh`.
- Heuristic registration: `tests/fuckup-heuristics-skillos-handoff.sh`.
- Coverage audit: `tests/audit-skill-handoff-coverage.sh`.

## Companion Rules

- L52 — findings become beads or explicit no-bead receipts.
- L53 — blocker, trauma, and gap rows surface in the fuckup log.
- L56 — recurring fuckups promote through the L-rule ladder.
- L96 — doctrine lands as a three-surface diff or does not land.
- L146 — skill enhancement honors JSM management boundaries.

