# 02-REFINE-r1.md — Converged Plan (Phase 2, Round 1)

**Phase:** 2 REFINE
**Round:** 1
**Author:** flywheel:1 / Phase-2 synthesis lane
**Synthesizes:** `01-RESEARCH-A.md` (problem-space inventory), `01-RESEARCH-B.md` (ecosystem audit), `01-RESEARCH-C.md` (implementation design)
**Status:** Draft for Phase 2 audit + further refinement rounds. Hypothesis slate ratified; bead DAG still preliminary.

---

## 1. Executive summary

Extract the universal substrate of the flywheel monorepo into a public, MIT-licensed engine at `github.com/JYeswak/flywheel`, and ship a separate SMB-facing landing site at `flywheel.zeststream.ai`. The two surfaces serve different audiences (developers vs SMB owners) but the same goal: build trust in Joshua, ZestStream, and the work. The bottleneck is not architecture — Lane C's 4-phase extraction pipeline is sound — but de-personalization scope. Lane A measured 50% of scripts hardcoding `/Users/josh`, 64% of doctrines naming a specific client, and only 11 of 183 memory rules surviving the strict pure-pattern filter. Realistic extraction effort is **40-60 worker-hours** (Lane A §5.1), 3-5× the optimistic estimate in the original CLASSIFICATION-PLAYBOOK. We recommend hypothesis **H3 (engine + redacted-overlay-as-case-study)**: ship a real engine for developers AND a redacted-but-real version of Joshua's overlay as the flagship case study. Both surfaces reinforce each other and dodge the trap of either (a) shipping a thin engine no one can copy from, or (b) shipping a maximal engine that drowns adopters in personal context.

---

## 2. The two-audience model

Joshua's directive (2026-05-12T~17:00Z, INTENT §Joshua's directive): *"The git repo's audience is fellow developers... our audience for the webpage is SMB clients — both are designed to build trust in me, our brand, and our work."*

The two surfaces are not redundant. They serve different decision-shapes:

| Surface | Audience | Decision they're making | Trust-building shape |
|---|---|---|---|
| `github.com/JYeswak/flywheel` | Developers, architects, AI-tooling tinkerers | "Is this engineering serious enough to study, copy, or contribute to?" | Code quality, tests, docs, transparent metrics, opinionated methodology |
| `flywheel.zeststream.ai` | SMB owners, prospective clients of ZestStream consulting | "Is this person someone I'd hire to fix my AI strategy?" | Founder visibility, named case studies, engagement clarity, quantified outcomes |

### What goes in the github repo

- The engine itself (extracted, de-personalized, installable)
- A `README.md` aimed at developers (5-minute overview + install command)
- A `CHARTER.md` declaring what flywheel is and isn't
- Doctrine, L-rules, and universal memory rules (the intellectual contribution)
- Hooks, scripts, templates (the operational substrate)
- A Nextra docs site at `docs/` (the reference manual)
- Examples + tests + CI workflows (the proof of seriousness)
- LICENSE (MIT), CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md (the table-stakes)

### What goes on the webpage

- A landing page that says "AI development that compounds" in one breath
- A `/what-is-flywheel` page that explains the three reasoning spaces in SMB language
- A `/for-developers` page that bridges to github (short; not the main path)
- A `/case-studies` page with at least one real case study (per H3, the redacted-Joshua-overlay-as-meta-case-study)
- An `/about` page featuring Joshua personally (MBA, 12 years ZIRKEL, current ZestStream focus)
- A `/contact` page with three engagement intake options (mirrors the AI Assessment ladder)
- The proxied install endpoint `/install.sh` and `/install.sh.sha256`

### How they reinforce each other

- The webpage's `/for-developers` links to the github repo as proof-of-engineering-substance.
- The github repo's `README.md` links to the webpage as the "official home" for the project.
- The case study on `/case-studies` is *the meta-application*: "here's how we used flywheel to extract flywheel." A developer reading it sees engineering rigor; an SMB owner reading it sees demonstrated execution.
- Both surfaces feature Joshua personally. The repo signs commits under his name; the webpage carries his photo + bio. The shared signal: this is one person's serious work, not a vendor brand.

---

## 3. Hypothesis slate

| ID | Strategy | Kill condition | Third alt? |
|---|---|---|---|
| **H1** | **Aggressive extraction (maximal engine).** Extract 70-80% of current substrate as engine. Spend 40-60h on de-personalization. Ship a comprehensive v0.2 covering doctrine + L-rules + memory + scripts + hooks + templates + skills. | Any single category exceeds 30 worker-hours OR any de-personalization sweep produces an artifact that fails the "would Joshua direct a developer to this?" Joshua-judged review. | no |
| **H2** | **Minimal extraction (thin engine).** Extract only the ~11 pure-pattern memory rules + ~25 engine-class doctrines + 4 canonical hooks + the install scaffold. Ship minimal but solid v0.2. Iterate to v0.3/v0.4 as adopters request expansion. | Adopters' first-week feedback says "this doesn't have enough substance to be useful" OR Joshua reviews and says "this isn't proud-worthy yet." | no |
| **H3** | **Engine + redacted-overlay-as-case-study (both-and).** Publish the engine at developer-ready depth (between H1 and H2 in volume; ~40 engine doctrines + 70 L-rules + 4 canonical hooks + ~80 scripts + ~30 memory rules + install scaffold) AND publish a redacted-but-real version of Joshua's overlay as the flagship case study on `flywheel.zeststream.ai/case-studies`. The case study shows the engine running on Joshua's actual fleet (with client names, dates, traumas redacted per the per-surface-consent rule). The engine builds developer trust; the case study builds SMB trust. | The redaction sweep on the overlay-as-case-study reveals so much real client data that even with redaction it can't ship without per-client consent we don't have time to collect AND the engine-without-case-study fails the SMB-trust bar (no named outcomes). | **yes** |

