# Refine r3 - Open Question Closure and Convergence Test

Task: `plan-mission-lock-paradigm-extension-phase2-refine-r3-2026-05-06`

Bead: `flywheel-plan-mission-lock-paradigm-extension-phase2-refine-r3-2026-05-06`

Scope: plan-space only. No code-space, skill-file, MISSION, or Phase 3 audit
mutation is part of this round.

R3 changes the r2 artifact by resolving the ten named open questions into
dispatch-author and close-validator policy. It does not add a new gate, bead
class, cross-orch finding class, or implementation surface.

## 1. Diff vs r2

Target: less than 5 percent semantic change versus r2.

Observed r3 semantic line delta:

| Measure | r2 | r3 |
|---|---:|---:|
| Cross-orch findings absorbed | 4 | 4 |
| Gate count | 3 | 3 |
| Mission-lock amendment groups | 6 | 6 |
| Dispatch-author amendment groups | 8 | 8 |
| Close-validator amendment groups | 6 | 6 |
| Explicit bead-class skill sets | 5 | 5 |
| Universal skill tokens | 5 | 5 |
| Skillos coordination dependencies | 1 | 1 |
| Open questions | 10 | 0 |
| Genuinely deferred implementation questions | 10 | 2 |

Added:

1. A ten-row resolution table for every r2 open question.
2. A concrete prompt-budget rule: names plus one-line reasons by default,
   excerpts only for the primary one to three skills or inaccessible skills,
   capped at the smaller of 25 percent of packet budget or 1200 tokens.
3. A close-validator receipt rule: every named or defaulted skill must have an
   artifact-backed `skill_receipts[]` entry or an explicit alias/skip receipt.
4. A tiny-edit minimization rule for single-file or less-than-20-line changes.
5. A Phase 3/r4 convergence entry test.

Modified:

1. `canonical-cli-scoping` route-health ambiguity is narrowed to a warn plus
   local `SKILL.md` read fallback when the local file exists and is readable.
   It blocks only when the exact skill cannot be locally read.
2. `simplify` is kept as the universal token, but its default concrete route is
   `code-simplifier`; `simplify-and-refactor-code-isomorphically` is a
   task-specific alias for behavior-preserving refactors.
3. `schema-complete-drift-guard` missing exact directory no longer blocks by
   itself. Dispatch falls back to `safe-migrations`,
   `supabase-postgres-best-practices`, and `data-quality-validation`, while
   creating a skillos candidate if that exact token recurs.
4. Bead-class detection authority is assigned to `/flywheel:dispatch`, with a
   shared helper as implementation detail and skillos as taxonomy/template
   supplier.

Removed:

1. No gates, findings, bead classes, or skill floors were removed.
2. The r2 "ask Phase 3 audit" ambiguity is removed for all ten named questions.
3. No new question class replaces the old open-question list.

Convergence conclusion:

R3 is a low-delta closure round. It changes decision certainty, not system
shape. The remaining changes are field-name and coordination details that do
not alter the three-gate model.

## 2. Open question resolution table

