# MP-05 — Multi-pass saturation

**Discovered:** 2026-05-19T01:00Z
**Discovered by:** skillos:1
**Skills exemplifying:** 5+

## Essence (one sentence)

Repeat a transform pass over the same artifact until diminishing returns proves the system is saturated; never declare done after one pass.

## Where it applies

Bug hunting (audit-fix-rescan), polish work (UI/text), idea generation, security audit, ergonomics audit, code simplification, ZSH matter review-passes.

## Adoption signal

Skill has a `--pass-N` / `--saturation-rounds` flag OR documents an explicit termination condition (diminishing returns metric, score ceiling, finding count < N).

## Exemplar skills (≥5, file:line)

- `~/.claude/skills/multi-pass-bug-hunting/SKILL.md:1` — primary canonical
- `~/.claude/skills/jeff-convergence-audit/SKILL.md:1` — saturation-rounds doctrine
- `~/.claude/skills/agent-ergonomics-cli/SKILL.md:181` — Phase 6 re-score after applied changes
- `~/.claude/skills/repeatedly-apply-skill/SKILL.md:1` — iterate-with-progressive-deepening
- `~/.claude/skills/jeff-swarm-ops/SKILL.md:1` — Jeff's swarm-build process applies multi-pass
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/CHANGELOG.md:1` — 60+ rounds visible in changelog

## Adoption recipes (≥3, per surface)

**Recipe 1 — CLI surface:** add `--pass-N` flag and a `--saturation-threshold` flag; document termination when `findings_delta_pct < threshold`.

**Recipe 2 — Audit doctrine:** include explicit termination condition in the skill's doctrine. Don't say "thorough review" — say "rerun until 3 consecutive passes show no new findings."

**Recipe 3 — Receipt envelope:** every multi-pass artifact carries `pass_n`, `prior_findings_count`, `delta_pct`, and `is_saturated:bool` fields.

## Compliance test (1 mechanical)

```bash
# A multi-pass-aware skill MUST document its termination condition.
grep -E "(diminish|saturation|pass.{0,5}[Nn]|consecutive)" SKILL.md || fail
```
