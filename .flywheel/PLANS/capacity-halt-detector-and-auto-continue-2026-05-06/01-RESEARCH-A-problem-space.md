---
title: "Phase 1 Lane A - Problem-Space Inventory"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 1 Lane A - Problem-Space Inventory

Plan arc: `capacity-halt-detector-and-auto-continue-recovery`.
Dispatch: `plan-capacity-halt-detector-and-auto-continue-2026-05-06`.
Scope: plan-space only; no detector, watcher, test, memory, or peer-repo mutation.

## Source-(a) And Survey Inputs

- Skills: `planning-workflow`, `research-triad`, `codebase-archaeology`, `jeff-convergence-audit`, `donella-meadows-systems-thinking`, `codex-cli-tracker`, `loop-enforcement`, `accretive-cron-orchestration`, `observability-platform`, `socraticode`.
- Command surfaces read: `/flywheel:plan` and `/flywheel:skills-best-practices`.
- Socraticode survey count at Phase 1 close: 10 queries.
- Empirical rows: `~/.local/state/flywheel/fuckup-log.jsonl#L1544`, `#L1575`, `#L1579`, later recurrence `#L1619`, and shipped-but-not-wired regression `#L1620`.

## Taxonomy

| Class | Primary signal | Local process state | Correct first recovery | Wrong recovery |
|---|---|---|---|---|
| `model_at_capacity_halt` | Last 50 lines contain `selected model is at capacity` or `please try a different model`, plus stable chevron prompt | Codex is alive, upstream capacity rejected current attempt | Bounded `continue` through `ntm send` with finite `y` confirmation | Respawn first; it loses task context |
| `api_error` | Auth, quota, network, or provider error without chevron retry affordance | Usually alive but blocked on external/substrate class | Provider/substrate probe and explicit fallback path | Blind `continue` loop |
| `frozen_pane` | Multi-frame no delta while robot activity says THINKING/GENERATING | Local pane or process may be wedged | Existing frozen-pane detector and gated respawn/relaunch | `continue`; it may be swallowed |
| `post_callback_reminder_template_with_stale_spinner` | Done/reminder prompt plus stale spinner residue | Codex has probably returned to prompt but display state is stale | Existing escape-then-reprompt-or-respawn primitive | Treat as capacity halt |
| `queued_not_submitted` | Prompt queued but not submitted after threshold | Input transport problem | Existing queued detector/recovery path | Provider fallback |
| `unknown_stable` | Stable hash, no known class | Detector knowledge gap | Snapshot, fuckup-log row, manual review/bead | Auto-mutating pane |

The class boundary is narrow: `model_at_capacity_halt` requires the capacity string, not merely a bare chevron. Chevron alone remains `unknown_stable` or prompt-ready depending on context.

## Empirical Failure-Mode Table

| Evidence | Panes | Observed behavior | Recovery evidence | Plan implication |
|---|---:|---|---|---|
| `fuckup-log#L1544` | Initial cluster, pane list omitted | Upstream capacity text halted codex at chevron | Joshua direct observation | Detector class must be first-class, not a generic stuck bucket |
| `fuckup-log#L1575` | `flywheel:4`, `alpsinsurance:2`, `alpsinsurance:4` | Simultaneous cross-session capacity burst | `ntm send ... "continue"` recovered | Watcher must serialize or budget burst work per pane/session |
| `fuckup-log#L1579` | `flywheel:2` | Fifth instance in the same burst window | `continue` applied | Same-pane budget required; repeated attempts imply persistent capacity |
| `fuckup-log#L1619` | `flywheel:3` | Sixth instance during plan-arc execution | `continue` | Plan must assume recurrence after code-space landing |
| `fuckup-log#L1620` | `flywheel:2`, `flywheel:3`, `flywheel:4` | Claimed subclass/live smoke did not prevent manual recovery; live classify reportedly returned `alive` | Manual `continue` still needed | Phase 4 must start with production-path reconcile, not greenfield build |

Simulated edges for Phase 4 test design:

| Edge | Expected classification | Expected action |
|---|---|---|
| Capacity string + stable chevron | `model_at_capacity_halt` | `auto_continue` if worker pane and budget remains |
| Capacity string + no chevron | provider/error review | no blind auto-send |
| Chevron alone | not capacity | no auto-continue |
| Same pane capacity 5 times/hour | `model_at_capacity_halt` | notify fallback after budget, no infinite loop |
| Orchestrator/human/callback pane capacity | protected refusal | notify or peer-orch permit track, no direct worker policy |
| Cross-session worker capacity | worker-scope permitted only if topology says worker and callback path is live | ledgered send, post-send measurement |
| `Continue anyway? [y/N]` prompt from transport | transport confirmation | finite `printf 'y\n'` pipe, never unbounded yes as primary |

## Criticality Matrix

| Class | Blast radius | Recovery cost | Manual recovery time | Criticality |
|---|---|---:|---:|---|
| Single worker capacity halt | One bead/dispatch idle | Low if recovered in place | 15-60 seconds once seen | Medium |
| Burst across several workers | Fleet throughput collapse during peak model load | Low per pane, high coordination load | Several minutes plus attention tax | High |
| Persistent capacity >5 minutes | Current model unavailable for that lane | Medium: fallback model or redispatch needed | 5-15 minutes | High |
| Protected/orchestrator capacity | Control plane may be affected | High if wrong actor mutates it | Human/peer recovery path | High |
| Misclassified capacity as `alive` | Silent watchdog failure | High because no recovery fires | Open-ended until Joshua notices | P0 regression |

Donella read: this is mainly leverage point #4, self-organization, with #6 information flows. The system already has the recovery primitive; the missing loop is classification, bounded action, and measurement.

## Open Questions For Phase 2

1. Should the final code-space work extend `codex-template-stuck-detector` only, or also keep `worker-auto-respawn-watchdog` live-classification as a sibling guard? Initial answer: extend the classifier and let the watchdog consume it, but Phase 4 must reconcile the already-landed worker changes.
2. What is the exact success measurement after `continue`? Initial answer: recapture after 5-10 seconds and require either output delta, disappearance of capacity text, or transition to THINKING/GENERATING.
3. How should cross-session worker sends be authorized? Initial answer: latest topology must classify the target as worker; peer orchestrator/callback receiver liveness proof is required for peer sessions; protected panes are refused.
4. How does idempotency prevent double-`continue` cascades? Initial answer: per-pane lease plus attempts ledger keyed by `(session,pane,hash_t1,capacity_text_digest)` with finite confirmation.
5. What is persistent-capacity behavior? Initial answer: after 5/hour or 3 failed success checks, route to fallback-model/redispatch plan and notify only with ledger proof.
