---
title: "Phase 5 Polish r1 — ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07"
type: plan
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 5 Polish r1 — ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07

snapshot_ts: 2026-05-07T18:28:47Z  
worker: CloudyMill / flywheel:0.2  
mode: polish dry-run prep  
source_of_truth: `br list --all --json --limit 0 | jq '.issues[] | select(.title | test("ntm-wire-in"))'` plus `.flywheel/dispatch-log.jsonl`

## Executive Verdict

**Recommendation: second polish round needed.**

The implementation wave is close, but not close-gate-ready:
- `br` source of truth: 34/38 closed, 4 open.
- `r4hmy` is still open/in flight.
- 3 beads remain blocked on `ntm#124`.
- Close gate dry-run is FAIL because `STATE.json` is still in `decompose` and the Three Judges / composite quality scores are missing.
- Four-lens evidence is incomplete in dispatch-log rows for several W2 research closeouts.
- At least one closed bead (`rb88g`) is below a 9.0 composite: 8/8/9/8 = 8.25.
- Six Wave 3 closeouts have legacy `event:"closed"` rows without `pipeline_slug`; normalize before final close.

## Summary Metrics

| Metric | Value |
|---|---:|
| Beads in plan | 38 |
| Closed beads verified from `br --all` | 34 |
| Open beads | 4 |
| ISSUE/PARTIAL verdicts | 8 |
| Total LOC delta, close-gate planning basis | ~-7,483 |
| Deferred ntm#124 LOC | -1,418 |
| Known per-lens rows | 27 |
| Average brand, known per-lens rows | 8.96 |
| Average sniff, known per-lens rows | 8.96 |
| Average Jeff, known per-lens rows | 9.04 |
| Average public, known per-lens rows | 8.85 |
| Known per-lens composite avg | 8.95 |
| Close gate dry-run | FAIL |

Average excludes W2 rows where the dispatch closeout recorded only `verdict` or `composite` rather than all four lens values.

## All 38 Beads

