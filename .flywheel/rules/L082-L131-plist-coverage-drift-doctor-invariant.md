## L131 — PLIST-COVERAGE-DRIFT-DOCTOR-INVARIANT

---
id: L131
title: Plist coverage drift doctor invariant
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: frozen-projection-of-mutable-state
---

Doctor `plist_coverage_drift` compares live sessions from
`~/.local/state/flywheel/session-topology.jsonl` and `team-roster.jsonl` against
`~/Library/LaunchAgents/com.zeststream.<session>.watcher.plist`. It reports
`sessions_without_plist[]`, `plists_without_session[]`, and `missing_count`;
severity is amber for 1-2 missing active-session watcher plists and red for 3+
missing. Red blocks doctor health.

This closes the `frozen-projection-of-mutable-state` trauma where recovery plans
freeze the fleet roster at authoring time while new sessions are onboarded later
and silently miss reboot survivability coverage.

**Evidence:** bead `flywheel-f7u17`; mobile-eats gap-fill bead
`flywheel-lndxj`; implementation in
`~/.claude/skills/.flywheel/lib/misc.sh` and
`~/.claude/skills/.flywheel/lib/portable/core.sh`; regression
`tests/test_doctor_plist_coverage_drift.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

