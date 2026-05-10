# flywheel-6s5dt Compliance Pack

Task: `flywheel-6s5dt-4f661e`
Bead: `flywheel-6s5dt` (P2)
Decision: DONE — reaper authored, dry-run validated, apply mode closed 20 stale-fired beads
Compliance score: 880/1000

## Final receipt

```
reaper_path=.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh (NEW, 162 lines, executable)
candidates_at_start=37 (open promotion-candidates from 17:11:00Z+ burst)
candidates_at_run=34 (3 closed concurrently between dispatch read and apply)
stale_closed_count=20 (canonical INCIDENTS already covers; auto-closed via reaper apply)
real_kept_count=14 (genuinely uncovered classes; need authoritative L56 promotion)
errored_count=0
final_open_count=14 (verified via post-run dry-run; matches real_kept_count)
files_reserved=.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh
```

## Finding

Per flywheel-iyaym diagnosis: 54 promotion-candidate beads were filed
at 2026-05-09T17:11:17Z when the orch tick ran from a stale worktree
checkout. Of those, 6 were closed via verify-only dispatches earlier
in this session (fre5a/tvv0m/cz38q/x77cu/hujtc/5n8ez), plus 11 others
were closed by sibling workers, leaving 37 open at reaper-dispatch
time.

Reaper iterates each open promotion-candidate bead created since
2026-05-09T17:11:00Z, extracts the trauma class from the title, runs
`grep -Fqi <class> /Users/josh/Developer/flywheel/INCIDENTS.md`
(canonical absolute path — same fix landed in flywheel-iyaym), and:

- If FOUND → bead is stale-fire → close via `br close`
- If MISSING → bead is genuine promotion candidate → keep open

## Repair

Authored `.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh`
(162 lines, bash, executable). Honors canonical-cli-scoping triad:

- `--dry-run` (default) / `--apply` (mutation discipline)
- `--json` (default) / `--no-json` (output discipline)
- `--since` (env-tunable cutoff timestamp)
- Stable schema_version `promotion-candidate-stale-fire-reaper.v1`
- Stable exit codes (0=ok, 2=arg/env, 3=br missing)
- Reads canonical INCIDENTS at absolute path; falls back to skill
  INCIDENTS as defense-in-depth

## Reaper apply-run results

```text
$ bash promotion-candidate-stale-fire-reaper.sh --apply --json
candidates_count: 34       # 3 fewer than dry-run; concurrent closures
stale_closed_count: 20     # auto-closed (canonical covers each class)
real_kept_count: 14        # genuine; need L56 promotion
errored_count: 0
```

Beads auto-closed (20):
flywheel-aaxnj, flywheel-gz8dg, flywheel-0qhlx, flywheel-nsnm1,
flywheel-d1nnc, flywheel-8z2og, flywheel-t5xr9, flywheel-z5tv7,
flywheel-x9sce, flywheel-ulk14, flywheel-iv8rt, flywheel-z9tgh,
flywheel-1p8ah, flywheel-jte7x, flywheel-tp2tf, flywheel-aqxy2,
flywheel-jwm71, flywheel-g8u73, flywheel-8xq32, flywheel-3gc38

## Real promotion candidates kept open (14)

These classes are genuinely uncovered in canonical INCIDENTS and
deserve dedicated L56 promotion (matches the flywheel-s2yd8 +
flywheel-e4tfe pattern from earlier this session):

```text
flywheel-1kdfk → worker-pane-not-waiting-integrate-blocker
flywheel-35exy → worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces
flywheel-dfs9y → worker_capacity_gate_false_block
flywheel-ovd29 → worker_capacity_gate_failed
flywheel-v8yr7 → three_q_surface_gap
flywheel-q1y1d → sister-orch-2-tick-blocker
flywheel-i2k6v → research-health-prelude-fail
flywheel-wwinm → orch-punt-to-next-tick-instead-of-next-actionable
flywheel-wb6oc → mobile-eats-dispatch-health-gate-fail
flywheel-6grpt → integrate_worker_not_waiting
flywheel-l7ssi → file-reservation-conflict
flywheel-95a51 → dcg-worktree-remove-block
flywheel-8io1s → dcg-blocked-temp-cleanup
flywheel-qqv5r → daily-report-missing-integrate-blocker
```

These should be dispatched to workers (CloudyMill or peer) for full
L56 layer-2 INCIDENTS authoring per the flywheel-s2yd8/e4tfe pattern.

## Acceptance Gate Map