| Bead | Status | Closure ts | Four-lens | Composite | LOC delta | Evidence / notes |
|---|---|---|---|---:|---:|---|
| flywheel-zqiw2 | closed | 2026-05-07T16:28:28Z | 9/9/9/9 | 9.00 | -621 | no evidence file path in `br close`; dispatch close row present |
| flywheel-sjdj2 | closed | 2026-05-07T16:53:58Z | 9/9/9/9 | 9.00 | -688 | no evidence file path in `br close`; dispatch close row present |
| flywheel-8bnz8 | closed | 2026-05-07T16:46:12Z | 9/9/9/9 | 9.00 | -1477 | no evidence file path in `br close`; dispatch close row present |
| flywheel-p0wwm | closed | 2026-05-07T16:49:19Z | 9/9/9/9 | 9.00 | -1116 | no evidence file path in `br close`; dispatch close row present |
| flywheel-zhr6s | closed | 2026-05-07T16:32:08Z | 9/9/10/9 | 9.25 | -351 | `/tmp/ntm-wire-in-W1-zhr6s-2026-05-07-evidence.md` |
| flywheel-zr12c | closed | 2026-05-07T16:34:41Z | 9/9/9/9 | 9.00 | -365 | no evidence file path in `br close`; dispatch close row present |
| flywheel-8tp66 | closed | 2026-05-07T16:32:00Z | 9/9/9/9 | 9.00 | -242 | no evidence file path in `br close`; dispatch close row present |
| flywheel-9gnjl | closed | 2026-05-07T16:43:24Z | 9/9/9/9 | 9.00 | -174 | no evidence file path in `br close`; dispatch close row present |
| flywheel-gndhc | closed | 2026-05-07T16:37:29Z | 9/9/9/9 | 9.00 | -161 | no evidence file path in `br close`; dispatch close row present |
| flywheel-7rerv | closed | 2026-05-07T16:37:09Z | 9/9/9/9 | 9.00 | -122 | `/tmp/ntm-wire-in-W1-7rerv-2026-05-07-evidence.md` |
| flywheel-txeui | closed | 2026-05-07T16:40:04Z | 9/9/9/9 | 9.00 | 0 | `/tmp/ntm-wire-in-W2-txeui-2026-05-07-evidence.md`; ISSUE |
| flywheel-8e1fx | closed | 2026-05-07T16:42:39Z | 9/9/9/9 | 9.00 | 0 | `/tmp/ntm-wire-in-W2-8e1fx-2026-05-07-evidence.md`; ISSUE |
| flywheel-m9aoh | closed | 2026-05-07T16:46:08Z | missing | n/a | 0 | `/tmp/ntm-wire-in-W2-m9aoh-2026-05-07-evidence.md`; ISSUE; dispatch row lacks per-lens |
| flywheel-melgv | closed | 2026-05-07T16:43:11Z | composite only | 9.60 | 0 | no evidence file path in `br close`; PARTIAL_keep_wrapper |
| flywheel-clt8w | closed | 2026-05-07T16:48:56Z | composite only | 9.60 | 0 | no evidence file path in `br close`; PARTIAL_keep_wrapper |
| flywheel-zhryi | closed | 2026-05-07T16:49:56Z | missing | n/a | 0 | `/tmp/ntm-wire-in-W2-zhryi-2026-05-07-evidence.md`; ISSUE_partial |
| flywheel-ro663 | closed | 2026-05-07T16:53:50Z | missing | n/a | 0 | `/tmp/ntm-wire-in-W2-ro663-2026-05-07-evidence.md`; ISSUE_pick_assign |
| flywheel-i32lt | closed | 2026-05-07T16:55:23Z | missing | n/a | 0 | `/tmp/ntm-wire-in-W2-i32lt-2026-05-07-evidence.md`; PARTIAL_keep_wrapper |
| flywheel-3atlk | closed | 2026-05-07T16:57:20Z | 9/9/9/9 | 9.00 | -316 | no evidence file path in `br close`; dispatch close row present |
| flywheel-rb88g | closed | 2026-05-07T17:01:01Z | 8/8/9/8 | 8.25 | -194 | no evidence file path in `br close`; below 9 composite |
| flywheel-vw6am | closed | 2026-05-07T17:56:33Z | 9/9/9/9 | 9.00 | -243 | `/tmp/ntm-wire-in-W3-vw6am-retry-2026-05-07-evidence.md`; legacy close row missing `pipeline_slug` |
| flywheel-h9gr6 | closed | 2026-05-07T18:04:36Z | 9/9/9/8 | 8.75 | -321 | `/tmp/h9gr6-evidence.txt`; legacy close row missing `pipeline_slug`; below 9 composite |
| flywheel-47ife | closed | 2026-05-07T18:03:02Z | 9/9/9/8 | 8.75 | -232 | `/tmp/flywheel-47ife-evidence.md`; legacy close row missing `pipeline_slug`; below 9 composite |
| flywheel-a8opj | closed | 2026-05-07T18:09:46Z | 9/9/9/9 | 9.00 | -165 | `/tmp/flywheel-a8opj-evidence.md`; legacy close row missing `pipeline_slug` |
| flywheel-gg1mj | closed | 2026-05-07T18:10:36Z | 9/9/9/8 | 8.75 | -151 | `/tmp/gg1mj-evidence.txt`; below 9 composite |
| flywheel-ctd96 | closed | 2026-05-07T18:08:02Z | 9/9/9/9 | 9.00 | -174 | `/tmp/flywheel-ctd96-evidence.md`; legacy close row missing `pipeline_slug` |
| flywheel-v0smn | closed | 2026-05-07T18:14:46Z | 9/9/9/9 | 9.00 | -65 | `/tmp/flywheel-v0smn-evidence.md` |
| flywheel-dj4a3 | closed | 2026-05-07T18:14:40Z | 9/9/9/9 | 9.00 | -81 | `/tmp/flywheel-dj4a3-evidence.md` |
| flywheel-dnv8o | closed | 2026-05-07T18:02:35Z | 9/9/9/9 | 9.00 | -209 | `/tmp/flywheel-dnv8o-evidence.md`; legacy close row missing `pipeline_slug` |
| flywheel-7bs2z | closed | 2026-05-07T18:23:08Z | 9/9/9/9 | 9.00 | -484 | `/tmp/7bs2z-evidence.txt` |
| flywheel-50q5d | closed | 2026-05-07T18:23:44Z | 9/9/9/9 | 9.00 | -215 | `/tmp/flywheel-50q5d-evidence.md` |
| flywheel-43c8f | closed | 2026-05-07T18:23:06Z | 9/9/9/9 | 9.00 | 0 | `/tmp/flywheel-43c8f-evidence.md` |
| flywheel-8y034 | closed | 2026-05-07T18:26:47Z | 9/9/9/9 | 9.00 | -145 | `/tmp/flywheel-8y034-evidence.md` |
| flywheel-ki5s9 | closed | 2026-05-07T18:28:42Z | 9/9/9/9 | 9.00 | -136 | `/tmp/ki5s9-evidence.txt` |
| flywheel-r4hmy | open | pending | n/a | n/a | -157 expected | in flight on pane 4 |
| flywheel-rd8oa | open | blocked | n/a | n/a | -237 expected | blocked on ntm#124 |
| flywheel-sox9n | open | blocked | n/a | n/a | -622 expected | blocked on ntm#124 |
| flywheel-7fcki | open | blocked | n/a | n/a | -559 expected | blocked on ntm#124 |

