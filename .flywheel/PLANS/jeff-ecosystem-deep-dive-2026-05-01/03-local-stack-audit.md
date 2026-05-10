---
title: "Jeff Ecosystem Recon — Local Stack Audit"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Jeff Ecosystem Recon — Local Stack Audit

Task: `jeff_eco_pane3`
Date: 2026-05-01
Evidence ledger: `/tmp/jeff_eco_pane3_evidence.txt`
Extra evidence: `/tmp/ntm_version_extra.txt`, `/tmp/jeff_eco_bins_extra.txt`, `/tmp/agentmail_git_extra.txt`, `/tmp/vibe_binary_extra.txt`, `/tmp/br_remote_extra.txt`, `/tmp/upstream_recent_extra.txt`

## ntm

- **Installed:** `ntm version 1.13.1` at `/Users/josh/.local/bin/ntm`; `ntm --version` is not accepted. Evidence: `/tmp/ntm_version_extra.txt:3`, `/tmp/jeff_eco_pane3_evidence.txt:307-309`
- **Source HEAD:** local `/Users/josh/Developer/ntm` at `5bbcaf7c 2026-04-30 15:17:32 -0600 Scope checkpoint dirs by project slug`; origin/main at `0fd7dfa0 2026-05-01 01:07:34 -0400 fix(install): resolve latest release via wget redirect`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:26-34`
- **Days behind:** ~0.3 days by commit timestamp, but **514 commits behind** and 63 local commits ahead. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:12`, `/tmp/jeff_eco_pane3_evidence.txt:33-34`
- **Friction points:**
  1. Version flag mismatch: common `--version` path exits 1; correct command is `ntm version`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:305-309`, `/tmp/ntm_version_extra.txt:2-8`
  2. Config loader rejects live config fields, including `coordinator.*`, `context_rotation.recovery.*`, extra models, and `session_paths.*`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:311-314`
  3. Health still reports two error panes in `flywheel` and marks pane 1 rate-limited/stuck, matching the known false-positive class. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:316-321`, `/tmp/jeff_eco_pane3_evidence.txt:370-394`
- **Unused upstream features:**
  1. New process-tree pane command detection for wrapper commands. Evidence: `/tmp/upstream_recent_extra.txt:7`
  2. CASS degraded-mode handling when installed but uninitialized. Evidence: `/tmp/upstream_recent_extra.txt:8`
  3. Claude Code model snapshot/restore in swarm lifecycle. Evidence: `/tmp/upstream_recent_extra.txt:13`
- **Silent failures:**
  1. `ntm config validate --json | jq ...` returns shell exit 0 even though the payload is a fatal config parse failure. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:311-314`
  2. `ntm health flywheel --json` exits 0 while reporting `error_count=2`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:316-321`, `/tmp/jeff_eco_pane3_evidence.txt:445`
  3. No local changelog was found by the requested `CHANGELOG*` probe. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:447-449`

## beads_rust / br

- **Installed:** `br 0.2.4` at `/Users/josh/.cargo/bin/br`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:575-579`, `/tmp/jeff_eco_bins_extra.txt:7`
- **Source HEAD:** local `/Users/josh/Developer/beads_rust` at `1a72cb42 2026-04-30 15:22:37 -0600 Add Phase 3 isolation regression tests`; upstream unresolved because origin refs are broken. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:122-129`
- **Days behind:** UNKNOWN; `git fetch origin` fails and local branch tracks `origin/main: gone`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:61-69`, `/tmp/br_remote_extra.txt:1-4`
- **Friction points:**
  1. Source repo cannot fetch cleanly due broken remote refs. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:61-65`
  2. Local source worktree is heavily dirty across CLI/storage/sync files, so installed `br 0.2.4` cannot be trusted as matching source HEAD. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:67-100`
  3. `br doctor` reports workspace `recoverable`, not clean, due 25 preserved recovery artifacts. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:581-600`
