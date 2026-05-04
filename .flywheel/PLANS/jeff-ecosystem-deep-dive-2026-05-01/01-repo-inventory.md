# Jeff Emanuel Ecosystem — Repo Inventory

**Snapshot:** 2026-05-01
**Scope:** 34 agentic-infra-relevant repos (filtered from 173 total non-archived non-fork repos)
**Source:** `gh api users/Dicklesworthstone/repos` enumerated 2026-05-01T17:30Z

---

## Hot zone (>5 commits last 30d)

## agentic_coding_flywheel_setup
- **Purpose:** Bootstraps a fresh Ubuntu VPS into a complete multi-agent AI development environment in 30 minutes: coding agents, session management, safety tools, and coordination infrastructure
- **Activity:** 100 commits last 30d, last push 2026-05-01, 1440★, TypeScript
- **Issues:** 0 open, 30 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** ADOPTED

## asupersync
- **Purpose:** Async runtime for Rust where correctness is structural: region-owned tasks, cancel-correct protocols, capability-gated effects, and deterministic replay testing
- **Activity:** 100 commits last 30d, last push 2026-05-01, 156★, Rust
- **Issues:** 0 open, 2 closed last 30d
- **Local checkout:** YES (~/Developer/asupersync)
- **Already tracked:** NO
- **Our integration status:** ADOPTED-TRANSITIVELY

## beads_rust
- **Purpose:** Fast Rust port of Steve Yegge's beads: local-first, non-invasive issue tracker storing tasks in SQLite with JSONL export for git collaboration
- **Activity:** 100 commits last 30d, last push 2026-05-01, 862★, Rust
- **Issues:** 0 open, 48 closed last 30d
- **Local checkout:** YES (~/Developer/beads_rust)
- **Already tracked:** YES
- **Our integration status:** ADOPTED

## coding_agent_session_search
- **Purpose:** Unified TUI and CLI to index and search your local coding agent session history across 11+ providers (Codex, Claude, Gemini, Cursor, Aider, etc.)
- **Activity:** 100 commits last 30d, last push 2026-05-01, 725★, Rust
- **Issues:** 1 open, 59 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** EVALUATING

## destructive_command_guard
- **Purpose:** The Destructive Command Guard (dcg) is for blocking dangerous git and shell commands from being executed by agents.
- **Activity:** 100 commits last 30d, last push 2026-05-01, 956★, Rust
- **Issues:** 0 open, 8 closed last 30d
- **Local checkout:** YES (~/Developer/destructive_command_guard)
- **Already tracked:** YES
- **Our integration status:** ADOPTED

## flywheel_connectors
- **Purpose:** Mesh-native protocol and Rust connector library for secure AI agent integration with external services: Twitter, Linear, Stripe, Discord, Gmail, GitHub, and more
- **Activity:** 100 commits last 30d, last push 2026-04-30, 74★, Rust
- **Issues:** 0 open, 1 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## frankensqlite
- **Purpose:** Independent ground-up Rust reimplementation of SQLite with concurrent writers and information-theoretic durability
- **Activity:** 100 commits last 30d, last push 2026-05-01, 158★, Rust
- **Issues:** 4 open, 23 closed last 30d
- **Local checkout:** YES (~/Developer/frankensqlite)
- **Already tracked:** YES
- **Our integration status:** ADOPTED-TRANSITIVELY

## frankentui
- **Purpose:** Minimal, high-performance terminal UI kernel with diff-based rendering, inline mode, and RAII terminal cleanup
- **Activity:** 100 commits last 30d, last push 2026-04-29, 236★, Rust
- **Issues:** 0 open, 6 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** NOT-RELEVANT-NOW

## ntm
- **Purpose:** Named Tmux Manager: spawn, tile, and coordinate multiple AI coding agents (Claude, Codex, Gemini) across tmux panes with a TUI command palette
- **Activity:** 100 commits last 30d, last push 2026-05-01, 266★, Go
- **Issues:** 1 open, 7 closed last 30d
- **Local checkout:** YES (~/Developer/ntm)
- **Already tracked:** YES
- **Our integration status:** ADOPTED

## pi_agent_rust
- **Purpose:** High-performance AI coding agent CLI written in Rust with zero unsafe code
- **Activity:** 100 commits last 30d, last push 2026-05-01, 826★, Rust
- **Issues:** 0 open, 16 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** EVALUATING