**Recommendation: adopt H3 as Phase 2 working hypothesis.** It threads the needle Joshua identified: "make ourselves and the world truly proud" requires both engineering credibility (engine) and demonstrated execution (case study). H1 alone risks looking like documentation without proof; H2 alone risks looking like a toy. H3 is the only candidate that uses Joshua's existing fleet as substrate while respecting the per-surface-consent and class-divergence memory rules.

**Phase 3 audit input:** the audit lane should specifically stress-test H3's kill condition. If the redacted-overlay-as-case-study can't pass the named-client-consent gate (memory rule 2026-05-11), H3 collapses to H1 or H2 by default.

---

## 4. Engine/overlay boundary — refined

### 4.1 What the lanes converge on

Lane A's classification work (§1-2) + Lane C's substrate-rule table (§1.4) + Lane B's PAI containment-zone pattern (§1) agree on a tri-class taxonomy:

- **Engine** — universally valuable; ships verbatim or with mechanical projection (`Joshua → {operator}`).
- **Engine-after-rewrite** — the pattern is universal but the artifact references specific clients/dates/orchs; needs substantive (not mechanical) rewrite to publish.
- **Overlay** — load-bearing content IS the instance; ships nowhere public.

Lane A measured each category. Lane C named the codemod. Lane B observed that PAI handles the same split with explicit `.pai-protected.json` containment zones.

### 4.2 Concrete counts (refined from Lane A §0)

| Substrate category | Total | Engine | Engine-after-rewrite | Overlay | Rewrite-effort (worker-hours) |
|---|---:|---:|---:|---:|---:|
| Doctrine (`.flywheel/doctrine/*.md`) | 94 | ~25 | ~50 | ~15-19 | 12-15 |
| L-rules (`.flywheel/rules/L*.md`) | 109 | ~70 | ~30 | ~10 | 6-8 |
| Memory rules (`.../memory/*.md`) | 183 | 11 | ~60-70 | ~100+ | 8-12 |
| Scripts (`.flywheel/scripts/*.sh|.py`) | 394 | ~80 | ~200 | ~115 | 10-15 |
| Hooks (canonical only) | 4 | 4 | 0 | 0 | < 1 |
| Templates (`templates/flywheel-install/*`) | 62 | ~30 | ~25 | ~7 | 2-3 |
| Flywheel-namespaced skills | ~6 + subtree | ~2 | ~3 | ~1 | 4-6 (+skillos coord) |
| AGENTS.md substrate | 4 | 1 (canonical) | 1 (template) | 2 | 1 |

**Engine-after-rewrite is the dominant work category.** ~370 artifacts across all categories need substantive rewrite, not mechanical substitution. This is what makes the 40-60 hour estimate realistic.

### 4.3 The boundary is achievable but not mechanical

Lane A §5.1 names the trap directly: *"Mechanical sweep is insufficient — substantial pattern-extraction rewrites are required for the high-value engine artifacts."* The CLASSIFICATION-PLAYBOOK's four-question filter triages correctly, but rewriting an `engine-after-rewrite` artifact that uses load-bearing client examples means *preserving the trauma-shape while losing the instance metadata.* That's authorial judgment, not codemod work.

**Implication for the extraction pipeline:** Lane C's Phase 2 (DE-PERSONALIZE) must distinguish two sub-modes:

- **Mode A — codemod sweep** for files where the de-personalization-table substitution is sufficient (most L-rules, most scripts, many memory rules).
- **Mode B — pattern-extraction rewrite** for files where the example must be abstracted while preserving evidentiary force (most engine-after-rewrite doctrines, some L-rules, the high-value memory rules).

Mode A is one worker-hour for hundreds of files. Mode B is 15-30 minutes per file for ~80-100 files. The arithmetic checks out at 40-60 hours total.

### 4.4 Two-repo vs one-repo decision

Lane A §5.3 surfaces the question: is the public artifact one repo (engine) or two (engine + overlay-example)?

**Phase-2 default: ONE repo.** Joshua's directive names `github.com/JYeswak/flywheel`. Two repos doubles the maintenance burden and dilutes the "study this one thing" signal. The case study (per H3) lives on the webpage, not in a second repo. If H3's case study proves so substantive that adopters want to fork it as a starting overlay, a `flywheel-overlay-template/` repo gets created at v0.3.