## Compliance Check

Evidence file references:
- **No**, not all closed beads have evidence files referenced in `br close` or the dispatch close row.
- Missing or weak evidence-file references: `zqiw2`, `sjdj2`, `8bnz8`, `p0wwm`, `zr12c`, `8tp66`, `9gnjl`, `gndhc`, `3atlk`, `rb88g`, `melgv`, `clt8w`.
- Several of these have test details in close text, but the close-gate artifact should prefer an explicit durable evidence path.

Four-lens ≥9.0 composite:
- **No**, not all closed beads hit ≥9.0 composite on recorded per-lens values.
- Below 9.0 composite: `rb88g` (8.25), `h9gr6` (8.75), `47ife` (8.75), `gg1mj` (8.75).
- Missing per-lens scores: `m9aoh`, `zhryi`, `ro663`, `i32lt`.
- Composite-only rows: `melgv` and `clt8w` at 9.6.

Dispatch-log close row sanity:
- `br --all` verifies 34 closed beads.
- Canonical `event:"close"` rows are present for the late W3/W4 rows from `gg1mj` onward, plus `ki5s9`.
- Legacy `event:"closed"` rows exist for older waves.
- Six closed W3 beads have stale legacy close rows without `pipeline_slug`: `vw6am`, `h9gr6`, `47ife`, `dnv8o`, `ctd96`, `a8opj`.

## Close Gate Dry Run

Command:

```bash
.flywheel/scripts/quality-bar-close-gate.sh --plan-slug ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07 --json
```

Result: **FAIL**.

Raw reasons:
- `quality_bar_passed_false`
- `current_phase_not_polish_or_ready:decompose`
- `audit_findings_missing`
- `jeff_score_missing`
- `donella_score_missing`
- `joshua_score_missing`
- `composite_missing`

## r1 Recommendation

**Second polish round needed.**

Specific work before advancing to close gate:
1. Land or explicitly defer `r4hmy`.
2. Keep `rd8oa`, `sox9n`, and `7fcki` deferred behind `flywheel-xyyfg` / ntm#124.
3. Normalize close rows for `vw6am`, `h9gr6`, `47ife`, `dnv8o`, `ctd96`, and `a8opj`.
4. Attach or backfill explicit evidence paths for the closed beads listed above.
5. Revisit the sub-9 composite beads: `rb88g`, `h9gr6`, `47ife`, `gg1mj`.
6. Update `STATE.json` into polish/ready with Three Judges scores only after the above receipts are durable.
