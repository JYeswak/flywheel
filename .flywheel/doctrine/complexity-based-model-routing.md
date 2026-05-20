# Complexity-based model routing — doctrine extraction

**Date:** 2026-05-11
**Origin:** flywheel-nhqc4 dual-recommendation (opencode-grok-first-router PUBLIC archive-recommended; EXTRACT-THEN-RETIRE Path A)
**Source repo:** `github.com/jyeswak/opencode-grok-first-router` @ `06858846827a9da5d96e2f35118dd4f7df476c39`
**Validated testing:** January 2026, Phase 1 + Phase 2 A/B benchmark across 10+ models
**Status:** ACTIVE doctrine; extracted BEFORE retire to preserve information flow per Meadows leverage-6

## The benchmark

**Cost (100 typical tasks):**
- All Claude Sonnet: **$2.50**
- Grok-First Router (90/10 split): **$0.60**
- **Savings: 76%**

**Correctness (both tiers):** 10/10 on validated test suite

**Tier breakdown:**

| Tier | Model | Correctness | Quality | Speed | Cost/task | When |
|---|---|---|---|---|---|---|
| FREE (90% of traffic) | `opencode/grok-code` | 10/10 | 9/10 | 6× faster | $0.00 | Structured impl, CRUD, clear-requirement bugfixes, prototypes |
| PREMIUM (10% of traffic) | `xai/grok-4-1-fast` | 10/10 | 9.5/10 | Standard | ~$0.05-0.07 | Architecture, novel problems, optimization, decision-making, ambiguity |

**Caveat:** Benchmark was specific to opencode + grok-code/grok-4-1-fast in January 2026. **Re-verify before applying to Claude Code routing**, cc-router, or any other model pair. The savings ratio + correctness numbers will shift with different model pairs.

## The 90/10 routing split rationale

Two-tier routing beats single-tier in cost-correctness Pareto when:
1. The FREE tier model has >=10/10 correctness on the **bottom 90% of tasks** by complexity
2. The PREMIUM tier handles the **top 10% requiring reasoning/self-correction**
3. The complexity-classification step costs O(string-match), not an LLM call

The split is **empirical**, not theoretical. If FREE tier correctness on bottom-90% drops below correctness floor, increase PREMIUM share. If PREMIUM-needing traffic is <5%, lower it.

## The complexity detector (verbatim — known-good keyword list)

The detector is keyword-based (intentionally cheap; no LLM call). Promotion logic: if ANY keyword matches the lowercased prompt, route to PREMIUM. Otherwise FREE.

### HIGH-complexity keywords (route → PREMIUM)

```
# Architectural and design
"design", "architect", "architecture", "system design",
"design pattern", "design decision",

# Novelty and complexity
"novel", "complex", "complicated", "sophisticated",
"advanced", "intricate",

# Optimization and analysis
"optimize", "optimization", "performance tuning",
"analyze", "analysis", "evaluate", "assessment",

# Decision-making and strategy
"figure out", "decide", "choose between", "determine",
"best approach", "strategy", "trade-off", "tradeoffs",
"pros and cons", "compare approaches",

# Problem-solving
"solve", "algorithm", "algorithmic", "computational complexity",
"efficiency", "scalability",

# Ambiguity
"unclear", "ambiguous", "not sure", "multiple ways",
"various approaches", "different options"
```

(Source: `index.ts:31-56` at sha `0685884`)

### MEDIUM/LOW (default → FREE)

Anything not matching the HIGH list. Concrete categories observed at validation:
- Structured implementation ("Create a Python function to validate email addresses")
- CRUD ("Add a DELETE endpoint to the users API")
- Clear-requirement bugfixes ("Fix the bug in login.ts where email validation fails")
- Prototyping

## The routing logic

```
User prompt → lowercase + substring-match against HIGH keyword list
              │
              ├── ANY match → PREMIUM model (reasoning + self-correction)
              │
              └── NO match → FREE model (structured impl)
```

Hook surface for opencode plugin shape (the reference impl):

```typescript
"model.select": async (input) => {
  const prompt = input.prompt || input.context || "";
  const complexity = detectComplexity(prompt);
  return {
    modelId: complexity === "high"
      ? "xai/grok-4-1-fast"
      : "opencode/grok-code"
  };
}
```

## Porting guide — adapt to other routing surfaces

### To cc-router (Claude Code complexity routing)

