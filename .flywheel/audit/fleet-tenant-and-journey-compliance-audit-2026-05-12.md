# Fleet Tenant + Journey Compliance Audit — 2026-05-12

**Authority:** L168 (tenant declaration) + L170 (user-journey declaration)
**Scope:** every repo under `~/Developer/` that could plausibly carry consumer surfaces or tenant routing
**Method:** filesystem probe — `.zs-tenant.yaml` presence, `.zs-journeys.yaml` presence, `app/` or `pages/` directory, `package.json` UI-framework dependencies, README purpose-classification
**CSV:** `fleet-tenant-and-journey-compliance-audit-2026-05-12.csv` (14 rows; same dir)

## Headline findings

- **14 repos enumerated** — 11 cloned locally + 3 not cloned
- **L168 compliance: 1/11 (mobile-eats only)** — `mobile-eats/.zs-tenant.yaml` shipped 2026-05-12 via `/zs:project-bootstrap`
- **L170 compliance: 0/11** — no repo currently declares `.zs-journeys.yaml`
- **`alps-insurance` is a symlink to `alpsinsurance`** — canonical name is `alpsinsurance`; treat as one repo
- **`clutterfreespaces` is not currently a git repo** — needs `git init` before bootstrap can land

## P0 client-facing repos (4)

| Repo | L168 | L170 | Notes |
|---|---|---|---|
| **mobile-eats** | YES (shipped) | NO | Origin incident; first L170 bootstrap candidate |
| **alpsinsurance** | NO | NO | Regulatory class — insurance customer surfaces; symlinked from `alps-insurance/` |
| **terratitle** | NO | NO | Montana property intelligence platform — 33.4M+ records; legal workflows |
| **blackfoot-telecom** | n/a (not-cloned) | n/a (not-cloned) | ISP customer portal — clone + bootstrap when ready |

## P1 repos with user-facing surfaces (3)

| Repo | L168 | L170 | Notes |
|---|---|---|---|
| **zeststream-v2-fresh** | NO | NO | Next.js consumer-facing surface (ZestStream brand front-end) |
| **vrtx** | NO | n/a | n8n workflow factory for VRTX Gym; no traditional UI; L170 not applicable but L168 required for tenant routing |
| **clutterfreespaces** | NO | NO | Joshua client (Missoula storage business); needs `git init` before bootstrap |

## P2 / internal / platform / api-only (4)

| Repo | L168 | L170 | Notes |
|---|---|---|---|
| **agent-ui** | NO | NO | Next.js admin/internal tool — internal-operator journeys still recommended |
| **zeststream-platform** | NO | n/a | Shared substrate (observability/billing/security); no direct UI; L170 not applicable |
| **zesttube** | NO | n/a | Video processing pipeline; internal-only; L170 not applicable |
| **flywheel_gateway** | NO | n/a | API service; no client-rendered UI; L170 not applicable |
| **picoz** | NO | unknown | Type/purpose unclear; investigate before classifying L170 applicability |

## Not-cloned (3)

- **blackfoot-telecom** — P0 client (ISP); clone-when-ready
- **zeststream** (no-suffix) — investigate vs `zeststream-v2-fresh` canonicalization
- **flywheel-gateway** (hyphen variant) — likely no-op; canonical uses underscore (`flywheel_gateway`)

## L170 applicability summary

| Category | Count | L170 needed? |
|---|---|---|
| Consumer-app (customer-facing) | 5 (mobile-eats + alpsinsurance + terratitle + zeststream-v2-fresh + clutterfreespaces + blackfoot-telecom-when-cloned) | YES |
| Internal-tool (operator-facing) | 1 (agent-ui) | YES (internal operators are still users) |
| Workflow-automation (no UI) | 1 (vrtx) | NO |
| Platform-substrate | 1 (zeststream-platform) | NO |
| Pipeline (no UI) | 1 (zesttube) | NO |
| API-only | 1 (flywheel_gateway) | NO |
| Unknown/investigate | 2 (picoz + zeststream-no-suffix) | TBD |

**Total L170-applicable repos: 7 confirmed (6 cloned + 1 not-cloned)** + 2 needing investigation

## Dispatch sequencing (per L170 packet Action 3 + handoff Action 3)

Post-skillos-Phase-A + post-mobile-eats-Phase-B:

1. **P0 batch (4):** mobile-eats (already partial; just L170) → alpsinsurance → terratitle → blackfoot-telecom-when-cloned
2. **P1 batch (3):** zeststream-v2-fresh → clutterfreespaces (after `git init`) → agent-ui
3. **L168-only batch (3):** vrtx + zesttube + flywheel_gateway (tenant routing without journeys)
4. **Investigate batch (2):** picoz + zeststream-no-suffix (classify before dispatching)

Each P0/P1 repo gets ONE combined onboarding packet: `/zs:project-bootstrap <slug>` (L168) + `/zs:journey-bootstrap <slug>` (L170). L168-only repos get just the first half.

## Joshua-bandwidth ask (deferred until Phase A + Phase B ship)

Per L170 packet Section "Joshua-bandwidth ask (consolidated)" + handoff Section 6: batched AskUserQuestion cycle across all 7 L170-applicable repos at once. Estimated 7 × 4 = 28 inputs in matrix-style turn. Saves Joshua context-switches vs per-repo asks.

## Update of L170 shard table

The L170 shard at `.flywheel/rules/L111-L170-...md` has a stale fleet-rollout table reading "0 currently compliant with L170 (or L168)" — actually:
- L168 compliance: **1/11** (mobile-eats shipped 2026-05-12)
- L170 compliance: **0/11** (correct)

A follow-up edit to the shard should reflect this updated empirical state.

## Receipts

- Probe command: `for repo in <list>; do test -f $repo/.zs-tenant.yaml && ... done`
- Empirical date: 2026-05-12T20:15:00Z (filesystem state at audit time)
- Receipt scope: 14 candidate repos; 11 cloned; 4 P0 client-facing; 7 L170-applicable
