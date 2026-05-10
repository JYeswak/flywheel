---
title: "Phase 3 AUDIT r1 — Cross-Cutting"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 — Cross-Cutting

Plan: `wire-or-explain-tick-gate-2026-05-04`
Lens: cross-cutting integration
Generated: 2026-05-04T22:42Z
Mode: plan-space read-only audit
Prior round: none
Convergence flag: `prior_round=none`

## Audit Frame

This lens audits the converged r2 plan as a meta-gate that must compose with
tick close, doctor JSON, dispatch-log, callback validation, Agent Mail, br,
DCG, cross-orch rollout, doctrine sync, and sibling orch-monitor primitives.

The audit intentionally does not re-litigate the plan's core invariant. r2
states the invariant as "No tick closes green until every shipped artifact in
scope is wired, deferred, not-required, or explicitly bypassed with an expiring
audited reason" at `02-REFINE-r2.md:15-19`. Phase 1 synthesis already showed
the same axis across F1/F2/F4/F5/F8/F9 at `02-PHASE1-SYNTHESIS.md:23-99` and
`00-INTENT.md:166-177`.

Skills applied:

- `donella-meadows-systems-thinking`: stock is unwired-output backlog; missing
  loop is consume -> act -> record -> close.
- `gate-truth-separation`: this is a flow/wiring gate, not code correctness,
  security authorization, or mission approval.
- `canonical-cli-scoping`: new helper and `flywheel-loop` surfaces need doctor,
  health, validate, audit, why, repair, schema, examples, JSON, and dry-run.
- `lean-formal-feedback-loop`: treat proof friction as evidence; the artifact
  ledger needs fixtures with witnesses and stable hashes, not prose assurance.
- `multi-pass-bug-hunting`: this pass hunts integration defects hidden by the
  now-converged r2 architecture.

Self-grade: `Y`

Composite score: `8.0/10.0`

Disposition: `auto_advance_eligible`

Reason: no TRUE Joshua-blocker class fires; seven findings should become Phase
4 bead amendments or additional acceptance gates.

## Source Lines Used

| Source | Relevant lines |
|---|---|
| r2 invariant and source of truth | `02-REFINE-r2.md:15-31` |
| r2 resolution states | `02-REFINE-r2.md:33-44` |
| r2 list-and-sort requirement | `02-REFINE-r2.md:46` |
| r2 failure modes FM1-FM7 | `02-REFINE-r2.md:50-68` |
| r2 bead table B1-B15 | `02-REFINE-r2.md:85-117` |
| r2 DAG | `02-REFINE-r2.md:196-224` |
| r2 dependency notes | `02-REFINE-r2.md:226-238` |
| r2 audit lens recommendation | `02-REFINE-r2.md:240-246` |
| r2 B1-B15 acceptance sketches | `02-REFINE-r2.md:259-425` |
| r2 CLI surface contract | `02-REFINE-r2.md:427-458` |
| r2 rollout state machine | `02-REFINE-r2.md:460-484` |
| r2 Phase 3 open questions | `02-REFINE-r2.md:486-502` |
| Phase 1 synthesis F1-F8 | `02-PHASE1-SYNTHESIS.md:23-99` |
| Phase 1 synthesis D1-D3 | `02-PHASE1-SYNTHESIS.md:101-121` |
| Phase 1 synthesis deep-dive scope | `02-PHASE1-SYNTHESIS.md:138-148` |
| INTENT Jeff consumer-path mismatch | `00-INTENT.md:135-163` |
| INTENT substrate-loss Finding 9 | `00-INTENT.md:166-177` |
| `/flywheel:plan` TRUE blocker classes | `~/.claude/commands/flywheel/plan.md:421-444` and `:488-494` |
| `/flywheel:plan` plan-space constraint | `~/.claude/commands/flywheel/plan.md:459-471` |
| orch-monitor sibling primitives | `orch-monitor.../01-RESEARCH-B.md:13-47` and `:51-88` |
| orch-monitor supervisor recommendation | `orch-monitor.../01-RESEARCH-B.md:259-320` |

## Findings Table

