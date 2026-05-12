# Flywheel Incidents — Reversible Operational Changes Log

## 2026-05-09T12:55Z — RESOLVED-UPSTREAM: br create source_repo='.' after create (`br-create-source-repo-dot-after-create`)

**Class:** `br-create-source-repo-dot-after-create`

**Event count:** 6 events 2026-05-03T04:04Z — 2026-05-04T03:28Z (`fuckup-log.jsonl` rows on flywheel substrate `commit_sha=93e6c89`).

**Severity:** low (cosmetic + audit-blast — `br create` stamped `source_repo='.'` instead of the parent directory basename, requiring a SQLite UPDATE + `br sync --flush-only --force` repair before close on each affected bead).

**Sample evidence rows** (all from `~/.local/state/flywheel/fuckup-log.jsonl`):

| ts | session | bead | what_happened |
|---|---|---|---|
| 2026-05-03T04:04:15Z | skillos | skillos-ai8 | `br create` emitted `source_repo=.` during skill authoring; pane1 repaired via `sqlite update` + `br sync --flush-only --force` |
| 2026-05-03T04:47:03Z | skillos | bd-7wuzn | upstream-ntm bead from `/Users/josh/Developer/ntm` again emitted `source_repo='.'`; repaired via `br doctor` + forced sync |
| 2026-05-03T06:14:43Z | skillos | skillos-cmj | `br create` for loop-driver-marker bead — same pattern, same repair |
| 2026-05-03T06:36:27Z | skillos | (pane 4) | same |
| 2026-05-03T06:47:32Z | skillos | (pane 1) | same |
| 2026-05-04T03:28:43Z | skillos | (pane 3) | last event — repair pattern stabilized, then upstream fix landed locally |

**Root cause (upstream):** `br 0.2.4` (installed 2026-05-01) had a bug in `src/cli/commands/create.rs:297-325` setting `source_repo: None`, then `src/storage/sqlite.rs:1621-1624 / 8890-8893` coalesced missing values to `"."`. Schema default at `13425-13427`. Bug class is silent-default-on-missing-field — the create path didn't compute the canonical parent-directory basename of `.beads/`, so `source_repo` defaulted to literal `"."` from storage.

**Resolution (UPSTREAM):** Filed `Dicklesworthstone/beads_rust#273` 2026-05-03 from flywheel pane 3 after 7-axis Meadows validation. Jeffrey closed it 2026-05-03 with fix in `03167479` (test coverage in `c3417779`) — `br create` and `br create --file <md>` now stamp `source_repo` from the canonicalized parent directory basename of `.beads/`; pathological paths keep `source_repo: None` so the legacy storage default remains only for genuinely missing legacy/import rows.

**Local resolution (LOCAL):** Local `br` rebuilt from `beads_rust` HEAD `3c46bea` on 2026-05-04T16:36Z; installed `br --version` is now `0.2.5`. Live probe 2026-05-09 confirms `br --version` reports `br 0.2.5` and the installed repro returns the repo basename instead of `"."`. Latest fuckup-log event for this class is 2026-05-04T03:28:43Z — five days stale at promotion time, all events predate the rebuild.

**Why no new doctrine / L-rule:** This is RESOLVED-UPSTREAM. The fix lives in Jeffrey's `br` source tree; flywheel substrate consumes it via the canonical `cargo install --path . --locked` rebuild documented in `feedback_jeff_substrate_version_drift.md`. There is no flywheel-side rule to add — the trauma class is closed by version bump. The L56 ladder fired because `~/.claude/skills/.flywheel/INCIDENTS.md` had no string match; this entry closes that gap so future ladder runs find coverage and do not re-promote stale events.

**Recurrence prevention:** (a) `br --version` probe on flywheel substrate health checks; (b) memory `feedback_jeff_substrate_version_drift.md` already triggers tick-time upgrade probes; (c) memory `reference_upstream_issues.md` documents the close at the `beads_rust#273 — CLOSED 2026-05-03 — FIXED` section. If the trauma class re-fires post-2026-05-09 against `br 0.2.5+`, that would indicate a fresh regression and warrants a new bead, not a re-promotion of this entry.

**Cross-references:**
- Upstream issue: https://github.com/Dicklesworthstone/beads_rust/issues/273 (CLOSED)
- Memory: `reference_upstream_issues.md` (`## beads_rust#273 — CLOSED 2026-05-03 — FIXED`)
- Memory: `feedback_jeff_substrate_version_drift.md` (META-RULE for this whole class of upstream-fix-landing trauma)
- Bead: `flywheel-lckz` (this promotion-candidate, closed by this INCIDENTS entry)

## 2026-05-07T03:12Z — RULE PROMOTION: Infisical 200-empty doctor fail-quiet (`substrate-doctor-200-empty-fail-quiet`)

**Rule:** Infisical substrate doctors MUST prove read authorization with a
known harmless probe key. A 200 response with `secrets: []` is not PASS; it is
`BLOCKED` because the identity may be authenticated without authorization to
read any useful secret.
