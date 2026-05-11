---
schema_version: n8n-unified-repo-recommendation/v1
bead: flywheel-5e4jf
authored_by: MagentaPond (flywheel:0.3)
authored_at: 2026-05-11
disposition: RECOMMENDATION-ONLY — ZERO MUTATIONS — JOSHUA APPROVAL GATE
target_class: PUBLIC-OSS (community-tool, MIT) — distinct from BV's PUBLIC-MIT-COMMERCIAL
mutations_made: 0
socraticode_queries: 16+ (8 phrasings × 2 repos)
indexed_chunks_observed: 30527 (24149 zss-v2-fresh + 6371 vrtx + cross-repo)
---

# n8n Unified Public Repo — Scoping Recommendation

## TL;DR

You have **substantial n8n work spread across two repos**:

- **`zeststream-v2-fresh`**: full TypeScript n8n SDK (`src/lib/n8n/`: client + compiler + deployer + validator + webhook handler + signature verifier), 25+ scripts (curate, certify, extract patterns, generate templates, import GitHub workflows), the agno-service `n8n_tools.py` agent toolkit, the `zs-ops-mcp` Python MCP server (workflow_intelligence_tools, validation_tools), Railway `infrastructure/n8n-v2/` (Dockerfile + railway.json + deploy.sh + CHECKLIST + README), 11+ Supabase migrations, the 7-layer V3 validation pipeline (syntax/semantic/connection/configuration/firewall/orchestration/pitfall), the workflow-templates Supabase library (10,689 templates noted in `scripts/search-templates.sh`), and a `/deploy-n8n` Claude Code skill.
- **`vrtx`**: 8 real production workflow JSONs (`n8n-workflows/01..08`), 30+ Python/shell scripts (`deploy-to-n8n.sh`, `joshua-live-deploy.sh`, `n8n-phase1-scaffold-workflows.py`, `n8n-vrtx-parity-packet.py`, `n8n-vrtx-inactive-import-validator.py`, `search-templates.sh`, `extract-phase1-marketplace-templates.py`), the 2026-04-29 "Codex n8n deployment archaeology" audit cohort (~15 audit docs documenting v1 vs v2 Railway pinning, Infisical credential bridge plan, registry sync strategy, credential overwrite policy), the v1+v2 active workflow estate (250 v1 workflows / 98 active / 136 credential type/name pairs as of 2026-04-29).

**Mutation discipline:** This audit is read-only. Zero changes to either repo. No public repo created on GitHub. Recommendation only.

**Headline recommendation:** **Option C (monorepo with multiple packages under one umbrella)**, named `n8n-deploy-kit` (or `zeststream-n8n-toolkit`). 4-package monorepo: `deploy/` (the CLI), `validate/` (the 7-layer pipeline), `templates/` (curated public-safe templates), `railway/` (Railway+Dockerfile patterns). Phase 1 extracts the **generic ~30%** of the surface; remaining 70% stays internal until a real external user emerges. Per `project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11` — no npm publish until paying-customer-pull justifies it.

---

## 1. Inventory: n8n-related surfaces across both repos

### 1A. `zeststream-v2-fresh` (PUBLIC=no; private commercial monorepo)

| Surface | Path(s) | LOC class | Reusability class | Notes |
|---|---|---|---|---|
| Core TypeScript n8n SDK | `src/lib/n8n/{client,compiler,deployer,validator,types,index,execution-webhook-handler,webhook-signature}.ts` | ~1500 LOC | **GENERIC** | Clean module shape; auth via `N8N_API_URL`/`N8N_API_KEY` env; deployer + activator + lister + health-checker; deploy threshold MIN_DEPLOYMENT_SCORE=70 |
| V3 7-layer validation pipeline | `src/lib/workflow-factory/{workflow-validator,semantic-validator,connection-validator,configuration-validator,firewall-validator,orchestration-validator,pitfall-validator}.ts` + Zod schemas in `src/lib/validation/schemas.ts` | ~3000 LOC | **GENERIC** | Layered scoring (syntax 20% / semantic 20% / connection 20% / configuration 20% / firewall 10% / orchestration 5% / pitfall 5%); 85+ "excellent", 70+ "deployable" |
| Deploy script via API | `src/app/api/portal/workflows/deploy/route.ts` (SSE for progress) + `src/app/api/workflow-factory/upload-to-n8n/route.ts` | ~400 LOC | **GENERALIZABLE** | Tied to MSP-portal auth + Supabase lead-capture; the inner `uploadWorkflowToN8n()` helper is GENERIC (POST /api/v1/workflows + 401/403/404 error normalization) |
| `/deploy-n8n` Claude Code skill | `.claude/skills/deploy-n8n/SKILL.md` | ~200 LOC | **GENERIC** | Mandatory V3 validation gate before deploy; minimum score 85/100 (`--threshold`); auto-fix; audit trail `.agents/audit/n8n-deployments.jsonl`; `--dry-run` |
| Workflow-factory ecosystem | `src/lib/workflow-factory/{node-catalog-db,template-matcher,pattern-detection,complex-patterns,...}.ts` + `src/components/workflow-factory/*` | ~10K LOC | **GENERALIZABLE** | Substantial UI + AI-generation; depends on Supabase `workflow_templates` table (10,689 templates) and `node_catalog` table (~524 n8n nodes scraped) |
| 25+ workflow scripts | `scripts/{deploy-to-n8n,certify-templates-v2,curate-for-n8n,extract-patterns-from-templates,generate-workflow-patterns,test-single-workflow,test-schema-integration,intelligent-workflow-repair,repair-workflows,extract-via-n8n-mcp,extract-workflow-schemas,import-github-workflows,...}.ts` | ~5000 LOC | mix: **GENERIC** for `test-single-workflow`, `test-schema-integration`, `repair-workflows`; **GENERALIZABLE** for `curate-for-n8n`, `certify-templates-v2`; **INSTANCE-SPECIFIC** for `extract-via-n8n-mcp`, ZestStream Supabase-bound bits |
| `agno-service/tools/n8n_tools.py` + `n8n_workflow_agent.py` | `agno-service/tools/n8n_tools.py`, `agno-service/agents/n8n_workflow_agent.py`, `services/agno/app/tools/workflows.py` | ~1200 LOC Python | **GENERALIZABLE** | Agno-framework + RLS-aware Supabase coupling; deploy_workflow → validate → request approval → deploy via n8n API → register in `n8n_workflow_registry` |
| `zs-ops-mcp` Python MCP server | `zs-ops-mcp/{server,server_new_tools,validation_tools,workflow_intelligence_tools}.py` + COMMUNITY_NODES_GUIDE.md + TOOL_REFERENCE.md | ~3000 LOC Python | **GENERALIZABLE** | Substantial MCP toolset; Supabase-coupled credential registry queries (`zs_list_credentials`); valuable substrate but ZestStream-specific table names |
| Railway n8n-v2 deploy substrate | `infrastructure/{deploy,n8n-v2/{deploy,Dockerfile,railway.json,railway.toml,CHECKLIST.md,README.md,.env.example}}` | ~500 LOC | **GENERIC** (high value!) | Battle-tested Railway n8n v2 deployment pattern; PostgreSQL addon + N8N_ENCRYPTION_KEY + N8N_BASIC_AUTH + N8N_HOST=0.0.0.0 + Dockerfile pinned to `n8nio/n8n:2.0.0`; deploy.sh interactive; CHECKLIST.md is operator-grade |
| n8n integration standards doc | `docs/N8N_INTEGRATION_STANDARDS.md` | ~600 lines | **DANGER — INSTANCE-SPECIFIC** | Contains 8+ hardcoded credential UUIDs (Supabase API `DbLynjFNNUTUwdBx`, Cloudflare R2 `wgVyUNwGJ5abhBrx`, YouTube `D4gcIUxvhnsjDSt3`, Twitter `z9vrTD4Nu7wdhF4l`, Grok `jlmZqHxGiistGAVb`, OpenAI `mYTnqI4teJly6jkf`, Firecrawl `G8KYY82Gruf08nfe`, SendGrid `kY9Pb6QO6XQpdvrw`). These are INTERNAL ZestStream credential IDs — must NOT be published. Doc pattern is reusable; the table is not. |
| Supabase migration set | `supabase/migrations/{20260206030000_n8n_workflow_registry,20260207000100_org_n8n_workspaces,20260207000300_workflow_executions,20260207000600_workflow_templates,20260207000000_portal_workflows,20260119155304_baseline_workflow_factory,20260119250001_workflow_performance_daily,20260119310000_workflow_performance_tracking,20260211210000_add_n8n_workflows_user_rls,20260211121200_backfill_cfs_workflow_metadata,057_workflow_performance_tracking}.sql` | ~2000 LOC SQL | **GENERALIZABLE** | The schema design (registry table, instance disambiguator, RLS, credential mirror) is publishable as a reference SQL bundle. Org-scoping bits need renaming/abstraction. |

