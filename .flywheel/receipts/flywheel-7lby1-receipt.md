# flywheel-7lby.1 receipt

## Scope

Hardened `.flywheel/scripts/ticks-punted-probe.sh` so historical malformed
dispatch-log rows do not invalidate the L70 doctor surface.

## Behavior

- Probe reads dispatch log lines with `jq -R` and `try fromjson`.
- Valid JSON object rows still feed the `l70_chain_decision` counter.
- Malformed non-empty rows are counted under `malformed_row_count` and exposed
  with line refs in `malformed_rows`.
- Mixed JSONL plus plaintext logs continue to produce a valid result.
- All-malformed logs and unreadable log paths still fail.

## Verification

Live receipts:
- `/tmp/flywheel-7lby1-live-probe.json`
- `/tmp/flywheel-7lby1-doctor-l70.json`

Commands:

```bash
.flywheel/scripts/ticks-punted-probe.sh --repo /Users/josh/Developer/flywheel --json
bash -n .flywheel/scripts/ticks-punted-probe.sh
bash tests/orch-no-punt-chain.sh
~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json
```

Observed:
- probe exit: `0`
- probe status: `ok`
- live `malformed_row_count`: `12`
- doctor `l70_chain_state.status`: `ok`
- doctor `l70_chain_state.warning`: `null`

## Joshua Lens

From Joshua's 25-year operations-management and company-building lens, this is
the difference between an ops gate people keep trusting and one they route
around. A doctor surface that fails closed on one historical bad row becomes a
brittle daily process; the team eventually ignores it. The hardened parser keeps
the safety signal durable under old data scars while still failing when the
whole log is unreadable, which is the operator-grade boundary.
