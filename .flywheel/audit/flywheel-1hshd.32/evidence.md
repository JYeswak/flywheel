# Evidence: flywheel-1hshd.32 — frozen-pane-detector.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.32 (P2, wave-4-general-32) | **Task ID**: flywheel-1hshd.32-cb2e71 | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/frozen-pane-detector.sh`
**Variant**: PARTIAL-BYPASS (4-flag bypass — widest this session)

## Per-flag baseline

| Flag/verb       | Native pre-scaffold? | Owner after scaffold |
|-----------------|----------------------|----------------------|
| --info          | YES (v2 envelope w/ mode + native_surface) | NATIVE |
| --schema        | YES (v2 envelope w/ properties) | NATIVE |
| --doctor        | YES (v2 envelope w/ source_health + mode) | NATIVE |
| --health        | YES (same shape as --doctor) | NATIVE |
| --examples      | NO (printed usage only) | SCAFFOLD |
| doctor/health verb | NO | SCAFFOLD (independent surface from native flags) |
| repair/validate/audit/why/quickstart | NO | SCAFFOLD |
| --session/--auto-recover/--apply/--dry-run/--json | YES | NATIVE (fall-through) |

**Variant feature**: 4 native flags bypassed (widest PARTIAL-BYPASS this session — previous max was 2 in 1hshd.25 docs-validation-probe). Both --doctor and --health route to the SAME native handler (legacy v2 contract). Scaffold doctor/health verbs are INDEPENDENT surfaces (different envelope shape, different probes) that coexist alongside native flag forms.

## Doctor probes (5)

bash, jq, tmux, ntm_executable (load-bearing — wraps ntm grep/errors/activity/wait), audit_log_dir.

## Repair scopes (2)

audit_log_dir, ntm_state_dir. Apply needs --idempotency-key.

## Validate subjects (3)

- **session-name**: `^[a-z][a-z0-9_-]*$` (matches native --session shape)
- **recovery-mode**: enum {report_only, auto_recover} — cross-sources native --auto-recover flag (4th N-recurrence of native-flags-to-enum projection META-RULE)
- **ntm-bin**: -x file check (load-bearing dependency)

## Test coverage

19/19 PASS. Test 18 verifies PARTIAL-BYPASS native --doctor + --health both still emit legacy v2 envelopes. Test 19 verifies 4-direction fidelity (scaffold + native paths coexist).

## Lint

Clean (script already had `set -euo pipefail`).

## Mission fitness

`adjacent` — frozen-pane-detector is the canonical primitive for detecting stuck codex/ntm panes (wraps ntm grep/errors/activity/wait). Canonical-CLI scaffold gives uniform machine-readable surfaces while preserving the full native v2 detection contract.

## Skill recurrence

- `native-flags-to-validate-enum projection` — N=4 this session (recovery-mode from native --auto-recover). META-RULE already promoted at N=3.

## Files changed

- `.flywheel/scripts/frozen-pane-detector.sh` (86 → ~570 lines)
- `tests/frozen-pane-detector-canonical-cli.sh` (94 → ~175 lines)

## L112 verify probe

`bash tests/frozen-pane-detector-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
