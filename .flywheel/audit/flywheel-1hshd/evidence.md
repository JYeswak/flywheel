# Compliance Evidence Pack — flywheel-1hshd

Bead: flywheel-1hshd (wave-4 decomposition; P0)
Parent bead: flywheel-jloib (closed)
Identity: MagentaPond

## Summary — WAVE-DECOMPOSITION META-TASK

This is NOT a single-binary scaffold task — it's the wave-level decomposition that produces 37 single-binary sub-beads (flywheel-1hshd.1 through flywheel-1hshd.37) for future worker dispatch. Per the natural-unit decompose META-RULE (memory: `feedback_decompose_by_natural_unit_not_bundle.md`, 2026-05-10): when work has a natural per-surface unit AND total >1-2h, file 1 bead per unit. 37 surfaces × ~30-60min = 18.5-37 hours of fillin work — clearly above the bundle threshold.

## What was done

Filed 37 per-binary sub-beads under flywheel-1hshd, one per surface from `.flywheel/audit/flywheel-jloib/wave-4-apply-spec.md` (P0 partial × general lane split A: a-l):

| # | Surface | Sub-bead ID |
|---|---|---|
| 1 | adversarial-orch-self-audit-probe.sh | flywheel-1hshd.1 |
| 2 | agents-md-fleet-propagator.sh | flywheel-1hshd.2 |
| 3 | apply-substrate-tuning.sh | flywheel-1hshd.3 |
| 4 | apply-tmux-tuning.sh | flywheel-1hshd.4 |
| 5 | auto-l112-gate.sh | flywheel-1hshd.5 |
| 6 | bcv-task-harness.sh | flywheel-1hshd.6 |
| 7 | callback-envelope-schema-validator.sh | flywheel-1hshd.7 |
| 8 | callback-receipt-validator-wrapper.sh | flywheel-1hshd.8 |
| 9 | callback-receipt-validator.sh | flywheel-1hshd.9 |
| 10 | callback-spool-reap.sh | flywheel-1hshd.10 |
| 11 | canonical-root-drift-fleet-check.sh | flywheel-1hshd.11 |
| 12 | check-trauma-class-substrate.sh | flywheel-1hshd.12 |
| 13 | cleanup-scratch.sh | flywheel-1hshd.13 |
| 14 | codex-budget-probe.sh | flywheel-1hshd.14 |
| 15 | codex-death-event-classifier.sh | flywheel-1hshd.15 |
| 16 | codex-queued-not-submitted-bare-enter-primitive.sh | flywheel-1hshd.16 |
| 17 | codex-template-stuck-detector.sh | flywheel-1hshd.17 |
| 18 | continuous-productivity-detector-install.sh | flywheel-1hshd.18 |
| 19 | continuous-productivity-detector.sh | flywheel-1hshd.19 |
| 20 | cost-telemetry-token-burn-probe.sh | flywheel-1hshd.20 |
| 21 | cross-repo-trauma-aggregator.sh | flywheel-1hshd.21 |
| 22 | cross-session-worker-borrow.sh | flywheel-1hshd.22 |
| 23 | cross-time-synthesis-probe.sh | flywheel-1hshd.23 |
| 24 | customer-facing-observability-probe.sh | flywheel-1hshd.24 |
| 25 | docs-validation-probe.sh | flywheel-1hshd.25 |
| 26 | file-length-probe.sh | flywheel-1hshd.26 |
| 27 | fleet-coherence-launchd.sh | flywheel-1hshd.27 |
| 28 | fleet-rotate-all-sessions.sh | flywheel-1hshd.28 |
| 29 | flywheel-adopt.sh | flywheel-1hshd.29 |
| 30 | flywheel-codex-stuck-detector-install.sh | flywheel-1hshd.30 |
| 31 | frozen-pane-detector-fleet.sh | flywheel-1hshd.31 |
| 32 | frozen-pane-detector.sh | flywheel-1hshd.32 |
| 33 | fuckup-coverage-join.sh | flywheel-1hshd.33 |
| 34 | gap-hunt-probe.sh | flywheel-1hshd.34 |
| 35 | headless-browser-reap.sh | flywheel-1hshd.35 |
| 36 | hub-blocker-detect.sh | flywheel-1hshd.36 |
| 37 | idempotency-replay-guard.sh | flywheel-1hshd.37 |

All 37 verified via `br show flywheel-1hshd.<N>` (count: missing=0/37).

## Sub-bead description template

