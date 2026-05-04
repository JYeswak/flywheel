# /jeff-convergence-audit Round 2 — Master Plan Review

## Findings count

- Total findings: 12
- Critical (blocks bead conversion): 3
- Major (should fix before convergence): 9
- Minor (nice-to-have): 0

## Findings

### F1 — Stream split misses downstream-consumer work
- **Dimension:** Stream completeness
- **Severity:** major
- **Evidence:** The plan declares only Stream A filings, Stream B local flywheel improvements, and Stream C doctor tentacles at lines 49-73. But the strategic scope includes "34 active Dicklesworthstone repos × 10 locally-installed tools × our flywheel doctrine" at line 4, and the tentacle model says every tool we depend on can drift silently at lines 63-65. There is no Stream D for downstream consumers: active fleet repos, client repos, worker templates, command docs, local launchd daemons, or runtime configs that consume the Jeff tools.
- **Recommended fix:** Add Stream D: "Downstream consumer hardening." It should cover consumer config updates, worker template changes, launchd/runtime migrations, and smoke tests in at least flywheel, picoz, skillos, and any client repo using the affected tentacle.

### F2 — Bead conversion target contradicts the graph
- **Dimension:** Bead dependency cycles / graph consistency
- **Severity:** critical
- **Evidence:** Section V says "Bead graph (3 streams, 30 beads total)" at line 335 and enumerates A=7, B=10, C=13 across lines 77-331. But the immediate next step says `/beads-workflow` should convert to "17 beads with dep graph" at line 415. This is not a cycle, but it is a conversion blocker: one of those counts is wrong before `br dep cycles` can even be meaningful.
- **Recommended fix:** Decide whether `/beads-workflow` receives 17 beads or all 30. If 17, explicitly mark which C or B beads are deferred and remove them from the graph. If 30, update line 415 and require cycle validation after conversion.

### F3 — B/C acceptance criteria are not mechanically verifiable enough
- **Dimension:** Acceptance criteria precision
- **Severity:** major
- **Evidence:** B3 accepts "at least one tick uses pane-work-signal as primary truth" at line 133, which does not prove false-idle detection is fixed or guarded by regression. B4 accepts "AGENTS.md updated, version bumped, propagation note added" at line 146, which does not prove command/hook consumers enforce the new doctrine. C8 says "Consumer: UNKNOWN" at line 283 but still has a bead. C9 says "no compile-time fallback warnings" at line 291 without defining the command. C10 says "source HEAD recent" at line 300 without a threshold.
- **Recommended fix:** For every B/C bead, rewrite acceptance as command + expected JSON/text. Examples: "run X, expect field Y == Z"; "doctor reports substrate status=green"; "regression fixture proves Codex active pane is non-idle." Beads with unknown consumers should become research beads, not implementation beads.

### F4 — Low effort estimates hide source-control and runtime complexity
- **Dimension:** Effort estimates
- **Severity:** major
- **Evidence:** B2 is estimated S/15min at lines 113-122, but the same plan says ntm is 514 commits behind at line 24, beads_rust origin refs are broken and worktree dirty at line 29, and B2 itself includes resolving broken refs plus pulling five repos at lines 117-120. B1 is estimated S/5min at lines 101-110 but it stops a daemon, changes PATH identity, restarts, and revalidates a filing premise. B9 is "S orchestrator + parallel workers (~20 min total)" at lines 191-197 but depends on B1 and B2 and produces six validated issue drafts.
- **Recommended fix:** Re-estimate B1/B2/B9 as M at minimum, split B2 into repo-specific beads, and add "blocked if dirty worktree/local commits require preservation decision."

