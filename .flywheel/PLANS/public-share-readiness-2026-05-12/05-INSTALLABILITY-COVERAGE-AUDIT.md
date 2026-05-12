# 05-INSTALLABILITY-COVERAGE-AUDIT.md

**Plan:** `public-share-readiness`
**Phase:** 5 POLISH preflight
**Author:** flywheel pane 2 / TopazMeadow
**Created:** 2026-05-12T20:47Z
**Basis:** Codex built-in `/goal` objective, Socraticode search against `/Users/josh/Developer/flywheel`, `04-BEADS-DAG.md`, `00-PLAN.md`, `ARCHITECTURE.md`, `templates/flywheel-install/README.md`, and Dicklesworthstone stack install notes.
**Status:** Coverage audit. Not a completion claim.

---

## 1. Objective Restatement

Make Flywheel publicly installable, understandable, and usable end to end across every surface.

Concrete success means a developer who finds `github.com/JYeswak/flywheel` or `flywheel.zeststream.ai` can:

1. Understand what Flywheel is and whether it fits their ecosystem.
2. Install or detect the required Dicklesworthstone-derived substrate.
3. Connect Claude, Codex, OpenClaw, Gemini, or reduced local mode.
4. Initialize Flywheel in their own repos without Joshua-specific state.
5. Run `doctor`, `tick`, dispatch-or-simulate, and validated closeout.
6. Inspect resulting work state and decide the next useful action.
7. Adapt the ecosystem safely, with SkillOS treated as the capability control plane.
8. Treat Red Hat/SMB positioning and Mobile Eats L170 journey semantics as proof surfaces, not as the whole mission.

This goal is deliberately larger than a README, an installer, or a route-smoke suite. It is a first-run operator journey with mechanical evidence.

---

## 2. Current Artifact Evidence

| Requirement | Current evidence | Coverage | Gap |
|---|---|---:|---|
| Public engine extraction | `00-PLAN.md` §1-7, `04-BEADS-DAG.md` B0-B11 | partial | Extraction is planned, not built. |
| Live-state/private overlay exclusion | `04-BEADS-DAG.md` B0.5, B3.4, B4 | partial | Denylist tool and enforcement do not exist yet. |
| Installer fresh/partial/existing states | `00-PLAN.md` §6.2, `04-BEADS-DAG.md` B6 | partial | B6 only says three-branch detection; no public preflight matrix for Jeff-stack dependencies. |
| Uninstall/byte equality | `04-BEADS-DAG.md` B7, B9, B17 | partial | Planned in CI/smoke; no implementation. |
| Public repo top-level trust files | `04-BEADS-DAG.md` B11, B14.5 | partial | Planned; no public repo files exist yet. |
| Website SMB trust surface | `00-PLAN.md` §8, `04-BEADS-DAG.md` B13.* | partial | Planned pages; no website implementation. |
| GitHub↔website cross-links | `04-BEADS-DAG.md` B14 | partial | Link check planned; no artifacts yet. |
| Fresh-machine smoke | `00-PLAN.md` §5.5, `04-BEADS-DAG.md` B17 | weak | Smoke is an 8-step release check, but it does not yet cover agent harnesses, SkillOS boundary, or reduced mode. |
| Dicklesworthstone stack substrate | Dicklesworthstone `COMMANDS.md` install notes; `ARCHITECTURE.md` substrate layer | weak | Current DAG names NTM/beads indirectly, but not Agent Mail, Beads viewer/graph, DCG, CASS-style memory, Socraticode, and setup scripts as a public preflight contract. |
| Claude onboarding | rough drafts mention Claude Code; templates know Claude hooks | weak | No harness-specific public setup/verify bead. |
| Codex onboarding | rough drafts mention codex; README has Codex worker rules | weak | No public Codex setup/verify bead. |
| OpenClaw onboarding | user objective names OpenClaw | missing | No discovered Flywheel artifact defines OpenClaw support level. |
| Gemini onboarding | rough architecture mentions Gemini for multi-model drafts | weak | No public Gemini setup/verify bead. |
| Reduced local mode | user objective requires reduced mode | missing | No DAG row proves useful single/reduced mode behavior without multi-agent dispatch. |
| Repo-local initialization | `templates/flywheel-install/`, `README.md`, `04-BEADS-DAG.md` B5-B6 | partial | Template rendering exists; public `flywheel init` user journey is not yet acceptance-tested. |
| Validated closeout | templates close validator, `ARCHITECTURE.md`, README L120-L128 | partial | Internal close contract exists; public first-run closeout story is not yet isolated from ZestStream-specific NTM/Agent Mail assumptions. |
| Work-state inspection | Beads/dispatch ledgers in `ARCHITECTURE.md`; `br ready` worker workflow | weak | Public “what do I inspect after first tick?” flow is not named in B17/B12. |
| SkillOS boundary | `04-BEADS-DAG.md` B16 and `00-PLAN.md` §9 item 12 | partial | Needs updated Phase 5 framing: SkillOS is capability control plane, not only fleet rollout or v0.3 skill handoff. |
| Mobile Eats L170 semantics | external callback from mobile-eats pane 2 | missing in plan | L170 journey-grade value semantics are not represented in B12/B13/B17 acceptance. |

