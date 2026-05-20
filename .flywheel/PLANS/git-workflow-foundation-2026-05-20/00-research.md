# Git/Workflow Management Foundation — Research Artifact

**Bead:** flywheel-m9yxr (P0)
**Joshua-direct:** 2026-05-20T19:45Z — "research best practices on git/workflow management and bake them into the foundation of our entire ecosystem. Full runbooks system wide with inventoried assets / stashes, worktrees getting left, etc."
**Phase:** PLAN-SPACE research (implementation deferred to follow-up beads)
**Mission-anchor:** Duty 3 (substrate-published) — git hygiene is sub-aspect of public-substrate state. Sister to Duty 1 (mission-locked) and Duty 5a (auto-push doctrine, flywheel-jrpfn).
**Audit baseline:** 285 extra worktrees, 206 stashes, 177 unpushed branches fleet-wide (2026-05-20T19:45Z).

---

## 0. TL;DR — Adopt / Evaluate / Skip Verdict Per Discovery

| Discovery | Source(s) | Verdict | Mission Duty |
|---|---|---|---|
| `git worktree remove` over `rm -rf`, paired with `git worktree prune` | git-worktree-manager SKILL.md L132, INCIDENTS dcg-worktree-remove-block, Augment Code 2026 guide | ADOPT (already canon) | Duty 3 |
| One agent per worktree, one worktree per branch | git-worktree-manager SKILL.md L136, MindStudio 2026 | ADOPT (already canon) | Duty 3 |
| Stash = 24h scratch, not durable storage | templates/.../doctrine/git-stash-discipline.md L40, git-scm 7.3 stashing | ADOPT (already canon) | Duty 3 |
| Pre-warmed worktree pool (fixed slots) for heavy-dep repos | Augment Code 2026, MindStudio Overstory | EVALUATE — useful for alps/zesttube; deferred to follow-up bead | Duty 3 |
| FIFO merge queue + tiered watchdog (Overstory pattern) | MindStudio 2026 | EVALUATE — overlaps with auto-push doctrine; reuse jrpfn before adopting | Duty 5a |
| Trunk-based + short-lived branches + feature flags | AWS Prescriptive Guidance, Mergify, Toptal | ADOPT (already practiced; codify in runbook) | Duty 3 |
| Branch lifecycle declared at creation (declared_bead + expires_at) | NEW synthesis — extension of one-worktree-per-bead doctrine | ADOPT (new — WORKTREE-MANIFEST schema below) | Duty 3 |
| Stash retention policy with auto-archive | NEW synthesis — extends git-stash-discipline halt-at-N=10 | ADOPT (new — STASH-POLICY schema below) | Duty 3 |
| Stale-branch reaper using upstream `[gone]` markers | git for-each-ref live probe + stale-in-progress-reaper.sh precedent | ADOPT (new — extends existing reaper to branches) | Duty 3 |
| Force-push safety: prefer `--force-with-lease`; never to main/master | gh-cli SKILL.md, codex-21869-post-push-ref-drift-rule doctrine | ADOPT (already canon — codify in runbook) | Duty 3 |
| Fleet-wide git inventory primitive (worktrees+stashes+branches+tags) | NEW synthesis — extends stale-worktree-detector to multi-asset | ADOPT (new script — fleet-git-inventory.sh below) | Duty 3, 5a |
| JetBrains IDE worktree GUI (2026.1) | Augment Code 2026 web ref | SKIP — Joshua uses tmux/CLI workflow | n/a |

---

## 1. Source A — Skills Library

### 1.1 `~/.claude/skills/git-worktree-manager/SKILL.md` (read full)

**Authority:** Tier=POWERFUL, multi-agent-optimized.

**Adopt:**
- L48-91 Create + cleanup + parallel-session workflows — already the canonical pattern.
- L124-136 Anti-patterns table — every row maps to a fleet trauma we have:
  - "Worktree on untracked files" → matches our shared-repo-dirty-preflight INCIDENT (2026-05-08, 13 events).
  - "Force-removing dirty worktrees" → matches dcg-worktree-remove-block (2026-05-09, 7 events).
  - "Worktree outliving its branch" → root cause of 285 fleet-wide extras.
- L194-203 Operational Checklist Before/After Creation + Before Removal — verbatim into runbook §cleanup-worktree.

**Evaluate:**
- L57-69 `scripts/worktree_manager.py` — Python tool with port allocation. Useful for ALPS/ZestTube parallel feature work; not adopted at flywheel-substrate layer (overkill for orch-driven workers).

**Skip:**
- L94-107 Docker Compose Pattern — not load-bearing for our shell-first fleet.

