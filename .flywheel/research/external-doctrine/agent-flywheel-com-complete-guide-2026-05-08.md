# agent-flywheel.com Complete Guide — Local Index 2026-05-08

Source: https://agent-flywheel.com/complete-guide
Pulled: 2026-05-08T02:40Z (via WebFetch)

This is the upstream public doctrine for the "agent flywheel" methodology. Pulled for local study + gap analysis vs flywheel-canonical (our doctrine in `~/.claude/skills/.flywheel/AGENTS.md` + `templates/flywheel-install/AGENTS.md`).

## Table of contents (verbatim)

1. The Complete Workflow
2. Why Planning Is 85% of the Work
3. Creating & Refining the Markdown Plan
4. Converting the Plan into Beads
5. Check Your Beads N Times, Implement Once
6. The Coordination Stack
7. Launching & Running the Swarm
8. Review, Testing & Hardening

---

## Core concepts (verbatim definitions)

| Concept | Definition |
|---|---|
| **Markdown Plan** | "A huge design document where the whole project still fits in context" — architecture, workflows, tradeoffs, intent |
| **Bead** | "A self-contained work unit in br with context, dependencies, and test obligations" |
| **Bead Graph** | "The full dependency structure across all beads" |
| **Plan Space** | "Where you are still shaping the whole system" — 1x rework cost |
| **Bead Space** | "Where you are shaping executable work packets" — 5x rework cost |
| **Code Space** | "Implementation and verification layer inside the codebase" — 25x rework cost |
| **Agent Mail** | High-bandwidth coordination layer; advisory locks + TTL expiry |
| **bv** | Graph-theory routing — PageRank, betweenness, critical-path |
| **AGENTS.md** | "The operating manual every agent must reload after compaction" |
| **Fungible Agents** | Generalist, interchangeable; no specialist roles or ringleaders |
| **Compaction** | Context compression triggering mandatory AGENTS.md re-read |
| **Skill** | "A reusable instruction bundle that teaches agents how to use a tool or execute a workflow" |
| **Fresh Eyes Technique** | New agent sessions with no accumulated assumptions |
| **Best-of-All-Worlds Synthesis** | Multi-model planning → GPT Pro hybrid |
| **Idea-Wizard** | Six-phase pipeline for adding features to existing projects |
| **DCG (Destructive Command Guard)** | Mechanical block on `git reset --hard`, `--force`, `rm -rf`, `git checkout --` |

---

## Methodology arc (8 phases — verbatim)

1. **Intent (Planning)** — competing plans → best-of-all-worlds → 4-5 refine rounds → 3,000-6,000+ line plan
2. **Planning Leverage** — front-load decisions while 1x cost
3. **Bead Conversion** — plan → 200-500 self-contained beads with full context embedded
4. **Bead Polishing** — 4-6+ fresh-session rounds, dedup, convergence ≥0.75
5. **Swarm Launch** — typical ratio 2 Claude, 1 Codex, 1 Gemini; stagger 30s+
6. **Implementation & Coordination** — Agent Mail file reservations, bv routing, single main branch
7. **Testing & Hardening** — UBS, cross-agent review, random code exploration
8. **Polish & Shipping** — platform-specific UI/UX, de-slopify docs

**Outcome exemplar:** 5,500-line plan → 347 beads → 11,000 LOC → 25 agents → 204 commits → ~5h to ship.

---

## Tools/binaries named (verbatim)

`br` · `bv` · Agent Mail (MCP) · `ntm` · UBS · DCG · Codex · Claude Code · Gemini-CLI · WezTerm · Ghostty · Zellij · CAAM · FrankenTerm · GitHub Pages Export

---

## Anti-patterns (verbatim list)

1. Pseudo-beads in markdown
2. Plan-bead gap (orphaned artifacts)
3. Vague beads (agents improvise architecture)
4. Missing dependencies
5. Thin AGENTS.md
6. No Agent Mail
7. Worktrees
8. Thundering herd
9. Over-coordination ("communication purgatory")
10. Strategic drift
11. Forcing beads too early
12. Specialist agents
13. Ringleader agents
14. Stashing/reverting other agents' work
15. Compaction amnesia
16. Oscillation in bead polish
17. Early polish termination
18. Oversimplification during synthesis
19. LLM writing artifacts ("let's dive in", "at its core", emdash overuse)

---

## Convergence criteria (verbatim)

**Plan refinement:** weighted score 0.75+ ready, 0.90+ diminishing returns
**Bead polishing:** rounds 1-3 major fixes, 4-7 architecture, 8-12 edge cases, 13+ polish; stop on incremental
**Code review:** 1-3 self-review rounds; alternate cross-agent + random until clean
**Swarm health:** steady bead progress · low idle burn · zero lock conflicts · steady push frequency · comprehensive coverage · no "come to Jesus" moments

---

## GAP ANALYSIS — what we (flywheel-canonical) have that they DON'T

These are unique flywheel-canonical contributions beyond agent-flywheel.com's public doctrine:

