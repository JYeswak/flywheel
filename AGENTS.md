# Flywheel Canonical Operational Doctrine

## How to read this file

This is the canonical "how agents operate" reference, distributed via
flywheel-loop init to every flywheel-installed repo as
`.flywheel/AGENTS-CANONICAL.md`. Each repo's local AGENTS.md should
reference this file and add only repo-specific operational rules.
Domain rules (what we're building, not how we operate) belong in CLAUDE.md.

## L-Rule Schema

Each L-rule below uses this frontmatter (YAML between `---` fences):

| Field | Type | Required | Meaning |
|---|---|---|---|
| id | string | yes | e.g. L48 (canonical id, never reused) |
| title | string | yes | one-line summary |
| status | enum | yes | long_term \| temporary \| retired |
| shipped | date | yes | YYYY-MM-DD when rule first landed |
| sunset_when | object | if temporary | bead: bd-XXX OR metric: <expr> OR date: YYYY-MM-DD |
| review_due | date | yes | YYYY-MM-DD next mandatory re-evaluation |
| trauma_class | string | yes | grouping label (e.g. phantom-substrate) |
| retired_by | object | if retired | bead/metric/date that triggered + retired_at |
| retired_at | date | if retired | YYYY-MM-DD |

## Rules

## L48 — SUBSTRATE-EXHAUSTION-BEFORE-ESCALATION

---
id: L48
title: Substrate-Exhaustion-Before-Escalation
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: phantom-substrate
---

Before any orchestrator message that asks Josh a credential-shaped,
substrate-corruption-shaped, or service-state-shaped question, it MUST first
climb these rungs and produce a probe ledger:

1. **Substrate probe** — `infisical secrets --path=/<service>`, `infisical secrets list --recursive | grep -i <service>`, `cf-secret list`, `gh secret list`, `op item list` (1Password). Alternate creds frequently already exist under a different path.
2. **Self-heal tool** — look for `scripts/<thing>_repair.sh` (e.g. `bead_db_repair.sh` is Tier 2 autonomous, L35). Run it. Substrate corruption usually has a named recovery path.
3. **Skill recovery section** — every relevant `*-ops` / `*-api` / `*-secrets` skill has a "Common failures" or "Recovery" block. `ls ~/.claude/skills/` and read it.
4. **Cross-repo precedent** — `mcp__socraticode__codebase_search` for the exact error string across `~/Developer/*` (canonical paths only, see L47-class symlink trauma); grep `~/.claude/projects/*/memory/` for prior CASS hits.

Only after 4 rungs return "no resolution" may the orchestrator ping Josh. The
escalation message MUST include a probe ledger of what was attempted:

```text
PROBE_LEDGER bead=bd-XXX
  rung1=infisical/cf-secret/gh-secret -> <result>
  rung2=self-heal-tool=<name> -> <exit_code>
  rung3=skill=<name> recovery -> <result>
  rung4=socraticode "<error>" -> <hits>
remaining_ask=<single concrete thing or NONE>
```

**Cost citation:** alpsinsurance pane 1 idle 2026-04-30 — orchestrator hit
Railway token-scope wall (`projectCreate=ok`, `variableUpsert=Unauthorized`),
framed it as "two yes/no questions for Josh" + "2-minute dashboard operation
from your laptop", and went 30-min heartbeat. Substrate had answers:
`infisical-rotation-ops` skill encodes project-token generation, `railway-api`
skill encodes browserless OTP login, parallel `br` corruption blocker had
`bead_db_repair.sh`-class fix in adjacent repo. Project sat idle for hours on a
wall the substrate could resolve.

**Forbidden orchestrator outputs (when not preceded by probe ledger, grade F):**
"two yes/no questions", "2-minute dashboard operation", "do you want to
generate", "should I attempt ... recovery", anything that frames a credential
or substrate problem as a human-only operation without proof the substrate path
was probed.

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits one ledger-less escalation;
logs to `~/.local/state/flywheel-loop/overrides.jsonl`. One-shot only.

**Doctrine artifact:**
`~/Developer/flywheel/templates/flywheel-install/ESCALATION-LADDER.md.tmpl`
ships the canonical 5-rung structure; flywheel-loop init drops it into every
`.flywheel/` install.
