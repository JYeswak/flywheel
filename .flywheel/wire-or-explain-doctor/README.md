# Peel Report Doctor Extension

The Peel Report doctor extension is the `.wire_or_explain` block exposed by
`flywheel-loop doctor`. Its invariant is: every Zest Ledger row that remains
unwired, questionable, overdue, or unrelayed is visible through one canonical
doctor surface with producer, measurement, consumer, and promotion metadata.

Use this README when you need the operator contract for the doctor view. The
ledger, classifier, detector, and ranker READMEs describe their own surfaces;
this file describes the final health signal that loops and workers read.

## Quick Start

```bash
repo="/Users/josh/Developer/flywheel"
flywheel-loop doctor --repo "$repo" --scope wire-or-explain --json > /tmp/peel-report.json
jq '.status, .unresolved_count, .top_actions' /tmp/peel-report.json
flywheel-loop doctor --repo "$repo" --json | jq '.wire_or_explain'
```

Expected result: the scoped command returns only the Peel Report block. The full
doctor command embeds the same block at `.wire_or_explain`.

## What It Measures

The Peel Report doctor extension reads the Zest Ledger and optional skillos
relay ledger, then emits a bounded operator summary.

| Flow piece | Surface |
|---|---|
| Stock | Active Zest Ledger rows with `state=unwired` or `state=questionably_wired`. |
| Inflow | Ledger writer, classifier, detector, worker, doctrine, and skill-candidate rows. |
| Measurement | `flywheel-loop doctor --scope wire-or-explain --json`. |
| Consumer | Full `flywheel-loop doctor --json`, worker callbacks, and `doctor-signal-bead-promotion.sh`. |
| Outflow | Consumer receipt, skillos relay receipt, explicit deferral, not-required proof, or auto-created repair bead. |

The block intentionally omits raw `payload` and `metadata` from ranked actions.
Operators get enough context to route the row without copying durable evidence
bodies or accidental secret-shaped text.

## Canonical CLI Matrix

| Verb | Flag | Description | Exit code |
|---|---|---|---|
| `doctor` | `--repo PATH` | Resolve repo-local mode and report against the requested flywheel repo. | 0, or inherited doctor failure |
| `doctor` | `--scope wire-or-explain` | Emit only the Peel Report doctor extension. | 0 unless `.status == "error"` |
| `doctor` | `--scope wire-or-explain validate --json` | Validate the field-specific Peel Report packet shape. | 0 when the packet satisfies the scoped schema |
| `doctor` | `--scope wire-or-explain audit --json` | Report scoped mutation ledgers, consumers, counts, and top actions without raw row payloads. | 0 when the doctor packet is valid JSON |
| `doctor` | `--scope wire-or-explain why FIELD --json` | Explain producer, measurement, and consumer for a Peel Report field. | 0 for registered fields |
| `doctor` | `--scope wire-or-explain schema --json` | Emit the field-specific `wire-or-explain-doctor/v1` schema contract. | 0 |
| `doctor` | `--json` | Emit machine-readable JSON. Required for downstream consumers. | 0 or 1 |
| `doctor` | no `--json` with scope | Emit a compact text summary: status, mode, unresolved, overdue, and skill backlog. | 0 or 1 |
| `doctor` | global `--no-color` | Accepted through `flywheel-loop` global output controls. | 0 or 1 |
| `doctor` | global `--no-emoji` | Accepted through `flywheel-loop` global output controls. | 0 or 1 |
| `doctor` | global `--width N` | Accepted through `flywheel-loop` global output controls. | 0 or 1 |
| `completion` | `bash` or `zsh` | Includes `--scope`, `wire-or-explain`, `validate`, `audit`, `why`, and `schema` candidates. | 0 |
| `schema` | top-level `schema` | Emits generic `flywheel-loop` schemas; use the scoped doctor schema for Peel Report fields. | 0 |
| `help` | `doctor --json` | Emits the parent doctor help topic; scoped field rationale lives under `doctor --scope wire-or-explain why FIELD --json`. | 0 |
| `health` | no direct scope | Reads full doctor state indirectly; it does not currently expose a separate wire-or-explain health slice. | 0 or degraded |
| `repair` | no direct scope | Repair is routed by `doctor-signal-bead-promotion.sh`, not by a mutating doctor subcommand. | 0 for dry-run repair planner |

Cluster D F01 closeout: scoped `validate`, `audit`, `why`, `schema`, and
completion entries for `wire-or-explain` are field-specific. `health` remains a
full-doctor read and `repair` remains routed through the promotion script.

## Output Shape

The block uses schema version `wire-or-explain-doctor/v1`.

