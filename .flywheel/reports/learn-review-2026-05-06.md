# /flywheel:learn --review: fuckup-log mining + Petal 9 candidate review

Task: `learn-review-fuckup-log-mining-2026-05-06`  
Scope: review-only; no memory files, skill files, or `/flywheel:learn --promote` commands were mutated or executed.  
Evidence: live 24h scrape observed 1080 unprocessed rows; dispatch snapshot was 1063 rows. Socraticode queries: 6.

## A. Fuckup-log 24h triage

Top 10 classes by frequency:

| Rank | Class | Count | Max severity | Last seen UTC | Trend | Sample row | Sample |
|---:|---|---:|---|---|---|---:|---|
| 1 | `post-callback-reminder-template-recovery` | 934 | high | 2026-05-06T16:49:26Z | rising | 1080 | `recovery-escape-then-reprompt attempted staged recovery` |
| 2 | `codex-model-at-capacity-halt` | 4 | medium | 2026-05-06T09:01:53Z | falling | 351 | `capacity-halt during plan-arc execution` |
| 3 | `file-reservation-closeout-conflict` | 4 | medium | 2026-05-06T11:45:53Z | rising | 564 | shared closeout reservation conflict |
| 4 | `pane-respawn` | 4 | medium | 2026-05-06T16:27:55Z | rising | 1024 | `post_callback_stale_chevron_input_deaf_after_wave2_4_close` |
| 5 | `br-db-wedge` | 3 | high | 2026-05-06T00:09:51Z | falling | 62 | bead DB wedge |
| 6 | `br-db-wedge-recurrence` | 3 | high | 2026-05-06T00:46:03Z | falling | 70 | recurring bead DB wedge |
| 7 | `br-prefix-mismatch` | 3 | medium | 2026-05-06T16:48:03Z | rising | 1078 | bead ID prefix mismatch |
| 8 | `ci-substrate-failure` | 3 | medium | 2026-05-05T21:08:03Z | falling | 24 | CI substrate failure |
| 9 | `file-reservation-conflict` | 3 | medium | 2026-05-06T01:34:19Z | falling | 89 | file reservation conflict |
| 10 | `fire-and-forget-dispatch` | 3 | high | 2026-05-06T10:30:45Z | falling | 363 | dispatch sent without liveness proof |

Taxonomy:

| Class | Memory coverage | Classifier/code coverage | Review class |
|---|---|---|---|
| `post-callback-reminder-template-recovery` | yes | yes: recovery script + classifier tests | memory/classifier |
| `codex-model-at-capacity-halt` | yes | yes: classifier tests + incidents | memory/classifier |
| `file-reservation-closeout-conflict` | generic | yes: shared reservation checks + incidents | classifier/partial-memory |
| `pane-respawn` | yes | yes: watchdog/frozen-pane/respawn tooling | memory/classifier |
| `br-db-wedge` | yes | yes: DB close-path and corruption monitors | memory/classifier |
| `br-db-wedge-recurrence` | yes, same family | yes, same family | duplicate-family |
| `br-prefix-mismatch` | no targeted memory | generic code hits only | net-new/partial |
| `ci-substrate-failure` | no | no | net-new |
| `file-reservation-conflict` | generic | yes: shared reservation checks + incidents | classifier/partial-memory |
| `fire-and-forget-dispatch` | yes | yes: delivery verification scripts | memory/classifier |

Recurrence trend:

- Rising: `post-callback-reminder-template-recovery`, `file-reservation-closeout-conflict`, `pane-respawn`, `br-prefix-mismatch`.
- Falling: `codex-model-at-capacity-halt`, `br-db-wedge`, `br-db-wedge-recurrence`, `ci-substrate-failure`, `file-reservation-conflict`, `fire-and-forget-dispatch`.
- Steady-state: none in the top 10 using last-6h vs previous-18h split.

## B. Petal 9 candidates table

Candidate key: C1-C3 memory rules, C4-C8 skill updates, C9-C11 fuckup promotions.

