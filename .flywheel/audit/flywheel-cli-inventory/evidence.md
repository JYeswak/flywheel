# Bead 1 Evidence: flywheel-cli-inventory

Date: 2026-05-10
Bead: flywheel-c3w4h
Mode: read-only static-analysis pass (grep + path heuristics)

## Headline

**395 CLI surfaces enumerated across the flywheel ecosystem. 234 P0 (60%
require canonical-cli baseline + doctor-mode work). 0 currently at upgraded
world-class-doctor-mode tier. Existing canonical-cli regression coverage:
11 surfaces (~3% of own fleet).**

## Method

Static probe via `/tmp/build-cli-inventory.sh` (committed under audit dir on
ship). For each binary candidate, the script grep-detected boolean signals
(`--apply`, `--dry-run`, `doctor` subcommand, `--info`, `--schema`,
`--examples`, `--json`, idempotency-key handling, backup/revert patterns,
ledger-receipt patterns) and inferred:

- `canonical_cli_scoping_status` — missing | partial | passing
- `doctor_subcommand_status` — absent | basic | upgraded
- `mutates_state` — yes | no | unknown
- `world_class_doctor_score_estimate` — 0–1000 (125pts × 8 boolean signals)
- `exemplar_match` — apply-tmux-tuning | beads-db-recover |
  reconcile-polish-gate | none

Sources:
- `.flywheel/scripts/*.sh` (336 candidates, top-level)
- `.flywheel/scripts/**/*.{sh,py}` (subdirs)
- `~/.claude/skills/.flywheel/bin/*` (excluding `.bak.*`, `.README.md`)
- `~/.claude/commands/flywheel/**/*.sh`
- jeff-stack hardcoded list (11 binaries: ntm, br/bv/bvp/bvg, am, dcg,
  caam, cass/cm, jsm)

Static analysis is sufficient for prioritization. Bead 2 will run live
`--info`/`--schema`/`--examples` probes per binary to validate the maturity
classification before shipping baseline patches.

## Distribution

### By ownership

| Ownership | Count | % |
|---|---|---|
| own | 384 | 97% |
| jeff-stack-orchestrated | 11 | 3% |
| **TOTAL** | **395** | **100%** |

### By priority (own + jeff)

| Priority | Definition | Count | % |
|---|---|---|---|
| P0 | own + mutates_state=yes + (canonical missing/partial OR doctor absent) | 234 | 59% |
| P1 | own + mutates_state=yes + canonical passing + doctor basic (upgrade target) | 27 | 7% |
| P2 | own + mutates_state=no (read-only probes; baseline only) | 123 | 31% |
| P3 | jeff-stack (file upstream issues, not patches) | 11 | 3% |

### Canonical-CLI scoping maturity (own only, n=384)

| Status | Count | % | Meaning |
|---|---|---|---|
| missing | 110 | 29% | No --info, no --schema, no --examples (some have --help) |
| partial | 224 | 58% | Some flags present but incomplete envelope |
| passing | 50 | 13% | --info + --schema + --examples + --help all valid |

### Doctor subcommand maturity (own only, n=384)

| Status | Count | % | Meaning |
|---|---|---|---|
| absent | 215 | 56% | No doctor/health/verify/repair/check subcommand |
| basic | 169 | 44% | Has doctor; no --json OR no idem-key OR no backup OR no revert |
| upgraded | 0 | 0% | Passes world-class-doctor-mode rubric end-to-end |

### Exemplar pattern distribution (own only)

| Exemplar | Count | Pattern |
|---|---|---|
| apply-tmux-tuning | 3 | Full lifecycle: dry-run + apply + revert + doctor + idempotent + byte-exact backup |
| beads-db-recover | 5 | doctor + apply + backup_path + smoke + ledger row |
| reconcile-polish-gate | 35 | atomic_write + idempotency-key + apply with backup |
| none | 341 | No discernible canonical pattern; doctor-mode upgrade required |

