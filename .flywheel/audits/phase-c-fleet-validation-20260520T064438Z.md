# Phase C Fleet Validation

- `ts`: `2026-05-20T06:44:38Z`
- `canonical_root`: `/Users/josh/Developer/skillos`
- `fleet_conformance_avg`: `0.875`
- `phase_a_avg`: `0.875`
- `phase_b_avg`: `0.125`
- `doctrine_avg`: `0.125`
- `memory_avg`: `0.1875`

| orch | phase_a | phase_b | doctrine | memory | findings |
|---|---:|---:|---:|---:|---:|
| mobile-eats | 1.0000 | 0.0000 | 0.0000 | 0.0000 | 0 |
| picoz | 1.0000 | 0.0000 | 0.0000 | 0.0000 | 0 |
| clutterfreespaces | 1.0000 | 0.0000 | 0.0000 | 0.0000 | 0 |
| alpsinsurance | 1.0000 | 0.0000 | 0.0000 | 0.0000 | 0 |
| vrtx | 1.0000 | 0.0000 | 0.0000 | 0.0000 | 0 |
| terratitle | 1.0000 | 0.0000 | 0.0000 | 0.0000 | 0 |
| skillos | 1.0000 | 1.0000 | 0.0000 | 0.5000 | 0 |
| flywheel | 0.0000 | 0.0000 | 1.0000 | 1.0000 | 4 |

## Divergences

- `flywheel` `shasum_mismatch_unattributed` `.flywheel/scripts/codex-goal-activate.sh` severity=`gap`
- `flywheel` `file_missing` `.flywheel/scripts/pane-work-signal-classify.sh` severity=`gap`
- `flywheel` `file_missing` `.flywheel/specs/pane-work-signal-taxonomy-v0.2.md` severity=`gap`
- `flywheel` `file_missing` `.flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md` severity=`gap`

## JSON

