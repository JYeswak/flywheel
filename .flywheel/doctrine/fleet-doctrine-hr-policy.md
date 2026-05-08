# Fleet Doctrine HR Policy

How canonical doctrine stays propagated across all flywheel-installed repos
with minimum operator effort. Frame it as HR: auto-enroll on hire, continuous
attestation, automatic remediation, compliance reporting.

## Source of truth

`/Users/josh/Developer/flywheel/AGENTS.md` (and its `.flywheel/AGENTS-CANONICAL.md`
mirror) is the canonical L-rule corpus. Edits land here first, then propagate.

When a rule is added, edited, or retired, the operator only edits the source.
The fleet picks up the change on the next attestation cycle (≤6h) without
manual touch.

## Three-layer enforcement stack

| Layer | Driver | Cadence | Action | Surface |
|---|---|---|---|---|
| **Hire (enroll)** | `flywheel-loop init` in repo | on-demand | Creates `.flywheel/`; repo is auto-discovered next cycle | `flywheel-loop doctor` |
| **Attestation (observe)** | `~/Library/LaunchAgents/ai.zeststream.canonical-meta-rules-sync-watchdog.plist` → `~/.flywheel/canonical-meta-rules/watchdog.sh` | every 1h | Three-surface drift check on 6 named repos; writes `~/.local/state/flywheel/canonical-meta-rules-watchdog.jsonl`; observe-only | `team_roster_freshness` adjacent |
| **Remediation (apply)** | `~/Library/LaunchAgents/ai.zeststream.flywheel-doctrine-sync.plist` → `flywheel-doctrine-sync --trigger periodic` | every 6h | Full sync: copies canonical AGENTS.md to `<repo>/AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md` for all in-scope repos under `/Users/josh/Developer`. Backup-before-write (`AGENTS.md.bak.<ts>`); append-only ledger | `flywheel-loop doctor` shows `fleet_l_rule_lag` |

Plus the manual escape hatch: `~/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh --apply` for emergency push.

## Auto-discovery

`flywheel-doctrine-sync` walks `/Users/josh/Developer/*/.flywheel/` and includes
any repo with a `loop.json` present. No manual enrollment list to maintain.

Confirmed scale at 2026-05-08: 327 repos scanned, 54 in-scope, 53 needed sync
on first run after L127-L138 propagation.

## Compliance reporting

`flywheel-loop doctor --json` surfaces:

- `doctrine_3_surface_divergence` — local repo doctrine integrity (pass/fail)
- `fleet_l_rule_lag` — count of fleet repos behind canonical (pass when zero)
- `fleet_three_surface_drift` — per-session three-surface drift count
- `skillos_relay` — separate L-rule relay channel (orthogonal to AGENTS.md sync)

Drift visible in any tick that runs the doctor.

## Self-service remediation

If an operator detects drift before the cron fires:

```bash
# Manual sync (apply mode default; requires no flags)
/Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync --trigger manual

# Or force a single repo
/Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync --trigger manual --repo /path/to/repo

# Local-only sync (full canonical block in root AGENTS.md, plus schemas/scripts)
/Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh --apply
```

Logs in `~/.claude/skills/reports/flywheel-doctrine-sync.{out,err}.log` and
`~/.local/state/flywheel/doctrine-sync-ledger.jsonl` (append-only, every action
recorded with prior/new content hashes and backup paths).

## Failure modes the policy fixes

| Mode | Without policy | With policy |
|---|---|---|
| Operator forgets to push canonical to repo X | X drifts silently for weeks | Picked up within 6h |
| New repo onboarded mid-cycle | Manual enrollment required | Auto-discovered next sync |
| Doctrine edited in a non-canonical surface | Each repo's local copy diverges | Canonical wins; non-canonical edits get backed up + overwritten |
| Plist gets unloaded (system event, etc.) | Silent drift accumulation | Doctor's `fleet_l_rule_lag` surfaces lag count; manual reload restores |

## Restoration history

- 2026-05-01: Plist first installed and validated (per README spec).
- 2026-05-08: Plist restored after observed absence; missing-plist drift
  manifested as `fleet_l_rule_lag=fail` (29 repos) and
  `fleet_three_surface_drift=drift` (across multiple sessions). Restoration
  RunAtLoad immediately resynced 53 in-scope repos.

## What's NOT in this policy (separate mechanisms)

- **Skill propagation**: `~/.claude/skills/` directory is a different surface;
  see `flywheel-skillos-relay`.
- **L-rule relay to skillos**: blocked by `skillos_fleet_mail_identity_unregistered`;
  separate substrate task.
- **mobile-eats three-surface drift (21 rules)**: mobile-eats template uses a
  local AGENTS.md that's not under the doctrine-sync scope; needs its own
  reconcile path.
- **Schema/script propagation**: `sync-canonical-doctrine.sh` (local manual
  helper) handles validation schemas and bead-quality-mining script in
  addition to AGENTS.md, with a wider scope. Run it after schema edits, not
  for routine doctrine updates.

## Cadence rationale

6h apply cycle is conservative. Doctrine doesn't change every hour, and each
sync writes backup files that accumulate. Faster cadence would inflate
`AGENTS.md.bak.*` count without operational gain. The hourly watchdog
provides faster *detection* (≤1h) while remediation runs less often.

If a doctrine edit needs to propagate same-tick, run the manual escape hatch.
Add edits via the manual path also write to the ledger so the cron's next run
sees `prior_hash == new_hash` and skips.
