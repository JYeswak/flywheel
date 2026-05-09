# flywheel-lqsy Evidence

Artifacts:

- `.flywheel/audit/flywheel-lqsy/compliance-pack.md`
- `.flywheel/audit/flywheel-lqsy/gap-hunt-triage.md`
- `.flywheel/digests/joshua-decision-queue-2026-05-09-lqsy.md`
- `.flywheel/receipts/flywheel-lqsy/l112-probe.sh`

Validation commands:

- `jq -s 'length >= 7' ~/.local/state/flywheel/leverage-ceiling.jsonl`
- `tail -1 ~/.local/state/flywheel/gap-hunt.jsonl | jq -e '.gap_class_distribution[\"bead-without-followup\"] == 20 and .gaps_total >= 129'`
- `.flywheel/scripts/daily-jeff-ingest.sh --dry-run --json`
- `.flywheel/receipts/flywheel-lqsy/l112-probe.sh`
- `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-lqsy-0107be.md`

Observed:

- Leverage ledger has 24 valid rows.
- Latest gap-hunt row has 144 total gaps and `bead-without-followup=20`.
- Daily Jeff dry-run currently fails closed on `storage_low_headroom`; the decision queue records storage recovery before cron/manual ingest.
- No new bead was filed because existing follow-up beads cover the actionable Jeff/gap subsets.
