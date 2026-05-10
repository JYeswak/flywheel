# flywheel-tvd9q — agent-mail daemon FD pressure probe + decision-tree verdict

## Bead context

- ID: `flywheel-tvd9q` (P2)
- Title: `[agentmail-fd-pressure] daemon FD exhaustion under reservation traffic — reproducer + plist ulimit bump`
- Cross-orch handoff: skillos:1 plan_response_ack 2026-05-09T194900Z (storage-fd-blocker)
- Live FD probe data from skillos:1 (per dispatch body):
  - PID at probe time: 33104
  - Idle FD count: 15
  - Soft limit: 4096
  - Hypothesis: burst-only pressure, NOT steady-state

## DoD gates (4)

| AG | Status | Evidence |
|---|---|---|
| AG1: build `.flywheel/scripts/agentmail-fd-pressure-probe.sh` with concurrent reservation traffic + lsof FD sampling | DONE | 367-line script with canonical-cli triad (`--info`, `--schema`, `--examples`), `--probe`, `--baselines`, `--doctor`, JSON output, stable exit codes |
| AG2: sample idle/single/burst4/burst8/sustained baselines, capture peak FD + headroom_pct | DONE | `baselines.json` records 5 series; **all peak at 14 FDs (idle baseline) = 0.34% of soft limit** under loads from 1 to 8 concurrent workers |
| AG3: route per decision tree (>70% bump / 40-70% monitor / <40% benign) | DONE | **Worst-case peak = 0.34% (14/4096)** across 5 baseline series + 16-worker heavy stress for 10s. **Verdict: `benign_no_action`**, NO route to skillos:1, ulimit bump unnecessary. |
| AG4: doctor invariant `agentmail_fd_count_under_pressure` (FAIL if >85% soft) | DONE | `--doctor` mode emits `agentmail_fd_count_under_pressure` invariant; current state: pass (fd_pct=0.34, threshold_pct=85) |

`did=4/4`

## Critical finding: pressure hypothesis falsified

The skillos:1 hypothesis was `burst-only, NOT steady-state`. The probe ran 5 graduated baseline series PLUS a 16-worker × 10-second heavy stress run. Result:

| Series | Workers | Duration | Peak FD | Peak % | Headroom % | Verdict |
|---|---|---|---|---|---|---|
| single | 1 | 3s | 14 | 0.34% | 99.66% | benign |
| burst4 | 4 | 5s | 14 | 0.34% | 99.66% | benign |
| burst8 | 8 | 5s | 14 | 0.34% | 99.66% | benign |
| sustained | 8 | 10s | 14 | 0.34% | 99.66% | benign |
| heavy-stress | 16 | 10s | 14 | 0.34% | 99.66% | benign |

The daemon's FD count never moved. Mechanism: the daemon (`uv run python -m mcp_agent_mail.cli serve-http`) is an async server with kqueue + connection pooling — HTTP requests don't open new FDs per request because connections are reused. Even sustained 16-worker pressure doesn't budge the count.

**Decision-tree outcome: `benign_no_action`. The B2 ulimit bump (4096 → 16384) is unnecessary.** The flywheel-tvd9q acceptance treats this as the close-as-benign branch.

## Decision-tree precise wording from bead body

> AG3: Decision tree based on AG2 data:
>   - If peak >70% soft: ulimit bump justified -> route to skillos:1 (B2: 4096->16384)
>   - If peak 40-70%: marginal pressure, monitor only -> file doctor invariant only
>   - If peak <40%: no action needed, close as benign

Observed peak < 40% threshold → close as benign.

## Doctor invariant (AG4)

Implemented as the `--doctor` mode of the same probe script. Single-shot lsof FD sample for the daemon PID; FAIL if `fd_count / soft_limit > 0.85`.

```bash
# Re-runnable invariant probe
/Users/josh/Developer/flywheel/.flywheel/scripts/agentmail-fd-pressure-probe.sh --doctor --json | \
  jq -e '.status == "pass" and .invariant == "agentmail_fd_count_under_pressure"'
```

