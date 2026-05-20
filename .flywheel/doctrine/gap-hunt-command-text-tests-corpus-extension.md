# gap-hunt-probe command_text() tests-corpus extension (2xdi.106)

**Class:** META-RULE recognizer corpus extension for `cross-source-silos` false-positive class
**Filed:** 2026-05-11
**Origin bead:** flywheel-2xdi.106 (P3) — `[gap-cross-source-silos] ntm-approve-human-gates-runs.jsonl`
**Same META-RULE shape as:** nq5ns (producer-stem fallback), 2xdi.88 (test corpus glob), 2xdi.98 (references cap raise)

## META-RULE

**Canonical-CLI tests ARE receiver-evidence.**

When `gap-hunt-probe.sh probe_cross_source_silos` flags a
`<X>-runs.jsonl` ledger as cross-source-silos, verify whether `tests/<X>-canonical-cli.sh`
or `.flywheel/tests/test_<X>.sh` exists and cites the producer script
BEFORE filing a per-ledger wire-in bead or allowlist row. The
ledger is false-positive when:

1. A test file exists for the producer script (`tests/<X>-canonical-cli.sh`
   or test-/test_ prefix shape), AND
2. The pre-2xdi.106 receivers corpus did NOT scan test files.

The fix is to add `tests/` and `.flywheel/tests/` to `command_text()`,
not a per-ledger allowlist.

## Why this works

The canonical-cli-scoping convention (per
`~/.claude/skills/canonical-cli-scoping/SKILL.md`) prescribes one
canonical-CLI test per surface at `tests/<surface>-canonical-cli.sh`.
The test cites the producer script by exact basename:

```bash
# tests/<surface>-canonical-cli.sh — header convention
SCRIPT="$ROOT/.flywheel/scripts/<surface>.sh"
"$SCRIPT" --info --json | jq -e '.name and .version ...'
"$SCRIPT" doctor --json | jq -e '.checks' ...
```

This citation IS receiver-evidence under nq5ns's producer-stem fallback:
the test names the producer, and nq5ns's match logic catches the producer
stem. The only missing piece pre-2xdi.106 was that `command_text()`
didn't scan test files — only doctrine surfaces (AGENTS/INCIDENTS/README/
doctrine/rules/commands).

## Counterargument considered

A reasonable objection: "tests aren't doctrine; they're behavioral specs.
Operators don't read tests to learn about ledgers."

Counter: canonical-cli tests for SCAFFOLDED canonical-cli surfaces are
**executable documentation**. They define the surface's contract (doctor/
health/repair/validate/audit/why/etc. signatures) and serve the same
discoverability function as a doc-row in SKILL.md or AGENTS.md — for a
scaffolded surface, the test IS the spec. Per the canonical-cli-scoping
universal-class rule, every scaffolded surface MUST have a canonical-cli
test, so the absence of a test for a scaffolded surface itself signals
a doc-completeness gap (the test absence IS the evidence to flag, and
my extension correctly leaves the 3 untested-stem ledgers flagged).

## The fix (one-block addition)

`.flywheel/scripts/gap-hunt-probe.sh` `command_text()` — appended block:

```python
test_roots = [REPO_ROOT / ".flywheel" / "tests", REPO_ROOT / "tests"]
for test_root in test_roots:
    if not test_root.is_dir():
        continue
    for pattern in ("test-*.sh", "test_*.sh", "*-canonical-cli*.sh"):
        for test_path in safe_iter_files(test_root, pattern, 600):
            pieces.append(read_text(test_path, 50_000))
```

50 KB per-file cap is generous — most test files are under 5 KB; the
50 KB ceiling accommodates extensively-instrumented canonical-cli tests
without budget concern. 600-file cap per pattern × 3 patterns × 2 roots
= up to 3600 files, but real counts are ~283 + ~348 = ~631 files total.

Globs mirror 2xdi.88's `test_files_corpus()` post-fix shape (symmetric
recognizer surface across probe-without-receiver and cross-source-silos).

## Verified leverage (15-for-1)

Pre-fix `cross-source-silos` count: 18
Post-fix `cross-source-silos` count: 3

Resolved by this single corpus extension (had canonical-cli or
test-prefix test references):
- ntm-approve-human-gates-runs.jsonl (THIS bead)
- beads-db-recover-runs.jsonl
- blocker-ac-tick-cadence-runs.jsonl
- caam-rotate-and-respawn.jsonl
- codex-budget-watchdog.jsonl
- dispatch-surface-conflict-probe-runs.jsonl
- ntm-coordinator-shadow-runs.jsonl
- ntm-fleet-health-runs.jsonl
- plan-to-bead-auto-trigger-runs.jsonl
- recovery-baseline-snapshot-runs.jsonl
- recovery-install-plist-alpsinsurance-runs.jsonl
- recovery-install-plist-clutterfreespaces-runs.jsonl
- recovery-install-plist-skillos-runs.jsonl
- test-doctor-empty-errors-runs.jsonl
- worker-head-verify-runs.jsonl

Remaining (genuinely cross-source-siloed — no test evidence):
- callback-fix-beads.jsonl
- stash-discipline-snapshots.jsonl
- worker-deep-liveness-probe-install-runs.jsonl

These 3 are real wire-gaps and would benefit from either canonical-cli
test authoring OR doctrine documentation.

## What this is NOT

- NOT a relaxation of cross-source-silos discipline. Ledgers without
  any test or doctrine reference are still flagged (3 remaining post-fix
  prove this).
- NOT a substitute for SKILL.md / AGENTS.md doc completeness. Canonical-CLI
  tests + canonical doctrine surfaces are complementary, not equivalent.
- NOT a free pass for un-tested producer scripts. The fix REWARDS
  canonical-cli test coverage; absence of a test is itself evidence.

## Regression test

`.flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh` locks
in 5 AGs:
- AG1 command_text() flywheel-2xdi.106 extension + test_roots loop present
- AG2 ntm-approve-human-gates-runs.jsonl no longer flagged
- AG3 cross-source-silos count ≤ 6 (post-fix=3; ≥12 sister resolutions)
- AG4 prior nq5ns producer-stem fallback preserved
- AG5 bash -n syntax check

Run quick: `TEST_QUICK=1 .flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh`
Run full: `.flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh`

## Cross-references

- Recognizer-corpus precedent: nq5ns (producer-stem fallback) commit ee1f4e5b
- Test-corpus precedent: 2xdi.88 (probe-without-receiver test glob)
- Per-file cap precedent: 2xdi.66 + 2xdi.98 (SKILL.md + references/*.md cap raises)
- META-RULE: `.flywheel/doctrine/bead-hypothesis-starting-point.md` (probe before implementing)
- Orch hint accuracy note: Joshua/orch hinted "ee1f4e5b may have cleared this; close as resolved-upstream per 2m2cs". Per META-RULE 2xdi.54, verified empirically — fix did NOT clear. Disposition diverged from hint. Hint was directional signal, not conclusion.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