| ID | Severity | Beads affected | Description | Mitigation |
|---|---|---|---|---|
| CC-F1 | high | B1,B5,B6,B8,B12 | Ledger authority is global, but several acceptance gates are repo-local; without an ownership resolver, the gate can block the wrong repo or miss cross-session rows. | Amend B1/B12 with canonical ledger topology, `owning_orch`, `blocking_scope`, and repo-local cache regeneration fixtures. |
| CC-F2 | high | B6,B7,B8,B9,B10,B12 | Bootstrap recursion is recognized but still split across enforcement, override, dogfood, tests, and doctrine; enforce could land before self-wiring proof is durable. | Make B8 dogfood/bootstrap proof a dependency of B6 enforce flip and B10 doctrine; add a bootstrap self-proof fixture. |
| CC-F3 | high | B2,B11,B12 plus sibling orch-monitor | Cross-orch rollout does not yet compose with the 35-primitives orch-monitor inventory; two supervisors could emit separate action ledgers for the same artifact/failure. | Add a cross-plan action-ledger join key and explicit compose-vs-replace rule: wire-or-explain classifies artifacts; orch-monitor acts on runtime failures. |
| CC-F4 | medium | B5,B11,B12 | Doctor and status surfaces include counts and top rows, but remediation hints are only explicitly required in B11, not in B5 doctor JSON that fleet automation will consume. | Add `recommended_action`, `resolve_command`, and `owner_hint` to B5 doctor fields and B11 status, with JSON schema tests. |
| CC-F5 | medium | B10,B12 plus L108 sync path | Three-surface doctrine drift is cited as reference shape, but B10 only says `sync-canonical-doctrine.sh --check or equivalent`; the plan should bind to the L108 sync pattern instead of allowing a second drift checker. | Amend B10 to reuse the existing canonical sync/check path and require zero 3-surface drift before rollout. |
| CC-F6 | medium | B13,B14,B15 | Substrate-loss side branches and DCG orphan-reset blocker are ordered correctly in the DAG, but B14 could block migration/reset operations before B13 writes branch proof rows. | Require B14 shadow mode until B13 branch proof is present; add synthetic migration fixture and recovery-command proof. |
| CC-F7 | low | B1,B2,B3,B4,B9 | Source claim coverage is strong, but the Phase 4 beads should carry source-line anchors into bead descriptions so future workers do not detach acceptance gates from the plan evidence. | Add `source_refs` section to each bead body during Phase 4 decompose; no extra architecture needed. |

Findings total: 7

Findings by severity: critical 0, high 3, medium 3, low 1

Cross-bead findings count: 7

## Finding CC-F1 — Fleet Ledger Authority vs Repo-Local Blocking Scope

Severity: high

Class: cross-orch ownership / false halt risk

Beads affected: B1, B5, B6, B8, B12

Source lines:

- r2 declares the fleet-level ledger at `~/.local/state/flywheel/wire-or-explain-ledger.jsonl`
  and derived repo caches at `02-REFINE-r2.md:27-31`.
- B1 says the source-of-truth path is the JSONL ledger and caches regenerate
  from it at `02-REFINE-r2.md:259-272`.
- B6 fails tick close in enforce on unresolved rows at `02-REFINE-r2.md:322-331`.
- B12 says rows include `ship_repo` and `ship_actor`, and each orch blocks only
  on owned rows at `02-REFINE-r2.md:386-395`.
- The open question asks whether cross-orch ledger rows block only the owning
  repo or every fleet tick at `02-REFINE-r2.md:494-495`.

Description:

The plan correctly chooses a fleet-level ledger, but the enforcement rule is
repo-local tick close. The design does not yet define the ownership resolver
that turns global rows into "this tick must halt" vs "surface-only cross-orch
debt." Without that resolver, a row shipped by skillos could halt flywheel, or
a row shipped by flywheel for a sibling repo could be ignored by the only repo
that can wire it.

Attack/failure scenario:

1. `mobile-eats` ships a doctor probe row into the fleet ledger.
2. `flywheel-loop tick --repo /Users/josh/Developer/flywheel` runs in enforce.
3. B6 sees unresolved rows in the global ledger.
4. If no `blocking_scope` exists, the gate either fails flywheel incorrectly or
   silently excludes the row without a durable reason.
5. The system repeats the identity-drift class: truth exists, but local halt
   scope is wrong.

Mitigation:

Amend B1 schema and B12 rollout gates with these fields:

