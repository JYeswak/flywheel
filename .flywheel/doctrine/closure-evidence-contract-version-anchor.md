---
title: "Closure Evidence MUST Include a Contract Version Anchor"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
schema_version: closure-evidence-contract-version-anchor/v1
---

# Closure Evidence MUST Include a Contract Version Anchor

Version: `closure-evidence-contract-version-anchor/v1`
Owner: workers authoring closure-evidence files (any bead/issue closeout)
Status: canonical, shipped 2026-05-11 (promoted from skillos fuckup-log 12:12Z + flywheel-v38e1 ratify-up wave)
Source bead: flywheel-v38e1.1 (parent: flywheel-v38e1 4-rule cohort promotion)
Sister doctrines: feedback_calibrate_test_to_actual_contract_before_filing_upstream.md (family)

## TL;DR (what / who / where)

**Anyone authoring closure evidence in `.flywheel/audit/<bead>/` (workers
on every bead close, orchestrators on stub closures) MUST include a
contract version anchor (`vN` or `version` or `schema_version`) in the
SAME FILE as any `contract`, `schema`, `receipt`, or `payload` reference.**
The flywheel/skillos canonical validator
(`~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh`
lines 290-292) emits the Jeff-lens fail `contract_without_version` and
**BLOCKS the close** when this constraint is violated.

Fix: add an explicit version-anchor sentence near the contract reference
(e.g., "L50-L53 dispatch-packet contract **v1**", "skillos.dispatch_packet_template.**v1**",
"v2 receipt schema", "heredoc contract **v1**").

## Canonical source

This doctrine promotes skillos fuckup-log row 2026-05-11T12:12:00Z
(`class: closure-evidence-missing-contract-version`) to fleet-wide
canonical doctrine per:

- Parent bead: `flywheel-v38e1` (fleet-canonical 4 durable rules wave)
- Ratify-up handoff: `.flywheel/handoffs/20260512T0010Z-from-flywheel-1-to-skillos-1-RATIFY-UP-WAVE-2-COHORT-8-DOCTRINES.md`
- Origin trace: skillos-t23.1 closure at 12:09Z BLOCKED with
  `lens_jeff_fail=contract_without_version`; closure_succeeded_after_version_anchor_added

## Why (motivation; failure-mode the doctrine prevents)

**Failure mode**: closure evidence describes a "contract" or "schema" or
"receipt" abstractly, but a future maintainer or auditor can't tell which
version was operative at close time. When the contract evolves (and it
does — `dispatch-packet.v1` → `v2`, `flywheel-worker-tick/v1` → `v2`,
etc.), the historical close becomes ambiguous: which version's invariants
did this evidence actually satisfy?

**Anti-pattern**: writing "this closure proves the dispatch-packet contract
holds" without a `v1` (or `schema_version`) anchor. Future replay must
either (a) infer the version from commit-date archaeology, or (b) treat
the close as version-indeterminate, devaluing the evidence.

**The trauma class** is `closure-evidence-missing-contract-version`. First
fire 2026-05-11T12:12Z (skillos-t23.1). Sister closures already complied
(b8u.1 ref'd "v2 receipt schema"; 2c8.1+2kj.1 ref'd "heredoc contract v1")
— t23.1 was the outlier missing the anchor.

## Validator implementation (the load-bearing check)

```bash
# ~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:290-292
if grep -qiE '(schema|contract|receipt|payload)' "$EVIDENCE_ABS" \
   && ! grep -qiE '(v[0-9]+|version|schema_version)' "$EVIDENCE_ABS"; then
  lens_fail jeff "contract_without_version"
fi
```

**Trigger condition (case-insensitive grep on the SAME FILE):**
- ANY token in `{schema, contract, receipt, payload}` present
- AND NO token in `{v[0-9]+, version, schema_version}` present

**Result**: Jeff-lens fails with `contract_without_version`; close BLOCKED.

## Mental model

```
Closure evidence file (.flywheel/audit/<bead>/evidence.md)
  │
  ├─ contains "schema"   ──┐
  ├─ contains "contract" ──┤
  ├─ contains "receipt"  ──┼─── trigger condition met
  └─ contains "payload"  ──┘
                            │
                            ▼
               Jeff-lens grep for {vN, version, schema_version}
                            │
                            ├─ FOUND  → close PROCEEDS ✓
                            └─ ABSENT → lens_jeff_fail=contract_without_version
                                        close BLOCKED ✗
```

## How to apply (positive-practice template)

When you write a closure-evidence file at `.flywheel/audit/<bead-id>/evidence.md`:

1. **Identify every contract / schema / receipt / payload reference** in the file
2. For EACH such reference, ensure a version anchor is present nearby:
   - Inline: "dispatch-packet contract **v1**"
   - Sentence: "Per `schema_version: dispatch-packet.v1` (line 215 of dispatch packet)..."
   - Frontmatter: `schema_version: <doctrine-name>/v1` at top of evidence file
   - Footer: "Schema(s) involved: `flywheel-worker-tick/v1`, `mission-fitness-callback-decision.v1`."
3. **Verify before close**: run the validator dry-run:
   ```bash
   ~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh \
     --evidence .flywheel/audit/<bead-id>/evidence.md --dry-run
   ```
