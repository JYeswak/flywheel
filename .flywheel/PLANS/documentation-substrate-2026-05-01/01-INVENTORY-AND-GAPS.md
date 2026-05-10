---
title: "Documentation Substrate Inventory and Gap Matrix"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [Survey Inputs](#survey-inputs)
- [Totals](#totals)
  - [Rows By Kind](#rows-by-kind)
- [Proposed README Schema](#proposed-readme-schema)
- [Top-20 Priority Backfill List](#top-20-priority-backfill-list)
- [Cross-Cutting Gap Themes](#cross-cutting-gap-themes)
  - [Theme A — Systemic Category Gaps](#theme-a-systemic-category-gaps)
  - [Theme B — Repeated README Blocks](#theme-b-repeated-readme-blocks)
  - [Theme C — Stale Existing Docs](#theme-c-stale-existing-docs)
  - [Theme D — Best-Fit Existing Skills](#theme-d-best-fit-existing-skills)
  - [Theme E — Mermaid Placement](#theme-e-mermaid-placement)
- [Validation Ladder](#validation-ladder)
- [Full Inventory Matrix](#full-inventory-matrix)
# Documentation Substrate Inventory and Gap Matrix

Lane 1 inventory only. This document does not implement docs substrate, hooks, doctor checks, or process changes.

## Survey Inputs

- Socraticode queries: 2 (`flywheel`, `~/.claude/skills`).
- Skill references skimmed: `planning-workflow`, `readme-writing`, `living-documentation`, `codebase-archaeology`.
- Concrete leverage signals: dispatch log, fuckup log, ntm fleet health log, doctrine-sync ledger, flywheel logs, substrate consumers, mtime recency, load-bearing primitive classification.
- Mermaid scan: 0 existing Mermaid diagrams across inspected flywheel docs/hook/command surfaces.

## Totals

- Total inventory rows: 732
- Missing README/doc surface rows: 154
- Rows with Mermaid: 1
- Rows stale by mtime >30d: 52
- Grade distribution: A=0, B=236, C=342, F=154

### Rows By Kind

| Kind | Rows |
|---|---:|
| binary | 29 |
| command | 20 |
| dispatch-template | 1 |
| doc | 4 |
| hook | 49 |
| l-rule | 18 |
| memory | 22 |
| plist | 111 |
| registry-row | 14 |
| skill | 464 |

## Proposed README Schema

| Field | Meaning |
|---|---|
| Purpose | What this artifact does and when an agent should touch it. |
| Entry points | Commands, hook event/matcher, LaunchAgent label, slash command, or skill trigger. |
| State surfaces | Files, ledgers, DB rows, panes, or external services read/written. |
| Freshness | `last_validated_ts`, validation command, expected cadence, and stale signals. |
| Examples | Copy-paste dry-run and real-run examples with expected output shape. |
| Troubleshooting | Top failure modes, exact probes, recovery paths, and escalation boundary. |
| Diagram | Mermaid sequence/state diagram for multi-step or feedback-loop artifacts. |
| Ownership | Owning skill/session/bead, consumers, and related L-rules. |

## Top-20 Priority Backfill List

| # | Artifact | Kind | Leverage | Grade | Proposed README | Mermaid? | Effort | README needs to cover |
|---:|---|---|---:|---|---|---|---|---|
| 1 | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop` | binary | 5 | F | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop.README.md` | yes | M | Document CLI purpose, subcommands/options, env vars, state files touched, validation commands, common failure modes for `flywheel-autoloop`. |
| 2 | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop` | binary | 5 | F | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop.README.md` | yes | M | Document CLI purpose, subcommands/options, env vars, state files touched, validation commands, common failure modes for `flywheel-loop`. |
| 3 | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-lock-repair` | binary | 5 | F | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-lock-repair.README.md` | no | M | Document CLI purpose, subcommands/options, env vars, state files touched, validation commands, common failure modes for `flywheel-lock-repair`. |
| 4 | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync` | binary | 5 | F | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync.README.md` | yes | M | Document CLI purpose, subcommands/options, env vars, state files touched, validation commands, common failure modes for `flywheel-doctrine-sync`. |
| 5 | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-refresh-source` | binary | 5 | F | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-refresh-source.README.md` | no | M | Document CLI purpose, subcommands/options, env vars, state files touched, validation commands, common failure modes for `flywheel-refresh-source`. |
| 6 | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-skillos-relay` | binary | 5 | F | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-skillos-relay.README.md` | yes | M | Document CLI purpose, subcommands/options, env vars, state files touched, validation commands, common failure modes for `flywheel-skillos-relay`. |
| 7 | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict` | binary | 5 | F | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict.README.md` | no | M | Document CLI purpose, subcommands/options, env vars, state files touched, validation commands, common failure modes for `flywheel-verdict`. |
| 8 | `/Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist` | plist | 5 | F | `/Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist.README.md` | yes | M | Document LaunchAgent label, cadence, ProgramArguments, state/log files, manual load/unload checks, and failure triage for `ai.zeststream.flywheel-autoloop.plist`. |
| 9 | `/Users/josh/Library/LaunchAgents/ai.zeststream.alps-flywheel-loop.plist` | plist | 5 | F | `/Users/josh/Library/LaunchAgents/ai.zeststream.alps-flywheel-loop.plist.README.md` | no | M | Document LaunchAgent label, cadence, ProgramArguments, state/log files, manual load/unload checks, and failure triage for `ai.zeststream.alps-flywheel-loop.plist`. |
| 10 | `/Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-doctrine-sync.plist` | plist | 5 | F | `/Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-doctrine-sync.plist.README.md` | no | M | Document LaunchAgent label, cadence, ProgramArguments, state/log files, manual load/unload checks, and failure triage for `ai.zeststream.flywheel-doctrine-sync.plist`. |
| 11 | `/Users/josh/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist` | plist | 5 | F | `/Users/josh/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist.README.md` | yes | M | Document LaunchAgent label, cadence, ProgramArguments, state/log files, manual load/unload checks, and failure triage for `ai.zeststream.ntm-fleet-health.plist`. |
| 12 | `/Users/josh/Library/LaunchAgents/ai.zeststream.skillos-flywheel-loop.plist` | plist | 5 | F | `/Users/josh/Library/LaunchAgents/ai.zeststream.skillos-flywheel-loop.plist.README.md` | no | M | Document LaunchAgent label, cadence, ProgramArguments, state/log files, manual load/unload checks, and failure triage for `ai.zeststream.skillos-flywheel-loop.plist`. |
| 13 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | no | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `dicklesworthstone-beads-rust`. |
| 14 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | no | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `dicklesworthstone-cass`. |
| 15 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | yes | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `dicklesworthstone-mcp-agent-mail`. |
| 16 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | yes | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `dicklesworthstone-ntm`. |
| 17 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | no | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `firewall-policy-bundle`. |
| 18 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | yes | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `mission-anchor-bundle`. |
| 19 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | yes | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `skill-os-kernel-bundle`. |
| 20 | `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json` | registry-row | 5 | F | `/Users/josh/.claude/skills/.flywheel/data/README.md` | no | M | Document substrate purpose, owned components, consumers, health probe, rollback path, and freshness proof for `substrate-intake-bundle`. |

## Cross-Cutting Gap Themes

### Theme A — Systemic Category Gaps
Binaries, hooks, and LaunchAgents are the largest load-bearing surfaces with the weakest standalone documentation. They are executable operational substrate, but most rows grade F because their purpose, inputs, side effects, and verification commands live only in code, dispatch scrollback, or launchd state. Skills and slash commands fare better because SKILL.md/command markdown exists, but they still generally lack freshness metadata and diagrams.

### Theme B — Repeated README Blocks
The same documentation blocks recur across many artifacts: environment variables, state/ledger paths, dry-run vs mutating commands, hook stdin JSON envelopes, L61/NTM callback expectations, rollback/safe-stop procedures, and doctor/freshness probes. The inventory repeatedly shows that agents must rediscover these blocks from shell source instead of a stable doc surface.

### Theme C — Stale Existing Docs
Existing doc-equivalent artifacts mostly grade C/B because they lack `last_validated_ts`, not because they are empty. The mtime staleness metric found 52 rows where a README/doc surface is more than 30 days older than the artifact; the larger issue is missing validation metadata across hundreds of SKILL.md, command, memory, and doctrine rows.

### Theme D — Best-Fit Existing Skills
`readme-writing` best fits public-facing README shape and command/reference examples; `technical-writing` is stronger for runbooks, operational references, and troubleshooting; `living-documentation` supplies freshness and staleness criteria; `codebase-archaeology` supplies the survey method for deriving entry points and state surfaces before drafting. This lane records fit only; procedure wiring belongs to Lane 3.

### Theme E — Mermaid Placement
There are zero Mermaid diagrams in the inspected flywheel documentation surfaces. The highest-value diagram targets are feedback loops and cross-session flows: `flywheel-loop`, `flywheel-autoloop`, doctrine sync, skillos relay, readiness/transport gates, tick/worker-tick slash commands, ntm fleet health, and the mission/skill-os substrate bundles. These are the flows where prose-only docs are most likely to leave a fresh agent guessing about order and feedback.

## Validation Ladder

1. inventory_150: PASS
2. fields_populated: PASS
3. concrete_signals: PASS
4. top20_mermaid_5: PASS
5. themes_A_E: PASS
6. no_source_modifications: PASS
7. verified_paths: PASS
8. output_written: PASS

ladder_passed=yes

## Full Inventory Matrix

Notes: for skills, slash commands, memory files, and doctrine rules, the existing SKILL.md/command markdown/memory markdown/AGENTS.md section is counted as the current doc surface; the grade still penalizes missing validation timestamp, troubleshooting, runnable examples, or Mermaid. For registry rows, `path` is the verified registry file path and `artifact_id` identifies the row.

| path | artifact_id | kind | has_readme | readme_path | has_mermaid | last_validated_ts | staleness_age_days | senior_dev_grade | leverage_rank | invocation_signal_count | consumer_count | trigger | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-agents-pointer-sweep | flywheel-agents-pointer-sweep | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-anchor | flywheel-anchor | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop | flywheel-autoloop | binary | False | missing | False | missing | 0 | F | 5 | 47 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-cass-correlate | flywheel-cass-correlate | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-check | flywheel-check | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-codex-orient | flywheel-codex-orient | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-codex-snapshot | flywheel-codex-snapshot | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-dashboard | flywheel-dashboard | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-digest | flywheel-digest | binary | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync | flywheel-doctrine-sync | binary | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-domain-spec-validate | flywheel-domain-spec-validate | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-friday-digest | flywheel-friday-digest | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-inject-latest-line | flywheel-inject-latest-line | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-install-hooks | flywheel-install-hooks | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-lock-repair | flywheel-lock-repair | binary | False | missing | False | missing | 0 | F | 5 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop | flywheel-loop | binary | False | missing | False | missing | 0 | F | 5 | 20 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-outcome | flywheel-outcome | binary | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-pattern | flywheel-pattern | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality | flywheel-quality | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality-gate | flywheel-quality-gate | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-refresh-source | flywheel-refresh-source | binary | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-render-latest | flywheel-render-latest | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-skillos-relay | flywheel-skillos-relay | binary | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-source-monitor | flywheel-source-monitor | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-stale | flywheel-stale | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-summarize | flywheel-summarize | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-sync | flywheel-sync | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-trauma-check | flywheel-trauma-check | binary | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict | flywheel-verdict | binary | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/hooks/accretive-write-gate.sh | accretive-write-gate.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 74 | B | 2 | 0 | 0 | PreToolUse:Write\|Edit | n/a |
| /Users/josh/.claude/hooks/accretive-write-ledger.sh | accretive-write-ledger.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 74 | B | 2 | 0 | 0 | PostToolUse:Write\|Edit\|MultiEdit | n/a |
| /Users/josh/.claude/hooks/auto-setup-comfyui-mcp.sh | auto-setup-comfyui-mcp.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 50 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/auto-setup-ks-mcp.sh | auto-setup-ks-mcp.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 48 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/block-cron-delete.sh | block-cron-delete.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 48 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/block-service-restarts.sh | block-service-restarts.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 55 | B | 2 | 0 | 0 | PreToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/block-tmux-kill.sh | block-tmux-kill.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 52 | B | 2 | 0 | 0 | PreToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/claude-md-reference-hint.sh | claude-md-reference-hint.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | UserPromptSubmit:* | n/a |
| /Users/josh/.claude/hooks/claude-md-reference-hint.test.sh | claude-md-reference-hint.test.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/context-integrity-status.sh | context-integrity-status.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 55 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/convergence-stall-detector.sh | convergence-stall-detector.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 48 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/daily-ledger-writer.sh | daily-ledger-writer.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 49 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/flywheel-doctrine-sync-post-edit.sh | flywheel-doctrine-sync-post-edit.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 80 | B | 5 | 0 | 0 | PostToolUse:Write\|Edit\|MultiEdit | n/a |
| /Users/josh/.claude/hooks/flywheel-loop-cron-guard.sh | flywheel-loop-cron-guard.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 80 | B | 5 | 0 | 0 | PreToolUse:CronCreate\|CronDelete\|ScheduleWakeup | n/a |
| /Users/josh/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh | flywheel-loop-dispatch-transport-gate.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 79 | B | 5 | 12 | 0 | PreToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/flywheel-loop-prompt-injector.sh | flywheel-loop-prompt-injector.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 78 | B | 2 | 0 | 0 | UserPromptSubmit:* | n/a |
| /Users/josh/.claude/hooks/flywheel-loop-readiness-gate.sh | flywheel-loop-readiness-gate.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 79 | B | 5 | 0 | 0 | PreToolUse:Write\|Edit\|MultiEdit\|Bash\|Agent\|Task | n/a |
| /Users/josh/.claude/hooks/flywheel-loop-stop-injector.sh | flywheel-loop-stop-injector.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 78 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/flywheel-outcome-capture.sh | flywheel-outcome-capture.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | PostToolUse:Skill | n/a |
| /Users/josh/.claude/hooks/flywheel-session-start-deltas.sh | flywheel-session-start-deltas.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/flywheel-skillos-relay-post-edit.sh | flywheel-skillos-relay-post-edit.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 80 | B | 5 | 0 | 0 | PostToolUse:Write\|Edit\|MultiEdit | n/a |
| /Users/josh/.claude/hooks/flywheel-slash-outcome-capture.sh | flywheel-slash-outcome-capture.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | PostToolUse:SlashCommand | n/a |
| /Users/josh/.claude/hooks/grade-loop-tick.sh | grade-loop-tick.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 78 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/harvest-continue-here.sh | harvest-continue-here.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 48 | B | 2 | 0 | 0 | PostToolUse:Write\|Edit\|MultiEdit | n/a |
| /Users/josh/.claude/hooks/insight-intake-injector.sh | insight-intake-injector.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 77 | B | 2 | 0 | 0 | UserPromptSubmit:* | n/a |
| /Users/josh/.claude/hooks/mem-session-capture.sh | mem-session-capture.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 55 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/mission-anchor-injector.sh | mission-anchor-injector.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 77 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/mission-freshness-anchor.sh | mission-freshness-anchor.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 49 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/mission-pretooluse-blocker.sh | mission-pretooluse-blocker.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 77 | B | 2 | 0 | 0 | PreToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/npm-install-guard-hook.sh | npm-install-guard-hook.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 79 | B | 5 | 0 | 0 | PreToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/pipeline-enforce.sh | pipeline-enforce.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 79 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/post-bead-create.sh | post-bead-create.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 79 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/post-tool-use-refresh-cache.sh | post-tool-use-refresh-cache.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 55 | B | 2 | 0 | 0 | PostToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/pre-compact-mem-inject.sh | pre-compact-mem-inject.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 80 | B | 5 | 0 | 0 | PreCompact:* | n/a |
| /Users/josh/.claude/hooks/pre-compact-reminder.sh | pre-compact-reminder.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 79 | B | 2 | 0 | 0 | PreCompact:* | n/a |
| /Users/josh/.claude/hooks/record-skill-pass.sh | record-skill-pass.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 47 | B | 2 | 0 | 0 | PostToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/research-first-fko.sh | research-first-fko.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 48 | B | 2 | 0 | 0 | UserPromptSubmit:* | n/a |
| /Users/josh/.claude/hooks/research-triad-hint.sh | research-triad-hint.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 78 | B | 3 | 2 | 0 | UserPromptSubmit:* | n/a |
| /Users/josh/.claude/hooks/runtime-ddl-skill-tripwire.sh | runtime-ddl-skill-tripwire.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | UserPromptSubmit:* | n/a |
| /Users/josh/.claude/hooks/session-start-context-sidecar.sh | session-start-context-sidecar.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 55 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/session-start.sh | session-start.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 48 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/sessionstart-envsubst-mcp.sh | sessionstart-envsubst-mcp.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/shadow-log-writer.sh | shadow-log-writer.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 55 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/skillmd-yaml-postcheck.sh | skillmd-yaml-postcheck.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 75 | B | 2 | 0 | 0 | PostToolUse:Write\|Edit\|MultiEdit | n/a |
| /Users/josh/.claude/hooks/stop-self-direction-check.sh | stop-self-direction-check.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 72 | B | 2 | 0 | 0 | not wired in settings.json | n/a |
| /Users/josh/.claude/hooks/tick-protocol-injector.sh | tick-protocol-injector.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 76 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/verify-compiled-claudemd.sh | verify-compiled-claudemd.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 55 | B | 2 | 0 | 0 | SessionStart:* | n/a |
| /Users/josh/.claude/hooks/warn-bead-quality.sh | warn-bead-quality.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 73 | B | 2 | 0 | 0 | PreToolUse:Bash | n/a |
| /Users/josh/.claude/hooks/workato-readonly.sh | workato-readonly.sh | hook | True | /Users/josh/.claude/hooks/README.md | False | missing | 70 | B | 2 | 0 | 0 | PreToolUse:Bash | n/a |
| /Users/josh/Library/LaunchAgents/ai.openclaw.gateway.plist | ai.openclaw.gateway.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.openclaw.gateway interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.alps-flywheel-loop.plist | ai.zeststream.alps-flywheel-loop.plist | plist | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | label=ai.zeststream.alps-flywheel-loop interval=600 |
| /Users/josh/Library/LaunchAgents/ai.zeststream.ecosystem-port-security-drift.plist | ai.zeststream.ecosystem-port-security-drift.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=ai.zeststream.ecosystem-port-security-drift interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist | ai.zeststream.flywheel-autoloop.plist | plist | False | missing | False | missing | 0 | F | 5 | 3 | 0 | n/a | label=ai.zeststream.flywheel-autoloop interval=600 |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-codex-snapshot.plist | ai.zeststream.flywheel-codex-snapshot.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.flywheel-codex-snapshot interval=14400 |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-digest.plist | ai.zeststream.flywheel-digest.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.flywheel-digest interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-doctrine-sync.plist | ai.zeststream.flywheel-doctrine-sync.plist | plist | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | label=ai.zeststream.flywheel-doctrine-sync interval=21600 |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-jeff-issue-watch.plist | ai.zeststream.flywheel-jeff-issue-watch.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.flywheel-jeff-issue-watch interval=900 |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-summarize-pending.plist | ai.zeststream.flywheel-summarize-pending.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.flywheel-summarize-pending interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-sync.plist | ai.zeststream.flywheel-sync.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.flywheel-sync interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-weekly-refresh.plist | ai.zeststream.flywheel-weekly-refresh.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.flywheel-weekly-refresh interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.mcp-agent-mail-local.plist | ai.zeststream.mcp-agent-mail-local.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.mcp-agent-mail-local interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist | ai.zeststream.ntm-fleet-health.plist | plist | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | label=ai.zeststream.ntm-fleet-health interval=60 |
| /Users/josh/Library/LaunchAgents/ai.zeststream.orbstack-trial-reminder.plist | ai.zeststream.orbstack-trial-reminder.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.orbstack-trial-reminder interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.python-health.plist | ai.zeststream.python-health.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.python-health interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.python-inventory.plist | ai.zeststream.python-inventory.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.python-inventory interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.qdrant-keepalive.plist | ai.zeststream.qdrant-keepalive.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.qdrant-keepalive interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.research-arxiv-poll.plist | ai.zeststream.research-arxiv-poll.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.research-arxiv-poll interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.research-reddit-poll.plist | ai.zeststream.research-reddit-poll.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.research-reddit-poll interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.research-weekly-reconcile.plist | ai.zeststream.research-weekly-reconcile.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.research-weekly-reconcile interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.security-posture.plist | ai.zeststream.security-posture.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.security-posture interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.skill-refresh.plist | ai.zeststream.skill-refresh.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.skill-refresh interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.skillos-flywheel-loop.plist | ai.zeststream.skillos-flywheel-loop.plist | plist | False | missing | False | missing | 0 | F | 5 | 0 | 0 | n/a | label=ai.zeststream.skillos-flywheel-loop interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.storage-health.plist | ai.zeststream.storage-health.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.storage-health interval=n/a |
| /Users/josh/Library/LaunchAgents/ai.zeststream.system-health.plist | ai.zeststream.system-health.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=ai.zeststream.system-health interval=n/a |
| /Users/josh/Library/LaunchAgents/com.caam.auth-agent.plist | com.caam.auth-agent.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.caam.auth-agent interval=n/a |
| /Users/josh/Library/LaunchAgents/com.caam.auth-coordinator.plist | com.caam.auth-coordinator.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.caam.auth-coordinator interval=n/a |
| /Users/josh/Library/LaunchAgents/com.caam.daemon.plist | com.caam.daemon.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.caam.daemon interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cass.autoindex.plist | com.cass.autoindex.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cass.autoindex interval=1800 |
| /Users/josh/Library/LaunchAgents/com.cass.reflect.plist | com.cass.reflect.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cass.reflect interval=n/a |
| /Users/josh/Library/LaunchAgents/com.ccmirror.ccr.plist | com.ccmirror.ccr.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.ccmirror.ccr interval=n/a |
| /Users/josh/Library/LaunchAgents/com.claudemem.worker.plist | com.claudemem.worker.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.claudemem.worker interval=n/a |
| /Users/josh/Library/LaunchAgents/com.clawdbot.gateway.plist | com.clawdbot.gateway.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.clawdbot.gateway interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.arxiv-research-pipeline.plist | com.cubcloud.arxiv-research-pipeline.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.arxiv-research-pipeline interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.auto-skill-grader.plist | com.cubcloud.auto-skill-grader.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.auto-skill-grader interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.auto-trigger-autoresearch.plist | com.cubcloud.auto-trigger-autoresearch.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.auto-trigger-autoresearch interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.baseline-capture.plist | com.cubcloud.baseline-capture.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.baseline-capture interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.cass-weekly-reflect.plist | com.cubcloud.cass-weekly-reflect.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.cass-weekly-reflect interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.compliance-audit.plist | com.cubcloud.compliance-audit.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.compliance-audit interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.context-integrity-scan-skills.plist | com.cubcloud.context-integrity-scan-skills.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.context-integrity-scan-skills interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.context-integrity-scan.plist | com.cubcloud.context-integrity-scan.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.context-integrity-scan interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.cost-per-customer.plist | com.cubcloud.cost-per-customer.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.cost-per-customer interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.cross-project-promoter.plist | com.cubcloud.cross-project-promoter.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.cross-project-promoter interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.daily-ledger-sync.plist | com.cubcloud.daily-ledger-sync.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.daily-ledger-sync interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.hook-health-check.plist | com.cubcloud.hook-health-check.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.hook-health-check interval=300 |
| /Users/josh/Library/LaunchAgents/com.cubcloud.infisical-sync.plist | com.cubcloud.infisical-sync.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.infisical-sync interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.learning-healthcheck.plist | com.cubcloud.learning-healthcheck.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.learning-healthcheck interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.mission-freshness-audit.plist | com.cubcloud.mission-freshness-audit.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.mission-freshness-audit interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.mission-gap-bead-proposer.plist | com.cubcloud.mission-gap-bead-proposer.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.mission-gap-bead-proposer interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.mission-staleness-detector.plist | com.cubcloud.mission-staleness-detector.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.mission-staleness-detector interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.ntm-watcher-heartbeat.plist | com.cubcloud.ntm-watcher-heartbeat.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.ntm-watcher-heartbeat interval=60 |
| /Users/josh/Library/LaunchAgents/com.cubcloud.pipeline-conformance.plist | com.cubcloud.pipeline-conformance.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.pipeline-conformance interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.plan-archive-stale.plist | com.cubcloud.plan-archive-stale.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.plan-archive-stale interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.search-quality-feedback.plist | com.cubcloud.search-quality-feedback.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.search-quality-feedback interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.self-healing-monitor.plist | com.cubcloud.self-healing-monitor.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.self-healing-monitor interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.service-slo-check.plist | com.cubcloud.service-slo-check.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.service-slo-check interval=300 |
| /Users/josh/Library/LaunchAgents/com.cubcloud.sglang-latency-metrics.plist | com.cubcloud.sglang-latency-metrics.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.sglang-latency-metrics interval=300 |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skill-gap-detector.plist | com.cubcloud.skill-gap-detector.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.skill-gap-detector interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skill-hash-ledger-build.plist | com.cubcloud.skill-hash-ledger-build.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.skill-hash-ledger-build interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skill-index-qdrant.plist | com.cubcloud.skill-index-qdrant.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.skill-index-qdrant interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skill-outcome-harvester.plist | com.cubcloud.skill-outcome-harvester.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.skill-outcome-harvester interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skill-pass-to-beads.plist | com.cubcloud.skill-pass-to-beads.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.skill-pass-to-beads interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skill-proposal-generator.plist | com.cubcloud.skill-proposal-generator.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.skill-proposal-generator interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skill-quality-heatmap.plist | com.cubcloud.skill-quality-heatmap.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.skill-quality-heatmap interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.skills-sync.plist | com.cubcloud.skills-sync.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.cubcloud.skills-sync interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.stale-knowledge-refresh.plist | com.cubcloud.stale-knowledge-refresh.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.stale-knowledge-refresh interval=n/a |
| /Users/josh/Library/LaunchAgents/com.cubcloud.token-efficiency.plist | com.cubcloud.token-efficiency.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.cubcloud.token-efficiency interval=n/a |
| /Users/josh/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist | com.google.GoogleUpdater.wake.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.google.GoogleUpdater.wake interval=3600 |
| /Users/josh/Library/LaunchAgents/com.google.keystone.agent.plist | com.google.keystone.agent.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=missing interval=n/a |
| /Users/josh/Library/LaunchAgents/com.google.keystone.xpcservice.plist | com.google.keystone.xpcservice.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=missing interval=n/a |
| /Users/josh/Library/LaunchAgents/com.kgraph.nightly-pipeline.plist | com.kgraph.nightly-pipeline.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.kgraph.nightly-pipeline interval=n/a |
| /Users/josh/Library/LaunchAgents/com.ntm.bead-status.plist | com.ntm.bead-status.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.ntm.bead-status interval=n/a |
| /Users/josh/Library/LaunchAgents/com.opencode.wisdom-update.plist | com.opencode.wisdom-update.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.opencode.wisdom-update interval=n/a |
| /Users/josh/Library/LaunchAgents/com.pico-z.batch-import.plist | com.pico-z.batch-import.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.batch-import interval=300 |
| /Users/josh/Library/LaunchAgents/com.pico-z.decision-ledger-sentinel.plist | com.pico-z.decision-ledger-sentinel.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.decision-ledger-sentinel interval=120 |
| /Users/josh/Library/LaunchAgents/com.pico-z.ingest-server.plist | com.pico-z.ingest-server.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.ingest-server interval=n/a |
| /Users/josh/Library/LaunchAgents/com.pico-z.kalshi-capture-full.plist | com.pico-z.kalshi-capture-full.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.kalshi-capture-full interval=900 |
| /Users/josh/Library/LaunchAgents/com.pico-z.l1-sentinel.plist | com.pico-z.l1-sentinel.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.l1-sentinel interval=1800 |
| /Users/josh/Library/LaunchAgents/com.pico-z.p0-probes.plist | com.pico-z.p0-probes.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.p0-probes interval=300 |
| /Users/josh/Library/LaunchAgents/com.pico-z.stats-sampler.plist | com.pico-z.stats-sampler.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.stats-sampler interval=60 |
| /Users/josh/Library/LaunchAgents/com.pico-z.wal-checkpoint-cron.plist | com.pico-z.wal-checkpoint-cron.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.wal-checkpoint-cron interval=600 |
| /Users/josh/Library/LaunchAgents/com.pico-z.weekly-cache-prune.plist | com.pico-z.weekly-cache-prune.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.pico-z.weekly-cache-prune interval=n/a |
| /Users/josh/Library/LaunchAgents/com.rano.daemon.plist | com.rano.daemon.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.rano.daemon interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.anthropic-proxy.plist | com.zeststream.anthropic-proxy.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.anthropic-proxy interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.bead-stats-sweep.plist | com.zeststream.bead-stats-sweep.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.bead-stats-sweep interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.cass-sync.plist | com.zeststream.cass-sync.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.cass-sync interval=1800 |
| /Users/josh/Library/LaunchAgents/com.zeststream.cc-cleanup.plist | com.zeststream.cc-cleanup.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.cc-cleanup interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.ccmirror-update.plist | com.zeststream.ccmirror-update.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.ccmirror-update interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.claude-orphan-reaper.plist | com.zeststream.claude-orphan-reaper.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.claude-orphan-reaper interval=300 |
| /Users/josh/Library/LaunchAgents/com.zeststream.cross-project-sweep.plist | com.zeststream.cross-project-sweep.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.cross-project-sweep interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.daemon-cron.plist | com.zeststream.daemon-cron.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.daemon-cron interval=900 |
| /Users/josh/Library/LaunchAgents/com.zeststream.deal-tracker.plist | com.zeststream.deal-tracker.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | plist_parse_error=not well-formed (invalid token): line 13, column 46 |
| /Users/josh/Library/LaunchAgents/com.zeststream.deal-webhook-listener.plist | com.zeststream.deal-webhook-listener.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.deal-webhook-listener interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.docker-autostart.plist | com.zeststream.docker-autostart.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.zeststream.docker-autostart interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.docker-maintenance.plist | com.zeststream.docker-maintenance.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.docker-maintenance interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.flywheel-idle-pane-watch.plist | com.zeststream.flywheel-idle-pane-watch.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.flywheel-idle-pane-watch interval=1800 |
| /Users/josh/Library/LaunchAgents/com.zeststream.infisical-sync.plist | com.zeststream.infisical-sync.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.infisical-sync interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.jsm-sync.plist | com.zeststream.jsm-sync.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.jsm-sync interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.ks-server.plist | com.zeststream.ks-server.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.ks-server interval=5 |
| /Users/josh/Library/LaunchAgents/com.zeststream.lone-wolves-sweep.plist | com.zeststream.lone-wolves-sweep.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.lone-wolves-sweep interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.mga-status.plist | com.zeststream.mga-status.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.mga-status interval=3600 |
| /Users/josh/Library/LaunchAgents/com.zeststream.nightly-regression.plist | com.zeststream.nightly-regression.plist | plist | False | missing | False | missing | 0 | F | 3 | 1 | 0 | n/a | label=com.zeststream.nightly-regression interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.skill-metrics-collect.plist | com.zeststream.skill-metrics-collect.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.skill-metrics-collect interval=n/a |
| /Users/josh/Library/LaunchAgents/com.zeststream.skill-pass-sweep.plist | com.zeststream.skill-pass-sweep.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=com.zeststream.skill-pass-sweep interval=n/a |
| /Users/josh/Library/LaunchAgents/homebrew.mxcl.grafana.plist | homebrew.mxcl.grafana.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=homebrew.mxcl.grafana interval=n/a |
| /Users/josh/Library/LaunchAgents/homebrew.mxcl.ollama.plist | homebrew.mxcl.ollama.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=homebrew.mxcl.ollama interval=n/a |
| /Users/josh/Library/LaunchAgents/homebrew.mxcl.postgresql@16.plist | homebrew.mxcl.postgresql@16.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=homebrew.mxcl.postgresql@16 interval=n/a |
| /Users/josh/Library/LaunchAgents/homebrew.mxcl.postgresql@17.plist | homebrew.mxcl.postgresql@17.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=homebrew.mxcl.postgresql@17 interval=n/a |
| /Users/josh/Library/LaunchAgents/homebrew.mxcl.prometheus.plist | homebrew.mxcl.prometheus.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=homebrew.mxcl.prometheus interval=n/a |
| /Users/josh/Library/LaunchAgents/homebrew.mxcl.redis.plist | homebrew.mxcl.redis.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=homebrew.mxcl.redis interval=n/a |
| /Users/josh/Library/LaunchAgents/homebrew.mxcl.sleepwatcher.plist | homebrew.mxcl.sleepwatcher.plist | plist | False | missing | False | missing | 0 | F | 2 | 0 | 0 | n/a | label=homebrew.mxcl.sleepwatcher interval=n/a |
| /Users/josh/.claude/skills/_archived/brand-guidelines | brand-guidelines | skill | True | /Users/josh/.claude/skills/_archived/brand-guidelines/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/cleanup-stories | cleanup-stories | skill | True | /Users/josh/.claude/skills/_archived/cleanup-stories/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/competitor-alternatives | competitor-alternatives | skill | True | /Users/josh/.claude/skills/_archived/competitor-alternatives/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/content-research-writer | content-research-writer | skill | True | /Users/josh/.claude/skills/_archived/content-research-writer/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/copy-editing | copy-editing | skill | True | /Users/josh/.claude/skills/_archived/copy-editing/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/director | director | skill | True | /Users/josh/.claude/skills/_archived/director/SKILL.md | False | missing | 0 | B | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/fleet | fleet | skill | True | /Users/josh/.claude/skills/_archived/fleet/SKILL.md | False | missing | 0 | B | 5 | 488 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/form-cro | form-cro | skill | True | /Users/josh/.claude/skills/_archived/form-cro/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/free-tool-strategy | free-tool-strategy | skill | True | /Users/josh/.claude/skills/_archived/free-tool-strategy/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/human-mcp | human-mcp | skill | True | /Users/josh/.claude/skills/_archived/human-mcp/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/lead-research-assistant | lead-research-assistant | skill | True | /Users/josh/.claude/skills/_archived/lead-research-assistant/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/marketing-ideas | marketing-ideas | skill | True | /Users/josh/.claude/skills/_archived/marketing-ideas/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/marketing-psychology | marketing-psychology | skill | True | /Users/josh/.claude/skills/_archived/marketing-psychology/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/mcp-n8n | mcp-n8n | skill | True | /Users/josh/.claude/skills/_archived/mcp-n8n/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/mcp-supabase | mcp-supabase | skill | True | /Users/josh/.claude/skills/_archived/mcp-supabase/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/onboarding-cro | onboarding-cro | skill | True | /Users/josh/.claude/skills/_archived/onboarding-cro/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/opencode | opencode | skill | True | /Users/josh/.claude/skills/_archived/opencode/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/orchestrate-phase | orchestrate-phase | skill | True | /Users/josh/.claude/skills/_archived/orchestrate-phase/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/paywall-upgrade-cro | paywall-upgrade-cro | skill | True | /Users/josh/.claude/skills/_archived/paywall-upgrade-cro/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/popup-cro | popup-cro | skill | True | /Users/josh/.claude/skills/_archived/popup-cro/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/prd-edit | prd-edit | skill | True | /Users/josh/.claude/skills/_archived/prd-edit/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/prd-validate | prd-validate | skill | True | /Users/josh/.claude/skills/_archived/prd-validate/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/programmatic-seo | programmatic-seo | skill | True | /Users/josh/.claude/skills/_archived/programmatic-seo/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/ralph-opencode | ralph-opencode | skill | True | /Users/josh/.claude/skills/_archived/ralph-opencode/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/ralph-orchestrator | ralph-orchestrator | skill | True | /Users/josh/.claude/skills/_archived/ralph-orchestrator/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/schema-markup | schema-markup | skill | True | /Users/josh/.claude/skills/_archived/schema-markup/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/signup-flow-cro | signup-flow-cro | skill | True | /Users/josh/.claude/skills/_archived/signup-flow-cro/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/social-content | social-content | skill | True | /Users/josh/.claude/skills/_archived/social-content/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/swarmd | swarmd | skill | True | /Users/josh/.claude/skills/_archived/swarmd/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/workflow-transition | workflow-transition | skill | True | /Users/josh/.claude/skills/_archived/workflow-transition/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/_archived/worktree-prd | worktree-prd | skill | True | /Users/josh/.claude/skills/_archived/worktree-prd/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ab-test-setup | ab-test-setup | skill | True | /Users/josh/.claude/skills/ab-test-setup/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ab-testing | ab-testing | skill | True | /Users/josh/.claude/skills/ab-testing/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/accounts-payable | accounts-payable | skill | True | /Users/josh/.claude/skills/accounts-payable/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/accounts-receivable | accounts-receivable | skill | True | /Users/josh/.claude/skills/accounts-receivable/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/accretive-cron-orchestration | accretive-cron-orchestration | skill | True | /Users/josh/.claude/skills/accretive-cron-orchestration/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/accretive-file-write | accretive-file-write | skill | True | /Users/josh/.claude/skills/accretive-file-write/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/add-expert | add-expert | skill | True | /Users/josh/.claude/skills/add-expert/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/add-sfx | add-sfx | skill | True | /Users/josh/.claude/skills/add-sfx/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/admin-page-for-nextjs-sites | admin-page-for-nextjs-sites | skill | True | /Users/josh/.claude/skills/admin-page-for-nextjs-sites/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/adobe-creative-enterprise | adobe-creative-enterprise | skill | True | /Users/josh/.claude/skills/adobe-creative-enterprise/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-cost-optimization | agent-cost-optimization | skill | True | /Users/josh/.claude/skills/agent-cost-optimization/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-evaluation | agent-evaluation | skill | True | /Users/josh/.claude/skills/agent-evaluation/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-fungibility-philosophy | agent-fungibility-philosophy | skill | True | /Users/josh/.claude/skills/agent-fungibility-philosophy/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-governance | agent-governance | skill | True | /Users/josh/.claude/skills/agent-governance/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-lifecycle | agent-lifecycle | skill | True | /Users/josh/.claude/skills/agent-lifecycle/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-mail | agent-mail | skill | True | /Users/josh/.claude/skills/agent-mail/SKILL.md | False | missing | 28 | B | 5 | 66 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-memory | agent-memory | skill | True | /Users/josh/.claude/skills/agent-memory/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-monitoring | agent-monitoring | skill | True | /Users/josh/.claude/skills/agent-monitoring/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-orchestration | agent-orchestration | skill | True | /Users/josh/.claude/skills/agent-orchestration/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-sandboxing | agent-sandboxing | skill | True | /Users/josh/.claude/skills/agent-sandboxing/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-sdk-landscape | agent-sdk-landscape | skill | True | /Users/josh/.claude/skills/agent-sdk-landscape/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agent-security | agent-security | skill | True | /Users/josh/.claude/skills/agent-security/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agentic-coding-flywheel-setup | agentic-coding-flywheel-setup | skill | True | /Users/josh/.claude/skills/agentic-coding-flywheel-setup/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/agentic-commerce-protocol | agentic-commerce-protocol | skill | True | /Users/josh/.claude/skills/agentic-commerce-protocol/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/analytics-tracking | analytics-tracking | skill | True | /Users/josh/.claude/skills/analytics-tracking/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/anthropic-cli-patterns | anthropic-cli-patterns | skill | True | /Users/josh/.claude/skills/anthropic-cli-patterns/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/apfs-snapshot-ops | apfs-snapshot-ops | skill | True | /Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/api-design-patterns | api-design-patterns | skill | True | /Users/josh/.claude/skills/api-design-patterns/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/api-documentation-generation | api-documentation-generation | skill | True | /Users/josh/.claude/skills/api-documentation-generation/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/api-versioning | api-versioning | skill | True | /Users/josh/.claude/skills/api-versioning/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/apple-silicon-ml-porting | apple-silicon-ml-porting | skill | True | /Users/josh/.claude/skills/apple-silicon-ml-porting/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/appointment-scheduling | appointment-scheduling | skill | True | /Users/josh/.claude/skills/appointment-scheduling/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/asset-library-curator | asset-library-curator | skill | True | /Users/josh/.claude/skills/asset-library-curator/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/asupersync-mega-skill | asupersync-mega-skill | skill | True | /Users/josh/.claude/skills/asupersync-mega-skill/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/audit-preparation | audit-preparation | skill | True | /Users/josh/.claude/skills/audit-preparation/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/authentication-authorization | authentication-authorization | skill | True | /Users/josh/.claude/skills/authentication-authorization/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/authoring-zest-feed-beat-boards | authoring-zest-feed-beat-boards | skill | True | /Users/josh/.claude/skills/authoring-zest-feed-beat-boards/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/authoring-zest-feed-storyboards | authoring-zest-feed-storyboards | skill | True | /Users/josh/.claude/skills/authoring-zest-feed-storyboards/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/automating-your-automations | automating-your-automations | skill | True | /Users/josh/.claude/skills/automating-your-automations/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/azure-apps | azure-apps | skill | True | /Users/josh/.claude/skills/azure-apps/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/background-jobs | background-jobs | skill | True | /Users/josh/.claude/skills/background-jobs/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/backward-compatibility | backward-compatibility | skill | True | /Users/josh/.claude/skills/backward-compatibility/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/batch-processing | batch-processing | skill | True | /Users/josh/.claude/skills/batch-processing/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/bd-to-br-migration | bd-to-br-migration | skill | True | /Users/josh/.claude/skills/bd-to-br-migration/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/beads-br | beads-br | skill | True | /Users/josh/.claude/skills/beads-br/SKILL.md | False | missing | 29 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/beads-bv | beads-bv | skill | True | /Users/josh/.claude/skills/beads-bv/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/beads-workflow | beads-workflow | skill | True | /Users/josh/.claude/skills/beads-workflow/SKILL.md | False | missing | 0 | B | 3 | 5 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/billing-dispute-resolution | billing-dispute-resolution | skill | True | /Users/josh/.claude/skills/billing-dispute-resolution/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/brenner | brenner | skill | True | /Users/josh/.claude/skills/brenner/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/browser-extension-automation | browser-extension-automation | skill | True | /Users/josh/.claude/skills/browser-extension-automation/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/budgeting-forecasting | budgeting-forecasting | skill | True | /Users/josh/.claude/skills/budgeting-forecasting/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/caam | caam | skill | True | /Users/josh/.claude/skills/caam/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/caching-strategy | caching-strategy | skill | True | /Users/josh/.claude/skills/caching-strategy/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/canonical-cli-scoping | canonical-cli-scoping | skill | True | /Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/canonical-owner-runtime-state | canonical-owner-runtime-state | skill | True | /Users/josh/.claude/skills/canonical-owner-runtime-state/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/canva-enterprise | canva-enterprise | skill | True | /Users/josh/.claude/skills/canva-enterprise/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/capacity-planning | capacity-planning | skill | True | /Users/josh/.claude/skills/capacity-planning/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cash-flow-management | cash-flow-management | skill | True | /Users/josh/.claude/skills/cash-flow-management/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cass | cass | skill | True | /Users/josh/.claude/skills/cass/SKILL.md | False | missing | 0 | B | 4 | 14 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cass-memory | cass-memory | skill | True | /Users/josh/.claude/skills/cass-memory/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cc-hooks | cc-hooks | skill | True | /Users/josh/.claude/skills/cc-hooks/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/changelog-md-workmanship | changelog-md-workmanship | skill | True | /Users/josh/.claude/skills/changelog-md-workmanship/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/churn-prediction | churn-prediction | skill | True | /Users/josh/.claude/skills/churn-prediction/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ci-cd-pipeline | ci-cd-pipeline | skill | True | /Users/josh/.claude/skills/ci-cd-pipeline/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/claims-processing | claims-processing | skill | True | /Users/josh/.claude/skills/claims-processing/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/claude-chrome | claude-chrome | skill | True | /Users/josh/.claude/skills/claude-chrome/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/claude-code-deployment | claude-code-deployment | skill | True | /Users/josh/.claude/skills/claude-code-deployment/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/client-ecosystem-audit | client-ecosystem-audit | skill | True | /Users/josh/.claude/skills/client-ecosystem-audit/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/clinical-decision-support | clinical-decision-support | skill | True | /Users/josh/.claude/skills/clinical-decision-support/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/clinical-documentation | clinical-documentation | skill | True | /Users/josh/.claude/skills/clinical-documentation/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cloudflare-api | cloudflare-api | skill | True | /Users/josh/.claude/skills/cloudflare-api/SKILL.md | False | missing | 1 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/clubready | clubready | skill | True | /Users/josh/.claude/skills/clubready/SKILL.md | False | missing | 0 | B | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm | code-review-gemini-swarm-with-ntm | skill | True | /Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/code-simplifier | code-simplifier | skill | True | /Users/josh/.claude/skills/code-simplifier/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/codebase-archaeology | codebase-archaeology | skill | True | /Users/josh/.claude/skills/codebase-archaeology/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/codebase-audit | codebase-audit | skill | True | /Users/josh/.claude/skills/codebase-audit/SKILL.md | False | missing | 30 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/codebase-pattern-extraction | codebase-pattern-extraction | skill | True | /Users/josh/.claude/skills/codebase-pattern-extraction/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/codebase-report | codebase-report | skill | True | /Users/josh/.claude/skills/codebase-report/SKILL.md | False | missing | 27 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/coding-agent-usage-tracker | coding-agent-usage-tracker | skill | True | /Users/josh/.claude/skills/coding-agent-usage-tracker/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/commission-calculation | commission-calculation | skill | True | /Users/josh/.claude/skills/commission-calculation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/commit | commit | skill | True | /Users/josh/.claude/skills/commit/SKILL.md | False | missing | 1 | C | 5 | 137 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/competitive-intelligence | competitive-intelligence | skill | True | /Users/josh/.claude/skills/competitive-intelligence/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/compliance-automation | compliance-automation | skill | True | /Users/josh/.claude/skills/compliance-automation/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/concurrency-patterns | concurrency-patterns | skill | True | /Users/josh/.claude/skills/concurrency-patterns/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/config-file-management | config-file-management | skill | True | /Users/josh/.claude/skills/config-file-management/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/consent-management | consent-management | skill | True | /Users/josh/.claude/skills/consent-management/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/container-orphan-detector | container-orphan-detector | skill | True | /Users/josh/.claude/skills/container-orphan-detector/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/containerization | containerization | skill | True | /Users/josh/.claude/skills/containerization/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/contract-negotiation | contract-negotiation | skill | True | /Users/josh/.claude/skills/contract-negotiation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/contract-review | contract-review | skill | True | /Users/josh/.claude/skills/contract-review/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/copywriting | copywriting | skill | True | /Users/josh/.claude/skills/copywriting/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cors-configuration | cors-configuration | skill | True | /Users/josh/.claude/skills/cors-configuration/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cost-attribution | cost-attribution | skill | True | /Users/josh/.claude/skills/cost-attribution/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cost-monitoring-infra | cost-monitoring-infra | skill | True | /Users/josh/.claude/skills/cost-monitoring-infra/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/crash-reporting | crash-reporting | skill | True | /Users/josh/.claude/skills/crash-reporting/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cross-agent-session-resumer | cross-agent-session-resumer | skill | True | /Users/josh/.claude/skills/cross-agent-session-resumer/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cross-collection-fanout | cross-collection-fanout | skill | True | /Users/josh/.claude/skills/cross-collection-fanout/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cross-platform-builds | cross-platform-builds | skill | True | /Users/josh/.claude/skills/cross-platform-builds/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cryptography-and-auth | cryptography-and-auth | skill | True | /Users/josh/.claude/skills/cryptography-and-auth/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/csctf | csctf | skill | True | /Users/josh/.claude/skills/csctf/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/csv-export-import | csv-export-import | skill | True | /Users/josh/.claude/skills/csv-export-import/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cubcloud-ops | cubcloud-ops | skill | True | /Users/josh/.claude/skills/cubcloud-ops/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cubcloud-validate | cubcloud-validate | skill | True | /Users/josh/.claude/skills/cubcloud-validate/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cubcode | cubcode | skill | True | /Users/josh/.claude/skills/cubcode/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cuda-to-mps-adapter-pattern | cuda-to-mps-adapter-pattern | skill | True | /Users/josh/.claude/skills/cuda-to-mps-adapter-pattern/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/cursor | cursor | skill | True | /Users/josh/.claude/skills/cursor/SKILL.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/customer-communication | customer-communication | skill | True | /Users/josh/.claude/skills/customer-communication/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/customer-health-scoring | customer-health-scoring | skill | True | /Users/josh/.claude/skills/customer-health-scoring/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/customer-onboarding | customer-onboarding | skill | True | /Users/josh/.claude/skills/customer-onboarding/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dashboard-generation | dashboard-generation | skill | True | /Users/josh/.claude/skills/dashboard-generation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/data-deidentification | data-deidentification | skill | True | /Users/josh/.claude/skills/data-deidentification/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/data-quality-validation | data-quality-validation | skill | True | /Users/josh/.claude/skills/data-quality-validation/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/data-visualization | data-visualization | skill | True | /Users/josh/.claude/skills/data-visualization/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/database-modeling | database-modeling | skill | True | /Users/josh/.claude/skills/database-modeling/SKILL.md | False | missing | 3 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/database-operations | database-operations | skill | True | /Users/josh/.claude/skills/database-operations/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dcg | dcg | skill | True | /Users/josh/.claude/skills/dcg/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/de-slopify | de-slopify | skill | True | /Users/josh/.claude/skills/de-slopify/SKILL.md | False | missing | 32 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/deadlock-finder-and-fixer | deadlock-finder-and-fixer | skill | True | /Users/josh/.claude/skills/deadlock-finder-and-fixer/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/deal-desk | deal-desk | skill | True | /Users/josh/.claude/skills/deal-desk/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/demand-forecasting | demand-forecasting | skill | True | /Users/josh/.claude/skills/demand-forecasting/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dependency-management | dependency-management | skill | True | /Users/josh/.claude/skills/dependency-management/SKILL.md | False | missing | 3 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/deployment-strategy | deployment-strategy | skill | True | /Users/josh/.claude/skills/deployment-strategy/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dev-browser | dev-browser | skill | True | /Users/josh/.claude/skills/dev-browser/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dev-cache-janitor | dev-cache-janitor | skill | True | /Users/josh/.claude/skills/dev-cache-janitor/SKILL.md | False | missing | 0 | B | 3 | 4 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dicklesworthstone-stack | dicklesworthstone-stack | skill | True | /Users/josh/.claude/skills/dicklesworthstone-stack/SKILL.md | False | missing | 0 | B | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/disk-observer | disk-observer | skill | True | /Users/josh/.claude/skills/disk-observer/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dispatch-tool-contracts | dispatch-tool-contracts | skill | True | /Users/josh/.claude/skills/dispatch-tool-contracts/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/distributed-systems | distributed-systems | skill | True | /Users/josh/.claude/skills/distributed-systems/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dns-ssl-configuration | dns-ssl-configuration | skill | True | /Users/josh/.claude/skills/dns-ssl-configuration/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/docker-network-ops | docker-network-ops | skill | True | /Users/josh/.claude/skills/docker-network-ops/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/docker-storage-ops | docker-storage-ops | skill | True | /Users/josh/.claude/skills/docker-storage-ops/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/docker-troubleshooting | docker-troubleshooting | skill | True | /Users/josh/.claude/skills/docker-troubleshooting/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/docker-volume-ops | docker-volume-ops | skill | True | /Users/josh/.claude/skills/docker-volume-ops/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/docs-demo | docs-demo | skill | True | /Users/josh/.claude/skills/docs-demo/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/document-automation | document-automation | skill | True | /Users/josh/.claude/skills/document-automation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/document-processing | document-processing | skill | True | /Users/josh/.claude/skills/document-processing/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/donella-meadows-systems-thinking | donella-meadows-systems-thinking | skill | True | /Users/josh/.claude/skills/donella-meadows-systems-thinking/SKILL.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dsr | dsr | skill | True | /Users/josh/.claude/skills/dsr/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/dueling-idea-wizards | dueling-idea-wizards | skill | True | /Users/josh/.claude/skills/dueling-idea-wizards/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/e-discovery | e-discovery | skill | True | /Users/josh/.claude/skills/e-discovery/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/e2e-testing-for-webapps | e2e-testing-for-webapps | skill | True | /Users/josh/.claude/skills/e2e-testing-for-webapps/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ecosystem-port-security | ecosystem-port-security | skill | True | /Users/josh/.claude/skills/ecosystem-port-security/SKILL.md | False | missing | 0 | C | 4 | 10 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/email-delivery | email-delivery | skill | True | /Users/josh/.claude/skills/email-delivery/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/email-sequence | email-sequence | skill | True | /Users/josh/.claude/skills/email-sequence/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/environment-configuration | environment-configuration | skill | True | /Users/josh/.claude/skills/environment-configuration/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/error-handling-patterns | error-handling-patterns | skill | True | /Users/josh/.claude/skills/error-handling-patterns/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/escalation-management | escalation-management | skill | True | /Users/josh/.claude/skills/escalation-management/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/etl-pipeline | etl-pipeline | skill | True | /Users/josh/.claude/skills/etl-pipeline/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/evaluation-framework | evaluation-framework | skill | True | /Users/josh/.claude/skills/evaluation-framework/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/expense-management | expense-management | skill | True | /Users/josh/.claude/skills/expense-management/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/extreme-software-optimization | extreme-software-optimization | skill | True | /Users/josh/.claude/skills/extreme-software-optimization/SKILL.md | False | missing | 4 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/fastmcp-rust | fastmcp-rust | skill | True | /Users/josh/.claude/skills/fastmcp-rust/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ffmpeg-analyse-video | ffmpeg-analyse-video | skill | True | /Users/josh/.claude/skills/ffmpeg-analyse-video/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/file-upload-storage | file-upload-storage | skill | True | /Users/josh/.claude/skills/file-upload-storage/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/financial-modeling | financial-modeling | skill | True | /Users/josh/.claude/skills/financial-modeling/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/financial-reporting | financial-reporting | skill | True | /Users/josh/.claude/skills/financial-reporting/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/fix-dependabot | fix-dependabot | skill | True | /Users/josh/.claude/skills/fix-dependabot/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/flywheel | flywheel | skill | True | /Users/josh/.claude/skills/flywheel/SKILL.md | False | missing | 0 | C | 5 | 1029 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/flywheel-connectors | flywheel-connectors | skill | True | /Users/josh/.claude/skills/flywheel-connectors/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/flywheel-doctor-author | flywheel-doctor-author | skill | True | /Users/josh/.claude/skills/flywheel-doctor-author/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/focused-fix | focused-fix | skill | True | /Users/josh/.claude/skills/focused-fix/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/form-validation | form-validation | skill | True | /Users/josh/.claude/skills/form-validation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/frankenagent-detection | frankenagent-detection | skill | True | /Users/josh/.claude/skills/frankenagent-detection/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/frankensearch-integration-for-rust-projects | frankensearch-integration-for-rust-projects | skill | True | /Users/josh/.claude/skills/frankensearch-integration-for-rust-projects/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/frankensqlite | frankensqlite | skill | True | /Users/josh/.claude/skills/frankensqlite/SKILL.md | False | missing | 0 | C | 4 | 14 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/frankensuite-website-development | frankensuite-website-development | skill | True | /Users/josh/.claude/skills/frankensuite-website-development/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/frankentui | frankentui | skill | True | /Users/josh/.claude/skills/frankentui/SKILL.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/fraud-detection | fraud-detection | skill | True | /Users/josh/.claude/skills/fraud-detection/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ga4 | ga4 | skill | True | /Users/josh/.claude/skills/ga4/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/game-theory-optimization | game-theory-optimization | skill | True | /Users/josh/.claude/skills/game-theory-optimization/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gate-truth-separation | gate-truth-separation | skill | True | /Users/josh/.claude/skills/gate-truth-separation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gcloud | gcloud | skill | True | /Users/josh/.claude/skills/gcloud/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gdb-for-debugging | gdb-for-debugging | skill | True | /Users/josh/.claude/skills/gdb-for-debugging/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/generating-images-multi-provider | generating-images-multi-provider | skill | True | /Users/josh/.claude/skills/generating-images-multi-provider/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/generating-videos-multi-provider | generating-videos-multi-provider | skill | True | /Users/josh/.claude/skills/generating-videos-multi-provider/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gh-actions | gh-actions | skill | True | /Users/josh/.claude/skills/gh-actions/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gh-cli | gh-cli | skill | True | /Users/josh/.claude/skills/gh-cli/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gh-coding-agent | gh-coding-agent | skill | True | /Users/josh/.claude/skills/gh-coding-agent/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gh-mcp-server | gh-mcp-server | skill | True | /Users/josh/.claude/skills/gh-mcp-server/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gh-models | gh-models | skill | True | /Users/josh/.claude/skills/gh-models/SKILL.md | False | missing | 2 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gh-og-share-images | gh-og-share-images | skill | True | /Users/josh/.claude/skills/gh-og-share-images/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/gh-triage-ru | gh-triage-ru | skill | True | /Users/josh/.claude/skills/gh-triage-ru/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ghostty | ghostty | skill | True | /Users/josh/.claude/skills/ghostty/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/giil | giil | skill | True | /Users/josh/.claude/skills/giil/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/git-commit-craftsman | git-commit-craftsman | skill | True | /Users/josh/.claude/skills/git-commit-craftsman/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/git-worktree-manager | git-worktree-manager | skill | True | /Users/josh/.claude/skills/git-worktree-manager/SKILL.md | False | missing | 2 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/google-agent-ecosystem | google-agent-ecosystem | skill | True | /Users/josh/.claude/skills/google-agent-ecosystem/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/grading-intro-outro-by-research-rubric | grading-intro-outro-by-research-rubric | skill | True | /Users/josh/.claude/skills/grading-intro-outro-by-research-rubric/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/graph-algorithms | graph-algorithms | skill | True | /Users/josh/.claude/skills/graph-algorithms/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/hardware-product-scoping | hardware-product-scoping | skill | True | /Users/josh/.claude/skills/hardware-product-scoping/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/hipaa-compliance | hipaa-compliance | skill | True | /Users/josh/.claude/skills/hipaa-compliance/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/hipaa-soc2-fastapi-hardening | hipaa-soc2-fastapi-hardening | skill | True | /Users/josh/.claude/skills/hipaa-soc2-fastapi-hardening/SKILL.md | False | missing | 2 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/horizontal-scaling | horizontal-scaling | skill | True | /Users/josh/.claude/skills/horizontal-scaling/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/human-in-the-loop | human-in-the-loop | skill | True | /Users/josh/.claude/skills/human-in-the-loop/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/idea-wizard | idea-wizard | skill | True | /Users/josh/.claude/skills/idea-wizard/SKILL.md | False | missing | 30 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/incident-response | incident-response | skill | True | /Users/josh/.claude/skills/incident-response/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/infisical-rotation-ops | infisical-rotation-ops | skill | True | /Users/josh/.claude/skills/infisical-rotation-ops/SKILL.md | False | missing | 0 | B | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/infisical-secrets | infisical-secrets | skill | True | /Users/josh/.claude/skills/infisical-secrets/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/information-retrieval | information-retrieval | skill | True | /Users/josh/.claude/skills/information-retrieval/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/install-substrate | install-substrate | skill | True | /Users/josh/.claude/skills/install-substrate/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/installer-workmanship | installer-workmanship | skill | True | /Users/josh/.claude/skills/installer-workmanship/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/integrating-script-visual-timing | integrating-script-visual-timing | skill | True | /Users/josh/.claude/skills/integrating-script-visual-timing/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/integration-testing | integration-testing | skill | True | /Users/josh/.claude/skills/integration-testing/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/interactive-visualization-creator | interactive-visualization-creator | skill | True | /Users/josh/.claude/skills/interactive-visualization-creator/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/isp-billing | isp-billing | skill | True | /Users/josh/.claude/skills/isp-billing/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/isp-customer-service | isp-customer-service | skill | True | /Users/josh/.claude/skills/isp-customer-service/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/jeff-convergence-audit | jeff-convergence-audit | skill | True | /Users/josh/.claude/skills/jeff-convergence-audit/SKILL.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/jeff-planning-enhanced | jeff-planning-enhanced | skill | True | /Users/josh/.claude/skills/jeff-planning-enhanced/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/jeff-swarm-ops | jeff-swarm-ops | skill | True | /Users/josh/.claude/skills/jeff-swarm-ops/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/jsm | jsm | skill | True | /Users/josh/.claude/skills/jsm/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/knowledge-base-management | knowledge-base-management | skill | True | /Users/josh/.claude/skills/knowledge-base-management/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/knowledge-graph | knowledge-graph | skill | True | /Users/josh/.claude/skills/knowledge-graph/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/kyc-aml | kyc-aml | skill | True | /Users/josh/.claude/skills/kyc-aml/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/launch-strategy | launch-strategy | skill | True | /Users/josh/.claude/skills/launch-strategy/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/lead-qualification | lead-qualification | skill | True | /Users/josh/.claude/skills/lead-qualification/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/lean-formal-feedback-loop | lean-formal-feedback-loop | skill | True | /Users/josh/.claude/skills/lean-formal-feedback-loop/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/legal-research | legal-research | skill | True | /Users/josh/.claude/skills/legal-research/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/library-updater | library-updater | skill | True | /Users/josh/.claude/skills/library-updater/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/living-documentation | living-documentation | skill | True | /Users/josh/.claude/skills/living-documentation/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/log-aggregation | log-aggregation | skill | True | /Users/josh/.claude/skills/log-aggregation/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/logistics-optimization | logistics-optimization | skill | True | /Users/josh/.claude/skills/logistics-optimization/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/long-horizon-pipeline-ops | long-horizon-pipeline-ops | skill | True | /Users/josh/.claude/skills/long-horizon-pipeline-ops/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/loop-enforcement | loop-enforcement | skill | True | /Users/josh/.claude/skills/loop-enforcement/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mailchimp-and-alternatives | mailchimp-and-alternatives | skill | True | /Users/josh/.claude/skills/mailchimp-and-alternatives/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mcp-cf-access-shim | mcp-cf-access-shim | skill | True | /Users/josh/.claude/skills/mcp-cf-access-shim/SKILL.md | False | missing | 0 | B | 3 | 5 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mcp-secret-scanner | mcp-secret-scanner | skill | True | /Users/josh/.claude/skills/mcp-secret-scanner/SKILL.md | False | missing | 0 | B | 3 | 4 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mcp-server-design | mcp-server-design | skill | True | /Users/josh/.claude/skills/mcp-server-design/SKILL.md | False | missing | 27 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/medical-coding | medical-coding | skill | True | /Users/josh/.claude/skills/medical-coding/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/message-queuing | message-queuing | skill | True | /Users/josh/.claude/skills/message-queuing/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/migration-architect | migration-architect | skill | True | /Users/josh/.claude/skills/migration-architect/SKILL.md | True | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mission-anchor-init | mission-anchor-init | skill | True | /Users/josh/.claude/skills/mission-anchor-init/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mlops | mlops | skill | True | /Users/josh/.claude/skills/mlops/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mock-code-finder | mock-code-finder | skill | True | /Users/josh/.claude/skills/mock-code-finder/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/modes-of-reasoning-project-analysis | modes-of-reasoning-project-analysis | skill | True | /Users/josh/.claude/skills/modes-of-reasoning-project-analysis/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/money-path-input-integrity | money-path-input-integrity | skill | True | /Users/josh/.claude/skills/money-path-input-integrity/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/multi-agent-swarm-workflow | multi-agent-swarm-workflow | skill | True | /Users/josh/.claude/skills/multi-agent-swarm-workflow/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/multi-document-rag | multi-document-rag | skill | True | /Users/josh/.claude/skills/multi-document-rag/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/multi-language-support | multi-language-support | skill | True | /Users/josh/.claude/skills/multi-language-support/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/multi-model-triangulation | multi-model-triangulation | skill | True | /Users/josh/.claude/skills/multi-model-triangulation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/multi-pass-bug-hunting | multi-pass-bug-hunting | skill | True | /Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/mythos-petri-tracker | mythos-petri-tracker | skill | True | /Users/josh/.claude/skills/mythos-petri-tracker/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/n8n-template-standard | n8n-template-standard | skill | True | /Users/josh/.claude/skills/n8n-template-standard/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/nango-integrations | nango-integrations | skill | True | /Users/josh/.claude/skills/nango-integrations/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/nano-banana/.claude/skills/frontend-design | frontend-design | skill | True | /Users/josh/.claude/skills/nano-banana/.claude/skills/frontend-design/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/nano-banana/.claude/skills/nano-banana-builder | nano-banana-builder | skill | True | /Users/josh/.claude/skills/nano-banana/.claude/skills/nano-banana-builder/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/nano-banana/.claude/skills/threejs-builder | threejs-builder | skill | True | /Users/josh/.claude/skills/nano-banana/.claude/skills/threejs-builder/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/nano-banana | nano-banana | skill | True | /Users/josh/.claude/skills/nano-banana/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/network-optimization | network-optimization | skill | True | /Users/josh/.claude/skills/network-optimization/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/network-security-isp | network-security-isp | skill | True | /Users/josh/.claude/skills/network-security-isp/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/nomic-embeddings | nomic-embeddings | skill | True | /Users/josh/.claude/skills/nomic-embeddings/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/nps-analysis | nps-analysis | skill | True | /Users/josh/.claude/skills/nps-analysis/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ntm | ntm | skill | True | /Users/josh/.claude/skills/ntm/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ntm-session-plist | ntm-session-plist | skill | True | /Users/josh/.claude/skills/ntm-session-plist/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/observability-designer | observability-designer | skill | True | /Users/josh/.claude/skills/observability-designer/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/observability-platform | observability-platform | skill | True | /Users/josh/.claude/skills/observability-platform/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/offline-first-sync | offline-first-sync | skill | True | /Users/josh/.claude/skills/offline-first-sync/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/og-share-images | og-share-images | skill | True | /Users/josh/.claude/skills/og-share-images/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ollama-ops | ollama-ops | skill | True | /Users/josh/.claude/skills/ollama-ops/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/operationalizing-expertise | operationalizing-expertise | skill | True | /Users/josh/.claude/skills/operationalizing-expertise/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/orbstack-migration | orbstack-migration | skill | True | /Users/josh/.claude/skills/orbstack-migration/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/orbstack-ops | orbstack-ops | skill | True | /Users/josh/.claude/skills/orbstack-ops/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/package-publishing | package-publishing | skill | True | /Users/josh/.claude/skills/package-publishing/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/page-cro | page-cro | skill | True | /Users/josh/.claude/skills/page-cro/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/pagination-filtering | pagination-filtering | skill | True | /Users/josh/.claude/skills/pagination-filtering/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/paid-ads | paid-ads | skill | True | /Users/josh/.claude/skills/paid-ads/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/path-rationalization | path-rationalization | skill | True | /Users/josh/.claude/skills/path-rationalization/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/patient-engagement | patient-engagement | skill | True | /Users/josh/.claude/skills/patient-engagement/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/payment-processing | payment-processing | skill | True | /Users/josh/.claude/skills/payment-processing/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/payroll-processing | payroll-processing | skill | True | /Users/josh/.claude/skills/payroll-processing/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/pdf-generation | pdf-generation | skill | True | /Users/josh/.claude/skills/pdf-generation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/performance-review | performance-review | skill | True | /Users/josh/.claude/skills/performance-review/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/pi-agent-rust | pi-agent-rust | skill | True | /Users/josh/.claude/skills/pi-agent-rust/SKILL.md | False | missing | 0 | B | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/pipeline-management | pipeline-management | skill | True | /Users/josh/.claude/skills/pipeline-management/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/plan-space-convergence | plan-space-convergence | skill | True | /Users/josh/.claude/skills/plan-space-convergence/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/planning-workflow | planning-workflow | skill | True | /Users/josh/.claude/skills/planning-workflow/SKILL.md | False | missing | 31 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/policy-administration | policy-administration | skill | True | /Users/josh/.claude/skills/policy-administration/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/port-allowlist-manager | port-allowlist-manager | skill | True | /Users/josh/.claude/skills/port-allowlist-manager/SKILL.md | False | missing | 0 | B | 3 | 4 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/post-compact-reminder | post-compact-reminder | skill | True | /Users/josh/.claude/skills/post-compact-reminder/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/pr | pr | skill | True | /Users/josh/.claude/skills/pr/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/pr-name | pr-name | skill | True | /Users/josh/.claude/skills/pr-name/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/prd | prd | skill | True | /Users/josh/.claude/skills/prd/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/predictive-maintenance | predictive-maintenance | skill | True | /Users/josh/.claude/skills/predictive-maintenance/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/pricing-strategy | pricing-strategy | skill | True | /Users/josh/.claude/skills/pricing-strategy/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/prior-authorization | prior-authorization | skill | True | /Users/josh/.claude/skills/prior-authorization/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/process-triage | process-triage | skill | True | /Users/josh/.claude/skills/process-triage/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/procurement-automation | procurement-automation | skill | True | /Users/josh/.claude/skills/procurement-automation/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/producing-zest-feed-episodes | producing-zest-feed-episodes | skill | True | /Users/josh/.claude/skills/producing-zest-feed-episodes/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/product-design-principles/skill | skill | skill | True | /Users/josh/.claude/skills/product-design-principles/skill/SKILL.md | False | missing | 0 | C | 5 | 618 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/product-naming | product-naming | skill | True | /Users/josh/.claude/skills/product-naming/SKILL.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/production-scheduling | production-scheduling | skill | True | /Users/josh/.claude/skills/production-scheduling/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/profiling-software-performance | profiling-software-performance | skill | True | /Users/josh/.claude/skills/profiling-software-performance/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/programmatic-tool-calling | programmatic-tool-calling | skill | True | /Users/josh/.claude/skills/programmatic-tool-calling/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/promo-code-finder | promo-code-finder | skill | True | /Users/josh/.claude/skills/promo-code-finder/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/prompt-engineering-science | prompt-engineering-science | skill | True | /Users/josh/.claude/skills/prompt-engineering-science/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/proposal-generation | proposal-generation | skill | True | /Users/josh/.claude/skills/proposal-generation/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/push-notifications | push-notifications | skill | True | /Users/josh/.claude/skills/push-notifications/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/python-best-practices | python-best-practices | skill | True | /Users/josh/.claude/skills/python-best-practices/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/python-health | python-health | skill | True | /Users/josh/.claude/skills/python-health/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/qdrant-ops | qdrant-ops | skill | True | /Users/josh/.claude/skills/qdrant-ops/SKILL.md | False | missing | 2 | B | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/qos-monitoring | qos-monitoring | skill | True | /Users/josh/.claude/skills/qos-monitoring/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/quality-assurance-manufacturing | quality-assurance-manufacturing | skill | True | /Users/josh/.claude/skills/quality-assurance-manufacturing/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/quality-checking-tts-audio | quality-checking-tts-audio | skill | True | /Users/josh/.claude/skills/quality-checking-tts-audio/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/railway-api | railway-api | skill | True | /Users/josh/.claude/skills/railway-api/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rano | rano | skill | True | /Users/josh/.claude/skills/rano/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rate-limiting | rate-limiting | skill | True | /Users/josh/.claude/skills/rate-limiting/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rch | rch | skill | True | /Users/josh/.claude/skills/rch/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/readme-writing | readme-writing | skill | True | /Users/josh/.claude/skills/readme-writing/SKILL.md | False | missing | 27 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/reality-check-for-project | reality-check-for-project | skill | True | /Users/josh/.claude/skills/reality-check-for-project/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/referral-program | referral-program | skill | True | /Users/josh/.claude/skills/referral-program/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/regulatory-monitoring | regulatory-monitoring | skill | True | /Users/josh/.claude/skills/regulatory-monitoring/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/release-preparations | release-preparations | skill | True | /Users/josh/.claude/skills/release-preparations/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/remotion-best-practices | remotion-best-practices | skill | True | /Users/josh/.claude/skills/remotion-best-practices/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/remotion-zesttube-traumas | remotion-zesttube-traumas | skill | True | /Users/josh/.claude/skills/remotion-zesttube-traumas/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rendering-multi-aspect-remotion | rendering-multi-aspect-remotion | skill | True | /Users/josh/.claude/skills/rendering-multi-aspect-remotion/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/renewal-management | renewal-management | skill | True | /Users/josh/.claude/skills/renewal-management/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/repeatedly-apply-skill | repeatedly-apply-skill | skill | True | /Users/josh/.claude/skills/repeatedly-apply-skill/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/request-response-logging | request-response-logging | skill | True | /Users/josh/.claude/skills/request-response-logging/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/request-validation | request-validation | skill | True | /Users/josh/.claude/skills/request-validation/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/requirements-gathering | requirements-gathering | skill | True | /Users/josh/.claude/skills/requirements-gathering/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/research-software | research-software | skill | True | /Users/josh/.claude/skills/research-software/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/research-triad | research-triad | skill | True | /Users/josh/.claude/skills/research-triad/SKILL.md | False | missing | 1 | B | 3 | 8 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/retry-backoff-patterns | retry-backoff-patterns | skill | True | /Users/josh/.claude/skills/retry-backoff-patterns/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/revenue-recognition | revenue-recognition | skill | True | /Users/josh/.claude/skills/revenue-recognition/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/reviewing-zest-feed-multi-axis | reviewing-zest-feed-multi-axis | skill | True | /Users/josh/.claude/skills/reviewing-zest-feed-multi-axis/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rfp-response | rfp-response | skill | True | /Users/josh/.claude/skills/rfp-response/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rg-optimized | rg-optimized | skill | True | /Users/josh/.claude/skills/rg-optimized/SKILL.md | False | missing | 29 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/role-based-access-ui | role-based-access-ui | skill | True | /Users/josh/.claude/skills/role-based-access-ui/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ru-multi-repo-workflow | ru-multi-repo-workflow | skill | True | /Users/josh/.claude/skills/ru-multi-repo-workflow/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rust-best-practices | rust-best-practices | skill | True | /Users/josh/.claude/skills/rust-best-practices/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rust-cli-with-sqlite | rust-cli-with-sqlite | skill | True | /Users/josh/.claude/skills/rust-cli-with-sqlite/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/rust-crates-publishing | rust-crates-publishing | skill | True | /Users/josh/.claude/skills/rust-crates-publishing/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/saas-cli-auth-flow | saas-cli-auth-flow | skill | True | /Users/josh/.claude/skills/saas-cli-auth-flow/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/saas-customer-analytics | saas-customer-analytics | skill | True | /Users/josh/.claude/skills/saas-customer-analytics/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/saas-scaffolder | saas-scaffolder | skill | True | /Users/josh/.claude/skills/saas-scaffolder/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/safe-migrations | safe-migrations | skill | True | /Users/josh/.claude/skills/safe-migrations/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/sales-forecasting | sales-forecasting | skill | True | /Users/josh/.claude/skills/sales-forecasting/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/scheduling-orchestration | scheduling-orchestration | skill | True | /Users/josh/.claude/skills/scheduling-orchestration/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/security-audit-for-saas | security-audit-for-saas | skill | True | /Users/josh/.claude/skills/security-audit-for-saas/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/security-pen-testing | security-pen-testing | skill | True | /Users/josh/.claude/skills/security-pen-testing/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/security-posture | security-posture | skill | True | /Users/josh/.claude/skills/security-posture/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/security-review | security-review | skill | True | /Users/josh/.claude/skills/security-review/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/self-improving-agent | self-improving-agent | skill | True | /Users/josh/.claude/skills/self-improving-agent/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/self-improving-agent/skills/extract | extract | skill | True | /Users/josh/.claude/skills/self-improving-agent/skills/extract/SKILL.md | False | missing | 0 | C | 4 | 22 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/self-improving-agent/skills/promote | promote | skill | True | /Users/josh/.claude/skills/self-improving-agent/skills/promote/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/self-improving-agent/skills/remember | remember | skill | True | /Users/josh/.claude/skills/self-improving-agent/skills/remember/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/self-improving-agent/skills/review | review | skill | True | /Users/josh/.claude/skills/self-improving-agent/skills/review/SKILL.md | False | missing | 0 | C | 5 | 93 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/self-improving-agent/skills/status | status | skill | True | /Users/josh/.claude/skills/self-improving-agent/skills/status/SKILL.md | False | missing | 0 | C | 5 | 247 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/seo-audit | seo-audit | skill | True | /Users/josh/.claude/skills/seo-audit/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/service-mesh | service-mesh | skill | True | /Users/josh/.claude/skills/service-mesh/SKILL.md | False | missing | 3 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/sharepoint-microsoft | sharepoint-microsoft | skill | True | /Users/josh/.claude/skills/sharepoint-microsoft/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/shopper-buy-decision-grader | shopper-buy-decision-grader | skill | True | /Users/josh/.claude/skills/shopper-buy-decision-grader/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/shopper-spec-drift-detector | shopper-spec-drift-detector | skill | True | /Users/josh/.claude/skills/shopper-spec-drift-detector/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically | simplify-and-refactor-code-isomorphically | skill | True | /Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/skill-autoresearch | skill-autoresearch | skill | True | /Users/josh/.claude/skills/skill-autoresearch/SKILL.md | False | missing | 1 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/skill-builder | skill-builder | skill | True | /Users/josh/.claude/skills/skill-builder/SKILL.md | False | missing | 1 | B | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/skill-search-mcp | skill-search-mcp | skill | True | /Users/josh/.claude/skills/skill-search-mcp/SKILL.md | False | missing | 0 | C | 3 | 4 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/sla-monitoring | sla-monitoring | skill | True | /Users/josh/.claude/skills/sla-monitoring/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/slb | slb | skill | True | /Users/josh/.claude/skills/slb/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/socratic-cross | socratic-cross | skill | True | /Users/josh/.claude/skills/socratic-cross/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/socraticode | socraticode | skill | True | /Users/josh/.claude/skills/socraticode/SKILL.md | False | missing | 1 | C | 4 | 33 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/spec-driven-workflow | spec-driven-workflow | skill | True | /Users/josh/.claude/skills/spec-driven-workflow/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/speculative-caching | speculative-caching | skill | True | /Users/josh/.claude/skills/speculative-caching/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/sqlmodel-rust | sqlmodel-rust | skill | True | /Users/josh/.claude/skills/sqlmodel-rust/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ssh | ssh | skill | True | /Users/josh/.claude/skills/ssh/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/state-management | state-management | skill | True | /Users/josh/.claude/skills/state-management/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/state-truth-recovery | state-truth-recovery | skill | True | /Users/josh/.claude/skills/state-truth-recovery/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/statistical-analysis | statistical-analysis | skill | True | /Users/josh/.claude/skills/statistical-analysis/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/stop-slop | stop-slop | skill | True | /Users/josh/.claude/skills/stop-slop/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/storage-ballast-helper | storage-ballast-helper | skill | True | /Users/josh/.claude/skills/storage-ballast-helper/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/storage-health | storage-health | skill | True | /Users/josh/.claude/skills/storage-health/SKILL.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/stripe-checkout | stripe-checkout | skill | True | /Users/josh/.claude/skills/stripe-checkout/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/subscriber-activation | subscriber-activation | skill | True | /Users/josh/.claude/skills/subscriber-activation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/substrate-bleed-triage | substrate-bleed-triage | skill | True | /Users/josh/.claude/skills/substrate-bleed-triage/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/supabase | supabase | skill | True | /Users/josh/.claude/skills/supabase/SKILL.md | False | missing | 0 | C | 3 | 9 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/supabase-api | supabase-api | skill | True | /Users/josh/.claude/skills/supabase-api/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/supply-chain-control-tower | supply-chain-control-tower | skill | True | /Users/josh/.claude/skills/supply-chain-control-tower/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/swarm-operator-loop | swarm-operator-loop | skill | True | /Users/josh/.claude/skills/swarm-operator-loop/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/system-health | system-health | skill | True | /Users/josh/.claude/skills/system-health/SKILL.md | False | missing | 0 | B | 3 | 4 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/system-performance-remediation | system-performance-remediation | skill | True | /Users/josh/.claude/skills/system-performance-remediation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/tanstack | tanstack | skill | True | /Users/josh/.claude/skills/tanstack/SKILL.md | False | missing | 28 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/tax-preparation | tax-preparation | skill | True | /Users/josh/.claude/skills/tax-preparation/SKILL.md | False | missing | 1 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/tax-return-preparation-and-advice-generic | tax-return-preparation-and-advice-generic | skill | True | /Users/josh/.claude/skills/tax-return-preparation-and-advice-generic/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/teams-sdks | teams-sdks | skill | True | /Users/josh/.claude/skills/teams-sdks/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/tech-debt-management | tech-debt-management | skill | True | /Users/josh/.claude/skills/tech-debt-management/SKILL.md | False | missing | 41 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/technical-writing | technical-writing | skill | True | /Users/josh/.claude/skills/technical-writing/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/territory-planning | territory-planning | skill | True | /Users/josh/.claude/skills/territory-planning/SKILL.md | False | missing | 2 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/testing-conformance-harnesses | testing-conformance-harnesses | skill | True | /Users/josh/.claude/skills/testing-conformance-harnesses/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/testing-fuzzing | testing-fuzzing | skill | True | /Users/josh/.claude/skills/testing-fuzzing/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/testing-golden-artifacts | testing-golden-artifacts | skill | True | /Users/josh/.claude/skills/testing-golden-artifacts/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/testing-metamorphic | testing-metamorphic | skill | True | /Users/josh/.claude/skills/testing-metamorphic/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/testing-real-service-e2e-no-mocks | testing-real-service-e2e-no-mocks | skill | True | /Users/josh/.claude/skills/testing-real-service-e2e-no-mocks/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/testing-tts-conformance | testing-tts-conformance | skill | True | /Users/josh/.claude/skills/testing-tts-conformance/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/text-to-sql | text-to-sql | skill | True | /Users/josh/.claude/skills/text-to-sql/SKILL.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/tick-protocol-init | tick-protocol-init | skill | True | /Users/josh/.claude/skills/tick-protocol-init/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ticket-triage | ticket-triage | skill | True | /Users/josh/.claude/skills/ticket-triage/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/time-series-analysis | time-series-analysis | skill | True | /Users/josh/.claude/skills/time-series-analysis/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/trouble-ticket-automation | trouble-ticket-automation | skill | True | /Users/josh/.claude/skills/trouble-ticket-automation/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/tui-glamorous | tui-glamorous | skill | True | /Users/josh/.claude/skills/tui-glamorous/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/tui-inspector | tui-inspector | skill | True | /Users/josh/.claude/skills/tui-inspector/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/typescript-best-practices | typescript-best-practices | skill | True | /Users/josh/.claude/skills/typescript-best-practices/SKILL.md | False | missing | 3 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ubs | ubs | skill | True | /Users/josh/.claude/skills/ubs/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/udr-rag-hybrid | udr-rag-hybrid | skill | True | /Users/josh/.claude/skills/udr-rag-hybrid/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ui-polish | ui-polish | skill | True | /Users/josh/.claude/skills/ui-polish/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/underwriting-automation | underwriting-automation | skill | True | /Users/josh/.claude/skills/underwriting-automation/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/upsell-identification | upsell-identification | skill | True | /Users/josh/.claude/skills/upsell-identification/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/uptime-monitoring | uptime-monitoring | skill | True | /Users/josh/.claude/skills/uptime-monitoring/SKILL.md | False | missing | 2 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/using-voicebox-multi-engine | using-voicebox-multi-engine | skill | True | /Users/josh/.claude/skills/using-voicebox-multi-engine/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/ux-audit | ux-audit | skill | True | /Users/josh/.claude/skills/ux-audit/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/vector-ingest-verification | vector-ingest-verification | skill | True | /Users/josh/.claude/skills/vector-ingest-verification/SKILL.md | False | missing | 2 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/vercel | vercel | skill | True | /Users/josh/.claude/skills/vercel/SKILL.md | False | missing | 0 | B | 3 | 8 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/vercel-api | vercel-api | skill | True | /Users/josh/.claude/skills/vercel-api/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/vibing-with-ntm | vibing-with-ntm | skill | True | /Users/josh/.claude/skills/vibing-with-ntm/SKILL.md | False | missing | 0 | C | 3 | 7 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/video-obs-youtube-music | video-obs-youtube-music | skill | True | /Users/josh/.claude/skills/video-obs-youtube-music/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/video-report | video-report | skill | True | /Users/josh/.claude/skills/video-report/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/voice-ai | voice-ai | skill | True | /Users/josh/.claude/skills/voice-ai/SKILL.md | False | missing | 0 | B | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/voice-of-customer | voice-of-customer | skill | True | /Users/josh/.claude/skills/voice-of-customer/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/web-renderer-test | web-renderer-test | skill | True | /Users/josh/.claude/skills/web-renderer-test/SKILL.md | False | missing | 0 | C | 3 | 4 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/web-visual-qa | web-visual-qa | skill | True | /Users/josh/.claude/skills/web-visual-qa/SKILL.md | False | missing | 0 | B | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/webhook-automation | webhook-automation | skill | True | /Users/josh/.claude/skills/webhook-automation/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/websocket-sse-patterns | websocket-sse-patterns | skill | True | /Users/josh/.claude/skills/websocket-sse-patterns/SKILL.md | False | missing | 3 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/wezterm | wezterm | skill | True | /Users/josh/.claude/skills/wezterm/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/wrangler | wrangler | skill | True | /Users/josh/.claude/skills/wrangler/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/writing-docs | writing-docs | skill | True | /Users/josh/.claude/skills/writing-docs/SKILL.md | False | missing | 0 | C | 3 | 6 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/writing-qwen-tts-scripts | writing-qwen-tts-scripts | skill | True | /Users/josh/.claude/skills/writing-qwen-tts-scripts/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/x-cli | x-cli | skill | True | /Users/josh/.claude/skills/x-cli/SKILL.md | False | missing | 0 | C | 3 | 2 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/xf | xf | skill | True | /Users/josh/.claude/skills/xf/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/zeststream-brand-voice | zeststream-brand-voice | skill | True | /Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md | False | missing | 1 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/zeststream-client-onboarding | zeststream-client-onboarding | skill | True | /Users/josh/.claude/skills/zeststream-client-onboarding/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/zeststream-n8n | zeststream-n8n | skill | True | /Users/josh/.claude/skills/zeststream-n8n/SKILL.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/zeststream-onboarding | zeststream-onboarding | skill | True | /Users/josh/.claude/skills/zeststream-onboarding/SKILL.md | False | missing | 0 | C | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/zeststream-peel-report | zeststream-peel-report | skill | True | /Users/josh/.claude/skills/zeststream-peel-report/SKILL.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/zeststream-pr | zeststream-pr | skill | True | /Users/josh/.claude/skills/zeststream-pr/SKILL.md | False | missing | 0 | C | 4 | 35 | 0 | n/a | n/a |
| /Users/josh/.claude/skills/zesttube-e2e-smoke | zesttube-e2e-smoke | skill | True | /Users/josh/.claude/skills/zesttube-e2e-smoke/SKILL.md | False | missing | 0 | B | 2 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/README.md | README.md | command | True | /Users/josh/.claude/commands/flywheel/README.md | False | missing | 0 | B | 3 | 5 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/bead-new.md | bead-new.md | command | True | /Users/josh/.claude/commands/flywheel/bead-new.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/beads.md | beads.md | command | True | /Users/josh/.claude/commands/flywheel/beads.md | False | missing | 0 | C | 5 | 65 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/dispatch.md | dispatch.md | command | True | /Users/josh/.claude/commands/flywheel/dispatch.md | False | missing | 0 | C | 5 | 584 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/handoff.md | handoff.md | command | True | /Users/josh/.claude/commands/flywheel/handoff.md | False | missing | 0 | B | 5 | 7 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/inbox.md | inbox.md | command | True | /Users/josh/.claude/commands/flywheel/inbox.md | False | missing | 0 | C | 3 | 5 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/init.md | init.md | command | True | /Users/josh/.claude/commands/flywheel/init.md | False | missing | 0 | C | 4 | 21 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/learn.md | learn.md | command | True | /Users/josh/.claude/commands/flywheel/learn.md | False | missing | 0 | B | 5 | 81 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/lock.md | lock.md | command | True | /Users/josh/.claude/commands/flywheel/lock.md | False | missing | 0 | C | 5 | 108 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/loop.md | loop.md | command | True | /Users/josh/.claude/commands/flywheel/loop.md | False | missing | 0 | B | 5 | 113 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/newcmd.md | newcmd.md | command | True | /Users/josh/.claude/commands/flywheel/newcmd.md | False | missing | 0 | B | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/ntm.md | ntm.md | command | True | /Users/josh/.claude/commands/flywheel/ntm.md | False | missing | 0 | B | 5 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/plan.md | plan.md | command | True | /Users/josh/.claude/commands/flywheel/plan.md | False | missing | 0 | B | 4 | 46 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/relock-state.md | relock-state.md | command | True | /Users/josh/.claude/commands/flywheel/relock-state.md | False | missing | 0 | C | 3 | 1 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/research.md | research.md | command | True | /Users/josh/.claude/commands/flywheel/research.md | False | missing | 0 | B | 4 | 20 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/status.md | status.md | command | True | /Users/josh/.claude/commands/flywheel/status.md | False | missing | 0 | C | 5 | 247 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/synth.md | synth.md | command | True | /Users/josh/.claude/commands/flywheel/synth.md | False | missing | 0 | C | 4 | 12 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/tail.md | tail.md | command | True | /Users/josh/.claude/commands/flywheel/tail.md | False | missing | 0 | C | 4 | 26 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/tick.md | tick.md | command | True | /Users/josh/.claude/commands/flywheel/tick.md | False | missing | 0 | B | 5 | 479 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/worker-tick.md | worker-tick.md | command | True | /Users/josh/.claude/commands/flywheel/worker-tick.md | False | missing | 0 | C | 5 | 4 | 0 | n/a | n/a |
| /Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md | AGENTS-CANONICAL.md | doc | True | /Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md | False | missing | 0 | C | 5 | 55 | 0 | n/a | n/a |
| /Users/josh/Developer/flywheel/.flywheel/GOAL.md | GOAL.md | doc | True | /Users/josh/Developer/flywheel/.flywheel/GOAL.md | False | missing | 0 | C | 3 | 7 | 0 | n/a | n/a |
| /Users/josh/Developer/flywheel/.flywheel/MISSION.md | MISSION.md | doc | True | /Users/josh/Developer/flywheel/.flywheel/MISSION.md | False | missing | 0 | C | 4 | 13 | 0 | n/a | n/a |
| /Users/josh/Developer/flywheel/.flywheel/STATE.md | STATE.md | doc | True | /Users/josh/Developer/flywheel/.flywheel/STATE.md | False | missing | 0 | C | 4 | 27 | 0 | n/a | n/a |
| /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md | dispatch-template.md | dispatch-template | True | /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md | False | missing | 0 | B | 3 | 6 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md | MEMORY.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md | False | missing | 0 | C | 3 | 3 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_callback_first_dispatch.md | feedback_callback_first_dispatch.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_callback_first_dispatch.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_callback_pane_registry.md | feedback_callback_pane_registry.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_callback_pane_registry.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_never_idles.md | feedback_flywheel_never_idles.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_never_idles.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_jeff_issue_chain.md | feedback_jeff_issue_chain.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_jeff_issue_chain.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_meadows_jeff_mentors.md | feedback_meadows_jeff_mentors.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_meadows_jeff_mentors.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_no_idle_clean_doctrine.md | feedback_no_idle_clean_doctrine.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_no_idle_clean_doctrine.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_no_push_ntm_br.md | feedback_no_push_ntm_br.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_no_push_ntm_br.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_pane_state_ntm_health.md | feedback_pane_state_ntm_health.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_pane_state_ntm_health.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_use_codex_workers.md | feedback_use_codex_workers.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_use_codex_workers.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_verify_ntm_send.md | feedback_verify_ntm_send.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_verify_ntm_send.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_wire_into_ecosystem.md | feedback_wire_into_ecosystem.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_wire_into_ecosystem.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_alps_quintessential_member_2026_05_01.md | project_alps_quintessential_member_2026_05_01.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_alps_quintessential_member_2026_05_01.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_bead_isolation_plan.md | project_bead_isolation_plan.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_bead_isolation_plan.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_fleet_observatory_2026_05_01.md | project_fleet_observatory_2026_05_01.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_fleet_observatory_2026_05_01.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_session_handoff_v04_2026_05_01.md | project_session_handoff_v04_2026_05_01.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_session_handoff_v04_2026_05_01.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_skillos_separated.md | project_skillos_separated.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_skillos_separated.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_agent_mail_service.md | reference_agent_mail_service.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_agent_mail_service.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_dicklesworthstone_stack_ntm.md | reference_dicklesworthstone_stack_ntm.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_dicklesworthstone_stack_ntm.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_lavenderglen_fleet_mail.md | reference_lavenderglen_fleet_mail.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_lavenderglen_fleet_mail.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_upstream_issues.md | reference_upstream_issues.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_upstream_issues.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_watcherctl_zeststream_infra.md | reference_watcherctl_zeststream_infra.md | memory | True | /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_watcherctl_zeststream_infra.md | False | missing | 0 | C | 1 | 0 | 0 | n/a | n/a |
| /Users/josh/Developer/flywheel/AGENTS.md | L48 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | SUBSTRATE-EXHAUSTION-BEFORE-ESCALATION |
| /Users/josh/Developer/flywheel/AGENTS.md | L29 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | NTM-only doctrine |
| /Users/josh/Developer/flywheel/AGENTS.md | L35 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | Every Tier 3 classification requires a paired-tool bead |
| /Users/josh/Developer/flywheel/AGENTS.md | L50 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | SOCRATICODE-MANDATORY-IN-EVERY-DISPATCH (every NTM dispatch surveys what we have before writing what we want) |
| /Users/josh/Developer/flywheel/AGENTS.md | L51 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | DISPATCH-FILE-RESERVATIONS-MANDATORY (every multi-file worker dispatch reserves files via agent-mail before edits) |
| /Users/josh/Developer/flywheel/AGENTS.md | L52 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | ISSUES-TO-BEADS-OR-EXPLICIT-NO-BEAD-RECEIPT (no observed gap is absorbed silently) |
| /Users/josh/Developer/flywheel/AGENTS.md | L53 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | FUCKUPS-REPORTED-IN-CALLBACK (every blocker / trauma / gap surfaces as a fuckup-log row) |
| /Users/josh/Developer/flywheel/AGENTS.md | L54 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | SKILL-DEEP-DIVE-ON-BLOCKERS (workers climb the skill tree before declaring a wall) |
| /Users/josh/Developer/flywheel/AGENTS.md | L55 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | SKILLOS-ESCALATION-FOR-MISSING-SKILLS (when no skill exists for a trauma class, route to skillos) |
| /Users/josh/Developer/flywheel/AGENTS.md | L56 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | FUCKUP-LOG → INCIDENTS → CANONICAL-L-RULE PROMOTION LADDER |
| /Users/josh/Developer/flywheel/AGENTS.md | L60 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | Per-session topology must be declared, not assumed |
| /Users/josh/Developer/flywheel/AGENTS.md | L61 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | Cross-session comms use BOTH ntm send AND agent-mail |
| /Users/josh/Developer/flywheel/AGENTS.md | L62 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | Workers emit skill-discovery rows at every callback |
| /Users/josh/Developer/flywheel/AGENTS.md | L63 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | Recovery primitives must rehearse before claiming reliability |
| /Users/josh/Developer/flywheel/AGENTS.md | L65 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | Cross-orch comms route through fleet-mail-project |
| /Users/josh/Developer/flywheel/AGENTS.md | L66 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | USE-DATA-NOT-MEAT-PUPPET (orchestrator must dispatch when evidence already selected an action) |
| /Users/josh/Developer/flywheel/AGENTS.md | L67 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | RAILWAY-TOKEN-SUBSTRATE-PROBE (deploy-token failures need substrate ledger before retry) |
| /Users/josh/Developer/flywheel/AGENTS.md | L68 | l-rule | True | /Users/josh/Developer/flywheel/AGENTS.md | False | missing | 0 | C | 5 | 0 | 0 | n/a | CORTEX→ENGINE-HANDOFF (worker findings + flywheel doctrine route to skillos as structured packets) |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | mission-anchor-bundle | registry-row | False | missing | False | 2026-04-29T04:01:43Z | 0 | F | 5 | 0 | 5 | n/a | kind=bundle owner=mission-anchor-init state_path=~/.claude/skills/mission-anchor-init/SELF-TEST.md |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | firewall-policy-bundle | registry-row | False | missing | False | 2026-05-01T06:24:00Z | 0 | F | 5 | 0 | 5 | n/a | kind=bundle owner=ecosystem-port-security state_path=/etc/pf.anchors/com.zeststream.ecosystem-port-security |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | skill-os-kernel-bundle | registry-row | False | missing | False | 2026-04-28T21:30:30Z | 0 | F | 5 | 0 | 6 | n/a | kind=bundle owner=skill-builder state_path=~/.claude/skills/.flywheel/reports/skill-os-pilot-latest.json |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | substrate-intake-bundle | registry-row | False | missing | False | 2026-04-28T20:48:12Z | 0 | F | 5 | 0 | 5 | n/a | kind=bundle owner=install-substrate state_path=~/.claude/skills/.flywheel/data/substrate-registry.json |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-vibe-cockpit | registry-row | False | missing | False | 2026-05-01T19:05:00Z | 0 | F | 4 | 0 | 3 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=~/Library/Application Support/vc/vc.duckdb |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-ntm | registry-row | False | missing | False | missing | 0 | F | 5 | 0 | 6 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/.config/ntm |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-beads-rust | registry-row | False | missing | False | missing | 0 | F | 5 | 0 | 5 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/Developer/flywheel/.beads/beads.db |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-bv | registry-row | False | missing | False | missing | 0 | F | 4 | 0 | 4 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/Developer/flywheel/.beads/beads.db |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-cass | registry-row | False | missing | False | missing | 0 | F | 5 | 0 | 5 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/Library/Application Support/com.coding-agent-search.coding-agent-search |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-dcg | registry-row | False | missing | False | missing | 0 | F | 4 | 0 | 4 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/.config/dcg |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-mcp-agent-mail | registry-row | False | missing | False | missing | 0 | F | 5 | 0 | 5 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/.local/share/mcp_agent_mail |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-frankensqlite | registry-row | False | missing | False | missing | 0 | F | 4 | 0 | 4 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/Developer/frankensqlite |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | dicklesworthstone-pi-agent-rust | registry-row | False | missing | False | missing | 0 | F | 4 | 0 | 4 | n/a | kind=tentacle owner=dicklesworthstone-stack state_path=/Users/josh/.pi/agent |
| /Users/josh/.claude/skills/.flywheel/data/substrate-registry.json | zeststream-skillos | registry-row | False | missing | False | 2026-05-01T19:49:49Z | 0 | F | 5 | 0 | 5 | n/a | kind=tentacle owner=zeststream-skillos state_path=~/Developer/skillos/.flywheel/STATE.md |