- `ship_repo`: canonical absolute path.
- `owning_orch`: session or identity expected to wire the artifact.
- `consumer_repo`: optional, for cross-repo consumer path.
- `blocking_scope`: enum `local_repo`, `owning_orch`, `fleet_surface_only`,
  `manual_review_only`.
- `scope_reason`: non-empty for non-local scopes.
- `scope_expires_at`: required for `fleet_surface_only` deferrals.

Acceptance gate amendment:

1. Fixture row from repo A with `blocking_scope=local_repo` blocks only repo A.
2. Fixture row from repo A with `consumer_repo=repo B` surfaces in repo B and
   does not halt repo C before expiry.
3. Missing `blocking_scope` is invalid in enforce mode.
4. Derived repo cache regenerated from the fleet ledger contains only rows
   relevant to that repo plus fleet-surface rows.
5. B12 smoke fixtures cover flywheel, skillos, alps, mobile-eats, vrtx, and
   picoz ownership boundaries.

Joshua decision needed: no

TRUE blocker class: none

## Finding CC-F2 — Bootstrap Recursion Still Needs a Hard Dependency

Severity: high

Class: bootstrap recursion / meta-gate self-proof

Beads affected: B6, B7, B8, B9, B10, B12

Source lines:

- FM5 is bootstrap recursion at `02-REFINE-r2.md:66`.
- B7 includes bootstrap and expiring overrides at `02-REFINE-r2.md:333-342`.
- B8 dogfoods today's corpus and imports proof rows at `02-REFINE-r2.md:343-351`.
- B9 includes an FM5 recursion fixture at `02-REFINE-r2.md:353-363`.
- B10 lands doctrine after mechanics at `02-REFINE-r2.md:365-373`.
- DAG currently has B6 -> B7 -> B9 and B8 -> B9, while B6 -> B10 at
  `02-REFINE-r2.md:204-213`.

Description:

The plan names bootstrap recursion, but the dependency shape still lets B6
land before the gate has proven it can wire its own artifacts. B6 can exist in
shadow safely, but enforce behavior should not be eligible until B8 dogfood and
B9 recursion fixtures prove the self-row closes without a permanent override.

Failure scenario:

1. B1-B6 ship the ledger and close hook.
2. The close hook emits wire-or-explain artifacts for itself.
3. Bootstrap override allows the first pass.
4. B8 dogfood has not yet imported or resolved the bootstrap row.
5. B10 doctrine lands and B12 starts rollout.
6. The system has doctrine and a close hook but no durable self-proof that the
   hook can close its own wiring loop.

Mitigation:

Keep B6 implementation split into `shadow_hook` and `enforce_flip`.

Dependency amendment:

- B6 shadow hook may depend on B5 only.
- B6 enforce flip must depend on B7, B8, and B9.
- B10 doctrine must cite the B8/B9 bootstrap proof receipt.
- B12 rollout must require `bootstrap_self_proof=PASS`.

Acceptance gate amendment:

1. B6 callback reports `mode_supported=shadow,enforce` but `enforce_enabled=false`
   until B8/B9 receipts exist.
2. B8 imports at least one row for the wire-or-explain gate itself.
3. B9 FM5 fixture proves bootstrap override is consumed once and cannot be
   reused after expiry.
4. `flywheel-loop doctor --json` reports `wire_or_explain_bootstrap_status`.
5. B10 L-rule cites the bootstrap proof path, not only plan prose.

Joshua decision needed: no

TRUE blocker class: none

## Finding CC-F3 — Wire-Or-Explain Must Compose With Orch-Monitor, Not Replace It

Severity: high

Class: cross-plan duplicate action loop

Beads affected: B2, B11, B12; sibling plan orch-monitor-recovery-auto-act

Source lines:

- r2 says the cross-cutting audit must verify composition with cross-orch
  sessions at `02-REFINE-r2.md:240-246`.
- B12 owns cross-orch rollout at `02-REFINE-r2.md:386-395`.
- The orch-monitor Lane B audit says the missing primitive is a fleet supervisor
  that consumes existing primitives as one closed loop at
  `orch-monitor.../01-RESEARCH-B.md:13-15`.
- That same audit lists 35 primitives and says the supervisor should output
  `~/.local/state/flywheel/orch-monitor-actions.jsonl` at
  `orch-monitor.../01-RESEARCH-B.md:51-88` and `:259-268`.
