# The Zest Sorter

The Zest Sorter ranks unresolved wire-or-explain ledger rows without mutating the
ledger. Its invariant is: every active `unwired` or `questionably_wired` row is
kept in the backlog and routed by deterministic priority.

## Quick Start

```bash
tmp="$(mktemp -d)"
.flywheel/scripts/wire-or-explain-ranker.py rank --ledger tests/fixtures/wire-or-explain-ranker/ledger.jsonl --now 2026-05-05T00:00:00Z --json > "$tmp/sorter.json"
jq -e '.summary.unresolved_count == 7' "$tmp/sorter.json"
jq -e '.top.oldest[0].identity_key == "oldest-row"' "$tmp/sorter.json"
```

Expected result: both `jq` probes exit 0. The output includes the full
unresolved list and four top-N slices.

## Ranking Contract

The sorter does not decide whether a row is wired. It consumes ledger rows after
The Zest Pour has classified stock. It ranks only:

- `unwired`
- `questionably_wired`

It keeps `br ready --json` as optional context. A Beads outage cannot erase or
reorder the wire-or-explain backlog.

## Canonical CLI Matrix

| Verb | Flag | Description | Exit code |
|---|---|---|---|
| global | `--help` | Print argparse help. | 0 |
| global | `--info` | Emit ranker name, schema version, class weights, and notes. | 0 |
| global | `--json` | Accepted for global and subcommand output. Output is JSON either way. | 0 |
| default / `rank` | `--ledger PATH` | Required ledger JSONL. | 0, 1 on ledger errors, 2 if omitted |
| `rank` | `--top N` | Number of rows in each top slice. Defaults to 5. | 0 |
| `rank` | `--now ISO8601` | Evaluation time for age scoring. | 0 |
| `rank` | `--br-ready PATH` | Optional Beads ready JSON context. Missing file is non-fatal. | 0 |
| `rank` | `--local-session NAME` | Local session name for locality scoring. Defaults to `flywheel`. | 0 |
| `rank` | `--local-repo PATH` | Local repo path for locality scoring. Defaults to `/Users/josh/Developer/flywheel`. | 0 |
| `rank` | `--json` | Accepted for command output. | 0 |
| `doctor` | rank flags plus `--stale-hours N` | Fail if ledger is stale or unreadable; include top actions. | 0 or 1 |
| `health` | doctor flags | Same probes as doctor, but status is `healthy` or `degraded`. | 0 or 1 |
| `why` | `IDENTITY_KEY --ledger PATH` | Show one unresolved row by identity. | 0 or 1 |
| `schema` | `--json` | Emit output schema summary. | 0 |
| `quickstart` | `--json` | Emit quickstart commands. | 0 |
| `validate` | `--ledger PATH --json` | Verify ledger readability and rank identity availability. | 0, 1, or 2 |
| `audit` | `--ledger PATH --limit N --json` | Emit recent redacted ranking row summaries. | 0, 1, or 2 |
| `repair` | `--ledger PATH --dry-run --json` | Emit a top-action route plan; `--apply` requires `--idempotency-key` and does not mutate the ledger. | 0, 1, 2, or 4 |
| `completion` | `bash` or `zsh` | Emit shell completion text. | 0 |
| `help` | `TOPIC --json` | Emit topic and command list. | 0 |

Current boundary: the sorter is a pure reader. `validate` checks rankability,
`audit` summarizes recent rows, and `repair` emits route plans for the top
unresolved rows while leaving ledger mutation to downstream consumers.

## State And Slice Examples

