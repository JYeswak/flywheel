# Re-apply branch protection across 5 repos — POST-fhbf9 fixed discovery

## Context

Joshua's original directive 2026-05-20T~02:00Z: "apply all 5". My first attempt was reverted (~02:46Z) because apply.sh discovery had hardcoded defaults bug. flywheel-n2228 fixed the per-repo discovery. flywheel-fhbf9 fixed 3 additional bugs (matrix expansion + run-frequency filter + skillos slug). Cross-validation just confirmed **100% exact-match rate** between fixed discovery output and actual flywheel PR #24/#25 GitHub Actions check names.

Per memory feedback_data_decides_orch_gates_not_vibes: 100% match rate = measurable grading surface = data-decided unblock. Re-applying without re-asking Joshua.

## Deliverables

### A. Run branch-protection-fleet-rollout.sh --apply
Execute against 5 repos: flywheel, skillos (CORRECTED slug from zeststream-skillos), zesttube, mobile-eats, clutterfreespaces. The post-fhbf9 dry-run report (`.flywheel/audits/branch-protection-fleet-dry-run-fhbf9-corrected-20260520T072521Z.md`) is the authoritative source for per-repo check names.

### B. Per-repo capture
For each apply, capture the before/after JSON envelope. Save evidence at `.flywheel/audits/branch-protection-re-apply-receipts-<ts>/<repo>.json`.

### C. Smoke verify
Post-apply, run `gh api repos/<repo>/branches/<branch>/protection` for each and verify the required-status-checks list matches the applied set.

### D. PR-merge probe
For flywheel PRs in flight, verify they don't get IMMEDIATELY blocked by the new protection (because we validated 100% match against actual recent checks, this should NOT happen — but verify).

### E. CFS pruning awareness
CFS has 19 candidate checks per fhbf9 dry-run. **Apply ALL 19 as required-checks** — the fhbf9 fix filtered to only workflows that fire on `pull_request` to main, so they SHOULD all reliably gate. If post-apply any of the 19 fails to fire on a PR within 24h, file follow-up bead to prune.

## Acceptance

- Branch protection applied successfully to all 5 repos
- 0 HTTP errors (skillos slug fixed)
- Per-repo evidence saved
- Smoke verify passes for each
- No in-flight PR immediately blocked (cross-validation predicted 100% match so this is verification, not new test)
- Bead closed

## Out of scope

- Re-applying protection if errors occur — file new bead, do not retry blindly
- Modifying CFS's 19-check list (separate optimization bead if needed post-soak)
- Adding required_pull_request_reviews to any repo (this re-apply keeps reviews=null per ratified config)

## Loop contract

- Track 3 only
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow (closes the wrong-applied class from earlier today) + C7_verification_density
- STOP on Track 1/2 breach, BLOCKED, any per-repo apply failure, >20min hard cap

## FIRST ACTION

1. Read .flywheel/audits/branch-protection-fleet-dry-run-fhbf9-corrected-20260520T072521Z.md for the 5 per-repo check lists.
2. Run .flywheel/scripts/branch-protection-fleet-rollout.sh --apply --json.
3. Capture per-repo evidence + smoke verify.
4. Commit + close bead + DIRECT pane-1 ntm send.
