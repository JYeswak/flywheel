# Halt-disease structural fix — converged plan

**Author:** RubyCastle synthesis of Lanes A/B/C (codex panes 2/3/4) + orchestrator
**Date:** 2026-05-04
**Joshua approval:** "yes - take the most jeff approved /donella-meadows-systems-thinking approach - execute"
**Trauma class:** `halt-by-default-cascades-through-every-layer`

## Diagnosis (3-lane unanimous)

A non-fatal signal in any lower layer (doctor / validator / escalation) is promoted to a whole-fleet stop because the contract lacks a scoped continuation outcome. The signal may be true, but the action is overbroad. Doctor's `status=fail` becomes tick's `exit 1` becomes validator's `BLOCK_CLOSE` becomes escalation's `wait_for_RubyCastle` becomes Joshua-mornings-with-idle-fleet.

Meadows leverage points the disease lives at:
- **#5 RULES** — wrong rule: `unscoped fail = halt`. Right rule: `truth blocks lies; safety blocks risk; everything else becomes routed work`.
- **#4 SELF-ORGANIZATION** — missing primitive: a session can't generate a permitted-work route from the failure itself. Has to wait for a human reinterpretation.
- **#6 INFORMATION FLOWS** — every signal must carry both `blocked_actions[]` AND `permitted_actions[]` in the same machine-readable artifact.

Anti-patterns matched (per `donella-meadows-systems-thinking/references/ANTI-PATTERNS.md`):
- `Parameter Thrashing` (8% → 7% threshold tuning instead of fixing the rule)
- `Reminder Substitution` (more doctrine without machine-checkable contract)
- `Human-As-Feedback-Loop` (Joshua became the router)

## Cure (3-lane unanimous)

Every health gate must emit `halt-contract/v1`:

```json
{
  "schema_version": "halt-contract/v1",
  "severity": "green|yellow|red",
  "tier": "host|repo|fleet",
  "mathematically_local": true|false,
  "blocked_actions": ["<action_class>", ...],
  "permitted_actions": ["<action_class>", ...],
  "repair_actions": ["<action_class>", ...],
  "owner": "repo_orch|host_orch|joshua",
  "expires_at": "<iso8601>",
  "reason": "<short_human>"
}
```

A halt without an allow-list is incomplete evidence. A `permitted_actions=[]` signal must carry `no_safe_work_reason` and is the only state where waiting is correct.

The creed (Lane B):
> **Truth blocks lies; safety blocks risk; everything else becomes routed work.**

## Execution order — Jeff-stack triad (doctor, measurement, repair)

### Phase 1 — MEASURE THE DISEASE (today, P0, ALL READ-ONLY)

Goal: turn `halt-by-default` from invisible into a tripwire that fires before Joshua wakes. NO behavior changes — only observers.

