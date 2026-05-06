# Beads Sync Recovery Research - 2026-05-06

Task: `beads-sync-recovery-research-2026-05-06` for `flywheel-1eg0k`.

Scope: plan-space research only. I did not run `br sync`, did not mutate
`.beads/beads.db`, and did not append recovered issue rows to JSONL. The only
planned JSONL write is the research marker required by the dispatch.

## DB vs JSONL Diff

Dispatch snapshot: `br sync --flush-only` previously refused export because the
DB had 1053-1055 issues, JSONL had 1024 unique issues, and export would lose:

`flywheel-6uxz`, `flywheel-e2dj`, `flywheel-f6p5`, `flywheel-i2ad`,
`flywheel-l82y`, `flywheel-nxuw`, `flywheel-p2yj`, `flywheel-x4ly`.

Live probe on 2026-05-06 found the eight-ID premise is stale:

| Check | Result |
|---|---:|
| DB issues | 1178 |
| JSONL unique issue IDs | 1272 |
| Named dispatch IDs present in DB | 8 / 8 |
| Named dispatch IDs present in JSONL | 8 / 8 |
| Dependencies touching named IDs | 0 |
| Labels/comments/events for named IDs | 0 / 0 / 0 |
| DB SHA-256 before report edits | `12fda755da6f6375bd3170419ca7c3875bcc17efd8076612b35258f8e1cbeab0` |
| JSONL SHA-256 before research marker | `590c8d3ebe3422c23a5b6b76f71336b5abc9603f34d33a250e788820231b8c61` |

Named-ID parity table:

| ID | DB rows | JSONL line | Title |
|---|---:|---:|---|
| `flywheel-6uxz` | 1 | 444 | `[promotion-candidate] repeat-gate-deny-readiness (4 events in 7d)` |
| `flywheel-e2dj` | 1 | 630 | `[promotion-candidate] research-health-prelude-fail (4 events in 7d)` |
| `flywheel-f6p5` | 1 | 664 | `[promotion-candidate] agent-fighting-gate (5 events in 7d)` |
| `flywheel-i2ad` | 1 | 737 | `[promotion-candidate] agent-mail-reservation-timeout (3 events in 7d)` |
| `flywheel-l82y` | 1 | 811 | `[promotion-candidate] jeff-corpus-storage-red-integrate-blocker (3 events in 7d)` |
| `flywheel-nxuw` | 1 | 866 | `[promotion-candidate] jeff-watcher-false-positive-on-gh-auth-fail (3 events in 7d)` |
| `flywheel-p2yj` | 1 | 901 | `[promotion-candidate] file-reservation-conflict (3 events in 7d)` |
| `flywheel-x4ly` | 1 | 1126 | `[promotion-candidate] ntm-pane-unhealthy (3 events in 7d)` |

## Provenance For Each Missing ID

These are no longer missing in live JSONL, but their provenance is clear:

| ID | Provenance |
|---|---|
| `flywheel-6uxz` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `repeat-gate-deny-readiness`; DB `created_by=josh`, `created_at=2026-05-03T20:33:33.756138+00:00`, content hash `ea4ce8fe8936ef6fa4fdd945629a7d378dc068300a42811ba6bebd2d6811c705`. |
| `flywheel-e2dj` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `research-health-prelude-fail`; DB `created_by=josh`, `created_at=2026-05-03T20:33:34.029857+00:00`, content hash `4f714fa33dd5d980a56d0dd490a43c000e574d5334a8b59c01c5f1135cd38cca`. |
| `flywheel-f6p5` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `agent-fighting-gate`; `.flywheel/dispatch-log.jsonl:1180` and `.flywheel/prompts/flywheel-tick-20260504T213228Z.md:21` show promotion-time `jq: Cannot index array with string "issues"` errors around auto-flush. |
| `flywheel-i2ad` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `agent-mail-reservation-timeout`; `.flywheel/prompts/flywheel-tick-20260504T074229Z.md:21` records creation. |
| `flywheel-l82y` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `jeff-corpus-storage-red-integrate-blocker`; `.flywheel/prompts/flywheel-tick-20260504T015853Z.md:21` records creation. |
| `flywheel-nxuw` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `jeff-watcher-false-positive-on-gh-auth-fail`; present in DB and JSONL with no dependency/comment/label/event rows. |
| `flywheel-p2yj` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `file-reservation-conflict`; `.flywheel/prompts/flywheel-tick-20260504T064003Z.md:21` records creation. |
| `flywheel-x4ly` | Auto-created by `doctrine-ladder-promote.sh` per L56 for `ntm-pane-unhealthy`; `.flywheel/dispatch-log.jsonl:1374` and `.flywheel/prompts/flywheel-tick-20260505T002205Z.md:21` show promotion-time `jq` errors. |

## Why JSONL Doesn't Have Them

Current JSONL does have all eight rows. The correct current statement is:
JSONL lacked them, or the export guard believed it would lose them, during the
2026-05-05 stale snapshot; that condition is no longer true for these IDs.

