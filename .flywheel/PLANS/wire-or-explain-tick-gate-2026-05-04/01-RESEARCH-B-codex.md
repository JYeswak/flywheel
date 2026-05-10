---
title: "Lane B Codex-Parallel Ecosystem Audit"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Lane B Codex-Parallel Ecosystem Audit

Plan: wire-or-explain-tick-gate-2026-05-04
Lane: B codex-parallel
Worker: flywheel:3 / MagentaPond
Date: 2026-05-04
Output: .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/01-RESEARCH-B-codex.md
Status: final after independent draft plus parallel Lane B convergence read
Socraticode queries: 6
Indexed chunks observed: 198092

## 1. Executive Finding

The flywheel repo already has many observation surfaces.
It does not yet have a single ship ledger that forces every shipped artifact to resolve to a consumer.
The closest current mechanism is doctor callback validation with `surfaces_unwired_count`.
That field proves the doctrine exists, but it is not the universal tick-close gate requested by the plan.
Today the system can notice some unwired surfaces after the fact.
It cannot yet refuse a tick close because a just-shipped script, rule, plist, hook, or command was not wired or deferred.

The right Lane C shape is a small, append-only, idempotent registry plus a doctor/tick gate.
Every ship event records one artifact row.
Each row must resolve to exactly one of:
`wired_into=<consumer>`, `deferred_until=<bead|iso_ts>`, or `not_applicable=<reason>`.
Unresolved rows younger than a very small grace window remain warnings in shadow mode.
Unresolved rows older than 24h fail tick close.
The tick prompt must carry the oldest and highest-downstream-cost offenders, per CoralRaven's addendum in `00-INTENT.md`.

This is not a request to build another dashboard.
It is a request to make existing dashboards, scripts, rules, hooks, plists, and commands prove their consumers.
The leverage point is the information-flow rule at tick close, not another observation primitive.

## 2. Required Source Posture

Read first:
`/tmp/dispatch_woe_lane_b.md`
`.flywheel/PLANS/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md`
`/tmp/alps_vercel_blocker_deep_dive.md`
`/tmp/alps_vercel_orchestrator_meta_failure.md`
`.flywheel/PLANS/orch-monitor-recovery-auto-act-2026-05-04/01-RESEARCH-B.md`

Skills consulted:
`agent-mail`
`donella-meadows-systems-thinking`
`dicklesworthstone-stack`
`gate-truth-separation`
`observability-platform`
`jeff-convergence-audit`
`canonical-cli-scoping`

Independence constraint:
The parallel Lane B artifact was not read before this draft.
Only after this independent audit is written should the convergence section be patched.

## 3. Intent Trace

The plan intent says tick completion must fail when newly shipped artifacts remain unwired.
The desired invariant is not "write a report about wiring."
The desired invariant is "a ship cannot silently disappear from all consumers."

The intent file names six current offender classes:
peer-orch productivity.
conformance.
comms.
process gap.
observatory aggregate.
L101-L108 doctrine runtime enforcers.

The intent file also names the sibling plan boundary:
`orch-monitor-recovery-auto-act` answers "act on observation."
This plan answers "do not ship observation without a consumer."

The CoralRaven addendum strengthens the output contract.
The tick close packet should emit the full unresolved list.
It should also sort by age, ship cost, and downstream dependency count.
At minimum it should surface:
`unwired_artifact_top_5_oldest`.
`unwired_artifact_top_5_highest_downstream_cost`.

The ALPS Vercel blocker reports the same failure class from the permit side.
The substrate had refuse gates.
It lacked a symmetric permit/license gate that could authorize obvious mission-licensed work.
That is an instance of "mechanism shipped, not wired to the decision point."

## 4. Current Closest Mechanism

`~/.claude/skills/.flywheel/bin/flywheel-loop` already knows the idea of unwired surfaces.
The strongest local evidence is in the doctor callback validation section.
It computes validation signals with producer, measurement, consumer, and promotion_path metadata.
It also reports `surfaces_unwired_count`.

Evidence:
`~/.claude/skills/.flywheel/bin/flywheel-loop:4136` starts callback validation.
`~/.claude/skills/.flywheel/bin/flywheel-loop:4357` builds validation signal metadata.
`~/.claude/skills/.flywheel/bin/flywheel-loop:4441` emits callback validation counts.
`~/.claude/skills/.flywheel/bin/flywheel-loop:6001` reads callback validation and surface audit data.
`~/.claude/skills/.flywheel/bin/flywheel-loop:6124` includes `surfaces_unwired_count` in the doctor packet.
`tests/doctor-validation-signals.sh:140` verifies the field exists.
`tests/doctor-validation-signals.sh:144` checks producer/measurement/consumer/promotion_path metadata.
`tests/three-q-surface-audit.sh:96` checks `surfaces_unwired_count`.

Gap:
This is a validation-signal surface, not a mandatory ship ledger.
It does not require every newly created artifact to register its intended consumer before tick close.
It also cannot explain why an unwired item is intentionally deferred.

## 5. B.1 Consumer Inventory

### 5.1 Consumer: flywheel-loop tick driver

Path:
`~/.claude/skills/.flywheel/bin/flywheel-loop`

Consumes what:
Loop state, repo-local `.flywheel` files, doctor results, dispatch logs, receipts, recovery probes, callback validation, and driver proof.

