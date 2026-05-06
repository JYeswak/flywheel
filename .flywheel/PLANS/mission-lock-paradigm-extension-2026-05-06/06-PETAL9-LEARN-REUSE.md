# Petal 9 LEARN/REUSE - mission-lock paradigm extension

Date: 2026-05-06
Task: `petal9-learn-review-plan-arc-2026-05-06`
Scope: plan-space extraction only. No memory files or skill files were mutated.
Socraticode: 6 queries against `/Users/josh/Developer/flywheel`.

## Plan-arc velocity analysis

The single-day velocity came from a tight loop: cross-orch findings arrived with
mission relevance, Phase 1 split discovery into lanes, Phase 2 used convergence
thresholds instead of taste, Phase 3 audited with three named lenses, Phase 4
decomposed all findings into a DAG, and Phase 5 stopped after measured polish
stability.

Evidence:

- Phase 1 absorbed cross-orch rows 151-154 into six gap classes and three gates.
- Phase 2 ran r1-r4; r4 sealed `convergence_streak=2`,
  `phase3_audit_eligible=true`, and only two deferred implementation questions.
- Phase 3 produced 18 findings, 0 critical, 4 high, 11 medium, 3 low; all three
  lenses returned `auto_advance`.
- Phase 4 produced 13 DAG nodes across 4 waves and covered 18/18 findings.
- Phase 5 r2 had 2.12% average diff and r3 had 0.00% diff, producing
  `phase5_ready=true`.

The reusable insight: the plan did not get faster by skipping rigor. It got
faster because every phase had a measurable advance/no-advance contract.

## Reusable patterns discovered

### 1. Convergence-gated plan arc

What it is: a plan loop where refinement and polish move forward only after
explicit stability thresholds, not after a worker declares the prose "good."

Where it applied today: r3/r4 moved Phase 2 to audit only after two consecutive
under-5% rounds; r2/r3 polish moved Phase 5 to READY after two stable rounds.

Generalization candidate: memory rule.

Concrete examples:

- `02-REFINE-r4.md`: `semantic_delta_vs_r3 = 2%`,
  `convergence_streak = 2`, `phase3_audit_eligible = true`.
- `05-POLISH-r3.md`: 13 bead summaries held byte-identical versus r2.
- `STATE.json`: records both refine and polish convergence streaks.

### 2. Audit-lens to DAG decomposition

What it is: audit findings are not left as prose; each finding maps to at least
one implementation bead and one evidence-bearing gate.

Where it applied today: the three Phase 3 lenses produced 18 findings; Phase 4
mapped all 18 into a 13-node, 4-wave DAG.

Generalization candidate: `/flywheel:plan` and `/flywheel:dispatch` skill update.

Concrete examples:

- SEC-001, IDEM-001, and CSR-003 all feed dispatch delivery identity.
- IDEM-004 feeds the plan-state lens merge ledger and readiness doctor.
- CSR-001/CSR-002 feed dispatch-author skill-routing and skillos handshake.

### 3. Contract-first implementation beads

What it is: before mutating runtime behavior, ship schemas, validators,
read-only probes, and golden tests that define the contract.

Where it applied today: Wave 2 shipped mission-lock output schema and dispatch,
close, and STATE contracts; Wave 3 shipped read-only validators before repair
apply-mode; Wave 4 added delivery identity and replay fixtures.

Generalization candidate: INCIDENTS reference plus skill update for
`dispatch-tool-contracts`, `codebase-archaeology`, and `/flywheel:worker-tick`.

Concrete examples:

- `mission-lock-output.schema.json` precedes scaffold/readiness consumers.
- `plan-state-lens-merge.sh` makes append-only STATE merge testable.
- `dispatch-self-test-delivery-identity.sh` proves duplicate sends are
  already-sent or already-complete instead of blind resend.

### 4. Cross-orch co-ownership with mission-anchor preservation

What it is: a sister orchestrator can own bounded work when the parent offers a
precise scope, preserves the mission anchor, and asks for complementary output.

Where it applied today: flywheel row 163 offered skillos five co-ownable beads;
skillos row 165 shipped `flywheel-codex-oom-killed-subclass-2026-05-06` with
commit `ebf44878`, 11/11 tests, 25 min wall, and mission anchor preserved.

Generalization candidate: memory rule plus `agent-orchestration` skill update.

Concrete examples:

- Flywheel gave top pick, scope, why co-ownable, and collision notes.
- Skillos returned a callback with parent bead, verdict, commit, tests, wall
  time, and mission anchor.
- Rows 166 and 168 show two skillos co-owned beads closed in the same hour.

### 5. EOF-only shared append discipline

What it is: shared close surfaces are treated as append-only logs with
reservation coordination, tail re-read, and scoped closeout instead of broad
file ownership.

Where it applied today: multiple workers finished code/private artifacts first,
then coordinated `INCIDENTS.md` and `.beads/issues.jsonl` append rows by re-reading
tails and writing EOF-only.

Generalization candidate: memory rule plus Agent Mail skill update.

Concrete examples:

- Wave 2 #4 released shared IDs so Wave 3 #1 could close, then re-reserved.
- Wave 3 #2 and Wave 3 #4 used EOF-only append after stable-tail re-read.
- Scoped commit pass left shared append files unstaged while committing plan
  artifacts, doctrine, scripts, schemas, tests, and impl docs by pathspec.

## Trauma classes that recurred

### `post-callback-stale-chevron-input-deaf-after-close`

Recurrence count: 913 same-family rows today. Exact slug: 1 direct row
(`fuckup-log.jsonl` line 2292). Legacy family:
`post-callback-reminder-template-recovery`, 912 same-day rows.

Instances:

