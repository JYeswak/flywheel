# Runtime Doctrine Separation Fleet Dry Run

- generated_at: `2026-05-20T05:43:44Z`
- mode: `dry-run`
- apply_policy: `Joshua-gated; agents must not apply fleet migration without direct approval`

| Repo | Outcome | Tracked before | Tracked after | Bytes recovered | Runtime classes | Mixed pending | Secret incidents |
|---|---:|---:|---:|---:|---|---:|---:|
| /Users/josh/Developer/flywheel | mixed-needs-operator | 3671 | 3180 | 4440745 | .flywheel/runtime<br>.flywheel/state<br>.flywheel/evidence | 1 | 0 |
| /Users/josh/Developer/skillos | ok | 743 | 742 | 14 | .flywheel/runtime | 0 | 0 |
| /Users/josh/Developer/zesttube | ok | 479 | 478 | 1491 | .flywheel/state | 0 | 0 |
| /Users/josh/Developer/mobile-eats | mixed-needs-operator | 1421 | 1403 | 933654 | .flywheel/evidence | 3 | 0 |
| /Users/josh/Developer/clutterfreespaces | mixed-needs-operator | 1218 | 1126 | 296050 | .flywheel/state<br>.flywheel/evidence | 1 | 0 |

## Raw Summaries

