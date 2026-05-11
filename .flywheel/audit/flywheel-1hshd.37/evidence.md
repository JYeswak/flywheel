# Evidence: flywheel-1hshd.37 — idempotency-replay-guard.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.37 | **Task ID**: flywheel-1hshd.37-617108 | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/idempotency-replay-guard.sh` (dispatch replay-guard via sha256 input hash → lock file + ledger)
**Variant**: PARTIAL-BYPASS — native owns rich --info envelope (info/v1 with statuses array + output_schema field) + rich --examples envelope (examples/v1). Scaffold owns --schema (native lacked) + all verbs.

## Per-flag baseline + variant

| Flag/verb | Native | Owner |
|-----------|--------|-------|
| --info    | YES (rich info/v1 envelope) | NATIVE |
| --schema  | NO | SCAFFOLD |
| --examples | YES (rich examples/v1 envelope) | NATIVE |
| verbs (doctor/health/repair/validate/audit/why/quickstart) | NO | SCAFFOLD |
| --input/--input-file/--ledger/--lock-dir/--json/--quiet/--mark-completed/--release-lock/--receipt-ref | YES | NATIVE |

## Doctor probes (7)

bash, jq, sha256_hasher (load-bearing — input → replay-key derivation), flock (warn on macOS), ledger_dir, lock_dir, audit_log_dir.

## Repair scopes (3)

audit_log_dir, ledger_dir (~/.local/state/flywheel/), lock_dir (~/.local/state/flywheel/idempotency-replay-locks).

## Validate subjects (3)

- **status**: enum {already_completed, in_flight, not_seen, completed} — cross-sources native --info .statuses[] (**N=8** of native-flags-to-enum projection)
- **receipt-ref**: length [4, 256] + pattern `^[A-Za-z0-9._/#:-]+$` (split into length + pattern checks; bash regex doesn't support {N,M} repetition)
- **input-mode**: enum {text, file, stdin} — cross-sources native --input/--input-file flag contract

## Test coverage

19/19 PASS. Test 15 verifies full-enum sweep + cross-source.

## Lint

Clean.

## Skill discovery

- **bash-regex-{N,M}-fix**: bash `=~` operator does NOT support `{N,M}` repetition syntax. Pivot to `(( length >= N && length <= M )) && [[ pattern_without_repetition ]]` two-check approach. 1st application this session.

## Mission fitness

`adjacent` — idempotency-replay-guard is the canonical primitive for preventing duplicate dispatch execution via sha256 input hash → ledger + lock_dir. Critical substrate; scaffold gives uniform machine-readable validation surface (status enum cross-sourcing native info, receipt-ref shape, input-mode enum cross-sourcing native flags) while preserving the full native --info/--examples rich JSON contracts.

## Files changed

- `.flywheel/scripts/idempotency-replay-guard.sh` (200 → ~680 lines)
- `tests/idempotency-replay-guard-canonical-cli.sh` (94 → ~180 lines)

## L112 verify probe

`bash tests/idempotency-replay-guard-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
