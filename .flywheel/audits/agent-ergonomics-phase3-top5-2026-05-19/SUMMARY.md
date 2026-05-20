# Agent Ergonomics Phase 3 Top 5 Summary

- Surfaces audited: 5
- Median final score: 847.5
- Acceptance target: >=750
- Status: PASS

| Surface | Class | Invokes 30d | Initial | Final | Uplift | Workspace |
|---|---|---:|---:|---:|---:|---|
| `bin/flywheel` | CLI | 118 | 767.5 | 847.5 | 80.0 | `bin/flywheel__agent_ergonomics_audit` |
| `.flywheel/scripts/storage-probe.sh` | doctor | 68 | 747.5 | 827.5 | 80.0 | `.flywheel/scripts/storage-probe.sh__agent_ergonomics_audit` |
| `.flywheel/scripts/peer-orch-blocker-watch.sh` | CLI | 56 | 767.5 | 847.5 | 80.0 | `.flywheel/scripts/peer-orch-blocker-watch.sh__agent_ergonomics_audit` |
| `.flywheel/scripts/ntm-wave2-native-probes.sh` | doctor | 56 | 767.5 | 847.5 | 80.0 | `.flywheel/scripts/ntm-wave2-native-probes.sh__agent_ergonomics_audit` |
| `.flywheel/scripts/ntm-spawn-templates-versioned.py` | CLI | 48 | 747.5 | 827.5 | 80.0 | `.flywheel/scripts/ntm-spawn-templates-versioned.py__agent_ergonomics_audit` |

## Recommendation Rollup

- Keep capabilities and robot-docs endpoints on all five top-T1 agent-facing surfaces.
- Phase 3a should continue with remaining T1 CLI/doctor surfaces only; tests in the Top-20 queue remain out of scope for this skill.
- Later passes can lift intent-inference scores by adding typo-specific `did you mean` suggestions.
