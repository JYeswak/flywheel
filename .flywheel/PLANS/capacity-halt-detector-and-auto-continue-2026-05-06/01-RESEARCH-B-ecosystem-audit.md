---
title: "Phase 1 Lane B - Ecosystem Audit"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 1 Lane B - Ecosystem Audit

Plan arc: `capacity-halt-detector-and-auto-continue-recovery`.
Scope: plan-space only.

## Source-(a) And Survey Inputs

- Skills: `planning-workflow`, `research-triad`, `codebase-archaeology`, `jeff-convergence-audit`, `donella-meadows-systems-thinking`, `codex-cli-tracker`, `loop-enforcement`, `accretive-cron-orchestration`, `observability-platform`, `socraticode`.
- Socraticode survey count: 10 total by Phase 1 close.
- Evidence rows: `fuckup-log#L1544`, `#L1575`, `#L1579`, `#L1619`, `#L1620`.

## ADOPT / EXTEND / AVOID

| Primitive | Decision | Why | Required Phase 4 proof |
|---|---|---|---|
| `.flywheel/scripts/codex-template-stuck-detector.sh` | EXTEND/RECONCILE | It already owns Codex subclass taxonomy, `recommended_recovery`, ledger, doctor fields, and fixture mode. Current dirty tree appears to include `model_at_capacity_halt`, but `fuckup-log#L1620` says a production path failed. | Live-string fixture and live-pane replay must prove the classifier path, not only metadata/schema. |
| `.flywheel/scripts/worker-auto-respawn-watchdog.sh` | EXTEND/RECONCILE | It owns worker-scope action routing, budgets, topology scan, and notify fallback. Current info surface declares `model_at_capacity_halt -> auto_continue`. | Install/launchd proof plus apply-mode dry-run/action ledger for one fixture and one live dry-run. |
| `.flywheel/scripts/frozen-pane-detector.sh` | ADOPT AS GUARDRAIL | It has recovery ledgers, leases, cooldowns, `--apply` separation, and cross-session allow flags. | Reuse its idempotency and receipt discipline, but do not duplicate its frozen classes. |
| `.flywheel/scripts/fleet-watcher-coverage-probe.sh` | EXTEND | It exposes watcher coverage and stale-dispatch doctor fields across sessions. Capacity-halt watcher coverage must appear here or an equivalent doctor surface. | Include capacity watcher labels/driver proof, especially flywheel session LaunchAgent coverage. |
| `halt-contract/v1` and halt-disease tests | ADOPT CONCEPT | They distinguish blocked actions from permitted safe work. Capacity halt blocks only the current model attempt, not all local work. | Persistent capacity should produce scoped halt contract: block same-model retry, permit fallback/redispatch/read/plan. |
| Peer-orch permit gate L115 | ADOPT BOUNDARY | `flywheel:1` owns peer-orch recovery only through a permit gate. Worker auto-continue is narrower than peer-orch respawn but still cross-session mutation. | Protected panes refused; peer orchestrator path must use L115-equivalent proof before any apply. |
| Raw `yes | ntm send ...` | AVOID AS PRIMARY | It can mask unexpected prompts and cascade. Existing R3 workaround test proves finite `printf 'y\n'` is safer. | Auto-continue primitive must use one finite confirmation input and record prompt/ack outcome. |
| New sibling capacity watcher | AVOID FOR NOW | The classifier/watchdog chain already exists. A sibling watcher would split authority. | Only build a sibling if Phase 4 proves existing classifier cannot safely host capacity class. |

## Cross-Cutting Findings

1. **The class is not a process death.** `worker-auto-respawn-watchdog` must treat capacity halt as recoverable halt before respawn. Current code-space artifacts appear to do that, but the live regression row forces validation.
2. **The burst is a fleet information-flow problem.** The first pane hit is a predictor that gpt-5.5 xhigh may be overloaded across sessions. The watcher should expose `capacity_halt_count_30m` and `capacity_halt_sessions_top`, not bury attempts in per-pane rows only.
3. **Cross-session recovery is allowed only when topology and closure are live.** AGENTS L86 forbids cross-session worker dispatch without remote callback liveness; L115 permits peer-orch recovery with a gate. Capacity auto-continue should stay worker-scope and refuse orchestrator/human/callback panes.
4. **The launchd driver is part of the feature.** A classifier that passes tests but has no loaded watcher is a marker-only win. Phase 4 must prove LaunchAgent loaded in `gui/<uid>` and recent log/event evidence exists.
5. **Doctor surfaces need success rate, not only fired count.** Existing detector doctor fields already include `codex_stuck_recovery_success_pct`; capacity halt needs the same kind of measurement plus budget exhaustion and protected refusal counts.

## Doctrine Reshaping

- Recurrence count crossed the "tool it, do not page Joshua" threshold on 2026-05-06. This belongs in autonomous recovery tooling, not human notification first.
- The class is OpenAI/Codex upstream capacity behavior, not Jeff-stack behavior. Do not file a Jeff issue from this dispatch.
- `continue` is safe only as a bounded in-place retry when the capacity string is still visible and the target is a worker pane.
- A post-code-space regression already exists. The plan therefore becomes the canonical Phase 4 checklist: reconcile existing code, prove live matching, prove driver/install coverage, then close.

## Adopted Skill Guidance

- `planning-workflow`: keep the plan artifact as the work product and defer code until Phase 4.
- `research-triad`: separate problem, ecosystem, and design lanes.
- `codebase-archaeology`: reuse local detector/watchdog shapes before inventing.
- `jeff-convergence-audit`: audit for blocker-class truth, not taste.
- `donella-meadows-systems-thinking`: classify this as a self-organization loop plus information-flow measurement.
- `codex-cli-tracker`: capacity/CLI behavior is volatile; use live probes and current artifacts rather than memory.
- `observability-platform`: recovery needs event, count, success-rate, and saturation metrics.
- `loop-enforcement` and `accretive-cron-orchestration`: loaded driver proof is required; state markers alone are not enough.
