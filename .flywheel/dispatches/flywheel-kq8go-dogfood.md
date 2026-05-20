# flywheel-kq8go T1+24..48h Dogfood — 3 dispatch types via new activation primitive

## Context

Joshua-ratified 2026-05-20T00:25Z 4-layer codex /goal-mode enforcement. T1+0..24h shipped probe + daemon + wrapper + dispatch.md update (commit cf6fec64). T1+24..48h dogfood = run 3 distinct dispatch types through the new path + verify Pursuing-goal state achieved + file class-divergence findings.

## Deliverables (single bead = flywheel-kq8go close on completion)

### Type 1: quick-fix dispatch (small, single-file edit)
- Spec: Read tests/codex-goal-mode-monitor-probe-smoke.sh end-to-end + verify all 8 assertions cover the 5 trauma classes correctly. If any class is uncovered, add the assertion. Report which assertions exist for each of 5 classes.
- Expected: ≤2min, Pursuing goal entered <5s, completes cleanly.

### Type 2: deep-work dispatch (multi-file investigation + audit)
- Spec: Audit .flywheel/scripts/codex-goal-mode-monitor-probe.sh against the canonical regexes in .flywheel/specs/pane-work-signal-taxonomy-v0.2.md (skillos canonical, commit fc809a04). Flag any divergence in classifier regex, state transitions, or trauma class triggers. Report at .flywheel/audits/probe-vs-taxonomy-v0.2-conformance-20260520.md.
- Expected: 10-15min, multiple file reads, Pursuing goal stays continuous (no abandonment).

### Type 3: multi-bead-sprint dispatch (paired beads in one /goal)
- Spec: Address flywheel-w8mxo (auto-push/MISSION.md collision allow-list fix) + flywheel-q9nzb (MISSION.md frozen-projection decomposition 22867-line journal). Two paired beads, scoped phases. Close both on completion.
- Expected: 30-60min, repeated Pursuing-goal evidence, callback row written for both bead closes.

## ACCEPTANCE

- All 3 dispatch types complete successfully via codex-goal-activate.sh path
- Each dispatch reaches Pursuing-goal state within 30s (Layer 2 verification passes)
- Each dispatch stays in Pursuing-goal until callback fires (no Layer 3 trauma)
- Each callback row in dispatch-log.jsonl captures goal_mode_trauma_fired (should be empty array for clean runs)
- Audit report at .flywheel/audits/probe-vs-taxonomy-v0.2-conformance-20260520.md
- Bead flywheel-kq8go closed with summary of all 3 dispatch outcomes
- Class-divergence findings filed back to skillos:1 via cross-orch handoff IF any are observed

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- DEEP-WORK validate: each dispatch outcome + final summary
- STOP on Track 1/2 breach, BLOCKED, agent-mail loop fail, >4h hard cap
- Bridge daemon LIVE — auto-routes callback. Belt+suspenders: ntm send flywheel --pane=1.
- SCR event: C7_verification_density (dogfood validation IS verification)

## FIRST ACTION

1. br show flywheel-kq8go.
2. ACK row.
3. Execute Type 1 → Type 2 → Type 3 sequentially.
4. Compile summary, file audit report, close bead, send callback.