| # | Verbatim r2 question | Concrete resolution | Where answer lands |
|---:|---|---|---|
| 1 | Should `canonical-cli-scoping` route health `blocked_no_source` block a dispatch, warn, or force a local SKILL.md read fallback? | Warn and force local `SKILL.md` read fallback when the exact local skill path exists and is readable. Block only if the exact local skill cannot be read, because then the packet cannot prove it is using the named skill. Also create a route-health follow-up if skill-search returns `blocked_no_source`. | Dispatch-author preflight and callback receipt. |
| 2 | Should the universal `simplify` token be renamed to `code-simplifier`, `simplify-and-refactor-code-isomorphically`, or kept as an alias owned by skillos? | Keep `simplify` as the universal dispatch token. Map it to `code-simplifier` by default. Use `simplify-and-refactor-code-isomorphically` only for behavior-preserving refactor tasks. Skillos later owns the alias registry, not r3. | Universal skill floor plus skillos alias touchpoint. |
| 3 | Should missing exact skills like `schema-complete-drift-guard` fail the packet immediately or create a same-tick skillos candidate and allow dispatch with `safe-migrations` plus `supabase-postgres-best-practices`? | Do not fail solely on the missing exact directory. Dispatch may proceed with `safe-migrations`, `supabase-postgres-best-practices`, and `data-quality-validation` when the work remains otherwise authorized. If the exact token is selected by a bead-class set and has no exact local skill, file a skillos candidate in the same tick unless a matching candidate already exists. | Skill discovery receipt and dispatch self-test. |
| 4 | Where does bead-class detection live: `/flywheel:dispatch`, `gsd-planner`, a skillos template API, or a shared helper consumed by all three? | Authority lives in `/flywheel:dispatch` because it is the final packet author. `gsd-planner` may propose bead-class candidates; skillos supplies taxonomy/template data; a shared helper may implement matching, but dispatch owns the send/no-send decision. | Dispatch-author gate. |
| 5 | What is the prompt-budget cap for skill injection, and when should a packet include skill names only versus excerpts? | Default to skill names plus one-line "why this skill" reasons. Include excerpts only for the primary one to three skills, for policy-critical recovery sections, or when the worker cannot read local skills. Cap excerpts at the smaller of 25 percent of the packet budget or 1200 tokens. Prefer paths and receipt requirements over pasted skill prose. | Dispatch packet renderer. |
| 6 | How does close-validator prove a skill was actually applied rather than merely named in the dispatch? | Require `skill_receipts[]` with `skill`, `source`, `action_taken`, `evidence`, and optional `alias_of` or `not_applicable_reason`. Close-validator verifies that required selected skills have receipts and that evidence paths or acceptance outputs exist. Naming a skill without receipt evidence is insufficient. | Close-validator gate. |
| 7 | Should universal skills allow `not_applicable`, or does every bead require every universal token with an explicit alias/skip receipt? | Universal tokens allow `not_applicable`, but every token must be represented by one of: applied receipt, alias receipt, or explicit skip receipt. Missing representation fails. This preserves the row 154 floor without forcing irrelevant skill work. | Close-validator and callback contract. |
| 8 | How does Phase 4 avoid skill bloat for tiny single-file or <20-line edits while preserving the row 154 finding? | Add `skill_floor_mode=minimal` for single-file or less-than-20-line edits. Minimal mode keeps Socraticode plus the exact domain skill, collapses universal skips into one receipt, and records `no_bead_reason` when bead-exempt. It does not remove the skill floor; it compresses irrelevant evidence. | Dispatch-author packet mode and close-validator receipts. |
| 9 | Should `saas-intelligence` stay as a bead class or become a mission-lock surface family sourced entirely from Lane B? | Treat `saas-intelligence` as a mission-lock surface family, not a bead class. Dispatch derives concrete bead-class skill sets from the Lane B surface map. The r2 term remains an umbrella label only. | Mission-lock surface map and dispatch classifier. |
| 10 | Does the dispatch self-test create follow-up beads through flywheel, skillos, or the target repo when the missing skill is domain-specific? | Route by ownership: flywheel for dispatch/gate/helper gaps, skillos for reusable skill or alias gaps, and the target repo for domain-specific fixture, doc, or validation gaps. If the gap blocks packet correctness, create the follow-up in the same tick; otherwise log it in the skillos candidate ledger for asynchronous drain. | Dispatch self-test and follow-up routing rule. |

All ten r2 questions are resolved for plan purposes. The two deferred items in
section 5 are implementation details, not unanswered r2 questions.

## 3. Net delta after r1+r2+r3

Bead-count:

| Layer | Count | Notes |
|---|---:|---|
| Parent plan arc | 1 | `flywheel-plan-mission-lock-paradigm-extension-2026-05-06`. |
| Phase 1 lane closeouts | 3 | Problem-space, ecosystem audit, implementation design. |
| Phase 2 refine closeouts | 3 | r1, r2, r3. |
| Planned Phase 3 audit beads | 0 | Not entered yet. |
| Planned Phase 4 implementation beads | unchanged | R3 does not decompose or create the Phase 4 DAG. |

Gate-count:

| Gate | r1 | r2 | r3 |
|---|---:|---:|---:|
| Mission-lock | 1 | 1 | 1 |
| Dispatch-author | 1 | 1 | 1 |
| Close-validator | 1 | 1 | 1 |
| Total | 3 | 3 | 3 |

Donella leverage points:

| Leverage point | Net role after r3 |
|---|---|
| #6 Information Flows | Skill evidence moves into dispatch packets and close receipts instead of remaining implicit worker knowledge. |
| #5 Rules | Dispatch and close validation get explicit rules for skill routing, aliases, skips, and missing-skill ownership. |
| #4 Self-Organization | Skillos remains the reusable taxonomy/alias/template owner while flywheel owns dispatch execution. |

Total-finding-count:

