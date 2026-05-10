---
title: "Jeff Ecosystem Deep Dive — 04 Our Needs vs Stack"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Jeff Ecosystem Deep Dive — 04 Our Needs vs Stack

**Snapshot:** 2026-05-01
**Task:** `jeff_eco_pane4`
**Sources:** flywheel local doctrine (`AGENTS.md`, `.flywheel/{MISSION,GOAL,STATE}.md`), pain log tail, project memory, Jeff local checkouts, `ntm#111`, vc daemon log.
**Socraticode survey:** 2 queries, 20 results.
**No patches or issue submissions.**

## Flywheel Need Shape

Flywheel is not just a repo; its `.flywheel/MISSION.md` defines it as the orchestration substrate for dispatch, beads, templates, audits, cross-repo coordination, and doctrine. The current goal is a repo-scoped, self-improving flywheel that keeps agents coordinated, observable, and doctrine-grounded without cross-repo state leakage.

Pain signal from the last 200 fuckup rows:

| Class | Count | Stack implication |
|---|---:|---|
| `repeat-gate-deny-dispatch_transport` | 25 | Transport doctrine is not mechanically encoded enough; NTM-only operations still need guardrails. |
| `agent-fighting-gate` | 5 | Workers need stronger preflight and dispatch contracts. |
| `repeat-gate-deny-readiness` | 4 | Readiness checks need live-state truth, not static assumptions. |
| `orchestrator-observability-contract-bypass` | 4 | Pane/fleet truth surfaces must be authoritative. |
| `orchestrator-idle-with-actionable-work` | 4 | Scheduler needs reliable idle/work detection plus fallback work. |
| `credential-substrate-truth-drift` | 4 | Agent-mail/token/config probes need doctor-grade validation. |
| `skill-substrate-validation-drift` | 3 | Skill discovery and validation need first-class ingestion. |

Relevant local memories:
- `feedback_pane_state_ntm_health.md:7-11` says use `ntm health` instead of raw pane inspection, but our later workaround shows `ntm health` is false-idle for Codex.
- `project_fleet_observatory_2026_05_01.md:24-32` records L61 dual-channel working legs and the `ntm-fleet-health` daemon.
- `reference_lavenderglen_fleet_mail.md:7-15` records the fleet-mail identity model and bead `flywheel-3fa`.
- `reference_upstream_issues.md:27-35` records the `beads_rust#270` WAL wedge fix and the new first-line debug rule.
- `feedback_jeff_issue_chain.md:7-17` says file evidence-rich upstream issues, not patches.

## Capability Coverage Matrix

| Capability | Doctrine ref | Jeff tool(s) | Coverage | Gap | Decision | Effort | Value | Priority |
|---|---|---|---|---|---|---|---|---|
| Multi-pane orchestration | L29 `AGENTS.md:95-103`, L48 `AGENTS.md:40-50` | `ntm` | Strong core | Coordinator config persistence drift (`ntm#111`); Codex health false-idle; dispatch-gate denials still frequent. | ENHANCE | M | Very high | P0 |
| Bead-based work substrate | L52 `AGENTS.md:218-235` | `beads_rust` + `bv` | Strong local substrate | Prior WAL wedge/version drift (`flywheel-14w`, `beads_rust#270`); vc collector cannot see local beads. | ENHANCE | M | Very high | P1 |
| Cross-orch coordination | L61 `AGENTS.md:424-437`, L65 `AGENTS.md:459-476` | `mcp-agent-mail` + `ntm` | Partial | Agent Mail has inbox/fetch/reservations, but no durable auto-poll + paired ntm-poke enforcement by itself. | ENHANCE | M | High | P1 |
| Skill discoveries | L62 `AGENTS.md:443-449` | Jeffrey's Skills.md / JSM surface | Weak coverage | Jeff has skill distribution (`jeffreys-skills.md` markets premium skills and `jsm`), but no evidence of our L62 callback-row ingestion. | OWN | M | High | P1 |
| Recovery rehearsal | L63 `AGENTS.md:451-457` | `ntm`, `vibe_cockpit`, `asupersync` concepts | Partial concept | Jeff stack has health/playbooks/structured cancellation, but no flywheel 5-green-drill acceptance harness. | OWN | M | High | P1 |
| Worker/orchestrator tick | `.flywheel/GOAL.md`, L50-L53 | flywheel-loop (ours) | Ours | Jeff tools are primitives; our tick receipts/callback/fuckup ladder remain flywheel-owned. | OWN | M | Very high | P0 |
| Truth signals for pane state | L60 `AGENTS.md:416-422`; memory `feedback_pane_state_ntm_health.md:7-11` | `ntm health` | Broken for Codex | `pane-work-signal.sh:4-8` records 36/36 false-idle samples; hash-delta workaround is authoritative today. | ENHANCE | S/M | Very high | P0 |
| Issue tracking | L52 `AGENTS.md:218-235` | `br`, `bv`, GitHub | Good, split-plane | Local issues in beads; cross-public Jeff issues manual but effective (`02-issue-patterns.md:195-203`). | ENHANCE | S | High | P1 |
| DCG | `~/.claude/CLAUDE.md:73` safety axiom | `dcg` | Adopted | Main gap is flywheel doctor/gate integration, not core DCG. | ENHANCE | S | High | P1 |
| Memory persistence | L50 `AGENTS.md:143-159`, L54 `AGENTS.md:285-305` | `cass`, `cass-memory` | Partial | CASS helps avoid re-solving, but dispatch enforcement is our doctrine and Socraticode is separate. | ENHANCE | M | High | P1 |
| Agentic IDE/fleet substrate | Hive `AGENTS.md:405-414` | `vibe_cockpit` | Promising but not ready | vc claims fleet monitoring, collectors, DuckDB, alerts, playbooks, but beads collector currently sees zero DBs. | WAIT/ENHANCE | M/H | Medium-high | P2 |
| Rust async runtime | `~/.claude/CLAUDE.md:64-80` reliability axiom | `asupersync` | Transitive | Excellent fit for future Rust daemons; current shell/Python flywheel loop should not churn for runtime purity. | WAIT | H | Medium | P3 |
| Embedded analytical DB | Fleet observability | DuckDB now, `frankensqlite` later | Mid-migration | vc still uses DuckDB; frankensqlite README says runtime is hybrid and not all target claims are live (`frankensqlite/README.md:138-152`). | WAIT | H | Medium-high | P2 |

