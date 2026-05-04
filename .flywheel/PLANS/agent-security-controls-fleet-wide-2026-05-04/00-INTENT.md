# INTENT — agent-security-controls-fleet-wide

**Slug:** agent-security-controls-fleet-wide-2026-05-04
**Started:** 2026-05-04T00:27Z
**Owner:** Joshua Nowak (delegated to flywheel:1 RubyCreek for Phase 1-3)
**Trigger:** Joshua flag 2026-05-04T00:25Z citing zodchii Twitter thread on Claude Code .env leak vectors. "I want proper /flywheel:plan for the security."

## Topic (verbatim from /flywheel:plan invocation)

agent-security-controls-fleet-wide

## Meadows leverage analysis (#5 RULES)

```
SYSTEM: Claude Code + Codex agent runtime accessing project filesystems with
        secrets across 17 flywheel-installed repos.
STOCK:  Secrets-in-conversation-logs sent to Anthropic/xAI servers. Currently
        UNKNOWN baseline (zero deny rules in settings.json).
PATTERN: Three leak paths — direct file read, runtime output capture, grep/search.
LOOP:   Missing balancing feedback. CLAUDE.md advisory rules are reminder-
        substitution (ANTI-PATTERNS.md #3); only settings.json deny rules are
        system-level enforcement.
LEVERAGE_POINT: #5 RULES — same family as auth-marker/v1 ratification yesterday.
INTERVENTION: Multi-layer defense (settings.json deny + .env.test fixtures +
              pre-commit hook + container isolation + cross-corpus learning).
              Fleet-wide via ft04 sync mechanism.
MEASURE: Doctor signals settings_deny_rules_count, env_in_gitignore,
         pre_commit_secret_hook_present, leaked_secret_pattern_count.
```

## Goal

Fleet-wide agent-security control via canonical settings.json deny-rule contract + per-repo doctor signals + .env.test fixture pattern + pre-commit hook + cross-corpus learning extraction (Jeff repos). Defense-in-depth.

## Three leak vectors (zodchii)

1. **Direct file read** — agent scans project, opens `.env`, contents become conversation context
2. **Runtime output capture** — failed HTTP request logs `Authorization: Bearer sk-live-abc...`; database timeout dumps connection string
3. **Grep/search** — agent greps for function name, hits config file with credentials, output includes matched lines with secrets

## Scope

- **Lane A — problem-space:** enumerate ALL leak vectors, current exposure across 17 repos, blast radius classification (Anthropic API keys, Stripe live keys, AWS, GitHub tokens, infisical refs, agent-mail tokens, etc.). Probe current `~/.claude/settings.json` and per-repo `.claude/settings.json` for deny rules. Probe `.env` presence in `.gitignore` per repo. Probe pre-commit hooks for secret detection.
- **Lane B — ecosystem-audit:** query Jeff corpus (NOW INDEXED — 85/177 incl ntm/meta_skill/mcp_agent_mail) for security patterns. zodchii's deny-rule list is one source; Jeff's destructive_command_guard, agent-sandboxing, mcp-secret-scanner skills are others. ADOPT/EXTEND/AVOID per primitive.
- **Lane C — implementation-design:**
  - settings.json canonical deny block (subset matching auth-marker/v1 sandbox-only paradigm — fail-closed by default, override-by-comment for legitimate reads like `~/.claude/projects/.../memory`)
  - Propagation via ft04 sync mechanism for ALL flywheel-installed repos
  - .env.test fixture standard (dummy values for runtime output safety)
  - pre-commit hook secret-pattern detector (Anthropic sk-ant-, Stripe sk-live-/sk_live_, GitHub ghp_/gho_, AWS AKIA, Slack xox-, SendGrid SG., JWT eyJ, BEGIN PRIVATE KEY)
  - Doctor signals: `settings_deny_rules_present`, `env_in_gitignore`, `pre_commit_secret_hook_present`, `leaked_secret_pattern_count`
  - Container isolation pattern for prod-credential work (nuclear option)
  - Companion to flywheel-2zsj storage-discipline (also fleet-wide via ft04)

## Companion beads (already filed, sibling rules)

- flywheel-ft04 CLOSED (root-AGENTS sync mechanism — propagation pipe)
- flywheel-2zsj CLOSED 2026-05-04T00:27Z (storage-discipline-system-wide — pattern this should follow)
- flywheel-useh OPEN (file-length-discipline — sibling fleet rule)
- flywheel-o7dq OPEN (daily-report — security section consumer)

## L-rule candidate

**L74 AGENT-SECURITY-DENY-RULES-CANONICAL** — ratifies settings.json deny block as fleet doctrine. Auth-marker/v1 in flywheel:1 yesterday is sibling #5 RULES leverage proof.

## Skills to consult (per /flywheel:skills-best-practices META-RULE)

- agent-security
- cryptography-and-auth
- mcp-secret-scanner
- infisical-secrets, infisical-rotation-ops
- agent-sandboxing
- ecosystem-port-security
- security-pen-testing, security-audit-for-saas
- secret-output-probe-error (existing trauma class in fuckup-log)
- destructive-command-guard / dcg (Jeff substrate skill)

## Pipeline scope

`--through=polish` (default 5-phase). Joshua-disposes pause AFTER Phase 3 audit per skill spec.

## Why P0 + full 5-phase plan

- Cross-cutting: 17 repos, 3 leak vectors, 4+ defense layers
- Multi-file architectural decision
- Joshua wants /flywheel:plan explicitly
- Cost: 12-20 worker dispatches over 5 phases is justified — cheaper than one secret leak to Anthropic logs

## Capacity note

Phase 1 spec wants 3 WAITING codex panes for parallel fanout. Current state: p2 WAITING, p3+p4 in flight. **Sequential mode chosen:** Lane A dispatches to p2 NOW; Lane B + Lane C queue for next freed panes (per flywheel-loop dispatch-log) and auto-fire on callback reap. State persists in STATE.json so resumption is durable.