### Substrate primitives
- **Doctrine version stamping + cross-repo propagation** (L126, doctrine-sync.sh, doctrine-broadcast-send.sh sidechannel) — agent-flywheel.com mentions AGENTS.md but no fleet-wide propagation
- **Mission-lock** (`/flywheel:mission-lock`) — pre-resolves Joshua-blocker classes 1-4 (vendors, tier, budget, ToS) at project start; eliminates ~80% of "Joshua-disposes?" pauses
- **Three Reasoning Spaces** rubric in CLAUDE.md (plan/bead/code @ 1x/5x/25x cost) — they share the cost model but we've operationalized it as a skill-routing decision criterion
- **6 TRUE Joshua-blocker classes** — explicit precedence-ordered taxonomy of when human-in-loop is mandatory vs phantom

### Trauma classes & recovery
- **fuckup-log.jsonl** with promotion class taxonomy (frozen-codex-spinner, phantom-Joshua-blocker, worker-closes-without-commit, etc.) — agent-flywheel.com has no analog
- **Frozen-pane detector** (scrollback-byte-delta) — they have nothing for codex spinner-misclassified-as-thinking
- **Codex template stuck detector** with `buffer_stuck` / `input_deaf` / `post_completion` subclasses
- **Respawn-then-relaunch** discipline (respawn drops to bare zsh; agent CLI must be relaunched manually)
- **Pane state via --robot-activity** as canonical worker-state truth
- **Peer-orch respawn permit gate** for cross-session pane recovery

### Orchestration discipline
- **Topology-lookup-before-dispatch** rule (session-topology.jsonl as primary key, NOT pane index assumption)
- **Callback-first dispatch** + delivery validation contract
- **caam profile swap on usage-limit** (sub-30s vs ~2hr wall-clock wait)
- **L120 br_close_executed** as mandatory callback field
- **L126 evidence-pack-replaces-self-grade** — relational evidence (compliance_score, compliance_pack_path) vs simple "I did it"
- **L127 (pending) WORKER-CLOSE-REQUIRES-GIT-COMMIT** — they have `commit early and often` but no enforcement gate

### Plan-space tooling
- **/flywheel:plan 5-phase pipeline** (RESEARCH → REFINE → AUDIT → DECOMPOSE → POLISH) with state machine + auto-advance algorithm
- **plan-space-convergence skill** as MANDATORY before `br create` for non-trivial work
- **dueling-idea-wizards** skill — multi-agent adversarial generation
- **multi-model-triangulation** skill — operationalized version of their "best-of-all-worlds"
- **jeff-convergence-audit** Phase 1 broad sweep — three-judges (Jeff/Donella/Joshua) 9.5/9.5/9.5 close gate
- **research-triad** (3-lane parallel: A=problem-space, B=ecosystem-audit, C=implementation-design)