Conclusion: the current 36-bead DAG is a strong public extraction plan, but it is not yet a complete public installability and first-run operator journey plan.

---

## 3. Prompt-To-Artifact Checklist

| Prompt requirement | Artifact that must eventually prove it | Current state | Phase 5 action |
|---|---|---|---|
| “publicly installable” | `install.sh`, `installer-smoke.yml`, B6/B9/B17 receipts | planned | Amend B6/B17 to include dependency preflight and harness modes. |
| “understandable” | `README.md`, docs getting-started/concepts/reference, website `/what-is-flywheel` | planned | Add first-run journey narrative to B12.1 and B13.3. |
| “usable end to end” | Fresh-environment journey receipt: install → init → doctor → tick → dispatch/simulate → closeout → inspect | not covered as one chain | Add a journey-level smoke script or extend B17 beyond the existing 8-step check. |
| “repo or website” | B11, B13.*, B14 link checks | planned | Keep B14, but require journey equivalence from both entrypoints. |
| “install or detect required substrate” | Preflight matrix for Git, shell, Python, Node, Rust/Cargo, Go, SQLite, tmux, Agent Mail, br/beads, NTM, DCG, CASS, Socraticode | missing | Add B6 sub-scope or new B6.5 preflight matrix bead. |
| “Dicklesworthstone-derived substrate” | Install/detect docs and smoke for mcp_agent_mail, agentic_coding_flywheel_setup, beads_viewer/Beads, destructive_command_guard, cass_memory_system | weak | Add substrate dependency contract; cite source repos/SHAs at implementation time. |
| “connect Claude” | Claude setup doc + config dry-run + doctor proof | weak | Add harness matrix acceptance to B12.1/B17. |
| “connect Codex” | Codex setup doc + AGENTS/MCP expectations + doctor proof | weak | Add harness matrix acceptance to B12.1/B17. |
| “connect OpenClaw” | Support-level statement + generic shell/MCP path or explicit unsupported status | missing | Add B12.1 requirement: honest support tier, no silent overclaim. |
| “connect Gemini” | Support-level statement + generic shell/MCP path or explicit unsupported status | weak | Add B12.1 requirement: honest support tier, no silent overclaim. |
| “reduced local mode” | Smoke path that works without multi-agent dispatch | missing | Add B5/B17 requirement for `dispatch --simulate` or equivalent. |
| “initialize in own repos” | `flywheel init` docs, template render, repo-local Beads state, `.flywheel/loop.json` | partial | Bind B5/B6/B12.1 to a synthetic target repo fixture. |
| “doctor/tick/dispatch-or-simulate/validated-closeout” | One command transcript or JSON receipt with all stages | partial | Add B17 journey receipt schema. |
| “inspect resulting work state” | Docs showing `br ready`, receipts, dispatch log, doctor output, next action | weak | Add B12.1/B17 acceptance for post-run inspection. |
| “adapt ecosystem without Joshua-specific state” | `.flywheel-protected.json`, de-personalization checks, template variables, no `/Users/josh` grep | partial | Existing B0.5/B1/B3/B4 cover extraction; B12 must teach adaptation. |
| “SkillOS capability control plane” | B16 handoff plus public docs that distinguish Flywheel vs SkillOS | weak | Amend B16 from skill-boundary handoff to capability-control-plane boundary. |
| “Red Hat/SMB as proof surface” | Website copy and `CHARTER.md` commercial framing | partial | Ensure B13 pages do not redefine whole ecosystem around SMB-only. |
| “Mobile Eats journey semantics as proof surface” | Journey acceptance vocabulary in docs/smoke: persona, first value, return loop, guardrail | missing | Add journey-grade acceptance to B12.1/B17; selectors/commands are evidence, not doctrine. |

