---
name: doctor-repair-triad
description: Candidate skill for requiring doctor/health/repair triads on operational flywheel substrate.
status: approval_only
source_bead: flywheel-w3pr.3
phase4_verdict: EXTEND
---

# Doctor Repair Triad

Use this candidate skill when creating or reviewing an operational script, CLI,
driver, or substrate that other panes rely on.

## Contract

Operational substrate should expose:

- read-only `doctor --json`
- read-only `health` or `status`
- repair path with `--dry-run` before apply
- structured counters that match the checks
- ANSI-free machine JSON
- promotion route for repeated failures

Repair mutates state only with backup or explicit no-backup rationale.

## Source Evidence

- Phase 4 verdict: `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, "Doctor / health / repair triad" = EXTEND.
- `mcp_agent_mail/README.md:721` documents Agent Mail doctor surfaces.
- `mcp_agent_mail/README.md:793` documents doctor repair dry-run behavior.
- `flywheel_connectors/AGENTS.md:17` lists `am doctor fix`, `am doctor repair`, and `am doctor reconstruct`.
- `coding_agent_session_search/README.md:55` documents `cass health --json` and index behavior.
- `meta_skill/tests/e2e/doctor_workflow.rs:179` tests doctor workflow behavior.

## Approval Gates

- Install only after `flywheel-hn8e` lands with PASS/WARN/FAIL examples.
- Keep the live skill separate from L60; L60 remains doctrine, this would be operator workflow guidance.