## mcp_agent_mail
- **Purpose:** Asynchronous coordination layer for AI coding agents: identities, inboxes, searchable threads, and advisory file leases over FastMCP + Git + SQLite
- **Activity:** 68 commits last 30d, last push 2026-05-01, 1912★, Python
- **Issues:** 0 open, 21 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** ADOPTED

## franken_agent_detection
- **Purpose:** Deterministic, local filesystem-based detection of installed coding-agent connectors for Rust tooling.
- **Activity:** 48 commits last 30d, last push 2026-04-29, 8★, Rust
- **Issues:** 0 open, 2 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** UNKNOWN

## automated_flywheel_setup_checker
- **Purpose:** Automated testing framework for ACFS installer scripts — runs all 41 installers in isolated Docker containers with error classification, parallel execution, and Claude-powered auto-remediation
- **Activity:** 37 commits last 30d, last push 2026-05-01, 2★, Rust
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** NOT-RELEVANT-NOW

## cass_memory_system
- **Purpose:** Procedural memory for AI coding agents: transforms scattered session history into persistent, cross-agent memory so every agent learns from every other
- **Activity:** 34 commits last 30d, last push 2026-05-01, 348★, TypeScript
- **Issues:** 0 open, 12 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** ADOPTED

## storage_ballast_helper
- **Purpose:** Cross-platform Rust daemon that prevents disk-full incidents for AI coding workloads using predictive pressure control, safe artifact cleanup, and multi-volume ballast pools.
- **Activity:** 31 commits last 30d, last push 2026-05-01, 10★, Rust
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## doodlestein_self_releaser
- **Purpose:** Local release tool that reuses your GitHub Actions workflow YAML to build via nektos/act when CI queues are throttled, then uploads artifacts to GitHub Releases
- **Activity:** 26 commits last 30d, last push 2026-04-30, 10★, Shell
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** NOT-RELEVANT-NOW

## beads_viewer
- **Purpose:** Graph-aware TUI for the Beads issue tracker: PageRank, critical path, kanban, dependency DAG visualization, and robot-mode JSON API
- **Activity:** 16 commits last 30d, last push 2026-04-29, 1489★, Go
- **Issues:** 0 open, 7 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** ADOPTED

## process_triage
- **Purpose:** Bayesian process classifier that detects abandoned/zombie processes and recommends safe cleanup actions
- **Activity:** 16 commits last 30d, last push 2026-04-29, 24★, Rust
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** YES (~/Developer/process_triage)
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## meta_skill
- **Purpose:** Local-first skill management platform for AI coding agents: dual SQLite+Git persistence, semantic search, bandit-optimized suggestions, and MCP integration
- **Activity:** 10 commits last 30d, last push 2026-05-01, 159★, Rust
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** UNKNOWN

## coding_agent_usage_tracker
- **Purpose:** Single CLI to monitor LLM provider usage across Codex, Claude, Gemini, Cursor, and Copilot: remaining quota, rate limits, and cost tracking in one place
- **Activity:** 9 commits last 30d, last push 2026-04-22, 45★, Rust
- **Issues:** 0 open, 3 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## slb
- **Purpose:** Two-person rule CLI for AI coding agents: peer review and approval required before running potentially destructive commands
- **Activity:** 9 commits last 30d, last push 2026-04-27, 69★, Go
- **Issues:** 0 open, 4 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** UNKNOWN

## cross_agent_session_resumer
- **Purpose:** Resume AI coding sessions across providers: converts Codex, Claude, Gemini, and other session formats through a canonical IR so you can pick up where you left off in any tool
- **Activity:** 8 commits last 30d, last push 2026-04-29, 71★, Rust
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## vibe_cockpit
- **Purpose:** Real-time monitoring dashboard for AI coding agent fleets: session health, output streaming, and observability across Claude, Codex, and Gemini
- **Activity:** 7 commits last 30d, last push 2026-04-30, 20★, Rust
- **Issues:** 0 open, 3 closed last 30d
- **Local checkout:** YES (~/Developer/vibe-cockpit)
- **Already tracked:** NO
- **Our integration status:** ADOPTED

---

## Cool zone (≤5 commits last 30d but in our agentic-infra scope)

