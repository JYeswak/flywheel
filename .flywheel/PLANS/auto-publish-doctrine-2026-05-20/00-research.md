# Auto-Publish Doctrine — Research (Plan-Space)

**Bead:** flywheel-jrpfn (P0)
**Authored:** 2026-05-20
**Author:** flywheel:1 orch (claude-opus-4.7)
**Mission Duty:** 3 (substrate-published) — 100% public repos within declared freshness invariant
**Sister beads landed:** flywheel-dycce (CI-POLICY local-first), flywheel-m9yxr (BRANCH-MANIFEST schema + fleet-git-inventory.sh)
**Follow-on:** flywheel-t24fi (auto-push enforcer — blocked on this)

---

## 1. Problem Statement

Joshua-direct 2026-05-20T19:00Z: *"we cannot have public repos in our stack and not pushing regular updates to them — if people download them and they don't have our latest work, they are being left behind."*

**Audit snapshot:**

| Repo | Visibility | main staleness | Local-only commits today |
|---|---|---|---|
| flywheel | PUBLIC | 5d | 199 |
| skillos / SkillOS | PUBLIC | 10d | 212 |
| zeststream-cast | PUBLIC | 12h | 54 |
| zeststream-cast-docs | PUBLIC | 2d | — |
| zeststream-brand-voice | PUBLIC | 4w | — |
| 100minds-mcp | PUBLIC | 4 months | — |