| Field | Meaning | Example |
|---|---|---|
| `counts_by_state` | Ledger row counts grouped by `state`. | `{"unwired":1,"questionably_wired":1}` |
| `unresolved_count` | Count of `unwired` plus `questionably_wired` rows. | `2` |
| `overdue_count` | Local unresolved rows past age threshold or past `deferral_until`. | `1` |
| `questionably_wired_count` | Weak-proof rows that still need a stronger consumer proof. | `1` |
| `skill_candidate_backlog_count` | Unresolved rows with `artifact_class=skill_candidate`. | `1` |
| `skill_candidate_unrelayed_count` | Skill candidates not marked sent, relayed, or delivered. | `1` |
| `skill_candidate_relay_failure_count` | Skill candidate relay failures in row or relay ledger state. | `1` |
| `last_relay_ts` | Latest successful skillos relay timestamp, or `null`. | `"2026-05-05T00:10:00Z"` |
| `top_actions` | Up to five redacted ranked rows to drain next. | `[{"identity_key":"row-1","route":{"action":"drain_consumer"}}]` |
| `actions` | Doctor action records with producer, measurement, consumer, status, and next action. | `[{"kind":"wire_or_explain_unresolved","status":"warn"}]` |
| `signals` | Machine-readable producer, measurement, and consumer metadata per signal. | `{"unresolved_count":{"producer":"The Zest Ledger"}}` |
| `auto_bead_promotion_trigger` | Whether this state should be promoted by the doctor signal script. | `{"enabled":true,"script":".flywheel/scripts/doctor-signal-bead-promotion.sh"}` |
| `promotion_metadata` | Extra bead title/root-cause metadata when promotion is enabled. | `{"root_cause":"flywheel-2eow","overdue_count":1}` |

## State Examples

### Passing or low-risk backlog

```json
{
  "status": "warn",
  "mode": "shadow",
  "counts_by_state": {
    "unwired": 1,
    "questionably_wired": 1
  },
  "unresolved_count": 2,
  "overdue_count": 0,
  "questionably_wired_count": 1,
  "auto_bead_promotion_trigger": {
    "enabled": false
  }
}
```

This means backlog exists but no local row has breached the promotion threshold.
Workers should drain or explicitly defer the `top_actions` rows.

### Overdue local blocker

```json
{
  "status": "error",
  "overdue_count": 1,
  "promotion_metadata": {
    "root_cause": "flywheel-2eow",
    "unresolved_count": 1,
    "overdue_count": 1,
    "promotion_script": ".flywheel/scripts/doctor-signal-bead-promotion.sh"
  },
  "auto_bead_promotion_trigger": {
    "enabled": true,
    "threshold": "overdue_count>0 OR skill_candidate_relay_failure_count>0 OR missing ledger in enforce mode"
  }
}
```

This is a halt-class signal for tick close. The next consumer is bead promotion
or direct drain of the unresolved row.

### Skill candidate relay success, wired through skillos

```json
{
  "skill_candidate_backlog_count": 1,
  "skill_candidate_unrelayed_count": 0,
  "skill_candidate_relay_failure_count": 0,
  "last_relay_ts": "2026-05-05T00:10:00Z",
  "actions": [
    {
      "kind": "skill_relay",
      "status": "pass",
      "consumer": "skillos relay"
    }
  ]
}
```

This says the skill-candidate stock is wired through a skillos route receipt. It
can still remain visible as backlog until a downstream closure receipt updates
the row.

### Skill candidate relay failure, unwired with skillos action metadata

```json
{
  "status": "error",
  "skill_candidate_backlog_count": 1,
  "skill_candidate_relay_failure_count": 1,
  "actions": [
    {
      "kind": "skill_relay",
      "status": "error",
      "next_action": "route_skill_candidate_rows_to_skillos_or_record_deferral"
    }
  ],
  "auto_bead_promotion_trigger": {
    "enabled": true
  }
}
```

This means skill-shaped findings are still unwired and accumulating without a
working skillos outflow. Treat the `next_action` as the skillos routing action,
not as optional prose.

### Redacted top action

```json
{
  "top_actions": [
    {
      "identity_key": "fixture-secret-redaction",
      "state": "unwired",
      "artifact_class": "finding",
      "subject": "secret-redaction-check",
      "consumer": "flywheel:1",
      "producer": "worker",
      "measurement": "bash tests/wire-or-explain-doctor.sh"
    }
  ]
}
```

The action does not include `payload`, `metadata`, raw payload excerpts, token
values, or other evidence bodies. Route by identity, consumer, and probe.

## Failure Modes

| Failure mode | Doctor shape | Exit behavior | Recovery |
|---|---|---|---|
| Missing ledger in `bootstrap` mode | `status=warn`, `reason_code=ledger_missing`, empty counts | 0 | Continue bootstrap, but create the ledger before enforce mode. |
| Missing ledger in `shadow` mode | `status=warn`, `reason_code=ledger_missing`, empty counts | 0 | Treat as degraded visibility; run ledger writer or explain why stock is intentionally absent. |
| Missing ledger in `enforce` mode | `status=error`, `reason_code=ledger_missing`, promotion enabled | nonzero | Restore or create the ledger, or let the promotion script file a repair bead. |
| Empty ledger in `enforce` mode | `status=error`, `reason_code=ledger_empty`, promotion enabled | nonzero | Bootstrap rows or record an explicit no-stock receipt. |
| Invalid JSONL | `status=error`, `reason_code=ledger_parse_failed` | nonzero | Repair or rebuild the ledger from trusted receipts. |
| Overdue blocker | `status=error`, `overdue_count>0`, `promotion_metadata` present | nonzero | Drain the row, defer with owner and date, or promote to an auto-doctor bead. |
| Skill relay success | `skill_relay.status=pass`, relay counts non-failing | 0 unless other rows fail | Continue downstream closure; no promotion needed for relay itself. |
| Skill relay failure | `skill_candidate_relay_failure_count>0`, `skill_relay.status=error` | nonzero | Send to skillos, repair relay receipts, or create a repair bead. |
| Secret-redaction guard | `top_actions` omit `payload` and `metadata` | 0 or 1 based on status | Never paste raw evidence into docs or callbacks; use row identity and probe. |

