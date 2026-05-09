# flywheel-ruhcf-649f7b evidence

Bead: flywheel-ruhcf
Task: flywheel-ruhcf-649f7b
Identity: CloudyMill
Timestamp: 2026-05-09T00:38Z

## Disposition

`/Users/josh/.cargo/bin/bd` was quarantined to:

`/Users/josh/.cargo/bin/bd.quarantine.flywheel-ruhcf-649f7b`

No replacement shim was installed. The canonical CLI on PATH is still:

`/Users/josh/.cargo/bin/br`

## Ownership

Pre-quarantine:

- `command -v bd` resolved to `/Users/josh/.cargo/bin/bd`.
- `bd --version` returned `bd 0.1.26`.
- `cargo install --list` reported `beads-rs v0.1.26: bd`.
- `shasum -a 256 /Users/josh/.cargo/bin/bd` returned `340a91127660220cb3bc1c9c46311d9d50deb266ada304f96681d81dc5affc0c`.
- `command -v br-real` had no result.

Current:

- `command -v bd` has no result.
- `command -v br-real` has no result.
- `command -v br` resolves to `/Users/josh/.cargo/bin/br`.
- `br --version` returns `br 0.2.5`.

## Live Callsites

Runtime compatibility audit:

- `ntm/internal/bv/bv.go` `RunBd` executes `br`, not `bd`.
- `ntm/internal/tools/bd.go` resolves candidate binaries in order `br`, then `bd`; with `bd` absent, NTM still detects `br`.
- `.claude` hook matches for `bd` are text-pattern compatibility gates or inactive/archive code, not direct runtime invocations that require the PATH binary.
- `ntm/internal/supervisor/supervisor.go` retains comments/examples for a `bd` daemon health command, but no active `RunBrReal` or direct `exec.Command("bd", ...)` callsite was found in active NTM code.
- One existing process remains: PID 6793, `/Users/josh/.cargo/bin/bd daemon run`, cwd `/Users/josh/Developer/alpsinsurance`, socket `/Users/josh/.beads/daemon.sock`. The running process was not killed. After quarantine, `lsof` shows its text file as `/Users/josh/.cargo/bin/bd.quarantine.flywheel-ruhcf-649f7b`.

## Proof

Targeted T2.6 proof:

```text
PASS T2.6 bd and br-real absent from PATH
```

Full audit command:

```bash
bash tests/phase2-audit.sh
```

Full audit result:

```text
PASS T2.6 bd and br-real absent from PATH
PASS T2.7 RunBrReal not called in ntm/internal
Summary: 6/9 passed, 3 failed
```

The three full-audit failures were unrelated to this bead: T2.3 source_repo cleanup, T2.4 temporary source_repo normalization, and T2.8b runtime_handoff fixture constraint.

## Acceptance Gates

- AG1: Evidence artifact created here with stale shim disposition.
- AG2: Targeted T2.6 proof passed.
- AG3: `br show flywheel-ruhcf --json` showed status `open` before evidence creation.
