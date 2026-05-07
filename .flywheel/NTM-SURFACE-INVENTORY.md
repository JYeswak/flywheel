# NTM Surface Inventory — USE / ISSUE / WRAP

**The Rule (three states, no fourth):**
- **USE** — ntm has this function. We use it. Any flywheel script that hand-rolls the same function is rewritten as a thin caller, or deleted.
- **ISSUE** — ntm doesn't have it, and it's worth filing upstream. We file the Jeff issue, then USE once it ships.
- **WRAP** — ntm doesn't have it, and it's not worth an upstream issue (flywheel-specific evidence/doctrine/contracts). We wrap, owning that the wrapper is flywheel territory.

**No competing implementations. No "alongside." If ntm has it, we use it.**

**Mission anchor:** continuous-orchestrator-uptime-self-sustaining-fleet
**Authored:** 2026-05-07 by flywheel:1 (claude orch, no worker — direct audit)

---

## Headline numbers

| Metric | Count |
|---|---:|
| Total NTM surfaces | **108** |
| Verification cohort (formerly claimed USE rows) | **86** |
| `VERIFIED-USE` | **24** |
| `LATENT-USE` | **12** |
| `WIRE-IT-QUEUED` | **25** |
| `RECLASSIFIED-EXCLUDED` | **14** |
| `RECLASSIFIED-WRAP-ALIAS` | **6** |
| `RECLASSIFIED-ISSUE` | **5** |
| Prior ISSUE candidates outside the 86-row cohort | **8** |
| Prior EXCLUDED rows outside the 86-row cohort | **5 physical rows** |

---

## Master table: every NTM surface, classified

For every row: **Decision** ∈ {USE, ISSUE, WRAP, EXCLUDED}. **Action** = exactly what to do.

