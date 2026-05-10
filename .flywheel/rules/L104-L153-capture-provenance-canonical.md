## L153 — CAPTURE-PROVENANCE-CANONICAL

---
id: L153
title: Per-pane capture provenance is the single source of truth for pane state
status: long_term
shipped: 2026-05-10
review_due: 2026-11-10
trauma_class: robot-mode-false-positive-poisoning
---

ntm PR #117 (`8cd9301c`) added per-pane `capture_provenance` to
`--robot-activity` output. The orchestrator and dispatch wrappers MUST
treat that field as the single source of truth for pane state and MUST
NOT dispatch work to a pane unless `capture_provenance == "live"` AND
`state == "WAITING"`.

Disposition matrix:

| `capture_provenance` | `state` | Disposition |
|---|---|---|
| `live` | `WAITING` | dispatch |
| `live` | `ERROR` / `STALLED` | skip + escalate (worker problem) |
| `live` | `THINKING` | busy; wait |
| `unavailable` | any | infrastructure problem; route to `flywheel-respawn` or `flywheel-recovery` BEFORE classifying the worker |

**Reason:** Recurring false-positive ERROR poisoning produced wrong-pane
sends and dispatch races (agentmail-mcp-disconnect symptom 2026-05-04).
Pre-PR-#117 the watcher had to cross-check two truth sources because
robot-mode lied; provenance reduces that to one canonical signal. The
ntm PR replaces the workaround originally tracked as ntm#114.

**Producers (must emit / log the field):**
- `ntm --robot-activity=<session>` (upstream Jeff)
- `flywheel-loop doctor --json` exposes `pane_capture_unavailable_count`
  and `pane_capture_state` (per-pane object). Implements the doctor side
  of `flywheel-255f` AG3.
- Dispatch wrappers (`/flywheel:dispatch`, dispatch-template) MUST log
  `capture_provenance` and `capture_collected_at` at send-time per
  `dispatch-log-entry-v2.schema.json`. Implements `flywheel-255f` AG4.

**Consumers (must refuse on breach):**
- `idle-pane-auto-dispatch.sh` — refuses to assign a pane unless
  `capture_provenance == "live"` AND `state == "WAITING"`.
- `/flywheel:dispatch` — refuses to send if pre-flight robot-activity
  reports anything else.
- Doctor red-flag rules — `pane_capture_unavailable_count > 0`
  surfaces as `status=warn` so fleet observability catches the breach
  before a worker round-trip.

**Tests:**
- `tests/pane-capture-provenance.sh` covers the four-fixture matrix
  (live-waiting → selected, live-error → not selected,
  unavailable-with-error → not selected, unavailable-without-error
  → not selected).

**Implementing beads:**
- `flywheel-ef8m` (parent: `[ntm-117-capture-provenance-upgrade]`,
  in_progress) — full feature integration including watcher and
  dispatch.md.
- `flywheel-255f` (this rule) — finishes the doctor / template /
  doctrine gates that were blocked by reservations on shared surfaces.

**Failure mode:** A worker sees `state=ERROR` from cached / stale
robot-activity, agents fight gates trying to retry. Provenance kills
that class because `capture_collected_at + capture_provenance` make the
freshness explicit.

**Surface:** doctrine layer-2; the underlying field flows
upstream→ntm→robot-activity→watcher→dispatch wrapper→callback envelope.
