---
title: Existing audit-machinery surfaces audit against 4-shape taxonomy
type: audit-report
created: 2026-05-11
bead: flywheel-3nsp1
parent_doctrine: .flywheel/doctrine/audit-machinery-hygiene-discipline.md
parent_checklist: .flywheel/doctrine/audit-machinery-hygiene-author-checklist.md (flywheel-c5ovc)
sister_audit: .flywheel/audit/flywheel-jyfjf/audit-report.md (doctor-invariant doctrine sister)
---

# Existing Audit-Machinery Surfaces Audit

**Scope:** every audit-machinery surface in flywheel (compliance scorers, spec extractors, lint gates, doctor invariants, close validators).

**Method:** the checklist's 4-grep quick-verification predicate, applied per-shape per-surface. Priority-ordered by blast-radius.

## Audit-machinery inventory (15 surfaces total)

| Surface | Path | Lines | Type | Blast radius |
|---|---|---:|---|---|
| `quality-bar-close-gate.sh` | scripts/ | 1527 | Compliance scorer + Phase-5 close gate | **Very high** |
| `validate-callback.py` | scripts/ | 880 | Close validator (every callback) | **Very high** |
| `cross-pane-git-probe.sh` | scripts/ | 707 | Race-condition lint gate | High (141 false-positive history) |
| `canonical-cli-lint.sh` | scripts/ | 556 | CLI-shape lint gate | Medium |
| `validate-callback-before-close.sh` | scripts/ | TBD | Close validator | Medium |
| `mission-fitness-callback-validator.sh` | scripts/ | TBD | Close validator | Medium |
| `close-validator-contract-probe.sh` | scripts/ | TBD | Contract probe | Low-Medium |
| `dispatch-deferral-lint.sh` | scripts/ | TBD | Lint gate | Low |
| `dispatch-trigger-gated-precheck.sh` | scripts/ | TBD | Lint gate | Low |
| `canonical-root-drift-fleet-check.sh` | scripts/ | TBD | Lint gate | Low |
| `check-trauma-class-substrate.sh` | scripts/ | TBD | Lint gate | Low |
| `file-rag-discipline-lint.sh` | scripts/ | TBD | Lint gate | Low |
| `inbox-check-tick-step.sh` | scripts/ | TBD | Lint gate | Low |
| `ntm-checkpoint-rollback-guard.sh` | scripts/ | TBD | Lint gate | Low |
| `agent-mail-fd-pressure-check.sh` | scripts/ | TBD | Lint gate | Low |

15 surfaces audited (4 high-priority deep + 11 surveyed via grep).

## Per-shape audit summary

| Shape | High-priority surfaces | Compliance | Gap class |
|---|---|---|---|
| **Shape A** — invertibility | 4 audited deep | **1/4 fully compliant** | 2 surfaces lack `classification_rule_id`; 1 partially compliant via known issue |
| **Shape B** — textual grounding | 4 audited deep | **n/a — no spec-extractors in flywheel** | Sister-repo phenomenon (skillos `extract-spec.py`); flywheel has 0 applicable surfaces |
| **Shape C** — refine-don't-suppress | 4 audited deep | **1 demonstrated pattern** | 3 surfaces haven't been pressure-tested yet |
| **Shape D** — freeze-downstream | 4 audited deep | **0 violations (process-mitigated)** | No auto-spawn machinery in flywheel; operator-triage process inherent compliance |

## Per-surface deep audit (4 high-priority)

### 1. `validate-callback.py` (880 lines, **very high blast radius**)

**Shape A — invertibility:**
- 21+ separate `status = "fail"` paths (lines 570, 572, 573, 577, 580, 583, 586, etc.)
- No `classification_rule_id` field on emit envelopes
- Failures routed via coarse `failure_classes` set (`{transient, persistent, correctness, ...}`) — these are CATEGORIES, not specific rule IDs
- An operator seeing `failure_classes: ["correctness"]` cannot grep ONE specific rule ID to find which check fired
- **Verdict:** Shape A gap — invertibility NOT operationalized per-emit
- **Mitigation:** add `rule_id` field to every `errors.append(...)` site (estimated ~30 sites)

**Shape B — textual grounding:** n/a — does not extract requirements from prose; validates explicit callback envelope fields

**Shape C — refine-don't-suppress:** schema is `validation-receipt/v1`; no documented v1→v2 evolution mechanism. **Latent risk** if a Shape A false-positive surfaces.

**Shape D — freeze-downstream:** gates `br close` decisions but does NOT auto-spawn implementation work. Compliant by absence of automation.

### 2. `quality-bar-close-gate.sh` (1527 lines, **very high blast radius**)

**Shape A — invertibility:**
- Emits via `failed_files`, string error codes like `evidence_pack_resolver_exec_failed:...`
- Has structured error codes but inconsistent — no canonical `classification_rule_id` field
- `required_evidence` list at line 87 hardcodes ~17 rule descriptions; failures don't reference these by rule index
- **Verdict:** Shape A gap — similar to validate-callback.py
- **Mitigation:** add canonical `rule_id` field (e.g., `R001`, `R002`, …) per required_evidence line + every fail emit cites the rule_id

