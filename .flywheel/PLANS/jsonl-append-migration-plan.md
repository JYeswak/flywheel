# JSONL Append Migration Plan

Source audit: `.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/07-TRAUMA-CLASS-AUDIT-2026-05-05.md:50-72`.

Shared primitive: `/Users/josh/.local/share/flywheel-watchers/lib/jsonl-append.sh`.

Scope: identify downstream patches only. This plan intentionally does not apply
the C1 site migrations; B56-FIX-03/05/06 and siblings own those edits.

| finding | target lines | owner bead | proposed patch | patch line count |
|---|---|---|---|---:|
| C1-01 | `/Users/josh/.local/bin/flywheel-watchers.bak.20260505T005651Z:69`, `:253` | B56-FIX-01 | Quarantine/retire backup; if retained, source `jsonl-append.sh` and replace registry/ledger appends with `fw_jsonl_append_validated`. | 3 |
| C1-02 | `.flywheel/scripts/idle-pane-auto-dispatch.sh:234`, `:241` | B56-FIX-03 | Source shared primitive near helper imports; replace dispatch-log JSONL append with validated append and keep cooldown marker write separate. | 4 |
| C1-03 | `/tmp/.disabled-watchers/idle-pane-auto-dispatch.sh:57`, `:60` | B56-FIX-04 | Parked script should remain disabled; if preserved as fixture, annotate direct appends as vulnerable and point to shared primitive. | 2 |
| C1-04 | `/tmp/.disabled-watchers/idle-pane-auto-dispatch-generic.sh:127`, `:130` | B56-FIX-04 | Same parked-script treatment as C1-03; migrate only if resurrected into live source. | 2 |
| C1-05 | `/tmp/.disabled-watchers/storage-cleared-watcher.sh:58`, `:59` | B56-FIX-04 | Replace watcher log and cross-orch JSONL direct appends with `fw_jsonl_append_validated` if the script becomes live again. | 3 |
| C1-06 | `/tmp/.disabled-watchers/jeff-corpus-watcher.sh:11`, `:12` | B56-FIX-04 | Replace local log and dispatch-log direct appends with shared primitive, or delete parked copy. | 3 |
| C1-07 | `.flywheel/scripts/leverage-ceiling-probe.sh:267` | B56-FIX-02 | Source shared primitive and route `append_ledger` through `fw_jsonl_append_validated`; reconcile `read_only:true` separately. | 4 |
| C1-08 | `.flywheel/scripts/headless-browser-reap.sh:137`, `:138` | B56-FIX-02 | Guard dry-run history writes, then use shared primitive for applied history rows. | 5 |
| C1-09 | `.flywheel/scripts/frozen-pane-detector-fleet.sh:67` | B56-FIX-02 | Replace `event_append` internals with shared primitive while preserving event schema. | 3 |
| C1-10 | `.flywheel/scripts/frozen-pane-detector.sh:459`, `:485`, `:501` | B56-FIX-05 | Source shared primitive once; migrate strike, recovery, and metrics JSONL writes together. | 7 |
| C1-11 | `.flywheel/scripts/ntm-fleet-health.sh:48`, `:66`, `:93` | B56-FIX-06 | Replace health log/error/summary appends with shared primitive and fail closed on append rc 2/3. | 7 |
| C1-12 | `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh:20`, `:25` | B56-FIX-02 | Source shared primitive and replace success/error receipt mirror appends. | 4 |
| C1-13 | `.flywheel/scripts/storage-probe.sh:254`, `:255` | B56-FIX-02 | Use shared primitive for history rows; keep rewrite/compaction path separate because it is not append-only. | 4 |
| C1-14 | `/Users/josh/.claude/skills/.flywheel/scripts/kill-recover-drill.sh:106` | B56-FIX-10 | Source shared primitive from skill runtime or vendor a skill-local wrapper; replace drill logger append. | 4 |

Downstream patch template:

```bash
# shellcheck source=/dev/null
source "$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh"
fw_jsonl_append_validated "$ledger_path" "$row_json"
```

Exit-code routing for migrations:

- `1`: row construction/schema failure; domain fail.
- `2`: write/lock/fsync failure; transient write failure.
- `3`: readback mismatch; treat as critical substrate corruption.
