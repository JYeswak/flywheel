# Lane B — Ecosystem Audit + Jeff/Upstream Patterns

**Plan:** wire-or-explain-tick-gate-2026-05-04
**Lane:** B (ecosystem mechanism inventory + Jeff/external patterns)
**Mode:** READ-ONLY, full multi-round under `/jeff-convergence-audit`
**Operator:** flywheel:1 background sub-agent
**Skills applied:** donella-meadows-systems-thinking, dicklesworthstone-stack, gate-truth-separation, observability-platform, socraticode, jeff-convergence-audit, canonical-cli-scoping
**Date:** 2026-05-04

---

## 1. Executive summary

Lane B's mandate is to enumerate every existing wiring mechanism that *could* consume a freshly-shipped artifact, document how to register an artifact with each one, characterize the failure mode if registration is malformed or missing, and decide which Jeff/upstream patterns we should adopt for the wire-or-explain gate.

**Top findings:**

1. **The flywheel substrate already has rich consumer-side machinery — and zero ship-side ledger.** There are at least 11 first-class consumer mechanisms (`flywheel-loop tick`, the 1,324-line tick-step list at `/Users/josh/Developer/flywheel/.flywheel/flywheel-loop-tick`, 39 launchd plists, 14 PreToolUse hooks, the canonical META-RULE three-surface sync at `/Users/josh/.flywheel/canonical-meta-rules/sync.sh`, the dispatch template gate, the orch-worker identity manifest, agent-mail registration, the codex-watchtower probe, the doctor probe set, the dispatch-log.jsonl, the `validation_fix_bead_plan` reaper). There is **no ledger that emits a row when an artifact is shipped** to be matched against these consumers. This is the asymmetry the gate must close.
2. **Discoverability is single-digit-percent.** Of the 11 mechanisms surveyed, **only 2** answer "what's currently wired into me?" with a single CLI: `launchctl list | grep ai.zeststream` and `crontab -l`. The other 9 require source-grep. This is the precondition for orphan-detection: you cannot detect orphans against a substrate that doesn't list its consumed inputs.
3. **The Jeff substrate has the canonical pattern already — `ntm deps -v` + `internal/pipeline/deps.go` Kahn topological sort.** Adopt this directly: every shipped artifact declares `consumed_by:[<mechanism>]`; the gate runs Kahn over the manifest at tick close and flags every node with in-degree 0 in the consumer graph.
4. **CoralRaven's `mission-anchor-dispatch-license.sh` proposal is a *special case* of wire-or-explain, not orthogonal.** "Mission-aligned dispatch" is one of the artifact classes that the gate must check for wiredness. The gate generalizes; the license-substrate is the first concrete consumer.
5. **The substrate is wired to refuse, not to permit** (CoralRaven §3, lines 75–79). The same observation applies fleet-wide: hooks block bad behavior; nothing emits a "did this thing get used?" signal. **Wire-or-explain is the symmetric permit-side instrumentation.**
6. **Shadow-mode-first is non-negotiable.** With 39 plists, 14 hooks, 136 scripts, 1,205 dispatch-log rows accumulated — flipping straight to enforcing-mode will block legitimate ticks on unwired-historical artifacts. Phase the gate via `gate_mode={shadow,warn,enforce}` with auto-promote conditions.

**Cross-cutting agreement candidates** (for Lane A/C convergence):
- Every wired-in-mechanism check must produce a JSON probe row (`{mechanism, artifact, status:wired|deferred|orphan, evidence:<file:line>}`) — matches the doctor probe pattern at `flywheel-loop-tick:309-321`.
- A canonical "discoverability command" per mechanism is required as part of registration (this is the orphan-detector primitive).
- Registration is structurally identical to Jeff's `register_agent` pattern (see ntm `AGENTS.md:368`): self-declared at ship-time, idempotent, surfaced via `<mechanism> deps` query.

---

## 2. Mechanism inventory (consumer-side)

### M1 — `flywheel-loop tick` driver (per-repo loop entry point)

```yaml
mechanism: flywheel-loop tick
file_path: /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop  (9,567 lines; doctor at line 7811; tick orchestration via run_probe_json line 295, tick_class_for_phase line 395)
consumes_classes: [doctor_probe, tick_step_script, phase_handler, doctrine_promotion]
registration_point: tick steps registered as standalone scripts called from /Users/josh/Developer/flywheel/.flywheel/flywheel-loop-tick (1,324 lines); each step appended as inline `<NAME>_RESULT="$(... 2>&1 || ...)"` block + JSONL log row
discoverability_command: NONE (must grep `_RESULT=` in flywheel-loop-tick) — DISCOVERABILITY GAP #1
failure_mode_if_misregistered: silent — `|| printf '{"action":"error"}'` swallow keeps tick green; misregistered probe just reports `action:error` and tick continues
example_already_wired: codex_watchtower_probe at flywheel-loop-tick:106-150 (probes codex-watchtower-daily.sh + codex-tracker-probe.sh + frozen-pane-detector.sh, emits CODEX_WATCHTOWER_RESULT to dispatch-log)
example_should_be_wired_but_isnt: peer-orch-productivity-watch.sh — exists at .flywheel/scripts/, has --apply mode, NO call site in flywheel-loop-tick (per intent §6.1)
```

