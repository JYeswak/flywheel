# NOT-WIRED Dispositions - flywheel-a2lff

Generated: 2026-05-07

Source report: `.flywheel/plans/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/11-USE-ROW-VERIFICATION.md`

Output requested by dispatch as `12-NOT-WIRED-DISPOSITIONS.md`; bead body used older name `12-USE-NOT-WIRED-TRIAGE.md`. This file follows the dispatch.

## Section 1 - Headline numbers

- WIRE-IT count: 25
- RECLASSIFY-EXCLUDED count: 14
- RECLASSIFY-WRAP-ALIAS count: 6
- RECLASSIFY-ISSUE count: 5
- Total: 50
- Socraticode searches run: 500 (50 surfaces * K=10)
- NTM help probes: 50/50 returned exit 0

## Section 2 - Per-surface disposition table

| Surface | Sub-class | Rationale | Action | Evidence |
|---|---|---|---|---|
| <a id="adopt"></a>`adopt` | RECLASSIFY-EXCLUDED | Adopting externally-created sessions is orthogonal to flywheel steady-state orchestration; flywheel creates, spawns, dispatches, and respawns sessions under known contracts. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Adopt an existing tmux session that was created outside of NTM.; socraticode `adopt flywheel use case` -> INCIDENTS.md:1801-1900 |
| <a id="agents"></a>`agents` | WIRE-IT | Agent capability metadata is directly relevant to dispatch quality and capacity routing. Current worker identity/capability handling remains scattered, so this should become a native data-source wire-in. | Propose wire-in bead `agents` (P1, -40 LOC, expected >=3 callsites). | help: Manage agent capability profiles for intelligent task assignment.; socraticode `agents flywheel use case` -> AGENTS.md:3151-3250 |
| <a id="analytics"></a>`analytics` | WIRE-IT | Fleet analytics are relevant to uptime and regression detection. Current reports still aggregate locally, so native analytics should become a measured rollup source. | Propose wire-in bead `analytics` (P1, -60 LOC, expected >=3 callsites). | help: Display aggregated analytics from NTM session events.; socraticode `analytics flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="attach"></a>`attach` | RECLASSIFY-EXCLUDED | Attach is an operator-interactive verb, not an automation primitive. Flywheel panes should be controlled via send/copy/health rather than interactive attachment. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Attach to an existing tmux session. If already inside tmux,; socraticode `attach flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="bind"></a>`bind` | RECLASSIFY-WRAP-ALIAS | This is already consumed indirectly by the onboarding wrapper; the 7p45b grep missed `run_native ... bind --show` because the surface is passed as an argument, not as literal `ntm bind`. | Propose inventory edit: mark WRAP-ALIAS/verified wrapper and cite existing wrapper callsite. | help: Configure a tmux keybinding to open the NTM command palette or dashboard overlay.; socraticode `bind flywheel use case` -> tests/test_apply_tmux_tuning.sh:1-85; wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native bind during onboarding |
| <a id="cass"></a>`cass` | WIRE-IT | CASS search is mission-relevant because memory/context lookup prevents substrate amnesia. The inventory claim should become a measured `ntm cass`/`ntm search` replacement path. | Propose wire-in bead `cass` (P1, -30 LOC, expected >=3 callsites). | help: Search, analyze, and explore past agent sessions indexed by CASS.; socraticode `cass flywheel use case` -> INCIDENTS.md:2701-2800 |
| <a id="changes"></a>`changes` | WIRE-IT | File-change attribution is relevant to multi-agent collision control. Current flywheel path and reservation checks are still local, so wire native changes as an input before reclassification. | Propose wire-in bead `changes` (P0, -50 LOC, expected >=3 callsites). | help: Show which files were modified by agents in recent operations.; socraticode `changes flywheel use case` -> README.md:991-1035 |
| <a id="completion"></a>`completion` | RECLASSIFY-WRAP-ALIAS | Already wired through onboarding via `run_native ... completion`; the direct grep missed the wrapper call shape. | Propose inventory edit: mark WRAP-ALIAS/verified wrapper and cite existing wrapper callsite. | help: Generate completion scripts for various shells.; socraticode `completion flywheel use case` -> INCIDENTS.md:2701-2800; wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native completion during onboarding |
| <a id="config"></a>`config` | WIRE-IT | Configuration state is mission-relevant because NTM drift silently breaks orchestration. Wire `ntm config` into doctor/validation rather than leaving TOML assumptions unmeasured. | Propose wire-in bead `config` (P1, -25 LOC, expected >=3 callsites). | help: Manage configuration; socraticode `config flywheel use case` -> INCIDENTS.md:1801-1900 |
| <a id="conflicts"></a>`conflicts` | WIRE-IT | File conflicts are a real shared-surface risk in the fleet. Wire native conflict reporting into L107/dispatch verification. | Propose wire-in bead `conflicts` (P0, -45 LOC, expected >=3 callsites). | help: Identify files modified by multiple agents simultaneously.; socraticode `conflicts flywheel use case` -> INCIDENTS.md:2701-2800 |
| <a id="controller"></a>`controller` | RECLASSIFY-ISSUE | Potentially useful, but the controller spawn contract needs Jeff clarification before flywheel can delegate pane-1 authority safely. | Propose Jeff issue manifest; do not wire until contract clarified. | help: Launch a controller agent in pane 1 of an existing session.; socraticode `controller flywheel use case` -> README.md:991-1035; ntm source: ~/Developer/ntm/internal/cli/controller.go:132-170 defines controller command; root robot flags at root.go:3334-3337 |
| <a id="create"></a>`create` | WIRE-IT | Session creation is relevant, but flywheel currently prefers `spawn` and onboarding wrappers. Add a focused create-vs-spawn disposition bead before treating USE as verified. | Propose wire-in bead `create` (P2, -20 LOC, expected >=3 callsites). | help: Create a new tmux session with the specified number of panes.; socraticode `create flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="doctor"></a>`doctor` | WIRE-IT | Native NTM doctor belongs in flywheel doctor as a sibling substrate probe. Zero callsites means this is a high-priority wire-in gap. | Propose wire-in bead `doctor` (P0, -35 LOC, expected >=3 callsites). | help: Validates that all ecosystem tools and dependencies are properly installed; socraticode `doctor flywheel use case` -> AGENTS.md:3331-3430 |
| <a id="ensemble"></a>`ensemble` | RECLASSIFY-EXCLUDED | Reasoning ensembles are a product/analysis feature, not continuous orchestrator uptime substrate. No current hand-rolled equivalent justifies keeping it as USE. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Manage and run reasoning ensembles.; socraticode `ensemble flywheel use case` -> AGENTS.md:541-640 |
| <a id="extract"></a>`extract` | WIRE-IT | Extracting code blocks from panes is useful for recovery and evidence capture. Wire it where worker-stall and evidence-pack flows currently parse pane text manually. | Propose wire-in bead `extract` (P1, -25 LOC, expected >=3 callsites). | help: Extract markdown code blocks from agent pane output.; socraticode `extract flywheel use case` -> README.md:451-550 |
| <a id="get-all-session-text"></a>`get-all-session-text` | WIRE-IT | Full-session text capture maps to tail/audit pack generation. Wire it as a replacement candidate for per-pane capture aggregation. | Propose wire-in bead `get-all-session-text` (P1, -55 LOC, expected >=3 callsites). | help: Captures output from all panes in all tmux sessions and displays as a markdown table.; socraticode `get-all-session-text flywheel use case` -> README.md:991-1035 |
| <a id="git"></a>`git` | WIRE-IT | Git coordination is mission-relevant, but must be scoped behind existing destructive-command and br discipline. Wire as read/diagnostic first. | Propose wire-in bead `git` (P2, -30 LOC, expected >=3 callsites). | help: Git-related commands for coordinating version control across agents.; socraticode `git flywheel use case` -> AGENTS.md:541-640 |
| <a id="grep"></a>`grep` | WIRE-IT | Pane-output grep is high-leverage for frozen-pane, callback, and stuck-template detectors. Zero callsites means the inventory claim is still aspirational. | Propose wire-in bead `grep` (P0, -80 LOC, expected >=3 callsites). | help: Search across all pane output buffers with regex support.; socraticode `grep flywheel use case` -> INCIDENTS.md:1801-1900 |
| <a id="guards"></a>`guards` | RECLASSIFY-ISSUE | Useful, but native Agent Mail guard parity with flywheel L107 and local hook contracts is not proven. Needs Jeff clarification before replacing local guards. | Propose Jeff issue manifest; do not wire until contract clarified. | help: Manage Agent Mail pre-commit guards for multi-agent coordination.; socraticode `guards flywheel use case` -> INCIDENTS.md:4051-4150; ntm source: ~/Developer/ntm/internal/cli/guards.go:21-50 defines Agent Mail guard install surface |
| <a id="hooks"></a>`hooks` | RECLASSIFY-ISSUE | Useful, but native hook installation must be compared against flywheel doctrine gates before wiring. Treat as upstream/contract issue, not direct USE. | Propose Jeff issue manifest; do not wire until contract clarified. | help: Install and manage git hooks for quality checks (UBS) and coordination (Agent Mail).; socraticode `hooks flywheel use case` -> INCIDENTS.md:2161-2260; ntm source: ~/Developer/ntm/internal/cli/hooks.go:19-20 and :205 define hook management/status |
| <a id="init"></a>`init` | RECLASSIFY-WRAP-ALIAS | Already wired through onboarding via `run_native ... init`; the audit missed the indirect call. | Propose inventory edit: mark WRAP-ALIAS/verified wrapper and cite existing wrapper callsite. | help: Initialize NTM orchestration for a project directory.; socraticode `init flywheel use case` -> README.md:91-190; wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native init during onboarding |
| <a id="kernel"></a>`kernel` | RECLASSIFY-EXCLUDED | Kernel registry inspection is an NTM developer surface. Flywheel can consume exported templates/context without making kernel a runtime dependency. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Inspect the command kernel registry used to drive CLI, TUI, and REST surfaces.; socraticode `kernel flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="kill"></a>`kill` | RECLASSIFY-EXCLUDED | Direct session kill is intentionally not a flywheel automation primitive; recovery uses respawn, wait, health, and explicit dangerous-drill gates. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Kill a tmux session and all its panes.; socraticode `kill flywheel use case` -> AGENTS.md:3511-3610 |
| <a id="level"></a>`level` | RECLASSIFY-EXCLUDED | CLI proficiency tier is human/operator education. It does not advance continuous orchestrator uptime once onboarding is established. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: View your current proficiency tier and change it.; socraticode `level flywheel use case` -> STATE.md:1-15 |
| <a id="memory"></a>`memory` | WIRE-IT | CASS memory lookup is relevant to substrate-amnesia prevention. Wire native memory into existing CASS/memory probes or reclassify after a measured no-fit receipt. | Propose wire-in bead `memory` (P1, -25 LOC, expected >=3 callsites). | help: Interact with CASS Memory (cm) system; socraticode `memory flywheel use case` -> README.md:991-1035 |
| <a id="models"></a>`models` | RECLASSIFY-EXCLUDED | Ollama model management is local model hygiene, not a current flywheel orchestration primitive. No direct hand-rolled NTM equivalent exists in today's plan. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Manage Ollama models used by local NTM agents.; socraticode `models flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="modes"></a>`modes` | RECLASSIFY-EXCLUDED | Reasoning modes are advisory/operator knowledge, not fleet substrate. Keep out of the direct USE set unless a future dispatcher selects modes programmatically. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Browse, search, and get detailed explanations of reasoning modes.; socraticode `modes flywheel use case` -> README.md:991-1035 |
| <a id="openapi"></a>`openapi` | RECLASSIFY-EXCLUDED | OpenAPI generation is a service/API exposure concern. Flywheel does not currently operate an NTM REST API contract that needs this surface. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Manage OpenAPI specification generation from the kernel registry.; socraticode `openapi flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="overlay"></a>`overlay` | RECLASSIFY-EXCLUDED | Overlay is interactive UI. It can be documented for operators but should not be counted as automated wire-in. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Open the NTM dashboard in a tmux popup that floats over your agent panes.; socraticode `overlay flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="personas"></a>`personas` | RECLASSIFY-EXCLUDED | NTM personas are agent-prompt personas, while flywheel's current profile logic is CAAM/account and worker identity. This row conflates concepts and should leave direct USE. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: List and inspect available agent personas.; socraticode `personas flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="profiles"></a>`profiles` | WIRE-IT | NTM agent profiles can reduce hardcoded agent capability assumptions. Wire them into onboarding/dispatch identity checks before declaring verified USE. | Propose wire-in bead `profiles` (P2, -35 LOC, expected >=3 callsites). | help: List and inspect available agent profiles.; socraticode `profiles flywheel use case` -> INCIDENTS.md:1801-1900 |
| <a id="plugins"></a>`plugins` | RECLASSIFY-EXCLUDED | Plugin management is extension administration, not flywheel uptime substrate. No current plugin lifecycle work is in scope. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Manage and list installed plugins; socraticode `plugins flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="profile"></a>`profile` | WIRE-IT | Named spawn profiles can replace hardcoded session shape. Wire this into onboarding as a durable spawn-profile path. | Propose wire-in bead `profile` (P2, -40 LOC, expected >=3 callsites). | help: Save, list, and delete reusable spawn configurations as named profiles.; socraticode `profile flywheel use case` -> INCIDENTS.md:1801-1900 |
| <a id="quick"></a>`quick` | RECLASSIFY-EXCLUDED | Quick creates a new project skeleton; flywheel-onboard is the richer repo-local onboarding contract, so direct quick use is intentionally out of scope. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: Create a new project directory with sensible defaults:; socraticode `quick flywheel use case` -> README.md:991-1035 |
| <a id="recipes"></a>`recipes` | WIRE-IT | Recipes can replace ad hoc session bootstrap presets. Wire into onboarding/status docs or reclassify after a fixture proves no fit. | Propose wire-in bead `recipes` (P2, -30 LOC, expected >=3 callsites). | help: List and view session recipes (presets).; socraticode `recipes flywheel use case` -> INCIDENTS.md:2701-2800 |
| <a id="repo"></a>`repo` | RECLASSIFY-ISSUE | Repo pass-through delegates to external tooling; flywheel needs clearer dry-run/status/error contracts before relying on it. | Propose Jeff issue manifest; do not wire until contract clarified. | help: Repo-level commands that pass through to external tooling.; socraticode `repo flywheel use case` -> MISSION.md:1-14; ntm source: ~/Developer/ntm/internal/cli/repo.go:13-24 and internal/tools/ru.go:13-21 show repo passes through RU adapter |
| <a id="resume"></a>`resume` | WIRE-IT | Resume maps to handoff/recovery after compaction. Wire it into handoff closeout validation. | Propose wire-in bead `resume` (P1, -35 LOC, expected >=3 callsites). | help: Resume work from the most recent handoff for a session,; socraticode `resume flywheel use case` -> INCIDENTS.md:2791-2890 |
| <a id="rollback"></a>`rollback` | RECLASSIFY-WRAP-ALIAS | Existing rollback wrapper is intentional flywheel doctrine: native checkpoint/rollback concepts are wrapped with dirty-worktree and receipt gates. | Propose inventory edit: mark WRAP-ALIAS/verified wrapper and cite existing wrapper callsite. | help: Restore a session to a previous checkpoint state.; socraticode `rollback flywheel use case` -> tests/test_validation_matrix_schema.sh:24-127; wrapper: .flywheel/scripts/ntm-checkpoint-rollback-guard.sh:18-43 defines rollback receipt schema and authorized rollback validation operations |
| <a id="save"></a>`save` | WIRE-IT | Saving pane output is relevant to evidence packs and support bundles. Wire it as a replacement for hand-rolled capture paths. | Propose wire-in bead `save` (P1, -40 LOC, expected >=3 callsites). | help: Save the output from session panes to individual files.; socraticode `save flywheel use case` -> README.md:181-280 |
| <a id="scale"></a>`scale` | WIRE-IT | Agent scaling maps to capacity management. Wire read-only/dry-run scale recommendations before allowing mutation. | Propose wire-in bead `scale` (P2, -45 LOC, expected >=3 callsites). | help: Scale agents in a session to exact target counts.; socraticode `scale flywheel use case` -> INCIDENTS.md:1801-1900 |
| <a id="scan"></a>`scan` | WIRE-IT | UBS scanning maps to validation and compliance. Wire native scan into validation matrix rather than relying on local script-level scan words. | Propose wire-in bead `scan` (P1, -35 LOC, expected >=3 callsites). | help: Run the Ultimate Bug Scanner (UBS) on files or directories.; socraticode `scan flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="search"></a>`search` | WIRE-IT | Search past sessions is directly relevant to incident replay and CASS lookup. Wire native search into memory/research flows. | Propose wire-in bead `search` (P1, -30 LOC, expected >=3 callsites). | help: Search past agent sessions indexed by CASS (Coding Agent Session Search).; socraticode `search flywheel use case` -> INCIDENTS.md:1801-1900 |
| <a id="session-templates"></a>`session-templates` | WIRE-IT | Session templates can replace hardcoded multi-agent shapes. Wire into onboarding after profile/recipes decisions settle. | Propose wire-in bead `session-templates` (P2, -45 LOC, expected >=3 callsites). | help: List and view session templates (multi-agent configurations).; socraticode `session-templates flywheel use case` -> INCIDENTS.md:2161-2260 |
| <a id="shell"></a>`shell` | RECLASSIFY-WRAP-ALIAS | Already wired through onboarding via `run_native ... shell`; the audit missed indirect call shape. | Propose inventory edit: mark WRAP-ALIAS/verified wrapper and cite existing wrapper callsite. | help: Generate shell integration for zsh, bash, or fish.; socraticode `shell flywheel use case` -> INCIDENTS.md:2161-2260; wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native shell during onboarding |
| <a id="spawn"></a>`spawn` | RECLASSIFY-WRAP-ALIAS | Already wired through onboarding via `run_native ... spawn`; the audit missed indirect call shape. | Propose inventory edit: mark WRAP-ALIAS/verified wrapper and cite existing wrapper callsite. | help: Create a new tmux session and launch AI coding agents in separate panes.; socraticode `spawn flywheel use case` -> INCIDENTS.md:1801-1900; wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native spawn during onboarding |
| <a id="status"></a>`status` | WIRE-IT | Detailed session status is a core orchestration signal. Wire into coordinator/status probes after #124-related daemon ambiguity is isolated. | Propose wire-in bead `status` (P0, -50 LOC, expected >=3 callsites). | help: Show detailed information about a session including:; socraticode `status flywheel use case` -> STATE.md:1-15 |
| <a id="support-bundle"></a>`support-bundle` | RECLASSIFY-ISSUE | Useful for diagnostics, but bundle contents and redaction defaults need an explicit contract before flywheel automates archives. | Propose Jeff issue manifest; do not wire until contract clarified. | help: Generate a support bundle archive containing diagnostic information; socraticode `support-bundle flywheel use case` -> README.md:91-190; ntm source: ~/Developer/ntm/internal/cli/support_bundle.go:52-71 defines bundle command; root.go:3182-3188 exposes robot bundle flags |
| <a id="view"></a>`view` | RECLASSIFY-EXCLUDED | View is an interactive pane inspection surface. Automation should use copy/logs/save/status instead. | Propose inventory edit: move from USE to EXCLUDED with no-fit rationale. | help: View all panes in a tmux session by:; socraticode `view flywheel use case` -> AGENTS.md:721-820 |
| <a id="watch"></a>`watch` | WIRE-IT | Watch is high-leverage for replacing polling and validating work-started states. Wire after the #124 watch/wait semantics blocker is resolved or guarded. | Propose wire-in bead `watch` (P0, -90 LOC, expected >=3 callsites). | help: Watch mode streams agent output or monitors files.; socraticode `watch flywheel use case` -> tests/test_flywheel_loop_health.sh:45-123 |
| <a id="workflows"></a>`workflows` | WIRE-IT | Workflow templates map to multi-bead orchestration patterns. Wire only as read-only recipe discovery first. | Propose wire-in bead `workflows` (P2, -35 LOC, expected >=3 callsites). | help: List and view workflow templates (orchestration patterns).; socraticode `workflows flywheel use case` -> README.md:991-1035 |

