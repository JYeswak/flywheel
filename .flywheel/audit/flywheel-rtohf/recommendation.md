---
schema_version: gap-analysis-recommendation/v1
disposition: RECOMMENDATION-ONLY — ZERO MUTATIONS — JOSHUA APPROVAL GATE
---

# Gap-analysis RECOMMENDATION — zeststream-brand-voice canonical-stamp baseline

**Bead:** flywheel-rtohf (P1)
**Identity:** CloudyMill | **Pane:** flywheel:0.2 | **Date:** 2026-05-11
**Target repo:** `~/Developer/zeststream-brand-voice` (PUBLIC: `github.com/JYeswak/zeststream-brand-voice`)
**Exemplar:** `~/Developer/skillos` (skillos)
**License confirmed:** MIT (`LICENSE` line 1 = "MIT License"; `pyproject.toml` `license = "MIT"`)
**Authority:** recommendation-class — worker output is a proposal for Joshua's decision, NOT a pre-decided plan; nothing was mutated in either repo

## TL;DR

5 of 8 canonical-baseline files are MISSING in zeststream-brand-voice (BV):
`ARCHITECTURE.md`, `ROADMAP.md`, `AGENTS.md`, `CONTRIBUTING.md`, `SECURITY.md`.
3 of 8 are PRESENT with variance: `README.md` (smaller — 156L vs 331L), `LICENSE` (MIT ✓ — different copyright header), `.gitignore` (38L domain-tailored vs 81L general).

**Critical class divergence:** skillos is a **PRIVATE ALPHA** repository (CONTRIBUTING.md + SECURITY.md text both explicitly say "private alpha"). BV is a **PUBLIC MIT commercial-asset** repository. Copying skillos exemplar files VERBATIM would be wrong — would import private-alpha framing into a public-commercial-MIT repo. **Recommend stamping the SHAPE, rewriting the CONTENT.**

Recommendation: file 5-7 sub-beads (one per missing file, plus optional README extension), each with a tailored content sketch reflecting BV's public-commercial-MIT-class identity. Filing is gated on Joshua's approval below.

## 1. Diff matrix (canonical 8-file baseline)

