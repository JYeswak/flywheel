# Jeff Corpus Doctrine Cluster — Phase 1
bead: flywheel-w3pr
generated_at: 2026-05-04T02:20:00Z
scope: first 200 lines of AGENTS.md, CLAUDE.md, and README.md across manifest repos

## Corpus Summary
- Manifest repos scanned: 177
- Repos with local paths present: 177
- Doctrine/readme docs read: 249
- AGENTS.md docs: 81
- CLAUDE.md docs: 1
- README.md docs: 167

## Cluster Index
- `testing-patterns`: Testing patterns and executable verification (12 cited docs)
- `doctor-health-repair-triad`: Doctor / health / repair triad (12 cited docs)
- `idempotency-and-dry-run`: Idempotency, dry-run, and fail-closed mutation posture (12 cited docs)
- `ipc-and-transport-contracts`: IPC, transport, and machine envelope contracts (12 cited docs)
- `error-handling-and-recovery`: Error handling, recovery, and escalation taxonomy (12 cited docs)
- `schema-versioning-and-migrations`: Schema versioning, migrations, and compatibility (12 cited docs)
- `callback-and-receipt-envelope`: Callback, receipt, and DONE/BLOCKED envelope shape (12 cited docs)
- `append-only-audit-and-lineage`: Append-only audit logs, lineage, and evidence chains (12 cited docs)

## Named Clusters

### testing-patterns: Testing patterns and executable verification
Preliminary pattern: Jeff repos repeatedly turn claims into runnable gates: unit/integration tests, fixtures, conformance reports, golden samples, and reproducibility metadata.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `agent_settings_backup_script` | `AGENTS.md` | L15: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L110: # Check for ShellCheck warnings (test files) | fixture, fixtures, test, verification |
| `markdown_web_browser` | `AGENTS.md` | L15: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L62: / `playwright` / Browser automation (Chrome for Testing channel, pinned) / | fixture, fixtures, pytest, test |
| `rich_rust` | `AGENTS.md` | L15: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L144: ## Testing | cargo test, conformance, fixture, fixtures, golden, property, proptest, test |
| `toon_rust` | `AGENTS.md` | L15: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L75: / `tempfile` / Temporary files for test isolation / | cargo test, conformance, fixture, fixtures, golden, property, proptest, test |
| `coding_agent_usage_tracker` | `AGENTS.md` | L15: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L55: - **Unsafe code:** Denied (`#![deny(unsafe_code)]`) — tests may use `#[allow(unsafe_code)]` for env var manipulation | cargo test, fixture, fixtures, test |
| `opentui_rust` | `AGENTS.md` | L15: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L70: / `proptest` / Property-based testing (dev-dependency) / | cargo test, conformance, golden, property, proptest, test |
| `beads_rust` | `AGENTS.md` | L17: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L145: ## Testing | cargo test, conformance, fixture, fixtures, property, proptest, test |
| `frankenlibc` | `AGENTS.md` | L15: **YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION.** Even a new file that you yourself created, such as a test code file. You have a horrible track record of dele; L58: This project leverages companion crates for build/test tooling roles only. These are NOT runtime libc dependencies: | cargo test, conformance, fixture, fixtures, test, verification |

Flywheel relevance: make dispatch acceptance gates runnable and require evidence receipts instead of narrative claims.