## Known Gaps Validated

1. **vc beads collector blind spot: validated.** `~/Library/Logs/vc-daemon.log` repeatedly shows `beads: FAIL (No beads databases found)` at log lines 10, 20, 30, 40, 50, 60, 70, 80, 90, 100. Local scan found **55** `.beads/` directories under `~/Developer`, including flywheel, ntm, beads_rust, vibe-cockpit, frankensqlite, and active client repos.

2. **ntm coordinator config gap: validated and maintainer-confirmed.** `ntm#111` title is `coordinator status ignores [coordinator] config from config.toml`; Jeff confirmed `internal/cli/coordinator.go:120-121` constructs status from defaults and `internal/config/config.go` lacks a `Coordinator` field. Local bead `flywheel-1ag` tracks the blocked upstream gap; `flywheel-3tv` already added the local config section.

3. **ntm health false-idle for Codex panes: validated locally.** `pane-work-signal.sh:4-8` records 36/36 controlled samples reporting idle while panes were working; scrollback hash delta is the only observed truth signal. This weakens any scheduler that trusts `ntm health` alone.

4. **Dual-channel L61: shipped locally, not native in Jeff stack.** Agent Mail has `fetch_inbox`, reservations, and searchable threads (`ntm/AGENTS.md:349-359`), but L61 requires every cross-session message to have both real-time `ntm send` and durable Agent Mail legs (`AGENTS.md:424-437`). Project memory says paired `message_id` + `project_key` ntm-pokes were added locally (`project_fleet_observatory_2026_05_01.md:24-28`).

5. **Cross-orch hive coordination: local doctrine/substrate.** L65 requires cross-orch comms through a shared fleet-mail project (`AGENTS.md:459-476`). LavenderGlen is the flywheel-p1 identity in that layer (`reference_lavenderglen_fleet_mail.md:7-15`). Jeff's Agent Mail supports the primitives, but fleet topology, identity vaulting, and routing are ours.

## Top 10 Gaps Ranked by Value/Effort

1. **Codex pane truth repair in ntm health** — Value: very high, Effort: S/M, Decision: ENHANCE. Evidence: `pane-work-signal.sh:4-8`, pain classes `orchestrator-observability-contract-bypass`, `orchestrator-idle-with-actionable-work`. Beads: `flywheel-3bk`.

2. **vc beads collector multi-repo discovery** — Value: very high, Effort: M, Decision: ENHANCE upstream. Evidence: vc log `No beads databases found` despite 55 local `.beads/` dirs; `01-repo-inventory.md:356-367`.

3. **ntm config schema/runtime sweep beyond coordinator** — Value: high, Effort: M, Decision: ENHANCE upstream. Evidence: `ntm#111`, `flywheel-1ag`, `01-repo-inventory.md:357`; likely same class as config validate rejecting documented sections.

4. **L61 auto-poll + paired-poke enforcement** — Value: high, Effort: M, Decision: OWN/ENHANCE. Evidence: L61 `AGENTS.md:424-437`, Agent Mail primitives `ntm/AGENTS.md:349-359`, memory `project_fleet_observatory_2026_05_01.md:24-28`.

5. **Fleet-mail identity/vault doctor v2** — Value: high, Effort: M, Decision: OWN. Evidence: L65 `AGENTS.md:459-476`, `reference_lavenderglen_fleet_mail.md:7-15`; bead `flywheel-3fa`.

6. **Recovery rehearsal harness to satisfy L63** — Value: high, Effort: M, Decision: OWN. Evidence: L63 `AGENTS.md:451-457`, memory `project_fleet_observatory_2026_05_01.md:41-45`; bead family includes `flywheel-2a7`.

7. **Skill-discovery row ingestion and promotion path** — Value: high, Effort: M, Decision: OWN. Evidence: L62 `AGENTS.md:443-449`, pain class `skill-substrate-validation-drift`, Jeffrey's Skills.md is distribution rather than our callback telemetry.

8. **br health/version guard in doctor** — Value: high, Effort: S/M, Decision: OWN plus upstream watch. Evidence: `reference_upstream_issues.md:27-35`, bead `flywheel-14w`; first-line debug is `br --version` vs beads_rust HEAD.

9. **Human-gate idle escalation primitive** — Value: medium-high, Effort: S/M, Decision: OWN. Evidence: L48 `AGENTS.md:40-50`, L35 `AGENTS.md:109-128`, pain class `orchestrator-idle-with-actionable-work`; bead `flywheel-17x`.

10. **Jeff issue filing loop as a formal flywheel pathway** — Value: medium-high, Effort: S, Decision: OWN. Evidence: `feedback_jeff_issue_chain.md:7-17`, `02-issue-patterns.md:195-203`; issue quality works when repro + source observations are precise.
