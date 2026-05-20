---
title: "Topology Restoration After Migration Strip"
type: doctrine
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Topology Restoration After Migration Strip

A documented failure class where a topology-rewriting script silently drops
pane-membership fields (`orchestrator_pane`, `callback_pane`, `worker_panes`,
`orchestrator_kind`, `human_pane`, `expected_pane_count`, `shell_panes`,
`worker_kinds`), causing latest-wins reads to misclassify orchestrator panes
as workers and orphaning fleet-mail identities.

## Symptom

- Orchestrator pane runs `/flywheel:loop` and the loop cron classifies its
  role as `worker` instead of `orchestrator`.
- `flywheel-loop doctor` reports `team_roster_freshness` GHOST/DEGRADED for
  affected sessions despite tmux session being live and active.
- `flywheel-skillos-relay doctor` reports `skillos_fleet_mail_identity_unregistered`
  even when the identity is registered and the token file present.
- `topology-gap-probe.sh --json` reports `latest_missing_required_fields_count > 0`.

## Root cause class

A topology-mutating script writes a new `session-topology.jsonl` row for an
existing session but only includes the field(s) it cares about
(e.g. `repo_path`, `bead_id_prefix`) and omits the pane-membership fields.

Because the topology reader uses latest-wins by `effective_at`, the new
incomplete row supersedes the prior good row and the missing fields read as
`null`. Downstream consumers (loop tick, skillos relay, team-pulse-heartbeat)
treat `null` as "absent" and behave incorrectly.

## Documented incident

- 2026-05-07T05:50Z — `migrate-topology-add-repo-path` ran across the fleet,
  added `repo_path` and `bead_id_prefix` to topology rows but stripped pane
  membership for 5 sessions: flywheel, mobile-eats, picoz, vrtx, alpsinsurance
  (clutterfreespaces never had pane membership registered).
- 2026-05-08T05:59Z — Joshua surfaced symptom: alps pane 1 loop tick
  classified role=worker.
- 2026-05-08T06:0xZ — Restoration appended `topology-restoration-*` rows
  merging latest fields with the pre-migration pane membership, and
  `topology-restoration-fill-required-fields` rows backfilled
  `orchestrator_kind` and `human_pane`. Tracked under bead `flywheel-4o9o1`.

## Restoration recipe

For each affected session:

1. Walk topology rows in order; identify the latest row before the strip
   (latest row with `orchestrator_pane != null`).
2. Build a new row that:
   - Carries forward all fields from the current latest row (including
     post-migration additions like `repo_path`, `bead_id_prefix`).
   - Restores stripped fields from the pre-migration row:
     `orchestrator_pane`, `callback_pane`, `worker_panes`, `worker_kinds`,
     `expected_pane_count`, `human_pane`, `shell_panes`,
     `fleet_mail_identity`, `agent_mail_identity`.
   - Sets `effective_at` = now,
     `registered_by` = `topology-restoration-after-migrate-topology-add-repo-path`,
     `restored_orchestrator_pane_from` = pre-migration `effective_at`.
3. Append to `~/.local/state/flywheel/session-topology.jsonl`.
4. Verify `topology-gap-probe.sh --json` shows
   `latest_missing_required_fields_count` decreased.

## Guard against future occurrence

`topology-tick-refresh.sh` correctly preserves all prior fields via
`dict(row, ...)` semantics — so once a restoration row lands, future
`topology-tick-refresh` runs will keep the fields.

The remaining systemic risk is a future ad-hoc migration script that does
NOT use `dict(row, ...)` semantics. The guard:

- `topology-gap-probe.sh` already detects rows missing required fields and
  is wired into the doctor surface
  (`flywheel-loop doctor --json` exposes `latest_missing_required_fields_count`).
- Any new topology-mutating script MUST use `dict(prior, ...)` semantics
  (carry forward, then override). Single-field updates are explicit
  "augment latest row" not "create new row".

## Latent issue

`clutterfreespaces` has 230 topology rows but NONE include
pane membership — the session was never properly onboarded with a topology
row that had `orchestrator_pane`. This is a separate issue from migration
damage and needs its own onboarding action, not restoration.

## Cross-references

- Bead: `flywheel-4o9o1`
- Receipt: `.flywheel/receipts/flywheel-4o9o1-receipt.md`
- Probe: `.flywheel/scripts/topology-gap-probe.sh`
- Refresh script: `.flywheel/scripts/topology-tick-refresh.sh` (preserves fields correctly)
- HR policy: `.flywheel/doctrine/fleet-doctrine-hr-policy.md`


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