### doctor-health-repair-triad: Doctor / health / repair triad
Preliminary pattern: Operational tools expose state inspection, structured health, and dry-run/apply repair paths rather than prose-only troubleshooting.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `automated_flywheel_setup_checker` | `README.md` | L1: # Automated Flywheel Setup Checker; L5: [![CI](https://img.shields.io/github/actions/workflow/status/Dicklesworthstone/automated_flywheel_setup_checker/ci.yml?style=for-the-badge&label=CI)](https://github.com/Dickleswort | check, fix, health |
| `coding_agent_session_search` | `README.md` | L53: # 1) First run builds the canonical archive. Later health checks report; L55: cass health --json // cass index --full | check, diagnostic, diagnostics, doctor, fix, health, recover, recovery |
| `agentic_coding_flywheel_setup` | `AGENTS.md` | L36: - **Never reference `master` in code or docs** — if you see `master` anywhere, it's a bug that needs fixing; L54: - **Linting:** `shellcheck` for all `.sh` files | check, fix |
| `frankenfs` | `README.md` | L28: **The problem:** Linux filesystems are trapped in kernel space. ext4 is 30 years old with a global journal lock (JBD2) that serializes all writes. btrfs has better internals but re; L35: / **RaptorQ self-healing** / Fountain-coded repair symbols (RFC 6330), Bayesian durability autopilot, adaptive refresh (age + block-count hybrid trigger), scrub-and-recover pipelin | check, fix, recover, recovery, repair |
| `flywheel_connectors` | `AGENTS.md` | L17: - `am doctor fix` / `am doctor repair` / `am doctor reconstruct`; L22: **If `am` commands fail or the API is unreachable:** retry once after a few seconds, then proceed with your work WITHOUT agent-mail. Do NOT attempt to diagnose, repair, or restart  | check, doctor, fix, repair |
| `frankenfs` | `AGENTS.md` | L36: - **Never reference `master` in code or docs** — if you see `master` anywhere, it's a bug that needs fixing; L76: / `ftui` (frankentui) / Terminal UX for CLI diagnostics and tooling / | check, diagnostic, diagnostics, fix |
| `frankenmermaid` | `README.md` | L9: / CLI validate command with structured diagnostics / Implemented / 1 evidence refs /; L21: *80+ interactive examples, live editor, style studio, diagnostics panel, and determinism checker* | check, diagnostic, diagnostics, recover, recovery |
| `frankenterm` | `README.md` | L7: <!-- ft-jjvxg + ft-xl2kc: Reality-check live demos.; L14: search recoveries, and real mission orchestration. Substrate | check, diagnostic, diagnostics, doctor, health, recover, recovery |

Flywheel relevance: every new operational substrate should expose `doctor --json`, health status, and dry-run repair before autonomous mutation.

### idempotency-and-dry-run: Idempotency, dry-run, and fail-closed mutation posture
Preliminary pattern: Mutating operations are expected to be repeatable, previewable, atomic, and explicit about destructive or irreversible effects.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `agent_settings_backup_script` | `README.md` | L1: # Agent Settings Backup (asb); L4: <img src="asb_illustration.webp" alt="asb - Smart backup tool for AI coding agent configurations"> | backup, dry-run |
| `agent_settings_backup_script` | `AGENTS.md` | L1: # AGENTS.md — agent_settings_backup_script; L25: 3. **Safer alternatives first:** When cleanup or rollbacks are needed, request permission to use non-destructive options (`git status`, `git diff`, `git stash`, copying to backups) | backup, dry-run |
| `system_resource_protection_script` | `README.md` | L30: Everything is idempotent, safe to re-run, and reversible via `--uninstall`.; L41: bash install.sh --plan    # dry-run | backup, dry-run, idempotent, safe to re-run |
| `bakery_algorithm` | `README.md` | L27: ## Unique Feature: Non-Atomicity; L28: The Bakery Algorithm's unique feature is its ability to ensure mutual exclusion in concurrent programming without requiring atomic reads and writes. This makes it powerful, especia | atomic |
| `coding_agent_session_search` | `README.md` | L85: - SQLite is the source of truth for indexed conversations and messages. All derived assets (lexical index, semantic vectors, analytics rollups, retention backups) can be rebuilt fr; L92: **Lexical publish durability (atomic-swap)** | atomic, backup, dry-run |
| `post_compact_reminder` | `README.md` | L43: / **Idempotent installer** / Safe to run repeatedly; detects existing installs, handles upgrades, creates backups /; L74: **2. Atomic file operations.** | atomic, backup, dry-run, idempotent |
| `chat_shared_conversation_to_file` | `README.md` | L55: 6) Emit Markdown to a temp file, rename atomically; render HTML twin with inline CSS/TOC/HLJS.; L81: - I/O: atomic writes; HTML and MD generated in-memory once. | atomic, dry-run |
| `coding_agent_account_manager` | `README.md` | L20: caam backup claude alice@gmail.com      # Save current auth; L82: A <-->/"backup / activate"/ D | backup |

