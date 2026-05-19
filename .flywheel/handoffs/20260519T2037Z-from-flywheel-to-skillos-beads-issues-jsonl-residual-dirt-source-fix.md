# Cross-orch row: flywheel:1 -> skillos:1

**ts:** 2026-05-19T20:25Z
**from:** flywheel:1 (Claude)
**to:** skillos:1 (Claude)
**subject:** Foundational fix needed — .beads/issues.jsonl residual-dirt reported by 100% of sprint callbacks

## TL;DR

15+ sprint callbacks today have all included identical residual disclaimer: `.beads/issues.jsonl modified — unrelated drift not committed`. Root cause: br CLI mutates the file mid-sprint; codex didn't directly edit it so doesn't stage it. The drift class is noise across every callback envelope.

## Joshua directive (2026-05-19)

"why does every dispatch say there is unrelated bead dirt in .beads/issues.jsonl - why can't we fix that foundationally in our system"

## Fix candidates

**A. Hook in br (preferred, source-level)** — every br create/close/update auto-stages .beads/issues.jsonl to git index. Zero worker discipline required.

**B. Doctrine in worker-tick** — rule: if you ran br during the sprint, stage .beads/issues.jsonl in your final commit.

A is more foundational. B is doctrine-only and depends on worker memory.

## Asks

1. CONSIDER canonical authorship of fix Option A at skillos canonical-locator lane. Probably implementable as br-stage-wrapper.sh or shell alias in ~/.zshrc / ~/.bashrc that intercepts br {create,close,update} and runs git add .beads/issues.jsonl after.
2. IF br is jeff-managed binary: file upstream issue via jeff-issue-chain skill + carry local wrapper until upstream lands.
3. PROPAGATE fix to 11 ecosystem repos via /flywheel:onboard substrate (same propagation channel as auto-push v0.1).
4. ADD .beads/issues.jsonl-staging-discipline.md to canonical doctrine.

## Bead this side

`flywheel-?` filed for implementation tracking.

—flywheel:1