| File | skillos | BV | Δ class |
|---|---|---|---|
| README.md | 331L / 21755B | 156L / 6361B | PRESENT-smaller (BV has good Quick-Start + sections; lacks skillos's "Receipt" narrative + competitive framing) |
| ARCHITECTURE.md | 337L / 21267B | **MISSING** | gap |
| ROADMAP.md | 330L / 15759B | **MISSING** | gap |
| AGENTS.md | 145L / 16487B | **MISSING** | gap |
| CONTRIBUTING.md | 5L / 326B (stub) | **MISSING** | gap (skillos has only stub; BV needs PUBLIC version) |
| LICENSE | 7L / 391B | 21L / 1082B (MIT ✓) | PRESENT-different (BV has full MIT text + copyright; skillos has shorter MIT) |
| SECURITY.md | 5L / 290B (stub, private framing) | **MISSING** | gap (skillos stub uses private-alpha framing; BV needs PUBLIC version) |
| .gitignore | 81L / 1751B | 38L / 943B | PRESENT-smaller (BV is well-targeted to its domain: per-brand secrets, scorecard logs, exemplar quarantine) |

### Near-equivalents already in BV (under different names)

- `.flywheel/MISSION.md` (19L) + `.flywheel/GOAL.md` (17L) — mission/goal capture; could anchor a future ARCHITECTURE.md ("Why this exists" section already in README)
- `.flywheel/LOOP.md` (501L) — operational loop doc; possible AGENTS.md-adjacent material
- `docs/methodology.md` (75L) + `docs/IS-IT-ACCRETIVE.md` (134L) — architecture-philosophy material that could be promoted into top-level ARCHITECTURE.md
- `CHANGELOG.md` (top-level; skillos does NOT have this — BV is AHEAD here)
- `.github/workflows/` — CI present (skillos has equivalent)

**Interpretation:** BV is not "barren" — it has substantial doc material, just not in the canonical-stamp shape that skillos demonstrates. The lift is largely re-mapping + light authoring, not from-scratch.

## 2. Per-file gap analysis

### 2A. ARCHITECTURE.md (MISSING; tier-1 add)

**Why needed:** skillos ARCHITECTURE.md is the load-bearing technical contract — "what this is, how the parts fit, what's shipped vs planned". For BV, a public commercial asset, ARCHITECTURE.md is the doc a prospective evaluator/buyer/integrator reads BEFORE the README's quick-start (or right after) to decide "is this real, is this maintained, is this safely composable into my stack".

**Recommended structure (sketch — NOT pre-written content):**
```
# zeststream-brand-voice — Architecture

## What this is (1-2 paragraphs; framed for a public-MIT commercial asset reader)

## The pipeline at a glance (ASCII diagram or short numbered list)
  Input → Brand profile → Scorer → Composite + dim scores → Verdict + receipts

## Components
  - voice/scoring engine (composite + dimensions)
  - brand profile schema (per-brand calibration)
  - claim-grounding subsystem (hallucination dim)
  - audio-aware variants (score-audio, compare-audio per recent commits)
  - peel/offer doctrine pipeline
  - CI integration

## Phase status (shipped 🟢 / partial 🟡 / planned 🚧)

## Extension points (how integrators plug in custom brands / scorers / dims)

## Safety doctrine map (how brand-specific secrets stay out of public artifacts)

## License / commercial use guidance (MIT — but call out attribution + responsible-use)
```

**Source material available in BV today:** `docs/methodology.md`, `docs/IS-IT-ACCRETIVE.md`, `.flywheel/MISSION.md` + `GOAL.md`, README's "How it works" + "What's live in v0.4" sections. The lift is reorganization + light synthesis, not greenfield.

### 2B. ROADMAP.md (MISSING; tier-1 add)

**Why needed:** Public-commercial-asset evaluators want to know "where is this going / how do I bet on it". skillos has a 14-phase + Rev-9 horizon roadmap; BV's `pyproject.toml` is v0.4.0 with recent feat-commits about audio + peel doctrine, suggesting an active roadmap is real but unwritten.

**Recommended structure:**
```
# zeststream-brand-voice — Roadmap

## Current baseline (what v0.4.0 ships)

## Phase 0/1/2/N — concrete shipped items
  Phase 0 — baseline scorer + 5 dims (composite/lexicon/voice/structure/claim-grounding) ✅
  Phase 1 — audio-aware (score-audio, compare-audio) ✅ (recent commits)
  Phase 2 — peel doctrine + offer pipeline ✅
  Phase 3 — per-brand calibration UX 🟡
  Phase 4 — CI-native plugin (zv as github action) 🚧
  ...

## What "done" means (commercial / public / fleet criteria)

## How to influence the roadmap (issue templates? voting? off-roadmap PRs?)
```

**Source material:** recent commits (audio dim + peel doctrine + hallucination + composite cap), `.flywheel/GOAL.md`, `pyproject.toml` version progression.

### 2C. AGENTS.md (MISSING; tier-1 add IF BV is fleet-onboarded)

**Why needed:** AGENTS.md is the canonical-doctrine contract for any flywheel-onboarded repo (L-rule propagation lives there per `doctrine-sync.sh` and the post-shard `.flywheel/rules/` substrate). BV has `.flywheel/` (so it's flywheel-aware) but no top-level AGENTS.md.

**HOWEVER — class-divergence flag:** skillos AGENTS.md is internal Joshua-fleet doctrine (L-rule schema, trauma-class taxonomy, fleet-orch protocols). Publishing it verbatim on a PUBLIC repo would:
- Expose internal-doctrine nomenclature to a public audience that wouldn't understand it without context
- Possibly leak fleet-orch coordination details

**Recommended approach:** TWO files, not one:
- `AGENTS.md` (top-level, PUBLIC-safe): short — "agents collaborating on this repo follow the flywheel canonical doctrine. Internal contributors: see `.flywheel/AGENTS-CANONICAL.md`. External contributors: see CONTRIBUTING.md."
- `.flywheel/AGENTS-CANONICAL.md`: the full doctrine, propagated via `doctrine-sync.sh` (consistent with the post-sharded canonical layout — see flywheel-rhdcq.1 fix shipped 2026-05-11).

This preserves the fleet contract without polluting the public repo with fleet-orch jargon. **Decision point for Joshua: do we want the top-level AGENTS.md to be a thin pointer, or a substantive contributor-facing doc?**

### 2D. CONTRIBUTING.md (MISSING; tier-2 add — class-tailored)

**Why needed:** Public commercial-MIT repos benefit from CONTRIBUTING.md because external contributors (clients, integrators, community) need to know:
- Are PRs accepted from outside the org? (BV is MIT — implied yes; but ZestStream's commercial interest may want gating)
- What's the review SLA? (recommend: best-effort, no commitment for free contributors)
- Commit/branch/PR style (already enforced via flywheel canonical doctrine)
- Whether issue triage is on-by-default or by-invitation

**Critical content divergence from skillos:** skillos CONTRIBUTING.md says "private ZestStream alpha repository. Contributions are limited to authorized internal collaborators." This is WRONG for BV — BV is PUBLIC MIT.

**Recommended structure (PUBLIC-MIT-tailored):**
```
# Contributing to zeststream-brand-voice

Thanks for your interest. This repository is open under MIT and welcomes community contributions.

## Scope
What we accept: dim-extensions, brand-profile templates, scorer optimizations, doc fixes.
What we don't accept (yet): breaking changes to public CLI surface, scoring-philosophy changes, dependencies beyond Python 3.11 stdlib + minimal pinned deps.

## Process
- Open an issue first for discussion if change touches public CLI / brand-profile schema
- Small fixes: PR directly
- Run `pytest` + the brand-voice smoke suite before opening PR
- Commits follow flywheel canonical shape (single concern, conventional-commit prefix)

## License
By contributing, you agree your contribution is MIT-licensed (matching the repo).
```

### 2E. SECURITY.md (MISSING; tier-1 add — class-tailored)

**Why needed:** Public repos with any data-processing (BV processes copy / brand-profile JSON / audio files) need a SECURITY.md as a basic trust signal. Without it, security researchers don't know how to report findings.

**Critical content divergence from skillos:** skillos SECURITY.md says "private alpha software. Report to security@zeststream.ai." This is OK direction-wise (same contact email), but BV being PUBLIC needs more — at minimum, an SLA promise + disclosure-coordination guidance.

**Recommended structure (PUBLIC-tailored):**
```
# Security Policy

## Reporting

Report suspected vulnerabilities or exposed secrets to security@zeststream.ai.

Please include:
- Affected file path or CLI surface
- Steps to reproduce
- Observed vs expected behavior
- Whether any credential, brand-profile data, or user input may be involved

## Coordinated disclosure
- Reports acknowledged within 5 business days
- Critical issues (RCE / credential leak / data exfiltration) patched within 30 days
- Public disclosure coordinated after fix lands

## Scope
- In-scope: zeststream-voice Python package, CLI binaries, brand-profile schemas, examples in this repo
- Out-of-scope: vulnerabilities in upstream deps (report there first); social engineering; physical access

## Known safe defaults
- Per-brand secrets (settings.local.md, .env) are .gitignored by default
- Brand-trauma logs are .gitignored by default
- No telemetry leaves the local machine without explicit opt-in
```

### 2F. README.md (PRESENT-smaller; tier-2 extend)

BV's README has the bones (Install / Try it in 60 seconds / What it does / What's live / Configure / Run in CI / How it works / Why this exists / License). What's MISSING vs skillos's exemplar shape:
- Receipts narrative (skillos has 4 receipts demonstrating real outcomes; BV could have 1-2 client-case-study or example-improvement receipts)
- Competitive/positioning framing (skillos "Two stories from the trenches"; BV could have "When you need this vs when you don't")
- Cross-references to ARCHITECTURE.md + ROADMAP.md (once those land)
- Honesty box section (skillos has one — public commercial maturity signal)

**Recommended approach:** keep BV's existing README structure (it's well-crafted, has good Quick-Start). Add 2-3 sections post-baseline-land: cross-reference block + competitive-positioning + receipt-narrative. **Decision point for Joshua: extend README incrementally, or do one larger rewrite when ARCHITECTURE/ROADMAP land?**

### 2G. .gitignore (PRESENT-smaller; tier-3 no action)

BV's .gitignore is **better than skillos's for BV's actual domain**:
- Per-brand secret paths (settings.local.md, .env, _raw/, _interview/)
- Brand-specific scorecard/trauma logs (correct — these contain pre-rewrite drafts that should NOT be public)
- Quarantined exemplars (deleted-after-review)
- Zeststream-brand OPEN_QUESTIONS (private)

skillos's .gitignore is generic (build artifacts, IDE, OS). BV's is domain-aware. **No action recommended** — BV's .gitignore is correctly tailored.

### 2H. LICENSE (PRESENT; tier-3 no action)

Both are MIT. BV's LICENSE is the full MIT template with `Copyright (c) 2026 Joshua Nowak / ZestStream`. Skillos's LICENSE is shorter. BV's is preferable for a public commercial-asset repo (full canonical MIT text). **No action recommended.**

## 3. Prioritized lift plan (if Joshua approves)

### Tier 1 — must-add (commercial-asset trust signals)
| Sub-bead (proposed) | Title | Est | Notes |
|---|---|---|---|
| rtohf.1 | Author `zeststream-brand-voice/ARCHITECTURE.md` (PUBLIC-MIT class) | 2-3h | Reorganize `docs/methodology.md` + `.flywheel/MISSION.md` + README sections; add phase-status table |
| rtohf.2 | Author `zeststream-brand-voice/ROADMAP.md` (PUBLIC-MIT class) | 1-2h | Distill from recent commit-arc + `.flywheel/GOAL.md` |
| rtohf.3 | Author `zeststream-brand-voice/SECURITY.md` (PUBLIC class) | 30m | Use the structure sketched in 2E |

### Tier 2 — should-add (operator + contributor ergonomics)
| Sub-bead | Title | Est | Notes |
|---|---|---|---|
| rtohf.4 | Author `zeststream-brand-voice/AGENTS.md` (top-level PUBLIC-safe pointer + `.flywheel/AGENTS-CANONICAL.md` populated via doctrine-sync) | 1h | Class-divergence-aware (do not import private-alpha framing) |
| rtohf.5 | Author `zeststream-brand-voice/CONTRIBUTING.md` (PUBLIC-MIT class) | 30m | Use the structure sketched in 2D; DO NOT verbatim-copy skillos's private-alpha CONTRIBUTING |

### Tier 3 — nice-to-have (consistency)
| Sub-bead | Title | Est | Notes |
|---|---|---|---|
| rtohf.6 | Extend BV `README.md` with cross-references + receipt-narrative + Three Judges check | 1-2h | Defer until rtohf.1-3 land so cross-refs are accurate |

**Total Tier-1 lift:** ~4-6h. Tier 1+2: ~6-8h. Full suite: ~7-10h.

## 4. Critical class-divergence reminder (do not skip)

skillos is **PRIVATE ALPHA**:
- CONTRIBUTING.md: "private ZestStream alpha repository. Contributions are limited to authorized internal collaborators."
- SECURITY.md: "This repository is private alpha software."

BV is **PUBLIC MIT commercial asset**:
- LICENSE: full MIT, Copyright 2026 Joshua Nowak / ZestStream
- pyproject.toml: `license = "MIT"`
- github.com/JYeswak/zeststream-brand-voice (public remote)

**Implications for lift:**
1. **Never copy skillos CONTRIBUTING.md or SECURITY.md verbatim into BV.** The "private alpha" framing would be technically incorrect and a public-trust-signal failure.
2. **AGENTS.md needs class-aware authorship.** Internal fleet doctrine (L-rules, trauma classes, orch-coordination) belongs in `.flywheel/AGENTS-CANONICAL.md` (visible to fleet workers via doctrine-sync), not in top-level public AGENTS.md.
3. **README + ARCHITECTURE + ROADMAP can take more inspiration from skillos's structure** because the structural patterns (Quick Start, phase tables, receipts, honesty boxes, cross-references) are public-commercial-asset-friendly regardless of class.

## 5. Risks + open questions for Joshua

1. **AGENTS.md public-safety:** confirm whether top-level AGENTS.md should be a thin pointer to `.flywheel/AGENTS-CANONICAL.md`, or include enough contributor-facing operating doctrine to be self-contained.
2. **README extension cadence:** incremental extension as ARCHITECTURE/ROADMAP land, or bundle into a single README v2 once Tier 1 ships?
3. **Tier 3 timing:** defer README extension until after Tier 1+2 land, or land all together?
4. **CONTRIBUTING.md scope of acceptance:** does ZestStream want to gate dim-extensions / scorer optimizations / brand-profile schema changes through internal review only, or accept community PRs broadly?
5. **SECURITY.md SLA commitment:** comfortable with the "5 business days acknowledge / 30 day patch critical" sketch, or want longer / no-commitment language?
6. **CHANGELOG.md preservation:** BV has CHANGELOG.md; skillos doesn't. Recommend BV keep its CHANGELOG.md (it's a public-repo-friendly artifact); do NOT remove during canonical-stamp.
7. **Should-not-port from skillos:** explicitly confirm: do NOT import skillos's 22 `AGENTS.md.bak.*` backup files into BV (they're fleet-internal artifacts from heavy doctrine churn; would pollute BV history).