### 1.2 `~/.claude/skills/git-commit-craftsman/SKILL.md` (read full)

**Adopt:**
- L52-145 Conventional Commits format (type/scope/subject/body/footer) — already practiced.
- L321-352 **Forever-rule:** never construct `git commit -m` via double-quoted heredoc with literal `$N` tokens — codified after the zesttube zt-25sx trauma (commits 5882e84, df277a0, 3127c35 leaked `/bin/zsh` into messages). Three correct shapes: single-quoted heredoc, single-quoted `-m`, stdin pipe from a file. **Verbatim into runbook §undo-bad-commit** + §integrate-worker-callback.

**Evaluate:** none — full adopt.

### 1.3 `~/.claude/skills/git-repo-janitor/SKILL.md` (read offset 1–200)

**Adopt:**
- 25 Kernel axioms (0-24), especially:
  - Axiom 0 (`blob_sha + canonical_path` is the unit, not filename) — informs WORKTREE-MANIFEST keying.
  - Axiom 2 (plan-for-irreversibility-first via bundle gate) — informs cleanup-worktree runbook step.
  - Axiom 3 (`git rm` not `rm`) — codified.
  - Axiom 9 (verbatim authorization recorded) — gates the destructive section of every runbook entry.
  - Axiom 15 (secret-in-tree halts and switches modes) — runbook §force-push-safety must surface.
  - Axiom 20 (clean run = empty artifacts, not absent artifacts) — informs inventory script output shape.
  - Axiom 23 (multi-repo runs are skip-list-first) — informs fleet-git-inventory aggregation.

**Evaluate:**
- Full 10-phase pipeline — too heavy for routine inventory; reserve for cleanup events.

### 1.4 `~/.claude/skills/gh-cli/SKILL.md` (read L1-150)

**Adopt:**
- L36-61 PR workflow (create --fill, view, checkout, review, merge --squash, merge --delete-branch).
- L114-125 Releases (gh release create with --generate-notes).
- L143-150 Decision Tree (gh pr view --json state,mergeStateStatus,statusCheckRollup before mutating).

**Evaluate:**
- gh API GraphQL queries — defer to follow-up bead if branch-protection-apply.sh needs richer policy state.

### 1.5 `~/.claude/skills/pr/SKILL.md` (read full — 17 lines, Remotion-scoped)

**Skip:** the canonical "prs" referenced by git-worktree-manager does not exist as a SKILL.md; it's the slash-command `/prs`. The `pr` SKILL.md is Remotion-scoped (Oxfmt + bunx), not fleet-wide. The fleet-wide PR contract lives in **gh-cli + git-commit-craftsman**.

**Gap discovered:** there is no fleet-wide `/prs orphans` skill formalized. Filed as follow-up consideration (see §5).

---

## 2. Source B — Socraticode K=10 × Q=6 queries against flywheel project

Qdrant: http://localhost:6433 (488 collections), recovered same session. Live probe confirmed.

### Q1: "worktree lifecycle cleanup pattern" (K=10)

- **INCIDENTS.md dcg-worktree-remove-block** (score 1.0) — 7 events 2026-05-08 on mobile-eats:0.3; root-cause = `strict_git:worktree-remove` DCG fired on `git worktree remove /tmp/<repo>-<id>-validate`. **Adopt-decision:** the validate-worktree pattern is canonical; the DCG block was the bug, not the worktree-remove. Reference in runbook §cleanup-worktree.
- **tests/stale-worktree-detector-smoke.sh** (score 0.44) — proves `stale-worktree-detector.sh` is wired and tested. Adopt as building block for fleet-git-inventory.sh.
- **templates/flywheel-install/doctrine/git-repo-discipline.md** + **scripts/repo-discipline-check.sh** — already-installed dirty-tree classifier. Reuse as the dirty-state surface in inventory.
- **tests/repo-hygiene-tick-smoke.sh** — proves repo-hygiene tick with worktree_count thresholds (P2=4, P1=10, P0=20) and stash_count thresholds (P2=5, P1=10, P0=20). **Adopt:** these threshold tiers become the fleet defaults in fleet-git-inventory.sh.

### Q2: "stash retention policy discipline auto-archive" (K=10)

- **templates/.../doctrine/git-stash-discipline.md** (score 0.75) — already-canonical doctrine. Stash = 24h scratch, two named trauma classes (`out-of-scope-leak` 44%, `AGENTS-CANONICAL-pane-leak` 25%). Adopt verbatim.
- **stash-discipline-check.sh** (score 0.38) — single-purpose gate with thresholds notable=1 / bead=5 / halt=10. Already wired into mission-fitness-callback-validator and flywheel-loop doctor. **Adopt as building block.**
- **tests/stash-discipline-wire.sh** — full wiring regression. Confirms current state.