## coding_agent_account_manager
- **Purpose:** Sub-100ms auth switching for AI coding CLIs (Claude Code, Codex, Gemini): swap subscription accounts instantly when you hit usage limits
- **Activity:** 5 commits last 30d, last push 2026-04-26, 115★, Go
- **Issues:** 0 open, 1 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## rano
- **Purpose:** Network observer that tracks outbound connections from AI CLI processes (Claude Code, Codex, Gemini), attributing sockets to providers in real time with SQLite logging
- **Activity:** 5 commits last 30d, last push 2026-04-28, 27★, Rust
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** YES (~/Developer/rano)
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## repo_updater
- **Purpose:** Pure-bash CLI for keeping hundreds of GitHub repos in sync: parallel clone/pull, conflict detection, JSON output, and meaningful exit codes for CI
- **Activity:** 4 commits last 30d, last push 2026-04-25, 88★, Shell
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** ADOPTED

## agent_settings_backup_script
- **Purpose:** Git-versioned backup tool for AI coding agent config folders (Claude Code, Cursor, Codex, etc.) with size-based rotation and easy restoration
- **Activity:** 1 commits last 30d, last push 2026-04-29, 27★, Shell
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** UNKNOWN

## brenner_bot
- **Purpose:** Harness the scientific methods of Sydney Brenner using AI Agents
- **Activity:** 1 commits last 30d, last push 2026-04-01, 77★, TypeScript
- **Issues:** 0 open, 1 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## post_compact_reminder
- **Purpose:** Claude Code hook that detects context compaction and injects a reminder to re-read AGENTS.md, preventing post-compaction rule amnesia in long sessions
- **Activity:** 1 commits last 30d, last push 2026-04-29, 43★, Shell
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## agent_flywheel_clawdbot_skills_and_integrations
- **Purpose:** Clawdbot skills for agentic coding workflows - ACFS stack, cloud CLIs, and dev tools
- **Activity:** 0 commits last 30d, last push 2026-03-27, 63★, Shell
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** UNKNOWN

## claude_code_agent_farm
- **Purpose:** Orchestration framework for running 20+ Claude Code agents in parallel: automated bug fixing, best-practices sweeps, lock-based coordination, and real-time tmux monitoring
- **Activity:** 0 commits last 30d, last push 2026-04-06, 802★, Shell
- **Issues:** 0 open, 1 closed last 30d
- **Local checkout:** NO
- **Already tracked:** YES
- **Our integration status:** NOT-RELEVANT-NOW

## cloud_benchmarker
- **Purpose:** Cloud Benchmarker automates performance testing of cloud instances, offering insightful charts and tracking over time.
- **Activity:** 0 commits last 30d, last push 2026-03-22, 37★, Python
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** EVALUATING

## curl_bash_one_liners_for_flywheel_tools
- **Purpose:** Copy-paste curl|bash one-liners to install every tool in the Agent Flywheel ecosystem: 23+ CLIs for AI agent orchestration, memory, security, and development
- **Activity:** 0 commits last 30d, last push 2026-03-22, 17★, ?
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** UNKNOWN

## flywheel_gateway
- **Purpose:** SDK-first orchestration platform for managing AI coding agent fleets: BYOA key rotation, real-time WebSocket dashboard, DCG integration, and cross-agent search
- **Activity:** 0 commits last 30d, last push 2026-03-23, 20★, TypeScript
- **Issues:** 0 open, 0 closed last 30d
- **Local checkout:** NO
- **Already tracked:** NO
- **Our integration status:** UNKNOWN


---

## Summary

- **Total repos in scope:** 34 (filtered from 173 non-archived non-fork)
- **Total open issues across these 34 repos:** 6
- **Total closed issues since 2026-04-01:** 255
- **Total commits last 30d:** 1336 (avg 39/repo)
- **Hotspots (>5 commits last 30d):** 23 repos

### Hotspot list (sorted by commit volume, top 20)
  - **agentic_coding_flywheel_setup** — 100 commits, 0 open issues
  - **asupersync** — 100 commits, 0 open issues
  - **beads_rust** — 100 commits, 0 open issues
  - **coding_agent_session_search** — 100 commits, 1 open issues
  - **destructive_command_guard** — 100 commits, 0 open issues
  - **flywheel_connectors** — 100 commits, 0 open issues
  - **frankensqlite** — 100 commits, 4 open issues
  - **frankentui** — 100 commits, 0 open issues
  - **ntm** — 100 commits, 1 open issues
  - **pi_agent_rust** — 100 commits, 0 open issues
  - **mcp_agent_mail** — 68 commits, 0 open issues
  - **franken_agent_detection** — 48 commits, 0 open issues
  - **automated_flywheel_setup_checker** — 37 commits, 0 open issues
  - **cass_memory_system** — 34 commits, 0 open issues
  - **storage_ballast_helper** — 31 commits, 0 open issues
  - **doodlestein_self_releaser** — 26 commits, 0 open issues
  - **beads_viewer** — 16 commits, 0 open issues
  - **process_triage** — 16 commits, 0 open issues
  - **meta_skill** — 10 commits, 0 open issues
  - **coding_agent_usage_tracker** — 9 commits, 0 open issues