### F5 — A6 is mis-tiered as a filing before validation proves upstream fault
- **Dimension:** Tier-classification correctness
- **Severity:** major
- **Evidence:** A6 is listed as a Stream A filing candidate despite "NEEDS DEEPER VALIDATION (stale substrate or stale cache?)" at line 88. The same stale top-pick symptom is used as a local C3 freshness measurement at lines 236-239. If stale input is caused by our bead sync, stale local checkout, or usage pattern, it is Stream B/C, not upstream Stream A.
- **Recommended fix:** Move A6 out of Stream A until a validation bead proves the stale recommendation reproduces on current upstream with a clean `.beads` fixture. Keep it as a B/C diagnostic candidate meanwhile.

### F6 — Hidden Joshua decisions are embedded in bead specs
- **Dimension:** Joshua-decision completeness
- **Severity:** critical
- **Evidence:** §VI lists 9 decisions at lines 384-392. It does not surface B1's choice to "Symlink `~/.local/bin/vc` → `~/.cargo/bin/vc` OR remove old binary" at line 106, nor the daemon kill at line 105. It does not surface B2's choice about pulling ntm with 63 local commits ahead (line 24 plus lines 117-120). It does not surface C13's "auto-clone or surface to Joshua" source-presence policy at line 327.
- **Recommended fix:** Add Joshua decisions for: (1) symlink vs remove old vc binary and daemon restart timing, (2) how to handle divergent local Jeff checkouts before pull, (3) whether C13 may auto-clone source repos or must ask first.

### F7 — Stream A validation ladder is asserted, not enforced
- **Dimension:** Validation ladder coverage
- **Severity:** major
- **Evidence:** The plan says every filing must pass the Filing Playbook validation ladder at line 79 and says filings match the template/playbook at line 55. But B9's acceptance only says "6 drafts on disk, validated, ready for submission" at line 196. There is no required artifact per filing proving repro, source trace, duplicate search, no-patch framing, and Monitor arm.
- **Recommended fix:** Add per-A bead acceptance requiring a `validation_ladder` block with explicit fields: repro command, current-upstream SHA, duplicate-search query/result, source observations, no-patch confirmation, draft path, and monitor plan.

### F8 — C-substrate measurements do not define the machine-readable shape
- **Dimension:** Substrate-registry shape
- **Severity:** major
- **Evidence:** Stream C promises "Measurement: validation command that returns machine-readable health" at line 69. But C1-C10 list prose checks like "`ntm version` parses" (line 219), "`br doctor` returns clean" (line 228), "top-pick recommendation includes a bead created within last 30d" (line 237), and "source HEAD recent" (line 300). These are not a defined JSON schema. Existing registry practice gives positive examples: the 28 current substrates have `validation_command`, `doctor_invariant_ref`, and `consumers`, and `substrate-registry-validate.sh --json` emits aggregate JSON fields like `coherent_ok`, `consumed_ok`, and failure arrays.
- **Recommended fix:** Define one JSON contract for tentacle probes before C1-C10 become beads, e.g. `{name,status,version,source_head,checks:[{name,status,evidence}],promotion:{warn,fail}}`, and require C11 to consume exactly that shape.

### F9 — Tentacle list omits adopted/evaluating Jeff tools
- **Dimension:** Tentacle coverage gaps
- **Severity:** major
- **Evidence:** Line 65 says ntm, br, bv, dcg, cass, mcp_agent_mail, vc, pi, frankensqlite, and asupersync are invisible to doctor. B5 lists additional repos to audit at lines 149-155, including `slb`, `storage_ballast_helper`, `meta_skill`, `franken_agent_detection`, `cross_agent_session_resumer`, and `coding_agent_account_manager`. Output 01 also shows local checkouts for `rano` and `process_triage`, but the master plan never decides whether they are tentacles.
- **Recommended fix:** Add a "candidate tentacles deferred" table with repo, current integration status, decision owner, and reason. At minimum include `repo_updater`, `process_triage`, `rano`, `franken_agent_detection`, `slb`, `coding_agent_usage_tracker`, and `coding_agent_account_manager`.