```json
{
  "fleet_rollup": {
    "canonical_root": "/Users/josh/Developer/skillos",
    "doctrine_avg": 0.125,
    "fleet_conformance_avg": 0.875,
    "fleet_size": 8,
    "memory_avg": 0.1875,
    "phase_a_avg": 0.875,
    "phase_b_avg": 0.125,
    "schema_version": "phase-c-fleet-validation/v1",
    "top_divergence_classes": [
      {
        "class": "file_missing",
        "count": 3
      },
      {
        "class": "shasum_mismatch_unattributed",
        "count": 1
      }
    ],
    "ts": "2026-05-20T06:44:38Z"
  },
  "orch_envelopes": [
    {
      "divergence_findings": [],
      "doctrine_propagation": {
        "conformance_pct": 0.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": false
          }
        ],
        "present": 0
      },
      "memory_pins": {
        "conformance_pct": 0.0,
        "exists": true,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-mobile-eats/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": false
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": false
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": false
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": false
          }
        ],
        "present": 0
      },
      "orch": "mobile-eats",
      "overall_conformance_pct": 1.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 1.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "status": "match",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": true,
            "sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "status": "match",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": true,
            "sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "status": "match",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": true,
            "sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "status": "match",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [],
        "mismatches": 0,
        "missing": 0,
        "present": 4,
        "shasum_matches": 4
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": false,
          "route_source_logged_or_topology_detected": false
        },
        "conformance_pct": 0.0,
        "files_checked": [
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "pending"
      },
      "repo": "/Users/josh/Developer/mobile-eats",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    },
    {
      "divergence_findings": [],
      "doctrine_propagation": {
        "conformance_pct": 0.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": false
          }
        ],
        "present": 0
      },
      "memory_pins": {
        "conformance_pct": 0.0,
        "exists": true,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-polymarket-pico-z/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": false
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": false
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": false
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": false
          }
        ],
        "present": 0
      },
      "orch": "picoz",
      "overall_conformance_pct": 1.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 1.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "status": "match",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": true,
            "sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "status": "match",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": true,
            "sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "status": "match",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": true,
            "sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "status": "match",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [],
        "mismatches": 0,
        "missing": 0,
        "present": 4,
        "shasum_matches": 4
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": false,
          "route_source_logged_or_topology_detected": false
        },
        "conformance_pct": 0.0,
        "files_checked": [
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "pending"
      },
      "repo": "/Users/josh/Developer/polymarket-pico-z",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    },
    {
      "divergence_findings": [],
      "doctrine_propagation": {
        "conformance_pct": 0.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": false
          }
        ],
        "present": 0
      },
      "memory_pins": {
        "conformance_pct": 0.0,
        "exists": true,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-clutterfreespaces/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": false
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": false
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": false
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": false
          }
        ],
        "present": 0
      },
      "orch": "clutterfreespaces",
      "overall_conformance_pct": 1.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 1.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "status": "match",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": true,
            "sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "status": "match",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": true,
            "sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "status": "match",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": true,
            "sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "status": "match",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [],
        "mismatches": 0,
        "missing": 0,
        "present": 4,
        "shasum_matches": 4
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": false,
          "route_source_logged_or_topology_detected": false
        },
        "conformance_pct": 0.0,
        "files_checked": [
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "pending"
      },
      "repo": "/Users/josh/Developer/clutterfreespaces",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    },
    {
      "divergence_findings": [],
      "doctrine_propagation": {
        "conformance_pct": 0.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": false
          }
        ],
        "present": 0
      },
      "memory_pins": {
        "conformance_pct": 0.0,
        "exists": true,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-alpsinsurance/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": false
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": false
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": false
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": false
          }
        ],
        "present": 0
      },
      "orch": "alpsinsurance",
      "overall_conformance_pct": 1.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 1.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "status": "match",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": true,
            "sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "status": "match",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": true,
            "sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "status": "match",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": true,
            "sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "status": "match",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [],
        "mismatches": 0,
        "missing": 0,
        "present": 4,
        "shasum_matches": 4
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": false,
          "route_source_logged_or_topology_detected": false
        },
        "conformance_pct": 0.0,
        "files_checked": [
          ".flywheel/WORK.md",
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "pending"
      },
      "repo": "/Users/josh/Developer/alpsinsurance",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    },
    {
      "divergence_findings": [],
      "doctrine_propagation": {
        "conformance_pct": 0.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": false
          }
        ],
        "present": 0
      },
      "memory_pins": {
        "conformance_pct": 0.0,
        "exists": true,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-vrtx/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": false
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": false
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": false
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": false
          }
        ],
        "present": 0
      },
      "orch": "vrtx",
      "overall_conformance_pct": 1.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 1.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "status": "match",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": true,
            "sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "status": "match",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": true,
            "sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "status": "match",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": true,
            "sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "status": "match",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [],
        "mismatches": 0,
        "missing": 0,
        "present": 4,
        "shasum_matches": 4
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": false,
          "route_source_logged_or_topology_detected": false
        },
        "conformance_pct": 0.0,
        "files_checked": [
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "pending"
      },
      "repo": "/Users/josh/Developer/vrtx",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    },
    {
      "divergence_findings": [],
      "doctrine_propagation": {
        "conformance_pct": 0.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": false
          }
        ],
        "present": 0
      },
      "memory_pins": {
        "conformance_pct": 0.0,
        "exists": false,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-terratitle/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": false
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": false
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": false
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": false
          }
        ],
        "present": 0
      },
      "orch": "terratitle",
      "overall_conformance_pct": 1.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 1.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "status": "match",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": true,
            "sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "status": "match",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": true,
            "sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "status": "match",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": true,
            "sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "status": "match",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [],
        "mismatches": 0,
        "missing": 0,
        "present": 4,
        "shasum_matches": 4
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": false,
          "route_source_logged_or_topology_detected": false
        },
        "conformance_pct": 0.0,
        "files_checked": [
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "pending"
      },
      "repo": "/Users/josh/Developer/terratitle",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    },
    {
      "divergence_findings": [],
      "doctrine_propagation": {
        "conformance_pct": 0.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": false
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": false
          }
        ],
        "present": 0
      },
      "memory_pins": {
        "conformance_pct": 0.5,
        "exists": true,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-skillos/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": false
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": true
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": true
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": false
          }
        ],
        "present": 2
      },
      "orch": "skillos",
      "overall_conformance_pct": 1.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 1.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "status": "match",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": true,
            "sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "status": "match",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": true,
            "sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "status": "match",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": true,
            "sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "status": "match",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [],
        "mismatches": 0,
        "missing": 0,
        "present": 4,
        "shasum_matches": 4
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": true,
          "route_source_logged_or_topology_detected": true
        },
        "conformance_pct": 1.0,
        "files_checked": [
          ".flywheel/scripts/dispatch.sh",
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "integrated"
      },
      "repo": "/Users/josh/Developer/skillos",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    },
    {
      "divergence_findings": [
        {
          "class": "shasum_mismatch_unattributed",
          "file": ".flywheel/scripts/codex-goal-activate.sh",
          "orch": "flywheel",
          "severity": "gap"
        },
        {
          "class": "file_missing",
          "file": ".flywheel/scripts/pane-work-signal-classify.sh",
          "orch": "flywheel",
          "severity": "gap"
        },
        {
          "class": "file_missing",
          "file": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
          "orch": "flywheel",
          "severity": "gap"
        },
        {
          "class": "file_missing",
          "file": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
          "orch": "flywheel",
          "severity": "gap"
        }
      ],
      "doctrine_propagation": {
        "conformance_pct": 1.0,
        "expected": 5,
        "files": [
          {
            "path": ".flywheel/doctrine/auto-push-blocked-worker-discipline.md",
            "present": true
          },
          {
            "path": ".flywheel/doctrine/dcg-worker-freeze-discipline.md",
            "present": true
          },
          {
            "path": ".flywheel/doctrine/dry-run-apply-parity-contract.md",
            "present": true
          },
          {
            "path": ".flywheel/doctrine/runtime-doctrine-separation-discipline.md",
            "present": true
          },
          {
            "path": ".flywheel/doctrine/repo-hygiene-tick-discipline.md",
            "present": true
          }
        ],
        "present": 5
      },
      "memory_pins": {
        "conformance_pct": 1.0,
        "exists": true,
        "expected": 4,
        "path": "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md",
        "pins": [
          {
            "pin": "feedback_goal_mode_is_codex_usage_limit_workaround",
            "present": true
          },
          {
            "pin": "feedback_codex_goal_mode_runtime_enforcement",
            "present": true
          },
          {
            "pin": "feedback_auto_push_blocked_worker_abandonment",
            "present": true
          },
          {
            "pin": "feedback_dry_run_apply_parity_contract",
            "present": true
          }
        ],
        "present": 4
      },
      "orch": "flywheel",
      "overall_conformance_pct": 0.0,
      "phase_a_files": {
        "allowed_divergences": 0,
        "canonical_missing": 0,
        "conformance_pct": 0.0,
        "expected": 4,
        "files": [
          {
            "canonical_sha256": "c8a6b066cc0ec9c2c125893cf65050be86ab359c012436fb15f2a556478ccd64",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/codex-goal-activate.sh",
            "id": "codex-goal-activate",
            "present": true,
            "sha256": "4a8b4ff0ecb349aa0b3fdee90a8e2dc88b45ea55484f2b667211153c220a0f18",
            "status": "mismatch_unattributed",
            "target_path": ".flywheel/scripts/codex-goal-activate.sh"
          },
          {
            "canonical_sha256": "b2e1c784f111dc400e87ce74c5047ead787414bbf2f7f4eb1288a6ac40f5a3b0",
            "divergence_attributed": false,
            "expected_path": ".flywheel/scripts/pane-work-signal-classify.sh",
            "id": "pane-work-signal-classify",
            "present": false,
            "sha256": null,
            "status": "missing",
            "target_path": ".flywheel/scripts/pane-work-signal-classify.sh"
          },
          {
            "canonical_sha256": "9eea41c0ace611e79e5bbee4a868a194e56dc364fe779ad04f691960ab0c8469",
            "divergence_attributed": false,
            "expected_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "id": "pane-work-signal-taxonomy-v0.2",
            "present": false,
            "sha256": null,
            "status": "missing",
            "target_path": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md"
          },
          {
            "canonical_sha256": "d47a141551e9de04a87ea176a97adbafd3d4a30d405248916d5ab1cd30b796cc",
            "divergence_attributed": false,
            "expected_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "id": "codex-goal-mode-discipline",
            "present": false,
            "sha256": null,
            "status": "missing",
            "target_path": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md"
          }
        ],
        "findings": [
          {
            "class": "shasum_mismatch_unattributed",
            "file": ".flywheel/scripts/codex-goal-activate.sh",
            "orch": "flywheel",
            "severity": "gap"
          },
          {
            "class": "file_missing",
            "file": ".flywheel/scripts/pane-work-signal-classify.sh",
            "orch": "flywheel",
            "severity": "gap"
          },
          {
            "class": "file_missing",
            "file": ".flywheel/specs/pane-work-signal-taxonomy-v0.2.md",
            "orch": "flywheel",
            "severity": "gap"
          },
          {
            "class": "file_missing",
            "file": ".flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md",
            "orch": "flywheel",
            "severity": "gap"
          }
        ],
        "mismatches": 1,
        "missing": 3,
        "present": 1,
        "shasum_matches": 0
      },
      "phase_b_dispatcher_integration": {
        "checks": {
          "codex_goal_activation_route": false,
          "route_source_logged_or_topology_detected": false
        },
        "conformance_pct": 0.0,
        "files_checked": [
          ".flywheel/scripts/dispatch-template.md",
          ".flywheel/GOAL.md",
          "AGENTS.md"
        ],
        "status": "pending"
      },
      "repo": "/Users/josh/Developer/flywheel",
      "repo_exists": true,
      "schema_version": "phase-c-fleet-validation/v1",
      "ts": "2026-05-20T06:44:38Z"
    }
  ],
  "schema_version": "phase-c-fleet-validation/v1",
  "ts": "2026-05-20T06:44:38Z"
}
```
