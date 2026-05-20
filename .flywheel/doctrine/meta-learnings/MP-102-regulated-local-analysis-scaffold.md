# MP-102 - Regulated local analysis scaffold

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Regulated workflows can be usefully automated only as local, non-mutating analysis scaffolds that mark outputs as drafts, preserve audit fields, and route decisions to authorized humans or systems.

## Where it applies

Insurance claims, policy administration, contracts, deal desk, prior authorization, clinical documentation, legal-adjacent work, and any system where a local tool must not bind, approve, deny, pay, settle, or submit.

## Adoption signal

The artifact states the forbidden live actions, uses synthetic or explicitly approved data, includes assumptions and source fields, and labels downstream decisions as draft material requiring review.

## Exemplar skills (>=5)

- `~/.claude/skills/claims-processing/SKILL.md:15` - claim workflows require a complete audit trail.
- `~/.claude/skills/claims-processing/SKILL.md:46` - local scaffolds cannot approve, deny, reserve, settle, pay, or close claims.
- `~/.claude/skills/policy-administration/SKILL.md:15` - policy transactions require integrity, premium impact analysis, compliant documents, and auditability.
- `~/.claude/skills/policy-administration/SKILL.md:46` - local output cannot bind, endorse, cancel, reinstate, bill, or issue a policy.
- `~/.claude/skills/contract-negotiation/SKILL.md:45` - contract work identifies fallback positions, escalations, and human gates.
- `~/.claude/skills/deal-desk/SKILL.md:35` - deal artifacts produce approval tiers, risk flags, and human gates without granting approval.
- `~/.claude/skills/prior-authorization/SKILL.md:16` - the workflow is documentation assembly, submission tracking, denial handling, and appeals.
- `~/.claude/skills/clinical-documentation/SKILL.md:147` - copy-forward and incomplete review create clinical documentation risk.

## Adoption recipes

**Recipe 1 - Forbidden-action banner:** list the exact live mutations the local tool cannot perform.

**Recipe 2 - Draft packet:** include assumptions, source fields, reviewer, open questions, and a draft label on every regulated conclusion.

**Recipe 3 - Review route:** name the authorized system or human gate that can turn the draft into a real decision.

## Compliance test

```bash
grep -E "(draft|human review|audit|assumption|source fields|cannot|approve|deny|bind|settle|submit)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-57-regulated-evidence-redaction-chain.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-99-authorized-sandbox-envelope.md`
