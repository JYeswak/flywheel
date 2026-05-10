---
title: "Lane C - Integration + Wire-Or-Explain Audit"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Lane C - Integration + Wire-Or-Explain Audit

Date: 2026-05-06  
Lane: C  
Scope: read-only research for `orch-uptime-plan-2026-05-06`  
Deliverable: `/tmp/orch-uptime-laneC-integration-wire-or-explain-2026-05-06.md`

## Executive Verdict

Lane A and Lane B are parallel-safe for research, but must sequence at the shipping boundary:

1. Lane B can refresh topology and watcher state independently.
2. Lane A can implement a vault-only `credential_rotation` recovery path that does not depend on pane topology.
3. Any post-rotation pane action, respawn, prompt send, or kill/reap step must wait for fresh topology and the existing pane authorization gate.

The canonical Wire-Or-Explain ledger expected at `~/.local/state/flywheel/wire-or-explain-ledger.jsonl` is absent. Therefore there are no live rows I can enumerate by `state != wired && owning_orch in (flywheel:1, flywheel:pane-1)`. That is not evidence that the queue is empty; it is a substrate gap. Existing WOE tooling treats an absent ledger as bootstrap-pass, so Lane A/B should not claim they drained current WOE rows.

L87 is not ready to sunset before this plan ships. Its sunset bead `flywheel-pp1g` is still `in_progress`, and the classifier divergence log still contains fresh stale-error rows for `flywheel:1 pane=1` on 2026-05-06.

The skillos sibling issue is the same trauma class as today's topology-stale gate: `frozen-projection-of-mutable-state`. Proposed canonical L-rule: `templates-name-sources-not-values`.

## Donella Trace

System boundary: flywheel orchestrator uptime across detector, recovery, topology, WOE, cron/template, and callback substrates.

Stock: continuously productive orchestrator panes, fresh topology facts, undrained WOE rows, and executable recovery primitives.

Flow break: mutable state is projected into long-lived literal payloads, then goes stale. Examples: topology roles captured once, stale blocker IDs in cron prompts, line-number-stale scripts, and recovery classifiers relying on pane state that may no longer be current.

Feedback loop: detector observes a halt, authorization classifies what may be touched, recovery either repairs the substrate or leaves a WOE row, then the next tick should see fresher state. Frozen literal projections break the loop by feeding old facts back into the detector.

Leverage points: rules/invariants, information flows, and self-organization. The highest-leverage fix is a doctrine + doctor invariant that forces long-lived templates to name authoritative sources, not copied values.

Measurements: `topology_stale` refusal rate, credential-exhaustion recovery latency, `frozen_projection_count`, WOE ledger presence, WOE unresolved row count, and callback recovery completion receipts.

## Wire-Or-Explain Rows

Canonical expected ledger:

`/Users/josh/.local/state/flywheel/wire-or-explain-ledger.jsonl`

Observed:

| Row | Predicate | Consumer | Disposition |
|---|---|---|---|
| `ledger_missing` | canonical WOE ledger absent | `wire-or-explain-ledger-writer.sh doctor`, `wire-or-explain-close-gate.py` | Separate substrate bead needed. Do not treat as drained by Lane A/B. |

The writer doctor returned `status=pass row_count=0` because bootstrap absence is currently allowed. The close gate also reports `ledger_missing`. For this uptime plan, the integration requirement should be: no intervention claims WOE closure until the ledger is present or the close gate has an explicit "ledger absent but expected" warning path.

Suggested WOE dispositions once ledger exists:

| Class | Owning intervention | Wiring expectation |
|---|---|---|
| `codex_usage_limit` / credential exhaustion | Lane A | `credential_rotation` receipt, vault-only stage, no pane mutation before topology check |
| `topology_stale` | Lane B | topology refresh receipt with source path, age, and watcher load result |
| `frozen_projection_of_mutable_state` | Lane C / doctrine | doctor invariant row naming offending template/plist/script and authoritative source path |

Read-only note: one close-gate probe wrote a local state receipt at `~/.local/state/flywheel/wire-or-explain/closeout-receipts/20260506T203528.755652Z.json`; no repo code, bead DB, or doctrine file was mutated.

## L87 Sunset Path

L87 is temporary, with `sunset_when.bead: flywheel-pp1g`.

Current status:

| Artifact | Status | Integration verdict |
|---|---|---|
| `flywheel-pp1g` | `in_progress`, priority 1 | Not sunset-ready |
| Upstream issue | recorded as `https://github.com/Dicklesworthstone/ntm/issues/118` | Evidence exists, but bead close was validator-blocked |
| Workaround | `.flywheel/scripts/stale-error-auto-ping.sh` | Keep active |
| Tests | `tests/stale-error-auto-ping.sh` | Re-run in final validation pass |
| Live divergence | `classifier-divergence-log.jsonl` fresh rows on 2026-05-06 | Confirms L87 still relevant |

Sunset criterion: close `flywheel-pp1g` cleanly after evidence rework, upstream/fallback status is represented, tests pass, and classifier divergence no longer shows active stale-error misclassification for live orchestrator panes.

## Dependency Order