| # | NTM surface | What it does | Decision | Verification status | Action |
|---:|---|---|---|---|---|
| 1 | `activity` | Show agent activity states | **USE** | VERIFIED-USE - .flywheel/scripts/fleet-coherence-scan.sh:15 | Already canonical (37 callsites). Keep using. Verification: 20 callsites; top .flywheel/scripts/fleet-coherence-scan.sh:15. |
| 2 | `add` | Add agents to existing session | EXCLUDED | EXCLUDED - no-fit/interactive/self-referential | No-fit per plan §11. Flywheel respawns whole sessions. |
| 3 | `adopt` | Adopt external tmux session | EXCLUDED | RECLASSIFIED-EXCLUDED - Adopting externally-created sessions is orthogonal to flywheel steady-state orchestration; flywheel creates, spawns, dispatches, and respawns sessions under known contracts | Reclassified EXCLUDED: Adopting externally-created sessions is orthogonal to flywheel steady-state orchestration; flywheel creates, spawns, dispatches, and respawns sessions under known contracts. |
| 4 | `agents` | Manage agent profiles + capabilities | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace `orch-worker-identity-manifest.sh` hand-rolled identity registry with `ntm agents list --json` as data source. |
| 5 | `analytics` | Session analytics + statistics | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Wire into `daily-report.sh`. Delete any hand-rolled session-stat aggregation that competes. |
| 6 | `approve` | Approval requests for dangerous ops | **USE** (today's W2A wrapper) | WRAP-TERRITORY - evidence wrapper retained | The W2A wrapper exists because flywheel adds the exact-question receipt + 6-class blocker enum. **That's evidence territory — keep WRAP.** Native is the runtime gate. |
| 7 | `assign` | Intelligent work assignment via BV triage | **USE** | VERIFIED-USE - .flywheel/scripts/dispatch-and-log.sh:81 | Already wired in `dispatch-and-log.sh`. **Daemon BLOCKED by ntm#124** (already filed). When fix lands, enable `--watch --auto`. Verification: 6 callsites; top .flywheel/scripts/dispatch-and-log.sh:81. |
| 8 | `attach` | Attach to a tmux session | EXCLUDED | RECLASSIFIED-EXCLUDED - Attach is an operator-interactive verb, not an automation primitive. Flywheel panes should be controlled via send/copy/health rather than interactive attachment | Reclassified EXCLUDED: Attach is an operator-interactive verb, not an automation primitive. Flywheel panes should be controlled via send/copy/health rather than interactive attachment. |
| 9 | `audit` | Query + verify audit logs | **USE** (today's W3bA wrapper) | WRAP-TERRITORY - evidence wrapper retained | Native owns the receipt-ledger reader. The W3bA wrapper is **WRAP** because flywheel needs the canonical-writer + hash-chain enforcement that revealed real gaps (flywheel-f12e6). Keep wrapper, native is data source. |
| 10 | `beads` | Beads alias to br | EXCLUDED | EXCLUDED - no-fit/interactive/self-referential | br owns this. |
| 11 | `bind` | Tmux keybinding for palette/overlay | **WRAP** (alias) | RECLASSIFIED-WRAP-ALIAS - .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native bind during onboarding | Already consumed by wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native bind during onboarding. Update inventory as WRAP alias, not direct unverified USE. |
| 12 | `bugs` | View + manage UBS findings | **USE** | LATENT-USE - monitor; focused regression probe | Replace any flywheel UBS-aggregation with `ntm bugs --json` as source. LATENT: 1 callsite(s); add focused regression probe. |
| 13 | `cass` | Interact with CASS | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace direct `cm`/`~/.claude/skills/cass/` invocations with `ntm cass`. |
| 14 | `changes` | File changes attributed to agents | **USE** | WIRE-IT-QUEUED - opwu8 | Queue wire-in bead (opwu8); Replace `picoz-pathspec`-style hand-rolled attribution with `ntm changes --json`. |
| 15 | `checkpoint` | Manage session checkpoints | **USE** (today's W3bR wrapper) | WRAP-TERRITORY - evidence wrapper retained | Native does the snapshot. W3bR wrapper exists because flywheel adds the dirty-worktree-scoped-exception protocol. **Keep wrapper as gate, native does the work.** |
| 16 | `cleanup` | Clean up stale NTM temp files | **USE** | VERIFIED-USE - .flywheel/scripts/private-tmp-prune.sh:20 | Replace `private-tmp-prune.sh`'s NTM-specific portions with `ntm cleanup`. Verification: 8 callsites; top .flywheel/scripts/private-tmp-prune.sh:20. |
| 17 | `completion` | Generate shell completion script | **WRAP** (alias) | RECLASSIFIED-WRAP-ALIAS - .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native completion during onboarding | Already consumed by wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native completion during onboarding. Update inventory as WRAP alias, not direct unverified USE. |
| 18 | `config` | Manage NTM configuration | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Already wired via canonical TOML installer. |
| 19 | `conflicts` | File conflicts between agents | **USE** | WIRE-IT-QUEUED - opwu8 | Queue wire-in bead (opwu8); Replace any flywheel hand-rolled cross-pane file conflict detection with `ntm conflicts`. |
| 20 | `context` | Manage context packs for agent tasks | **USE** | VERIFIED-USE - .flywheel/scripts/build-dispatch-packet.sh:43 | Replace per-bead context assembly in `build-dispatch-packet.sh` with `ntm context list/get`. Verification: 3 callsites; top .flywheel/scripts/build-dispatch-packet.sh:43. |
| 21 | `controller` | Launch dedicated controller agent | **ISSUE** | RECLASSIFIED-ISSUE - Jeff issue manifest pending | Reclassified ISSUE: Jeff issue manifest pending per 12-NOT-WIRED-DISPOSITIONS.md; do not wire until contract clarifies. |
| 22 | `coordinator` | Multi-agent session coordination | **USE** (today's W3aC wrapper for shadow mode) | VERIFIED-USE - .flywheel/scripts/ntm-coordinator-shadow.sh:8 | Native owns the daemon. W3aC wrapper exists because daemon is BLOCKED by ntm#124. After #124 lands, **delete the shadow wrapper** and use native directly. Verification: 14 callsites; top .flywheel/scripts/ntm-coordinator-shadow.sh:8. |
| 23 | `copy` | Copy pane output to clipboard | **USE** | LATENT-USE - monitor; focused regression probe | Replace any flywheel scrollback-to-clipboard with `ntm copy`. LATENT: 2 callsite(s); add focused regression probe. |
| 24 | `create` | Create tmux session | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Wire into onboarding. |
| 25 | `dashboard` | Interactive session dashboard | **USE** | LATENT-USE - monitor; focused regression probe | Document as canonical dashboard. LATENT: 1 callsite(s); add focused regression probe. |
| 26 | `deps` | Check required deps | **USE** | LATENT-USE - monitor; focused regression probe | Replace flywheel dep-checking in `flywheel-onboard.sh` with `ntm deps`. LATENT: 1 callsite(s); add focused regression probe. |
| 27 | `diff` | Compare two agent panes | **USE** | LATENT-USE - monitor; focused regression probe | Replace `recency-weighted-two-truth-classifier.sh`'s scrollback compare with `ntm diff`. LATENT: 2 callsite(s); add focused regression probe. |
| 28 | `doctor` | Validate NTM ecosystem health | **USE** | WIRE-IT-QUEUED - opwu8 | Queue wire-in bead (opwu8); Wire into `flywheel-loop doctor` as a sibling probe. **Delete any flywheel hand-rolled NTM-health checks that compete.** |
| 29 | `ensemble` | Manage reasoning ensembles | EXCLUDED | RECLASSIFIED-EXCLUDED - Reasoning ensembles are a product/analysis feature, not continuous orchestrator uptime substrate. No current hand-rolled equivalent justifies keeping it as USE | Reclassified EXCLUDED: Reasoning ensembles are a product/analysis feature, not continuous orchestrator uptime substrate. No current hand-rolled equivalent justifies keeping it as USE. |
| 30 | `errors` | Show only error output from agents | **USE** | VERIFIED-USE - .flywheel/scripts/codex-template-stuck-detector.sh:17 | Replace error-grep patterns in `frozen-pane-detector.sh` and `stale-error-auto-ping.sh` with `ntm errors`. Verification: 11 callsites; top .flywheel/scripts/codex-template-stuck-detector.sh:17. |
| 31 | `extract` | Extract code blocks from agent output | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Use directly when needed in worker-stall-alert flow. |
| 32 | `get-all-session-text` | Markdown table of all panes | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace `/flywheel:tail` skill's per-pane scrollback aggregation. |
| 33 | `git` | Git coordination commands | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace `git -C` patterns in flywheel-recovery flow with `ntm git`. |
| 34 | `grep` | Search pane output with regex | **USE** | WIRE-IT-QUEUED - opwu8 | Queue wire-in bead (opwu8); High-leverage. Replace pipe-grep patterns across multiple scripts. |
| 35 | `guards` | Agent Mail pre-commit guards | **ISSUE** | RECLASSIFIED-ISSUE - Jeff issue manifest pending | Reclassified ISSUE: Jeff issue manifest pending per 12-NOT-WIRED-DISPOSITIONS.md; do not wire until contract clarifies. |
| 36 | `handoff` | Create or manage session handoffs | **USE** | LATENT-USE - monitor; focused regression probe | Replace `/flywheel:handoff` skill's session-pause primitive with `ntm handoff`. Flywheel keeps the prose handoff doc on top. LATENT: 2 callsite(s); add focused regression probe. |
| 37 | `health` | Health status of session agents | **USE** | VERIFIED-USE - .flywheel/scripts/team-pulse-heartbeat.sh:82 | Already wired. Extend to additional flywheel scripts. Verification: 19 callsites; top .flywheel/scripts/team-pulse-heartbeat.sh:82. |
| 38 | `help` | Help about any command | EXCLUDED | EXCLUDED - no-fit/interactive/self-referential | Self-referential. |
| 39 | `history` | View prompt history | **USE** | VERIFIED-USE - .flywheel/scripts/dispatch-and-log.sh:90 | Replace L91 prompt-visible probe in `verify-callback-delivery.sh` with `ntm history`. Verification: 6 callsites; top .flywheel/scripts/dispatch-and-log.sh:90. |
| 40 | `hooks` | Git hooks for quality + coordination | **ISSUE** | RECLASSIFIED-ISSUE - Jeff issue manifest pending | Reclassified ISSUE: Jeff issue manifest pending per 12-NOT-WIRED-DISPOSITIONS.md; do not wire until contract clarifies. |
| 41 | `init` | Initialize NTM for project | **WRAP** (alias) | RECLASSIFIED-WRAP-ALIAS - .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native init during onboarding | Already consumed by wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native init during onboarding. Update inventory as WRAP alias, not direct unverified USE. |
| 42 | `interrupt` | Send Ctrl+C to all agent panes | **USE** | VERIFIED-USE - .flywheel/scripts/recovery-escape-then-reprompt.sh:18 | Replace hand-rolled C-c in `recovery-escape-then-reprompt.sh`. Verification: 3 callsites; top .flywheel/scripts/recovery-escape-then-reprompt.sh:18. |
| 43 | `kernel` | Inspect command kernel registry | EXCLUDED | RECLASSIFIED-EXCLUDED - Kernel registry inspection is an NTM developer surface. Flywheel can consume exported templates/context without making kernel a runtime dependency | Reclassified EXCLUDED: Kernel registry inspection is an NTM developer surface. Flywheel can consume exported templates/context without making kernel a runtime dependency. |
| 44 | `kill` | Kill a tmux session | EXCLUDED | RECLASSIFIED-EXCLUDED - Direct session kill is intentionally not a flywheel automation primitive; recovery uses respawn, wait, health, and explicit dangerous-drill gates | Reclassified EXCLUDED: Direct session kill is intentionally not a flywheel automation primitive; recovery uses respawn, wait, health, and explicit dangerous-drill gates. |
| 45 | `level` | View/change CLI proficiency tier | EXCLUDED | RECLASSIFIED-EXCLUDED - CLI proficiency tier is human/operator education. It does not advance continuous orchestrator uptime once onboarding is established | Reclassified EXCLUDED: CLI proficiency tier is human/operator education. It does not advance continuous orchestrator uptime once onboarding is established. |
| 46 | `list` | List all tmux sessions | **USE** | VERIFIED-USE - .flywheel/scripts/fleet-coherence-scan.sh:15 | Already wired. Verification: 11 callsites; top .flywheel/scripts/fleet-coherence-scan.sh:15. |
| 47 | `lock` | Reserve files via Agent Mail | **ISSUE** | ISSUE-CANDIDATE - research/Jeff issue path | **Possible upstream gap:** flywheel uses MCP Agent Mail directly (`mcp__mcp-agent-mail__reserve_files`); `ntm lock` may not cover the same operation surface. **File research bead → if equivalent, USE; if missing fields, file Jeff issue to bridge.** |
| 48 | `locks` | Manage file reservations | **ISSUE** (companion to #47) | ISSUE-CANDIDATE - research/Jeff issue path | Same path. |
| 49 | `logs` | Aggregate + filter logs from agents | **USE** | LATENT-USE - monitor; focused regression probe | Replace flywheel hand-rolled log aggregation. LATENT: 1 callsite(s); add focused regression probe. |
| 50 | `mail` | Human Overseer messaging to agents | **USE** | VERIFIED-USE - .flywheel/scripts/agent-mail-send-redacted.sh:51 | Replace `agent-mail-send-redacted.sh` for human-orch broadcasts. Verification: 4 callsites; top .flywheel/scripts/agent-mail-send-redacted.sh:51. |
| 51 | `memory` | Interact with CASS Memory | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace direct `cm` calls. |
| 52 | `message` | Agent Mail messaging | **USE** | LATENT-USE - monitor; focused regression probe | Already wired in 2 scripts. Extend `agentmail-registration-broadcast.sh`. LATENT: 2 callsite(s); add focused regression probe. |
| 53 | `metrics` | View + manage success metrics | **USE** (today's W1M wrapper) | WRAP-TERRITORY - evidence wrapper retained | The W1M wrapper exists because flywheel needs metric→gate-action mapping that ntm metrics doesn't provide. **WRAP-territory** — flywheel-specific. |
| 54 | `models` | Manage local Ollama models | EXCLUDED | RECLASSIFIED-EXCLUDED - Ollama model management is local model hygiene, not a current flywheel orchestration primitive. No direct hand-rolled NTM equivalent exists in today's plan | Reclassified EXCLUDED: Ollama model management is local model hygiene, not a current flywheel orchestration primitive. No direct hand-rolled NTM equivalent exists in today's plan. |
| 55 | `modes` | Browse + explore reasoning modes | EXCLUDED | RECLASSIFIED-EXCLUDED - Reasoning modes are advisory/operator knowledge, not fleet substrate. Keep out of the direct USE set unless a future dispatcher selects modes programmatically | Reclassified EXCLUDED: Reasoning modes are advisory/operator knowledge, not fleet substrate. Keep out of the direct USE set unless a future dispatcher selects modes programmatically. |
| 56 | `openapi` | OpenAPI spec management | EXCLUDED | RECLASSIFIED-EXCLUDED - OpenAPI generation is a service/API exposure concern. Flywheel does not currently operate an NTM REST API contract that needs this surface | Reclassified EXCLUDED: OpenAPI generation is a service/API exposure concern. Flywheel does not currently operate an NTM REST API contract that needs this surface. |
| 57 | `overlay` | Floating overlay above panes | EXCLUDED | RECLASSIFIED-EXCLUDED - Overlay is interactive UI. It can be documented for operators but should not be counted as automated wire-in | Reclassified EXCLUDED: Overlay is interactive UI. It can be documented for operators but should not be counted as automated wire-in. |
| 58 | `palette` | Interactive command palette | **USE** | LATENT-USE - monitor; focused regression probe | Document. LATENT: 1 callsite(s); add focused regression probe. |
| 59 | `personas` | Manage agent personas | EXCLUDED | RECLASSIFIED-EXCLUDED - NTM personas are agent-prompt personas, while flywheel's current profile logic is CAAM/account and worker identity. This row conflates concepts and should leave direct USE | Reclassified EXCLUDED: NTM personas are agent-prompt personas, while flywheel's current profile logic is CAAM/account and worker identity. This row conflates concepts and should leave direct USE. |
| 60 | `profiles` | Manage agent profiles | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace persona-selection hand-rolling in CAAM rotate flow. |
| 61 | `pipeline` | Run + manage workflow pipelines | **USE** (today's W3aP wrapper) | LATENT-USE - monitor; focused regression probe | W3aP wrapper exists for shadow-mode dry-run dag while #124 blocks daemon. **After #124, delete shadow wrapper, use native.** LATENT: 1 callsite(s); add focused regression probe. |
| 62 | `plugins` | Manage installed plugins | EXCLUDED | RECLASSIFIED-EXCLUDED - Plugin management is extension administration, not flywheel uptime substrate. No current plugin lifecycle work is in scope | Reclassified EXCLUDED: Plugin management is extension administration, not flywheel uptime substrate. No current plugin lifecycle work is in scope. |
| 63 | `policy` | NTM policy configuration | **USE** (today's W3bP wrapper) | WRAP-TERRITORY - evidence wrapper retained | W3bP wrapper exists because flywheel adds privilege-escalation block + warn-only validation gate semantics. **WRAP-territory.** |
| 64 | `preflight` | Validate prompt before sending | **USE** (today's W2P wrapper) | WRAP-TERRITORY - evidence wrapper retained | W2P wrapper exists because flywheel needs L91 four-state receipt (transport_accepted + prompt_visible + submitted + work_started). **WRAP-territory** — flywheel-doctrine. |
| 65 | `profile` | Session spawn profiles | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace flywheel hardcoded session-shape (pane 1=claude, panes 2-4=codex). |
| 66 | `quick` | Quick project setup | EXCLUDED | RECLASSIFIED-EXCLUDED - Quick creates a new project skeleton; flywheel-onboard is the richer repo-local onboarding contract, so direct quick use is intentionally out of scope | Reclassified EXCLUDED: Quick creates a new project skeleton; flywheel-onboard is the richer repo-local onboarding contract, so direct quick use is intentionally out of scope. |
| 67 | `quota` | Check agent quota usage | **USE** (today's W1Q wrapper) | WRAP-TERRITORY - evidence wrapper retained | W1Q wrapper exists because flywheel needs threshold-classification + unknown-provider warn semantics. **WRAP-territory.** |
| 68 | `rebalance` | Workload distribution | **USE** | VERIFIED-USE - .flywheel/scripts/peer-orch-blocker-watch.sh:13 | W4T queued (dry-run). Verification: 3 callsites; top .flywheel/scripts/peer-orch-blocker-watch.sh:13. |
| 69 | `recipes` | Session recipes (presets) | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace flywheel session-bootstrap with `ntm recipes`. |
| 70 | `redact` | Redaction utilities | **ISSUE** | ISSUE-CANDIDATE - research/Jeff issue path | **Possible gap:** flywheel-scrub-secret-scan-wrapper covers cases ntm redact may not. File research bead — if covered, **delete W2S wrapper and USE native**. If gaps exist, **file Jeff issue**, then USE once shipped. |
| 71 | `replay` | Replay prompt from history | **USE** | VERIFIED-USE - .flywheel/scripts/recovery-escape-then-reprompt.sh:18 | Replace flywheel snapshot-then-resend in recovery flow. Verification: 3 callsites; top .flywheel/scripts/recovery-escape-then-reprompt.sh:18. |
| 72 | `repo` | Repo management commands | **ISSUE** | RECLASSIFIED-ISSUE - Jeff issue manifest pending | Reclassified ISSUE: Jeff issue manifest pending per 12-NOT-WIRED-DISPOSITIONS.md; do not wire until contract clarifies. |
| 73 | `respawn` | Kill + restart worker agents | **USE** | VERIFIED-USE - .flywheel/scripts/dispatch-and-verify.sh:90 | Already wired. Canonical primitive. Verification: 26 callsites; top .flywheel/scripts/dispatch-and-verify.sh:90. |
| 74 | `resume` | Resume work from handoff | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Companion to #36. |
| 75 | `review-queue` | List idle agents + suggest review | **ISSUE** | ISSUE-CANDIDATE - research/Jeff issue path | **Different abstraction from `idle-state-probe.sh`.** Flywheel's idle classifier emits an L85-doctrine taxonomy (`dispatching/cooldown/light_queue/saturated/disabled_class`) that `ntm review-queue` doesn't model. **File Jeff issue: extend `ntm review-queue` to expose L85-class taxonomy, or expose a structured idle-state schema.** Then USE. |
| 76 | `rollback` | Restore session to checkpoint | **WRAP** (alias) | RECLASSIFIED-WRAP-ALIAS - .flywheel/scripts/ntm-checkpoint-rollback-guard.sh:18-43 defines rollback receipt schema and authorized rollback validation operations | Already consumed by wrapper: .flywheel/scripts/ntm-checkpoint-rollback-guard.sh:18-43 defines rollback receipt schema and authorized rollback validation operations. Update inventory as WRAP alias, not direct unverified USE. |
| 77 | `rotate` | Rotate to different account | **USE** (today's W0A wrapper) | VERIFIED-USE - .flywheel/scripts/caam-auto-rotate-on-usage-limit.sh:31 | W0A wrapper exists because flywheel needs CAAM profile selection layer + idempotency-receipt. **WRAP-territory.** Native does the actual rotate. Verification: 10 callsites; top .flywheel/scripts/caam-auto-rotate-on-usage-limit.sh:31. |
| 78 | `safety` | Destructive command protection | **USE** (today's W2D wrapper, advisory) | LATENT-USE - monitor; focused regression probe | Native is advisory. **DCG retains authority** — that's flywheel-territory because it's a defense-in-depth doctrine layer. **WRAP-territory.** LATENT: 1 callsite(s); add focused regression probe. |
| 79 | `save` | Save pane outputs to files | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace hand-rolled tail-capture. |
| 80 | `scale` | Scale agents to target counts | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace flywheel worker-slot-ledger hand-roll. |
| 81 | `scan` | Run UBS scanner | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace flywheel UBS pipeline. |
| 82 | `scrub` | Scan NTM artifacts for leaked secrets | **USE** (today's W2S wrapper) | ISSUE/WRAP-PENDING - redact/scrub comparison follow-up | See #70 — possibly **DELETE wrapper** and USE native if equivalent. Research bead pending. |
| 83 | `search` | Search archived agent output via CASS | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Direct use. |
| 84 | `send` | Send prompt to agent panes | **USE** | VERIFIED-USE - .flywheel/scripts/build-dispatch-packet.sh:132 | Already canonical (16 callsites). Verification: 48 callsites; top .flywheel/scripts/build-dispatch-packet.sh:132. |
| 85 | `serve` | HTTP server + REST + event streaming | **USE** (today's W1S wrapper) | WRAP-TERRITORY - evidence wrapper retained | W1S wrapper exists because flywheel needs redacted payload + loopback-bind defaults. **WRAP-territory** for security envelope; native does transport. |
| 86 | `session-templates` | Multi-agent template configs | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Companion to #68. |
| 87 | `sessions` | Manage saved session states | **USE** | VERIFIED-USE - .flywheel/scripts/fleet-coherence-scan.sh:16 | Already wired. Verification: 7 callsites; top .flywheel/scripts/fleet-coherence-scan.sh:16. |
| 88 | `setup` | Initialize NTM for project | **USE** | LATENT-USE - monitor; focused regression probe | Add to onboarding. LATENT: 2 callsite(s); add focused regression probe. |
| 89 | `shell` | Shell integration script | **WRAP** (alias) | RECLASSIFIED-WRAP-ALIAS - .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native shell during onboarding | Already consumed by wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native shell during onboarding. Update inventory as WRAP alias, not direct unverified USE. |
| 90 | `spawn` | Create session + spawn agents | **WRAP** (alias) | RECLASSIFIED-WRAP-ALIAS - .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native spawn during onboarding | Already consumed by wrapper: .flywheel/scripts/flywheel-onboard.sh:236-243 plans and invokes native spawn during onboarding. Update inventory as WRAP alias, not direct unverified USE. |
| 91 | `status` | Detailed session status | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Already wired (`coordinator status`). |
| 92 | `summary` | Activity summary for agents | **USE** | VERIFIED-USE - .flywheel/scripts/team-pulse-heartbeat.sh:82 | Replace `daily-report.sh` per-agent rollup. Verification: 5 callsites; top .flywheel/scripts/team-pulse-heartbeat.sh:82. |
| 93 | `support-bundle` | Diagnostic bundle archive | **ISSUE** | RECLASSIFIED-ISSUE - Jeff issue manifest pending | Reclassified ISSUE: Jeff issue manifest pending per 12-NOT-WIRED-DISPOSITIONS.md; do not wire until contract clarifies. |
| 94 | `swarm` | Weighted multi-project swarm | **USE** | VERIFIED-USE - .flywheel/scripts/peer-orch-blocker-watch.sh:13 | Replace `peer-orch-blocker-watch.sh` cross-session hand-roll. Verification: 4 callsites; top .flywheel/scripts/peer-orch-blocker-watch.sh:13. |
| 95 | `template` | Manage prompt templates | **USE** | VERIFIED-USE - .flywheel/scripts/build-dispatch-packet.sh:43 | Replace `dispatch-templates/` directory bootstrap. Verification: 3 callsites; top .flywheel/scripts/build-dispatch-packet.sh:43. |
| 96 | `timeline` | Session timeline history | **USE** | VERIFIED-USE - .flywheel/scripts/dispatch-log-fitness-invariant.sh:17 | Replace `dispatch-log-fitness-invariant.sh` event source. Verification: 3 callsites; top .flywheel/scripts/dispatch-log-fitness-invariant.sh:17. |
| 97 | `tutorial` | Interactive NTM tutorial | EXCLUDED | EXCLUDED - no-fit/interactive/self-referential | One-shot interactive. |
| 98 | `unlock` | Release file reservations | **ISSUE** (companion to #47) | ISSUE-CANDIDATE - research/Jeff issue path | Same path. |
| 99 | `upgrade` | Upgrade NTM | **USE** | VERIFIED-USE - .flywheel/scripts/jeff-binary-version-watchtower.sh:60 | Wire into `jeff-binary-version-watchtower.sh`. Verification: 3 callsites; top .flywheel/scripts/jeff-binary-version-watchtower.sh:60. |
| 100 | `version` | Print version | **USE** | VERIFIED-USE - .flywheel/scripts/jeff-binary-version-watchtower.sh:60 | Wire into doctor for version-drift detection. Verification: 4 callsites; top .flywheel/scripts/jeff-binary-version-watchtower.sh:60. |
| 101 | `view` | View all panes | EXCLUDED | RECLASSIFIED-EXCLUDED - View is an interactive pane inspection surface. Automation should use copy/logs/save/status instead | Reclassified EXCLUDED: View is an interactive pane inspection surface. Automation should use copy/logs/save/status instead. |
| 102 | `wait` | **Wait until agents reach desired state** | **USE** | VERIFIED-USE - .flywheel/scripts/worker-stall-alert-probe.sh:27 | **HIGHEST LEVERAGE.** Replaces polling loops in 6+ flywheel scripts. **Delete `sleep + activity` polling wherever it appears.** Verification: 14 callsites; top .flywheel/scripts/worker-stall-alert-probe.sh:27. |
| 103 | `watch` | Stream agent output / file watcher | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Companion to #101. Replace daemon polling. |
| 104 | `work` | Intelligent work distribution | **ISSUE** | ISSUE-CANDIDATE - research/Jeff issue path | **Possible duplicate of `assign`.** Research bead — if equivalent, pick one. If `work` is more flexible than `assign`, file Jeff issue clarifying contract differences, then USE the right one. |
| 105 | `workflows` | Orchestration patterns | **USE** | WIRE-IT-QUEUED - wave-2 P1/P2 TBD | Queue wire-in bead (wave-2 P1/P2 TBD); Replace flywheel multi-bead chaining. |
| 106 | `worktree` | Git worktrees for agent isolation | **ISSUE** | ISSUE-CANDIDATE - research/Jeff issue path | **prd skill currently hand-rolls worktrees.** File research bead — if `ntm worktree` is feature-equivalent, **delete prd's worktree code and USE native**. If gaps, file Jeff issue. |
| 107 | `worktrees` | Git worktrees for agent isolation | **ISSUE** | ISSUE-CANDIDATE - research/Jeff issue path | **prd skill currently hand-rolls worktrees.** File research bead — if `ntm worktree` is feature-equivalent, **delete prd's worktree code and USE native**. If gaps, file Jeff issue. |
| 108 | `zoom` | Zoom a specific pane | EXCLUDED | EXCLUDED - no-fit/interactive/self-referential | Interactive. |

**Tally:** verification cohort=86 (`VERIFIED-USE`=24, `LATENT-USE`=12, `WIRE-IT-QUEUED`=25, `RECLASSIFIED-EXCLUDED`=14, `RECLASSIFIED-WRAP-ALIAS`=6, `RECLASSIFIED-ISSUE`=5); total NTM surfaces=108.

---

## The 8 ISSUE candidates (file research beads, then file Jeff issues if confirmed gap)

| # | Surface | Suspected gap | Action |
|---|---|---|---|
| 47 | `lock` | MCP Agent Mail vs `ntm lock` operation surface mismatch | Research bead → field-by-field compare → file Jeff issue if gap |
| 48 | `locks` | Same | Same |
| 70 | `redact` | flywheel `scrub` covers SEC-class fixtures ntm may not | Research bead → audit fixture coverage → file Jeff if missing |
| 75 | `review-queue` | Doesn't expose L85 idle-state-class taxonomy | File Jeff issue: extend with structured idle-state schema |
| 82 | `scrub` (revisit via #70) | Possible duplicate of `redact` | Research path |
| 98 | `unlock` | Companion to #47 | Same |
| 104 | `work` | Possible duplicate of `assign` | Research bead → contract compare |
| 106/107 | `worktree`/`worktrees` | prd skill duplicates? | Research bead → field-by-field |

---

## The 8 legitimate WRAP-territory (today's W0–W3b ships that should NOT delete)

These wrappers exist because **flywheel-specific evidence/contracts/doctrine** ride on top of native. They are not duplicates of ntm functionality:

| # | Wrapper | Why WRAP (what it adds beyond ntm) |
|---|---|---|
| W0A | `caam-auto-rotate-on-usage-limit.sh` | CAAM profile selection + idempotency-receipt + rotation ledger |
| W1Q | `ntm-quota-proactive-probe.sh` | Threshold-classification + unknown-provider warn semantics |
| W1M | `ntm-metrics-doctor-probe.sh` | Metric→gate-action mapping (flywheel-doctor-specific) |
| W1S | `ntm-serve-eventstream-bridge.sh` | Redacted payloads + loopback-bind defaults (security envelope) |
| W2P | `ntm-preflight-l91-wrapper.sh` | L91 four-state receipt (transport+visible+submitted+work-started) |
| W2D | `ntm-safety-dcg-sibling.sh` | DCG-as-authority defense-in-depth doctrine |
| W2A | `ntm-approve-human-gates.sh` | Exact-question receipt + 6-class blocker enum |
| W3bA | `ntm-audit-receipts.sh` | Canonical-writer + hash-chain enforcement (revealed flywheel-f12e6) |
| W3bP | `ntm-policy-contracts.sh` | Privilege-escalation block + warn-only gate semantics |
| W3bR | `ntm-checkpoint-rollback-guard.sh` | Dirty-worktree-scoped-exception protocol |

W0T (skillos doctrine), W3aC and W3aP (shadow-mode while #124 blocks daemon) are **transitional** — when ntm#124 lands, W3aC and W3aP are **DELETE**.

---

## Flywheel scripts: DELETE / DELEGATE / WRAP

Applying the rule to all 231 flywheel scripts:

### Category 1 — DELETE-OR-REWRITE-AS-CALLER (~30 scripts)

These hand-roll a function ntm provides natively. **Replace the body with a thin call to ntm.**

| Script | Surface to delegate to | Action |
|---|---|---|
| `idle-pane-auto-dispatch.sh` (699 LOC) | `ntm wait` + `ntm watch` | Rewrite as event-driven; expect ~80% LOC reduction |
| `worker-auto-respawn-watchdog.sh` (451 LOC) | `ntm wait` + `ntm respawn` | Rewrite as event-driven |
| `peer-orch-freeze-monitor.sh` (772 LOC) | `ntm watch` + `ntm activity` | Rewrite |
| `peer-orch-productivity-watch.sh` (621 LOC) | `ntm watch` | Rewrite |
| `halt-disease-watchdog.sh` (317 LOC) | `ntm watch` | Rewrite |
| `worker-stall-alert-probe.sh` (370 LOC) | `ntm wait --condition=generating` | Rewrite |
| `recovery-escape-then-reprompt.sh` (200 LOC) | `ntm interrupt` + `ntm replay` | Rewrite |
| `verify-callback-delivery.sh` (183 LOC) | `ntm history` | Rewrite (replaces L91 hand-roll) |
| `recency-weighted-two-truth-classifier.sh` (220 LOC) | `ntm diff` + `ntm activity` | Rewrite |
| `ntm-fleet-health.sh` (289 LOC) | `ntm health` (loop over sessions) | Already calls; trim to thin caller |
| `agentmail-registration-broadcast.sh` (322 LOC) | `ntm message --broadcast` | Rewrite |
| `agent-mail-send-redacted.sh` (323 LOC) | `ntm mail` + `ntm redact` (pending #69) | Rewrite after research |
| `team-pulse-heartbeat.sh` (470 LOC) | `ntm health` + `ntm summary` | Rewrite |
| (remainder enumerated in `/tmp/ntm-script-counts.tsv`) | | |

**Estimated LOC removed by Category 1 deletion: ~5,000 LOC.**

### Category 2 — KEEP-AS-CALLER (already a thin wrapper) (~58 scripts)

These already correctly delegate to ntm. Audit each for any remaining hand-rolled portions; trim where found.

Examples: `dispatch-and-log.sh`, `dispatch-and-verify.sh`, `peer-orch-respawn-permit.sh`, `frozen-pane-detector.sh` (mostly delegate; flywheel-specific scrollback delta detector is **WRAP-territory** because no ntm equivalent exists for "stuck-spinner-while-state=THINKING" classification).

### Category 3 — KEEP-AS-WRAP (flywheel-doctrine, no ntm equivalent expected) (~140 scripts)

These encode flywheel-domain artifacts (mission/INCIDENTS/fuckup/CASS/br/agent-mail-MCP/doctrine) with no ntm-native equivalent. Each is a **legitimate WRAP** by the rule:

Examples by domain:
- **Doctrine validators** (mission-fitness, mission-anchor, four-lens, three-judges, publishability, ladder-promote): no ntm equivalent — flywheel-doctrine territory
- **br-substrate guards** (br-close-with-gate, br-create-validated, br-db-corruption-monitor, beads-db-recover): br is owned by Jeff; flywheel adds the close-gate contract
- **Callback/dispatch evidence** (callback-receipt-validator, dispatch-canonical-cli-validator, dispatch-log-fitness-invariant, two-truth-sources-validator): L71/L91/L67 doctrine — flywheel-territory
- **Storage/disk/jeff-corpus** (storage-prune, jeff-corpus-doctor, disk-observer): out of ntm scope
- **Tests/fixtures** (`tests/`-prefixed): updated as part of the wire-in beads they test
- **Identity registry** (orch-worker-identity-manifest, identity-stability-tuple-validator, agent-mail-identity-canonical-validator): pending #4 audit (`ntm agents`); may move to Cat 1
- **Doctor probes** (capacity-halt-*, recovery-doctor-probe, low-bead-threshold-detector): flywheel-doctor-specific

### Category 4 — DELETE-OBSOLETE (~5 scripts)

One-off batch scripts dated specifically: `disk-reclaim-batch-2026-05-07.sh`, `picoz-archive-and-fresh-2026-05-07.sh`, `regenerate-dicklesworthstone-sources.sh`, etc. **Delete after current execution is verified.**

---

## Rollout: bead per surface, no exceptions

For each of the 108 surfaces:
- **USE rows (86):** file a bead per script that gets deleted/rewritten in Category 1, OR a bead to wire native into a doctor row. Tier 1 (`ntm wait`/`ntm watch`/`doctor`/`grep`/`interrupt`/`history`/`version`) goes first — biggest LOC delete.
- **ISSUE rows (8):** file a research bead → audit gap → file Jeff issue → track via `jeff-issue-chain` → USE when fixed.
- **WRAP rows (8 W0–W3b ships):** already shipped today.
- **EXCLUDED rows (6):** file a 1-line "skipped because X" row in the inventory; no bead.

**Bead count target: ~30 Category-1 rewrite beads + 8 ISSUE research beads = 38 beads** to file across the next 2 days. That's the actual migration backlog.

---

## Refresh recipe

```bash
ntm --help | awk '/^Available Commands:/,/^Flags:/' | grep -E '^  [a-z]' | awk '{print $1}' | sort -u > /tmp/ntm-subcommands.txt
> /tmp/ntm-subcommand-coverage.tsv
while IFS= read -r sub; do
  total=$(grep -hE "(ntm $sub |\\\$NTM $sub |--robot-$sub)" /Users/josh/Developer/flywheel/.flywheel/scripts/*.sh 2>/dev/null | wc -l | tr -d ' ')
  files=$(grep -lE "(ntm $sub |\\\$NTM $sub |--robot-$sub)" /Users/josh/Developer/flywheel/.flywheel/scripts/*.sh 2>/dev/null | wc -l | tr -d ' ')
  printf '%s\t%s\t%s\n' "$sub" "$total" "$files" >> /tmp/ntm-subcommand-coverage.tsv
done < /tmp/ntm-subcommands.txt
```

## Cross-references

- **Plan:** `.flywheel/plans/ntm-surface-utilization-migration-2026-05-06/02-REFINE-r2.md`
- **L29 (NTM-only pane I/O):** `AGENTS.md` lines 91–190
- **Coordinator wire-in test:** `tests/test_ntm_coordinator_wire.sh`
- **Today's W0–W3b ships:** flywheel-x1p0o, h9swh, kboe9, d7ci4, jztnm, fcyrt, wojns, 981x5, dt5lf, r4d7r, ewa3g, h3exf, hgex7, imcs2, j3if6, rmwgg, f12e6
- **Upstream blockers:** ntm#124 (assign --watch --auto unsafe)

L112: OK_ntm_surface_inventory_USE_ISSUE_WRAP_2026_05_07