- The sibling plan recommends failure-class routing for frozen workers,
  queued prompts, dead codex, idle work, true blockers, substrate blocked,
  watcher missing, recovery SLO, comms silent, and token expiry at
  `orch-monitor.../01-RESEARCH-B.md:272-282`.

Description:

Wire-or-explain is an artifact wiring gate. Orch-monitor is a runtime recovery
supervisor. The two plans touch the same fleet sessions and doctor surfaces.
If Phase 4 does not encode a compose-vs-replace boundary, both plans can
create ledgers, status lines, and recommended actions that appear authoritative
for the same failure.

Failure scenario:

1. A frozen worker causes an unwired artifact row because a callback never lands.
2. Wire-or-explain ranks the row and B11 recommends a resolve/defer action.
3. Orch-monitor classifies the same pane as `frozen_worker` and recommends
   bounded recovery.
4. Without a shared join key, the two systems file separate beads or send
   separate packets.
5. The operator sees two "next actions" for one root condition.

Mitigation:

Add a cross-plan action contract:

- Wire-or-explain ledger rows carry `related_runtime_failure_id` when a runtime
  failure explains an unwired artifact.
- Orch-monitor action ledger rows carry `related_ship_event_id` when recovery
  is intended to unblock an artifact.
- Both ledgers use the same `dispatch_id`, `session`, `pane`, `repo`, and
  `fingerprint` fields where available.
- Wire-or-explain never restarts panes or mutates workers.
- Orch-monitor never classifies artifact wiring state as wired/deferred.

Acceptance gate amendment:

1. Fixture frozen pane with missing callback creates one orch-monitor action row
   and one wire-or-explain row joined by IDs.
2. `/flywheel:wire-status` renders "blocked_by_runtime_recovery=<action_id>"
   instead of recommending duplicate manual work.
3. Orch-monitor dry-run does not consume or rewrite wire-or-explain resolution
   states.
4. Wire-or-explain ranker can lower priority when a live orch-monitor action is
   already in progress.
5. No duplicate bead is filed for the same joined failure in the same tick.

Joshua decision needed: no

TRUE blocker class: none

## Finding CC-F4 — Remediation Hints Need To Be Machine-Readable in Doctor JSON

Severity: medium

Class: dashboard-only remediation risk

Beads affected: B5, B11, B12

Source lines:

- r2 maps F7 to B3/B5/B11 at `02-REFINE-r2.md:112-114`.
- B5 acceptance requires `.wire_or_explain` and top-five fields at
  `02-REFINE-r2.md:307-320`.
- B11 acceptance requires top three recommended actions and exact resolve/defer
  commands at `02-REFINE-r2.md:375-385`.
- Phase 1 F7 says doctor probes surface problems without remediation hints at
  `02-PHASE1-SYNTHESIS.md:89-94`.

Description:

B11 has operator remediation, but B5 doctor JSON is what fleet automation and
status aggregators will likely consume first. If B5 emits counts and top rows
without machine-readable actions, the system can regress into the exact F7
shape: problem surfaced, no next action substrate.

Mitigation:

Amend B5 with a nested `wire_or_explain.actions[]` array:

- `ship_event_id`
- `recommended_action`: `wire`, `defer`, `mark_not_required`, `fix_detector`,
  `runtime_recovery_pending`, `bead_required`
- `resolve_command`
- `dry_run_command`
- `owner_hint`
- `blocking_scope`
- `expires_at` for deferral/override

Acceptance gate amendment:

1. Every unresolved top row in doctor JSON includes one action object.
2. `resolve_command` is redacted-safe and runnable in dry-run.
3. `wire-status --json` and doctor JSON agree on action count.
4. Missing action hints make B5 tests fail.
5. B12 fleet rollout reads the doctor action object, not screen-scraped status
   text.

Joshua decision needed: no

TRUE blocker class: none

## Finding CC-F5 — B10 Should Reuse the L108 Three-Surface Sync Pattern

Severity: medium

Class: doctrine drift / duplicate mechanism risk

Beads affected: B10, B12

Source lines:

- r2 says the today-wired baseline is one sync/check chain at
  `02-REFINE-r2.md:119-131`.
- B10 requires L-rule landing in three surfaces and `sync-canonical-doctrine.sh
  --check or equivalent` at `02-REFINE-r2.md:365-373`.
