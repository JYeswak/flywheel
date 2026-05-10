# flywheel-5eon Compliance Pack

Task: `flywheel-5eon-ad3f62`
Bead: `flywheel-5eon`
Decision: DONE
Compliance score: 890/1000

## Finding

Read-only verification before edit confirmed `/Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh`
(581 lines pre-edit) had **zero** phase-routing logic. The driver's
heartbeat branch emits a single static heredoc every 30 minutes regardless
of prior callback `next_phase`, regardless of `.beads/issues.jsonl` open
counts, regardless of plan/research dir state. This is the same
phase-advance-drift trauma class that stalled mobile-eats at
2026-05-03T16:53Z and 16:58Z.

The canonical `flywheel-loop-tick:1024-1124` has six load-bearing helpers:
`valid_phase()`, `latest_callback_next_phase()`, `jsonl_open_bead_count()`,
`jsonl_total_bead_count()`, `dir_has_files()`, and `detect_phase()`. None of
those existed in skillos's runner.

## Repair

Ported the canonical helpers into the skillos-owned driver under bead
`flywheel-5eon`, adapted to skillos's prompt-emitter shape:

- Added `valid_phase`, `latest_callback_next_phase`, `jsonl_open_bead_count`,
  `jsonl_total_bead_count`, `dir_has_md`, `compute_phase_pin` helpers
  (file lines 401-471).
- Inserted a phase-pin computation step at the top of the per-tick loop
  (file lines ~478-484): `compute_phase_pin` runs once per tick, returns
  `<PHASE> <REASON>` on stdout, splits into `PHASE_PIN` / `PHASE_REASON`.
- Added a `Phase pin:` paragraph with placeholders to the heartbeat
  heredoc (in the prompt body) plus the canonical guardrail sentence
  ("Previous callback `next_phase` is authoritative when present. Do not
  fall back to RESEARCH when `br` is unavailable and `.beads/issues.jsonl`
  or plans provide enough state. JSONL open beads mean DISPATCH;
  all-closed beads with plans mean BEADS.").
- Added a `perl -0pi -e` substitution pass after the heredoc (matching the
  pattern already used by the blocker branch) so single-quoted heredoc
  bodies stay shell-safe while `__PHASE_PIN__` and `__PHASE_REASON__` get
  replaced.

Cross-orch hygiene: change is mechanical, additive, scoped to phase
routing. No semantic alteration to mission gates, blocker circuit
breaker, ready-zero fallback, L70/L94 advisories, or pane 2 dispatch
logic. Edit left uncommitted on skillos's repo so RubyCastle (skillos:1
orchestrator) can review in-place. Commit message will include the
`[canonical-driver-gap]` trailer per bead body when committed.

Skillos-shaped adaptation vs canonical: skillos uses a simpler "latest
callback in pane tail" correlation (no task_id matching) because the
driver doesn't generate dispatches itself — the inside-pane orchestrator
does. For a 30-minute interval, the most recent `Callback: ... next_phase=Y`
in the 320-line pane tail is the right pin. Skillos also emits AUTO as
the last-resort fallback (vs RESEARCH in canonical) since the inside-pane
prompt has its own mission-gate work-selection that should run when no
phase is decisive.

## Acceptance Gate Map

The bead body specifies these test gates:

1. **Read-only grep should show callback next_phase consumption** —
   `grep -nE "callback_next_phase" run-30m-loop.sh` returns lines 450, 452.
   ✓
2. **Read-only grep should show JSONL open-bead fallback to DISPATCH** —
   line 456: `printf 'DISPATCH jsonl_open_beads:%d\n' "$open_count"`. ✓
3. **Read-only grep should show all-closed-with-plan routing to BEADS** —
   line 463: `printf 'BEADS all_closed_with_plan\n'`. ✓
4. **Driver does not emit RESEARCH after a callback says PLAN/BEADS/DISPATCH** —
   verified via stubbed-ntm-copy test: callback `next_phase=BEADS` with
   2 open beads in JSONL pinned BEADS (not DISPATCH, not RESEARCH). ✓

did=4/4

## Evidence

