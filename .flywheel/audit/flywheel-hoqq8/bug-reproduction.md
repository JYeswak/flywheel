# flywheel-hoqq8 — bug reproduction

## How the bug was confirmed

Before applying the fix, the regression test was run against the un-patched
scaffold-canonical-cli.sh. The exact command + outcome:

```
$ FIXTURE="$WORK_TMP/hoqq8-fixture.sh"
$ TESTS_DIR="$WORK_TMP/tests-regression"
$ SCAFFOLD_TESTS_DIR="$TESTS_DIR" .flywheel/scripts/scaffold-canonical-cli.sh "$FIXTURE" --apply --json --allow-uninventoried >/dev/null 2>&1
$ echo "rc=$?"
rc=3
$ ls "$TESTS_DIR"
hoqq8-fixture-canonical-cli.sh
```

`rc=3` (refused apply) accompanied by a leaked test file in TESTS_DIR.

## Root cause

In `scaffold-canonical-cli.sh::scaffold_target`, section 4 (test scaffolding)
ran BEFORE section 5 (apply gate). The original ordering:

1. compute diff
2. test scaffold:  `if [[ "$mode" == "apply" ]]; then write test_path; fi`  ← **side-effect**
3. apply gate:     `if [[ "$mode" == "apply" && -z "$idem_key" ]]; then refuse + exit 3; fi`

When `--apply` was passed without `--idempotency-key`, section 2's apply branch
fired (writing the test) before section 3 refused the apply. The refusal then
exited with rc=3 but the test was already on disk.

## Fix

Hoist the apply-key gate to fire BEFORE all side-effects (test scaffold,
backup, mutation). New ordering:

1. compute diff
2. apply-key gate (4a):  refuses immediately on `--apply` without `--idempotency-key`
3. test scaffold (4b):   only reached when apply has a valid key OR mode is dry-run
4. apply (5):            backup + cp; key already validated above

This is the same pattern applied to the python sibling (scaffold-canonical-cli-py.sh)
during flywheel-oozt3 validation.

## Sister context

flywheel-oozt3 shipped scaffold-canonical-cli-py.sh in this same lane and
discovered this bug class while writing its own apply-gate. The python sibling
shipped the fix natively; this bead applies the fix to the bash sibling.
