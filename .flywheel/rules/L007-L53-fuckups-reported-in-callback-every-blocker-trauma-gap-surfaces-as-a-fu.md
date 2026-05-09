## L53 — FUCKUPS-REPORTED-IN-CALLBACK (every blocker / trauma / gap surfaces as a fuckup-log row)

---
id: L53
title: Fuckups reported in every dispatch callback
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: trauma-amnesia
---

**Rule:** Every BLOCKED callback AND every DONE callback that hit a trauma along the way MUST log a fuckup-log row via `flywheel-loop fuckup log` BEFORE sending the callback. The callback then references the fuckup-log row IDs (or the JSONL line numbers, or the trauma_class names) so the orchestrator can correlate the callback with the durable record.

DONE callbacks for clean dispatches MAY skip fuckup logging (no trauma → nothing to log). BLOCKED callbacks MUST always log at least one fuckup row describing the blocker.

**Why:** Without enforcement, traumas survive only in pane scrollback and then evaporate at /clear time or session end. The fuckup-log substrate (shipped 2026-04-30 via ac02fb6 + f8efbec) only compounds value if every dispatch contributes rows. Trauma-amnesia is the failure mode where the same blocker surprises the next worker on the next session because nobody persisted it.

**Mechanism:**
- Pre-flight in dispatch packet: instructions to call `~/.claude/skills/.flywheel/bin/flywheel-loop fuckup log --class=<trauma> --severity=<sev> --what-happened=<text>` on every blocker
- Callback contract: BLOCKED requires `fuckups_logged=<class1>,<class2>,...`; DONE may include `fuckups_logged=` if any traumas were observed (empty is valid for clean DONE)
- Auto-emission complement: even if the worker forgets, hook-blocks/overrides auto-harvest catches volume signals (per L50 doctrine — both manual and automatic)

**Forbidden worker callback outputs:** BLOCKED missing `fuckups_logged=` field; DONE that hit a documented trauma without `fuckups_logged=`.

**Override:** None for BLOCKED. JOSHUA_OVERRIDE does not bypass L53 because escalation without a durable trauma record is exactly the substrate-amnesia mode this rule prevents.

**Cost citation:** br DB wedge recurred multiple times today (2026-04-30) before being captured as a fuckup row. The first 2 wedges left no record other than scrollback; only the third triggered the manual fuckup log entry. With L53 in place, every wedge would have been recorded immediately, and triage would have surfaced "br-db-wedge fired 3 times this session" before the human noticed.

**Companion rules:** L48 (substrate-exhaustion) requires probe ledger before escalating to Josh — the probe ledger and the fuckup-log row are different artifacts (ledger = "what I tried", fuckup-log = "what failed"). Both required, not redundant.


