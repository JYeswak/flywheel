## Summary

Follow-up to #273. The installed `br 0.2.5` (built 2026-05-06, between v0.2.5 and v0.2.6 tags) still stores `source_repo` as the **basename** of the canonicalized parent of `.beads/`, not the absolute path. Fleet automation using `source_repo` to route beads back to canonical repo locations needs the absolute path (basename collides across machines and across `~/Developer/foo` vs `~/Developer/scratch/foo`).

Master already has the canonical fix at commit `648b50f1` ("set source_repo to canonical repo path at create time") — this issue is asking either (a) for a v0.2.7 release that includes that commit, or (b) clarification on the intent of the basename-vs-absolute behavior between `03167479` (basename) and `648b50f1` (absolute path), and the expected upgrade path. Plus (c) a `br update --source-repo PATH` flag for repairing already-leaked basename rows.

## Reproducer (installed binary `0.2.5`)

```bash
tmp=$(mktemp -d /tmp/br-source-repo.XXXXXX) && cd "$tmp" && git init -q
br init
id=$(br create "source_repo probe" --json | jq -r '.id // .issue.id // .[0].id')
br show "$id" --json | jq -r '.[0].source_repo // .source_repo'
# Observed: "br-source-repo.<suffix>"  ← basename of canonicalized parent of .beads/
# Wanted:   "/private/var/folders/.../br-source-repo.<suffix>"  ← full canonical absolute path
```

## Source trail (`~/Developer/beads_rust/` on master)

- `src/cli/commands/create.rs:59-62` (HEAD): `path.canonicalize().to_string_lossy()` → absolute path. **The fix is already here.**
- `git show 03167479 -- src/cli/commands/create.rs` (2026-05-03): `canonical_source_repo` returns **basename** of canonicalized parent. This is the version the installed `0.2.5` binary uses.
- `git show 912126d8`: confirms basename-of-parent design intent at that earlier point.
- `git show 648b50f1`: "set source_repo to canonical repo path at create time" — the absolute-path resolution.
- `src/storage/sqlite.rs:1552`: column default is `"."` (`unwrap_or(".")`).
- `src/util/source_repo_guard.rs:25-33`: `normalize_repo_path` resolves relative `source_repo` against cwd — explains why `"flywheel"` (basename) shows up as a mismatch warning relative to `/Users/josh/Developer/flywheel`.

## Why this matters (impact)

- `flywheel-loop doctor --json`'s `beads_db_health` probe checks `leakage_count` (rows where `source_repo` doesn't match the canonical absolute path of the repo). Basename rows trip the leakage counter; when leakage > 0 the probe forces top-level doctor status=fail.
- The `project_bead_isolation_plan` initiative (8 cross-project leakage FMs across the fleet) cannot finish without canonical absolute-path `source_repo`.
- Basename collisions: a bead created in `~/Developer/foo/.beads/` and one in `~/Developer/scratch/foo/.beads/` both record `source_repo: "foo"` — cross-machine routing can't tell them apart.

## Workaround research (5 candidates evaluated)

| # | Workaround | Verdict | Rationale |
|---|---|---|---|
| W1 | Bulk `jq` rewrite of `.beads/issues.jsonl` + `br sync --merge --force-jsonl` | One-shot OK | Heavy-handed; violates spirit of "writes go through br" for routine use |
| W2 | Set `issue_prefix:` to absolute path in `.beads/config.yaml` | REJECT | `normalize_prefix` (sqlite.rs:6610) lowercases + strips non-alnum → mangles IDs; AND `source_repo` is set from `canonical_source_repo(beads_dir)`, not from `config.issue_prefix`, so this can't influence source_repo regardless |
| W3 | Wrapper around every `br create` call that jq-edits the new row + `br sync --merge --force-jsonl` | Works mechanically | Requires modifying ~30+ call sites; ~200ms latency per create; race-condition window between create and merge |
| W4 | `sqlite3 .beads/beads.db "UPDATE issues SET source_repo=..."` + `br sync --flush-only --force` | Works with `--force` | Direct SQL UPDATE doesn't add to `dirty_issues` table, so plain `--flush-only` says "Nothing to export"; the `--force` bypass is a code-smell for routine use; concurrency exposure in WAL mode |
| W5 | `BEADS_SOURCE_REPO=...` env override | REJECT | Searched all of `src/` — env var does not exist. `BEADS_DIR` exists but doesn't affect `canonical_source_repo` derivation (tested) |

All copy-tested in `mktemp -d` fixtures, repro snippets preserved.

## Asks

### 1. Release / clarify the canonical-source-repo fix

Either:
- Cut v0.2.7 with `648b50f1` so installed binaries pick up the absolute-path behavior; or
- Confirm that the basename-not-absolute behavior between `03167479` and `648b50f1` is the intended steady state, and document the upgrade path (e.g., is `648b50f1` going to be reverted, or is master post-`648b50f1` the canonical?).

### 2. `br update --source-repo PATH` for repair of already-leaked rows

`br update` exposes flags for title/description/design/acceptance-criteria/notes/status/priority/type/assignee, but NOT for `source_repo`. So after a fleet upgrades to a binary with the canonical fix, the pre-existing basename rows have no canonical write path to repair without bypassing `br`.

Proposed:

```bash
br update <ID> --source-repo /Users/josh/Developer/flywheel
```

Validation:
- Refuse empty or relative paths (`--source-repo "."` → reject)
- Optionally warn if path doesn't resolve to a real directory (don't hard-fail; cross-machine clones may not have it locally)
- Update row in DB + JSONL via canonical write path
- Audit-log entry like other `br update` operations

## Acceptance gates

For #1 (release/clarify):
- A released `br` binary on a fresh `git init && br init` stores `source_repo` as the canonical absolute path of the `.beads/` parent

For #2 (br update --source-repo):
- `br update <ID> --source-repo /abs/path` exits 0 with the row's `source_repo` updated
- `--source-repo` rejected if path is empty or relative
- Round-trip: after `br update --source-repo`, `jq` on JSONL shows the new value

## Filed by

`flywheel-6kdnf` (per draft at `flywheel-wz5rh` 2026-05-10, with bug-shape correction per `flywheel-6kdnf` workaround research 2026-05-11). Local artifacts:
- Draft: `.flywheel/audit/flywheel-wz5rh/upstream-beads-rust-issue-draft.md`
- Workaround matrix + source trail: `.flywheel/audit/flywheel-6kdnf/workaround-research.md`