Verdict: parallel-safe research, staged implementation.

Lane B can ship topology refresh and watcher-load fixes without waiting on Lane A. Lane A's CAAM/vault rotation primitive can ship as topology-independent only if it does not send input to panes, kill processes, respawn sessions, or classify pane ownership from stale topology.

Required stage split:

| Stage | Topology requirement | Notes |
|---|---|---|
| `credential_rotate` | none | Vault/profile state only; must not touch panes |
| `verify_profile_active` | none if vault/API-only | May probe profile status without pane mutation |
| `recover_pane_after_rotation` | fresh topology required | Sends, respawns, or authorization-gated pane actions |
| `drain_woe_row` | WOE ledger required | Cannot close rows while canonical ledger is absent |

This preserves the key insight in Lane A: credential rotation should not be blocked by topology staleness when the affected state is independent of pane role. It also preserves L115/L117-style pane protection: topology-independent must not become pane-permission-independent.

## Blocked / Relevant Beads

Selected P0/P1 beads affecting safe ordering:

| Bead | Priority/status | Relationship to plan | Disposition |
|---|---:|---|---|
| `flywheel-pp1g` | P1 `in_progress` | L87 sunset criterion | Must close before retiring L87 |
| `flywheel-3iz0` | P0 open | WOE dogfood import; likely needed because canonical ledger is absent | Prioritize or pair with WOE ledger repair |
| `flywheel-2x5yi` | P0 open | Watcher canonical CLI for plist on/off/status | Coordinate with Lane B; likely same surface |
| `flywheel-25om8` | P0 `in_progress` | Loop telemetry convergence and driver writeback | Sequence after/with topology refresh |
| `flywheel-5ktd.2` | P0 open | Pane work-signal parser | Coordinate with Lane B topology truth |
| `flywheel-5ktd.3` | P0 open | Tick dispatch-capacity truth | Coordinate with Lane B and recovery gating |
| `flywheel-wire-codex-model-at-capacity-halt-class-c38ad0dd` | P0 open | Sibling structural halt class | Align classifier schema with Lane A |
| `flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06` | P0 open | Same detector/recovery family | Avoid parallel edits to same detector files |
| `flywheel-viux` | P1 `in_progress` | Idle-state-class doctor signal | Coordinate with Lane B doctor output |
| `flywheel-zidg` | P1 open | NTM-only pane-state reads | Coordinate with topology/pane-state source |
| `flywheel-1255t` | P1 open | Callback-overdue circuit breaker | Can run parallel if it avoids topology/credential code |

The queue has more P0/P1 beads, but these are the ones that materially constrain the Lane A/B/C integration surface.

## Frozen Projection Extension

Trauma class: `frozen-projection-of-mutable-state`

Definition: a long-lived payload, template, plist, cron job, prompt file, or driver script captures a mutable value at render/install time, then continues to act on it after the authoritative state has changed.

Accepted skillos verdict: Option C Hybrid. Use a watcher for state changes plus a lower-cadence heartbeat cron. Both must name authoritative paths or queries, not captured mutable values.

Canonical L-rule proposal:

`templates-name-sources-not-values`

Draft rule:

Long-lived templates, cron payloads, LaunchAgent `ProgramArguments`, dispatch scaffolds, tick prompts, and watcher payloads may name authoritative source paths, selectors, query names, or schema fields. They must not bake mutable values captured at install or render time. If a value can change during the lifetime of the process, the emitted payload must force read-at-fire-time from the source.

Allowable literals: immutable version IDs, hashes, static repo paths, schema names, command names, and documented constant labels.

Forbidden literals: blocker IDs, active profile names, pane roles, pane IDs, topology rows, timestamps used as freshness claims, secret values, current owner names, and current recovery decisions when those can change before the next fire.

Sibling doctrine:

| Rule | Relationship |
|---|---|
| SEC-001 mission-lock secret-values | Secret dispatches name vault paths/classes, not secret values |
| L116 tick-is-process | Tick must be driven by a process, not a stale document |
| L57 loop-state-marker-not-driver | Active markers are not enough without live driver proof |
| L110 outflow drain | Receipts and callbacks must prove state actually moved |

## Fleet Sweep Targets

| Target | Sweep question | Initial note |
|---|---|---|
| `~/.local/state/flywheel/session-topology.jsonl` | Do drivers read latest topology at fire-time? | Mutable source of truth; do not freeze rows into plists |
| `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick` line 161 area | Are positional args/defaults and blocker IDs live-read, not frozen? | Current line number drifted; inspect `update_blocker_tick_counter` and `send_fleet_escalation_capsule` |
| Per-session stuck-detector plists | Do plists name topology source rather than pane values? | `ai.zeststream.codex-stuck-detector-watchdog.plist` uses `--worker-panes-from-topology`, a good pattern |
| ALPS tick prompt | Does it reference current mission/state paths instead of frozen blocker text? | Peer repo owns implementation |
| skillos cron-literal templates | Do cron prompts read current blocker state instead of literal `blocker_id`? | skillos owns implementation; flywheel owns invariant |

Observed plist examples to include in sweep:

