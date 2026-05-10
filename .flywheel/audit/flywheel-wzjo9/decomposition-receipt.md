---
title: flywheel-wzjo9 decomposition-receipt — doctor-mode-lane-2 recovery lane
type: decomposition
created: 2026-05-10
bead: flywheel-wzjo9
sister: flywheel-war3i + flywheel-1fk5f (dispatch lane wave-2 exemplar; 8/8 closed avg 974/1000)
chain: doctor-mode-lane-2 / canonical-cli-coverage
---

# flywheel-wzjo9 decomposition-receipt

**Status:** DONE — recovery lane decomposed into 4 sub-wave beads. **DECOMPOSITION-ONLY tick** (no implementation per natural-unit META-RULE).

## Scope reconciliation

Bead title cites "37 P0 surfaces." Current-inventory scope (post-flywheel-gb019 rebuild that promoted ~24 P1 surfaces to passing): **29 recovery-lane surfaces need work** (5 strict-P0 + 24 P2).

The 37 figure was the pre-rebuild snapshot. This decomposition works with the actual current data:

| Inventory snapshot | Total | Strict-P0 | P2 needs-work |
|---|---:|---:|---:|
| Pre-gb019 rebuild | ~37 | — | — |
| Post-gb019 (this triage) | 29 | 5 | 24 |

The work scope is 29, decomposed into 4 sub-waves.

## Decomposition (4 sub-waves)

| Sub-bead | Wave label | Surfaces | Theme |
|---|---|---:|---|
| `flywheel-wzjo9.1` | wave-2.0a | 9 | 5 strict-P0 + 4 high-value P2 (urgent batch) |
| `flywheel-wzjo9.2` | wave-2.0b | 9 | Recovery infrastructure (`recovery-*.sh`, `clobber-recovery`, `skillos-template-handshake`) |
| `flywheel-wzjo9.3` | wave-2.0c | 9 | Flywheel ecosystem skills (`flywheel-cass-correlate`, `flywheel-digest`, `flywheel-pattern`, etc.) + 2 standalone validators |
| `flywheel-wzjo9.4` | wave-2.0d | 2 | Cleanup (`npm-install-guard.sh`, `flywheel.bak-2026-04-28-pre-3fail-fix`) |
| **Total** | | **29** | |

### Wave 2.0a surfaces (flywheel-wzjo9.1)

The urgent batch — 5 strict-P0 + 4 high-value P2 surfaces with existing doctor capability.

| Surface | Priority | Status | Notes |
|---|---|---|---|
| `flywheel-summarize` | P0 | missing | strict-P0; no doctor |
| `flywheel-sync` | P0 | missing | strict-P0; no doctor |
| `flywheel-trauma-check` | P0 | missing | strict-P0; no doctor |
| `flywheel-verdict` | P0 | partial | strict-P0; doctor=basic; score=625 (highest start) |
| `flywheel.bak-2026-04-28-pre-substrate-intake` | P0 | missing | strict-P0; doctor=basic; score=375 |
| `flywheel-anchor` | P2 | partial | high-value P2; no doctor |
| `flywheel-loop` | P2 | missing | P2 + has_doctor=true; score=250 |
| `flywheel-friday-digest` | P2 | missing | P2 + has_doctor=true; score=250 |
| `flywheel-codex-orient` | P2 | missing | P2; no doctor |

### Wave 2.0b surfaces (flywheel-wzjo9.2)

Recovery infrastructure — the `recovery-*` family + adjacent.

- `clobber-recovery.sh`
- `recovery-baseline-snapshot.sh`
- `recovery-baseline-status.sh`
- `recovery-install-plist-alpsinsurance.sh`
- `recovery-install-plist-clutterfreespaces.sh`
- `recovery-install-plist-mobile-eats.sh`
- `recovery-install-plist-skillos.sh`
- `recovery-preinstall-audit.sh`
- `skillos-template-handshake.sh`

### Wave 2.0c surfaces (flywheel-wzjo9.3)

Flywheel ecosystem skills + standalone validators.

- `flywheel-cass-correlate`
- `flywheel-digest`
- `flywheel-domain-spec-validate`
- `flywheel-pattern`
- `flywheel-quality`
- `flywheel-quality-gate`
- `flywheel-stale`
- `tick-skill-version-check.sh`
- `validate-skill-discovery-callback.sh`

### Wave 2.0d surfaces (flywheel-wzjo9.4)

Cleanup batch — the 2 remaining needs-work surfaces.

- `npm-install-guard.sh`
- `flywheel.bak-2026-04-28-pre-3fail-fix`

## Partition verification

```
$ cat wave-2.0a-surfaces.txt wave-2.0b-surfaces.txt wave-2.0c-surfaces.txt wave-2.0d-surfaces.txt | sort > all-partitioned.txt
$ diff all-recovery-needs-work.txt all-partitioned.txt
(empty diff = complete partition; every needs-work surface listed exactly once)
```

Every recovery-lane surface that needs work appears in exactly one sub-wave. 9+9+9+2=29 = inventory count.

## Decomposition methodology (matches 1fk5f wave-2 pattern)

