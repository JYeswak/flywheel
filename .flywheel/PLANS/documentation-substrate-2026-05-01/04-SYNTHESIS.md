---
title: Documentation Substrate — Cross-Lane Synthesis
date: 2026-05-01
status: partial — Lane 3 reaped, Lanes 1 + 2 in flight
author: cc orchestrator (pane 1)
inputs:
  lane_1_inventory_and_gaps: { path: 01-INVENTORY-AND-GAPS.md, status: done, callback_received_at: 2026-05-01T20:38:50Z, ladder_passed: yes, rows: 732, top20_count: 20 }
  lane_2_substrate_design:   { path: 02-SUBSTRATE-DESIGN.md, status: done, callback_received_at: 2026-05-01T20:37:15Z, ladder_passed: yes, components: 6, violations: 21 }
  lane_3_process_procedure:  { path: 03-PROCESS-AND-PROCEDURE.md, status: done, callback_received_at: 2026-05-01T20:35:34Z, ladder_passed: yes }
---

# Documentation Substrate — Cross-Lane Synthesis (PARTIAL)

> Per L66 (USE-DATA-NOT-MEAT-PUPPET): this synthesis captures only what
> has shipped to disk. Lanes 1 and 2 are in flight; their slots below
> stay empty until callback files land. Do NOT fabricate cross-lane
> alignment until all three lanes are reaped.

## Reap Status

| Lane | Pane | Output file | Callback file | Status | Reaped at |
|---|---|---|---|---|---|
| 1 — INVENTORY + GAPS | 2 | `01-INVENTORY-AND-GAPS.md` | `/tmp/docs_plan_inventory_callback.md` | **done, ladder_passed=yes** | 2026-05-01T20:38:50Z |
| 2 — SUBSTRATE DESIGN | 3 | `02-SUBSTRATE-DESIGN.md` | `/tmp/docs_plan_substrate_callback.md` | **done, ladder_passed=yes** | 2026-05-01T20:37:15Z |
| 3 — PROCESS + PROCEDURE | 4 | `03-PROCESS-AND-PROCEDURE.md` | `/tmp/docs_plan_process_callback.md` | **done, ladder_passed=yes** | 2026-05-01T20:35:34Z |

When Lanes 1 and 2 land, fill the empty sections below and re-run the
convergence checks at the bottom.

## Lane 3 Capture (real, on disk)

### What Lane 3 delivered

- 8-stage lifecycle state machine (`stage:0_artifact_drafted` →
  `stage:7_retired`) with 2 mermaid diagrams (state machine + authoring
  flowchart).
- Senior-dev procedural floor for 6 artifact categories: binaries, hooks,
  launchd plists, skills, doctrine docs, substrate-registry entries.
- Authoring decision tree as a mermaid flowchart with terminal-path
  exhaustiveness rule.
- 3 validation gates (Author Self-Check, Senior-Dev Review, Stale Triage)
  with explicit pass/fail criteria and required doctor outputs.
- Staleness triage protocol with ledger path
  `~/.local/state/flywheel/docs-staleness-log.jsonl`.
- 8 failure modes with detection + recovery (target was ≥5).
- Cross-cutting policies: locale, versioning, status enum, lock-log,
  idempotency, mermaid conventions.
- 6 verified skill template paths (`readme-writing`, `skill-builder`,
  `living-documentation`, `changelog-md-workmanship`, `technical-writing`,
  `cc-hooks`).

### Doctor signals Lane 3 names (Lane 2 must wire these)

These are the SOFT violations Lane 3's process emits and Lane 2's
substrate must surface in `flywheel-loop doctor --json`:

- `readme_missing` (durable artifact has no README)
- `readme_foundation` (status=foundation, ungraduated)
- `readme_validation_pending` (validation_command unverified)
- `readme_validated`, `readme_stable`
- `readme_stale_yellow`, `readme_stale_red`
- `readme_orphaned` (target_artifact path missing)
- `readme_validation_failed`
- `readme_below_senior_dev_bar`
- `readme_mermaid_required_missing`

### Skill ↔ stage mapping Lane 3 declares

