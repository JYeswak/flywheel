## L81 — DOCS-ARE-LOAD-BEARING-CROSS-PANE-VALIDATED

---
id: L81
title: Docs are load-bearing and require cross-pane validation
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: documentation-substrate
---

Durable operational artifacts need README-grade documentation before they are
considered ready substrate. For load-bearing artifacts, docs are part of the
artifact contract. A worker may draft the README, but the drafting worker may
not be the final validator. Gate 2 validation MUST be performed by a different
pane, and Joshua signoff is required before a README can move from foundation
or reviewed state to validated state.

Load-bearing artifacts include flywheel binaries, launchd plists, hooks,
slash-command contracts, substrate-registry rows, canonical doctrine, and any
script or state machine that another pane relies on for execution decisions.

**How to apply:**
- Worker pane drafts the README at the exact artifact-owned path with
  frontmatter, Mermaid when required, command/reference coverage, side effects,
  error modes, and a real `validation_command`.
- Worker callback identifies the README path and leaves `reviewed_by`,
  `reviewed_at`, `validated_by`, and `validated_at` unset unless the dispatch
  explicitly assigned a separate review role.
- Orchestrator pane performs Gate 2 from a cold read: run the validation
  command, check target path existence, inspect Mermaid and command reference
  coverage, verify See Also paths, and confirm no self-validation.
- If Gate 2 fails, the orchestrator rejects the artifact back to the worker
  with checklist failures. The worker rewrites the README; do not patch-forward
  a failed README to make it look better while preserving the failed premise.
- If Gate 2 passes, the orchestrator fills `reviewed_by` and `reviewed_at`,
  then routes the artifact to Joshua for final signoff.
- Joshua final signoff sets `validated_by` and `validated_at`. Only then may
  the README be treated as validated.
- If the target artifact is retired or removed, the README must move to retired
  state or be removed by an explicit docs-retirement bead; orphaned docs are
  substrate drift.

**SOFT violations:**
- `readme_below_floor`: artifact lacks a README or the inventory grade is F.
- `readme_validated_by_self`: `validated_by` equals `reviewed_by`, or the
  worker that drafted the README also marks it validated.
- `readme_orphaned`: README `target_artifact` path no longer exists.
- `readme_validation_failed`: README `validation_command` exits non-zero.
- `readme_pending_orchestrator_review`: drafted README waits more than 2 hours
  without Gate 2 review.
- `readme_pending_joshua_signoff`: `reviewed_by` is set but `validated_by` is
  null for more than 24 hours.
- `readme_review_timeout`: draft-to-validation round trip exceeds 7 days.

**Forbidden outputs:**
- Claiming load-bearing documentation is validated when the author and reviewer
  are the same pane.
- Treating README text as sufficient when `validation_command` is absent,
  failing, stale, or not run by a separate reviewer.
- Patching a failed README forward after Gate 2 rejection instead of issuing a
  rewrite/reject-and-revert loop.
- Marking a repo's docs substrate caught up when `readme_below_floor`,
  `readme_validated_by_self`, or `readme_validation_failed` is still present.

**Evidence:** bead `flywheel-ic6`; synthesis bead `flywheel-7np`; plan
`.flywheel/plans/cross-pane-protocol-2026-05-01/04-XPANE-SYNTHESIS.md`; Lane 1
doctrine source
`.flywheel/plans/cross-pane-protocol-2026-05-01/01-L69-DOCTRINE-AND-STATE-MACHINE.md`;
documentation-substrate synthesis reporting 732 tracked artifacts and 0 A-grade
docs.

**Companion rules:** L56 (promotion ladder), L60 (doctor signal contract), L61
(wire doctrine into AGENTS/README), L71 (validate-and-redispatch discipline),
L80 (closed-bead audit mining), `flywheel-readme`, and the cross-pane protocol
plan. The source plan called this proposed L69, but L69/L70 were already
allocated before this bead landed; L81 preserves canonical ID uniqueness.

