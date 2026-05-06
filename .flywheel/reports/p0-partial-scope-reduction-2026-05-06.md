# P0 PARTIAL Bead Scope Reduction - 2026-05-06

Task: `p0-partial-scope-reduction-research-2026-05-06`.

Source audit: `.flywheel/reports/p0-bead-freshness-audit-2026-05-06.md`.

Scope: plan-space research only. No bead bodies, bead statuses, dispatch-log rows,
memory files, skill files, or substrate code were mutated.

Socraticode preflight: 8 queries against `/Users/josh/Developer/flywheel`;
Socraticode status showed 976 indexed chunks; 80 result chunks observed.

## Enumeration Correction

The dispatch packet listed `flywheel-2bfg`, `flywheel-2gix`, and
`flywheel-3iz0` as PARTIAL candidates, but the audit marks them FRESH. The audit
marks three omitted beads as PARTIAL: `flywheel-8na7`, `flywheel-dt2w`, and
`flywheel-olrx`. This report analyzes the audit's real eight PARTIAL beads.

### flywheel-1bt7 | [wire-or-explain] A9 L55 skillos-relay auto-fire (Finding 10)

**Original bead body claim**: "Wire L55 skillos-escalation-for-missing-skills auto-fire. Trauma classes without skillos route emit relay row."

**What's already substrate-shipped** (from audit live-probe evidence):
- `flywheel-skillos-relay --info --json` exists as a canonical relay binary.
- `tests/flywheel-skillos-relay-canonical-cli.sh` passed; classifier route for skill candidates exists.

**What's left to do** (residual scope):
- Prove live pending skill-candidate rows auto-drain to skillos.
- Emit durable drain receipts and warn on stale or failed drains.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Finish L55 skillos relay auto-drain: consume pending skill-candidate rows on tick, emit skillos relay/drain receipts, and surface stale or failed drains in doctor/status. Existing relay CLI/classifier already count as shipped.

**Donella analysis**: which leverage point does the residual scope touch?
- #4 self-organization.
- Reasoning: the residual lets the system turn recurring missing-skill findings into skillos work without human routing.

**Joshua-decision-needed**: APPROVE_NEW_BODY

### flywheel-1kha | [wire-or-explain] A7 L53 callback fuckup-field validator + foundational-tool-repeat-halt

**Original bead body claim**: "Wire L53 callback fuckup-field validator. Adds CoralRaven foundational-tool-repeat-halt: scan last 3 callbacks for >=2 same foundational-tool risk_flag, halt + cross-orch help."

**What's already substrate-shipped** (from audit live-probe evidence):
- Dispatch template requires `fuckups_logged=`.
- The template rejects `BLOCKED` callbacks with `fuckups_logged=none`.

**What's left to do** (residual scope):
- Scan recent callbacks for repeated same foundational-tool risk flags.
- Halt or route cross-orch help with a receipt/count when the repeat class appears.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Implement only the foundational-tool repeat-halt half: scan recent callbacks for repeated same foundational-tool risk_flag, halt/route cross-orch help, and expose a receipt/count. L53 fuckups_logged callback contract is already wired.

**Donella analysis**: which leverage point does the residual scope touch?
- #5 rules.
- Reasoning: the residual changes the callback close rule from "log the trauma" to "stop repeat foundational-tool churn."

**Joshua-decision-needed**: APPROVE_NEW_BODY

### flywheel-1wjt | [wire-or-explain] A6 L52 issues-beads-or-no-bead-receipt enforcer

**Original bead body claim**: "Wire L52 issues->beads-or-explicit-no-bead-receipt enforcer. Probe scans observed gaps without absorption."

**What's already substrate-shipped** (from audit live-probe evidence):
- Dispatch template requires `beads_filed=`, `beads_updated=`, or `no_bead_reason=`.
- `.flywheel/scripts/validate-callback.py` parses `no_bead_reason` and fails receipts without valid bead actions.