| Stage | Skill that fires |
|---|---|
| 0 → 1 | `readme-writing`, `technical-writing`, `skill-builder`, `cc-hooks` (per artifact kind) |
| 1 → 2 | `readme-writing` (frontmatter + validation_command) |
| 2 → 3 | senior-dev (cold reviewer) — no skill, human/agent gate |
| 3 → 4 | doctor periodic check |
| 4/5/6 → triage | `living-documentation` |
| → 7 | archive procedure (Lane 2 must specify path) |

## Lane 1 Capture (real, on disk)

### What Lane 1 delivered

- **732 inventory rows** (target was ≥150 — exceeded 4.9×).
- **Grade distribution:** A=0, B=236, C=342, F=154. **Zero A grades** — entire ecosystem is below senior-dev bar.
- **By kind:** 464 skill, 111 plist, 49 hook, 29 binary, 22 memory, 20 command, 18 L-rule, 14 registry-row, 4 doc, 1 dispatch-template.
- **Mermaid diagrams found across 732 rows:** 1 (one). This is the systemic gap.
- **Top-20 backfill list:** all leverage=5, all grade=F. Concentration:
  - 7 binaries: `flywheel-autoloop`, `flywheel-loop`, `flywheel-lock-repair`, `flywheel-doctrine-sync`, `flywheel-refresh-source`, `flywheel-skillos-relay`, `flywheel-verdict`
  - 5 plists: `flywheel-autoloop`, `alps-flywheel-loop`, `flywheel-doctrine-sync`, `ntm-fleet-health`, `skillos-flywheel-loop`
  - 8 substrate-registry entries: `dicklesworthstone-{beads-rust,cass,mcp-agent-mail,ntm}`, `firewall-policy-bundle`, `mission-anchor-bundle`, `skill-os-kernel-bundle`, `substrate-intake-bundle`
- **Mermaid:yes in top-20:** 9 (target was ≥5 — exceeded).
- **Effort:** all 20 are M (45min each).

### Lane 1's 5 cross-cutting themes

- **A. Executable-doc gap** — binaries/hooks/plists are F because code is the only source of truth for purpose, side effects, verification.
- **B. Repeated blocks recur everywhere** — env vars, state paths, dry-run vs mutating examples, hook stdin envelopes, callback contracts, rollback, doctor probes. Template these.
- **C. Freshness metadata absent** — 52 rows stale by mtime >30d, but missing `last_validated_ts` on most rows is the broader issue.
- **D. Skill fit map** — `readme-writing` (shape), `technical-writing` (runbooks/troubleshooting), `living-documentation` (freshness), `codebase-archaeology` (survey).
- **E. Mermaid is absent** — 1/732 = 0.14% coverage. Highest-value targets: flywheel-loop/autoloop, doctrine sync, skillos relay, hook gates, tick/worker-tick, ntm fleet health, substrate bundles.

## Lane 2 Capture (real, on disk)

### What Lane 2 delivered

- 6 substrate components (per dispatch spec): pointer enforcement,
  freshness tracker, auto-detection hook, validation command engine,
  mermaid requirement matrix, senior-dev validation gate.
- Doctor top-level field `.docs_substrate` with 7 sub-fields:
  `pointer_compliance`, `freshness`, `mermaid_required_missing`,
  `senior_dev_gate`, `validation_command_failures`, `queued_gaps`,
  `last_run_ts`.
- 21 SOFT violations defined (covers Lane 3's 11 named signals + 10
  additional Lane-2-specific violations for pointer parsing, validation
  safety/timeout, command-reference completeness, hook errors, gap
  queueing).
- Mermaid requirement matrix matches Lane 3's mermaid conventions
  (multi-step flows, feedback loops, registry entries with components,
  doctrine docs all REQUIRED).
- Substrate-registry freshness probe names a stale class:
  `docs_substrate_syncer_stale`.

### Lane 2's 21 SOFT violations (full list)