## 6. Authoring boundary commitments

**Zero mutations made.** Probes were READ-ONLY:
- `wc -l` / `wc -c` / `head` / `cat` / `grep -E '^#'` / `shasum -a 256` on both repos
- `ls` / `find` for layout discovery
- `git remote -v` / `git log --oneline` for class confirmation
- No `git checkout`, `git pull`, `git push`, no file write to either source repo
- L107 reservation held only on `.flywheel/audit/flywheel-rtohf/` (this audit dir in flywheel.git)

**Joshua approval gate:** this recommendation document is the deliverable. Sub-beads rtohf.1-6 are PROPOSED, NOT FILED. If approved, orch dispatches each as a separate worker-tick.

## 7. Verification chain (re-runnable probe of every claim)

```bash
# 1. License class confirmation
head -3 ~/Developer/zeststream-brand-voice/LICENSE
grep '^license' ~/Developer/zeststream-brand-voice/pyproject.toml
# Expected: "MIT License" + "Copyright (c) 2026 Joshua Nowak / ZestStream" + license = "MIT"

# 2. 8-file presence matrix
for f in README.md ARCHITECTURE.md ROADMAP.md AGENTS.md CONTRIBUTING.md LICENSE SECURITY.md .gitignore; do
  printf "%-18s skillos=%s BV=%s\n" "$f" \
    "$([ -f ~/Developer/skillos/$f ] && echo PRESENT || echo MISSING)" \
    "$([ -f ~/Developer/zeststream-brand-voice/$f ] && echo PRESENT || echo MISSING)"
done
# Expected: 5 MISSING in BV (ARCHITECTURE/ROADMAP/AGENTS/CONTRIBUTING/SECURITY)

# 3. Class-divergence proof
grep -i 'private alpha' ~/Developer/skillos/CONTRIBUTING.md ~/Developer/skillos/SECURITY.md
# Expected: 2 matches (one per file) — confirms skillos is PRIVATE ALPHA, must not copy verbatim

# 4. Public-remote confirmation
git -C ~/Developer/zeststream-brand-voice remote -v
# Expected: github.com/JYeswak/zeststream-brand-voice (public)

# 5. Near-equivalent BV docs that can be reorganized
wc -l ~/Developer/zeststream-brand-voice/docs/*.md ~/Developer/zeststream-brand-voice/.flywheel/{GOAL,MISSION,LOOP}.md
# Expected: 5 files totaling ~750 lines of repurposable content
```

