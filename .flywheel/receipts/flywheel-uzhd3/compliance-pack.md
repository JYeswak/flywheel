# flywheel-uzhd3 Compliance Pack

Task: `flywheel-uzhd3-514838`

## Did

- Added L148 `PUBLIC-READY-DEFAULT` to `AGENTS.md`,
  `.flywheel/AGENTS-CANONICAL.md`, and `templates/flywheel-install/AGENTS.md`.
- Updated L89 language so private/internal status is metadata, not a
  ZestStream voice-gate exemption.
- Updated `.flywheel/scripts/publishability-bar.sh` so `Public repo: no` no
  longer short-circuits brand voice checks.
- Preserved explicit voice-gate bypasses for `EXEMPT_CLIENT_OWNED` and
  `EXEMPT_PUBLIC_FACING`.
- Updated `.flywheel/scripts/zeststream-public-prepublish-hook.sh` so public
  pushes enforce the publishability result regardless of current private
  hosting status.
- Added `publishability-bar.sh` and `zeststream-public-prepublish-hook.sh` to
  the canonical doctrine sync shared-script allowlist.
- Repaired pre-existing three-surface doctrine drift by adding missing L145 to
  `templates/flywheel-install/AGENTS.md`.
- Updated README command descriptions to name the public-ready default and
  explicit exemption taxonomy.

## Re-Audit Scope

`flywheel-sib04` read-only evidence shows the stale private/internal close
class applies to `flywheel-lzc6`, `flywheel-f3s7`, `flywheel-u1zd`,
`flywheel-1t8t`, and `flywheel-lzw7`. The client-owned class represented by
`flywheel-wrjv` remains an explicit exemption and should not be reopened as a
ZestStream voice failure.

`.beads/issues.jsonl` was released for sibling worker
`flywheel-sib04-3d6d8e` to perform the reopen/close br mutations without a
reservation conflict.

## Verification

- `bash -n` passed for:
  - `.flywheel/scripts/publishability-bar.sh`
  - `.flywheel/scripts/zeststream-public-prepublish-hook.sh`
  - `.flywheel/scripts/sync-canonical-doctrine.sh`
  - `tests/publishability-bar.sh`
  - `tests/zeststream-public-prepublish-hook.sh`
- `tests/publishability-bar.sh`: PASS.
- `tests/zeststream-public-prepublish-hook.sh`: PASS.
- `.flywheel/scripts/doctrine-3-surface-divergence-probe.sh --json`: PASS,
  `doctrine_3_surface_divergent_count=0`.
- `~/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target /Users/josh/Developer/flywheel --json`:
  PASS, `drift_count=0`.
- `AGENTS_MD_FLEET_LEDGER=/tmp/flywheel-uzhd3-agents-md-fleet-ledger.jsonl .flywheel/scripts/agents-md-fleet-propagator.sh --json --record-scan`:
  recorded source doctrine drift targets for the active propagator fleet
  (`repos_checked=8`, `fleet_doctrine_drift_count=8`).
- `SYNC_CANONICAL_LEDGER_DISABLE=1 .flywheel/scripts/sync-canonical-doctrine.sh --dry-run --json`:
  scanned doctrine sync cadence targets (`target_count=71`) and showed the two
  publishability scripts as planned shared-script propagation actions.

## Gaps

- `agents-md-fleet-propagator.sh --doctor --json` with the default large ledger
  failed with `jq: Argument list too long`; logged fuckup class
  `agents-md-fleet-propagator-ledger-arg-too-long`.
- Full fleet apply was not run in this worker. The cadence path is wired and
  dry-run evidence shows drift targets and script-copy actions.
