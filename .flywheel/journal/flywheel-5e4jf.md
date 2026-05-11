---
bead: flywheel-5e4jf
title: n8n surface scoping audit across zeststream-v2-fresh + vrtx
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
constraint: zero mutations
disposition: RECOMMENDATION-ONLY
recommendation: OPTION_D_HYBRID_PHASE_1_then_OPTION_C_MONOREPO_growth_path
joshua_ask: extract tremendous n8n work into single unified public repo (his first); supabase stays private
---

# Journey: flywheel-5e4jf

## What Joshua asked

> "I have tremendous n8n work in my system(s) within zeststream-v2-fresh and
> vrtx. I would like to extract that into a single unified public repo —
> it can be my first. But I need it to be private in the sense that I do
> not want others accessing my supabase. My n8n ecosystem continues to grow
> — I have a v1 and v2 instance both deployed on Railway and I have new
> processes in vrtx I've built to be able to quickly and easily deploy
> really high quality workflows."

P1 deep-audit; 8-section read-only recommendation; ZERO mutations.

## What I shipped

`.flywheel/audit/flywheel-5e4jf/recommendation.md` (~700 lines, 11 sections)
+ evidence pack + this journal.

## How I probed (Axiom 9 + Axiom 22 discipline)

8 concepts × 2-3 phrasings × K=10-15 per query = 16+ socraticode queries
across both repos (zss-v2-fresh: 24149 chunks indexed, vrtx: 6371 chunks).
Cross-repo parallel batching gave substantially better cross-file coverage
than sequential queries — surfaced as skill discovery
`socraticode_deep_cross_repo_inventory_pattern`.

Plus shell ground-truth: `find` across vrtx/scripts (30+ n8n-related scripts
identified), `ls src/lib/n8n/` zss-v2-fresh (8 TS modules: client + compiler
+ deployer + validator + types + index + webhook-handler + signature),
`grep` for hardcoded Supabase URL (10+ hits — flagged as scrub-required).

## Headline finding

The surface is **far larger than expected**:
- zss-v2-fresh has a complete TypeScript n8n SDK + 7-layer V3 validation
  pipeline + 25+ workflow scripts + agno-service agent toolkit +
  zs-ops-mcp Python MCP server + Railway infrastructure + 11+ Supabase
  migrations + `/deploy-n8n` Claude Code skill
- vrtx has 8 real production workflow JSONs + 30+ Python/shell scripts
  (the "high quality deploy process" Joshua referenced) + the 2026-04-29
  Codex deployment-archaeology audit cohort + v1+v2 active workflow estate
  (250/98 ratio)

Going single-repo (Option A) = kitchen-sink anti-pattern (6-8 days, mixed
concerns, high cognitive overhead). Going 5-repo split (Option B) = high
maintenance burden + diluted social proof. Going Option C (monorepo with
packages) = best long-term shape but premature for v0.1. **Going Option D
(hybrid: curated essentials public, advanced internal) = lowest cost, lowest
risk, fastest time-to-publish, matches the publish-decision directive
("internal-proof first, no premature polish, no npm publish until paying-
customer-pull").**

## What makes the VRTX deploy process "high quality"

Joshua's quote about "new processes in vrtx I've built to be able to
quickly and easily deploy really high quality workflows" maps to a 3-script
stack with 5 quality properties:

1. **Inactive-import-first model** (`n8n-phase1-scaffold-workflows.py` ~744L)
2. **Parity-checking vs live state** (`n8n-vrtx-parity-packet.py`)
3. **Credential-blind detection** (per `audits/2026-04-29-codex-credential-blind-policy.md`)
4. **Migration-wave classifier** (`n8n-migration-wave-classifier.py`)
5. **Per-workflow smoke ceremony** (10 `n8n-vrtx05-*.py` scripts)

The quality is **safety + reversibility**: every workflow lands disabled,
gets validated, only activates after human-in-the-loop smoke. Portable to
the public repo in ~2 worker-days (patterns 1-4 are universal; pattern 5
needs abstraction).

## Critical secret-scrub list (must address before publish)

1. `docs/N8N_INTEGRATION_STANDARDS.md` — 8 hardcoded credential UUIDs
2. `vrtx/scripts/search-templates.sh` — hardcoded Supabase URL
3. `vrtx/n8n-workflows/01..08.json` — likely contain credential refs
4. `vrtx/data/refresh-2026-04-28/*.json` — live n8n exports
5. `audits/2026-04-29-*` cohort — Supabase project IDs + named clients
6. All VRTX/Univision/ClubReady/ClutterFreeSpaces named-client references

Per `feedback_named_client_consent_per_surface_audit` META-RULE: ZERO
named-client material in v0.1; rewrite all templates with synthetic
gym/title/telecom data, not anonymized real data.

## 10 Joshua-decisions surfaced

Per §10 of recommendation.md:
1. Repo shape (D recommended for Phase 1; C for growth)
2. Repo name (`n8n-deploy-kit` recommended)
3. Account (jyeswak / zeststream)
4. License (MIT recommended)
5. Initial visibility (PRIVATE → PUBLIC after red-line audit)
6. v1 vs v2 coverage (v2-canonical recommended)
7. Template scope Phase 1 (5 synthetic recommended; NOT port VRTX)
8. Maintenance budget (30min/week minimum)
9. Pre-publish red-line gates (4-gate audit recommended)
10. Approve next dispatch (YES → file 4-7 sub-beads; NO defer; NEEDS MORE probes)

## Mission coherence

`mission_fitness=adjacent`. Direct support of Joshua's expressed ask
("extract into single unified public repo"). Aligns with 3 directives:
- `project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11`: a new public repo is in-scope for publish-readiness rollout
- `project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11`: §8C red-line gates require internal-proof + Joshua-dogfood ≥3 workflows + secret-scan clean BEFORE public flip
- `project_zeststream_ai_assessment_north_star_2026_05_11`: substrate-work-serves-commercial-deliverable-speed-of-light — extraction time-budgeted (~3-4 days Phase 1) to NOT displace AI-Assessment delivery

## Compliance

- AG receipt: 13/13 (8 dispatch-essential + 5 honesty/process)
- META-RULE 2026-05-11: 47th application
- Axiom 9 explicit (16+ socraticode queries documented)
- Axiom 22 explicit (16 sources triangulated)
- L52: 0 sub-beads filed per ZERO-MUTATIONS dispatch
- L61: not_applicable
- L107: NONE_READONLY
- L120: br close before callback (verified)
- compliance_score: 1000/1000

## Zero-mutation discipline confirmed

Both source repos untouched: zero commits, zero file edits, zero gh api
writes. All probes read-only. All worker writes went to
`.flywheel/audit/flywheel-5e4jf/` in flywheel repo only.

## Skill discovery

`socraticode_deep_cross_repo_inventory_pattern` — parallel-batched
socraticode searches across 2+ indexed repos + shell ground-truth +
named-client + secret-scan surface = canonical "extraction-readiness"
audit pattern. Reusable for any future "extract from internal to public"
question across the fleet's ~100 jyeswak repos.

## Operational pattern (4th application of recommendation-class)

This is the 4th read-only-audit → recommendation → Joshua-decision-surface
worker-tick this session (after 2hiee 100minds, rtohf BV, mmjvg flywheel-
stamp spec). Each preserved zero-mutations + Axiom-22 triangulation +
explicit decision surface. The pattern is the canonical
recommendation-class worker-tick — formalize as a flywheel skill if
N reaches ≥5 applications.