```json
[
  {
    "schema_version": "runtime_doctrine_separation_migrate.v1",
    "ts": "2026-05-20T05:43:45Z",
    "repo": "/Users/josh/Developer/flywheel",
    "mode": "dry-run",
    "outcome": "mixed-needs-operator",
    "runtime_migrated": [
      ".flywheel/runtime",
      ".flywheel/state",
      ".flywheel/evidence"
    ],
    "tracked_files_before": 3671,
    "tracked_files_after": 3180,
    "bytes_recovered": 4440745,
    "secrets_incidents": [],
    "mixed_classes_pending_review": [
      {
        "class": "audits",
        "path": ".flywheel/audits",
        "tracked_files": 97,
        "tracked_bytes": 91164247,
        "operator_action": "review class-specific retention before untracking or rotating",
        "truncated": false
      }
    ],
    "runtime_actions": [
      {
        "class": "runtime",
        "path": ".flywheel/runtime",
        "target": "/Users/josh/.local/state/flywheel/flywheel/runtime",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 11,
        "tracked_files_after": 0,
        "tracked_bytes_before": 260571,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/runtime"
        }
      },
      {
        "class": "state",
        "path": ".flywheel/state",
        "target": "/Users/josh/.local/state/flywheel/flywheel/state",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 28,
        "tracked_files_after": 0,
        "tracked_bytes_before": 1017521,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/state"
        }
      },
      {
        "class": "evidence",
        "path": ".flywheel/evidence",
        "target": "/Users/josh/.local/state/flywheel/flywheel/evidence",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 452,
        "tracked_files_after": 0,
        "tracked_bytes_before": 3162653,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/evidence"
        }
      }
    ]
  },
  {
    "schema_version": "runtime_doctrine_separation_migrate.v1",
    "ts": "2026-05-20T05:43:45Z",
    "repo": "/Users/josh/Developer/skillos",
    "mode": "dry-run",
    "outcome": "ok",
    "runtime_migrated": [
      ".flywheel/runtime"
    ],
    "tracked_files_before": 743,
    "tracked_files_after": 742,
    "bytes_recovered": 14,
    "secrets_incidents": [],
    "mixed_classes_pending_review": [],
    "runtime_actions": [
      {
        "class": "runtime",
        "path": ".flywheel/runtime",
        "target": "/Users/josh/.local/state/flywheel/skillos/runtime",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 1,
        "tracked_files_after": 0,
        "tracked_bytes_before": 14,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/runtime"
        }
      },
      {
        "class": "state",
        "path": ".flywheel/state",
        "target": "/Users/josh/.local/state/flywheel/skillos/state",
        "planned": false,
        "already_migrated": false,
        "tracked_files_before": 0,
        "tracked_files_after": 0,
        "tracked_bytes_before": 0,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/state"
        }
      },
      {
        "class": "evidence",
        "path": ".flywheel/evidence",
        "target": "/Users/josh/.local/state/flywheel/skillos/evidence",
        "planned": false,
        "already_migrated": false,
        "tracked_files_before": 0,
        "tracked_files_after": 0,
        "tracked_bytes_before": 0,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/evidence"
        }
      }
    ]
  },
  {
    "schema_version": "runtime_doctrine_separation_migrate.v1",
    "ts": "2026-05-20T05:43:45Z",
    "repo": "/Users/josh/Developer/zesttube",
    "mode": "dry-run",
    "outcome": "ok",
    "runtime_migrated": [
      ".flywheel/state"
    ],
    "tracked_files_before": 479,
    "tracked_files_after": 478,
    "bytes_recovered": 1491,
    "secrets_incidents": [],
    "mixed_classes_pending_review": [],
    "runtime_actions": [
      {
        "class": "runtime",
        "path": ".flywheel/runtime",
        "target": "/Users/josh/.local/state/flywheel/zesttube/runtime",
        "planned": false,
        "already_migrated": false,
        "tracked_files_before": 0,
        "tracked_files_after": 0,
        "tracked_bytes_before": 0,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/runtime"
        }
      },
      {
        "class": "state",
        "path": ".flywheel/state",
        "target": "/Users/josh/.local/state/flywheel/zesttube/state",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 1,
        "tracked_files_after": 0,
        "tracked_bytes_before": 1491,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/state"
        }
      },
      {
        "class": "evidence",
        "path": ".flywheel/evidence",
        "target": "/Users/josh/.local/state/flywheel/zesttube/evidence",
        "planned": false,
        "already_migrated": false,
        "tracked_files_before": 0,
        "tracked_files_after": 0,
        "tracked_bytes_before": 0,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/evidence"
        }
      }
    ]
  },
  {
    "schema_version": "runtime_doctrine_separation_migrate.v1",
    "ts": "2026-05-20T05:43:45Z",
    "repo": "/Users/josh/Developer/mobile-eats",
    "mode": "dry-run",
    "outcome": "mixed-needs-operator",
    "runtime_migrated": [
      ".flywheel/evidence"
    ],
    "tracked_files_before": 1421,
    "tracked_files_after": 1403,
    "bytes_recovered": 933654,
    "secrets_incidents": [],
    "mixed_classes_pending_review": [
      {
        "class": "validation",
        "path": ".flywheel/validation",
        "tracked_files": 355,
        "tracked_bytes": 29459886,
        "operator_action": "review class-specific retention before untracking or rotating",
        "truncated": true
      },
      {
        "class": "brand-candidates",
        "path": ".flywheel/brand-candidates",
        "tracked_files": 21,
        "tracked_bytes": 6095262,
        "operator_action": "review class-specific retention before untracking or rotating",
        "truncated": false
      },
      {
        "class": "audits",
        "path": ".flywheel/audits",
        "tracked_files": 67,
        "tracked_bytes": 6412380,
        "operator_action": "review class-specific retention before untracking or rotating",
        "truncated": false
      }
    ],
    "runtime_actions": [
      {
        "class": "runtime",
        "path": ".flywheel/runtime",
        "target": "/Users/josh/.local/state/flywheel/mobile-eats/runtime",
        "planned": false,
        "already_migrated": false,
        "tracked_files_before": 0,
        "tracked_files_after": 0,
        "tracked_bytes_before": 0,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/runtime"
        }
      },
      {
        "class": "state",
        "path": ".flywheel/state",
        "target": "/Users/josh/.local/state/flywheel/mobile-eats/state",
        "planned": false,
        "already_migrated": false,
        "tracked_files_before": 0,
        "tracked_files_after": 0,
        "tracked_bytes_before": 0,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/state"
        }
      },
      {
        "class": "evidence",
        "path": ".flywheel/evidence",
        "target": "/Users/josh/.local/state/flywheel/mobile-eats/evidence",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 18,
        "tracked_files_after": 0,
        "tracked_bytes_before": 933654,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/evidence"
        }
      }
    ]
  },
  {
    "schema_version": "runtime_doctrine_separation_migrate.v1",
    "ts": "2026-05-20T05:43:45Z",
    "repo": "/Users/josh/Developer/clutterfreespaces",
    "mode": "dry-run",
    "outcome": "mixed-needs-operator",
    "runtime_migrated": [
      ".flywheel/state",
      ".flywheel/evidence"
    ],
    "tracked_files_before": 1218,
    "tracked_files_after": 1126,
    "bytes_recovered": 296050,
    "secrets_incidents": [],
    "mixed_classes_pending_review": [
      {
        "class": "audits",
        "path": ".flywheel/audits",
        "tracked_files": 253,
        "tracked_bytes": 1524111,
        "operator_action": "review class-specific retention before untracking or rotating",
        "truncated": true
      }
    ],
    "runtime_actions": [
      {
        "class": "runtime",
        "path": ".flywheel/runtime",
        "target": "/Users/josh/.local/state/flywheel/clutterfreespaces/runtime",
        "planned": false,
        "already_migrated": false,
        "tracked_files_before": 0,
        "tracked_files_after": 0,
        "tracked_bytes_before": 0,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/runtime"
        }
      },
      {
        "class": "state",
        "path": ".flywheel/state",
        "target": "/Users/josh/.local/state/flywheel/clutterfreespaces/state",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 17,
        "tracked_files_after": 0,
        "tracked_bytes_before": 124439,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/state"
        }
      },
      {
        "class": "evidence",
        "path": ".flywheel/evidence",
        "target": "/Users/josh/.local/state/flywheel/clutterfreespaces/evidence",
        "planned": true,
        "already_migrated": false,
        "tracked_files_before": 75,
        "tracked_files_after": 0,
        "tracked_bytes_before": 171611,
        "gitignore": {
          "added": false,
          "already_present": false,
          "pattern": "/.flywheel/evidence"
        }
      }
    ]
  }
]

```
