# DRAFT — beads_rust upstream issue: source_repo SQL filtering and walk-up isolation

> **Status:** Draft pending Joshua signoff per L66 Phase 5 (thankfulness
> test). Do **NOT** auto-file. Owned by flywheel bead `flywheel-6zgt`.
>
> **Standing rules respected:** no patch will be sent to
> `Dicklesworthstone/beads_rust`; this is a problem statement + repro, not
> a prescriptive PR. Human-facing prose addresses Jeffrey Emanuel.

---

## Title

`br: cross-repo bead bleed when .beads is reached via symlink walk-up — request source_repo filter on list/ready/blocked, last-touched repo guard, and discovery anti-walk-up symlink skip`

## Problem

When a child directory's `.beads` is a symlink (or junction) to a
parent or sibling repo's `.beads`, `br list / ready / blocked` from
inside the child directory return the parent/sibling's beads rather
than failing or filtering. The same pattern occurs when `--db` points
at a mixed JSONL/SQLite store that contains beads from multiple
`source_repo` values: callers cannot constrain a query to "only the
beads belonging to this repo" without post-filtering the JSON output
themselves.

The downstream symptom is "cross-project bead bleed" in multi-repo
fleets: a worker running in `repoB/sub/` ends up creating a bead that
gets `source_repo=repoA` (now stamped correctly post-`#273`), or
listing what it thinks is repoB ready work and acting on repoA beads.

This is distinct from the recently-fixed `#273` (which made
`br create` stamp `source_repo` with the correct repo basename) — the
prevention story now needs a corresponding *query-side* filter and a
*discovery-side* symlink skip so that a stamped `source_repo` is also
queryable and a cross-tree symlink doesn't silently substitute one
repo for another.

## Concrete reproducer

```bash
TMP=$(mktemp -d /tmp/br-bleed.XXXXXX)
mkdir -p "$TMP/repoA" "$TMP/repoB"

cd "$TMP/repoA" && git init -q && br init >/dev/null 2>&1
br create "repoA bead isolated" --json | jq -r '.id // .[0].id'   # → repoa-XXX

cd "$TMP/repoB" && git init -q && br init >/dev/null 2>&1
br create "repoB bead isolated" --json | jq -r '.id // .[0].id'   # → repob-XXX

# Cross-tree symlink: replace repoB/.beads with a symlink to repoA/.beads
mv "$TMP/repoB/.beads" "$TMP/repoB/.beads.orig"
ln -s "$TMP/repoA/.beads" "$TMP/repoB/.beads"

# Observed: br list from repoB now returns ONLY repoA's bead.
cd "$TMP/repoB" && br list --status open --json
# {"issues":[{"id":"repoa-...","source_repo":"repoA",...}],"total":1}
```

(Live capture from this repro: this evidence pack ships
`repoB-leak-evidence.json` in the parent `flywheel-6zgt` audit dir
showing the leak is real on `br 0.2.5`.)

## Current behavior (file:line)

`beads_rust/src/storage/sqlite.rs`

- **Line 923**, `list_issues`: `ListFilters` has no `source_repo` axis.
  Queries select all rows across the connected DB, regardless of
  which repo each row was stamped from.
- **Line 1223**, `get_ready_issues`: `ReadyFilters` likewise lacks a
  `source_repo` axis.
- **Line 1682**, blocked-issues query: same shape.

`beads_rust/src/cli/commands/{list,ready,blocked}.rs`

- No `--repo <path>` flag. When a caller wants to scope a query to
  a single repo's beads they must either run from inside that repo's
  walk-up tree (which the symlink hazard above defeats) or post-filter
  the JSON output themselves.

`beads_rust/src/cli/commands/{close,update,show,reopen}.rs`

- The "last-touched bead id" fallback resolves IDs across all rows in
  the connected DB without verifying the touched bead's `source_repo`
  matches the discovery context. From inside `repoB`, a fallback
  resolution can land on a `repoA`-stamped row.

`beads_rust/src/config/mod.rs` (lines 221-229)

- `discover_beads_dir` walks up looking for `.beads`. When the found
  `.beads` is a symlink whose target lives outside the walk-up tree,
  it is followed silently. Callers downstream cannot distinguish
  "intentional same-repo symlink (e.g. for portability)" from
  "accidental cross-tree symlink (parasitic substrate bleed)".

## Expected behavior (additive contract)

This is a request for the contract surface, not a prescriptive PR.
Suggested additive shape, framed against the existing
`ListFilters` / `ReadyFilters` pattern:

1. **`source_repo` filter** on `list_issues`, `get_ready_issues`, and
   the blocked-issues query. When set, append `AND source_repo = ?`
   to the SQL. When `None`, behavior is unchanged (matches today's
   "all repos" semantic, preserving interactive use).

2. **`--repo <path>` CLI flag** on `br list`, `br ready`, `br blocked`.
   Populates the `source_repo` filter. When `--db <path>` is provided,
   `--repo` may be auto-derived from the parent of `.beads/` for the
   passed DB.

