# L154 — CLOSURE-EVIDENCE-CONTRACT-VERSION-ANCHOR

---
id: L154
title: Closure evidence MUST anchor a contract/schema/receipt reference to an explicit version
status: long_term
shipped: 2026-05-11
review_due: 2026-11-11
trauma_class: closure-evidence-missing-contract-version
---

Anyone authoring closure evidence in `.flywheel/audit/<bead>/` (workers on every
bead close, orchestrators on stub closures) MUST include a contract version
anchor (`vN` or `version` or `schema_version`) in the SAME FILE as any
`contract`, `schema`, `receipt`, or `payload` reference. The flywheel/skillos
canonical validator (`~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh`
lines 290-292) emits the Jeff-lens fail `contract_without_version` and BLOCKS
the close when this constraint is violated.

**Trigger condition (case-insensitive grep on the SAME FILE):**
- ANY token in `{schema, contract, receipt, payload}` present
- AND NO token in `{v[0-9]+, version, schema_version}` present

**Result**: Jeff-lens fails with `contract_without_version`; close BLOCKED.

**How to apply:**

1. Identify every `contract` / `schema` / `receipt` / `payload` reference in
   the evidence file.
2. For EACH such reference, ensure a version anchor is present nearby:
   - Inline: "dispatch-packet contract **v1**"
   - Sentence: "Per `schema_version: dispatch-packet.v1` …"
   - Frontmatter: `schema_version: <doctrine-name>/v1` at top of evidence file
   - Footer: "Schema(s) involved: `flywheel-worker-tick/v1`, …"
3. Verify before close via validator dry-run:
   ```bash
   ~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh \
     --evidence .flywheel/audit/<bead-id>/evidence.md --dry-run
   ```
4. If `lens_jeff_fail=contract_without_version` appears, add the anchor + rerun.

**Producers (the load-bearing check):**

```bash
# ~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:290-292
if grep -qiE '(schema|contract|receipt|payload)' "$EVIDENCE_ABS" \
   && ! grep -qiE '(v[0-9]+|version|schema_version)' "$EVIDENCE_ABS"; then
  lens_fail jeff "contract_without_version"
fi
```

**Reason:** Closure evidence that names a "contract" / "schema" / "receipt"
without a version anchor becomes ambiguous as contracts evolve (e.g.,
`dispatch-packet.v1` → `v2`, `flywheel-worker-tick/v1` → `v2`). Future replay
of the close cannot tell which version's invariants the evidence satisfied.
Origin fire: skillos:1 t23.1 closure at 2026-05-11T12:09Z BLOCKED by Jeff-lens;
unblocked at 12:12Z after adding the anchor — promoted to flywheel canonical
doctrine via `flywheel-v38e1.1` and now to L-rule via `flywheel-nerln`.

**Evidence:** doctrine doc `.flywheel/doctrine/closure-evidence-contract-version-anchor.md`
(208 lines, full TL;DR + canonical source + mental model + anti-patterns + sister
doctrines + conformance criteria); validator at
`~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:290-292`;
origin trace skillos-t23.1; parent bead `flywheel-v38e1.1`; promotion bead
`flywheel-nerln`.

**Companion rules:**
- L52 (issues-to-beads-or-explicit-no-bead-receipt) — evidence completeness
- L61 (doctrine-landing-wires-into-AGENTS-and-README) — doctrine wire-in
- L80 (closed-bead-audit-mining) — the audit pass that runs the validator
- L153 (capture-provenance-canonical) — sister Jeff-lens evidence integrity rule
- L154 (this rule) — the closure-evidence anchor invariant

**Canonical source:** `.flywheel/doctrine/closure-evidence-contract-version-anchor.md`
(schema_version: `closure-evidence-contract-version-anchor/v1`)

**Sister rules / cohort:** Part of the 4-rule v38e1 cohort promoted to flywheel
canonical from skillos:1 fuckup-log. Future sister L-rules to file as cohort
members move through promotion gate:
- `closure-evidence-missing-public-lens-anchor` (14:50Z, doctrine shipped via v38e1.2; L-rule pending)
- `inbox-discipline-missed-during-deep-burndown-motion` (17:00Z, doctrine shipped via v38e1.3; L-rule pending)
- `outbox-discipline-cross-orch-ship-notification` (22:30Z, doctrine shipped via v38e1.4; L-rule pending)