- Source claim ledger says sync.sh is the reference wired shape at
  `02-REFINE-r2.md:514`.
- `/flywheel:plan` requires artifact shipped rows for plan outputs at
  `~/.claude/commands/flywheel/plan.md:459-465`.

Description:

The phrase "or equivalent" is too loose for the one known fully wired doctrine
path. B10 should reuse the exact L108/ft04-style doctrine propagation and drift
check, otherwise Phase 4 may create a second three-surface checker that passes
locally but is not consumed by tick close.

Mitigation:

Amend B10 acceptance gates:

1. L109 lands through the existing canonical doctrine propagation mechanism,
   not manual per-surface edits.
2. The same existing drift check that produced the D2 baseline is used.
3. B10 emits an artifact_shipped row for the L-rule and a resolution row showing
   `wired_into=<sync/check consumer>`.
4. Three-surface drift count is zero before B12 rollout.
5. B10 tests prove root AGENTS, `.flywheel/AGENTS-CANONICAL.md`, and
   `templates/flywheel-install/AGENTS.md` converge from one source.

Joshua decision needed: no

TRUE blocker class: none

## Finding CC-F6 — B14 DCG Enforcement Needs Shadow Mode Until B13 Branch Proof Exists

Severity: medium

Class: substrate-loss guard ordering / false block risk

Beads affected: B13, B14, B15

Source lines:

- INTENT Finding 9 says worker local main plus orch squash/reset orphaned two
  commits and proposes side branches, DCG reset blocker, and memory at
  `00-INTENT.md:166-177`.
- r2 places B13 -> B14 -> B15 at `02-REFINE-r2.md:219-223`.
- B13 writes side-branch proof to the wire-or-explain ledger at
  `02-REFINE-r2.md:397-405`.
- B14 blocks resets that would orphan local worker commits at
  `02-REFINE-r2.md:407-415`.

Description:

The DAG orders B13 before B14, which is correct. The missing cross-cutting
detail is mode. If B14 enforce lands before all dispatches have branch proof,
it can block legitimate reset/recovery operations for historical commits that
pre-date B13. That would push workers toward bypassing DCG, which the plan is
trying to avoid.

Mitigation:

Amend B14:

- `shadow` mode reports orphan risk and recovery commands without blocking.
- `enforce` mode requires B13 branch proof schema and at least one successful
  dispatch fixture.
- Pre-B13 historical orphan risks become `migration_window` warnings with
  bounded expiry.
- Recovery commands include side-branch creation, cherry-pick path, and reset
  retry proof.

Acceptance gate amendment:

1. Pre-B13 synthetic commit triggers warning in shadow, not block.
2. Post-B13 synthetic worker-main commit blocks reset in enforce.
3. Pushed worker branch passes.
4. Block message names the orphan commit and recovery commands.
5. Migration fixture never touches production refs.

Joshua decision needed: no

TRUE blocker class: none

## Finding CC-F7 — Carry Source Refs Into Phase 4 Beads

Severity: low

Class: evidence detachment / implementation drift

Beads affected: B1, B2, B3, B4, B9 and likely all Phase 4 bead bodies

Source lines:

- r2 has a detailed Source Claim Ledger at `02-REFINE-r2.md:504-517`.
- Phase 1 synthesis records the specific source disagreements at
  `02-PHASE1-SYNTHESIS.md:101-121`.
- `/flywheel:plan` says Phase 4 maps audit findings into beads at
  `~/.claude/commands/flywheel/plan.md:435-444`.

Description:

r2 is well-cited, but the future Phase 4 bead bodies can still drift if they
copy acceptance gates without the source refs. The fix is small: carry source
refs into each bead body so implementation workers can verify the local reason
for each gate.

Mitigation:

In Phase 4 decompose, every bead body gets:

```text
Source refs:
- <plan artifact>:<line>
- <audit finding>:<id>
- <doctrine/memory/skill ref>
```

Acceptance gate amendment:

1. Every B1-B15 bead has at least two plan source refs.
2. Beads amended by this audit cite `03-AUDIT-r1-cross-cutting.md#CC-Fx`.
3. Phase 5 polish rejects beads with no source refs.
4. Worker callbacks report `source_refs_verified=true`.
5. No new source refs require source-code edits during plan phases.

Joshua decision needed: no

