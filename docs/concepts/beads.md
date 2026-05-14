# Beads

Beads are Flywheel's task graph. They turn plans into inspectable work packets
with scope, dependencies, acceptance criteria, and close evidence.

Use Beads when work crosses files, changes behavior, or needs another agent to
pick it up later:

```bash
br ready --json
br show <id> --json
br close <id> --reason "Completed with evidence..."
```

Do not edit `.beads/issues.jsonl` by hand. The `br` command owns the database
and exports JSONL for review.

A useful Bead is self-contained. A future worker should know what to change,
which files are in scope, which tests prove it, and what remains open.
