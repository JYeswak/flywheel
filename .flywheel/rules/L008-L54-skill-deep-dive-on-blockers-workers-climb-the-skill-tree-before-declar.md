## L54 — SKILL-DEEP-DIVE-ON-BLOCKERS (workers climb the skill tree before declaring a wall)

---
id: L54
title: Skill deep-dive on blockers before BLOCKED callback
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: skill-substrate-bypass
---

**Rule:** Before any worker sends a BLOCKED callback, they MUST climb the skill tree:
1. List skills relevant to the trauma class (`ls ~/.claude/skills/ | grep -i <relevant-keyword>`)
2. Read SKILL.md + any "Recovery" / "Common failures" section in 2-3 most-relevant skills
3. Attempt the recovery path documented in those skills, record outcomes
4. Only after rungs 1-3 produce no resolution may BLOCKED be sent

BLOCKED callbacks must include `skills_consulted=<name1>,<name2>,...` listing every skill whose recovery path was actually executed (not just listed). Empty `skills_consulted=` on a BLOCKED callback is non-compliant — even for trauma classes that have no obvious skill, the worker MUST report the search attempted (e.g. `skills_consulted=NONE_FOUND grep_terms_used=br-db-wedge,beads-corrupt,sqlite-recovery`).

**Why:** We have ~280 skills in `~/.claude/skills/`. Most workers blocked today never consulted a single one before escalating. Skill substrate bypass is the failure mode where 4 months of accreted reusable knowledge sits unread because workers default to "ask the orchestrator" or "ask Josh" before reading the arsenal.

**Mechanism:**
- Pre-flight in dispatch packet: explicit list of "skills likely relevant to this dispatch" (orchestrator does the initial mapping; worker still verifies and consults)
- Callback contract: BLOCKED requires `skills_consulted=<list-or-NONE_FOUND>`. DONE may include the field if skills helped but it's optional for clean DONE.
- Escalation chain (per L48 + L54): substrate probe → self-heal tool → **skill recovery section (L54)** → cross-repo precedent → only then human

**Forbidden worker callback outputs:** BLOCKED missing `skills_consulted=` field; BLOCKED with empty list and no `NONE_FOUND` justification with grep_terms_used.

**When no skill exists for the trauma:** This is the L55 trigger — escalate to skillos session for new skill authoring (see L55 below).

**Cost citation:** alpsinsurance idle 2026-04-30 hours waited at "Railway token Q1/Q2 for Josh" — both `infisical-rotation-ops` and `railway-api` skills exist with recovery sections covering the exact wall (project-token generation + browserless OTP). Worker never read either. L54 makes that read mandatory.

**Companion rules:** L48 (substrate-exhaustion-before-escalation) is the broader 5-rung ladder; L54 is the specific "rung 3" enforcement. Without L54, agents declared L48 satisfied while skipping the skill rung.