TRUE blocker class: none

## TRUE Blocker Class Evaluation

Result: no TRUE blocker class triggered.

| Class | Triggered | Evaluation | Evidence |
|---|---|---|---|
| `new-platform-or-vendor-not-in-mission-lock` | no | The plan uses existing flywheel, ntm, br, DCG, Agent Mail, doctor, dispatch-log, and sibling observatory primitives. No new vendor or platform is introduced. | r2 bead table `02-REFINE-r2.md:85-117`; sibling primitive inventory `orch-monitor.../01-RESEARCH-B.md:51-88`. |
| `secret-rotation-or-new-credential-creation` | no | No secret rotation, credential creation, vault mutation, or token propagation is required. The only sensitive adjacent surfaces are Agent Mail ownership and doctor output, and this audit proposes IDs/paths, not raw secrets. | r2 scope `02-REFINE-r2.md:21-31`; B12 row fields `02-REFINE-r2.md:386-395`. |
| `financial-commitment-above-mission-budget` | no | No paid service, cloud resource, or budget commitment is proposed. All work is local plan/bead/test/doctor substrate. | `/flywheel:plan` plan-space constraint `~/.claude/commands/flywheel/plan.md:459-471`. |
| `legal-or-compliance-decision` | no | The plan changes operational gating and doctrine only. It does not decide legal retention, compliance policy, customer-facing disclosure, or regulated behavior. | r2 gate truth separation `02-REFINE-r2.md:44`. |
| `destructive-irreversible-on-shared-state` | no | B14 is about preventing destructive reset-induced orphaning. It must ship with shadow mode and synthetic fixtures, but the plan does not authorize an irreversible shared-state action. | INTENT F9 `00-INTENT.md:166-177`; B14 fixture constraint `02-REFINE-r2.md:407-415`. |
| `paradigm-conflict-with-active-mission` | no | The plan aligns with the active mission: move from passive measurement to closed-loop action, while preserving gate-truth separation and auto-advance unless a true blocker fires. | problem statement `02-REFINE-r2.md:7-13`; `/flywheel:plan` anti-pattern text `~/.claude/commands/flywheel/plan.md:488-494`. |

Blocker class evaluations: 6/6

Triggered blocker classes: none

## Composite Score

Score: `8.0/10.0`

Pass threshold: `>=7.0`

Verdict: pass

Scoring rubric used:

| Axis | Weight | Score | Rationale |
|---|---:|---:|---|
| Mechanism correctness | 2.0 | 1.7 | Core invariant, state model, and bead DAG are coherent. CC-F1/CC-F2 require sharper enforcement boundaries. |
| Cross-bead dependency safety | 2.0 | 1.5 | DAG is acyclic and mostly ordered, but bootstrap enforce split and B13/B14 mode gates need refinement. |
| Fleet/cross-orch composition | 2.0 | 1.4 | B12 names ownership, but needs resolver fields and compose contract with orch-monitor. |
| Doctor/status/CLI operability | 1.5 | 1.2 | CLI surface is strong; doctor remediation actions need machine-readable fields. |
| Rollout safety | 1.5 | 1.3 | Shadow/warn/enforce exists; bootstrap and DCG migration windows need explicit mode gates. |
| Evidence durability | 1.0 | 0.9 | Source refs are strong; Phase 4 beads should inherit them mechanically. |

Total: `8.0`

Why not lower:

- No critical finding.
- All high findings have local amendments that fit existing beads.
- No TRUE blocker class fires.
- The sibling orch-monitor conflict is a composition contract issue, not a
  paradigm conflict.

Why not higher:

- The gate is meta-infrastructure. Ownership and bootstrap errors would create
  fleet-wide false halts or false greens.
- The plan still leaves one key open question in enforcement scope at
  `02-REFINE-r2.md:494-495`; CC-F1 turns it into concrete schema work.

## Cross-Bead Integration Matrix

