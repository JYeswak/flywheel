# INTENT: joshua-request-capture-system

**Originator:** Joshua (flywheel orch session, 2026-05-03 ~21:00Z)
**Trigger:** "this is a big flywheel fuckup - when I ask for stuff in a project - it needs to be logged as a josh request in the mission file - we cannot forget about stuff that I ask about" + "we need the josh request thing properly planned through /flywheel:plan and locked into our flywheel as a whole across all sessions not a one-time fix"

## Verbatim prompt

> joshua-request-capture-system — codify the full lifecycle of capturing Joshua's verbal/turn-time requests into MISSION.md (or sister substrate) so they cannot be forgotten. Recurring failure: today (2026-05-03) Joshua asked for socraticode indexing of jeff-corpus 5h ago; clone landed, semantic indexing forgotten, no MISSION.md trace; Joshua had to surface it. Earlier this session: peer-reboot recovery, plan-adherence concerns, multiple "you have to ask Joshua" instances. Memory `feedback_orch_paralysis_recurring` codifies the asking-failure side; this plan codifies the forgetting-failure side. Need: (1) canonical Josh-request schema in MISSION.md, (2) auto-capture from orch turn (every Joshua message scanned for request-shape), (3) auto-surface in /flywheel:status + tick prompt, (4) cross-session propagation (stamped to mobile-eats/skillos/alps/picoz/terra-title/zesttube/zeststream-infra MISSION files), (5) closure protocol (when is a Josh-request "done"?), (6) backfill of last 24-48h Joshua requests from this orch transcript.

## Six required deliverables

1. Canonical Josh-request schema (frontmatter or section in MISSION.md, applicable across all flywheel-managed sessions)
2. Auto-capture from orch turn (mechanism for orch CC sessions to detect request-shape in Joshua messages and append to MISSION.md atomically)
3. Auto-surface in /flywheel:status (open requests visible in dashboard) + tick driver prompt (prepended to every loop-driver tick)
4. Cross-session propagation (each peer repo's MISSION.md inherits the schema; doctrine-sync hook propagates schema changes)
5. Closure protocol (state machine: open → acknowledged → in-progress → done|deferred|won't-do, with evidence requirement)
6. Backfill: scan today's flywheel orch transcript for Joshua requests we missed (jeff-corpus socraticode, recovery-doctrine, FoggyBear unretire, others), retroactively log them

## Mode

Plan-space only. File beads. **Do not dispatch** until current 3 in-flight workers free + you sign off on the audit findings.

## Existing related substrate

- Memory `feedback_orch_paralysis_recurring.md` — the asking-side failure (sister to this forgetting-side failure)
- Memory `feedback_data_guides_decisions_not_human_judgment.md` — META-RULE this operationalizes
- Memory `feedback_wire_into_ecosystem.md` — META-RULE: every finding/doctrine/validation gets wired without being reminded
- INCIDENTS doctor-signal-fail-without-bead-promotion (sibling pattern: signal known, mechanism missing)
- MISSION.md current shape: locked frontmatter + Mission Source section, no request log
- Skill `mission-anchor-init` — handles MISSION.md scaffolding
- Skill `canonical-owner-runtime-state` — substrate for runtime state (likely relevant)
- Doctrine: L62 "STATE.md is latent opportunity substrate" (sibling primitive for runtime work)

## Out of scope

- Modifying Joshua's message-input UI (Claude Code harness — out of our hands)
- Auto-fulfilling requests (orch still decides what to dispatch — capture ≠ auto-execute)
- Cross-orch enforcement (each peer's orch is responsible for its own request-capture; we provide schema + propagate)
- Persistence beyond MISSION.md (that's the substrate; sister artifacts can reference but MISSION.md is canon)
