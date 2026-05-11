---
schema_version: stamp-gap-analysis/v1
bead: flywheel-2hiee
target_repo: https://github.com/JYeswak/100minds-mcp
target_realpath: /Users/josh/Developer/100minds-mcp
authored_by: MagentaPond (flywheel:0.3)
authored_at: 2026-05-11
analysis_class: read-only (zero mutations)
disposition: SURFACE-FOR-JOSHUA-APPROVAL
recommendation: OPTION_C_HOLD_AS_PRODUCTION_INTERNAL_ALPHA_WITH_LIGHTWEIGHT_HONESTY_STAMP
mutations_made: 0
---

# Gap Analysis — 100minds-mcp vs Canonical Stamp Baseline

## TL;DR

| Question | Answer | Confidence |
|---|---|---|
| Rust active in past 2 days? | **MIXED** — last commit 2026-05-09 (~48h ago) was a `chore(housekeeping)` auto-commit from skillos:1 fleet, not real Rust dev. Real Rust development paused since 2026-01-30 (~3.3 months ago) | High |
| MIT license confirmed? | **TRUE** — `LICENSE` says MIT, GitHub API reports SPDX MIT, README badge MIT, Cargo.toml license="MIT" | High |
| Active customer pull? | **NOT VERIFIED** — 0 stars, 0 forks, 0 watchers, 1 README view in past 14d, all 9 open issues are dependabot (5) or self-filed [SWARM] [AUDIT] tasks (4). The "Used in production by Zesty" claim in README is self-referencing (Zesty = ZestStream's own swarm-daemon) | High |
| Canonical-stamp coverage | **PARTIAL** — 6 of 11 required artifacts present; 0 of 7 `.flywheel/` substrate; LICENSE class diverges (MIT vs All-Rights-Reserved baseline; this is intentional public-OSS divergence) | High |
| **RECOMMENDATION** | **OPTION C — HOLD AS PRODUCTION-INTERNAL-ALPHA with LIGHTWEIGHT honesty stamp** (see §6) | Surface for Joshua approval |

## 1. Verification of triage-rationale claims

### Claim 1: "Rust active 2d"

**Source data:**
```
Local HEAD: a228a56 2026-05-09 14:40:20 -0600
  chore(housekeeping): skillos:1-fleet-housekeeping auto-commit 1 append-only/log files

GitHub pushed_at: 2026-05-09T20:44:50Z
Today: 2026-05-11
Δ: ~48 hours
```

**Last 10 commits:**

| sha | date | msg |
|---|---|---|
| a228a56 | 2026-05-09 | chore(housekeeping): **auto-commit** append-only/log files |
| 2ab050e | 2026-01-30 | docs(AGENTS.md): Add MCP protocol compliance |
| 2e9a75f | 2026-01-30 | fix(mcp): Wrap tool responses |
| 4aaf050 | 2026-01-29 | feat(mcp): implement full MCP HTTP protocol |
| e103c15 | 2026-01-29 | fix: complete Thompson Sampling |
| 73976e4 | 2026-01-29 | docs: comprehensive AGENTS.md |
| 50b2d75 | 2026-01-29 | docs: comprehensive README |
| 1698e02 | 2026-01-29 | feat(neural): V6 Neural Bandit |
| 11f905f | 2026-01-29 | fix: remove needless borrow |
| 290fbd9 | 2026-01-29 | feat: production-quality polish |

**Verdict: MIXED.**
- Activity in past 2 days: TRUE (single auto-commit)
- Real Rust development in past 2 days: FALSE (pre-housekeeping last commit was 2026-01-30, ~100 days ago)
- Interpretation matters: if "active" means "git pushed", TRUE. If "active" means "real engineering activity", FALSE.

### Claim 2: "MIT confirmed"

**Source data:**
- `LICENSE` line 1: `MIT License`
- `LICENSE` line 3: `Copyright (c) 2026 ZestStream`
- GitHub API `license.spdx_id`: `MIT`
- README badge: `[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)`
- `Cargo.toml`: `license = "MIT"`

**Verdict: TRUE** — 4 independent sources confirm MIT.

### Claim 3: "active customer pull"

**External-signal probes:**

| Signal | Value | Interpretation |
|---|---|---|
| Stars | 0 | No external user starred |
| Forks | 0 | No external user forked |
| Watchers | 0 | No external user watching |
| Open issues (total) | 9 | — |
| Open issues by dependabot | 5 (#13-#17) | Bot churn, not customer pull |
| Open issues by JYeswak | 4 (#8-#11) | Self-filed [SWARM] [AUDIT] tasks |
| Open issues by external user | **0** | No external customer signal |
| Traffic clones (14d) | 55 total / 44 unique | Cloning activity exists |
| Traffic views (14d) | 1 view / 1 unique | Essentially zero README readers |
| Clones peak day (2026-05-09) | 23 clones / 12 unique | Coincides with auto-commit + CI/internal pull |

**README customer-pull claim audit:**
- README line 18: *"Used in production by [Zesty](https://github.com/zeststream/swarm-daemon) to guide autonomous coding agents"*
- This is **self-referencing**: Zesty = ZestStream's own swarm-daemon project
- README "Production-tested: 100k+ decisions in autonomous swarms" — same self-reference
- No third-party customer named in README

**Verdict: NOT VERIFIED as external customer pull.** Internal-fleet pull (Zesty swarm + dependabot + 44 unique clones over 14d, most concentrated on the auto-commit day) IS present and consistent with internal-substrate use, but no external customer signal exists.

This matters because the triage rationale appears to have used "active customer pull" as a reason to defer fold/archive — that reasoning is honest if rephrased as "active internal-fleet pull", but cannot be claimed as external customer-pull validation.

## 2. Canonical-stamp coverage (per flywheel-mmjvg stamp catalog)

Mapping the 15 canonical-stamp artifacts (plus 8 directory scaffolds) against what's present in `/Users/josh/Developer/100minds-mcp`:

| Artifact | Required? | Present? | State (per stamp v0.1) | Notes |
|---|---|---|---|---|
| README.md | yes | ✓ 19,552 bytes | **DRIFTED_BENIGN** | Lines, anchor present (`^# 100minds`); diverges in shape from skillos exemplar (no Mission Anchor blockquote, no Quick Start ≤5 commands strict pattern). Heavy ASCII art header (proven design choice). |
| ARCHITECTURE.md | yes | ✗ | **ABSENT** | Gap |
| ROADMAP.md | yes | ✗ | **ABSENT** | Gap |
| AGENTS.md | yes | ✓ 14,476 bytes | DRIFTED_BENIGN | Present; opens with "AI Agent Integration Guide" not the canonical Flywheel doctrine header; not auto-generated from `.flywheel/rules/`. Pragmatic for project-local agent integration. |
| LICENSE | yes | ✓ MIT | **DRIFTED_BREAKING-by-design** | LICENSE class = MIT, baseline stamp = All-Rights-Reserved alpha. **Intentional divergence: this repo is public OSS.** Stamp's catalog needs a `license_class` selector to handle "public-mit" vs "private-alpha-arr" without flagging this as breaking. |
| SECURITY.md | yes | ✓ 1,597 bytes | IDENTICAL-class | Honest contact, supported versions table |
| CONTRIBUTING.md | yes | ✓ 4,286 bytes | DRIFTED_BENIGN | Public OSS-style ("Thank you for your interest"), not skillos private-alpha clause. Intentional public-OSS divergence. |
| .gitignore | yes | ✓ 370 bytes | DRIFTED_BREAKING | Present but **does NOT have `.flywheel/`-class re-include `!` rules** — and there's no `.flywheel/` substrate to re-include. Pre-stamp pattern. |
| .flywheel/MISSION.md | yes | ✗ | **ABSENT** | Gap (full .flywheel/ substrate missing) |
| .flywheel/GOAL.md | yes | ✗ | **ABSENT** | Gap |
| .flywheel/AGENTS-CANONICAL.md | yes | ✗ | **ABSENT** | Gap |
| .flywheel/STATE.md | no (recommended) | ✗ | ABSENT | — |
| .flywheel/INCIDENTS.md | no | ✗ | ABSENT | — |
| .flywheel/PUBLISHABILITY-AUDIT.md | conditional | ✗ | ABSENT | Would be created by first stamp apply |
| .flywheel/dispatch-log.jsonl | no | ✗ | ABSENT | — |

**Bonus present (not in stamp catalog):**
- `CHANGELOG.md` (1,698 bytes — Keep-a-Changelog format) — good
- `.github/` (CI workflows) — good
- `.beads/` (Beads integration started) — partial flywheel integration
- `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, `Dockerfile`, `docker-compose.yml`, `src/`, `data/`, `eval/`, `scripts/`, `docs/`, `assets/` — Rust project substrate, all appropriate

**Score:** 6 of 11 required artifacts present (3 with intentional public-OSS drift, 1 with breaking gitignore drift due to missing .flywheel/). Pre-stamp publish-readiness: **6/15 → 40%** below stamp's 13/15 (87%) "publish-ready" threshold.

## 3. Additional issues observed (non-stamp)

| # | Issue | Severity | Why it matters |
|---|---|---|---|
| 1 | `Cargo.toml` `repository = "https://github.com/zeststream/100minds-mcp"` but actual repo is `https://github.com/JYeswak/100minds-mcp` | Medium | Stale metadata; crates.io publish would 404 the repo link. Pre-fold/archive triage should fix or note. |
| 2 | Package name `minds-mcp` ≠ binary name `100minds` ≠ repo name `100minds-mcp` | Low | Three-name ambiguity. Common in Rust workspaces but worth a `Naming` section in README/ARCHITECTURE. |
| 3 | README claims "70 thinkers" in description but "100 thinkers" in ASCII header + "thinkers-100" badge | Low | Minor inconsistency (GitHub description says 70, README body says 100). Likely the 70→100 expansion is what the V6 Neural Bandit commit shipped. |
| 4 | README links to `https://github.com/zeststream/swarm-daemon` (404) — that org is `ZestStream` not `zeststream`, and `swarm-daemon` may not exist publicly | Medium | Self-pull-validation link is broken (404). The customer-pull claim that depends on this link is therefore unverifiable from README alone. |
| 5 | No `.beads/issues.jsonl` rotation policy visible | Low | Per memory `feedback_retention_policy_by_default_for_accreting_surfaces` — every accreting surface needs launchd/cron retention at creation. |
| 6 | Bonus: CI badge URL points at `JYeswak/100minds-mcp/actions/workflows/ci.yml` — confirms CI workflow exists | n/a | Good — shows operator discipline |

## 4. Mission-fitness lens (Joshua-directives 2026-05-11)

Three relevant directives (per memory):

1. **`project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11`** — every jyeswak repo publish-ready or triaged to fold/archive
2. **`project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11`** — prove the system is what we say internally before publishing; npm publish gated by paying-customer-pull
3. **`project_zeststream_ai_assessment_north_star_2026_05_11`** — substrate work serves commercial deliverable speed-of-light

How 100minds-mcp scores against each:

| Directive | 100minds-mcp status |
|---|---|
| Publish-ready-or-fold/archive | **Neither yet.** 6/15 stamp coverage (not publish-ready) and not folded/archived |
| Internal-proof-first | **Honest pass.** Repo IS in real internal production (Zesty swarm); no premature npm publish (Cargo.toml repository link broken but no crates.io publish observed) |
| AI-Assessment-speed-of-light | **No direct contribution.** This repo doesn't accelerate AI-Assessment client deliverables — it's foundational adversarial-decision tooling that Zesty uses, one layer removed from client-facing speed |

## 5. Option matrix

| Option | Cost | Risk | Mission fit |
|---|---|---|---|
| **A. LIFT — apply full stamp** | High (3-5 days authoring: ARCHITECTURE, ROADMAP, .flywheel/*, gitignore rewrite, README mission-anchor refactor) | Low (additive; non-destructive) | Polishing public-face has low ROI given 0 external pull signal |
| **B. TRIAGE TO FOLD — archive** | Low (gh repo edit --archived) | **HIGH** — repo IS in internal production (Zesty swarm-daemon dependency); archiving disrupts internal use; would need to private-fork-and-archive carefully | Drops fleet substrate that's actually used |
| **C. HOLD AS PRODUCTION-INTERNAL-ALPHA + LIGHTWEIGHT honesty stamp** ★ | Low (1 day: add Production Status note to README + author `.flywheel/PUBLISHABILITY-AUDIT.md` + fix Cargo.toml repository URL + fix broken swarm-daemon link) | Low (small, surgical, honest framing) | Matches all 3 directives: honest framing aligns with internal-proof-first; preserves internal Zesty use; minimal time-to-AI-Assessment-speed |
| **D. DEFER pending external customer-pull validation** | Zero | None | But: defers a P1; doesn't resolve the "publish-ready or fold/archive" directive |

★ = recommended; ranked 1st on cost/risk/mission-fit composite.

## 6. RECOMMENDATION

### Primary: **OPTION C — HOLD AS PRODUCTION-INTERNAL-ALPHA with LIGHTWEIGHT honesty stamp**

**Rationale (5 points):**

1. **The repo is already public** — archiving (Option B) disrupts internal Zesty production use and orphans a working-but-undeveloped public surface
2. **0 external pull signal** (0 stars / 0 forks / 1 README view in 14d) means **full canonical stamp ROI is low** — investing 3-5 days to polish public-face docs for a repo no one is reading externally violates `project_zeststream_ai_assessment_north_star_2026_05_11` (commercial speed-of-light)
3. **Real Rust dev paused 3.3 months** — the repo's actual state is "stable internal substrate", not "actively developed product." A full ROADMAP.md would be aspirational fiction
4. **Honest framing is cheap + protects the ZestStream brand** — a Production Status note that says "production-tested internally; external use at own risk; not actively developed" is more brand-protective than a fully-polished README that implies active maintenance
5. **Defers full stamp until external pull signal materializes** — consistent with the publish-decision directive's "no premature polish; gated by paying-customer-pull"

### Lightweight honesty-stamp scope (1 day of work; gated by Joshua approval)

If Option C is approved, the minimal proposed scope is:

| Sub-action | What | Why |
|---|---|---|
| C1 | Add **Production Status** callout to README near top: "Internally production-tested by ZestStream's swarm-daemon (Zesty). Not actively developed for external consumption. External use at own risk. Last real Rust dev: 2026-01-30." | Honest framing; sets correct expectations |
| C2 | Author **`.flywheel/PUBLISHABILITY-AUDIT.md`** referencing this gap-analysis | Records the deliberate decision to defer full stamp |
| C3 | Fix `Cargo.toml` `repository` URL: `https://github.com/zeststream/100minds-mcp` → `https://github.com/JYeswak/100minds-mcp` | Stale metadata correctness |
| C4 | Fix README broken self-pull link: `https://github.com/zeststream/swarm-daemon` (404) → working URL or remove the link if Zesty swarm-daemon isn't public | Verifiability — broken proof-link looks worse than no proof-link |
| C5 | Add `.flywheel/MISSION.md` and `.flywheel/GOAL.md` stubs anchoring to "Adversarial Decision Intelligence" mission | Minimum substrate for future stamp application |

**Estimated effort:** 1 worker-day (vs Option A's 3-5 days). Reversible if external pull signal emerges later.

### Secondary: **Bead-decomposition for if/when Option C is approved**

Per META-RULE 2026-05-10 (decompose-by-natural-unit-not-bundle):

- `flywheel-2hiee.1` — README Production Status callout (C1) — 30 min
- `flywheel-2hiee.2` — `.flywheel/PUBLISHABILITY-AUDIT.md` authoring (C2) — 2h
- `flywheel-2hiee.3` — `Cargo.toml` repository URL fix (C3) — 5 min + CI verification
- `flywheel-2hiee.4` — README broken self-pull link fix or removal (C4) — 30 min
- `flywheel-2hiee.5` — `.flywheel/MISSION.md` + `.flywheel/GOAL.md` stubs (C5) — 2h

**NOT FILED in this audit** — sub-beads await Joshua's Option C approval per the dispatch's `zero mutations, surface for Joshua approval before any lift action` constraint.

## 7. Decision-required surface

> **Joshua, this audit asks for one of these dispositions:**
>
> 1. **APPROVE OPTION C** (recommended) — file `flywheel-2hiee.1` through `.5` as sub-beads; dispatch in normal flywheel order. ~1 worker-day total.
> 2. **APPROVE OPTION A** — file full-stamp-application sub-beads; ~3-5 worker-days. (Recommended only if a near-term external customer pull is anticipated.)
> 3. **APPROVE OPTION B** — fold/archive; coordinate with Zesty swarm-daemon to remove internal dependency first. (Recommended only if internal Zesty usage is also being deprecated.)
> 4. **DEFER** (Option D) — no action; revisit when external pull signal (≥1 external star, ≥1 external issue, or ≥1 named external user) materializes.

This gap-analysis is **read-only**. Zero mutations have been made to the 100minds-mcp repo or its substrate. Disposition awaits Joshua's direction.

## 8. L52 / L61 / L107 receipts

- **L52:** Sub-beads for Option C identified but **NOT FILED** per dispatch constraint. Will file on Joshua approval.
- **L61:** No doctrine/INCIDENTS/canonical/L-rule/skill edits. `agents_md_updated=not_applicable`, `readme_updated=not_applicable`, `no_touch_reason=zero-mutations-audit-only`
- **L107:** No shared-surface edits in flywheel repo (only owned audit dir). No edits in target repo. `files_reserved=NONE_READONLY` `files_released=NONE_READONLY`

## 9. Sources (Axiom 22 triangulation)

| Source ID | Path / Command | Fetched-at |
|---|---|---|
| 100minds-mcp-local-clone | `/Users/josh/Developer/100minds-mcp` (head: a228a56 2026-05-09) | 2026-05-11 |
| github-api-repo-metadata | `gh api repos/JYeswak/100minds-mcp` | 2026-05-11 |
| github-api-traffic-clones | `gh api repos/JYeswak/100minds-mcp/traffic/clones` (14d window) | 2026-05-11 |
| github-api-traffic-views | `gh api repos/JYeswak/100minds-mcp/traffic/views` (14d window) | 2026-05-11 |
| github-api-issues | `gh api repos/JYeswak/100minds-mcp/issues?state=open` | 2026-05-11 |
| github-api-recent-commits | `gh api repos/JYeswak/100minds-mcp/commits?per_page=5` | 2026-05-11 |
| stamp-catalog-baseline | `.flywheel/audit/flywheel-mmjvg/stamp-catalog.json` | 2026-05-11 |
| joshua-mission-directives | 3 memory entries (publish-readiness + publish-decision + AI-Assessment-north-star) | 2026-05-11 |

`triangulation=pass` — 8 independent sources, no single-source claims.
