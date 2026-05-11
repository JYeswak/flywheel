# flywheel-2xdi.146 — Evidence Pack

**Bead:** flywheel-2xdi.146 (P3)
**Title:** [gap-wired-but-cold] `.flywheel/scripts/codex-pane-path-probe.sh`
**Mission fitness:** `adjacent` — test-receiver wire-in for cold probe; sister to 2xdi.90/.92
**Sister recipe:** flywheel-2xdi.90 + flywheel-2xdi.92 (N=2 prior); **this is N=3 → SKILL DISCOVERY PROMOTION**

## Hypothesis vs root cause (N=34 bead-hypothesis META-rule)

**Bead hypothesis:** script not referenced by flywheel ledgers in 30d.

**Verified — DOUBLE-flagged:**
- Fresh probe shows TWO classes firing for this script:
  - `wired-but-cold:developer-flywheel-.flywheel-scripts-codex-pane-path-probe.sh`
  - `probe-without-receiver:codex-pane-path-probe.sh`
- ZERO active corpus references (tick.md, other flywheel scripts, tests/, launchd)
- All references are in audit packs (`.flywheel/audit/...`) — doc surfaces, not active corpus
- Script is well-formed (canonical-cli surface: --info / --schema / --doctor / --json / --help)
- Owns bead `flywheel-orx1` (PATH-discipline contract validator)

## Fix

Same recipe as 2xdi.90 (operator-fatigue-probe) and 2xdi.92 (public-artifact-pipeline-probe): wire a regression test under `tests/<probe-name>-canonical-cli.sh` naming convention. This matches gap-hunt-probe's `test_files_corpus` pattern (corpus #5 receiver) AND the script's name pattern would let the test be globbed by `*-probe.sh` — but the canonical-cli naming convention removes that ambiguity.

Created `tests/codex-pane-path-probe-canonical-cli.sh` with 10 assertions:
1. syntax
2. --info envelope (codex-pane-path-probe/v1)
3. --schema envelope (same version)
4. --doctor envelope (triad)
5. default --json run mode envelope
6. default run includes status field
7. --help enumerates all 4 canonical surfaces
8. READ-ONLY (no notification call sites)
9. schema_version stable across all surfaces (no drift)
10. owner bead citation (flywheel-orx1) preserved

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Identify gap empirically | DONE — double-flagged across 2 classes; 0 corpus receivers |
| AG2: Wire receiver | DONE — test file under canonical-cli convention |
| AG3: Verify gap cleared | DONE — fresh probe; BOTH classes cleared |

## Verification

```bash
$ bash tests/codex-pane-path-probe-canonical-cli.sh
SUMMARY pass=10 fail=0

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("codex-pane-path-probe"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap probed, receiver wired, both classes cleared in one fix
- **DIDNT none**
- **GAPS none**

## Files Changed

- `tests/codex-pane-path-probe-canonical-cli.sh` (new, 95 lines, 10/10 PASS)
- `.flywheel/audit/flywheel-2xdi.146/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `bash tests/codex-pane-path-probe-canonical-cli.sh | tail -1`
- `l112_probe_expected`: `grep:pass=10 fail=0`
- `l112_probe_timeout_sec`: `30`

## 🎯 N=3 — SKILL DISCOVERY PROMOTION

The test-receiver wire-in recipe has now shipped **3 instances**:

| # | Bead | Probe | Assertions |
|---|---|---|---|
| 1 | flywheel-2xdi.90 | operator-fatigue-probe | 9/9 |
| 2 | flywheel-2xdi.92 | public-artifact-pipeline-probe | 10/10 |
| 3 | **flywheel-2xdi.146** | **codex-pane-path-probe** | **10/10** |

N=3 = skill-discovery promotion threshold met. Recipe applied unchanged
across 3 distinct probes. Filed
`pattern-emerged-probe-without-receiver-via-canonical-cli-test-fix-N3-promotion-ready`.

## Bonus: double-class clearance

This bead's fix cleared TWO probe classes in one operation:
- `wired-but-cold` (script not in ledger corpus)
- `probe-without-receiver` (no caller corpus hit)

Both classes share a common cause (no active corpus reference) and both
clear via the same fix (test file in corpus #5). Future probes that
double-flag this way should expect a single-fix resolution.

## Pattern reinforcement — 23rd distinct fix shape entry

Cluster shape distribution after this bead:
- doctrine cross-link forward-link: N=11
- probe corpus extensions: N=4
- **test-receiver wire-in: N=3** ← now at skill-promotion threshold
- unmanaged-skill direct mutation + paired patch: N=2
- canonical-cli rename: N=2
- stale-orphan REMOVE: N=2
- singletons: 100, dnxjb, 9a3k1, 113, kwjja, r9pri, 03yaj, plue9

Test-receiver wire-in is now the **3rd most-replicated cluster pattern**
(after doctrine cross-link and probe corpus extensions). At N=5 (next
2 instances land), promote to operational skill.

## Four-Lens Self-Grade

- **brand:** 10 — N=3 promotion-confirming instance; faithful sister-pattern
- **sniff:** 10 — 10 assertions covering all 4 canonical surfaces + READ-ONLY check + owner-bead-cite invariant
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future workers shipping cold-probe fixes have a 3-exemplar recipe pinned in the cluster