4. If `lens_jeff_fail=contract_without_version` appears, add the anchor + re-run.

## Concrete example (load-bearing exemplar)

**MISSING anchor (close BLOCKED):**

```markdown
## Disposition: SHIPPED — dispatch-packet contract satisfied;
evidence shows the receipt arrived per the agreed payload.
```

Jeff-lens fails: contains `contract` + `receipt` + `payload`, no version.

**WITH anchor (close PROCEEDS):**

```markdown
## Disposition: SHIPPED — dispatch-packet contract v1 satisfied;
evidence shows the receipt (schema_version=flywheel-worker-tick/v1) arrived
per the agreed payload.
```

Jeff-lens passes: `v1` and `schema_version` both present.

**This very doctrine doc complies** (the frontmatter `schema_version:
closure-evidence-contract-version-anchor/v1` and the "v1" anchors
throughout demonstrate the pattern).

## Anti-patterns

1. **Vague version language** without `vN`/`version`/`schema_version` token —
   "the latest dispatch-packet shape" is NOT a version anchor; "**v1** of
   the dispatch-packet shape" is.

2. **Version anchor in a DIFFERENT file** (e.g., evidence cites
   `<bead>-patch-artifact.json` whose `schema_version` is in THAT file,
   not the evidence file). The validator greps the evidence file
   in-isolation. Mirror the anchor into the evidence file.

3. **Removing the anchor during late editing** (e.g., concision pass strips
   the "v1" tokens). Run the validator post-edit before close.

4. **Treating the validator as advisory** — it's a hard close-gate. The
   close `br_close_executed=yes` path is INTERCEPTED until the
   `lens_jeff_fail=contract_without_version` resolves.

## Tips / tricks (beyond the basics)

- **Sister doctrines** that pair naturally: `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`
  (validate to current contract, not stale); `feedback_publishability_bar_three_judges.md` (Jeff is one judge — passing his lens is mechanical).
- **Frontmatter anchor pays double**: if you add `schema_version:
  <doctrine-name>/v1` to YAML frontmatter, you've cleared the validator
  AND given downstream consumers a machine-readable version.
- **Sister-class pattern** to `closure-evidence-missing-public-lens-anchor`
  (14:50Z fuckup, sister doctrine in this 4-rule cohort): same Jeff-lens
  validator family, different missing anchor (publishability bar).

## Sister doctrine

- `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md` (canonical-memory family pair per ratify-up handoff)
- `feedback_publishability_bar_three_judges.md` (sister Jeff/Donella/Joshua bar; same validator)
- `feedback_post_wire_or_explain_three_skill_polish_gate.md` (sister polish-gate family)
- `~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh` (load-bearing validator at line 290-292)
- Parent ratify-up handoff: `.flywheel/handoffs/20260512T0010Z-from-flywheel-1-to-skillos-1-RATIFY-UP-WAVE-2-COHORT-8-DOCTRINES.md`
- Skillos origin handoff: `~/Developer/skillos/.flywheel/handoffs/20260512T000000Z-from-skillos-1-to-flywheel-1-WAVE-2-DOCTRINE-COHORT-PROMOTION-READY.md`
- Sister 3 cohort rules (pending promotion this wave):
  - `closure-evidence-missing-public-lens-anchor` (14:50Z)
  - `inbox-discipline-missed-during-deep-burndown-motion` (17:00Z)
  - `outbox-discipline-missed-when-codifying-doctrine-same-session` (22:30Z)

## Conformance

A closure-evidence file proves conformance via:

- File contains at least one of `{contract, schema, receipt, payload}` OR none (vacuously passes if no such reference)
- IF such a reference is present, file ALSO contains at least one of `{v[0-9]+, version, schema_version}` in the SAME FILE (validator greps in-isolation)
- Validator dry-run returns `lens_jeff_pass` (or no `contract_without_version` fail)
- Close gate at `br_close_executed=yes` runs after validator passes

## Below-trauma-class tracking

N=1 confirmed fire (skillos-t23.1 closure at 12:09Z, BLOCKED then unblocked
post-anchor-add). Trauma-class promotion threshold N=4 not met for the
specific `contract_without_version` shape, BUT the broader META-class
**Jeff-lens anchor-missing** (sister to `public_lens_anchor_missing` at
14:50Z) is at N=2 within the v38e1 cohort — pending the 3rd sister rule's
promotion.

Track via fuckup-log if recurs:
`failure_class=closure_evidence_missing_contract_version` (canonical class
name preserved from origin).

## Promotion provenance

- **Origin fire**: skillos:1 fuckup-log row 2026-05-11T12:12:00Z
- **Bead reservation**: flywheel-v38e1 (parent wave; 4 rules) → flywheel-v38e1.1 (this rule)
- **Ratify-up packet**: 2026-05-12T00:10Z flywheel:1 → skillos:1 (sha256-ratification list of 8 doctrines + 4-rule cohort acceptance)
- **Shipped to canonical**: this doctrine doc 2026-05-11T18:0X (worker MagentaPond)
- **Future syncs**: `.flywheel/scripts/doctrine-sync.sh` propagates to fleet on next tick


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