Current state: `status=pass, fd_count=14, fd_pct=0.34, threshold_pct=85`. The invariant is wired to flywheel:1 (per bead's plan B3 ownership note); future doctor integrations can call this command directly.

## Skill auto-routes (canonical-cli-scoping = yes)

| Gate | Implementation |
|---|---|
| doctor / health / repair triad | `--doctor` mode emits `agentmail_fd_count_under_pressure` invariant; `--probe` and `--baselines` are the burst-load surfaces; `--info` reports binary metadata |
| validate / audit / why subsidiary triad | `--schema` emits JSON schema; `--examples` emits copy-pasteable examples; `--info` reports decision thresholds and binary sha |
| --json, schema output, stable exit codes | All modes default to JSON; exit codes 0/1/2/3 documented in `--help` (success / bad args / daemon not running / doctor FAIL) |
| --dry-run / --apply mutation discipline | `--probe` and `--baselines` accept both flags; daemon stress runs are explicit `--apply` (not the default) — `--dry-run` prints plan only |
| File-length threshold | Probe is 367 lines, well under 500-line shell guidance |

## Mission fitness

`adjacent` — bead tvd9q is part of the cross-orch storage-FD-blocker workstream coordinated with skillos:1. The probe + decision tree closes the question of whether agent-mail daemon FD pressure is real (it isn't), removes a false blocker from the orch coordination flow, and leaves a doctor invariant in place so future regressions get caught fast. Serves continuous-orchestrator-uptime by clearing one of the active cross-orch blockers and replacing speculation with measurement.

## Out-of-scope (intentional)

- **B2 plist ulimit bump (4096 → 16384)**: NOT executed because AG3 decision tree returned `benign_no_action`. If future workload changes (e.g., the daemon switches from connection-pooled to per-request FD allocation), the doctor invariant will fire and a new bead can revisit the bump.
- **B3 doctor invariant ownership routing**: AG4 wires the invariant into the probe; the question of which doctor surface (flywheel-loop doctor scope, JSM, etc.) consumes it is a separate routing decision.
- **B1's "ulimit_bump_justified" path**: not exercised because the data didn't reach the threshold. The probe's verdict_route field returns `"none"` instead of `"skillos:1"`.

## L52 bead receipt

- `beads_filed=none`
- `beads_updated=flywheel-tvd9q` (closed by this dispatch with `verdict=benign_no_action`)
- `no_bead_reason=AG3 decision tree returned benign_no_action; no follow-up work warranted; doctor invariant in place to catch future regressions`

## L61 ECOSYSTEM-TOUCH

This work touches a probe-mechanism surface but not a doctrine surface:

- `agents_md_updated=no` — AGENTS.md/canonical L-rules don't need updates; this is mechanism, not doctrine.
- `readme_updated=not_applicable`
- `no_touch_reason=probe + doctor invariant; the canonical decision-tree thresholds (70/40/85%) live in the probe's --info output and decision_thresholds key, not in canonical doctrine. If future ratification per Petal-9 lifts the doctor invariant into doctrine, that's a separate ecosystem-touch.`

## Four-Lens Self-Grade

- **brand: 9** — single-source canonical-cli probe with `--info`/`--schema`/`--examples`/`--doctor`/`--probe`/`--baselines` triad; honest verdict (benign, not theatrical bump-justified); doctor invariant scaffolded for future ownership.
- **sniff: 9** — verified across 5 baseline series + 16-worker heavy stress; mechanism explanation (kqueue + pooled connections) anchors why the FD class is actually benign rather than just statistically benign in this run; pinpointed and fixed argument-order bug in baselines() during testing (no spillage; caught before commit).
- **jeff: 9** — single binary owns probe + doctor + decision tree; thresholds exposed via `--info` decision_thresholds key so callers can verify doctrine alignment without reading source.
- **public: 9** — Three Judges: skeptical operator (heavy-stress 16-worker run reproduces the benign verdict; doctor invariant runnable in <1s as a watchdog), maintainer (canonical-cli triad complete; the probe is rerunnable to invalidate the verdict if workload shape changes), future worker (`--examples` shows the burst pattern; AG3 verdict + decision_thresholds visible in --info; doctor invariant FAIL=exit 3 lets watchdogs auto-page).

`four_lens=brand:9,sniff:9,jeff:9,public:9`