## Section 3 - WIRE-IT bead manifest

### `agents`

- `br create --title "[ntm-use-wire] wire `agents` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -40 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm agents` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `analytics`

- `br create --title "[ntm-use-wire] wire `analytics` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -60 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm analytics` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `cass`

- `br create --title "[ntm-use-wire] wire `cass` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -30 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm cass` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `changes`

- `br create --title "[ntm-use-wire] wire `changes` into flywheel validation surface" --priority 0 --type task`
- Scope estimate: -50 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm changes` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `config`

- `br create --title "[ntm-use-wire] wire `config` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -25 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm config` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `conflicts`

- `br create --title "[ntm-use-wire] wire `conflicts` into flywheel validation surface" --priority 0 --type task`
- Scope estimate: -45 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm conflicts` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `create`

- `br create --title "[ntm-use-wire] wire `create` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -20 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm create` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `doctor`

- `br create --title "[ntm-use-wire] wire `doctor` into flywheel validation surface" --priority 0 --type task`
- Scope estimate: -35 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm doctor` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `extract`

- `br create --title "[ntm-use-wire] wire `extract` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -25 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm extract` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `get-all-session-text`

- `br create --title "[ntm-use-wire] wire `get-all-session-text` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -55 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm get-all-session-text` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `git`

- `br create --title "[ntm-use-wire] wire `git` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -30 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm git` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `grep`

