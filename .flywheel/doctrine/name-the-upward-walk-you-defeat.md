---
title: "Name the Upward-Walk Function You're NOT Calling"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Name the Upward-Walk Function You're NOT Calling

Version: `name-the-upward-walk-you-defeat/v1`
Owner: any author of a literal-path predicate or scope check
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.128 (memory-without-cross-link wire-in)
Sister memories: 3-memory ntm#130/#131/#132 doctrine sweep cluster (2026-05-08)

## TL;DR

When authoring a path predicate that must NOT walk up the directory tree,
**explicitly name the walking primitive you're refusing to call** in a
comment. Without that comment, a future refactor can silently swap to the
walking variant and re-introduce parent-walk bugs.

Pattern source: Jeff's ntm#130 fix (commit 27604b24, refactored 06114a5d).
Exemplar comment: `// Deliberately NOT ResolveProjectDir, since that walks
up the filesystem and is exactly the behavior we need to defeat for
recovery contexts.`

## Canonical memory source

This doctrine summarizes
`feedback_name_what_you_defeat.md` — the META-RULE 2026-05-08 memory
documenting the explicit-name-the-defeated-function discipline. Origin:
Jeff's ntm#130 fix (recovery contexts walking parent .beads silently when
they shouldn't). Read the memory for the original `hasLocalBeadsDB(dir)`
exemplar + sister-memory cross-refs.

## The pattern

### Why explicit naming matters

