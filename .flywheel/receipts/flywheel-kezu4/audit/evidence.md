# flywheel-kezu4 — cross-orch ratification review of skillos `~/.claude` retention manifest v1

## Bead context

- ID: `flywheel-kezu4` (P2)
- Title: `[cross-orch:skillos] ~/.claude retention manifest ratification — review flywheel-touching rules (handoff 2026-05-09T173000Z, PR #174)`
- Parent handoff: `.flywheel/handoffs/2026-05-09T173000Z-from-skillos-1-claude-state-retention-manifest-ratification.md` (skillos:1 BrightLake → flywheel:1 RubyCastle)
- Manifest under review: `/Users/josh/Developer/skillos/state/claude-state-retention-manifest-v1.json` (20 rules, ratified_at=null, mission_anchor matches)
- Pruner under review: `/Users/josh/Developer/skillos/scripts/skillos_claude_state_pruner.py` (canonical-cli with health/doctor/repair/audit/validate)

## DoD gates (3) per parent handoff's three confirmation asks

| AG | Status | Verdict |
|---|---|---|
| 1. No retention rule deletes a path flywheel-loop needs preserved beyond its window | DONE | ✓ Protected paths cover all flywheel-loop write surfaces. Per-tick artifact retention windows (proposed v2: 14d tool-results, 30d UUID dirs/subagents, 200 most-recent transcripts) are >= flywheel-loop's longest known back-reference window (gap-hunt-probe's 30d state-dir window). |
| 2. Per-tick artifact retention windows match flywheel's substrate-integrity contract | DONE | ✓ See AG1; gap-hunt's 30d window reads `~/.local/state/flywheel/*.jsonl` (NOT under `~/.claude/`), so manifest's 14d on tool-results doesn't touch flywheel's audit chain. |
| 3. Receipt-ledger format is mutually parseable for cross-orch audit | DONE | ✓ `skillos.claude_state_pruner_receipt.v1` schema is jq-parseable; every field machine-readable; `mission_anchor_hash` per-row enables cross-orch verification. |

`did=3/3`

## Verdict: **Option B — request rule changes before ratification**

The manifest's design intent (bound `~/.claude/` accreting state) is correct. The receipt-ledger schema is parseable. Safety posture is correct (default keep-all + protected halt + dry-run + idempotency-key + halt-on-protected). But three rules — including the manifest's stated highest-volume target — are pattern-mismatched against the live `~/.claude/projects/` layout:

| Real-layout path | Files | Manifest rule | Status |
|---|---|---|---|
| `~/.claude/projects/*/*/subagents/*` | **5,827** | (none) | UNCOVERED — highest-volume single category |
| `~/.claude/projects/*/memory/*` | 6,783 | `projects-memory-protected` | PROTECTED ✓ |
| `~/.claude/projects/*/*.jsonl` (top-level transcripts) | 756 | `projects-conversations` (`*/conversations`) | UNCOVERED — pattern-mismatch |
| `~/.claude/projects/*/*/tool-results/*` | 588 | `projects-tasks-output` (`*/tasks/*/output`) | UNCOVERED — pattern-mismatch |

Manifest's claimed "highest-volume accreting path" = `~/.claude/projects/*/tasks/*/output` matches **0 files**. There are no `tasks/` directories under `~/.claude/projects/` in this Claude Code version's layout. Same for `conversations/` directories.

Live doctor probe (captured at `skillos-pruner-doctor-output.json`):

```
{"status": "FAIL", "manifest_ratified_at": null, "manifest_version": 1,
 "rule_summaries": [
   {"pattern": "~/.claude/transcripts",   "eligible_count": 362},
   {"pattern": "~/.claude/paste-cache",   "eligible_count": 1349},
   {"pattern": "~/.claude/agent-context", "eligible_count": 9},
   {"pattern": "~/.claude/backup_hooks",  "eligible_count": 1149},
   {"pattern": "~/.claude/ensemble",      "eligible_count": 1}
 ]}
```

Only 5 of 20 rules have any matches. Total eligible across matching rules: 2,870 files. Real high-volume target paths (13,991 files under `projects/*`) are invisible to v1.

## Required v2 rule changes

| Action | Old rule | Pattern (corrected) | Retention | Why |
|---|---|---|---|---|
| REPLACE | `projects-tasks-output` | `~/.claude/projects/*/*/tool-results/*` | last-N-days, days=14 | Actual per-task tool output path |
| REPLACE | `projects-tasks-files` | `~/.claude/projects/*/*` (UUID-shape filter) | last-N-days, days=30 | Per-session UUID dirs older than 30d |
| REPLACE | `projects-conversations` | `~/.claude/projects/*/*.jsonl` | last-N-files, limit=200 | Top-level transcript JSONL files |
| ADD | `projects-subagents` | `~/.claude/projects/*/*/subagents/*` | last-N-days, days=30 | Largest single category at 5,827 files |