- `br create --title "[ntm-use-wire] wire `grep` into flywheel validation surface" --priority 0 --type task`
- Scope estimate: -80 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm grep` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `memory`

- `br create --title "[ntm-use-wire] wire `memory` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -25 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm memory` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `profiles`

- `br create --title "[ntm-use-wire] wire `profiles` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -35 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm profiles` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `profile`

- `br create --title "[ntm-use-wire] wire `profile` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -40 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm profile` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `recipes`

- `br create --title "[ntm-use-wire] wire `recipes` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -30 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm recipes` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `resume`

- `br create --title "[ntm-use-wire] wire `resume` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -35 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm resume` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `save`

- `br create --title "[ntm-use-wire] wire `save` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -40 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm save` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `scale`

- `br create --title "[ntm-use-wire] wire `scale` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -45 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm scale` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `scan`

- `br create --title "[ntm-use-wire] wire `scan` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -35 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm scan` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `search`

- `br create --title "[ntm-use-wire] wire `search` into flywheel validation surface" --priority 1 --type task`
- Scope estimate: -30 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm search` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `session-templates`

- `br create --title "[ntm-use-wire] wire `session-templates` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -45 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm session-templates` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `status`

- `br create --title "[ntm-use-wire] wire `status` into flywheel validation surface" --priority 0 --type task`
- Scope estimate: -50 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm status` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `watch`

- `br create --title "[ntm-use-wire] wire `watch` into flywheel validation surface" --priority 0 --type task`
- Scope estimate: -90 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm watch` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

