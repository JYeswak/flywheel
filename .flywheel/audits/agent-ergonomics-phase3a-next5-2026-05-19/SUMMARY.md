# Agent Ergonomics Phase 3a Next 5 Summary

- Surfaces audited: 5
- Median final score: 832.5
- Acceptance target: >=750
- Status: PASS

| Surface | Class | Invokes 30d | Initial | Final | Uplift | Workspace |
|---|---|---:|---:|---:|---:|---|
| `.flywheel/scripts/frozen-pane-detector.sh` | ledger-writer | 93 | 752.5 | 832.5 | 80.0 | `.flywheel/scripts/frozen-pane-detector.sh__agent_ergonomics_audit` |
| `.flywheel/scripts/stale-error-auto-ping.sh` | ledger-writer | 82 | 752.5 | 832.5 | 80.0 | `.flywheel/scripts/stale-error-auto-ping.sh__agent_ergonomics_audit` |
| `.flywheel/scripts/recovery-escape-then-reprompt.sh` | ledger-writer | 64 | 752.5 | 832.5 | 80.0 | `.flywheel/scripts/recovery-escape-then-reprompt.sh__agent_ergonomics_audit` |
| `.flywheel/scripts/peer-orch-respawn-permit.sh` | ledger-writer | 48 | 752.5 | 832.5 | 80.0 | `.flywheel/scripts/peer-orch-respawn-permit.sh__agent_ergonomics_audit` |
| `.flywheel/scripts/worker-auto-respawn-watchdog.sh` | ledger-writer | 45 | 752.5 | 832.5 | 80.0 | `.flywheel/scripts/worker-auto-respawn-watchdog.sh__agent_ergonomics_audit` |

## Recommendation Rollup

- Keep capabilities and robot-docs endpoints on all five top-T1 agent-facing surfaces.
- Later scoped passes should continue with remaining T1 agent-facing surfaces only; tests remain out of scope for this skill.
- Later passes can lift intent-inference scores by adding typo-specific `did you mean` suggestions.
