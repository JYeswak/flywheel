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

## L29 — NTM-only doctrine

---
id: L29
title: NTM-only doctrine — never operational tmux for pane I/O
status: long_term
shipped: 2026-04-30
review_due: 2027-04-30
trauma_class: dispatch-substrate
---

**Rule:** All pane operations (send, capture, list, save, grep, health, spawn, kill) MUST route through `ntm` verbs. The underlying terminal multiplexer binary is forbidden in operational substrate. Positive-only instruction — never name the wrong tool in deny messages, examples, or cautionary guidance (negation amplifies salience).

**How to apply:**
- Send to a pane → `ntm send <session> --pane=<n> "..."`
- Capture pane → `ntm copy <session>:<pane> -l <N>`
- Search pane → `ntm grep <session> <pattern>`
- Health check → `ntm health <session>`
- Save snapshot → `ntm save <session>`
- All of the above also via `/flywheel:ntm <verb>` slash surface

**Why:** agents have huge pretraining bias toward the underlying multiplexer name and near-zero on `ntm`. Without active reinforcement (positive-only doctrine + ambient slash surface + intent-detection gate), every agent regresses to the wrong tool every session. The `flywheel-loop-dispatch-transport-gate.sh` denies direct underlying-multiplexer-binary dispatch invocations.

**Evidence:** 2026-04-30 audit found 7+ active `~/.claude/{commands,skills,hooks}/` paths still using direct multiplexer calls; pane 2 audit log at `/tmp/picoz-pane2-flywheel-install-audit.md` Section A.7. Cleanup is bd-cwfs2 substep 8 + ongoing.

## L35 — Every Tier 3 classification requires a paired-tool bead

---
id: L35
title: Tier 3 classification requires paired-tool bead
status: long_term
shipped: 2026-04-19
review_due: 2026-10-30
trauma_class: autonomy-ratchet
---

**Rule:** When classifying a blocker Tier 3 (per CLAUDE.md §Tier 3 / AGENTS.md §L22), file a paired bead `bd-tool-to-downgrade-<class>` in the **same tick**. The paired bead asks: "what tool, if it existed, would make this Tier 2 next time?" Track the ratio of Tier 3 classifications with paired tools built within 30 days. Goal: every recurring blocker class has a tool; Tier 3 shrinks to zero — all gates become coded.

**Why:** 2026-04-19 afternoon. Orphan PID 97714 was classified Tier 3 ("shared-state kill requires approval"). That classification is technically correct but autonomy-ratcheting: every time this class appears, a human is needed. No tool gets built. The autonomy stock drains. Meadows: eroding-goal ratchet (`[ER]`).

**The actual failure:** orphan of a dead python child with `ppid=1` is not "shared state." No live process references it. It's routine ops cleanup. A 5-gate verified reap tool (lsof port + ppid=1 + comm=python3 + cwd + pgrep) is clearly Tier 2 — and I built it this session (`scripts/reap_orphan_ingest.sh`) in ~10 minutes after Josh forced the frame.

**Mechanism:** add to sweep.md STEP 2.5 escalation ladder: after 3 consecutive HOLDs on same blocker, Grade C if paired-tool bead exists, Grade D otherwise. Pattern: `bd-tool-to-downgrade-orphan-ingest-child`, `bd-tool-to-downgrade-<next-class>`, etc.

**Evidence:** `scripts/reap_orphan_ingest.sh` shipped this session. Reaped PID 97714 successfully (5 gates passed, SIGTERM, SIGKILL, launchctl respawn verified). Next orphan = autonomous, not a 9hr Tier 3 stall.


## L50 — SOCRATICODE-MANDATORY-IN-EVERY-DISPATCH (every NTM dispatch surveys what we have before writing what we want)

---
id: L50
title: Socraticode-mandatory in every dispatch
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: substrate-amnesia
---

**Rule:** Every NTM dispatch packet sent to a worker pane MUST require socraticode pre-flight before any design or implementation work begins. Worker callbacks MUST report `socraticode_queries=N` and `indexed_chunks_observed=N`. Zero-query callbacks fail the dispatch contract — orchestrator re-dispatches with the survey requirement re-emphasized.

**Why:** Josh 2026-04-30 mission statement: "I need to ensure that every single dispatch ntm wide is using socraticode to look at what we have — that is part of the mission. We know about what exists in every layer of our playground." Without enforcement, agents repeatedly reinvent existing skills/scripts/L-rules. Substrate amnesia is the failure mode where a 4-month-old solution gets re-derived from scratch because nobody surveyed first. The flywheel only compounds when each cycle reads what prior cycles produced.

**Mandatory pre-flight pattern in every dispatch packet:**

```
## MANDATORY PRE-FLIGHT: socraticode survey

Required calls (MCP tool: `mcp__socraticode__codebase_search`):
1. codebase_search query="<domain term 1>" projectPath="<canonical-not-symlink>" limit=10
2. codebase_search query="<domain term 2>" projectPath="<canonical>" limit=10
... (3-5 queries minimum, more for complex tasks)

Use canonical path (not symlink alias). If `indexed_chunks=0` on every
query, abort and re-run on canonical path (L47-class symlink trauma).

Save findings to /tmp/<step>-research-survey.md.
```

**Mandatory callback fields:**
- `socraticode_queries=N` (count of MCP calls actually made)
- `indexed_chunks_observed=N` (sum of indexed_chunks across results — proves canonical path used)

**Forbidden orchestrator outputs (when dispatching):** packets without a socraticode pre-flight section, packets that reference a symlink path instead of canonical, packets that ask the worker to "go figure it out" without surveying.

**Forbidden worker callback outputs (per dispatch contract):** any DONE/BLOCKED message without `socraticode_queries=` field. Orchestrator treats missing field as DRIFT — re-dispatches with reinforced pre-flight.

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits one ledger-less dispatch (extremely rare; reserved for trivial single-line edits where survey overhead exceeds work).

**Cost citation:** four months of project history accreted scattered scripts/configs/hooks/CLIs because each new task started from scratch instead of surveying. Tonight Josh re-stated the mission explicitly. This rule is the mechanical enforcement of the mission.

**Companion rules:** L46 (picoz-local — Axiom 9 commit-message socraticode trailer for substrate-critical commits) is the commit-time check. L50 (this — canonical) is the dispatch-time check. Both layers needed: dispatch-time prevents re-derivation; commit-time prevents merging without evidence.