- 2026-05-06T16:27:55Z flywheel pane 3 after Wave 2 #4 close:
  `post_callback_stale_chevron_input_deaf_after_wave2_4_close`.
- 2026-05-06T01:27-01:32Z repeated recovery rows across flywheel panes 3/4
  and skillos pane 2.

Read: the exact new slug should wrap the legacy reminder-template recovery
rows. Otherwise the signal splits between human-readable incident names and
reviewable classes.

### `shared-append-reservation-deadlock`

Recurrence count: 10 same-family rows today. Exact slug: 1 direct row
(`fuckup-log.jsonl` line 2275). Same-family classes include
`file-reservation-closeout-conflict` (4), `file-reservation-conflict` (3),
`append-reservation-conflict` (1), and `shared-append-reservation-queue` (1).

Instances:

- 2026-05-06T16:19:46Z Wave 2 output schema and Wave 3 skillos handshake both
  held EOF append reservations and blocked each other.
- 2026-05-06T10:41-11:45Z closeout conflicts blocked capacity-halt, Phase 4
  decompose, and calling-in-sick policy close rows.

Read: this is not a reason to skip reservations. It is a reason to make shared
append queues first-class and prefer short-lived EOF leases.

### `br-db-wedge-recurrence`

Recurrence count: 3 same-day rows.

Instances:

- 2026-05-06T00:31Z `br close` failed with WAL corruption.
- 2026-05-06T00:36Z another closeout hit malformed SQLite and JSONL fallback.
- 2026-05-06T00:46Z wedge recurred after repair; live DB stayed read-only.

Read: JSONL fallback was load-bearing today. The fallback is not optional
documentation; it preserved plan velocity under bead DB instability.

## Cross-orch coordination wins

Rows 159-165 are the important arc:

- Rows 159-161 show blocker escalations that required flywheel ownership.
- Row 162 is skillos offering background capacity plus reporting substrate
  findings.
- Row 163 is the key handshake: flywheel accepted the offer, preserved the
  mission anchor, and offered scoped, non-overlapping candidate beads.
- Row 164 corrected a false bead offer quickly instead of letting the sister
  orchestrator pick nonexistent work.
- Row 165 is the successful callback: skillos shipped
  `flywheel-codex-oom-killed-subclass-2026-05-06`, 11/11 tests, commit
  `ebf44878`, and returned the mission anchor.

Why it worked:

- Mission-anchor preservation kept the sister worker aligned to the parent
  objective instead of creating an orphan improvement.
- Scope clarification made each offered bead bounded by file ownership and
  blast radius.
- Complementary-not-competing artifacts avoided duplicated work: skillos owned
  reusable substrate/classifier shape, flywheel consumed the callback as parent
  plan evidence.

## What to promote

Memory rule candidates:

```suggestion
Path: ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_plan_arc_convergence_gates.md
Title: Plan arcs advance on measured convergence, not prose confidence
Body:
When a flywheel plan claims readiness, require explicit stability evidence:
refine convergence before audit, audit findings mapped before decompose, and
polish convergence before READY. A worker saying "stable" is not enough; the
STATE artifact must carry the streak, diff, findings, and readiness fields.
```

```suggestion
Path: ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_cross_orch_coownership_scope_handshake.md
Title: Sister orchestrators need bounded co-ownership packets
Body:
When accepting background capacity from another orchestrator, offer bounded
candidate beads with mission anchor, scope, collision notes, and callback shape.
The sister orchestrator should produce complementary artifacts under the parent
bead, not compete for the same append surfaces or invent a new mission.
```

```suggestion
Path: ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_shared_append_short_lease_stable_tail.md
Title: Shared closeout surfaces need short EOF leases and stable-tail proof
Body:
For shared append-only files such as INCIDENTS.md and .beads/issues.jsonl, do
private artifacts first, coordinate active holders, re-read the tail immediately
before writing, append EOF-only, and release quickly. Long exclusive leases on
shared logs create deadlocks even when every worker is individually correct.
```

Skill update candidates:

- `/flywheel:plan`: document convergence-gated transition thresholds as a
  reusable plan-arc skeleton.
- `/flywheel:dispatch`: add audit-lens to DAG coverage receipts and cross-orch
  co-ownership packet fields.
- `/flywheel:worker-tick`: carry a stable-tail shared append checklist for
  `INCIDENTS.md` and `.beads/issues.jsonl`.
- `agent-mail`: add a short-lived shared-append reservation recipe.
- `codebase-archaeology`: add "plan-arc evidence extraction" as a named pass.

Fuckup-log promotion candidates:

- Promote `post-callback-stale-chevron-input-deaf-after-close` as the canonical
  wrapper over legacy `post-callback-reminder-template-recovery` rows.
- Promote `shared-append-reservation-deadlock` into INCIDENTS if the same-family
  closeout conflicts keep hitting after short-lease guidance lands.
- Keep `br-db-wedge-recurrence` promotion-ready; JSONL fallback should remain
  a required close path until Beads DB integrity is boring for multiple days.

## What to NOT promote

- Do not promote "single-day plan arc" as a goal. The reusable pattern is phase
  discipline plus convergence evidence; the one-day wall-clock outcome was a
  consequence, not an invariant.
- Do not promote exact row numbers 151-165 as doctrine. Promote the handshake
  shape and evidence fields; ledger row numbers are session-local.
- Do not promote 13 beads and 4 waves as a universal size. Those counts fit
  this plan's 18 findings; smaller plans should stay smaller.
- Do not generalize EOF-only append through active reservations as permission to
  ignore Agent Mail. The safe pattern is coordination plus short stable-tail
  append, not silent write-through.
- Do not auto-write memory or skill files from this extraction. Petal 9 should
  surface candidates; Joshua decides what becomes durable memory.