**Gap:** no auto-archive primitive. Doctrine says "stash >24h = file as bead"; reality says 206 stashes accumulated. Filed in follow-up beads (stash-archiver cron).

### Q3: "stale branch unpushed detection reaper" (K=10)

- **tests/stale-in-progress-reaper.sh** (score 0.83) — full classifier for in_progress beads. **Adopt as PATTERN** (not direct reuse): branch-reaper mirrors this with `git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/`, classify ACTIVE / STALE / GONE, dry-run + apply contract.
- **stale-in-progress-reaper-carve-out.sh** — label-based carve-out (`upstream-tracker`, `cross-orch-active`, `joshua-gated`, `defer-gated`). **Adopt the carve-out shape** for branches: branches carrying `keep-alive`, `pending-pr`, `archived-snapshot` labels (annotated via BRANCH-MANIFEST.json) skip the reaper.

### Q4: "agentic dispatch worktree branch isolation" (K=10)

- **INCIDENTS.md shared-repo-dirty-preflight** (3 events 2026-05-08) — Forever-Rule: orchestrators own dirty pre-flight for every shared repo before dispatch.
- **INCIDENTS.md concurrent-dirty-validation-drift** (13 events 2026-05-08) — Forever-Rule: workers MUST validate in isolated worktrees `/tmp/<repo>-<task>-validate-<pid>` when shared tree is poisoned.
- **INCIDENTS.md bead-missing-from-local-db** (cross-worktree dispatch trauma) — workers MUST `br sync --import-only` before `br show|update|close` when bead is missing from local DB.

**Synthesis:** the runbook's `dispatch-worker-to-feature` section must codify ALL THREE invariants in one decision tree.

### Q5: "auto-push policy force-push safety guard" (K=10)

- **auto-push-auto-sweep-smoke.sh + auto-push-v0.1-adoption.sh** (scores 1.0, 0.45) — `.flywheel/auto-push-policy.yaml` schema `skillos.auto_push_policy.v1` with fields {upstream_required, local_ci_gate, gitguardian_gate, supabase_mirror_gate, post_commit_fire, push_cadence, allowed_branches_regex, forbidden_branches_regex, private_paths_blocklist, known_dirty_paths_allow_list, auto_sweep_on_dirty_tree, ledger_path, on_failure}. Sister bead **flywheel-jrpfn** owns extending this fleet-wide. **Adopt:** runbook §merge-to-main + §force-push-safety reference this policy as the authority surface, NOT redefine.
- **doctrine/codex-21869-post-push-ref-drift-rule.md** + **tests/codex-21869-post-push-ref-drift-guard.sh** — codifies the post-push reconciliation probe required when codex workers gain `workspace-write + network_access`. Currently dormant; tests assert dormancy invariant. **Adopt:** runbook §force-push-safety cites as the activate-when condition.

### Q6: "git inventory fleet-wide audit script" (K=10)

- **tests/client-tentacle-version-audit.sh** + script (score 0.40) — read-only fleet probe pattern. `client-tentacle-version-audit.py` iterates fleet-roster.json, runs probes per repo, emits JSON with required fields `[repo, tool, version, status]`. **Adopt the shape:** fleet-git-inventory.sh follows the same envelope (info/schema/doctor/health/repair/validate/audit canonical-cli scoping per `canonical-cli-scoping` skill).
- **tests/fleet-observatory-aggregate.sh** — aggregator pattern with bounded health score 0–100, doctor_field `fleet_observatory_health_score`. **Adopt:** fleet-git-inventory.sh exports `fleet_git_hygiene_score` (0-100) and `fleet_git_hygiene` dashboard line.
- **tests/fleet-watcher-coverage-probe.sh** — confirms `fleet-watcher-coverage-probe.sh` already follows `--info --json` / `--schema --json` envelope. **Adopt verbatim envelope.**

---

## 3. Source C — Web Research (2026-05-20 fetch-ts)

### 3.1 "2026 git worktree lifecycle best practices agentic AI fleet cleanup"

