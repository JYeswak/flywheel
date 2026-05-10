# Bead 1: flywheel-cli-inventory (UPDATED 2026-05-10 with socraticode findings)

Joshua signoff 2026-05-10: integrate /world-class-doctor-mode-for-cli-tools
into the flywheel ecosystem. Step 1 of 3-bead chain.

## Pre-existing substrate to leverage (do NOT rebuild)

Socraticode survey found the substrate is more mature than initial spec assumed:

1. **Existing CLI registry**: `.flywheel/cli-registry.json` (schema
   `flywheel-cli-registry/v1`, currently 9 surfaces). Magic comment marker:
   `# flywheel-cli-surface: true`. Emit script:
   `.flywheel/scripts/cli-registry-emit.sh`. Test:
   `tests/test_cli_registry_emit.sh`. **EXTEND this; don't replace.**

2. **Canonical-cli-scoping skill scripts** at
   `~/.claude/skills/canonical-cli-scoping/scripts/`:
   - `check-cli-scoping.sh` — the per-binary validator (4-pass shape)
   - `canonical-cli-scorecard.sh` — produces the maturity scorecard
   - `ci-gate-cli-scoping.sh` — pre-commit/CI gate
   - `validate-canonical-cli-scoping.sh` — schema validation

3. **World-class-doctor-mode skill scripts** at
   `~/.claude/skills/world-class-doctor-mode-for-cli-tools/scripts/`:
   - `discover-cli.sh --probe-doctor` — Phase 0 inventory primitive
   - `cass-mine.sh` — Phase 1 archaeology
   - `mine-changelog.py` — Phase 1 archaeology
   - `query-corpus.py --language` — FM seeding
   - `scaffold-doctor.sh` — Phase 4 scaffold
   - `scorecard.py` — Phase 6 rubric scoring
   - `verify-{undo,idempotence,crash-recovery,concurrency,metamorphic,cross-fm}.sh`
     — Phase 5 safety-harness
   - `coverage-gap.py`, `diff-scorecards.py`, `single-fm-rescore.sh`

4. **Flywheel doctor lib** at `~/.claude/skills/.flywheel/lib/doctor.d/`:
   - `part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`
   - `part-02-check_beads_db_health-to-detect_tests_json.sh`
   - `part-03-security-posture.sh`

5. **Proven exemplars** (already implement world-class-doctor-mode patterns
   informally — these are the canonical templates to propagate):
   - `.flywheel/scripts/apply-tmux-tuning.sh` — full lifecycle (dry-run,
     apply, revert, doctor, validate ledger, idempotent re-apply,
     version-incompat-refuse, byte-exact revert via backup)
   - `.flywheel/scripts/apply-substrate-tuning.sh` — same pattern
   - `.flywheel/scripts/beads-db-recover.sh` — doctor + apply + backup_path
     + smoke tests + ledger row
   - `templates/flywheel-install/scripts/reconcile-polish-gate.sh` —
     atomic_write + diff + apply + rollback
   - `.flywheel/scripts/jeff-corpus-compact.sh` — idempotency-key +
     receipt path matching doctor read path
   - `.flywheel/scripts/validation-fix-bead.sh` — doctor + dry-run + apply
     with idempotency-key

6. **Surface scale (socraticode-counted)**:
   - `.flywheel/scripts/*.sh`: 336 total
   - With `--apply` or `--dry-run` patterns: 169 (likely state-mutating)
   - With existing `doctor` subcommand: ~50 (sample-counted)
   - Skill bins under `~/.claude/skills/.flywheel/bin/`: ~30
   - Currently in CLI registry: 9 (4.5% coverage)
   - Currently with canonical-cli-scoping tests: ~11 (5.5% coverage)

## Goal

Produce comprehensive inventory.jsonl extending the existing
`.flywheel/cli-registry.json` schema, classifying every CLI surface (own +
jeff-stack-orchestrated) by ownership, introspection maturity, and
doctor-mode rubric tier. Output gates beads 2 and 3.

## Scope

### AG1: extend cli-registry-emit to enumerate full fleet

Use `.flywheel/scripts/cli-registry-emit.sh` as the foundation. Extend its
discovery to:

- All `.flywheel/scripts/*.sh` (336 candidates)
- All `~/.claude/skills/.flywheel/bin/*` excluding `.bak.*` and
  `.README.md` (30 candidates)
- All `~/.claude/commands/flywheel/_shared/*.sh` (canonical wrappers)
- `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick` (repo-local driver)

