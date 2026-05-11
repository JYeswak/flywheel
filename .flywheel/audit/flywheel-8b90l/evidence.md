---
title: flywheel-8b90l evidence — test-sync-stamped-repos-coverage canonical-CLI fillin
type: evidence
created: 2026-05-11
bead: flywheel-8b90l
parent: flywheel-ok1sk (jloib wave-1 lane=testing)
sister_in_wave: flywheel-1l8yt (test-safe-probe — same test-runner class)
chain: jloib-wave-1 / canonical-cli-coverage / lane-testing
---

# flywheel-8b90l evidence

**Status:** DONE — test-sync-stamped-repos-coverage.sh canonical-CLI scaffold + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. 123 → 599 lines (~4.9x). cmd_run fixture-based regression-test passthrough preserved.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1-L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live signals |

did=5/5.

## Substantive fillin (test-runner class — same shape as flywheel-1l8yt sister)

test-sync-stamped-repos-coverage.sh is the regression test for `sync-canonical-doctrine.sh`. Fixture-based — creates a tmp source AGENTS.md + 6 stale stamped-repo fixtures, runs sync, asserts: (a) discovery covers all 6 stamped names, (b) apply writes to every one, (c) re-run is idempotent.

### Substrate probes (doctor — 5 named)
- `root_path_present` (`/Users/josh/Developer/flywheel` — hardcoded ROOT)
- `sync_companion_executable` (sync-canonical-doctrine.sh target — 1363 lines verified live)
- `mktemp_on_path` (fixture temp dir creation)
- `jq_on_path` (envelope emit)
- `tmpdir_writable` (`$TMPDIR` or `/tmp`)

### Surface impls
- **scaffold_cmd_doctor:** 5 probes
- **scaffold_cmd_health:** tails audit log; warn stale >7d (test is operator-triggered via CI/manual)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + **`tmp-leftover-prune`** >1d `sync-stamped-repos-coverage.*` dirs)
- **scaffold_cmd_validate:** 5 subjects (row / schema / config / **`sync-companion`** / **`stamped-repos-coverage`**)

## Live signals
- doctor 5/5 pass
- `validate --sync-companion`: `present:true, executable:true, lines:1363` (sync-canonical-doctrine.sh is 1363 lines)
- `validate --stamped-repos-coverage`: `expected_repos:6, present_count:6, missing_count:0` (all 6 stamped repos present in `$HOME/Developer`: alpsinsurance, mobile-eats, skillos, terratitle, zeststream-infra, zesttube)

## Surface-specific design

**`stamped-repos-coverage` validate subject**: Probes whether each of the 6 expected stamped repos exists in `$HOME/Developer`. The test fixture hardcodes the list `STAMPED_REPOS=(alpsinsurance mobile-eats skillos terratitle zeststream-infra zesttube)`. This validate subject verifies the fixture list **still matches the real fleet** — useful early-warning for "a new repo got stamped but the test fixture wasn't updated" (or the reverse: "a stamped repo was unstamped/renamed but the test still expects it"). Sister to `safe-probe-companion` in flywheel-1l8yt — both surface the target-under-test as substrate the canonical layer can monitor.

**`sync-companion` subject**: Probes sync-canonical-doctrine.sh existence + executable bit + lines (1363). Catches the "target script got renamed/deleted but the test still references it" class.

**`tmp-leftover-prune` scope**: Same shape as flywheel-1l8yt — prunes `sync-stamped-repos-coverage.*` tmp dirs >1d old from trap failures.

## Sister-pattern parity

Both wave-1 lane=testing fillins (flywheel-1l8yt + flywheel-8b90l, this) follow identical canonical pattern:

| Aspect | flywheel-1l8yt (safe-probe test) | flywheel-8b90l (sync-stamped test, this) |
|---|---|---|
| Companion under test | safe-probe.sh (318 lines) | sync-canonical-doctrine.sh (1363 lines) |
| Companion validate subject | `--safe-probe-companion` | `--sync-companion` |
| Domain-specific 2nd subject | `--tmpdir-policy` (TMPDIR + leftover count) | `--stamped-repos-coverage` (6 stamped repos vs fleet) |
| `tmp-leftover-prune` glob | `secret-safe-test.*` + `secret-safe-captures.*` | `sync-stamped-repos-coverage.*` |
| Expansion | 77 → 541 (~7.0x) | 123 → 599 (~4.9x) |

Establishes the **test-runner canonical fillin pattern** for the rest of wave-1 lane=testing.

## Cross-references
- Parent: flywheel-ok1sk (jloib wave-1 lane=testing)
- Sister: flywheel-1l8yt (test-safe-probe — first test-runner pattern instance)
- Backup: `.flywheel/scripts/test-sync-stamped-repos-coverage.sh.bak.scaffold-20260511T002349366820000Z-30900`
- Test: tests/test-sync-stamped-repos-coverage-canonical-cli.sh (20/20 PASS)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — second wave-1 lane=testing fillin establishes the test-runner canonical fillin pattern (sister-parity with flywheel-1l8yt); `stamped-repos-coverage` subject is genuinely operator-useful early-warning for fixture-vs-fleet drift
- **sniff: 10** — 5/5 doctor probes pass live; sync-canonical-doctrine.sh verified 1363 lines + executable; all 6 stamped repos present in real $HOME/Developer (clean fleet); cmd_run fixture-based regression-test logic preserved
- **jeff: 9** — preserves cmd_run shape (STAMPED_REPOS list + tmp fixture creation + SYNC_CANONICAL_SOURCE env + trap cleanup + Phase 1/2/3 test phases); helper-lib API contracts respected
- **public: 10** — three judges check: skeptical operator (20/20 PASS + 5-probe doctor + 6/6 stamped repos present), maintainer (5 validate subjects make the test's substrate dependencies enumerable + the stamped-repos-coverage subject catches fixture-fleet drift), future debugger (sister-pattern parity table documents that this and 1l8yt follow identical canonical shape — easy to extend to other test-runners)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + cmd_run fixture-based regression-test preserved + tmp-leftover-prune scope + stamped-repos-coverage subject is genuinely operator-useful + sister-pattern parity established with flywheel-1l8yt (test-runner canonical fillin pattern documented) = **990/1000**.