### `workflows`

- `br create --title "[ntm-use-wire] wire `workflows` into flywheel validation surface" --priority 2 --type task`
- Scope estimate: -35 LOC or equivalent test/probe addition.
- Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
- Acceptance: introduce >=3 measured executable/script/test callsites for `ntm workflows` or an explicit no-fit receipt; add one fixture/doctor assertion; update inventory verification status to WIRE-IT-QUEUED -> VERIFIED-USE.

## Section 4 - RECLASSIFY-EXCLUDED inventory edit manifest

```diff
- `ntm adopt`: **USE**
+ `ntm adopt`: EXCLUDED - Adopting externally-created sessions is orthogonal to flywheel steady-state orchestration; flywheel creates, spawns, dispatches, and respawns sessions under known contracts.
- `ntm attach`: **USE**
+ `ntm attach`: EXCLUDED - Attach is an operator-interactive verb, not an automation primitive. Flywheel panes should be controlled via send/copy/health rather than interactive attachment.
- `ntm ensemble`: **USE**
+ `ntm ensemble`: EXCLUDED - Reasoning ensembles are a product/analysis feature, not continuous orchestrator uptime substrate. No current hand-rolled equivalent justifies keeping it as USE.
- `ntm kernel`: **USE**
+ `ntm kernel`: EXCLUDED - Kernel registry inspection is an NTM developer surface. Flywheel can consume exported templates/context without making kernel a runtime dependency.
- `ntm kill`: **USE**
+ `ntm kill`: EXCLUDED - Direct session kill is intentionally not a flywheel automation primitive; recovery uses respawn, wait, health, and explicit dangerous-drill gates.
- `ntm level`: **USE**
+ `ntm level`: EXCLUDED - CLI proficiency tier is human/operator education. It does not advance continuous orchestrator uptime once onboarding is established.
- `ntm models`: **USE**
+ `ntm models`: EXCLUDED - Ollama model management is local model hygiene, not a current flywheel orchestration primitive. No direct hand-rolled NTM equivalent exists in today's plan.
- `ntm modes`: **USE**
+ `ntm modes`: EXCLUDED - Reasoning modes are advisory/operator knowledge, not fleet substrate. Keep out of the direct USE set unless a future dispatcher selects modes programmatically.
- `ntm openapi`: **USE**
+ `ntm openapi`: EXCLUDED - OpenAPI generation is a service/API exposure concern. Flywheel does not currently operate an NTM REST API contract that needs this surface.
- `ntm overlay`: **USE**
+ `ntm overlay`: EXCLUDED - Overlay is interactive UI. It can be documented for operators but should not be counted as automated wire-in.
- `ntm personas`: **USE**
+ `ntm personas`: EXCLUDED - NTM personas are agent-prompt personas, while flywheel's current profile logic is CAAM/account and worker identity. This row conflates concepts and should leave direct USE.
- `ntm plugins`: **USE**
+ `ntm plugins`: EXCLUDED - Plugin management is extension administration, not flywheel uptime substrate. No current plugin lifecycle work is in scope.
- `ntm quick`: **USE**
+ `ntm quick`: EXCLUDED - Quick creates a new project skeleton; flywheel-onboard is the richer repo-local onboarding contract, so direct quick use is intentionally out of scope.
- `ntm view`: **USE**
+ `ntm view`: EXCLUDED - View is an interactive pane inspection surface. Automation should use copy/logs/save/status instead.
```

