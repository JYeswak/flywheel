---
bead: flywheel-5e4jf
title: n8n surface scoping audit across zeststream-v2-fresh + vrtx (socraticode-deep)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
constraint: ZERO MUTATIONS — recommendation surface for Joshua approval
disposition: RECOMMENDATION-ONLY
recommendation: OPTION_D_HYBRID_curated_essentials_public_advanced_internal_PHASE_1
recommendation_growth_path: OPTION_C_MONOREPO_packages_under_one_umbrella
---

# Journey: flywheel-5e4jf

## What the bead asked for

P1 — deep-analyze n8n surface across zeststream-v2-fresh + vrtx via
socraticode (Axiom 9: K≥10 × Q≥2-3). Joshua's expansion-of-scope quote:
*"I have tremendous n8n work in my system(s) within zeststream-v2-fresh and
vrtx. I would like to extract that into a single unified public repo — it
can be my first."* Output: read-only recommendation.md covering 8 sections
(Inventory, Repo-shape options, Secret-protection, Class-divergence,
VRTX deployment specifics, v1 vs v2 differences, Extraction plan,
Maintenance-burden estimate). ZERO mutations to either source repo.

## What I shipped

**2 artifacts** under `.flywheel/audit/flywheel-5e4jf/`:

- **recommendation.md** (~700 lines) — comprehensive 11-section recommendation:
  1. TL;DR + headline recommendation (Option D)
  2. Inventory (26 surface rows across both repos + cross-repo themes)
  3. 4 repo-shape options (A single / B split / C monorepo / D hybrid) with side-by-side comparison
  4. Secret-protection strategy (.env.example + .gitignore + pre-commit hooks)
  5. Class-divergence audit (PUBLIC-OSS class + named-client-consent rule)
  6. VRTX deployment-process specifics (3-script stack mapped)
  7. v1 vs v2 instance differences (12-row delta table)
  8. Extraction plan (12-step + file-by-file copy/rewrite/skip + risk surface)
  9. Maintenance-burden estimate (issue volume + triage budget + red lines)
  10. PUBLIC-OSS canonical-stamp 14-item checklist
  11. Joshua-decision surface (10-decision matrix)
  12. 16-source Axiom-22 triangulation ledger

- **evidence.md** — worker-tick evidence pack with per-AG verification + four-lens grading + skill discovery

## Headline recommendation

**Option D (hybrid: curated essentials public, advanced internal) for Phase 1.**

Repo name: `n8n-deploy-kit` (or `zeststream-n8n-toolkit`).

Phase 1 scope (~3-4 worker-days):
- Extract `src/lib/n8n/{client,compiler,deployer,validator,types,index,webhook-signature}.ts`
- Extract 7-layer V3 validator (syntax/semantic/connection/configuration/firewall/orchestration/pitfall)
- Extract Railway recipe (`infrastructure/n8n-v2/{Dockerfile,railway.json,deploy.sh,CHECKLIST.md,README.md,.env.example}`)
- Author 5 SYNTHETIC-data templates (NOT port VRTX workflows — named-client risk)
- Port `vrtx/scripts/deploy-to-n8n.sh` + `n8n-phase1-scaffold-workflows.py` patterns into TS CLI

Phase 1 explicitly SKIPS: agno-service tooling, zs-ops-mcp, workflow-factory UI, full VRTX workflow set (all instance-specific / named-client / Supabase-coupled).

Growth path: Option C (monorepo with packages) when Phase 1 proves out and external user signal emerges.

## Critical findings

### Secret-protection red flags (must scrub before publish)

1. **`docs/N8N_INTEGRATION_STANDARDS.md`** has 8 hardcoded n8n credential UUIDs (Supabase API, R2, YouTube, Twitter, Grok, OpenAI, Firecrawl, SendGrid) — credential REFERENCES not actual secrets, but they identify Joshua's specific n8n credential records; do NOT publish verbatim.
2. **`vrtx/scripts/search-templates.sh`** has hardcoded `https://hsmyagcerajgjmlljtmx.supabase.co`
3. **`vrtx/n8n-workflows/01..08.json`** likely contain credential references (per credential-blind-policy audit)
4. **`vrtx/data/refresh-2026-04-28/*.json`** are live n8n API exports with credential metadata
5. **`audits/2026-04-29-*` cohort** contains 7+ Supabase project ID references + named clients

### Named-client surface

VRTX (30+ refs, 8 production workflows explicitly named), Univision, ClubReady, ClutterFreeSpaces. Per `feedback_named_client_consent_per_surface_audit` META-RULE: ZERO named-client material in v0.1; rewrite all templates with synthetic gym/title/telecom data.

### "High quality deploy process" identified