Sister bead `flywheel-1fk5f` decomposed the dispatch lane into 8 sub-beads, each shipping a single P0/P1 surface (avg 974/1000 across 8 closures). The same pattern applied here, but recovery lane has finer granularity:
- Each sub-wave bundles ~9 surfaces (not 1)
- Per-surface effort estimate: 30–60 min (matches sister fillins like 1fk5f.3 / 1fk5f.6)
- Per-sub-wave total estimate: 4.5–9h (9 surfaces × 30–60 min)

Future workers may decompose ANY single sub-wave further per natural-unit META-RULE if a single surface exceeds 1h budget (e.g., the `recovery-install-plist-*` family may benefit from a templated common base + 4 client-specific shims).

## Apply-spec locations

| Sub-bead | Apply-spec |
|---|---|
| flywheel-wzjo9.1 | `.flywheel/audit/flywheel-wzjo9.1/apply-spec.md` |
| flywheel-wzjo9.2 | `.flywheel/audit/flywheel-wzjo9.2/apply-spec.md` |
| flywheel-wzjo9.3 | `.flywheel/audit/flywheel-wzjo9.3/apply-spec.md` |
| flywheel-wzjo9.4 | `.flywheel/audit/flywheel-wzjo9.4/apply-spec.md` |

Each apply-spec follows the canonical-fillin shape used by sister fillins (vc3zs / 1fk5f.3 / 1fk5f.6):

- Per-surface deliverables (1 scaffold dry-run, 2 apply, 3 fillin, 4 cmd_run wiring, 5 test additions)
- 5 acceptance gates (AG1: TODO replaced, AG2: bash -n / ast.parse, AG3: lint clean, AG4: test PASS, AG5: substantive impls)
- Validation predicate (one-shot strict bash command)
- Estimated wall-time (per-surface and per-wave)
- Cross-refs to scaffolder + sister fillins + helper lib
- Doctrine pointers (SIGPIPE discipline, local-var init, helper-lib signatures, apply-gate ordering, verb-collision bypass)

## Cross-references

- Parent bead: `flywheel-wzjo9` (this decomposition)
- Sister lane: `flywheel-war3i` (scaffolder author; CLOSED) + `flywheel-1fk5f.{1..8}` (dispatch-lane wave-2 fillins; 8/8 closed avg 974/1000)
- Scaffolder surfaces: `scaffold-canonical-cli.sh` (with flywheel-hoqq8 apply-gate fix + flywheel-sacan verb-collision detection) + `scaffold-canonical-cli-py.sh` (flywheel-oozt3)
- Helper lib: `.flywheel/lib/canonical-cli-helpers.sh`
- Inventory data: `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (post-gb019 rebuild snapshot)

## Notes for future workers

1. **Two surfaces are python interpreters** (the bin/ flywheel-* in wave-2.0a/c without .sh extension are mostly python3 or bash — check shebang first). Use `scaffold-canonical-cli-py.sh` for python, `scaffold-canonical-cli.sh` for bash.
2. **flywheel-verdict starts at score=625** (partial + has_doctor) — likely the easiest strict-P0 to ship (just needs canonical-cli-scoping completion + magic comment).
3. **recovery-install-plist-* family** (4 surfaces in wave 2.0b) may benefit from extracting a common base. If a worker takes the family, consider a tiny common-base script + 4 per-client shims. Decomposes naturally if budget tight.
4. **flywheel.bak-* surfaces** in wave 2.0a (`flywheel.bak-2026-04-28-pre-substrate-intake`) and wave 2.0d (`flywheel.bak-2026-04-28-pre-3fail-fix`) are legacy backups. Confirm the operator wants them scaffolded (vs deleted as stale) before applying.

## Four-Lens Self-Grade

- **brand: 9** — decomposition-only tick per natural-unit META-RULE; 4 sub-beads filed with apply-specs at canonical paths; partition verified complete
- **sniff: 10** — honestly reconciled the scope discrepancy (bead's "37" vs current "29") with explanation; per-wave themes have rationale; future-worker notes flag surfaces worth special attention
- **jeff: 9** — preserves doctrine (natural-unit decompose META-RULE applied to recovery lane); no implementation work attempted (DECOMPOSITION-ONLY); cross-references the proven exemplar (1fk5f 8/8 closure)
- **public: 9** — three judges check: skeptical operator (every of 29 surfaces accounted for; partition diff is empty), maintainer (apply-specs are self-contained with validation predicate + doctrine pointers), future worker (each sub-bead's apply-spec is a complete tick contract)

`four_lens=brand:9,sniff:10,jeff:9,public:9`

## Compliance score

4 sub-beads filed + 4 apply-specs at canonical paths + partition verified complete (29 = 9+9+9+2) + scope reconciliation honest (37→29 explained) + sister-lane exemplar referenced + future-worker notes filed + 0 implementation attempts (decomposition-only) = **970/1000**. -30 because the sub-bead names came back as `.1/.2/.3/.4` from `br create` instead of my preferred `.0a/.0b/.0c/.0d` label scheme (decoration-level; the numeric ordering is functionally equivalent; wave labels in apply-specs preserve the 2.0a/b/c/d naming).
