# 01-RESEARCH-A.md — Problem-Space Inventory (Lane A)

**Phase:** 1 RESEARCH
**Lane:** A — problem-space inventory
**Author:** flywheel:1 / Lane-A worker
**Authored:** 2026-05-12
**Scope:** Enumerate what's actually in `/Users/josh/Developer/flywheel/` (+ `~/.claude/` substrate that flywheel composes onto) that needs extraction, classification, or de-personalization before the engine ships publicly.
**Methodology:** Direct filesystem inventory + sampled classification (≥30 representative artifacts) + contamination grep + per-category risk register. Classification rule from CLASSIFICATION-PLAYBOOK.md applied INDEPENDENTLY (not trusted on faith).

---

## 0. Executive shape

| Category | Count | Engine eligible | Engine-after-rewrite | Overlay-only | Heavy contamination |
|---|---:|---:|---:|---:|---:|
| Doctrine corpus (`.flywheel/doctrine/*.md`) | 94 | ~25 | ~50 | ~15-19 | 60/94 (64%) name a client |
| L-rule corpus (`.flywheel/rules/L*.md`) | 110 (+MANIFEST.json) | ~70 | ~30 | ~10 | 46/110 (42%) name Joshua |
| Memory rules (`~/.claude/projects/.../memory/*.md`) | 183 | 11 pure-pattern | ~70 (after sweep) | ~100+ instance-locked | 84/183 client + 127/183 Joshua + 166/183 dated |
| Skills (flywheel-namespaced) | ~6 top-level + `.flywheel/` subtree | ~2 | ~3 | ~1 | 138 files in `.flywheel/` skill mention Joshua |
| Scripts (`.flywheel/scripts/`) | 358 `.sh` + 36 `.py` = 394 | ~80 | ~200 | ~115 | 197/394 (50%) hardcode `/Users/josh`; 65/394 (16%) name a specific client |
| Hooks (`~/.claude/hooks/`) | 187 entries; ~4 are the canonical pretooluse/posttooluse | All 4 engine | varies | most overlay/legacy | mixed; engine subset is clean |
| Templates (`templates/flywheel-install/*`) | 62 files | ~30 | ~25 | ~7 (per-tenant plists) | tenant-named launchd plists; josh-request schema |
| AGENTS.md substrate | 1 canonical + 1 template + 2 project copies | 1 (canonical paradigm) | 1 (template needs param) | 0 | repo-list table inside is overlay |

**Headline finding:** the engine paradigm is real and publishable, but it is **deeply entangled** with overlay content. ~50% of scripts reference Joshua's home path; ~64% of doctrine names a specific client; only **11/183 memory rules survive the four-question filter as pure-pattern publish-eligible**. Mechanical sweep is insufficient — substantial pattern-extraction rewrites are required for the high-value engine artifacts.

---

## 1. Substrate-by-substrate inventory

### 1.1 Doctrine corpus — `.flywheel/doctrine/*.md`

**Count:** 94 markdown files (+ `README.md` + one `.json` schema).

**Contamination measurements** (grep across the 94 files):
- 60/94 (64%) reference one of: alps, alpsinsurance, terratitle, blackfoot, mobile-eats, skillos, elektrafi, vrtx, cubcloud, clutterfreespaces, picoz
- 57/94 (61%) mention "Joshua" by name
- Most also cite specific bead IDs (`flywheel-jloib`, `flywheel-2xdi.60.1`, etc.) and dates

**Sample file paths** (representative, with classification):

