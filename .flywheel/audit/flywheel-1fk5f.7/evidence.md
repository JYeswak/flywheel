---
title: ntm-fleet-health — substantive 18-TODO fillin
type: evidence
bead: flywheel-1fk5f.7
task: flywheel-1fk5f.7-d9c2a4
parent: flywheel-1fk5f (wave-2 fillin parent)
sister_chain: 1fk5f.1 (1000), .2 (950), .3 (960), .5 (960)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for ntm-fleet-health.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | grep = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — canonical-cli scaffold-test 13/13 (now 19/19) | 19/19 PASS | `canonical-cli-test-run.txt` |
| AG5 — concrete subcommand outputs | doctor 12 named probes; validate ntm-bin self-tested exec+health | `smoke-*.json` |

## What got filled in

### `doctor` (smoke-doctor.json) — 12 substrate checks
- **wrapped binary**: ntm_executable
- **lib**: jsonl_append_lib_readable
- **inputs**: topology_file_readable
- **mutable substrate**: out_file_dir_writable, lock_file_dir_writable
- **deps (4)**: jq, mktemp, grep, awk
- **infra**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded

### `validate` (smoke-validate-ntm-bin.json)
Two subjects:
- `ntm-bin` — verifies `ntm` is executable AND `ntm --help` advertises a `health` subcommand (the wrapper's load-bearing delegate). Returns exec_ok + health_subcommand_ok + missing[].
- `audit-row JSONL_LINE` — standard ts+status check.

The ntm-bin validator self-tested against the real ntm binary and returned
`exec_ok=true, health_subcommand_ok=true` — meaningful confirmation that the
downstream binary has the subcommand the wrapper invokes.

### Other subcommands
Standard wgitr-chain: health/repair/audit/why follow the established pattern.

## Ledger integration (emit hook)

The legacy main is a single while-loop processing sessions, with `emit()` as the
universal output point per iteration. Hooked `cli_audit_append` INSIDE `emit()`
(matches the emit_json hook pattern from 1fk5f.5), so every fleet-health probe
lands an audit row with threshold + restart fields. Apply-spec point 10
satisfied for emit-loop surfaces.

## Test scaffold extension (apply-spec point 11)

Tests 16-19: doctor concrete checks, doctor probes ntm_executable, repair --apply
isolated TMP, validate audit-row well-formed.

## Mission fitness

Class: `direct`. Fleet-health is the substrate watcher that surfaces stuck panes
to orchestrators. Without it, orchestrators discover stuck workers via callback
storm rather than proactive probe. Direct work on continuous-orchestrator-uptime.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching wave-2 chain
- **Sniff**: 10/10 — every subcommand smoked; emit hook ensures audit log accretes; validate ntm-bin confirms downstream health subcommand
- **Jeff**: 9/10 — 2-file edit; legacy emit/main preserved
- **Public**: 9/10 — three judges check passes

## L112 verify probe

```bash
bash /Users/josh/Developer/flywheel/.flywheel/scripts/ntm-fleet-health.sh doctor --json | jq -r '.status'
# expected: pass
```
