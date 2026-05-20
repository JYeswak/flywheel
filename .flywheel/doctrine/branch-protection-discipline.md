# Branch Protection Discipline

Branch protection is the CI reviewer for Flywheel substrate repos.

Source: `.flywheel/audits/git-workflow-fleet-analysis-20260520.md`, especially
the eight-gate taxonomy. Gates 1-3 define the immediate policy: auto-merge is
enabled, human review should not gate substrate repos, and required status
checks must gate merges.

GitHub API basis: `PUT /repos/{owner}/{repo}/branches/{branch}/protection` in
the REST protected-branches documentation. The endpoint accepts nullable
`required_pull_request_reviews` and `restrictions`, required status-check
contexts, linear-history enforcement, force-push blocking, and deletion
blocking.

## Substrate Repos

For Flywheel-managed substrate repos such as `flywheel`, `skillos`, `zesttube`,
`mobile-eats`, and `clutterfreespaces`, branch protection should require green
CI and should not require human pull-request approval:

- `required_status_checks.strict=true`
- `required_status_checks.contexts=[repo-specific CI checks]`
- `required_pull_request_reviews=null`
- `required_linear_history=true`
- `enforce_admins=false`
- `restrictions=null`
- `allow_force_pushes=false`
- `allow_deletions=false`

Claude/Codex review remains a bot workflow and callback discipline, not a
GitHub required-review gate for substrate repos.

## Client Legal/Billing Repos

Client-facing legal, billing, insurance, payment, or high-liability repos keep
human review:

- `required_pull_request_reviews.required_approving_review_count=1`
- required CI checks still gate merge
- repo-specific overrides live in `.flywheel/state/branch-protection-overrides.json`

## Emergency Override

`enforce_admins=false` preserves Joshua's emergency override path. Any emergency
override should be recorded in the dispatch/callback evidence with the repo,
branch, reason, and follow-up bead if policy or tooling drift caused the bypass.

## Joshua Gate

`.flywheel/scripts/branch-protection-apply.sh` supports `--apply`, but live
production protection changes require Joshua's explicit apply directive. Until
then, fleet work stays in `--dry-run` and produces a report under
`.flywheel/audits/`.
