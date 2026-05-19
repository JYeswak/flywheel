# MP-72 — Reconciled financial exception ledger

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Finance workflows become trustworthy when every balance ties to an authoritative ledger, every variance is decomposed, and every exception routes to a bounded approval or investigation path.

## Where it applies

Accounts payable, accounts receivable, cash forecasting, budgets, board reporting, expense review, revenue recognition, payroll, and any financial automation that can create false confidence.

## Adoption signal

The skill requires GL or bank reconciliation, aging or variance buckets, materiality thresholds, exception routing, and an audit trail that explains each financial number.

## Exemplar skills (≥5)

- `~/.claude/skills/accounts-payable/SKILL.md:64` — AP subledger reconciles to the general ledger.
- `~/.claude/skills/accounts-payable/SKILL.md:246` — AP aging total ties to the GL payable balance.
- `~/.claude/skills/accounts-receivable/SKILL.md:216` — AR aging total ties to the GL receivable balance.
- `~/.claude/skills/accounts-receivable/SKILL.md:217` — every invoice appears in exactly one aging bucket.
- `~/.claude/skills/cash-flow-management/SKILL.md:69` — cash forecasting uses bank balance, not accounting balance.
- `~/.claude/skills/cash-flow-management/SKILL.md:149` — assumption changes need an audit trail.
- `~/.claude/skills/budgeting-forecasting/SKILL.md:163` — material variances are decomposed into price, volume, mix, and timing.
- `~/.claude/skills/financial-reporting/SKILL.md:238` — statements cross-verify GL, subledgers, and bank.
- `~/.claude/skills/expense-management/SKILL.md:221` — hard limits stay hard unless CFO approval is explicit.

## Adoption recipes

**Recipe 1 — Tie-out first:** every report starts with the authoritative GL, bank, payroll, or billing source and records reconciliation status.

**Recipe 2 — Bucket exceptions:** invoices, variances, expenses, and cash gaps get deterministic buckets with thresholds and owner routing.

**Recipe 3 — Explain the delta:** material movements include root cause, source rows, reviewer, and follow-up action.

## Compliance test

```bash
grep -E "(reconcile|GL|general ledger|bank balance|aging bucket|variance|approval|audit trail|material)" SKILL.md || fail
```
