## L61 — DOCTRINE-LANDING-WIRES-INTO-AGENTS-AND-README

---
id: L61
title: Doctrine landing wires into AGENTS and README
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: doctrine-orphaning
---


When new doctrine, INCIDENTS entries, or canonical patterns land via dispatch
or worker callback, the orchestrator MUST update `AGENTS.md` (new L-rule) AND
the relevant `README.md` within the same session. Doctrine without ecosystem
wire-in becomes orphaned doctrine — referenced in beads, dispatch logs, and
fuckup-log rows, but invisible to anyone reading the repo.

**Reason:** `feedback_wire_into_ecosystem` META-RULE has been firing as
reminder for weeks but produced 0 AGENTS.md updates per session repeatedly
(observed 2026-05-03 ~09:10Z by Joshua: "i'm also not seeing enough emphasis
put on readme and agents.md files - didn't we wire that into the flywheel?
why aren't agents doing more of it"). META-RULE without mechanical gate =
META-suggestion.

**How to apply:**
- After any doctrine landing (INCIDENTS write, canonical-cli-scoping skill ship,
  bead-promoted-to-L-rule, new probe shipped), orchestrator runs ecosystem-touch
  before declaring "done":
  1. Append new L-rule to `<repo>/AGENTS.md` with: name, why, how-to-apply,
     forbidden outputs, evidence, companion rules
  2. Update `<repo>/README.md` if doctrine changes the user-facing narrative
     (new CLI, new tick step, new mission) OR if last-updated timestamp >7d
  3. Cross-reference into `~/.claude/projects/-Users-josh-Developer-flywheel/memory/`
     entry if doctrine spans sessions
- Workers receiving dispatches that land doctrine MUST include `agents_md_updated=yes|no`
  in callback fields; orchestrator MUST refuse to call work "done" if `no` without
  explicit no-touch reason
- Skipping ecosystem-touch is a SOFT violation `orch_skipped_ecosystem_touch`
  logged to fuckup-log

**Forbidden outputs:**
- Declaring a tick "complete" or a bead "closed" with new doctrine but
  AGENTS.md/README untouched in the same session
- Filing more new beads without first wiring previous session's doctrine
- "META-RULE acknowledged" responses without immediate ecosystem touch

**Evidence:** This conversation 2026-05-03 ~09:10Z (Joshua flag);
`feedback_wire_into_ecosystem` memory entry (META-RULE source);
4+ doctrine landings tonight (loop-integrity, R1-INCIDENTS, mobile-eats receipt,
FD doctor, skillos pattern) with 0 AGENTS.md updates before this rule landed —
self-validating evidence.

**Companion rules:** L56 (fuckup-log → L-rule promotion ladder ends here, not at INCIDENTS); L52 (every fuckup gets a bead OR no-bead reason — same shape applies to ecosystem touch); `feedback_wire_into_ecosystem` memory.

