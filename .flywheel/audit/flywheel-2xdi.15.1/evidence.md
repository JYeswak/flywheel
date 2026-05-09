# flywheel-2xdi.15.1 Evidence

Task: `flywheel-2xdi.15.1-bbcb57`
Bead: `flywheel-2xdi.15.1`
Title: [mobile-eats] callback receipt signal stale behind fresh loop marker
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Parent triage evidence: `.flywheel/audit/flywheel-2xdi.15/evidence.md`.

## Disposition

Implemented. The loop-integrity classifier no longer conflates fresh fleet
marker writeback with callback or canonical bridge freshness.

## Acceptance Receipts

| Acceptance | Status | Evidence |
|---|---|---|
| Separate marker / callback / canonical bridge in classification | done | `.flywheel/scripts/gap-hunt-probe.sh` `classify_loop` now emits `marker_fresh`, `callback_receipt_fresh`, `canonical_bridge_fresh` as independent signals (5 legacy + 3 explicit) |
| Bounded validator reporting the three signals separately | done | `.flywheel/scripts/loop-integrity-signals.sh --project mobile-eats --json` (≤5s budget; observed 0.04s) |
| Preserve `flywheel-dwmb.1` (receipt-mirror/full-doctor split) | done | `--info --json` `loop_integrity_signals_owned_by` keeps `receipt_files_written_since_last_tick` owned by `flywheel-dwmb.1`; the new signals are owned by `flywheel-2xdi.15.1` |
| Regression evidence using 2026-05-09 mobile-eats marker-fresh / callback-stale case | done | live probe captured (this file + `regression-2026-05-09.json`) |
| Reference parent triage evidence | done | top of this file |

## Regression Case (2026-05-09)

Probe at 2026-05-09T12:18:58Z, repo /Users/josh/Developer/mobile-eats,
window_seconds=600 (2× the 300s marker interval):

| Signal | ok | Age (sec) | Source |
|---|---|---|---|
| marker_fresh | true | 348 | `~/.flywheel/loops/mobile-eats.json` last_tick=2026-05-09T12:13:10Z |
| callback_receipt_fresh | false | 334,849 | `~/Developer/mobile-eats/.flywheel/dispatch-log.jsonl` no `callback_received_at` newer than 2026-05-05T15:23:39Z |
| canonical_bridge_fresh | false | 334,389 | `~/.local/state/flywheel-loop/last_tick_mobile-eats.json` ts=2026-05-05T15:25:49Z, task_id=20260505T152545Z |

Verdict from the bounded validator alone: `LIMPING`
(2 of 3 explicit signals failing).

Verdict from `gap-hunt-probe.sh` (5 legacy + 3 explicit signals together):
`DEAD`. failed_signals included both the legacy `callback_received_in_last_2_ticks`
and the explicit `callback_receipt_fresh`, plus `canonical_bridge_fresh`,
plus the legacy `ledger_writes_since_last_tick` /
`receipt_files_written_since_last_tick` paths.

The pre-fix classifier could mark this loop as healthy whenever the marker
writeback driver kept `~/.flywheel/loops/mobile-eats.json` fresh (which it
does every 5m via the launchd plist). With this change, the verdict is
explicitly tied to the three independently measurable surfaces, so a fresh
marker can no longer mask stale callbacks or stale canonical bridge state.

## Files Changed

- `.flywheel/scripts/loop-integrity-signals.sh` — new bounded validator,
  default window 2× marker interval, fallback 1800s. Modes: probe, info,
  schema, doctor.
- `.flywheel/scripts/gap-hunt-probe.sh` —
  - `SCRIPT_VERSION` bumped to `2026-05-09.1`
  - `info_json` advertises three new `loop_integrity_signals` plus
    `loop_integrity_signals_owned_by` ownership map
  - `classify_loop` invokes the bounded validator (≤8s subprocess timeout)
    and appends its three signals to the classification

## Verification Commands (re-runnable)

```bash
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/loop-integrity-signals.sh
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh
/Users/josh/Developer/flywheel/.flywheel/scripts/loop-integrity-signals.sh --info --json
/Users/josh/Developer/flywheel/.flywheel/scripts/loop-integrity-signals.sh --schema --json
/Users/josh/Developer/flywheel/.flywheel/scripts/loop-integrity-signals.sh --doctor --json
/Users/josh/Developer/flywheel/.flywheel/scripts/loop-integrity-signals.sh --project mobile-eats --json
/Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh --info --json | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(json.dumps(d.get("loop_integrity_signals"),indent=2))'
```

L112 probe (worker callback):

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/loop-integrity-signals.sh --project mobile-eats --json | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); s=d["signals"]; assert s["marker_fresh"]["ok"] is True; assert s["callback_receipt_fresh"]["ok"] is False; assert s["canonical_bridge_fresh"]["ok"] is False; print("ok")'
```

Expected output: literal `ok` (the 2026-05-09 regression case still
classifies the same way until the upstream callback ingestion / canonical
bridge writeback gets repaired by a separate bead).

## Boundary With flywheel-dwmb.1

This bead owns ingestion + classification of the three freshness surfaces:
marker_fresh, callback_receipt_fresh, canonical_bridge_fresh.

flywheel-dwmb.1 still owns the narrower receipt-mirror / full-doctor split
(the legacy `receipt_files_written_since_last_tick` signal in
`gap-hunt-probe.sh` is preserved as-is). The `loop_integrity_signals_owned_by`
map advertises that boundary.

## Four-Lens Self-Grade

- Brand: 8 — the flywheel finally measures the three load-bearing freshness
  surfaces independently for an active flagship loop instead of letting the
  marker writeback driver hide stale work-completion signals.
- Sniff: 9 — three explicit signals, three measurable paths, one bounded
  subprocess. No silent-zero-hits because each signal returns
  `evidence=missing=<path>` when its file is absent.
- Jeff: 8 — small surface area (one new script + one classifier hook +
  one info-list update), idempotent, dry-run-friendly, schema/info/doctor
  triad respected.
- Public: 8 — a skeptical operator, maintainer, or future worker can rerun
  the probe in 0.04s and see the marker-fresh + callback-stale + bridge-stale
  case. Three Judges check passes (the dispatch-log.jsonl and bridge json
  are inspectable side-by-side with the marker).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-2xdi.15.1 no_bead_reason=none`.
