# Sample bead body fixture demonstrating OWNED_WRITE_ROOTS

This fixture demonstrates the orch-side declaration of `OWNED_WRITE_ROOTS` in a
dispatch packet task body. The orch uses this when a bead needs write access to
paths beyond the flywheel-repo default allowlist (e.g., when intentionally
mutating a client repo, a peer-orch canonical doctrine, or `~/.claude/skills/`).

## Example 1 — single peer-orch authorized

A bead authorizing intentional cross-orch sync into a specific skillos directory:

```text
### Title
sync flywheel-canonical pattern catalog X into skillos pattern-mirror dir

### Description
...

OWNED_WRITE_ROOTS=/Users/josh/Developer/flywheel/,/Users/josh/Developer/skillos/.flywheel/doctrine/_mirrors/

(Default flywheel root + explicitly named skillos mirror subdir; the
worker may NOT write to any OTHER path under /Users/josh/Developer/skillos/.)
```

## Example 2 — multi-client cross-repo dispatch

A bead authoring a doctrine doc that needs to be propagated to two client repos
explicitly:

```text
### Title
propagate doctrine X to alpsinsurance + vrtx via sync-canonical-doctrine.sh

### Description
...

OWNED_WRITE_ROOTS=/Users/josh/Developer/flywheel/,/Users/josh/Developer/alpsinsurance/.flywheel/doctrine/,/Users/josh/Developer/vrtx/.flywheel/doctrine/
```

## Example 3 — flywheel-only (no override needed)

A bead with no `OWNED_WRITE_ROOTS=` line falls back to the default allowlist
from the canonical dispatch-template:

```text
### Title
author flywheel-internal doctrine doc

### Description
...

(No OWNED_WRITE_ROOTS= line — default applies:
  /Users/josh/Developer/flywheel/, /tmp/, ~/.local/state/flywheel/,
  ~/.claude/skills/.flywheel/ via paired-jsm-import only)
```

## Pre-Write check the worker MUST run

For every absolute-path Write/Edit destination:

```bash
target_path="<the path you want to write>"
target_resolved="$(realpath "$target_path" 2>/dev/null || echo "$target_path")"
target_repo_top="$(git -C "$(dirname "$target_resolved")" rev-parse --show-toplevel 2>/dev/null || true)"
# Compare target_repo_top against the bead's OWNED_WRITE_ROOTS allowlist
# If no match: STOP, do NOT invoke Write, send BLOCKED with
# blocker_class=owned_write_root_violation
```

## Callback envelope additions (per L120-sibling discipline)

DONE callbacks for beads that wrote to any absolute path MUST include:

```text
owned_write_roots_verified=yes
owned_write_roots_allowlist=/Users/josh/Developer/flywheel/,/Users/josh/Developer/<extra-allowed>/
```

Missing or `no`/`unknown` is rejected by the callback validator per the
`flywheel-16b53` trauma-class precedent.

## Anti-pattern (rejected by validator)

```text
owned_write_roots_verified=no
```

This callback shape is non-pass. If the worker could not verify write roots
(e.g., the bead body did not include an allowlist and the default didn't
cover the necessary scope), the worker should have sent BLOCKED, not DONE.
