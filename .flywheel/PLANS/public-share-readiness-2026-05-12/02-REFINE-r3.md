# 02-REFINE-r3.md — Converged Plan (Phase 2, Round 3)

**Phase:** 2 REFINE
**Round:** 3
**Author:** flywheel:1 / Phase-2 synthesis lane
**Baseline:** `02-REFINE-r2.md` (577 lines, 2026-05-12T19:15Z)
**Synthesizes:** `01-RESEARCH-A.md`, `01-RESEARCH-B.md`, `01-RESEARCH-C.md`
**Status:** Round-3 refinement. No structural change vs R2. De-slopify + technical-precision pass; §10.7 acceptance table extended to cover every P0 bead.

---

## 1. Executive summary

Extract the universal substrate of the flywheel monorepo to a public MIT-licensed engine at `github.com/JYeswak/flywheel`, and ship a separate SMB-facing landing site at `flywheel.zeststream.ai`. The two surfaces serve different audiences (developers vs SMB owners) toward the same goal: build trust in Joshua, ZestStream, and the work.

The bottleneck is not architecture — Lane C's four-phase extraction pipeline is sound — but de-personalization scope. Lane A measured 50% of scripts hardcoding `/Users/josh`, 64% of doctrines naming a specific client, and 11 of 183 memory rules surviving the strict pure-pattern filter. Realistic extraction effort is **40-60 worker-hours** (Lane A §5.1), 3-5× the original CLASSIFICATION-PLAYBOOK estimate.

We recommend hypothesis **H3 (engine + redacted-overlay-as-case-study)**: ship a real engine for developers AND a redacted-but-real version of Joshua's overlay as the flagship case study. H4 (repo-only, defer page) and H5 (page-first, scaffold repo) were considered and rejected — each breaks the two-audience model Joshua named at 17:00Z.

---

## 2. The two-audience model

Joshua's directive (2026-05-12T~17:00Z, INTENT §Joshua's directive): *"The git repo's audience is fellow developers... our audience for the webpage is SMB clients — both are designed to build trust in me, our brand, and our work."*

The two surfaces serve different decision-shapes:

| Surface | Audience | Decision they're making | Trust-building shape |
|---|---|---|---|
| `github.com/JYeswak/flywheel` | Developers, architects, AI-tooling tinkerers | "Is this engineering serious enough to study, copy, or contribute to?" | Code quality, tests, docs, transparent metrics, opinionated methodology |
| `flywheel.zeststream.ai` | SMB owners, prospective ZestStream consulting clients | "Is this person someone I'd hire to fix my AI strategy?" | Founder visibility, named case studies, engagement clarity, quantified outcomes |

### What goes in the github repo

- The engine itself (extracted, de-personalized, installable)
- A `README.md` aimed at developers (5-minute overview + install command)
- A `CHARTER.md` declaring what flywheel is and is NOT
- Doctrine, L-rules, and universal memory rules (the intellectual contribution)
- Hooks, scripts, templates (the operational substrate)
- A Nextra docs site at `docs/` (the reference manual)
- Examples, tests, CI workflows (the proof of seriousness)
- `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` (table-stakes)

### What goes on the webpage

- A landing page that names the value claim in one breath
- A `/what-is-flywheel` page that explains the three reasoning spaces in SMB language
- A `/for-developers` page that bridges to github (short; not the main path)
- A `/case-studies` page with at least one real case study (per H3, the redacted-Joshua-overlay-as-meta-case-study)
- An `/about` page featuring Joshua personally (MBA, 12 years ZIRKEL, current ZestStream focus)
- A `/contact` page with three engagement tiers (mirrors the AI Assessment ladder)
- The proxied install endpoint `/install.sh` and `/install.sh.sha256`

### How they reinforce each other

- The webpage's `/for-developers` links to the github repo as proof-of-engineering-substance.
- The github repo's `README.md` links to the webpage as the project's official home.
- The case study on `/case-studies` is *the meta-application*: "here is how we used flywheel to extract flywheel." A developer reads it and sees engineering rigor; an SMB owner reads it and sees demonstrated execution.
- Both surfaces feature Joshua personally. Commits are signed under his name; the webpage carries his photo and bio. The shared signal: this is one person's serious work, not a vendor brand.

---

## 3. Hypothesis slate

R1 carried three hypotheses. R2 evaluated two additional candidates (H4, H5) suggested by the stress-test prompt, then narrowed.

| ID | Strategy | Kill condition | Third alt? |
|---|---|---|---|
| **H1** | **Aggressive extraction (maximal engine).** Extract 70-80% of current substrate as engine. Spend 40-60 worker-hours on de-personalization. Ship a v0.2 covering doctrine + L-rules + memory + scripts + hooks + templates + skills. | Any single category exceeds 30 worker-hours OR any de-personalization sweep produces an artifact that fails Joshua's "would I direct a developer to this?" review. | no |
| **H2** | **Minimal extraction (thin engine).** Extract only the 11 pure-pattern memory rules + ~25 engine-class doctrines + 4 canonical hooks + the install scaffold. Ship minimal but solid v0.2. Iterate to v0.3/v0.4 as adopters request expansion. | Adopters' first-week feedback says "this doesn't have enough substance to be useful" OR Joshua reviews and says "this isn't proud-worthy yet." | no |
| **H3** | **Engine + redacted-overlay-as-case-study (both-and).** Publish the engine at developer-ready depth (~40 engine doctrines + 70 L-rules + 4 canonical hooks + ~80 scripts + ~30 memory rules + install scaffold) AND publish a redacted-but-real version of Joshua's overlay as the flagship case study on `flywheel.zeststream.ai/case-studies`. The engine builds developer trust; the case study builds SMB trust. | The redaction sweep on the overlay-as-case-study reveals so much real client data that even with redaction it can't pass the per-client consent gate within the v0.2 window, AND the engine-without-case-study fails the SMB-trust bar (no named outcomes). | **yes** |

**H4 and H5 (R2 evaluation, retained):**

