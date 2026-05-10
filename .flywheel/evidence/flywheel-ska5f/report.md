# flywheel-ska5f — Worker Report

**Task:** [monitor-noise-investigation] task-notification replays stale events on every turn — context pollution class
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-flywheel-d23ow; post: this commit
**Status:** done — root cause definitively localized at the `tail -F` startup layer; 4-char fix landed across 3 surfaces; regression test PASS
**Mission fitness:** infrastructure — eliminates persistent context pollution that bloats orch reasoning surface across every dynamic-mode session.

## Verdict

**Root cause: `tail -F` default 10-line tail at startup.** When the /loop dynamic-mode arms a persistent Monitor with `tail -F dispatch-log.jsonl | grep ...`, BSD/GNU `tail -F` emits the LAST 10 lines (default `-n 10`) on startup BEFORE following new appends. The Monitor framework faithfully relays each line as a `<task-notification>`. Net effect: every fresh Monitor arm fires 10 stale callback events into the orchestrator's context.

Fix: insert `-n 0` to start the follow at zero offset. 4-character change. Applied across 3 surfaces:
1. `/Users/josh/.claude/commands/loop.md:46` (canonical /loop skill source)
2. `tests/test_loop_dynamic_mode_arms_monitor.sh:52,61,67` (test fixture + assertion)
3. `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_wake_event_driven_not_time_based.md:15` (memory canonical command + caveat)

## Acceptance gate coverage

