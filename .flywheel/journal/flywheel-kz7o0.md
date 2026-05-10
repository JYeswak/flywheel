---
bead: flywheel-kz7o0
title: fleet-comms-health-probe.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent: flywheel-ok1sk (jloib wave-1; sub-bead 5 of 17)
sister_exemplars: 0pkcf=985, ou656=985, lrdum=985, gbfpo=985 (avg 985)
---

# Journey: flywheel-kz7o0

## What Joshua asked for

Wave-1-doctrine-5 (5th ok1sk sub-bead). Bash wrapper around Python heredoc;
larger surface (673 lines) than typical sister bash files. Bash scaffolder
applied normally.

## What I shipped

- 18 TODO markers filled with substantive impl
- doctor: 7 named probes (python3_available, jq_available,
  repo_root_resolvable, loops_dir_present, agent_mail_state_dir_present,
  ntm_executable, audit_log_dir_writable) — the fleet-comms-health domain
  has more substrate deps than typical indexers (load-bearing trio: python3 +
  ntm + agent_mail_state_dir)
- health: $SCAFFOLD_AUDIT_LOG binding with stale-threshold
- repair: 2 scopes (state_dir, audit_log_dir) with apply contract
- validate: 3 subjects with domain-specific contracts:
  - **session-topology-row**: enforces JSONL row contract with 4 required
    fields (session, orchestrator_pane, orchestrator_kind, effective_at) —
    matches session-topology-ledger/v1 schema
  - **ledger-path**: 2-layer enforcement (under ~/.local/state/flywheel/ +
    .jsonl extension) with distinct reason codes
  - audit-row: standard
- audit + why: standard sister pattern
- Test 13 → 19 (calibrated 2 + added 6 fillin including 2 ledger-path
  rejection tests with reason-code assertions + session-topology-row test)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean.

## Notable

- `validate session-topology-row` is a NEW shape — the previous beads
  (lrdum, gbfpo) had `bead-id` as a string-pattern subject; this one has
  `session-topology-row` as a JSONL row-shape subject. Both are valid
  validate patterns; the choice depends on what the surface canonicalizes.
- `validate ledger-path` reuses the wzjo9.2.1 / lrdum 2-layer pattern but
  swaps the `.flywheel/audit/` constraint for `~/.local/state/flywheel/`
  (the per-flywheel-instance state ledger location) — surface-appropriate.

## Files touched

- `.flywheel/scripts/fleet-comms-health-probe.sh` (673 → 1162 lines)
- `tests/fleet-comms-health-probe-canonical-cli.sh` (13 → 19 tests)
- `.flywheel/audit/flywheel-kz7o0/{evidence,journey,compliance,smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-kz7o0.md`

## Mission fitness

Class: **direct**. Wave-1-doctrine-5 sub-bead from ok1sk decomposition;
canonical-cli scaffold + fillin on a doctrine-lane fleet comms probe.