Each sub-bead uses a consistent description format referencing:
- Parent wave bead (flywheel-1hshd)
- Surface name + path
- Apply-spec path (`.flywheel/audit/flywheel-jloib/wave-4-apply-spec.md`)
- Per-binary AG3 (--info / --schema / --examples + doctor with 5+ probes / health binds audit log / repair with 2+ scopes + rc=3 apply contract / validate with 3+ subjects / audit cli_emit_audit_tail / why 3 states)
- Sister wave-2 exemplars from THIS session: 5ke66.{3,5,7,9,10,12,14,16,17,18,20,21} avg 996.5 — all shipped by MagentaPond
- This-session canonical patterns documented: hybrid-envelope coexistence (5ke66.{9,12,14}), source-vs-exec guard (5ke66.10), surgical dash-flag scaffold (5ke66.17), self-referential L107 scaffolding (5ke66.18)
- Effort estimate: 30-60min per binary (partial baseline; lighter than wave-2 missing baseline)

## Decomposition policy compliance

Per `.flywheel/audit/flywheel-jloib/wave-4-apply-spec.md` section "Sub-bead decomposition policy":
> When this wave is dispatched, file 37 per-binary sub-beads (flywheel-jloib.4.1 through flywheel-jloib.4.37) following wzjo9.1.{1..9} pattern. Each sub-bead is a single-binary scaffold+fillin task with the AG3 acceptance gate.

The apply-spec mentions IDs like `flywheel-jloib.4.<N>` but `br create --parent flywheel-1hshd` produces `flywheel-1hshd.<N>` IDs because flywheel-1hshd IS the wave-4 bead (the spec's "flywheel-jloib.4" is conceptual nomenclature). Sub-bead IDs are correct.

## Wave-2 sister-pattern reference (for future worker dispatches)

Wave-2-general shipped 12 surfaces in this session (5ke66.{1,3,5,7,9,10,12,14,16,17,18,20,21}). Average compliance: 996.5/1000. Wave-4 sub-beads can follow the same dispatch + scaffold + close pattern. Reference patterns documented in evidence:

| Pattern | Bead | When to use |
|---|---|---|
| bash+python heredoc with no existing tests | 5ke66.3 | python heredoc + new scaffold over it |
| pure-bash with set-e upgrade | 5ke66.{5,16} | original `set -uo` → `set -euo` |
| interactive bash, DCG-safe | 5ke66.7 | `read -p` flows preserved |
| python+existing tests with hybrid envelopes | 5ke66.{9,12,14} | hand-rolled --info/--schema preserving backward-compat |
| sourced library, BASH_SOURCE guard | 5ke66.10 | `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` |
| surgical dash-flag scaffold | 5ke66.17 | python has positional canonical subcommands already |
| self-referential L107 tool | 5ke66.18 | scaffold the tool you depend on for scaffolding |
| python stub --info replaced | 5ke66.20 | no test asserts on stub shape |

## Compliance score

| Axis | Score |
|---|---:|
| Decomposition correctness | 200/200 — 37/37 sub-beads filed, parent-child dep correct |
| Title format compliance | 100/100 — `[wave-4-general-N] <name> canonical-CLI scaffold + 18-TODO fillin` |
| Description template consistency | 200/200 — apply-spec ref + AG3 + sister-pattern catalog uniform across all 37 |
| Apply-spec coverage | 200/200 — every surface from spec table present in sub-bead list |
| L52 bead-receipt discipline | 100/100 — `beads_filed=flywheel-1hshd.1..37` (37 IDs) in callback |
| Documentation | 50/50 — this evidence pack + pattern catalog for downstream workers |
| Style | 100/100 — canonical br invocations, no manual jsonl writes (META-RULE: bead JSONL writes via br only) |
| **TOTAL** | **950/1000** — decomposition complete; downstream scaffolds will accrete additional compliance per sub-bead |

## Four-Lens Self-Grade

- **brand:10** — sister-pattern conformance with wave-2 decomposition (5ke66 wave); sub-bead descriptions explicitly reference all wave-2 patterns shipped this session.
- **sniff:10** — no manual `.beads/issues.jsonl` writes (canonical br create only); parent-child deps verified.
- **jeff:10** — single-surface-per-sub-bead decomposition is the natural unit; lint-clean substrate; bead JSONL writes through canonical br only.
- **public:10** — Three Judges check: downstream worker picking up `flywheel-1hshd.5` will have the apply-spec path, the surface name + path, the AG3 contract, AND the pattern catalog showing which of 7 sister scaffold patterns applies.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **n/a-decomposition** — this bead doesn't ship a canonical-CLI scaffold; it files 37 sub-beads that WILL each ship one.
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a**
- `readme-writing`: **n/a**

## Files reserved/released (L107)

None — bead creation via `br create` doesn't require shared-surface reservations (the canonical br write path is the only writer to `.beads/issues.jsonl`).

## Backup

N/A — pure bead-creation work; no source file edits.
