# Flywheel Repo Map

Fast-path navigation for agents. This is an index only; operational doctrine stays in [AGENTS.md](AGENTS.md), especially the L-rule index and loop contract sections.

## Top-Level Directories

| Directory | Purpose |
|---|---|
| `.beads` | Beads state exported by `br`; coordinate with the AGENTS.md beads workflow before editing. |
| `.cass` | CASS/procedural-memory state; see AGENTS.md reference router before relying on it. |
| `.claude` | Repo-local Claude configuration surface; keep project-specific and lightweight. |
| `.dcg` | Destructive-command-guard support state; AGENTS.md hard rules apply. |
| `.flywheel` | Canonical flywheel substrate: scripts, doctrine, audits, runtime, inventory, rules, and loop state. |
| `.git` | Git metadata; never edit directly. |
| `.git-archive` | Local archive material for historical repo state. |
| `.github` | GitHub workflows and repository automation metadata. |
| `.ntm` | NTM orchestration state and transport configuration. |
| `.planning` | Planning artifacts and work-in-progress plans. |
| `.ruff_cache` | Python lint/cache output; ignored for Claude context. |
| `.vercel` | Vercel local/project metadata. |
| `AGENTS` | Agent-facing support material adjacent to root [AGENTS.md](AGENTS.md). |
| `beads_compliance_audit` | Beads compliance audit artifacts and supporting evidence. |
| `bin` | Repo command entrypoints; see [bin/CLAUDE.md](bin/CLAUDE.md). |
| `cross-orch-input` | Cross-orchestrator input packets and handoff material. |
| `docs` | Public and internal documentation generated from repo evidence. |
| `fixtures` | Shared fixture data for tests and probes. |
| `flywheel__nextra_documentation_site` | Nextra documentation site package. |
| `githooks` | Git hook scripts and installable hook support. |
| `inventory` | Inventory snapshots outside the `.flywheel` substrate. |
| `launchd` | macOS launchd plist and daemon support. |
| `packages` | Reusable packages and libraries used by the public/export surfaces. |
| `receipts` | Receipt artifacts used as evidence for claims and closeouts. |
| `scripts` | Root-level public/export scripts, separate from `.flywheel/scripts`. |
| `site` | Website application surface. |
| `state` | Local state snapshots and ledgers. |
| `templates` | Install, schema, and report templates. |
| `tests` | Repo test harnesses; see [tests/CLAUDE.md](tests/CLAUDE.md). |

## High-Traffic Flywheel Areas

- `.flywheel/scripts`: executable substrate and audit tools; see `.flywheel/scripts/CLAUDE.md`.
- `.flywheel/doctrine`: meta-patterns, rules, and operating doctrine; see `.flywheel/doctrine/CLAUDE.md`.
- `.flywheel/audits`: generated audit reports and evidence; see `.flywheel/audits/CLAUDE.md`.
