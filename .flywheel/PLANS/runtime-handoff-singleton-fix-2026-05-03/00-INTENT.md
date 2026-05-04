# INTENT: runtime-handoff-singleton-fix

**Slug:** runtime-handoff-singleton-fix-2026-05-03
**Filed:** 2026-05-03T~21:35Z
**Origin:** Joshua directive after flywheel-frov dispatch produced issue draft
**Parent doctrine:** `~/Developer/flywheel/.flywheel/PLANS/bead-isolation-fix-2026-04-30.md` (FM-8 / Change 2.7 / T2.8)

## Verbatim prompt

> runtime-handoff-singleton-fix — long-standing FM-8 from bead-isolation-fix-2026-04-30 plan. ntm runtime_handoff table is effectively a singleton (CHECK id=1, ON CONFLICT id) despite Jeff partially adding working_dir column. Cross-project state can leak as soon as the next handoff is written. We need the FULL plan (research lanes A/B/C → refine → audit → bead DAG → polish) so we can /flywheel:dispatch the actual implementation. Constraint: ntm is Jeff's repo per memory feedback_no_push_ntm_br — we can patch our LOCAL copy but cannot push. Plan should produce beads for: (1) verify partial-migration intent against latest ntm main, (2) author migration + Go-side write-path patches in our local clone, (3) test harness for multi-project handoff, (4) flywheel-loop doctor probe to catch regression, (5) optional Jeff issue contribution if intentionality check passes. Pre-existing artifacts: /tmp/jeff-issue-runtime-handoff-singleton.md, /tmp/jeff-issue-runtime-handoff-repro.sh, /tmp/runtime-handoff-migration-packet.sql from flywheel-frov dispatch.

## Pre-existing artifacts (Phase 1 lanes MUST read these first)

- `/tmp/jeff-issue-runtime-handoff-singleton.md` (high-quality issue draft, includes file:line citations to ntm@0b88f8d5)
- `/tmp/jeff-issue-runtime-handoff-repro.sh` (executable, demonstrates singleton overwrite vs scoped preservation)
- `/tmp/runtime-handoff-migration-packet.sql` (proposed schema migration with backup + rollback)
- `/tmp/jeff-runtime-handoff-intentionality-check.md` (in flight on pane 4: 4-step check; partial result intentionality=2/4 no_file_threshold_met=false)
- `~/.claude/skills/jeff-issue-chain/references/INCIDENTS.md` (new this session: file-without-checking-intentional-API-drift)
- `~/Developer/flywheel/.flywheel/PLANS/bead-isolation-fix-2026-04-30.md` (canonical 4-phase parent plan, FM-1..FM-8)

## Constraints

- **ntm boundary**: Jeff's repo per `feedback_no_push_ntm_br` and `feedback_jeff_issue_chain`. Local patches OK, NO upstream pushes.
- **Cross-orch boundary**: this is flywheel-scope only; do NOT dispatch to skillos/mobile-eats/alps panes.
- **Skill source-(a)**: per META-RULE 2026-05-03, lanes consult `/flywheel:skills-best-practices` first.
- **Doctor signal**: success metric is leakage_count drop in `flywheel-loop doctor --json` AND multi-project handoff test passes.

## Out of scope (explicit anti-decisions)

- Patching beads_rust (separate FMs, separate plan)
- Mobile-eats / skillos / alps runtime_handoff state (their orchs own their own)
- Migrating Jeff's upstream beads_rust schema (we file issues, not PRs)

## Success criteria

- Local ntm clone patched + tested for multi-project handoff
- Test harness reproducible (lives in flywheel repo or jeff-corpus)
- flywheel-loop doctor gains a `runtime_handoff_singleton_check` probe
- leakage_count metric tracks runtime_handoff scope as a sub-component
- Decision documented on whether/how to contribute upstream (issue vs PR vs neither)
