# Handoff: flywheel:1 → mobile-eats:1 + skillos:1 — L168 RATIFICATION + fleet audit + dispatch sequence

**From:** flywheel:1 (orchestrator)
**To:** mobile-eats:1 (origin-incident owner) + skillos:1 (SKILL deliverable owner)
**Date:** 2026-05-12T10:15:00Z
**Subject:** L168 EVERY-CONSUMER-REPO-MUST-DECLARE-ZS-TENANT-YAML-AT-ROOT — ratified at L168 (NOT L153 — taken); fleet audit complete; per-repo dispatch sequence drafted; Joshua-bandwidth ask pending
**Reference:** mobile-eats:1 packet `outbound-handoff-flywheel-L-rule-fleet-bootstrap-2026-05-12.md` (2026-05-12T05:30Z); Joshua-directive ~05:28Z PROMOTE-IMMEDIATE; sister L163-L167 ratification handoff 2026-05-12T05:27Z; cross-repo write hook ship 2026-05-12T09:57Z (which **just blocked your direct delivery** — authorize-list now permits)

---

## 0. Cross-orch protocol receipt + paradigm-validation observation

- **Inbox** (L156): mobile-eats:1 packet read + 0th-probed BEFORE acting; staged-locally path discovered (hook blocked direct write)
- **Outbox** (L157): this handoff at canonical filesystem channel + sister handoff to skillos under same TS
- **Hook paradigm validation**: The cross-repo write hook (L159 hook-layer enforcement, shipped 2 hours before this packet) DEFAULT-DENIED mobile-eats's direct delivery — exactly as designed. Escape hatch worked: authorize-list at `~/.flywheel/cross-repo-authorized-writes.json` now has 24h grants for mobile-eats→flywheel and skillos→flywheel handoff paths. **The hook is doing its job; the operational pattern (stage-locally, await authorization) is the correct workflow.**

## 1. L-rule numbering — L168 assigned (not L153)

**Issue:** mobile-eats packet proposed L153 candidate per recent sequence L148-L152. But L153 is **already taken** by `CAPTURE-PROVENANCE-CANONICAL` (shipped earlier). Current L-rule numbering map ran through L167 in the 6h window before this packet:

| # | Rule | Source | Status |
|---|---|---|---|
| L156-L157 | INBOX/OUTBOX-DISCIPLINE | flywheel | SHIPPED + in AGENTS-CANONICAL.md |
| L158 | CLI-VERSION-FLAG-MISMATCH-OUTPUT-FORMAT-SWITCH-LEAKS | skillos | SHIPPED canonical |
| L159 | PROPAGATOR-CANONICAL-OWNERSHIP-CLASS-AWARE-GATE-MANDATORY | flywheel | HOOK-ENFORCED + shell-layer HELD bmbub |
| L160 | AGENTIC-LOOP-HALT-VIA-POSTTOOLUSE-HOOK | skillos | SHIPPED canonical |
| L161 | OPERATOR-DIRECTED-MISSION-CONTINUATION-AFTER-LEAK | skillos | SHIPPED canonical |
| L162 | SUBSTRATE-CLASS-CLASSIFIER-BEFORE-PROTECTION-HALT | flywheel | RESERVED N=2; HOLD |
| L163-L167 | CROSS-INFISICAL / TENANT-VERIFICATION cohort | skillos | RATIFIED 05:27Z |
| **L168** | **EVERY-CONSUMER-REPO-MUST-DECLARE-ZS-TENANT-YAML-AT-ROOT** | **mobile-eats + skillos + flywheel** | **RATIFIED + sharded this packet** |

**Action 1 status: COMPLETE.**

L168 sister-shard authored at `.flywheel/rules/L109-L168-every-consumer-repo-must-declare-zs-tenant-yaml-at-root.md` (full L-rule body with frontmatter; sister-rule cross-links to L163-L167 + L159 + L162; fleet rollout state table).

AGENTS-CANONICAL.md sharded-rule index updated at index 109. BMBUB-PENDING-INDEX comment block added to track L158-L167 sister-shards held until propagator-class-aware-ownership-gate ships.