| Output state or slice | Example condition | Expected output |
|---|---|---|
| `status=pass` | Ledger exists and parses. | `summary.total_rows` and `summary.unresolved_count` are present. |
| `status=error` | Ledger is missing, empty, invalid JSONL, or stale under doctor threshold. | `reason_code=ledger_missing`, `ledger_empty`, `ledger_parse_failed`, or `ledger_stale`. |
| `health=healthy` | Doctor has no ledger errors or staleness errors. | `command=health`, `status=healthy`. |
| `health=degraded` | Doctor reports ledger errors or staleness. | `command=health`, `status=degraded`. |
| `unwired` | Source row state is `unwired`. | Included in `unresolved`; state weight is 80. |
| `questionably_wired` | Source row state is `questionably_wired`. | Included in `unresolved`; state weight is 35. |
| `top.oldest` | Highest age, then score. | Fixture expects `oldest-row` first. |
| `top.downstream_cost` | Highest downstream cost, dependency count, ship cost, then age. | Cost-heavy row rises even if newer. |
| `top.blocking_scope` | Highest blocking-scope score, rank bucket, then score. | Fleet/tick/mission rows surface early. |
| `top.actionability` | Rows with auto-fire trigger, consumer, and verification probe. | Actionable rows outrank owner-triage rows. |

Concrete probe:

```bash
tmp="$(mktemp -d)"
.flywheel/scripts/wire-or-explain-ranker.py doctor --ledger tests/fixtures/wire-or-explain-ranker/ledger.jsonl --now 2026-05-05T00:00:00Z --stale-hours 999999 --json > "$tmp/sorter-doctor.json"
jq -e '.status == "pass" and .unresolved_count == 7' "$tmp/sorter-doctor.json"
```

## Failure Modes

| Failure | Output | Recovery |
|---|---|---|
| Ledger path missing | `reason_code=ledger_missing`, exit 1 | Pass the correct ledger path or restore the ledger. |
| Ledger is empty | `reason_code=ledger_empty`, exit 1 | Bootstrap with The Zest Ledger writer or defer until first row exists. |
| Ledger has invalid JSONL | `reason_code=ledger_parse_failed`, exit 1 | Fix or rebuild the ledger from trusted receipts. |
| Ledger row is not an object | `reason_code=ledger_row_not_object`, exit 1 | Remove or repair malformed row. |
| Ledger read fails | `reason_code=ledger_read_failed`, exit 1 | Check permissions and path. |
| Doctor stale threshold breached | `reason_code=ledger_stale`, exit 1 | Run the detector/writer pipeline or justify the paused ledger. |
| Optional Beads ready context missing | `br_ready_context.status=missing`, exit 0 | Continue; Beads context is advisory only. |

## Anti-Patterns

| Do not | Why it is wrong | Do this instead |
|---|---|---|
| Drop `questionably_wired` rows from the backlog. | Weak proof is exactly the stock the system must drain. | Rank them with lower state weight, but keep them visible. |
| Treat Beads ready output as required. | A Beads outage would hide wire-or-explain debt. | Keep Beads data optional context. |
| Sort only by age. | Old low-impact rows can starve fleet blockers. | Use rank bucket, score, downstream cost, and actionability. |
| Mutate the ledger from the ranker. | Ranking must be a pure read. | Emit route actions and let consumers write receipts. |
| Hide stale-ledger errors behind `status=pass`. | Staleness is a stock/flow delay signal. | Let doctor fail with `ledger_stale`. |

## Doctor, Health, And Repair Expectations

`doctor --json` must read the ledger, detect stale ledgers, and return top
actions for unresolved rows. Any unreadable, empty, parse-failed, or stale ledger
is an error.

`health --json` maps doctor output into `healthy` or `degraded`. Healthy means
the sorter can read and rank the stock; it does not mean the backlog is empty.

`repair --dry-run --json` does not mutate the ledger. It proposes safe next
actions such as "route to consumer", "create repair bead", or "send skill
candidate to skillos." Apply mode requires an idempotency key and still emits a
route-plan receipt rather than editing ledger rows.

`flywheel-loop doctor --scope wire-or-explain` consumes sorter output as a
prioritized action list. The sorter participates in halt-on-breach by making
unresolved and stale stock visible rather than letting it disappear into raw
ledger order.

## Halt Behavior

Halt or degrade when:

- The ledger is missing, empty, unreadable, or invalid.
- The ledger is stale beyond the configured threshold.
- A top action has no owner, no consumer, and no deferral.
- Fleet-scoped unresolved rows are present and no drain receipt exists.

The stock is "ranked unresolved rows"; the outflow is a routed action that
produces a consumer receipt, a repair bead, or an explicit deferral.

Part of the Yuzu Method framework by ZestStream.
