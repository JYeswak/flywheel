# Stale Worktree Detector Initial Dry Run

- generated: 20260520T084447Z
- mode: probe-only dry-run; no SLB submissions

## flywheel

```json
{
  "repo": "/Users/josh/Developer/flywheel",
  "default_branch": "master",
  "worktrees_total": 12,
  "classified_counts": {
    "DISPOSABLE": 0,
    "REVERSIBLE_RECIPE": 0,
    "PEER_REVIEW": 12,
    "HUMAN_FALLBACK": 0
  },
  "submissions": 0,
  "routing_table": {
    "path": "/Users/josh/Developer/zesttube/.flywheel/config/slb-tier-mapping.yaml",
    "routes": {
      "DISPOSABLE": "8iook",
      "PEER_REVIEW": "zesttube-slb",
      "REVERSIBLE_RECIPE": "daeqx"
    },
    "status": "missing"
  }
}

```

## zesttube

```json
{
  "repo": "/Users/josh/Developer/zesttube",
  "default_branch": "main",
  "worktrees_total": 35,
  "classified_counts": {
    "DISPOSABLE": 0,
    "REVERSIBLE_RECIPE": 0,
    "PEER_REVIEW": 35,
    "HUMAN_FALLBACK": 0
  },
  "submissions": 0,
  "routing_table": {
    "path": "/Users/josh/Developer/zesttube/.flywheel/config/slb-tier-mapping.yaml",
    "routes": {
      "DISPOSABLE": "8iook",
      "PEER_REVIEW": "zesttube-slb",
      "REVERSIBLE_RECIPE": "daeqx"
    },
    "status": "missing"
  }
}

```
