# Audit pack: flywheel-8ht5f

**Bead:** flywheel-8ht5f — [stale-in-progress-reaper] launchd-driven self-org closure of in_progress beads with zero activity 7+ days
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T05:12:02Z
**Disposition:** DONE — 7/7 acceptance gates landed; inaugural-candidates pinned for Joshua review; launchctl load gated on Joshua sign-off.

## Pre-existing inventory + gap analysis

The reaper script already existed at `.flywheel/scripts/stale-in-progress-reaper.sh`
(May 4 build, 344 lines Python-in-shell, 16/16 tests passing with classifier
that uses commit/callback/assignee signals). This bead's deliverable is the
**gaps**:

| Pre-existing | Status |
|--------------|--------|
| Script with --info / --schema / --examples / --doctor / --apply | ✓ |
| Tests in `tests/stale-in-progress-reaper.sh` | ✓ 16/16 PASS |
| Ledger at `~/.local/state/flywheel/stale-reaper-ledger.jsonl` | ✓ |
| ACTIVE / RECENTLY_TOUCHED / STALE classification | ✓ |

| Gap (this bead's deliverable) | Status |
|-------------------------------|--------|
| Label-based carve-outs (upstream-tracker / cross-orch-active / joshua-gated / defer-gated) | ✓ added |
| Schema file at `.flywheel/validation-schema/v1/stale-reaper.v1.schema.json` | ✓ new |
| Launchd plist at `.flywheel/launchd/ai.zeststream.flywheel-stale-reaper.plist` | ✓ new |
| Carve-out tests | ✓ new (`tests/stale-in-progress-reaper-carve-out.sh` 10/10) |
| Inaugural manual run + report for Joshua review | ✓ new |
| Doctrine doc | ✓ new |
| Joshua-gate before launchctl load | ✓ deferred (NOT loaded) |

## Acceptance gates

### AG1 — Reaper script ✓ (extended, not authored from scratch)

Pre-existing script extended with:

1. New constant `DEFAULT_CARVE_OUT_LABELS = (upstream-tracker, cross-orch-active, joshua-gated, defer-gated)`.
2. Config option `cfg.carve_out_labels` (overridable via `STALE_REAPER_CARVE_OUTS` env or `--carve-out=` flag).
3. New helper `fetch_label_map(cfg)` — single sqlite3 query against
   `.beads/beads.db` `labels` table, returns `{bead_id: [label, ...]}`.
4. `classify(cfg, row, label_map=None)` — label-based carve-out check
   happens FIRST (before commit/callback/assignee). Carved-out beads
   get `classification="CARVED_OUT"`, `recommended_action="keep"`.
5. `scan(cfg)` envelope gains `carved_out_count`, `carve_out_labels`,
   `carved_out_preview[]`.

The existing classification ladder is preserved — labels just add a
zeroth-priority safety net.

### AG2 — Schema ✓

`.flywheel/validation-schema/v1/stale-reaper.v1.schema.json` (JSON
Schema draft-07) validates the scan envelope:
- `schema_version` enum on `stale-in-progress-reaper.v1`
- Required: `total_in_progress`, `stale_count`, `active_count`,
  `recently_touched_count`, `carved_out_count`, `carve_out_labels`,
  `candidates`
- `classified_bead.classification` enum: `STALE | ACTIVE | RECENTLY_TOUCHED | CARVED_OUT`
- `classified_bead.recommended_action` enum: `close | keep`

### AG3 — Launchd plist ✓

`.flywheel/launchd/ai.zeststream.flywheel-stale-reaper.plist`:
- StartCalendarInterval Weekday=0 (Sunday) Hour=9 Minute=30
- KeepAlive=false; RunAtLoad=false
- ProgramArguments calls `--apply --json` (live close mode)
- StandardOut/Err logs to `~/.local/state/flywheel/stale-reaper.{out,err}.log`
- `plutil -lint` PASS

**Joshua-gate held**: plist is committed but NOT `launchctl load`ed.
Joshua reviews the inaugural candidates before authorizing the load.

### AG4 — E2E smoke test ✓

`tests/stale-in-progress-reaper-carve-out.sh` — 10/10 PASS:

```
PASS 5 fixture beads: 1 stale + 4 carved-out + 0 active
PASS only fix-stale-plain is a STALE candidate (no carve-out label)
PASS carve-out label 'upstream-tracker' protects fix-upstream-track
PASS carve-out label 'cross-orch-active' protects fix-cross-orch
PASS carve-out label 'joshua-gated' protects fix-joshua-gated
PASS carve-out label 'defer-gated' protects fix-defer-gated
PASS carve_out_labels default == canonical 4-label list
PASS carved_out_preview entries carry matched label lists
PASS STALE_REAPER_CARVE_OUTS=joshua-gated narrows protection (3 previously-protected become STALE)
PASS dry-run does not write ledger (read-only invariant)
```

Existing `tests/stale-in-progress-reaper.sh` continues to pass 16/16
after the extension — backwards-compat preserved.

### AG5 — Inaugural manual run ✓

```
$ .flywheel/scripts/stale-in-progress-reaper.sh --json | jq '...'
total_in_progress: 66
stale_count:       2
active_count:     62 (commit/callback/assignee signals protect)
recently_touched_count: 2
carved_out_count:  0 (no in_progress bead carries carve-out labels yet)

candidates (for Joshua review):
  - flywheel-3bk  dynamic-ntm-session-coverage-heartbeat  updated 2026-05-01
  - flywheel-3ul  autoloop-anti-monoculture               updated 2026-05-01
```

Pinned at `.flywheel/audit/flywheel-8ht5f/inaugural-candidates.json`
for Joshua review before the first `--apply` execution.

The bead body mentioned "64 in_progress beads accumulated since May 4
planning burst with zero activity" — that cohort is 6 days old today
(threshold is 7). Most are classified `ACTIVE` because they have
recent commit/callback/assignee signals. The 2-bead candidate set is
the May-1 cohort (9+ days old) with zero signals. As the May-4 cohort
crosses 7 days tomorrow, the next dry-run will surface them.

### AG6 — Doctrine note ✓

`.flywheel/doctrine/stale-in-progress-reaper.md` documents:
- Donella leverage-point-#4 framing
- Classification priority (carve-out FIRST, then activity signals)
- Carve-out label canonical defaults + override env
- Cadence (Sunday 09:30; sister to flywheel-4s3oy at 09:00)
- Joshua-gate before first `launchctl load`
- Cross-references to existing tests + sister beads

### AG7 — Bootstrap launchctl + flywheel-watchers register ⏸ (Joshua-gated)

The plist is committed but `launchctl load` is **deferred** per the
bead body's Joshua-gate directive. The orchestrator should route the
inaugural-candidates.json to Joshua for review before authorizing:

```bash
launchctl load .flywheel/launchd/ai.zeststream.flywheel-stale-reaper.plist
flywheel-watchers register --label ai.zeststream.flywheel-stale-reaper --owner flywheel-1
```

Until Joshua signs off, the reaper is dry-run-only via manual invocation.

## Boundary discipline

- ✓ READ from `.beads/beads.db` (sqlite3 SELECT only); no raw SQL mutations
- ✓ WRITE only via `br close --force <id> --reason "..."` (canonical path)
- ✓ Carve-outs honored: bead body's 4-label list is the default
- ✓ Joshua review of inaugural candidates BEFORE first `--apply` (gate held)
- ✓ Idempotency ledger maintained
- ✓ Dry-run by default; `--apply` opt-in for live close

## Files shipped

- `.flywheel/scripts/stale-in-progress-reaper.sh` (modified; +89 lines for
  carve-out classification + label fetch + envelope fields)
- `.flywheel/validation-schema/v1/stale-reaper.v1.schema.json` (new)
- `.flywheel/launchd/ai.zeststream.flywheel-stale-reaper.plist` (new; not loaded)
- `tests/stale-in-progress-reaper-carve-out.sh` (new; 10/10 PASS)
- `.flywheel/doctrine/stale-in-progress-reaper.md` (new)
- `.flywheel/audit/flywheel-8ht5f/evidence.md` (this file)
- `.flywheel/audit/flywheel-8ht5f/inaugural-candidates.json` (Joshua review artifact)
- `.flywheel/canonical-paths.txt` (modified; +6 rows)
- `.flywheel/journal/flywheel-8ht5f.md` (new)

## Three-Q audit (per bead body)

- **VALIDATED**: 16/16 + 10/10 = 26/26 fixture-backed tests pass.
  Live scan against current beads.db produces 2-candidate dry-run
  output (Joshua review pinned).
- **DOCUMENTED**: doctrine + schema + canonical-paths + cross-refs to
  Donella leverage-point-#4 paradigm and sister bead flywheel-4s3oy.
- **SURFACED**: `--doctor` mode emits `stale_in_progress_count_24h`
  and `stale_in_progress_top_classes` (already pre-existing); the new
  `carved_out_count` + `carve_out_labels` fields surface in `--json`
  envelope; weekly Sunday 09:30 plist (Joshua-gated load).

## Joshua review steps

1. Read `.flywheel/audit/flywheel-8ht5f/inaugural-candidates.json` —
   2 stale candidates, both 9+ days old, no recent signals.
2. Run `br show flywheel-3bk` and `br show flywheel-3ul` to confirm
   they're not load-bearing.
3. If approved, choose one of:
   - **Apply manually now**:
     `.flywheel/scripts/stale-in-progress-reaper.sh --apply --json`
   - **Authorize launchd**:
     `launchctl load .flywheel/launchd/ai.zeststream.flywheel-stale-reaper.plist`

## Four-Lens Self-Grade

- brand: 9 — extends pre-existing 16/16-tested script with additive
  label carve-outs (no breaking change); doctrine names Donella +
  cross-refs sister bead.
- sniff: 9 — every claim verifiable; 26/26 tests; live scan reproducible;
  Joshua-gate explicit.
- jeff: 9 — atomic extension, sqlite3 SELECT-only, br close --force
  canonical path, ledger idempotency, env-override widens/narrows
  carve-outs.
- public: 9 — three-judges check: skeptical operator can re-run
  `--json` and see 2 candidates; maintainer can read doctrine to
  understand carve-out priority over signals; future worker can
  extend the carve-out label set via env or flag.
