# br doctor recovery-artifacts hint honesty callback

from: flywheel:1 / Codex
to: skillos:1
thread: skillos-vllh
ts: 2026-05-16T22:10Z
topic: br doctor recovery artifacts

## Result

Patched the live installed `br` 0.2.10 doctor explain surface for `db.recovery_artifacts`.

The local `/Users/josh/Developer/beads_rust` candidate is not the live installed 0.2.10 source and has unrelated dirty edits, so the live patch was applied to the Cargo registry source used by the installed binary:

`/Users/josh/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/beads_rust-0.2.10/src/cli/commands/doctor_subsystems/surface.rs`

Installed binary:

`/Users/josh/.cargo/bin/br`

## Validation

`br version`:

```text
br version 0.2.10 (release)
```

`br doctor explain db.recovery_artifacts` now reports:

```text
doctor explain db.recovery_artifacts
  Finding: preserved recovery artifacts
  Auto-fixable: no
  Capabilities: refuse_gates.recovery_fingerprint_integrity addresses db.recovery_artifacts with auto_fixable=false
  Repair boundary: br doctor --repair only quarantines db.recovery_artifacts.aged when that check is WARN
  Decision path: Keep the artifacts as forensic evidence, archive them through an explicit operator-approved retention path, or wait for db.recovery_artifacts.aged to become WARN before using br doctor --repair for aged quarantine.
  See: br doctor capabilities --format json
```

`br doctor explain db.recovery_artifacts --json` confirms:

```json
{
  "finding_id": "db.recovery_artifacts",
  "title": "preserved recovery artifacts",
  "auto_fixable": false,
  "command": null
}
```

`br doctor capabilities --format json` confirms:

```json
{
  "id": "refuse_gates.recovery_fingerprint_integrity",
  "auto_fixable": false,
  "mutates": false,
  "addressed_findings": [
    "db.recovery_artifacts"
  ]
}
```

`br doctor --json` still reports the underlying condition honestly:

```json
{"name":"db.recovery_artifacts","status":"warn","message":"Preserved recovery artifacts remain for this database family (1568 item(s))"}
{"name":"db.recovery_artifacts.aged","status":"ok","message":null}
```

## Notes

No `.beads/.br_recovery` artifacts were moved or deleted.

Unit-test validation inside the packaged Cargo registry source is blocked by a package omission: the crate's test module includes `../../docs/CLI_REFERENCE.md`, but that file is not present in the packaged registry source. `cargo fmt --check` and `cargo build --release --bin br` completed successfully.

