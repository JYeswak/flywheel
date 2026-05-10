---
title: Upstream issue draft — `br update --source-repo` flag
type: upstream-issue-draft
target_repo: jeffrey-emanuel/beads_rust (or equivalent canonical jeff-stack repo)
filed_by: flywheel-wz5rh
filed_at: 2026-05-10
---

# Issue draft: `br update --source-repo` flag

## Summary

Currently `br update` exposes flags for title/description/design/acceptance-criteria/notes/status/priority/type/assignee, but NOT for `source_repo`. When a row's `source_repo` field becomes desynced (e.g., the row was created from a working directory where `source_repo` got the project basename instead of the absolute path), there is no canonical write path to fix it.

## Reproducer

```bash
# Original creation set source_repo='flywheel' (basename) instead of
# canonical absolute path '/Users/josh/Developer/flywheel'.
br update flywheel-03aca --notes "force-touch" 2>&1
# Updated flywheel-03aca: ...
jq -c 'select(.id == "flywheel-03aca") | .source_repo' .beads/issues.jsonl
# "flywheel"  ← still wrong; br update does not touch source_repo
```

## ROOT CAUSE (discovered during wz5rh fix)

`br create` reads `.beads/config.yaml`'s `issue_prefix` and uses it as
`source_repo`. So `issue_prefix: flywheel` produces every new bead with
`source_repo: "flywheel"` (the basename). This is the bug-source — every
new bead created from this directory leaks until upstream is fixed.

Verified: ran wz5rh fix, then immediately filed bead flywheel-9vb9i (a
P2 follow-up). The new bead row had `source_repo: "flywheel"` (the
issue_prefix value), proving br create copies issue_prefix → source_repo.

Two upstream fixes needed (both mentioned in issue body):

1. **`br create`**: source_repo should resolve to the canonical absolute
   path of the .beads/ directory's parent (the repo root), NOT the
   issue_prefix string. Fall back to `$PWD` if the .beads/ parent isn't
   determinable.
2. **`br update --source-repo PATH`** (originally proposed): exposes a
   surface to repair already-leaked rows without round-tripping through
   `br sync --merge --force-jsonl`.

This blocks fleet-wide canonical-source_repo cleanup unless workers either:
- Bypass br via direct `.beads/issues.jsonl` edit (violates `feedback_beads_jsonl_writes_via_br_only` META-RULE 2026-05-07)
- Use `br sync --merge --force-jsonl` to round-trip the JSONL through (works, but is heavy-handed)

## Impact

`flywheel-loop doctor --json` has a `beads_db_health` probe that checks `leakage_count` (rows where `source_repo` doesn't match the canonical absolute path). When leakage > 0, `beads_db_health.status=fail`, which forces top-level doctor `status=fail`. There is no canonical br-side path to repair the divergence.

Downstream from this, the entire `project_bead_isolation_plan` initiative (8 cross-project leakage FMs across the fleet) cannot be cleanly finished without bypassing the `br`-only write contract.

## Proposed fix

Add `--source-repo PATH` to `br update`:

```bash
br update <ID> --source-repo /Users/josh/Developer/flywheel
```

- Validate the path is absolute (refuse basename-only)
- Optionally validate path resolves to a real directory (warn-only; cross-machine clones may not have it locally)
- Update the row in DB + JSONL via the canonical write path
- Audit-log entry like other `br update` operations

## Acceptance gate

- `br update <ID> --source-repo PATH` exits 0 with the row's `source_repo` updated
- `--source-repo` rejected if path is empty or relative
- Round-trip: after `br update --source-repo`, `jq` on JSONL shows the new value

## Workaround used by flywheel-wz5rh

Direct `.beads/issues.jsonl` edit via `jq` (291 rows) + `br sync --merge --force-jsonl` to rebuild DB. This is documented as a one-time exception authorized by the wz5rh dispatch packet, predicated on this upstream feature landing.