## Bead 2 input set (P0 = 234 binaries)

Top 10 P0 lanes by concentration:

| Lane | P0 count |
|---|---|
| general | 103 |
| recovery | 37 |
| dispatch | 24 |
| jeff-corpus | 17 |
| agent-mail | 10 |
| beads | 9 |
| doctrine | 8 |
| storage | 7 |
| testing | 6 |
| mission | 5 |

The `general` lane is over-broad — first action in bead 2 should be a
lane-reclassification pass (re-grep for finer tokens like
`coordinator|topology|callback|dispatch-log` before doing the canonical
patches). Splitting `general` into ~5 sub-lanes will make per-lane PR
batching feasible.

## Bead 3 input set (P1 = 27 binaries)

These are the closest-to-upgraded surfaces — already passing canonical and
have a basic doctor. World-class-doctor-mode pass-1 should run on these
**first** (highest-leverage; partial credit already in place).

Top 15 P1 by score (highest = closest to world-class):

| Score | Binary | Lane | Exemplar |
|---|---|---|---|
| 875 | ntm-checkpoint-rollback-guard.sh | dispatch | reconcile-polish-gate |
| 750 | ntm-policy-contracts.sh | dispatch | reconcile-polish-gate |
| 750 | ntm-audit-receipts.sh | dispatch | reconcile-polish-gate |
| 750 | mission-fitness-callback-validator.sh | mission | reconcile-polish-gate |
| 750 | mission-anchor-dispatch-license.sh | mission | reconcile-polish-gate |
| 750 | install-coordinator-daemon.sh | orchestration | reconcile-polish-gate |
| 625 | watcher-isomorphic-probe.sh | general | none |
| 625 | stale-in-progress-reaper.sh | general | none |
| 625 | ntm-serve-eventstream-bridge.sh | agent-mail | none |
| 625 | ntm-quota-proactive-probe.sh | dispatch | none |
| 625 | ntm-metrics-doctor-probe.sh | dispatch | none |
| 500 | peer-orch-respawn-permit.sh | recovery | none |
| 500 | mission-fitness-doctor.sh | doctrine | none |

The 6 surfaces at 750+ already implement the reconcile-polish-gate exemplar
substantially. They'll need a smaller doctor-mode delta — primary work is
adding fixture suite, undo-byte-exactness verification, and Phase-7 fresh-eyes
pass against the WCDM rubric.

## Existing canonical-cli regression test coverage (n=11)

| Surface | Test path |
|---|---|
| flywheel-loop | `tests/canonical-cli-scoping-flywheel-loop.sh` |
| flywheel-loop (alt) | `tests/flywheel-loop-canonical-cli.sh` |
| flywheel-loop-tick | `tests/flywheel-loop-tick-canonical-cli-test.sh` |
| flywheel-autoloop | `tests/flywheel-autoloop-canonical-cli.sh` |
| flywheel-doctrine-sync | `tests/flywheel-doctrine-sync-canonical-cli.sh` |
| flywheel-lock-repair | `tests/flywheel-lock-repair-canonical-cli.sh` |
| flywheel-refresh-source | `tests/flywheel-refresh-source-canonical-cli.sh` |
| flywheel-skillos-relay | `tests/flywheel-skillos-relay-canonical-cli.sh` |
| flywheel-verdict | `tests/flywheel-verdict-canonical-cli.sh` |
| peer-orch-respawn-permit.sh | `tests/peer-orch-respawn-permit-canonical-cli-test.sh` |
| dispatch-canonical-cli-validator | `.flywheel/tests/test-dispatch-canonical-cli-validator.sh` |

These 11 are the existing baseline. Bead 2's first action is verifying
all 11 still pass on HEAD (regression sanity), then extending coverage to
the 234 P0 set in priority order.

## Substrate already in place (do not rebuild)