### 4.5 Flywheel↔skillos boundary

Lane A §5.2 names the unresolved cross-repo question: JSM, skill-builder, agent-mail, the canonical-CLI-scoping skills — are they flywheel-publishable or skillos-canonical?

**Phase-2 default: defer skill substrate to v0.3.** v0.2 ships zero ambient skills. The engine ships the *interface* (skills/ directory layout, SKILL.md format, sentinel comment conventions) but not specific skills beyond the flywheel-namespaced ones that survive de-personalization (~2 engine + ~3 engine-after-rewrite). The skillos:1 ratification handoff (already initiated per the cross-orch coordination thread on 2026-05-11) decides which skillos-owned skills enter the public ecosystem at v0.3 and which stay private.

---

## 5. Extraction pipeline — refined

Lane C's 4-phase pipeline (CLASSIFY → DE-PERSONALIZE → ASSEMBLE → VERIFY) is structurally sound. Refinements below sharpen each phase.

### 5.1 The classification mechanism — hybrid, not codemod alone

**Classifier is a Python script** (not bash) at `scripts/classify.py` that emits `classification.jsonl`. Per-file classification rule:

```python
def classify(path, content):
    if any(pure_overlay_pattern.search(content) for pattern in OVERLAY_PATTERNS):
        return ("overlay", "matches_overlay_pattern")
    if pure_pattern_filter(content):  # no proper noun, no date, no path more specific than ~/Developer/
        return ("engine", "passes_pure_pattern_filter")
    if mechanically_projectable(content, DEPERSONALIZATION_TABLE):
        return ("engine_after_rewrite", "mode_a_codemod_sufficient")
    return ("engine_after_rewrite", "mode_b_pattern_rewrite_required")
```

The classifier is conservative: it errors on the side of `engine_after_rewrite` rather than `engine`. Every `engine` classification gets a `manual_review_recommended: true` flag if it scores below a confidence threshold. Joshua + flywheel:1 review the borderline cases.

### 5.2 The de-personalization codemod — table-driven

Lane C §1.5 sketches `de_personalization_table.yaml`. Phase 2 refines:

- **The table itself is engine-class** — it ships in the public repo at `scripts/de-personalization-table.example.yaml` so adopters can build their own.
- **The table is monorepo-only** in the form that contains Joshua's actual private mappings. That copy lives at `.flywheel/extraction/de-personalization-table.yaml` and is `.gitignore`d in the public repo.
- **The substitution is whole-token, not substring.** Naive substring substitution would replace "Joshua" inside "joshuanowak.com" as ".com". Use word-boundary regex (`\bJoshua\b`) or AST-aware substitution for markdown.
- **The table has audit metadata.** Each entry records "first observed in <file>" so Joshua can review the privacy implications of each mapping before extraction.

### 5.3 The verification step — what "successful extraction" means

Lane C §1.8 lists the smoke-test checks. Phase 2 adds the **Joshua-judged success criterion** per Joshua's INTENT directive ("make ourselves and the world truly proud"):

