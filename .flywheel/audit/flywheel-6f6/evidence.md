# flywheel-6f6 evidence

Task: flywheel-6f6-d03daf
Bead: flywheel-6f6
Status: DONE-ready

## Acceptance

- PASS: `.flywheel/launchd/tentacle-daemon-registry.json` lists each daemon's plist label, expected uptime, binary path, and restart policy.
- PASS: `.flywheel/scripts/tentacle-launchd-matrix.sh --json` reconciles registry rows against `launchctl list` output and emits JSON.
- PASS: fixture test validates missing daemon, stale daemon, disabled-but-loaded daemon, and read-only restart matrix output.
- PASS: audit mode does not unload, reload, bootout, bootstrap, or kickstart services.

## Live audit

Command:

```bash
.flywheel/scripts/tentacle-launchd-matrix.sh --json | jq '{status,total,pass_count,warn_count,mutation_performed,rows:[.rows[]|{plist_label,status,reason,launchctl_present,planned_restart_action}]}'
```

Observed:

```json
{
  "status": "warn",
  "total": 2,
  "pass_count": 1,
  "warn_count": 1,
  "mutation_performed": false,
  "rows": [
    {
      "plist_label": "ai.zeststream.ntm-fleet-health",
      "status": "warn",
      "reason": "missing_launchd_label",
      "launchctl_present": false,
      "planned_restart_action": "launchctl kickstart -k gui/501/ai.zeststream.ntm-fleet-health"
    },
    {
      "plist_label": "com.vc.daemon",
      "status": "pass",
      "reason": "disabled_expected",
      "launchctl_present": false,
      "planned_restart_action": null
    }
  ]
}
```

## Verification

- PASS: `bash -n .flywheel/scripts/tentacle-launchd-matrix.sh`
- PASS: `bash -n tests/tentacle-launchd-matrix.sh`
- PASS: `tests/tentacle-launchd-matrix.sh`
- PASS: `bash /Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh .flywheel/scripts/tentacle-launchd-matrix.sh`
- PASS: `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-6f6-d03daf.md`
- PASS: `br dep tree flywheel-6f6`

## Compliance pack

- socraticode_queries: 1
- indexed_chunks_observed: 10
- skill_auto_routes_addressed: canonical-cli-scoping=yes, rust-best-practices=n/a, python-best-practices=n/a, readme-writing=n/a
- skill_discoveries: 0
- beads_filed: none
- beads_updated: flywheel-6f6
- no_bead_reason: no new gap; existing bead closed
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- no_touch_reason: no doctrine or README changes
- four_lens: brand:8, sniff:9, jeff:8, public:8

## Artifacts

- `.flywheel/launchd/tentacle-daemon-registry.json`
- `.flywheel/scripts/tentacle-launchd-matrix.sh`
- `tests/tentacle-launchd-matrix.sh`
- `.flywheel/audit/flywheel-6f6/l112-probe.sh`
- `.flywheel/audit/flywheel-6f6/validation-receipt.json`
