# Stash Recovery Bundle (v1.0)

Project: /Users/josh/Developer/polymarket-pico-z
Bundle path: /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08
Created: 2026-05-08T23:49:48Z
Stash count:       34

This bundle is the recovery story for every stash that existed at run start.
Each stash has FOUR layers of recoverability:

  1. `refs/stash-backup/<NNN>` — a permanent ref inside the project's
     `.git/refs/`. Survives `git stash drop`, `git stash clear`, and
     `git gc` (it's a real ref, so gc treats it as a root).
	  2. `diffs/<NNN>.diff` — the tracked/index diff from
	     `git stash show -p --binary <inventory-sha>`. Applies via `git apply --3way`
	     against any compatible base. Untracked files are stored separately in
	     layer 4.
  3. `meta/<NNN>.txt` — sha, parent, date, author, untracked flag, message.
  4. `stashed-untracked/<NNN>/` — materialized untracked files (only when
     the original stash was `git stash -u`).

## Recovery recipes

### Recover a single stash by backup ref (preferred)

	```
	git cherry-pick -m 1 refs/stash-backup/034
	```

	Stash backup refs point at merge commits. `-m 1` selects the original
	HEAD parent and recovers the tracked/index changes. If `index.tsv` says
	`has_untracked=true`, also copy `stashed-untracked/034/` as shown below.

### Recover a single stash by bundle diff

		```
		git apply --3way --check /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs/034.diff
		git apply --3way        /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs/034.diff
	# If index.tsv says has_untracked=true, also copy stashed-untracked/034/.
	git add <changed-files>
	git commit -m "recover stash@{34} from bundle"
	```

### Recover untracked files specifically

		```
		( cd /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/stashed-untracked/034 && tar -cf - . ) | ( cd /Users/josh/Developer/polymarket-pico-z && tar -xf - )
	git add <new-files>
	git commit
	```

### Re-create the stash entry itself (rare)

	```
	if grep -q '^diff --git ' /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs/034.diff; then
	  git apply --3way --check /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs/034.diff
	  git apply --3way        /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs/034.diff
	fi
	if awk -F'\t' '$1 == 34 {print $11}' /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/index.tsv | grep -qx true; then
	  ( cd /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/stashed-untracked/034 && tar -cf - . ) | ( cd /Users/josh/Developer/polymarket-pico-z && tar -xf - )
fi
git stash push --include-untracked -m "recovered stash@{34} from bundle"
```

## ⚠️  Footgun: `git format-patch` is the WRONG recovery source

	`git format-patch -1 stash@{N}` is not the stash recovery diff. A stash is
	a merge commit, and format-patch can emit a tiny, empty, or unrelated patch
	depending on the merge parents. It also does not materialize untracked files.

**Always use `git stash show -p --binary stash@{N}`** for the recovery diff.
The diffs in this bundle were generated via `git stash show -p --binary` and ARE the
authoritative recovery source.

## Bundle integrity

To re-verify byte-equality of every backup ref vs. its diff:

```
/Users/josh/.claude/skills/git-stash-janitor/scripts/verify-bundle.sh /Users/josh/Developer/polymarket-pico-z
```

Should report 0 mismatches.

## Lifecycle

This bundle is yours to keep. Recommended:

  - Keep for at least one release cycle (typically 1–4 weeks)
  - Once you're sure nothing important was missed, you can `mv` it to a
    trash location (DCG would block `rm -rf`; that's fine — `mv` works)

## Index

See `index.tsv` for the full per-stash index.
