---
title: "Agent Ergonomics Application Baseline — 2026-05-08"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# Agent Ergonomics Application Baseline — 2026-05-08

## Scope

Bead: `flywheel-r52ig`
Skill applied: `agent-ergonomics-cli-max`
Canonical companion: `canonical-cli-scoping`

This is the first baseline pass applying Jeffrey Emanuel's agent-ergonomics CLI
rubric to Flywheel's own `.flywheel/scripts` and loop-control substrate.

## Ranking Method

Top-10 candidates were ranked with the skill's operating heuristic:

```text
bucketed dispatch-log frequency x bucketed failure-rate x blast-radius
```

Raw evidence is stored in:

```text
.flywheel/receipts/flywheel-r52ig/audit/top_10_cli_inventory.jsonl
```

## Top-10 Inventory

| Rank | Tool | Role |
|---:|---|---|
| 1 | `flywheel-loop` | Primary tick, doctor, worker-mode control loop. |
| 2 | `dispatch-and-verify` | L140 dispatch delivery wrapper. |
| 3 | `sync-canonical-doctrine` | Fleet doctrine propagation. |
| 4 | `build-dispatch-packet` | Canonical dispatch packet materializer. |
| 5 | `validate-callback` | Callback close gate. |
| 6 | `tmp-aggressive-prune` | Storage pressure recovery. |
| 7 | `peer-orch-respawn-permit` | Peer-orch recovery permit gate. |
| 8 | `flywheel-loop-tick` | Tick driver and accretion path. |
| 9 | `frozen-pane-detector-fleet` | Fleet liveness watchdog. |
| 10 | `flywheel-doctor` | Operator doctor alias surface. |

## Top-3 Audit Results

Generated artifacts:

- `flywheel-loop`: `agent_surfaces.jsonl` and `recommendations.jsonl`.
- `dispatch-and-verify`: `agent_surfaces.jsonl` and `recommendations.jsonl`.
- `sync-canonical-doctrine`: `agent_surfaces.jsonl` and `recommendations.jsonl`.

Strategic adjacent sample:

- `build-dispatch-packet`: included because the bead body named it as likely
  top-3 and it is the canonical packet materializer.

## Eleven-Dimension Scores

Scores use the skill's 0-1000 scale and are intentionally conservative for
surfaces without complete robot-docs/capabilities endpoints.

| Tool | Pre | Post | Delta | Disposition |
|---|---:|---:|---:|---|
| `flywheel-loop` | 820 | 820 | 0 | Already mature; high-blast, no patch. |
| `dispatch-and-verify` | 610 | 735 | +125 | Low-blast introspection patch applied. |
| `sync-canonical-doctrine` | 690 | 690 | 0 | High-blast fleet propagation; defer full pass. |
| `build-dispatch-packet` | 780 | 780 | 0 | Already has introspection and stable exits. |

Post-score evidence:

```text
.flywheel/receipts/flywheel-r52ig/audit/post_scores.jsonl
```

## Applied Changes

Low-blast recommendation applied:

- `dispatch-and-verify.sh --help` now exits 0 instead of the usage-error path.
- `dispatch-and-verify.sh --info --json` exposes runtime defaults.
- `dispatch-and-verify.sh --examples --json` emits copy-paste workflows.
- `dispatch-and-verify.sh --schema` emits the machine-readable contract and
  exit-code table.
- Help text now advertises the introspection and probe-mode options so the
  inventory tool can discover them.

Regression: `tests/dispatch-and-verify.sh` pins the new introspection surfaces.

## Deferred High-Blast Recommendations

Do not auto-patch these in a worker dispatch without a narrower bead:

- `flywheel-loop`: any changes touch the central control loop.
- `sync-canonical-doctrine`: any changes can propagate to fleet repos.
- `validate-callback`: any changes affect close validation.
- `flywheel-loop-tick`: file is oversized and tied to active tick drivers.

## Fresh-Agent Simulation

Simulation receipts:

```text
.flywheel/receipts/flywheel-r52ig/audit/fresh_agent_simulations.jsonl
```

Each audited surface has at least one first-try command that succeeds from help
or introspection alone.

## Quarterly Cadence

Quarterly re-audit cadence:

```text
owner=flywheel
cadence=quarterly
next_due=2026-08-08
scope=top-10 flywheel CLI substrate by ranked inventory
entrypoint=.flywheel/receipts/flywheel-r52ig/l112-probe.sh
```

The audit is a time series. Future passes append a new receipt directory and
compare against this baseline rather than overwriting it.

## Four-Lens Self-Grade

- Brand: 8/10. Clear ownership and cadence, no new public command name.
- Sniff: 8/10. One low-risk patch, high-blast surfaces deferred explicitly.
- Jeff: 8/10. Applies the rubric and keeps evidence machine-readable.
- Public: 8/10. A skeptical operator, maintainer, and future worker can rerun
  the artifacts and understand what was changed.