## Section 5 - RECLASSIFY-WRAP-ALIAS inventory edit manifest

- `bind`: existing wrapper evidence `.flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native bind during onboarding`. Rename/update inventory row to `WRAP-ALIAS` with verification status `RECLASSIFIED-WRAP-ALIAS`; callsite count in 7p45b was a false zero caused by indirect wrapper invocation.
- `completion`: existing wrapper evidence `.flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native completion during onboarding`. Rename/update inventory row to `WRAP-ALIAS` with verification status `RECLASSIFIED-WRAP-ALIAS`; callsite count in 7p45b was a false zero caused by indirect wrapper invocation.
- `init`: existing wrapper evidence `.flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native init during onboarding`. Rename/update inventory row to `WRAP-ALIAS` with verification status `RECLASSIFIED-WRAP-ALIAS`; callsite count in 7p45b was a false zero caused by indirect wrapper invocation.
- `rollback`: existing wrapper evidence `.flywheel/scripts/ntm-checkpoint-rollback-guard.sh:18-43 defines rollback receipt schema and authorized rollback validation operations`. Rename/update inventory row to `WRAP-ALIAS` with verification status `RECLASSIFIED-WRAP-ALIAS`; callsite count in 7p45b was a false zero caused by indirect wrapper invocation.
- `shell`: existing wrapper evidence `.flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native shell during onboarding`. Rename/update inventory row to `WRAP-ALIAS` with verification status `RECLASSIFIED-WRAP-ALIAS`; callsite count in 7p45b was a false zero caused by indirect wrapper invocation.
- `spawn`: existing wrapper evidence `.flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native spawn during onboarding`. Rename/update inventory row to `WRAP-ALIAS` with verification status `RECLASSIFIED-WRAP-ALIAS`; callsite count in 7p45b was a false zero caused by indirect wrapper invocation.