3. **Last-touched repo guard** on `close / update / show / reopen`.
   When the fallback resolution lands on a row whose `source_repo`
   does not match the discovery context, error with a clear message
   instead of silently acting on a foreign-repo bead. Suggested
   message:
   ```
   br: last-touched bead <id> belongs to <source_repo>; current discovery context is <repo>; pass --repo or run from <source_repo> to override
   ```

4. **Anti-walk-up symlink guard** in `discover_beads_dir`. When the
   walked-up `.beads` is a symlink whose canonicalised target lives
   outside the walk-up base (i.e. it is **cross-tree**), skip it with
   a stderr warning and continue walking. An env var
   (`BEADS_STRICT_LOCAL=1` is one obvious name) MAY toggle this
   from "warn and skip" to "fail-loud" semantics for orchestration
   contexts that require fail-fast.

A reference shell-side implementation of (4) lives in our local
`bv` wrapper at
`/Users/josh/.local/bin/bv` (Phase 3 hardening filed under
`flywheel-6zgt`). It demonstrates the strict-local refusal path with
exit code 78 (`EX_CONFIG`) and the cross-tree-symlink skip during
walk-up. We do not propose this as a patch against `beads_rust`; it
is local prevention while the upstream contract converges.

## Tests this would unblock (copied from our plan T3.1-T3.7)

| # | Type | Description |
|---|---|---|
| T3.1 | Unit | `list_issues` with `source_repo` filter → only matching beads |
| T3.2 | Unit | `create` sets absolute `source_repo` (already shipped via #273) |
| T3.3 | Unit | `close` via last-touched with repo mismatch → error |
| T3.4 | Unit | `discover_beads_dir` skips cross-tree symlinks |
| T3.5 | Integration | `bv --robot-next` with `BEADS_STRICT_LOCAL=1` in no-local-db dir → error (today: passes locally on `bv` with rc=78) |
| T3.6 | Integration | Mixed DB queried with repo filter → correct isolation |
| T3.7 | Regression | Production multi-repo fleet (zesttube, mobile-eats, alpsinsurance, flywheel) all still work |

## Backward compatibility

All proposed fields are additive. `source_repo=None` preserves
"all repos" semantics. The CLI `--repo` flag defaults to absent.
Existing callers ignore the new filter. Consumers that care about
isolation can opt-in (`--repo $(pwd)` or `BEADS_STRICT_LOCAL=1`).

## Why upstream, not only a local workaround

We can (and have) hardened our `bv` wrapper to refuse cross-tree
symlinks under `BEADS_STRICT_LOCAL=1`. But that is a single consumer.
Other agents and operators reading `br list` JSON cannot detect the
ambiguity once the symlink has already substituted one repo for
another inside `discover_beads_dir`. The contract belongs in
`beads_rust` so any downstream caller (CI, watchdogs, agent fleets)
can rely on the same isolation guarantee.

## Dedup / reference

- `#273` (CLOSED 2026-05-03) — `br create` `source_repo='.'` was a
  *write-side* leakage; this is the corresponding *query-side*
  filter request. Not a duplicate.
- `#262 / #268 / #269 / #270` — sync/sparse-field/integrity issues,
  unrelated.
- `#274` (open) — closure-time policy gates, unrelated.

Tracking on flywheel side: `flywheel-6zgt` (this bead) and the
predecessor isolation chain `flywheel-frov / flywheel-1o0i /
flywheel-45tt / flywheel-ldhr / flywheel-wrrf` (all CLOSED).

## Files / line numbers cited

- `beads_rust/src/storage/sqlite.rs:923` (`list_issues`)
- `beads_rust/src/storage/sqlite.rs:1223` (`get_ready_issues`)
- `beads_rust/src/storage/sqlite.rs:1682` (blocked query)
- `beads_rust/src/cli/commands/list.rs`
- `beads_rust/src/cli/commands/ready.rs`
- `beads_rust/src/cli/commands/blocked.rs`
- `beads_rust/src/cli/commands/close.rs`
- `beads_rust/src/cli/commands/update.rs`
- `beads_rust/src/cli/commands/show.rs`
- `beads_rust/src/cli/commands/reopen.rs`
- `beads_rust/src/config/mod.rs:221-229` (`discover_beads_dir`)

(Line numbers from plan
`/Users/josh/Developer/flywheel/.flywheel/PLANS/bead-isolation-fix-2026-04-30.md`,
verified against the latest `Dicklesworthstone/beads_rust` clone in
`/Users/josh/Developer/beads_rust` if/when filed.)

## Joshua signoff checklist (Phase 5)

- [ ] Repro reproduces fresh on `br --version` $(br --version)
- [ ] No tokens, secrets, or auth material echoed
- [ ] Multi-model triangulation cited (this draft is the v1; second-pass
      review optional before filing)
- [ ] Upstream tone: problem statement + repro, no prescriptive PR,
      Jeffrey-not-Jeff in human-facing prose
- [ ] Cross-reference flywheel bead populated (`flywheel-6zgt`)
- [ ] Local prevention path (bv `BEADS_STRICT_LOCAL=1`) shipped before filing

When checklist clears, file via `gh issue create --repo
Dicklesworthstone/beads_rust --title "<title above>" --body-file
.flywheel/audit/flywheel-6zgt/upstream-issue-draft.md` (or stripped
copy with the "Joshua signoff checklist" section removed).
