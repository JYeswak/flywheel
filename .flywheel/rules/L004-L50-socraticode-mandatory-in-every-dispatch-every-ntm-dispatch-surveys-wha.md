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

### Doctrine Note — Skills Library Load-Bearing META-RULE

The skills library is a first-class substrate, not a fallback reference. At every
project start, milestone shift, or mission pivot, consult
`/flywheel:skills-best-practices <domain>` before socraticode or research-triad
work. Adopted skill references belong in mission-lock receipts, dispatch
packets, or bead descriptions so the reusable practice survives beyond the
current pane.

Evidence:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_skills_library_load_bearing.md`.


