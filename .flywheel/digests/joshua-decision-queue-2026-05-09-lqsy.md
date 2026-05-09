# Joshua Decision Queue Update - flywheel-lqsy - 2026-05-09

Purpose: update the flagship follow-up decision queue with live leverage data, B10 gap triage, and Jeff ingest cadence status.

## Recommended Disposal Order

1. **Storage first:** do not manually run daily Jeff ingest while storage is FIRE.
2. **Jeff cron decision:** approve repairing/re-enabling the daily Jeff ingest label after storage free space is back above the configured minimum.
3. **Jeff digest evidence:** after storage recovery, run one manual daily ingest and close `flywheel-1lpv.3` only if it yields either three actionable findings or an explicit no-actionable-signal receipt.
4. **B10 gap triage:** accept the `flywheel-lqsy` triage split and avoid filing duplicate beads for the sampled `bead-without-followup` rows.

## Current Evidence

- Leverage ledger valid rows: 24, which satisfies the `>=7` gate.
- Latest leverage rows still point at `machines` as the common binding constraint, with earlier token-budget warnings.
- Latest gap-hunt row: 144 gaps, not the older 129 in the bead text.
- Latest gap-hunt top classes are capped at 20 each; `bead-without-followup=20`.
- `daily-jeff-ingest.sh --dry-run --json` returns `storage_low_headroom`.
- `jeff-intel-network.sh doctor --json` currently reports failure.
- `launchctl list` shows `ai.zeststream.flywheel-daily-jeff-ingest` present but last status `1`; x-poll and philosophy labels show status `0`.

## Jeff Drafts And Cron Ask

Open Jeff-related work remains:

- `flywheel-1lpv.1`: activate scheduled Jeff ingest sources.
- `flywheel-1lpv.3`: produce actionable first daily digest.
- `flywheel-3p1j`: Jeff issue rubric is closed and remains the outbound quality gate.

Ask for Joshua:

```text
Approve Option A: do not run daily Jeff ingest manually while storage is FIRE; recover disk headroom first, then repair/re-enable ai.zeststream.flywheel-daily-jeff-ingest and run one manual daily digest as proof before trusting the cron.
```

Short form:

```text
Approve Jeff ingest Option A: storage recovery first, then cron repair + one manual proof run.
```

## B10 Triage Ask

Approve the `flywheel-lqsy` B10 split:

- actionable: 64 current live gaps, handled as batched work or existing follow-ups
- doctrine-debt: 50 current live gaps, not urgent one-off work
- noise: 30 current live gaps, no automatic bead filing

No decisions were applied while preparing this digest.
