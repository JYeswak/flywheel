---
title: "autoloop-target-selector doctrine"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# autoloop-target-selector doctrine

**Bead origin:** flywheel-se3h.9 (extends parent flywheel-se3h
session-topology plan).

## Why this exists

Autoloop targeting that hardcodes session lists drifts the moment a
session is added, removed, renamed, or quarantined. The canonical
fix is to have the selector consume the session topology ledger
(`~/.local/state/flywheel/session-topology.jsonl`) and fail closed
on anything that doesn't match the eligibility contract.

This means:
- Ghost sessions (registered but `orchestrator_pane=null`) are skipped.
- Sessions whose topology row is missing entirely don't sneak through.
- Sessions in unexpected `session_status` are refused unless the
  operator widens the allow-list explicitly.

## Pipeline

```
~/.local/state/flywheel/session-topology.jsonl   (topology refresh writer)
        │
        ▼
.flywheel/scripts/autoloop-target-selector.sh
   --apply [--topology=PATH] [--allowed-status=...]      (read-only)
        │
        ▼
JSON envelope with eligible[] and skipped[] (with structured reasons)
        │
        ▼
Consumed by the autoloop dispatcher (separate bead — out of scope here)
```

## Eligibility rule

A session is eligible iff ALL hold for its latest topology row:

| Field                 | Required                                        |
|-----------------------|-------------------------------------------------|
| `orchestrator_pane`   | non-null                                        |
| `callback_pane`       | non-null                                        |
| `session_status`      | in `--allowed-status` (default: `live,live_corrected`) |

Default allow-list is intentionally conservative: only sessions that
the topology refresh has explicitly stamped `live` or `live_corrected`
make it through. A session row with `session_status=null` (refresh
hasn't stamped status yet) is REFUSED — fail closed. The operator can
widen via `--allowed-status=` if a diagnostic mode wants to include
them.

## Skip-reason classes (carried into receipt)

- `missing_orchestrator_pane`
- `missing_callback_pane`
- `status_not_allowed:<observed_status>`
- `missing_topology_row` (reserved — selector currently treats absent
  rows as "session unknown" and excludes from output entirely; future
  caller-supplied session list would surface this class)

The receipt's `skipped[]` array carries one object per refused session
with all reasons cited, so the operator can see exactly why each was
excluded.

## Latest-row-per-session semantics

The topology jsonl is append-only; the selector deduplicates by
session via `group_by(.session) | map(max_by(.effective_at))` so the
*newest* topology row wins. This means a session that recently went
from `live` to `null` (refresh dropped status) immediately becomes
ineligible without requiring jsonl rewrite.

## CLI doctrine (canonical-cli-scoping triad)

| Mode                 | Behavior                                          |
|----------------------|---------------------------------------------------|
| `--info`             | help                                              |
| `--schema`           | one-line emit schema                              |
| `--examples`         | curated invocations                               |
| `--doctor [--json]`  | source health probe (rows, sessions, latest_ts)   |
| `--apply [--json]`   | run selection, emit eligible/skipped envelope     |

Stable exit codes:
- `0` success
- `1` internal error
- `2` bad argument or missing topology source
- `3` topology source has zero rows (cold start)

## AG6 read-only invariant

The selector NEVER calls `ntm send`, `tmux send-keys`, `pkill`, or
any other live-dispatch primitive. This is asserted by Test 13 in
the e2e suite via grep on the selector source. Tests run against
fixture jsonl, not the live topology, and never touch any client
session.

## Doctor / daily-report integration

The selector's `--doctor` mode emits `topology_present`,
`topology_rows`, `topology_latest_ts`, and `distinct_sessions` —
all consumable by `flywheel-loop doctor` for a future
`autoloop_topology_targeting_status` field. Wiring that field into
the doctor JSON envelope is a separate bead (out of scope here per
spec; the bead body says "doctor or daily report surfaces topology-
targeting gaps" — this doctrine documents where the surfacing should
land).

For now, the daily report's session-topology section can call
`autoloop-target-selector.sh --apply --json` and surface the
`skipped_count` and `skipped[].reasons` directly.

## Cross-references

- Parent bead: flywheel-se3h (session-topology plan) +
  flywheel-se3h.1 (registry validation, in_progress) +
  flywheel-se3h.2 (register-session writer, closed)
- Plan source: `.flywheel/PLANS/session-topology-2026-05-01.md`
- Topology writer: `topology-tick-refresh` (per
  `registered_by` field in jsonl rows)
- Live observation as of 2026-05-10: 7 distinct sessions in
  topology; 2 eligible (`alpsinsurance` live_corrected + `skillos`
  live), 5 skipped (1 ghost `clutterfreespaces`, 4 with null status
  awaiting refresh-side stamp).