For each candidate, run `discover-cli.sh --probe-doctor` and capture:

```
{
  "name": "<basename>",
  "path": "<repo-relative or absolute>",
  "ownership": "own | jeff-stack-orchestrated",
  "lane": "storage | beads | agent-mail | dispatch | recovery | ...",
  "canonical_cli_scoping_status": "missing | partial | passing | upstream_owned",
  "doctor_subcommand_status": "absent | basic | upgraded",
  "mutates_state": "yes | no | unknown",
  "has_apply_dry_run_pattern": true|false,
  "has_backup_pattern": true|false,
  "has_revert_or_undo": true|false,
  "has_idempotency_key": true|false,
  "has_ledger_receipt": true|false,
  "world_class_doctor_score_estimate": 0-1000 | null,
  "exemplar_match": "apply-tmux-tuning | beads-db-recover | reconcile-polish-gate | none",
  "priority": "P0 | P1 | P2 | P3"
}
```

Estimate `world_class_doctor_score_estimate` from the boolean signals (each
boolean = ~125pts; null if no doctor subcommand).

### AG2: classify by exemplar pattern match

For each own-binary with a doctor subcommand, run a 4-criteria check against
the `apply-tmux-tuning.sh` exemplar:
- `--dry-run` does not mutate (sha-stable)
- `--apply` produces backup_path in receipt
- `--revert` (or doctor undo) restores byte-exact
- `--apply --apply` is idempotent (no double-action)

Set `exemplar_match` based on which proven pattern the script most closely
follows. Surfaces with no exemplar match are P0 doctor-mode-upgrade
candidates (bead 3).

### AG3: jeff-stack delineation

Hardcode the upstream-owned list:
- `ntm`, `br`/`bv`/`bvp`/`bvg`, `am`, `dcg`, `caam`, `cass`/`cm`, `jsm`

These get `canonical_cli_scoping_status=upstream_owned`. Do not probe their
internals; just record ownership and the upstream issue path
(per `feedback_jeff_issue_chain`).

### AG4: priority rubric

- P0: own + mutates_state=yes + (canonical_cli_scoping_status IN [missing,
  partial] OR doctor_subcommand_status=absent)
- P1: own + mutates_state=yes + canonical passing + doctor basic
  (world-class-doctor-mode upgrade target)
- P2: own + mutates_state=no (read-only probes; baseline-only sufficient)
- P3: jeff-stack-orchestrated (file upstream issues, not patches)

### AG5: cross-reference existing tests

Walk `.flywheel/tests/*canonical-cli*` and `tests/*canonical-cli*`,
record which surfaces already have canonical-cli regression coverage.
This is the existing baseline; bead 2 builds on it.

### AG6: output

Write `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (one row per
binary, schema as AG1 above).

Write `.flywheel/audit/flywheel-cli-inventory/evidence.md`:
- Total surfaces enumerated (own / jeff-stack split)
- Counts by maturity tier
- P0 list (~30-50 expected, the bead-2 input set)
- P1 list (~20-40 expected, the bead-3 input set)
- P2 list (read-only probes; document but don't upgrade)
- Probe failures (binaries that errored on --help; needs investigation)
- Existing canonical-cli test coverage map (which P0/P1 already have tests)
- Exemplar-pattern distribution (apply-tmux-tuning vs beads-db-recover vs
  none)

Optionally append registry rows to `.flywheel/cli-registry.json` for any
own-binary with `# flywheel-cli-surface: true` that's currently missing.

## Boundary

- READ-ONLY pass except for inventory.jsonl, evidence.md, and optional
  registry append (registry append is small + reversible via git).
- DO NOT probe jeff-stack binaries with --info/--schema; their introspection
  surfaces are upstream's call.
- DO NOT modify scripts. Pure inventory.
- 60-min budget (revised up from 30min given socraticode-discovered scale).
- If a binary's --help hangs >5s, mark `probe_timeout` and move on.

## Success criteria

- inventory.jsonl exists with one row per binary, schema-valid, ~200+ rows
- evidence.md documents tier distribution + exemplar-pattern map
- bead 2's input set (P0) is unambiguous from inventory
- bead 3's input set (P1) is unambiguous from inventory
- existing `.flywheel/cli-registry.json` extended (or audit shows where
  registry should grow); zero registry rows lost
- zero new CLI work this bead — pure observation + lightweight registry sync