- **H4 — Repo-only ship, defer webpage.** Github engine ships at v0.2; `flywheel.zeststream.ai` is a single placeholder page pointing at the repo until v0.3+. **Rejected.** It violates the 17:00Z directive ("our audience for the webpage is SMB clients"). The SMB-trust signal feeds the consulting pipeline; deferring it costs ZestStream's commercial north star (memory 2026-05-11) several months of pipeline. A small but real webpage ships in parallel.
- **H5 — Webpage-first, engine scaffolded.** `flywheel.zeststream.ai` ships as a real SMB landing page now; the github repo stays a skeleton until extraction completes in v0.3. **Rejected.** It violates Joshua's 17:00Z correction ("The goal is not to publish some documents, it is to actually publish the entire flywheel"). A webpage pointing at a non-functional repo destroys developer trust and reads as marketing without product.

H4 and H5 are recorded so Phase 3 can verify the rejection holds. They are not in the working slate.

**Recommendation: H3 remains the working hypothesis.** It threads Joshua's directive ("make ourselves and the world truly proud"): engineering credibility (engine) plus demonstrated execution (case study). H1 alone risks documentation without proof. H2 alone reads as a toy. H3 is the only candidate that uses Joshua's existing fleet as substrate while respecting the per-surface-consent and class-divergence memory rules.

**Strongest argument against H3 (R2 stress-test, retained):** the kill condition rests on the redaction sweep passing the per-client consent gate. R1 said "the meta-case-study is consent-free by definition" — but that assumes the meta-narrative ("flywheel used to extract flywheel") can be told without naming the clients whose work passed through Joshua's fleet during the extraction window. Verified: the meta-case-study can be told using only operator-side metrics (extraction worker-hours, bead-graph counts, doctrine line totals, cross-orch incidents) with **zero client name references**. The kill-condition is observable: B11.5's redaction-pass output is `grep`-able for any name from `de-personalization-table.yaml`'s client column. Detection budget: ≤30 minutes per draft, run during the B11.5 bead's verify step. If grep returns non-empty after redaction, B11.5 fails and Joshua decides whether to (a) reshape the case study to remove the named-client surface, or (b) collect per-client consent before publishing.

---

## 4. Engine/overlay boundary — refined

### 4.1 What the lanes converge on

Lane A's classification work (§1-2) + Lane C's substrate-rule table (§1.4) + Lane B's PAI containment-zone pattern (§1) agree on a tri-class taxonomy:

- **Engine** — universally valuable; ships verbatim or with mechanical projection (`Joshua → {operator}`).
- **Engine-after-rewrite** — the pattern is universal but the artifact references specific clients, dates, or orchs; needs substantive (not mechanical) rewrite to publish.
- **Overlay** — load-bearing content IS the instance; ships nowhere public.

Lane A measured each category. Lane C named the codemod. Lane B observed that PAI handles the same split through explicit `.pai-protected.json` containment zones.

### 4.2 Concrete counts (from Lane A §0)

| Substrate category | Total | Engine | Engine-after-rewrite | Overlay | Rewrite effort (worker-hours) |
|---|---:|---:|---:|---:|---:|
| Doctrine (`.flywheel/doctrine/*.md`) | 94 | ~25 | ~50 | ~15-19 | 12-15 |
| L-rules (`.flywheel/rules/L*.md`) | 109 | ~70 | ~30 | ~10 | 6-8 |
| Memory rules (`.../memory/*.md`) | 183 | 11 | ~60-70 | ~100+ | 8-12 |
| Scripts (`.flywheel/scripts/*.{sh,py}`) | 394 | ~80 | ~200 | ~115 | 10-15 |
| Hooks (canonical only) | 4 | 4 | 0 | 0 | <1 |
| Templates (`templates/flywheel-install/*`) | 62 | ~30 | ~25 | ~7 | 2-3 |
| Flywheel-namespaced skills | ~6 + subtree | ~2 | ~3 | ~1 | 4-6 (+skillos coord) |
| AGENTS.md substrate | 4 | 1 (canonical) | 1 (template) | 2 | 1 |

**Engine-after-rewrite is the dominant work category.** ~370 artifacts need substantive rewrite, not mechanical substitution. That arithmetic anchors the 40-60 worker-hour estimate.

### 4.3 The boundary is achievable but not mechanical

Lane A §5.1: *"Mechanical sweep is insufficient — substantial pattern-extraction rewrites are required for the high-value engine artifacts."* The CLASSIFICATION-PLAYBOOK's four-question filter triages correctly, but rewriting an `engine-after-rewrite` artifact that uses load-bearing client examples means preserving the trauma-shape while losing the instance metadata. That is authorial judgment, not codemod work.

**Implication for the extraction pipeline:** Lane C's Phase 2 (DE-PERSONALIZE) splits into two sub-modes:

- **Mode A — codemod sweep** for files where the de-personalization-table substitution is sufficient (most L-rules, most scripts, many memory rules).
- **Mode B — pattern-extraction rewrite** for files where the example must be abstracted while preserving evidentiary force (most engine-after-rewrite doctrines, some L-rules, the high-value memory rules).

Mode A is one worker-hour for hundreds of files. Mode B is 15-30 minutes per file across ~80-100 files. The arithmetic resolves to 40-60 worker-hours total.

### 4.4 Two-repo vs one-repo decision

Lane A §5.3: is the public artifact one repo (engine) or two (engine + overlay-example)?

**Phase-2 default: ONE repo.** Joshua's directive names `github.com/JYeswak/flywheel`. Two repos double maintenance burden and dilute the "study this one thing" signal. The case study (per H3) lives on the webpage, not in a second repo. If H3's case study proves so substantive that adopters want to fork it as a starting overlay, a `flywheel-overlay-template/` repo gets created at v0.3.

### 4.5 Flywheel↔skillos boundary

Lane A §5.2 names the unresolved cross-repo question: JSM, skill-builder, agent-mail, and the canonical-CLI-scoping skills — are they flywheel-publishable or skillos-canonical?

