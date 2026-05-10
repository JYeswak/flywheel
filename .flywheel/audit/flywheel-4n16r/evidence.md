# flywheel-4n16r Evidence — investigation-verdict for split_flywheel_loop_dispatcher action

Task: `flywheel-4n16r-b18c52`
Bead: `flywheel-4n16r` (P2 OPEN → CLOSED this turn)
Title: [skillos-gap] flywheel-loop doctor returns action=split_flywheel_loop_dispatcher (not ready_for_tick)
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes
flywheel-gibd's surfaced gap by routing the actual refactor work
to a properly-scoped follow-up (`flywheel-cmr7o`) and capturing
the misframing receipt.

## Headline outcome

**Investigation verdict: this was misfiled as a "skillos-gap"
but the trauma is in the SHARED flywheel substrate.** The doctor
returns `action=split_flywheel_loop_dispatcher` for ANY `--repo`
arg because it inspects the same shared binary at
`~/.claude/skills/.flywheel/bin/flywheel-loop` (currently 814 lines vs
500-line monolith threshold). Refactor work routed to
`flywheel-cmr7o` (P3, OPEN). 6-test investigation-verdict
regression in
`tests/4n16r-flywheel-loop-monolith-investigation-verdict.sh`
asserts: trauma condition holds (Test 1), monolith producer at
canonical location (Test 2), action assigner emits the expected
signal (Test 3), live doctor reproduces (Test 4), refactor bead
filed (Test 5), misframing receipt in audit (Test 6). Test 1
INVERTS when refactor lands (file ≤500 lines).

## Misframing receipt

The bead title and body call this a `[skillos-gap]`. The
investigation refutes the framing:

| Claim in bead | Investigation finding |
|---|---|
| "skillos-gap" | The doctor inspects `$FLYWHEEL_LOOP_MONOLITH_PATH` (default `$FLYWHEEL_HOME/bin/flywheel-loop` = `~/.claude/skills/.flywheel/bin/flywheel-loop`), which is the GLOBAL flywheel substrate — same path regardless of `--repo` arg. The same fail signal fires for `--repo /Users/josh/Developer/flywheel`, `--repo /Users/josh/Developer/skillos`, `--repo /Users/josh/Developer/alpsinsurance`, etc. The gap is fleet-wide flywheel substrate, NOT skillos-specific. |
| "Recommended next step: investigate split_flywheel_loop_dispatcher action source in flywheel-loop doctor implementation; resolve in skillos substrate." | Investigation located the source: `~/.claude/skills/.flywheel/lib/misc.d/part-01-auto_respawn_before_tick-to-doctor_check_plist_coverage_drift.sh:283` (function `monolith_size_regression_doctor_json`). Resolution lives in the FLYWHEEL skill substrate (the bin/flywheel-loop file), NOT in skillos. |

Future workers: a doctor signal that returns the same value
across all `--repo` args is a fleet-wide flywheel substrate gap,
not a per-repo gap. The `--repo` arg is for the worker's
git-discoverable context (mission anchor, dispatch log, etc.),
NOT for the doctor's own substrate-self-check.

## Where the action signal comes from

```
~/.claude/skills/.flywheel/lib/misc.d/part-01-auto_respawn_before_tick-to-doctor_check_plist_coverage_drift.sh:283
  monolith_size_regression_doctor_json()
    f = ${FLYWHEEL_LOOP_MONOLITH_PATH:-$FLYWHEEL_HOME/bin/flywheel-loop}
    max = ${FLYWHEEL_LOOP_MONOLITH_MAX_LINES:-500}
    lines = wc -l < $f                    # currently 814
    status = if lines > max then "fail"   # 814 > 500 → fail

~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh:851
  if [[ "$monolith_size_regression_status" == "fail" ]]; then
    status=fail
    action=split_flywheel_loop_dispatcher
  fi
```

The chain is: file-line-count → monolith-status → top-level
action. No skillos involvement; no `--repo`-arg dependency.

## Acceptance disposition

The bead asks "Recommended next step: investigate
split_flywheel_loop_dispatcher action source... resolve in
skillos substrate." The investigation:

1. **Reproduced** the signal — verdict matches the captured baseline
   at `.flywheel/evidence/flywheel-gibd/skillos-doctor-before.json`.
2. **Located** the action source — `monolith_size_regression_doctor_json`
   at part-01 misc.d line 283.
3. **Refuted** the skillos-attribution — the fail is fleet-wide
   flywheel substrate, not skillos.
4. **Routed** the actual refactor work to `flywheel-cmr7o`.

did=4/4 didnt=none gaps=flywheel-cmr7o (the refactor bead;
this is intentional gap surfacing, not a skipped acceptance).

## What this fix ships

### `flywheel-cmr7o` (NEW, P3)

Title: `[refactor] split bin/flywheel-loop dispatcher into lib/
modules (814 → ≤500 lines)`. Concrete DoD:
- `wc -l ~/.claude/skills/.flywheel/bin/flywheel-loop` ≤ 500
- functions extracted to `lib/` per existing patterns
- `flywheel-loop doctor --repo <any> --json | jq -r .action` returns
  `ready_for_tick`
