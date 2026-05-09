# flywheel-h17x Compliance Pack

Task: `flywheel-h17x-51c433`

## Decision

Blocked. Do not add Axiom 23 to `CLAUDE.md` yet.

The bead explicitly says the axiom must defer until B6 has at least 7 days of
leverage-ceiling probe data. Current evidence shows only 3 distinct data days,
and the live probe cannot append the current observation to the ledger.

## Evidence

Command:

```bash
jq -s '{rows:length, successful:map(select(.success==true))|length, first_ts:(map(.ts)|min), last_ts:(map(.ts)|max), distinct_days:([.[].ts[0:10]]|unique), distinct_day_count:([.[].ts[0:10]]|unique|length), score_avg:(map(.leverage_ceiling_score // empty) | add / length), binding_counts:(group_by(.binding_constraint // "unknown") | map({constraint:.[0].binding_constraint, count:length}))}' /Users/josh/.local/state/flywheel/leverage-ceiling.jsonl
```

Observed:

```json
{
  "rows": 24,
  "successful": 24,
  "first_ts": "2026-05-03T05:30:31Z",
  "last_ts": "2026-05-07T13:47:47Z",
  "distinct_days": ["2026-05-03", "2026-05-04", "2026-05-07"],
  "distinct_day_count": 3,
  "score_avg": 310.6666666666667,
  "binding_counts": [
    {"constraint": "accounts", "count": 6},
    {"constraint": "machines", "count": 18}
  ]
}
```

Live probe:

```bash
bash /Users/josh/Developer/flywheel/.flywheel/scripts/leverage-ceiling-probe.sh --json
```

Observed:

```json
{
  "success": true,
  "status": "critical",
  "leverage_ceiling_score": 235,
  "binding_constraint": "machines",
  "worker_panes_total": 17,
  "worker_panes_working_count": 4
}
```

Stderr:

```text
WARN: leverage-ceiling ledger append failed path=/Users/josh/.local/state/flywheel/leverage-ceiling.jsonl
```

## Acceptance Mapping

- Add Axiom 23 to `CLAUDE.md`: not done; explicitly blocked by the bead's
  deferral condition.
- B6 dependency closed: yes, `flywheel-hsx5` is closed.
- 7+ days of B6 probe data: no, only 3 distinct days are present.
- Measurement substrate healthy enough to continue collecting data: no, live
  probe emits a ledger append failure.
- Follow-up bead: `flywheel-xy71r` filed for the append failure.

## Four-Lens Self-Grade

- Brand: 8/10. Avoids premature doctrine that would weaken the mental model.
- Sniff: 9/10. The decision follows measured data, not the appealing axiom text.
- Jeff: 8/10. Preserves Beads and measurement-first discipline.
- Public: 8/10. A skeptical operator, maintainer, and future worker can rerun
  the exact ledger and live-probe commands.

Compliance score: 820/1000.

## L112

Probe:

```bash
jq -s '([.[].ts[0:10]] | unique | length) < 7' /Users/josh/.local/state/flywheel/leverage-ceiling.jsonl
```

Expected: `jq:true`
