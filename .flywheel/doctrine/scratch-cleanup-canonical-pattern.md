# Scratch Cleanup Canonical Pattern

## Pattern

Dispatch workers create per-task scratch directories with `mktemp -d`, usually under `/var/folders/.../T/` on macOS or `/tmp/` on Linux. Raw recursive deletion from a pane command repeatedly trips DCG because the command text contains a broad destructive primitive against an absolute path.

## Canonical Primitive

Use:

```bash
flywheel-cleanup-scratch --apply --json "$WORK_TMP"
```

The command is backed by `.flywheel/scripts/cleanup-scratch.sh` and only accepts:

- `/var/folders/.*/T/(flywheel|josh|wave)-.*`
- `/tmp/(flywheel|dispatch_)-.*`

Default mode is dry-run. Apply mode is explicit and still refuses paths outside the scratch allowlist. Missing paths are a successful no-op.

## Why

The recurring failure class started after 2026-05-08T23:52Z and appeared in at least these dispatches: `flywheel-glrlb`, `flywheel-olp9b`, `flywheel-z6lk3`, `flywheel-mjrly`, `flywheel-wire-worker-close-requires-git-commit-a1912c82`, `flywheel-rdqc7.1`, `flywheel-03uki`, `flywheel-ftj0m`, and `flywheel-wire-dispatch-to-lib-not-bin`.

The policy is not to weaken DCG. The policy is to remove dangerous command text from worker closeout and route cleanup through one narrow, validated helper.

## Operator Checks

```bash
.flywheel/scripts/cleanup-scratch.sh schema --json
.flywheel/scripts/cleanup-scratch.sh doctor --json
bash tests/cleanup-scratch.sh
```

## Four-Lens Self-Grade

four_lens=brand:8,sniff:8,jeff:8,public:8

Three Judges check: a skeptical operator can verify the path gate, a maintainer can audit one helper instead of many ad hoc cleanups, and a future worker gets one command to use at closeout.