Sources fetched 2026-05-20T20:00Z:
- Augment Code: https://www.augmentcode.com/guides/git-worktrees-parallel-ai-agent-execution
- The Agentic Blog 2026-03-31: https://blog.appxlab.io/2026/03/31/multi-agent-ai-coding-workflow-git-worktrees/
- htek.dev: https://htek.dev/articles/git-worktree-unlocks-agentic-development/
- Laurent Kempé 2026-03-31: https://laurentkempe.com/2026/03/31/from-3-worktrees-to-n-ai-powered-parallel-development-on-windows/
- Towards Data Science: https://towardsdatascience.com/ai-agents-need-their-own-desk-and-git-worktrees-give-it-one/
- MindStudio: https://www.mindstudio.ai/blog/parallel-agentic-development-git-worktrees
- nekocode/agent-worktree: https://github.com/nekocode/agent-worktree

**Adopt patterns (≥2 independent sources, per Axiom 22):**
- `git worktree remove` over `rm -rf`, paired with `git worktree prune` (Augment Code + MindStudio).
- Automated cleanup of worktrees whose branches are merged to remote (Augment Code + MindStudio).
- Pre-warmed pool for heavy-dep repos (Augment Code) — single source, **EVALUATE not adopt**; revisit when alps/zesttube hit pool fatigue.
- Overstory FIFO merge queue + tiered watchdog (MindStudio) — single source for the specific shape, but overlaps with our auto-push doctrine. **EVALUATE; reuse jrpfn before adopting.**

**Skip patterns:**
- JetBrains IDE 2026.1 worktree GUI — Joshua works in tmux/CLI.

### 3.2 "git stash retention policy stale branch reaper monorepo 2026"

Sources fetched 2026-05-20T20:00Z:
- git-scm 7.3: https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning
- git-scm git-stash docs: https://git-scm.com/docs/git-stash
- Atlassian: https://www.atlassian.com/git/tutorials/saving-changes/git-stash
- GitLab: https://docs.gitlab.com/topics/git/stash/
- DevToolbox 2026: https://devtoolbox.dedyn.io/blog/git-stash-complete-guide

**Adopt (≥2 sources):**
- Stash for short-lived context switches; commit early/often otherwise (git-scm + Atlassian + GitLab — 3 sources).
- Convert work to a branch when work extends beyond a day (Atlassian + DevToolbox).

**Gap:** the web has no published "stash retention policy" or "stale-branch reaper" pattern at the depth our doctrine already carries. **Our internal doctrine is ahead of the public state of practice.** Confirm-by-omission.

### 3.3 "trunk-based development vs github flow multi-agent 2026 best practices"

Sources fetched 2026-05-20T20:00Z:
- AWS Prescriptive Guidance: https://docs.aws.amazon.com/prescriptive-guidance/latest/choosing-git-branch-approach/git-branching-strategies.html
- Mergify: https://mergify.com/blog/trunk-based-development-vs-gitflow-which-branching-model-actually-works/
- Toptal: https://www.toptal.com/developers/software/trunk-based-development-git-flow
- Aviator: https://www.aviator.co/blog/trunk-based-development-vs-gitflow/

**Adopt (≥3 sources):**
- Trunk-based + short-lived branches + feature flags is the high-performer pattern (AWS + Mergify + Toptal + Aviator).
- Enforce PR size limits and merge frequency (Mergify + Aviator).
- ~60% of teams use hybrid (Mergify) — informs runbook: GitHub Flow for ALPS/ZestTube (deploy-frequent), trunk-based for flywheel/skillos (continuous integration without deploy gates).

---

## 4. Synthesis — What This Research Produces (deliverables)

| Artifact | Path | What it does | Mission Duty |
|---|---|---|---|
| Canonical runbook | `.flywheel/docs/git-workflow-runbook.md` | Single-source operator runbook for 9 git workflows | Duty 3 |
| WORKTREE-MANIFEST schema | `.flywheel/schemas/WORKTREE-MANIFEST.schema.json` | Per-repo declaration of active worktrees + lifecycle | Duty 3 |
| BRANCH-MANIFEST schema | `.flywheel/schemas/BRANCH-MANIFEST.schema.json` | Per-repo declaration of branches + lifecycle | Duty 3, 5a |
| STASH-POLICY schema | `.flywheel/schemas/STASH-POLICY.schema.json` | Per-repo stash retention rules | Duty 3 |
| Fleet inventory primitive | `.flywheel/scripts/fleet-git-inventory.sh` | Read-only multi-repo git asset audit + doctor field | Duty 3 |

---

## 5. Follow-up Implementation Beads (filed after this research lands)

Each implements a slice; this research bead does **not** ship cron/reaper code.