**Root cause (Meadows #6, information flow):** Commits land on feature branches; PRs rarely cut; merges to `main` rarely happen; public consumers see stale state. Local disk durability ≠ public visibility. Default fleet state is **DRIFT**, not **FRESH**.

---

## 2. Sources (Load-Bearing, ≥3 per mission-lock doctrine)

### Source A — Skills library (`~/.claude/skills/`)
- **`gh-actions/SKILL.md`** — fetch-ts 2026-05-20. Defines `ci.yml` on push/PR, `release.yml` on tag, dependabot. No mention of auto-merge.
- **`release-preparations/SKILL.md`** — fetch-ts 2026-05-20. 12-session battle-tested release flow. Mentions "release-automation race (main vs master)" as a known gotcha (OP-7). No auto-merge primitive.
- **`package-publishing/SKILL.md`** — fetch-ts 2026-05-20. Semantic versioning + GH Actions release pipelines; no auto-merge pattern.
- **`repo-hygiene/SKILL.md`** — fetch-ts 2026-05-20. Planning-only. Hard gate: "Default to dry-run. Apply requires Joshua review + `--idempotency-key`."

**Reading:** The skills library has **NO existing pattern for `main`-staleness enforcement or auto-merge-to-main**. This is novel doctrine for the fleet.

### Source B — Socraticode (488 collections, `mcp__socraticode__codebase_search` against `/Users/josh/Developer/flywheel`)
Queries run 2026-05-20:

| Query | Top hit | Score |
|---|---|---|
| "github actions auto-merge pull request when CI passes branch protection" | `tests/branch-protection-apply-smoke.sh` | 0.83 |
| "main branch staleness detector freshness invariant fleet" | `tests/stale-worktree-detector-smoke.sh` | 0.55 |
| "auto push policy feature branch enforcement cadence" | `tests/auto-push-auto-sweep-smoke.sh` | 1.00 |

**Existing in-repo prior art (confirmed via socraticode):**
1. `.flywheel/scripts/auto-push.sh` + `.flywheel/auto-push-policy.yaml` — schema `skillos.auto_push_policy.v1`. Already covers `push_cadence: post-commit`, `allowed_branches_regex`, `gitguardian_gate`, `local_ci_gate`, `supabase_mirror_gate`, `on_failure: block_next_commit`. **Operates at feature-branch tip; does NOT enforce merge-to-main.**
2. `.flywheel/CI-POLICY.json` — schema `flywheel.ci_policy.v1`. Declares "local_first_last_drop" policy and `per_push_feature_branch_ci_allowed: false`. Last-drop events: `pull_request.opened`, `pull_request.reopened`, `pull_request.ready_for_review`, `push.main`, `push.master`, `schedule.daily`, `workflow_dispatch`, `release_tag`.
3. `tests/branch-protection-apply-smoke.sh` — synthetic harness for applying branch-protection. Exists; not yet wired for auto-merge.
4. `.flywheel/schemas/BRANCH-MANIFEST.schema.json` (sister bead m9yxr) — already carries `last_pushed_at`, `lifecycle: merge_to_main|abandon|extract_to_repo|long_running`, `upstream_state: tracking|ahead|behind|diverged|gone|none`, `open_pr_url`. **Branches-side ledger; main-side staleness is what's missing.**
5. `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` — canonical CLI scaffold; existing pattern to mirror for `public-repo-freshness-probe.sh`.

**Reading:** The fleet already has 80% of the lower half of the stack (feature-branch push, CI gating, branch manifest). The missing piece is **main-merge cadence + freshness invariant** — exactly what this bead asks for.

### Source C — Research-triad (Jeff Emanuel's repos, `gh api`, fetch-ts 2026-05-20T20:00Z)
Probed `Dicklesworthstone/{ntm, beads_rust, coding_agent_session_search, coding_agent_account_manager}`:

| Repo | Last main push | Branch protection | Workflows | Pattern observed |
|---|---|---|---|---|
| ntm | 2026-05-20T19:46Z (today) | None (HTTP 404) | ci.yml, e2e-tests.yml, notify-acfs.yml, release.yml | Direct push to main, multi/day. PRs used (#155, #149, #153) for review but merged fast. |
| beads_rust | 2026-05-20T16:31Z (today) | None | audit, ci, conformance, doctor, e2e-full, notify-acfs, release, update-package-manifests | Direct push to main. 5 commits today; recent `test(schema):`, `doctor(P5-cycle-57):`, etc. |
| coding_agent_session_search | 2026-05-20T19:50Z (today) | None | acfs-checksums-dispatch, bench, browser-tests, ci, coverage, fresh-clone-build, fuzz, install-test, lighthouse, notify-acfs, perf, release | Same pattern: direct push to main, multiple/day. |
| coding_agent_account_manager | 2026-05-06T19:35Z (14d) | None | ci, release, acfs-checksums-dispatch, notify-acfs | Same pattern but lower velocity. |

**Jeff's pattern (de facto):**
- **NO branch protection** on main — high-trust solo-dev workflow.
- **NO auto-merge automation** — PRs created for review surface but merged manually by Jeff.
- CI on `push: [main]` AND `pull_request: [main]` with `concurrency.group: ${{workflow}}-${{ref}}` + `cancel-in-progress: true`.
- Release on tag push `v*` with attestation/cosign/SLSA provenance.
- **Cross-repo notification:** `notify-acfs.yml` fires on relevant events — a fleet-wide pulse-out pattern. This is the closest analog to what flywheel needs.

**Reading:** Jeff's "freshness" isn't enforced by automation — it's enforced by **personal velocity + low-friction direct-push-to-main**. The 28-closed-issue track record is the *output* of that velocity, not the cause. Direct-push-to-main is the actual fleet pattern; PRs are review surface, not merge gate.

---

## 3. Adopt / Evaluate / Skip Table

| Pattern | Source | Decision | Rationale |
|---|---|---|---|
| **Direct push to main** for solo-trust repos | Jeff | **ADOPT** | Matches actual fleet velocity. PR-for-every-merge is overhead theater on a 1-developer + N-AI-workers fleet. |
| **`concurrency.cancel-in-progress`** on CI | Jeff (all 4 repos) | **ADOPT (already partially in CI-POLICY)** | Cancels stale runs on rapid pushes — saves spend + keeps freshness signal accurate. |
| **`on: pull_request` types `[opened, reopened, ready_for_review]`** (NOT `synchronize`) | flywheel CI-POLICY | **KEEP** | Already in place; saves GHA spend; aligns with local-first-last-drop. |
| **Branch protection rules on main** (require status checks, dismiss stale reviews) | gh-actions skill, generic GH best-practice | **SKIP for solo-trust repos; ADOPT for client-facing repos (later)** | Jeff runs without it. Joshua-as-only-human matches the same trust profile. Reserve for repos where external contributors land (e.g., future PRs from clients). |
| **GitHub auto-merge** (`gh pr merge --auto`) | gh docs | **EVALUATE — gated only** | Requires branch protection + required checks. Useful for *labeled* PRs from agent workers, NOT default. Default merge is direct-push or manual `gh pr merge`. |
| **`audit-bot` identity approving PRs** | Bead body | **EVALUATE — formalize in follow-up** | Today: Joshua approves manually or direct-pushes. Audit-bot identity = `flywheel:1` orch when PR was authored by an agent worker. Requires formal identity registry entry — defer to follow-up bead. |
| **Per-commit feature-branch push** | flywheel auto-push.sh (already) | **KEEP** | Already canonical. `push_cadence: post-commit` in `auto-push-policy.yaml`. |
| **Auto-sweep accreting state paths on push** | flywheel auto-push.sh | **KEEP** | Already canonical; covers `.flywheel/MISSION.md`, ledgers, etc. |
| **PER-REPO freshness-invariant declaration** | NOVEL | **ADOPT (new)** | This bead's load-bearing innovation. Lives in `.flywheel/PUBLISH-POLICY.json`. |
| **Fleet-wide freshness probe** (cron, doctor surface) | NOVEL (analog: fleet-canonical-rule-freshness-probe.sh) | **ADOPT (new)** | Artifact 3 of this bead. |
| **Cross-repo notify-acfs pattern** | Jeff | **EVALUATE — borrow shape later** | Jeff's `notify-acfs.yml` is the right model for "main pushed → notify subscribers." Not in scope this bead; file as follow-on. |
| **`audit.yml`, `doctor.yml`, `conformance.yml` workflows on main** | Jeff (beads_rust) | **EVALUATE — borrow on individual workflow basis** | Jeff dedicates whole workflows to verification gates. Some are already in flywheel (`tests/local-ci-policy.sh`, `tests/github-workflows.sh`). |
| **Tag-push release with SLSA provenance + cosign** | Jeff + release-preparations skill | **ADOPT (already canonical)** | No change needed. |

---

## 4. Final Recommendation — The Auto-Publish Stack

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 4: Freshness probe + doctor surface (THIS BEAD)         │
│           public-repo-freshness-probe.sh → doctor.public_repo_  │
│           freshness → /flywheel:tick fires beads on degraded.   │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 3: Per-repo policy declaration (THIS BEAD)              │
│           .flywheel/PUBLISH-POLICY.json (schema below)         │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: Merge-to-main path (FOLLOW-ON BEADS)                 │
│           default: direct push (solo-trust, Jeff pattern)       │
│           gated:  gh pr merge --auto when audit-bot approves    │
│           disabled: manual only (for repos with external PRs)   │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1: Feature-branch push (ALREADY CANONICAL)              │
│           .flywheel/scripts/auto-push.sh + auto-push-policy.yaml│
└─────────────────────────────────────────────────────────────────┘
```

**Operating principle:** *Direct push to main is the default for solo-trust repos. Auto-merge gates are an opt-in escalation for repos where external contributors land. The freshness invariant is the public commitment; the merge path is implementation detail.*

**Default per-repo policy (flywheel-class repos):**
```json
{
  "max_main_staleness_hours": 24,
  "auto_merge_policy": "disabled",
  "feature_branch_push_policy": "per-commit",
  "required_checks_before_merge": []
}
```
This means: `auto-push.sh` keeps pushing feature branches per-commit; main stays fresh because Joshua/agents direct-push merges; if main drifts >24h despite work happening, the probe alarms and `/flywheel:tick` files a bead.

**For repos that want PR-gated merges (e.g., zeststream-cast-docs eventually):**
```json
{
  "max_main_staleness_hours": 48,
  "auto_merge_policy": "gated",
  "audit_bot_identity": "flywheel:1",
  "required_checks_before_merge": ["CI / lint", "CI / test"],
  "feature_branch_push_policy": "per-commit"
}
```

---

## 5. What This Bead Delivers (3 artifacts)

1. **This research doc** → `.flywheel/PLANS/auto-publish-doctrine-2026-05-20/00-research.md`
2. **PUBLISH-POLICY schema** → `.flywheel/schemas/PUBLISH-POLICY.schema.json`
3. **Freshness probe** → `.flywheel/scripts/public-repo-freshness-probe.sh`

## 6. Follow-up beads (filed after close)

- `auto-merge-gated-mode-implementation` — wire `gh pr merge --auto` + branch-protection for `auto_merge_policy: gated` repos. **P1**.
- `PR-template-bootstrap-fleet` — drop standardized `.github/pull_request_template.md` into every public repo via flywheel-init. **P2**.
- `audit-bot-identity-formalization` — formalize `flywheel:1` (and per-orch peers) as PR-approver identities in the fleet identity registry. **P1**.
- `cross-repo-notify-pulse` (borrow Jeff's `notify-acfs.yml` pattern) — when main updates on repo A, ping subscribers in repos B/C. **P2**.

## 7. Citations (source-id + fetch-ts)

- `gh-api://Dicklesworthstone/ntm` fetch-ts 2026-05-20T20:00Z
- `gh-api://Dicklesworthstone/beads_rust` fetch-ts 2026-05-20T20:00Z
- `gh-api://Dicklesworthstone/coding_agent_session_search` fetch-ts 2026-05-20T20:00Z
- `gh-api://Dicklesworthstone/coding_agent_account_manager` fetch-ts 2026-05-20T20:00Z
- `gh-api://JYeswak` repo list fetch-ts 2026-05-20T20:00Z
- `socraticode://flywheel?query=auto-merge` fetch-ts 2026-05-20T20:00Z (488 collections, qdrant 1.17.1)
- `file:///Users/josh/.claude/skills/gh-actions/SKILL.md` fetch-ts 2026-05-20T20:00Z
- `file:///Users/josh/.claude/skills/release-preparations/SKILL.md` fetch-ts 2026-05-20T20:00Z
- `file:///Users/josh/Developer/flywheel/.flywheel/CI-POLICY.json` fetch-ts 2026-05-20T20:00Z
- `file:///Users/josh/Developer/flywheel/.flywheel/schemas/BRANCH-MANIFEST.schema.json` fetch-ts 2026-05-20T20:00Z
- `beads-show://flywheel-jrpfn` fetch-ts 2026-05-20T20:00Z
- `beads-show://flywheel-t24fi` fetch-ts 2026-05-20T20:00Z
