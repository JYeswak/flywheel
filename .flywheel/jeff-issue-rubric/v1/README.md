# Jeff Issue Rubric v1

This rubric gates draft GitHub issues for Jeff Emanuel's repos before posting.
The policy is deliberately strict:

- 7 high axes: `auto_post`
- 6 high axes: `revise`
- 0-5 high axes: `withdraw`

Any axis below `high` makes the rubric status `fail`; the decision explains
whether the draft should be revised or withdrawn.

## Axes

1. `bug_reality`: observed behavior, expected behavior, repro, version/commit,
   and cost citation.
2. `dedup`: targeted `gh issue list` search with no visible duplicate.
3. `source_trace`: upstream file:line citations plus version context.
4. `signal_not_prescription`: describe the contract gap, not Jeff's
   implementation.
5. `tone_match`: direct, evidence-led, concise, and Joshua-flavored.
6. `jeff_thank_test_hostile`: no generic thanks, vendor framing, demands, or
   hostile wording.
7. `no_derail`: no secrets, no PR/patch ask, no broad feature request, explicit
   out-of-scope, and flywheel tracking bead.

## Commands

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-issue-rubric.py \
  --draft /tmp/jeff-issue-runtime-handoff-singleton.md \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-issue-rubric.py \
  --draft /tmp/jeff-issue-runtime-handoff-singleton.md \
  --write-receipt \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-issue-rubric.py \
  --doctor \
  --json
```

Doctor mode scans `/tmp/jeff-issue-*.md` and reports
`jeff_drafts_unrubricd_count` for drafts without a current receipt. Receipts are
stored under `.flywheel/jeff-issue-rubric/v1/receipts/` and keyed by draft hash.
