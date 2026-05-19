# tests

Tests should prove the repo contract with small fixtures and clear pass/fail accounting.

## Conventions

- Use `mktemp -d` plus `trap 'rm -rf "$TMP"' EXIT` for isolated fixtures.
- Emit `PASS ...` and `FAIL ...` lines, then end with `SUMMARY pass=<n> fail=<n>`.
- Keep fixture writes inside the temp directory unless the test is explicitly validating a committed fixture.
- Include a `PROVENANCE.md` backlink in generated fixture trees when the fixture represents a real doctrine or audit source.
- Test one script through its public CLI surface instead of sourcing implementation internals.
