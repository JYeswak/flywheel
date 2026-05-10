---
title: "Plan Intent — validator-v2-three-outcome-and-stock-backpressure"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Plan Intent — validator-v2-three-outcome-and-stock-backpressure

**Slug:** validator-v2-three-outcome-and-stock-backpressure-2026-05-04
**Started:** 2026-05-04T13:30:00Z (approx)
**Triggered by:** Joshua 2026-05-04: *"I want this proper /flywheel:plan - this is a key component to how our system works and I cannot afford a quick fix - if you are 100% confident in the solution, lock it down, but if there is any ambiguity it needs proper planning."*
**Approval:** explicit ("we have 1 worker active right now - how do we have so many in progress beads? are beads not getting closed or re-addressed? that seems like a stock issue")

## Verbatim trigger

The validator at `~/Developer/flywheel/.flywheel/scripts/validate-callback-before-close.sh` (438 lines, v1.1.0) is causing problems:

1. **Halt-disease at the validator layer.** Every FAIL count > 0 → BLOCK_CLOSE, even when 4/4 lenses PASS but a substrate probe (`br dep cycles`) throws. The validator weaponizes its own bugs against the work it should be approving. Today: B1 (halt-contract schema) and B3 (regression fixture) — both 4/4 lens PASS — both BLOCK_CLOSE'd because `br dep cycles` returned `UNIQUE constraint failed: export_hashes.issue_id`.

2. **Stock-without-balancing-flow** at the bead-DB level. Last 5 days: 912 → 447 open beads. Created vs closed deltas: +0, +85, +11, +175, +275. Cumulative +546 in 5 days. Inflow has positive feedback amplifiers (every BLOCK_CLOSE files a rework child, every plan-decompose creates 5-13 beads, every audit-gap files children). Outflow is bottlenecked by the validator + single-orchestrator routing. Donella's missing balancing loop (#7) on stock size doesn't exist.