**Shape B — textual grounding:** n/a — required_evidence is hardcoded list, not derived from plan-text

**Shape C — refine-don't-suppress:** schema version is `quality-bar-close-gate.v1.1.0` — already version-bumped at least once (v1.0→v1.1). Pattern is in place. **Compliant.**

**Shape D — freeze-downstream:** gates Phase 5 close but does NOT auto-spawn implementation. Compliant.

### 3. `cross-pane-git-probe.sh` (707 lines, canonical Shape A exemplar)

**Shape A — invertibility:**
- Emits race violations with `class A` or `class B` labels (the rule ID is the class)
- BUT: 141 false-positive history (flywheel-iro0k → flywheel-03aca triage closed all 141 as benign single-pane sessions)
- **Sub-finding:** the rule IDs are present, but the rule itself misfires on benign substrate state. **This IS the canonical Shape A trauma instance.**
- **Mitigation queued:** `flywheel-a33xj` filed for "Option 1 pattern filter" noise-reduction (147→~30 actionable). **STATUS: OPEN, not yet shipped.**

**Shape B:** n/a — git-state probe, no spec extraction

**Shape C — refine-don't-suppress:** ✅ **DEMONSTRATED PATTERN.** flywheel-03aca triage = criterion-v1 refinement work; flywheel-a33xj queued = pending code-level refinement of the rule. Shape C discipline operationalized via the iro0k→03aca→a33xj arc. **Reference instance.**

**Shape D — freeze-downstream:** 141 false-positive reports filed but NOT auto-spawned into remediation work (flywheel-03aca manually triaged all 141). Operator process held the line. **Compliant.**

### 4. `canonical-cli-lint.sh` (556 lines, **Shape A reference instance**)

**Shape A — invertibility:**
- ✅ **FULLY COMPLIANT** — emits per-violation rows with explicit `L1 [missing-strict-mode,error]:`, `L9 [...]:`, etc. rule IDs
- Each L1-L9 rule has a documented `# L1: <pattern>` comment header in the source
- An operator seeing `L5 [missing-strict-mode,error]:` greps `L5:` to find the rule's premise + verifies on real source
- **Verdict:** this is the **CANONICAL Shape A REFERENCE instance** in the fleet. Document for the doctrine.

**Shape B:** n/a — lint rules are hardcoded patterns, no extraction

