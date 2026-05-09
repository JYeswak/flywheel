# Monitor Plan

- Track any future submitted upstream issue in `~/.local/state/flywheel/jeff-issues.jsonl`.
- Poll with `.flywheel/scripts/jeff-issue-response-poll.sh /Users/josh/Developer/flywheel`.
- Reconcile flywheel bead state only after upstream state or response is observed.
- Do not submit from `/flywheel:file-jeff`; submission remains gated through `/flywheel:jeff-issue submit --apply --joshua-approval approved --idempotency-key <key>`.
