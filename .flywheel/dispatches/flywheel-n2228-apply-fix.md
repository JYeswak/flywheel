# flywheel-n2228 — Fix branch-protection-apply.sh per-repo discovery bug

## Context

2026-05-20T02:46Z apply run used hardcoded flywheel default check names for ALL 5 repos (zesttube, mobile-eats, CFS, flywheel-itself, attempted-skillos). Wrong check names blocked PR merges. Joshua had to manually revert via gh api DELETE. The dry-run REPORT had correct per-repo names — the apply PATH didn't use them.

This is a `dry_run_apply_divergence` trauma class (paired bead: flywheel-vlodi for the broader doctrine).

## Root cause hypothesis (verify in socraticode)

`.flywheel/scripts/branch-protection-apply.sh` has two paths:
- `--dry-run` mode: runs discovery (parses .github/workflows/*.yml + recent gh api actions runs) → emits correct per-repo names
- `--apply` mode: skips discovery, uses hardcoded default array

OR

- Both paths use discovery but apply mode pulls from a different config file that wasn't populated
- OR `.flywheel/state/branch-protection-overrides.json` has stale/wrong data for non-flywheel repos

## Deliverables

### A. Fix .flywheel/scripts/branch-protection-apply.sh
- Apply path MUST call same discovery function as dry-run path
- Discovery shape: for each repo:
  1. Parse `.github/workflows/*.yml` job names from a checked-out copy OR via `gh api repos/X/contents/.github/workflows`
  2. Cross-reference with recent runs: `gh api repos/X/actions/runs --jq '.workflow_runs[0:20] | unique_by(.name) | .[].name'`
  3. Use intersection as canonical required-checks list
  4. If override exists in `.flywheel/state/branch-protection-overrides.json` for that repo, prefer override
  5. Document the discovery decision in JSON envelope as `discovery_source: workflow_yml|recent_runs|override|union`

### B. Smoke fixture extension
`tests/branch-protection-apply-smoke.sh` (already 10 assertions, extend):
- Mock 2 repos with different .github/workflows/*.yml content
- Apply each: verify per-repo correct check names
- Assert dry-run and apply produce IDENTICAL check-name lists for same repo
- Add divergence-detection assertion: if dry-run JSON.required_checks != apply JSON.required_checks for same input, FAIL

### C. Re-run dry-run report
After fix, regenerate `.flywheel/audits/branch-protection-fleet-dry-run-20260520.md` with the actually-correct per-repo check names. The dry-run report from today may have been right OR may have had the same bug — verify.

### D. Add parity assertion to the script
Add `--verify-parity` flag: runs both dry-run logic + apply pre-mutation logic on same input + diffs. Exits non-zero if mismatch. This is the first concrete implementation of the broader dry-run/apply parity contract (flywheel-vlodi).

## Acceptance

- branch-protection-apply.sh in apply mode uses same discovery as dry-run mode
- Smoke fixture extended with parity assertion (12+ total)
- Re-generated dry-run report shows per-repo correct check names
- shellcheck PASS
- Bead flywheel-n2228 closed

## Out of scope (separate beads)

- Re-applying protection to the 4 repos — Joshua-gate after fix verifies (filed: re-apply bead TBD)
- Broader dry-run/apply parity contract across other scripts — flywheel-vlodi
- DCG pre-authorized-scopes — flywheel-8iook

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits to apply.sh + smoke fixture
- socraticode K>=10 with 2 phrasings on branch-protection-apply.sh + gh api workflow discovery patterns
- Bridge daemon LIVE
- SCR event: C7_verification_density + C6_trauma_outflow (dry-run/apply divergence class)
- STOP on Track 1/2 breach, BLOCKED, >2h hard cap
- DEEP-WORK validate: shellcheck + smoke + 2 live dry-runs comparing before/after fix
- DO NOT actually re-apply protection to GitHub repos — that's separate Joshua-gate

## FIRST ACTION

1. br show flywheel-n2228.
2. Read .flywheel/scripts/branch-protection-apply.sh end-to-end.
3. Read .flywheel/audits/branch-protection-fleet-dry-run-20260520.md to see what dry-run claimed.
4. ACK row.
5. socraticode existing discovery patterns.
6. Identify the divergence root cause.
7. Fix + extend smoke + re-generate report.
8. Self-validate.
9. Commit + close bead + DIRECT pane-1 ntm send.
