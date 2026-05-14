## L55 — CAPABILITY-CONTROL-PLANE-ESCALATION-FOR-MISSING-SKILLS (when no skill exists for a trauma class)

---
id: L55
title: Missing-skill escalation routes to the capability control plane
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: skill-arsenal-gap
---

**Rule:** When L54 deep-dive returns `skills_consulted=NONE_FOUND` for a
recurring trauma class (3+ fuckup-log occurrences within 7 days), the trauma is
escalated to the configured capability-control-plane lane as a candidate skill.
Escalation mechanism:

1. Worker logs the fuckup with `should_become=skill`
2. Doctor's `fuckup_triage` section flags 3+ `NONE_FOUND` rows of the same class
   as a candidate for capability-pack authoring.
3. Orchestrator or doctor sends a draft-skill packet to the configured
   capability-control-plane lane with the trauma class, evidence sample, and
   proposed skill name.
4. The capability-control-plane lane handles authoring, review, and publication
   into the configured skills root per its own mission, goal, and state.
5. Once published, the next worker hitting the same trauma finds the skill via L50 socraticode survey → loop closes

**Why:** The skill arsenal only compounds if missing skills are systematically
authored, not ad-hoc patched. Authoring inside consumer sessions pollutes the
skill with consumer context. Routing through a capability-control-plane lane
keeps skills universal-first.

**Mechanism:**
- Trigger: `flywheel-loop doctor` `fuckup_triage` candidate with `should_become=skill` AND frequency ≥3-in-7d
- Routing: send a structured packet to the configured capability-control-plane
  lane:
  ```
  CANDIDATE_SKILL trauma_class=<class> frequency=<count> evidence=<3-row-sample> proposed_name=<kebab-case-suggestion> originating_session=<which-session-hit-this>
  ```
- The capability-control-plane lane consumes via its own tick loop; worker
  dispatches do not block waiting for skill authoring.
- New skill ships when ready; L50 socraticode survey makes it discoverable on next dispatch

**Forbidden orchestrator outputs:** sending CANDIDATE_SKILL packets to an
unconfigured consumer lane. The dedicated capability-control-plane lane is the
only authorized author of new shared skills; other sessions consume.

**Override:** `HUMAN_OVERRIDE='<reason>'` permits direct authoring in a consumer
lane for emergencies. The override must be logged and reviewed at closeout.

**Cost citation:** ~280 existing skills accreted ad-hoc across 4 months — many duplicate each other, none have provenance, none were authored against a shared quality bar. L55 prevents the next 280 from accreting the same way.

**Companion rules:** L54 (skill deep-dive on blockers) detects the gap. L55
(this) closes it. The receiving substrate is defined by the installed
capability-control-plane lane's repo-local mission.

**Receiving substrate state:** enforcement is active only after the configured
capability-control-plane lane has a locked repo-local mission and passes
`flywheel-loop init`. Until then, CANDIDATE_SKILL packets queue in repo-local
state for the lane to drain on first tick.