**What's left to do** (residual scope):
- Build a standalone observed-gap scanner beyond callback validation.
- Warn on observed gaps that were absorbed without a bead or explicit no-bead reason.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Add the standalone L52 observed-gap scanner: find observed gaps lacking beads_filed, beads_updated, or no_bead_reason outside callback validation, emit warn rows, and leave current callback validator untouched.

**Donella analysis**: which leverage point does the residual scope touch?
- #6 information flows.
- Reasoning: the residual exposes silent finding loss that is outside the callback envelope already enforced.

**Joshua-decision-needed**: APPROVE_NEW_BODY

### flywheel-2fz8z | [wire-or-explain] H2 phase-anchor-probe.sh doctor field + dispatcher refusal hook

**Original bead body claim**: "phase-anchor-probe.sh reads .flywheel/MISSION.md Section 3, derives current_open_phase, surfaces phase_anchor_violations_24h doctor field."

**What's already substrate-shipped** (from audit live-probe evidence):
- `.flywheel/scripts/mission-anchor-dispatch-license.sh` emits `current_open_phase`.
- The same surface reads and weights `phase_tag` data.

**What's left to do** (residual scope):
- Add the named `phase-anchor-probe.sh` or equivalent doctor field.
- Refuse dispatches where `task.phase_tag > current_open_phase + 1`.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Wire the missing phase-anchor named surface: add phase-anchor-probe/doctor field and dispatcher refusal for task.phase_tag beyond current_open_phase+1, reusing existing mission-anchor current_open_phase data.

**Donella analysis**: which leverage point does the residual scope touch?
- #5 rules.
- Reasoning: the residual makes phase order a dispatch rule instead of only a visible mission-license datum.

**Joshua-decision-needed**: APPROVE_NEW_BODY

### flywheel-2x5yi | [wire-or-explain] H7 flywheel-watchers canonical CLI for plist on/off/status

**Original bead body claim**: "Canonical CLI shipped 2026-05-05T00:38Z at ~/.local/bin/flywheel-watchers. Single command turns 39 ZestStream plists on/off/status by repo."

**What's already substrate-shipped** (from audit live-probe evidence):
- `flywheel-watchers --info --json` exists and reports registry/ledger paths.
- `tests/flywheel-watchers-test.sh` passed 62/62; live status reported watcher rows.

**What's left to do** (residual scope):
- Prove exact `watcher_off_age_seconds` doctor integration.
- Surface stale/off watcher age through loop doctor/status.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Reduce H7 to doctor integration only: expose watcher_off_age_seconds and stale/off status from the shipped flywheel-watchers CLI/ledger so loop doctor can alert on disabled plists aging out.

**Donella analysis**: which leverage point does the residual scope touch?
- #6 information flows.
- Reasoning: the remaining work puts already-recorded watcher state where the orchestrator can act on it.

**Joshua-decision-needed**: APPROVE_NEW_BODY

### flywheel-8na7 | [wire-or-explain] A12 L61 3-surface drift error escalation

**Original bead body claim**: "Wire L61 doctrine-landing-3-surface drift error escalation."

**What's already substrate-shipped** (from audit live-probe evidence):
- `.flywheel/scripts/doctrine-3-surface-divergence-probe.sh --json` exists and returns divergent rows.
- `.flywheel/scripts/doctor-signal-bead-promotion.sh` consumes `doctrine_3_surface_divergent_count`.

**What's left to do** (residual scope):
- Resolve or explicitly route the current two divergent doctrine rows.
- Keep the existing detector and promotion path unchanged.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Reduce A12 to current 3-surface divergence drain: resolve or route the two live divergent doctrine rows surfaced by doctrine-3-surface-divergence-probe, preserving the existing detector/promotion wiring.

**Donella analysis**: which leverage point does the residual scope touch?
- #5 rules.
- Reasoning: the detector exists; the residual enforces the rule that drift must drain instead of remaining a known red signal.

**Joshua-decision-needed**: APPROVE_NEW_BODY

### flywheel-dt2w | [wire-or-explain] dispatch worker-side branch enforcement

**Original bead body claim**: "Enforce worker-side branch discipline in dispatch packets and callbacks so local-main worker artifacts cannot be silently reset away."

