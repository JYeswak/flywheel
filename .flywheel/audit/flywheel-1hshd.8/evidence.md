# Compliance Evidence Pack — flywheel-1hshd.8

Surface: `/Users/josh/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh`
Bead: flywheel-1hshd.8 (wave-4-general-8)
Parent bead: flywheel-1hshd
Identity: MagentaPond

## Summary — TWO-REPO commit (surface outside flywheel)

**Cross-repo surface**: this is the FIRST wave-4 surface that lives OUTSIDE the flywheel repo. The script is at `~/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh` — inside the `~/.claude` git repo, not flywheel.

Workflow:
- **`.claude` repo**: receives the script edit (scaffold + lint fix + magic comment)
- **`flywheel` repo**: receives the test file + this evidence pack + the canonical CLI test entry

67 → 374 lines (+307 lines, ~458% growth — large because the wrapper was 67 lines and needed FULL canonical surface family added, not partial). 22/22 PASS, AG1+AG3 strict, lint RC=0 (was RC=1).

## Inventory baseline (pre-scaffold)

`has_apply:false, has_dry_run:false, has_doctor:false, has_info:false, has_schema:false, has_examples:false, has_repair:false, has_health:false, marked_cli_surface:false`. Only `has_help:true` and `has_json:true`. Wave-4 partial label was generous — this was effectively missing-baseline despite being in the partial lane.

## Gaps closed (6 — full canonical-CLI family added)

1. **L5 missing-strict-mode** → `set -uo pipefail` → `set -euo pipefail` (safe because the wrapper already uses explicit `set +e` around the VALIDATOR call to preserve rc capture for pass/block/unverifiable tri-state)
2. **L6 missing-magic-comment** → `# flywheel-cli-surface: true`
3. **--info / --schema / --examples** → AG3-compliant introspection envelopes
4. **No-dash subcommand family** → doctor / health / repair / validate / audit / why / quickstart / help / completion
5. **--apply contract** → repair --apply requires --idempotency-key (rc=3)
6. **Substrate probes** → doctor checks 5: jq, validator_executable, repo_dir_present, dispatch_file_readable, audit_log_writable

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json` | PASS (**NEW**) |
| `--schema --json` | PASS (**NEW**) |
| `--examples --json` | PASS (**NEW**) |
| `doctor --json \| jq -e '.checks \| length >= 5'` | PASS (**NEW** — 5 substrate probes) |
| `repair --apply` without `--idempotency-key` → rc=3 | PASS (**NEW**) |
| canonical-cli-lint.sh RC=0 | PASS (**NEW** — was RC=1 from L5) |
| wrapper delegation preserved (echo "..." \| wrapper --dispatch-file → validator) | PASS |

## Per-binary fillin coverage

- **doctor (5 probes)**: jq_on_path, validator_executable (CALLBACK_RECEIPT_VALIDATOR), repo_dir_present, dispatch_file_readable (when CALLBACK_RECEIPT_DISPATCH_FILE set), audit_log_writable.
- **health**: tails audit log; 7d staleness threshold.
- **repair (2 scopes)**: audit-log-rotate (5MB; rc=3) + validator-prime (read-only — probes validator path).
- **validate (4 subjects)**: row (3 required fields) + schema + config + validator (probes validator-callable).
- **audit / why / quickstart / help / completion**: full canonical family.
- **Original wrapper behavior preserved**: stdin → VALIDATOR `check --callback-stdin` → tri-state exit (0=pass, 1=block, 2=unverifiable).

## Test suite

`tests/callback-receipt-validator-wrapper-canonical-cli.sh` — 22/22 PASS:
- 12 AG1 canonical surfaces
- 4 fillin-specific (doctor probes, repair validator-prime, validate validator + row)
- 2 BACKWARD-COMPAT (wrapper delegates to validator; rejects missing --dispatch-file with rc=2)
- 3 lint + magic comment + --help
- 1 bash -n syntax

## Cross-repo commit pattern (NEW skill discovery)

This pattern documents a NEW workflow for wave-4 surfaces with cross-repo paths:
1. Reserve the surface via L107 (works even for paths outside flywheel)
2. Edit the script in its native repo (`~/.claude` in this case)
3. Create test file in flywheel `tests/` with absolute path reference
4. Create evidence pack in flywheel `.flywheel/audit/<bead-id>/`
5. Commit script edit in source repo (`.claude`)
6. Commit test + evidence in flywheel
7. Backup file goes in the source repo's `.bak.scaffold-*` pattern

This is the first time the wave-4 worker-tick has needed to split commits across repos. Filing as a `skill-discovery/v1` row.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 (6 gaps closed; FULL canonical family from scratch) |
| Heredoc fallback preserved | 150/150 (original wrapper stdin→validator delegation unchanged) |
| Test coverage (22/22) | 100/100 |
| Documentation | 50/50 (cross-repo pattern documented) |
| Style / Bash hygiene | 100/100 (lint RC=0; safe strict-mode upgrade with explicit set +e block) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — first cross-repo surface; pattern documented for downstream workers.
- **sniff:10** — wrapper delegation verified (rc=1/2 from malformed callback proves dispatch path works post-scaffold).
- **jeff:10** — single-purpose scaffold; original 67-line wrapper logic preserved verbatim.
- **public:10** — Three Judges check: 22/22 tests + 2 dedicated backward-compat tests for wrapper delegation.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — 6 gaps closed, full canonical family added
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — no python
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`/Users/josh/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh` reserved + released (verified L107 works on cross-repo paths).

## Backup

`/Users/josh/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh.bak.scaffold-20260511T031811072518000Z-20145` (in .claude repo).