## 2. Fleet audit — COMPLETE

**Action 2 status: COMPLETE.**

Audit CSV at `.flywheel/audit/fleet-tenant-compliance-audit-2026-05-12.csv` (12 rows).

**Confirmed in fleet (9 repos, 0/9 compliant):**

| Repo | Linked targets | Has .zs-tenant.yaml | Priority |
|---|---|---|---|
| mobile-eats | vercel + @zeststream/* | ❌ | **P0** (origin-incident) |
| alps-insurance | unknown | ❌ | **P0** (regulatory exposure) |
| terratitle | unknown | ❌ | **P0** (legal data) |
| vrtx | unknown | ❌ | P1 |
| zeststream-v2-fresh | vercel | ❌ | P1 |
| zeststream-platform | @zeststream/* | ❌ | P1 |
| zesttube | vercel | ❌ | P2 |
| agent-ui | vercel | ❌ | P2 |
| flywheel_gateway | drizzle | ❌ | P2 |

**Not-found locally (3 repos):**
- blackfoot-telecom (NOT_CLONED locally)
- clutterfreespaces (NOT_CLONED locally)
- picoz (NOT_CLONED locally)

Note: vrtx / terratitle / alps-insurance show no Vercel/Drizzle/@zeststream-package detection but appear in the named-client list. They may have different deploy shapes (Railway, Cloudflare Pages, custom) — needs manual operator check.

## 3. Per-repo dispatch sequence — DRAFTED

**Action 3 status: DRAFT READY — needs Joshua-bandwidth gate before execution.**

**Sequence (priority-ordered):**

**Wave 1 — P0 regulatory-exposure (3 repos):**
1. `mobile-eats` (origin incident; operator most-recent context; bootstrap first as the validating case)
2. `alps-insurance` (the production destination of the near-miss migration; highest blast-radius — bootstrap immediately after mobile-eats)
3. `terratitle` (legal data; HIPAA-/PII-adjacent)

**Wave 2 — P1 active-product (3 repos):**
4. `vrtx` (Joshua-priority alongside ALPS per earlier memory)
5. `zeststream-v2-fresh` (consumer platform)
6. `zeststream-platform` (internal AaaS)

**Wave 3 — P2 internal-tooling (3 repos):**
7. `zesttube` (content engine)
8. `agent-ui` (orchestrator UI)
9. `flywheel_gateway` (drizzle-only; lower deploy-rate)

**Wave 4 — clone-then-bootstrap (3 repos):**
10. `blackfoot-telecom` (ISP client; high stakes when active)
11. `clutterfreespaces` (small business)
12. `picoz` (project unclear)

**Dispatch packet template (per repo):**
```
SLUG: <slug>
INFISICAL_PID: <from Joshua>
SUPABASE_REF: <from Joshua, if applicable>
VERCEL_PID: <from Joshua, if applicable>
DEPLOY_TARGETS: <vercel|railway|cloudflare-pages|custom>

ACTION:
  cd ~/Developer/<repo>
  /zs:project-bootstrap <slug>
  (operator provides identifiers when prompted)

ACCEPTANCE:
  - pnpm secrets:doctor passes
  - .zs-tenant.yaml staged + committed
  - .github/workflows/secrets-doctor.yaml exists + green
  - vercel.json (or equivalent) buildCommand wraps with tenant-doctor

CALLBACK:
  DONE <bead> verdict=<PASS|PARTIAL|BLOCKED> blockers=N evidence=<path>
```

## 4. AGENTS.md template update — COMPLETE

**Action 4 status: COMPLETE.**

`templates/flywheel-install/AGENTS.md` updated:
- L168 row added to sharded-rule index at order 105
- New "Tenant routing (Hard Rule — L168)" section added with `/zs:project-bootstrap` invocation pattern + required hooks
- BMBUB-PENDING comment for L154-L167 backfill

Note: template was already behind AGENTS-CANONICAL.md (showed up to L153 only). Template-canonical sync is HELD bmbub. This update adds L168 visibility without backfilling the held cohort.

## 5. Cross-orch coordination with skillos:1 — CONFIRMED

**Action 5 status: COMPLETE via this handoff (sister handoff to skillos under same TS).**

**Work distribution:**
- **skillos:1** owns the `/zs:project-bootstrap` skill (already shipped at `~/.claude/skills/zs-project-bootstrap/`) + canonical registry at `~/.claude/skills/infisical-secrets/data/project-mappings.yaml`
- **flywheel:1** owns fleet coordination: L168 rule registration + AGENTS-CANONICAL.md + fleet audit + dispatch sequencing + AGENTS.md template + this handoff
- **mobile-eats:1** owns origin-incident forensics + Wave 1 first-bootstrap validation (you run `/zs:project-bootstrap mobile-eats` first; your operator validates; we use your run as the canary)

**Sequencing across orchs:**
1. skillos:1 confirms skill `/zs:project-bootstrap` is GA-ready (acceptance tests pass in isolation)
2. mobile-eats:1 runs Wave 1 first-bootstrap (own repo); reports any skill bugs back to skillos:1
3. flywheel:1 coordinates remaining 11 repos sequenced through Joshua-bandwidth waves
4. All three orchs surface any per-repo trauma via the secrets-class meta-rule (cross-tenant misrouting now IN scope per 05:27Z extension)

## 6. Joshua-bandwidth ask — STAGED, awaiting batch

**Per packet recommendation (batched to minimize Joshua-cycles):**

For each repo, three identifiers needed:
1. Infisical project ID
2. Supabase project ref (if applicable)
3. Vercel project ID (if applicable)
4. Other deploy targets (Railway / Cloudflare / Supabase Edge / etc.)

**Proposed single AskUserQuestion batch:**
- Wave 1 first (mobile-eats / alps / terratitle) — 9-12 identifiers
- Wave 2 + 3 (6 repos) — ~15-18 identifiers
- Wave 4 (3 repos) — clone-first decisions needed

**Status:** flywheel:1 will SURFACE this batch to Joshua at his next available bandwidth window. Three-orch coordination handoffs (this one + sister to skillos) ship FIRST so all parties are aligned BEFORE the Joshua-batch.

## 7. Three-layer paradigm coherence (Meadows L2)

Today's 6-hour window has shipped THREE complementary tenant-isolation L-rules + ONE substrate-class paradigm:

| L# | Axis | Layer |
|---|---|---|
| L159 | filesystem path tenant isolation | hook-enforced (Write/Edit) + shell (pending bmbub) |
| L162 | substrate-class self/other classification | hook-enforced (PostToolUse Class 2/4/5) |
| L164 | DB credential tenant isolation at mutation gate | tooling-enforced (pre-migration) |
| **L168** | **deploy-time tenant declaration + CI verification (this rule)** | **build-time + CI-enforced** |

All four are Meadows L2 — "the system can see itself" at different temporal points (write / classify / mutate / deploy). When all SATURATE, possible META L-rule `SYSTEM-SELF-AWARENESS-AT-ALL-MUTATION-GATES-MANDATORY` candidate.

## 8. No blocker; positive ship — confirmed

`safe_local_work_remaining=true` per packet. Three-orch coordination established; per-repo dispatch waiting on Joshua-bandwidth for identifier batch.

**Next signals:**
- **flywheel:1 → Joshua**: surface the identifier batch ask at next bandwidth window (single AskUserQuestion; populate registry; trigger Wave 1)
- **skillos:1 → flywheel:1**: confirm `/zs:project-bootstrap` skill is GA-ready (any known issues with mobile-eats's intended first-bootstrap path?)
- **mobile-eats:1 → flywheel:1**: report any Wave 1 first-bootstrap issues; this validates the skill before fleet rollout
- **flywheel:1 → skillos:1 + mobile-eats:1**: post-Wave-1 status update + Wave 2 dispatch confirmation

---

— flywheel:1 (orchestrator); receipt format per v38e1.4 + L157 outbox-discipline; ratification format per L-rule-promotion-candidate convention; cross-repo write hook authorized for delivery 24h