### M2 — `flywheel-loop doctor` probe

```yaml
mechanism: flywheel-loop doctor (--strict)
file_path: /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop  (def doctor() at line 7811; called from line 8023; bash entry at doctor_strict_command line 984)
consumes_classes: [doctor_field, doctor_probe_script, schema_postcheck]
registration_point: doctor_schema_postcheck() at line 5216; new fields added by appending probe call to doctor() body + emitting JSON key in stdout payload
discoverability_command: `flywheel-loop doctor --strict --repo <path> --json | jq 'keys'` (lists currently-emitted fields, but NOT which probes contribute them)
failure_mode_if_misregistered: schema_postcheck warns; field appears as `null` or absent; downstream consumers (flywheel-loop-tick promotion logic) silently skip
example_already_wired: doctor_ntm_health_json at line 5125 (emits ntm-side fields); fleet_three_surface_drift_* fields from canonical-meta-rules/sync.sh fleet mode
example_should_be_wired_but_isnt: fleet_conformance_min_score (per intent §6.2) — value emitted by fleet-conformance-probe.sh but no doctor consumer reads it for promotion or alert
```

### M3 — launchd LaunchAgents (`~/Library/LaunchAgents/ai.zeststream.*.plist`)

```yaml
mechanism: launchd
file_path: /Users/josh/Library/LaunchAgents/ai.zeststream.*.plist (39 plists present; observed via `ls`)
consumes_classes: [scheduled_script, recurring_probe]
registration_point: drop a new ai.zeststream.<name>.plist; `launchctl load -w <plist>`
discoverability_command: `launchctl list | grep ai.zeststream` (returns 30 loaded jobs at probe time; clean primitive — closest to a real wiring registry today)
failure_mode_if_misregistered: plist syntax error → load fails silently; bad ProgramArguments → job stays in `-` state; wrong StartInterval → never fires
example_already_wired: ai.zeststream.flywheel-flywheel-loop (drives the per-repo tick); ai.zeststream.canonical-meta-rules-sync-watchdog (drives sync.sh)
example_should_be_wired_but_isnt: peer-orch-productivity-watch.sh — no plist invokes it (intent §6.1); fleet-process-gap-detector.sh — runs ad-hoc, no plist
```

### M4 — `~/.flywheel/canonical-meta-rules/sync.sh` (META-RULE three-surface distributor)

```yaml
mechanism: canonical META-RULE three-surface sync
file_path: /Users/josh/.flywheel/canonical-meta-rules/sync.sh (385 lines; three_surface_sync at line 57; fleet mode at line 209)
consumes_classes: [meta_rule_block (L<NN> doctrine), feedback_*.md memory file]
registration_point: drop `feedback_<topic>.md` into /Users/josh/.flywheel/canonical-meta-rules/; sync bundle picked up at sync.sh:342 `for f in "$CANONICAL_DIR"/feedback_*.md`
discoverability_command: `bash sync.sh --check-three-surface --target <repo> --json | jq '.surface_rule_counts, .missing_in_agents_md'` (clean; reports drift)
failure_mode_if_misregistered: drift detected, status=`drift`, exit 1; gate at flywheel-loop-tick fails the surface check
example_already_wired: L101–L108 META-RULES live in canonical AGENTS.md → mirrored by sync.sh into per-repo AGENTS.md + .flywheel/AGENTS-CANONICAL.md + templates/flywheel-install/AGENTS.md
example_should_be_wired_but_isnt: per intent §6.6 — L101–L108 have no *runtime enforcer*. The doctrine is propagated by sync.sh but no tick handler ACTS on the rule (e.g. L102 might say "every dispatch must include josh_request_id" — sync.sh ensures the rule exists in three surfaces, but only the dispatch-template gate enforces it at runtime, and only for that one rule)
```

### M5 — `~/.claude/hooks/` (Claude Code PreToolUse / SessionStart / Stop / PreCompact)

