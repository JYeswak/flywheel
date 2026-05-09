## L125 — ENV-FILE-IS-SEALED-SUBSTRATE

---
id: L125
title: Env file is sealed substrate
status: long_term
shipped: 2026-05-07
review_due: 2026-11-09
trauma_class: read-tool-secret-leak
---


**Trauma class:** `read-tool-secret-leak`
**Generalizes:** L58 (secret material never in pane text)
**Sibling to:** L73 (runtime leak)
**Backed by:** SEC-001..006

`.env*` files are sealed substrate. Reading them via `Read`/`Edit`/`Write`/`cat`/MCP file-tools produces a transcript leak equivalent to the L58 pane-text leak. The Bash-surface guards (`dcg`, `infisical-safe.sh`, infisical PreToolUse hook) DO NOT cover file-read tools — that gap is by Anthropic-spec design, so the fix is doctrine + skill + heuristic, not new Claude-Code tool guards.

**Canonical verification:** `cf-secret <NAME> | shasum -a 256` (single key, fingerprint only).

**Canonical bulk audit:** read each key via per-key fingerprint, never bulk file read. If structure must be enumerated, use `awk -F= '{print $1}' .env*` (names only, never values).

**Forbidden:**
- `Read` tool on `.env*`, `.envrc`, `.secrets`, `*.pem`, `id_rsa*`, `**/credentials*`
- `cat`/`head`/`tail`/`less`/`more` on `.env*`
- Pasting env contents into prompts, code, or comments
- Logging env contents to any file (even temp)
- Sharing `.env*` via mcp filesystem tool

**Allowed:**
- `cf-secret <NAME> | shasum -a 256` for verification
- `awk -F= '{print $1}' .env*` for name enumeration only
- Reading `.env.example` or sentinel files with no real values

**Promotion ladder:** fuckup-row → infisical-secrets/INCIDENTS.md → AGENTS.md L-rule (here) + AGENTS-CANONICAL.md → flywheel-install/templates/AGENTS-TEMPLATE.md broadcast → canonical-meta-rules-sync to all flywheel-installed repos.

**Evidence:** mobile-eats:1 cross-orch handoff 2026-05-07; Joshua directive "harden via L-rule + skill discipline, NOT new tool guards"; flywheel:1 ACK; infisical-secrets skill File-Surface Discipline section; templates/fuckup-heuristics.json 6th heuristic row; mobile-192v SEC-007 packet validator extension bead (cross-orch).

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L58, L73, L56, SEC-001..006.