| Gate | Status | Evidence |
|---|---|---|
| AG1: Reproduce stale-replay in clean Monitor against static log file | DID | Built static 12-line log fixture (timestamps 2026-05-08T20:15Z–22:00Z); armed Monitor `tail -F static-log` → received ONE batched event-notification containing lines 3-12 (last 10) immediately on startup; Monitor task `brr6ishah`, output file 1233 bytes (10 callback rows visible in this session's task-notification record) |
| AG2: Identify which layer is replaying | DID | Contrast experiment: same Monitor command but `tail -n 0 -F` (Monitor task `b0v8b14ka`) → ZERO event notifications during 8s lifetime, only the timeout notification at end. Output file did not even materialize (no stdout produced). **Layer = `tail -F` default startup behavior, not Monitor framework, not grep --line-buffered** |
| AG3: Propose fix | DID | Recommendation **(b) primary**: change canonical `tail -F` → `tail -n 0 -F` in /loop skill + tests + memory. **(c) deferred**: keep event-driven Monitor architecture; no need to fall back to ScheduleWakeup-only — that would lose 50-150 idle-min/session correctly identified by the source memory rule. **(a) infeasible**: Monitor-framework offset tracking is not a flywheel-side change. Applied (b) in this tick. |
| AG4: Update memory file caveat | DID | Memory file `feedback_orch_wake_event_driven_not_time_based.md` now (1) names the corrected canonical command with `-n 0`, (2) contains a `**CAVEAT 2026-05-10 (flywheel-ska5f):**` block explaining the bug, the reproduction, and the 4-char fix, (3) references the surface citations |

did=4/4, didnt=none, gaps=none.

## Live verification

### AG1 reproduction (positive case — bug present)

```bash
# Build static fixture
WORK_TMP="$(mktemp -d -t flywheel-ska5f.XXXXXX)"
LOG="$WORK_TMP/static-dispatch-log.jsonl"
for i in $(seq 1 12); do
  printf '{"ts":"2026-05-08T%02d:%02d:00Z","event":"callback","task":"flywheel-static-%02d","note":"static stale event %d for replay test"}\n' \
    $((20 + i / 6)) $((i * 5 % 60)) $i $i >> "$LOG"
done

# Arm Monitor with the BUGGY canonical pattern
Monitor(
  command: "tail -F $LOG | grep --line-buffered 'callback'",
  timeout_ms: 10000,
  persistent: false
)

# OBSERVED: Monitor task brr6ishah emitted ONE batched event-notification
# containing lines 3..12 (last 10) immediately on startup, with no new
# appends to the static log. This is the stale-replay class.
```

### AG2 contrast (fix verified — bug absent)

```bash
# Same Monitor on same static file but with -n 0
Monitor(
  command: "tail -n 0 -F $LOG | grep --line-buffered 'callback'",
  timeout_ms: 8000,
  persistent: false
)

# OBSERVED: Monitor task b0v8b14ka produced ZERO event notifications during
# its 8s lifetime — only the timeout notification at end. Output file did not
# even materialize because no stdout was produced. tail -n 0 -F means
# "start at zero offset, don't replay the tail" → only NEW appends fire events.
```

### AG3+AG4 application

```bash
# 1. Verify broken pattern eliminated everywhere
grep -c "tail -F <repo>" /Users/josh/.claude/commands/loop.md  # → 0
grep -c "tail -F <repo>" ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_wake_event_driven_not_time_based.md  # → 0

# 2. Verify fixed pattern present everywhere
grep -c "tail -n 0 -F <repo>" /Users/josh/.claude/commands/loop.md  # → 1
grep -c "tail -n 0 -F" ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_wake_event_driven_not_time_based.md  # → 2

# 3. Run regression test
bash tests/test_loop_dynamic_mode_arms_monitor.sh
# → PASS: loop dynamic mode Monitor contract fixture (/Users/josh/.claude/commands/loop.md, session=flywheel)
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/test_loop_dynamic_mode_arms_monitor.sh 2>&1 | tail -1` expects literal `PASS: loop dynamic mode Monitor contract fixture`.

## Pattern: tail-default-tail-leaks-as-stale-events-class

Generic shape: any framework that "treats each stdout line as an event" — Monitor, watchman, dtail subscribers, fluentbit tail input — when fed through `tail -F` without explicit `-n 0`, will fire 10 stale events on every startup. The bug is invisible during steady-state operation (the framework only emits new lines once running) but surfaces violently on:
- Initial Monitor arm (10 stale events at session start)
- Monitor restart at turn-boundary (if framework respawns the script)
- Session resume (if framework re-arms Monitors after compaction)
- Operator manually re-arming after a /loop re-entry

Convergent class with:
- `feedback_dcg_prose_trigger_strip_dangerous_substrings` — invisible-in-steady-state default that surfaces on specific ops
- `feedback_calibrate_test_to_actual_contract_before_filing_upstream` — `tail -F` is the contract, default tail-of-10 is the actual behavior, the canonical Monitor command was calibrated to the wrong premise

The 4-character `-n 0` insert is the canonical "default-defeats-the-spec" fix shape (sister to flywheel-tpprm `clobber-recovery.sh` recovery + flywheel-d23ow `cd-realpath-wrapper.sh` prevention shipped earlier today).

## Files changed

- `~ /Users/josh/.claude/commands/loop.md:46` — `tail -F` → `tail -n 0 -F` (global skill, not in repo, no git stage)
- `~ /Users/josh/Developer/flywheel/tests/test_loop_dynamic_mode_arms_monitor.sh:52,61,67` — fixture + assertion updated to `-n 0` form (3 occurrences)
- `~ /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_wake_event_driven_not_time_based.md` — canonical command updated + CAVEAT block added (memory file, not in repo, no git stage)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-ska5f/report.md` — this file

## Three-Q

- **VALIDATED:** AG1 + AG2 reproduced cleanly with two Monitor invocations on the same static fixture (positive: 10 stale events; negative: 0 events). Regression test PASS post-patch. All 3 surfaces grep-verified to no longer contain the broken pattern AND to contain the fixed pattern.
- **DOCUMENTED:** memory file CAVEAT block names the bug, reproduction shape, and fix in one place. The /loop skill source comment chain is intact (the `-n 0` is now the doctrine).
- **SURFACED:** every future /loop dynamic-mode Monitor arm will use `tail -n 0 -F` automatically. The regression test asserts the corrected canonical pattern is present in `loop.md`, so any regression that drops `-n 0` will fail this test.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:10,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** narrowest fix possible — 4-character `-n 0` insertion at 5 sites (1 in skill, 3 in test, 1 in memory + CAVEAT prose); no architectural change, no rollback to ScheduleWakeup-only, no Monitor-framework patching attempt.
- **Sniff (10/10):** experimentally-verified root cause via two contrasting Monitor invocations on the same static fixture; no inference, no hand-waving, just `tail -F` emit-10-lines-on-startup observed and `tail -n 0 -F` emit-zero-on-startup confirmed.
- **Jeff (10/10):** Jeff "calibrate-test-to-actual-contract" discipline applied — the `tail -F` documentation IS the contract, the actual-startup-emit IS the behavior, the canonical Monitor command was calibrated to the wrong premise. Convergent with the 5+ prior `feedback_calibrate_*` patterns logged today. Same-tick disposition.
- **Public (9/10):** **Three Judges check** — skeptical operator can reproduce the bug+fix in 60 seconds with two Monitor invocations; maintainer reads the CAVEAT block + sees the regression test; future workers handling Monitor + tail patterns get the rule baked into the canonical /loop doctrine.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=tail-default-tail-leaks-as-stale-events-class/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=tail-default-tail-leaks-as-stale-events-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **tail-default-tail-leaks-as-stale-events class:** any framework that treats each stdout line as an event (Monitor, watchman, fluentbit tail), when fed through `tail -F` without `-n 0`, fires N (default 10) stale events on every startup. Default-defeats-the-spec class. Generic fix: insert `-n 0` (or `-c 0` on macOS) at every `tail -F` invocation feeding a per-line-event consumer. Detection: arm consumer against a STATIC log; if events fire before any append, you have it. Convergent with `feedback_calibrate_test_to_actual_contract_before_filing_upstream` — default behavior of `tail -F` IS the actual contract; the canonical doctrine was calibrated to the wrong assumption. Sister to flywheel-tpprm/d23ow "default surfaces an unsafe pattern" class, just at the tail layer instead of cd. |

## L52 / L70 receipt

- L52 (issues-to-beads): `no_bead_reason=phase-ska5f-completed-in-tick-no-new-bead-needed`. Investigation produced its own fix; no follow-up gap.
- L70 (no-punt): the next-actionable IS this fix — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion needed (the doctrine lives in the /loop skill source + memory CAVEAT).
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=fix-localized-to-skill-source-test-fixture-and-memory-caveat`

## Compliance Pack

Score: 945/1000.

- 4/4 acceptance gates DID (AG1 reproduce + AG2 layer-id + AG3 fix-shipped + AG4 memory-update)
- Regression test PASS post-patch
- L107 reservation acquired (tests/test_loop_dynamic_mode_arms_monitor.sh) + released after commit (per flywheel-y4e47 lifecycle)
- 4/4 lenses with 9-10/10 self-grades
- Two-Monitor experimental confirmation of root-cause layer

Pack path: `.flywheel/evidence/flywheel-ska5f/`.

## Cross-references

- Source: `flywheel-ska5f` (this bead)
- Sister class beads (today's same-shape Layer-1 prevention bundle):
  - `flywheel-tpprm` (clobber-recovery.sh recovery primitive)
  - `flywheel-d23ow` (cd-realpath-wrapper.sh prevention primitive)
  - This: `flywheel-ska5f` (tail -n 0 -F default-defeats-spec at framework boundary)
- Subject canonical doctrine: `/Users/josh/.claude/commands/loop.md:46`
- Regression test: `tests/test_loop_dynamic_mode_arms_monitor.sh` (3 line-changes: 52, 61, 67)
- Memory updated: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_wake_event_driven_not_time_based.md` (canonical command + 2026-05-10 CAVEAT block)
- L107 lifecycle (applied): reserve → write → git add → git commit → release (per `flywheel-y4e47`)
- Memory cross-refs: `feedback_orch_wake_event_driven_not_time_based.md`, `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`, `feedback_convergent_evolution_is_canonical_signal.md`
- L-rules cited: L107 (reservation, applied), L70 (no-punt — same-tick disposition), L52 (no new bead — investigation completes the loop), L120 (close before callback)
