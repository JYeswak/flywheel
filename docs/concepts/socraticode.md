# Socraticode

Socraticode is the codebase-search and context layer Flywheel expects agents to
use before non-trivial edits. It helps an agent find existing patterns before it
adds a new one.

The public rule is simple:

```text
search first, patch second
```

If Socraticode is available, run a codebase search with enough results to see
the local pattern. If it is not available, use `rg`, nearby tests, and existing
scripts before changing behavior.

Flywheel does not publish private Socraticode indexes. A new user builds their
own local index or uses reduced search surfaces.
