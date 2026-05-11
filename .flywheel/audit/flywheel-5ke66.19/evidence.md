---
bead: flywheel-5ke66.19
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-PARTIAL-BYPASS
sister_exemplars: 5ke66.11 (985, same PARTIAL); 5ke66.6 (985, same PARTIAL)
---

# Evidence Pack — flywheel-5ke66.19

## Scope

Wave-2-general-19 (19th of 21 5ke66 sub-beads). Apply canonical-cli scaffold +
substantive fillin to `.flywheel/scripts/state-md-miner.sh` — mines fleet
STATE.md files for /flywheel:learn opportunities; identifies stale STATE
entries (>--stale-days, default 14) and proposes auto-bead candidates
(--max-beads-per-repo default 5). Surface is **PARTIAL-BYPASS**
(third application of this variant).

## Files touched

`.flywheel/scripts/state-md-miner.sh` (503 → 749 lines after scaffold; TODO=0)
`tests/state-md-miner-canonical-cli.sh` (94 → 158 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/state-md-miner.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/state-md-miner.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/state-md-miner.sh \
  && bash tests/state-md-miner-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Variant choice — PARTIAL-BYPASS (third application)

Per-flag baseline probe pre-scaffold confirmed:
- Native `--info` emits canonical envelope: `state-md-miner/v1 +
  .default_roster + .default_state_dir`
- Native `--schema` emits full JSON-Schema for the result envelope
- Native `--examples` emits text invocation lines
- Native `doctor` (subcommand) NOT supported — argparse rejects

Scaffold owns verbs; native owns flags. Sister to 5ke66.6 + 5ke66.11.
Third application of PARTIAL-BYPASS confirms variant is robust + the
recipe transfers mechanically.

## Domain-specific fillins

### doctor (7 named probes)

- `bash`, `jq`, `mktemp` — universal
- `python3_available` (load-bearing for state-md-miner heredoc)
- `roster_readable` (`~/.local/state/flywheel/fleet-roster.json`;
  warn-tier; single-repo mode still works via --repo arg)
- `state_dir_writable` (`~/.local/state/flywheel/state-md-miner`)
- `audit_log_dir_writable`

### health

36h stale threshold (1.5x daily mining cadence; tunable via
`STATE_MD_MINER_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes)

- `state_dir` → `mkdir -p ~/.local/state/flywheel/state-md-miner`
- `audit_log_dir`
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects, domain-precise)

- `repo-path` — must be absolute (matches --repo arg semantic;
  consistent with 5ke66.2 append-safe-write target-path pattern)
- `stale-days` — integer in `[1, 365]` matching --stale-days arg
  semantic (default 14 from native argparse)
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/repo/finding_id/run_id matching the per-finding row schema).

## Test calibration (13 → 19)

Baseline tests calibrated to PARTIAL-BYPASS:

- Tests 2/3/4: native shapes (state-md-miner/v1 schema_version;
  JSON-Schema with .title; text examples)
- Tests 5-13: scaffold owns subcommands

6 fillin assertions:

- Test 14: PARTIAL-BYPASS annotation grep-discoverable
- Test 15: dual-direction fidelity (--info goes native [no .command]
  + doctor goes scaffold [.command=doctor])
- Test 16: validate repo-path rejects relative
- Test 17: validate stale-days accepts default 14
- Test 18: validate stale-days rejects 999 (out of [1,365])
- Test 19: doctor probes load-bearing python3 + roster + state_dir trio

## Notable

- Third PARTIAL-BYPASS application confirms variant maturity. Recipe
  transferred mechanically from 5ke66.11 with no scaffolder regressions.
- stale-days [1,365] range matches native --stale-days arg semantic
  (1-day minimum for any meaningful staleness check, 365-day cap as
  practical upper bound for fleet STATE.md mining)
- repo-path validator mirrors 5ke66.2 append-safe-write target-path
  pattern (absolute-only) — consistent canonical contract for any
  validator that takes a path arg
- Native --info envelope's keys (default_roster, default_state_dir)
  align with scaffold doctor's roster_readable + state_dir_writable
  probes — scaffold + native cross-reference each other

## Smoke captures

15 smoke captures verify all four route directions
(--info/--schema/--examples native, doctor/health/repair/validate/audit/
why scaffold).

## Mission fitness

Class: **adjacent** (per dispatch). state-md-miner.sh is the fleet
STATE.md miner that drives /flywheel:learn auto-bead creation;
canonical-CLI surface (mixed scaffold + native) lets orchestrator
probe substrate (python3 + roster + state_dir) and validate repo-path
+ stale-days args before triggering mining runs.
