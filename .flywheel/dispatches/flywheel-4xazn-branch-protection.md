# flywheel-4xazn — Branch protection rules fleet-wide

## Context

Joshua-direct 2026-05-20 deep git workflow analysis (.flywheel/audits/git-workflow-fleet-analysis-20260520.md) identified branch-protection-rules as Phase 1 P0. Auto-merge enabled today (flywheel + skillos + zesttube + mobile-eats + clutterfreespaces). Now: configure branch protection so auto-merge fires ONLY on green CI without requiring human review for substrate repos.

## Deliverables

### A. .flywheel/scripts/branch-protection-apply.sh
- Bash script idempotent.
- Flags: --repo OWNER/REPO --branch main --apply | --dry-run --json
- Sets via `gh api -X PUT repos/OWNER/REPO/branches/BRANCH/protection`:
  - `required_status_checks`: object with `strict=true` and `contexts` array (discovered from existing workflows OR explicit --check-names "ci,smoke,shellcheck")
  - `required_pull_request_reviews=null` for substrate repos (Claude/codex are reviewers via /flywheel:review bot)
  - `enforce_admins=false` (Joshua can override in emergencies)
  - `restrictions=null` (no push restrictions; auto-merge handles)
  - `required_linear_history=true` (squash-merge enforces clean history)
  - `allow_force_pushes=false`
  - `allow_deletions=false`
- Auto-discover CI check names: parse .github/workflows/*.yml for job names + fallback to `gh api repos/OWNER/REPO/actions/runs --jq '.workflow_runs[0:5][].name'`
- Print before/after JSON diff
- Emit envelope: `{"schema_version":"branch_protection_apply.v1","ts":"...","repo":"...","branch":"...","outcome":"applied|dry-run|error","required_checks":[...]}`

### B. .flywheel/scripts/branch-protection-fleet-rollout.sh
- Iterate the 5 flywheel-managed repos: flywheel + skillos + zesttube + mobile-eats + clutterfreespaces
- For each: call branch-protection-apply.sh --apply --json
- Aggregate result envelope
- Picoz EXCLUDED (perms issue — flywheel-02oow tracks investigation)
- Per-repo override config at `.flywheel/state/branch-protection-overrides.json` (some repos may want different settings — e.g., legal-billing repos keep required_pull_request_reviews=1)

### C. tests/branch-protection-apply-smoke.sh
- 6+ assertions:
  1. --dry-run on real repo emits valid envelope without mutation
  2. --apply on test branch sets expected fields via mock gh API
  3. Auto-discovery of CI check names from .github/workflows/*.yml works
  4. Override config file respected when present
  5. Idempotent re-apply produces same final state
  6. enforce_admins stays false (Joshua override path preserved)

### D. .flywheel/doctrine/branch-protection-discipline.md
- Document the decision: substrate repos (flywheel, skillos, zesttube-* substrate, etc.) — required_pull_request_reviews=null + required_status_checks=CI green.
- Client-facing legal/billing repos — keep required_pull_request_reviews=1.
- Override path: enforce_admins=false so Joshua can force-push or bypass in emergencies; audit-log the override.
- Cite the 8-gate taxonomy from .flywheel/audits/git-workflow-fleet-analysis-20260520.md as the doctrine basis.

## Acceptance

- All 4 artifacts ship (apply script + fleet rollout + smoke + doctrine)
- shellcheck PASS on bash scripts
- Smoke fixture 6/6 PASS
- Live dry-run output on flywheel repo shows what would be set (no actual mutation)
- Bead flywheel-4xazn closed
- Per-repo overrides config present at .flywheel/state/branch-protection-overrides.json (empty default; flywheel-side opinionated defaults document the substrate-vs-client distinction)
- DO NOT actually apply the protection rules — that's Joshua-gate (sets Phase 1 production policy). Ship the apply script, run --dry-run on each repo, generate the report, await Joshua's apply directive.

## Loop contract

- Track 3 only.
- mcp-agent-mail file_reservation_paths before edits.
- socraticode K>=10 with 2 phrasings on existing branch-protection patterns + gh api usage + GitHub branch-protection schema docs.
- Bridge daemon LIVE — auto-routes callback. Belt+suspenders: ntm send flywheel --pane=1.
- SCR event: C7_verification_density + C6_trauma_outflow (Joshua-keystroke-per-merge removal class).
- STOP on Track 1/2 breach, BLOCKED, agent-mail loop fail, >3h hard cap.
- DEEP-WORK validate: shellcheck + smoke + dry-run on flywheel repo + dry-run on skillos repo.
- DO NOT modify any actual GitHub repo settings via apply mode in this sprint — Joshua-gate required.

## FIRST ACTION

1. br show flywheel-4xazn.
2. Read .flywheel/audits/git-workflow-fleet-analysis-20260520.md sections "Gate 1-3" and "Phase 1".
3. ACK row.
4. socraticode existing branch-protection patterns + GitHub API.
5. Implement 4 artifacts.
6. Self-validate (shellcheck + smoke + 2 live dry-runs).
7. Generate fleet dry-run report at .flywheel/audits/branch-protection-fleet-dry-run-20260520.md showing what would be set per repo.
8. Commit + close bead + DIRECT pane-1 ntm send + truth-verify status=closed.
