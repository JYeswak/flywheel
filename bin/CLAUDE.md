# bin

Command entrypoints should be thin, discoverable wrappers over repo-owned implementation.

## Conventions

- Maintain the canonical CLI floor where applicable: `doctor`, `health`, `repair`, `validate`, `audit`, and `why`.
- Entrypoints should resolve the repo root from their own path, not from the caller's current directory.
- Keep mutation behind explicit flags and idempotency keys when a command writes shared state.
- Prefer forwarding to `.flywheel/scripts` or `scripts` implementations instead of duplicating logic here.
- Include terse usage output for unknown commands and non-zero exits for invalid arguments.