```yaml
mechanism: claude code hooks
file_path: /Users/josh/.claude/settings.json (hooks block at line 106; ~14 PreToolUse matchers, several Read/Write/Bash/Skill matchers); hook scripts at /Users/josh/.claude/hooks/ (~50 .sh files)
consumes_classes: [pretool_gate, posttool_capture, prompt_injector, compact_handler]
registration_point: edit settings.json hooks[] array; add `{matcher,hooks:[{type:command,command:<path>,timeout:N}]}` block
discoverability_command: `jq '.hooks | keys[] as $event | "\($event): \(.[$event] | length) groups"' ~/.claude/settings.json` (partial; doesn't tell you which hook fires for which tool)
failure_mode_if_misregistered: timeout exceeded → tool blocked or warned; bad path → hook silently skipped on most CC versions; bad jq in hook stdin parse → empty result, hook permits
example_already_wired: flywheel-loop-readiness-gate.sh wired into Write|Edit|MultiEdit|Bash|Agent|Task at settings.json:118-127; flywheel-loop-dispatch-transport-gate.sh wired into Bash at settings.json:128-137; mission-pretooluse-blocker.sh wired at settings.json:213-220
example_should_be_wired_but_isnt: any artifact-shipping hook itself — there is no PreToolUse|PostToolUse hook that emits a "ship-event" row when a new script is written into .flywheel/scripts/, .flywheel/AGENTS-CANONICAL.md, or ~/.claude/skills/.flywheel/bin/. The substrate is blind to its own ship-events.
```

### M6 — `~/.claude/commands/flywheel/_shared/dispatch-template.md` (dispatch boilerplate)

```yaml
mechanism: dispatch template
file_path: /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md (414 lines)
consumes_classes: [dispatch_constraint, callback_contract_field, identity_block]
registration_point: append section to dispatch-template.md; dispatch-template-using callers (`/flywheel:dispatch`, /fw-dispatch) re-read on each invocation
discoverability_command: NONE — dispatch-template.md is a prose file; constraints not enumerated structurally  — DISCOVERABILITY GAP #2
failure_mode_if_misregistered: silent — workers ignore unknown constraints; callback validator (callback_validation_reaper_gate at flywheel-loop-tick:1001) only checks specific named fields (josh_request_id, callback_delivery_verified)
example_already_wired: JOSH REQUEST LINKAGE BLOCK (template:38-54) — every dispatch enforces josh_request_id; LOCKED WORKER IDENTITY BLOCK (template:55-112) — every dispatch checks orch-worker-identity manifest
example_should_be_wired_but_isnt: any of the L101–L108 rules that should constrain dispatch (per intent §6.6) — they live in feedback_*.md, sync.sh propagates them as text, but dispatch-template doesn't reference them and callback-validator doesn't probe for them
```

### M7 — `.flywheel/flywheel-loop-tick` (the tick step list — CONSUMER PRIMARY)

```yaml
mechanism: flywheel-loop-tick step orchestrator
file_path: /Users/josh/Developer/flywheel/.flywheel/flywheel-loop-tick (1,324 lines; `_RESULT=` step pattern from line ~107 onward; JSONL emission to .flywheel/dispatch-log.jsonl)
consumes_classes: [probe_script, json_probe, doctor_signal_promotion, validation_gate, fix_bead_planner]
registration_point: append `<NAME>_RESULT="$(run_probe_json <script> <args>)"` block + matching `jq -nc ... >>"$LOG"` row + insertion into prompt prelude (lines 1059-1115)
discoverability_command: NONE — must grep `_RESULT=` (≈40 distinct steps observed)  — DISCOVERABILITY GAP #3 (the most consequential)
failure_mode_if_misregistered: probe failure swallowed by `2>&1 || printf '{"action":"error"}'` (line 110, 309, 313, etc.); tick continues; orphaned probe never gets called
example_already_wired: codex_watchtower_probe (lines 106-150); doctor_signal_bead_promotion (line 814); callback_validation_reaper_gate (line 1001); validation_fix_bead_plan (line 1009)
example_should_be_wired_but_isnt: fleet-comms-health-probe.sh, fleet-conformance-probe.sh, fleet-observatory-aggregate.sh — all live in .flywheel/scripts/ and report doctor fields, none called from flywheel-loop-tick (per intent §6.2-§6.5)
```

### M8 — pre-commit / post-commit git hooks (per-repo)

```yaml
mechanism: git hooks
file_path: <repo>/.git/hooks/pre-commit, post-commit  (NB: not version-controlled by default)
consumes_classes: [commit_gate, post_commit_publisher]
registration_point: write executable file into .git/hooks/ — install pattern via `flywheel-install-hooks` in /Users/josh/.claude/skills/.flywheel/bin/
discoverability_command: `ls -la .git/hooks/` per repo (filesystem-truth only)
failure_mode_if_misregistered: silent skip if non-executable; commit blocked if exit≠0
example_already_wired: dcg pre-commit globally; mcp_agent_mail tests assert `precommit_script_contains_gate_and_mode` (test_guard_render.py:13)
example_should_be_wired_but_isnt: no commit hook fires the wire-or-explain ledger row when a new artifact is added — git-side is blind
```