Registration point:
`flywheel-loop:6381` begins `portable_tick`.
`flywheel-loop:6419` writes a tick receipt under `.flywheel/ticks`.
`flywheel-loop:6360` runs auto-respawn before tick.

Discoverability command:
`~/.claude/skills/.flywheel/bin/flywheel-loop tick --repo /Users/josh/Developer/flywheel --dry-run`
`~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel`

Failure mode:
The tick driver can complete a tick with a receipt while newly shipped artifacts have no consumer row.
Its current decision logic mostly chooses between dirty worktree, docs, tests, overrides, and dispatch state.
It does not yet read an append-only `wire_or_explain` ledger and fail on unresolved ship rows.

Example wired today:
Callback validation counts are consumed into doctor output and the packet field `surfaces_unwired_count`.

Example should-be-wired-but-isnt:
A newly committed script in `.flywheel/scripts/` can land without registering a doctor probe, command surface, LaunchAgent, hook, or explicit deferral bead.

Assessment:
This is the main enforcement point.
Lane C should add a tick-close check here, but keep the registry writer separate.

### 5.2 Consumer: flywheel-loop doctor

Path:
`~/.claude/skills/.flywheel/bin/flywheel-loop`

Consumes what:
Probe outputs from conformance, comms health, process gap, shared-surface reservations, watcher coverage, recovery SLO, peer productivity, callback validation, and three-question surface audit.

Registration point:
`flywheel-loop:3551` registers fleet conformance JSON.
`flywheel-loop:3585` registers fleet comms health JSON.
`flywheel-loop:3623` registers fleet process gap detector JSON.
`flywheel-loop:3659` registers shared-surface reservation JSON.
`flywheel-loop:3691` registers fleet watcher coverage JSON.
`flywheel-loop:3725` registers recovery SLO probe JSON.
`flywheel-loop:4607` registers peer productivity watch doctor JSON.

Discoverability command:
`~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json`

Failure mode:
Doctor has a long list of manually registered probe consumers.
Adding a probe is still an edit-by-memory task.
If a new script ships but no doctor stanza is added, the doctor cannot know.

Example wired today:
`peer_orch_idle_with_work_available_count` can fail doctor with action `send_peer_orch_productivity_escalation`.

Example should-be-wired-but-isnt:
The generic "script shipped" event is not automatically mapped to "doctor probe expected" or "not a doctor probe."

Assessment:
Doctor should consume `wire_or_explain status --json`.
It should not become the registry writer.
It should turn unresolved rows into warning/fail signals with producer, measurement, consumer, and promotion_path metadata.

### 5.3 Consumer: LaunchAgents

Path:
`~/Library/LaunchAgents/ai.zeststream.*.plist`

Consumes what:
Executable paths, intervals, environment variables, labels, logs, and launchd loaded state.

Registration point:
`~/Library/LaunchAgents/ai.zeststream.flywheel-flywheel-loop.plist:5` uses `.flywheel/flywheel-loop-tick`.
`~/Library/LaunchAgents/ai.zeststream.flywheel-flywheel-loop.plist:13` sets a 1800 second cadence.
`~/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist:5` runs `.flywheel/scripts/ntm-fleet-health.sh`.
`~/Library/LaunchAgents/ai.zeststream.frozen-pane-detector-fleet.plist:5` runs frozen-pane detection.
`~/Library/LaunchAgents/ai.zeststream.alps-idle-pane-watch.plist:5` runs idle pane auto-dispatch.
`~/Library/LaunchAgents/ai.zeststream.canonical-meta-rules-sync-watchdog.plist:6` runs canonical meta-rule sync.

Discoverability command:
`launchctl list | rg 'ai\\.zeststream'`
`plutil -p ~/Library/LaunchAgents/ai.zeststream.flywheel-flywheel-loop.plist`

Failure mode:
A LaunchAgent can exist but be disabled, stale, unloaded, pointing at a removed script, or missing a consumer ledger row.
`flywheel-loop` can classify driver_status, but generic ship events do not require launchd registration when a script is intended as a daemon.

Example wired today:
The flywheel loop plist points at `.flywheel/flywheel-loop-tick`, and driver proof checks parse plist program arguments.

Example should-be-wired-but-isnt:
If a new watcher script is committed, no gate asks whether a LaunchAgent should be created, explicitly deferred, or declared manual-only.

Assessment:
Launchd is a consumer, not a source of truth.
The registry should record `consumer_type=launchd` rows and doctor should verify loaded status for rows that claim launchd wiring.

### 5.4 Consumer: canonical meta-rule sync

Path:
`~/.flywheel/canonical-meta-rules/sync.sh`