## Section 6 - RECLASSIFY-ISSUE Jeff-issue manifest

### `controller`

- Proposed title: `Clarify ntm controller automation contract for noninteractive orchestration`
- Repro outline: in a throwaway repo, run `ntm controller --help`, then attempt the relevant dry-run/JSON/status path needed for automated orchestration; compare behavior to documented flywheel guard/status requirements.
- File:line citations: `~/Developer/ntm/internal/cli/controller.go:132-170 defines controller command; root robot flags at root.go:3334-3337`.
- Anonymization check: proposed body should use `/path/to/repo`, `<session>`, and `<work-item-id>` only; no local user paths, no project names, no bead IDs.

### `guards`

- Proposed title: `Clarify ntm guards automation contract for noninteractive orchestration`
- Repro outline: in a throwaway repo, run `ntm guards --help`, then attempt the relevant dry-run/JSON/status path needed for automated orchestration; compare behavior to documented flywheel guard/status requirements.
- File:line citations: `~/Developer/ntm/internal/cli/guards.go:21-50 defines Agent Mail guard install surface`.
- Anonymization check: proposed body should use `/path/to/repo`, `<session>`, and `<work-item-id>` only; no local user paths, no project names, no bead IDs.

### `hooks`

- Proposed title: `Clarify ntm hooks automation contract for noninteractive orchestration`
- Repro outline: in a throwaway repo, run `ntm hooks --help`, then attempt the relevant dry-run/JSON/status path needed for automated orchestration; compare behavior to documented flywheel guard/status requirements.
- File:line citations: `~/Developer/ntm/internal/cli/hooks.go:19-20 and :205 define hook management/status`.
- Anonymization check: proposed body should use `/path/to/repo`, `<session>`, and `<work-item-id>` only; no local user paths, no project names, no bead IDs.

### `repo`

- Proposed title: `Clarify ntm repo automation contract for noninteractive orchestration`
- Repro outline: in a throwaway repo, run `ntm repo --help`, then attempt the relevant dry-run/JSON/status path needed for automated orchestration; compare behavior to documented flywheel guard/status requirements.
- File:line citations: `~/Developer/ntm/internal/cli/repo.go:13-24 and internal/tools/ru.go:13-21 show repo passes through RU adapter`.
- Anonymization check: proposed body should use `/path/to/repo`, `<session>`, and `<work-item-id>` only; no local user paths, no project names, no bead IDs.

### `support-bundle`

- Proposed title: `Clarify ntm support-bundle automation contract for noninteractive orchestration`
- Repro outline: in a throwaway repo, run `ntm support-bundle --help`, then attempt the relevant dry-run/JSON/status path needed for automated orchestration; compare behavior to documented flywheel guard/status requirements.
- File:line citations: `~/Developer/ntm/internal/cli/support_bundle.go:52-71 defines bundle command; root.go:3182-3188 exposes robot bundle flags`.
- Anonymization check: proposed body should use `/path/to/repo`, `<session>`, and `<work-item-id>` only; no local user paths, no project names, no bead IDs.

## Section 7 - Inventory column proposal