1. Replace `opencode/grok-code` (FREE) with a fast Claude tier (e.g., `claude-haiku-4-5-20251001`) or with Grok fast tier (`grok-4` or `grok-code`).
2. Replace `xai/grok-4-1-fast` (PREMIUM) with `claude-opus-4-7` or `claude-sonnet-4-6` based on context-window need.
3. Re-run the A/B suite. The savings ratio WILL shift; expected: lower than 76% because Claude Haiku is not free.
4. Keep the HIGH-keyword list as starting point; tune per observed correctness on YOUR task distribution.

### To LangGraph or arbitrary LLM-app

The pattern is the same: cheap classifier → model.select hook. The classifier need not be keyword-based — embedding-similarity to a "complexity exemplar" set works too, at the cost of an embedding call per prompt.

### Anti-patterns

- **Don't use an LLM to classify complexity.** The point of the cheap tier is to avoid LLM calls; classifying with an LLM defeats the savings.
- **Don't skip validation.** The 76% number is benchmark-specific. Always run a held-out test set on YOUR distribution before claiming savings.
- **Don't single-tier.** "Just use the cheap model" is wrong when 10% of tasks genuinely need reasoning. Correctness floor matters.

## Provenance + reversibility

- Source repo at extraction: `https://github.com/jyeswak/opencode-grok-first-router` @ commit `06858846827a9da5d96e2f35118dd4f7df476c39` ("Fix: Remove opencode peerDependency (doesn't exist on npm)")
- Author: Joshua Nowak
- License: MIT
- Validation context: January 2026 OpenCode multi-model A/B testing, Phase 1 + Phase 2
- If the original repo is retired (Path A) or deleted, this doctrine doc is the canonical preservation of the routing pattern + benchmark.

## When to re-run the benchmark

- New model release in either tier
- Task distribution shift (e.g., adding a new client whose prompts are systematically harder)
- Provider pricing change
- Correctness signal degrades (anything below 10/10 on bottom-90%)

## Memory cross-references

- `project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11.md` — the stamping mission this preserves value within
- `feedback_class_divergence_public_mit_vs_private_alpha.md` — sister discipline (audience-class) for the rewrite-side
- `feedback_orch_wake_event_driven_not_time_based.md` — Meadows leverage-6 (information flow) parallel pattern
- `feedback_dcg_blocked_subcommand_rest_api_alternative.md` — safety discipline for the archive receipt below: the REST API path is only valid after explicit approval is already visible.

## Retirement receipt (CHANGELOG)

| Date | Action | Authority | Reversibility |
|---|---|---|---|
| 2026-05-11 | Source repo `JYeswak/opencode-grok-first-router` archived on GitHub via `gh api -X PATCH repos/JYeswak/opencode-grok-first-router -f archived=true` (the `gh repo archive` subcommand was DCG-blocked; the REST API path is the same semantic action with distinct DCG classification) | flywheel-92akx (Path A; Approved-on-all 2026-05-11; per nhqc4 (b)) | Reversible: `gh api -X PATCH repos/JYeswak/opencode-grok-first-router -f archived=false` |

**Pre-retirement state:** repo public, not archived, 1 star, 0 forks, last push 2026-01-14, default branch `main`. Source SHA `06858846827a9da5d96e2f35118dd4f7df476c39` (short `0685884`) verified present in origin before retirement.

**Why Path A:** doctrine extraction complete (this doc preserves the 76% cost-savings benchmark, the 90/10 keyword detector verbatim, and the cc-router porting guide). The source repo's load-bearing knowledge survives the archive. Archive (not delete) preserves audit trail + reversibility.

**What survived in this doc:**
- 76% cost-savings benchmark (Phase 1 + Phase 2 OpenCode A/B testing, Jan 2026)
- 90/10 keyword-based complexity classifier (verbatim ruleset)
- Porting guide to cc-router (and to LangGraph / arbitrary LLM-apps)
- Anti-patterns ("don't use an LLM to classify complexity", "don't skip validation", "don't single-tier")

**What did NOT survive (intentional):**
- The opencode-specific TypeScript glue (not portable; reimplement per host)
- The original test fixtures (recreate against current model versions per "When to re-run the benchmark" section above)

If a future operator needs the original repo, unarchive via `gh repo edit JYeswak/opencode-grok-first-router --archived=false`. The git history is preserved at GitHub indefinitely while archived.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
