# Handoff: SkillOS -> Flywheel Fleet Codex Health Observability

Source: `skillos:3`
Target: `flywheel:1`
Bead: `skillos-supyh`
Generated: 2026-05-19T18:51:19Z

## TL;DR

SkillOS shipped the first observability primitive for today's fleet-wide
Codex-freeze trauma: a launchd-backed fleet Codex health tick that polls all
attached NTM sessions, classifies Codex panes through the existing
`pane-watchdog.sh` substrate, and appends durable rows to:

```text
/Users/josh/.local/state/flywheel/fleet-codex-health.jsonl
```

## Evidence

- Investigation report:
  `/Users/josh/Developer/skillos/state/codex-freeze-fleet-investigation-20260519T184354Z.md`
- Shipped SkillOS tick script:
  `/Users/josh/Developer/skillos/.flywheel/scripts/fleet-codex-health-tick.sh`
- Tick script commit:
  `13c0ac19 feat(watchdog): add fleet codex health tick`
- LaunchAgent plist:
  `/Users/josh/Library/LaunchAgents/ai.zeststream.fleet-codex-health.plist`
- Loaded launchctl label:
  `ai.zeststream.fleet-codex-health`

Verification:

```text
plutil -lint /Users/josh/Library/LaunchAgents/ai.zeststream.fleet-codex-health.plist
=> OK

launchctl list | grep fleet-codex-health
=> -  0  ai.zeststream.fleet-codex-health
```

Launchd RunAtLoad produced a tick at `2026-05-19T18:50:21Z`:

```json
{"schema_version":"flywheel.fleet_codex_health.v1","ts":"2026-05-19T18:50:21Z","session":"skillos","pane":3,"agent_type":"codex","state":"DEAD","activity_state":"THINKING","duration":"0s","confidence":0.8,"classifier":"queued_input_or_capture_failed","source":"fleet-codex-health-tick","evidence":"/tmp/skillos-pane3-snapshot.20260519T185021Z.json"}
```

The same tick wrote 9 compact JSONL rows across the current 8 attached sessions:

```text
alpsinsurance
clutterfreespaces
flywheel
mobile-eats
picoz
skillos
vrtx
zesttube
```

## Ask

Flywheel:1 should consider adopting this primitive fleet-wide after a 1-week
soak period, using the SkillOS ledger as the evidence source for false-positive
rate and operational noise.

Proposed post-soak adoption path:

1. Lift the tick script or equivalent into flywheel-owned substrate.
2. Extend it with freeze-pattern correlation analysis over:
   - `/Users/josh/.local/state/flywheel/fleet-codex-health.jsonl`
   - `/Users/josh/.local/state/flywheel/fuckup-log.jsonl`
   - `/Users/josh/Developer/flywheel/.flywheel/handoffs/*.md`
3. Emit a daily rollup keyed by stable incident IDs such as
   `codex-freeze:2026-05-19:skillos:3`.

Recommended threshold from the SkillOS investigation:

- fleet-wide: `>=5` `pane-respawn` rows in 24h,
- session-local: `>=2` respawns for one session in 2h,
- pane-local: `>=2` non-`ALIVE` health samples plus no commit/callback progress.

Boundary: SkillOS has shipped observation only. Recovery remains permit-gated
and should continue to honor flywheel's owner-session boundary before any
cross-orch respawn.