| ID | Candidate | Body summary | Petal 9 evidence | Top-10 correlation | Verdict | Anti-knowledge check |
|---|---|---|---|---|---|---|
| C1 | `feedback_plan_arc_convergence_gates.md` | Plan arcs advance on measured convergence gates; STATE carries streak/diff/findings/readiness. | Mission-lock arc reached READY through refine/audit/decompose/polish gates. | no direct top-10 class | REVISE: keep as positive planning memory; do not frame as trauma rule. | Generalizable to plan arcs, but not supported by fuckup frequency. |
| C2 | `feedback_cross_orch_coownership_scope_handshake.md` | Co-ownership packets need mission anchor, scope, collision notes, callback shape, and complementary artifacts. | skillos co-ownership around plan artifacts. | no direct top-10 class | REVISE: add anti-duplicate condition and explicit owner boundaries. | Generalizable only when two orchestrators own disjoint deliverables. |
| C3 | `feedback_shared_append_short_lease_stable_tail.md` | Shared append surfaces need short EOF leases, stable-tail proof, holder coordination, re-read tail, quick release. | Petal closeout append coordination and shared file contention. | covers `file-reservation-closeout-conflict`; covers `file-reservation-conflict` | APPROVE. | Generalizable; exactly matches recurring shared append failures. |
| C4 | `/flywheel:plan` convergence-gated transition thresholds | Add reusable skeleton for refine/audit/decompose/polish readiness gates. | Plan arc conversion from draft to READY. | no direct top-10 class | APPROVE. | Positive practice; should not imply every tick needs full arc machinery. |
| C5 | `/flywheel:dispatch` audit-lens and co-ownership fields | Add audit-lens coverage receipts and cross-orch packet fields. | Dispatches needed evidence-driven coverage and scoped callbacks. | partial `fire-and-forget-dispatch` | REVISE: split liveness/delivery receipts from cross-orch co-ownership fields. | Generalizable, but current proposal mixes two mechanisms. |
| C6 | `/flywheel:worker-tick` stable-tail checklist | Add shared append checklist to worker closeout. | Shared INCIDENTS/JSONL EOF-only closeout pattern. | covers reservation conflicts; partial post-callback closeout | APPROVE. | Generalizable for shared append surfaces only. |
| C7 | `agent-mail` short-lived shared-append reservation recipe | Document short leases, renewal, conflict coordination, and release timing. | Agent Mail coordination was needed for shared files. | covers reservation conflicts | APPROVE. | Generalizable; keep recipe scoped to shared append, not all edits. |
| C8 | `codebase-archaeology` plan-arc evidence extraction pass | Add named pass for extracting reusable plan-arc evidence. | Petal 9 extraction was archaeology-heavy. | no direct top-10 class | REVISE: make it a report template/reference first; promote to skill only after recurrence. | Risk of over-generalizing one successful review format. |
| C9 | `post-callback-stale-chevron-input-deaf-after-close` | Promote canonical wrapper over legacy post-callback recovery class. | Petal 9 named stale post-callback behavior. | covers top class and partial `pane-respawn` | APPROVE. | Generalizable; merge aliases under one canonical class. |
| C10 | `shared-append-reservation-deadlock` | Promote shared append reservation conflict family if closeout conflicts persist. | Petal 9 shared closeout coordination. | covers reservation conflict family | APPROVE AS FAMILY: alias closeout/conflict/queue variants. | Generalizable if promoted as family, not one exact slug. |
| C11 | `br-db-wedge-recurrence` | Promotion-ready; JSONL fallback remains required until Beads DB boring. | Multiple DB wedge events during plan arc. | covers `br-db-wedge` and `br-db-wedge-recurrence` | REVISE: consolidate under canonical `br-db-wedge`; avoid duplicate sibling class. | Generalizable, but exact recurrence suffix duplicates the root class. |

## C. Cross-correlation matrix

Cells use the required values `covers`, `partial`, and `no`.

