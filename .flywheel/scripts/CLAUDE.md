# .flywheel/scripts

Executable flywheel substrate. Prefer small, re-runnable scripts with explicit JSON output over one-off shell transcripts.

## Conventions

- Name scripts by stable surface and action: `<surface>-<verb>.sh`, `<surface>-audit.sh`, or `<surface>-validator.sh`.
- Keep default behavior read-only unless the command has an explicit `--apply` or `--write-*` flag.
- Support `--json` for machine consumers when the script reports status, counts, or audit findings.
- Validate shell with `bash -n .flywheel/scripts/<script>.sh` before closeout.
- For canonical CLI surfaces, keep `doctor`, `health`, `repair`, `validate`, `audit`, and `why` behavior together or explain why the surface is intentionally narrower.
- Tests belong in `tests/` and should call the script through `ROOT/.flywheel/scripts/...` so fixtures can override roots without mutating live state.
