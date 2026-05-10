---
title: "Meadows Leverage Analysis — codex-orch-feedback-gap (and validate-everything umbrella)"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Meadows Leverage Analysis — codex-orch-feedback-gap (and validate-everything umbrella)

Captured: 2026-05-03T22:42Z by flywheel:1 orch
Source: Joshua reframe "do A first then take most /donella-meadows-systems-thinking approach"
Skill: ~/.claude/skills/donella-meadows-systems-thinking/

## SYSTEM
Cross-runtime feedback flow Joshua → orch(s); applies to capture surface AND to entire validate-everything plan.

## STOCK
Captured Joshua-prompts available to ALL orch tick consumers.
Currently: 12 rows / 100% Claude / 0% Codex. Stock flat-at-zero on Codex side.

## PATTERN
Joshua issues directives to skillos:1 / mobile-eats:1 → orchs receive via tmux/ntm → no canonical capture → tick prelude can't surface → doctrine drift accumulates → Joshua periodically asks "are you getting my messages?" as the only error signal.

## LOOP (missing balancing loop)
Claude side B-loop: prompt → hook → JSONL → tick prelude → orch action → reduces unread.
Codex side: severed at hook stage. Nothing closes the gap.

## DELAY
Joshua-discovery delay = hours-to-days. Doctrine-propagation delay = ≤24h via doctrine-sync.

## LEVERAGE HIERARCHY (Meadows 1999, highest first)

| # | Level | This problem | Recommended? |
|---|---|---|---|
| 2 | Paradigm | Flywheel was Claude-first by accident. "Codex orchs are second-class" is the unstated paradigm. | Yes — name it explicitly so we don't keep re-suffering |
| 3 | Goal | Codex orchs goaled to "run the loop" not "participate symmetrically in fleet learning." | YES — re-goal to "all orchs are first-class fleet participants" |
| 4 | Self-organization | Premature here without #3 alignment | No — would parameter-thrash |
| 5 | Rules | "Non-capturing orch is non-conformant" + doctor-signal gate | YES — pair with #3 |
| 6 | Information flows | The hook itself (xap2) | YES — but as MECHANISM under #3+#5, not the headline |
| 7-9 | Buffers/stocks/delays | Don't help when stock=0 | No |
| 10-12 | Parameters | Tweaking timeouts | No — lowest leverage |

## RECOMMENDED INTERVENTION (combined #3+#5+#6)

1. **L71 ORCH-CAPTURE-PARITY** (rule + goal alignment)
   - Every orch (Claude/Codex/future) MUST surface Joshua-originated input to canonical josh-requests substrate
   - Orchs without capture path = doctor non-conformant
   - Goal: cross-runtime symmetry of fleet participation

2. **Doctor signal `orchs_with_capture_gap_count`**
   - Produced from josh-requests session-coverage check
   - Threshold: ≥1 → status=warn 7d → status=fail
   - Self-test: every active orch session must have ≥1 capture row in last 24h

3. **Mechanism (pluggable per runtime, NOT Claude-hook-shaped)**
   - **Primary:** agent-mail (Joshua sends critical directives via cross-orch agent-mail = native capture, no codex hook needed)
   - **Secondary:** ntm-send wrapper (every orch send writes JSONL row with `captured_via=ntm_send`)
   - **Tertiary:** codex-pane-tail-poller (5-min cron scans codex panes for new prompts, dedup via prompt_hash)

## MEASURE (the loop that proves intervention)

- Stock: rows/day per orch session (target: non-zero for every active orch within 7d)
- Flow: capture latency p95 (Claude ~3s; Codex via agent-mail <60s)
- Gap-loop: `orchs_with_capture_gap_count` trends to 0 within 14d
- Anti-recurrence: when next runtime added (Cursor? Aider?), doctor flags non-conformance within 1 hour

## SOURCE
- Meadows 1999 leverage hierarchy: Donella Meadows Project /leverage-points-places-to-intervene-in-a-system/, page TODO
- Local: ~/.claude/skills/donella-meadows-systems-thinking/references/LEVERAGE-POINTS.md (verified on disk)

## INTEGRATION INTO PLAN

This analysis upgrades:
- Phase 4 pre-draft B11/B12 (currently #6-only) → must become #3+#5+#6 stack
- flywheel-xap2 (currently P1 hook implementation) → should become parent-epic with rule + signal + mechanism children

## Why this beats "ship the hook"

Hook-only fix (#6 alone) reaches:
- Codex info flow gap closed for now
- BUT: no rule = next runtime repeats gap
- BUT: no goal alignment = captured prompts treated as informational not actionable
- BUT: no doctor signal = drift recurs silently

Combined #3+#5+#6 stack means: **next time we add a runtime, doctor immediately flags non-conformance, L-rule says "fix or non-participating," capture mechanism is per-runtime-pluggable.**

## Out of scope for this analysis

- Implementing the rule/signal/mechanism (Phase 4-5)
- Upstream codex hook surface request (parallel track)
- Other Meadows analyses for other validate-everything components (Phase 2 REFINE will apply Meadows to each component)