### 1B. `vrtx` (PUBLIC=no; client engagement repo with deep n8n process)

| Surface | Path(s) | LOC class | Reusability class | Notes |
|---|---|---|---|---|
| `scripts/deploy-to-n8n.sh` (THE canonical VRTX deploy script) | `scripts/deploy-to-n8n.sh` | 57 lines | **GENERIC** (high value!) | One-shot deploy of single workflow JSON to n8n.zeststream.ai via REST API; `--activate` flag; loads from `.env` + Infisical via `infisical-load --export zeststream`; clean error handling; the ZestStream-specific URL is the only INSTANCE-SPECIFIC bit (trivially parameterizable to `N8N_URL` env var) |
| `scripts/joshua-live-deploy.sh` | `scripts/joshua-live-deploy.sh` | unknown LOC | **INSTANCE-SPECIFIC** | Operator-grade live deploy ceremony; almost certainly wraps the above with VRTX-specific safety gates |
| `scripts/n8n-phase1-scaffold-workflows.py` | `scripts/n8n-phase1-scaffold-workflows.py` | 744 lines (truncated view; estimated ~750 LOC) | **GENERIC** (very high value!) | Build-and-import-inactive-Phase-1-workflow-scaffolds into n8n v2; argparse CLI with `--audit` + `--out` + `--summary`; verdict-emitting; designed for inactive-import-first safety model. **This is the "high quality" deploy process Joshua referenced.** |
| `scripts/n8n-vrtx-parity-packet.py` | `scripts/n8n-vrtx-parity-packet.py` | unknown LOC | **GENERALIZABLE** | Deterministic checker comparing local JSON to live v1 metadata; catches drift between repo artifacts and live n8n state |
| `scripts/n8n-vrtx-inactive-import-validator.py` | `scripts/n8n-vrtx-inactive-import-validator.py` | unknown LOC | **GENERIC** | Inactive-import validator pattern — publishable |
| `scripts/n8n-registry-{sync-execute,sync-dry-run,preview,sql-review,execute-readiness}.py` | (5 scripts) | unknown LOC, ~1500 LOC est | **GENERALIZABLE** | Supabase registry sync ceremony (dry-run + execute + readiness gates); the algorithm is portable, the Supabase tables are not |
| `scripts/n8n-vrtx05-*.py` (10+ scripts) | `scripts/n8n-vrtx05-{smoke-v2,build-inactive-candidate,create-real-handles,cutover-readiness,rebind-postgres-pooler,handle-name-collision-probe,handle-shaped-dummy-probe,simulate-v2-handle-rewrite,secret-input-preflight,import-inactive}.py` | unknown LOC, ~2000 LOC est | **INSTANCE-SPECIFIC** (VRTX 05 specifically) | Excellent operator-grade workflow-bringup ceremony for a single workflow; the **patterns** (rebind-postgres-pooler, handle-rewrite, secret-input-preflight) are GENERALIZABLE; the per-workflow specifics are not |
| `scripts/extract-phase1-marketplace-templates.py` | `scripts/extract-phase1-marketplace-templates.py` | unknown LOC | **GENERIC** | n8n marketplace template extraction |
| `scripts/n8n-migration-wave-classifier.py` | `scripts/n8n-migration-wave-classifier.py` | unknown LOC | **GENERIC** | v1→v2 migration wave classifier (which workflows safe to migrate first) |
| `scripts/n8n-local-credential-map.py` + `scripts/n8n-local-artifact-sweep.py` | (2 scripts) | unknown LOC | **GENERIC** | Local credential mapping + local artifact sweeper |
| `scripts/n8n-org-slice-preview.py` | `scripts/n8n-org-slice-preview.py` | unknown LOC | **GENERIC** | Per-org workflow slice preview (multi-tenant aware) |
| `scripts/search-templates.sh` + `scripts/fetch-template.sh` | (2 shell scripts) | ~50 LOC | **GENERIC** | Search the 10,689-template Supabase library for n8n workflow patterns; fetch one |
| `n8n-workflows/01..08.json` | 8 real production VRTX workflow exports | ~8 files, ~3500 LOC JSON est | **INSTANCE-SPECIFIC** (cannot publish verbatim; contain VRTX brand+credentials+webhook paths) | But the **shapes** (webhook-echo-test, gf-lead-pipeline, mailchimp-audit, etc.) are publishable as TEMPLATES once credentials and brand are scrubbed |
| `audits/2026-04-29-*` (~15 docs) | 14 audit docs from the Codex n8n deployment archaeology run | ~30K LOC markdown | **GENERALIZABLE** | The methodology (deployment-estate-registry, credential-blind-policy, parity-hardening-matrix, n8n-workflow-factory-evolution, etc.) is publishable as architecture/process docs |
| `.claude/skills/zeststream-n8n-railway-ops/` + `.claude/skills/zeststream-n8n-workflow-factory/` | 2 Claude Code skills | ~1500 LOC each | **GENERALIZABLE** | Highly polished operator skills; the contents are publishable but reference ZestStream naming + Supabase tables |
| `data/refresh-2026-04-28/{workflows-raw,workflows-p2,workflows-p3,vrtx-workflows}.json` | live n8n API exports | ~4 large JSON files | **DANGER — INSTANCE-SPECIFIC** | Full workflow exports with potentially-embedded credential references; do not publish without scrub |