- **Unused upstream features:**
  1. `--repo` flag for `list/ready/blocked`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:610-612`
  2. Authority diagnostic command. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:613-615`
  3. Strict-local/symlink rejection and frozen `.beads` discovery protections. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:616-618`
- **Silent failures:**
  1. Broken origin refs mean "days behind" cannot be computed without repairing refs. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:61-65`
  2. `br list --format json` succeeds with 43 visible issues while `br doctor` says 91 total records, so naive list counts understate the full DB. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:589`, `/tmp/jeff_eco_pane3_evidence.txt:603-606`
  3. Recovery artifacts persist but do not fail normal commands. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:583-600`

## bv

- **Installed:** `bv v0.13.0` at `/opt/homebrew/bin/bv`; `/Users/josh/.local/bin/bv` is a small wrapper. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:796-801`, `/tmp/jeff_eco_bins_extra.txt:2`
- **Source HEAD:** NOT-INSTALLED; no `/Users/josh/Developer/beads_viewer` clone. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:155-156`, `/tmp/jeff_eco_pane3_evidence.txt:803-806`
- **Days behind:** UNKNOWN; source clone missing. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:803-806`
- **Friction points:**
  1. Source clone absent, so we cannot diff installed `v0.13.0` against upstream. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:155-156`
  2. Installed path is Homebrew, not source-built under `~/.local/bin`; this weakens local source-to-binary traceability. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:797-800`, `/tmp/jeff_eco_bins_extra.txt:2`
  3. Robot triage reports `flywheel-2te` as top pick even though this session already completed it, suggesting stale bead sync or bv input freshness lag. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:808-810`
- **Unused upstream features:**
  1. Robot triage exposes PageRank, betweenness, blocker ratio, staleness, urgency, and risk breakdowns; our tick only recently started adding PageRank. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:808-810`
  2. Top-pick quick reference can drive dispatch selection. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:808-810`
  3. Risk-signal detail could feed fleet coherence prioritization. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:808-810`
- **Silent failures:**
  1. No source clone means "upstream features" cannot be verified against installed binary. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:803-806`
  2. `bv --robot-triage` exits 0 despite stale-looking top pick. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:808-811`
  3. Source grep returns nothing because the source tree is missing, not because there are no issues. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:813-815`

## agent-mail / mcp-agent-mail

- **Installed:** source-like install at `~/.local/share/mcp_agent_mail`, package version `0.3.2`; HTTP process running via `uv run python -m mcp_agent_mail.cli serve-http`. Evidence: `/tmp/agentmail_git_extra.txt:6-8`, `/tmp/jeff_eco_pane3_evidence.txt:819-848`, `/tmp/jeff_eco_pane3_evidence.txt:852`, `/tmp/jeff_eco_pane3_evidence.txt:854`
- **Source HEAD:** local `b1ad7bf 2026-04-28 20:42:04 -0400`; origin/main `e32ff31 2026-05-01 13:07:10 -0400`. Evidence: `/tmp/agentmail_git_extra.txt:2-5`
- **Days behind:** ~2.7 days, 6 commits behind. Evidence: `/tmp/agentmail_git_extra.txt:2-5`
- **Friction points:**
  1. Both probed health ports fail: `8080` and documented `8765`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:817-855`
  2. The process is running, so this is a port/config discovery gap, not simply "server down". Evidence: `/tmp/jeff_eco_pane3_evidence.txt:852`, `/tmp/jeff_eco_pane3_evidence.txt:854`
  3. System Python cannot import `mcp_agent_mail`; only the project venv can. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:861-867`, `/tmp/agentmail_paths_extra.txt:31-34`
- **Unused upstream features:**
  1. Read/ack state badges and filters in inbox/detail views. Evidence: `/tmp/upstream_recent_extra.txt:29-31`
  2. Fixed hooks that actually reach Claude/Gemini/Codex/Factory inbox checks. Evidence: `/tmp/upstream_recent_extra.txt:33-34`
  3. Static mailbox export/share tooling with update, preview, signing, encryption, and deployment workflows. Evidence: `/tmp/agentmail_git_extra.txt:40-63`, `/tmp/agentmail_git_extra.txt:83-96`
