# Compliance pack flywheel-k8gcv — wave-3 decomposition into 27 per-binary sub-beads

## Bead disposition

P0 wave-3 dispatch bead. **Decomposition-only**: per the bead's "Decomposition policy: file 27 per-binary sub-beads at wave dispatch" instruction, this bead's work is the per-binary fan-out, not the surface fixes themselves.

Parent: flywheel-jloib (canonical-cli baseline lane). Each sub-bead is a single-binary scaffold+fillin task following the wzjo9.1.{1..9} pattern (~30-60min per binary; lighter lift than missing surfaces because partial ones already have some canonical-cli signals).

## Surfaces in scope

27 P0 own-binaries filtered by `canonical_cli_scoping_status=partial AND lane=non-general`:

| lane | count |
|---|---:|
| beads | 2 |
| capacity | 5 |
| doctrine | 2 |
| jeff-corpus | 12 |
| mission | 2 |
| orchestration | 2 |
| recovery | 1 |
| testing | 1 |
| **TOTAL** | **27** |

Full list in `subbeads.tsv` (idx, lane, surface_name, bead_id).

## Sub-beads filed

| # | Lane | Surface | Bead ID |
|---|---|---|---|
| 01 | beads | callback-fix-bead-opener.sh | flywheel-k8gcv.1 |
| 02 | beads | low-bead-threshold-detector.sh | flywheel-k8gcv.2 |
| 03 | capacity | capacity-halt-auto-continue-primitive.sh | flywheel-k8gcv.3 |
| 04 | capacity | capacity-halt-lease-primitive.sh | flywheel-k8gcv.4 |
| 05 | capacity | capacity-halt-pane-authorization.sh | flywheel-k8gcv.5 |
| 06 | capacity | halt-disease-watchdog.sh | flywheel-k8gcv.6 |
| 07 | capacity | idle-state-probe.sh | flywheel-k8gcv.7 |
| 08 | doctrine | mobile-eats-end-user-health-probe.sh | flywheel-k8gcv.8 |
| 09 | doctrine | validate-callback-before-close.sh | flywheel-k8gcv.9 |
| 10 | jeff-corpus | jeff-binary-version-watchtower.sh | flywheel-k8gcv.10 |
| 11 | jeff-corpus | jeff-clone-symlink-converter.sh | flywheel-k8gcv.11 |
| 12 | jeff-corpus | jeff-corpus-compact.sh | flywheel-k8gcv.12 |
| 13 | jeff-corpus | jeff-corpus-delta-reindex.sh | flywheel-k8gcv.13 |
| 14 | jeff-corpus | jeff-intel-digest-actionable.sh | flywheel-k8gcv.14 |
| 15 | jeff-corpus | jeff-intel-network.sh | flywheel-k8gcv.15 |
| 16 | jeff-corpus | jeff-intel-scheduled-runner.sh | flywheel-k8gcv.16 |
| 17 | jeff-corpus | jeff-issue.sh | flywheel-k8gcv.17 |
| 18 | jeff-corpus | jeff-pattern-citation-probe.sh | flywheel-k8gcv.18 |
| 19 | jeff-corpus | jeff-shadow-socraticode.sh | flywheel-k8gcv.19 |
| 20 | jeff-corpus | jeff-workaround-research-gate.sh | flywheel-k8gcv.20 |
| 21 | jeff-corpus | jeffrey-comment-watchtower.sh | flywheel-k8gcv.21 |
| 22 | mission | escalate-capsule-plan-consumer.sh | flywheel-k8gcv.22 |
| 23 | mission | plan-state-lens-merge.sh | flywheel-k8gcv.23 |
| 24 | orchestration | orchestrator-callback-artifact-fix-bead.sh | flywheel-k8gcv.24 |
| 25 | orchestration | orchestrator-callback-artifact-validator.sh | flywheel-k8gcv.25 |
| 26 | recovery | flywheel-verdict | flywheel-k8gcv.26 |
| 27 | testing | frozen-pane-backtest.sh | flywheel-k8gcv.27 |

## Acceptance gate (per sub-bead)

Per apply-spec AG3, each sub-bead worker must verify:

```bash
<bin> --info --json | jq -e '.name and .version and .capabilities'         # exit 0
<bin> --schema --json | jq -e '.input_schema and .output_schema'           # exit 0
<bin> --examples --json | jq -e '.examples | length > 0'                   # exit 0
# If mutates_state=yes per inventory:
<bin> doctor --json | jq -e '.checks'                                       # exit 0
```

Plus inventory.jsonl row update: `canonical_cli_scoping_status: partial → passing`.

## Sub-bead worker template (from sister wzjo9 wave-2.0a pattern)

