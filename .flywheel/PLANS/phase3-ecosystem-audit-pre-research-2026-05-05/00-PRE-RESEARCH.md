# Phase 3 Ecosystem Audit Pre-Research

date: 2026-05-05
mode: plan-space only
task_id: phase3-ecosystem-pre-research-2026-05-05
bead_db_writes: 0
repos_inventoried: 5
socraticode_queries: 5
output_scope: pre-research document only

## Executive Verdict

Phase 3 is not ready to execute. This pre-research is safe and useful now
because it inventories scope, surfaces, coordination, and run modes before any
ecosystem audit fires. The audit itself remains gated on:

- Phase 1 flywheel stamp PASS.
- Phase 2 template implementation DONE.
- A fresh repo onboarded via `flywheel-install` proving the 5-skill polish gate
  fires.
- Existing repo reconcile proving the gate installs without corrupting
  repo-local mission/docs.

All five ecosystem repos named in the dispatch are present locally:

- `/Users/josh/Developer/alpsinsurance`
- `/Users/josh/Developer/skillos`
- `/Users/josh/Developer/swarm-daemon`
- `/Users/josh/Developer/mobile-eats`
- `/Users/josh/Developer/vrtx`

The core risk is not scoring. The core risk is scope. ALPS root is
healthcare/insurance domain and is off-limits for this audit. Mobile Eats and
VRTX also contain product/client domain surfaces that should not be mutated by a
flywheel polish gate. The Phase 3 audit must run as read-only grading plus
finding packets, not cross-repo source mutation.

## System Frame

Boundary: flywheel-managed ecosystem repos, installed `.flywheel/` substrate,
peer orchestrator sessions, gate receipts, Zest Ledger / local grade ledgers,
and future repair beads created after audit findings are synthesized.

Stock: ungraded ecosystem surfaces that may carry flywheel operational risk.

Inflow:

- Repos initialized or reconciled from `templates/flywheel-install/`.
- New scripts, validators, README surfaces, doctrine docs, launchd drivers, and
  peer-orch dispatch surfaces.
- Cross-repo naming/contract references such as `flywheel-loop`, `/flywheel:`,
  launchd labels, JSONL ledgers, and absolute paths.

Outflow:

- A surface receives a 5-skill grade receipt.
- A finding lands in the owning repo's report and future bead plan.
- A legacy production surface is explicitly marked audit-only.
- A scope-excluded domain file is recorded as excluded, not graded.

Feedback loop:

- Signal: read-only audit report per repo.
- Actor/rule: owning orchestrator routes findings into beads or no-action
  receipts.
- Response: repair beads improve surfaces; reconcile propagates gate substrate.
- Delay risk: if all repos audit at once, findings outrun worker capacity.

Meadows leverage:

- #6 information flows: per-repo reports and doctor fields make quality debt
  visible to the owner.
- #5 rules: scope-allowlist and audit run mode prevent domain collisions.
- #4 self-organization: peer orch ownership lets each repo route findings
  without flywheel rewriting every project by hand.

## 1. Per-Repo Inventory

Inventory method:

- Read-only filesystem counts.
- No bead DB writes.
- No source edits.
- No audit execution.
- `READMEs` count excludes `.git`, `node_modules`, `.venv`, `target`, `dist`,
  and `build`.
- `test suites` means directories named `tests`, `test`, `spec`, or
  `__tests__`.
- `CLI binaries` means executable files in `bin/`, `scripts/`, or
  `.flywheel/scripts/` for the raw inventory. Full-scope executable counts are
  called out separately where needed.

| Repo | Local status | `.flywheel/` files | CLI binaries | READMEs | Test suites | Active grade estimate |
|---|---:|---:|---:|---:|---:|---:|
| `alpsinsurance` | present | 286 | 52 | 54 | 17 | 8 in-scope |
| `skillos` | present | 603 | 30 | 2 | 1 | 61 in-scope |
| `swarm-daemon` | present | 0 | 24 raw / 59 full-scope execs | 7 | 2 | 68 in-scope |
| `mobile-eats` | present | 644 | 9 | 63 | 0 | 16 in-scope |
| `vrtx` | present | 186 | 59 | 12 | 0 | 86 in-scope |

Total initial grade-surface estimate: 239-240, depending on whether loop config
JSON is graded as its own surface or as evidence for repo-local docs.

### alpsinsurance

Scope boundary:

