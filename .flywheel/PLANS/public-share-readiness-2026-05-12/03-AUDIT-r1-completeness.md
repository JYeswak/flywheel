# 03-AUDIT-r1-completeness.md — Phase 3 AUDIT, Completeness Lens

**Phase:** 3 AUDIT
**Lens:** completeness — does the plan address every Phase-1 finding and every Joshua-directive line?
**Auditor:** flywheel:1 / Phase-3 completeness lane
**Baseline:** `02-REFINE-r4.md` (594 lines)
**Authored:** 2026-05-12T~21:30Z

---

## 1. Lens summary

This lens asks one question: **for every input — Phase-1 findings (A/B/C) and Joshua's verbatim directives — does the converged plan address it, or is there a gap?** It does NOT evaluate quality, internal consistency, or risk-balance — those are other lenses. It evaluates surface coverage.

Method:
1. Walk each Phase-1 lane finding line-by-line. Cite plan section that addresses it.
2. Walk each of Joshua's 12 directive lines from the 17:00Z correction.
3. Spot-check every P0 bead's acceptance criterion.
4. Score: addressed / partial / not-addressed / wrong-addressed.

Bias check: I am not the plan author. I read the inputs against the plan, not the plan against itself.

---

## 2. Coverage table — Lane A findings

| # | Lane A finding | Plan addresses? | Citation |
|---|---|---|---|
| A1 | 94 doctrines audited | YES | §4.2 table row "Doctrine: 94" |
| A2 | 109 L-rules numbered L48-L168 | YES | §4.2 "L-rules: 109"; numbering-preservation noted in Lane A risk #6 but plan does NOT lock the policy explicitly |
| A3 | 183 memory rules | YES | §4.2 "Memory rules: 183" |
| A4 | 50% of scripts hardcode `/Users/josh` | YES | §6.1 (path-parameterization contract); §4.2 "Scripts: 394"; risk-register #5 |
| A5 | 64% of doctrines name a client | PARTIAL | §4.3 cites the dominance of engine-after-rewrite; Mode-B sub-mode addresses this conceptually; no per-doctrine consent-or-rewrite policy beyond Mode B |
| A6 | 69% of memory rules name Joshua | YES | §4.1 tri-class taxonomy; §5.2 de-personalization table includes `Joshua → {operator}` |
| A7 | 91% of memory rules are date-stamped | PARTIAL | §5.2 includes the date regex `(?i)20\d\d-\d\d-\d\d`; no policy on whether to drop dates, generalize ("during early development"), or preserve as historical metadata |
| A8 | Only 11/183 memory rules survive strict pure-pattern grep | YES | §1 exec summary cites "11 of 183 memory rules surviving the strict pure-pattern filter"; §7.2 sets v0.2 ship count at 30-40 |
| A9 | 50 scripts are per-tenant overlay | YES | §6.3 (tenant-named launchd plists do not ship); risk-register #2 |
| A10 | Live `state.db` in skill subtree must never publish | NOT-ADDRESSED | Lane A §3 risk #9 names this explicitly; the plan never mentions `state.db`, `-shm`, or `-wal`. This is a leak risk if the skill subtree extracts naively. |
| A11 | `AGENTS-CANONICAL.md` is auto-generated (edit shards not output) | NOT-ADDRESSED | Lane A §3 risk #7 names this. Plan never mentions the generator workflow, AGENTS-CANONICAL.md's regenerable nature, or the shard-vs-output edit discipline. |
| A12 | Propagator scripts HALTED per L168 | NOT-ADDRESSED | Lane A §3 risk #3 names three HALTED propagators (`canonical-doctrine-sync.sh`, `sync-canonical-doctrine.sh`, `agents-md-fleet-propagator.sh`). Plan never disposes of them — do they ship with `STATUS: halted`? Do they ship at all? |
| A13 | Lane A's 20-risk failure-mode catalogue | PARTIAL | §11 risk-register has 10 risks. 10 of Lane A's 20 are not surfaced (e.g., A10 state.db, A11 AGENTS-CANONICAL.md generator, A12 propagators, MEMORY.md system-prompt-injection, CLAUDE.md global-ref, beads JSONL leak, cross-orch handoffs leak, PLANS dir leak) |
| A14 | Skillos coordination on critical path | YES | §4.5 (defer skill substrate to v0.3); §10.6 B16 (skillos cross-orch handoff); risk-register #4 |
| A15 | Realistic 40-60 worker-hour estimate | YES | §1 exec summary; §4.2 table; §4.3 "40-60 worker-hours total" |

