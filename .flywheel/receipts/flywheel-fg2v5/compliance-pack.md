# flywheel-fg2v5 compliance pack

## Scope

Added a repo-local NTM-only pane sidecar respawn surface:

- `.flywheel/scripts/ntm-pane-sidecar-respawn.sh`
- `tests/ntm-pane-sidecar-respawn.sh`
- `.flywheel/receipts/flywheel-fg2v5/l112-probe.sh`

## Acceptance mapping

- Dry-run shows target pane, command path, cwd, redacted env overrides, and config overrides.
- Apply restarts only the requested pane through `ntm respawn --panes=<pane>` and launches the explicit sidecar command through `ntm send --pane=<pane>`.
- Apply collects pane health and NTM version evidence.
- Rollback uses recorded-command `ntm respawn` for the same pane and skips sidecar send.

## Socraticode

- socraticode_queries=10
- indexed_chunks_observed=100

## L112

Probe:

```bash
bash .flywheel/receipts/flywheel-fg2v5/l112-probe.sh
```

## Four-Lens Self-Grade

- brand: 8/10. The surface is operator-shaped and scoped to the canary pane.
- sniff: 8/10. The wrapper is dry-run first, emits health/version evidence, and avoids raw pane substrate.
- jeff: 8/10. It adds a boring executable primitive plus a regression test rather than another prose-only recovery note.
- public: 8/10. Three Judges check: a skeptical operator sees the exact NTM plan, a maintainer gets fake-NTM coverage, and a future worker gets a re-runnable L112 probe.