### 1C. Cross-repo unifying themes

- **Two-instance pattern (v1 + v2):** Both repos understand a v1/v2 split. Code is generally instance-id-aware via `n8n_instance_id ∈ {v1, v2}`.
- **Validation-before-deploy:** Both repos enforce a minimum validation score before deploy (zss-v2-fresh: 70, deploy-n8n skill: 85). The 7-layer V3 pipeline is the canonical scoring.
- **Inactive-import-first safety model:** vrtx's `n8n-phase1-scaffold-workflows.py` builds-and-imports-inactive, then activates after smoke-test passes. This is the "high quality" deploy process Joshua referenced.
- **Supabase as registry:** Both repos mirror n8n state into Supabase tables (`n8n_workflow_registry`, `n8n_credentials`, `n8n_webhook_registry`).
- **Infisical for secrets:** Both repos use Infisical (`infisical run --` or `infisical-load --export`) instead of inline env vars.
- **Railway for hosting:** Both v1 and v2 instances live on Railway with documented Dockerfile pinning patterns.

---

## 2. Repo-shape options for the unified public repo

### Option A — Single `n8n-deploy-kit` repo (deploy + templates + monitoring + helpers)

**Shape:** one repo with `bin/n8n-deploy`, `templates/*`, `validate/*`, `monitor/*`, `examples/*`.

**Pros:**
- Simplest install path: one `npm i n8n-deploy-kit` (or `cargo install`, `pip install`) and you have everything.
- Single README + ARCHITECTURE + CHANGELOG to maintain.
- Easiest first-issue triage (one repo, one queue).
- Lowest cognitive overhead for first-time public users.

**Cons:**
- 5-10K LOC mixed concerns inflates the install footprint.
- Hard to evolve the deploy CLI separately from the template library.
- One bad version pin in any sub-area cascades to all users.
- "Kitchen sink" vibes can lower per-feature trust.

**Recommended name:** `n8n-deploy-kit` (or `zeststream-n8n-toolkit`).
**Estimated extraction effort:** **6-8 worker-days** (heavy refactor to flatten module hierarchy; lots of cross-import surgery from the zss-v2-fresh src/lib tree).

### Option B — Split into focused repos

**Shape:** 4-5 separate small repos:
- `n8n-deploy` — the CLI (`bin/n8n-deploy <workflow.json> --activate`)
- `n8n-validator` — the 7-layer V3 validation pipeline as a library
- `n8n-templates` — curated, scrubbed, public-safe template gallery
- `n8n-railway-template` — Railway+Dockerfile+CHECKLIST+deploy.sh recipe
- `n8n-monitoring` (optional) — health-check + status probes

**Pros:**
- Each repo can evolve at its own cadence.
- Users install only what they need (small footprints).
- Clean ownership: one repo = one concern.
- Better SEO (each repo ranks for its specific term).

**Cons:**
- 5× the maintenance overhead (5 READMEs, 5 ARCHITECTUREs, 5 CHANGELOGs, 5 issue queues).
- Cross-repo coordination for breaking changes.
- Higher install friction (`npm i n8n-deploy n8n-validator n8n-templates` vs one package).
- Splits the "social proof" (5 repos at 0 stars each looks worse than 1 repo at 0).

**Recommended names:** `n8n-deploy` / `n8n-validator` / `n8n-templates` / `n8n-railway-template` / `n8n-monitor`.
**Estimated extraction effort:** **8-12 worker-days** (each repo needs its own README, install path, examples; more boilerplate).

### Option C — Monorepo with multiple packages under one umbrella ★ RECOMMENDED ★

**Shape:** one GitHub repo `n8n-deploy-kit` (or `zeststream-n8n-toolkit`) with multiple npm packages OR a Cargo workspace OR a uv-managed Python monorepo:

```
n8n-deploy-kit/
├── README.md                          # one front door
├── ARCHITECTURE.md
├── ROADMAP.md
├── CHANGELOG.md
├── LICENSE                            # MIT
├── SECURITY.md
├── CONTRIBUTING.md
├── .gitignore
├── .flywheel/                         # canonical-stamp substrate
├── packages/
│   ├── deploy/                        # the CLI + its tests
│   │   ├── package.json (or pyproject.toml)
│   │   ├── README.md (package-specific)
│   │   └── src/
│   ├── validate/                      # the 7-layer V3 pipeline
│   ├── templates/                     # scrubbed public-safe templates
│   └── railway/                       # Railway+Dockerfile recipe
├── examples/                          # end-to-end usage examples
└── docs/                              # architecture, runbooks, patterns
```

**Pros:**
- One README + one CHANGELOG: same maintenance burden as Option A.
- BUT users can install individual packages: `npm i @zeststream/n8n-deploy` without pulling validator/templates.
- Easier to evolve sub-packages independently while sharing tests + CI + LICENSE + SECURITY.
- Social proof concentrates on one repo (stars + forks on one URL).
- The umbrella `n8n-deploy-kit` can ship as a meta-package that pulls in all 4 sub-packages for users who want the full kit.
- Clean composition story: "here's the deploy tool, here's the validator it uses, here's the template library it draws from."

**Cons:**
- Slightly higher initial setup (workspace tooling: `pnpm workspaces`, `npm workspaces`, or `cargo workspace`, or `uv workspace`).
- Has to commit to one language for the meta (recommend **TypeScript** — most of the zss-v2-fresh SDK is already TS; vrtx Python scripts can ship as a separate `packages/cli-py/` or be ported).

**Recommended name:** `n8n-deploy-kit` (under github.com/jyeswak/n8n-deploy-kit).
**Estimated extraction effort:** **4-6 worker-days** for the umbrella + deploy + validate packages (Phase 1); +2-3 worker-days for templates + railway (Phase 2).

### Option D — Hybrid (curated essentials public + advanced bits internal)

**Shape:** Option C structure for the public repo, but a deliberate carve-out:
- **Public:** `deploy/`, `validate/`, `railway/`, ~5 curated templates, the documented patterns.
- **Internal:** `templates-full/` (the 10,689-template Supabase library — too instance-specific to publish), `agno/` (the Python agent tooling — too coupled to Supabase RLS), `zs-ops-mcp/` (the MCP server — too coupled to ZestStream tables), the workflow-factory UI (too coupled to MSP-portal auth).

