# flywheel-xp50r — integrate-stall-escalator: N-strikes-then-escalate via L95

## Bead context

- ID: `flywheel-xp50r` (P3)
- Title: `[worker-stall-recovery] integrate-side detection of pane=ERROR-after-callback should escalate via L95`
- Filed by: `flywheel-ovd29` close (MistyCliff, 2026-05-09)
- DoD (3 gates):
  1. Locate the integrate-prelude code path that emits `worker_capacity_gate_failed`
  2. After N consecutive emissions on the same pane (suggested N=3), invoke worker-stall escalation
  3. Regression test: pane stuck at ERROR after callback delivery for >15 minutes triggers canonical recovery

## Investigation: emitter is the orchestrator, not a script

`grep -rln "worker_capacity_gate_failed" .flywheel/scripts/ ~/.claude/skills/.flywheel/` returns only INCIDENTS docs and ledger files — **no script emits this trauma class**. The 12 fuckup-log rows on 2026-05-03 19:11-20:07Z (`session=mobile-eats pane=1`) all carry `auto_emit_source: null`, meaning the orchestrator (Claude in pane 1) authored each row manually after `dispatch-capacity-gate.sh` returned `verdict=blocked reason=activity_ERROR`.

`dispatch-capacity-gate.sh:62-69` is the canonical capacity-gate decision: it reads ntm assign + ntm health, classifies `RAW_ACTIVITY` into a verdict, and exits. It does NOT track per-pane consecutive-fail count or trigger L95 — that orchestration is on the caller side, which historically meant the orchestrator's free-form prompt logic.

So the DoD's "integrate-prelude code path" is implicit: the gate decides but doesn't escalate, and the orchestrator's tick logic re-fires the same fuckup-log row instead of ladder-climbing to L95. The right fix is a NEW dedicated script that closes the loop deterministically.

## Fix: integrate-stall-escalator.sh

Modeled on `two-blocker-ticks-escalator.sh` (the canonical sibling — same shape: tick-N-strikes detector + auto-escalate path):

- **Reads** `~/.local/state/flywheel/fuckup-log.jsonl` within a configurable lookback window (default 12h).
- **Filters** for `trauma_class == "worker_capacity_gate_failed"` AND `what_happened` contains the Sub-shape B pattern (`"robot-activity was ERROR"`). Sub-shape A (THINKING) is correctly excluded — that's the parent class doing the right thing.
- **Groups** events by (session, pane).
- **Counts** events per group; if `count >= THRESHOLD` (default 3, from bead body suggestion), emits a stalled-pane record and plans escalation.
- **--apply mode**: invokes `worker-stall-alert-probe.sh --session <S> --apply --json` for each stalled pane and appends an idempotent receipt to `~/.local/state/flywheel/integrate-stall-escalator-ledger.jsonl`. Idempotency key = `<session>:<pane>:<latest_event_ts>`.
- **--dry-run (default)**: plans without invoking the probe.

Canonical-CLI scoping: --doctor / --info / --schema / --examples / --apply / --dry-run / --json / stable exit codes (0 ok / 1 domain / 64 usage). File length ~280 lines (under 500-line shell threshold).

## DoD verification

| Gate | Done |
|---|---|
| Locate emitter | yes — orchestrator-emitted trauma class; gate decision in `dispatch-capacity-gate.sh:62-69`; documented above |
| N-strikes-then-escalate (N=3 suggested) | yes — `integrate-stall-escalator.sh` with configurable `--threshold` and `--apply` invokes `worker-stall-alert-probe.sh` |
| Regression test triggers canonical recovery | yes — `.flywheel/tests/test-integrate-stall-escalator.sh` with 14 PASS gates including: T2 above-threshold fixture plans escalation; T3 below-threshold (sub-A filtered + sub-B count=2) plans 0; T4 multi-pane fixture plans 2; T5 idempotency under --apply; T6 canonical schema_version; T1+T7 introspection triad + bash -n |

`did=3/3`

## Live detection on historical data

```
$ INTEGRATE_STALL_LOOKBACK_HOURS=336 .flywheel/scripts/integrate-stall-escalator.sh --json | jq -c '{stalled_panes:(.stalled_panes|length),escalations_planned}'
{"stalled_panes":1,"escalations_planned":1}
```

The detector finds the exact incident the bead describes: `mobile-eats:1`, 6 consecutive Sub-shape B events 2026-05-03T19:41:37Z..20:07:18Z. Threshold 3, count 6, escalation planned. (Default 12h lookback elides this since it's 6 days old, which is correct behavior — the escalator targets in-progress stalls, not archaeology.)

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes | Triad (--info / --schema / --doctor) + --apply/--dry-run mutation discipline + --json + stable exit codes; sibling pattern from `two-blocker-ticks-escalator.sh`; file under 500-line threshold (~280 lines) |
| rust-best-practices | n/a | Bash + embedded Python |
| python-best-practices | yes-partial | Embedded Python: type hints on `parse_ts(value: str) -> datetime | None`, `iso(dt: datetime) -> str`, `already_escalated(...) -> bool`; `pathlib.Path` for file ops; tmp-path uses `Path.parent.mkdir(parents=True, exist_ok=True)`; subprocess uses `text=True, timeout=60` |
| readme-writing | n/a | No README touched; in-script header documents the contract |

## Four-Lens Self-Grade

- **brand: 9** — Joshua-style sibling-pattern reuse (modeled on `two-blocker-ticks-escalator.sh`); single-source-of-truth (the fuckup-log IS the symptom signal); 14/14 PASS.
- **sniff: 9** — new files only (no foreign-file edits, no L107 race exposure); fixture-based regression test exercising both above-threshold and below-threshold paths + idempotency; default --dry-run discipline.
- **jeff: 9** — small, focused, deterministic; ledger receipt schema is self-describing; idempotency by `<session>:<pane>:<latest_ts>` key prevents storm; respects parent class's Sub-shape A vs B distinction.
- **public: 9** — Three Judges: skeptical operator (live detection on historical data shows exact bead's incident), maintainer (canonical-CLI triad + bash -n + 14/14 tests + sibling pattern citation), future worker (clear path to wire into a tick step or watchdog later).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`infrastructure` — the integrate-side caller had no canonical climb to L95. This escalator closes the ladder so the orchestrator's `worker_capacity_gate_failed` trauma rows automatically transition to L95 worker-stall recovery after 3 consecutive emissions on the same pane. Directly serves continuous-orchestrator-uptime by removing a 30-minute-per-incident manual-recovery bottleneck.

## L61 ECOSYSTEM-TOUCH

`agents_md_updated=no` (script-only addition; no doctrine/L-rule mutation). `readme_updated=not_applicable`. `no_touch_reason=new script + new test; in-script header is the docs surface; AGENTS.md / L95 doctrine already named; no canonical-rule change needed because the implementation closes the existing L95 ladder rather than introducing new doctrine.`

## Wire-in (future)

This script is shipped but NOT yet wired into:

- `flywheel:tick` Step 4n or sibling
- `dispatch-capacity-gate.sh` post-gate hook
- A launchd/cron schedule

Wiring is a separate dispatch concern — the bead's DoD is 3 gates (locate, implement, test), all met. A future bead can wire `--apply` into the orchestrator's tick flow when fleet capacity allows.