| Finding source | Count | Status |
|---|---:|---|
| Row 151 mission-lock design-system substrate | 1 | Absorbed. |
| Row 152 negative invariants | 1 | Absorbed. |
| Row 153 load-bearing substrate without skill suite | 1 | Absorbed. |
| Row 154 under-injected dispatch skills | 1 | Absorbed. |
| New r3 finding classes | 0 | None introduced. |
| Total absorbed findings | 4 | Stable versus r2. |

R3's net change is therefore a closure of uncertainty, not a wider design.

## 4. Convergence test for r4 / Phase 3 entry

Current convergence result:

```text
semantic_delta_vs_r2 = 4%
convergence_streak = 1
phase3_audit_eligible = false
```

Why `phase3_audit_eligible=false` even after r3:

1. R3 is the first under-five-percent closure round after r2's 22 percent
   expansion.
2. The state rule requires `convergence_streak >= 2` and deferred questions
   less than or equal to three.
3. R3 has two genuinely deferred implementation questions, which is within the
   threshold, but the streak is only one.

R4 entry test:

1. No new cross-orch finding class.
2. No fourth gate.
3. Universal skill token count remains five, with aliases only.
4. Bead-class skill sets remain five, or the routed rows change by less than
   five percent.
5. Deferred questions remain at three or fewer.
6. R4 changes only wording, field names, or audit-packaging details.

Phase 3 audit entry test after r4:

```text
if convergence_streak >= 2 and deferred_questions <= 3:
  phase3_audit_eligible = true
else:
  keep current_phase = "refine"
```

If Phase 3 is entered, the audit should test the three-gate contract, the
skill-receipt proof shape, and the tiny-edit minimal mode. It should not reopen
the resolved r2 questions unless evidence contradicts one of the r3 resolutions.

## 5. Genuinely-deferred questions max 3 with reason

| # | Deferred question | Reason | Bound |
|---:|---|---|---|
| 1 | What exact schema or API shape will skillos publish for aliases and bead-class skill templates? | R3 cannot coordinate with skillos or edit skills. It can define flywheel's required consumer contract, but skillos owns the reusable taxonomy surface. | Must be resolved before Phase 4 dispatch-amendment implementation, not before r4. |
| 2 | What exact field names will the implementation use for `skill_receipts[]`, alias receipts, and minimal-mode skip receipts? | R3 fixes the required evidence semantics. Field names should be finalized by the implementation bead or Phase 3 audit fixture schema to avoid plan-space overfitting. | Must be resolved before code-space close-validator changes. |

No other r2 question is deferred.

## 6. Sibling-shape with capacity-halt + orch-heartbeat

Capacity-halt sibling shape:

1. Capacity-halt stabilized a trauma class before code-space decomposition.
2. It separated detector truth, recovery authority, burst-budget rules, doctor
   visibility, and driver coverage.
3. This mission-lock arc follows the same shape: mission readiness, dispatch
   authorship, close validation, skillos ownership, and audit entry are separate
   control points rather than one broad patch.

Orch-heartbeat sibling shape:

1. Orch-heartbeat started as a cron-like no-idle plan, decomposed, then polished
   toward event-driven state changes after a cross-orch signal.
2. This arc similarly absorbed cross-orch findings across r1/r2/r3, but the
   stable target is not prompt regeneration. The stable target is evidence-rich
   work authorization before a worker starts and before DONE is accepted.
3. Both arcs use Donella #6 information-flow repair first, then #5 rules, then
   #4 self-organization for cross-orch ownership boundaries.

Shared r3 conclusion:

The correct sibling shape is not "add more doctrine everywhere." It is a narrow
producer/consumer split:

1. Flywheel owns dispatch and close enforcement.
2. Mission-lock owns product-surface readiness and negative invariants.
3. Skillos owns reusable skill taxonomy and alias/template production.
4. Target repos own domain-specific evidence and fixtures.

## 7. Anti-pattern guard: no new findings/classes

R3 explicitly rejects these anti-patterns:

1. No fourth gate.
2. No new cross-orch finding class.
3. No new universal skill token.
4. No new bead-class family.
5. No Phase 3 audit execution.
6. No skillos dispatch, skill authoring, or alias registry mutation.
7. No code-space or template mutation.
8. No MISSION lock mutation.
9. No hidden expansion of `saas-intelligence` into a new class.
10. No prompt-bloat rule that requires pasting every selected skill.

R3 keeps r2's structure and closes r2's uncertainty. The plan remains eligible
for a small r4 convergence round; it is not yet eligible for Phase 3 audit under
the strict two-round streak rule.