- bash -n + a regression test for one canonical loop entry-point passes

### `tests/4n16r-flywheel-loop-monolith-investigation-verdict.sh` (NEW, 6 PASS)

Investigation-verdict regression. Test 1 asserts the trauma
condition (`bin/flywheel-loop` is currently >500 lines) — when
flywheel-cmr7o lands the refactor, Test 1 will FAIL with a
clear "lifecycle advanced" message. The closing worker at that
phase inverts the assertion (or files a successor bead).

| # | Test | Invariant |
|---|---|---|
| 1 | bin/flywheel-loop is currently >500 lines | trauma condition holds; refactor pending; INVERTS on lifecycle advance |
| 2 | monolith_size_regression_doctor_json producer at canonical location with max=500 | check substrate intact |
| 3 | doctor assigns action=split_flywheel_loop_dispatcher on monolith fail | action chain intact |
| 4 | live doctor returns the expected action (or another with monolith trigger) | runtime reproduction |
| 5 | flywheel-cmr7o follow-up bead exists + names the canonical trauma site | re-routing landed |
| 6 | audit pack documents the skillos-gap misframing receipt + flywheel-substrate scope | misframing surfaced for future workers |

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| regression test | `tests/4n16r-flywheel-loop-monolith-investigation-verdict.sh` | `39f8cda995235eb09789844cc00d41ad941b93b293a3298043a33e3612789b9c` |

## Verification commands (re-runnable)

```bash
# 6 PASS regression
bash /Users/josh/Developer/flywheel/tests/4n16r-flywheel-loop-monolith-investigation-verdict.sh
# expected: SUMMARY pass=6 fail=0 (until cmr7o refactor lands)

# Reproduce the doctor verdict
~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel --json \
  | jq '{status, action, monolith_lines: .monolith_size_regression.lines, monolith_max: .monolith_size_regression.max_lines}'
# expected: status=fail, action=split_flywheel_loop_dispatcher, lines=814, max=500

# Confirm the producer is at the canonical line
grep -n monolith_size_regression_doctor_json \
  ~/.claude/skills/.flywheel/lib/misc.d/part-01-auto_respawn_before_tick-to-doctor_check_plist_coverage_drift.sh
# expected: line 283

# Confirm the action assigner is at the canonical line
grep -nE 'action=split_flywheel_loop_dispatcher' \
  ~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# expected: line 852

# Follow-up refactor bead
br show flywheel-cmr7o | head -3
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/4n16r-flywheel-loop-monolith-investigation-verdict.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=6 fail=0`.

## Boundary

- **No edit to `~/.claude/skills/.flywheel/bin/flywheel-loop`.**
  Refactor is flywheel-cmr7o's scope; this bead investigates and
  re-routes.
- **No edit to the monolith doctor.** Producer + action chain
  are working as designed; the fail signal is INTENDED to push
  toward the refactor.
- **No edit to skillos.** The misfiled framing was wrong;
  investigation re-routes scope to the correct substrate.
- **No reopen of `flywheel-gibd`.** That bead's escape-hatch
  filed this gap correctly; the misframing was inherited from
  flywheel-gibd's surface but doesn't reflect on its close
  quality.
- **No new INCIDENTS or numbered L-rule.** Investigation +
  re-routing is a one-off close, not a recurring pattern.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — substrate test, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=investigation_verdict_close_no_doctrine_surface_mutated_no_l-rule_authored_actual_refactor_routed_to_flywheel-cmr7o_followup_6_test_regression_guards_misframing_correction_plus_lifecycle_invert_signal_via_test_1`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 4/4 acceptance verbatim;
  investigation-verdict + misframing-receipt + re-routing pattern
  is the canonical disposition for "filed under wrong scope" beads.
- **Sniff: 9** — outcome-shaped headline ("misfiled as
  skillos-gap but the trauma is in shared flywheel substrate...
  refactor work routed to flywheel-cmr7o"); concrete file-path +
  line-number citations for the action source chain
  (part-01:283 → part-02:852); 6-test regression with
  invert-on-lifecycle-advance Test 1.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; refuses
  to edit the monolith doctor (working as designed; fail is
  intentional); refuses to edit bin/flywheel-loop (flywheel-cmr7o
  scope); refuses to refile flywheel-gibd or the parent
  skillos-gap framing (closed beads stay closed); files a
  concrete refactor bead instead of leaving the work stranded.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow when cmr7o is dispatched)**: 4
    verification commands confirm verdict + chain + follow-up
    bead in <5s; the cmr7o bead body has all the info needed
    to start the refactor.
  - **maintainer (extending later)**: misframing receipt
    documents the "doctor signal that returns same value
    across all --repo args = fleet-wide gap" heuristic for
    future investigation-verdict beads.
  - **future worker (LLM agent)**: facing another "filed
    under wrong scope" bead, the worker has (a) the
    investigation-verdict + re-route pattern, (b) the
    misframing-receipt section as a copy-paste template, (c)
    the invert-on-lifecycle-advance Test 1 pattern (matches
    the f23ix capture-harness + ksey9 staged-proposal patterns
    from earlier this session).

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-cmr7o
beads_updated=flywheel-4n16r
no_bead_reason=none`.