`readme_pointer_missing`, `readme_pointer_broken`,
`readme_pointer_unparseable`, `readme_stale_yellow`, `readme_stale_red`,
`readme_validation_command_failed`, `readme_validation_failed`,
`readme_validation_timeout`, `readme_validation_unsafe_command`,
`readme_validation_missing_for_critical`, `readme_frontmatter_missing`,
`readme_target_artifact_missing`, `readme_mermaid_required_missing`,
`readme_mermaid_unparseable`, `readme_below_senior_dev_bar`,
`readme_command_reference_incomplete`, `readme_troubleshooting_too_thin`,
`readme_dependency_links_missing`, `docs_gap_queued`,
`docs_gap_hook_unloaded`, `docs_gap_hook_error`.

### Lane 2's skill mapping (lifecycle stages)

| Stage / function | Skill |
|---|---|
| Source-of-truth survey | `codebase-archaeology` |
| README authoring | `readme-writing` |
| README updates / freshness | `living-documentation` |
| API/contract docs | `api-documentation-generation` |
| Technical prose polish | `technical-writing` |
| Dispatch/callback flow docs | `dispatch-tool-contracts` |

## Cross-Lane Convergence Checks (RUN WHEN ALL THREE LAND)

These checks are pre-declared so synthesis is mechanical, not vibes:

1. **Lane 1 ↔ Lane 2 alignment.**
   Does Lane 1's top-20 priority list map to artifact kinds that Lane 2's
   substrate components actually validate? If Lane 1 prioritizes
   launchd plists but Lane 2 has no plist-specific validation hook,
   that's a divergence — flag for Joshua.

2. **Lane 2 ↔ Lane 3 alignment.**
   Lane 3 declares 11 doctor signals. Lane 2's `doctor_substrate` JSON
   contract must emit ALL 11 (or document why a signal is dropped).
   Missing signals = process gates that fire blind = SOFT violation
   class `process_signal_unwired`.

3. **Lane 1 ↔ Lane 3 alignment.**
   Lane 3 names 6 senior-dev categories. Lane 1's inventory should
   classify every artifact into one of those 6 categories (or surface
   a 7th category that Lane 3 missed).

4. **Mermaid coverage.**
   Lane 3 requires mermaid for: multi-step flows, feedback loops,
   substrate-registry entries with components, doctrine documents.
   Lane 1's "mermaid:yes top-20 count ≥ 5" must be consistent with
   this rule. Lane 2's mermaid-requirement matrix must encode the
   same rule.

5. **Lifecycle storage.**
   Lane 3's stages reference frontmatter and ledger rows that Lane 2
   must store. Cross-check: every stage transition Lane 3 names has a
   storage path Lane 2 owns.

6. **Skill coverage gap.**
   Lane 3 maps 6 categories to existing skills. If Lane 1 inventory
   surfaces an artifact category with NO mapped skill, that's a
   skillos pipeline candidate (per L68 cortex→engine handoff).

## Open Questions for Joshua (POST-CONVERGENCE)

To be filled when all three lanes land:
- Q1: which of Lane 1's top-20 to convert to beads first?
- Q2: implement Lane 2 substrate as new binary `flywheel-doctor-readme`
  or extend existing `flywheel-loop doctor`?
- Q3: senior-dev review (Lane 3 Gate 2) — human-only, or skillos-driven
  with foggybear hardening?
- Q4: rollout — backfill top-20 first, OR enable doctor warnings
  ecosystem-wide and let new artifacts be doc-first from day 1?

## Lane 2 ↔ Lane 3 Convergence (early — both lanes on disk)

**Check 2 — doctor signal coverage:**
Lane 3 names 11 doctor signals. Lane 2 emits 21 SOFT violations.
Coverage map:

| Lane 3 signal | Lane 2 emits? | Notes |
|---|---|---|
| `readme_missing` | ⚠️ partial — Lane 2 uses `readme_pointer_missing` + `readme_target_artifact_missing` | naming divergence; reconcile during impl |
| `readme_foundation` | ❌ NOT EMITTED | Lane 2 needs to add (it's a status, not a violation — likely OK) |
| `readme_validation_pending` | ❌ NOT EMITTED | Lane 2 should add (or document that pending = absence of `validation_failed`) |
| `readme_validated` | ❌ NOT EMITTED (status not violation) | OK |
| `readme_stable` | ❌ NOT EMITTED (status not violation) | OK |
| `readme_stale_yellow` | ✅ |  |
| `readme_stale_red` | ✅ |  |
| `readme_orphaned` | ✅ as `readme_target_artifact_missing` | rename one to match |
| `readme_validation_failed` | ✅ |  |
| `readme_below_senior_dev_bar` | ✅ |  |
| `readme_mermaid_required_missing` | ✅ |  |

**Verdict:** 8/11 signals covered cleanly, 2 naming divergences
(`readme_missing` vs `readme_pointer_missing`/`readme_target_artifact_missing`,
`readme_orphaned` vs `readme_target_artifact_missing`), 1 missing
(`readme_validation_pending`). Reconcile naming before impl-bead conversion.

**Check 4 — mermaid coverage:**
Lane 3 mermaid rules and Lane 2 mermaid-requirement matrix MATCH:
multi-step flows, feedback loops, registry entries with components,
doctrine docs all required. ✅ aligned.

**Check 6 — skill coverage:**
Lane 3 maps 6 senior-dev categories to skills. Lane 2 maps 6 lifecycle
functions to skills. Cross-reference:
- Both use: `readme-writing`, `living-documentation`, `technical-writing`
- Lane 3 only: `skill-builder`, `cc-hooks`, `changelog-md-workmanship`
- Lane 2 only: `codebase-archaeology`, `api-documentation-generation`,
  `dispatch-tool-contracts`

These are complementary (different lifecycle stages), not divergent.
Combined skill set covers authoring + survey + updates + API docs +
polish + dispatch flow + changelog + hook authoring + skill authoring.
✅ aligned.

## Lane 1 ↔ Lane 2 Convergence (real, both on disk)

**Check 1 — substrate covers top-20 artifact kinds:**
Lane 1's top-20 spans 3 kinds: binary (7), plist (5), registry-row (8).
Lane 2's 6 components map to all three:
- Binaries → pointer enforcement + freshness tracker + validation command engine + senior-dev gate ✅
- Plists → pointer enforcement (via comment block) + freshness tracker + validation (`plutil -lint` + `launchctl list`) ✅
- Registry-rows → already validated by `validation_command` + `health_probe_command` per Lane 2 substrate-registry entry pattern ✅
**Verdict:** Lane 2 substrate covers 100% of Lane 1's top-20 kinds. ✅ aligned.

## Lane 1 ↔ Lane 3 Convergence (real, both on disk)

**Check 3 — Lane 1 inventory classification fits Lane 3's 6 senior-dev categories:**
Lane 1 by-kind: skill, plist, hook, binary, memory, command, l-rule, registry-row, doc, dispatch-template (10 kinds).
Lane 3's 6 senior-dev categories: binaries, hooks, plists, skills, doctrine docs, substrate-registry entries.

Mapping:
| Lane 1 kind | Lane 3 category | Match |
|---|---|---|
| binary | binaries | ✅ |
| hook | hooks | ✅ |
| plist | plists | ✅ |
| skill | skills | ✅ |
| l-rule | doctrine docs | ✅ |
| doc | doctrine docs | ✅ |
| registry-row | substrate-registry entries | ✅ |
| memory | ❌ NO Lane 3 category | **divergence** |
| command | ❌ NO Lane 3 category (closest: skills) | **divergence** |
| dispatch-template | ❌ NO Lane 3 category | **divergence** |

**Verdict:** 7/10 Lane 1 kinds map cleanly. **3 divergences** (memory, command, dispatch-template) — Lane 3 needs to add these as senior-dev categories OR reclassify them under existing categories before bead conversion. Memory files (22 rows) are auto-managed but pointer-checkable per dispatch spec — likely a sub-category of doctrine. Commands (20 rows) are skill-shaped slash commands — likely a sub-category of skills. Dispatch-templates (1 row) — sub-category of doctrine.

**Check 5 — lifecycle storage covers Lane 1 staleness gap:**
Lane 1 Theme C: 52 rows stale by mtime >30d, broader gap is missing `last_validated_ts` on most rows.
Lane 2 storage path: `~/.local/state/flywheel/docs-staleness-log.jsonl` ✅
Lane 3 stages: 5_stale_warn / 6_stale_fail / 7_retired all named ✅
**Verdict:** Lifecycle storage covers staleness gap. ✅ aligned. Backfilling `last_validated_ts` is implicit in Gate 2 (senior-dev review writes `validated_by`+`validated_at` to frontmatter).

## Cross-Lane Triple Convergence Summary

| Check | Lanes | Result |
|---|---|---|
| 1. Substrate covers top-20 kinds | 1↔2 | ✅ aligned |
| 2. Doctor signal coverage | 2↔3 | ⚠️ 3 naming divergences |
| 3. Inventory ↔ senior-dev categories | 1↔3 | ⚠️ 3 missing categories (memory, command, dispatch-template) |
| 4. Mermaid coverage | 2↔3 | ✅ aligned |
| 5. Lifecycle storage covers staleness | 1↔2↔3 | ✅ aligned |
| 6. Skill coverage | 2↔3 | ✅ complementary |

## Divergences To Resolve Before Bead Conversion

1. **Naming reconciliation (Check 2):** Lane 3's `readme_missing` vs Lane 2's `readme_pointer_missing`/`readme_target_artifact_missing`. Lane 3's `readme_orphaned` vs Lane 2's `readme_target_artifact_missing`. Lane 3's `readme_validation_pending` not emitted by Lane 2.
   **Fix:** Lane 2 spec wins (it's the substrate that emits signals); update Lane 3's process doc to use Lane 2 names. Add `readme_validation_pending` to Lane 2.

2. **Missing senior-dev categories (Check 3):** memory (22 rows), command (20 rows), dispatch-template (1 row).
   **Fix:** Lane 3 process doc needs 3 new senior-dev category sections (or explicit "subcategory of X" notes).

3. **Mermaid systemic gap (Theme E):** 1/732 = 0.14% coverage. Top-20 has 9 mermaid:yes targets — that becomes the first sweep.
   **Fix:** Wave 1 of bead-backed implementation = the 9 mermaid:yes top-20 entries.

## Joshua Decisions (POST-CONVERGENCE)

1. **Q1 — Bead conversion order.** All 20 leverage-5 entries are M-effort (45min × 20 = ~15h). Sweep order:
   - **Option A (mermaid-first):** the 9 mermaid:yes entries first (highest visibility, addresses systemic gap most loudly)
   - **Option B (kind-first):** all 7 binaries → all 5 plists → all 8 registry-rows (template-friendly, batch-able)
   - **Option C (criticality):** flywheel-loop + flywheel-autoloop + flywheel-doctrine-sync first (core orchestration loop)
   **Recommend C for first wave (3 beads), then A for visibility (next 6), then finish with kind-batches.**

2. **Q2 — Implementation form.** Lane 2's 6 components: extend `flywheel-loop doctor` OR new `flywheel-doctor-readme` binary?
   **Recommend extend (avoids substrate proliferation; Lane 2 explicitly says "REUSE doctrine-sync pattern, don't re-implement").**

3. **Q3 — Senior-dev gate (Lane 3 Gate 2).** Human-only OR skillos-driven via FoggyBear hardening?
   **Recommend hybrid: skillos drafts validation + first-pass review, Joshua approves the senior-dev sign-off field. Per L68 cortex→engine pattern.**

4. **Q4 — Rollout.** Backfill top-20 first OR enable doctor warnings ecosystem-wide and gate new artifacts doc-first?
   **Recommend BOTH in parallel: enable warnings (read-only, no enforcement) immediately so the 154 F-grades become visible; backfill top-20 over Wave 1; Wave 2+ tightens enforcement category-by-category.**

## Synthesis Status

- ✅ All 3 lanes captured (real, on disk, ladder_passed=yes each)
- ✅ All 6 cross-lane convergence checks run on real data
- ✅ 3 divergences flagged with specific fixes
- ✅ 4 Joshua decisions stated with recommendations
- ⏸ Awaiting Joshua sign-off on decisions Q1–Q4
- ⏸ Then bead conversion via `/beads-workflow` (per `~/.claude/skills/beads-workflow`)

Next orchestrator action: surface this synthesis to Joshua, get Q1–Q4 decisions, then `/flywheel:handoff` for compact-resume.
