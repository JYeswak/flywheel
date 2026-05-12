# flywheel-wire-worker-close-requires-git-commit-a1912c82 Evidence

## Scope

- Wired `worker-close-requires-git-commit` into `.flywheel/scripts/meta-rule-structural-batch-gate.sh`.
- Added `.flywheel/tests/test-worker-close-requires-git-commit.sh` to prove the live memory rule is registered and parity-classified `WIRED`.
- Updated `INCIDENTS.md` structural batch coverage from 36 to 37 rules.

## Validation

- `bash -n .flywheel/scripts/meta-rule-structural-batch-gate.sh .flywheel/tests/test-worker-close-requires-git-commit.sh tests/test_worker_close_requires_git_commit.sh`
- `shellcheck .flywheel/scripts/meta-rule-structural-batch-gate.sh .flywheel/tests/test-worker-close-requires-git-commit.sh tests/test_worker_close_requires_git_commit.sh`
- `bash .flywheel/tests/test-worker-close-requires-git-commit.sh`
- `MEMORY_RULE_GATE_PARITY_LEDGER="$(mktemp -t worker-close-parity-ledger.XXXXXX)" .flywheel/scripts/memory-rule-gate-parity-detector.sh check --json | jq -e '.rules[] | select(.memory_path == "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md") | .classification == "WIRED" and .evidence_count >= 3 and (.missing_evidence | length == 0)'`
- `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-wire-worker-close-requires-git-commit-a1912c82-163b56.md`

## Follow-Up Gap

`bash tests/test_worker_close_requires_git_commit.sh` still fails because the
JSM-managed `beads-compliance-and-completion-verification` skill lacks the
deterministic dirty-scope marker expected by that root regression. Filed
`flywheel-tynj3` for the skill-owned fix and appended skill-discovery row
`sd-b2d7b1d0f7e7b1a9`.

## Four-Lens Self-Grade

- brand:8
- sniff:8
- jeff:8
- public:8

## Close Notes

- Shared-surface reservations released for touched paths.
- Agent Mail active reservations checked: none active for flywheel or
  `~/.claude/skills/.flywheel`.
- Scratch cleanup initially hit destructive-command guard for broad deletion
  shapes, then succeeded with narrow non-recursive file removal. Logged
  `scratch-cleanup-dcg-block`.