- Strict scope: `.flywheel/` only.
- ALPS root is OFF-LIMITS.
- Root docs, backend, frontend, Workato data, insurance docs, integration
  recipes, and infrastructure files are not part of the Phase 3 polish-gate
  audit.

In-scope active surfaces:

- `.flywheel/scripts/*` executable surfaces.
- `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, `.flywheel/STATE.md`.
- `.flywheel/loop.json`.
- `.flywheel/validation-schema/*`.

Non-flywheel substrate that must not be touched:

- `backend/`
- `frontend/`
- `infrastructure/`
- `integrations/`
- `knowledge/workato-*`
- `raw_dumps/`
- `docs/compliance/`, `docs/integrations/`, `docs/deployment/`
- `reference-patterns/`
- `.beads/`, `.planning/`, `.ntm/`, caches, archives, and historical receipts

Run mode:

- Grade-only for discovery.
- Blocking only if a future ALPS-owned `.flywheel/` mutation tries to close
  without a gate receipt.
- No mutation outside `.flywheel/`.

### skillos

Scope boundary:

- In scope: `.flywheel/`, `scripts/`, `tests/`, `state/`, root `AGENTS.md`,
  root `README.md`, and skillos-specific operator docs.
- Skillos is peer orchestration substrate, not product domain code.
- Historical transcripts and outputs are not active surfaces.

In-scope active surfaces:

- 31 executable surfaces under active scope.
- 8 primary doc surfaces.
- 22 schema/config surfaces.
- 208 test files as evidence surfaces, not all grade targets.

Non-substrate or excluded surfaces:

- `outputs/` transcripts.
- `AGENTS.md.archive/` except when auditing provenance.
- `.beads/`, `.ntm/`, `.cass/`, caches, recovery backups.
- Generated or rolled-back artifacts unless they are the current installed
  surface.

Run mode:

- Warn-only first pass because skillos has active peer-orch coupling and large
  skill routing state.
- Blocking only after skillos-owning orchestrator accepts the Phase 3 report and
  creates repair beads.

### swarm-daemon

Scope boundary:

- Full repo is the Yuzu canon source-of-truth.
- It is the lowest-coupling neighbor in the cross-repo wiring map.
- It has no `.flywheel/` install substrate today, so Phase 3 audits canon,
  source, docs, and CLI surfaces directly.

In-scope active surfaces:

- Rust CLI and daemon source in `src/`.
- `bin/`, `scripts/`, `docker/scripts/`, and quality-gate scripts.
- Root `README.md`, `AGENTS.md`, `PLANNING.md`, and architecture docs.
- Cargo manifests and launchd plist surfaces.
- Tests under `tests/`, `analysis/tests/`, and Rust test harnesses.

Non-touch or caution surfaces:

- Build output, `target/`, generated `output/`, historical reports.
- Secret-bearing local files or docs that contain credential instructions.
- Jeff-owned names such as `br`, `ntm`, `agent-mail`, `dcg`, and related
  upstream contracts.

Run mode:

- First repo to audit.
- Grade-only, full repo.
- Findings become canon-repair beads or upstream-issue packets, not in-place
  mutation by this pre-research lane.

### mobile-eats

Scope boundary:

- Present locally.
- Flywheel audit scope: `.flywheel/`, `templates/flywheel-install/`, root
  `AGENTS.md`, root `README.md`.
- Product app code under `next-app/` is not part of this Phase 3 substrate
  audit unless the mobile-eats owner explicitly expands the scope.

In-scope active surfaces:

- 7 executable flywheel/script surfaces.
- 7 doc surfaces in active scope.
- 2 schema surfaces.
- Template copy under `templates/flywheel-install/`.

Non-flywheel substrate that must not be touched:

- `next-app/`
- `docs/legal/`
- product assets and app routes
- `.vercel/`, provider config, product deployment surfaces
- closed-bead historical receipts and reality-check plan artifacts unless used
  as read-only evidence

Run mode:

- Warn-only for flywheel substrate.
- Grade-only for root docs.
- No product mutation from the ecosystem polish audit.

### vrtx

Scope boundary:

- Present locally.
- Client engagement repo with lead-system/n8n/workflow domain code.
- Flywheel substrate scope: `.flywheel/`, root `AGENTS.md`, root `README.md`.
- Optional owner-approved audit scope: `scripts/` and `docs/runbooks/`, as
  grade-only operational surfaces.

In-scope active surfaces:

- 57 executable surfaces under the proposed active scope.
- 27 doc surfaces.
- 2 schema surfaces.

Non-flywheel substrate that must not be touched:

- `workflows/`
- `n8n-workflows/`
- `workers/`
- `data/`
- `fixtures/`
- `deliverables/`
- `docs/SIGNED-SCOPE-EMAIL-2026-04-22.md`
- `audits/**` historical records
- credential docs and `.secrets/`

Run mode:

- Last before ALPS if included in Phase 3 execution.
- Grade-only unless VRTX orchestrator requests repair beads.
- Never mutate signed scope, historical audits, or client deliverables.

## 2. Surface Discovery Per Repo

Surface classes for Phase 3:

- Executable files in allowed scope.
- CLI entrypoints and scripts with operator-facing behavior.
- Doctor, health, repair, validate, audit, why, status, watcher, and gate tools.
- README/operator docs for the repo or surface.
- Mission/goal/state docs that install or guide flywheel behavior.
- Schema files used by validators or doctor output.
- Launchd plist surfaces if they control a flywheel or Yuzu driver.
- Template files that propagate into future repos.

Excluded classes:

- `.beads/issues.jsonl*` and bead DB internals.
- `.ntm/` runtime logs.
- Historical `*.bak.*` snapshots.
- Generated receipts, dispatch logs, old handoffs, and transcripts.
- Build artifacts, `node_modules`, `target`, caches, and vendored packages.
- Domain source code excluded by repo-specific scope-allowlist.

Per-repo estimated grade surfaces:

| Repo | What counts | Estimate | Enforcement mode |
|---|---|---:|---|
| ALPS | `.flywheel` scripts/docs/schemas/loop config only | 8 | grade-only first pass; strict for future `.flywheel` mutations |
| skillos | `.flywheel`, active `scripts`, `tests`, `state`, root docs | 61 | warn-only first pass |
| swarm-daemon | full canon repo: Rust CLI, scripts, docs, tests, plists | 68 | grade-only first pass |
| mobile-eats | `.flywheel`, template copy, root operational docs | 16 | warn-only / grade-only |
| vrtx | `.flywheel`, root docs, selected scripts/runbooks | 86 | grade-only |

Total ecosystem estimate: 239 surfaces.

Counting rule:

Do not count every test file as a polish surface. Tests are evidence unless the
test harness itself is an operator-facing validator. Do count executable test
drivers, validation scripts, schema contracts, and README surfaces.

## 3. Pre-Known Gaps From Cross-Repo Wiring Map

Known coupling from `/tmp/cross-repo-wiring-map-2026-05-05.md`:

- 21+ launchd plists in `~/Library/LaunchAgents` encode `flywheel`,
  `flywheel-loop`, session names, or related labels. A rename or gate change
  can break them silently unless unload/reload and label migration are
  explicit.
- 145 JSONL ledgers under `~/.local/state/flywheel/` are inter-pane contracts.
  Filenames and row schemas are surface-adjacent and must be treated as
  compatibility contracts.
- Skillos and flywheel are the highest-coupling pair: 311 hard path refs plus
  436 `flywheel-loop` refs and 355 `/flywheel:` refs in the map's observed
  count set.
- `templates/flywheel-install/` has 20 files and propagates any gap linearly
  into future repos.
- `flywheel-loop` rename ripples through roughly 520 files.
- `/flywheel:` namespace rename ripples through roughly 438 files.
- Swarm-daemon is low outbound coupling but owns Yuzu canon, so it is the best
  first audit target.
- Jeff-owned tools (`ntm`, `br`, `bv`, `dcg`, `agent-mail`, `cass`,
  frankensqlite/frankensearch/frankentui family) are not rename targets and not
  ours to "polish" by changing names.

Implication:

Phase 3 must audit compatibility surfaces, not only code style. Launchd labels,
ledger row shapes, template copies, skill references, memory references, and
slash command names are all surface-adjacent.

## 4. Audit Run-Mode Design

Run modes:

- `grade-only`: read-only grade receipt; findings become reports or beads later.
- `warn-only`: doctor/status warning; does not block current repo work.
- `blocking-fail`: only after owner accepts the gate and only for future touched
  surfaces inside the declared scope.

Per-repo run mode:

| Repo | Initial mode | Why |
|---|---|---|
| swarm-daemon | grade-only | Full canon source, low coupling, best gate calibration target |
| skillos | warn-only | High flywheel coupling and active capability-control-plane mission |
| mobile-eats | warn-only / grade-only | Product app exists; flywheel substrate can be graded, product code excluded |
| vrtx | grade-only | Client repo with signed scope and domain surfaces |
| ALPS | grade-only, `.flywheel` only | Active client, domain-collision risk, root off-limits |

When audit fires:

- Manual Phase 3 launch by flywheel:1 after trigger probes pass.
- On-demand per owning orchestrator after it receives the Phase 3 packet.
- Not scheduled as a recurring fleet job until the first manual run produces
  stable receipts and manageable finding volume.

Finding destinations:

- Per-repo report:
  `.flywheel/PLANS/phase3-polish-gate-audit-2026-05-05/<repo>-REPORT.md`
  or the repo's equivalent plan/report path.
- Local grade ledger:
  `.flywheel/polish-gate/grades.jsonl` once Phase 2 implementation exists.
- Zest Ledger row when that substrate is available.
- Final synthesis in flywheel:
  `.flywheel/PLANS/phase3-ecosystem-audit-2026-05-05/99-SYNTHESIS.md`.

Finding routing:

- Critical scope violation: halt that repo audit and notify flywheel:1.
- Must-fix finding in grade-only mode: record; do not mutate.
- Must-fix finding in future blocking mode: owning repo cannot close a touched
  surface until a repair bead or waiver receipt exists.
- Client-domain finding outside declared scope: convert to
  `excluded_by_scope`, not a polish-gate failure.

Agent Mail coordination:

- Use Agent Mail capsules for cross-orch reports when available.
- Include report path, grade counts, scope allowlist, excluded path count,
  must-fix count, and requested owner action.
- Do not send secrets or raw credential material in capsules.

## 5. Cross-Repo Coordination Protocol

Chosen protocol:

Flywheel:1 coordinates; owning orchestrators audit their own repos.

Mechanism:

1. Flywheel:1 verifies Phase 3 readiness.
2. Flywheel:1 sends a structured audit packet to the owning orchestrator:
   `alpsinsurance`, `skillos`, `mobile-eats`, `vrtx`.
3. Each owning orchestrator runs the read-only audit in its own repo, using its
   repo-local scope-allowlist and mission lock.
4. Each owner writes its report in its repo and sends a callback/capsule with
   the report path and counts.
5. Flywheel:1 audits flywheel-owned/template surfaces and coordinates
   synthesis.
6. Swarm-daemon has no active NTM session in the current session list. Unless a
   swarm-daemon owning orchestrator is started, flywheel:1 can dispatch a
   read-only grade lane for swarm-daemon because it is canon/source inventory,
   not client mutation.

Justification:

- Scope ownership lives with the repo mission lock.
- Client repos should not be graded by a foreign orchestrator that might confuse
  substrate and domain surfaces.
- Flywheel still owns fleet productivity and synthesis.
- Agent Mail capsules make findings durable without cross-repo writes.
- This avoids ad-hoc per-repo doctrine edits.

Current NTM availability snapshot:

- `alpsinsurance`: session present; overall health reported error because some
  panes are errored/auth-stuck, but there are healthy active panes.
- `skillos`: session present; overall health reported error due one pane, but
  codex panes exist.
- `mobile-eats`: session present; overall health reported error due user pane,
  but codex panes exist.
- `vrtx`: session present; overall health reported error due user pane, but
  active worker/orch panes exist.
- `swarm-daemon`: no active NTM session observed.

Protocol consequence:

Before dispatching Phase 3, flywheel:1 should run a peer-orch availability
probe and either:

- send owner packets to healthy sessions;
- recover a peer orchestrator through the permit gate when allowed; or
- mark a repo `deferred_peer_orch_unavailable`.

## 6. Sequencing

Recommended order:

1. `swarm-daemon`
2. `skillos`
3. `mobile-eats`
4. `vrtx`
5. `alpsinsurance`
6. synthesis

Why `swarm-daemon` first:

- It is the Yuzu canon source-of-truth.
- It has low outbound coupling in the wiring map.
- It is full-repo in scope, so the gate can calibrate against a real source tree
  without client-domain collision.
- It exercises canonical CLI and README checks on a mature Rust/ops repo.

Why `skillos` second:

- It is the highest-coupling peer with flywheel.
- Its OS/control-plane mission makes it important, but it should not be the
  first calibration target because skillos/flywheel references are dense.

Why `mobile-eats` third:

- Present and flywheel-installed.
- Product code is excluded, giving a moderate substrate-only audit after the
  two internal/canon repos.

Why `vrtx` fourth:

- Client repo, but lower healthcare/insurance domain-collision risk than ALPS.
- Scope must protect signed client artifacts and n8n workflows.

Why `ALPS` last:

- Active client.
- Root is explicitly off-limits.
- Domain vocabulary collides with flywheel terms: doctor, ledger, worker,
  dispatch, tick, and reap.
- The audit must prove zero findings outside `.flywheel/`.

Estimated wall time:

| Repo | Estimate | Notes |
|---|---:|---|
| swarm-daemon | 90-120 min | full repo, Rust CLI + docs + tests |
| skillos | 75-105 min | many schemas/tests, high flywheel coupling |
| mobile-eats | 35-55 min | substrate scope only |
| vrtx | 60-90 min | many scripts; grade-only client guard |
| ALPS | 25-40 min | narrow `.flywheel` only, but strict scope proof required |
| synthesis | 45-75 min | cross-repo summary and bead DAG |

Stagger rule:

Do not run all audits at once. Start one repo, inspect findings volume, then
fan out to at most two parallel owner audits.

## 7. Risks and Mitigations

Risk 1: Phase 1 gate shape shifts.

Mitigation: Phase 3 waits on Phase 1 PASS and Phase 2 implementation evidence.
This pre-research is not permission to execute.

Risk 2: ALPS domain collision.

Mitigation: ALPS audit path is `.flywheel/` only. Dry-run audit must verify
zero findings outside `.flywheel/`; any outside finding halts ALPS audit.

Risk 3: VRTX and Mobile Eats product-code collision.

Mitigation: initial scope is flywheel substrate and root operational docs.
Product/client surfaces are excluded unless the owner expands scope in a
separate plan.

Risk 4: Peer orchestrators unavailable.

Mitigation: run NTM health and peer-orch permit checks before dispatch. Mark
deferred rather than forcing cross-orch work from flywheel.

Risk 5: Finding flood.

Mitigation: stagger audits, cap per-repo must-fix list to top P0/P1, and put
remaining issues in follow-up sections. Synthesis converts findings into a
small bead DAG.

Risk 6: Template propagation amplifies a bad gate.

Mitigation: require fresh install and existing reconcile fixtures before Phase
3. Do not audit ecosystem against an unproven template.

Risk 7: Launchd and ledger compatibility missed.

Mitigation: treat launchd labels and JSONL ledger row shapes as
surface-adjacent. Include them in flywheel/skillos/swarm audit packets.

Risk 8: Audit-only report becomes shelfware.

Mitigation: every report must include owner, next action, and future bead list.
Synthesis owns follow-through routing.

Risk 9: Secret leakage through reports.

Mitigation: no secrets in plan, report, callback, or capsule. Findings should
name secret-handling policy gaps without printing values.

Risk 10: Scoring inconsistency across repos.

Mitigation: use one common grade schema from Phase 2, include reviewer and
skill rubric evidence, and require three-judges sniff per report.

## 8. Phase 3 Trigger Conditions

Phase 3 ready condition:

- Phase 1 GO: flywheel wave-0 surfaces pass all five skills at `>=9.0` with no
  must-fix findings.
- Phase 2 EXECUTION DONE: flywheel-install has manifest, discovery, grade
  receipts, doctor fields, close validator hooks, tests, docs, and reconcile
  behavior.
- Fresh install proof: a temporary repo initialized through flywheel-install has
  the gate substrate and emits a grade/warn receipt.
- Existing repo reconcile proof: one existing repo can receive the gate
  idempotently without rewriting domain docs.
- Scope proof: ALPS-style fixture produces zero findings outside `.flywheel/`.
- Peer-orch readiness: owning sessions are healthy or explicitly deferred.
- Finding sink proof: reports can land in per-repo paths and synthesis can
  consume them.

Ready probe:

- Run the Phase 2 fresh-install fixture.
- Run the Phase 2 existing-reconcile fixture.
- Run a dry-run discovery against ALPS and assert excluded path count is
  nonzero while outside-scope finding count is zero.
- Run a peer-orch availability check.
- Confirm local grade ledger write/read works.

Halt conditions:

- Any audit proposes mutation.
- Any ALPS finding lands outside `.flywheel/`.
- A report includes secret material.
- A peer-orch packet cannot be delivered and no owner path exists.
- Fresh-install or reconcile gate proof regresses.
- Findings volume exceeds capacity and synthesis cannot route the first batch.
- Any repo's mission lock contradicts the proposed audit scope.

Mid-flight abort:

Abort only the affected repo audit. Do not abort the whole Phase 3 run unless
the gate schema itself is wrong or the Phase 2 template proof regresses.

## 9. Bead Decomposition

No beads are filed by this dispatch. This is a list only.

Candidate Phase 3 beads:

1. P3-00: Final readiness probe for Phase 3 trigger.
   - Scope: flywheel only.
   - Effort: 45-60 min.
   - Acceptance: Phase 1 PASS, Phase 2 fixtures pass, peer-orch availability
     classified, ALPS dry-run scope fixture clean.

2. P3-01: Swarm-daemon 5-skill grade-only audit.
   - Scope: full `/Users/josh/Developer/swarm-daemon`.
   - Effort: 90-120 min.
   - Acceptance: report path, surface count, top findings, no mutation.

3. P3-02: Skillos warn-only 5-skill audit.
   - Scope: owning skillos orchestrator.
   - Effort: 75-105 min.
   - Acceptance: owner report, high-coupling findings, repair bead candidates.

4. P3-03: Mobile Eats substrate-only audit.
   - Scope: `.flywheel/`, template copy, root operational docs.
   - Effort: 35-55 min.
   - Acceptance: zero product-code findings unless explicitly scope-expanded.

5. P3-04: VRTX grade-only substrate/runbook audit.
   - Scope: `.flywheel/`, root docs, selected scripts/runbooks.
   - Effort: 60-90 min.
   - Acceptance: signed scope and historical audits excluded.

6. P3-05: ALPS `.flywheel`-only audit.
   - Scope: `.flywheel/` only.
   - Effort: 25-40 min.
   - Acceptance: zero findings outside `.flywheel/`; root off-limits proof.

7. P3-06: Ecosystem synthesis and repair DAG.
   - Scope: flywheel synthesis.
   - Effort: 45-75 min.
   - Acceptance: consolidated findings, per-repo next-owner, proposed repair
     beads, and no silent findings.

DAG:

```text
P3-00 readiness
  -> P3-01 swarm-daemon
  -> P3-02 skillos
  -> P3-03 mobile-eats
  -> P3-04 vrtx
  -> P3-05 ALPS
  -> P3-06 synthesis
```

Parallelism:

- P3-01 should run first alone.
- P3-02 and P3-03 can run in parallel after P3-01 calibrates the rubric.
- P3-04 and P3-05 should run after the substrate/client-scope pattern is proven.

## 10. success criteria

Plan success criteria:

- This file exists at
  `.flywheel/PLANS/phase3-ecosystem-audit-pre-research-2026-05-05/00-PRE-RESEARCH.md`.
- It includes `scope-allowlist`, `ALPS`, and `success criteria` strings for
  L112.
- It inventories all five ecosystem repos and notes none are missing.
- It separates raw file counts from active grade-surface estimates.
- It defines per-repo scope boundaries and non-touch zones.
- It estimates total surfaces.
- It includes cross-repo wiring gaps.
- It chooses a coordination protocol.
- It sequences the audit and names halt conditions.
- It lists future beads without filing them.

Execution success criteria for future Phase 3:

- Every repo audit packet includes a scope-allowlist.
- ALPS audit produces zero findings outside `.flywheel/`.
- Peer owner callback includes report path, surface count, must-fix count,
  excluded path count, and bead/no-bead routing.
- No audit mutates source.
- Zest Ledger or local grade receipts capture every graded surface.
- Synthesis maps every finding to a repo owner and next action.
- Three-judges sniff is clean for each report or the report is reworked.

Three-judges sniff for this plan:

- Jeff: 9.5. Counts, run modes, owner protocol, readiness probes, and halt
  conditions are concrete enough to dispatch.
- Donella: 9.6. The plan names stock, inflow, outflow, loops, delays, and
  leverage points; it avoids parameter-only fixes.
- Joshua: 9.5. It protects active clients, does not jump ahead of Phase 1/2,
  and keeps audit work useful without becoming source mutation.

Composite: 9.53

Blockers found:

- Zero blockers for this pre-research artifact.
- Phase 3 execution remains intentionally blocked until trigger conditions pass.