- **Engineering-objective gates** (Lane C's smoke test): install on fresh macOS works, doctor returns 0, uninstall byte-equality holds, CI green on macOS + Ubuntu.
- **Joshua-judged gates** (new):
  - Joshua reads the README and says "I'd direct a developer here."
  - Joshua reads the CHARTER and says "this reads as mine, not as generic substrate."
  - Joshua opens 10 random engine doctrines/L-rules/memory rules and finds zero client-name leaks.
  - Joshua reviews the manual-review queue from extraction and signs off on every entry.

The Joshua-judged gates are a B15 acceptance criterion, not a continuous CI check.

### 5.4 Reversibility — strict, with one nuance

Lane C §1.7 declares the extraction strictly additive (never modifies source). Phase 2 adds: **the source repo's .flywheel/extraction/ directory accumulates classification.jsonl + manual-review notes from each extraction run**, dated by run timestamp. These are overlay-class (they reference real client names) and stay in the monorepo. The accumulation is the audit trail; if a future extraction misclassifies a file, the prior runs' notes show the history.

If H3 is killed and we fall back to H1 or H2, the working extraction trees are `rm -rf`'d and the table is updated. The source repo is untouched.

---

## 6. Installer architecture — refined

Lane C §2 is detailed and largely correct. Two refinements driven by Lane A's findings:

### 6.1 Path parameterization is a contract — not a substitution

Lane A §3 risk #4 names the trap: parameterizing `/Users/josh/.local/bin/ntm` to `$NTM_BIN` is a contract change. Existing flywheel installations don't have `$NTM_BIN` set. **Refinement:** every parameterized path ships with a hardcoded default that preserves the original behavior on Joshua's machine:

```bash
NTM_BIN="${NTM_BIN:-$HOME/.local/bin/ntm}"
FLYWHEEL_ENGINE_ROOT="${FLYWHEEL_ENGINE_ROOT:-$HOME/.flywheel/engine}"
FLYWHEEL_PROJECT_ROOT="${FLYWHEEL_PROJECT_ROOT:-$(pwd)}"
```

The defaults match what Joshua's monorepo currently assumes, so the same scripts work in both source-monorepo mode and public-engine mode without divergence.

### 6.2 The installer must handle pre-existing flywheel state

Lane C §2.4 covers the `settings.json` idempotency case. Lane A §3 risk #11 surfaces a deeper one: many adopters will have **no** `~/.claude/settings.json` and **no** `~/.flywheel/` at install time, but **some** adopters (Joshua, his fleet) already have these in a heavily customized state. The installer needs three branches:

| Pre-state | Installer behavior |
|---|---|
| Fresh — no `~/.flywheel/`, no flywheel hooks in settings.json | Standard install path; create everything. |
| Partial — `~/.flywheel/` exists from a prior install but no hooks registered | Skip directory creation; do hook registration; merge settings.json. |
| Existing — flywheel hooks already in settings.json | Idempotent: detect, skip, log "already installed; use `flywheel update`". |

The detection is by **marker command** (Lane C §2.4): every flywheel hook entry contains `.flywheel/engine/hooks/` in its `command` field. A jq query reliably classifies pre-state.

### 6.3 Tenant-named launchd plists do not ship

Lane A §3 risk #8 calls out that `templates/flywheel-install/launchd/ai.zeststream.<tenant>-coordinator-daemon.plist` (6 files) name specific tenants. The installer **must not** install any tenant-named plist. Instead, it installs a single canonical plist template at `~/.flywheel/templates/launchd/coordinator-daemon.plist.tmpl` with `${TENANT}` and `${BRAND}` placeholders. The user (or `flywheel init`) instantiates one per their actual tenant.

---

## 7. Public repo structure — refined

Lane C §3 tree is adopted with adjustments. Changes:

### 7.1 Add `extraction/` to the source-repo-only meta-directory

Not in the public repo. Lives at `.flywheel/extraction/` in the source monorepo. Contains:
- `de-personalization-table.yaml` (private; the master mapping)
- `classification-runs/<ts>/classification.jsonl` (audit trail)
- `manual-review-queue/<ts>/` (worker scratch)

This is overlay by definition.

### 7.2 Adjust `engine/universal-memory/` size expectation

Lane C §3 says `~/.flywheel/engine/universal-memory/` ships `~30-50 .md`. Lane A measured 11 pure-pattern + ~60-70 engine-after-rewrite. After Mode-B rewrite effort, **realistic v0.2 ship count is 30-40 universal memory rules**. The tree comment is updated accordingly.

### 7.3 Add `examples/redacted-overlay-walkthrough/` (if H3 holds)

If H3 is the working hypothesis, the engine repo's `examples/` directory includes a **link** (not a copy) to the case study on the webpage. The link reads: *"See `flywheel.zeststream.ai/case-studies/flywheel-on-flywheel` for an end-to-end walkthrough of how this engine runs on a real fleet."* The example itself lives on the webpage because its narrative is SMB-trust-building, not developer-pedagogy-building.

### 7.4 Add `.flywheel-protected.json` (PAI-inspired containment-zone declaration)

Lane B §1 / PAI's `.pai-protected.json` is the closest reference for explicit containment-zone documentation. The public engine ships a `.flywheel-protected.json` at repo root that declares which paths in an adopter's environment the engine treats as private:

```json
{
  "$schema": "https://flywheel.zeststream.ai/schemas/protected-v1.json",
  "protected_paths": [
    "~/.flywheel/private/",
    "~/.flywheel/secrets/",
    "<project>/.zs-tenant.yaml",
    "<project>/.beads/"
  ],
  "rationale": "These paths contain operator-specific state, secrets, or local task graphs..."
}
```

The hooks read this file at install time and configure cross-repo write guards accordingly.

### 7.5 Top-level files inventory (final list for B11)

| File | Audience | Length target | Tone |
|---|---|---|---|
| `README.md` | Developers | ~150 lines | Direct; one install command; one paragraph on what flywheel is; clear "next steps" |
| `LICENSE` | All | MIT verbatim | n/a |
| `CHARTER.md` | All | ~100 lines | Mission + values + what flywheel is NOT |
| `CHANGELOG.md` | All | Grows over time | Keep-a-changelog format |
| `CODE_OF_CONDUCT.md` | Contributors | Contributor Covenant v2.1 verbatim | n/a |
| `CONTRIBUTING.md` | Contributors | ~80 lines | DCO sign-off requirement, PR conventions, where to ask questions |
| `SECURITY.md` | Security researchers | ~40 lines | How to report; supported versions; response SLO |
| `install.sh` | All (mechanical) | n/a | Bash; per §6 |
| `uninstall.sh` | All (mechanical) | n/a | Bash; symmetric |

---

## 8. flywheel.zeststream.ai webpage architecture — refined

Lane B §4 + Lane C §4 converge on a Next.js multi-page site. Phase 2 refines audience-routing and CTA discipline.

### 8.1 Which pages and what's on each

| Page | Audience | Purpose | Key content | Conversion target |
|---|---|---|---|---|
| `/` (landing) | Mixed (SMB primary) | Set the frame in 30 seconds | Hero: "AI development that compounds." Three-space frame. Why-this-matters-for-SMBs blocks. Photo + 80-word bio of Joshua. | "Book an AI Assessment" → `/contact` |
| `/what-is-flywheel` | SMB | Explain the methodology without jargon | 9-petal diagram with SMB-translated labels ("intent" not "petal 1"). Cost framing: "we plan first because planning mistakes are cheaper than coding mistakes." Methodology transparency per Lane B §4 (Basecamp pattern). | "Read a case study" → `/case-studies` |
| `/for-developers` | Developer | Bridge to engineering credibility | One paragraph; the github URL; the install command; "if you've used PAI, NTM, beads_rust, flywheel composes ideas from these." | "Read the docs" → `docs.flywheel.zeststream.ai` |
| `/case-studies` | SMB (with developer-grade rigor) | Proof of execution | At v0.2: ONE case study, the redacted-overlay-on-flywheel meta-application (per H3). Quantified metrics: extraction effort, beads shipped, line-of-doctrine ratio, cross-orch incidents resolved. Format per Lane B §4 (SmartBug pattern: industry, challenge, solution, measured result). | "Book an AI Assessment" → `/contact` |
| `/about` | Mixed | Build trust in Joshua personally | Bio: MBA, 12 years ZIRKEL, left ElektraFi 2025-12-31, full ZestStream focus. Why flywheel exists (Joshua's own words, edited). Photo. Direct email. Per Lane B §4 (Cushion / Basecamp pattern: founder-as-product). | "Book an AI Assessment" → `/contact` |
| `/contact` | SMB | The conversion page | Cal.com embed OR form to `chiefzester@gmail.com`. Three intake options: "AI Assessment ($999)" / "Strategy Sprint" / "Full Implementation". Per Lane B §4 (Stripe Atlas pattern: engagement clarity). | Form submission |
| `/install.sh` | Developer (mechanical) | Curl-piped installer | Cloudflare Worker proxy of the github release artifact. | n/a |
| `/install.sh.sha256` | Developer (mechanical) | Companion hash | Static asset; matches the release. | n/a |
| `/docs/` (or `docs.` subdomain) | Developer | Reference manual | Nextra build from the repo's `docs/` directory. | "Try flywheel doctor" → install instructions |

### 8.2 The user journey

**SMB owner journey:** lands on `/` from a referral, ZestStream.ai sidebar, or LinkedIn → scans the hero + three-space frame → reads `/what-is-flywheel` (the explainer) → reads `/case-studies` (the proof) → reads `/about` (the person) → books an Assessment on `/contact`. **5-7 minutes total.**

**Developer journey:** lands on `/for-developers` from a Hacker News post, a tweet, or Joshua's github profile → clicks through to github → reads the README → runs `curl ... | bash` → reads the docs site. **2-3 minutes to first install.**

The two journeys never cross. A developer who lands on `/` and sees commercial copy bounces; a SMB owner who lands on `/for-developers` bounces. The site's job is to route correctly on the first click.

### 8.3 What builds trust at each touchpoint

Per Lane B §4 (SMB-trust signals taxonomy):

| Touchpoint | Trust signal | Lane B reference |
|---|---|---|
| Hero | Direct, specific, no buzzwords ("compounds" is the claim; the rest of the page is the proof) | §4 anti-pattern: vague benefit claims |
| Three-space frame | Methodology transparency (Plan/Bead/Code cost ratios) | §4: Basecamp publishes methodology |
| Case study | Named, quantified, photo if possible | §4: SmartBug + Copyhackers patterns |
| About | Founder visibility + direct email | §4: Cushion + Basecamp patterns |
| Contact | Three engagement tiers with prices/scope | §4: Stripe Atlas pattern |

### 8.4 What does NOT go on the webpage

Per Lane B §4 anti-patterns + the per-surface-consent memory rule (2026-05-11):

- No client names without explicit per-surface consent (Joshua's CLAUDE.md mentions clients; that does not authorize public publication).
- No technical jargon ("bead graph," "NTM dispatch," "robot-tail" all stay on the docs site, not the SMB pages).
- No animations or scrollytelling.
- No "Contact us for pricing" — at minimum a typical-engagement range.
- No anonymous testimonials.

---

## 9. Open Phase-2-decided questions

Lane C §7 surfaced 12 open questions. Phase 2 proposes defaults below. Joshua-decision-required items are flagged.

| # | Question | Phase-2 default | Joshua-decision-required? |
|---|---|---|---|
| 1 | Final repo name and org (`JYeswak/flywheel` vs `zeststream/flywheel`) | **`github.com/JYeswak/flywheel`** — Joshua's directive names it; matches the founder-as-product trust pattern (Lane B §4). | No (default unless Joshua flips) |
| 2 | CLI implementation language (bash vs Rust) | **Bash for v0.2.** Rust is the durable path but doubles the engineering cost for v0.2. Rewrite to Rust at v0.4 if adoption justifies. | No |
| 3 | Docs site host path (subpath vs subdomain) | **Subdomain `docs.flywheel.zeststream.ai`.** Cleaner Nextra deploy; better SEO; isolates docs traffic from commercial. | No |
| 4 | `~/.flywheel/engine/` install via git clone vs tarball | **Tarball.** Simpler; matches PAI's approach; `flywheel update` handles upgrades without users learning git internals. | No |
| 5 | Telemetry stance at v0.2 | **Zero telemetry. README states this explicitly.** Anonymous version-check considered for v0.3 if there's demonstrated demand. | No |
| 6 | Signing approach beyond TLS | **TLS-only at v0.2.** Add minisign at v0.3 if a security-conscious adopter requests it. | No |
| 7 | DCO vs CLA for contributors | **DCO (Developer Certificate of Origin).** Lightweight; standard in the Linux Foundation orbit; doesn't require a contributor agreement signed in advance. | No (mild Joshua-flippable) |
| 8 | CHANGELOG format | **Keep-a-changelog spec.** Human-curated. Conventional-commits-generated is brittle and noisy. | No |
| 9 | What goes in `/case-studies` at v0.2 | **The redacted-overlay-on-flywheel meta-application (per H3).** | **YES** — per the per-surface-consent memory rule, Joshua reviews the redaction before publication. |
| 10 | v0.2 release blocks on webpage live, or repo-first / webpage-at-v0.2.1 | **v0.2 ships repo + webpage together.** The two-audience model breaks if one surface lags. Webpage scope is small enough (6 pages, mostly static) to ship in parallel with engine extraction. | No (mild Joshua-flippable based on calendar) |
| 11 | Pre-1.0 git history rewrite policy | **Pre-1.0 may rewrite via `--force-with-lease` on `main`.** Explicitly stated in CHARTER.md. Adopters know what to expect. Freezes at v1.0. | No |
| 12 | Skill ownership boundary with `~/.claude/skills/` | **v0.2 ships zero ambient skills.** The engine ships the *interface* (skills/ directory layout, SKILL.md schema, sentinel comments). The skillos:1 ratification handoff decides what crosses into the public ecosystem at v0.3. | **YES** — cross-orch coord with skillos:1 |

**Joshua-decision-required summary:** items #9 (case study consent) and #12 (skill boundary with skillos:1). Phase 3 audit should pre-empt both with concrete proposals so Joshua's call is straightforward.

---

## 10. Preliminary bead DAG — refined

Lane C drafted 15 beads. Phase 2 refinements below.

### 10.1 Bead splits identified by Lane A's contamination metrics

Lane C's B3 (Implement de-personalization pass) is currently L-effort. Lane A measured this as 40-60 worker-hours across 5 substrate categories. **B3 splits into 5 per-category beads** so workers can parallelize:

- B3.1 Doctrine sweep (Mode A + Mode B)
- B3.2 L-rule sweep (Mode A dominant)
- B3.3 Memory-rule sweep (Mode A + Mode B + heavy manual-review queue)
- B3.4 Script sweep (Mode A: path parameterization codemod)
- B3.5 Skill + template sweep

Each is L-effort. Total effort budget per Lane A: ~40-60 hours = 4-6 worker-days at sustained parallel pace.

### 10.2 Bead splits identified by Lane B's webpage shape

Lane C's B13 (Build flywheel.zeststream.ai landing page) is L-effort. **B13 splits into 6 per-page beads:**

- B13.1 `/` landing
- B13.2 `/what-is-flywheel`
- B13.3 `/for-developers`
- B13.4 `/case-studies` (Joshua-judged before publish)
- B13.5 `/about`
- B13.6 `/contact` + intake-form-routing

Plus B13.7: deploy + DNS + Cloudflare-Worker for install.sh.

### 10.3 Bead splits identified by Lane C's docs site

Lane C's B12 (Author Nextra docs site under docs/) is L-effort. **B12 splits into 3 per-section beads:**

- B12.1 Docs/getting-started + docs/architecture
- B12.2 Docs/concepts (5 pages: plan-bead-code, trauma-promotion, substrate-classes, cross-orch-protocol, doctor-health-repair)
- B12.3 Docs/reference + docs/guides + docs/about

### 10.4 New beads not in Lane C's draft

- **B0 — Author CHARTER.md draft for Joshua review.** Precedes B1. The charter sets the working hypothesis (H3); Joshua reviews and ratifies before extraction starts. The charter is also the canonical statement of what flywheel is, which the rest of the work executes against.
- **B11.5 — Run case-study redaction pass.** Specifically the H3 redacted-overlay-as-case-study artifact. Heavy Joshua-judged review.
- **B14.5 — Author CHANGELOG.md initial entry.** Document v0.2.0's scope explicitly. Required for Keep-a-changelog compliance.
- **B16 — Skillos cross-orch coordination handoff.** Per item #12 in §9. Outbox to skillos:1 with the engine-skill-boundary proposal.

### 10.5 Refined DAG summary

| ID | Title | Effort | Deps | Pri | Class |
|---|---|---|---|---|---|
| B0 | Author CHARTER.md draft for Joshua review | M | — | P0 | engine |
| B1 | Author de-personalization-table.yaml | M | B0 | P0 | extraction |
| B2 | Implement classification pass | M | B1 | P0 | extraction |
| B3.1 | Doctrine sweep | L | B1, B2 | P0 | extraction |
| B3.2 | L-rule sweep | M | B1, B2 | P0 | extraction |
| B3.3 | Memory-rule sweep | L | B1, B2 | P0 | extraction |
| B3.4 | Script sweep | L | B1, B2 | P0 | extraction |
| B3.5 | Skill + template sweep | M | B1, B2 | P0 | extraction |
| B4 | Implement assembly pass | M | B3.* | P0 | extraction |
| B5 | Author the engine CLI | L | B4 | P0 | engine |
| B6 | Author the installer | L | B5 | P0 | engine |
| B7 | Author the uninstaller | M | B6 | P0 | engine |
| B8 | Author the release pipeline | M | B6 | P0 | infra |
| B9 | Author the smoke-test CI workflow | M | B6, B7 | P0 | infra |
| B10 | Run extraction end-to-end + manual-review queue | L | B3.*, B4 | P0 | extraction |
| B11 | Author public repo top-level files | M | B10 | P0 | engine |
| B11.5 | Run case-study redaction pass (H3) | L | B10 | P0 | content |
| B12.1 | Docs/getting-started + architecture | M | B10, B11 | P1 | docs |
| B12.2 | Docs/concepts (5 pages) | M | B10, B11 | P1 | docs |
| B12.3 | Docs/reference + guides + about | M | B10, B11 | P1 | docs |
| B13.1 | Webpage `/` landing | M | B11 | P1 | webpage |
| B13.2 | Webpage `/what-is-flywheel` | M | B11 | P1 | webpage |
| B13.3 | Webpage `/for-developers` | S | B11 | P1 | webpage |
| B13.4 | Webpage `/case-studies` (uses B11.5) | M | B11.5 | P1 | webpage |
| B13.5 | Webpage `/about` | M | B11 | P1 | webpage |
| B13.6 | Webpage `/contact` + intake routing | M | B11 | P1 | webpage |
| B13.7 | Webpage deploy + DNS + Cloudflare-Worker | M | B13.* | P1 | infra |
| B14 | Wire webpage→github cross-references | S | B12.*, B13.* | P1 | infra |
| B14.5 | Author CHANGELOG.md initial v0.2.0 entry | S | B11 | P0 | engine |
| B15 | Publish v0.2.0 release + Joshua sign-off | M | B8, B9, B10, B11, B12.*, B13.*, B14 | P0 | release |
| B16 | Skillos cross-orch coordination handoff | S | B0 | P0 | coord |

**Total: 31 beads.** Roughly double Lane C's draft, consistent with Lane A's revised effort estimate. Critical path is B0→B1→B2→B3.*→B4→B5→B6→B7→B10→B11→B15. Webpage track (B13.*) and docs track (B12.*) parallelize against B5-B11. Phase 4 DECOMPOSE will produce canonical bead IDs and lock the DAG.

---

## 11. Risk register

Synthesized from Lane A §3 (20 failure modes) + Lane B §4 (anti-patterns) + Lane C §6 (cross-platform considerations). Top 10:

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | De-personalization sweep removes evidentiary force from load-bearing doctrines (Lane A §3 risk #1) | High | High | Mode B pattern-extraction rewrite, not mechanical substitution. Preserve trauma-shape, lose instance metadata. Joshua-judged review on every Mode-B output. |
| 2 | Per-tenant launchd plists (6 files) leak the Joshua-fleet tenant list (Lane A §3 risk #8) | Certain if unhandled | High | Installer ships a single canonical `coordinator-daemon.plist.tmpl` with placeholders. The 6 named plists stay in source repo only. |
| 3 | The H3 case study can't pass the named-client-consent gate (kill condition for H3) | Medium | High (collapses H3 to H1 or H2) | Build the case study around the meta-application (flywheel-on-flywheel) which is consent-free by definition. Client-named studies wait for explicit per-surface consent. |
| 4 | Skillos cross-orch coordination drags B0/B16 into a multi-week negotiation | Medium | Medium | Decouple: v0.2 ships zero ambient skills. The skills/ interface ships, specific skills wait for v0.3. Outbox to skillos:1 happens immediately but doesn't block v0.2. |
| 5 | Installer-smoke CI on macos-14 reveals a path/binary mismatch we don't catch locally | Medium | Medium | Lane C's installer-smoke.yaml runs nightly. macos-14 + ubuntu-22.04 in CI catches almost everything. Joshua's local install is the canonical test for environmental edge cases. |
| 6 | The webpage's case study reads as marketing fluff (Lane B §4 anti-pattern: vague claims) | Medium | High | Case study format follows the SmartBug pattern strictly: industry, challenge, solution, **named metric**. The H3 meta-application supplies the metrics (extraction effort, bead count, doctrines extracted, cross-orch incidents). |
| 7 | Joshua reviews the v0.2 repo and says "this doesn't read as mine" (kill condition for H1, partial kill for H3) | Medium | High | The CHARTER.md (B0) is written by Joshua or under his close supervision. Every Mode-B doctrine rewrite is checkpointed before B10 closes. |
| 8 | The 40-60 hour effort estimate proves optimistic | Medium | Medium | Decompose into per-category beads (B3.1-B3.5) so we measure burn rate against real progress. If Mode B per-file budget exceeds 30 min consistently, raise to Joshua for scope-trimming decision. |
| 9 | The github repo's first impression (README) lands wrong | Medium | High | README written against Lane B §3 patterns (Bun's one-liner; Tailwind's transparent metrics; CrewAI's progressive disclosure). Read by an external developer (not Joshua, not flywheel:1) before launch. |
| 10 | Pre-1.0 history rewrite breaks adopter expectations | Low | Medium | CHARTER.md states the policy explicitly. Adopters of pre-1.0 software accept this by convention. The policy is frozen at v1.0. |

---

## 12. Success criteria (Joshua-judged)

Per Joshua's directive: *"make ourselves and the world truly proud."* Concretize.

### 12.1 "Joshua proud" in the github repo

Five observable criteria:

1. **The README's first 200 words read as Joshua's voice, not generic-AI-tool-marketing.** No "comprehensive," "leveraging," "cutting-edge." Direct sentences; first-person where natural.
2. **The CHARTER.md states what flywheel is NOT** (alongside what it is). The "is NOT" list is concrete and opinionated. ("Flywheel is not a low-code platform. Flywheel is not a replacement for engineering judgment.")
3. **`flywheel doctor` returns 0 on a clean macOS install in under 10 seconds.**
4. **The CI badge on the README is green.** All workflows pass on the v0.2.0 tag.
5. **A developer who is not Joshua, given just the README, gets to `flywheel doctor` exit-0 in under 5 minutes without asking a question.**

### 12.2 "Joshua proud" in the webpage

Five observable criteria:

1. **The hero (`/`) makes the value claim in one sentence under 12 words.** ("AI development that compounds." Or its successor; Joshua-approved.)
2. **The `/case-studies` page contains at least one named, quantified outcome.** Per H3: the flywheel-on-flywheel meta-application with measured metrics.
3. **`/about` features Joshua personally** with a photo + direct email, per the Basecamp / Cushion founder-visibility pattern.
4. **`/contact` lists three engagement tiers with price ranges and scope per tier.** Mirrors the AI Assessment ladder (memory 2026-05-11 north star).
5. **An SMB owner who lands on `/` (with no prior context) can articulate "what Joshua does" within 60 seconds of arriving.** Tested with a real SMB owner before launch (paid 30-min usability test if needed).

### 12.3 The smallest demonstration of success

A single sentence: **"Joshua, on the day of v0.2 launch, posts the github URL and the webpage URL on LinkedIn or to a client, and does not feel embarrassed."** Every Joshua-judged gate composes up to this one criterion. If any gate is failing on launch day, B15 doesn't close.

---

## 13. What this round did NOT decide (for round 2 of REFINE)

- **Per-bead acceptance gate specifics.** Phase 4 DECOMPOSE writes these.
- **Final wording of the README, CHARTER, hero, about-bio.** B0 and B11 author these; Joshua reviews.
- **Final case-study scope (which metrics, which screenshots, which redaction depth).** B11.5 designs this; Joshua signs off per item #9 in §9.
- **Final visual design of the webpage.** B13.* authors; Joshua signs off on visual direction.
- **Whether to invite outside contributors at v0.2 or wait for v0.3.** Open; depends on whether v0.2 launches with a CONTRIBUTING.md that lists "currently not accepting outside contributions" or with the standard open-door language.

These are round-2 REFINE topics or Phase 4 DECOMPOSE topics.

---

## 14. Convergence test for Phase 2 → Phase 3

Phase 3 AUDIT can run when:

- ✓ Hypothesis slate is in STATE.json (3 candidates, exactly one third-alt)
- ✓ Engine/overlay boundary refined with concrete counts per substrate category
- ✓ Extraction pipeline refined with Mode A vs Mode B distinction
- ✓ Installer architecture refined with pre-state branching + tenant-plist handling
- ✓ Public repo structure refined with `.flywheel-protected.json` + extraction meta-directory
- ✓ Webpage architecture refined with two-audience routing + page-by-page conversion logic
- ✓ All 12 of Lane C's open questions have Phase-2 defaults
- ✓ Preliminary bead DAG refined (15 → 31 beads after splits)
- ✓ Risk register present (top 10)
- ✓ Success criteria concretized (Joshua-judged)

All ✓. Phase 2 round 1 complete.

---

*End of 02-REFINE-r1.md. Hand off to Phase 3 AUDIT for adversarial review, or to a Phase-2 round 2 if Joshua wants further refinement before audit.*