**Lane A score: 9 YES, 3 PARTIAL, 3 NOT-ADDRESSED out of 15 sampled findings.**

---

## 3. Coverage table — Lane B findings

| # | Lane B finding | Plan addresses? | Citation |
|---|---|---|---|
| B1 | PAI one-line install pattern | YES | §6 installer architecture; §5.5 smoke test step 2 (`curl -fsSL ... \| bash`) |
| B2 | PAI `tee` install pattern (verification before pipe-to-bash) | NOT-ADDRESSED | Lane C §2.8 user verification path covers this; plan §6 doesn't echo it. Plan's verify is in CI/release pipeline, not adopter-facing |
| B3 | PAI `/interview` onboarding ritual | PARTIAL | §6.2 mentions `flywheel init --tenant test-tenant` exists; no first-run interactive wizard analogous to `/interview`/TELOS. Lane B labels this a gap; plan inherits the gap |
| B4 | PAI `.pai-protected.json` containment-zone declaration | YES | §7.4 `.flywheel-protected.json` (PAI-inspired containment-zone declaration) explicit |
| B5 | Aider multi-LLM flexibility positioning | NOT-ADDRESSED | Lane B identifies Aider as one of two positioning angles flywheel must choose between (Aider's flexibility vs Bun's all-in-one). Plan never picks. |
| B6 | Bun/CrewAI progressive-disclosure pattern | PARTIAL | §7.5 sets README at ~150 lines (progressive-disclosure-shaped) but no explicit "emotional → details → code" structure |
| B7 | n8n self-hosting transparency | NOT-ADDRESSED | Plan mentions zero-telemetry but not self-host-vs-saas framing |
| B8 | SMB trust: named clients + quantified outcomes | YES | §8.3 trust-touchpoint table; §12.2 criterion 2; H3 case-study design |
| B9 | SMB trust: founder visibility | YES | §8.1 `/about`; §12.2 criterion 3 ("`/about` features Joshua personally") |
| B10 | SMB trust: engagement-tier clarity | YES | §8.1 `/contact` ("three engagement tiers"); §12.2 criterion 4 |
| B11 | SMB anti-patterns: vague claims, jargon-without-translation, hidden pricing | YES | §8.4 ("What does NOT go on the webpage") covers all three |
| B12 | Webpage tech stack (Next.js / Vercel / Cloudflare) | PARTIAL | Plan doesn't specify Next.js vs Astro vs other. Lane C §4.5 named Next.js as default; plan §8 doesn't echo or override. |
| B13 | 5 SMB-trust example sites (Basecamp / Stripe Atlas / Cushion / SmartBug / Copyhackers) | YES | §8.3 cross-references all five via Lane B §4 |
| B14 | Lane B's full 10-line page structure recommendation | PARTIAL | §8.1 has 9 pages, structurally aligned; specific copy guidance for hero / problem / methodology absent |
| B15 | "Joshua is the differentiator" framing | YES | §2 ("Both surfaces feature Joshua personally"); §8.1 `/about` block; §12.2 |

**Lane B score: 8 YES, 4 PARTIAL, 3 NOT-ADDRESSED out of 15.**

---

## 4. Coverage table — Lane C findings