Consumes what:
Canonical L-rule blocks from `~/Developer/flywheel/AGENTS.md`, repo-local `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and optional templates.

Registration point:
`sync.sh:16` identifies `~/Developer/flywheel/AGENTS.md` as canonical source.
`sync.sh:27` defines three-surface modes.
`sync.sh:106` chooses per-repo surfaces.
`sync.sh:140` computes missing and drift counts.
`sync.sh:209` defines the default fleet repos.

Discoverability command:
`~/.flywheel/canonical-meta-rules/sync.sh --fleet-check-three-surface --json`
`~/.flywheel/canonical-meta-rules/sync.sh --apply-three-surface --repo /Users/josh/Developer/flywheel`

Failure mode:
It covers L-rule propagation only.
It does not cover generic scripts, slash commands, hooks, plists, receipts, tests, or beads.

Example wired today:
Canonical L-rules are measurable across three surfaces.

Example should-be-wired-but-isnt:
L101-L108 runtime enforcers can exist as doctrine without proof of a runtime consumer unless a separate doctor/test/hook row is added.

Assessment:
Keep this specialized.
Do not overload it into the generic ship ledger.
Instead, `wire_or_explain` rows for `artifact_kind=l_rule` can require `wired_into=canonical-meta-rules-sync` plus an enforcement/probe row when the rule claims runtime behavior.

### 5.5 Consumer: Claude hooks

Path:
`~/.claude/hooks/`

Consumes what:
Tool events from Claude settings: PreToolUse, UserPromptSubmit, PostToolUse, and Stop.

Registration point:
`~/.claude/settings.json:106` registers PreToolUse hooks.
`~/.claude/settings.json:224` registers UserPromptSubmit hooks.
`~/.claude/settings.json:408` registers PostToolUse hooks.
`~/.claude/settings.json:475` leaves Stop hooks empty.
`~/.claude/hooks/flywheel-loop-readiness-gate.sh:111` blocks source mutation in partially initialized loop repos.
`~/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh:60` allows the canonical dispatch transport.
`~/.claude/hooks/flywheel-doctrine-sync-post-edit.sh:119` runs doctrine sync after AGENTS/template edits.
`~/.claude/hooks/mission-pretooluse-blocker.sh:74` watches dispatch-class commands.

Discoverability command:
`jq '.hooks' ~/.claude/settings.json`
`rg -n 'flywheel|mission' ~/.claude/hooks ~/.claude/settings.json`

Failure mode:
Hooks are strong enforcement points for Claude.
Codex does not receive those hooks.
Hook-only enforcement silently fails for Codex workers and shell scripts.

Example wired today:
Doctrine sync runs after relevant Write/Edit/MultiEdit events.

Example should-be-wired-but-isnt:
No Stop hook exists to reject a task closeout with unresolved newly shipped artifacts.
Codex workers need the same rule through tick/doctor or dispatch template, not only hooks.

Assessment:
Use hooks as one consumer of the ledger.
Do not make hooks the only enforcement path.

### 5.6 Consumer: dispatch template

Path:
`~/.claude/commands/flywheel/_shared/dispatch-template.md`

Consumes what:
Worker packet identity, file reservation, callback validation, DID/DIDNT/GAPS, four-lens audit, and callback envelope fields.

Registration point:
`dispatch-template.md:24` starts callback contract.
`dispatch-template.md:55` starts identity registry instructions.
`dispatch-template.md:133` starts shared surface reservation instructions.
`dispatch-template.md:179` starts verify-callback instructions.
`dispatch-template.md:211` starts DID/DIDNT/GAPS.
`dispatch-template.md:232` starts four-lens audit.
`dispatch-template.md:380` includes final callback envelope fields.
`dispatch-template.md:394` mandates Agent Mail reservation for file edits.

Discoverability command:
`rg -n 'wire|callback|reservation|DID|DIDNT|GAPS' ~/.claude/commands/flywheel/_shared/dispatch-template.md`

Failure mode:
The template asks workers to report work and gaps.
It does not yet require each produced artifact to report its consumer or deferral.

Example wired today:
Callback validation and shared surface reservation are explicit in the packet.

Example should-be-wired-but-isnt:
A worker can create a script/test/command/docctrine rule and still send DONE without `artifacts_registered=` rows.

Assessment:
Add a dispatch packet block requiring `wire_or_explain register` for every created artifact.
Callbacks should include `artifacts_registered=N`, `artifacts_unresolved=N`, and the output path to the ledger excerpt.

### 5.7 Consumer: repo-local flywheel-loop-tick

Path:
`.flywheel/flywheel-loop-tick`

Consumes what:
Repo-local phase state, dispatch logs, callbacks, doctor signals, inbox events, frozen detector, canonical pull, value gap probe, Agent Mail probe, and pre-tick event streams.

Registration point:
`.flywheel/flywheel-loop-tick:388` defines valid phases and tick class.
`.flywheel/flywheel-loop-tick:505` moves to validate/integrate on in-flight dispatch.
`.flywheel/flywheel-loop-tick:633` starts callback validation reaper gate.
`.flywheel/flywheel-loop-tick:804` begins pre-tick event aggregation.
`.flywheel/flywheel-loop-tick:1054` writes the prompt prelude.
`.flywheel/flywheel-loop-tick:1129` sends the prompt through `ntm send`.
`.flywheel/flywheel-loop-tick:1147` appends a dispatch log row.

Discoverability command:
`.flywheel/flywheel-loop-tick --dry-run`
`rg -n 'callback_validation|dispatch_log|ntm send|pre_tick' .flywheel/flywheel-loop-tick`

Failure mode:
The tick shell has many event feeds.
It does not include a wire/explain event feed.
It records dispatch log fields but no artifact registration summary.

Example wired today:
Callback validation results are added to the prompt and dispatch log.

Example should-be-wired-but-isnt:
The tick prompt does not yet include `unwired_artifact_top_5_oldest` or `unwired_artifact_top_5_highest_downstream_cost`.

Assessment:
This should be the repo-local reader of the gate.
It can add a small pre-tick event source from `wire_or_explain status --json`.

### 5.8 Consumer: pre-commit and post-commit hooks

Path:
`.git/hooks/pre-commit`
`.git/hooks/post-commit`

Consumes what:
Commit-time changes.

Registration point:
No enabled repo-local pre-commit or post-commit hook was found.
The present files are sample hooks only.

Discoverability command:
`find .git/hooks -maxdepth 1 -type f ! -name '*.sample' -perm -111 -print`

Failure mode:
Commit-time is currently not a flywheel enforcement point in this repo.
A commit can add an artifact without a ship-ledger row.

Example wired today:
No enabled example found in this repo.

Example should-be-wired-but-isnt:
Any commit that creates `.flywheel/scripts/*`, `.claude/commands/*`, `~/Library/LaunchAgents/*`, or canonical L-rule runtime doctrine should require either registration or explicit opt-out.

Assessment:
Commit hooks are optional and risky because many agents bypass local hook assumptions.
If used, keep them advisory first and make tick-close the authoritative fail gate.

### 5.9 Consumer: crontab

Path:
User crontab

Consumes what:
Time-based jobs outside launchd.

Registration point:
`crontab -l` shows unrelated jobs for KS intelligence, ingestion check, UBS update, backup-to-s3, and disk watchdog.

Discoverability command:
`crontab -l`

Failure mode:
Cron does not currently wire flywheel artifacts.
It is a legacy scheduler surface that can hide orphaned scripts if used ad hoc.

Example wired today:
No flywheel wire/explain consumer found in crontab.

Example should-be-wired-but-isnt:
No new flywheel watcher should be wired only through cron without a ledger row and doctor discoverability.

Assessment:
Treat cron as a consumer type for detection.
Prefer launchd for macOS persistent loops.

### 5.10 Consumer: Agent Mail MCP wiring

Path:
`~/.codex/config.toml`
`~/.mcp.json`
`.flywheel/scripts/agent-mail-send-redacted.sh`

Consumes what:
MCP server config, bearer-header auth, identity registry metadata, file reservations, inbox/callback coordination, and redacted send wrappers.

Registration point:
`~/.codex/config.toml:73` configures the mcp-agent-mail server.
`~/.mcp.json:13` configures the local MCP URL and Authorization header.
`.flywheel/scripts/agent-mail-send-redacted.sh:18` builds a redacted Agent Mail wrapper.
`.flywheel/scripts/agent-mail-send-redacted.sh:131` emits tool arguments with redacted registration token handling.

Discoverability command:
`rg -n 'mcp-agent-mail|agent-mail|registration_token|Authorization' ~/.codex/config.toml ~/.mcp.json .flywheel/scripts`

Failure mode:
Agent Mail reservations require identity/token context.
Codex must not echo raw tokens.
If MCP session authentication is missing, direct MCP file reservation can fail even though a shared-surface reservation script can still coordinate.

Example wired today:
Shared surface reservation successfully reserved this output artifact path.

Example should-be-wired-but-isnt:
The final ship ledger should be readable by Agent Mail or dispatch validation so callbacks can prove `artifacts_registered=N`.

Assessment:
Agent Mail is a coordination substrate.
It should not be the only artifact registry, but it should be allowed to carry callbacks and reservation references.

## 6. System Diagnosis By Mechanism Type

Observation mechanisms are abundant.
Registration mechanisms are partial.
Permit mechanisms are underdeveloped.
Tick-close enforcement is the missing choke point.

The repo has a repeated pattern:
Build probe.
Add doctor line.
Add status line.
Add L-rule.
Do not always add a runtime owner.
Then rediscover the gap during the next audit.

The proposed gate must make the missing owner visible at the time of ship.
It should not ask every worker to reason from first principles.
It should ask for a small structured row.

## 7. Jeff / Upstream Pattern Survey

### 7.1 ADOPT: install-time service registration with verify mode

Jeff evidence:
`remote_compilation_helper/install.sh:2510` exposes install options.
`remote_compilation_helper/install.sh:2542` wires systemd/launchd service setup.
`storage_ballast_helper/src/cli_app.rs:830` has a service registration branch.
`storage_ballast_helper/src/cli_app.rs:892` tells the operator how to verify launchctl state.

Adopt:
`wire_or_explain register` should have `--verify-only` and `--apply` modes.
The gate should support "show what would be required" before enforcement.

### 7.2 ADOPT: versioned artifact manifest with hash and run correlation

Jeff evidence:
`process_triage/docs/E2E_ARTIFACT_MANIFEST.md:1` defines a versioned manifest.
The manifest requires run_id, commands, logs, artifact paths, metrics, and hashes.

Adopt:
Artifact rows should carry producer commit, producer command, path hash, and source run id if available.
This makes idempotent re-runs cheap and auditable.

### 7.3 ADOPT: downstream consumer list as a release-gate input

Jeff evidence:
`frankenfs/docs/reports/SOAK_CANARY_CAMPAIGNS.md:22` lists manifest profiles.
`frankenfs/docs/reports/SOAK_CANARY_CAMPAIGNS.md:59` says validators fail closed when proof-bundle or release-gate consumers are dropped.

Adopt:
Rows that claim `wired_into=<consumer>` should be verified by consumer-specific probes.
Dropping a consumer should not silently mark the artifact wired.

### 7.4 ADOPT: heartbeat/watchdog staleness

Jeff evidence:
`frankenterm/crates/frankenterm-core/src/watchdog.rs:1` describes subsystem heartbeat monitoring.
`frankenterm/crates/frankenterm-core/src/watchdog.rs:364` starts a background monitor.
`frankenterm/crates/frankenterm-core/src/watchdog.rs:366` explicitly avoids forced restarts.

Adopt:
For `wired_into=daemon|watcher`, the gate should check heartbeat freshness.
Do not infer health from file presence.

### 7.5 EXTEND: policy Allow / Deny / RequireApproval

Jeff evidence:
`flywheel_connectors/connectors/docusign/src/signing.rs:214` models action policies.
`flywheel_connectors/connectors/microsoft365/src/sharepoint.rs:1859` tests allow, deny, and approval cases.

Extend:
Wire/explain rows can use a similar tri-state:
`wired`, `deferred`, `not_applicable`.
Do not call `deferred` a pass unless it has a bead or deadline.

### 7.6 ADOPT: every deny path writes an audit row

Jeff evidence:
`frankenterm/docs/security/policy-denial-audit-wiring-matrix.md:1` maps deny paths to audit wiring.

Adopt:
Every tick-close failure for unwired artifacts must write a row.
Rows should include the missing consumer, age, downstream cost, and recommended next action.

### 7.7 ADOPT: graduated enforcement states

Jeff evidence:
`remote_compilation_helper/rch-common/tests/feature_flags_rollout_e2e.rs:50` defines Disabled, DryRun, Canary, and Enabled.
`frankenterm/tests/e2e/test_replay_shadow_rollout.sh:1` tests shadow, enforce, and killswitch paths.
`pi_agent_rust/tests/graduated_rollout_integration_sec72.rs:1` tests rollout progression and rollback guards.

Adopt:
Ship `WIRE_OR_EXPLAIN_MODE=shadow` first.
Move to `warn` after false positives are classified.
Move to `fail` only for rows older than 24h or critical artifact kinds.

### 7.8 ADOPT: service boundary discovery and health subjects

Jeff evidence:
`asupersync/src/messaging/service.rs:2481` validates service registration and exposes discovery and health control handlers.

Adopt:
Every registered consumer type should have a discoverability command.
The gate should fail rows with `wired_into=<consumer>` if there is no discoverability command.

### 7.9 EXTEND: generated manifest with repro command

Jeff evidence:
`beads_rust/tests/bench_synthetic_scale.rs:1811` generates a manifest with metrics, health, content hash, and reproduction command.

Extend:
`wire_or_explain` rows should include `verify_command`.
This lets doctor rerun evidence without reading prose.

### 7.10 AVOID: supervisor restarts as proof of wiring

Jeff evidence:
`franken_node/crates/franken-node/src/connector/supervision.rs:1841` handles supervision escalation and restart windows.

Avoid:
Do not count restart capability as the same thing as consumer wiring.
A daemon can restart perfectly and still do nothing useful.

### 7.11 AVOID: install-success messages without doctor evidence

Evidence:
Jeff installers often emit human-friendly verification next steps.

Avoid:
Do not accept "installed service" as wired unless the doctor probe can rediscover it.
The flywheel failure class is silent drift after installation.

### 7.12 AVOID: dashboards as terminal consumers

Evidence:
The sibling orch-monitor audit found many observability primitives with no apply path.

Avoid:
A status line may be a consumer, but it cannot be the only consumer for an enforcement rule.
At least one operational decision point must consume the row.

## 8. External Pattern Survey

### 8.1 systemd WantedBy

Source:
https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html

Pattern:
systemd uses install-time dependency metadata such as `WantedBy` to express which target should pull in a unit.
The lesson is not "copy systemd."
The useful pattern is explicit activation linkage.
A unit file alone is not enough; install metadata determines whether it enters the boot graph.

Flywheel mapping:
A script file alone is not enough.
Artifact rows need `wired_into=<target>` where target can be launchd, doctor, hook, command, dispatch template, or tick gate.

### 8.2 Kubernetes readiness probes and OwnerReferences

Sources:
https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/

Pattern:
Readiness separates "process exists" from "ready to serve."
OwnerReferences separate object existence from lifecycle ownership.

Flywheel mapping:
`wired_into=launchd` proves process ownership only if paired with health proof.
`producer=<commit>` and `owner=<consumer>` should be separate fields.
A row can be owned but not ready.

### 8.3 Terraform depends_on

Source:
https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on

Pattern:
Terraform normally infers dependency order.
`depends_on` exists for relationships the graph cannot infer.

Flywheel mapping:
The gate can infer some artifact kinds.
Examples: `.plist` implies launchd verification; `.claude/hooks/*.sh` implies settings registration; `.claude/commands/*.md` implies slash command discoverability.
For ambiguous rows, require explicit `wired_into` or `deferred_until`.

### 8.4 npm lifecycle scripts and Cargo build scripts

Sources:
https://docs.npmjs.com/cli/using-npm/scripts
https://doc.rust-lang.org/cargo/reference/build-scripts.html

Pattern:
Package managers provide lifecycle hooks around install, build, test, and publish.
Cargo build scripts are build-time, not generic post-install services.

Flywheel mapping:
Use lifecycle-like hooks sparingly.
The safer local equivalent is a tick-close lifecycle check.
Do not hide long-running service registration inside a build or commit hook.

### 8.5 Erlang/OTP supervisor children

Sources:
https://www.erlang.org/doc/system/sup_princ.html
https://www.erlang.org/doc/apps/stdlib/supervisor.html

Pattern:
Supervisors have explicit child specs and restart strategies.
The tree is inspectable.

Flywheel mapping:
Watchers and recurring jobs should have explicit child rows.
A recurring script without a supervisor row is not a supervised component.

### 8.6 Nix flake checks

Sources:
https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-check
https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake

Pattern:
Flakes expose check outputs as a standard surface that tooling can discover.

Flywheel mapping:
`wire_or_explain status --json` should be a standard output.
Doctor and tick should not scrape prose.

### 8.7 Make .PHONY

Source:
https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html

Pattern:
`.PHONY` declares that a target is an action, not a file.
This prevents stale file names from short-circuiting execution.

Flywheel mapping:
Consumers must distinguish artifacts from actions.
A file path exists check is not enough for command, hook, and daemon wiring.

### 8.8 Bazel visibility

Source:
https://bazel.build/concepts/visibility

Pattern:
Bazel visibility controls what can depend on a target.
It makes dependency boundaries explicit.

Flywheel mapping:
The registry should record legal consumer classes for each artifact kind.
A runtime enforcement rule should not claim that a README section is a sufficient consumer.

## 9. Cross-Cutting Check: Idempotency

The gate must be idempotent on re-ship.
Same artifact path plus same content hash plus same producer commit should update/confirm the existing row, not append duplicates.
Same artifact path plus new content hash should create a new version row.
Same content hash with additional consumer should append a consumer edge.

Required key:
`artifact_id = sha256(repo_realpath + path + content_hash + artifact_kind)`

Required update behavior:
`register --apply` is upsert.
`resolve --wired-into` is upsert on edge key.
`defer --until` replaces only if the new deferral is earlier or explicitly forced.

Failure to avoid:
Repeated tick runs should not inflate `unwired_artifact_count_24h`.

## 10. Cross-Cutting Check: Atomicity

Multi-file ships need an atomic group id.
A doctrine rule plus script plus test should be treated as one ship group.
The group should fail if any required artifact row remains unresolved.

Required fields:
`ship_group_id`
`producer_commit`
`artifact_path`
`artifact_kind`
`content_hash`
`consumer_edges[]`
`status`
`created_ts`
`resolved_ts`

Implementation note:
Append rows to JSONL first, then write a compact status cache atomically with rename.
Do not make the cache the source of truth.

## 11. Cross-Cutting Check: Circular Wiring

The gate must prevent circular proof.
A script cannot prove itself wired by saying it is listed in its own README.
A doctor probe cannot prove itself if only the probe output says it is wired.
The consumer must be an independently discoverable surface.

Minimum rule:
`producer_path != consumer_path` unless the consumer type is a registry file with a separate discoverability command.

Example valid:
Script path -> launchd plist -> launchctl loaded state -> doctor field.

Example invalid:
Script path -> script help text -> "wired."

## 12. Cross-Cutting Check: Discoverability

Every consumer row needs a command that a worker can run.
This matches Jeff service-discovery patterns and Joshua's Socraticode-first doctrine.

Required field:
`discover_command`

Examples:
LaunchAgent: `launchctl list | rg <label>`
Doctor: `flywheel-loop doctor --repo <repo> --json | jq <field>`
Hook: `jq '.hooks' ~/.claude/settings.json | rg <hook>`
Slash command: `ls ~/.claude/commands/flywheel`
Agent Mail: MCP health or redacted wrapper command.

If there is no discoverability command, the row is unresolved.

## 13. Cross-Cutting Check: Shadow To Enforcing Ramp

Start with shadow mode.
Shadow mode writes rows and warnings.
It never blocks tick close.

Then warn mode.
Warn mode fails only if the artifact kind is critical and the row is older than the configured grace window.

Then enforce mode.
Enforce mode fails tick close when `unwired_artifact_count_24h > 0`.

Recommended default:
`WIRE_OR_EXPLAIN_MODE=shadow` for one day.
`WIRE_OR_EXPLAIN_MODE=warn` for the next day.
`WIRE_OR_EXPLAIN_MODE=fail` after false positives are beaded or explicitly exempted.

Kill switch:
`WIRE_OR_EXPLAIN_MODE=off` should be logged as an override row with reason.

## 14. CoralRaven Mapping

CoralRaven's `mission-anchor-dispatch-license.sh` is not orthogonal.
It is a special-case permit gate that should use the same wire/explain substrate.

Current failure:
The system has refusal substrate for mission drift.
It lacks a symmetric license artifact that can be consumed by dispatch.

Mapping:
`artifact_kind=permit_gate`
`artifact_path=~/.claude/hooks/mission-anchor-dispatch-license.sh`
`wired_into=mission-pretooluse-blocker or dispatch-template`
`consumer_type=dispatch_license`
`discover_command=rg -n 'mission_license|license' ~/.claude/hooks ~/.claude/commands/flywheel`

Decision:
Treat license-gate work as an exemplar row, not a separate architecture.
The general gate says any new permit/refuse gate must be wired into a decision point.
The license gate answers one high-value instance of that general rule.

## 15. Proposed Lane C Gate Shape

Add a small script:
`.flywheel/scripts/wire-or-explain.sh`

Modes:
`register`
`resolve`
`defer`
`status`
`doctor`
`scan`

Source of truth:
`.flywheel/wiring-ledger.jsonl`

Derived cache:
`.flywheel/state/wire-or-explain-status.json`

Register example:
`.flywheel/scripts/wire-or-explain.sh register --artifact .flywheel/scripts/foo.sh --kind script --producer-commit HEAD --ship-group-id <id> --verify-command '<cmd>'`

Resolve example:
`.flywheel/scripts/wire-or-explain.sh resolve --artifact .flywheel/scripts/foo.sh --wired-into flywheel-loop-doctor --consumer-type doctor --discover-command '<cmd>'`

Defer example:
`.flywheel/scripts/wire-or-explain.sh defer --artifact .flywheel/scripts/foo.sh --deferred-until bd-abc123 --reason 'needs cross-repo rollout bead'`

Status example:
`.flywheel/scripts/wire-or-explain.sh status --json`

Discoverability alias:
`flywheel-loop deps -v --json`

Reason:
The write helper can live as a small repo script, while the read surface should be a canonical `flywheel-loop` command.

Doctor integration:
`flywheel-loop doctor` consumes status JSON.
It emits `unwired_artifact_count_24h`.
It emits top five oldest and top five highest cost rows.
It emits metadata fields: producer, measurement, consumer, promotion_path.

Tick integration:
`.flywheel/flywheel-loop-tick` adds status JSON to pre-tick events.
Prompt prelude includes unresolved rows.
Tick close fails in enforce mode.

Dispatch template integration:
Workers must include `artifacts_registered=N`, `artifacts_resolved=N`, `artifacts_deferred=N`, and `artifacts_unresolved=N`.

Test integration:
Add a fixture that registers one unresolved artifact and proves doctor/tick fail in enforce mode.
Add a fixture that defers the row to a bead and proves pass with warning.
Add a fixture that resolves to a doctor consumer and proves pass.

## 16. Artifact Kind Defaults

`artifact_kind=script`
Likely consumers: doctor, launchd, command, hook, dispatch template, manual-only deferral.

`artifact_kind=launchd_plist`
Likely consumers: launchctl loaded state, driver_status, logs.

`artifact_kind=hook`
Likely consumers: `~/.claude/settings.json`, hook self-test, Codex fallback if relevant.

`artifact_kind=slash_command`
Likely consumers: command tree, dispatch template, smoke command.

`artifact_kind=l_rule`
Likely consumers: canonical meta-rule sync, doctor/runtime probe if rule claims enforcement.

`artifact_kind=doctor_probe`
Likely consumers: doctor JSON packet, tests, status line if user-facing.

`artifact_kind=status_line`
Likely consumers: status command and source probe.

`artifact_kind=bead_plan`
Likely consumers: bead DAG, br ready/dependencies, dispatch packet.

`artifact_kind=permit_gate`
Likely consumers: dispatch/pretool gate and audit ledger.

## 17. Failure Class Coverage

Silent script orphan:
Covered by register scan plus unresolved count.

Doctrine-only runtime claim:
Covered by `artifact_kind=l_rule` requiring runtime consumer when the title/status claims enforcement.

LaunchAgent marker-only:
Covered by `consumer_type=launchd` requiring launchctl loaded and tick evidence.

Hook-only Codex blind spot:
Covered by requiring non-hook consumer for Codex-relevant rules.

Dashboard-only observation:
Covered by forbidding status/dashboard as sole consumer for enforcement rules.

Deferred forever:
Covered by `deferred_until` requiring bead id or ISO timestamp.

Duplicate re-runs:
Covered by content hash upsert.

Circular self-proof:
Covered by consumer/proof separation.

## 18. Risks

Risk 1:
The scanner over-flags docs and scratch files.
Mitigation:
Only scan committed paths or explicit register calls at first.

Risk 2:
Workers bypass the script.
Mitigation:
Dispatch template and callback validator require artifact counts.

Risk 3:
Doctor becomes slow.
Mitigation:
Status cache is generated from append-only JSONL and checked cheaply.
Expensive consumer verification can be sampled or run on changed rows.

Risk 4:
Rows become another stale substrate.
Mitigation:
Tick fails on stale unresolved rows, and resolved rows require discoverability commands.

Risk 5:
Enforcement blocks useful emergency work.
Mitigation:
Shadow and warn phases first; override rows require a reason and are visible.

## 19. Recommended Minimal First Commit For Lane C

Create `.flywheel/scripts/wire-or-explain.sh`.
Support `register`, `resolve`, `defer`, and `status --json`.
Use JSONL append plus atomic cache write.
Do not wire git hooks in the first commit.

Add tests:
`tests/wire-or-explain.sh`
`tests/doctor-wire-or-explain.sh`

Patch `flywheel-loop doctor`:
Read status JSON.
Emit `unwired_artifact_count_24h`.
Emit oldest and highest-cost lists.

Patch `.flywheel/flywheel-loop-tick`:
Include status JSON in pre-tick prompt.
Fail only in shadow-disabled manner at first unless env says enforce.

Patch dispatch template:
Add artifact registration block and callback fields.

## 20. Three-Judge Readiness

Judge 1: Did this identify existing consumers?
Yes.
The audit covers tick, doctor, launchd, meta-rule sync, hooks, dispatch template, repo tick shell, git hooks, cron, and Agent Mail.

Judge 2: Did this separate observation from enforcement?
Yes.
The report repeatedly treats dashboards and status lines as insufficient terminal consumers.

Judge 3: Did this provide an implementable mechanism?
Yes.
The proposed script, JSONL ledger, cache, doctor integration, tick integration, and callback fields are concrete.

Remaining weakness:
The final convergence section still needs the parallel Lane B comparison.

## 21. Independent Conclusions Before Reading Parallel Lane B

Conclusion A:
The repo has enough primitives.
The missing primitive is a universal ship row and tick-close reader.

Conclusion B:
The best first enforcement point is doctor plus tick, not git hooks.

Conclusion C:
Artifact registration should be separate from consumer verification.

Conclusion D:
CoralRaven's mission license gate should be treated as a high-value artifact kind in the same substrate.

Conclusion E:
The implementation should start in shadow mode and become enforcing after one or two cycles of false-positive cleanup.

## 22. Convergence With Sub-Agent Lane B

Parallel Lane B read after this independent draft was written:
`.flywheel/PLANS/wire-or-explain-tick-gate-2026-05-04/01-RESEARCH-B.md`

Agreement level:
high.

Shared top finding:
Both audits identify the same asymmetry.
The substrate has many consumer-side mechanisms and no universal ship-side ledger.
Both reports use nearly the same phrase in substance: rich consumers, zero ship ledger.

Consumer inventory overlap:
Both reports cover tick, doctor, LaunchAgents, canonical meta-rule sync, hooks, dispatch template, repo-local flywheel-loop-tick, git hooks, cron, and Agent Mail.
The parallel artifact adds two useful mechanisms I did not count in my required-ten inventory:
`.flywheel/loop.json` / `.flywheel/STATE.md` sentinels.
`.flywheel/dispatch-log.jsonl` as the existing incomplete event ledger.

Actionable merge:
Lane C should include dispatch-log as an explicit consumer/source-adjacent ledger.
It should add `event:"artifact_shipped"` or equivalent, because that is the missing row class both audits identify.

Jeff pattern overlap:
Both audits adopt idempotent registration, discoverability commands, graph hygiene, and graduated enforcement.
The parallel report found a stronger local Jeff pattern than my first pass:
`ntm deps -v` plus Kahn topological sort.

Actionable merge:
Keep my proposed `.flywheel/scripts/wire-or-explain.sh` as the writer/helper.
Expose the canonical read surface as `flywheel-loop deps -v --json` and/or `flywheel-loop wiring-ledger --json`.
Use topological sort for cycle and orphan-chain diagnostics.

External pattern overlap:
Both audits surveyed the required eight:
systemd, Kubernetes, Terraform, npm/cargo, Erlang/OTP, Nix, Make, and Bazel.
The conclusions align on explicit dependency arcs, discoverability, readiness distinct from existence, and shadow/dry-run ergonomics.

Gate shape agreement:
Both reports recommend JSONL ledger rows.
Both require content hash or equivalent revision identity.
Both require `deferred_until`.
Both require a discoverability command.
Both recommend shadow -> warn -> enforce.
Both reject static analyzer only behavior.

Naming/location difference:
I proposed `.flywheel/state/wire-or-explain.jsonl` initially.
The parallel report proposes `.flywheel/wiring-ledger.jsonl`.
I now prefer `.flywheel/wiring-ledger.jsonl` for the source of truth because it mirrors `.flywheel/dispatch-log.jsonl` and is easier to discover.
The `.flywheel/state/` path remains appropriate for derived cache only.

Atomicity difference:
Both reports agree on per-file rows plus bundle awareness.
The parallel artifact calls this `bundle_id:<plan-id>`.
My report calls it `ship_group_id`.
Lane C should pick one field name.
Recommendation: use `bundle_id` for graph compatibility and add `plan_slug` separately when available.

CoralRaven agreement:
Both reports classify `mission-anchor-dispatch-license.sh` as a special case of the general wire/explain primitive, not an orthogonal plan.
Both connect it to the refuse-vs-permit asymmetry from the ALPS Vercel reports.

Differences worth preserving:
The parallel report's discoverability-gap count is sharper: 12 mechanisms, only a minority self-list cleanly.
My report's consumer inventory gives more concrete local line references for existing doctor/tick/shared-surface rows.
The combined Lane C design should use both: the parallel graph model plus my concrete integration points.

Final convergence verdict:
high agreement.
No blocking contradiction found.
The useful synthesis is:
append-only `.flywheel/wiring-ledger.jsonl`;
writer helper `.flywheel/scripts/wire-or-explain.sh`;
canonical query `flywheel-loop deps -v --json`;
doctor/tick enforcement of `unwired_artifact_count_24h`;
dispatch-template callback fields for artifact registration;
shadow-first enforcement.

## 23. Callback Metrics Draft

mechanisms_audited=10
jeff_patterns_adopted=8
evaluated=6
avoided=4
socraticode_queries=6
indexed_chunks_observed=198092
self_grade=Y
agreement_with_subagent=high
