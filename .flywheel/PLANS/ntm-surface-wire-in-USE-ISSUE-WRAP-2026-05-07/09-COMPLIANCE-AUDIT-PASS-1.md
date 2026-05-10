---
title: "Beads Compliance Audit Pass 1"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Beads Compliance Audit Pass 1

Date: 2026-05-07
Task: `beads-compliance-audit-2026-05-07`
Skill: `/beads-compliance-and-completion-verification`
Threshold: `700/1000`
Audit pass: `/Users/josh/Developer/flywheel/beads_compliance_audit/passes/2026-05-07T19-03-18Z`
Master report: `/Users/josh/Developer/flywheel/beads_compliance_audit/passes/2026-05-07T19-03-18Z/REPORT.md`

## Top Line

Verdict: **FAIL / more passes needed**.

The skill audited the full live bead universe: `1107` beads total, `533` closed in the pass inventory, `239` false-closed below threshold. The master report warns this is a deterministic-only pass: Phase 4 required-test execution and Phase 6 test-depth audit were stubbed for all `1107` beads, so scores are an upper bound and should not drive reopen/debt actions without a subagent-backed second pass.

Scoped to today's `ntm-surface-*` plan strings, live bead data yielded `40` closed claims. `4/40` scored at or above threshold; `36/40` scored below threshold. Scoped average score: `659.5/1000`.

Literal `plan_slug=ntm-surface-(wire-in|validation-followup)` matched `35` closed rows; broad plan text matching (`plan_slug`, `plan_origin`, and the named plan path) matched `40`, including the follow-up beads whose descriptions use `plan_origin` rather than `plan_slug`.

## Top 5 Lowest Scoped Beads

| Bead | Score | Reason from scorecard |
|---|---:|---|
| `flywheel-txeui` | 630 | Missing `migrations.primary`; deterministic parser marked no migration/non-code artifact evidence. |
| `flywheel-3atlk` | 650 | Missing `migrations.primary`; same parser-derived gap. |
| `flywheel-43c8f` | 650 | Missing `migrations.primary`; same parser-derived gap. |
| `flywheel-47ife` | 650 | Missing `migrations.primary`; same parser-derived gap. |
| `flywheel-50q5d` | 650 | Missing `migrations.primary`; same parser-derived gap. |

These are "most likely optimistic" only under the deterministic runner. The common failure shape is not direct evidence of implementation theater; it is mostly evidence that the fast-path parser extracted LOC/migration language from dispatch bodies and then found no corresponding non-code artifact. Real verification requires the compliance-verifier and test-depth-auditor subagents.

## Remediation Beads

Remediation beads filed: `0`.

Reason: the pass report explicitly says **do not reopen beads or create completion-debt based on this deterministic-only report alone**. Phase 9 was completed in report-only mode after the local runner hit macOS Bash portability issues. No closed statuses were changed.

Runner repairs applied to make the skill runnable on this machine:

- Set execute bits on the skill shell scripts.
- Patched GNU-only `xargs -d` usage in `inventory-beads.sh`.
- Patched Bash-4-only `mapfile` usage in `remediate.sh`.

## Convergence

Convergence: **more_passes_needed**.

`convergence.json` says this is the first pass, so convergence is undefined until a prior pass exists. The next pass should run with real Phase 4/6 subagents or targeted single-bead audits for the low-scoring scoped beads before filing completion-debt.
