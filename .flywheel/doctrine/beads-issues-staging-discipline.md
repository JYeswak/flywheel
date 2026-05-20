# Beads Issues Staging Discipline

Flywheel dogfood v0.1 treats the `br` CLI as the owner of Beads mutations and the wrapper as the owner of staging the exported review surface.

Contract:

- Mutating Beads operations `br create`, `br close`, `br update`, and `br dep ...` must stage `.beads/issues.jsonl` before returning control to the worker.
- Read-only Beads operations such as `br show`, `br list`, `br ready`, and `br blocked` must not stage `.beads/issues.jsonl`.
- The wrapper stages only the JSONL review surface; it does not commit and does not stage unrelated work.
- If the underlying `br` command fails, the wrapper preserves the exit code and does not stage.

Implementation:

- Repo wrapper: `.flywheel/scripts/br-stage-wrapper.sh`
- Local dogfood integration: `~/.local/bin/br` symlinks to the wrapper. Joshua's shell startup already prepends `~/.local/bin` before `~/.cargo/bin`, so normal `br` calls route through the wrapper.
- Real binary: `/Users/josh/.cargo/bin/br`, overrideable for fixtures with `BR_STAGE_WRAPPER_REAL_BR`.

If `br` is Jeff-managed or upstream-owned, do not patch the binary in place. The wrapper is the canonical local interface until SkillOS ships the canonical substrate or an upstream `br` hook lands. Upstream work should route through the Jeff issue chain with the local wrapper named as the mitigation.