| Concern | Beads touched | Current r2 state | Audit disposition |
|---|---|---|---|
| Ledger writer to close gate | B1,B5,B6 | B1 root, B5 doctor, B6 close gate are ordered at `02-REFINE-r2.md:196-205`. | Sound, but needs global-to-local ownership resolver. |
| Bootstrap recursion | B6,B7,B8,B9,B10 | FM5 named; B7 override; B8 dogfood; B9 fixture; B10 doctrine. | Needs enforce flip dependency on B8/B9 proof. |
| Cross-orch rollout | B1,B6,B7,B11,B12 | B12 blocks only owned rows and surfaces cross-repo pending. | Needs `blocking_scope` and sibling orch-monitor join key. |
| Doctor field coherence | B5,B11 | B5 emits counts/top rows; B11 emits commands. | Add machine-readable action hints to B5. |
| Three-surface drift | B10,B12 | B10 says check or equivalent. | Bind to existing sync/check baseline. |
| Substrate loss | B13,B14,B15 | Correct structural/information/behavioral split. | Add B14 shadow migration window. |
| Evidence propagation | all | r2 source ledger is strong. | Carry source refs into Phase 4 bead bodies. |

## Recommended Phase 4 Amendments

1. Add `blocking_scope`, `owning_orch`, and `consumer_repo` fields to B1.
2. Split B6 into shadow hook vs enforce flip in the bead body, even if one bead
   implements both.
3. Add a B8/B9 bootstrap proof receipt as a hard precondition for B10/B12.
4. Add cross-plan join fields between wire-or-explain rows and
   orch-monitor action rows.
5. Add machine-readable `actions[]` to B5 doctor JSON.
6. Replace B10's "or equivalent" drift check with the existing canonical
   sync/check path used by the D2 baseline.
7. Put B14 in shadow until B13 branch proof fixtures pass.
8. Carry source refs into all Phase 4 beads and Phase 5 polish checks.

## Phase 4 Bead Amendment Map

| Existing bead | Required amendment from this audit |
|---|---|
| B1 `wire-or-explain-ledger-schema-and-writer` | Add ownership/scope fields, resolver tests, source refs. |
| B2 `wire-or-explain-ship-event-classifier` | Add join fields for runtime failures and worker branch artifacts. |
| B3 `wire-or-explain-wired-detector` | Ensure detector emits action-relevant reason codes. |
| B4 `wire-priority-ranker` | Lower priority when joined runtime recovery is already active. |
| B5 `wire-or-explain-doctor-fields` | Add `actions[]`, `owner_hint`, `resolve_command`, `blocking_scope`, and bootstrap status. |
| B6 `wire-or-explain-tick-close-gate` | Split shadow hook from enforce flip; enforce requires bootstrap proof. |
| B7 `wire-or-explain-shadow-enforce-override` | Own bootstrap override expiry and cross-repo pending semantics. |
| B8 `wire-or-explain-dogfood-import-2026-05-04` | Import self-row/bootstrap proof and D2 reference row. |
| B9 `wire-or-explain-fault-injection-tests` | Add cross-plan join fixture and B14 migration shadow fixture. |
| B10 `wire-or-explain-l109-three-surface-doctrine` | Reuse canonical sync/check, cite bootstrap proof, no "equivalent" drift checker. |
| B11 `wire-status-operator-surface` | Render action objects from doctor JSON; do not invent separate command text. |
| B12 `wire-or-explain-cross-orch-fleet-rollout` | Depend on ownership resolver, bootstrap proof, B15, and orch-monitor join contract. |
| B13 `dispatch-worker-side-branch-enforcement` | Ensure branch proof rows include enough data for B14 to trust them. |
| B14 `dcg-orphan-commit-reset-blocker` | Shadow before enforce, migration warnings for historical commits, synthetic-only fixtures. |
| B15 `substrate-loss-memory-and-learn-promotion` | Link memory/fuckup promotion to B13/B14 receipts and audit finding CC-F6. |

## Audit Ledger

Three-Q audit:

- VALIDATED: findings cite r2/intent/synthesis/sibling-plan line references.
- DOCUMENTED: each finding has affected beads, failure scenario, mitigation, and
  acceptance-gate amendment.
- SURFACED: no TRUE blocker class; high findings map to Phase 4 amendments.

Plan-space discipline:

- Source files edited: none.
- Beads DB writes: none.
- Commits: none.
- New artifact: `.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r1-cross-cutting.md`.

Callback fields:

```text
self_grade=Y
findings_total=7
findings_by_severity={critical:0,high:3,medium:3,low:1}
composite_score=8.0
true_blocker_classes_triggered=none
blocker_class_evaluations=6/6
cross_bead_findings_count=7
commits_total=0
```
