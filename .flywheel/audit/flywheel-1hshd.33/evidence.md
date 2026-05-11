# Evidence: flywheel-1hshd.33 — fuckup-coverage-join.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.33 (P2, wave-4-general-33) | **Task ID**: flywheel-1hshd.33-99be7d | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/fuckup-coverage-join.sh` (joins fuckup classes to 5 routing layers)
**Variant**: PARTIAL-BYPASS — native owns --schema (custom joins/output_fields shape); scaffold owns --info/--examples + all verbs.

## Per-flag baseline + variant

| Flag/verb       | Native | Owner |
|-----------------|--------|-------|
| --schema        | YES (joins+output_fields) | NATIVE |
| --info/--examples | NO | SCAFFOLD |
| verbs           | NO | SCAFFOLD |
| --json/--self-test/--repo/--log/--memory-dir/--limit | YES | NATIVE (fall-through) |

## Doctor probes (7)

bash, jq, fuckup_log_readable (load-bearing — join input), memory_dir, incidents_md, canonical_l_rule_dir, audit_log_dir.

## Repair scopes (3)

audit_log_dir, memory_dir, fuckup_log_dir.

## Validate subjects (3)

- **fuckup-class**: `^[a-z][a-z0-9_]*$` (snake_case canonical fuckup_class shape)
- **join-layer**: enum {memory, incident, canonical_l_rule, probe, dashboard} — cross-sources native --schema .joins[] (5 layers)
- **limit**: integer in [1, 10000] cross-sources native --limit flag

5-layer cross-source enum is the WIDEST native-flags-to-enum projection this session (N=5 recurrence; META-RULE already promoted at N=3).

## Test coverage

19/19 PASS. Test 15 verifies 5-layer enum full sweep.

## Lint

Clean.

## Mission fitness

`adjacent` — fuckup-coverage-join is the substrate that maps detected fuckup classes to durable routing (memory, INCIDENTS, canonical L-rules, probes, dashboard). Without uniform machine-readable surfaces, orchestrators can't introspect which join layers are healthy. Scaffold adds uniform doctor/validate/health/repair while preserving the native --schema joins+output_fields contract for legacy consumers.

## Files changed

- `.flywheel/scripts/fuckup-coverage-join.sh` (192 → ~700 lines)
- `tests/fuckup-coverage-join-canonical-cli.sh` (94 → ~175 lines)

## L112 verify probe

`bash tests/fuckup-coverage-join-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
