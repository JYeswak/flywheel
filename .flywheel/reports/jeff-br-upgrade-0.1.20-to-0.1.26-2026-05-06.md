# Jeff br substrate upgrade review: dispatch target stale

Task: `jeff-substrate-version-drift-br-2026-05-06`  
Bead: `flywheel-2j54`  
Status: `blocked`  
Decision: do not downgrade load-bearing `br` from live `0.2.5` to dispatch target `0.1.26`.

## Pre-State

Evidence file: `/tmp/jeff-br-pre-upgrade-2026-05-06.txt`

Key live facts:

- `which br`: `/Users/josh/.cargo/bin/br`
- `br --version`: `br 0.2.5`
- `br` sha256: `069430ecbec6aa159b554529e3276d05b9a86c270936b6a61dc5a0f58d521373`
- `bd --version`: `bd 0.1.26`
- `cargo install --list`: `beads-rs v0.1.26` owns `bd`; `beads_rust v0.2.5` owns `br`.
- Jeff latest GitHub release: `v0.2.3`, published `2026-05-01T03:17:30Z`.
- Jeff latest observed tag: `v0.2.5`.
- Local `~/Developer/beads_rust` worktree is dirty and behind `origin/main`; it is not safe to use as a build source for this dispatch without touching Jeff source state.

The dispatch premise said installed `br` should be `0.1.20` and latest should be `0.1.26`. Live substrate disproved both for `br`.

## Upgrade Steps Executed

Executed:

- Read `/tmp/dispatch_jeff-substrate-version-drift-br.md`.
- Read `/flywheel:worker-tick`, `jeff-issue-chain`, `codebase-archaeology`, and the Jeff substrate memory rules.
- Ran repo preflight: dry-run tick was runnable; doctor failed on existing Beads DB corruption and other repo health issues.
- Ran Socraticode K=4 against `/Users/josh/Developer/flywheel`.
- Reserved private report/probe paths through Agent Mail. Shared `INCIDENTS.md` and `.beads/issues.jsonl` had a live WindyMountain conflict.
- Probed current `br`, `bd`, cargo install metadata, GitHub latest release, and latest tags.
- Logged fuckup class `jeff-br-upgrade-dispatch-stale-target`.

Not executed:

- No `git pull` in `~/Developer/beads_rust`.
- No source patch in Jeff's repo.
- No binary replacement.
- No push to Jeff remotes.
- No INCIDENTS or `.beads/issues.jsonl` append, because the task is blocked and shared reservations were actively conflicted.

## Post-State

Evidence file: `/tmp/jeff-br-post-upgrade-2026-05-06.txt`

Post-state is intentionally unchanged:

- `br --version`: `br 0.2.5`
- `br` remains `/Users/josh/.cargo/bin/br`.
- `bd` remains `0.1.26`.
- Official latest release remains `v0.2.3`; latest observed tag remains `v0.2.5`.

The dispatch L112 command is stale and must not be forced:

```bash
br --version 2>&1 | grep -q '0\.1\.26'
```

That would require downgrading `br`.

## Behavior Diff

No binary changed, so there is no legitimate before/after behavior diff.

Observed current behavior:

- `br --help` works.
- `br ready --json | jq length` fails because `br` emits a database error, not JSON.
- `br list --status=in_progress --json | jq length` fails for the same reason.
- `br show flywheel-1eg0k --json` fails with `BusySnapshot`.
- `br sync --flush-only --json` fails with the same `BusySnapshot`.

This is consistent with the repo doctor failure: `.beads/beads.db` is currently corrupt/busy. The dispatch already said JSONL fallback remains active until `flywheel-1eg0k` resolves; the upgrade pass did not repair that substrate.

## New Behaviors Observed

Live Jeff release/tag truth has moved beyond the dispatch:

- GitHub latest release is `v0.2.3`, not `v0.1.26`.
- Latest tag observed is `v0.2.5`.
- Local installed `br` is already `0.2.5`.
- `v0.1.20..v0.1.26` included `fix(no-db): re-read JSONL before flush to prevent clobbering concurrent writes`, routing support, richer show/blocked/ready/stats output, dependency traversal improvements, and multiple sync/storage hardening commits.

That range is useful historical context, but it is not the correct live target for `br` on this machine.

## Jeff-Issue Candidates

Candidates surfaced, not filed:

1. `DISPATCH-CANDIDATE`: version-watchtower or dispatch author mixed `bd` and `br` substrate facts. Evidence: `bd 0.1.26` is installed, while `br` is `0.2.5`.
2. `LOCAL-CANDIDATE`: `br` commands fail on the flywheel repo with `BusySnapshot` due current `.beads/beads.db` corruption. This is likely already covered by `flywheel-1eg0k`; do not file upstream until DB recovery isolates a reproducible `br` bug on a clean repo.

Regressions observed from upgrade: `0` because no upgrade was applied.

## Sync Flush-Only

`br sync --flush-only --json` currently fails before producing JSON:

```text
Error: BusySnapshot { conflicting_pages: "page 1835278412 > snapshot db_size 3266 (latest: 3266)" }
```

This does not prove a 0.2.5 regression; it proves current flywheel Beads DB health is not good enough for `br` sanity checks.

## Recommendation

Keep `br 0.2.5`.

Do not roll back to `0.1.26`. The correct next action is to update the dispatch/watchtower target logic from "0.1.26 latest" to live Jeff release/tag truth, then let `flywheel-1eg0k` or its successor repair the Beads DB substrate before re-running sanity checks.

## Worker Receipt

| Gate | Result | Evidence |
|---|---|---|
| Pre-upgrade probe artifact | DID | `/tmp/jeff-br-pre-upgrade-2026-05-06.txt` |
| Upgrade executed to `0.1.26` | DIDNT | blocked: would downgrade live `br 0.2.5` |
| Post-upgrade probe artifact | DID | `/tmp/jeff-br-post-upgrade-2026-05-06.txt` |
| Four br sanity checks pass | DIDNT | blocked by current `.beads/beads.db` `BusySnapshot` |
| Upgrade report written | DID | this file |
| No push to Jeff upstream | DID | no push executed |
| No patch to Jeff source | DID | no source patch executed |
| INCIDENTS shipped | DIDNT | shared reservation conflict and task blocked |
| JSONL closure appended | DIDNT | shared reservation conflict and task blocked |
| Socraticode K>=4 | DID | 4 queries |

Four-Lens self-grade: Brand 8, Sniff 9, Jeff 9, Public 8.