| # | Gate | Status |
|---|---|---|
| AG1 | Identify the false-positive beads via br query | ✓ 37 found via `br list --json --limit 0 \| jq filter`; reaper script encapsulates this query as `class_in_incidents` filter |
| AG2 | For each, verify class is canonically covered | ✓ Reaper runs `grep -Fqi <class> $CANONICAL_INCIDENTS` per bead; 20 found covered → close; 14 not found → keep |
| AG3 | Bulk close stale-fires with templated reason linking flywheel-iyaym | ✓ Reaper applied close on 20 beads; close reason includes `[flywheel-iyaym]` reference; each closure logged |
| AG4 | Surface count + sample of real beads where class_in_incidents fails | ✓ 14 real-kept beads enumerated above with bead-id → class mapping; surfaced for orch dispatch |

did=4/4

## Evidence

```text
$ # Reaper script bash-n syntax pass:
$ bash -n .flywheel/scripts/promotion-candidate-stale-fire-reaper.sh && echo OK
OK

$ # Pre-apply: 37 open promotion-candidates from burst window
$ br list --json --limit 0 | jq '
    [.issues[] | select(.created_at >= "2026-05-09T17:11:00Z")
                 | select(.title | startswith("[promotion-candidate]"))
                 | select(.status != "closed")] | length'
37

$ # Apply mode result:
$ bash .flywheel/scripts/promotion-candidate-stale-fire-reaper.sh --apply --json | tail -1 | jq '.stale_closed_count, .real_kept_count'
20
14

$ # Post-apply verification (final dry-run):
$ bash .flywheel/scripts/promotion-candidate-stale-fire-reaper.sh --dry-run --json | jq '.candidates_count, .real_kept_count'
14
14
# All 14 remaining are genuinely uncovered (real_kept = candidates_count, no stale left)
```

## Scope

- Edits: 1 source file + 2 audit-dir files + 20 bead-status mutations
  - `.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh`
    (NEW, 162 lines, executable, bash-n-pass)
  - `.flywheel/audit/flywheel-6s5dt/reaper-final-state.json` (post-apply state)
  - `.flywheel/audit/flywheel-6s5dt/compliance-pack.md` (this file)
  - 20 promotion-candidate beads closed via `br close` (each with
    standard close-receipt; no doctrine modifications)
- Files reserved/released: 1 (reaper script path; released before callback)
- Out of scope:
  - L56 promotion of the 14 real-kept classes (orch follow-up; should
    spawn 14 workers OR a batch dispatcher; per AG4 they're surfaced
    as the next actionable batch)
  - Automating the reaper as a periodic cron/launchd job (future
    refinement; current invocation is operator-driven)
  - Detecting orch-running-from-worktree at tick time (separate
    fleet-doctor concern from flywheel-iyaym)

## L52 / L80 / L120 / L61

- DIDNT: L56 authoring for the 14 real classes (out of scope; orch
  routes them per AG4 surface)
- GAPS: 14 genuine promotion candidates need follow-up dispatches
- beads_filed: none
- beads_updated: 20 (the closed bead status changes)
- no_bead_reason: reaper-shipped-and-applied-14-real-classes-orch-routed-via-flywheel_orch_action_required
- br_close_executed: yes (after this pack, before callback) — and
  20 OTHER beads were closed by the reaper apply
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: dispatch-cloudymill-or-peer-on-14-real-promotion-candidates-listed-in-compliance-pack-each-needs-L56-layer-2-INCIDENTS-section-authored-per-flywheel-s2yd8-and-e4tfe-pattern

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — reaper honors triad
  (--dry-run/--apply, --json, stable exit codes, env-tunable
  cutoff); pattern matches established session reaper-script
  shape
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a (could be added — reaper has `--help` topic
  but not yet a dedicated README)

## Four Lens

- Brand: 9 (data-decides discipline applied — reaper enumerates
  37 candidates, classifies each, applies closures only when
  canonical covers; 14 real-kept surfaced for orch routing rather
  than blindly closing all)
- Sniff: 9 (every claim grounded: 37 → 20 stale + 14 real + 0
  error; bash-n syntax check; post-apply verification dry-run
  confirms 14 remain; reaper-final-state.json saved as durable
  evidence)
- Jeff: 8 (no Jeffrey-substrate touch; reaper uses `br close`
  canonically; trauma class universe is flywheel-internal
  doctrine cleanup)
- Public: 9 (Three-Judges check: operator can re-run the reaper
  in dry-run and see consistent state; maintainer 6 months out
  sees the script + comments + flywheel-iyaym reference and
  understands the burst-cleanup motion; future worker on real
  classes has the 14 bead IDs already enumerated)

## L112 Probe

```
bash /Users/josh/Developer/flywheel/.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh --dry-run --json 2>/dev/null \
  | jq -r '.stale_closed_count'
```
Expected: `literal:0` (post-apply, all stale-fires closed; only 14
real candidates remain, none of which are stale).
