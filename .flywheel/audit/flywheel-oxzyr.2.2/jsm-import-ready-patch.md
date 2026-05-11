# JSM-Import-Ready Patch — flywheel-oxzyr.2.2

**Target:** `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop`
**Patch type:** `jsm-import-ready` (`.flywheel` skill is unmanaged)
**Operation:** add `_flywheel_loop_doctor_undo()` function (190 lines) + add `doctor undo` intercept in native dispatcher (8 lines)
**Source bead:** `flywheel-oxzyr.2.2`
**Sister:** chokepoint foundation at `flywheel-oxzyr.2.1`

## What this patch ships

### 1. Native dispatcher intercept

Inserted in the `doctor)` case (native code post-line-505 scaffold-end):

```bash
doctor)
    shift
    # flywheel-oxzyr.2.2: intercept `doctor undo <run-id>` before delegating
    if [[ "${1:-}" == "undo" ]]; then
        shift
        _flywheel_loop_doctor_undo "$@"
        exit $?
    fi
    portable_doctor "$@"
    exit $? ;;
```

### 2. `_flywheel_loop_doctor_undo()` function

Added to the chokepoint module block (between `_flywheel_loop_mutate()` end and END marker).

~190 lines covering:
- Surface: `<run-id> [--dry-run|--apply] [--json] [--help]`
- Backup chain walk: reads `intent.jsonl` + matches `applied.jsonl` for pre_sha
- Byte-exact restore: `cp -p <backup> <target>` + post-restore SHA verification
- LIFO iteration (most recent mutation first via `tac` / `tail -r`)
- dry_run vs apply modes
- doctor-undo/v1 schema output
- Exit codes: 0/1/2/3/4

## Verification post-patch (validated live)

```
bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop: OK
flywheel-loop --help: OK (canonical CLI surface intact)
flywheel-loop doctor undo --help: OK (subcommand help works)

End-to-end round-trip:
  1. Setup: TEST_FILE with content; ORIGINAL_SHA=43e345...
  2. _flywheel_loop_mutate file_write ...: post-mutation POST_SHA=874cfd...
  3. flywheel-loop doctor undo restoretest-001 --dry-run --json: planned mode, no mutation
  4. flywheel-loop doctor undo restoretest-001 --apply --json: status=restored
  5. shasum -a 256 TEST_FILE: RESTORED_SHA=43e345...
  6. [ ORIGINAL_SHA = RESTORED_SHA ]: BYTE-EXACT RESTORE VERIFIED ✓
```

## File-length receipt

Pre-patch: 953 lines (.2.1 baseline)
Post-patch: 1147 lines
Delta: +194 lines (intercept + function + provenance comments)
Threshold: 1000 lines is a soft guideline; binary now intentionally exceeds for the substrate-doctor mechanism. Allowed-large receipt: this is a dispatcher script + native logic + scaffold + chokepoint module; the size growth tracks scaffold-doctor capability expansion per oxzyr.2 wave.

## JSM management state

`.flywheel` skill UNMANAGED per `jsm list`. Direct mutation allowed + this paired patch artifact provided for future JSM import.

`no_direct_skill_mutation_reason=skill_unmanaged_direct_mutation_allowed_with_paired_jsm_import_ready_patch_artifact_written`

## Sister-bead progressive unblocks

| Sub-bead | Status post-.2.2 |
|---|---|
| oxzyr.2.1 (chokepoint) | ✓ shipped |
| oxzyr.2.2 (doctor undo) | ✓ THIS BEAD shipped |
| oxzyr.2.3 (FM-5 + FM-10 audit-only) | UNBLOCKED |
| oxzyr.2.4 (FM-6 + FM-9 byte-exact undo) | **FULLY UNBLOCKED** (was partial; both .2.1 + .2.2 now ship) |
| oxzyr.2.5 (FM-8 input-deaf quarantine) | UNBLOCKED |
| oxzyr.2.6 (real fixture data + round-trip tests) | **FULLY UNBLOCKED** (round-trip test pattern now exercisable end-to-end with apply mode) |

The two foundation pieces (chokepoint + undo) ship the byte-exact-undo-of-mutation contract. The remaining .2.3-.2.6 sub-beads can now build FM-specific invariants on top.

## Canonical-CLI compliance

`flywheel-loop doctor undo` surfaces:
- `--help` / `-h` (usage)
- `--dry-run` (default; planning mode)
- `--apply` (mutation mode)
- `--json` (machine-readable output)
- Stable exit codes (0/1/2/3/4)
- Schema `doctor-undo/v1` declared in output

Per canonical-cli-scoping triad: doctor/health/repair (already present in flywheel-loop scaffold); validate/audit/why (present in scaffold); --json + dry-run/apply mutation discipline (✓ this patch).

`cli_canonical=yes`