```diff
-| # | NTM surface | What it does | Decision | Action |
-|---|---|---|---|---|
+| # | NTM surface | What it does | Decision | Verification status | Action |
+|---|---|---|---|---|---|
+| ... | `ntm adopt` | ... | ... | RECLASSIFIED-EXCLUDED | Adopting externally-created sessions is orthogonal to flywheel steady-state orchestration; flywheel creates, spawns, dispatches, and respawns sessions under known contracts. |
+| ... | `ntm agents` | ... | ... | WIRE-IT-QUEUED | Agent capability metadata is directly relevant to dispatch quality and capacity routing. Current worker identity/capability handling remains scattered, so this should become a native data-source wire-in. |
+| ... | `ntm analytics` | ... | ... | WIRE-IT-QUEUED | Fleet analytics are relevant to uptime and regression detection. Current reports still aggregate locally, so native analytics should become a measured rollup source. |
+| ... | `ntm attach` | ... | ... | RECLASSIFIED-EXCLUDED | Attach is an operator-interactive verb, not an automation primitive. Flywheel panes should be controlled via send/copy/health rather than interactive attachment. |
+| ... | `ntm bind` | ... | ... | RECLASSIFIED-WRAP-ALIAS | This is already consumed indirectly by the onboarding wrapper; the 7p45b grep missed `run_native ... bind --show` because the surface is passed as an argument, not as literal `ntm bind`. |
+| ... | `ntm cass` | ... | ... | WIRE-IT-QUEUED | CASS search is mission-relevant because memory/context lookup prevents substrate amnesia. The inventory claim should become a measured `ntm cass`/`ntm search` replacement path. |
+| ... | `ntm changes` | ... | ... | WIRE-IT-QUEUED | File-change attribution is relevant to multi-agent collision control. Current flywheel path and reservation checks are still local, so wire native changes as an input before reclassification. |
+| ... | `ntm completion` | ... | ... | RECLASSIFIED-WRAP-ALIAS | Already wired through onboarding via `run_native ... completion`; the direct grep missed the wrapper call shape. |
+| ... | `ntm config` | ... | ... | WIRE-IT-QUEUED | Configuration state is mission-relevant because NTM drift silently breaks orchestration. Wire `ntm config` into doctor/validation rather than leaving TOML assumptions unmeasured. |
+| ... | `ntm conflicts` | ... | ... | WIRE-IT-QUEUED | File conflicts are a real shared-surface risk in the fleet. Wire native conflict reporting into L107/dispatch verification. |
+| ... | `ntm controller` | ... | ... | RECLASSIFIED-ISSUE | Potentially useful, but the controller spawn contract needs Jeff clarification before flywheel can delegate pane-1 authority safely. |
+| ... | `ntm create` | ... | ... | WIRE-IT-QUEUED | Session creation is relevant, but flywheel currently prefers `spawn` and onboarding wrappers. Add a focused create-vs-spawn disposition bead before treating USE as verified. |
+| ... | `ntm doctor` | ... | ... | WIRE-IT-QUEUED | Native NTM doctor belongs in flywheel doctor as a sibling substrate probe. Zero callsites means this is a high-priority wire-in gap. |
+| ... | `ntm ensemble` | ... | ... | RECLASSIFIED-EXCLUDED | Reasoning ensembles are a product/analysis feature, not continuous orchestrator uptime substrate. No current hand-rolled equivalent justifies keeping it as USE. |
+| ... | `ntm extract` | ... | ... | WIRE-IT-QUEUED | Extracting code blocks from panes is useful for recovery and evidence capture. Wire it where worker-stall and evidence-pack flows currently parse pane text manually. |
+| ... | `ntm get-all-session-text` | ... | ... | WIRE-IT-QUEUED | Full-session text capture maps to tail/audit pack generation. Wire it as a replacement candidate for per-pane capture aggregation. |
+| ... | `ntm git` | ... | ... | WIRE-IT-QUEUED | Git coordination is mission-relevant, but must be scoped behind existing destructive-command and br discipline. Wire as read/diagnostic first. |
+| ... | `ntm grep` | ... | ... | WIRE-IT-QUEUED | Pane-output grep is high-leverage for frozen-pane, callback, and stuck-template detectors. Zero callsites means the inventory claim is still aspirational. |
+| ... | `ntm guards` | ... | ... | RECLASSIFIED-ISSUE | Useful, but native Agent Mail guard parity with flywheel L107 and local hook contracts is not proven. Needs Jeff clarification before replacing local guards. |
+| ... | `ntm hooks` | ... | ... | RECLASSIFIED-ISSUE | Useful, but native hook installation must be compared against flywheel doctrine gates before wiring. Treat as upstream/contract issue, not direct USE. |
+| ... | `ntm init` | ... | ... | RECLASSIFIED-WRAP-ALIAS | Already wired through onboarding via `run_native ... init`; the audit missed the indirect call. |
+| ... | `ntm kernel` | ... | ... | RECLASSIFIED-EXCLUDED | Kernel registry inspection is an NTM developer surface. Flywheel can consume exported templates/context without making kernel a runtime dependency. |
+| ... | `ntm kill` | ... | ... | RECLASSIFIED-EXCLUDED | Direct session kill is intentionally not a flywheel automation primitive; recovery uses respawn, wait, health, and explicit dangerous-drill gates. |
+| ... | `ntm level` | ... | ... | RECLASSIFIED-EXCLUDED | CLI proficiency tier is human/operator education. It does not advance continuous orchestrator uptime once onboarding is established. |
+| ... | `ntm memory` | ... | ... | WIRE-IT-QUEUED | CASS memory lookup is relevant to substrate-amnesia prevention. Wire native memory into existing CASS/memory probes or reclassify after a measured no-fit receipt. |
+| ... | `ntm models` | ... | ... | RECLASSIFIED-EXCLUDED | Ollama model management is local model hygiene, not a current flywheel orchestration primitive. No direct hand-rolled NTM equivalent exists in today's plan. |
+| ... | `ntm modes` | ... | ... | RECLASSIFIED-EXCLUDED | Reasoning modes are advisory/operator knowledge, not fleet substrate. Keep out of the direct USE set unless a future dispatcher selects modes programmatically. |
+| ... | `ntm openapi` | ... | ... | RECLASSIFIED-EXCLUDED | OpenAPI generation is a service/API exposure concern. Flywheel does not currently operate an NTM REST API contract that needs this surface. |
+| ... | `ntm overlay` | ... | ... | RECLASSIFIED-EXCLUDED | Overlay is interactive UI. It can be documented for operators but should not be counted as automated wire-in. |
+| ... | `ntm personas` | ... | ... | RECLASSIFIED-EXCLUDED | NTM personas are agent-prompt personas, while flywheel's current profile logic is CAAM/account and worker identity. This row conflates concepts and should leave direct USE. |
+| ... | `ntm profiles` | ... | ... | WIRE-IT-QUEUED | NTM agent profiles can reduce hardcoded agent capability assumptions. Wire them into onboarding/dispatch identity checks before declaring verified USE. |
+| ... | `ntm plugins` | ... | ... | RECLASSIFIED-EXCLUDED | Plugin management is extension administration, not flywheel uptime substrate. No current plugin lifecycle work is in scope. |
+| ... | `ntm profile` | ... | ... | WIRE-IT-QUEUED | Named spawn profiles can replace hardcoded session shape. Wire this into onboarding as a durable spawn-profile path. |
+| ... | `ntm quick` | ... | ... | RECLASSIFIED-EXCLUDED | Quick creates a new project skeleton; flywheel-onboard is the richer repo-local onboarding contract, so direct quick use is intentionally out of scope. |
+| ... | `ntm recipes` | ... | ... | WIRE-IT-QUEUED | Recipes can replace ad hoc session bootstrap presets. Wire into onboarding/status docs or reclassify after a fixture proves no fit. |
+| ... | `ntm repo` | ... | ... | RECLASSIFIED-ISSUE | Repo pass-through delegates to external tooling; flywheel needs clearer dry-run/status/error contracts before relying on it. |
+| ... | `ntm resume` | ... | ... | WIRE-IT-QUEUED | Resume maps to handoff/recovery after compaction. Wire it into handoff closeout validation. |
+| ... | `ntm rollback` | ... | ... | RECLASSIFIED-WRAP-ALIAS | Existing rollback wrapper is intentional flywheel doctrine: native checkpoint/rollback concepts are wrapped with dirty-worktree and receipt gates. |
+| ... | `ntm save` | ... | ... | WIRE-IT-QUEUED | Saving pane output is relevant to evidence packs and support bundles. Wire it as a replacement for hand-rolled capture paths. |
+| ... | `ntm scale` | ... | ... | WIRE-IT-QUEUED | Agent scaling maps to capacity management. Wire read-only/dry-run scale recommendations before allowing mutation. |
+| ... | `ntm scan` | ... | ... | WIRE-IT-QUEUED | UBS scanning maps to validation and compliance. Wire native scan into validation matrix rather than relying on local script-level scan words. |
+| ... | `ntm search` | ... | ... | WIRE-IT-QUEUED | Search past sessions is directly relevant to incident replay and CASS lookup. Wire native search into memory/research flows. |
+| ... | `ntm session-templates` | ... | ... | WIRE-IT-QUEUED | Session templates can replace hardcoded multi-agent shapes. Wire into onboarding after profile/recipes decisions settle. |
+| ... | `ntm shell` | ... | ... | RECLASSIFIED-WRAP-ALIAS | Already wired through onboarding via `run_native ... shell`; the audit missed indirect call shape. |
+| ... | `ntm spawn` | ... | ... | RECLASSIFIED-WRAP-ALIAS | Already wired through onboarding via `run_native ... spawn`; the audit missed indirect call shape. |
+| ... | `ntm status` | ... | ... | WIRE-IT-QUEUED | Detailed session status is a core orchestration signal. Wire into coordinator/status probes after #124-related daemon ambiguity is isolated. |
+| ... | `ntm support-bundle` | ... | ... | RECLASSIFIED-ISSUE | Useful for diagnostics, but bundle contents and redaction defaults need an explicit contract before flywheel automates archives. |
+| ... | `ntm view` | ... | ... | RECLASSIFIED-EXCLUDED | View is an interactive pane inspection surface. Automation should use copy/logs/save/status instead. |
+| ... | `ntm watch` | ... | ... | WIRE-IT-QUEUED | Watch is high-leverage for replacing polling and validating work-started states. Wire after the #124 watch/wait semantics blocker is resolved or guarded. |
+| ... | `ntm workflows` | ... | ... | WIRE-IT-QUEUED | Workflow templates map to multi-bead orchestration patterns. Wire only as read-only recipe discovery first. |
```

## Audit receipts

- `socraticode_queries=500` from `/tmp/flywheel-a2lff-evidence.json`.
- Every row has a non-empty evidence field containing NTM help output plus a Socraticode top hit; WRAP-ALIAS rows add wrapper citations and ISSUE rows add ntm source citations.
- No beads, inventory edits, or Jeff issues were created by this dispatch.