- **Silent failures:**
  1. Health endpoint checks say not running while a serve-http process is present. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:849-850`, `/tmp/jeff_eco_pane3_evidence.txt:852`, `/tmp/jeff_eco_pane3_evidence.txt:854`
  2. Agent-mail log grep found no recent errors despite failed health probes. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:857-859`
  3. Python import probe returns `None`, so ad hoc Python diagnostics can falsely conclude not installed. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:861-867`

## dcg

- **Installed:** `dcg v0.4.0` at `/Users/josh/.local/bin/dcg`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:869-884`, `/tmp/jeff_eco_bins_extra.txt:4`
- **Source HEAD:** NOT-INSTALLED; no `/Users/josh/Developer/dcg` clone. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:158-159`
- **Days behind:** UNKNOWN; source clone missing. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:158-159`
- **Friction points:**
  1. Source clone absent, so local binary cannot be audited against upstream. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:158-159`
  2. Requested hook probe finds no hook name containing `dcg`; safety seems present as other hooks, not a visible dcg hook. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:869-884`
  3. Grep evidence is dominated by generic hooks and backups, making dcg integration ownership unclear. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:886-904`, `/tmp/jeff_eco_pane3_evidence.txt:1003-1017`
- **Unused upstream features:**
  1. UNKNOWN without source clone. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:158-159`
  2. Current hook layer has dispatch transport gates that are adjacent but not clearly dcg-owned. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:889-899`
  3. Current hook layer has PostgreSQL safety integration separate from dcg. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:961-980`
- **Silent failures:**
  1. `ls ~/.claude/hooks/ | grep -i dcg` produces no visible hook but the command group exits successfully. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:869-884`
  2. Hook reference helper is explicitly silent on no-match or missing refs. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1003-1017`
  3. `n8n-lessons-capture.py` allows on error. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:886-889`

## cass

- **Installed:** `cass 0.2.0` at `/Users/josh/.local/bin/cass`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1050-1055`, `/tmp/jeff_eco_bins_extra.txt:3`
- **Source HEAD:** NOT-INSTALLED; no `/Users/josh/Developer/cass` clone. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:161-162`
- **Days behind:** UNKNOWN; source clone missing. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:161-162`
- **Friction points:**
  1. `cass robot status` prints `Could not parse arguments`, so the expected robot surface is not available or has drifted. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1050-1055`
  2. Source clone absent, so local binary cannot be audited. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:161-162`
  3. Source grep returns nothing because source is missing. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1057-1059`
- **Unused upstream features:**
  1. UNKNOWN without source clone. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:161-162`
  2. ntm upstream now has CASS degraded-mode handling we do not benefit from until ntm update lands. Evidence: `/tmp/upstream_recent_extra.txt:8`
  3. ntm README advertises CASS robot search/status surfaces, but local `cass robot status` fails. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:467-468`, `/tmp/jeff_eco_pane3_evidence.txt:1050-1055`
- **Silent failures:**
  1. Combined probe exits 0 even though `cass robot status` failed parse. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1050-1055`
  2. Absence of source clone can be misread as no search hits. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1057-1059`
  3. No local state directory listing appeared from either `~/.local/share/cass` or `~/.cass`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1050-1055`

## vibe_cockpit / vc