**Phase-2 default: defer skill substrate to v0.3.** v0.2 ships zero ambient skills. The engine ships the *interface* (skills/ directory layout, SKILL.md format, sentinel-comment conventions) but no specific skills beyond the flywheel-namespaced ones that survive de-personalization (~2 engine + ~3 engine-after-rewrite). The skillos:1 ratification handoff (initiated 2026-05-11) decides which skillos-owned skills enter the public ecosystem at v0.3 and which stay private.

---

## 5. Extraction pipeline — refined

Lane C's 4-phase pipeline (CLASSIFY → DE-PERSONALIZE → ASSEMBLE → VERIFY) is structurally sound. Refinements below sharpen each phase.

### 5.1 The classification mechanism — hybrid, not codemod alone

**Classifier is a Python script** at `scripts/classify.py` that emits `classification.jsonl`. Per-file classification rule:

```python
def classify(path, content):
    if any(pattern.search(content) for pattern in OVERLAY_PATTERNS):
        return ("overlay", "matches_overlay_pattern")
    if pure_pattern_filter(content):  # no proper noun, no date, no path more specific than ~/Developer/
        return ("engine", "passes_pure_pattern_filter")
    if mechanically_projectable(content, DEPERSONALIZATION_TABLE):
        return ("engine_after_rewrite", "mode_a_codemod_sufficient")
    return ("engine_after_rewrite", "mode_b_pattern_rewrite_required")
```

The classifier errors on the side of `engine_after_rewrite` rather than `engine`. Every `engine` classification gets `manual_review_recommended: true` if it scores below a confidence threshold. Joshua + flywheel:1 review the borderline cases.

### 5.2 The de-personalization codemod — table-driven

Lane C §1.5 sketches `de_personalization_table.yaml`. Refinements:

- **The table itself is engine-class** — it ships in the public repo at `scripts/de-personalization-table.example.yaml` so adopters can build their own.
- **The table is monorepo-only** in the form that contains Joshua's actual private mappings. That copy lives at `.flywheel/extraction/de-personalization-table.yaml` and is `.gitignore`d in the public repo.
- **Substitution is whole-token, not substring.** Naive substring substitution replaces "Joshua" inside `joshuanowak.com` as `.com`. Use word-boundary regex (`\bJoshua\b`) or AST-aware substitution for markdown.
- **The table carries audit metadata.** Each entry records "first observed in <file>" so Joshua reviews privacy implications before extraction.

The codemod is a real tool, not a script gloss. **It is its own bead (B1.5, new in R2)** — see §10.4.

### 5.3 The verification step — what "successful extraction" means

Lane C §1.8 lists the smoke-test checks. R2 added the **Joshua-judged success criterion** per Joshua's INTENT directive:

