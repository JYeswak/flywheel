# flywheel Mission

schema_version: 1
doc_type: mission
status: locked
locked_at: 2026-05-20T19:40:00Z
lock_hash: a59529f34c4051c2f9c0d20399650cf5673eb6e410d602d04f6689017181e796
prior_lock_hash: 5ccb4f23a38b4aa2bb16ad4f69181f8f517c9b62207752f946a956c0df3aba4d
mission_lock_id: ml-2026-05-20-mission-drift-five-duties-token-burn
mission_lock_reason: mission-drift-depth-add-token-burn
locked_by_extension: flywheel-1-mission-lock-skill
repo: /Users/josh/Developer/flywheel
repo_realpath: /Users/josh/Developer/flywheel
installed_from: /Users/josh/Developer/flywheel/templates/flywheel-install
template_version: "0.1.0"
template_hash: b16c74ddcf48e94ccc0130a19b0fde842608f00da4136319727037ad893fc06f
rendered_at: 20260501T052023Z
rendered_by: flywheel-loop-reconcile
locked_by: template-live-doc-backfill
source_path: /Users/josh/Developer/flywheel/.flywheel/MISSION.md
source_sha256: cff6eb918478d7de08d9f3dd3b0b13221d6aa9acd930fadb45e045b095498551
source_section: legacy compact live doc
provenance_note: Backfilled from the flywheel legacy compact live mission without removing substance.
journal_split_note: journal split out 2026-05-20 per frozen-projection class

## Senior-Dev Orientation

> **Cold-worker pointer (added 2026-05-09 by flywheel-q2gz.3 — Lane 3 doctrine-doc floor).**
> Read this block first if you are touching `.flywheel/MISSION.md` and have not edited it before.

- **Purpose.** Repo-local mission anchor for `/Users/josh/Developer/flywheel`. Names the operating doctrine, the mission anchor lock chain, and the substrate constraints that constrain every dispatch and orchestrator decision in this repo. Companion docs: `/Users/josh/Developer/flywheel/.flywheel/GOAL.md`, `/Users/josh/Developer/flywheel/.flywheel/STATE.md`, and the fleet-level anchors at `/Users/josh/.claude/skills/.flywheel/{GOAL,WORK,LOOP}.md`.
- **Update boundary.** This file is **locked** (`status: locked`, `locked_by: template-live-doc-backfill`, `lock_hash` above). New mission text lands as a follow-up section under an explicit `## Mission anchor extension locked YYYY-MM-DD` header, NOT a rewrite of existing sections. Lock-hash drift is investigated, not paved over. Do not strip the metadata block (`schema_version` through `provenance_note`) — the flywheel-loop reconcile path reads those fields verbatim.
- **Validation.** Run from anywhere:
  ```bash
  test -s /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
    && grep -q '^## Senior-Dev Orientation$' /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
    && grep -Eq '^lock_hash: [0-9a-f]{64}$' /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
    && grep -Eq '^source_sha256: [0-9a-f]{64}$' /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
    && [ "$(wc -l < /Users/josh/Developer/flywheel/.flywheel/MISSION.md)" -ge 100 ] \
    && echo ok || echo missing
  ```
  Expected: literal `ok`. Failure means the orientation marker, lock-hash, source SHA, or content body has drifted (the `wc -l >= 100` floor proves the locked body was not truncated to a stub).
- **Provenance.** Source path and SHA are pinned in the metadata block above (`source_path`, `source_sha256`, `template_hash`). Mission anchor extension on 2026-05-04 is named in the body. Lock-log integrity is the canonical "did anyone touch this" signal — check via `git log -p /Users/josh/Developer/flywheel/.flywheel/MISSION.md | head -200` for any commit that does not name a `## Mission anchor extension locked` section.
- **Stale signals.**
  - `lock_hash` drift without a paired entry in any flywheel session note under `/Users/josh/Developer/flywheel/.flywheel/handoffs/`.
  - `## Mission Source` heading appearing twice with empty content between them (current state, intentional, preserved during backfill — do not collapse without owner sign-off).
  - Any "Mission anchor extension" claim that does not include `locked YYYY-MM-DD` in the heading.
  - References to `/Users/josh/Desktop/Projects/clients/alps-insurance` (legacy stale path; canonical is `/Users/josh/Developer/alpsinsurance`).
- **Out-of-scope for this orientation block.** Authoring new mission language, replacing the metadata block, removing the duplicate `## Mission Source` heading, or editing the locked content. Those changes are owner-gated and route through their own bead.

## Mission Source


## Mission Source