Most likely chain from local evidence:

1. L56 promotion beads were created in/around DB-backed Beads operations.
2. The JSONL export path encountered stale-store/corruption context and refused
   loss-prone `br sync --flush-only` exports.
3. Repeated repair/rebuild artifacts exist under `.beads/` and root-level
   `.beads.bak*` / `.beads.failed*`; later recovery appears to have restored
   these eight rows into JSONL before this research dispatch.
4. Because the eight rows now exist in both stores, appending them again would
   create duplicate JSONL identities rather than recover missing data.

## Sister-Issue Check

Broader DB/JSONL parity is still not clean:

| Direction | Count | Sample |
|---|---:|---|
| DB-only IDs | 1 | `flywheel-e8lft` |
| JSONL-only IDs | 95 | `flywheel-audit-ntm-send-no-cass-check-autonomous-callsites-2026-05-06`, `flywheel-caam-recovery-verification-probe-2026-05-06`, `flywheel-caam-rotation-test-deferred-pending-oauth-2026-05-06`, ... |

The DB-only sample is `flywheel-e8lft` (`br-db-wedge-repair`, closed,
P0, created `2026-05-06T00:08:22.332326+00:00`). JSONL has a related
reference in `flywheel-br-db-wedge-recurrent-aa39`, but not the exact ID.

I did not file a new bead because `flywheel-1eg0k` remains open and already
covers Beads DB/JSONL non-lossy convergence; this report records the sister
mismatch for Joshua's option decision.

## Prior-Attempt RCA

Relevant durable rows:

- fuckup-log line 1104, `2026-05-05T10:24:43Z`: high-severity
  `beads-sync-stale-db-jsonl-export-refusal`, DB 1054 vs JSONL 1024, same
  eight would-lost IDs.
- fuckup-log line 1108, `2026-05-05T10:34:00Z`: same high-severity class after
  additional closeout work; `br sync --flush-only` still refused.
- fuckup-log line 1235, `2026-05-05T14:07:41Z`: `flywheel-useh` updated the
  parent note, then `br sync --flush-only --json` still refused stale export.

RCA: prior attempts treated normal Beads close/update plus `flush-only` as the
convergence path. The guard correctly refused because exporting a stale DB over
JSONL would have been lossy. The fix was not to force export; it needed an
independent set reconciliation: enumerate DB-only and JSONL-only IDs, prove
provenance per ID, then choose a non-lossy merge/import/delete policy.

Contributing substrate evidence:

- `.beads/` contains multiple `beads.db.bak.*`, `beads.db.aside.*`,
  `beads.db.malformed*`, `beads.db-wal.aside.*`, and `issues.jsonl.bak.*`
  artifacts.
- Root has `.beads.bak.v2a1-D-20260504T182358Z` and
  `.beads.failed.flywheel14w.20260501T161900Z`, indicating recent repair paths.
- Promotion prompts around `flywheel-f6p5` and `flywheel-x4ly` show `jq` errors
  while doctrine-ladder promotion continued, suggesting partial side effects
  across Beads/JSON surfaces.

## Recovery Options Matrix

| Option | Action | Current applicability | Data-loss risk | Notes |
|---|---|---|---|---|
| A | Append recovered JSONL rows for the eight dispatch IDs from DB rows. | Not applicable now. | Medium if run now. | All eight are already in JSONL; appending would duplicate identities. |
| B | Delete the eight DB rows because older JSONL lacked them. | Reject. | High. | They are real L56 promotion candidates with provenance, and JSONL now has them. |
| C | Build a full verified reconciler for all DB-only and JSONL-only IDs. | Good follow-up. | Low if dry-run first. | Should handle current `flywheel-e8lft` DB-only and 95 JSONL-only IDs under lock/backup. |
| D | No-op for the eight IDs; preserve `flywheel-1eg0k` open pending Joshua decision on broader reconcile. | Best current option. | None. | Matches live evidence and avoids stale-snapshot recovery writes. |

## Recommended Option With Joshua-Decision-Needed Flag

Recommended option: `D`.

`joshua_decision_needed=true`.

Reason: the named eight rows are already present in both stores, so the
original recovery write would now be wrong. Joshua should choose whether the
next bead closes `flywheel-1eg0k` as stale-resolved after independent parity
verification, or expands it into a full reconciler for the remaining
`1 DB-only / 95 JSONL-only` sister mismatch.

## Dry-Run Merge Artifact Path

Artifact: `/tmp/beads-sync-recovery-dry-run-2026-05-06.sql`.

The artifact is intentionally read-only SQL. It verifies the eight DB rows and
related-table counts, but does not execute any recovery mutation. JSONL
presence was verified separately with `jq` because SQLite cannot read the live
JSONL file without an import table.

Socraticode preflight: 6 queries, 60 indexed chunks observed across
`/Users/josh/Developer/beads_rust` and `/Users/josh/Developer/flywheel`.