`ai.zeststream.alps-codex-stuck-detector.plist`, `ai.zeststream.alps-flywheel-loop.plist`, `ai.zeststream.flywheel-codex-stuck-detector.plist`, `ai.zeststream.mobile-eats-flywheel-loop.plist`, `ai.zeststream.skillos-flywheel-loop.plist`, `ai.zeststream.skillos-codex-stuck-detector.plist`, `ai.zeststream.vrtx-codex-stuck-detector.plist`.

Ownership split:

| Owner | Responsibility |
|---|---|
| flywheel | Canonical L-rule, doctor invariant, fleet sweep coordination, fixture/test pattern |
| mobile-eats | Tick script implementation fix |
| ALPS | Tick prompt implementation fix |
| skillos | Cron-literal template implementation fix |
| peer sessions | Local watcher/heartbeat deployment |

## Doctor Invariant Proposal

Add a doctor check, backed by a script such as:

`.flywheel/scripts/frozen-projection-invariant-scan.sh`

Scan inputs:

1. `~/Library/LaunchAgents/*.plist`
2. `~/.local/bin/*flywheel-loop-tick`
3. `.flywheel/scripts/*tick*`, `.flywheel/scripts/*watch*`, `.flywheel/scripts/*stuck*`
4. `.flywheel/templates/**`, `templates/**`
5. dispatch and command surfaces under `~/.claude/commands/` when relevant

Flag patterns:

| Pattern | Meaning |
|---|---|
| `blocker_id=<literal>` in long-lived payloads | stale blocker projection |
| `pane=<number>` or `worker_panes=<literal-list>` in plists | stale topology projection unless explicitly static |
| serialized `session_topology`, `role`, `effective_at`, `last_seen` in prompt templates | stale topology projection |
| active profile or credential state literals in cron payloads | stale credential-state projection |
| unguarded positional arg expansion in tick scripts | line-drift / stale payload fragility |

Allow patterns:

| Pattern | Reason |
|---|---|
| `--worker-panes-from-topology` | names source, not value |
| `--topology-file <path>` | read-at-fire-time |
| `state_file=...`, `blocker_state_path=...` | source reference |
| `Read <path> then decide` in prompt payload | source-driven |
| immutable git sha/version hash | stable by design |

Doctor output fields:

`frozen_projection_count`, `frozen_projection_by_target`, `literal_payload_targets`, `path_named_payload_targets`, `oldest_literal_age_sec`, `scan_files`, `status=pass|warn|fail`.

Initial severity:

`warn` for first fleet rollout; promote to `fail` for new or modified templates once the sweep completes.

## Tests / Fixtures Designed

1. Missing WOE ledger: absent canonical ledger yields explicit `ledger_missing_expected=true`, not silent pass.
2. Lane A WOE row: unresolved `codex_usage_limit` row closes only with `credential_rotation` receipt and no pane mutation.
3. Lane B WOE row: unresolved `topology_stale` row closes only with topology refresh receipt, source path, and freshness age.
4. Cross-owned WOE rows: open rows owned by `flywheel:1` and `flywheel:pane-1` are both listed; other orch owners are not silently hidden.
5. Dependency stage split: vault-only credential rotation succeeds with stale topology; pane recovery refuses until topology is fresh.
6. L87 sunset guard: `flywheel-pp1g` still `in_progress` or fresh divergence rows prevent L87 retirement.
7. Frozen cron literal: cron payload with literal `blocker_id=...` fails invariant.
8. Source-name cron: cron payload with `blocker_state_path=...` passes invariant.
9. Stuck-detector plist: `--worker-panes-from-topology` passes; literal pane list in a LaunchAgent fails.
10. Tick-script arg guard: unguarded `$2` under `set -u` fails fixture; guarded `${2:-}` passes.

## Skill Citations

Skills consulted:

1. `beads-workflow`
2. `codebase-audit`
3. `agent-mail`
4. `agent-orchestration`
5. `agent-lifecycle`

Reference router citations:

1. `~/.claude/references/claude-md-beads.md`
2. `~/.claude/references/claude-md-ntm.md`

Socraticode survey:

`socraticode_queries=10`

Primary query areas: WOE ledger/close gate, L87/flywheel-pp1g, topology-stale authorization, capacity halt recovery, CAAM/credential rotation, and blocked P0/P1 beads.

## Joshua Blocker Check

No true Joshua blocker is present for Lane C research, the L-rule proposal, or the doctor invariant proposal.

CAAM live OAuth rotation tests may remain deferred to a separate credential/OAuth bead if active OAuth login is required. That does not block the architecture: Lane A can design and implement a vault-only recovery primitive with test fixtures, while live credential replacement follows the existing no-token-rotation rule and explicit Joshua authorization boundary.

## L112 Observation

`OK_orch_uptime_laneC_research_complete`

## Callback Fields

`lane=C`  
`self_grade=8`  
`socraticode_queries=10`  
`skills_cited=5`  
`donella_trace=present`  
`joshua_blocker_class_check=passed`  
`test_cases_designed=10`  
`existing_substrate_extended=true`  
`new_files_proposed=2`

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
