# 00-INTENT — ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07

## Verbatim topic

> ok - now this is the bead list I want us working on right now. /flywheel:plan this and work through entire list today

Bead list source: `/Users/josh/Developer/flywheel/.flywheel/NTM-SURFACE-INVENTORY.md` (v3, classified USE=86 / ISSUE=8 / WRAP=8 / EXCLUDED=6 with companion script tally).

## Hard rule (Joshua-locked 2026-05-07)

> "if ntm has it we use it - if ntm doesn't have it and its worthy of an issue - we submit it - if ntm doesn't have it and its not worthy of an issue, we wrap it."

No competing implementations. Every flywheel script that hand-rolls something ntm provides natively must be **rewritten as a thin caller** or **deleted outright**. The 8 W0–W3b wrappers shipped today (W0A caam-rotate, W1Q quota threshold, W1M metrics-doctor mapping, W1S serve-redacted, W2P L91 four-state, W2D DCG-sibling, W2A approve-exact-question, W3bA canonical-writer-audit, W3bP privilege-block, W3bR dirty-worktree-guard) are legitimate WRAP because they encode flywheel-specific evidence/doctrine layers (L91 4-state receipt, hash-chain canonical-writer, L85 idle-state taxonomy) over native ntm primitives.

## Mission anchor

continuous-orchestrator-uptime-self-sustaining-fleet — Joshua grows outside the founder; the flywheel must keep dispatching while Joshua sleeps/works/travels.

## Backlog target

~38 beads:
- ~30 Category-1 rewrites (DELETE-OR-REWRITE-AS-CALLER): scripts that hand-roll ntm-native functionality
- 8 ISSUE research beads: confirm-or-file Jeff issues for `lock`/`locks`/`unlock` (vs MCP Agent Mail), `redact`/`scrub` coverage gap, `review-queue` (L85 taxonomy gap), `work` vs `assign` duplication, `worktree`/`worktrees` (vs `prd` skill)

## Tier-1 highest-LOC-delete (first wave priorities)

- `idle-pane-auto-dispatch.sh` (699 LOC) → `ntm assign --watch` + `ntm wait` (BLOCKED on ntm#124 closure for `--watch`; safe to use `ntm wait` synchronously)
- `peer-orch-freeze-monitor.sh` (772 LOC) → `ntm doctor` + `ntm watch`
- `peer-orch-productivity-watch.sh` (621 LOC) → `ntm coordinator digest` (already wired in tick Step 1b; this script is now redundant)
- `worker-auto-respawn-watchdog.sh` (451 LOC) → `ntm doctor --auto-respawn` patterns + frozen-pane-detector wrap
- `halt-disease-watchdog.sh` (317 LOC) → `ntm history` + `ntm grep` for stuck-pattern detection
- `worker-stall-alert-probe.sh` (370 LOC) → `ntm interrupt` + `ntm wait`
- `continuous-productivity-detector.sh` (294 LOC) → `ntm coordinator digest`
- `recovery-escape-then-reprompt.sh` (200 LOC) → `ntm interrupt` then `ntm send`
- `verify-callback-delivery.sh` (183 LOC) → `ntm history` + `ntm grep`
- `recency-weighted-two-truth-classifier.sh` (220 LOC) → `ntm --robot-activity` (canonical worker-state surface)

Estimated total LOC removed: ~5,000.

## Constraints

- Today's session has ~3h orchestrator runway. Bead DAG must fit 3 panes × ~5 beads = 15 parallel-shippable beads in first wave, serialized by dependency on ntm subcommand availability.
- Pipeline compressed per Joshua: inventory IS converged research+refine → skip Phase 1, run lightweight Phase 2 confirmation if needed → straight to Phase 3 audit + Phase 4 decompose.
- Quality bar: every bead names exactly which flywheel script it rewrites/deletes, which ntm surface it delegates to, expected LOC delta, and acceptance test (script still passes existing tests after rewrite).
- ntm#124 (`assign --watch` over-dispatch) is OPEN upstream. Beads touching `--watch` mode must include the wait-for-#124-fix gate; synchronous `ntm assign --auto` and `ntm wait` are fine to use immediately.

## Out of scope

- Gap beads from prior wave: flywheel-rmwgg (jq-fix CLOSED), flywheel-f12e6 (audit-remediation IN FLIGHT pane 4) — already counted in earlier plan.
- Net-new ntm features (filing those becomes ISSUE research beads, but proposing them is not).
