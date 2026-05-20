# flywheel Mission

schema_version: 1
doc_type: mission
status: locked
locked_at: 2026-05-20T00:00:00Z
lock_hash: 332f24a5f5ef61f1408b90c2c5d8ab326181ab47ef596a172e6148368a33e424
prior_lock_hash: d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528
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

