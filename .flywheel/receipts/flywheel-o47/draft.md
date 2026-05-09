# Watcher reports healthy when GitHub token is invalid

## What happened
Observed: Jeff watcher reported healthy while GITHUB_TOKEN auth failed and unauthenticated REST still showed ntm#111 open

## Repro
```bash
export GITHUB_TOKEN=invalid && run Jeff watcher status probe; compare gh auth status with unauthenticated REST issue state
```

## Expected vs observed
Expected: Watcher classifies 401 or 403 GitHub auth as unhealthy and preserves a clear monitor signal

Observed: Jeff watcher reported healthy while GITHUB_TOKEN auth failed and unauthenticated REST still showed ntm#111 open

## File:line citations
- `INCIDENTS.md:619`
- `INCIDENTS.md:631`

## Why this matters / cost citation
This breaks downstream flywheel substrate expectations; see tracking bead.

## Tracking
Tracking on flywheel side: bead flywheel-o47

## Monitor plan
After filing, track the upstream issue in `~/.local/state/flywheel/jeff-issues.jsonl`, poll with `.flywheel/scripts/jeff-issue-response-poll.sh`, and close or update flywheel-o47 only after the upstream state or response is reconciled.

## Out of scope
Not asking for a PR, patch, or implementation prescription here; this is a contract/repro report for Dicklesworthstone/ntm.
