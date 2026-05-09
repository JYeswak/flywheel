## L135 — SKILL-DISCOVERY-CALLBACK-FIELDS

---
id: L135
title: Skill discovery callback fields
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: skill-discovery-substrate-unwired
---

Workers MUST report `skill_discoveries=<N> sd_ids=<list|none>` in DONE and
BLOCKED callbacks. When discoveries are emitted, workers append rows to
`~/.local/state/flywheel/skill-discoveries.jsonl` and include the emitted
`sd-*` IDs. `skill_discoveries>0 sd_ids=none` rejects close. Legal
no-discovery reasons are documented in the dispatch template.

**Evidence:** bead `flywheel-nvny`; dispatch contract
`~/.claude/commands/flywheel/_shared/dispatch-template.md`; worker contract
`~/.claude/commands/flywheel/worker-tick.md`; validator
`.flywheel/scripts/validate-skill-discovery-callback.sh`; tests
`tests/test_skill_discovery_callback_valid.sh` and
`tests/test_skill_discovery_callback_mismatch.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

