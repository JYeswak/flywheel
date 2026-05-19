# Fleet Codex Health Discipline

Adopted from SkillOS handoff `20260519T185119Z` during the flywheel v0.1 dogfood soak.

The primitive is observation-only. It polls attached NTM sessions, asks the
SkillOS `pane-watchdog.sh` classifier to sweep each session, and appends compact
rows to `/Users/josh/.local/state/flywheel/fleet-codex-health.jsonl`.

It checks:
- attached sessions from `ntm list --json`;
- Codex panes from `ntm activity <session> --json`;
- pane liveness via `pane-watchdog.sh sweep <session>`;
- non-`ALIVE` evidence snapshots under `/tmp/<session>-pane<N>-snapshot.*.json`.

Status surfacing is read-only through
`.flywheel/scripts/fleet-codex-health-status.sh`. Recovery remains permit-gated;
this primitive must not respawn panes or cross owner-session boundaries by
itself.