Optional but valuable v2 additions:

| Action | Pattern | Retention | Why |
|---|---|---|---|
| ADD | `/private/tmp/claude-501/*/*/tasks/*` | last-N-days, days=14 | 469 files in sister surface (requires extending target_root or supporting absolute paths) |
| ADD | `~/.claude/.agents/tasks` | last-N-days, days=14 | Global agent-tasks surface present today |

## What flywheel:1 confirms is correct in v1 (NO change needed)

1. **Protected paths cover all flywheel-loop write surfaces** — `skills`, `commands`, `hooks`, `references`, `memory`, `projects/*/memory`, `CLAUDE.md`, secret ledgers — all correctly listed.
2. **Receipt-ledger schema is mutually parseable** — every field jq-accessible; `mission_anchor_hash` per-row.
3. **Safety posture (default keep-all + protected halt + dry-run + idempotency + halt-on-protected) is correct** — do NOT relax.
4. **Doctrine alignment is correct** — B5/B3/R1 mappings hold.

## Cross-orch concern flagged for v2

v2 should add a `live_match_audit` step in doctor that flags rules with `eligible_count == 0` for >7 days (rotting-rule alarm). This would have caught the v1 pattern-mismatch automatically. Filed as a concern in the handoff, not an acceptance gate.

## L52 bead receipt

- `beads_filed=none` (skillos:1 owns the next action: ship v2 with rule changes; flywheel:1 will ratify on re-handoff)
- `beads_updated=flywheel-kezu4` (closed by this dispatch)
- `no_bead_reason=cross-orch ratification gate; the next-actionable owner is skillos:1 (ship v2). Not flywheel:1 scope to author the rule fixes; manifest ownership is skillos:1 per parent handoff.`

## L61 ECOSYSTEM-TOUCH

This work touches `.flywheel/handoffs/` (cross-orch handoff substrate) but no canonical doctrine, INCIDENTS, or skill surface in flywheel repo:

- `agents_md_updated=not_applicable`
- `readme_updated=not_applicable`
- `no_touch_reason=cross-orch ratification response; manifest is skillos-owned (skillos:1 per parent handoff); flywheel-side handoff is the canonical channel for ratification responses; no flywheel doctrine or canonical L-rule surface touched.`

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | n/a | No CLI/flag authored. Existing canonical-cli probe (`skillos_claude_state_pruner.py`) was used read-only. |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | No Python authored. The pruner is skillos's; no edits. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — measured ratification verdict (Option B with concrete rule-change deltas backed by live filesystem audit). Doesn't reject the manifest; doesn't rubber-stamp.
- **sniff: 9** — ran live doctor probe + filesystem audit + cross-checked every protected path against flywheel-loop write surfaces; identified pattern-mismatch class (rotting rule alarm) as a v2 doctor improvement.
- **jeff: 9** — single-source-of-truth: parent handoff is skillos's; this response is flywheel's; both live in `.flywheel/handoffs/` per the canonical channel; receipt-ledger schema confirmed parseable; manifest ownership stays at skillos:1.
- **public: 9** — Three Judges: skeptical operator (live doctor output captured; volume-counted; pattern-mismatch reproducible by `find` + `jq`), maintainer (the v2 rule deltas are concrete + drop-in), future worker (rule deltas reference exact file counts and patterns; cross-orch fleet propagation note covers mobile-eats:1, alpsinsurance:1, vrtx:1).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`adjacent` — ratification response unblocks skillos:1's Phase 16-α-1 propagation arc. Without flywheel:1's ratification, skillos:1 can't install the launchd plist; without rule corrections, the plist would have been installed against patterns that don't match the live filesystem layout (operational-health risk: claims-success-without-effect class). Serves continuous-orchestrator-uptime by ensuring the cross-orch retention substrate actually does what it claims when it ships.

## Out-of-scope (intentional)

- **Authoring v2 of the manifest** — skillos:1 owns the manifest authoring per parent handoff "Will sample any rule changes via this same handoff channel before manifest version bumps." Flywheel:1's role is ratification, not authoring.
- **Touching the pruner script** — `skillos_claude_state_pruner.py` is skillos's surface; no edits.
- **Installing the launchd plist** — explicitly held per skillos:1's parent commitment "Will not install launchd until RubyCastle ratifies." Flywheel:1 holds ratification until v2 ships.
- **Cross-orch propagation to mobile-eats:1, alpsinsurance:1, vrtx:1** — flagged in the handoff but propagation is skillos:1's Phase 16-α-1 task.
