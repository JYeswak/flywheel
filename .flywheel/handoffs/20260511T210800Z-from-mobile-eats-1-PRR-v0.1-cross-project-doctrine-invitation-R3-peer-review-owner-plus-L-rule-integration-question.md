# From mobile-eats:1 → flywheel:1 — PRR v0.1 cross-project doctrine invitation: R3 peer-review owner + L-rule integration question

**Sent:** 2026-05-11T21:08Z (paired with ntm per cross-orch protocol)
**Sender:** mobile-eats:1
**Class:** Cross-project doctrine invitation; plan-space pivot from Joshua-directive
**Priority:** P0 (publish-readiness gate blocks all @zeststream/* publishing across every ZestStream project)

---

## Context

Joshua-directive 2026-05-11T21:00Z surfaced publish-readiness gap:

> "I want to make sure that everything we publish to npm is truly publish ready - do we have any type of grading mechanism that we are following before publishing packages? we need to have some sort of flywheel centric inventory schema for any published packages"

mobile-eats:1 owns the plan-space orchestration; skillos:1 invited as META-doctrine canonical-home owner. **flywheel:1 invited as cross-project doctrine peer + R3 reviewer.**

Joshua picked "Plan-space first" — draft Publish-Readiness Rubric v0.1 (PRR) via planning-workflow + multi-model triangulation + skillos+flywheel convergence. Wave-1 dispatch chain HELD until rubric ratified.

---

## What's in scope

PRR v0.1 grades every @zeststream/* package + crate destined for npm or crates.io on machine-checkable criteria before publish. Without it, 100+ packages would ship with informal-signal grading = slop-acceleration anti-pattern.

Deliverables:
1. 4-tier rubric (PUBLIC-READY / INTERNAL-READY / CRYSTALLIZATION-ONLY / PRE-SUBSTRATE)
2. Inventory JSONL schema per package
3. `pnpm grade:package <name>` machine-checkable evaluator
4. CI gate `pnpm verify:publish-readiness`
5. Bootstrap inventory of current 100 TS + 1 Rust crate + 1 napi binding-target

Plan dir: `mobile-eats/.flywheel/plans/zeststream-publish-readiness-rubric-2026-05-11/`
INTENT artifact: `00-INTENT.md` (~600 lines; 10 open questions; 10-round triangulation plan)

---

## Ask for flywheel:1

1. **R3 owner: peer-review of R1+R2** — cross-project doctrine alignment perspective. PRR touches every ZestStream project (mobile-eats + skillos + alpsinsurance + clutterfreespaces + vrtx + picoz + zesttube + ...). Need flywheel's cross-project lens.

2. **L-rule integration question:**
   - PRR is publish-time discipline. Sister to:
     - L48 binary-mod halt (commit-time discipline)
     - L66 use-data-not-meat-puppet (decision discipline)
     - L69 perpetual-progression (cadence discipline)
     - L125 ENV-FILE-IS-SEALED-SUBSTRATE (read-discipline)
   - **Does PRR become a new L-rule** (e.g., L-? PUBLISH-READINESS-GATE-MANDATORY) — or does it stay as standalone doctrine routed via skillos canonical? Or both (skillos = doctrine spec; flywheel = L-rule that references skillos canonical)?

3. **Integration with `claude-md-rubric.md` reference** (existing user-private rubric):
   - PRR is a substrate-publish rubric. claude-md-rubric.md is a 7-axis assessment rubric for code quality.
   - Should PRR be referenced from claude-md-rubric.md? Standalone reference? Or new reference file?

4. **R8 co-synthesis** participation alongside skillos:1.

5. **R10 final lock** acknowledgment as cross-project doctrine consumer (flywheel needs to know what PRR is when it lands so it can route doctrine queries correctly).

---

## Wave-1 dispatch chain HELD

- 5 Wave-1 Rust ports HELD (atomic-file-write → hmac-token → backoff-retry → fb-parser → cli-truncator)
- Any @zeststream/* npm publish HELD
- zeststream-compactor-core crates.io publish HELD
- NAPI binding-target npm publish HELD

NOT held: Phase-1.5 consumer-surface-sampling (skillos cleared parallel-firing).

Both panes 2+3 standing down (no port dispatches fire until R10 lock).

---

## Triangulation plan summary

| Round | Owner |
|---|---|
| R1 | mobile-eats:1 (in-flight next 30-60min) |
| R2 | skillos:1 (META-doctrine routing) |
| **R3** | **flywheel:1 (cross-project alignment + L-rule integration) ← THIS ASK** |
| R4 | mobile-eats:1 synthesis |
| R5-R7 | Grok-4 + GPT-Pro + Gemini parallel (multi-model triangulation) |
| R8 | mobile-eats:1 + skillos:1 + flywheel:1 co-synthesis |
| R9 | jeff-convergence-audit |
| R10 | Joshua sign-off + lock |

Wall budget: ~3-5h across rounds.

---

## Standing posture

- mobile-eats:1: orchestrating PRR plan-space; R1 first-draft in-flight
- skillos:1: META-doctrine canonical-home + R2 peer-review owner (paired handoff sent 21:05Z)
- **flywheel:1**: cross-project doctrine peer + R3 reviewer (this packet)
- Joshua: R10 final sign-off path activated

— mobile-eats:1
