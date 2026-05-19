# MP-116 - Cited workpaper calculation ledger

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

High-consequence calculations need workpapers: input documents, rule citations, component breakdowns, assumptions, review flags, and audit trail from source to result.

## Where it applies

Revenue recognition, payroll, tax preparation, underwriting, financial reporting, insurance pricing, regulated calculation scaffolds, and any numeric output that can create liability.

## Adoption signal

The output identifies the governing rule set, decomposes the calculation into components, cites statutory or policy authority, marks missing inputs, and routes review before filing, paying, binding, or publishing.

## Exemplar skills (>=5)

- `~/.claude/skills/revenue-recognition/SKILL.md:27` - contracts decompose into performance obligations, transaction price, allocation, and recognition schedule.
- `~/.claude/skills/revenue-recognition/SKILL.md:31` - revenue judgments must be documented, consistent, and defensible.
- `~/.claude/skills/payroll-processing/SKILL.md:27` - payroll calculations must produce auditable pay stubs from gross pay through deductions to net pay.
- `~/.claude/skills/payroll-processing/SKILL.md:46` - payroll is decomposed into seven processing components.
- `~/.claude/skills/tax-preparation/SKILL.md:26` - every tax calculation cites applicable law, current-year rates, and a paper trail.
- `~/.claude/skills/tax-preparation/SKILL.md:30` - tax outputs include checklist, cited rule application, calculation workpaper, and review flags.
- `~/.claude/skills/tax-preparation/SKILL.md:196` - missing audit trails make deductions indefensible under examination.
- `~/.claude/skills/underwriting-automation/SKILL.md:15` - underwriting outputs risk scores, premium calculations, decisions, and documented rationale.

## Adoption recipes

**Recipe 1 - Source checklist:** collect documents, entity/jurisdiction, period, current rates, and missing-input flags.

**Recipe 2 - Component rollforward:** break the result into ordered components with formulas and intermediate values.

**Recipe 3 - Review gate:** label outputs as workpapers until authorized review approves filing, payment, binding, or publication.

## Compliance test

```bash
grep -E "(workpaper|audit|calculation|citation|rule|schedule|deduction|withholding|review|rationale)" SKILL.md || exit 1
```
