# Flywheel Scripts

Repo-local helper scripts used by the flywheel control plane and slash-command
surfaces.

| Script | Purpose |
|---|---|
| `flywheel-onboard.sh` | Phase 2 canonical fleet onboarding CLI: 5-tier dry-run/doctor probe, schema/info/examples, stamp/sync/upgrade planning surface. |
| `leverage-ceiling-probe.sh` | Meadows leverage ceiling probe for account/machine/token binding constraints. |
| `gap-hunt-probe.sh` | Gap discovery probe with loop-integrity classes and append-only ledger support. |
| `mobile-eats-receipt-bridge.sh` | Read-only bridge from product loop receipts to canonical flywheel tick-shaped JSON. |
| `mobile-eats-loop-with-receipt-mirror.sh` | Launchd wrapper that mirrors mobile-eats receipts to the canonical path after each product tick. |
| `headless-browser-probe.sh` | JSON doctor probe for orphaned `agent-browser-chrome` process count, age, memory, and lock suspicion. |
| `headless-browser-reap.sh` | Dry-run-first reaper for stale or over-threshold `agent-browser-chrome` processes; applied runs append receipts. |
| `frozen-pane-detector-fleet.sh` | Disabled-by-default LaunchAgent installer and doctor wrapper for fleet frozen-pane observation; honors STOP/FATAL files, recovery budgets, and degraded-truth no-recovery gates. |
| `daily-report.sh` | Generates `.flywheel/reports/daily-YYYY-MM-DD.md` from Beads, memory, dispatch, fuckup, doctor, Jeff-intel, incidents, and cross-orch state. |
| `agentmail-registration-broadcast.sh` | Sends token-safe registration request packets to live `needs_registration` orchestrator panes and exposes `agentmail_pending_registration_broadcasts_count`. |

Run script-specific `--help`, `--info`, `--schema`, and `--examples` where
available before wiring a script into doctor or slash-command surfaces.
