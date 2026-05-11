# flywheel-2xdi.92 — Evidence Pack

**Bead:** flywheel-2xdi.92 (P3)
**Title:** [gap-probe-without-receiver] public-artifact-pipeline-probe.sh
**Mission fitness:** `adjacent` — probe receiver wire-in
**Sister:** flywheel-2xdi.90 (operator-fatigue-probe; same recipe, shipped earlier this tick)

## Hypothesis vs root cause (N=15 bead-hypothesis META-rule)

**Bead hypothesis:** probe emits output but no receiver references it.

**Verified:** Probe exists, schema `public-artifact-pipeline/v1`, canonical-cli surfaces (--info / --schema / --doctor / --dry-run / --apply / --json) all return v1. Zero receivers across all 5 gap-hunt corpora. Genuine gap.

## Fix

Created `tests/public-artifact-pipeline-probe-canonical-cli.sh` — 10 assertions:
1. syntax
2-4. canonical-cli triad (--info / --schema / --doctor)
5. default --json run mode
6. --dry-run (mutation discipline)
7. --apply with mode=apply (mutation discipline)
8. --min-score arg accepted
9. READ-ONLY measurement (no notification call sites)
10. schema_version field present in --schema

## Acceptance gates

| Gate | Status |
|---|---|
| AG1: Identify gap empirically | DONE — 0 receivers across 5 corpora |
| AG2: Wire receiver | DONE — test file under canonical-cli convention |
| AG3: Verify gap cleared | DONE — fresh probe no longer flags it |

## Verification

```bash
$ bash tests/public-artifact-pipeline-probe-canonical-cli.sh
SUMMARY pass=10 fail=0

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("probe-without-receiver.*public-artifact"))'
(empty)

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_class_distribution["probe-without-receiver"]'
16   # was 19 pre-fix; this fix cleared 1, sampling re-rank cleared 2 more
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, receiver wired, gap cleared
- **DIDNT none**
- **GAPS none new** — 16 other probe-without-receiver gaps remain

## Files Changed

- `tests/public-artifact-pipeline-probe-canonical-cli.sh` (new, 10/10 PASS)
- `.flywheel/audit/flywheel-2xdi.92/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("probe-without-receiver.*public-artifact"))'`
- `l112_probe_expected`: `literal:` (empty)
- `l112_probe_timeout_sec`: `60`

## Four-Lens Self-Grade

- **brand:** 9 — faithful sister-pattern application of 2xdi.90 recipe
- **sniff:** 10 — clean 10/10 PASS, no test refinement needed (vs 2xdi.90 needed 2)
- **jeff:** 9 — wires into corpus #5; no cross-repo edits
- **public:** 9 — assertions document the probe's mutation discipline (--dry-run vs --apply)