**Pros:**
- Honest separation of "ready to share" vs "internal complexity."
- Protects competitive moat (the full template library + agent tooling stays private).
- Smaller public surface = easier to maintain.
- Aligns with `project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11`: prove internally first, publish only the curated essentials.

**Cons:**
- Two-codebase divergence risk (public packages drift from internal usage).
- Need a sync ceremony to back-port internal improvements.
- Users may ask for the internal bits and we'll have to say "not yet."

**Recommended name:** Same as Option C — `n8n-deploy-kit`. Just narrower scope.
**Estimated extraction effort:** **3-4 worker-days** for Phase 1 (deploy + validate + railway + 5 templates). Lowest cost. Highest discipline.

### Side-by-side comparison

| Dimension | A: single | B: split | C: monorepo ★ | D: hybrid (subset of C) ★★ |
|---|---|---|---|---|
| Maintenance burden | medium | high (5×) | medium | low |
| Install ergonomics | best | worst | good | good |
| Per-package evolution | bad | best | good | good |
| Social proof concentration | good | bad | best | best |
| Effort to ship Phase 1 | 6-8d | 8-12d | 4-6d | **3-4d** |
| Risk of mid-build pivot | medium | high | medium | low |
| Audience-class fit | OK | OK | best | best |
| ROI for first 30 days | medium | low | good | **best** |

**Recommendation:** **Option D** is the cleanest first move. **Option C is the natural growth path** once the curated essentials prove out. Avoid A (kitchen sink anti-pattern) and B (premature splitting).

---

## 3. Secret-protection strategy

### 3A. Inventory of secrets observed (read-only grep)

**`vrtx` repo (live `.env` + `.env.infisical` exist):**
- `.env` — 2.3KB present at root; gitignored per project's `.gitignore` (36 lines)
- `.env.infisical` — 155B present; gitignored
- Hardcoded Supabase URL `hsmyagcerajgjmlljtmx.supabase.co` appears in:
  - `scripts/search-templates.sh` (in the URL string)
  - `supabase/.temp/linked-project.json` (Supabase CLI artifact)
  - 7 audit docs (`audits/2026-04-28..2026-04-29-*`)
  - 2 architecture docs (`docs/supabase-learning-substrate-architecture.md`, `docs/operations-brain-architecture.md`)
- 8 workflow JSON files at `n8n-workflows/01..08.json` — likely contain credential references (UUIDs) per the `audits/2026-04-29-codex-credential-blind-policy.md` audit
- `data/refresh-2026-04-28/*.json` — live n8n API exports; almost certainly contain credential metadata

**`zeststream-v2-fresh` repo:**
- `docs/N8N_INTEGRATION_STANDARDS.md` — **8 hardcoded n8n credential UUIDs** (Supabase API, Cloudflare R2, YouTube, Twitter, Grok, OpenAI, Firecrawl, SendGrid)
- `infrastructure/n8n-v2/.env.example` — clean template (per CHECKLIST.md)
- Multiple references to `NEXT_PUBLIC_SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` env-var patterns (proper env-var usage)
- Historical exposure: `PHASE_1_SECURITY_FIXES_COMPLETE.md` documents a prior breach where service_role JWT was exposed in `NEXT_PUBLIC_SUPABASE_ANON_KEY` — fixed but indicates prior secret-hygiene gaps

### 3B. Recommended `.env.example` shape (for the public repo)

```ini
# ─── n8n connection ────────────────────────────────────────────
N8N_URL=https://your-n8n-instance.example.com
N8N_API_KEY=                # generate via Settings → API → Create

# ─── (optional) Supabase registry mirror ───────────────────────
# Leave empty if you don't want to mirror n8n state to Postgres.
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=  # server-side only; never NEXT_PUBLIC_*

# ─── (optional) Railway deployment ─────────────────────────────
RAILWAY_TOKEN=              # only needed if you use the railway/ recipe

# ─── (optional) Infisical for secret management ───────────────
INFISICAL_PROJECT_ID=
INFISICAL_CLIENT_ID=
INFISICAL_CLIENT_SECRET=    # used by `infisical run --` wrapper

# ─── (optional) Deploy validation gates ────────────────────────
N8N_DEPLOY_MIN_SCORE=70     # 70=permissive, 85=strict (recommended)
N8N_DEPLOY_AUDIT_LOG=./n8n-deployments.jsonl
```

### 3C. Recommended `.gitignore` entries (additions to a stock Node+Python `.gitignore`)

```gitignore
# Secrets
.env
.env.local
.env.production
.env.infisical
.env.*.local
*.secret
*.pem

# n8n credential dumps
**/*-credentials.json
**/n8n-export.json
data/refresh-*/
audits/*-credential-*.md
audits/*-secret-*.md

# Supabase local
supabase/.temp/
supabase/.branches/

# Local n8n workflow exports (operator-only; never publish raw)
**/local-workflows/
**/private-workflows/

# Audit logs that may contain workflow IDs / credential IDs
*.audit.jsonl
.agents/audit/
```

### 3D. Recommended pre-commit hook (defense in depth)

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks

  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.82.13
    hooks:
      - id: trufflehog
        entry: trufflehog filesystem --no-update --fail --no-verification
        language: system
        pass_filenames: false
        stages: ["pre-commit", "pre-push"]

  - repo: local
    hooks:
      - id: scrub-credential-uuids
        name: Scrub n8n credential UUIDs from staged files
        entry: scripts/scrub-credential-uuids.sh
        language: script
        types: [json, markdown]
