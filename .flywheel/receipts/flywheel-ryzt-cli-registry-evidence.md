---
schema_version: flywheel-cli-registry-evidence/v1
contract_version: flywheel-cli-registry/v1
receipt_schema_version: four-lens-close-validator/v1
---

# flywheel-ryzt CLI registry evidence

task_id: flywheel-ryzt
bead: flywheel-ryzt
did=8/8 didnt=none gaps=none tests=PASS
socraticode_queries=6
indexed_chunks_observed=60

## Acceptance gates

| gate | result | evidence |
|---|---|---|
| Enumerate representative help surfaces | PASS | Captured current `--help` output for `tmp-prune.sh`, `storage-prune.sh`, `agent-mail-fd-pressure-check.sh`, `agent-mail-fd-doctor.sh`, `agent-mail-restart.sh`, `close-validator-contract-probe.sh`, `br-create-validated.sh`, and `caam-recovery-path-probe.sh`. |
| Add canonical registry | PASS | `.flywheel/cli-registry.json` declares name, path, lane, owner, schema id, summary, usage, args, examples, output formats, exit codes, and notes for 9 CLI surfaces. |
| Add registry emitter | PASS | `.flywheel/scripts/cli-registry-emit.sh` emits `help`, `info`, `examples`, and `schema` from `.flywheel/cli-registry.json`. |
| Refactor one script | PASS | `.flywheel/scripts/tmp-prune.sh` now serves `--help` through the registry emitter with a local fallback for older template copies. |
| Add round-trip fixture | PASS | `tests/test_cli_registry_emit.sh` proves registry schema shape, registered path existence, missing-surface refusal, and byte-for-byte `tmp-prune.sh --help` round-trip. |
| Document source of truth | PASS | `.flywheel/canonical-paths.txt` now names `flywheel_cli_registry`, `flywheel_cli_registry_emitter`, and `flywheel_cli_registry_tests`. |
| Preserve existing behavior | PASS | `tests/test-tmp-prune.sh` still passes 14 checks after the help refactor. |
| Joshua lens applied | PASS | CLI help drift is the silent operator trap: 25-year operations-manager judgment says every undocumented flag is tomorrow's runbook gap; the registry is the runbook source and survives turnover better than copied usage strings. |

## Files changed

- `.flywheel/cli-registry.json`
- `.flywheel/scripts/cli-registry-emit.sh`
- `.flywheel/scripts/tmp-prune.sh`
- `tests/test_cli_registry_emit.sh`
- `.flywheel/canonical-paths.txt`
- `.flywheel/receipts/flywheel-ryzt-cli-registry-evidence.md`

## Commands run

```bash
jq empty .flywheel/cli-registry.json
# PASS

bash -n .flywheel/scripts/cli-registry-emit.sh .flywheel/scripts/tmp-prune.sh tests/test_cli_registry_emit.sh
# PASS

bash tests/test_cli_registry_emit.sh
# SUMMARY pass=22 fail=0

bash tests/test-tmp-prune.sh
# PASS: 14 checks

.flywheel/scripts/cli-registry-emit.sh tmp-prune.sh --mode help
# emitted canonical help from .flywheel/cli-registry.json

.flywheel/scripts/tmp-prune.sh --help
# byte-for-byte match with registry-emitted help
```

## Four-Lens Self-Grade

Brand voice: PASS. This is a small substrate improvement with plain names and explicit ownership. The registry makes flywheel CLI surfaces read as Joshua's operating system instead of anonymous shell helpers.

Sniff / Three Judges: PASS. Jeffrey can inspect one JSON contract and one emitter instead of hunting copied `usage()` strings. Donella sees an information-flow repair: docs, examples, schema IDs, and ownership now move from one stock. Joshua sees the operator-experience pattern: CLI help drift burns team attention during runbooks, and the registry reduces that daily execution cost.

Jeff doctrine: PASS. The contract is versioned as `flywheel-cli-registry/v1`, paths are concrete, output formats are named, and the fixture proves the registry-to-help path.

Public publishability: PASS. A public reviewer could fork this pattern because it is inspectable: one registry, one emitter, one migrated script, one round-trip test, and one canonical-path receipt. Outcome: future CLI help/examples/schema docs can derive from one source rather than drifting across scripts.