| # | Lane C finding | Plan addresses? | Citation |
|---|---|---|---|
| C1 | 4-phase pipeline (CLASSIFY → DE-PERSONALIZE → ASSEMBLE → VERIFY) | YES | §5 (refined); §5.1-§5.4 |
| C2 | Bash installer with staging-dir-rename atomicity | PARTIAL | §6 covers installer pre-state branching; §6.1 path parameterization. Atomicity-via-staging-rename (Lane C §2.3) not explicitly echoed |
| C3 | jq-based idempotent settings.json merge | PARTIAL | §6.2 implies it; specific jq merge logic from Lane C §2.4 not echoed |
| C4 | SHA-256-verified backup | NOT-ADDRESSED | Lane C §2.5 designs backup with `.sha256` companion; plan never re-states the backup-with-hash discipline. B7 acceptance ("byte-equality with pre-install state") implies but doesn't specify. |
| C5 | Install receipt as authoritative undo manifest | NOT-ADDRESSED | Lane C §2.5/§2.7 makes this central. Plan never mentions "install receipt" by that name. B7 acceptance says "byte-equality" not "receipt-driven uninstall" |
| C6 | Per-tenant launchd plists do NOT ship | YES | §6.3 explicit |
| C7 | bats test framework for `tests/` | NOT-ADDRESSED | Plan §7.6 CI workflow names `shellcheck`, `ruff`, `markdownlint` — not `bats`. Lane C §3 tree includes bats; plan's CI table omits it. |
| C8 | Nextra docs at v0.2.0 | YES | §7.1 "Nextra docs site at `docs/`"; §10.6 B12.* beads |
| C9 | `examples/hello-doctor/` as standalone clone-target | NOT-ADDRESSED | Lane C §3 tree + §6.1 hello-doctor walkthrough as smoke test. Plan §5.5 has the pre-launch smoke test but doesn't bind it to a checked-in `examples/hello-doctor/` directory. |
| C10 | 12 open Phase-2 questions resolved | YES | §9 table covers all 12 with defaults; Joshua-decision items flagged (#1, #9, #12) |
| C11 | First-adopter strategy | YES | §9.1 (meta-case-study at v0.2; external adopter recruited post-launch for v0.2.1) |
| C12 | Pre-launch smoke test on fresh laptop | YES | §5.5 + B17 bead |

**Lane C score: 6 YES, 2 PARTIAL, 4 NOT-ADDRESSED out of 12.**

### 4a. Verification of the 12 open questions (per Lane C §7)

R3 §9 was claimed to resolve all 12. Verification by question number:

| Q# | Lane C question | Plan §9 resolution? |
|---|---|---|
| 1 | Final repo name and org | YES (Joshua-decision required) |
| 2 | CLI language (bash vs Rust) | YES (bash for v0.2) |
| 3 | Docs site path | YES (subdomain) |
| 4 | Engine install: git clone vs tarball | YES (tarball) |
| 5 | Telemetry stance | YES (zero) |
| 6 | Signing beyond TLS | YES (TLS-only at v0.2) |
| 7 | DCO vs CLA | YES (DCO) |
| 8 | CHANGELOG format | YES (keep-a-changelog) |
| 9 | What goes in `/case-studies` at v0.2 | YES (meta-case-study; Joshua-decision required) |
| 10 | Repo blocks on webpage or ships independently | YES (ship together) |
| 11 | Pre-1.0 git history rewrite policy | YES (force-with-lease allowed pre-1.0) |
| 12 | Skill ownership boundary with skillos | YES (v0.2 ships zero ambient skills; Joshua-decision required) |

**All 12 of Lane C's open questions have Phase-2 defaults.** ✓

---

## 5. Coverage table — Joshua's directives (17:00Z verbatim)

| # | Joshua-directive line | Plan addresses? | Citation |
|---|---|---|---|
| J1 | "actually publish the entire flywheel" | YES | §1 exec summary; H3 hypothesis publishes engine + case study |
| J2 | "make whatever you just published private for now" | NOT-ADDRESSED | Plan never mentions the commit-346f2ec rollback or the make-private remediation. This is a Phase-0 prerequisite that should be acknowledged as DONE or NOT-YET-DONE in the plan. |
| J3 | "entire flywheel process needs to be measured against the PAI" | PARTIAL | Lane B did the PAI gap analysis. Plan §7.4 adopts the `.flywheel-protected.json` pattern. Plan does NOT have a dedicated "PAI gap analysis" section that walks each gap. The 6-row Lane B gap table is inherited by reference, not surfaced. |
| J4 | "de-joshuaify the entire flywheel process" | YES | §4.1-§4.3 tri-class taxonomy; §5.2 de-personalization table; §10.6 B1-B3.* beads |
| J5 | "commercially sharable" | PARTIAL | §9 item 12 mentions "publishable into the ecosystem" but commercial-viability beyond MIT licensing (e.g., consulting funnel, AI Assessment ladder integration, brand-extension policy) is in §8 webpage scope only. Engine-side commercial viability (e.g., dual-license possibility, sponsored-feature roadmap) not addressed. |
| J6 | "really good looking page on our website" | PARTIAL | §8 covers structure + content. Visual design spec is explicitly deferred (§13 "Final visual design of the webpage. B13.* authors; Joshua signs off on visual direction"). The "really good looking" criterion has no Joshua-judged acceptance gate in §12.2. |
| J7 | "git repo's audience is fellow developers" | YES | §2 two-audience table; §8 page-by-page audience routing |
| J8 | "audience for the webpage is SMB clients" | YES | §2; §8 |
| J9 | "both designed to build trust in me, our brand, and our work" | YES | §2 "How they reinforce each other"; §12.1 + §12.2 success criteria |
| J10 | "proper /flywheel:plan on this" (meta-completeness) | YES | The plan itself is in `/flywheel:plan` 5-phase shape; §14 convergence test |
| J11 | "write it up into a proper set of documents" | PARTIAL | The plan documents itself (00-INTENT, 01-RESEARCH-{A,B,C}, 02-REFINE-r4). Plan does NOT specify which artifacts the BEAD-output produces in the public repo (README, CHARTER, CONTRIBUTING are listed in §7.5 but no overall "doc tree" matrix). |
| J12 | "we have some really good documenting skills" | NOT-ADDRESSED | Plan does NOT invoke specific skills by name (`writing-docs`, `technical-writing`, `readme-writing`, `de-slopify`, `documentation-website-for-software-project`). No bead is bound to a documenting-skill invocation. B11 (top-level files) and B12.* (docs site) silently assume the worker knows which skill to invoke. |

**Joshua-directive score: 6 YES, 4 PARTIAL, 2 NOT-ADDRESSED out of 12.**

---

## 6. H3 component coverage (Dimension 3)

| H3 component | Plan addresses? | Citation |
|---|---|---|
| Engine published at developer-ready depth | YES | §4.2 counts; §7 repo structure; §10.6 B10/B11 |
| Redacted-overlay-as-case-study on webpage | YES | §8.1 `/case-studies`; B11.5 + B13.4 |
| Per-client consent for any named entities in case study | PARTIAL | §9 item 9 references per-surface-consent memory rule. Plan does NOT specify the consent-collection workflow (template message? outbound email? signed acknowledgement?). |
| Redaction process spec | PARTIAL | §3 H3 stress-test names the grep verification; §5.2 de-personalization table is the instrument. No standalone "redaction spec for case-study" doc. B11.5 acceptance is one-line grep ("returns empty"). Sufficient for engineering but not for editorial. |
| Consent collection workflow | NOT-ADDRESSED | Plan never specifies workflow. Joshua-decision-required item without a process attached. |
| Fallback if consent not granted in time | PARTIAL | §3 H3 kill-condition: "Joshua decides whether to (a) reshape the case study to remove named-client surface, or (b) collect per-client consent before publishing." But no calendar gate, no v0.2-vs-v0.2.1 decision tree |

**H3 score: 2 YES, 3 PARTIAL, 1 NOT-ADDRESSED out of 6.**

---

## 7. Acceptance-criterion DAG completeness (Dimension 4)

Plan claims 33 beads. §10.6 lists 33; §10.7 has acceptance for all P0 + B14.5. Spot-check:

### P0 beads (count: 22, per §10.6)

B0, B1, B1.5, B2, B3.1, B3.2, B3.3, B3.4, B3.5, B4, B5, B6, B7, B8, B9, B10, B11, B11.5, B14.5, B15, B16, B17.

**§10.7 acceptance rows present for:** B0, B1, B1.5, B2, B3.1, B3.2, B3.3, B3.4, B3.5, B4, B5, B6, B7, B8, B9, B10, B11, B11.5, B14.5, B15, B16, B17 = **22/22.** ✓

### P1 beads (count: 11)

B12.1, B12.2, B12.3, B13.1, B13.2, B13.3, B13.4, B13.5, B13.6, B13.7, B14.

§10.7 statement: "*P1 beads (B12.*, B13.*, B14) inherit acceptance from the workflow lints in `ci.yml` (`markdownlint`, schema-validate, link-check) and do not require additional gates here.*"

**Verdict:** PARTIAL. The inherited acceptance is correct for docs lint but does NOT capture editorial/visual acceptance — i.e., `/about` page features Joshua's photo (visual), `/case-studies` features quantified metrics (content), `/contact` features three engagement tiers (commercial scope). None of these are markdownlint-checkable. The §12.2 Joshua-judged criteria fill this for the webpage as a whole, but they are not bead-level.

### P2/P3 beads

None present. All 33 beads are P0 or P1. Plan does not surface P2 (nice-to-have) or P3 (deferred) beads. This is structurally clean for v0.2 but may misrepresent reality (e.g., outside-contributor enablement at v0.2 from §13 is undisposed).

### Beads referenced elsewhere but missing from DAG

- §5.5 pre-launch smoke test → B17 ✓
- §9 item 9 redaction → B11.5 ✓
- §9 item 12 skillos coord → B16 ✓
- §7.6 CI workflows (3 of them) → B8 + B9 ✓ (release + ci/installer-smoke; though §7.6 names *three* workflows, B8 covers `release.yml` and B9 covers two: `ci.yml` + `installer-smoke.yml`. Bead boundary is correct but reading is ambiguous.)
- §7.4 `.flywheel-protected.json` → **NOT IN DAG.** No bead authors or installs this file. Plan §7.4 describes it but no bead owns it. **GAP.**
- §6.3 canonical `coordinator-daemon.plist.tmpl` → **NOT IN DAG.** Plan removes the 6 tenant-named plists from extraction but doesn't bead-ize authoring the canonical placeholder template.
- §5.4 source-repo `.flywheel/extraction/` accumulation (classification.jsonl + manual-review notes) → IMPLICIT in B2/B10 but not surfaced as an artifact-output bead

---

## 8. Findings register

### F1 — `state.db` and SQLite runtime state never disposed of in plan
- **Severity:** HIGH
- **Dimension:** Phase-1 finding coverage (Lane A risk #9)
- **Location:** plan §4-§7
- **Finding:** Lane A §3 risk #9 explicitly names `~/.claude/skills/.flywheel/state.db` (+`-shm`, `-wal`) as a runtime-state-leak hazard. Plan never mentions it. If skill subtree extraction happens (even at v0.3), and the disposal policy is not pre-baked, runtime fleet state leaks publicly.
- **Evidence:** grep of plan for "state.db" / "sqlite" / "wal" / "shm" returns empty.
- **Recommendation:** Add §5.x or §7.x explicit "live-state artifact denylist": `state.db`, `state.db-shm`, `state.db-wal`, `beads.db`, `.beads/issues.jsonl`, dispatch logs, `.flywheel/handoffs/*.md`, `.flywheel/PLANS/<slug>/*` (current arc IS a PLAN). Bind to B2's classification rule.
- **TRUE-blocker class:** **YES — irreversible leak class.** Once `state.db` ships publicly, recall is incomplete (forks, mirrors). Per memory rule 2026-05-12 "secrets-class trauma skips 3-strike gate," this is a single-occurrence-irreversible-breach.

### F2 — `AGENTS-CANONICAL.md` auto-generation discipline not encoded
- **Severity:** MEDIUM
- **Dimension:** Phase-1 finding coverage (Lane A risk #7)
- **Location:** plan §4-§5
- **Finding:** `.flywheel/AGENTS-CANONICAL.md` is the output of `agents-md-shard-extract.sh`. Lane A §3 risk #7 says: "sweep edits go in the L-rule shards under `.flywheel/rules/`, not in AGENTS-CANONICAL.md." Plan never re-states this. A worker executing B3.* on the source repo may edit AGENTS-CANONICAL.md directly; next regeneration blows the edits away.
- **Evidence:** grep of plan for "AGENTS-CANONICAL" returns empty.
- **Recommendation:** Add to §5.x ("Edits land in shards under `.flywheel/rules/L*.md`, never in AGENTS-CANONICAL.md; that file is regenerable output."). Bind to B3.2 acceptance.
- **TRUE-blocker class:** No — workflow loss, not safety leak.

### F3 — Three HALTED propagator scripts have no disposal policy
- **Severity:** HIGH
- **Dimension:** Phase-1 finding coverage (Lane A risk #3)
- **Location:** plan §4.2, §10.6
- **Finding:** `canonical-doctrine-sync.sh`, `sync-canonical-doctrine.sh`, `agents-md-fleet-propagator.sh` are HALTED per L168 + propagator-canonical-ownership-class-aware-gate memory rule (N=3 SATURATION). Lane A §3 risk #3 names them. Plan never says: do they ship as `STATUS: halted`? Do they not ship until the gate is canonical? Are they fully omitted from v0.2?
- **Evidence:** grep of plan for "propagator" / "HALTED" returns empty.
- **Recommendation:** Add §5.x "halted-script disposal": do not ship in v0.2; cited in CHANGELOG as "deferred to v0.3 pending canonical-ownership-class manifest." Bind to B3.4 acceptance.
- **TRUE-blocker class:** **YES if published as-is.** Adopters who run halted propagators hit N=3 SATURATION clobber trauma. This is the founder-fault class that motivated L168.

### F4 — `MEMORY.md` system-prompt-injection mechanism not addressed
- **Severity:** MEDIUM
- **Dimension:** Phase-1 finding coverage (Lane A risk #10)
- **Location:** plan §7 + §5.5
- **Finding:** `MEMORY.md` is load-bearing for Claude Code's `UserPromptSubmit` hook injection. Plan's universal-memory directory at `engine/universal-memory/` ships 30-40 rules but the MEMORY.md index (the file Claude actually reads on prompt-submit) is not specified. Without the index, the rules don't surface.
- **Evidence:** grep of plan for "UserPromptSubmit" / "MEMORY.md" returns empty.
- **Recommendation:** Add to §7.x: engine ships an empty `MEMORY.md.template` with the index schema documented; adopter `flywheel init` populates it. Or: rules in `engine/universal-memory/` ship with a canonical generated `INDEX.md`.
- **TRUE-blocker class:** No — feature gap, not safety.

### F5 — Consent collection workflow for H3 case study not specified
- **Severity:** HIGH
- **Dimension:** H3 component coverage
- **Location:** plan §3, §9 item 9
- **Finding:** Plan acknowledges per-surface-consent memory rule (2026-05-11) but does NOT specify: (a) who drafts the consent ask, (b) what the consent ask says, (c) what the consent record looks like (signed email? agent-mail thread? written acknowledgement?), (d) the v0.2-vs-v0.2.1 fallback calendar if consent doesn't land in time.
- **Evidence:** §9 item 9: "per the per-surface-consent memory rule, Joshua reviews the redaction before publication." This conflates Joshua-review (operator self-review) with client-consent (external party).
- **Recommendation:** Add §3.x or new §8.5 "Consent workflow for named-entity surfaces": template ask, record format, calendar, fallback. Bind to B11.5 sub-bead or split B11.5 into "redaction" + "consent-collection."
- **TRUE-blocker class:** **YES — client-trust class.** Publishing a named-client metric without consent breaches the 2026-05-11 META-RULE that triggered the audit.

### F6 — `.flywheel-protected.json` described but not bead-ized
- **Severity:** MEDIUM
- **Dimension:** acceptance-criteria DAG
- **Location:** plan §7.4, §10
- **Finding:** §7.4 declares the file at repo root, lists 4 protected paths, sets a `$schema`. No bead in §10.6 owns authoring it. B11 ships top-level files but doesn't enumerate `.flywheel-protected.json`. B5/B6 (CLI + installer) read it at install time but don't own writing it.
- **Evidence:** §10.6 + §10.7 table.
- **Recommendation:** Add B11.x or extend B11 acceptance to include `.flywheel-protected.json` validates against `https://flywheel.zeststream.ai/schemas/protected-v1.json`. Author the schema file separately (or commit a `.json` schema definition into the repo).
- **TRUE-blocker class:** No — DAG completeness gap.

### F7 — Documenting-skills not invoked anywhere in plan
- **Severity:** MEDIUM
- **Dimension:** Joshua-directive coverage (J12)
- **Location:** plan §10 (DAG), §13
- **Finding:** Joshua said "we have some really good documenting skills." Memory rule index references `writing-docs`, `de-slopify`, `technical-writing`, `readme-writing`, `documentation-website-for-software-project` (the latter exists per §1 user CLAUDE.md). Plan never names any skill as a bead-execution instrument. Workers executing B11 (top-level files) or B12.* (docs site) silently pick their own approach.
- **Evidence:** grep of plan for "de-slopify" / "writing-docs" / "skill" (in execution context) returns the §4.5 boundary discussion but no execution-binding.
- **Recommendation:** Add §10.x "skill-binding table": each bead names the canonical skill(s) the worker invokes. B11 → `readme-writing` + `de-slopify`; B12.* → `documentation-website-for-software-project`; B13.* → page-specific writing skills + visual-design skills. This converts implicit worker discretion into explicit doctrine.
- **TRUE-blocker class:** No — quality / consistency risk.

### F8 — PAI gap analysis not surfaced as a dedicated plan section
- **Severity:** MEDIUM
- **Dimension:** Joshua-directive coverage (J3)
- **Location:** plan §7.4 (single line of PAI inheritance)
- **Finding:** Joshua: "the entire flywheel process needs to be measured against the PAI I shared - we need to find all gaps." Lane B §1 produced a 6-row gap table (one-liner install / onboarding ritual / containment-zone / recovery playbook / modular packs / philosophical positioning). Plan addresses one row explicitly (`.flywheel-protected.json` per §7.4). The other five rows are NOT walked. The `RECOVERY.md` centralization, the onboarding-ritual analog to `/interview`, the modular Pack README, the public manifesto — none surfaced as plan items.
- **Evidence:** grep of plan for "PAI" returns §7.4 only.
- **Recommendation:** Add §X "PAI gap analysis disposition" — a 6-row table that walks each Lane B gap with: status (addressed / deferred to v0.3 / explicitly rejected) and citation/bead-binding for the addressed ones.
- **TRUE-blocker class:** No — completeness gap; bead may surface it during DECOMPOSE.

### F9 — Bats test framework named in Lane C, absent in plan CI spec
- **Severity:** LOW
- **Dimension:** Phase-1 finding coverage (Lane C §3 + §6)
- **Location:** plan §7.6
- **Finding:** Lane C §3 repo tree includes `tests/installer/test_*.bats` (multiple bats files). Lane C §6.5 CI workflow runs `bats --tap`. Plan §7.6 CI workflow names `shellcheck`, `ruff`, `markdownlint`, schema-validate. No `bats` line.
- **Evidence:** §7.6 table.
- **Recommendation:** Either add `bats` to `installer-smoke.yml` jobs (likely the correct location) or document why bats was dropped.
- **TRUE-blocker class:** No.

### F10 — Live `.beads/issues.jsonl`, dispatch logs, handoff dir, PLANS dir disposal not addressed
- **Severity:** HIGH
- **Dimension:** Phase-1 finding coverage (Lane A risk #12, #13, #14)
- **Location:** plan §4, §5
- **Finding:** Lane A §3 names four overlay-class directories that contain live operator state: `.beads/issues.jsonl` (bead history with real bead IDs), `.flywheel/dispatch-log.jsonl` (dispatch history), `.flywheel/handoffs/*.md` (cross-orch communication, ~30+ files), `.flywheel/PLANS/<slug>/*` (~20+ historical plan-space arcs — including this one). Plan never disposes of any of them. They are not in the extraction destination mapping; they are not in any extraction-class denylist; they are not in B2's classification rules.
- **Evidence:** §5.1 classifier code shape; grep of plan for "issues.jsonl" / "dispatch-log" / "handoffs" / "PLANS/" returns empty.
- **Recommendation:** Add to F1's "live-state artifact denylist" entry. Critical because this very plan-arc directory (`.flywheel/PLANS/public-share-readiness-2026-05-12/`) contains client names by reference.
- **TRUE-blocker class:** **YES — bead ID + cross-orch leak class.** Some PLANS contain real client names by reference; some handoffs name clients verbatim. Single-occurrence-irreversible if published.

### F11 — L-rule numbering policy named in Lane A risk #6, deferred in plan
- **Severity:** LOW
- **Dimension:** Phase-1 finding coverage (Lane A risk #6)
- **Location:** plan §4, §9
- **Finding:** Lane A §3 risk #6 says: preserve L48-L168 numbering; engine ships with explanatory preface. Plan does not lock this policy. §9's 12 questions don't include "L-rule numbering."
- **Evidence:** grep of plan for "L-rule numbering" / "L48" / "numbering" returns empty.
- **Recommendation:** Add to §9 as item 13 OR add to §4.x as locked-in default.
- **TRUE-blocker class:** No — adopter-confusion risk only.

### F12 — Visual-design Joshua-judged criterion missing from §12.2
- **Severity:** MEDIUM
- **Dimension:** Joshua-directive coverage (J6 "really good looking page")
- **Location:** plan §12.2
- **Finding:** §12.2 has 5 Joshua-judged webpage criteria but they are content-focused (hero copy length, named outcome, photo, engagement tiers, SMB-owner 60-second test). No visual-quality criterion ("Joshua looks at the rendered page on his laptop and on a phone and says: this is mine, this is professional, this is something I'd send a prospect"). §13 explicitly defers visual design.
- **Evidence:** §12.2 + §13.
- **Recommendation:** Add §12.2 criterion 6: "the page renders cleanly on macOS Safari + iOS Safari at default zoom, Joshua reviews live, no jarring contrasts / type / spacing." Bind to B13.4 acceptance.
- **TRUE-blocker class:** No.

### F13 — Date-stamp policy not specified
- **Severity:** LOW
- **Dimension:** Phase-1 finding coverage (Lane A finding A7)
- **Location:** plan §5.2
- **Finding:** §5.2 de-personalization table includes a date regex but doesn't specify whether the substitution drops the date, abstracts to "during early development," or preserves as a `<date>` placeholder for adopters to re-instance. 91% of memory rules carry dates; the policy choice affects ~167 files.
- **Evidence:** §5.2 sample table.
- **Recommendation:** Add policy line: "Dates substitute to `<incident-date>` placeholder by default; engine ships explanatory note. Mode-B rewrites may abstract to 'early-development incident' if date itself is load-bearing."
- **TRUE-blocker class:** No.

### F14 — Plan §11 risk register has 10 risks; Lane A had 20
- **Severity:** MEDIUM
- **Dimension:** Phase-1 finding coverage (Lane A §3)
- **Location:** plan §11
- **Finding:** Top-10 selection from Lane A's 20 is reasonable, but 7 of the 10 omitted risks are exactly the load-bearing leaks (state.db, AGENTS-CANONICAL.md, propagators, MEMORY.md, beads JSONL, handoffs, PLANS). These are the F1/F2/F3/F4/F10 findings above. Risk register's "top 10" methodology preferentially selected non-leak risks.
- **Evidence:** §11 vs Lane A §3 cross-reference.
- **Recommendation:** Re-rank risk register on likelihood × irreversibility (not just likelihood × impact). Leak-class risks all rank top-5 under that criterion.
- **TRUE-blocker class:** No — this is meta-rubric, not direct leak.

### F15 — Commit 346f2ec (rollback to private) not mentioned anywhere in plan
- **Severity:** LOW (housekeeping)
- **Dimension:** Joshua-directive coverage (J2)
- **Location:** plan everywhere
- **Finding:** Joshua said "make whatever you just published private for now" referring to the premature 14:25Z push. The plan implicitly assumes this is done but never states it. New phases of work may re-encounter the question.
- **Evidence:** grep of plan for "346f2ec" / "private for now" / "premature" returns empty.
- **Recommendation:** Add one line to §1 exec summary or §13: "Phase-0 (commit 346f2ec) made the premature 17:00Z push private; this plan presumes that rollback is complete."
- **TRUE-blocker class:** No.

---

## 9. Severity counts

| Severity | Count |
|---|---:|
| HIGH | 4 (F1, F3, F5, F10) |
| MEDIUM | 7 (F2, F4, F6, F7, F8, F12, F14) |
| LOW | 4 (F9, F11, F13, F15) |
| **TOTAL** | **15** |

| TRUE-blocker class | Count |
|---|---:|
| YES (irreversible / safety / client-trust) | 3 (F1 state.db, F3 propagators, F5 consent, F10 live-state dirs — F10 counted with F1 as one class but listed separately for finding traceability; net unique = 3 + 1 = **4 TRUE-blocker findings**) |
| No | 11 |

---

## 10. Completeness verdict

**Material gaps.** The plan is structurally strong (architecture, hypothesis slate, bead DAG, success criteria all present and refined) but has **four TRUE-blocker leak/consent gaps** that must close before Phase 4 DECOMPOSE produces canonical beads:

1. **F1 + F10 — live-state artifact denylist** (state.db / -shm / -wal / beads.db / .beads/issues.jsonl / dispatch-log / handoffs/ / PLANS/). Single class of risk; missing entirely from the plan. Per secrets-class memory rule, this skips the 3-strike gate.

2. **F3 — HALTED propagator scripts disposal**. Three named scripts that, if shipped, recreate the trauma class that motivated L168.

3. **F5 — consent collection workflow for H3 case study**. The plan acknowledges per-surface-consent but never specifies the workflow. Without it, the H3 working hypothesis has a non-executable critical step.

4. **F8 — PAI gap analysis surfaced** as 6-row table-walk so each Lane B finding has explicit disposition (addressed / deferred / rejected). Currently only 1 of 6 gaps is surfaced.

Beyond the TRUE-blockers, **7 MEDIUM findings** (F2, F4, F6, F7, F12, F14, plus the documenting-skill-binding) sharpen the plan but don't block. **4 LOW findings** are housekeeping.

**Recommendation:** Do not advance to Phase 4 DECOMPOSE until F1 + F3 + F5 + F8 are closed (added as plan sections in an r5 round OR explicitly resolved with cited rationale). The remaining 11 findings can fold into Phase 4 DECOMPOSE as bead acceptance refinements.

The plan as it stands is **complete with material gaps** — strong enough to anchor a R5 patch round, not yet strong enough for irreversible bead dispatch.

---

## 11. Acceptance check

| Acceptance criterion | Status |
|---|---|
| Every Phase 1 lane finding accounted for (yes/partial/no with citation) | ✓ (Lane A 15 findings, Lane B 15 findings, Lane C 12 findings — all rowed) |
| Every Joshua-directive line addressed | ✓ (12 directive lines from 17:00Z all rowed) |
| Findings register has ≥5 items | ✓ (15) |
| Verdict is honest (no rubber-stamping) | ✓ (material gaps, 4 TRUE-blocker findings) |
| File written to specified path | ✓ |

---

*End of 03-AUDIT-r1-completeness.md. Hand off to Phase 3 lens-merge.*
