---
title: ntm-approve-human-gates — substantive 18-TODO fillin
type: evidence
bead: flywheel-1fk5f.5
task: flywheel-1fk5f.5-4880c4
parent: flywheel-1fk5f (wave-2 fillin parent)
sister_chain: flywheel-1fk5f.1 (1000/1000), flywheel-1fk5f.2 (950/1000), …
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for ntm-approve-human-gates.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | `grep -c 'TODO(canonical-cli-scaffold)'` = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — canonical-cli scaffold-test 13/13 (now 19/19) | 19/19 PASS | `canonical-cli-test-run.txt` |
| AG5 — concrete subcommand outputs | doctor 9 named probes; 6/6 substantive | `smoke-*.json` |

Test scaffold extended from 15→19 per apply-spec point 11.

## What got filled in

### `doctor` (smoke-doctor.json) — 9 substrate checks
- **wrapped binary**: ntm_executable (the binary the wrapper proxies)
- **deps (4)**: jq, mktemp, grep, awk
- **infra**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded
- **wrapper-namespace assertion** (load-bearing): SCAFFOLD_WRAPPER_NS matches surface name (guards against script-rename drift)

### `health` / `repair` / `audit` / `why`
Standard wgitr-chain patterns.

### `validate` (smoke-validate-audit-row.json)
Two subjects:
- `approval-receipt PATH` — verifies required fields (gate, question, decision, approver, ts) per the wrapper's
  approval-receipt contract. Returns missing[] for any unmet field.
- `audit-row JSONL_LINE` — standard ts+status check.

### `--schema <surface>` + topic_help
Per-surface field documentation for all 6 subcommands.

## Ledger integration (legacy hook)

The legacy `cmd_check` flow terminates via `emit_json` (which `exit`s after emitting the
canonical envelope). Hooked `cli_audit_append` INSIDE `emit_json` (before its return) so
every wrapper invocation lands in `$SCAFFOLD_AUDIT_LOG` with gate/subcommand/decision
fields. That's the apply-spec point-10 "cmd_run wiring" applied to a surface where the
legacy main bypasses cmd_run entirely (the wrapper has its own main + parse_args).

## Test scaffold extension (apply-spec point 11)

Tests 16-19 added:
- 16: doctor returns ≥5 concrete checks
- 17: doctor probes wrapper_namespace_assertion (load-bearing for this surface)
- 18: repair --apply --idem-key writes audit-log row (isolated TMP)
- 19: validate audit-row accepts well-formed row

## Mission fitness

Class: `direct`. The wrapper preserves exact human approval questions and validates
approval receipts — load-bearing for the human-in-the-loop boundary that bounds
agent autonomy. Direct work on continuous-orchestrator-uptime-with-human-gating.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching wave-2 chain
- **Sniff**: 10/10 — every subcommand smoked end-to-end; emit_json hook ensures audit log accretes; wrapper-namespace assertion guards against rename drift
- **Jeff**: 9/10 — script + sister test edits honored; legacy `check` semantics preserved (still routes through main case statement)
- **Public**: 9/10 — three judges check passes

## L112 verify probe

```bash
bash /Users/josh/Developer/flywheel/.flywheel/scripts/ntm-approve-human-gates.sh doctor --json | jq -r '.status'
# expected: pass
```
