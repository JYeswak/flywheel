# flywheel-f1s2x — Evidence Pack

**Bead:** flywheel-f1s2x (P2)
**Title:** [probe-test-filter-vacuous] sister gap-hunt-probe regression tests use `.gaps // []` filter on probe JSON that has no `.gaps` field — passes vacuously
**Mission fitness:** `adjacent` — testing-discipline correctness preserves the meaning of the 2xdi cluster's regression suite.

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| 1 | Update three sister tests to use `.gap_ids` / `.gap_class_distribution` instead of `.gaps` | DONE |
| 2 | Re-run; verify each per-script-name match returns 0 under the real filter | DONE — all four 4/4, 4/4, 4/4, 6/6 |
| 3 | Add cross-ref comment to `tests/gap-hunt-probe-skill-tree-md-corpus.sh` | DONE |

## Fix details

The probe's JSON output has NO top-level `.gaps[]` array — real gap state lives in `.gap_ids[]` (strings like `"wired-but-cold:.claude-skills-..."`) and `.gap_class_distribution{}`.

Three sister tests previously used `[.gaps // [] | .[] | select(.class == "wired-but-cold" and (.where | test("...")))] | length`. Since `.gaps` is null, `.gaps // []` evaluates to `[]`, the select() never runs, length is always 0 — assertion passes regardless of actual probe state.

**Replacement filter shape:**
```jq
[.gap_ids // [] | .[] | select(startswith("wired-but-cold:") and contains("<script-name>"))] | length
```

This decodes the actual gap_ids strings (encoded as `<class>:<stable-id>`), giving a real per-script-name check.

### Per-file changes

- **tests/gap-hunt-probe-for-loop-source-corpus.sh** — Test 3: switched to `.gap_ids` filter for `reconcile`. Dropped "0 total wired-but-cold" assertion (was vacuously true; real cluster has many remaining real cold candidates unrelated to 2xdi.47).
- **tests/gap-hunt-probe-skill-md-corpus.sh** — Test 3: switched to `.gap_ids` filter for `protected-session-recovery`. Dropped Test 4 "0 total" assertion.
- **tests/gap-hunt-probe-exec-sh-corpus.sh** — Test 3: switched to `.gap_ids` filter for `archetype-calibrate`. Dropped Test 4 "0 total" assertion.
- **tests/gap-hunt-probe-skill-tree-md-corpus.sh** — header comment updated to cross-ref this bead.

## Verification

| Test | Before | After |
|---|---|---|
| for-loop-source-corpus (2xdi.47) | 4/4 (vacuous) | 4/4 (real) |
| skill-md-corpus (2xdi.49) | 5/5 (vacuous total + per-script) | 4/4 (real per-script) |
| exec-sh-corpus (2xdi.64) | 5/5 (vacuous total + per-script) | 4/4 (real per-script) |
| skill-tree-md-corpus (2xdi.66) | 6/6 (already real) | 6/6 (real) |

The sister fixes ARE confirmed real (reconcile, protected-session-recovery, archetype-calibrate all unflagged under the real filter). The tests previously passed vacuously but the probe fixes are sound.

## DID / DIDNT / GAPS

- **DID 3/3** — all acceptance gates met
- **DIDNT none**
- **GAPS none**

## Files Changed

- `tests/gap-hunt-probe-for-loop-source-corpus.sh` (filter fix)
- `tests/gap-hunt-probe-skill-md-corpus.sh` (filter fix)
- `tests/gap-hunt-probe-exec-sh-corpus.sh` (filter fix)
- `tests/gap-hunt-probe-skill-tree-md-corpus.sh` (cross-ref comment)

## L112 Probe

- `l112_probe_command`: `grep -l "gaps // \[\]" tests/gap-hunt-probe-{for-loop-source,skill-md,exec-sh}-corpus.sh 2>/dev/null | wc -l | tr -d ' '`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `5`

## Meta-pattern reinforcement

**Test-filter vacuity** is a class. The lesson is: when a regression test asserts "0 matches" against a JSON field, verify the field actually exists in the output. `jq` silently returns empty arrays for missing fields via `//` operator — useful for resilience, dangerous for verification.

Sister-test reflex going forward: every new probe test must `jq '.field_name'` (no fallback) at least once to confirm the field exists in the real output, before using fallback-style filters.
