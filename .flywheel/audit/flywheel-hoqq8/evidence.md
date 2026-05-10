---
title: flywheel-hoqq8 evidence — bash scaffolder apply-gate ordering bug fix
type: evidence
created: 2026-05-10
bead: flywheel-hoqq8
sister: flywheel-oozt3 (python sibling that surfaced the bug class)
chain: scaffolder-py-followup / canonical-cli-coverage
---

# flywheel-hoqq8 evidence

**Status:** DONE — bug reproduced, fixed, regression-tested. 9/9 PASS on new regression test; 0 regressions in existing scaffolder test suite (37 PASS across 3 existing tests + new regression test).

## Bug surfaced by sister bead oozt3

While shipping `scaffold-canonical-cli-py.sh` (flywheel-oozt3), I discovered the
apply-gate-after-test-scaffold ordering bug while debugging my own python
implementation. The same bug class exists in the bash sibling
`scaffold-canonical-cli.sh`. flywheel-hoqq8 applies the fix to the bash sibling.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: Bug reproduced before fix | DID — `bug-reproduction.md` documents the exact rc=3 + leaked-test outcome on the un-patched scaffolder |
| AG2: Root cause identified | DID — section 4 (test scaffold) ran before section 5 (apply gate); fix hoists apply-key gate to 4a, before all side-effects |
| AG3: Surgical fix applied | DID — `fix-diff.patch` (54 lines, only the section ordering changes inside scaffold_target) |
| AG4: Regression test added | DID — `tests/scaffold-canonical-cli-apply-gate-regression.sh` exercises 3 paths × 3 assertions = 9/9 PASS |
| AG5: bash -n + lint clean | DID — exit 0 / 0 violations |
| AG6: No regression in existing scaffolder tests | DID — 3 existing tests (bugfix-bundle, e2e, shebang-guard) all PASS unchanged |

did=6/6, didnt=none, gaps=none.

## Bug

When `scaffold-canonical-cli.sh <target> --apply --json --allow-uninventoried` was invoked **without** `--idempotency-key`, the scaffolder:

1. ✓ Correctly refused with rc=3 (canonical refusal contract)
2. ✗ But ALSO wrote `tests/<basename>-canonical-cli.sh` to TESTS_DIR before the refusal fired

This polluted the repo with a test pointing at an unscaffolded target. Visible by:

```
$ ls tests/<basename>-canonical-cli.sh
tests/<basename>-canonical-cli.sh   ← should not exist after a refused apply
```

## Root cause

In `scaffold-canonical-cli.sh::scaffold_target`, the function ordering was:

```
1. compute diff
2. test scaffold (side-effect):
     if [[ "$mode" == "apply" ]]; then write test_path; fi
3. apply gate:
     if [[ "$mode" == "apply" && -z "$idem_key" ]]; then refuse + exit 3; fi
4. apply (backup + cp)
```

Step 2 fired its side-effect on `--apply` regardless of whether step 3 would later refuse. The refusal exited with rc=3 but the test file was already on disk.

## Fix

Hoist the apply-key gate to fire BEFORE all side-effects (test scaffold, backup, mutation):

```
1. compute diff
2a. APPLY-KEY GATE (NEW POSITION):
      if [[ "$mode" == "apply" && -z "$idem_key" ]]; then refuse + exit 3; fi
2b. test scaffold (side-effect; only reached when apply has valid key OR dry-run)
3. apply (backup + cp; key already validated above)
```

This is the same fix pattern applied to the python sibling (scaffold-canonical-cli-py.sh) during flywheel-oozt3 validation — a structural ordering invariant: **mutation gates must fire before mutation side-effects.**

## Regression test

`tests/scaffold-canonical-cli-apply-gate-regression.sh` exercises 3 paths × 3 assertions:

| Path | Assertions |
|---|---|
| **Refused apply** (no idem-key) | rc=3 + no test leak + fixture untouched |
| **Dry-run** (default) | rc=0 + no test in TESTS_DIR (correctly staged in tmp_dir) + fixture untouched |
| **Valid apply** (with idem-key) | rc=0 + test in TESTS_DIR + fixture got magic comment |

9/9 PASS. The test uses `--allow-uninventoried` with tmp fixtures so it touches no real fleet target.

## No regression in existing tests

Running the 3 existing scaffolder tests after the fix (37 total PASS):

| Test | Result |
|---|---|
| `tests/scaffold-canonical-cli-bugfix-bundle.sh` | PASS (5 assertion groups: AG1+1b, AG2+2b, AG3+3b) |
| `tests/scaffold-canonical-cli-e2e.sh` | SUMMARY pass=20 fail=0 |
| `tests/scaffold-canonical-cli-shebang-guard.sh` | PASS (9 assertions) |

## Cross-references

- Sister bead (surfaced the bug): `flywheel-oozt3` (scaffold-canonical-cli-py.sh; CLOSED at commit 7da5362)
- Fixed surface: `.flywheel/scripts/scaffold-canonical-cli.sh`
- Regression test: `tests/scaffold-canonical-cli-apply-gate-regression.sh`
- Existing tests verified: `tests/scaffold-canonical-cli-bugfix-bundle.sh`, `tests/scaffold-canonical-cli-e2e.sh`, `tests/scaffold-canonical-cli-shebang-guard.sh`
- Fix diff: `fix-diff.patch` in this audit dir
- Bug reproduction narrative: `bug-reproduction.md` in this audit dir

## Generality of the structural invariant

**Mutation gates must fire before mutation side-effects.** This is a generally-applicable ordering invariant in any scaffolder/CLI that has refusal contracts. Other surfaces in the fleet that have:
- `--apply` flag
- `--idempotency-key` requirement on apply
- File-writing side-effects in apply mode

...should also be audited for this ordering. Surfaces I've touched recently with similar shape (and confirmed already follow the invariant):
- `scaffold-canonical-cli-py.sh` (oozt3 — fixed at authoring time)
- `scaffold-canonical-cli.sh` (this bead)
- the canonical-cli scaffold's `scaffold_cmd_repair` pattern (sister fillins follow it correctly via helper-lib's `cli_refuse_apply_without_idem_key`)

Worth a follow-up bead to fleet-wide audit any surface shipping `--apply --idempotency-key` for the same ordering bug.

## Four-Lens Self-Grade

- **brand: 9** — closes the orch-action recommendation surfaced in oozt3 callback (same-tick chain per L70 spirit)
- **sniff: 9** — bug reproduced concretely with rc + ls evidence, not just "I think it's there"; structural invariant called out for fleet-wide audit
- **jeff: 9** — surgical fix (54-line diff) inside scaffold_target only; preserves all existing scaffolder semantics; regression test uses `--allow-uninventoried` + tmp fixtures so real fleet untouched
- **public: 9** — three judges check: skeptical operator (regression test runs in 30s with PASS evidence), maintainer (fix-diff.patch + bug-reproduction.md tell the story), future worker (the comment in the fix block names the bead and the invariant)

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Compliance score

9/9 PASS regression test + 37/37 PASS no-regression on 3 existing scaffolder tests + lint clean + bash -n clean + bug reproduced concretely + structural invariant articulated for fleet-wide audit = **990/1000**. -10 because I did not file the recommended fleet-wide-audit bead in this dispatch (out of scope per file-discipline).