### F10 — No stale-plan refresh gate
- **Dimension:** Stale state risks
- **Severity:** major
- **Evidence:** The plan snapshot is fixed at 2026-05-01T17:50Z on line 3. It explicitly depends on volatile state: ntm#111 awaiting Jeff's implementation at lines 419-420, active vc daemon PID 43482 at line 418, B2 pulling stale repos at lines 113-122, and A7 waiting until #111 lands at lines 89-91. There is no "if this plan is older than 7 days" refresh requirement.
- **Recommended fix:** Add a pre-beads freshness gate: re-run repo inventory, issue status for ntm#111, local HEAD/ahead-behind checks, vc daemon PID/binary check, and source artifact timestamps if the plan is older than 24h for filings or 7d for local work.

### F11 — The ecosystem wiring checklist does not cover this plan's own future findings
- **Dimension:** Self-referential gaps
- **Severity:** major
- **Evidence:** Lines 423-427 list what is wired into the ecosystem: meta-rule memory, Filing Playbook, upstream issues reference, and this master plan plus artifacts. But the plan has no requirement to ingest Round 2 findings, future convergence failures, or bead-conversion deltas into the same ecosystem. Line 406 says convergence is "Round 1 of 1+" and line 414 calls for Round 2, but no line says Round 2 findings must update the master plan before conversion.
- **Recommended fix:** Add a "self-wiring" gate: every convergence finding must be either integrated into `00-MASTER-PLAN.md`, filed as a bead, or recorded with explicit no-change reason before `/beads-workflow`.

### F12 — Cross-stream dependencies are under-modeled
- **Dimension:** Cross-stream coupling
- **Severity:** critical
- **Evidence:** Line 93 says all Stream A filings depend on B1 or full-path invocation. B9 depends on B1/B2 at line 197. B10 depends on B5 at lines 199-208. B6 depends on B1/B2 at line 164. B7 depends on B1/B2 and maybe B6 at line 176. Yet line 374 says "Parallel-safe after B1: B2/B3/B5/B6/B10/C1-C10 can all run in parallel." That contradicts multiple explicit dependencies and will create wrong `br dep add` edges.
- **Recommended fix:** Replace the graph with an edge list before bead conversion. Minimum edges: B1→B2/B6/B7/B9/C7; B2→A1-A7/B6/B7/B9/C1/C2/C6/C9/C10; B5→B10; B6→B7 if MCP integration is in scope; C1-C10→C11→C12/C13.

## New Joshua-decisions surfaced

1. **vc binary remediation policy:** symlink `~/.local/bin/vc`, remove the stale binary, or use full-path invocation only? Evidence: plan lines 105-110.
2. **Divergent checkout pull policy:** may agents fast-forward/pull Jeff repos when local commits/worktree changes exist, or must they snapshot/ask first? Evidence: plan lines 24, 29, 117-120.
3. **Auto-clone policy for tentacles:** may C13 auto-clone missing adopted Jeff source repos, or only surface to Joshua? Evidence: plan line 327.
4. **Tentacle scope expansion:** are `repo_updater`, `process_triage`, `rano`, `franken_agent_detection`, `slb`, `coding_agent_usage_tracker`, and account-manager repos tentacles now or deferred? Evidence: plan lines 65 and 149-155.

## Convergence verdict

- ROUND 2 STATUS: findings present
- Recommendation: NEEDS JOSHUA-DECISION FIRST, then revise master plan and RUN ROUND 3

The plan is not ready for `/beads-workflow`. The blockers are the 17-vs-30 bead mismatch, hidden Joshua decisions, and contradictory cross-stream dependency claims.

## Gaps the plan EXPLICITLY does NOT cover (for transparency)

- ZestStream client delivery work and client repo feature priorities.
- skillos skill-authoring backlog except where L62/L54 touches Jeff-derived skills.
- Direct patches to Jeff repos; filings are evidence/draft only.
- Full migration from shell/Python flywheel runtime to Rust/asupersync/frankensqlite.
- Full public issue submission automation without Joshua review.