- **Engineering-objective gates** (Lane C's smoke test): install on fresh macOS works, doctor returns 0, uninstall byte-equality holds, CI green on macOS + Ubuntu.
- **Joshua-judged gates:**
  - Joshua reads the README and says "I'd direct a developer here."
  - Joshua reads the CHARTER and says "this reads as mine, not as generic substrate."
  - Joshua opens 10 random engine doctrines/L-rules/memory rules and finds zero client-name leaks.
  - Joshua reviews the manual-review queue from extraction and signs off on every entry.

The Joshua-judged gates are a B15 acceptance criterion, not a continuous CI check.

### 5.4 Reversibility — strict, with one nuance

Lane C §1.7 declares extraction strictly additive (never modifies source). R2 added: **the source repo's `.flywheel/extraction/` directory accumulates `classification.jsonl` + manual-review notes from each extraction run**, dated by run timestamp. These are overlay-class (they reference real client names) and stay in the monorepo. The accumulation is the audit trail; if a future extraction misclassifies a file, prior-run notes show the history.

If H3 is killed and the plan falls back to H1 or H2, the working extraction trees are removed and the table is updated. The source repo is untouched.

### 5.5 Pre-launch demonstration smoke test

Joshua personally verifies the engine on a fresh-installed laptop before public announcement. Concrete script:

1. Open a clean macOS user account (or a fresh `tart` VM with macOS-14, or a clean Linux Docker container).
2. Run the one-liner: `curl -fsSL https://flywheel.zeststream.ai/install.sh | bash`.
3. Confirm installer exit code is 0 and the installer prints an idempotency message on a second run.
4. Run `flywheel doctor`. Confirm exit code 0 within 10 seconds.
5. Run `flywheel init --tenant test-tenant`. Confirm `.flywheel/` and `.zs-tenant.yaml` are created in the current directory.
6. Run `flywheel uninstall --dry-run` then `flywheel uninstall --confirm`. Confirm byte-equality with pre-install state via `git status`.
7. Read the README aloud. Confirm no "comprehensive," "leveraging," "cutting-edge," or other banned phrases.
8. Open the github repo in a browser. Confirm the README renders cleanly, the LICENSE is visible, and the CI badge is green on `main`.

This is the B15-bead's last sub-check before Joshua's go/no-go on v0.2 announce. Budget: ≤30 minutes.

---

## 6. Installer architecture — refined

Lane C §2 is detailed and largely correct. Two refinements driven by Lane A's findings:

### 6.1 Path parameterization is a contract, not a substitution

Lane A §3 risk #4: parameterizing `/Users/josh/.local/bin/ntm` to `$NTM_BIN` is a contract change. Existing flywheel installations do not have `$NTM_BIN` set. **Refinement:** every parameterized path ships with a hardcoded default that preserves the original behavior on Joshua's machine:

```bash
NTM_BIN="${NTM_BIN:-$HOME/.local/bin/ntm}"
FLYWHEEL_ENGINE_ROOT="${FLYWHEEL_ENGINE_ROOT:-$HOME/.flywheel/engine}"
FLYWHEEL_PROJECT_ROOT="${FLYWHEEL_PROJECT_ROOT:-$(pwd)}"
```

The defaults match what Joshua's monorepo currently assumes, so the same scripts work in source-monorepo mode and public-engine mode without divergence.

### 6.2 The installer must handle pre-existing flywheel state

Lane C §2.4 covers the `settings.json` idempotency case. Lane A §3 risk #11: most adopters have no `~/.claude/settings.json` and no `~/.flywheel/` at install time; Joshua's fleet already has both in a heavily customized state. The installer needs three branches:

| Pre-state | Installer behavior |
|---|---|
| Fresh — no `~/.flywheel/`, no flywheel hooks in `settings.json` | Standard install path; create everything. |
| Partial — `~/.flywheel/` exists from a prior install but no hooks registered | Skip directory creation; do hook registration; merge `settings.json`. |
| Existing — flywheel hooks already in `settings.json` | Idempotent: detect, skip, log "already installed; use `flywheel update`". |

Detection uses a **marker command** (Lane C §2.4): every flywheel hook entry contains `.flywheel/engine/hooks/` in its `command` field. A `jq` query classifies pre-state reliably.

### 6.3 Tenant-named launchd plists do not ship

Lane A §3 risk #8: `templates/flywheel-install/launchd/ai.zeststream.<tenant>-coordinator-daemon.plist` (6 files) name specific tenants. The installer **must not** install any tenant-named plist. It installs a single canonical plist template at `~/.flywheel/templates/launchd/coordinator-daemon.plist.tmpl` with `${TENANT}` and `${BRAND}` placeholders. The user (or `flywheel init`) instantiates one per their actual tenant.

---

## 7. Public repo structure — refined

Lane C §3 tree is adopted with adjustments.

### 7.1 Add `extraction/` to the source-repo-only meta-directory

Not in the public repo. Lives at `.flywheel/extraction/` in the source monorepo. Contains:
- `de-personalization-table.yaml` (private; the master mapping)
- `classification-runs/<ts>/classification.jsonl` (audit trail)
- `manual-review-queue/<ts>/` (worker scratch)

This is overlay by definition.

### 7.2 Adjust `engine/universal-memory/` size expectation

Lane C §3 said `~/.flywheel/engine/universal-memory/` ships `~30-50 .md`. Lane A measured 11 pure-pattern + ~60-70 engine-after-rewrite. After Mode-B rewrite effort, **realistic v0.2 ship count is 30-40 universal memory rules**. The tree comment is updated accordingly.

### 7.3 Add `examples/redacted-overlay-walkthrough/` (if H3 holds)

If H3 is the working hypothesis, the engine repo's `examples/` directory includes a **link** (not a copy) to the case study on the webpage: *"See `flywheel.zeststream.ai/case-studies/flywheel-on-flywheel` for an end-to-end walkthrough of how this engine runs on a real fleet."* The example lives on the webpage because its narrative is SMB-trust-building, not developer-pedagogy-building.

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
| `README.md` | Developers | ~150 lines | Direct; one install command; one paragraph on what flywheel is; clear next steps |
| `LICENSE` | All | MIT verbatim | n/a |
| `CHARTER.md` | All | ~100 lines | Mission + values + what flywheel is NOT |
| `CHANGELOG.md` | All | Grows over time | Keep-a-changelog format |
| `CODE_OF_CONDUCT.md` | Contributors | Contributor Covenant v2.1 verbatim | n/a |
| `CONTRIBUTING.md` | Contributors | ~80 lines | DCO sign-off requirement, PR conventions, where to ask questions |
| `SECURITY.md` | Security researchers | ~40 lines | How to report; supported versions; response SLO |
| `install.sh` | All (mechanical) | n/a | Bash; per §6 |
| `uninstall.sh` | All (mechanical) | n/a | Bash; symmetric |

### 7.6 CI workflow

The public engine repo ships `.github/workflows/` containing three workflows:

| Workflow | Trigger | Jobs | Time budget |
|---|---|---|---|
| `ci.yml` | every push to `main`, every PR | shellcheck on `*.sh`, `ruff check` on `*.py`, markdownlint on `*.md`, schema-validate `.flywheel-protected.json` | ≤3 min |
| `installer-smoke.yml` | every PR, nightly cron at 09:00 UTC | matrix on `{macos-14, ubuntu-22.04}` × `{bash 4, bash 5}`: install → doctor → uninstall → byte-equality check | ≤8 min per leg |
| `release.yml` | tag push matching `v[0-9]+.[0-9]+.[0-9]+` | build release tarball, generate SHA256, sign with `gh attest`, publish github release | ≤5 min |

All three workflows are required for the `main` branch protection rule. The README's CI badge tracks `ci.yml`.

---

## 8. flywheel.zeststream.ai webpage architecture — refined

Lane B §4 + Lane C §4 converge on a Next.js multi-page site. R2 retained R1's structure and tightened the page table; R3 keeps it.

### 8.1 Which pages and what's on each

| Page | Audience | Purpose | Key content | Conversion target |
|---|---|---|---|---|
| `/` (landing) | Mixed (SMB primary) | Set the frame in 30 seconds | Hero: "AI development that compounds." Three-space frame. Why-this-matters-for-SMBs blocks. Photo + 80-word bio of Joshua. | "Book an AI Assessment" → `/contact` |
| `/what-is-flywheel` | SMB | Explain the methodology without jargon | 9-petal diagram with SMB-translated labels ("intent" not "petal 1"). Cost framing: "we plan first because planning mistakes are cheaper than coding mistakes." Methodology transparency per Lane B §4 (Basecamp pattern). | "Read a case study" → `/case-studies` |
| `/for-developers` | Developer | Bridge to engineering credibility | One paragraph; the github URL; the install command; "if you've used PAI, NTM, beads_rust, flywheel composes ideas from these." | "Read the docs" → `docs.flywheel.zeststream.ai` |
| `/case-studies` | SMB (with developer-grade rigor) | Proof of execution | At v0.2: ONE case study, the redacted-overlay-on-flywheel meta-application (per H3). Metrics: extraction worker-hours, beads shipped, line-of-doctrine ratio, cross-orch incidents resolved. Format per Lane B §4 (SmartBug pattern: industry, challenge, solution, measured result). | "Book an AI Assessment" → `/contact` |
| `/about` | Mixed | Build trust in Joshua personally | Bio: MBA, 12 years ZIRKEL, left ElektraFi 2025-12-31, full ZestStream focus. Why flywheel exists (Joshua's own words, edited). Photo. Direct email. Per Lane B §4 (Cushion / Basecamp pattern: founder-as-product). | "Book an AI Assessment" → `/contact` |
| `/contact` | SMB | The conversion page | Cal.com embed or form to `chiefzester@gmail.com`. Three intake options: "AI Assessment ($999)" / "Strategy Sprint" / "Full Implementation". Per Lane B §4 (Stripe Atlas pattern). | Form submission |
| `/install.sh` | Developer (mechanical) | Curl-piped installer | Cloudflare Worker proxy of the github release artifact. | n/a |
| `/install.sh.sha256` | Developer (mechanical) | Companion hash | Static asset; matches the release. | n/a |
| `/docs/` (or `docs.` subdomain) | Developer | Reference manual | Nextra build from the repo's `docs/` directory. | "Try flywheel doctor" → install instructions |

### 8.2 The user journey

**SMB owner journey:** lands on `/` from a referral, ZestStream.ai sidebar, or LinkedIn → scans the hero + three-space frame → reads `/what-is-flywheel` (the explainer) → reads `/case-studies` (the proof) → reads `/about` (the person) → books an Assessment on `/contact`. **5-7 minutes total.**

**Developer journey:** lands on `/for-developers` from a Hacker News post, a tweet, or Joshua's github profile → clicks through to github → reads the README → runs `curl ... | bash` → reads the docs site. **2-3 minutes to first install.**

The two journeys never cross. A developer who lands on `/` and sees commercial copy bounces; an SMB owner who lands on `/for-developers` bounces. The site's job is to route correctly on the first click.

### 8.3 What builds trust at each touchpoint

Per Lane B §4 (SMB-trust signals taxonomy):

| Touchpoint | Trust signal | Lane B reference |
|---|---|---|
| Hero | Direct, specific, no buzzwords | §4 anti-pattern: vague benefit claims |
| Three-space frame | Methodology transparency (Plan/Bead/Code cost ratios) | §4: Basecamp publishes methodology |
| Case study | Named, quantified, photo if possible | §4: SmartBug + Copyhackers patterns |
| About | Founder visibility + direct email | §4: Cushion + Basecamp patterns |
| Contact | Three engagement tiers with prices/scope | §4: Stripe Atlas pattern |

### 8.4 What does NOT go on the webpage

Per Lane B §4 anti-patterns + the per-surface-consent memory rule (2026-05-11):

- No client names without explicit per-surface consent. (Joshua's CLAUDE.md mentions clients; that does not authorize public publication.)
- No technical jargon ("bead graph," "NTM dispatch," "robot-tail" stay on the docs site).
- No animations or scrollytelling.
- No "Contact us for pricing" — at minimum a typical-engagement range.
- No anonymous testimonials.

---

## 9. Open Phase-2-decided questions

Lane C §7 surfaced 12 open questions. R1 proposed defaults; R2 retained them; R3 retains them. Joshua-decision-required items are flagged.

| # | Question | Phase-2 default | Joshua-decision-required? |
|---|---|---|---|
| 1 | Final repo name and org | **`github.com/JYeswak/flywheel`** — Joshua's directive names it; matches the founder-as-product trust pattern (Lane B §4). Alternative `github.com/JYeswak/zeststream-flywheel` rejected: doubles the name length, adds "zeststream" branding to a methodology that is intentionally portable across operators. | **YES** — Joshua to confirm `JYeswak/flywheel` before B0 starts |
| 2 | CLI implementation language (bash vs Rust) | **Bash for v0.2.** Rust is the durable path but doubles the engineering cost for v0.2. Rewrite to Rust at v0.4 if adoption justifies. | No |
| 3 | Docs site host path (subpath vs subdomain) | **Subdomain `docs.flywheel.zeststream.ai`.** Cleaner Nextra deploy; better SEO; isolates docs traffic from commercial. | No |
| 4 | `~/.flywheel/engine/` install via git clone vs tarball | **Tarball.** Simpler; matches PAI's approach; `flywheel update` handles upgrades without users learning git internals. | No |
| 5 | Telemetry stance at v0.2 | **Zero telemetry. README states this explicitly.** Anonymous version-check considered for v0.3 if there is demonstrated demand. | No |
| 6 | Signing approach beyond TLS | **TLS-only at v0.2.** Add minisign at v0.3 if a security-conscious adopter requests it. | No |
| 7 | DCO vs CLA for contributors | **DCO (Developer Certificate of Origin).** Lightweight; standard in the Linux Foundation orbit; no contributor agreement signed in advance. Contributors add `Signed-off-by:` to each commit; the PR template includes a DCO checkbox. | No (Joshua-flippable; default proposed in R2) |
| 8 | CHANGELOG format | **Keep-a-changelog spec.** Human-curated. Conventional-commits-generated is brittle and noisy. | No |
| 9 | What goes in `/case-studies` at v0.2 | **The redacted-overlay-on-flywheel meta-application (per H3).** | **YES** — per the per-surface-consent memory rule, Joshua reviews the redaction before publication. |
| 10 | v0.2 release blocks on webpage live, or repo-first / webpage-at-v0.2.1 | **v0.2 ships repo + webpage together.** The two-audience model breaks if one surface lags. Webpage scope is small enough (6 pages, mostly static) to ship in parallel with engine extraction. | No (mild Joshua-flippable based on calendar) |
| 11 | Pre-1.0 git history rewrite policy | **Pre-1.0 may rewrite via `--force-with-lease` on `main`.** Stated in CHARTER.md. Adopters know what to expect. Freezes at v1.0. | No |
| 12 | Skill ownership boundary with `~/.claude/skills/` | **v0.2 ships zero ambient skills.** The engine ships the *interface* (skills/ directory layout, SKILL.md schema, sentinel comments). The skillos:1 ratification handoff decides what crosses into the public ecosystem at v0.3. | **YES** — cross-orch coord with skillos:1 |

**Joshua-decision-required summary:** items #1 (repo name), #9 (case-study consent), and #12 (skill boundary with skillos:1). Phase 3 audit should pre-empt these with concrete proposals so Joshua's call is straightforward.

### 9.1 First-adopter story

Lane B emphasized "named case studies + quantified outcomes." Beyond the meta-case-study (flywheel-on-flywheel), is there one real adopter we can recruit pre-launch for a v0.2.1 case study?

**R2 proposal (retained): ship v0.2 with the meta-case-study only. Recruit one external adopter during the v0.2→v0.2.1 window (target: 30 days post-launch).** Reasoning:
- The meta-case-study supplies named, quantified outcomes (Joshua + flywheel:1 are named operators; the metrics are real).
- Recruiting an external adopter pre-launch adds 2-4 weeks of calendar lag for relationship-building, redaction negotiation, and consent capture. That lag pushes v0.2 past the commercial-pipeline window Joshua named.
- Post-launch recruitment uses v0.2 itself as the credibility instrument — easier ask, faster yield.

Joshua-decision-required: yes, but mild — Joshua can flip to "delay v0.2 to land an external adopter" if a candidate surfaces between R2 and Phase 5.

---

## 10. Preliminary bead DAG — refined

Lane C drafted 15 beads. R1 expanded to 31. R2 added two (B1.5 codemod, B17 pre-launch smoke test). R3 keeps the count at 33 and extends §10.7 to cover every P0 bead.

### 10.1 Bead splits identified by Lane A's contamination metrics

Lane C's B3 (Implement de-personalization pass) was L-effort. Lane A measured 40-60 worker-hours across 5 substrate categories. **B3 splits into 5 per-category beads** so workers can parallelize:

- B3.1 Doctrine sweep (Mode A + Mode B): 12-15 worker-hours
- B3.2 L-rule sweep (Mode A dominant): 6-8 worker-hours
- B3.3 Memory-rule sweep (Mode A + Mode B + heavy manual-review queue): 8-12 worker-hours
- B3.4 Script sweep (Mode A: path parameterization codemod): 10-15 worker-hours
- B3.5 Skill + template sweep: 4-6 worker-hours

Each fits within L (≤16 worker-hours). B3.4 sits at the upper L bound; R2 reviewed whether to split further by subcategory (`scripts/secrets/*`, `scripts/audits/*`, `scripts/doctor/*`) and decided **no** — the codemod is uniform across subcategories, and a single worker can sweep them in one pass once the codemod (B1.5) is built. If B3.4 exceeds 15 worker-hours in execution, Phase 4 DECOMPOSE splits it then.

### 10.2 Bead splits identified by Lane B's webpage shape

Lane C's B13 (Build flywheel.zeststream.ai landing page) was L-effort. **B13 splits into 6 per-page beads plus deploy:**

- B13.1 `/` landing
- B13.2 `/what-is-flywheel`
- B13.3 `/for-developers`
- B13.4 `/case-studies` (Joshua-judged before publish)
- B13.5 `/about`
- B13.6 `/contact` + intake-form-routing
- B13.7 Deploy + DNS + Cloudflare-Worker for `install.sh`

### 10.3 Bead splits identified by Lane C's docs site

Lane C's B12 (Author Nextra docs site under `docs/`) was L-effort. **B12 splits into 3 per-section beads:**

- B12.1 docs/getting-started + docs/architecture
- B12.2 docs/concepts (5 pages: plan-bead-code, trauma-promotion, substrate-classes, cross-orch-protocol, doctor-health-repair)
- B12.3 docs/reference + docs/guides + docs/about

### 10.4 New beads added in R2

- **B1.5 — Build the de-personalization codemod (`scripts/depersonalize.py`).** Was implicit in R1. The codemod is a real tool: word-boundary token substitution, markdown-AST aware, table-driven, dry-run-default. It runs as B3.*'s primary instrument. M-effort.
- **B17 — Pre-launch smoke test on a fresh laptop** (per §5.5). Run by Joshua personally before B15 closes. S-effort (≤30 minutes).

### 10.5 Beads retained from R1

- **B0 — Author CHARTER.md draft for Joshua review.** Precedes B1.
- **B11.5 — Run case-study redaction pass.** The H3 redacted-overlay-as-case-study artifact.
- **B14.5 — Author CHANGELOG.md initial entry** for v0.2.0.
- **B16 — Skillos cross-orch coordination handoff.**

### 10.6 Refined DAG summary

| ID | Title | Effort | Deps | Pri | Class |
|---|---|---|---|---|---|
| B0 | Author CHARTER.md draft for Joshua review | M | — | P0 | engine |
| B1 | Author de-personalization-table.yaml | M | B0 | P0 | extraction |
| B1.5 | Build the de-personalization codemod (`scripts/depersonalize.py`) | M | B1 | P0 | extraction |
| B2 | Implement classification pass | M | B1 | P0 | extraction |
| B3.1 | Doctrine sweep | L (12-15h) | B1, B1.5, B2 | P0 | extraction |
| B3.2 | L-rule sweep | M (6-8h) | B1, B1.5, B2 | P0 | extraction |
| B3.3 | Memory-rule sweep | L (8-12h) | B1, B1.5, B2 | P0 | extraction |
| B3.4 | Script sweep | L (10-15h) | B1, B1.5, B2 | P0 | extraction |
| B3.5 | Skill + template sweep | M (4-6h) | B1, B1.5, B2 | P0 | extraction |
| B4 | Implement assembly pass | M | B3.* | P0 | extraction |
| B5 | Author the engine CLI | L | B4 | P0 | engine |
| B6 | Author the installer | L | B5 | P0 | engine |
| B7 | Author the uninstaller | M | B6 | P0 | engine |
| B8 | Author the release pipeline (`release.yml`) | M | B6 | P0 | infra |
| B9 | Author the CI workflows (`ci.yml` + `installer-smoke.yml`) | M | B6, B7 | P0 | infra |
| B10 | Run extraction end-to-end + manual-review queue | L | B3.*, B4 | P0 | extraction |
| B11 | Author public repo top-level files (incl. DCO in CONTRIBUTING.md) | M | B10 | P0 | engine |
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
| B14 | Wire webpage↔github cross-references | S | B12.*, B13.* | P1 | infra |
| B14.5 | Author CHANGELOG.md initial v0.2.0 entry | S | B11 | P0 | engine |
| B15 | Publish v0.2.0 release + Joshua sign-off | M | B8, B9, B10, B11, B12.*, B13.*, B14, B17 | P0 | release |
| B16 | Skillos cross-orch coordination handoff | S | B0 | P0 | coord |
| B17 | Pre-launch smoke test on fresh laptop | S (≤30 min) | B11, B12.*, B13.7 | P0 | release |

**Total: 33 beads.** Critical path is B0→B1→B1.5→B2→B3.*→B4→B5→B6→B7→B10→B11→B17→B15. Webpage track (B13.*) and docs track (B12.*) parallelize against B5-B11. Phase 4 DECOMPOSE produces canonical bead IDs and locks the DAG.

### 10.7 Acceptance-criterion sharpening

Every P0 bead now has an **observable, single-axis** acceptance criterion (a script, grep, or exit-code check can verify it; no compound "and" gates):

| Bead | Observable acceptance |
|---|---|
| B0 | `CHARTER.md` exists at repo root and Joshua has appended a `Reviewed-by: Joshua Nowak <chiefzester@gmail.com>` trailer to its commit |
| B1 | `de-personalization-table.yaml` validates against `scripts/de-personalization-table.schema.json` (exit code 0) |
| B1.5 | `scripts/depersonalize.py --dry-run` on the source monorepo produces a diff that, when applied, leaves zero matches for any value in `de-personalization-table.yaml`'s left column |
| B2 | `scripts/classify.py` emits `classification.jsonl` with one row per scanned file and zero rows with `class: null` |
| B3.1 | `grep -rE` for the de-personalization table's regex set against the doctrine extraction tree returns empty |
| B3.2 | `grep -rE` for the de-personalization table's regex set against the L-rule extraction tree returns empty |
| B3.3 | `grep -rE` for the de-personalization table's regex set against the memory-rule extraction tree returns empty |
| B3.4 | `grep -rE` for the de-personalization table's regex set against the script extraction tree returns empty |
| B3.5 | `grep -rE` for the de-personalization table's regex set against the skill+template extraction tree returns empty |
| B4 | `scripts/assemble.py` produces the public-repo working tree under `.flywheel/extraction/staging/` and `git diff --stat` reports zero modifications to the source monorepo |
| B5 | `flywheel --help`, `flywheel doctor`, `flywheel init`, `flywheel update`, `flywheel uninstall` each return exit code 0 with usage text on a fresh staging-tree install |
| B6 | Installer-smoke CI green on macos-14 + ubuntu-22.04 for `install → doctor → uninstall → byte-equality` |
| B7 | `uninstall.sh --confirm` on a freshly-installed staging tree leaves `git status` clean (byte-equality with pre-install state) |
| B8 | `release.yml` produces a tagged github release whose tarball SHA256 matches the published `install.sh.sha256` |
| B9 | `ci.yml` and `installer-smoke.yml` both green on a probe PR against `main` |
| B10 | `.flywheel/extraction/staging/` contains the v0.2 working tree; `manual-review-queue/<ts>/` is empty or every entry has a `signed_off_by: joshua` field |
| B11 | Repo root contains `README.md`, `LICENSE`, `CHARTER.md`, `CHANGELOG.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`; `CONTRIBUTING.md` contains the string `Signed-off-by` (DCO marker) |
| B11.5 | `grep` of the redacted case-study draft against `de-personalization-table.yaml`'s client column returns empty |
| B14.5 | `CHANGELOG.md` contains a `## [0.2.0] - <date>` section and validates against `keepachangelog` lint |
| B15 | The git tag `v0.2.0` exists, the github release is published, and the CI badge on the README is green for that tag |
| B16 | An outbound message to skillos:1 is recorded in agent-mail with topic `flywheel-skill-boundary-v0.2` and a non-null `acknowledged_at` |
| B17 | The smoke-test script (§5.5) returns exit code 0 on a fresh macOS-14 environment |

P1 beads (B12.*, B13.*, B14) inherit acceptance from the workflow lints in `ci.yml` (markdownlint, schema-validate, link-check) and do not require additional gates here.

---

## 11. Risk register

Synthesized from Lane A §3 (20 failure modes) + Lane B §4 (anti-patterns) + Lane C §6. Top 10:

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | De-personalization sweep removes evidentiary force from load-bearing doctrines (Lane A §3 risk #1) | High | High | Mode B pattern-extraction rewrite, not mechanical substitution. Preserve trauma-shape, lose instance metadata. Joshua-judged review on every Mode-B output. |
| 2 | Per-tenant launchd plists (6 files) leak the Joshua-fleet tenant list (Lane A §3 risk #8) | Certain if unhandled | High | Installer ships a single canonical `coordinator-daemon.plist.tmpl` with placeholders. The 6 named plists stay in source repo only. |
| 3 | The H3 case study can't pass the named-client-consent gate (kill condition for H3) | Medium | High (collapses H3 to H1 or H2) | Build the case study around the meta-application (flywheel-on-flywheel), which is consent-free by construction. Client-named studies wait for explicit per-surface consent. |
| 4 | Skillos cross-orch coordination drags B0/B16 into a multi-week negotiation | Medium | Medium | Decouple: v0.2 ships zero ambient skills. The skills/ interface ships; specific skills wait for v0.3. The outbox to skillos:1 happens immediately but does not block v0.2. |
| 5 | Installer-smoke CI on macos-14 reveals a path/binary mismatch we don't catch locally | Medium | Medium | `installer-smoke.yml` runs on every PR and nightly. macos-14 + ubuntu-22.04 catch almost everything. Joshua's local install (B17) is the canonical test for environmental edge cases. |
| 6 | The webpage's case study reads as marketing fluff | Medium | High | Case study format follows the SmartBug pattern: industry, challenge, solution, **named metric**. The H3 meta-application supplies the metrics (extraction worker-hours, bead count, doctrines extracted, cross-orch incidents). |
| 7 | Joshua reviews v0.2 and says "this doesn't read as mine" (kill condition for H1, partial kill for H3) | Medium | High | The CHARTER.md (B0) is written by Joshua or under his close supervision. Every Mode-B doctrine rewrite is checkpointed before B10 closes. |
| 8 | The 40-60 worker-hour effort estimate proves optimistic | Medium | Medium | Per-category beads (B3.1-B3.5) measure burn rate against real progress. If Mode B per-file budget exceeds 30 minutes consistently, raise to Joshua for scope-trimming decision. |
| 9 | The github repo's first impression (README) lands wrong | Medium | High | README written against Lane B §3 patterns (Bun's one-liner; Tailwind's transparent metrics; CrewAI's progressive disclosure). Reviewed by an external developer (not Joshua, not flywheel:1) before launch. |
| 10 | Pre-1.0 history rewrite breaks adopter expectations | Low | Medium | CHARTER.md states the policy explicitly. Adopters of pre-1.0 software accept this by convention. The policy freezes at v1.0. |

---

## 12. Success criteria (Joshua-judged)

Per Joshua's directive: *"make ourselves and the world truly proud."*

### 12.1 "Joshua proud" in the github repo

Five observable criteria:

1. **The README's first 200 words read as Joshua's voice, not generic-AI-tool-marketing.** No "comprehensive," "leveraging," "cutting-edge." Direct sentences; first-person where natural.
2. **The CHARTER.md states what flywheel is NOT** alongside what it is. The "is NOT" list is concrete and opinionated. ("Flywheel is not a low-code platform. Flywheel is not a replacement for engineering judgment.")
3. **`flywheel doctor` returns 0 on a clean macOS install in under 10 seconds.**
4. **The CI badge on the README is green.** All workflows pass on the v0.2.0 tag.
5. **A developer who is not Joshua, given just the README, gets to `flywheel doctor` exit-0 in under 5 minutes without asking a question.**

### 12.2 "Joshua proud" in the webpage

Five observable criteria:

1. **The hero (`/`) makes the value claim in one sentence under 12 words.** ("AI development that compounds." Or its successor; Joshua-approved.)
2. **The `/case-studies` page contains at least one named, quantified outcome.** Per H3: the flywheel-on-flywheel meta-application with measured metrics.
3. **`/about` features Joshua personally** with a photo, direct email, and bio, per the Basecamp / Cushion founder-visibility pattern.
4. **`/contact` lists three engagement tiers with price ranges and scope per tier.** Mirrors the AI Assessment ladder (memory 2026-05-11 north star).
5. **An SMB owner who lands on `/` (with no prior context) can articulate "what Joshua does" within 60 seconds.** Tested with a real SMB owner before launch (paid 30-minute usability test if needed).

### 12.3 The smallest demonstration of success

A single sentence: **"Joshua, on the day of v0.2 launch, posts the github URL and the webpage URL on LinkedIn or to a client, and does not feel embarrassed."** Every Joshua-judged gate composes to this one criterion. If any gate is failing on launch day, B15 does not close.

---

## 13. What this round did NOT decide (for round 4 of REFINE)

- **Per-bead acceptance gate specifics beyond §10.7.** Phase 4 DECOMPOSE writes the rest.
- **Final wording of the README, CHARTER, hero, about-bio.** B0 and B11 author; Joshua reviews.
- **Final case-study scope** (which metrics, which screenshots, which redaction depth). B11.5 designs; Joshua signs off per item #9 in §9.
- **Final visual design of the webpage.** B13.* authors; Joshua signs off on visual direction.
- **Whether to invite outside contributors at v0.2 or wait for v0.3.** Open; depends on whether v0.2 launches with CONTRIBUTING.md saying "currently not accepting outside contributions" or the standard open-door language.

---

## 14. Convergence test for Phase 2 → Phase 3

Phase 3 AUDIT can run when:

- ✓ Hypothesis slate is in STATE.json (3 working candidates, exactly one third-alt; H4/H5 evaluated and rejected with cited reasons in §3)
- ✓ Engine/overlay boundary refined with concrete counts per substrate category
- ✓ Extraction pipeline refined with Mode A vs Mode B distinction + B1.5 codemod bead
- ✓ Installer architecture refined with pre-state branching + tenant-plist handling
- ✓ Public repo structure refined with `.flywheel-protected.json` + extraction meta-directory + CI workflow spec
- ✓ Webpage architecture refined with two-audience routing + page-by-page conversion logic
- ✓ All 12 of Lane C's open questions have Phase-2 defaults; Joshua-decision items flagged (#1, #9, #12)
- ✓ Pre-launch smoke test specified (§5.5) and bound to bead B17
- ✓ DCO contributor-assertion model selected (#7)
- ✓ Bead DAG sharpened (31 → 33 beads; every P0 has observable single-axis acceptance per §10.7)
- ✓ Risk register present (top 10)
- ✓ Success criteria concretized (Joshua-judged)
- ✓ First-adopter strategy decided (§9.1: meta-case-study at v0.2; external adopter recruited post-launch for v0.2.1)

All ✓. Phase 2 round 3 complete.

---

*End of 02-REFINE-r3.md. Hand off to Phase 3 AUDIT for adversarial review, or run round 4 to confirm convergence.*
