# FM-6: legacy loop-config schema drift

**Class:** byte-exact-undo (Shape A substrate-without-version-probe)
**Test mode:** RUN+UNDO — `flywheel-loop doctor fm6 --target <PATH> --apply` + `doctor undo <run-id>` (.2.4 ship)
**MEMORY source:** `feedback_loop_state_without_driver.md`

## Detect predicate
- Parse target JSON
- Required keys: `project`, `repo`, `active`
- Allowlist beyond required (canonical optional keys): `tier`, `interval`, `started_at`, ... `_unknown_keys_archive`
- DRIFTED if: any unknown key OR any required key missing
- drift_class ∈ {`unknown_keys`, `missing_required`, `unknown_keys_and_missing_required`, `malformed_json`, `none`}

## Fix strategy (byte-exact undo via chokepoint)
- Build migrated JSON: strip unknown keys, archive under `_unknown_keys_archive`, fill missing required with `null`
- Write via `_flywheel_loop_mutate file_write` (chokepoint records intent → SHA-256 pre-state backup → mutate → applied receipt)
- `doctor undo <run-id>` restores byte-exact original via `cp -p <backup> <target>`

## Round-trip protocol
1. Copy `corrupt-v0-config.json` to scratch
2. Capture pre_sha (sha-256 of scratch file)
3. `flywheel-loop doctor fm6 --target <scratch> --apply --run-id <RUN_ID> --json` → expect rc=1, drift_class=unknown_keys, backup_written=true
4. Verify scratch file is keys-equal to `expected-v1-migrated.json`
5. `flywheel-loop doctor undo <RUN_ID> --apply --json` → expect rc=0
6. Verify restored sha-256 == pre_sha (byte-exact round-trip)

## Fixture files
- `corrupt-v0-config.json` — config with 3 unknown keys (one with timestamp-in-key ad-hoc pattern)
- `expected-v1-migrated.json` — unknown keys archived under `_unknown_keys_archive`; keys jq-sorted
- `undo-original.bak` — byte-exact baseline (= corrupt; what `doctor undo` should restore to)