When two functions exist for similar purposes (one walks, one doesn't), the
silent default is to read the codebase and pick one — but the choice between
them is load-bearing for correctness. A maintainer reading `filepath.Abs +
Clean` doesn't see the rejected `ResolveProjectDir`; the next refactor
swaps "this seems equivalent" and reintroduces the walk.

Naming the rejected primitive in a comment is **defense-in-depth against
silent regression**:

1. Future maintainers know there WAS a choice (not just one obvious primitive)
2. The comment is grep-able when the bug recurs
3. Code review can verify the rejected primitive is still wrong for the use case

### How to apply

**Go (Jeff's exemplar):**
```go
// hasLocalBeadsDB checks if dir contains a .beads directory.
// Deliberately NOT ResolveProjectDir, since that walks up the filesystem
// and is exactly the behavior we need to defeat for recovery contexts.
func hasLocalBeadsDB(dir string) bool {
    abs, _ := filepath.Abs(dir)
    abs = filepath.Clean(abs)
    _, err := os.Stat(filepath.Join(abs, ".beads"))
    return err == nil
}
```

**Shell:**
```bash
# Path normalization for the LITERAL link (NOT $(realpath -P), which would
# follow the symlink). Symlink resolution is a walk; we want the path as
# given.
abs_path="$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
```

**Python:**
```python
# Use Path.absolute() + Path; deliberately NOT Path.resolve() since
# .resolve() walks the symlink chain and is the behavior we need to defeat.
abs_path = (Path(p).absolute()).as_posix()
```

### When two functions exist for similar purposes

The rule: pick the non-walking one AND comment which one you rejected and
why. The "why" is what protects against future refactor regression.

## Anti-patterns

1. **Silently picking `filepath.Abs+Clean` without naming the rejected
   `ResolveProjectDir`** — next maintainer doesn't know there's a choice;
   silent regression on parent-walk bugs.

2. **Using `realpath` when you mean literal `pwd`** — symlink resolution is
   a walk. If you want the path as given (preserving the symlink), name
   that explicitly.

3. **Path-string-equality without `filepath.Abs+Clean`** — fragile across
   symlinks and relative paths. Compare normalized absolute paths.

4. **Naming the rejected primitive vaguely** — "we don't want to walk"
   isn't enough. Name the SPECIFIC primitive: "deliberately NOT
   `ResolveProjectDir`".

## Behavioral vs name cross-linking

This doctrine doc gives the memory a **name cross-link** so gap-hunt-probe's
memory-without-cross-link class clears. The discipline IS load-bearing
behaviorally:

| Surface | Embedding evidence |
|---|---|
| Jeff's ntm#130 fix commit 27604b24 | `hasLocalBeadsDB` exemplar with explicit-NOT comment |
| Jeff's ntm#131/#132 fixes (sister sweep) | `filepath.Abs+Clean` discipline + both-empty/either-empty preservation |

But the discipline isn't NAME-cited in our doctrine corpora until now. This
doctrine doc closes that gap; the live runtime artifacts (ntm fixes upstream)
remain the load-bearing source.

Per substrate-self-improving loop: this is the 8th instance of memory-without-cross-link
auto-injection (1st post-pmg3c LIVE loop validation). flywheel-xbsd8 owns the
recurring class for faqj2 next-tick harvest.

## 3-memory ntm#130/#131/#132 doctrine sweep cluster

This memory is part of a 3-memory cluster sharing **common origin** (Jeff's
ntm#130/#131/#132 doctrine sweep 2026-05-08) but **different disciplines**:

| Memory | Discipline | Doctrine status |
|---|---|---|
| **`feedback_name_what_you_defeat.md`** (this) | Name the rejected walking primitive | ✓ THIS doc (2xdi.128) |
| `feedback_basename_keying_collision_class.md` | Absolute-path scoping over basename for cross-project state | pending doctrine doc |
| `feedback_legacy_compat_both_empty_either_empty.md` | Gate ONLY on both-non-empty-and-disagree | ✓ `.flywheel/doctrine/api-additive-compat-both-empty-either-empty.md` |

Per pmg3c sub-pattern selection: **1:1 forward-link** (default; not
CLUSTER-ANCHOR — siblings share origin not discipline class). Each memory
deserves its own 1:1 doctrine doc when dispatched.

## Sister doctrine

- `feedback_name_what_you_defeat.md` (canonical memory source)
- `feedback_basename_keying_collision_class.md` (sister memory; pending
  doctrine when dispatched)
- `feedback_legacy_compat_both_empty_either_empty.md` (sister memory;
  already canonicalized at `.flywheel/doctrine/api-additive-compat-both-empty-either-empty.md`)
- `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` (meta-recipe;
  this bead is the 8th instance — 1st live post-pmg3c loop validation)
- Jeff's ntm#130 (commit 27604b24, refactored 06114a5d) — upstream
  exemplar
- Jeff's ntm#131 (checkpoint working_dir validation, commit 4d1b14bc)
- Jeff's ntm#132 (CM workspace scoping, commit cb0a98de)

## Conformance

A path predicate authored under this doctrine proves conformance via:

- Comment on the predicate explicitly names the rejected walking primitive
  (`// Deliberately NOT <walking-fn>; literal-path semantics required.`)
- The rejected primitive is grep-able in code review
- Path comparison uses normalized absolute paths (`filepath.Abs+Clean` or
  equivalent), not string equality
- Symlink resolution is a deliberate choice, not an accident

## Below-trauma-class tracking

1 confirmed exemplar (Jeff's ntm#130 fix). Sister memories
(`basename_keying_collision_class`, `legacy_compat_both_empty_either_empty`)
are part of the same 2026-05-08 ntm doctrine sweep but document different
disciplines.

4-instance trauma-class promotion threshold not met for this specific
discipline (only 1 ntm exemplar so far). Track future cases via fuckup-log:
`failure_class=silent_walk_regression_no_explicit_NOT_comment`.

## Substrate-self-improving loop milestone (1st live post-pmg3c)

This bead is the **first dispatch that arrived AFTER flywheel-pmg3c shipped
the auto-injection wire-in** (commit `b87bace4`). The dispatch packet at
`/tmp/dispatch_flywheel-2xdi.128-5fbcb5.md` line 212 contains the
FORWARD-LINK DOCTRINE DOC RECIPE BLOCK auto-injected by
`.flywheel/scripts/inject-forward-link-recipe.sh`.

The loop fires end-to-end:
1. gap-hunt-probe flags `feedback_name_what_you_defeat.md` (memory-without-cross-link)
2. Orch dispatches flywheel-2xdi.128 → build-dispatch-packet.sh runs
3. inject-forward-link-recipe.sh detects `[gap-memory-without-cross-link]`
   title → injects FORWARD-LINK BLOCK before METADATA
4. Worker (this) reads recipe in-band, applies 1:1 sub-pattern, ships THIS
   doctrine doc
5. Next probe run: corpus 4 (skill_md_corpus) or doctrine-corpus contains
   memory filename → gap cleared

**The substrate is now self-teaching for this class.** No manual re-discovery.