1. **flywheel-git-worktree-reaper** (P1) — daemon + dry-run + apply that consumes WORKTREE-MANIFEST.json and reaps expired/orphaned worktrees fleet-wide. Depends on this schema + extends stale-worktree-detector.sh classifier. Mission Duty 3.
2. **flywheel-git-stash-archiver** (P1) — cron that auto-archives stashes >max_age_days (per STASH-POLICY.json) to off-tree journal `~/.local/state/flywheel/stash-archive/<repo>/<ts>.patch` then drops them. Depends on STASH-POLICY schema; extends stash-discipline-check.sh. Mission Duty 3.
3. **flywheel-git-stale-branch-reaper** (P1) — daemon that classifies branches ACTIVE/STALE/GONE via `git for-each-ref` + label carve-outs from BRANCH-MANIFEST.json, dry-run + apply. Depends on BRANCH-MANIFEST schema. Mission Duty 3.
4. **flywheel-git-auto-push-policy-enforcer** (P0, depends on jrpfn) — extends auto-push.sh to consume BRANCH-MANIFEST `lifecycle` + `last_pushed_at`, fires warn/auto-push per cadence. Mission Duty 5a.
5. **flywheel-git-worktree-manifest-bootstrap** (P2) — adds WORKTREE-MANIFEST.json / BRANCH-MANIFEST.json / STASH-POLICY.json stubs into the flywheel-init template + per-tentacle fleet-rollout. Mission Duty 3.

Acceptance for each: canonical-cli envelope (info/schema/doctor/health/repair/validate/audit), dry-run+apply parity, doctor JSON key, dashboard line, regression test, ledger entry.

---

## 6. Provenance + Citations

- **Skills (path : authority):**
  - `~/.claude/skills/git-worktree-manager/SKILL.md` : tier=POWERFUL, Multi-Agent.
  - `~/.claude/skills/git-commit-craftsman/SKILL.md` L321-352 : zesttube zt-25sx trauma.
  - `~/.claude/skills/git-repo-janitor/SKILL.md` Axioms 0-24.
  - `~/.claude/skills/gh-cli/SKILL.md` L36-150.
  - `~/.claude/skills/pr/SKILL.md` : Remotion-scoped (skipped for fleet-wide).
- **Socraticode (project_path=flywheel, projectPath probe 2026-05-20T20:00Z, qdrant 6433):**
  - Q1-Q6 results enumerated in §2; top hits with scores cited inline.
- **Web (fetch-ts 2026-05-20T20:00Z):**
  - 7 worktree refs, 5 stash refs, 4 trunk-vs-GitHub-flow refs — citations in §3.
- **Internal INCIDENTS (canon):**
  - dcg-worktree-remove-block (2026-05-09, 7 events).
  - shared-repo-dirty-preflight (2026-05-08, 3 events).
  - concurrent-dirty-validation-drift (2026-05-08, 13 events).
  - bead-missing-from-local-db (cross-worktree dispatch trauma).
- **Existing doctrine (templates/flywheel-install/doctrine/):**
  - git-repo-discipline.md (2026-05-14).
  - git-stash-discipline.md (2026-05-10).
  - cross-pane-git-discipline.md, git-main-sync-discipline.md, gitguardian-gate-discipline.md, repo-hygiene-operational-protocol.md, repo-hygiene-tick-discipline.md.
  - codex-21869-post-push-ref-drift-rule.md (dormant).

---

## 7. Diagnosis (Meadows leverage points)

- **Leverage point #4 (self-organization):** the fleet has no structural rule that retires a worktree when its bead closes. Default = infinite accretion. The WORKTREE-MANIFEST schema introduces the rule.
- **Leverage point #5 (rules):** stash-discipline already has rules (N=10 halt) but no enforcement on accretion below halt — 206 stashes accumulate at N<10 per repo. STASH-POLICY adds max_age_days as a second rule axis.
- **Leverage point #6 (information flow):** 285 worktrees + 206 stashes + 177 unpushed branches are invisible in the daily-report and the /flywheel:status dashboard. The fleet-git-inventory.sh primitive surfaces them as a single line + JSON key.
- **Confirm-by-omission:** the public state of practice (web search §3.2) has no equivalent retention/reaper pattern; our internal doctrine is ahead. The gap is enforcement substrate, not doctrine authorship.

---

## 8. Mission-anchor Alignment

| Duty | Sub-aspect | Primitive |
|---|---|---|
| Duty 1 (mission-locked) | Foundational discipline visibility | runbook + inventory dashboard line |
| Duty 3 (substrate-published) | Public-substrate state hygiene | WORKTREE-MANIFEST, BRANCH-MANIFEST, STASH-POLICY, fleet-git-inventory.sh |
| Duty 5a (auto-push, jrpfn) | Branch lifecycle drives push cadence | BRANCH-MANIFEST.last_pushed_at + auto-push-policy enforcer (follow-up bead 4) |

Every follow-up bead cites its Duty.