```

The `scrub-credential-uuids.sh` is a custom check for **n8n-specific** credential UUID leakage (the `docs/N8N_INTEGRATION_STANDARDS.md` issue — 24-char alphanumeric UUIDs in JSON `"credentials": {...}` blocks).

### 3E. Is the existing code structured to use env vars or has secrets inline?

**Mostly env-var based (good):**
- `src/lib/n8n/deployer.ts` reads `process.env.N8N_API_URL` cleanly.
- `vrtx/scripts/deploy-to-n8n.sh` reads `N8N_API_KEY` from `.env` + Infisical.
- The 7-layer V3 validation is config-driven.

**Red flags (require scrubbing before publish):**
- `docs/N8N_INTEGRATION_STANDARDS.md` has 8 credential UUIDs inline (must strip or generalize).
- `vrtx/scripts/search-templates.sh` has hardcoded `https://hsmyagcerajgjmlljtmx.supabase.co` (must parameterize).
- `data/refresh-2026-04-28/*.json` are full workflow exports that may contain credential refs (must NOT publish; replace with synthetic example workflows).
- `audits/2026-04-29-*` cohort contains 7+ references to the Supabase project ID (audits are internal substrate — don't publish; references can be deleted or replaced with `<your-supabase-project>`).
- `n8n-workflows/01..08.json` likely contain credential UUIDs (per the credential-blind-policy audit) — scrub before publishing as templates.

---

## 4. Class-divergence audit (per `.flywheel/doctrine/public-repo-canonical-stamp-class-divergence.md`)

**Target audience-class:** **PUBLIC-OSS** (community-tool, MIT). This is **distinct from**:
- **PRIVATE-ALPHA** (skillos exemplar) — would be hostile-to-community
- **PUBLIC-MIT-COMMERCIAL** (zeststream-brand-voice) — would be premature commercial framing

PUBLIC-OSS framing for an n8n deploy kit:
- README should welcome contributors openly (PR-friendly; "good first issues" labels)
- LICENSE: MIT (canonical full text)
- CONTRIBUTING.md: open scope (anyone can PR), discuss-first for big changes
- SECURITY.md: 5-day-ack SLA, coordinated disclosure (per ain6c PUBLIC-OSS class)
- AGENTS.md: SPLIT pattern (top-level thin pointer + `.flywheel/AGENTS-CANONICAL.md` for fleet-internal contributors)
- No commercial-pull (no "$999 Assessment" CTAs); this is a free tool

### Named-client-consent audit (per `feedback_named_client_consent_per_surface_audit`)

**Client names observed in the n8n surface:**
- **VRTX** (VRTX Gym, Missoula MT) — appears in 30+ vrtx repo scripts/audits/README; multiple workflows are explicitly named `VRTX 01 — Webhook Echo Test`, `VRTX 05 — GF Contact -> Config-Driven Lead Pipeline`
- **ClutterFreeSpaces** — referenced in Vercel project list + Railway estate
- **Univision / Univision-Microsoft-Entra** — referenced in vrtx Microsoft credential audit
- **Mailchimp / Facebook / WordPress / ClubReady** — vendor/integration names, not clients (publishable)
- **Joshua** / **Derek** / **Penelope** / **Ronie** / **Kirstin** — internal/client team members

**Rule per `feedback_named_client_consent_per_surface_audit`:** any client names in published code/docs/templates require explicit per-client consent. Without consent, replace with **industry-only descriptions** (e.g., "gym CRM lead pipeline", "title-company workflow", "telecom provisioning"). Example replacements:
- "VRTX 05 — GF Contact -> Config-Driven Lead Pipeline" → "Gravity Forms Lead → CRM Lead Pipeline Template"
- "Univision-Microsoft-Entra" → "Microsoft Entra (Azure AD) Tenant Setup Recipe"
- Audit docs naming Derek/Penelope/Ronie/Kirstin → either delete the audit (audits are operator-internal) OR redact

**Recommendation:** publish **zero named-client material** in v0.1. All templates that derive from VRTX workflows must be **rewritten with synthetic gym/title-company data**, not anonymized client data.

---

## 5. VRTX deployment-process specifics

Joshua's quote: *"I have new processes in vrtx I've built to be able to quickly and easily deploy really high quality workflows."*

### 5A. What the "high quality deploy process" actually IS (probed via socraticode)

Three load-bearing scripts compose the VRTX deploy process:

#### `scripts/deploy-to-n8n.sh` (57 lines — the canonical one-shot deployer)
- Single positional arg: workflow JSON file
- Optional `--activate` flag
- Loads `.env` then layers Infisical secrets via `infisical-load --export zeststream`
- Validates `N8N_API_KEY` presence (clean error if missing)
- POSTs to `https://n8n.zeststream.ai/api/v1/workflows`
- Extracts workflow ID from response (Python json parser inline)
- Optional second PATCH to activate
- Final URL for human verification

**Quality features:** clean error path; idempotent-safe (won't activate without --activate); easy to read.

#### `scripts/n8n-phase1-scaffold-workflows.py` (~744 lines — THE high-quality deploy gate)
- `argparse` CLI: `--audit <path>` + `--out <path>` + `--summary`
- Reads an audit file (a manifest of workflows to scaffold)
- For each workflow:
  - Builds inactive scaffold (workflow created in n8n with `active=false`)
  - Verifies node count + credential ref count
  - Emits per-workflow verdict
- Final verdict: `PHASE1_SCAFFOLDS_IMPORTED_INACTIVE` or failure-class verdict
- **Inactive-import-first model:** workflows land disabled; activation is a separate, intentional second step

This is the **"really high quality" pattern Joshua referred to** — it's not about deploy speed; it's about **safety + reversibility**: every workflow lands inactive, gets validated, and ONLY activates after a human-in-the-loop smoke test.

#### `scripts/n8n-vrtx-parity-packet.py` (drift-detection)
- Compares local JSON artifacts to live n8n state
- Catches drift between repo and runtime (e.g., webhook path renamed)
- Patches local on drift (per the 2026-04-29 audit it caught `vrtx-test` vs `test` path drift)

### 5B. What makes the VRTX process "high quality"

Five concrete properties:

1. **Inactive-import-first.** Workflows land disabled. Activation is intentional + auditable.
2. **Parity-checking against live state.** Repo artifacts are kept in sync with the running n8n (catches drift).
3. **Credential-blind detection** (per `audits/2026-04-29-codex-credential-blind-policy.md`). The scaffold script refuses to import workflows referencing credentials without IDs (those that need manual binding).
4. **Migration-wave classification** (`scripts/n8n-migration-wave-classifier.py`). Workflows are sorted by risk class (webhook-only, schedule-only, code-node-using, file/command-using) so easy ones go first.
5. **Per-workflow smoke ceremony** (`scripts/n8n-vrtx05-{smoke-v2,cutover-readiness,secret-input-preflight}.py`). Before activating any workflow, a structured smoke runs in v2 sidecar mode.

### 5C. Portability to the public repo

| VRTX process element | Portable to public? | Why |
|---|---|---|
| Inactive-import-first model | **YES** — load-bearing | Universal safety pattern |
| Parity-checking against live state | **YES** — universal | Any n8n user benefits |
| Credential-blind detection | **YES** — universal | Any multi-credential workflow benefits |
| Migration-wave classifier | **YES** — universal | v1→v2 migration is a community-wide need |
| Per-workflow smoke ceremony | **GENERALIZABLE** — needs abstraction | VRTX-05-specific currently; generalize to "smoke-any-workflow" |
| The Supabase registry sync | **GENERALIZABLE** — optional component | Public users may not have Supabase; make the registry mirror opt-in |
| The Infisical secret bridge | **GENERALIZABLE** — optional component | Public users may use Vault/AWS-SM/Doppler instead; make the secret-source pluggable |

**Estimated work to port the VRTX deploy process to public:** **~2 worker-days** (the 5 portable patterns above are small clean scripts; main work is renaming + abstracting Supabase/Infisical assumptions).

---

## 6. v1 vs v2 instance differences

### 6A. The split (per `audits/2026-04-29-codex-n8n-deployment-archaeology.md` + `audits/2026-04-29-codex-n8n-live-upgrade.md`)

| Dimension | v1 (`n8nio/n8n:1.x`) | v2 (`n8nio/n8n:2.x`) |
|---|---|---|
| Production status (VRTX) | LIVE — pinned `1.123.37` (latest patch line) | SIDECAR — pinned `2.0.0`; currently healthy, empty |
| Railway source | `JYeswak/ZestStream` branch `n8n-instance-service` | `JYeswak/ZestStream-v2` root `/infrastructure/n8n-v2` |
| Dockerfile | `.agents/railway/n8n-instance/Dockerfile` | `infrastructure/n8n-v2/Dockerfile` |
| Healthcheck | `/healthz` ✓ | DISABLED (migrations exceed Railway healthcheck window) |
| Database | Postgres (`Postgres`) | Postgres (`Postgres-oGcI` separate) |
| `--tunnel` option | available | **REMOVED** |
| `N8N_CONFIG_FILES` | works | **REMOVED** |
| In-memory binary data mode | works | **REMOVED** (forces R2/S3 for binary) |
| SQLite legacy driver | works | **REMOVED** (Postgres-only) |
| `ExecuteCommand` node | enabled by default | **DISABLED by default** (security tightening) |
| `LocalFileTrigger` node | enabled by default | **DISABLED by default** |
| OAuth callback auth | unauthenticated | **AUTH REQUIRED by default** |
| Code-node env access | full | **RESTRICTED** (task runners required for full env) |
| Credential `PATCH` endpoint | absent | absent (both versions; affects all credential bridge plans) |
| Credential `POST` + `DELETE` | works | works |
| Credential overwrite endpoint | with `CREDENTIALS_OVERWRITE_PERSISTENCE=true` | with `CREDENTIALS_OVERWRITE_PERSISTENCE=true` |

### 6B. Should the public repo cover both v1 and v2?

**Recommendation:** **v2-canonical with v1-compatibility-notes**.

Reasoning:
- v2 is npm `latest` and `stable` as of 2026-04-27 (`n8n@2.18.4`). New external users will land on v2.
- v1 is NOT EOL'd (`n8n@1.123.37` released 2026-04-24) and still gets patches; some existing operators are on v1.
- The Railway template + Dockerfile should ship **v2 as default** with a `Dockerfile.v1` alternative.
- Migration-wave classifier is v1→v2 ONLY (no need for v2→v1 reverse).
- The credential bridge plan (post-PATCH-absent reality) applies to both; one set of docs covers both.

**Risk:** if a v1-only user follows v2 instructions, the breaking-change deltas (REMOVED tunnel, REMOVED config-files, REMOVED binary mode, etc.) will bite them. Solution: a **v1 vs v2 compatibility matrix** in ARCHITECTURE.md (the table in §6A above is the seed).

---

## 7. Recommended extraction plan (if Joshua approves Option D)

### 7A. Step-by-step extraction sequence (Phase 1 — ~3-4 worker-days)

| Step | Action | Source | Target | Effort | Risk |
|---|---|---|---|---|---|
| 1 | Create empty private GitHub repo `jyeswak/n8n-deploy-kit` (PRIVATE first) | n/a | github | 5 min | none |
| 2 | Apply canonical-stamp PUBLIC-OSS class (README + ARCHITECTURE + ROADMAP + LICENSE + SECURITY + CONTRIBUTING + .gitignore + .flywheel/{MISSION,GOAL,AGENTS-CANONICAL}) | flywheel-stamp v0.1 spec (mmjvg) | new repo | 4h | low |
| 3 | Extract `src/lib/n8n/{client,compiler,deployer,validator,types,index,webhook-signature}.ts` into `packages/deploy/src/` | zss-v2-fresh | new repo | 3h | low (clean module shape) |
| 4 | Extract 7-layer V3 validator into `packages/validate/src/` | zss-v2-fresh `src/lib/workflow-factory/{workflow,semantic,connection,configuration,firewall,orchestration,pitfall}-validator.ts` + `src/lib/validation/schemas.ts` | new repo | 4h | medium (cross-file deps to flatten) |
| 5 | Port `vrtx/scripts/deploy-to-n8n.sh` + `n8n-phase1-scaffold-workflows.py` → `packages/deploy/bin/n8n-deploy` (TypeScript port) | vrtx | new repo | 3h | low |
| 6 | Extract `infrastructure/n8n-v2/{Dockerfile,railway.json,deploy.sh,CHECKLIST.md,README.md,.env.example}` → `packages/railway/` | zss-v2-fresh | new repo | 1h | none |
| 7 | Author 5 curated synthetic-data templates → `packages/templates/` | new (write from scratch — DO NOT copy VRTX workflows) | new repo | 4h | medium (require synthetic gym/title/telecom data) |
| 8 | Run `gitleaks --no-git --piped` + `trufflehog filesystem` over the entire repo | new repo | own audit | 30min | high (must pass clean) |
| 9 | Author `examples/` (3 end-to-end): "deploy your first workflow", "validate before deploy", "migrate v1 → v2" | new (write fresh) | new repo | 4h | low |
| 10 | Pre-commit hook setup (gitleaks + trufflehog + scrub-credential-uuids.sh) | new (write fresh) | new repo | 1h | none |
| 11 | First internal use: deploy a real VRTX workflow VIA the new CLI (dogfood test) | new repo | proves itself | 2h | medium (catches bugs) |
| 12 | (gated on Joshua approval) Flip repo PRIVATE → PUBLIC | new repo | github | 5 min | low (reversible) |

**Total: ~26 hours = ~3-4 worker-days**

### 7B. Files to copy (verbatim or near-verbatim)

| Source file | Target file | Modifications needed |
|---|---|---|
| `src/lib/n8n/client.ts` | `packages/deploy/src/client.ts` | strip ZestStream-specific URL constants; parameterize via env |
| `src/lib/n8n/deployer.ts` | `packages/deploy/src/deployer.ts` | none material; uses env vars properly |
| `src/lib/n8n/validator.ts` | `packages/validate/src/index.ts` | none |
| `src/lib/n8n/types.ts` | `packages/deploy/src/types.ts` | none |
| `src/lib/n8n/index.ts` | `packages/deploy/src/index.ts` | none |
| `src/lib/n8n/webhook-signature.ts` | `packages/deploy/src/webhook-signature.ts` | none |
| `src/lib/n8n/compiler.ts` | `packages/deploy/src/compiler.ts` | none |
| `src/lib/workflow-factory/workflow-validator.ts` | `packages/validate/src/syntax.ts` | none |
| `src/lib/workflow-factory/semantic-validator.ts` | `packages/validate/src/semantic.ts` | none |
| `src/lib/workflow-factory/connection-validator.ts` | `packages/validate/src/connection.ts` | none |
| `src/lib/workflow-factory/configuration-validator.ts` | `packages/validate/src/configuration.ts` | none |
| `src/lib/validation/schemas.ts` | `packages/validate/src/schemas.ts` | none |
| `infrastructure/n8n-v2/Dockerfile` | `packages/railway/Dockerfile` | none |
| `infrastructure/n8n-v2/railway.json` | `packages/railway/railway.json` | none |
| `infrastructure/n8n-v2/deploy.sh` | `packages/railway/deploy.sh` | none material (interactive prompts are fine) |
| `infrastructure/n8n-v2/CHECKLIST.md` | `packages/railway/CHECKLIST.md` | scrub any ZestStream-internal references |
| `vrtx/scripts/deploy-to-n8n.sh` | (becomes the basis for) `packages/deploy/bin/n8n-deploy` (TS port) | strip Infisical hardcoded `--export zeststream`; make secret-source pluggable |

### 7C. Files to REWRITE (cannot copy verbatim)

| Source file | Why not copyable | Rewrite strategy |
|---|---|---|
| `docs/N8N_INTEGRATION_STANDARDS.md` | 8 hardcoded credential UUIDs | Rewrite as generic "credential ID convention guide"; no live UUIDs |
| `n8n-workflows/01..08.json` (VRTX workflows) | VRTX-specific brand + credentials + webhook paths | Rewrite 5 synthetic templates from scratch with industry-only language |
| `audits/2026-04-29-*` audit cohort | Internal substrate; references named clients | Either delete (not publish) OR distill into a single ARCHITECTURE.md decision-history section |
| `vrtx/scripts/joshua-live-deploy.sh` | Operator-grade live deploy ceremony with VRTX-specific gates | Distill into a documented "production deploy ceremony" section in ARCHITECTURE.md; don't ship the literal script |

### 7D. Files to SKIP (do NOT publish)

| Surface | Why skip |
|---|---|
| `services/agno/app/tools/workflows.py` + `agno-service/tools/n8n_tools.py` + `agno-service/agents/n8n_workflow_agent.py` | Coupled to agno-framework + RLS-aware Supabase; too instance-specific |
| `zs-ops-mcp/*` | Coupled to ZestStream-specific Supabase table names (`n8n_credentials`, `n8n_workflow_registry`); valuable internal tooling, not portable yet |
| `src/lib/workflow-factory/{node-catalog-db,template-matcher,pattern-detection,complex-patterns}.ts` | Depends on Supabase `node_catalog` + `workflow_templates` tables (10,689 templates) — too coupled |
| `src/components/workflow-factory/*` | UI components; depend on Supabase + MSP-portal auth |
| `vrtx/scripts/n8n-vrtx05-*.py` (10 scripts) | VRTX-05-specific operator ceremony |
| `vrtx/scripts/n8n-registry-*.py` (5 scripts) | Tied to ZestStream Supabase schema |
| `vrtx/data/refresh-2026-04-28/*.json` | Live n8n exports with credential references |
| `supabase/migrations/2026020700060*_workflow_templates.sql` (and 11 others) | Org-scoped schema; abstract into a reference SQL bundle later |

### 7E. Risk surface

| Risk | Mitigation |
|---|---|
| Secret leakage in committed history | Squash-commit on private→public flip; pre-commit gitleaks + trufflehog gates; manual review of every `*.json` before staging |
| Named-client leakage | Per-surface client-consent audit BEFORE staging; replace VRTX→synthetic-gym; replace Univision→synthetic; scrub all Joshua/Derek/Penelope/Ronie/Kirstin references |
| Credential UUID leakage (`docs/N8N_INTEGRATION_STANDARDS.md` pattern) | Custom pre-commit `scrub-credential-uuids.sh` matching 16+ char alphanumeric UUIDs in `"credentials": {...}` blocks; ALL workflow JSON templates use synthetic UUIDs |
| Cross-file deps in `src/lib/n8n/*` to `@/lib/supabase` | Refactor: remove Supabase coupling from the SDK; let users plug in their own persistence layer via interface |
| `MIN_DEPLOYMENT_SCORE=70` threshold drift across packages | Single canonical export from `packages/deploy/src/types.ts`; all consumers import from there |
| v1/v2 confusion for new users | ARCHITECTURE.md has v1 vs v2 compatibility matrix (§6A above); Dockerfile defaults to v2; CHECKLIST.md notes both lines are supported |
| Breaking changes between published versions | Semver discipline; CHANGELOG.md required for any user-visible change; v0.x is alpha and explicitly documented |

---

## 8. Maintenance-burden estimate

### 8A. Likely issue volume

Calibrating against:
- `zeststream-brand-voice` (zss-bv): public-MIT-commercial, ~6 months in repo, currently 0 external stars / 1 view in 14 days (per flywheel-2hiee precedent for low-pull projects)
- n8n community on github (`n8n-io/n8n`): 87K+ stars, ~30 issues opened per day
- Comparable public n8n tools: `n8n-mcp-server` (~5K stars), `n8n-nodes-base` extensions (varies)

**For `n8n-deploy-kit` at v0.1 with no marketing push:**
- **First 30 days:** 0-2 external issues (matches zss-bv baseline; n8n community is large but discovery takes time)
- **First 90 days:** 2-10 external issues (if posted to `r/n8n` subreddit, n8n Discord, or HN)
- **First 12 months:** 20-100 external issues (linear-to-quadratic growth if pattern resonates)

**Issue mix prediction (informed by n8n community character):**
- ~40% will be "feature requests" (add support for X; integrate with Y)
- ~30% will be "bug reports" (validation X fails on n8n version Y)
- ~20% will be "questions" (how do I do X)
- ~10% will be "drive-by complaints" (close politely)

### 8B. Triage time budget recommendation

| Phase | Triage budget | Cadence |
|---|---|---|
| Months 0-3 (alpha; <10 issues) | 30 min/week | Friday afternoon |
| Months 3-9 (~20 issues outstanding) | 1h/week | Friday afternoon |
| Months 9-12 (>50 issues) | 2h/week or assign to a sub-agent | Friday morning + ad-hoc |
| Year 2+ (sustained external users) | 4h/week minimum | Daily review + Friday triage |

### 8C. When NOT to publish (red lines)

Per `project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11`, internal-proof is the gate. Specific go/no-go criteria:

**DO NOT publish if:**
- Pre-publish secret scan finds ANY hits (zero tolerance)
- Pre-publish named-client audit finds unconsented references
- The triage budget (30 min/week) cannot be sustained for the first 90 days
- No internal user (Joshua, Codex, fleet workers) is dogfooding the CLI on a real workflow
- The README cannot honestly fill in: "I've used this to deploy X workflows in production for myself" (without that, the social proof is fake)

**DO publish if:**
- Above red lines all pass
- The CLI has been used to deploy at least 3 real workflows by Joshua personally
- The validator has caught at least 1 real bug pre-deploy
- The Railway template has been used to spin up at least 1 fresh n8n instance
- The README + ARCHITECTURE + LICENSE + SECURITY + CONTRIBUTING are all PUBLIC-OSS-class (per class-divergence doctrine)

### 8D. Maintenance-burden mitigation strategy

- **Set explicit limits in CONTRIBUTING.md:** "Best-effort review; no SLA on community PRs."
- **Use issue templates:** force reporters to provide reproducer + n8n version + expected vs actual behavior.
- **Auto-close stale issues:** github action that closes issues with no activity for 90 days.
- **Pin the "scope" doc:** what we accept + what we don't (per tvvu8 CONTRIBUTING.md pattern).
- **No commercial-support promise:** explicit in README that this is community-tier; commercial support pathway is hello@zeststream.ai.

---

## 9. Class-divergence checklist for the public repo (per doctrine)

Applying the class-divergence doctrine auditor checklist for PUBLIC-OSS:

- [ ] Target audience-class confirmed: PUBLIC-OSS (community-tool, MIT)
- [ ] README.md: scannable, copy-pasteable Quick Start ≤5 commands, no commercial framing
- [ ] ARCHITECTURE.md: includes v1 vs v2 compatibility matrix, no internal-Joshua-fleet jargon
- [ ] ROADMAP.md: phased buildout with status legend; honest about alpha state
- [ ] AGENTS.md: SPLIT pattern — thin pointer at top-level + full canonical in `.flywheel/AGENTS-CANONICAL.md`
- [ ] CONTRIBUTING.md: open scope (per tvvu8 PUBLIC-OSS pattern); 5-day-ack review SLA best-effort
- [ ] SECURITY.md: 5-day-ack SLA + 30-day-Critical-patch SLA + coordinated disclosure (per ain6c PUBLIC-OSS pattern)
- [ ] LICENSE: full MIT text + Copyright 2026 Joshua Nowak / ZestStream
- [ ] .gitignore: includes the entries from §3C above
- [ ] No fleet-orch jargon (L-rules, trauma-class, fuckup-log, dispatch-log, jsm, br, dcg, etc.) in public files
- [ ] No "private alpha" framing
- [ ] No fabricated stats (star count, user count) — leave as `[FILL]` until real
- [ ] Pre-commit hooks (gitleaks + trufflehog + custom credential-UUID scrub) in `.pre-commit-config.yaml`
- [ ] CI workflow (`.github/workflows/ci.yml`) runs validator on every PR + secret scan + tests
- [ ] Issue + PR templates in `.github/ISSUE_TEMPLATE/` + `PULL_REQUEST_TEMPLATE.md`

---

## 10. Joshua-decision surface

This audit is read-only. The decisions below are Joshua's:

| Decision | Options |
|---|---|
| **Repo shape** | A (single) / B (split 5) / **C (monorepo)** / **D (hybrid)** [recommended: D for Phase 1, C as growth path] |
| **Repo name** | `n8n-deploy-kit` / `zeststream-n8n-toolkit` / [your call] |
| **Account** | `jyeswak/` (personal) / `zeststream/` (org-future) / [your call] |
| **License** | MIT (recommended; matches PUBLIC-OSS class) / Apache-2.0 (CLA-friendlier for commercial integrators) |
| **Initial visibility** | PRIVATE first (extract + dogfood) → PUBLIC after pre-publish red-line audit passes |
| **v1 vs v2 coverage** | v2-canonical + v1-compatibility-notes (recommended) / v2-only / both-equal |
| **Template scope (Phase 1)** | 5 synthetic-data templates (recommended) / port existing VRTX workflows (NOT recommended — named-client risk) / 0 templates (defer to v0.2) |
| **Maintenance budget** | 30 min/week (alpha) / 1h/week / 2h/week / decline-to-publish if no budget |
| **Pre-publish red-line gates** | secret scan clean + named-client scrub + Joshua-dogfood ≥3 workflows + canonical-stamp PUBLIC-OSS pass [recommended] / lower bar |
| **Approve next dispatch** | YES — file 4-7 sub-beads per the §7A extraction plan / NO — defer / NEEDS MORE — request specific deeper probes |

---

## 11. Sources (Axiom 22 triangulation)

| Source ID | Path / Command | Fetched-at |
|---|---|---|
| socraticode-zss-v2-fresh-status | `mcp__socraticode__codebase_status` (24149 chunks, green) | 2026-05-11 |
| socraticode-vrtx-status | `mcp__socraticode__codebase_status` (6371 chunks, green) | 2026-05-11 |
| socraticode-deploy-x4 | 4 phrasings × 2 repos: "n8n workflow deployment script" / "deploy n8n workflow to instance" | 2026-05-11 |
| socraticode-credentials | "n8n credential management secret env" (both repos) | 2026-05-11 |
| socraticode-supabase | "supabase url anon service role key environment" + "supabase workflow registry postgres schema" | 2026-05-11 |
| socraticode-railway | "Railway deployment n8n infrastructure dockerfile" | 2026-05-11 |
| socraticode-validation | "workflow validation schema linter score" | 2026-05-11 |
| socraticode-vrtx-process | "VRTX deploy workflow high quality process" | 2026-05-11 |
| socraticode-templates | "workflow template library catalog reusable" | 2026-05-11 |
| shell-vrtx-file-inventory | `find ./scripts -name '*.py' -o -name '*.sh'` (vrtx) | 2026-05-11 |
| shell-zss-v2-fresh-file-inventory | `ls src/lib/n8n/ + scripts/*n8n*` (zss-v2-fresh) | 2026-05-11 |
| shell-secret-grep | hardcoded `hsmyagcerajgjmlljtmx.supabase.co` grep (vrtx) | 2026-05-11 |
| memory-publish-decision | `project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11` | 2026-05-11 |
| memory-publish-readiness | `project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11` | 2026-05-11 |
| doctrine-class-divergence | `.flywheel/doctrine/public-repo-canonical-stamp-class-divergence.md` | 2026-05-11 |
| audit-precedent-2hiee | `.flywheel/audit/flywheel-2hiee/gap-analysis.md` (100minds-mcp audit pattern) | 2026-05-11 |

`triangulation=pass` — 16 independent sources, no single-source claims, no WebFetch needed (both repos locally indexed).

---

**End of recommendation.** Zero mutations made to either source repo. Awaiting Joshua's disposition on repo-shape + name + extraction approval.
