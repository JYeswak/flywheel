# flywheel-h17x Blocked Evidence

Task: `flywheel-h17x-51c433`

## Blocker

Axiom 23 should remain deferred. The B6 data gate has not met the bead's
requirement for 7 days of leverage-ceiling probe data.

## Commands Run

```bash
br show flywheel-h17x
br dep tree flywheel-h17x
jq -s '{rows:length, successful:map(select(.success==true))|length, first_ts:(map(.ts)|min), last_ts:(map(.ts)|max), distinct_days:([.[].ts[0:10]]|unique), distinct_day_count:([.[].ts[0:10]]|unique|length), score_avg:(map(.leverage_ceiling_score // empty) | add / length), binding_counts:(group_by(.binding_constraint // "unknown") | map({constraint:.[0].binding_constraint, count:length}))}' /Users/josh/.local/state/flywheel/leverage-ceiling.jsonl
bash /Users/josh/Developer/flywheel/.flywheel/scripts/leverage-ceiling-probe.sh --json
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-h17x-51c433.md
```

## Results

- `br show`: `flywheel-h17x` remains open.
- Dependency `flywheel-hsx5`: closed.
- Leverage ledger rows: 24 successful rows.
- Distinct leverage data days: 3 (`2026-05-03`, `2026-05-04`, `2026-05-07`).
- Live leverage score: 235/1000.
- Live binding constraint: machines.
- Live probe stderr: `WARN: leverage-ceiling ledger append failed`.
- Dispatch packet audit: pass.

## Follow-Up

Filed `flywheel-xy71r` for the leverage-ceiling ledger append failure. This is
the concrete blocker preventing the 7-day evidence runway from accreting.

## L112 Probe

```bash
jq -s '([.[].ts[0:10]] | unique | length) < 7' /Users/josh/.local/state/flywheel/leverage-ceiling.jsonl
```

Expected: `jq:true`
