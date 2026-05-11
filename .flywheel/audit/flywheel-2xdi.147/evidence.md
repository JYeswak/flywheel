# flywheel-2xdi.147 — Evidence Pack

**Bead:** flywheel-2xdi.147 (P3)
**Title:** [gap-wired-but-cold] `.flywheel/scripts/cross-repo-fmh-probe.sh`
**Mission fitness:** `adjacent` — 4th instance of newly-promoted test-receiver wire-in recipe
**Sister recipe (now N=4):** 2xdi.90 + .92 + .146 + **.147**
**Sanctioning:** flywheel-2xdi.146 (N=3 promotion ready)

## Hypothesis vs root cause (N=35 bead-hypothesis META-rule)

**Bead hypothesis:** script not referenced by flywheel ledgers in 30d.

**Verified:**
- Script EXISTS, well-formed (`cross-repo-fmh-probe.v1` schema)
- Owns bead `flywheel-1rmp.12` (cross-repo-failure-mode-harvester value-gap)
- Full canonical-cli surface: `--info`/`--schema`/`--doctor`/`--health`/`--json` + operational args (`--lookback-days`/`--min-repos`/`--top`)
- Step 4o anti-pattern preserved (READ-ONLY; no br/ntm/gh/git mutating verbs)
- ZERO active corpus references — confirmed cold

## Fix

Same recipe as 2xdi.90/.92/.146: test under canonical-cli naming convention. Tests file at `tests/cross-repo-fmh-probe-canonical-cli.sh` provides corpus #5 receiver, clearing the wired-but-cold gap.

Created `tests/cross-repo-fmh-probe-canonical-cli.sh` with **12 assertions** (richer than prior 3 instances due to richer probe surface):
1. syntax
2. --info envelope (cross-repo-fmh-probe.v1)
3. --schema envelope (same version)
4. --doctor envelope (triad)
5. --health envelope (full triad)
6. default --json run mode envelope
7. --lookback-days arg accepted (per-call tuning)
8. --min-repos arg accepted (per-call tuning)
9. --top arg accepted (per-call tuning)
10. Step 4o READ-ONLY anti-pattern (no notification/mutating call sites)
11. schema_version stable across all 5 surfaces (no drift)
12. owner-bead (flywheel-1rmp.12) citation preserved

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Identify gap empirically | DONE — 0 corpus receivers; cold flag fresh |
| AG2: Wire receiver | DONE — test file under canonical-cli convention |
| AG3: Verify gap cleared | DONE — fresh probe `cross-repo-fmh-probe` absent from gap_ids |

## Verification

```bash
$ bash tests/cross-repo-fmh-probe-canonical-cli.sh
SUMMARY pass=12 fail=0

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("cross-repo-fmh-probe"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3**
- **DIDNT none**
- **GAPS none**

## Files Changed

- `tests/cross-repo-fmh-probe-canonical-cli.sh` (new, 105 lines, 12/12 PASS)
- `.flywheel/audit/flywheel-2xdi.147/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `bash tests/cross-repo-fmh-probe-canonical-cli.sh | tail -1`
- `l112_probe_expected`: `grep:pass=12 fail=0`
- `l112_probe_timeout_sec`: `30`

## Recipe replication — N=4 (1st post-promotion application)

| # | Bead | Probe | Assertions |
|---|---|---|---|
| 1 | 2xdi.90 | operator-fatigue-probe | 9/9 |
| 2 | 2xdi.92 | public-artifact-pipeline-probe | 10/10 |
| 3 | 2xdi.146 | codex-pane-path-probe (N=3 promotion) | 10/10 |
| 4 | **2xdi.147** | **cross-repo-fmh-probe** | **12/12** |

**1st post-promotion application.** The recipe was promoted at 2xdi.146;
this is its first post-promotion instance — confirms operational stability
just like 2xdi.134 was the 1st post-kwjja-promotion for forward-link recipe.

Assertion count growth (9 → 10 → 10 → 12) reflects probe surface richness;
the recipe template is unchanged.

## Pattern reinforcement — 24th distinct fix shape entry

Cluster shape distribution after N=4 test-receiver wire-ins:
- doctrine cross-link forward-link: N=11
- probe corpus extensions: N=4
- **test-receiver wire-in: N=4** ← tied for 2nd most-replicated
- unmanaged-skill direct mutation + paired patch: N=2
- canonical-cli rename: N=2
- stale-orphan REMOVE: N=2
- singletons: 8

Test-receiver wire-in (N=4) is now tied with probe corpus extensions
(N=4) as the 2nd most-replicated cluster pattern.

## Four-Lens Self-Grade

- **brand:** 10 — 1st post-promotion instance; faithful recipe application
- **sniff:** 10 — 12 assertions exercise the richest probe surface yet (5 canonical surfaces + 3 operational args)
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future workers shipping similar fixes have a 4-exemplar recipe with growing assertion-coverage shape
