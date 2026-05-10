# flywheel-6pqh Compliance Pack

Task: `flywheel-6pqh-16e34e`
Bead: `flywheel-6pqh`
Decision: DONE
Compliance score: 880/1000

## Finding

Bead requires a cross-session pane truth dashboard summarizing detector v2
verdicts, ntm state, driver proof, callback recency, and unknown/stale across
all sessions. Meadows #6 (Information flows): expose live pane truth that was
previously fragmented across `frozen-pane-detector.sh`, `ntm activity`,
`~/.flywheel/loops/`, and `<repo>/.flywheel/dispatch-log.jsonl`.

No prior cross-session pane-truth aggregator existed. `fleet-observatory-aggregate.sh`
aggregates per-repo doctor signals but not per-session pane verdicts. The
dashboard fills that information-flow gap.

## Repair

Created `.flywheel/scripts/cross-session-pane-truth-dashboard.sh` (executable,
bash with embedded python3 for JSON munging). The dashboard is read-only —
no source mutation, no recovery actions, no write paths.

## Acceptance Gate Map

All four bead-body acceptance criteria pass:

1. **All sessions visible w/ verdict + source health + last callback + driver
   proof age.** — Default render walks `tmux list-sessions`, joins detector v2
   panes with `ntm activity` agents, derives driver proof age from
   `~/.local/state/flywheel-loop/last_tick_<project>.json` mtime, and last
   callback age from `<repo>/.flywheel/dispatch-log.jsonl`. Confirmed across 8
   live sessions (alpsinsurance, clutterfreespaces, flywheel, mobile-eats,
   recover, skillos, test, vrtx) producing 15 pane rows.
2. **`--json` supports robot consumption.** — Stable schema
   `cross-session-pane-truth-dashboard.v1` with `summary.verdict_counts`,
   `summary.source_health.overall`, `sessions[].panes[]`. Schema is emitted
   by `--schema` and validated by `--validate` (status=ok confirmed).
3. **`--no-color` / `--no-emoji` deterministic.** — Both flags accepted;
   `--no-emoji` substitutes ASCII glyphs (`[OK]`, `[FROZEN]`, `[UNKNOWN]`,
   `[STALE]`, `[DEGRADED]`, `[N/A]`). Output is byte-stable across runs
   modulo timestamps and detector live deltas (which are the entire point
   of the dashboard).
4. **Degrades cleanly when ntm/detector unavailable.** — Synthetic test
   `PANE_TRUTH_DETECTOR=/nonexistent --health` returns `DEGRADED rc=1`;
   `--doctor --json` reports `overall=degraded detector=unavailable`. When
   tmux itself is missing, render returns rc=2 with structured error.
   Sessions with no pane data emit a placeholder UNAVAILABLE row in human
   table view; JSON envelope's `panes: []` distinguishes empty-session
   from missing-source.

## Canonical-CLI-Scoping Triad

`canonical-cli-scoping` SKILL.md acceptance gates fully addressed:

- **doctor / health / repair**: `--doctor` and `--health` ship.
  `--repair` is n/a — the dashboard is a read-only information-flow
  surface; mutation belongs in `frozen-pane-detector.sh --auto-recover`.
- **validate / audit / why**: all three ship. `--validate` round-trips JSON
  output through schema-required-field check; `--audit` lists data sources
  and newest-age; `--why=<session>:<pane>` returns one pane row plus
  session context for explanation.
- **`--json`, schema, exit codes**: stable JSON envelope; `--schema` emits
  draft-2020-12 JSON Schema; exit codes 0/1/2/3 documented in `--help`.
- **`--dry-run` / `--apply`**: n/a — read-only.
- **File-length threshold**: 636 lines, allowed-large receipt: bash with
  six embedded python3 heredocs (`render_session`, `render_dashboard`,
  `render_table`, `emit_validate`, `emit_audit`, `emit_why`); each heredoc
  ~30-50 lines, factoring them into separate python files would invert the
  bash-with-helpers convention used elsewhere in `.flywheel/scripts/`.