3. **Validator is a key Donella-Meadows + Jeff-inspired system component.** Joshua's framing: not a "quick fix" candidate. Three-outcome contract (BLOCK_CLOSE | CLOSE_WITH_REWORK_DEBT | SAFE_TO_CLOSE) is conceptually right (per Lane B yesterday) but the edge cases are non-trivial:
   - How does CLOSE_WITH_REWORK_DEBT interact with the existing rework-bead auto-creator (validator-v1 lines 325-364)?
   - Does the rework debt become metadata on the parent (kills inflow) or a still-spawned child with cap+SLA (preserves visibility but maintains some inflow)?
   - When does substrate-probe failure → SCOPED warning vs → BLOCK_CLOSE?
   - How does the bead-stock backpressure rule interact with legitimate burst-create work like plan-decompose phases?
   - What's the canonical "rework debt cap" before doctor halts new debt creation? Per-lens or aggregate?
   - How do existing in-progress rework-children (~50+ from yesterday's BLOCK_CLOSE cascade) get reconciled into the new debt model?

## Goal

Plan that produces:

### A. Validator v2 — three-outcome contract
1. `BLOCK_CLOSE` — only for hard truth/safety/security/secret/false-claim. Enumerated failure classes.
2. `CLOSE_WITH_REWORK_DEBT` — artifact real, smoke proof real, but lens fail / thin evidence / publishability gap. Parent closes with `rework_debt` metadata + optional auto-created child bead with SLA + cap.
3. `SAFE_TO_CLOSE` — clean, all gates passed.

### B. Substrate-probe failure handling — fail-forward not fail-closed
Validator distinguishes "my own probe threw" from "probe returned a real finding." When probe throws (e.g., `br dep cycles` UNIQUE constraint), emit SCOPED warning for that probe class only, validate the rest, do not weaponize own bugs.

### C. Bead-stock backpressure — Donella's missing balancing loop
Doctor exposes:
- `open_bead_stock_count`
- `inflow_outflow_ratio_7d`
- `oldest_in_progress_zombie_age_h`
- `closed_with_rework_debt_count`
- `oldest_debt_age_hours`
- `debt_cap_breached_count`

When `inflow_outflow_ratio_7d > 1.5` for 3 days, doctor emits a halt-contract that BLOCKS new bead creation classes (plan-decompose, skill-enhance-batch, audit-gap children). PERMITS close-and-rework dispatch. PERMITS Joshua-override.

### D. Zombie auto-resume
Any in_progress bead >24h without active worker → doctor emits `zombie_in_progress_count`. Watchdog auto-reopens (status: open) so the bead doesn't permanently squat.

### E. Migration — existing 50+ in-flight rework beads
What happens to them? Auto-roll-up into parent metadata? Manual triage? Drop and start fresh? Plan addresses.

### F. Three-judges audit pass (per /flywheel:plan v2 doctrine)
Validator v2 must pass the publishability bar against itself. Phase 3 includes that audit per the rubric at `~/.claude/skills/.flywheel/prompts/three-judges-rubric.md` and `.flywheel/PUBLISHABILITY-BAR.md`.

## Goal NOT in this plan (explicit out-of-scope)

- Beads DB substrate repair (UNIQUE constraint failed: export_hashes.issue_id) — separate substrate work
- Halt-contract/v1 schema (already shipped via halt-fix-b1)
- Watchdog (B2) — still in flight on pane 3
- Regression fixture (B3) — already shipped, awaiting close
- Storage decisions (OrbStack, etc) — separate plan

## Donella lens mapping

- **#5 Rules:** binary BLOCK_CLOSE | SAFE_TO_CLOSE → three-outcome decision matrix; "every gap files a child" → "debt is metadata unless it crosses cap"
- **#4 Self-organization:** debt queue self-organizes (cap blocks new debt, not work; oldest-debt SLA drains); zombies auto-reopen
- **#7 Balancing feedback:** missing inflow/outflow balancing loop ADDED via stock-backpressure halt-contract
- **#6 Information flows:** append-only validator audit log makes validator behavior measurable
- **#3 Goals:** "ship safe + queue rework debt" replaces "block every imperfection"

## Jeff lens mapping

- **Doctor:** validator emits scoped halt-contract/v1, not binary halt
- **Measurement:** append-only `.flywheel/state/validator-history.jsonl` per run; doctor consumes counts
- **Repair:** when probe throws, scoped degrade; when debt cap breaches, halt new debt creation
- **Append-only-audit-log pattern** (the same pattern 20+ skill-enhance beads want adopted): every validator decision = one immutable JSONL row
- **Callback-envelope-shape pattern**: validator output is a callback envelope, must follow Jeff's shape

## Constraints

- READ-ONLY through Phase 3
- Phase 4 mutates beads DB only (new beads created)
- Phase 5 polishes
- Code edits via separate /flywheel:dispatch after plan converges
- Compose-not-replace: layer on existing `validate-callback-before-close.sh`, `flywheel-doctor-author`, `gate-truth-separation`, `loop-enforcement`, `donella-meadows-systems-thinking`, `jeff-convergence-audit`
- ntm-only for any pane probes (per `feedback_use_ntm_not_raw_tmux.md`)
- Topology lookup before any cross-session dispatch (per `feedback_topology_lookup_before_dispatch.md`)
- Three judges audit pass mandatory (per /flywheel:plan v2 §"three-judges publishability audit")

## Worker capacity at plan start

Probe at 2026-05-04T13:30Z:
- pane 2: WAITING codex ✓
- pane 3: THINKING codex (B2 halt-disease-watchdog still in flight from yesterday)
- pane 4: WAITING codex ✓

**Capacity: 2/3 — one short of Phase 1 fanout.**

Options:
1. WAIT for pane 3 to finish B2 callback (preferred — same Phase 1 cohort)
2. SEQUENTIAL Phase 1 (Lane A first, then Lane B, then Lane C — 3× wall-clock)
3. ABORT and resume after pane 3 frees

## Sources cited (Phase 1 packets must include)

- `donella-meadows-systems-thinking` — leverage points, anti-patterns, stock/flow
- `jeff-convergence-audit` — convergence pattern this plan embeds
- `flywheel-doctor-author` — doctor/measurement/repair triad
- `gate-truth-separation` — gate semantics
- `loop-enforcement` — orchestration discipline
- `validate-callback-before-close.sh` v1.1.0 — current validator (438 lines)
- Yesterday's halt-disease lanes A/B/C at `/tmp/halt-disease-lane-{a,b,c}-output.md`
- Three-judges rubric at `~/.claude/skills/.flywheel/prompts/three-judges-rubric.md`
- `.flywheel/PUBLISHABILITY-BAR.md`
- Halt-contract/v1 schema at `templates/flywheel-install/halt-contract/v1.schema.json` (B1 deliverable)
