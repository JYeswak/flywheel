## L55 — SKILLOS-ESCALATION-FOR-MISSING-SKILLS (when no skill exists for a trauma class, route to skillos)

---
id: L55
title: Missing-skill escalation routes to skillos session
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: skill-arsenal-gap
---

**Rule:** When L54 deep-dive returns `skills_consulted=NONE_FOUND` for a recurring trauma class (3+ fuckup-log occurrences within 7 days), the trauma is escalated to the **skillos NTM session** as a candidate skill. Escalation mechanism:
1. Worker logs the fuckup with `should_become=skill`
2. Doctor's `fuckup_triage` section flags 3+ `NONE_FOUND` rows of same class as candidate for skillos
3. Orchestrator (or doctor itself, future) sends a draft-skill packet to skillos via `ntm send skillos --pane=1` with the trauma class, evidence sample, and proposed skill name
4. skillos session handles authoring, review, and publication into `~/.claude/skills/<name>/` per its own MISSION/GOAL/STATE
5. Once published, the next worker hitting the same trauma finds the skill via L50 socraticode survey → loop closes

**Why:** The skill arsenal only compounds if missing skills are systematically authored, not ad-hoc patched. Authoring inside consumer sessions (picoz orchestrator pauses to write a skill mid-trade-decision) pollutes the skill with consumer context. Authoring in skillos keeps skills universal-first per skillos MISSION.md.

**Mechanism:**
- Trigger: `flywheel-loop doctor` `fuckup_triage` candidate with `should_become=skill` AND frequency ≥3-in-7d
- Routing: `ntm send skillos --pane=1` with structured packet:
  ```
  CANDIDATE_SKILL trauma_class=<class> frequency=<count> evidence=<3-row-sample> proposed_name=<kebab-case-suggestion> originating_session=<which-session-hit-this>
  ```
- skillos consumes via its own tick loop; worker dispatches don't block waiting for skill authoring (asynchronous)
- New skill ships when ready; L50 socraticode survey makes it discoverable on next dispatch

**Forbidden orchestrator outputs:** sending CANDIDATE_SKILL packets to any session other than skillos. The dedicated session is the only authorized author of new skills (other sessions consume, never write to `~/.claude/skills/`).

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits direct authoring in a non-skillos session for emergencies (e.g. mid-incident response, can't wait for skillos cycle). Logged; reviewed at next petal-9 close.

**Cost citation:** ~280 existing skills accreted ad-hoc across 4 months — many duplicate each other, none have provenance, none were authored against a shared quality bar. L55 prevents the next 280 from accreting the same way.

**Companion rules:** L54 (skill deep-dive on blockers) detects the gap. L55 (this) closes it. skillos MISSION.md (`~/Developer/skillos/.flywheel/MISSION.md`) defines the receiving substrate.

**Receiving substrate state (2026-04-30):** skillos session exists in NTM (`skillos`), repo bootstrapped at `~/Developer/skillos/`, MISSION.md drafted (status=draft awaiting Josh review). L55 enforcement active once MISSION.md locks AND `flywheel-loop init --repo /Users/josh/Developer/skillos` succeeds. Until then, CANDIDATE_SKILL packets queue at `~/.local/state/flywheel/skillos-pending-candidates.jsonl` for skillos to drain on first tick.