- **Installed:** built binary exists at `/Users/josh/Developer/vibe-cockpit/target/debug/vc` as `vc 0.1.0`; PATH `vc` is Vercel CLI 50.10.2 at `/opt/homebrew/bin/vc`. Evidence: `/tmp/vibe_binary_extra.txt:1-3`, `/tmp/vibe_binary_extra.txt:33`, `/tmp/jeff_eco_pane3_evidence.txt:1061-1065`, `/tmp/jeff_eco_bins_extra.txt:8`
- **Source HEAD:** `e0daa5c 2026-04-30 17:16:19 -0400 fix(vc_cli,vc_store): minor cleanups from fresh-eyes review`; origin matches. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:173-181`
- **Days behind:** 0 days / 0 commits. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:178-182`
- **Friction points:**
  1. Command-name collision: `vc --version` runs Vercel, not Vibe Cockpit. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1061-1065`, `/tmp/jeff_eco_pane3_evidence.txt:1119-1175`
  2. Daemon log repeats `beads: FAIL (No beads databases found)`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1067-1117`, `/tmp/jeff_eco_pane3_evidence.txt:1213-1314`
  3. Daemon log repeats missing collector tools: `rch`, `sysmoni`, `afsc`, `caut`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1067-1117`
- **Unused upstream features:**
  1. TUI/dashboard, robot, web, MCP, health, incident, migration, ingest, reporting commands are available in the built binary but not on PATH. Evidence: `/tmp/vibe_binary_extra.txt:3-32`
  2. `migrate-db` command for DuckDB-to-FrankenSQLite exists. Evidence: `/tmp/vibe_binary_extra.txt:28-31`
  3. Structured shutdown and collector backpressure landed upstream. Evidence: `/tmp/upstream_recent_extra.txt:45-48`
- **Silent failures:**
  1. PATH shadowing makes `vc` look installed while actually invoking Vercel. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1061-1065`, `/tmp/vibe_binary_extra.txt:1-3`
  2. Daemon continues cycling while beads collector fails every cycle. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1213-1316`
  3. Config still documents DuckDB as default and beads collector enabled, while runtime has missing-beads failures. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1492-1496`, `/tmp/jeff_eco_pane3_evidence.txt:1070-1115`

## frankensqlite

- **Installed:** source workspace at `/Users/josh/Developer/frankensqlite`, no standalone binary path audited. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1502-1515`
- **Source HEAD:** local `5eabd23e 2026-04-29 23:28:19 -0400`; origin/main `f1f3b6a8 2026-05-01 12:52:31 -0400`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:220-228`
- **Days behind:** ~1.7 days, 48 commits behind. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:215-228`
- **Friction points:**
  1. Local source is behind 48 commits, which matters because vibe-cockpit depends on path crates from this checkout. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:215-228`
  2. README states residual fallback paths still exist for CTE/view materialization, joins/group/window functions, schema virtualization, and some `INSERT ... SELECT`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1583-1590`
  3. CLI is not yet sqlite3-equivalent; persistent history, full tab completion, and broader dot-command parity are future work. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1673-1675`
- **Unused upstream features:**
  1. Latest upstream count-star fast-path gate hardening. Evidence: `/tmp/upstream_recent_extra.txt:15-18`
  2. Recent record/materialization performance improvements. Evidence: `/tmp/upstream_recent_extra.txt:19-27`
  3. Current README exposes transaction observability PRAGMAs we are not yet using in vc. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1591-1599`
- **Silent failures:**
  1. Compatibility fallback paths can hide incomplete lowerings behind successful execution. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1583-1590`
  2. On shared memory restrictions, cross-process coordination falls back to file-lock behavior and degrades to single-writer while preserving correctness. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1714-1717`
  3. README still includes examples with `unwrap()`/`panic!`, which can leak into consumer patterns. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1676-1679`

## asupersync

- **Installed:** source workspace at `/Users/josh/Developer/asupersync`; consumer crates use crates.io `asupersync 0.3.1`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:267-275`, `/tmp/jeff_eco_pane3_evidence.txt:278-300`
- **Source HEAD:** local `a2e097b8 2026-03-09 20:12:32 -0500`; origin appears same, but fetch timed out. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:255-275`
- **Days behind:** 0 commits by cached origin metadata, but confidence is degraded because fetch exited 124. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:255-257`, `/tmp/jeff_eco_pane3_evidence.txt:272-275`
- **Friction points:**
  1. `git fetch origin` timed out, so freshness proof is weak. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:255-257`
  2. Worktree is dirty in `AGENTS.md` and `Cargo.toml`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:259-265`
  3. README explicitly says strict drop-in compatibility with Tokio-hardwired libraries is not the right use case. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1801-1804`
