# flywheel-1w0ep Compliance Report

The committed hook dispatcher and installer satisfy the B07 security-hook bead.
The implementation is intentionally scoped to the shared synthetic secret corpus
and emits only class/path/line metadata.

## Evidence

- `bash tests/security-precommit-hook.sh`: PASS, 11 checks.
- `bash tests/canary-secret-scan.sh`: PASS.
- `bash .flywheel/scripts/test-safe-probe.sh`: PASS.
- Dispatch template audit: PASS for `/tmp/dispatch_flywheel-1w0ep-aab242.md`.

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 9

The public lens includes the three-judges check: a skeptical operator gets
dry-run/apply behavior, a maintainer gets fixture coverage and scoped files,
and a future worker gets a receipt-backed compliance pack.