1. **B1: halt-contract/v1 schema fixture** — `templates/flywheel-install/halt-contract/v1.schema.json` + 3 fixtures (green / yellow / red) with expected permitted/blocked actions. Smoke-tests confirm schema validates and rejects unscoped halts.
2. **B2: watchdog-of-watchdogs** — `.flywheel/scripts/halt-disease-watchdog.sh` (read-only). Runs every 5 min via launchd. Joins `ntm --robot-activity` × `flywheel-loop doctor --json` × `.flywheel/dispatch-log.jsonl` × `br ready` to compute the 3 invariants:
   - `joshua_mornings_with_idle_fleet_count` (must be 0)
   - `dispatches_continued_per_doctor_yellow` (must be ≥1 per yellow per 10 min)
   - `time_between_yellow_signal_and_halt_propagation_seconds` (must be 0 for unscoped halts — i.e., they shouldn't exist)
3. **B3: regression fixture from today's incident** — `tests/halt-disease/regress-2026-05-04.sh`. Replays this morning's actual doctor JSON (skillos disk_free_pct=9.92, mobile-eats leakage_count=10, beads DB UNIQUE constraint). Asserts: under proposed v2 contract, all 3 sessions would have continued safe work. Failing this test means the cure didn't take.

Acceptance: 3 invariants computable today; watchdog runs every 5 min; regression fixture green against the proposed v2 contract.

### Phase 2 — VALIDATOR V2 (this week)

Three-outcome decision matrix replaces binary `BLOCK_CLOSE | SAFE_TO_CLOSE`:

| outcome | when | action |
|---|---|---|
| `BLOCK_CLOSE` | hard truth/safety/security/secret risk; false claim; runtime timeout claimed as pass; unresolved dependency cycle | reopen bead; do not close |
| `CLOSE_WITH_REWORK_DEBT` | artifact real, smoke proof real, but lens fail / thin evidence / publishability gap | close parent + auto-create child debt bead with SLA + cap; doctor counts it |
| `SAFE_TO_CLOSE` | mechanical evidence + required artifacts + no hard blockers | close with validator receipt + 4-lens scores |

Patch target (Lane B has the bash diff): `~/Developer/flywheel/.flywheel/scripts/validate-callback-before-close.sh`. Add doctor fields: `closed_with_rework_debt_count`, `oldest_debt_age_hours`, `debt_cap_breached_count`. Cap blocks NEW debt, never blocks safe work.

Memory updates (Lane B identified, all read-only proposals first):
- `feedback_two_blocker_ticks_escalate_to_flywheel_plan.md` — replace "wait for RubyCastle" with `blocker-route/v2` (permission map)
- `feedback_validator_must_check_four_lenses.md` — lens fail → rework debt unless hard truth blocker
- `feedback_four_lens_bar_fleet_wide.md` — bar is readiness/quality-debt metric, not fleet halt
- `feedback_publishability_bar_three_judges.md` — same correction
- `feedback_orchestrator_rubber_stamp_drift.md` — backpressure on unvalidated truth claims, not all work
- `feedback_orch_paralysis_recurring.md` — "human surfacing is not a route"

### Phase 3 — DOCTOR V2 ROUTING (next week, shadow mode)

Additive `routing` field on `flywheel-loop doctor --json`. Old `status` stays for CI compat. Tick scripts read `routing.dispatch_classes[<class>].decision` instead of `.status`. Shadow flag `FLYWHEEL_ROUTED_DOCTOR=1`. One non-critical loop first (skillos), then propagate via `templates/flywheel-install/`. Dispatch class catalog at `.flywheel/dispatch-classes/v1/catalog.json`.

### Phase 4 — ALPS + VRTX ONBOARD UNDER POST-FIX DOCTRINE

After Phase 1 watchdog is live (so we can measure that the new sessions don't relapse), spin alpsinsurance + vrtx ntm sessions, refresh MISSION.md, register loop tier `active_normal` 20-min interval. Use updated `flywheel-install` template with halt-contract/v1 baked in.

### Phase 5 — ECOSYSTEM ALIGNMENT GRADING

7-facet rubric across all fleet repos. Gap matrix → bead list → swarm. Recurring ritual not one-off.

## Adversarial regression vectors (Lane C, 10 of them)

Each one needs structural prevention, not "remember to do X":
1. New doctor field added without scope → schema rejects at PR time
2. Consumer ignores scoped JSON, reads only `.status` → conformance test fails
3. Validator regresses to binary verdicts → test asserts 3-outcome matrix exists
4. Debt queue grows unbounded → cap blocks new debt, doctor surfaces oldest-debt-age
5. Escalation route terminates at human → watchdog fails if `next_owner=human` while safe work remains
6. Threshold drift without semantics → each threshold has action class matrix + expiry receipt
7. Real red misclassified as yellow under push to fail-forward → conformance fixture includes hard-fail cases
8. New repo loop omits fail-forward contract → flywheel-install template test scans tick scripts
9. Watchdog relies on stale loop markers → uses live ntm activity + dispatch/callback receipts (Axiom 12)
10. Human side-channel becomes primary again → invariant fires CRITICAL on next-owner=human-with-safe-work

## Success criteria (the invariant)

`joshua_mornings_with_idle_fleet_count` is computed daily at 12:55Z (pre-morning) and **MUST be 0** for 7 consecutive days before this trauma class is promoted to closed. Violation alarm fires 5 min after detection, BEFORE Joshua wakes up the next morning.

If the watchdog fires and Joshua finds idle fleet: it's a structural regression, not a watchdog noise issue. Re-open this trauma class.

## Bead DAG (Phase 1 only — Phase 2+ deferred to converged plan)

```
B1 halt-contract-v1-schema-fixture (Phase 1 root)
B2 halt-disease-watchdog-script (depends B1)
B3 halt-disease-regression-fixture-from-2026-05-04 (depends B1)
B4 watchdog-launchd-plist (depends B2)
B5 watchdog-doctor-field-publication (depends B2,B3)
B6 watchdog-canonical-paths-registration (depends B4)
```

Phase 2 beads filed after Phase 1 watchdog ships and we have 24h of clean measurement.

## What is NOT in this plan (deferred)

- OrbStack 195GB structural decision (separate plan, your call)
- Beads DB integrity warning recovery (separate substrate work, doesn't block this)
- Mobile-eats and skillos active blocker resolution (will resolve naturally once doctor v2 ships in Phase 3 — for now, they remain in canonical wait state per their last receipts)

## Lane outputs (preserved)

- `/tmp/halt-disease-lane-a-output.md` — mechanism (doctor schema + tick script)
- `/tmp/halt-disease-lane-b-output.md` — paradigm (validator + escalation + memory)
- `/tmp/halt-disease-lane-c-output.md` — verification (invariants + watchdog + adversarial)
- `/tmp/halt-disease-shared-brief.md` — shared brief

## Self-grade

four_lens=brand:9/sniff:9/jeff:9/public:9
- brand: ZestStream voice, no slop, names the bar
- sniff: founder-ops outcomes (Joshua mornings idle = 0; dispatches continued per yellow ≥ 1)
- jeff: contracts pinned (halt-contract/v1, halt-disease-watchdog/v1), shadow mode for additive change, 3-fixture conformance, doctor/measurement/repair triad
- public: addresses original acceptance gates, names bar (Three Judges + Donella + Jeff), versioned schema, machine-checkable