---

## 4. Required Phase 5 Amendments

### A1 — Add a public preflight dependency matrix

**Why:** B6 says the installer handles fresh/partial/existing state, but the objective requires the installer to install or detect the substrate Flywheel actually depends on.

**Minimum matrix columns:**

| Dependency | Required for | Install path | Detect command | Reduced-mode fallback |
|---|---|---|---|---|
| Git | all modes | system/package manager | `git --version` | none |
| Bash/zsh | all modes | system | `$SHELL --version` or `bash --version` | none |
| Python 3.10+ | Agent Mail / scripts | package manager / uv / pyenv | `python3 --version` | no Agent Mail server |
| Node 18+ | CASS-style memory / docs site | package manager / nvm | `node --version` | no CASS/docs dev server |
| Rust/Cargo | DCG / some Jeff tools | rustup | `cargo --version` | warn, shell-only guard docs |
| Go | beads viewer | go install | `go version` | skip TUI viewer |
| SQLite | Beads / local ledgers | system | `sqlite3 --version` | none for Beads mode |
| tmux | NTM panes | system | `tmux -V` | reduced local mode |
| Agent Mail | multi-agent coordination | mcp_agent_mail install | health command | single-agent/reduced mode |
| Beads / `br` | work graph | beads install | `br --version` / `br where` | no dispatch graph; tutorial only |
| NTM | pane orchestration | Jeff install path | `ntm --version` / health | simulated dispatch |
| DCG | destructive-command guard | build/install | `dcg --version` | warn, require manual shell caution |
| CASS-style memory | cross-session memory | service install | health endpoint | no memory layer |
| Socraticode | codebase search | MCP setup | MCP health/search | docs say non-trivial edits unsupported |

**Routing:** Either split from B6 as `B6.5` or make B6 acceptance require this matrix plus a fixture runner.

### A2 — Extend B17 from release smoke to journey-grade smoke

Current B17 is a release smoke. It must become a first-run journey smoke:

1. Start in a clean macOS or Linux fixture.
2. Run preflight.
3. Install or record reduced-mode fallback.
4. Configure one selected harness.
5. Initialize a synthetic repo.
6. Run `doctor`.
7. Run first `tick`.
8. Dispatch or simulate one worker lane.
9. Close with validated receipt.
10. Inspect `br`, receipts, and next action output.

**Acceptance:** one JSON receipt with fields:

```json
{
  "mode": "full|reduced",
  "harness": "claude|codex|openclaw|gemini|none",
  "preflight": "pass|warn|fail",
  "init": "pass|fail",
  "doctor": "pass|fail",
  "tick": "pass|fail",
  "dispatch_or_simulate": "pass|fail",
  "closeout": "pass|fail",
  "inspect_next_action": "pass|fail"
}
```