### M9 — cron (`crontab -l`)

```yaml
mechanism: cron
file_path: user crontab
consumes_classes: [scheduled_command]
registration_point: `crontab -e`
discoverability_command: `crontab -l` (clean)
failure_mode_if_misregistered: bad path → mailed error; missing PATH → silent fail
example_already_wired: ks-daily-intelligence (06:00); check-ingestion-success.sh (07:00); ubs --update (00:00); backup-to-s3.sh (05:00); disk-watchdog.sh (every 30m)
example_should_be_wired_but_isnt: cron is mostly NOT used for fleet substrate — launchd is the canonical scheduler. Every flywheel script that ended up in cron rather than launchd is itself a wiring drift. Gate could detect this.
```

### M10 — `.flywheel/loop.json` + `.flywheel/STATE.md` sentinels

```yaml
mechanism: per-repo loop sentinel + state
file_path: <repo>/.flywheel/loop.json (gates readiness); <repo>/.flywheel/STATE.md (latest snapshot)
consumes_classes: [loop_opt_in_flag, repo_state_summary]
registration_point: write loop.json + MISSION.md/GOAL.md/STATE.md (readiness-gate.sh requires all)
discoverability_command: `find ~/Developer -maxdepth 3 -name loop.json` (filesystem); flywheel-loop-readiness-gate.sh at lines 26-34 checks signal
failure_mode_if_misregistered: dispatches/edits BLOCKED in any repo with .flywheel/ but missing loop.json — see flywheel-loop-readiness-gate.sh (this IS a refuse-gate; the wire-or-explain symmetric permit-gate doesn't exist)
example_already_wired: sentinel governs hook gate behavior fleet-wide
example_should_be_wired_but_isnt: loop.json doesn't carry a `consumed_artifacts:[]` list — perfect place to declare wiring on a per-repo basis
```

### M11 — Agent Mail MCP (`mcp_agent_mail`) + orch-worker identity manifest

```yaml
mechanism: agent-mail registry + orch-worker identity manifest
file_path: ~/.local/state/flywheel/orch-worker-identity/<session>.json (manifest); ~/.local/share/mcp_agent_mail (service); registration via /Users/josh/Developer/flywheel/.flywheel/scripts/agentmail-registration-broadcast.sh
consumes_classes: [agent_identity, fleet_mail_token, dispatch_routing_rule]
registration_point: orch-worker-identity-manifest.sh --apply (refreshes manifest); agent-mail register_agent MCP tool
discoverability_command: `jq '.workers[] | {pane,fleet_mail_identity,registration_status}' <manifest>` (clean per-session); `jeff-corpus mcp_agent_mail` `register_agent` (per ntm AGENTS.md:368)
failure_mode_if_misregistered: dispatch BLOCKED at dispatch-template.md:73-93 if registration_status != "active"; broadcast triggered + 30s wait + reprobe; if still inactive returns BLOCKED with blocker_class=fleet-mail-registration-downtime
example_already_wired: every orch worker pane carries identity — picoz=PicozWorker*, alps=AlpsWorker*, etc.
example_should_be_wired_but_isnt: skill-shipped agents (e.g. /flywheel:fleet-observatory) have no agent-mail identity — they exist only as slash commands; could be a class for the gate to flag (or correctly classify as out-of-scope, per Lane A taxonomy)
```

### M12 — `.flywheel/dispatch-log.jsonl` (the existing event ledger — INCOMPLETE)

```yaml
mechanism: dispatch-log.jsonl (1,205 rows at probe time)
file_path: /Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl
consumes_classes: [tick_event, probe_result, validation_outcome, fix_bead_creation]
registration_point: any tick step that emits a `jq -nc ... >>"$LOG"` row gets recorded
discoverability_command: `tail -n 100 .flywheel/dispatch-log.jsonl | jq -r '.event' | sort -u` (clean — lists distinct event types)
failure_mode_if_misregistered: row not appended → invisible; consumer (validation reaper) sees nothing
example_already_wired: l70_chain_decision (line 1037), value_gap_probe (line 1049), callback_validation_reaper_gate (line 1005), validation_fix_bead_plan (line 1013), agent_mail_fd_doctor (line 858), daily_jeff_ingest_doctor (line 882), fleet_onboard_doctor (line 898)
example_should_be_wired_but_isnt: there is no `event:"artifact_shipped"` row class today. ZERO ship-side events. This is exactly where wire-or-explain lives.
```

**Inventory total: 12 first-class consumer mechanisms. Of those, 3 have clean discoverability commands (launchctl, crontab, sync.sh --check); 4 have partial (manifest jq, doctor --json, dispatch-log tail, jq settings.json); 5 have NONE (require source-grep). Three of the five gaps are the load-bearing ones (M1, M6, M7).**

---