1. **Existing CLI registry**: `.flywheel/cli-registry.json` (9 surfaces).
   Schema `flywheel-cli-registry/v1`. Magic comment marker:
   `# flywheel-cli-surface: true`. Emit script:
   `.flywheel/scripts/cli-registry-emit.sh`. Test:
   `tests/test_cli_registry_emit.sh`. Bead 2 EXTENDS this — should grow
   from 9 to ~234 rows after canonical baseline ships per surface.

2. **Canonical-cli-scoping skill scripts** (the validators):
   - `~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh`
   - `~/.claude/skills/canonical-cli-scoping/scripts/canonical-cli-scorecard.sh`
   - `~/.claude/skills/canonical-cli-scoping/scripts/ci-gate-cli-scoping.sh`

3. **World-class-doctor-mode skill scripts** (40+ helpers for bead 3):
   - `discover-cli.sh --probe-doctor`
   - `cass-mine.sh`, `mine-changelog.py`, `query-corpus.py`
   - `scaffold-doctor.sh`, `scorecard.py`
   - `verify-{undo,idempotence,crash-recovery,concurrency,metamorphic,cross-fm}.sh`
   - `validate-doctor.sh`, `single-fm-rescore.sh`
   - `coverage-gap.py`, `diff-scorecards.py`

4. **Flywheel doctor lib** at `~/.claude/skills/.flywheel/lib/doctor.d/`:
   - `part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`
   - `part-02-check_beads_db_health-to-detect_tests_json.sh`
   - `part-03-security-posture.sh`

5. **Proven exemplars** (the templates to propagate):
   - `.flywheel/scripts/apply-tmux-tuning.sh`
   - `.flywheel/scripts/apply-substrate-tuning.sh`
   - `.flywheel/scripts/beads-db-recover.sh`
   - `templates/flywheel-install/scripts/reconcile-polish-gate.sh`
   - `.flywheel/scripts/jeff-corpus-compact.sh`
   - `.flywheel/scripts/validation-fix-bead.sh`

## Caveats

1. **Static analysis only**. Numbers are upper-bound estimates. Bead 2 will
   run live `--info`/`--schema` probes and may downgrade some surfaces
   (e.g., a script with `case --info` arm that no-ops won't actually pass
   live scoping).

2. **`mutates_state=yes` is heuristic**. Detected via `--apply` flag, ledger
   append patterns, or backup pattern. May undercount Python scripts and
   over-count read-only probes that happen to use shell-mutation idioms in
   non-write contexts.

3. **`general` lane is over-broad** (103 P0 surfaces). First action in
   bead 2 is finer lane re-classification before per-lane PR batching.

4. **Probe didn't run live binaries**. Some scripts may hang or have unstated
   environment dependencies. Bead 2 must use `discover-cli.sh --probe-doctor`
   with a 5s per-probe timeout; record `probe_timeout` for failures rather
   than blocking the whole pass.

5. **No score validation against reference scorecards**. Estimates are
   125pts × 8 booleans, max 1000. World-class-doctor-mode skill's scorecard.py
   uses a finer 10-dimension rubric — bead 3 should re-score against that.

## Next actions

- **Bead 2 (flywheel-jloib)**: dispatch worker to run live canonical-CLI
  baseline pass on the top-30 P0 surfaces from this inventory (start with
  `dispatch` lane = 24 surfaces, since it's load-bearing and most concentrated).
  Then process remaining P0 lanes in concentration order.
- **Bead 3 (flywheel-oxzyr)**: dispatch worker to run world-class-doctor-mode
  ten-phase loop on the top-6 P1 surfaces (those at score 750+).
  `flywheel-loop` remains the canonical first-target reference impl per
  bead 3's apply-spec.
- **Optional bead 4** (deferred): extend `cli-registry-emit.sh` to auto-detect
  surfaces by scanning for the `# flywheel-cli-surface: true` marker, and
  add a CI check that flags any new mutating script without the marker.
