# A6 Validation: bv Stale Top-Pick Before Filing

## Verdict

`local_input_gap`

The current live `bv` substrate does not prove an upstream `beads_viewer` bug.
The suspected stale top-pick condition did not reproduce as a closed or stale
source recommendation. Current `bv --robot-next` returns an in-progress bead
from the current `.beads` data hash. The stale issue alerts are separate beads,
not the top pick.

## Commands Run

```bash
BV_FORMAT=json bv --robot-insights -format json
BV_FORMAT=json bv --robot-next -format json
BV_FORMAT=json bv --robot-triage -format json
BV_FORMAT=json bv --robot-alerts -format json
BV_FORMAT=json bv --robot-priority -format json
BV_FORMAT=json bv --robot-suggest -format json
br show flywheel-se3h.1 --json
br dep cycles
stat -f 'issues_jsonl_mtime=%Sm issues_jsonl_size=%z' -t '%Y-%m-%dT%H:%M:%S%z' .beads/issues.jsonl
git log -1 --format='last_commit=%H %cI %s' -- .beads/issues.jsonl
wc -l .beads/issues.jsonl
```

Raw outputs are committed under `.flywheel/audit/flywheel-215/`.

## Source/Input Freshness Evidence

- `bv` robot outputs share `data_hash=91de0ea1a646e9f0`.
- `bv --robot-next` generated at `2026-05-09T05:50:38Z`.
- `.beads/issues.jsonl` mtime was `2026-05-08T23:47:35-0600`.
- Last committed `.beads/issues.jsonl` change was
  `182c3fea6ad960228216a3c4faa652894c1be93c` at
  `2026-05-08T23:47:10-06:00`.
- `.beads/issues.jsonl` line count was `1281`.
- `br dep cycles` reported no dependency cycles.

## Current Top Pick

`bv --robot-next` returned:

```json
{
  "id": "flywheel-se3h.1",
  "title": "[session-topology-registry] validate topology ledger schema and fleet bootstrap",
  "score": 0.2009478781990242,
  "unblocks": 1
}
```

`br show flywheel-se3h.1 --json` confirms:

```json
{
  "id": "flywheel-se3h.1",
  "status": "in_progress",
  "priority": 0,
  "updated_at": "2026-05-04T11:41:17.588850Z",
  "closed_at": null
}
```

This may be an ergonomics/policy question for `bv` ranking, but it is not an
upstream stale-read bug on the current evidence. The top pick exists in the
current bead substrate and is not closed.

## Stale Alerts

`bv --robot-alerts` reported two stale issues:

- `flywheel-3bk`: inactive for 8 days, status `in_progress`.
- `flywheel-3ul`: inactive for 8 days, status `in_progress`.

Neither stale alert is the `bv --robot-next` top pick.

## Duplicate Search Decision

No upstream duplicate search was run. The dispatch says duplicate-search only if
upstream filing remains plausible; with the current live data, upstream filing
is not plausible because the alleged stale top-pick defect does not reproduce.

## Recommended Routing

Do not file upstream from A6. If this behavior is still undesirable, route a
local follow-up for ranking policy: decide whether `bv --robot-next` should
penalize or exclude `in_progress` beads older than a threshold, or whether the
operator should use `bv --robot-alerts` for stale-work cleanup instead of
interpreting top-pick as freshness-clean.

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 8
- public: 8

Three Judges check: a skeptical operator can rerun the exact robot commands, a
maintainer can inspect the raw JSON artifacts, and a future worker can see why
this did not meet the bar for an upstream filing.