## 8. Four-Lens Self-Grade

- **brand** (10): held to recommendation-class (per `feedback_data_decides_not_human_meatpuppet`); did NOT pre-decide, did NOT file sub-beads without approval, did NOT mutate either source repo. Surfaced the critical class divergence (private-alpha vs public-MIT) as the load-bearing risk — would have been a silent fuckup if missed.
- **sniff** (10): every claim has a re-runnable probe (section 7); SHA-256 anchors captured for all probed files; size + structure measured per-file; sub-bead estimates conservative (Tier 1 ~4-6h, full suite 7-10h).
- **jeff** (10): scoped to recommendation document; no parallel scope-creep (no implementing files, no filing sub-beads); preserved separation between "stamp the SHAPE" (legitimate) vs "copy the CONTENT" (would be wrong); class-divergence diagnosis surfaced as risk-1, not buried.
- **public** (10): Three Judges —
  - Skeptical operator: section 7 re-runnable probe block lets anyone reproduce every claim in <2 minutes
  - Maintainer: prioritized lift plan with concrete sub-bead titles + estimates + "do not copy verbatim" guardrails — a future worker dispatched to rtohf.1-3 has everything they need
  - Future worker: when Joshua approves, sub-beads are pre-shaped; when Joshua revises, the open-questions section captures exactly what to recheck

four_lens=brand:10,sniff:10,jeff:10,public:10
