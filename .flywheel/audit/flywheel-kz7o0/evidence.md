---
title: fleet-comms-health-probe.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
bead: flywheel-kz7o0
task: flywheel-kz7o0-b8d14c
priority: P0
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent: flywheel-ok1sk (jloib wave-1; sub-bead 5 of 17)
sister_exemplars: 0pkcf=985, ou656=985, lrdum=985, gbfpo=985 (avg 985)
---

# Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/fleet-comms-health-probe.sh` |
| Lines (before) | 673 |
| Lines (after) | 1162 |
| Pre status | canonical_cli_scoping=missing |
| Post status | canonical_cli_scoping=passing |
| Verb collisions | NONE |

## Acceptance gates

| Gate | Result |
|---|---|
| AG1: 18 TODO replaced | ✓ |
| AG2: bash -n exits 0 | ✓ |
| AG3: lint exits 0 | ✓ 0 violations |
| AG4: tests >= 13 | ✓ 19/19 |
| AG5a: doctor 7+ named probes | ✓ python3, jq, repo_root, loops_dir, agent_mail_state_dir, ntm, audit_log_dir |
| AG5b: health binds audit log | ✓ |
| AG5c: repair scope-specific | ✓ 2 scopes |
| AG5d: validate per-subject | ✓ 3 subjects (session-topology-row, ledger-path, audit-row) |
| AG5e: audit cli_emit_audit_tail | ✓ |
| AG5f: why provenance | ✓ |

## Domain-specific fillin highlights

- **Doctor probes the load-bearing trio:** python3 (heredoc interpreter) + ntm (the comms primitive) + agent_mail_state_dir (the per-agent token + session-token dir)
- **`validate session-topology-row`**: enforces JSONL row contract with 4 required fields (`session`, `orchestrator_pane`, `orchestrator_kind`, `effective_at`) — the canonical session-topology shape per session-topology-ledger/v1
- **`validate ledger-path`**: 2-layer enforcement (under `~/.local/state/flywheel/` AND `.jsonl` extension) with distinct reason codes — tests 16+17 verify both rejection paths
- 7 doctor probes is one more than typical (the fleet-comms-health domain has more substrate dependencies than pure indexers)

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/fleet-comms-health-probe.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/fleet-comms-health-probe.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/fleet-comms-health-probe.sh \
  && bash tests/fleet-comms-health-probe-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```