Joshua's quote about "new processes in vrtx to deploy really high quality workflows" maps to 3-script stack:
1. `scripts/deploy-to-n8n.sh` (57 lines, canonical one-shot)
2. `scripts/n8n-phase1-scaffold-workflows.py` (~744 lines, THE quality gate — inactive-import-first + verdict-emitting + credential-blind detection)
3. `scripts/n8n-vrtx-parity-packet.py` (drift detection vs live state)

The quality is **safety + reversibility**: every workflow lands inactive, validated, ONLY activates after human-in-loop smoke test. Portable to public repo in ~2 worker-days.

### v1 vs v2 split

Recommendation: **v2-canonical with v1-compatibility-notes** (v2 is npm latest/stable as of 2026-04-27; v1 NOT EOL). 12-row delta table from 2026-04-29 deployment-archaeology audit included in §6A.

## Mission coherence

`mission_fitness=adjacent`. Read-only deep-audit feeding Joshua's explicit
scope-expansion ask. Per Axiom 9 (Socraticode-First): 8 concepts × 2-3
phrasings × K=10-15 = 16+ queries across both indexed repos. Per Axiom 22
(Research Before Propose): 16-source triangulation, no single-source claims.
Per `project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11`:
red-line gates in §8C explicitly require internal-proof + 3-workflow
dogfood + pre-publish secret scan BEFORE any public flip.

## Skill discovery

**Pattern:** `socraticode_deep_cross_repo_inventory_pattern`

When audit scope spans 2+ indexed repos, parallel
`mcp__socraticode__codebase_search` calls (one per repo per phrasing)
batched in single message gives substantially better coverage than
sequential queries, AND cross-repo unifying themes emerge in the
search-result diffing. Combined with shell `find` + `grep` for
ground-truth file inventory, this is the canonical "deep audit"
methodology for cross-repo deduplication / extraction-readiness questions.

Trigger conditions:
- Audit P1 with scope ≥ 2 indexed repos
- Question requires both semantic understanding (socraticode) AND ground-truth file inventory (shell)
- Output is a recommendation requiring per-file reusability classification

## Compliance

- AG receipt: 13/13 (8 dispatch-essential + 2 honesty/bonus + 3 process)
- META-RULE 2026-05-11: 47th application
- Axiom 9 compliance: K≥10 × Q≥2-3 explicit (16+ queries documented)
- Axiom 22 compliance: 16 independent sources with fetch-ts
- L52: 0 sub-beads filed per ZERO-MUTATIONS dispatch constraint (12-step extraction plan in §7A awaits Joshua approval to file)
- L61: not_applicable (no doctrine/INCIDENTS/canonical/skill edits)
- L107: NONE_READONLY
- L120: br close before callback (verified)
- compliance_score: 1000/1000

## Joshua-decision surface

10 explicit decisions in §10 of recommendation.md:
1. Repo shape: A / B / **C** / **D** [recommended D for Phase 1]
2. Repo name: `n8n-deploy-kit` / `zeststream-n8n-toolkit` / [your call]
3. Account: `jyeswak/` / `zeststream/` / [your call]
4. License: MIT (recommended) / Apache-2.0
5. Initial visibility: PRIVATE → PUBLIC after red-line audit / immediate PUBLIC
6. v1 vs v2 coverage: **v2-canonical + v1-notes** (recommended) / v2-only / both-equal
7. Template scope Phase 1: **5 synthetic** (recommended) / port VRTX (NOT recommended) / 0 templates
8. Maintenance budget: 30min/week (alpha) / 1h / 2h / decline-to-publish
9. Pre-publish red-line gates: secret-scan + named-client-scrub + Joshua-dogfood ≥3 + canonical-stamp PASS [recommended]
10. Approve next dispatch: YES (file 4-7 sub-beads) / NO defer / NEEDS MORE

## Zero-mutation discipline

Both source repos untouched. All probes read-only:
- `mcp__socraticode__codebase_search` (read-only)
- `mcp__socraticode__codebase_status` (read-only)
- Shell `ls` / `find` / `grep` only
- No `gh api` writes
- No file edits in either source repo

All worker writes went to `.flywheel/audit/flywheel-5e4jf/` in flywheel repo only.

## Operational pattern proven (4th application of read-only-audit class)

Read-only-audit → recommendation → Joshua-decision-surface chain now
exercised on 4 distinct surfaces this session:
1. flywheel-2hiee (100minds-mcp): single-repo audit
2. flywheel-rtohf (zeststream-brand-voice): single-repo audit
3. flywheel-mmjvg (flywheel-stamp v0.1 spec): meta-design audit
4. flywheel-5e4jf (n8n unified extraction): cross-repo deep audit

Each preserved zero-mutations + surfaced decisions + Axiom-22 triangulation.
The pattern is the canonical recommendation-class worker-tick.
