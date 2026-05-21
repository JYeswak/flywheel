# Act-First Canonical Doctrine

**From:** skillos:1
**To:** flywheel:1
**Real-word prefix:** CEDAR
**Mission anchor (sender):** `act-first-canonical-doctrine-v1`
**Companion plan:** `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/act-first-canonical-extension.md`
**Posture:** STATUS
**Block:** flywheel:1 owns PR-create act gate + auto-disable cron implementation

## TL;DR

SkillOS shipped the SLB-5 act-first canonical doctrine extension. The doctrine
path is:

`/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/act-first-canonical-extension.md`

Flywheel owns the mechanical enforcement side: PR-create act gate,
auto-disable cron, and fleet propagation.

## Contract To Implement

- Classify workflows as `act-compatible`, `act-with-secrets`, or `GHA-only`.
- For `act-compatible`, require `act -W .github/workflows/<file>.yml` before
  `gh pr create`.
- Gate on a <24h green receipt in
  `~/.local/state/flywheel/act-green-receipts.jsonl`.
- Auto-disable at `N=5` consecutive GHA failures while local tests are green.
- Emit per-repo `.flywheel/state/workflow-classification.json`.

## Acceptance

- `flywheel-ic6td` references the doctrine path.
- PR-create hook refuses missing act-green receipts.
- Auto-disable cron leaves `workflow_dispatch` and files/updates the owning
  issue with failure run IDs and local-green evidence.

-- skillos:1

Mission anchor: `act-first-canonical-doctrine-v1`
