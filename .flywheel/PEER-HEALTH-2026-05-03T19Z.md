# Peer Health Snapshot 2026-05-03T19Z

Scope: read-only audit of `mobile-eats`, `skillos`, and `alpsinsurance` from flywheel.

System reboot: `2026-05-03T11:56:29-0600` (`2026-05-03T17:56:29Z`).

## Health Table

| Peer | Repo | NTM activity | Agent health | Driver / reboot status | Attention |
|---|---|---|---|---|---|
| `mobile-eats` | `/Users/josh/Developer/mobile-eats` | 2 codex panes detected; robot activity reported panes 1 and 2 as `THINKING` at `2026-05-03T18:44:00Z` | health grade A for panes 1 and 2; both locally idle/healthy | RECOVERED. `ai.zeststream.mobile-eats-flywheel-loop` loaded; recent dispatch proof at `2026-05-03T18:45:30Z`; dispatch log mtime `2026-05-03T18:34:17Z` | None |
| `skillos` | `/Users/josh/Developer/skillos` | 2 codex panes detected; pane 1 `THINKING`, pane 2 `WAITING` at `2026-05-03T18:44:00Z` | health grade A for panes 1 and 2 | RECOVERED. `ai.zeststream.skillos-flywheel-loop` running; recent dispatch/callback rows through `2026-05-03T18:44:06Z`; dispatch log mtime `2026-05-03T18:44:06Z` | None |
| `alpsinsurance` | `/Users/josh/Developer/alpsinsurance` | `SESSION_NOT_FOUND` for `ntm --robot-activity=alpsinsurance`; `ntm list` showed only `flywheel`, `mobile-eats`, `skillos` | `SESSION_NOT_FOUND`; total panes 0 | NOT RECOVERED. `ai.zeststream.alps-flywheel-loop` exists but launchd state is `not running`, `last exit code = 1`; recent post-reboot attempts at `2026-05-03T18:15:44Z`, `18:26:10Z`, `18:36:35Z` all `ntm_dispatch_failed`; ALPS dispatch log mtime `2026-05-03T02:01:31Z` | Agent Mail contact request opened to active ALPS agent `CopperGlen`; direct send blocked by contact approval policy. No ALPS intervention performed. |

## Fuckup Mining

Inputs checked:
- Repo-local incident files: `/Users/josh/Developer/{mobile-eats,skillos,alpsinsurance}/.flywheel/INCIDENTS.md`
- Repo-local fuckup logs: none of the three peer repos has `.flywheel/fuckup-log.jsonl`
- Fleet fuckup log filtered by `session`, `git_repo`, and peer names: `~/.local/state/flywheel/fuckup-log.jsonl`

Last-24h peer rows mined from fleet log: 78 events across 63 exact trauma classes.

No exact trauma class had `>=3` occurrences across `>=2` peer sessions in the last 24h. Exact-class promotion candidates: 0.

High-frequency single-peer classes:
- `canonical_doctrine_drift_local`: 4, `mobile-eats`, max medium
- `research-health-prelude-fail`: 4, `mobile-eats`, max medium
- `beads_db_health_failed`: 3, `mobile-eats`, max high
- `br-create-source-repo-dot-after-create`: 5, mostly `skillos` plus flywheel-scoped rows
- `br-source-repo-dot-after-create`: 3, mostly `skillos` plus flywheel-scoped rows
- `phase-advance-drift`: 2, `mobile-eats`, max high
- `jsm-health-probe-corrupts-sqlite`: 2, `skillos`, max high

Doctrine-bleed signals:
- `frozen-codex-spinner-misclassified-as-thinking` recurred after promotion in flywheel `INCIDENTS.md`.
- `agent-mail-token-echo-in-pane` and adjacent token-continuity/token-echo classes recurred after L58.
- `canonical_doctrine_drift_local` recurred 4 times in `mobile-eats`, adjacent to L61 ecosystem-wire-in doctrine.
- NTM health/activity disagreement classes recurred in `mobile-eats` and `skillos`, adjacent to L67 live truth-source doctrine.

## Reboot Recovery

| Peer | Last 2h evidence | Verdict |
|---|---|---|
| `mobile-eats` | loop log shows repeated `run_start` and `ntm_dispatch_sent` after reboot; latest at `2026-05-03T18:45:30Z`; session attached | recovered |
| `skillos` | launchd job running; dispatch log has rows at `2026-05-03T18:28:16Z`, `18:34:57Z`, `18:43:10Z`, `18:44:06Z`; session attached | recovered |
| `alpsinsurance` | no NTM session; launchd job not running with last exit 1; recent loop logs are dispatch failures | failed |

Promotion queue impact: add `reboot-recovery-asymmetry` as a reboot-specific doctrine candidate even though exact-class mining produced zero cross-peer class candidates.
