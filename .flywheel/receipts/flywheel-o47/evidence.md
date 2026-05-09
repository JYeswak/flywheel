# flywheel-o47 Evidence Pack

## Summary

- Added `/flywheel:file-jeff` as the review-only slash-command workflow for Jeff issue filing packs.
- Reused `.flywheel/scripts/jeff-issue.sh` as the single phased gate; no direct skill mutation was made under `~/.claude/skills/dicklesworthstone-stack`.
- Updated `jeff-issue.sh` drafts to render eight sections by adding `## Monitor plan`.
- Extended `tests/jeff-issue.sh` to prove the file-jeff wrapper exists, defaults to dry-run generation, avoids direct filing, and renders an eight-section draft.
- Updated `README.md` slash-command inventory.

## JSM Discipline

`skill-enhance-jsm-discipline.sh --validate-packet /tmp/dispatch_flywheel-o47-52fa5e.md --json` failed closed because `jsm list --json` timed out after 20s.

Decision: no direct skill mutation. The reusable workflow landed in the flywheel slash-command surface and repo-local gate script only.

## Workflow Invocation

Candidate:

```text
Watcher reports healthy when GitHub token is invalid
```

Generated artifacts:

- `.flywheel/receipts/flywheel-o47/source.json`
- `.flywheel/receipts/flywheel-o47/duplicate-search-evidence.json`
- `.flywheel/receipts/flywheel-o47/draft.md`
- `.flywheel/receipts/flywheel-o47/validation-ladder.json`
- `.flywheel/receipts/flywheel-o47/monitor-plan.md`
- `.flywheel/receipts/flywheel-o47/submit-dry-run.json`
- `.flywheel/receipts/flywheel-o47/workflow-summary.json`

Workflow summary:

```json
{
  "source_status": "pass",
  "dedup_mode": "online",
  "dedup_match_count": 0,
  "draft_status": "pass",
  "draft_sections": 8,
  "rubric_status": "fail",
  "rubric_decision": "withdraw",
  "submit_status": "blocked",
  "no_issue_submitted": true
}
```

The candidate draft intentionally did not file: the rubric withdrew it and the submit phase stayed blocked by dry-run, missing Joshua approval, missing idempotency key, and rubric failure. This satisfies the command-generation/no-submission safety gate.

## Verification

```bash
python3 -m py_compile .flywheel/scripts/jeff-issue.sh
bash -n tests/jeff-issue.sh
tests/jeff-issue.sh
```

Observed:

```text
Summary: 26 passed, 0 failed
```

## Skill Routes

- `canonical-cli-scoping=yes`: command remains phased, dry-run default, submit gated by approval and idempotency, JSON outputs and tests.
- `python-best-practices=yes`: touched Python gate keeps typed signatures and fixture-backed validation.
- `readme-writing=yes`: README command inventory updated with a concrete role line only.
- `rust-best-practices=n/a`: no Rust touched.

## Four-Lens Self-Grade

brand: 8
sniff: 8
jeff: 9
public: 8

Three Judges:

- skeptical operator can inspect generated source/draft/rubric/submit-dry-run artifacts
- maintainer can rerun `tests/jeff-issue.sh`
- future worker has a named review-only command instead of an implicit filing ritual