### Adoption coverage
- **ADOPTED (in production or transitively):** 11/34 (32%)
- **EVALUATING:** 12/34
- **UNKNOWN (not yet assessed):** 7/34 — fertile ground for `/jeff-convergence-audit`
- **NOT-RELEVANT-NOW:** 4/34

### Cross-reference vs `dicklesworthstone-stack` skill INVENTORY

- INVENTORY snapshot dated 2026-04-27 covers 25 repos, ranked by stars + recent updates
- INVENTORY's 5 ADOPT picks all in our hotspot zone: `mcp_agent_mail`, `agentic_coding_flywheel_setup`, `beads_viewer`, `destructive_command_guard`, `cass_memory_system`
- INVENTORY classifies `frankensqlite` as SKIP, but `vibe_cockpit` pulls it transitively (mid-migration); we also installed `beads_rust` which depends on it
- INVENTORY classifies `beads_rust` as SKIP (engine-only) — we have diverged: we are heavy users of `br` CLI in production
- **9 repos in our scope are missing from INVENTORY entirely** (UNKNOWN status above) — these are the audit blind spots

### Local checkouts present (8 of 34)

  - `ntm` → `~/Developer/ntm`
  - `beads_rust` → `~/Developer/beads_rust`
  - `vibe_cockpit` → `~/Developer/vibe-cockpit`
  - `frankensqlite` → `~/Developer/frankensqlite`
  - `asupersync` → `~/Developer/asupersync`
  - `destructive_command_guard` → `~/Developer/destructive_command_guard`
  - `rano` → `~/Developer/rano`
  - `process_triage` → `~/Developer/process_triage`

### Open issue density signal

- **Only 6 open issues across 34 active hotspot repos.**
- This is extraordinarily low for an ecosystem this active.
- He closed **255** issues in the last 30 days across this set.
- **Implication:** any issue we file has high signal value because his queue is short and his close rate is high.

### Triangulation hypothesis: where the gaps live

Based on inventory + local install state + recent trauma log:

1. **Multi-repo discovery gap (validated):** vc_collect's beads collector finds 0 of our 8+ local `.beads/` repos. Filed-ready.
2. **Config schema/loader drift (validated):** `ntm coordinator status` ignores TOML; filed today as ntm#111.
3. **Hidden integration surfaces:** repos in UNKNOWN status (storage_ballast_helper, slb, flywheel_connectors, flywheel_gateway) might already solve problems we've manually papered over.
4. **Skill catalog drift:** dicklesworthstone-stack INVENTORY is 4 days stale; INVENTORY says 25 repos but we now have 34 in scope as candidates.

### Output for /jeff-convergence-audit

Feed `/jeff-convergence-audit` the following ranked candidates for deep dive:

**Tier 0 (validated gaps, ready to file once audited):**
- ntm#111 *(filed; await Jeff response)*
- vibe_cockpit beads-collector multi-repo discovery gap

**Tier 1 (UNKNOWN repos to research before audit):**
- `flywheel_connectors` — cross-tool integration glue
- `flywheel_gateway` — SDK-first orchestration platform
- `slb` — short name, find purpose
- `storage_ballast_helper` — storage hygiene
- `meta_skill` — skill-system primitive
- `franken_agent_detection` — anti-frankenagent surface
- `cross_agent_session_resumer` — session continuity layer
- `coding_agent_account_manager` — multi-account fleet management
- `agent_flywheel_clawdbot_skills_and_integrations` — adjacent skill ecosystem

**Tier 2 (EVALUATING repos, partially adopted):**
- `pi_agent_rust` — could replace orchestrator pane workloads
- `coding_agent_session_search` — adjacent to cass
- `cloud_benchmarker` — already enabled in vc.toml as collector
- `process_triage` — already a vc collector
- `rano` — already a vc collector, low integration depth
- `cross_agent_session_resumer`
- `brenner_bot` — taste-doctrine ratchet

**Tier 3 (low-priority intentional skips):**
- `frankentui`, `claude_code_agent_farm`, `automated_flywheel_setup_checker`, `doodlestein_self_releaser`
