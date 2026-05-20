# Dry-Run/Apply Parity Contract

## Contract

Any flywheel script that exposes both non-mutating and mutating modes MUST share
a single data source and computation path.

The script computes the intended operation once into an in-memory
representation. From that representation it either:

- renders the plan in `--dry-run`, `--check`, or `--plan` mode; or
- mutates from the same representation in `--apply`, `--commit`, or
  `--execute` mode.

The mutating branch may add side effects, receipts, and post-mutation
verification. It must not recompute the target data through a separate path.

## Required Shape

1. Parse inputs.
2. Load shared data sources.
3. Compute one canonical envelope.
4. In dry-run mode, render that envelope.
5. In apply mode, mutate from that envelope.
6. In parity tests, compare the dry-run envelope with the apply pre-mutation
   envelope for the same inputs.

The parity assertion should compare stable computation fields after removing
timestamps, outcome labels, and mutation receipts. A script-specific field such
as `.computation`, `.desired`, `.required_checks`, or `.plan` is acceptable if
it is the complete pre-mutation target.

## Anti-Pattern

Do not maintain separate dry-run and apply branches that compute the same target
data through different discovery logic, defaults, fixtures, or fallbacks.

Examples of forbidden shapes:

- dry-run discovers per-repo state while apply uses a default table;
- dry-run reads live workflow names while apply reads stale config;
- dry-run and apply each call different helper functions that independently
  infer the mutation payload;
- the smoke fixture only asserts that dry-run does not mutate and apply mutates,
  but never proves the pre-mutation envelopes are identical.

## Trauma Corpus Row

`branch-protection-apply.sh` violated this contract on
2026-05-20T02:46Z. Dry-run used per-repo CI check discovery, but apply used
hardcoded flywheel defaults. The result was four repositories receiving wrong
required status-check names, blocking PR merges until Joshua manually reverted
the incorrect branch-protection settings via GitHub API deletion.

Bead `flywheel-n2228` fixed the concrete script by making dry-run and apply
share the same discovery path and by adding `--verify-parity`, which compares
the dry-run plan with the apply pre-mutation plan before any mutation.

Bead `flywheel-vlodi` generalizes the lesson: every dual-mode flywheel script
needs either an existing parity assertion or a follow-up bead that adds one.

## Validator

`.flywheel/scripts/parity-contract-validator.sh` scans dual-mode shell scripts
and reports whether their smoke fixture contains a parity assertion. The
validator is intentionally diagnostic: it emits PASS, FAIL, or NO-FIXTURE per
script and writes a Markdown audit report under `.flywheel/audits/`.

Out-of-scope for the validator: changing existing fixtures, deciding the exact
comparison field for each script, or claiming all current scripts already
conform. Those are per-script follow-up beads.