### Coordination beyond Agent Mail
- **doctrine-broadcast-send.sh sidechannel** — file-based pub-sub for fleet doctrine updates (built TODAY because Agent Mail's recipient-approval policy gates intra-fleet handshakes; they don't have this gap because they don't run multi-orch fleet)
- **Cross-orch handoff via /tmp/<peer>_doctrine_note.md** — alps→flywheel pattern (used today: alps loop-staleness note, mobile-eats audit handoff)
- **Peer-orch idle-on-blocker** + **flywheel:1 owns peer recovery**

### Audit & verification
- **/beads-compliance-and-completion-verification** skill (Jeff's; we wrap heavily)
- **NTM-SURFACE-INVENTORY.md** with verification status column (108 surfaces classified VERIFIED-USE / LATENT-USE / WIRE-IT-QUEUED / RECLASSIFIED-{EXCLUDED,WRAP-ALIAS,ISSUE})
- **Wire-or-explain ledger** — every classification is data-backed, never aspirational
- **Watcher pattern bank** with extension protocol — unknown_stable detector outputs become beads + pinned patterns

### Substrate hygiene
- **session-residue-prune.sh + storage-prune.sh** — dry-run-first hygiene with idempotency-key contract
- **socraticode K≥10 doctrine** — semantic codebase search before grep/read for code claims (their guide doesn't mention semantic search)
- **dispatch-log.jsonl** as canonical event substrate with schema versioning

### Brenner-style discipline (just adopted today)
- **Hypothesis slate + kill criteria** in /flywheel:plan Phase 2 (shipped today via daxk3)
- **Evidence-pack v2 with relational supports/refutes/informs** (in flight on pane 3 via lvm43)
- **Prediction-lock receipts** for high-risk plan hypotheses (queued: gau3q)

---

## GAP ANALYSIS — what THEY have that we should consider

### 1. Explicit "lie to them" technique
Their guide names a specific technique: claim 80+ missed elements exist to force exhaustive re-review. We don't have an explicit name for this — could be a useful addition to /multi-model-triangulation or /flywheel:plan Phase 2 refinement.

**Action:** consider a `lie-to-them-rerun` substep in plan refinement when convergence stalls without delta.

### 2. Idea-Wizard 6-phase pipeline (specific shape)
Their explicit shape: ground in reality → 30 ideas → winnow to 5 → expand to 15 → human review → beads → 4-5 refine. We have `idea-wizard` skill but our shape may differ; worth comparing.

**Action:** read our `idea-wizard` skill, compare to their 6-phase shape, decide if we want their winnow-cardinality (30→5→15).

### 3. Explicit convergence numbers (0.75 / 0.90)
We have convergence concepts but they've nailed specific thresholds. Worth adopting in our /flywheel:plan close-gate.

**Action:** add weighted convergence score field to /flywheel:plan STATE.json schema with 0.75 ready / 0.90 diminishing thresholds.

### 4. "Come to Jesus moments" as anti-pattern
They name strategic drift watching as "no come to Jesus moments" — meaning no hard course-corrections. We have `feedback_orch_paralysis_when_data_specifies_action` but not the inverse: regular plan-vs-actual drift checks.

**Action:** consider adding plan-vs-actual drift probe to /flywheel:tick.

### 5. Bead polishing rounds-by-content (1-3 fixes, 4-7 architecture, 8-12 edges, 13+ polish)
Concrete schedule. We've been doing rounds without a content-shape map.

**Action:** add round-content-expectation table to beads-workflow skill.

### 6. Stagger starts 30+ seconds
Specific anti-thundering-herd rule. We start fleets via ntm spawn; not sure if there's a built-in stagger.

**Action:** check `ntm spawn` flags for stagger; add if missing or document our approximation.

### 7. Outcome exemplar (5500 lines plan → 347 beads → 11k LOC → 25 agents → 204 commits → 5h)
Concrete success-shape benchmark. We don't track plan-LOC/bead-count/commit-count ratios.

**Action:** add to flywheel:status dashboard.

### 8. UBS as quality gate before EVERY commit
Pre-commit-hook style. We have UBS skill but don't enforce per-commit.

**Action:** consider DCG-style pre-commit hook running UBS on changed files.

### 9. De-slopify named patterns
They name specific telltale patterns: emdash overuse, "let's dive in," "at its core". Our `de-slopify` skill exists; verify pattern coverage.

**Action:** read our de-slopify skill, compare named patterns.

### 10. Platform-specific polish (desktop + mobile UI/UX separately)
Their guide separates these. Our /flywheel:polish doesn't.

**Action:** if we ship UI work, consider platform-split polish rounds.

---

## What we have but THEY don't track (not gaps; uniqueness)

- Multi-orch fleet (5+ session) coordination — they assume single-orch swarm
- Cross-repo doctrine propagation
- Trauma class promotion (fuckup-log → memory rule → L-rule → cross-repo broadcast)
- Mission-lock as Joshua-blocker pre-resolution
- Mobile-eats / alps / zesttube / picoz / skillos productized fleet membership
- Brenner-methodology adoption (kill-first hypotheses, relational evidence packs)
- Loop-staleness elimination (event-driven Monitor on dispatch-log)

---

## Recommended next moves

**Tier 1 (file as beads now):**
1. Convergence-score thresholds (0.75/0.90) into /flywheel:plan
2. Bead polishing rounds-by-content table into beads-workflow
3. Verify our idea-wizard skill matches the 30→5→15 shape; close gap if not

**Tier 2 (research first):**
4. UBS pre-commit hook (sniff how invasive vs current /sniff-rubric)
5. Platform-split polish rounds (only if UI work is on roadmap)
6. Plan-vs-actual drift probe in /flywheel:tick (Donella systems-thinking adjacent)

**Tier 3 (lower priority):**
7. "Lie to them" technique formalization
8. De-slopify pattern coverage audit
9. Stagger-spawn enforcement (verify ntm spawn behavior)
10. flywheel:status outcome-shape benchmarks

**No-action items (we already have or do better):**
- AGENTS.md re-read after compaction (we have post-compact-reminder skill)
- File reservations + Agent Mail (we use; plus we have file-sidechannel for doctrine)
- Single main branch (we follow)
- Fungible agents (our flywheel-pane2/3/4 all read same AGENTS.md)
- DCG (we use Jeff's; recently tuned)

---

## Doctrine summary (verbatim)

> "The whole game" is moving "the hardest thinking into representations that still fit into model context windows." Planning dominates because reasoning about a 6,000-line plan is cheaper and faster than refactoring a 100,000-line codebase.

This matches our Three Reasoning Spaces (1x / 5x / 25x rework) doctrine exactly — they framed it as "context-window-fit thinking-representation" which is a good linguistic handle worth borrowing.

> The human is the "clockwork deity": design the machine (plan + beads), set it running (launch swarm), and tend it (monitor, unblock, review).

Aligns with our "Joshua tends the swarm; Claude orchestrates 9 petals; workers implement beads" doctrine. Their "clockwork deity" framing is sharper than our description; consider importing the term.

---

## Source

Pulled 2026-05-08T02:40Z via WebFetch from https://agent-flywheel.com/complete-guide. Single fetch; structurally extracted by Claude Opus 4.7 with verbatim preservation of named concepts.
