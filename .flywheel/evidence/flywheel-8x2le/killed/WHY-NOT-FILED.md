# Why the jeff-br-source-repo issue was NOT filed

**Date:** 2026-05-09
**Decision by:** Joshua (overwhelm-caution + accretive-bar test)
**Disposition:** RESOLVED LOCALLY — no upstream issue filed.

## Evidence that decided it

`br 0.2.5` source_repo behavior in flywheel.db:

```
1386 rows  source_repo=/Users/josh/Developer/flywheel  (historical, absolute)
  10 rows  source_repo=flywheel                          (recent, basename)
```

The behavior shifted from absolute → basename at some point. Direct probes
2026-05-09T17:54Z confirm `br create` from cwd `/Users/josh/Developer/flywheel`
now writes `source_repo=flywheel` and from a tempdir writes the dir basename.

## Why the draft did not clear the accretive bar

1. **No upstream contract violation cited.** `br --help create` exposes no
   `source_repo` flag and no public doc was found promising absolute paths.
   Closed `beads_rust#273` fixed the literal `.` value but did not promise an
   absolute path. Filing "should be absolute" without a cited contract is our
   opinion, not Jeffrey's bug.

2. **Frame was upside-down.** The draft read "Joshua's audit expects X, br
   outputs Y, please fix br." Cleaner read: our audit's expectation is
   uncalibrated against br's actual current contract.

3. **Internal-doctrine projection.** Citing our memory class names
   (`feedback_basename_keying_collision_class`,
   `frozen-projection-of-mutable-state`) in an upstream issue is the noise
   pattern Joshua's overwhelm-caution exists to prevent. Jeffrey doesn't share
   our class system; he needs concrete user-impact evidence.

4. **Narrow blast radius outside us.** Basename collisions only matter to
   users running beads in multiple repos that share a basename AND building
   cross-project tooling that keys on `source_repo`. That's a small set —
   probably just Joshua's flywheel substrate. Most beads users are single-repo.

5. **Client-side fix exists and is cheap.** Anywhere we key on `source_repo`,
   we can canonicalize at read-time. The collision class only fires when we
   *trust* basename as canonical — a discipline we can enforce in our consumer
   layer without asking Jeffrey to change column semantics (which would be a
   breaking change for any existing `br` user with absolute-path data).

## What we did instead

`tests/phase2-audit.sh` T2.4 was rewritten to test the contract that actually
matters to consumers: `br create` populates `source_repo` AND `br where` (from
inside the repo) resolves the local `.beads` directory. The check no longer
asserts a specific implementation choice (absolute vs basename), so it survives
either br behavior.

Cross-repo basename collision risk remains a CONSUMER concern — the canonical
fix is to canonicalize at read time when keying across repos, not to demand a
specific source_repo shape from upstream.

## What would clear the accretive bar

If we ever want to engage Jeffrey on this, file a *documentation* issue:
"document `source_repo` semantics in br" — ask him to clarify in README/docs
whether `source_repo` is canonical-path, basename, or undefined. That helps
everyone (including future us). Not "fix it to absolute."
