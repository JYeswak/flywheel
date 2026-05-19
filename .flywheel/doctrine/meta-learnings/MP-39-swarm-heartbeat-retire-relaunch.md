# MP-39 — Swarm heartbeat retire-relaunch

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 6+

## Essence

Long-running agent swarms need a heartbeat loop that advances idle agents, retires degraded agents, preserves artifacts, and relaunches clean rounds instead of endlessly prompting stale contexts.

## Where it applies

NTM swarms, Gemini review swarms, cloud coding agents, fungible worker fleets, cross-agent memory, agent connector detection.

## Adoption signal

Swarm workflow has heartbeat cadence, idle detection, rate-limit/degradation detection, retire rules, round summary, and restart/replacement procedure.

## Exemplar skills (≥5)

- `~/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:12` — swarm runs repeated review rounds and kills/relaunches for the next round.
- `~/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:102` — cron heartbeat checks health, feeds idle agents, and retires degraded agents.
- `~/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:167` — rate-limited or Flash agents are retired.
- `~/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:175` — round ends when all agents complete or retire.
- `~/.claude/skills/agent-fungibility-philosophy/SKILL.md:62` — dead agents are replaced with a new session and same init prompt.
- `~/.claude/skills/agent-fungibility-philosophy/SKILL.md:236` — work continues when agents die.
- `~/.claude/skills/gh-coding-agent/SKILL.md:35` — cloud-agent sessions can be listed with status and model.
- `~/.claude/skills/frankenagent-detection/SKILL.md:29` — installed-agent detection returns a stable report of available connectors.

## Adoption recipes

**Recipe 1 — Heartbeat:** every swarm has a periodic health/read-tail/advance loop.

**Recipe 2 — Retire criteria:** degraded model fallback, rate limit, low-quality output, or context drift retires a pane.

**Recipe 3 — Round summary:** each round records active/retired agents, artifacts, key findings, and restart decision.

## Compliance test

```bash
grep -E "(heartbeat|idle|retire|rate-limited|kill and relaunch|dead agents replaced)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
