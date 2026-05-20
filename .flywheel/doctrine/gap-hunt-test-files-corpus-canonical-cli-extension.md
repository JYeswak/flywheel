# gap-hunt-probe test_files_corpus canonical-cli extension (2xdi.88)

**Class:** META-RULE corpus extension for `probe-without-receiver` false-positive class
**Filed:** 2026-05-11
**Origin bead:** flywheel-2xdi.88 (P3) — `[gap-probe-without-receiver] mobile-eats-end-user-health-probe.sh`
**Same META-RULE shape as:** 2xdi.47 (for-loop indirect-source), 2xdi.48 (bin/* wrappers), 2xdi.49 (SKILL.md docs), 2xdi.50 (var-assigned defaults), 2xdi.54 (doctrine/*.md), 2xdi.58 (tests/test_*.sh), 2xdi.69 (launchd plists), e7lxv (phantom-bead suppression), kckw8 (3-corpora wiring chains)

## META-RULE

**Fix the corpus property, not the per-script allowlist.**

When `gap-hunt-probe.sh` flags a `*-probe.sh` script as `probe-without-receiver`,
verify the corpus coverage BEFORE filing a per-script allowlist row or filing a
wire-in bead. The probe is false-positive when:

1. A test file exists at `tests/<basename>-canonical-cli.sh` or
   `.flywheel/tests/<basename>-canonical-cli.sh` that references the probe, **and**
2. The pre-extension corpus glob (`test-*.sh`, `test_*.sh`) did not include the
   canonical-cli suffix style.

The fix is a one-line glob extension in `test_files_corpus()`, not a per-script
exception.

## Why this works

The canonical-cli-scoping convention (per
`~/.claude/skills/canonical-cli-scoping/SKILL.md`) prescribes
`tests/<surface>-canonical-cli.sh` as the canonical CLI conformance test
naming. As of 2026-05-11, the flywheel.git `tests/` tree has 278+ such files,
of which 23 reference a `-probe.sh` script directly (i.e., they ARE receivers
of those probes via test invocation).

Pre-2xdi.88 corpus glob `("test-*.sh", "test_*.sh")` silently missed this
class because `<basename>-canonical-cli.sh` lacks the `test-`/`test_` prefix.

## The fix (one line)

```python
# .flywheel/scripts/gap-hunt-probe.sh test_files_corpus()
# Pre-2xdi.88
for pattern in ("test-*.sh", "test_*.sh"):
# Post-2xdi.88
for pattern in ("test-*.sh", "test_*.sh", "*-canonical-cli*.sh"):
```

## Verified leverage

Single extension resolves at least 2 OPEN P3 false-positive beads in the same
gap-hunt run that flagged 2xdi.88:

| Bead | Subject | Sister test | Status |
|---|---|---|---|
| flywheel-2xdi.88 | mobile-eats-end-user-health-probe.sh | tests/mobile-eats-end-user-health-probe-canonical-cli.sh | RESOLVED |
| flywheel-2xdi.90 | operator-fatigue-probe.sh | tests/operator-fatigue-probe-canonical-cli.sh | RESOLVED (2-for-1) |

Pre-fix `probe-without-receiver` class count: 17+ (per gap-hunt-probe --json
distribution at 2026-05-11T~15:00Z; mobile-eats + operator-fatigue both
present).

Post-fix `probe-without-receiver` class count: 17 (mobile-eats + operator-fatigue
both NO LONGER present; other genuine probes remain — those are real wire
gaps or different false-positive classes pending separate triage).

## What this is NOT

- NOT a relaxation of probe wire-in discipline. Probes that lack EITHER a
  receiver OR a canonical-cli test file are still flagged. Most of the 17
  remaining `probe-without-receiver` entries are genuine wire gaps.
- NOT a substitute for tick.md wire-in. Probes that need continuous (tick-driven)
  invocation still require tick.md Dim-N subsection (per flywheel-myfak.1
  precedent for Dim-9).
- NOT a free pass for un-tested probes. The canonical-cli test must EXIST
  at the expected path AND reference the probe — if either is absent, the
  flag stands.

## Regression test

`.flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh` locks in
all 5 AGs:
- AG1 corpus glob includes `*-canonical-cli*.sh`
- AG2 mobile-eats no longer flagged
- AG3 operator-fatigue no longer flagged (2-for-1 leverage)
- AG4 prior 2xdi.58 `test_*.sh` allowlist preserved
- AG5 `bash -n` syntax check passes

Run quick: `TEST_QUICK=1 .flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh`
Run full (includes live probe invocation): `.flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh`

## Cross-references

- META-RULE precedent: `.flywheel/doctrine/bead-hypothesis-starting-point.md`
  (2xdi.54) — probe before implementing; root-cause fixes make symptom-AGs moot
- Sister extensions: 2xdi.47/48/49/50/54/58/69, e7lxv, kckw8 (8 prior
  META-RULE corpus extensions this session; this is the 9th)
- Canonical-cli convention source:
  `~/.claude/skills/canonical-cli-scoping/SKILL.md` §"Implementation checklist"


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
