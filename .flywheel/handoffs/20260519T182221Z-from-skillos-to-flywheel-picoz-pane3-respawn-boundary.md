# Handoff: SkillOS -> flywheel picoz pane-respawn boundary

Source: `skillos:2`
Target: `flywheel:1`
Bead: `skillos-i568d`
Owner repo: `/Users/josh/Developer/flywheel`
Target script: `/Users/josh/Developer/flywheel/.flywheel/scripts/peer-orch-respawn-permit.sh`

## Incident

Today, 2026-05-19, `picoz-orch` respawned `skillos:3` mid-task. Joshua had to
correct the cross-orch interruption manually.

This is the same class as the earlier cross-orch boundary incident where a
worker clobbered peer-canonical state through absolute-path construction. The
shared failure shape is: one orchestrator acted on another session's owned
runtime without proving ownership first.

## Requested flywheel change

Extend `peer-orch-respawn-permit.sh` so a respawn request is refused when:

```text
permit-orch != owning-session-orch
```

Concrete expected behavior:

- `picoz:1` attempting to respawn `skillos:3` must be refused.
- The refusal message should name the owning session/orchestrator and cite the
  L115 peer-orch recovery permit contract.
- Same-orchestrator recovery remains allowed when the existing L115 permit gates
  pass.

## Acceptance target

Add a synthetic test in the flywheel repo proving a `picoz:1 -> skillos:3`
respawn attempt is refused with a clear L115 error. Keep the SkillOS bead
`skillos-i568d` open until flywheel lands the script/test change or returns a
specific non-action disposition.

## Boundary

SkillOS is not editing `/Users/josh/Developer/flywheel` in this tick. This
handoff routes the owner-side script change to flywheel.
