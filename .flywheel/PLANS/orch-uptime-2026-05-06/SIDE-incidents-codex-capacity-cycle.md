# Codex Capacity Cycle INCIDENTS Promotion Research

Date: 2026-05-06
Mode: read-only research
Socraticode: K=10 across `/Users/josh/Developer/flywheel` and `/Users/josh/Developer/mobile-eats`

## Recommendation

Promote the mobile-eats finding as a canonical flywheel INCIDENTS additive
entry under class `codex-capacity-cycle-throttle`.

Do not merge the trauma class into `codex_usage_limit`. Use:
- Incident / trauma class: `codex-capacity-cycle-throttle`
- Detector subclass: `codex_usage_limit`
- Recovery primitive: `caam_auto_rotate`

Reason: `codex_usage_limit` is the concrete detector/recovery subclass from
orch-uptime Lane A. The trauma is broader: single-pane topology converts a
Codex capacity/quota cycle into fleet idle. The Lane A A1/A2 cure is still the
right implementation path.

## Proposed Canonical INCIDENTS Additive Entry

```markdown
## Codex capacity cycles stall single-pane projects (2026-05-06)

Date: 2026-05-06

Promotion Action: NEW

Class: `codex-capacity-cycle-throttle`

Event Count: 2 capacity cycles in mobile-eats on 2026-05-06, plus one
170.2min rank-1 idle gap classified to the second cycle/recovery path.

Severity: high for single-pane projects; medium for multi-pane projects with
different model/provider fallback.

Cost: mobile-eats lost a 170.2min idle gap from 14:15:19Z to 17:05:30Z,
rank 1 idle gap of the day. The same diagnostic attributes 276min / 514min
= 53.7% avoidable idle to substrate-level traumas, with capacity-cycle
throttle as the largest contributor. The original finding also observed two
capacity cycles roughly 66min apart; cycle 1 cost about 9min and cycle 2
started as an 11-12min capacity stall before compounding into the 170min dry
stretch. Every single-worker flywheel project using a Codex high-demand tier
carries equivalent full-loop stall exposure.

Root Cause: Codex capacity/quota text is treated as a generic pane ERROR and
single-pane project topology has no alternate worker/model tier. The
orchestrator passively waits or retries the same throttled pane instead of
classifying the signal, rotating to an already-vaulted CAAM profile when the
signal is `codex_usage_limit`, or routing work to a different pane/model.

Forever-Rule: When a Codex pane reports capacity or usage-limit throttle,
orchestrators must classify the signal before treating it as worker failure.
For `codex_usage_limit`, route through the Lane A cure:
`codex_usage_limit -> caam_auto_rotate` with `recovery_class=credential_rotation`
and a no-secret recovery receipt. For model-capacity stalls, do not dispatch
new work to the throttled pane unless an explicit `--accept-stall` receipt is
present; route the next safe P0/P1 bead to a different model tier/provider or
secondary pane where available. Single-pane flywheel projects must carry either
a secondary-capacity plan or an explicit accepted-stall receipt.

Fix Applied/Status: PROPOSED canonical promotion. Implementation is already
represented in orch-uptime Lane A:
- A1 `flywheel-orch-uptime-caam-auto-rotate-primitive-2026-05-06` adds the
  dry-run-default CAAM selector primitive for vaulted Codex profiles.
- A2 `flywheel-orch-uptime-detector-codex-usage-limit-2026-05-06` adds the
  `codex_usage_limit` detector subclass and routes recovery to
  `caam_auto_rotate`.
This incident should close only after A1/A2 land, detector sibling regressions
stay green, and the dispatch surface exposes the `--accept-stall` or fallback
routing behavior.

Evidence:
- Source finding:
  `/Users/josh/Developer/mobile-eats/.flywheel/findings/2026-05-06-codex-capacity-cycle.md`.
- Mobile-eats local INCIDENTS rule promotion:
  `/Users/josh/Developer/mobile-eats/.flywheel/INCIDENTS.md` section
  `2026-05-06T19:30Z -- RULE PROMOTION: Capacity throttling on single-pane topology...`.
- CAAM diagnostic:
  `/Users/josh/Developer/mobile-eats/.flywheel/audits/2026-05-06-caam-diagnostic.md`
  section 2 rank 1 (170.2min) and avoidable idle line (53.7%).
- Orch-uptime Lane A research:
  `/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/01-RESEARCH-A.md`.
- Orch-uptime DAG:
  A1 `flywheel-orch-uptime-caam-auto-rotate-primitive-2026-05-06`;
  A2 `flywheel-orch-uptime-detector-codex-usage-limit-2026-05-06`.
```

## A1/A2 Cross-Reference

- A1 is the cure primitive: `caam-auto-rotate-on-usage-limit.sh`, dry-run by
  default, no token/auth/vault value output, no OAuth refresh, no launchctl,
  no pane mutation.
- A2 is the classifier wire: add `codex_usage_limit` with six pattern families
  (`usage limit`, `Limit reached`, `rate_limit_exceeded`, `Plan free tier`,
  `try again in`, `429 Too Many`) and route only `--auto-recover --apply` to
  A1.
- A2 depends on A1 and W0; it coordinates with the existing
  `flywheel-wire-codex-model-at-capacity-halt-class-c38ad0dd` sibling to avoid
  regressing `model_at_capacity_halt`, queued-not-submitted, OOM, post-callback,
  and unknown-stable behavior.

## Promotion Order vs Other 7 Mobile-Eats Traumas

Recommended order by uptime impact, cross-project blast radius, and cure
readiness:

1. `codex-capacity-cycle-throttle` - promote now. Rank-1 170.2min idle gap,
   53.7% avoidable-idle context, and A1/A2 cure already scoped.
2. `codex-chevron-stuck-on-dispatch` - high severity, repeated 5x dispatch
   non-submission; should pair with dispatch delivery receipt/L91 and
   `dispatch-and-verify`.
3. `beads-symlink-escape` - high severity, 6+ WARNs, can make `br ready` look
   empty during active-high loops.
4. `load-bearing-substrate-shipped-without-skill-suite` - high quality/velocity
   debt, rank-2 idle contributor via skill-suite supplement/re-dispatch.
5. `background-poll-race-on-dispatch-handoff` - medium, rank-3 28.6min idle
   contributor; cheap helper/gate fix.
6. `orch-trust-trap-agentmail-as-completion-signal` - already registered in
   flywheel canonical INCIDENTS; update only if adding new mobile-eats evidence.
7. `mission-lock-undersells-design-system-substrate` - high product/process
   severity but already flowing through mission-lock paradigm work; promote
   after uptime blockers above unless that plan stalls.
8. `orch-no-punt-gate-stale-pane-metrics` - low, straightforward hook source
   fix; promote after high/medium uptime classes.

## Read-Only Notes

- `br` live reads hit the existing BusySnapshot failure; A1/A2 details were
  verified through `00-PLAN.md`, `04-BEADS-DAG.md`, and append-only
  `.beads/issues.jsonl`.
- No repo files, beads, ledgers, or INCIDENTS.md files were mutated.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