### A3 — Add a harness support matrix

The public plan must not imply equal support for all harnesses until verified.

| Harness | Current evidence | Phase 5 support label |
|---|---|---|
| Claude | Strong internal evidence: hooks/templates/skills assume Claude Code | `supported-first` if config dry-run + doctor smoke lands |
| Codex | Strong internal worker evidence; MCP/resource assumptions differ | `supported-first` if AGENTS/MCP setup + doctor smoke lands |
| OpenClaw | No current artifact found in Flywheel search | `compatibility-target` until probed |
| Gemini | Mentioned as multi-model source, not operator harness | `compatibility-target` until probed |
| none/reduced | Objective requires it; current DAG missing | `required-v0.2` reduced mode |

### A4 — Reframe SkillOS boundary in B16

Current B16 is a skill-boundary coordination handoff. The latest SkillOS rev7 correction is broader:

> SkillOS is the Skills Operating System and capability control plane for ZestStream's AI-native pods.

Phase 5 should rewrite B16 acceptance so the boundary is:

- Flywheel owns installability, doctrine/templates, loop/dispatch/closeout, and public engine extraction.
- SkillOS owns capability-loop substrate, skill-surface governance, Jeff-stack capability ingestion, research-triad signal, and validated self-improving skill loops.
- Red Hat/SMB is a commercial proof surface, not the whole SkillOS mission.

### A5 — Import Mobile Eats L170 semantics into public journey gates

Mobile Eats pane 2 clarified:

- L170 is not three route smoke tests.
- UI/product journeys require persona, first value, return loop, and guardrail.
- Selectors are executable evidence, not the doctrine layer.
- Owner/operator journeys count when they are real users.
- Failures route by semantic class: missing value, stale product meaning, auth/test-fixture gap, selector drift, source/data gap.

For Flywheel, the analogous first-run journey must declare:

| Field | Flywheel public onboarding equivalent |
|---|---|
| Persona | solo developer, team lead, or SMB technical operator |
| First value | initialized repo with a passing doctor and next action |
| Return loop | reusable tick/dispatch/closeout cycle with state inspection |
| Guardrail | no private-state leak, no destructive mutation, reduced-mode honesty |

---

## 5. Recommended DAG Changes Before `br create`

Do not create all 36 beads unchanged. Phase 5 should amend the DAG first:

1. **Amend B6** or add **B6.5**: dependency preflight matrix and reduced-mode resolver.
2. **Amend B12.1**: getting-started docs must include first-run operator journey, harness matrix, and post-run inspection.
3. **Amend B13.3**: `/for-developers` must state support tiers honestly and link to install/preflight docs.
4. **Amend B16**: SkillOS boundary becomes capability-control-plane boundary, not only skill handoff.
5. **Amend B17**: journey-grade smoke receipt replaces the current 8-step release-only smoke.
6. **Amend B15**: Joshua sign-off must cover repo, website, and first-run journey, not only release artifacts.

If the DAG remains at 36 beads, these are acceptance rewrites. If the DAG grows, likely additions are:

- `B6.5` Public dependency preflight matrix.
- `B12.0` First-run journey narrative and support-tier matrix.
- `B17.5` Reduced-mode smoke plus harness compatibility receipt.

---

## 6. Non-Completion Finding

The active Codex `/goal` is not achieved.

Reason: current artifacts prove intent and a strong extraction DAG, but they do not yet prove:

- dependency-aware public preflight,
- harness-specific setup for Claude/Codex/OpenClaw/Gemini,
- reduced local mode,
- journey-grade first value/return loop/guardrail,
- SkillOS rev7 capability-control-plane boundary,
- a single end-to-end install/init/doctor/tick/dispatch-or-simulate/closeout/inspect receipt.

Next concrete action: update `04-BEADS-DAG.md` Phase 5 polish queue and affected bead rows with the amendments above, then create the first canonical `br` beads only after the amended DAG converges.