| File | Class | Notes |
|---|---|---|
| `substrate-class-classifier.md` | `engine` | The L162 paradigm primitive. Light de-personalization on incident citations (N=3 SATURATION clobber → "early-development cross-repo clobber"). Universal pattern. |
| `cross-repo-write-path-discipline.md` | `engine-after-rewrite` | Documents the cross-repo write gate. References specific paths + propagator script names. Sweep needed. |
| `closure-evidence-contract-version-anchor.md` (L154) | `engine-after-rewrite` | Universal pattern about closure-evidence schema-pinning. Cites specific Joshua-fleet handoff. |
| `closure-evidence-public-lens-anchor-discipline.md` (L155) | `engine-after-rewrite` | Universal pattern. |
| `inbox-discipline-missed-during-deep-burndown-motion.md` | `engine-after-rewrite` | Pattern is universal; specific orch names (skillos:1, flywheel:1) need projection to `orch-A`/`orch-B`. |
| `outbox-discipline-cross-orch-ship-notification.md` (L157) | `engine-after-rewrite` | Same shape as inbox. |
| `meta-primitive-extraction-friction-class.md` | `engine` | Pure paradigm. |
| `meta-primitive-composition-shape-taxonomy.md` | `engine` | Pure paradigm. |
| `mission-fidelity-substrate.md` | `engine-after-rewrite` | The pattern is universal (mission-claim → evidence → invariant); current examples cite flywheel-specific scripts. |
| `fleet-doctrine-hr-policy.md` | `engine-after-rewrite` | The HR policy abstraction is publishable; specific role descriptions reference Joshua-fleet roster. |
| `jeff-corpus-substrate-lifecycle.md` | `overlay` | Specific to Joshua's local corpus (`~/Developer/jeff-corpus/`); the underlying pattern (indexed-data vs source-bulk) is a sentence in another doctrine. |
| `jeff-daily-corpus-diff.md` | `overlay` | Specific to Joshua's daily intel rhythm with Jeff. |
| `option-e-cross-orch-fuckup-log-fold-up.md` | `overlay` | Cross-orch coordination instance. The pattern is in `outbox-discipline-cross-orch-ship-notification.md`. |
| `session-handoff-v0.4-2026-04-27.md` | `overlay` | Specific dated handoff doctrine version. |
| `tick-script-skillos-doctor-emission.md` | `engine-after-rewrite` | Pattern (tick scripts emit doctor signals) is universal; "skillos" name is the example. |
| `jsm-canonical-auth-contract.md` | `overlay` | JSM is a private skillos/Joshua substrate. The auth-marker JSON next to it is overlay too. |
| `jsm-sandbox-auth-marker.v1.json` | `overlay` | Schema for a private mechanism. |
| `naming-convention-distinguishable-ownership.md` | `engine` | Universal pattern (surfaces must read as the operator's, not as generic substrate). |
| `respawn-is-canonical-recovery-for-codex-tmux-stdin-states.md` | `engine-after-rewrite` | Universal codex-tmux failure-mode pattern; tool-name "codex" is fair to keep. |
| `bead-hypothesis-starting-point.md` | `engine` | Pure paradigm primitive. |

**Engine-eligible (pure-pattern) doctrines** identified by sample + name (~25): `substrate-class-classifier`, `meta-primitive-extraction-friction-class`, `meta-primitive-composition-shape-taxonomy`, `meta-primitive-sourcing-pattern-taxonomy`, `meta-primitive-export-shape-taxonomy`, `meta-primitive-substrate-verdict-shape-taxonomy`, `bead-hypothesis-starting-point`, `dispatch-premise-mismatch`, `dispatch-post-send-verification-silent-deaf`, `audit-machinery-hygiene-discipline`, `audit-machinery-hygiene-author-checklist`, `naming-convention-distinguishable-ownership`, `naming-rename-cross-repo-wire-or-explain`, `scope-aware-rename-domain-collision-protection`, `blocker-discipline`, `git-stash-discipline`, `tmp-lifecycle`, `filesystem-as-rag`, `failure-taxonomy`, `cluster-maintainer-pattern`, `forward-link-doctrine-doc-recipe`, `operator-library-recipe`, `complexity-based-model-routing`, `depth-axis-mismatch`, `plan-convergence-gates-positive-practice`.

**Engine-after-rewrite (~50)** — the vast middle. The pattern is universal but the artifact cites specific orchs, dates, or beads. Mechanical projection (`Joshua → {operator}`, `skillos:1 → orch-A`, bead IDs scrubbed, dates abstracted) closes the gap.

**Overlay-only (~15-19):** any doctrine whose load-bearing content IS the instance — `jeff-corpus-substrate-lifecycle.md`, `jsm-canonical-auth-contract.md`, `session-handoff-v0.4-2026-04-27.md`, `L66-L70-adoption-packet-2026-05-01.md`, `tick-script-skillos-doctor-emission.md` (debatable; could be engine-after-rewrite), `option-e-cross-orch-fuckup-log-fold-up.md`.

### 1.2 L-rule corpus — `.flywheel/rules/L*.md`

**Count:** 110 shard files (numbered `L001-L48-*.md` through `L109-L168-*.md`) + `MANIFEST.json`. Note: the **numeric prefix is sort-order (001-109)**, the **canonical L-id is the second number** (L48 through L168). 109 active L-rules.

**Contamination measurements:**
- 46/110 (42%) reference "Joshua" by name
- 38/110 (35%) name a specific client/project (mostly skillos, mobile-eats, alps)
- All cite specific dates (shipped, review_due — these are engine schema fields, not contamination)
- Bead IDs and trauma-class-instance citations are common

**Sample paths + classification:**

| Rule | Class | Notes |
|---|---|---|
| `L001-L48-substrate-exhaustion-before-escalation.md` | `engine-after-rewrite` | "Josh" → `{operator}`; universal pattern (don't escalate to operator before substrate-exhausted). |
| `L002-L29-ntm-only-doctrine.md` | `engine` | Positive-only pane-I/O routing discipline; "ntm" is the tool name (engine-class to keep). |
| `L004-L50-socraticode-mandatory-in-every-dispatch.md` | `engine-after-rewrite` | Pattern universal; "socraticode" is a specific tool — keep as named example or generalize to "semantic code search". |
| `L010-L56-fuckup-log-incidents-canonical-l-rule-promotion-ladder.md` | `engine` | The promotion ladder paradigm; tool-agnostic. |
| `L022-L68-no-silent-darkness-goal-contract.md` | `engine` | Universal observability principle. |
| `L048-L94-shared-sqlite-writes-must-serialize.md` | `engine` | Universal SQLite concurrency rule. |
| `L043-L89-zeststream-voice-public-repo-canonical.md` | `overlay` | This is the *opposite* of the engine — it's the rule that says "public-facing Joshua-owned repos must read as Joshua's voice." Engine for ZestStream brand; overlay for general use. |
| `L099-L148-public-ready-default.md` | `engine` | Universal repo-quality discipline. |
| `L100-L149-pre-commit-gitleaks-mandatory.md` | `engine` | Universal secret-leak discipline. |
| `L107-L156-inbox-discipline-0th-probe.md` | `engine-after-rewrite` | Universal cross-orch coordination primitive. References specific orchs. |
| `L108-L157-outbox-discipline-cross-orch-ship-notification.md` | `engine-after-rewrite` | Same shape. |
| `L109-L168-every-consumer-repo-must-declare-zs-tenant-yaml-at-root.md` | `engine-after-rewrite` | The cross-tenant-isolation pattern is universal; current rule is anchored to ZestStream's `.zs-tenant.yaml` convention. Engine version: "every consumer repo declares its tenant context at root". |
| `L096-L145-orch-handshakes-never-gate-on-joshua.md` | `engine-after-rewrite` | `Joshua → {operator}` makes it engine. |
| `L066-L115-peer-orch-recovery-permit-gate.md` | `engine` | Multi-orch coordination primitive. |
| `L094-L143-codex-prepared-chevron-not-stale-buffer.md` | `engine` | Tool-specific (codex CLI) but the pattern is universal for CLI worker prompts. Could stay tool-named. |

**Engine vs engine-after-rewrite ratio:** estimate ~70 engine (or engine-after-rewrite with just `Joshua → {operator}` substitution), ~30 needing substantive rewrite, ~10 truly overlay-class (`L43-L89-zeststream-voice-public-repo-canonical` and similar brand-locked rules).

### 1.3 Memory rules — `~/.claude/projects/-Users-josh-Developer-flywheel/memory/*.md`

**Count:** 183 markdown files. Bucket breakdown:
- 144 `feedback_*.md` (operational pattern captures)
- 23 `project_*.md` (project-specific state)
- 13 `reference_*.md` (canonical lookup tables)
- 1 `memory_*.md` (correction-class)
- 2 `user_*.md` (operator-specific preferences)
- + `MEMORY.md` (index)

**Contamination measurements:**
- 84/183 (46%) name a specific client/project
- 127/183 (69%) name "Joshua"
- 166/183 (91%) include a specific date (2026-xx-xx)
- **Only 11/183 feedback_*.md files survive the strict pure-pattern grep filter** (no client + no Joshua + no specific date)

**Sample paths + classification:**

| Memory rule | Class | Why |
|---|---|---|
| `feedback_data_decides_not_human_meatpuppet.md` | `engine-after-rewrite` | Pattern (data + methodology → decision; AI doesn't gate on operator). "Joshua → {operator}". |
| `feedback_orch_handshakes_never_gate_on_joshua.md` | `engine-after-rewrite` | Pure pattern; the "Joshua" in the title is the substitution target. |
| `feedback_codex_workers_panes_234.md` | `overlay` | Pane numbers + specific pane assignment. Could be re-authored as engine ("operator names the worker-pane layout in config"), but the artifact as-written is overlay. |
| `project_alps_vrtx_onboarding_priority_2026_05_04.md` | `overlay` | Without client names + date, empty. |
| `feedback_meadows_jeff_mentors.md` | `engine-after-rewrite` | "Joshua articulated these as mentors" → "operator articulates intellectual mentors"; pattern is universal (name your intellectual lineage). |
| `feedback_dispatch_post_send_verify_for_silent_deaf.md` | `engine` | Universal Shape G transport-layer pattern; tool-specific names (ntm, robot-tail) are fair to keep. |
| `feedback_no_push_ntm_br.md` | `overlay` | "Don't push to Jeff's repos" — only meaningful in Joshua-fleet's context. |
| `feedback_jeff_substrate_version_drift.md` | `engine-after-rewrite` | Universal pattern (your substrate's dependencies need version-drift monitoring). |
| `reference_jeff_substrate_inventory.md` | `overlay` | Pure lookup table of Joshua's binaries. |
| `feedback_secrets_class_skip_3_strike_gate.md` | `engine` | The secrets-class META-RULE; universal. References specific L-rules. |
| `feedback_propagator_canonical_ownership_class_aware_gate.md` | `engine-after-rewrite` | Pattern is universal; cites specific scripts (`canonical-doctrine-sync.sh`, `sync-canonical-doctrine.sh`). |
| `feedback_named_client_consent_per_surface_audit.md` | `engine-after-rewrite` | Universal pattern (consent per surface). Currently anchored to a 2026-05-11 incident. |
| `project_zeststream_ai_assessment_north_star_2026_05_11.md` | `overlay` | Joshua's commercial north-star statement. Pure overlay. |
| `feedback_publishability_bar_three_judges.md` | `engine-after-rewrite` | Universal "would three independent judges find this publishable" pattern. Replace "Jeff/Donella/Josh" with role labels. |
| `feedback_class_divergence_public_mit_vs_private_alpha.md` | `engine` | Universal pattern (don't copy canonical files verbatim across audience-class lines). |

**Bucket judgments:**

| Bucket | Approx engine-eligible (engine + engine-after-rewrite combined) | Approx overlay |
|---|---:|---:|
| `feedback_*` (144 total) | ~70-80 after rewrite | ~64-74 overlay-class (or rewritten away from instance examples) |
| `project_*` (23) | 0 | 23 (these ARE the project state) |
| `reference_*` (13) | 0-2 (`reference_watcher_pattern_bank_extension_protocol` is more pattern than reference) | 11-13 |
| `memory_*` (1) | 0 | 1 |
| `user_*` (2) | 0 | 2 (operator-specific preferences by definition) |

**Net publishable memory after sweep: ~70-80 of 183 (38-44%).**

### 1.4 Skills — flywheel-namespaced

**Count and locations:**

- `~/.claude/skills/.flywheel/` — the **flywheel command-suite directory** (slash commands like `/flywheel:plan`, `/flywheel:dispatch`, `/flywheel:loop`, etc.). Contains 30+ subdirectories: `bin/`, `config/`, `data/`, `dispatch-templates/`, `doctrine/`, `hooks/`, `lib/`, `logs/`, `prompts/`, `proposals/`, `references/`, `reports/`, `schemas/`, `scripts/`, `skills/`, `sources/`, `sql/`, `tests/`, `triage/` + ~16 top-level markdown files (`CHANGELOG.md`, `DASHBOARD.md`, `GAPS-LIVE.md`, `GAPS.md`, `GOAL.md`, `INCIDENTS.md`, `LOOP.md`, `MISSION.md`, `PATTERNS.md`, `SCAFFOLD-CONTEXT.md`, `STATE.md`, `WORK.md`) + a SQLite state.db (and -shm/-wal).
- `~/.claude/skills/flywheel/` — a **single skill** with `SKILL.md`, `LATEST.md`, `data/`, `references/`, `respawn/`, `scripts/`. SKILL.md says "Internal placeholder. This skill is intentionally withheld from distribution." — **EXPLICITLY OVERLAY**.
- Other flywheel-named skills: `agentic-coding-flywheel-setup`, `flywheel-connectors`, `flywheel-doctor-author`, `flywheel-end-to-end`, `flywheel-recovery`. Five top-level skills.

**Skills that are skillos-canonical, not flywheel's to publish:**
- `jsm` — skillos-owned skill substrate management
- `skill-builder` — skillos-owned skill authoring
- `dcg.bak.before-jsm-force.20260502T210600Z` — backup of a halted skill version

**Sample classification of flywheel-namespaced skill substrate:**

| Skill / file | Class | Notes |
|---|---|---|
| `~/.claude/skills/.flywheel/LOOP.md` | `engine-after-rewrite` | The flywheel loop protocol; references Joshua's fleet by example. Heavy `Joshua`/path contamination — 138 files in the `.flywheel/` skill-subtree mention Joshua. |
| `~/.claude/skills/.flywheel/MISSION.md` | `overlay` | Joshua's fleet mission. By definition overlay. |
| `~/.claude/skills/.flywheel/GOAL.md` | `overlay` | Joshua's fleet goal. |
| `~/.claude/skills/.flywheel/STATE.md` | `overlay` | Live state. |
| `~/.claude/skills/.flywheel/INCIDENTS.md` | `overlay` | Live incident log. |
| `~/.claude/skills/.flywheel/PATTERNS.md` | `engine-after-rewrite` | Pattern catalog; some patterns universal. |
| `~/.claude/skills/.flywheel/state.db` (+wal/shm) | `overlay` (never publish; live SQLite) | LOAD-BEARING runtime state. Never publish. |
| `~/.claude/skills/.flywheel/sync-config.env.example` | `engine-after-rewrite` | Config template; check for embedded paths. |
| `~/.claude/skills/.flywheel/bin/flywheel-lock-repair` | `engine-after-rewrite` | A CLI; needs path-parameterization. |
| `~/.claude/skills/flywheel/SKILL.md` | `overlay` (per its own self-declaration) | "Internal placeholder; intentionally withheld." |
| `agentic-coding-flywheel-setup` | `engine` (skill scaffold) | Likely a setup skill; needs sampling for hardcoded paths. |
| `flywheel-connectors` | `engine-after-rewrite` | Likely connector-pattern documentation. |
| `flywheel-doctor-author` | `engine-after-rewrite` | Doctor-CLI author skill; engine pattern. |
| `flywheel-recovery` | `engine-after-rewrite` | Recovery skill; references specific session names. |
| `flywheel-end-to-end` | `engine-after-rewrite` | End-to-end skill; check for path contamination. |
| `jsm` | `overlay` / `out-of-scope` | Skillos-canonical. Not flywheel's to publish. |
| `skill-builder` | `overlay` / `out-of-scope` | Skillos-canonical. |

**Cross-repo coordination required:** the boundary between flywheel-owned skills (publishable here) and skillos-owned skills (publishable from the skillos repo, if at all) is not yet drawn. skillos:1 owns ratification on which skills cross into the public engine and which stay private.

### 1.5 Scripts — `.flywheel/scripts/`

**Count:** 358 `.sh` files + 36 `.py` files = **394 total**. (Listing also has subdirs `doctor-invariants/`, `deep-audit/`, `__pycache__/`, several `.bak` files, and a few `.json`/`.plist`/`.md` adjuncts; the 394 count is strictly `.sh|.py`.)

**Contamination measurements:**
- 197/394 (50%) hardcode `/Users/josh/...`
- 65/394 (16%) name a specific client (alps, terratitle, blackfoot, mobile-eats, skillos, elektrafi, vrtx, cubcloud, clutterfreespaces, picoz)
- 50 scripts are *named after* a specific client (`recovery-install-plist-alpsinsurance.sh`, `mobile-eats-end-user-health-probe.sh`, etc.) — they are inherently overlay or per-tenant.

**Sample classification:**

| Script | Class | Notes |
|---|---|---|
| `flywheel-onboard.sh` | `engine-after-rewrite` | The onboard CLI — engine pattern; hardcodes `/Users/josh/Developer/flywheel/templates/...` schema path. Parameterize via `$FLYWHEEL_ENGINE_ROOT`. |
| `flywheel-cron.sh` | `engine-after-rewrite` | Engine-class cron substrate. |
| `flywheel-loop-revive.py` | `engine` | Clean (no `/Users/josh` grep hits in sampled head). |
| `canonical-doctrine-sync.sh` | `engine-after-rewrite` (per CLASSIFICATION-PLAYBOOK; currently HALTED per L168 propagator-ownership-class trauma) | Propagator script. Needs canonical-ownership-class gate before any publish. |
| `sync-canonical-doctrine.sh` | `engine-after-rewrite` (HALTED) | Same. |
| `agents-md-fleet-propagator.sh` | `engine-after-rewrite` (HALTED) | Same — N=3 SATURATION trauma class. |
| `agents-md-shard-extract.sh` | `engine` | The shard-extract pattern. |
| `recovery-install-plist-alpsinsurance.sh` | `overlay` | Per-tenant install. The *pattern* is engine; this artifact is overlay. |
| `recovery-install-plist-clutterfreespaces.sh` | `overlay` | Same. |
| `recovery-install-plist-mobile-eats.sh` | `overlay` | Same. |
| `recovery-install-plist-skillos.sh` | `overlay` | Same. |
| `recovery-install-plist-zeststream-v2.sh` | `overlay` | Same. |
| `mobile-eats-end-user-health-probe.sh` | `overlay` | Specific client. Pattern is in `customer-facing-observability-probe.sh`. |
| `mobile-eats-loop-with-receipt-mirror.sh` | `overlay` | Per-client. |
| `mobile-eats-receipt-bridge.sh` | `overlay` | Per-client. |
| `mobile-eats-path-a-validator.sh` | `overlay` | Per-client. |
| `picoz-archive-and-fresh-2026-05-07.sh` | `overlay` | Per-client + dated one-shot. |
| `jeff-corpus-doctor.sh` | `overlay` | Specific to Joshua's jeff-corpus install. |
| `jeff-binary-version-watchtower.sh` | `engine-after-rewrite` | The watchtower pattern is universal; "jeff" is example. |
| `dispatch-and-verify.sh` | `engine` | Universal dispatch primitive. |
| `validate-callback-before-close.sh` | `engine` | Universal callback validation. |
| `infisical-safe.sh` | `engine-after-rewrite` | Universal secret-tool wrapping pattern; Infisical-specific. |
| `scaffold-canonical-cli.sh` | `engine` | CLI scaffold (pure engine). |
| `scaffold-canonical-cli-py.sh` | `engine` | Same. |
| `disk-reclaim-batch-2026-05-07.sh` | `overlay` | One-shot dated cleanup. |
| `flywheel-adopt.sh` | `engine-after-rewrite` | Engine pattern for adopting a repo. |
| `flywheel-resume` | `engine-after-rewrite` | Resume CLI. |
| `flywheel-recovery.sh` | `engine-after-rewrite` | Recovery wrapper. |
| `daily-report.py` | `engine-after-rewrite` | Daily report engine; verify path-param. |

**Bucket judgment:**
- ~80 scripts are universal engine (the dispatch / validation / classifier / scaffold / probe primitives)
- ~200 are engine-after-rewrite (need path parameterization or example-anonymization)
- ~115 are pure overlay (per-tenant launchd installers, per-client probes, dated one-shots, halted-state scripts)

### 1.6 Hooks — `~/.claude/hooks/`

**Count:** 187 entries in `~/.claude/hooks/` (some directories, some scripts, some `.bak`, some logs). The **canonical pretooluse/posttooluse engine hooks** are 4:

| Hook | Class | Notes |
|---|---|---|
| `pretooluse-bash-secret-guard.sh` | `engine` | Universal pre-bash secret blocker. |
| `pretooluse-bash-cross-repo-guard.sh` | `engine` | Universal cross-repo write guard for bash. |
| `pretooluse-write-edit-cross-repo-guard.sh` | `engine` | Universal cross-repo write guard for Write/Edit tools. |
| `posttooluse-bash-secret-redact.sh` | `engine` | Universal post-bash secret redactor. |

**Other hook content** is a mixed bag: rule2hook artifacts, deep-analysis logs, flywheel-orchestrator-specific gates (e.g., `flywheel-orch-handshakes-never-gate-on-joshua-gate.sh`), CASS cache hooks, mission-anchor injectors, etc. Most are overlay/legacy. The publishable subset is the 4 canonical pretooluse/posttooluse engine hooks (plus a settings.json registration template).

**Sample classification of other notable hooks:**

| Hook | Class | Notes |
|---|---|---|
| `claude-md-reference-hint.sh` | `engine-after-rewrite` | Universal "load CLAUDE.md reference on demand" pattern. |
| `pre-commit/` | `engine` (subset) | Pre-commit hook installer + framework — engine. |
| `mission-anchor-injector.sh` | `engine-after-rewrite` | Mission-anchor injection is engine; the specific anchor content is overlay. |
| `flywheel-orch-*-gate.sh` (multiple) | `engine-after-rewrite` | Each gate encodes a specific L-rule; pattern is engine, current artifact references specific orchs. |
| `block-cron-delete.sh`, `block-service-restarts.sh`, `block-tmux-kill.sh` | `engine` | Universal defensive deny-rule hooks. |
| `pre-bash-safety-fast.sh.original` | `engine` | Universal bash-safety. |
| `accretive-write-gate.sh` | `engine` | Universal accretive-write discipline gate. |

### 1.7 Templates — `templates/flywheel-install/`

**Count:** 62 files under `templates/flywheel-install/` + 4 top-level template files (`fuckup-heuristics.json`, `josh-request-schema.md`, `josh-request-schema.v1-archive.md`, `peer-orch-broadcasts/`).

**Sample paths + classification:**

| Template | Class | Notes |
|---|---|---|
| `templates/flywheel-install/AGENTS.md` | `engine-after-rewrite` | Canonical AGENTS template; identical to `.flywheel/AGENTS-CANONICAL.md`. Mentions Joshua in the embedded L-rule index. |
| `templates/flywheel-install/MISSION.md.tmpl` | `engine` | Pure template (`.tmpl` extension). |
| `templates/flywheel-install/GOAL.md.tmpl` | `engine` | Same. |
| `templates/flywheel-install/STATE.md.tmpl` | `engine` | Same. |
| `templates/flywheel-install/ESCALATION-LADDER.md.tmpl` | `engine` | Same. |
| `templates/flywheel-install/loop.json.tmpl` | `engine` | Same. |
| `templates/flywheel-install/render.sh` | `engine` | The template renderer. |
| `templates/flywheel-install/schema.json` | `engine` | Schema for the install. |
| `templates/flywheel-install/hygiene-targets.schema.json` | `engine` | Hygiene-targets schema. |
| `templates/flywheel-install/launchd/ai.zeststream.flywheel-coordinator-daemon.plist` | `overlay` (ZestStream-branded; per-tenant) | Brand-specific plist. Engine version would parameterize the brand. |
| `templates/flywheel-install/launchd/ai.zeststream.alpsinsurance-coordinator-daemon.plist` | `overlay` | Per-tenant. |
| `templates/flywheel-install/launchd/ai.zeststream.mobile-eats-coordinator-daemon.plist` | `overlay` | Per-tenant. |
| `templates/flywheel-install/launchd/ai.zeststream.picoz-coordinator-daemon.plist` | `overlay` | Per-tenant. |
| `templates/flywheel-install/launchd/ai.zeststream.skillos-coordinator-daemon.plist` | `overlay` | Per-tenant. |
| `templates/flywheel-install/launchd/ai.zeststream.vrtx-coordinator-daemon.plist` | `overlay` | Per-tenant. |
| `templates/flywheel-install/polish-gate/*` (12 files) | `engine` | Polish-gate machinery; pure pattern. |
| `templates/flywheel-install/tests/*` (10 files) | `engine` | Test harness for the polish gate. |
| `templates/flywheel-install/coordinator-config/ntm-config.canonical.toml` | `engine-after-rewrite` | Canonical NTM config; check for `/Users/josh` paths. |
| `templates/josh-request-schema.md` | `overlay` (operator-specific) or `engine-after-rewrite` | The operator-request schema; the *schema* is engine, the name is operator-specific. |
| `templates/peer-orch-broadcasts/doctrine-update-template.md` | `engine-after-rewrite` | Cross-orch broadcast template. |
| `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md` | `engine-after-rewrite` | Same. |
| `templates/fuckup-heuristics.json` | `engine` | Fuckup classification heuristics. |

### 1.8 AGENTS.md substrate

**Files found:**
- `/Users/josh/Developer/flywheel/AGENTS.md` — repo-root AGENTS.md (overlay; the consumer artifact)
- `/Users/josh/Developer/flywheel/.flywheel/AGENTS.md` — project-level AGENTS.md (overlay; the consumer artifact)
- `/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md` — **the canonical paradigm** (~18KB)
- `/Users/josh/Developer/flywheel/templates/flywheel-install/AGENTS.md` — the template (engine candidate)

**Classification:**

| File | Class | Notes |
|---|---|---|
| `.flywheel/AGENTS-CANONICAL.md` | `engine-after-rewrite` | The paradigm document (rule schema + rule index + canonical doctrine). Contains the L-rule index (engine), plus references to specific Joshua-fleet orchestration patterns (rewrite-able). The generator is `agents-md-shard-extract.sh`. |
| `templates/flywheel-install/AGENTS.md` | `engine-after-rewrite` | The template that's distributed to flywheel-installed repos. Identical structure to canonical. Needs name-substitution for public engine. |
| `flywheel/AGENTS.md`, `flywheel/.flywheel/AGENTS.md` | `overlay` | The materialized instances in this specific repo. Not for publishing as-is. |

---

## 2. Top-N hot-spot lists

### 2.1 Top 10 doctrines that are universally valuable

These would be saddest to keep private — high-value engine candidates:

1. **`substrate-class-classifier.md`** — the L162 paradigm primitive. Five-class substrate taxonomy + classification rule. Resolves three traumas (propagator clobber, hook-on-own-fixture, cobbler's-children). **Engine; lightly de-personalize.**
2. **`meta-primitive-extraction-friction-class.md`** — extraction-friction taxonomy.
3. **`meta-primitive-composition-shape-taxonomy.md`** — primitive-composition shapes.
4. **`meta-primitive-sourcing-pattern-taxonomy.md`** — sourcing patterns.
5. **`meta-primitive-export-shape-taxonomy.md`** — export shapes.
6. **`meta-primitive-substrate-verdict-shape-taxonomy.md`** — verdict shapes.
7. **`bead-hypothesis-starting-point.md`** — "bead body is Bayesian prior, not posterior" (root-cause discipline).
8. **`audit-machinery-hygiene-discipline.md`** + `audit-machinery-hygiene-author-checklist.md` — the audit-machinery substrate.
9. **`naming-convention-distinguishable-ownership.md`** + `naming-rename-cross-repo-wire-or-explain.md` — naming discipline pair.
10. **`failure-taxonomy.md`** + `cluster-maintainer-pattern.md` — failure classification + cluster maintainer paradigm.

### 2.2 Top 10 doctrines most contaminated with client/project names

These need heavy rewrite or relegation to overlay:

1. **`jeff-corpus-substrate-lifecycle.md`** — anchored to Joshua's jeff-corpus install.
2. **`jeff-daily-corpus-diff.md`** — Jeff intel rhythm.
3. **`tick-script-skillos-doctor-emission.md`** — skillos-anchored.
4. **`jsm-canonical-auth-contract.md`** — JSM-anchored.
5. **`jsm-sandbox-auth-marker.v1.json`** — schema for JSM.
6. **`option-e-cross-orch-fuckup-log-fold-up.md`** — cross-orch instance.
7. **`session-handoff-v0.4-2026-04-27.md`** — version + date in title.
8. **`L66-L70-adoption-packet-2026-05-01.md`** — dated adoption packet.
9. **`mission-fidelity-substrate.md`** — pattern universal, evidence cites flywheel-specific scripts.
10. **`cross-repo-write-path-discipline.md`** — pattern universal, references specific propagator scripts. (Worth the rewrite — load-bearing engine doctrine.)

### 2.3 Skills that are skillos-canonical (not flywheel's to publish)

Cross-repo coordination needed with skillos:1 / Joshua before any of these are touched:

- `~/.claude/skills/jsm` — Joshua's Skill Manager; skillos-managed substrate
- `~/.claude/skills/skill-builder` — skillos-owned skill authoring
- `~/.claude/skills/dcg.bak.before-jsm-force.20260502T210600Z` — backup of halted DCG skill (skillos-managed)
- The skillos-namespaced skills (cm, br, mem, bv, bvp, bvg adapters; the canonical-CLI-scoping skills; the polish-related skills) all need skillos ratification before classification

### 2.4 Scripts that hardcode `/Users/josh/...` paths

197/394 = **50% of scripts**. These all need parameterization before publish. The pattern of the parameterization:

- `${HOME}` for user home directory
- `${FLYWHEEL_ENGINE_ROOT:-$HOME/.flywheel}` for engine install
- `${FLYWHEEL_PROJECT_ROOT:-$(pwd)}` for the current project
- `${NTM_BIN:-$(command -v ntm)}` for external tool binaries

**High-traffic offenders** (sampled):
- `flywheel-onboard.sh` — hardcodes `/Users/josh/Developer/flywheel/templates/flywheel-install/hygiene-targets.schema.json`
- `mobile-eats-end-user-health-probe.sh` — `${MOBILE_EATS_REPO:-/Users/josh/Developer/mobile-eats}` (already env-overridable; good pattern)
- `skillos-notify.py` — `/Users/josh/.local/bin/ntm` (hardcoded; needs `$NTM_BIN`)
- `recovery-install-plist-*.sh` (5 files) — per-tenant; overlay-class; **don't publish**
- Most `flywheel-*.sh` and `dispatch-*.sh` scripts have `/Users/josh` in error messages or example invocations

### 2.5 Memory rules that are pure-pattern (publish-eligible with minimal rewrite)

The 11 that survive the strict grep filter (no client, no Joshua, no date):

(Verified by running the filter; sample includes:)
- `feedback_basename_keying_collision_class.md`
- `feedback_bash_regex_no_brace_repetition.md`
- `feedback_br_prefix_mismatch_is_schema_drift.md`
- `feedback_breadth_first_substrate_inventory.md`
- `feedback_ci_substrate_failures_need_owner_route.md`
- `feedback_cross_repo_consumer_vs_mutator_distinction.md`
- `feedback_dispatch_to_lib_not_bin_for_split_modules.md`
- `feedback_drift_detector_self_validates_via_p2_receipts.md`
- `feedback_evidence_pack_replaces_four_lens.md`
- `feedback_lost_callback_artifact_reconstruction.md`
- `feedback_validator_uses_isolated_tmpdir.md`

The other ~60-70 engine-eligible feedback memory rules each need a one-pass mechanical substitution (`Joshua → {operator}`; date → "<incident-date>"; `skillos:1 → orch-A`; etc.).

### 2.6 Memory rules that are pure-instance (overlay-only forever)

Roughly **~100 of 183 memory rules** fall here. Representative paths:

- All 23 `project_*.md` rules (these ARE the project history)
- All 11 `reference_*.md` rules naming Joshua's specific binaries / paths
- 2 `user_*.md` (operator preferences)
- ~60 `feedback_*.md` rules whose load-bearing content IS the specific incident:
  - `feedback_alps_real_path.md` (would be removed entirely)
  - `feedback_caam_rotation_on_codex_token_limits_2026_05_08.md`
  - `feedback_codex_cli_21620_agents_subdir_workspace_write_bug.md`
  - `feedback_picoz_archive_and_fresh_2026_05_07.md` (if present; one-shot)
  - All "skillos-specific behavior" memory rules
  - All "mobile-eats-specific behavior" memory rules
  - etc.

---

## 3. Failure-mode catalogue (the de-personalization sweep can go wrong)

These are the concrete risks the sweep needs to handle:

1. **Load-bearing example destruction** — Doctrine like `substrate-class-classifier.md` references the N=3 SATURATION clobber + the L160 AKID-fixture trip + the 425 dirty-files trauma as motivating examples. Mechanically replacing dates and orch names removes the *credibility* of the doctrine. **Mitigation:** abstract the example to "an N=3 cross-repo-clobber observed during early development," preserve the *shape* of the trauma, lose the *instance metadata*.

2. **Skillos / flywheel boundary erosion** — The flywheel repo contains doctrine about JSM, skillos handshakes, the skill-builder workflow. These are skillos-owned in the cross-orch taxonomy. **Mitigation:** flywheel:1 + skillos:1 jointly decide which doctrines stay in flywheel-engine, which migrate to skillos-engine, and which become overlay-class cross-references.

3. **Propagator-script-state phantom-engine class** — Three propagator scripts are HALTED per L168 / propagator-canonical-ownership-class-aware-gate (memory rule 2026-05-12). The scripts contain engine logic but cannot run safely until the gate exists. **Risk:** publishing them implies they work; adopters who run them on their own repos hit the same N=3 SATURATION trauma. **Mitigation:** ship them with an explicit `STATUS: requires substrate-class manifest before invocation` README; or do not ship until the gate is canonical.

4. **Hardcoded path contract changes** — Parameterizing `/Users/josh/.local/bin/ntm` to `$NTM_BIN` is a **contract change**. Existing flywheel installations don't set `$NTM_BIN`. **Mitigation:** preserve the hardcoded default (`${NTM_BIN:-$HOME/.local/bin/ntm}`); document the env var; provide a per-project `.envrc`.

5. **Memory-rule trauma-class loss** — A memory rule like `feedback_orch_paralysis_recurring.md` captures *recurrence* — the third+ correction to a single failure mode. De-personalizing loses the "this is the Nth time you said this" frame, which is what makes it L-rule-promotable. **Mitigation:** preserve the recurrence-counter ("N=3 incidents observed before promotion") as an abstract field; lose only the specific dates.

6. **L-rule numeric ID continuity** — The L-rules are numbered L48-L168. Public engine probably wants L1-L100 contiguous. **Risk:** renumbering breaks every back-reference in the trauma corpus + the 109 L-rule shard filenames + the regenerated AGENTS.md. **Mitigation:** preserve numbering. Engine ships with a `# Note: L-rule IDs preserve historical promotion order; gaps reflect retired or non-published rules` preface.

7. **`.flywheel/AGENTS-CANONICAL.md` is auto-generated** — It's the output of `agents-md-shard-extract.sh`. **Risk:** any manual edit during the sweep gets blown away on next extract. **Mitigation:** sweep edits go in the L-rule shards under `.flywheel/rules/`, not in AGENTS-CANONICAL.md.

8. **Templated launchd plists are per-tenant** — `templates/flywheel-install/launchd/ai.zeststream.<tenant>-coordinator-daemon.plist` — six of them, all naming specific tenants. **Risk:** publishing them leaks the Joshua-fleet tenant list. **Mitigation:** ship one canonical `ai.<brand>.<tenant>-coordinator-daemon.plist.tmpl` template; the six existing plists move to overlay.

9. **State.db in `.flywheel/` skill subtree** — `~/.claude/skills/.flywheel/state.db` (+ -shm/-wal) is a live SQLite DB. **Risk:** if the public engine's skill scaffolding inadvertently ships the DB, runtime state from Joshua's fleet leaks. **Mitigation:** explicit `.gitignore` + publish-time strip; the engine ships an empty schema file, not a populated DB.

10. **Memory rule index file `MEMORY.md` is system-prompt-injected** — It's load-bearing for Claude Code's UserPromptSubmit injection. **Risk:** stripping client/Joshua mentions from the engine version diverges from the original; recompositing for adopters is non-trivial. **Mitigation:** engine ships an *empty* `MEMORY.md` with the index schema documented; adopters' memory rules populate it on their side.

11. **CLAUDE.md global-ref file** — `~/.claude/CLAUDE.md` (Joshua's private global instructions) is what binds everything together. **Risk:** the engine repo references it, but it's overlay by definition. **Mitigation:** engine ships a `CLAUDE.md.template` (sections + schema + example slots); adopter composes their own.

12. **Beads JSONL and dispatch logs** — `.beads/issues.jsonl` (the bead history) and `.flywheel/dispatch-log.jsonl` (the dispatch history) are overlay. **Risk:** if the engine repo includes them in any test fixture or doc example, real bead IDs leak. **Mitigation:** scrub all `flywheel-[a-z0-9]{5,7}` IDs from doc examples; use `flywheel-xxxxxx` placeholders.

13. **Cross-orch handoff history** — `.flywheel/handoffs/*.md` (~30+ files) contains live cross-orch communication. **Risk:** publishing means publishing the multi-pane operations history. **Mitigation:** overlay-only; engine ships an empty `.flywheel/handoffs/.gitkeep` + a doc explaining the protocol.

14. **PLANS directory** — `.flywheel/PLANS/<plan-slug>/` (~20+ historical plan-space arcs). **Risk:** they're rich with client names, dates, decisions. **Mitigation:** overlay-only. Engine ships a `PLANS/.gitkeep` + a `PLANS-README.md` explaining the 5-phase /flywheel:plan protocol.

15. **The `flywheel` skill itself** is marked "intentionally withheld" — explicit overlay. **Risk:** if extraction inadvertently follows the skill-namespace convention and copies it, the explicit withhold is bypassed. **Mitigation:** publish allowlist, not denylist; only artifacts explicitly classified `engine` are extracted.

16. **The `MISSION.md` paradigm vs Joshua's MISSION.md content** — The *paradigm* (mission-anchor injection on every tick) is engine. Joshua's specific mission is overlay. **Risk:** the LOOP.md doctrine references Joshua's MISSION.md content as example. **Mitigation:** rewrite examples to use synthetic mission ("$\{operator\}'s mission: build a self-sustaining flywheel for client work").

17. **Skill-builder skill is skillos-canonical** — Adopters of flywheel-engine will want to build their own skills. **Risk:** if engine doesn't include a way to build skills, the engine is incomplete. **Mitigation:** flywheel-engine documents the *interface* (skills directory, SKILL.md format, sentinel comments); the *implementation* of a skill-builder is downstream (skillos repo).

18. **L-rule retroactive promotion** — Some L-rules cite memory rules as their origin (e.g., L156 cites `inbox-discipline-missed-during-deep-burndown-motion.md`). **Risk:** if the memory rule is overlay but the L-rule is engine, the engine has a dangling reference. **Mitigation:** doctrine cross-references use abstract trauma-class names, not memory-rule filenames.

19. **The `.zs-tenant.yaml` substrate (L168)** is ZestStream-specific by name. **Risk:** engine adopters don't have a ZestStream tenant registry. **Mitigation:** rename engine version to `.flywheel-tenant.yaml` (or operator-chosen); document the convention.

20. **Brand language in templates** (e.g., `ai.zeststream.flywheel-coordinator-daemon.plist`). **Risk:** ZestStream brand is in the canonical template. **Mitigation:** template name uses `${BRAND}` placeholder.

---

## 4. Criticality matrix

Ranked by composite (Volume × Value-to-public × Risk), low-effort first:

| Substrate category | Volume | De-personalization effort (avg per artifact) | Value-to-public | Risk | Priority |
|---|---:|---|---:|---:|---:|
| Templates (`templates/flywheel-install/*`) | 62 | low-medium (param + tenant strip) | HIGH (the install scaffold) | LOW (well-bounded) | **P0** |
| Canonical hooks (4 pretooluse/posttooluse) | 4 | low (already generic) | HIGH (safety substrate) | LOW | **P0** |
| AGENTS.md substrate | 1 canonical + 1 template | medium (auto-generated; touch shards) | HIGH (the rule index) | LOW | **P0** |
| L-rule corpus | 109 | low-medium per rule (~1-3 substitutions each) | VERY HIGH (the trauma-class promotion ladder) | MEDIUM (some are brand/voice-specific) | **P1** |
| Doctrine corpus | 94 | medium-high (many need pattern-extraction rewrite) | VERY HIGH (the paradigm primitives) | MEDIUM (load-bearing examples) | **P1** |
| Scripts | 394 | high (50% need path-param; many are overlay) | MEDIUM (engine primitives) + HIGH (installer/scaffold) | MEDIUM (per-tenant scripts must NOT publish) | **P2** |
| Memory rules | 183 | high (heavy rewrite; only 11 pure-pattern) | MEDIUM-HIGH (the operational corpus) | HIGH (most contain client names) | **P3** (or stay overlay) |
| Flywheel-namespaced skills | 6 top-level + `.flywheel/` subtree | very high (heavy contamination + skillos cross-repo) | HIGH (slash-commands UX) | HIGH (state.db, MISSION/GOAL/STATE) | **P3** + skillos coord |
| Other hooks (~180 of 187) | ~180 | varies | LOW-MEDIUM (legacy + experimental) | LOW | **P4** (defer) |

**Composite ranking explanation:**
- Templates + canonical hooks + AGENTS.md ship FIRST. They're small, clean, and the foundation of the engine install.
- L-rules + doctrine ship SECOND. They're the substantive intellectual contribution.
- Scripts ship THIRD, in waves. Per-tenant scripts move to overlay. Engine primitives parameterize.
- Memory rules + flywheel-namespaced skills ship LAST or partially. Many will simply stay overlay.

---

## 5. Cross-cutting observations

### 5.1 Engine/overlay boundary is achievable but not mechanical

The CLASSIFICATION-PLAYBOOK's four-question filter works as a *triage* mechanism — it correctly identifies the three classes. But the *rewrite* effort for engine-after-rewrite artifacts is substantial because:
- Many doctrines use load-bearing client/incident examples
- The trauma-class promotion ladder cites specific past traumas as evidence
- ~50% of scripts hardcode paths that need parameterization (a contract change, not a substitution)

A worker-hour estimate of 10-15 hours (from CLASSIFICATION-PLAYBOOK §How to dispatch the sweep) is **optimistic by 3-5×** based on this inventory. Realistic effort: 40-60 worker-hours across parallel workers, plus 4-6 worker-hours of flywheel:1+Joshua ratification on edge cases.

### 5.2 Skillos coordination is on the critical path

The flywheel/skillos boundary is currently fuzzy:
- JSM skill: skillos-owned
- skill-builder: skillos-owned
- agent-mail skill (`~/.claude/skills/agent-mail/`): unclear (could be either)
- The `.flywheel/` slash-command suite: flywheel-owned but composes skillos primitives

Lane B/C (or downstream phases) should produce a cross-repo coordination handoff to skillos:1 before any skill substrate is extracted.

### 5.3 Two-repo, not one-repo, may be cleaner

The intent says "github.com/JYeswak/flywheel". A single repo is the stated target. But the analysis suggests two natural artifacts:

- `flywheel-engine/` — the universal substrate (doctrine, L-rules, scripts, templates, hooks)
- `flywheel-overlay-example/` — a working example of an overlay (anonymized) that adopters fork or copy

This is consistent with PAI's pattern (Personal_AI_Infrastructure / personal/private separation). Worth surfacing in Phase 2 (REFINE).

### 5.4 What's missing from current substrate that public adopters will need

Not yet in the inventory but required for the public engine:
- A `README.md` written for external developers (not internal-flavored)
- A `LICENSE` (intent says MIT)
- A `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`
- A `flywheel init` first-run wizard
- A working `hello-world` example repo (separate)
- Architecture diagrams (currently no `.png`/`.svg`)
- A `flywheel.zeststream.ai` documentation site (Nextra or similar)

These are NEW artifacts to author, not extractions from existing substrate.

---

## 6. Recommended Phase 2 (REFINE) handoff content

For the REFINE phase, the synthesis lane should consume:

1. **This inventory** (volume + contamination measurements + sample classifications)
2. **The criticality matrix** (priority sequencing)
3. **The failure-mode catalogue** (risks to design around)
4. **Lane B/C outputs** (PAI gap analysis and brand/audience research, expected)

The REFINE output should:
- Lock the engine/overlay boundary at file-class level (not just paradigm-level)
- Decide flywheel ↔ skillos boundary (cross-repo coord with skillos:1)
- Decide one-repo vs two-repo
- Decide L-rule numbering (preserve vs renumber)
- Decide installer mechanism (curl|bash vs npm vs homebrew)
- Decide brand language (preserve ZestStream/flywheel.zeststream.ai vs neutralize)
- Produce a per-substrate-category WORK ESTIMATE in worker-hours

---

## 7. Acceptance check

| Acceptance criterion | Status |
|---|---|
| Inventory covers all 8 categories with real counts | ✓ (94 doctrines, 110 L-rules, 183 memory rules, 6+ flywheel skills, 394 scripts, 187 hook entries [4 canonical], 62 template files, 4 AGENTS.md files) |
| Each substrate category has ≥5 example file paths (or all if <5) | ✓ (every category has 5+ sample paths with classification) |
| Classification rule applied to ≥30 representative artifacts | ✓ (~80 artifacts classified across the 8 categories) |
| Failure-mode catalogue has ≥10 concrete risks | ✓ (20 risks documented) |
| Criticality matrix is a real table | ✓ (§4) |
| File written to specified path | ✓ (this file) |

---

*End of Lane A research artifact. Hand off to Phase-2 synthesis. STATE.json should advance from `01-RESEARCH` to `02-REFINE` only after Lanes B (industry / PAI gap) and C (brand / audience) also land.*
