# Evidence: flywheel-1hshd.36 — hub-blocker-detect.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.36 | **Task ID**: flywheel-1hshd.36-124dec | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/hub-blocker-detect.sh` (detects hub blockers — beads blocking >N parent closures)
**Variant**: SELECTIVE-VERB-BYPASS — native owns rich --info envelope + doctor/check verbs (legacy hub-blocker-detect/v1 contract with hub_blocker_count/signal/dashboard_line/operator_lens) + --examples. Scaffold owns --schema (native lacked) + health/repair/validate/audit/why/quickstart/help.

## Per-flag baseline + variant

| Flag/verb       | Native pre-scaffold? | Owner after scaffold |
|-----------------|----------------------|----------------------|
| --info          | YES (rich v1) | NATIVE |
| --schema        | NO (unknown_arg) | SCAFFOLD |
| --examples      | YES (text) | NATIVE |
| doctor verb     | YES (legacy contract) | NATIVE (SELECTIVE-VERB-BYPASS) |
| check verb      | YES | NATIVE |
| health/repair/validate/audit/why/quickstart | NO | SCAFFOLD |
| --repo/--threshold/--apply/--idempotency-key/--json | YES | NATIVE |

## Doctor probes (delegated to native)

Native emits: hub_blocker_count, max_parent_block_count, top_hub_blocker_id, top_parent_ids, promoted_count, fuckup_log_count, signal {GREEN/YELLOW/RED}, dashboard_line, operator_lens. Scaffold's doctor verb is dead code (intercept short-circuits to native); `scaffold_cmd_doctor` emits delegation envelope only.

## Repair scopes (2)

audit_log_dir, beads_dir.

## Validate subjects (3)

- **threshold**: int [1, 100]; default 3 — cross-sources native --threshold flag (**N=7** of native-flags-to-enum projection)
- **bead-id**: `^[a-z][a-z0-9]+-[a-z0-9.]+$`
- **signal**: enum {GREEN, YELLOW, RED} — cross-sources native doctor .signal output

## Test coverage

19/19 PASS. Test 14 verifies SELECTIVE-VERB-BYPASS native doctor preserved. Test 15 signal full-enum sweep.

## Lint

Clean after bonus L4 short-circuit fix (`json_bool` helper: replaced `[[ ]] && X || Y` with explicit `if/then/else/fi`).

## Mission fitness

`adjacent` — hub-blocker-detect surfaces the "one child blocks N parents" ops-manager bottleneck signal. Adding scaffold validate (threshold/bead-id/signal) gives uniform machine-readable validation while preserving the rich native --info envelope + doctor verb legacy contract.

## Skill recurrence

- `native-flags-to-validate-enum projection` — N=7 (threshold from --threshold + signal from doctor .signal). META-RULE promoted at N=3.
- `SELECTIVE-VERB-BYPASS at full verb level` (vs sub-arg level in 1hshd.27 fleet-coherence-launchd) — variant catalog now has both sub-arg and full-verb forms.

## Files changed

- `.flywheel/scripts/hub-blocker-detect.sh` (356 → ~840 lines + L4 json_bool fix)
- `tests/hub-blocker-detect-canonical-cli.sh` (94 → ~180 lines)

## L112 verify probe

`bash tests/hub-blocker-detect-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