- **Unused upstream features:**
  1. Lab runtime, virtual time, deterministic scheduling, trace replay. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1730-1734`, `/tmp/jeff_eco_pane3_evidence.txt:1786-1788`
  2. Adaptive EXP3/Hedge cancel preemption and Lyapunov-style scheduling signals. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1792-1795`
  3. Futurelock detection with structured evidence ledgers. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1906-1907`
- **Silent failures:**
  1. Cached origin says in sync even when fresh fetch timed out. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:255-275`
  2. Consumer projects can still carry Tokio compatibility despite asupersync being the desired runtime. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1743-1765`
  3. SQLite support runs through a blocking pool bridge, not a native async database driver. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1893-1895`

## pi-agent-rust

- **Installed:** `pi 0.1.8 (833dd501 2026-03-07T23:56:44.599105000Z)` at `/Users/josh/.local/bin/pi` symlinked to `pi-agent`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1910-1914`, `/tmp/jeff_eco_bins_extra.txt:6`
- **Source HEAD:** NOT-INSTALLED; no `/Users/josh/Developer/pi-agent-rust` clone. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:302-303`, `/tmp/jeff_eco_pane3_evidence.txt:1910-1918`
- **Days behind:** UNKNOWN; source clone missing. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:302-303`
- **Friction points:**
  1. Source clone absent. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:302-303`
  2. The combined probe exits 1 because the source `ls` fails after version prints. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1910-1914`
  3. Source grep returns nothing because there is no source tree. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1916-1918`
- **Unused upstream features:**
  1. UNKNOWN without source clone. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:302-303`
  2. Installed binary exposes only version in this probe; no feature inventory available locally. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1910-1914`
  3. Candidate for source clone sync before future convergence audit. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:302-303`
- **Silent failures:**
  1. Binary exists, but source is absent, so version provenance stops at embedded commit string. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1910-1914`
  2. `which pi` succeeds while repo audit cannot proceed. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1910-1918`
  3. No upstream comparison possible. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:302-303`

## Cross-cutting Findings

- **Config-loader/schema drift repeats.** ntm rejects live config fields; vc config enables collectors that runtime cannot satisfy; Agent Mail health port docs/process reality disagree. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:311-314`, `/tmp/jeff_eco_pane3_evidence.txt:1492-1496`, `/tmp/jeff_eco_pane3_evidence.txt:849-850`, `/tmp/jeff_eco_pane3_evidence.txt:852`, `/tmp/jeff_eco_pane3_evidence.txt:854`
- **Source-to-binary traceability is weak.** `bv`, `dcg`, `cass`, and `pi` have installed binaries but no local source clones; `vc` source is present but PATH points to Vercel. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:155-162`, `/tmp/jeff_eco_pane3_evidence.txt:302-303`, `/tmp/jeff_eco_pane3_evidence.txt:1061-1065`
- **Git freshness is unreliable.** ntm is 514 commits behind; frankensqlite is 48 behind; beads_rust origin refs are broken; asupersync fetch timed out. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:31-34`, `/tmp/jeff_eco_pane3_evidence.txt:225-228`, `/tmp/jeff_eco_pane3_evidence.txt:61-65`, `/tmp/jeff_eco_pane3_evidence.txt:255-257`
- **Robot surfaces exist but are uneven.** bv robot output is rich; cass robot status fails parse; ntm advertises CASS robot surfaces but local cass cannot satisfy the expected command. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:808-810`, `/tmp/jeff_eco_pane3_evidence.txt:1050-1055`, `/tmp/jeff_eco_pane3_evidence.txt:467-468`
- **PATH namespace collision is real.** `vc` is occupied by Vercel, so Vibe Cockpit cannot be invoked by its intended binary name without explicit path or install relocation. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:1061-1065`, `/tmp/vibe_binary_extra.txt:1-3`
- **Tools installed but not currently auditable from source:** `bv`, `dcg`, `cass`, `pi`. Evidence: `/tmp/jeff_eco_pane3_evidence.txt:155-162`, `/tmp/jeff_eco_pane3_evidence.txt:302-303`

## Counts

- Tools audited: 10
- Friction points listed: 30
- Investigation only; no patches applied.
