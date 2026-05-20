# MP-103 - Criteria evidence mapping packet

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

High-stakes submissions and proposals should map every external criterion to specific evidence, gaps, assumptions, and reviewer-ready next actions before prose is written or submitted.

## Where it applies

Prior authorization, medical necessity documentation, RFP responses, proposal generation, policy/claims reviews, compliance matrices, and any work judged against explicit criteria.

## Adoption signal

The work product contains a row for each SHALL, payer criterion, required document, or decision standard, with evidence location, status, gap, owner, and review decision.

## Exemplar skills (>=5)

- `~/.claude/skills/prior-authorization/SKILL.md:121` - each payer criterion must map to specific clinical evidence.
- `~/.claude/skills/prior-authorization/SKILL.md:168` - peer review prep maps evidence to criteria, alternatives, risks, and call documentation.
- `~/.claude/skills/clinical-documentation/SKILL.md:109` - payer policies require linking diagnosis to treatment rationale.
- `~/.claude/skills/clinical-documentation/SKILL.md:167` - documentation supports medical necessity for every order.
- `~/.claude/skills/rfp-response/SKILL.md:27` - SHALL, MUST, WILL, SHOULD, MAY, weights, dates, and ambiguities are extracted before drafting.
- `~/.claude/skills/rfp-response/SKILL.md:95` - the compliance matrix comes before writing and covers every mandatory row.
- `~/.claude/skills/requirements-gathering/SKILL.md:130` - traceability tables connect origin, implementation, test, and status.
- `~/.claude/skills/proposal-generation/SKILL.md:30` - proposals draft only from gathered facts and flag missing terms.

## Adoption recipes

**Recipe 1 - Criterion ledger:** enumerate every required criterion before drafting response text.

**Recipe 2 - Evidence pointer:** attach each criterion to a source field, document, quote, lab, contract clause, or implementation artifact.

**Recipe 3 - Gap route:** mark unsupported rows with owner, question, risk, and reviewer action instead of burying uncertainty in prose.

## Compliance test

```bash
grep -E "(criterion|criteria|evidence|matrix|traceability|SHALL|MUST|medical necessity|gap|review)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-74-assertion-control-evidence-chain.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