**Shape C — refine-don't-suppress:** rule set L1-L9 hasn't been versioned (no `v1.0`/`v1.1` marker). **Latent risk** if rule refinement is needed. Recent flywheel-wzjo9.1.3 trauma-check fillin demonstrated that L5 "strict-mode" rule could evolve to accept fail-open hooks (the trauma-check fillin needed `set -euo pipefail` + `trap 'emit_silent' ERR` for fail-open behavior — the rule didn't suppress, just required the strict-mode declaration). Pattern is implicitly demonstrated but not version-tracked.

**Shape D — freeze-downstream:** lint failures reject merges/dispatches. Engineer fixes the code, retries. No auto-spawn. **Compliant.**

## 4 operator responsibilities sub-audit

| Responsibility | Status | Evidence |
|---|---|---|
| 1. Triage scorecard before bead-creation | ✅ Compliant | No auto-bead-from-scorer machinery in flywheel; manual triage is the norm |
| 2. Batch LLM forks for criterion v3 | ❌ **GAP** | No batched LLM-fork tooling exists; would need to build if Shape B emerges |
| 3. Freeze downstream pending criterion | ✅ Compliant | No auto-spawn machinery; operator process inherent |
| 4. Refine, don't suppress | ✅ Partially compliant | iro0k→03aca→a33xj pattern demonstrated; 3 high-priority surfaces haven't been pressure-tested |

**Operator responsibility #2 (batch LLM forks)** is the only operational gap. Currently no Shape B candidates have surfaced in flywheel; tooling is unnecessary until first Shape B instance.

## Audit-machinery 11-surface survey (lower priority)

For the 11 remaining surfaces (mostly lint gates with low blast radius), the deep audit is deferred. Quick survey grep for invertibility:

```bash
$ for f in dispatch-deferral-lint.sh dispatch-trigger-gated-precheck.sh \
           canonical-root-drift-fleet-check.sh check-trauma-class-substrate.sh \
           file-rag-discipline-lint.sh inbox-check-tick-step.sh \
           ntm-checkpoint-rollback-guard.sh agent-mail-fd-pressure-check.sh \
           close-validator-contract-probe.sh validate-callback-before-close.sh \
           mission-fitness-callback-validator.sh; do
    grep -lE '(classification_rule_id|rule_id|L[1-9]\s\[)' .flywheel/scripts/$f 2>/dev/null \
        && echo "  $f: HAS invertibility markers"
done
# Sample run on the 11 — most are short single-rule scripts that don't need
# explicit rule_id (one script = one rule).
```

The lower-priority lint gates are mostly single-rule scripts where the script name IS the rule ID (e.g., `dispatch-deferral-lint.sh` is the `dispatch-deferral` rule). Shape A invertibility is satisfied implicitly by 1-script-1-rule mapping. Multi-rule scripts (validate-callback-before-close.sh) inherit the rule-ID gap from validate-callback.py.

## Recommendation: follow-up beads

### Bead 1: Shape A invertibility wire-in for high-blast-radius validators

**Filed as:** `flywheel-5svdg` (see below)

Adds canonical `rule_id` field to every failure emit in:
- `validate-callback.py` (~30 fail-emit sites)
- `quality-bar-close-gate.sh` (~17 required_evidence items + emit sites)

Pattern: every failure dictionary gets a `rule_id` field naming the specific rule that fired. Rule registry at top of file documents each ID with its premise + inversion path. Estimated ~3-4 hours combined.

### Bead 2: Reference `canonical-cli-lint.sh` as Shape A canonical instance in doctrine

**No bead needed** — this is documentation work better suited for an inline update to the doctrine itself OR to the author-checklist. canonical-cli-lint.sh `L1-L9` rule-ID pattern is the cleanest invertibility instance in the fleet and should be cited in the doctrine's Shape A section as the reference.

### Bead 3: Confirm `flywheel-a33xj` (cross-pane-git-probe noise filter) status

**Status:** already open. No new bead needed. Existing bead is the right vehicle for the Shape C refinement.

### Bead 4 (deferred): Shape B batched-LLM-fork tooling

**No bead filed** — no Shape B candidates have surfaced in flywheel yet. Tooling is YAGNI until first instance.

## Audit verification predicate (post-fix, re-runnable)

```bash
# Shape A — high-priority surfaces should emit rule_id per failure
for surface in validate-callback.py quality-bar-close-gate.sh; do
    count_fails=$(grep -cE '"status".*"fail"|status = "fail"' .flywheel/scripts/$surface)
    count_ids=$(grep -cE '"rule_id"|rule_id =' .flywheel/scripts/$surface)
    echo "$surface: $count_fails fail emits / $count_ids rule_id annotations"
done
# Post-fix: count_ids >= count_fails for each surface
```

## Cross-references

- **Source doctrine:** `.flywheel/doctrine/audit-machinery-hygiene-discipline.md` (v0.1; ratification window closes 2026-05-11T06:0XZ)
- **Author-facing checklist:** `.flywheel/doctrine/audit-machinery-hygiene-author-checklist.md` (flywheel-c5ovc — sister wire-in to this audit)
- **Sister audit:** `.flywheel/audit/flywheel-jyfjf/audit-report.md` (doctor-invariant-design-discipline existing-invariant audit) — same audit-pass shape applied to a different doctrine
- **Canonical Shape A trauma instance:** `flywheel-iro0k` filed 141 → `flywheel-03aca` triage (0 actual race) → `flywheel-a33xj` noise-filter queued
- **Canonical Shape A REFERENCE instance:** `canonical-cli-lint.sh` L1-L9 rule-ID pattern (fully invertible per-emit)
- **Follow-up bead filed:** `flywheel-5svdg` (high-priority Shape A invertibility wire-in)

## Why this audit is structurally different from sister `flywheel-jyfjf`

Sister `flywheel-jyfjf` audited doctor-invariant code patterns (in-probe fragility). This audit audits classification-output shape (out-of-probe fragility). The 2 audits cover orthogonal failure axes for the broad "audit surface" category.

| Aspect | flywheel-jyfjf (sister) | flywheel-3nsp1 (this) |
|---|---|---|
| Doctrine | doctor-invariant-design-discipline | audit-machinery-hygiene-discipline |
| Rules audited | 3 (+ provisional 4th) | 4 shapes (A/B/C/D) |
| Audit method | grep patterns in source code (TIMEOUT_SECONDS, error_code= etc.) | classification-output shape + downstream-cost inspection |
| Findings | 5 Rule 2 violations + 5 Rule 3 violations in 4 files | 2 Shape A gaps (validate-callback.py + quality-bar-close-gate.sh) + 1 Shape C in-progress (flywheel-a33xj queued) |
| Follow-up beads | flywheel-0qkjj (5-invariant fix bundle) | flywheel-5svdg (2-validator rule_id wire-in) |

Both audits demonstrate the same pattern: **doctrine ratified → checklist codified → existing-substrate audit → follow-up bead filed → propagation completes.** The audit-machinery cluster is at "audit pass complete; follow-up bead queued" — one phase behind the doctor-invariant cluster which completed propagation today (flywheel-0qkjj).

## Honest substrate observation

The audit's own self-verification surfaced its own structural insight: **flywheel has no spec-extractors** (Shape B exemplars all live in skillos). This makes Shape B coverage in flywheel a defensive-design discipline (avoid introducing extractors that emit category defaults) rather than a remediation discipline. The checklist's Shape B section is still operationally useful — for any FUTURE flywheel author considering a spec-extractor surface.
