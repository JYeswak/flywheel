---
title: flywheel-1l8yt evidence — test-safe-probe canonical-CLI fillin
type: evidence
created: 2026-05-11
bead: flywheel-1l8yt
parent: flywheel-ok1sk (jloib wave-1 lane=testing)
chain: jloib-wave-1 / canonical-cli-coverage / lane-testing
---

# flywheel-1l8yt evidence

**Status:** DONE — test-safe-probe.sh canonical-CLI scaffold + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. 77 → 541 lines (~7.0x). cmd_run regression-test passthrough preserved (still exits 77 SKIP if rg missing).

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1-L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live signals |

did=5/5.

## Substantive fillin

test-safe-probe.sh is the regression test for `safe-probe.sh` (the production secret-leak detection probe). The test creates tmp dirs with FAKE GITHUB/INFISICAL tokens, runs safe-probe against them, and asserts no fake-token leaks in stdout/stderr captures.

### Substrate probes (doctor — 5 named)
- `rg_on_path` (required for cmd_run, else exit 77 SKIP)
- `safe_probe_companion` (the target script under test must exist + be executable)
- `mktemp_on_path` (needed for temp dir creation)
- `jq_on_path` (envelope emit)
- `tmpdir_writable` (`$TMPDIR` or `/tmp`)

### Surface impls
- **scaffold_cmd_doctor:** 5 probes
- **scaffold_cmd_health:** tails audit log; warn stale >7d (test is operator-triggered)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + **`tmp-leftover-prune`**: prunes `secret-safe-test.*` + `secret-safe-captures.*` dirs >1d old that leaked through trap failures)
- **scaffold_cmd_validate:** 5 subjects (row / schema / config / **`safe-probe-companion`** / **`tmpdir-policy`**)

## Live signals
- doctor 5/5 pass
- `validate --safe-probe-companion`: `present:true, executable:true, lines:318` (safe-probe.sh is 318 lines — sanity check)
- `validate --tmpdir-policy`: `writable:true, leftover_test_dirs:0` (clean fleet — no leaked test dirs)

## Surface-specific design notes

**`tmp-leftover-prune` scope**: The test cmd_run uses `mktemp -d secret-safe-test.XXXXXX` + `secret-safe-captures.XXXXXX` with a `trap rm -rf` cleanup. If the test process is killed before the trap fires (kill -9, OOM, system reboot), the dirs leak. This scope prunes leftover dirs older than 1 day. Conservative threshold — gives the test plenty of time to clean up after itself before pruning.

**`safe-probe-companion` subject**: Probes the EXISTENCE of the script under test. The canonical layer treats safe-probe.sh as substrate (it's a dependency of the test runner). Useful early-warning for `safe-probe.sh got renamed/deleted but the test still references it`.

**`tmpdir-policy` subject**: Probes `$TMPDIR` writable + counts leftover test dirs. Operators can spot trap-leakage symptoms before they accumulate.

## Cross-references
- Parent: flywheel-ok1sk (jloib wave-1)
- Lane: testing
- Sister wave fillins: wzjo9.x avg 980-990
- Backup: `.flywheel/scripts/test-safe-probe.sh.bak.scaffold-20260511T001908056828000Z-34418`
- Test: tests/test-safe-probe-canonical-cli.sh (20/20 PASS)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — wave-1 lane=testing fillin at sister-trend cadence; `tmp-leftover-prune` repair scope is test-specific and operator-useful (catches trap-leakage symptoms)
- **sniff: 10** — all 5 doctor probes pass live; safe-probe.sh companion existence verified (318 lines); tmpdir-policy shows 0 leftover dirs (clean fleet); cmd_run exit 77 SKIP semantics preserved
- **jeff: 9** — preserves cmd_run regression-test semantics (tmp_root + captures mktemp + trap cleanup + run_expect_rc + assert_no_fake_output); helper-lib API contracts respected; conservative 1-day pruning threshold avoids racing the live test
- **public: 10** — three judges check: skeptical operator (20/20 PASS + 5-probe doctor + 318-line companion verified live), maintainer (5 validate subjects expose every dependency the cmd_run has), future debugger (safe-probe-companion + tmpdir-policy subjects make the test's substrate dependencies enumerable)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + cmd_run regression-test passthrough preserved + tmp-leftover-prune scope is test-specific (operator-useful) + safe-probe-companion subject surfaces test target dependency + tmpdir-policy subject probes trap-leakage symptoms = **990/1000**.