**What's already substrate-shipped** (from audit live-probe evidence):
- `tests/wire-or-explain-classifier.sh` passed `worker_branch_records_ref_and_identity_hash`.
- Classifier and ledger writer support `branch_ref` and identity proof fields.

**What's left to do** (residual scope):
- Require branch/ref proof in dispatch packets and callbacks for implementation tasks.
- Reject or mark local-main worker commit proof unresolved in the ledger.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Reduce B13 to dispatch/callback contract enforcement: require branch_ref plus identity_proof in implementation dispatches and callbacks, and reject/local-main unresolved rows. Classifier/ledger shape is already shipped.

**Donella analysis**: which leverage point does the residual scope touch?
- #5 rules.
- Reasoning: the residual makes branch identity proof a close/dispatch contract, not just a classified artifact shape.

**Joshua-decision-needed**: APPROVE_NEW_BODY

### flywheel-olrx | [wire-or-explain] C7 dispatch-template L111 inheritance + bead acceptance gate

**Original bead body claim**: "Upstream wiring that makes C1-C5 produce rows automatically."

**What's already substrate-shipped** (from audit live-probe evidence):
- Dispatch template contains L111 judge score fields.
- Dispatch template contains the `AUTO-L112 CALLBACK GATE BLOCK`.

**What's left to do** (residual scope):
- Prove automatic row production for the C1-C5 chain.
- Tie bead acceptance gates to the row production path instead of only template text.

**Proposed reduced bead body** (verbatim, <=280 chars, the new scoped claim):
> Reduce C7 to automatic row production: prove dispatch-template L111/AUTO-L112 inheritance creates the required C1-C5 ledger rows from bead acceptance gates. Existing score fields and AUTO-L112 block are shipped.

**Donella analysis**: which leverage point does the residual scope touch?
- #4 self-organization.
- Reasoning: automatic row production lets new dispatches create their own validation substrate without a separate orchestrator reminder.

**Joshua-decision-needed**: APPROVE_NEW_BODY

## Summary Table

| bead_id | residual_scope_size_chars | leverage_point | recommendation |
|---|---:|---|---|
| flywheel-1bt7 | 226 | #4 self-organization | APPROVE_NEW_BODY |
| flywheel-1kha | 234 | #5 rules | APPROVE_NEW_BODY |
| flywheel-1wjt | 210 | #6 information flows | APPROVE_NEW_BODY |
| flywheel-2fz8z | 208 | #5 rules | APPROVE_NEW_BODY |
| flywheel-2x5yi | 190 | #6 information flows | APPROVE_NEW_BODY |
| flywheel-8na7 | 203 | #5 rules | APPROVE_NEW_BODY |
| flywheel-dt2w | 219 | #5 rules | APPROVE_NEW_BODY |
| flywheel-olrx | 211 | #4 self-organization | APPROVE_NEW_BODY |

## Highest-Leverage PARTIAL Beads

1. `flywheel-1bt7`: missing-skill relay auto-drain compounds across the whole skill library by routing recurring skill gaps into skillos.
2. `flywheel-dt2w`: branch/ref proof prevents local-main worker artifacts from being reset away, which protects implementation substrate.
3. `flywheel-olrx`: automatic C1-C5 row production makes dispatch validation self-producing instead of operator-maintained.

## Lowest-Effort PARTIAL Beads

1. `flywheel-2x5yi`: CLI and ledger already exist; residual is a doctor/status readout field.
2. `flywheel-8na7`: detector and promotion path already exist; residual is resolving or routing the two live divergent rows.
3. `flywheel-1wjt`: callback validation is shipped; residual is a narrow scanner for observed gaps outside the callback envelope.

## Donella Aggregate

Leverage distribution: #5 rules = 4, #6 information flows = 2, #4 self-organization = 2.

Interpretation: most PARTIAL beads are no longer missing raw observation; they
are missing rule enforcement at dispatch/close boundaries. The substrate state
has moved from "can we see the gap?" toward "does the system drain the gap
automatically and refuse unsafe continuation?"