| Fuckup class | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | C10 | C11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `post-callback-reminder-template-recovery` | no | no | no | no | partial | partial | no | no | covers | no | no |
| `codex-model-at-capacity-halt` | no | no | no | no | no | no | no | no | no | no | no |
| `file-reservation-closeout-conflict` | no | partial | covers | no | no | covers | covers | no | no | covers | no |
| `pane-respawn` | no | no | no | no | partial | no | no | no | partial | no | no |
| `br-db-wedge` | no | no | no | no | no | no | no | no | no | no | covers |
| `br-db-wedge-recurrence` | no | no | no | no | no | no | no | no | no | no | covers |
| `br-prefix-mismatch` | no | no | no | no | no | no | no | no | no | no | no |
| `ci-substrate-failure` | no | no | no | no | no | no | no | no | no | no | no |
| `file-reservation-conflict` | no | partial | covers | no | no | covers | covers | no | no | covers | no |
| `fire-and-forget-dispatch` | no | partial | no | no | partial | no | no | no | no | no | no |

Coverage readout:

- Well-served classes: post-callback recovery, reservation conflict family, bead DB wedge family.
- Gaps needing new candidate work: `br-prefix-mismatch`, `ci-substrate-failure`.
- Candidates without strong top-10 data: C1, C4, C8. These are positive practice candidates, not trauma promotions.

## D. Promotion decisions for Joshua review

APPROVE:

1. C3 memory rule candidate: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_shared_append_short_lease_stable_tail.md`

   Suggested body:
   ```text
   Shared append surfaces such as INCIDENTS.md and .beads/issues.jsonl need short-lived EOF leases, explicit holder coordination, stable-tail re-read immediately before append, append-only writes, and prompt release. Do not hold broad shared-file reservations while doing private artifact work. Build private artifacts first, then reacquire or confirm the shared lease just before the closeout append.
   ```

2. C4 skill update: `/flywheel:plan` should absorb the convergence-gated transition skeleton as a positive practice.
3. C6 skill update: `/flywheel:worker-tick` should add the stable-tail shared append checklist.
4. C7 skill update: `agent-mail` should add the short-lived shared-append reservation recipe.
5. C9 fuckup promotion: `post-callback-stale-chevron-input-deaf-after-close`, canonicalizing the legacy post-callback recovery class.
6. C10 fuckup promotion: `shared-append-reservation-deadlock`, but promote as a family alias over closeout/conflict/queue variants.

REVISE:

1. C1: keep as positive planning memory; remove trauma framing and include evidence fields from STATE.
2. C2: add explicit owner boundaries and an anti-duplicate guard before memory promotion.
3. C5: split dispatch changes into liveness/delivery receipts and cross-orch co-ownership packets.
4. C8: keep as report template/reference until this extraction pass recurs.
5. C11: consolidate with canonical `br-db-wedge`; do not create a sibling `*-recurrence` rule.

REJECT:

- None. Every candidate has reusable signal, but five require narrowing before promotion.

NEW candidates not in Petal 9:

1. `feedback_br_prefix_mismatch_is_schema_drift.md`: recurring prefix mismatch should route to bead schema/ID normalization, not manual closeout guesswork.
2. `feedback_ci_substrate_failures_need_owner_route.md`: CI substrate failures currently have no targeted memory, classifier, or incident coverage; create an owner-routing rule after one more confirmed occurrence or one high-severity cost citation.

## E. Anti-knowledge

1. Do not promote the raw 1063 or 1080 row count as doctrine. It is a moving scrape count, not a stable fact; use it only as the review sample size.
2. Do not create a new standalone class from the 934 post-callback rows without deduping emitter noise and aliasing legacy recovery names.
3. Do not treat `br-db-wedge` and `br-db-wedge-recurrence` as independent trauma classes. They are one family until evidence proves different root causes.
4. Do not turn positive plan-arc patterns into failure rules. C1/C4 are good reusable practices, but they are not justified by the top trauma frequencies.

## F. Recommendations summary

Final counts:

- Memory rules approved: 1
- Skill updates approved: 3
- Fuckup classes ready for `/flywheel:learn --promote`: 2
- Candidates needing revision: 5
- Candidates rejected: 0
- New candidate gaps: 2

Pre-staged commands for Joshua after review:

```bash
# promote only after accepting the alias/body decisions above
/flywheel:learn --promote post-callback-stale-chevron-input-deaf-after-close
/flywheel:learn --promote shared-append-reservation-deadlock

# revised candidate, only after consolidating aliases under the root class
/flywheel:learn --promote br-db-wedge
```

Do not run promotion commands until the memory/skill wording is accepted; this pass intentionally stopped at review.
