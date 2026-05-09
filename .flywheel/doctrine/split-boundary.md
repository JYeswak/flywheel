# Cherry-Pick Boundary Doctrine

When an upstream cherry-pick mixes Jeff-canonical code with Joshua-local code,
split it at the cherry-pick boundary before landing either side.

For `ntm` agent-type support:

- `pi` is Jeff-canonical. It maps to Dicklesworthstone's `pi_agent_rust` and may
  land on upstream-track branches when the patch is otherwise compatible.
- `cubcode` is Joshua-local CubCloud / cc-router substrate. Keep it out of
  upstream-track commits unless Joshua explicitly promotes it upstream; land it
  as a separate local-only commit on `local/bead-isolation-reconciled-*` branches.

Do not skip a mixed cherry-pick and silently lose the upstream-canonical portion.
Either split the patch locally or file an upstream issue asking Jeff to split it.
