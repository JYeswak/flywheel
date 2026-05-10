# Bead jloib.0d: refactor pilot to use helper lib

After helper lib (jloib.0a) ships, refactor the pilot script
(`daily-report-enabled-repos.sh`) to source it and use helpers instead
of inlined functions. Validates the lib design against the first real
surface.

## Goal

Prove that the helper lib delivers ~50% line savings on a real
surface by refactoring the pilot. If the savings are <30%, the lib
design is wrong and must be revised before bead 2.x lane work begins.

## Scope

### AG1: refactor

Edit `.flywheel/scripts/daily-report-enabled-repos.sh`:

1. Add `source "$(dirname "${BASH_SOURCE[0]}")/../lib/canonical-cli-helpers.sh"`
   near the top (after `set -euo pipefail`)
2. Replace inlined `iso_now()` with calls to `cli_iso_now`
3. Replace inlined `sha_self()` with calls to `cli_sha_self "${BASH_SOURCE[0]}"`
4. Replace inlined `audit_append()` with `cli_audit_append "$AUDIT_LOG" ...`
5. Replace inline `--info` JSON construction with `cli_emit_info ...`
6. Replace inline `--examples` with `cli_emit_examples ...`
7. Replace inline quickstart with `cli_emit_quickstart ...`
8. Replace inline completion bash/zsh with `cli_emit_completion_bash` /
   `cli_emit_completion_zsh`
9. Replace inline `--apply` refusal with `cli_refuse_apply_without_idem_key`
10. Replace inline subcommand --help routing with
    `cli_dispatch_subcommand_help`
11. Per-surface logic (cmd_run, cmd_doctor, cmd_health, cmd_repair,
    cmd_validate_config, cmd_audit, cmd_why) stays inline — that's the
    judgment-required portion the lib doesn't cover
12. emit_topic_help stays mostly inline (data) but use
    `cli_emit_topic_help` with a topic_map JSON

### AG2: validate against pilot regression test

`tests/daily-report-enabled-repos-canonical-cli.sh` must continue to
pass 22/22 with ZERO modifications. The lib swap is functional-equivalent.

### AG3: measure delta

Record:
- Before lines: 817 (post-pilot, pre-lib-refactor)
- After lines: ? (post-refactor)
- Helper-lib lines: ? (lib itself, from jloib.0a)
- Net delta per script: <before> - <after>
- Projected savings × 234 P0 surfaces: <delta> × 234

If <delta> >= 150 lines/script, lib design validated. Proceed to
bead 2.x lane work.

If <delta> < 100 lines/script, lib design needs revision. File a
followup bead before lane work begins.

### AG4: linter validation

Run `canonical-cli-lint.sh` (jloib.0c) on the refactored pilot. Must
report zero violations. If violations appear, indicates either lib
or linter has a bug — surface for triage.

### AG5: receipt

Update `.flywheel/audit/flywheel-cli-canonical-baseline/pilot-lessons.md`
with measured deltas (the original lessons doc had estimates; this
replaces with measurements).

## Boundary

- DO NOT add new features to the pilot script. Pure refactor.
- DO NOT change subcommand behavior. Backward compat (existing
  daily-ops launchd plist invocation) must continue to work.
- Diff must be reviewable as a clean refactor (no unrelated changes).
- Pilot regression test must NOT be modified.

## Acceptance gate

- `bash -n .flywheel/scripts/daily-report-enabled-repos.sh` passes
- `bash tests/daily-report-enabled-repos-canonical-cli.sh` reports 22/22
  PASS with ZERO test modifications
- `canonical-cli-lint.sh .flywheel/scripts/daily-report-enabled-repos.sh`
  reports zero violations
- Line-count delta documented in pilot-lessons.md
- If delta validates lib design, bead is closed; otherwise lib-revision
  followup filed

## Estimated effort

~2 hours. The refactor is mechanical once the lib is in place. Most
time goes to verifying behavioral equivalence + measuring deltas.

## Dependencies

- jloib.0a MUST be closed before this bead can begin
- jloib.0c (linter) ideally closed before this; otherwise the lint
  validation step is deferred