Flywheel is the coordination repo for ZestStream's agentic coding infrastructure. It coordinates bead-based task graphs, dispatches work to ntm workers, and houses plans, skills, templates, command contracts, audits, and cross-repo coordination records.

Fleet-level mission and operating doctrine live under:

- /Users/josh/.claude/skills/.flywheel/GOAL.md
- /Users/josh/.claude/skills/.flywheel/WORK.md
- /Users/josh/.claude/skills/.flywheel/LOOP.md

## North-Star Outcome

A repo-scoped, self-improving flywheel substrate that keeps Joshua's agents coordinated, dispatchable, observable, and grounded in current doctrine without leaking state across repos.

## Self-Sustaining Company Operating Anchor

Mission anchor extension locked 2026-05-04: flywheel is the command center for
Joshua's agent fleet and must move the company toward outgrowing its founder.
The system goal is total visibility into identity, work, and performance with
metrics routed to architecture changes, not individual-agent performance
reviews.

Canonical memory:
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_self_sustaining_company_paradigm_2026_05_04.md`

Operating implications:
- Measure reliability, faithfulness, leverage, reuse, coordination, and
  drift-authoring as system-level vectors.
- Track `founder_dispose_pct` trending down quarterly as operating-model success.
- Route bad trends to doctrine, skill, probe, or dispatch-template changes.
- Forbid agent-shaming reports, leaderboards, and named-agent performance
  reviews.

## Primary Beneficiary

Joshua Nowak and the ZestStream agent fleet: orchestrator panes, worker panes, repo-local flywheel installs, and the downstream client/application repos they coordinate.

## Explicit Non-Goals

- This repo does not contain application product code.
- This repo must not become a dumping ground for global bead state or cross-repo task ownership.
- This repo must not bypass repo-local readiness, receipt, transport, doctrine, or bead isolation gates.

## Safety And Privacy Boundaries

- Keep source edits repo-scoped and bead- or loop-backed.
- Preserve canonical doctrine and do not silently mutate client/application repos from this substrate.
- Use ntm for pane operations and keep worker dispatches visible through callbacks and logs.
- Do not reintroduce global bead fallback, cross-repo bead recovery, or silent .beads walk-up leakage.

## Evidence That Would Change The Mission

Change this mission only if Joshua changes the coordination ownership model, the flywheel substrate moves out of this repo, or repeated incidents show that a different source-of-truth layout better preserves repo isolation and agent coordination.

## Owner-Review Cadence

Review when the flywheel template contract changes, after major loop/autoloop architecture changes, after doctrine-drift repair batches, or at least quarterly during Sunday coffee review.

## Lock Receipt

Backfilled from the legacy compact live mission on 2026-05-01T01:25:43Z by template-live-doc-backfill. The lock_hash covers the body after this metadata block.

## North-Star Outcome

Migrated from the previous repo-local mission. Refine on the next owner-review pass.

## Primary Beneficiary

Repo maintainers and agents running portable flywheel loop ticks.

## Explicit Non-Goals

Do not infer new mission scope during reconcile.

## Safety And Privacy Boundaries

Preserve existing provenance and avoid source mutation during migration.

## Evidence That Would Change The Mission

Owner review or validation evidence that contradicts the current mission.

## Owner-Review Cadence

Review when the repo mission, owner, or operating constraints change.

## Lock Receipt

Reconciled from existing .flywheel/MISSION.md at 20260501T052023Z.

## Mission anchor extension locked 2026-05-14

> "Repo hygiene is core infrastructure of the AaaS product — the flywheel is accountable to the same standards it enforces on client repos. Every session closes with a `git_hygiene` block in the closeout receipt; unclassified accretion is the alarm, not classified motion."

**Corollary — gated-loop halt:** When a loop's goal is blocked exclusively by external gates (`owner: joshua` or `owner: external-system`), the loop MUST detect the gate and halt rather than burning tokens on adjacent work. A loop that spins on gated information is a defect, not diligence.

**Cross-references:**
- Doctrine: `.flywheel/doctrine/substrate-class-classifier.md` (substrate class taxonomy)
- Enforcement: `.flywheel/scripts/validate-callback-before-close.sh` (git hygiene gate)
- Enforcement: `.flywheel/scripts/dispatch-capacity-gate.sh` (dirty-tree dispatch block)
- Enforcement: `.flywheel/scripts/loop-goal-gate.sh` (gated-loop halt check)
- L-rule: L162 substrate-class classifier before protection halt mandatory (`.flywheel/rules/L113-L162-substrate-class-classifier-before-protection-halt-mandatory.md`)

## Joshua Requests

journal split out 2026-05-20 per frozen-projection class.
Canonical JSONL source: `~/.local/state/flywheel/josh-requests.jsonl`.
Archived markdown mirror: `.flywheel/josh-requests-archive/2026-05.md`.
New hook writes append-only request entries to the monthly archive, not this locked mission projection.

## Negative invariants (security)

# AUDIT-ADDED: SEC-001..006 - needs Joshua review on next mission-relock

These invariants are additive mission-lock template requirements for touched
auth, credential, PII, and customer-trust surfaces.

- SEC-001: dispatch packets set `secret_values_allowed=false`; they may name
  secret classes, keys, vault paths, and safe helper commands, but never include
  token fragments, raw env output, Agent Mail bearer tokens, registration
  tokens, private keys, or copied secret-bearing pane text.
- SEC-002: credential-touching `skill_receipts[]` include `credential_touch`,
  `safe_wrapper`, `secret_value_allowed=false`, `rotation_approval_source`, and
  `joshua_explicit_rotation_approval` when rotation or destructive credential
  work is involved.
- SEC-003: skillos and peer orchestrators receive skill names, aliases,
  templates, route health, schemas, and redacted evidence only; they never
  receive customer-private evidence, raw pane captures, env dumps, secret values,
  or repo-local credential payloads.
- SEC-004: close-validator may fail closure, open/update beads, and demand
  receipts, but may not rotate tokens, edit `.env`, overwrite MCP secret config,
  write vault values, or mark credential repair complete from pane text.
- SEC-005: every touched surface declares its secret source of truth, principal
  type, allowed operations, forbidden principals, and whether service-role/admin
  credentials are permitted or explicitly forbidden.
- SEC-006: missing negative invariants on touched auth/credential/PII/customer-trust
  surfaces mean blocked readiness until Phase 0 scaffolding lands or a no-touch
  proof shows that the security surface is outside the dispatch scope.


## Mission Anchor Extension Locked 2026-05-20T19:00Z

Joshua-direct mission-drift event 2026-05-20: the "command center" anchor (2026-05-04 extension) now has explicit operational duties.
Reason: `mission-drift` — auto-publish doctrine + agentic issue-bead flow + always-watching role formalization.

### The Four Duties of flywheel:1

1. **Workers-working** — every dispatched task pursuing-goal-active; dead panes detected + recovered (flywheel-pjaaj); idle codex panes assigned ready beads; no silent-fallback to grep when substrate is down. Metric: <3 idle codex panes with ready beads at any tick.

2. **Blockers-unblocked** — red gates flip to research-beads via `/flywheel:plan`; bead-to-fix-to-close chains never go stale; "we'll fix it later" is a fileable trauma class, not an acceptable status. Metric: <5 hub blockers active; top blocker promoted within 24h.

3. **Substrate-published** — every public repo in the fleet maintains a declared freshness invariant. Main is auto-merged from green feature branches via PR. If it's public, it's current. Disk-durability ≠ public-visibility. Per repo: `.flywheel/PUBLISH-POLICY.json` declares `max_main_staleness_hours`, `auto_merge_policy`, `audit_bot_identity`, `required_checks_before_merge`. Metric: 100% public repos within declared freshness invariant.

4. **Public-issues-watched** — GitHub issues filed against any `JYeswak/*` public repo auto-route into beads (Jeff-style closed-loop pipeline). Bead closures emit PRs that link back to the source issue. PR merge closes source issue. No external collaborator waits. Metric: 0 GitHub issues on JYeswak/* repos older than 48h without a linked bead.

### Doctor-Surface Visibility

`flywheel_orch_four_duty_status` dashboard line renders per-duty green/yellow/red on every `/flywheel:status`. Underlying probes:
- duty 1: `ntm --robot-activity` fleet sweep + idle-pane-with-ready-bead detector
- duty 2: `doctor.fleet_process_health` + `hub_blockers` + `three_surface_drift` keys
- duty 3: per-repo `public_repo_freshness_probe`; alarm at threshold breach
- duty 4: `gh issue list` polling per JYeswak/* + bead cross-reference

### Pause/Resume Policy

flywheel:1 auto-pauses when ANY duty is RED for >2 ticks consecutive without remediation in flight. Resume requires `/flywheel:mission-lock --reason=resume-from-pause` OR explicit Joshua release.

### Founder-Dispose Threshold

- Duties 1-2 yellow: fully automated, no Joshua interrupt
- Duty 3 red: notify only (dashboard + xpane to peer orchs)
- Duty 4 red >2h: notify only
- Any duty red >24h: page Joshua

### Foundational Research Beads (filed 2026-05-20 in support of duties)

- `flywheel-jrpfn` P0: auto-publish public repos doctrine (duty 3 implementation)
- `flywheel-wukwc` P0: agentic issue↔bead↔commit↔push closed-loop (duty 4 implementation)
- `flywheel-761ln` P0: always-watching role formalization (this section's parent bead)
- `flywheel-pjaaj` P0: codex-worker-death-monitor (duty 1 implementation)
- `flywheel-thw90` P0: team-pulse stale despite live fleet (duty 1 information-flow fix)
- `flywheel-1dktu` P0: orbstack-cascade socraticode outage (duty 1 substrate health)
- `flywheel-8gmx6` P0: caam refresh-token mutex (duty 1 transport reliability)
- `flywheel-bxhxa` P0: storage-health-probe 5-tier classifier (substrate foundation)
- `flywheel-94xyb` P0: log-rotation contract (substrate foundation)
- `flywheel-ivb2s` P0: ledger-retention enforcer (substrate foundation)

## Mission Anchor Extension Locked 2026-05-20T19:40Z

Joshua-direct depth-add 2026-05-20T19:40Z, naming the CFS:1 phantom-bead-creation incident:
> "auto ops is great but auto ops without mission alignment is token burn ... we need to make sure that every repo is mission aligned - and if there is mission drift that is getting surfaced sooner rather than later."

### Duty 5 — Mission-alignment surveillance (fleet-wide)

Every repo in the fleet maintains a fresh mission-lock and ground-truth callback verification. flywheel:1 surveils both dimensions, surfaces drift EARLY, halts token-burn cycles BEFORE Joshua wakes up to N "completed" beads with no actual state change.

**Two failure modes Duty 5 prevents:**

1. **Mission drift** — repo work diverges from its declared mission anchor over time. Dispatched work passes the mission-fitness gate at dispatch time, then drifts toward what's interesting/possible instead of what's mission-required.
   - Prevention: every repo has `mission_lock_age_status` probe; alarm at >168h fresh threshold; refuse new dispatches at >720h stale.
   - Metric: 100% repos with `mission_lock_age < 720h` (max threshold). Yellow at 168-720h. Red at >720h.

2. **Callback-vs-ground-truth drift** (CFS phantom-bead-creation class) — worker callbacks claim substantive DB/fs/gh operations executed, but ground-truth state shows they didn't. Plan-space artifacts may be real and substantive, but the world they describe was never realized. Example: CFS:1 pane 2 Phase 4 DECOMPOSE claimed "10 beads + 5 deps created"; `br list` confirmed none existed.
   - Prevention: orchestrators run ground-truth probe on every DONE callback that claims bead/file/issue operations. `br show <claimed-id>` for bead ops, `ls -la <claimed-path>` for file ops, `gh issue view <claimed-issue>` for github ops. Refuse close until verified.
   - Metric: 100% DONE callbacks have `ground_truth_verified=true` in dispatch-log row.

### Doctor-Surface (extended)

`fleet_mission_alignment_status` dashboard line on every `/flywheel:status`:
`Mission: <fresh>/<total> fresh, <stale> stale; ground_truth_verified=<pct>% (24h)`

Underlying probes:
- per-repo `mission-lock-age-probe.sh`
- dispatch-log scan for `ground_truth_verified` field across last 24h
- phantom-bead detector: scan worker callbacks claiming `br create/update/comment` ops, cross-check against `br list --updated-since=<dispatch_ts>`

### Token-Burn Halt Condition

If any repo enters duty-5-RED (mission stale >720h OR phantom-bead detection rate >0 in last 24h), flywheel:1 HALTS all new dispatches to that repo's panes until:
- mission is re-locked via `/flywheel:mission-lock --reason=resume-from-pause` (mission drift case), OR
- phantom-bead-creation root cause identified + worker contract patched (verification gap case)

This is the **anti-token-burn invariant**: better to halt than to burn cycles on work that's not delivering to mission OR not landing in actual state.

### Foundational Research Beads (filed 2026-05-20 in support of Duty 5)

- `flywheel-<TBD-mission-surveillance>` P0: fleet-wide mission-lock-age audit + dashboard wiring
- `flywheel-<TBD-phantom-bead>` P0: orchestrator-side ground-truth callback verification protocol; promote `/beads-compliance-and-completion-verification` skill to canonical-required for every DONE callback that touches DB/fs/gh state