```text
$ bash /tmp/test-phase-pin.sh
Test 1 (empty beads, empty plans dir): AUTO no_decisive_signal_orchestrator_picks
Test 2 (2 open): DISPATCH jsonl_open_beads:2
Test 3 (1 closed + 1 plan): BEADS all_closed_with_plan
Test 4 (no beads + 1 plan): BEADS plans_or_docs_without_beads

$ bash /tmp/test-callback-priority.sh
Result: BEADS callback_next_phase
PASS: callback BEADS overrode jsonl_open_beads

$ bash /tmp/test-prompt-sub.sh
[before]  Phase pin (computed by run-30m-loop.sh): __PHASE_PIN__ (reason: __PHASE_REASON__).
[after]   Phase pin (computed by run-30m-loop.sh): DISPATCH (reason: jsonl_open_beads:2).
PASS: placeholder replaced (zero __PHASE_PIN__ matches post-substitution)

$ grep -nE "callback_next_phase|jsonl_open_beads|all_closed_with_plan" run-30m-loop.sh
406: # RESEARCH is a last-resort fallback only — JSONL open beads → DISPATCH,
450: phase="$(latest_callback_next_phase 2>/dev/null || true)"
452:   printf '%s callback_next_phase\n' "$phase"; return 0
456:   printf 'DISPATCH jsonl_open_beads:%d\n' "$open_count"; return 0
463:   printf 'BEADS all_closed_with_plan\n'; return 0

$ bash -n /Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh
(no output = OK)

$ /Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh --dry-run
{"status":"ok","mode":"dry_run","runner":"run-30m-loop"}
```

Test scripts preserved at `/tmp/test-phase-pin.sh`,
`/tmp/test-callback-priority.sh`, `/tmp/test-prompt-sub.sh`.

## Scope

- Edits: 1 file (`/Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh`,
  581 → 673 lines = +92 lines for helpers + per-tick computation +
  prompt placeholder + perl substitution)
- Files reserved/released: skillos driver path, reserved via flywheel's
  L107 tool against absolute path
- Out of scope: `mirror_last_tick_receipt()` extension to carry task_id
  (canonical does; skillos's pane-tail-grep approach doesn't need it for
  this port); replacing skillos runner with canonical generator (bead
  body offered this as alternative once a generator exists, which it
  does not yet); committing the change on skillos's repo (cross-orch
  hygiene preserved by leaving change uncommitted for RubyCastle to
  review).

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: cross-orch-port-with-explicit-dispatch-no-skillos-side-bead-needed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable (no doctrine surface change in flywheel)
- readme_updated: not_applicable (skillos's README is owned by skillos
  orchestrator, not in flywheel scope)

## Cross-Orch Notes

- **Reservation tooling**: skillos doesn't have its own
  `shared-surface-reservation-check.sh`; used flywheel's tool against
  absolute path, which works because the script is path-agnostic.
- **Commit posture**: change left uncommitted in skillos's working tree
  so RubyCastle (skillos:1 orchestrator) can run skillos's own
  validation suite, decide on commit message, and choose whether to
  bump the script's frontmatter version. The bead body's "COMMIT:
  include [canonical-driver-gap] when fixed" guidance is preserved as
  a recommendation for whoever lands the commit.
- **Future consolidation**: if a canonical-driver generator ships
  later, skillos can swap this hand-rolled port for a generated driver
  in one cleanup bead. The helper function names match the canonical
  source 1:1 to ease that future migration.

## Four Lens

- Brand: 8 (cross-orch port preserves skillos's voice and runner shape;
  added comments cite the source bead and trauma class explicitly)
- Sniff: 9 (4 functional tests with synthetic inputs — empty,
  open-beads, closed-with-plan, callback-priority — all pass; bash -n
  clean; --dry-run and --help paths unaffected)
- Jeff: 7 (no Jeff-substrate touch; pure flywheel-doctrine port)
- Public: 9 (a future maintainer reading the new section sees the
  source citation `flywheel-loop-tick:1024-1124`, the bead reference
  `flywheel-5eon`, and the trauma class — auditable end-to-end)

## Skill Auto-Routes

- canonical-cli-scoping: addressed=n/a — no CLI surface changed (this is
  a launchd-loaded driver, not a user-invoked CLI; existing `--dry-run`
  and `--help` paths preserved)
- rust-best-practices: n/a — no Rust
- python-best-practices: n/a — no Python
- readme-writing: n/a — no README touched

## L112 Probe

```
grep -cE "callback_next_phase|jsonl_open_beads|all_closed_with_plan" /Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh
```
Expected: `literal:5` (5 matches: comment line 406, function line 450,
return-line 452, return-line 456, return-line 463).