## Doctor, Health, And Repair Expectations

The doctor extension is the canonical status surface for wire-or-explain stock.
Do not build a parallel status source from raw grep output or a second ad hoc
ledger parser.

`flywheel-loop doctor --scope wire-or-explain --json` must:

- Read the Zest Ledger and optional skillos relay ledger.
- Emit counts, ranked actions, relay metrics, and signal metadata.
- Return nonzero when `.status == "error"`.
- Preserve redaction by excluding raw row payload and metadata from actions.

`flywheel-loop doctor --json` must embed the same payload at `.wire_or_explain`
and promote the full doctor status to fail when the block is error. That makes
the full doctor the consumer for tick close and worker callbacks.

`flywheel-loop health` is lighter than doctor and does not currently expose a
field-specific wire-or-explain scope. If health is green but this doctor block is
warn or error, the doctor block wins for this substrate.

Repair is not performed by the doctor command. The repair expectation is:

1. Doctor emits `auto_bead_promotion_trigger.enabled=true`.
2. `doctor-signal-bead-promotion.sh` reads `.wire_or_explain`.
3. The script creates or matches an `[auto-doctor:wire_or_explain]` bead.
4. The bead owns the drain, deferral, relay repair, or ledger repair action.

## Halt-On-Breach Behavior

Mode is resolved from `FLYWHEEL_WIRE_OR_EXPLAIN_MODE`, then from
`.flywheel/wire-or-explain/mode`, then defaults to `shadow`.

| Mode | Missing ledger | Unresolved not overdue | Overdue or relay failure | Intended use |
|---|---|---|---|---|
| `bootstrap` | warn, exit 0 | warn, exit 0 | error, nonzero | First install before stock exists. |
| `shadow` | warn, exit 0 | warn, exit 0 | error, nonzero | Observe without failing missing-ledger bootstrap gaps. |
| `enforce` | error, nonzero | warn, exit 0 | error, nonzero | Gate close when the ledger is expected to exist. |

The halt is deliberate. The stock is "unresolved wire-or-explain obligations";
the outflow must be a consumer receipt, skillos relay receipt, explicit deferral,
not-required proof, bypass receipt, or repair bead. A prose explanation alone is
not a drain.

## Anti-Patterns

| Do not | Why it is wrong | Do this instead |
|---|---|---|
| Read `.wire_or_explain` through a parallel status source. | Parallel surfaces drift from the doctor consumer. | Use `flywheel-loop doctor --scope wire-or-explain --json`. |
| Treat `warn` as "ignore." | Warn means stock exists or visibility is degraded. | Drain, defer, or keep it visible in the next tick. |
| Force `enforce` before the first ledger row exists. | Missing bootstrap stock becomes a false hard fail. | Start in bootstrap or shadow, then flip to enforce after stock exists. |
| Count `questionably_wired` as closed. | Weak proof is still unresolved stock. | Add a mechanical probe or downstream receipt. |
| Route skill candidates by prose in a callback. | Skill-candidate stock needs a durable skillos relay receipt. | Send through the relay path and record the receipt. |
| Paste payload or metadata into README examples. | Evidence bodies can contain sensitive or noisy data. | Show identity, route, probe, and redacted action shape only. |
| Let auto-created doctor beads sit unowned. | Promotion is only useful if the bead becomes an outflow. | Assign, drain, close, and leave a closure receipt. |

## Operator Checklist

Before closing work that touches wire-or-explain stock:

1. Run `flywheel-loop doctor --repo "$PWD" --scope wire-or-explain --json`.
2. Confirm `reason_code` is absent or intentionally understood.
3. Confirm every `top_actions[]` row has a consumer, deferral, or repair bead.
4. Confirm skill candidates have relay receipts or explicit deferral.
5. Confirm `auto_bead_promotion_trigger.enabled` is false, or that the promoted
   bead is named in the callback.
6. Run `bash tests/wire-or-explain-doctor.sh` after changing doctor docs or
   behavior.

## Validation

```bash
bash tests/wire-or-explain-doctor.sh
flywheel-loop doctor --repo /Users/josh/Developer/flywheel --scope wire-or-explain --json | jq -e '.schema_version == "wire-or-explain-doctor/v1"'
flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json | jq -e '.wire_or_explain'
```

Part of the Yuzu Method framework by ZestStream.