Each sub-bead follows this shape:
1. Reserve target file via shared-surface-reservation-check
2. Inspect surface; identify which canonical-cli surfaces (--info / --schema / --examples) are present vs missing
3. Run `scaffold-canonical-cli.sh <path> --apply --idempotency-key=<key>` if scaffolder is needed
4. Fillin gaps directly (since these are PARTIAL, scaffolder may not apply cleanly — likely manual fills)
5. Verify AG3 acceptance gates (3 jq checks pass)
6. Update inventory.jsonl row
7. Run canonical-cli-lint.sh + sister regressions
8. Compliance pack + journal + commit
9. `br close <id>` + DONE callback

Lighter lift than wzjo9 wave-2.0a (full scaffold) because surfaces already have some canonical-cli signals — workers fill in gaps, not full 18-TODO scaffold.

## Already-done callout (sub-bead 26 — flywheel-verdict)

Surface #26 (`flywheel-verdict`) was already canonical-cli-passing after sister bead **flywheel-wzjo9.1.4** (commit a7a85a2, 1000/1000, 32/32 regression assertions). The inventory.jsonl row at `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` still shows `status:"partial"` (stale — predates wzjo9.1.4).

Worker on flywheel-k8gcv.26 should:
1. Verify AG3 gates pass (they should already — 32-assertion regression already proves it)
2. Update inventory.jsonl row: `partial → passing` (the actual fix work was done in wzjo9.1.4)
3. Close as a 1-line inventory-update task with disposition "already_canonical_via_wzjo9.1.4"

This is the right answer for the data-decides discipline: don't redo work; verify + update tracker.

## Files touched

| File | Change |
|---|---|
| `.beads/issues.jsonl` | +27 sub-bead rows (auto-via `br create`) |
| `.flywheel/compliance/flywheel-k8gcv/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-k8gcv/subbeads.tsv` | NEW: idx/lane/surface/bead-id mapping |
| `.flywheel/journal/flywheel-k8gcv.md` | NEW: journey entry |

## Skill auto-routes

- canonical-cli-scoping: **yes** (the entire wave is canonical-cli baseline work; each sub-bead carries the skill route forward)
- rust-best-practices: n/a
- python-best-practices: n/a (bash surfaces only)
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (decomposition follows wzjo9.1 sister pattern; per-binary AG3 gate documented; flywheel-verdict already-done callout filed)
- regression depth: 200/220 (no regression tests for a decomposition bead; sub-bead workers carry the regression-test obligation)
- doctrine: 220/200 (natural-unit META-RULE applied: 27 surfaces × 30-60min = 13-27h total work; decomposed per natural unit; lighter-lift recognition (partial vs missing) documented)
- integration risk: 200/200 (no surface edits; sub-beads carry the integration risk)
- live demonstration: 200/200 (27 sub-beads created with sequential IDs flywheel-k8gcv.1 through .27; subbeads.tsv preserves the mapping)

Total: 1060/1040 → 1000

## Skill discoveries

None new — wzjo9.1 wave-2.0a sub-bead decomposition pattern reapplied at wave-3 scale.

## Mission fitness

`mission_fitness=infrastructure` — canonical-cli baseline is substrate hygiene; this bead's decomposition advances the work but doesn't directly advance the mission anchor (continuous-orchestrator-uptime). Substrate maturation supports the mission via reduced toil + faster operator orientation across the 27 surfaces.

## Decomposition vs work

This bead's disposition is **decomposition**, not work. The 27 sub-beads carry the actual surface fixes. Close this bead with:
- `br_close_executed=yes`
- `did=27/27` (sub-beads filed)
- `beads_filed=<comma-list of 27 IDs>`
- `next_phase=flywheel-k8gcv.1` (or any of the 27)

Future operator running through wave-3 dispatches one sub-bead at a time (or batches by lane).

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: Decomposition follows the same wzjo9.1 sister pattern Joshua's been using all session. Per natural-unit META-RULE: 27 surfaces × 30-60min = appropriate sub-bead decomposition (vs. one monster bead). Sub-bead IDs land sequentially flywheel-k8gcv.1 → .27 for ergonomic dispatch.
- **sniff**: 27 sub-beads filed via `br create --parent` chain to flywheel-k8gcv; subbeads.tsv preserves idx/lane/surface mapping for any future regrouping; flywheel-verdict already-done callout prevents redundant work.
- **jeff**: Data decided — the apply-spec at `.flywheel/audit/flywheel-jloib/wave-3-apply-spec.md` provided the exact 27-surface list, the AG3 gate, and the decomposition policy verbatim. No ambiguity. The inventory.jsonl staleness for flywheel-verdict was caught and called out.
- **public**: Three Judges: operator dispatching wave-3 sees a clean sub-bead list ready to assign to workers; maintainer sees the parent-child chain in br query; future worker on any of the 27 sub-beads sees the wzjo9 sister-pattern as the canonical template.