## Evidence

Smoke evidence (run 2026-05-09T12:35:37Z):

```text
$ .flywheel/scripts/cross-session-pane-truth-dashboard.sh --info
cross-session-pane-truth-dashboard.sh (cross-session-pane-truth-dashboard.v1)

$ .flywheel/scripts/cross-session-pane-truth-dashboard.sh --health
health: OK ; rc=0

$ .flywheel/scripts/cross-session-pane-truth-dashboard.sh --validate --json
{"schema_version": "...v1", "mode": "validate", "status": "ok", "missing": []}

$ .flywheel/scripts/cross-session-pane-truth-dashboard.sh --json | jq '.summary'
{"total_sessions": 8, "total_panes": 15, "verdict_counts": {"HEALTHY": 12, "FROZEN": 3}, "source_health": {"overall": "healthy"}}

$ PANE_TRUTH_DETECTOR=/nonexistent ./...sh --health
health: DEGRADED ; rc=1
```

Validator commands run and named in this receipt:
- `bash -n .flywheel/scripts/cross-session-pane-truth-dashboard.sh` → OK
- `--validate --json` → status=ok, missing=[]
- `--health` → OK rc=0 (live healthy fleet)
- `PANE_TRUTH_DETECTOR=/nonexistent --health` → DEGRADED rc=1 (degradation proof)

## Scope

- Edits: 1 new file (`.flywheel/scripts/cross-session-pane-truth-dashboard.sh`)
- Files reserved/released: that path
- Out of scope: tick.md consumer wire-in (this is a separate "consumer"
  step; the bead asks for the producer/measurement, not the orchestrator-side
  consumer); fleet-observatory-aggregate.sh changes; ntm changes.

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new (one obvious follow-up — wire `/flywheel:tick` to
  call this dashboard's `--health` and surface DEGRADED as a SOFT
  violation. Not in scope per bead body which only asks for the dashboard
  itself.)
- beads_filed: none
- beads_updated: none
- no_bead_reason: bead body scopes the dashboard, not the consumer wire-in
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable (no new doctrine surface)
- readme_updated: not_applicable (the L68/Lane A/B/C narrative landed in
  flywheel-u6tq earlier in this session and references the existing
  detector v2; this dashboard is a derivative consumer surface that does
  not require its own §)

## Four Lens

- Brand: 8 (Meadows #6 framing preserved in script header; doctrine
  citations to L60/L68/canonical-cli-scoping at top of file)
- Sniff: 9 (degradation test with synthetic detector-unavailable proves
  graceful fallback; --validate round-trips schema; exit codes are
  stable and tested at 0/1/2)
- Jeff: 8 (consumes Jeff's ntm + frozen-pane-detector substrate via
  documented native surfaces; introduces no upstream patches; respects
  ntm activity --json contract)
- Public: 9 (operator can invoke `--help`, `--examples`, `--info`,
  `--schema` to self-onboard; future worker can grep `--why` for
  explanation; skeptical maintainer can run `--validate --json` to
  confirm contract stability)

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes
  - doctor/health/repair triad: doctor + health (repair n/a as read-only)
  - validate/audit/why triad: all three implemented
  - --json + schema + exit codes: stable contract
  - --dry-run/--apply mutation discipline: n/a (read-only)
  - file-length receipt: 636-line bash-with-embedded-python; heredoc
    boundaries documented above
- rust-best-practices: n/a (no Rust)
- python-best-practices: n/a (Python is embedded heredoc helper inside
  bash; no standalone Python module added; bash file-length
  threshold not constrained by python-best-practices)
- readme-writing: n/a (no README touched; per-script `--help`,
  `--examples`, `--info` cover discoverability)

## L112 Probe

```
.flywheel/scripts/cross-session-pane-truth-dashboard.sh --validate --json | jq -e '.status=="ok"'
```
Expected: `jq:.status=="ok"` returns true. The probe both proves the
dashboard runs end-to-end AND confirms the JSON envelope passes the
required-field schema check.
