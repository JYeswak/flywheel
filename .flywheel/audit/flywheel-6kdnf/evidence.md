# Evidence: flywheel-6kdnf — beads_rust upstream issue filed

**Bead**: flywheel-6kdnf (P2) | **Task ID**: flywheel-6kdnf-be79be | **Identity**: MistyCliff
**Parent draft**: `.flywheel/audit/flywheel-wz5rh/upstream-beads-rust-issue-draft.md`

## Outcome

**Filed**: https://github.com/Dicklesworthstone/beads_rust/issues/289
**Title**: `br create source_repo: release/clarify canonical-path fix (648b50f1) + br update --source-repo flag for repair`

## Rule-2 workaround research (per `feedback_jeff_issue_requires_full_workaround_research_first`)

Workaround research dispatched as a subagent before filing. Full report at `.flywheel/audit/flywheel-6kdnf/workaround-research.md`.

| # | Workaround | Verdict |
|---|---|---|
| W1 | Bulk `jq` + `br sync --merge --force-jsonl` | One-shot OK (applied at wz5rh); not routine |
| W2 | Set `issue_prefix:` to absolute path | REJECT — `normalize_prefix` mangles + doesn't affect source_repo anyway |
| W3 | Per-create wrapper with jq-edit + merge | Works mechanically; requires ~30+ call-site changes + race window |
| W4 | `sqlite3 UPDATE` + `br sync --flush-only --force` | Works with `--force` bypass; concurrency exposure |
| W5 | `BEADS_SOURCE_REPO=...` env var | REJECT — env var does not exist in source |

Decision: **file issue**. Upstream commit `648b50f1` already has the canonical fix on master; issue asks for release or clarification on the upgrade path between `03167479` (basename) and `648b50f1` (absolute path), plus the `br update --source-repo` flag for repairing already-leaked rows.

## Bug-shape correction discovered during research

Original wz5rh draft attributed the bug to `issue_prefix → source_repo`. Research found the actual mechanism: `canonical_source_repo(beads_dir)` returns the basename of the canonicalized parent of `.beads/`. The basename happens to equal the `issue_prefix` in flywheel's case (both `flywheel`) — that's where the original confusion came from.

The filed issue uses the corrected root cause and cites the relevant commits (`03167479` → `912126d8` → `648b50f1`) with source-cite chain.

## Acceptance

The bead title is "file beads_rust upstream issue for --source-repo flag on br create per wz5rh draft". The deliverable is the filing.

- ✅ Issue filed: #289
- ✅ Rule 1 satisfied (`feedback_jeff_issue_chain`): clear problem statement, repro, observed-vs-expected, version, references our local commit; not a PR
- ✅ Rule 2 satisfied (`feedback_jeff_issue_requires_full_workaround_research_first`): 5 workarounds researched, source-cited, copy-tested in `mktemp -d` fixtures, 2 viable (W3, W4) ruled out for routine fleet use, 2 rejected outright (W2, W5), 1 already in production for one-shot use (W1)
- ✅ Bug shape corrected from wz5rh draft (issue_prefix → canonical_source_repo basename)
- ✅ Strengthened evidence: cites upstream commits that pinpoint the fix history

## Files changed

- New: `.flywheel/audit/flywheel-6kdnf/workaround-research.md` (subagent output)
- New: `.flywheel/audit/flywheel-6kdnf/issue-body-final.md` (filed body)
- New: `.flywheel/audit/flywheel-6kdnf/filed-issue-receipt.json` (gh issue view receipt)

## L112 verify probe

`gh issue view 289 --repo Dicklesworthstone/beads_rust --json state | jq -r .state`
Expected: `grep:OPEN` (until Jeff closes)
