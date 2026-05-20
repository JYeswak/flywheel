# Skill Scoping Fix Plan - 2026-05-19

Scope: scoped to skill-scoping audit + diff proposals. Skill files under `/Users/josh/.claude/skills` were read-only; no skill source files were mutated.

## Live Classifier Summary

| Metric | Count |
|---|---:|
| Live `SKILL.md` rows classified | 547 |
| Prior audit `SKILL.md` rows | 542 |
| TIGHT | 159 |
| MEDIUM | 377 |
| BROAD | 11 |
| Non-tight remediation queue | 388 |
| Prior broad-fire candidates | 387 |

The live root now has 547 `SKILL.md` files, five more than the prior report. The comparable broad-fire queue remains essentially the same: 388 live non-tight rows versus 387 prior candidates. The delta is live library drift, not an estimate.

Classification contract: TIGHT has explicit trigger signal and path-scope signal; MEDIUM has exactly one; BROAD has description but neither signal.

## Context-Cost Projection

- Non-tight descriptions total `132304` characters across `388` skills.
- Average non-tight description length: `340.99` characters.
- Estimated avoidable context tax if all non-tight skills are scoped: `33228` tokens/session using `ceil(description_chars / 4)` per skill.
- Prior-report framing for 387 broad-fire skills: `340.99 chars x 387 / 4 = 32,991` tokens/session projected reduction.

This is a projection of auto-load noise avoided after scoping, not a claim that every description currently appears in every prompt.

## Top-10 Immediate Scoping Queue

| Rank | Skill | Class | Traffic | Outcomes | Loads | Missing | Decision |
|---:|---|---|---:|---:|---:|---|---|
| 1 | `flywheel` | BROAD | 922 | 922 | 0 | trigger, path | SCOPE-IN-PLACE or RETIRE placeholder |
| 2 | `beads-workflow` | MEDIUM | 798 | 798 | 0 | path | SCOPE-IN-PLACE |
| 3 | `agent-mail` | MEDIUM | 333 | 313 | 2 | path | SCOPE-IN-PLACE |
| 4 | `authentication-authorization` | MEDIUM | 84 | 84 | 0 | path | SCOPE-IN-PLACE |
| 5 | `codebase-audit` | MEDIUM | 72 | 72 | 0 | path | SCOPE-IN-PLACE |
| 6 | `goal-build` | BROAD | 61 | 61 | 0 | trigger, path | SCOPE-IN-PLACE |
| 7 | `commit` | MEDIUM | 58 | 58 | 0 | path | SCOPE-IN-PLACE |
| 8 | `data-quality-validation` | MEDIUM | 52 | 52 | 0 | path | SCOPE-IN-PLACE |
| 9 | `agentic-coding-flywheel-setup` | MEDIUM | 50 | 30 | 2 | path | SCOPE-IN-PLACE |
| 10 | `ci-cd-pipeline` | MEDIUM | 46 | 46 | 0 | path | SCOPE-IN-PLACE |

## Decision Matrix

| Bucket | Count | Rule | Action |
|---|---:|---|---|
| High-traffic non-tight | 153 | Any usage score > 0 | SCOPE-IN-PLACE, highest score first |
| Niche or never-loaded | 235 | Usage score = 0 in outcomes/load events | RETIRE if archived/stale; otherwise defer until touched |
| Archived candidates | 25 | `_archived/` or `.archive/` paths | RETIRE / keep archived, do not spend hand-tuning unless reactivated |
| Bulk-similar families | 21 | Name families such as `agent-*`, `accounts-*`, `customer-*`, `holding-company-*`; live `jsm`/plugin-like skills are already tight or absent from the non-tight queue | BATCH-SCOPE with uniform frontmatter pattern |

## Retire / Archive Candidates

Candidate rule: non-tight and usage score 0. First 30 by path:

- `.flywheel/skills/orchestrator-self-capture` (MEDIUM)
- `_archived/brand-guidelines` (MEDIUM)
- `_archived/cleanup-stories` (MEDIUM)
- `_archived/competitor-alternatives` (MEDIUM)
- `_archived/copy-editing` (MEDIUM)
- `_archived/director` (MEDIUM)
- `_archived/fleet` (MEDIUM)
- `_archived/form-cro` (MEDIUM)
- `_archived/free-tool-strategy` (MEDIUM)
- `_archived/human-mcp` (MEDIUM)
- `_archived/marketing-ideas` (MEDIUM)
- `_archived/marketing-psychology` (MEDIUM)
- `_archived/mcp-n8n` (MEDIUM)
- `_archived/mcp-supabase` (MEDIUM)
- `_archived/onboarding-cro` (MEDIUM)
- `_archived/opencode` (MEDIUM)
- `_archived/orchestrate-phase` (MEDIUM)
- `_archived/paywall-upgrade-cro` (MEDIUM)
- `_archived/popup-cro` (MEDIUM)
- `_archived/prd-edit` (MEDIUM)
- `_archived/prd-validate` (BROAD)
- `_archived/ralph-orchestrator` (MEDIUM)
- `_archived/schema-markup` (MEDIUM)
- `_archived/signup-flow-cro` (MEDIUM)
- `_archived/swarmd` (MEDIUM)
- `_archived/workflow-transition` (MEDIUM)
- `ab-test-setup` (MEDIUM)
- `adobe-creative-enterprise` (MEDIUM)
- `agent-fungibility-philosophy` (MEDIUM)
- `anthropic-cli-patterns` (MEDIUM)

## Batch-Scope Families

- `agent-*`: add `applies_to` for agent infra repos (`/Users/josh/Developer/flywheel/**`, agent runtime paths, or provider-specific repos) and keep trigger phrases domain-specific.
- `accounts-*`, `customer-*`, `billing-*`: add `applies_to` for finance/CRM/accounting project paths only; avoid firing in infra repos.
- `holding-company-*`: add `applies_to` for holding-company docs/plans only; do not auto-load during routine code edits.
- `jsm` / plugin-like skills: no non-tight live queue found in this pass; keep as BATCH-SCOPE pattern if new plugin/jsm variants appear.
- Archived skills: leave archived or add `status: archived` plus no auto-trigger route in the future JSM pass.

## Commands

```bash
.flywheel/scripts/skill-scoping-classifier.sh --output .flywheel/audits/skill-scoping-2026-05-19/CLASSIFIED.jsonl --summary
bash tests/skill-scoping-classifier.sh
```
