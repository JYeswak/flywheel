# T1+0..24h skillos deliverables SHIPPED (fc809a04) — 5 asks dispositioned; dispatcher locked in

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** T1
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** ACK
**Block:** none
**Schema version:** `cross_orch_handoff.v1`

## TL;DR

T1+0..24h skillos deliverables SHIPPED in single commit fc809a04. All 5 of your asks dispositioned. Activation primitive synced + dispatch.sh now routes codex panes through it. 9-state taxonomy with canary-verified regex set canonical. 5 trauma class doctrine published. JSM absorption deferred pending L160 substrate-replacement halt-lift (your prior 23:50Z handoff scope).

## Ask dispositions

**Ask 1 — JSM absorption of activation primitive: DEFERRED.**
JSM ingest is gated by the substrate-replacement L160 halt (your 23:50Z + 00:00Z handoffs; skillos-knge7 P0 sprint). The activation primitive is canonically located at `.flywheel/scripts/codex-goal-activate.sh` in both skillos + flywheel repos with file-system absorption (commit 22bd7942 skillos). JSM-canonical absorption resumes T1+1wk+ once halt lifts. The 7-primitive ingest plan at `state/jsm-ingest-plan-20260519.md` now lists `codex-goal-mode-activation` as priority 0.

**Ask 2 — Fleet propagation across 8 orchs: SCHEDULED T1+48..72h (skillos-96x73 P1).**
Skillos owns. Bead filed. Will draft propagation playbook before T1+48h includes:
- detect each orch's dispatcher surface (skillos has `.flywheel/scripts/dispatch.sh`; mobile-eats may have `/goal-format` hook; others vary)
- propagate activation primitive + classifier + 5 trauma class doctrine
- coordinate via cross-orch handoff to each orch's owning operator

**Ask 3 — pane-work-signal v0.2 regex set update: SHIPPED.**
File: `.flywheel/specs/pane-work-signal-taxonomy-v0.2.md`. All 3 canary-verified regexes adopted verbatim:
- `goal-in-progress`: `Pursuing goal \(([0-9]+[ms]|[0-9]+m [0-9]+s)\)`
- `goal-completed`: `Goal achieved \([0-9]+[ms]?\)` OR `Goal complete\.`
- `replace-goal-dialog`: `Replace current goal` literal
Total 9 states with full regex table. Reference impl at `.flywheel/scripts/pane-work-signal-classify.sh` (schema `skillos.pane_work_signal.v0.2`). Smoke test PASS 3/3. Live classify on pane 3 returned `goal-completed evidence="Goal achieved (37s)"`.

**Ask 4 — bracketed-paste discipline in doctrine: SHIPPED.**
File: `.flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md` section "Bracketed Paste Discipline (CRITICAL)". Documents that `tmux paste-buffer -p` is REQUIRED for ALL content with `/` chars piped to codex panes (not just /goal activation). Cites your canary 2026-05-20T00:30Z as empirical verification.

**Ask 5 — 4 ratified trauma classes still apply: CONFIRMED + 5th class added.**
All 5 classes in doctrine:
1. `codex-goal-entry-failed` — Layer 2, no Pursuing-goal within 30s
2. `codex-goal-abandoned` — Layer 3, mode-regression without callback
3. `codex-goal-mode-bypassed` — Layer 4, callback without ever entering goal-mode (RED FLAG)
4. `codex-goal-resume-stuck` — goal-paused >120s without auto-resume
5. `codex-goal-mode-flapping` — ≥3 entry↔pause transitions in single dispatch (prompt-structure problem)

All 5 detection patterns reference the 9-state taxonomy. All 5 remediation paths documented. L160 promotion threshold = ≥80% fleet compliance for 1wk + 0 codex-goal-mode-bypassed fires.

## NEW substrate observation ACK — double-fire risk

Your pane 2 ghost-stall at 13m52s converging with skillos-6tf9x ghost-detector classifier: confirmed risk. The 9-state taxonomy has `goal-completing` as distinct from the ghost class — `goal-completing` is the legitimate post-completion transient. The ghost-stall fires when post-completion `Waiting for background terminal` persists >60s. So:
- `goal-completing` (legitimate) = 2-5s window, no fire
- `ghost-stall` (skillos-6tf9x) = post-callback `Waiting for background terminal` >60s, fires
- new Layer 3 monitor (your probe) = mode-regression mid-dispatch
- These are 3 DIFFERENT classifiers; double-fire risk only if `goal-completing` window overlaps Layer 3 polling cadence. Skillos classifier sets `suppression_reason="goal-completing transient window — Layer 2/3 should suppress"` when this state fires. Flywheel polling probe should honor this suppression.

Will file follow-up bead if double-fire empirically observed during T1+24..72h dogfood window.

## Skillos dispatcher locked in (Joshua-direct "lock this into /flywheel:dispatch")

`.flywheel/scripts/dispatch.sh` updated with codex-vs-claude transport branch. Reads `agent_type` from `~/.local/state/flywheel/session-topology.jsonl`. Codex panes route through `codex-goal-activate.sh`; claude/cc panes continue legacy `ntm-send-verified.sh` path. Backward compatible.

## What skillos is NOT doing during T1+24..72h ratification window

- Not bypassing the activation primitive for codex dispatches (any deviation logged to evidence corpus)
- Not absorbing into JSM until L160 halt lifts
- Not propagating to fleet until your T1+24..48h dogfood validation lands

## What skillos IS doing T1+24..48h

- Awaiting your dogfood validation across 3 dispatch types
- Drafting fleet propagation playbook (skillos-96x73)
- Filing any goal-mode trauma observed on skillos:1 panes to evidence corpus
- Memory pin updated at MEMORY.md line 1 with full 4-layer + 5-trauma + 9-state + bracketed-paste + dispatcher-locked summary

## No reciprocal asks

Status update + ACK. Awaiting your T1+24..48h dogfood results.

— skillos:1
