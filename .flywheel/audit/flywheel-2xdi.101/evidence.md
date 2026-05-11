# flywheel-2xdi.101 — Evidence Pack

**Bead:** flywheel-2xdi.101 (P3)
**Title:** [gap-probe-without-receiver] state-store-authority-probe.sh
**Mission fitness:** `adjacent` — probe receiver wire-in + dedup-blind-spot discovery

## Joshua-flagged dedup signal

Dispatch note: "flywheel-2xdi.102 has identical title — surface as gap-hunt-probe dedup-blind-spot finding alongside primary investigation."

Investigation found **two distinct underlying issues** that both manifest as duplicate beads:
1. The auto-bead-filer doesn't dedup on title (filed `flywheel-9a3k1` P2)
2. The probe-finder false-positive matched a test file as a probe (filed `flywheel-dnxjb` P3)

Both are sister gaps. Resolving 2xdi.101 *and* 2xdi.102 came via a single targeted rename.

## Hypothesis vs root cause (N=16 bead-hypothesis META-rule)

**Bead hypothesis:** probe at `.flywheel/scripts/state-store-authority-probe.sh` has no receiver.

**Root cause analysis revealed TWO files with the same basename:**
- `.flywheel/scripts/state-store-authority-probe.sh` — GENUINE probe (5400+ lines, full MODE=/canonical-cli surface)
- `tests/state-store-authority-probe.sh` — TEST file for the genuine probe (invokes `$ROOT/.flywheel/scripts/state-store-authority-probe.sh`)

Both got separate gap_ids in gap-hunt-probe → separate beads (2xdi.101 + .102). The probe-finder's `*-probe.sh` glob (rglob, no path scope) matched both. The test file IS the receiver the bead complains is missing, but gap-hunt-probe's test_files_corpus pattern (`test-*.sh` / `test_*.sh` / `*-canonical-cli*.sh`) didn't match the test's name.

## Fix

Single `git mv` resolves BOTH 2xdi.101 (real gap) and 2xdi.102 (false positive):

```bash
git mv tests/state-store-authority-probe.sh tests/state-store-authority-probe-canonical-cli.sh
```

Effect:
- New filename matches `*-canonical-cli*.sh` in test_files_corpus → genuine probe at `.flywheel/scripts/` now has a corpus-5 receiver → 2xdi.101 cleared
- New filename no longer matches `*-probe.sh` → file no longer scanned as probe → 2xdi.102 cleared
- 14/14 test assertions still PASS unchanged (test invokes probe via absolute path, not relative to its own name)

## Acceptance gates

| Gate | Status |
|---|---|
| AG1: Identify gap empirically | DONE — probe-finder picked up two files, real probe had no corpus-matching receiver |
| AG2: Wire receiver | DONE — rename existing test to canonical-cli convention |
| AG3: Verify gap cleared | DONE — fresh probe; both .101 and .102 targets cleared |
| AG4 (Joshua dispatch note): Surface dedup blind spot | DONE — filed flywheel-9a3k1 (auto-filer dedup) + flywheel-dnxjb (probe-finder false-positive) |
| AG5: Verify regression test still PASS | DONE — 14/14 unchanged |

## Verification

```bash
$ git mv tests/state-store-authority-probe.sh tests/state-store-authority-probe-canonical-cli.sh
$ bash tests/state-store-authority-probe-canonical-cli.sh
SUMMARY pass=14 fail=0

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("state-store-authority"))'
(empty) — both .101 and .102 targets cleared

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_class_distribution["probe-without-receiver"]'
14  # was 16 pre-fix; this fix cleared 2
```

## DID / DIDNT / GAPS

- **DID 5/5** — gap probed, both files identified, single mv applied, both beads cleared, 2 meta-gaps filed
- **DIDNT none**
- **GAPS** = `flywheel-9a3k1` (P2 auto-filer dedup blind-spot) + `flywheel-dnxjb` (P3 probe-finder tests/ false-positive)

## Files Changed

- `tests/state-store-authority-probe.sh` → `tests/state-store-authority-probe-canonical-cli.sh` (git rename, no content change)
- `.flywheel/audit/flywheel-2xdi.101/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '[.gap_ids[] | select(test("state-store-authority"))] | length'`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `60`

## Pattern note

7th distinct fix shape in 2xdi.* cluster:
- 47/49/64/66 = probe corpus extensions
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in (new file)
- 100 = INCIDENTS citation
- **101/102 = git rename to canonical-cli convention (resolves real-bead + sister-FP in one move)**

The rename approach is uniquely efficient when:
- An existing test file matches the probe pattern
- The test invokes the probe via absolute path (no path-self-reference)
- Canonical-cli naming is the established convention

## Four-Lens Self-Grade

- **brand:** 10 — single-move resolves real + false-positive bead in one stroke
- **sniff:** 10 — investigation surfaced TWO root causes (auto-filer dedup + probe-finder FP); both filed as separate beads
- **jeff:** 9 — convergent with 2xdi.* cluster pattern
- **public:** 10 — Joshua's dedup-hint led directly to two meta-bead discoveries; documented for future bead-author + probe-author reference