## 3. Jeff / upstream patterns (ADOPT / EXTEND / AVOID)

### J1 — `ntm deps -v` + topological-sort dependency graph

**Source:** /Users/josh/Developer/ntm/internal/pipeline/deps.go:197-260 (Kahn topological sort with level tracking); /Users/josh/Developer/ntm/internal/cli/deps.go:41 (CLI exposure); ntm README.md:70,82 ("Sanity check everything with `ntm deps -v`"); CHANGELOG.md:308 ("JeffreysPrompts and MetaSkill command registrations")

**Verdict: ADOPT (canonical pattern).**

The wire-or-explain gate IS a topological sort over (artifacts, consumers). Every artifact declares `consumed_by:[<mechanism>]`. Gate runs Kahn at tick close. Nodes with in-degree 0 in the consumer graph (i.e. no consumer references them) = orphans. The Jeff implementation already gives us the algorithm, deterministic ordering, level tracking, and a CLI shape (`<tool> deps -v` / `--json`) that's familiar fleet-wide.

Concrete adoption: `flywheel-loop deps -v --json` returns `{artifacts:[{path,class,consumed_by,wired:bool,deferred_until,evidence:<file:line>}], orphans:[<paths>], cycles:[]}`. Mirrors deps.go:212-260 line-for-line.

### J2 — `ntm` agent registration via `register_agent` (idempotent self-declaration)

**Source:** ntm AGENTS.md:368 (`register_agent(project_key, program, model)`); :421 ("Use granular tools for control"); :425 ("`from_agent not registered`: Always `register_agent` in the correct `project_key` first"); /Users/josh/Developer/ntm/internal/cli/setup_test.go:203 (clears registered_at when unregistered).

**Verdict: ADOPT (registration shape).**

Every shipped artifact registers itself to its consumer at ship-time, idempotently. Pattern: `flywheel-loop register-artifact --path <p> --class <c> --consumed-by <m>` writes a row to `.flywheel/wiring-ledger.jsonl`. Idempotent re-registration updates the row. Unregistration mirrors ntm's `clears registered_at` (setup_test.go:203). The `from_agent not registered` ergonomic from ntm gives us the canonical error message: `artifact not registered with consumer mechanism <m>`.

### J3 — `ntm` webhook manager (Register/Unregister + dispatch lifecycle)

**Source:** /Users/josh/Developer/ntm/internal/webhook/manager.go:292 (`func Unregister`); manager_test.go:124-138.

**Verdict: EXTEND (lifecycle shape; not the implementation).**

We don't need webhooks. We do need the lifecycle pair: register → active → unregister/decommission. Every wired artifact carries one of `{active,deferred,decommissioned}`. The decommission path matters: shipped artifacts that the substrate intentionally retires must be marked decommissioned, not orphaned. Without this, normal cleanup churns the gate.

### J4 — `bv` graph triage primitives (`bv --robot-suggest`, `bv --robot-insights | jq '.Cycles'`)

**Source:** ntm AGENTS.md:548 (`--robot-suggest`: "Hygiene: duplicates, missing deps, label suggestions"); AGENTS.md:581 (`bv --robot-insights | jq '.Cycles'  # Circular deps (must fix!)`)

**Verdict: ADOPT.**

`bv` already does graph hygiene over beads with the exact ergonomic we want for artifacts. The wire-or-explain gate output is structurally identical to `bv --robot-insights` output: cycles, missing-deps, hygiene class. Adopt the JSON shape and the `must fix!` severity convention.

### J5 — `mcp_agent_mail` precommit-script-contains-gate-and-mode test pattern

**Source:** /Users/josh/Developer/mcp_agent_mail/tests/test_guard_render.py:13 (`def test_precommit_script_contains_gate_and_mode`); :20 (prepush variant).

**Verdict: ADOPT (testing pattern for the gate itself).**

The wire-or-explain gate's own tests must follow this shape: `test_tick_close_contains_wire_or_explain_gate`, `test_gate_emits_orphan_count_field`, `test_shadow_mode_does_not_block`. mcp_agent_mail proves Jeff already has the canonical "guard rendered correctly" test pattern; the gate inherits it directly.

### J6 — `swarm-operator-loop` / `cubcode` / `dcg` / `frankenagent-detection`

**Status: NOT FOUND in /Users/josh/Developer top-level.** Only found `/Users/josh/Developer/local-agents/cubcode`. dcg, swarm-operator-loop, frankenagent-detection not under ~/Developer/. Lane B reports this as a substrate-breadth gap; the wire-or-explain gate research can proceed without them since J1+J2+J4 give us the canonical pattern, but follow-up should mine these via socraticode index when access restored. **EVALUATED, deferred.**

### J7 — `beads_rust` validation::no_hook_execution doctrine