Flywheel relevance: new tick/doctor/promoter surfaces should be safe to re-run and preview mutating behavior.

### ipc-and-transport-contracts: IPC, transport, and machine envelope contracts
Preliminary pattern: Cross-process surfaces are treated as contracts: JSON/robot modes, envelopes, command schemas, queues, sockets, and transport health checks.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `Dicklesworthstone` | `README.md` | L9: ![Rust](https://img.shields.io/badge/-Rust-2b2b2b?style=flat-square&logo=rust&logoColor=dea584); L10: ![TypeScript](https://img.shields.io/badge/-TypeScript-2b2b2b?style=flat-square&logo=typescript&logoColor=3178C6) | http, mcp, message |
| `sassaman_and_dingledine_on_remailers_at_blackhat_2003` | `README.md` | L2: ![Illustration](https://raw.githubusercontent.com/Dicklesworthstone/sassaman_and_dingledine_on_remailers_at_blackhat_2003/main/remailers_illustration.webp); L6: > **Editor's Note**: This is a transcript of a really great talk given in 2003. You can watch the full video of it [here](https://www.youtube.com/watch?v=Y7A2J6YnLfA). I thought it | http, message |
| `coding_agent_session_search` | `README.md` | L7: ![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue.svg); L8: ![Rust](https://img.shields.io/badge/Rust-stable-orange.svg) | --json, envelope, http, json, mcp, message |
| `ultimate_mcp_client` | `README.md` | L1: # 🧠 Ultimate MCP Client; L5: [![Python 3.13+](https://img.shields.io/badge/python-3.13+-blue.svg)](https://www.python.org/downloads/release/python-3130/) | http, json, mcp, message, queue, socket, transport, websocket |
| `curl_bash_one_liners_for_flywheel_tools` | `README.md` | L7: [![GitHub](https://img.shields.io/badge/GitHub-Dicklesworthstone-181717?style=for-the-badge&logo=github)](https://github.com/Dicklesworthstone); L8: [![X](https://img.shields.io/badge/X-@doodlestein-000000?style=for-the-badge&logo=x)](https://x.com/doodlestein) | http, mcp |
| `franken_whisper` | `README.md` | L9: [![License: MIT+Rider](https://img.shields.io/badge/License-MIT%2BOpenAI%2FAnthropic%20Rider-blue.svg)](./LICENSE); L10: [![Rust Edition](https://img.shields.io/badge/Rust-2024_Edition-orange.svg)](https://doc.rust-lang.org/edition-guide/rust-2024/) | --json, envelope, http, json, pipe, socket, transport, websocket |
| `beads_rust` | `README.md` | L9: [![CI](https://github.com/Dicklesworthstone/beads_rust/actions/workflows/ci.yml/badge.svg)](https://github.com/Dicklesworthstone/beads_rust/actions/workflows/ci.yml); L10: [![License: MIT](https://img.shields.io/badge/License-MIT%2BOpenAI%2FAnthropic%20Rider-blue.svg)](./LICENSE) | --json, http, json, mcp, pipe |
| `mcp_agent_mail` | `README.md` | L1: # MCP Agent Mail; L7: A mail-like coordination layer for coding agents, exposed as an HTTP-only FastMCP server. It gives agents memorable identities, an inbox/outbox, searchable message history, and vol | http, json, mcp, message |

Flywheel relevance: codify callback and transport envelopes before adding more pane/orch message paths.

### error-handling-and-recovery: Error handling, recovery, and escalation taxonomy
Preliminary pattern: Errors are classified, routed, and made recoverable with clear commands, rather than swallowed or hidden behind generic status.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `causal_direction_estimation_from_data` | `README.md` | L15: 2. **Evaluating Prediction Errors:**; L16: - We analyze the error distributions for each model — the discrepancies between predicted and actual values. | error |
| `paxos_vs_raft` | `README.md` | L25: _Fault Tolerance:_ It's possible that some of your friends might not respond to messages, maybe because they're busy or their phone is off. Despite this, the rest of the group stil; L27: Consensus protocols aim to ensure that all functioning nodes in a distributed system can agree on a single value, despite potential communication delays or node failures. They are  | error, fail, failure |
| `automated_flywheel_setup_checker` | `README.md` | L11: **Automated verification of [ACFS](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup) installer scripts in isolated Docker containers — with error classification, ; L19: **The Problem:** ACFS ships 41 installer scripts that download, verify, and configure tools on fresh Ubuntu VPS instances. Any upstream URL change, checksum drift, or dependency is | error, fail, failure, retry |
| `cmaes_explainer` | `AGENTS.md` | L54: * No random `console.log` / `console.error` sprinkled across UI components. If you need diagnostics, either:; L67: Goal: fast manual/automated sanity sweep with screenshots and console/error capture, reproducible by any agent. | diagnostic, error, fail, failure |
| `asupersync_ansi_c` | `README.md` | L37: **The Solution:** `asx` ports asupersync's full semantic model to ANSI C: region/task/obligation lifecycle guarantees, structured cancellation, deterministic replay, strict OOM beh; L43: / **1,364 exported `ASX_API` declarations across 38 header families** / Full async runtime: scheduler, channels, sync primitives, actors, combinators, timers, codecs, diagnostics,  | diagnostic, error, fail, failure, recover, recovery, retry |
| `meta_skill` | `AGENTS.md` | L37: br doctor 2>&1 / grep -E "(✖/FAIL/Error)"; L38: # If any failures, STOP. Ask user. | error, fail, failure, recover, recovery |
| `coding_agent_session_search` | `README.md` | L59: cass search "authentication error" --robot --limit 5 --fields minimal; L81: - stderr = diagnostics | diagnostic, error, fail, failure, fallback, recover, recovery, retry |
| `frankenmermaid` | `README.md` | L9: / CLI validate command with structured diagnostics / Implemented / 1 evidence refs /; L21: *80+ interactive examples, live editor, style studio, diagnostics panel, and determinism checker* | diagnostic, error, fail, failure, fallback, recover, recovery |

Flywheel relevance: route recurring failure classes into doctor signals, beads, and recovery commands.

### schema-versioning-and-migrations: Schema versioning, migrations, and compatibility
Preliminary pattern: Artifacts and databases carry explicit versions, migration paths, compatibility checks, and upgrade evidence.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `frankentorch` | `README.md` | L32: 4. frankenlibc/frankenfs compatibility-security thinking: strict vs hardened mode separation, fail-closed compatibility gates, and explicit drift ledgers.; L42: Implementation proceeds in packetized waves (`FT-P2C-*`) to control risk and improve proof quality, but the terminal target remains complete PyTorch drop-in compatibility. | compatibility, schema, v1, version |
| `franken_node` | `README.md` | L11: ![Compatibility](https://img.shields.io/badge/compatibility-node%20%2B%20bun-5b3cc4); L17: `franken_node` is a trust-native JavaScript/TypeScript runtime platform for extension-heavy systems; it pairs Node/Bun migration speed with deterministic security controls and repl | compatibility, migrate, migration, schema, v1, version |
| `acip` | `README.md` | L10: [![Version](https://img.shields.io/badge/version-1.3-blue.svg)](#acip-v13--whats-new-and-why); L66: The repository contains versioned markdown files, each representing a complete ACIP prompt version. | compatibility, v1, version |
| `frankenjax` | `README.md` | L31: / Transform composition: `jit(grad(f))`, `vmap(grad(f))`, `grad(grad(f))` / V1 matrix gated; unsupported rows fail closed /; L37: / Strict/Hardened compatibility-security mode split / All green / | compatibility, v1, v2 |
| `fastapi_rust` | `AGENTS.md` | L33: **The default branch is `main`. The `master` branch exists only for legacy URL compatibility.**; L53: - **Dependency versions:** Explicit versions for stability | compatibility, schema, upgrade, version |
| `frankensqlite` | `README.md` | L26: 1. **MVCC Concurrent Writers.** The single-writer lock is replaced with page-level Multi-Version Concurrency Control. Multiple writers commit simultaneously as long as they touch d; L30: The current runnable engine is already real, but still hybrid. Compatibility mode over standard SQLite files is the live runtime path today; Native mode / ECS sections below descri | compatibility, downgrade, schema, v2, version |
| `flywheel_connectors` | `README.md` | L8: > target. `FCP_Specification_V2.md` is retained as historical / legacy-interoperability context.; L19: **Current provisioning path (V1 — Host-First, transitional):** the way to bring systems online today is `fwc -> fcp-host HTTP admin API -> connector subprocesses over supervised st | downgrade, migrate, migration, schema, v1, v2, version |
| `franken_engine` | `README.md` | L25: ./target/release/frankenctl version; L57: operator tooling. **Shipped surfaces**: `version`, `compile`, `run`, `doctor`, | compatibility, migration, schema, v1, version |

Flywheel relevance: version every validation/receipt artifact and include migration tests for v1-to-next changes.

### callback-and-receipt-envelope: Callback, receipt, and DONE/BLOCKED envelope shape
Preliminary pattern: Worker/agent completion is treated as structured evidence: callbacks, receipts, status fields, and artifacts that can be validated.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `frankentorch` | `README.md` | L17: - every temporary gap must map to explicit parity-closure beads plus conformance evidence; L21: Deterministic Autograd Contract (DAC): replayable gradient graph execution with provenance-complete gradient evidence. | ack, artifact, envelope, evidence |
| `sassaman_and_dingledine_on_remailers_at_blackhat_2003` | `README.md` | L1: # Attacks on Anonymity Systems: The Theory; L2: ![Illustration](https://raw.githubusercontent.com/Dicklesworthstone/sassaman_and_dingledine_on_remailers_at_blackhat_2003/main/remailers_illustration.webp) | DONE, ack |
| `agent_settings_backup_script` | `README.md` | L1: # Agent Settings Backup (asb); L4: <img src="asb_illustration.webp" alt="asb - Smart backup tool for AI coding agent configurations"> | ack, status |
| `eidetic-engine-docs` | `README.md` | L5: **Overall Purpose:** This module acts as the "brain's librarian and project manager" for your AI agent. It provides a structured way to store, retrieve, and relate all kinds of inf; L11: *   **Enums (e.g., `WorkflowStatus`, `ActionStatus`, `ActionType`, `ArtifactType`, `ThoughtType`, `MemoryLevel`, `MemoryType`, `LinkType`, `GoalStatus`)** | ack, artifact, status |
| `franken_engine` | `README.md` | L16: Native Rust runtime for adversarial extension workloads, with deterministic replay surfaces, signed evidence contracts, and explicit proof-state tracking for cryptographic decision; L28: <p><em>This repository currently ships Rust workspace crates and source-built utility binaries, not a packaged installer or prebuilt release binaries.</em></p> | ack, artifact, evidence, receipt |
| `flywheel_connectors` | `README.md` | L17: **Operational truth hierarchy:** `fwc` classifies every answer by its truth source — **mesh-backed > host-backed > node-local > offline** — instead of collapsing everything into a ; L23: 1. **A transitional host-first control plane converging toward mesh-native operation**: `fwc` (the sole CLI) talks to `fcp-host` (node-local supervisor) which manages connector sub | ack, evidence, receipt, status |
| `franken_networkx` | `README.md` | L7: FrankenNetworkX is a high-performance, Rust-backed drop-in replacement for [NetworkX](https://networkx.org/). Use it as a standalone library or as a NetworkX backend with zero code; L12: - [Backend integration](docs/backend.md) | ack, artifact, callback, evidence |
| `frankenredis` | `README.md` | L25: 1. **alien-artifact-coding** for decision theory, confidence calibration, and explainability. Status: not started.; L26: 2. **extreme-software-optimization** for profile-first, proof-backed performance work. Status: optimization proof artifacts exist (`ISOMORPHISM_PROOF_ROUND{1,2}.md`), the live-serv | ack, artifact, evidence, status |

Flywheel relevance: normalize worker callback fields and receipts so orchestrator validation can fail closed.

### append-only-audit-and-lineage: Append-only audit logs, lineage, and evidence chains
Preliminary pattern: Operational history is append-only, replayable, and checkpointed so audits can verify chronology and lineage.

Coverage: 12 cited repo docs from first-200-line doctrine/readme scans.

| repo | source | first matching line(s) | terms |
|---|---|---|---|
| `Dicklesworthstone` | `README.md` | L9: ![Rust](https://img.shields.io/badge/-Rust-2b2b2b?style=flat-square&logo=rust&logoColor=dea584); L10: ![TypeScript](https://img.shields.io/badge/-TypeScript-2b2b2b?style=flat-square&logo=typescript&logoColor=3178C6) | audit, log, receipt |
| `the_lighthill_debate_on_ai` | `README.md` | L38: One man who's pessimistic about the long-term prospects of artificial intelligence is our speaker tonight, Sir James Lighthill, one of Britain's most distinguished scientists. He's; L46: Increasingly, an important role in automation is played by computers. A computer is an extremely fast, reliable, and biddable device for manipulating numbers and similar symbols ac | chain, evidence, log |
| `cohomological_ai` | `README.md` | L1: # Cohomological Transformer; L7: Welcome to **cohomological_transformer**, a single-file Python codebase that explores advanced—and quite speculative—ideas at the intersection of: | chain, log |
| `nextjs-github-markdown-blog` | `README.md` | L1: # Next.js GitHub Markdown Blog; L3: A modern, feature-rich blogging platform that uses GitHub as a CMS. Transform your Markdown files into a beautiful, responsive blog with minimal setup. Perfect for developers who w | log |
| `paxos_vs_raft` | `README.md` | L13: Now, let's take a non-technical analogy to explain this further:; L33: Raft, on the other hand, simplifies the process by electing a leader in the first phase, who then makes all the decisions until it fails. The election ensures that there's always a | append, log |
| `flywheel_connectors` | `README.md` | L25: 2. **FCP specifications and the mesh-native ownership split**: the protocol model, security invariants, and the FCP3 owner crates (`fcp-kernel`, `fcp-policy`, `fcp-evidence`) that ; L29: **Target steady state (V2 — Mesh-Native, converging):** personal-device sovereignty, mesh durability, and capability-gated execution across your own infrastructure. In the target m | audit, chain, checkpoint, evidence, log, receipt |
| `ppp_loan_fraud_analysis` | `README.md` | L13: 3. **Deep Analysis**: The `analyze_patterns_in_suspicious_loans.py` script loads the sorted suspicious loans alongside the full dataset to perform advanced statistical and machine ; L93: - **How It Works:** Weighted residential indicators (e.g., “PO Box” at 0.9, “Suite” at 0.4) sum to a score; if >0.7, points are added (e.g., 10). Dictionaries track businesses per  | audit, evidence, log |
| `introduction_to_temporal_logic` | `README.md` | L1: # Introduction to Temporal Logic; L3: The first formal treatment of the ideas now known as temporal logic can be traced to the Polish logician [Jerzy Łoś](https://en.wikipedia.org/wiki/Jerzy_%C5%81o%C5%9B) in his 1947  | log |

Flywheel relevance: preserve causality through append-only logs and replayable lineage for learning substrate.

## Method Notes
- Phase 1 used only local checked-out Jeff repos from `.flywheel/jeff-corpus/v1/manifest.json`.
- For each present doc, only the first 200 lines were read into the clustering scan, matching dispatch scope.
- Cluster membership is keyword-assisted and preliminary; Phase 3 quality scoring should separate mature reusable primitives from incidental README language.