**Source:** /Users/josh/Developer/beads_rust/src/validation/mod.rs:314 ("**No hook execution**: No git hooks are installed or triggered"); :774 (test).

**Verdict: AVOID (anti-pattern for *our* gate).**

beads_rust deliberately does *not* execute hooks during validation — it's a pure analyzer. Our gate must do the opposite: it MUST run at tick-close with executable consequences. We note this as a contrast: the wire-or-explain gate is a *tick* gate, not a *validation* gate. Different leverage point (Meadows #4 self-organization vs. #5 rules).

### J8 — `frankensqlite` (referenced in user memory but not directly mineable for this lane)

**Verdict: DEFER.** Memory references frankensqlite#85 as filed upstream; not relevant to wiring inventory.

**ADOPT count: 4 (J1, J2, J4, J5). EXTEND count: 1 (J3). AVOID count: 1 (J7). DEFER/eval-incomplete: 2 (J6, J8).**

---

## 4. External pattern survey (≤150 words each)

### E1 — systemd `WantedBy` / `Requires=` / socket activation

`WantedBy=` declares "I want to be started when target X is started" — this is exactly the wire-or-explain registration shape inverted (consumer declares intent, not artifact). `Requires=` is the dependency arc; failure cascades. Socket activation is the lazy permit-gate (don't start the consumer until something is asking for it). **Analogue for our gate:** every shipped artifact's `consumed_by:[<mechanism>]` field IS a `WantedBy=` declaration; the mechanism IS the systemd target. `systemctl list-dependencies <unit>` is the discoverability primitive — fleet equivalent: `flywheel-loop deps <mechanism>` lists registered artifacts. **Adopt:** the `WantedBy` shape (artifact declares its consumer); avoid systemd's complexity.

### E2 — Kubernetes `ownerReferences` + readiness probe + `kubectl rollout status`

`ownerReferences` is a parent-child wiring graph; orphan detection is built-in (`kubectl get pods --field-selector=status.phase=Failed`). Readiness probes are the runtime "is this thing actually being used?" loop. `kubectl rollout status --timeout=10m` is shadow-mode → enforce ramp. **Analogue:** `consumed_by` = ownerReferences; the gate's status field = readiness; rollout-status = our ramp from `gate_mode=shadow` to `gate_mode=enforce`. **Adopt:** the rollout-status state machine for our shadow→warn→enforce transition.

### E3 — Terraform `depends_on` + apply-time validation

Terraform graph is declared explicitly (`depends_on=[aws_instance.x]`), validated at plan-time, executed in topological order at apply-time. Drift detection (`terraform plan` with no changes shows ≠ 0 changes = drift). **Analogue:** wire-or-explain ledger == terraform state; orphan = "in code, not in state"; unwired-but-shipped = "in state, not in code". **Adopt:** the plan/apply asymmetry — `flywheel-loop deps --plan` shows what would be wired; `--apply` writes the ledger.

### E4 — npm/cargo post-install hooks + lockfile drift

`postinstall` runs after dep resolution; package-lock.json/Cargo.lock pins what was actually installed; drift detection is `npm ci --dry-run`. **Analogue:** lockfile = wiring-ledger.jsonl. **Adopt:** the lockfile-as-source-of-truth pattern. **Avoid:** npm-style arbitrary post-install code execution — too unbounded for our gate.

### E5 — Erlang/OTP supervisor children list

OTP supervisors declare children explicitly: `init/1 -> {ok, {SupFlags, [ChildSpec1, ChildSpec2, ...]}}`. Adding a child requires editing the supervisor module; orphans are impossible by construction. **Analogue:** the closest model to "gate is impossible to orphan past" — every consumer mechanism declares its children, period. **Adopt:** the children-list-as-canonical-source pattern; this is M1/M7's missing primitive (a children list at the top of flywheel-loop-tick).

### E6 — Nix `outputs.checks`

Every flake declares `outputs.checks = { tickGate = ...; }`; `nix flake check` runs all checks; an unwired check is impossible because nothing references it. **Analogue:** `flywheel-loop check` runs every registered consumer-side check; ledger = `outputs`. **Adopt:** the "single command runs every wiring check" ergonomic.

### E7 — Make `.PHONY` + dependency declaration

Targets declare deps (`tick: doctor probes ledger`); `make -n tick` shows what would run. **Analogue:** the simplest possible gate. **Adopt:** the `--dry-run` ergonomic for shadow mode.

### E8 — Bazel BUILD + visibility rules

Every target declares `visibility = ["//some:__pkg__"]`; orphan targets fail `bazel query 'rdeps(//..., //orphan)'` empty. **Analogue:** rdeps query = "who consumes me?" probe. **Adopt:** the rdeps query shape as the discoverability primitive.

---

## 5. Cross-cutting concerns

### C1 — Idempotency

**Question:** re-shipping the same artifact (e.g., probe revision) — does it re-register or skip?
**Answer:** Re-register, with `revision_history:[]` carried inline. Pattern from J2 (ntm `register_agent` is idempotent). Ship event keys on `(artifact_path, content_sha)`. New sha → new ledger row with `supersedes:<prior_row_id>`. Same sha → skip. Critical because hot-fix iteration on a probe shouldn't churn the ledger.

### C2 — Atomicity

**Question:** if shipping involves N files (script + doctor field + L-rule + test), are they wired all-or-nothing or per-file?
**Answer:** **Per-file with bundle awareness.** Each file is its own ledger row (gate granularity = file). But ship events can declare `bundle_id:<plan-id>` so a plan can be reasoned about as a unit. The gate flags partial-wiring at the bundle level: "bundle X has 4 artifacts, 2 wired, 2 orphan — block tick close until resolved." Avoids the "all or nothing" failure where one missing test blocks shipping the script-and-doctor-field that was the actual leverage.

### C3 — Circular wiring

**Question:** artifact A consumes B's output; B is unwired. Does the gate flag B only, or A as well?
**Answer:** Flag both, with chained-orphan severity. Pattern: `bv --robot-insights | jq '.Cycles'` (J4) — Jeff already returns chains. The gate's output mirrors: `{primary_orphan:B, downstream_orphans:[A,C,...], chain_depth:3}`. This is also where Kahn (J1) gives us a free check: if topological sort fails (cycle detected), the cycle members are returned together.

### C4 — Discoverability for orphan-detection

**Question:** can we run a single command that lists every artifact and its wiring state today?
**Answer:** **NO, today.** This is the load-bearing precondition for the gate. The gate's first deliverable is therefore: `flywheel-loop wiring-ledger --json` returns the union of all currently-wired artifacts AND all orphans — populated by walking each mechanism's discoverability command (M3 launchctl, M4 sync.sh --check, M5 jq settings.json, M9 crontab, etc.) and cross-referencing the ship-side ledger. The 5 gaps in §2 (M1, M6, M7, M8, M11) need their *own* discoverability commands written as part of gate construction.

### C5 — Shadow-mode → enforcing-mode ramp

**Question:** how do we ramp without false-positive blocking?
**Answer:** Three-stage ramp keyed on `gate_mode` field in `.flywheel/loop.json`:
1. `gate_mode=shadow` (first 7 days): gate runs, emits `unwired_artifact_count_24h` field, never blocks tick. Joshua-readable daily-report row.
2. `gate_mode=warn` (next 7 days): gate prefixes tick prompt with WARNING block listing top-N orphans; tick still proceeds. Worker prompts include the warning so workers fix opportunistically.
3. `gate_mode=enforce` (after): tick FAILS at close if `unwired_artifact_count_24h > 0` AND every unwired artifact lacks `deferred_until` justification. JOSHUA_OVERRIDE=<reason> escape (matches the existing flywheel-loop-readiness-gate.sh pattern at lines 18-23).

Auto-promote condition: shadow→warn when 7d window has <5 false-positive deferrals; warn→enforce when 7d window has 0 unjustified orphans. Reverse: any tick that would have failed in enforce-mode under warn-mode logs `would_have_failed` row → operator runs `flywheel-loop wiring-ledger --explain <artifact>`.

---

## 6. CoralRaven convergence mapping

CoralRaven's report at /Users/josh/Developer/alpsinsurance/.flywheel/reports/2026-05-04-vercel-blocker-deep-dive.md is structurally the same finding as this plan. Direct citations:

**§3 (lines 75–79) — the asymmetry observation:**

> "Currently the substrate has #6 partially: `mission-anchor-dispatch-preflight.sh` blocks dispatch when MISSION.md is **unfilled**. There is no symmetric **enabling** path that says 'MISSION.md is filled and explicitly authorizes this; proceed.'
>
> This is the asymmetry: **the substrate is wired to refuse, not to permit.**"

**§4 (Why 3 — Structural level, lines 107-108):**

> "The substrate has **gate truth** for blocking (mission-anchor-dispatch-preflight.sh aborts on unfilled MISSION.md, DCG blocks risky commands, etc.) but no symmetric **license truth** for permitting. There is no `mission-anchor-dispatch-license.sh` that says 'this task is in the locked envelope, proceed.'"

**Mapping to wire-or-explain:**

CoralRaven's `mission-anchor-dispatch-license.sh` proposal is **a special case of wire-or-explain**, not orthogonal:
- "Mission-aligned dispatch" is one artifact-class (per Lane A taxonomy).
- "Mission anchor authorizes this task" is one *wired* state.
- "License is unknown / ambiguous / absent" is one *orphan* state.

The wire-or-explain gate is the general primitive. The license-substrate is a concrete consumer that registers via the gate: every locked MISSION.md task IS a shipped artifact whose consumer is the dispatch path, whose wiredness is checked by the license-script. If the license-substrate ships and *itself* has no consumer (no tick handler reads its output) — wire-or-explain flags it. If MISSION.md is filled and explicitly names work that the dispatch path doesn't act on — wire-or-explain flags **that** as an orphan too.

**Concrete co-build:** when Lane C designs the wire-or-explain ledger schema, every row has a `mission_anchor_phase:<P0|P1|P2|P3|null>` field. CoralRaven's #6 information-flow fix lands as a special case: "permit when mission_anchor_phase is present AND task matches phase ladder." The dispatch path queries the wire-or-explain ledger; the ledger is the single source of truth for both wiring AND license. **Two findings, one substrate.**

This is the cross-cutting finding all 3 lanes should agree on (per intent §"Convergence criteria — Phase 1": "≥1 cross-cutting finding all 3 agree on").

---

## 7. Recommendations for Lane C (implementation design)

Based on Lane B's mechanism inventory and Jeff/external pattern survey:

1. **Schema (adopt J1+J2+E2 shape):**
   ```jsonl
   {"schema_version":"wiring-ledger/v1","ts":"<iso>","artifact":"<path>","content_sha":"<sha256>","class":"<probe|hook|plist|skill|doctrine|...>","consumed_by":["<mechanism>"],"status":"wired|deferred|orphan","evidence":"<file:line>","deferred_until":"<bead-id|iso>|null","supersedes":"<prior-row-id>|null","bundle_id":"<plan-id>|null","mission_anchor_phase":"P0|P1|P2|P3|null"}
   ```

2. **Discoverability CLI (adopt J1+E8 shape):** `flywheel-loop deps -v --json` and `flywheel-loop wiring-ledger --json` and `flywheel-loop wiring-ledger --explain <artifact>`.

3. **Tick integration (extend M7 pattern):** new step `WIRE_OR_EXPLAIN_RESULT="$(wire_or_explain_gate)"` appended to flywheel-loop-tick; emits `event:"wire_or_explain"` row to dispatch-log.jsonl; tick close hook reads the row.

4. **Ledger location:** `.flywheel/wiring-ledger.jsonl` per repo (mirrors dispatch-log.jsonl convention) + `~/.local/state/flywheel/wiring-ledger.jsonl` fleet-aggregated.

5. **Discoverability writes (close DISCOVERABILITY GAPs #1-#3):** ship `flywheel-loop tick-steps --json` (lists registered tick steps in M1/M7); `flywheel-loop dispatch-template --constraints --json` (lists dispatch-template constraints in M6). These three are themselves new artifacts that the gate will register.

6. **Shadow-mode (adopt E2+E7):** `gate_mode={shadow,warn,enforce}` in `.flywheel/loop.json`; auto-promote rules from §C5; JOSHUA_OVERRIDE escape matches existing override.sh pattern at /Users/josh/.claude/hooks/_shared/override.sh.

7. **Test plan (adopt J5):** `test_flywheel_loop_tick_contains_wire_or_explain_gate`, `test_gate_shadow_mode_does_not_block`, `test_gate_enforce_mode_blocks_on_orphan`, `test_idempotent_register`, `test_circular_orphan_chain_detected`.

8. **Dogfood plan:** retroactively classify the 6 unwired-or-questionably-wired artifacts named in intent §6 (peer-orch-productivity-watch.sh, fleet-conformance-probe.sh, fleet-comms-health-probe.sh, fleet-process-gap-detector.sh, fleet-observatory-aggregate.sh, L101-L108) + CoralRaven's mission-anchor-dispatch-license.sh proposal. If the gate flags exactly these 7 + nothing else, gate is correctly calibrated. If it flags more — investigate each (likely real orphans). If fewer — gate has a blind spot.

9. **Anti-patterns to avoid (J7):** the gate is NOT a static analyzer; it MUST execute at tick-close and emit an actionable JSON row. The gate is NOT a refuse-only mechanism; it is bidirectional (orphan → block; deferred-with-reason → permit; wired → permit-and-record).

10. **Cross-orch broadcast:** when the gate ships, `/flywheel:fleet-conductor` broadcasts wire-or-explain status to every active orchestrator (skillos, alpsinsurance, mobile-eats, vrtx, picoz). CoralRaven's §9 routing item F applies directly: "every active orchestrator should self-check for the same pattern."

---

```
{"lane":"B","mechanisms_audited":12,"jeff_patterns_adopted":4,"evaluated":8,"avoided":1,"external_patterns_surveyed":8,"socraticode_queries":0,"indexed_chunks_observed":0,"coralraven_mapping_done":yes,"output_path":"/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/01-RESEARCH-B.md","ready_for_lane_c":yes}
```
