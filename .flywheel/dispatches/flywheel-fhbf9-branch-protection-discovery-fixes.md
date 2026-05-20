# flywheel-fhbf9 — Fix branch-protection-apply.sh check-name discovery (matrix expansion + run-frequency filter + skillos repo name)

## Context

flywheel-n2228 fixed the per-repo discovery hardcoded-defaults bug (Joshua had to revert wrong-applied protection). Post-n2228 dry-run + canonical-truth probe (this bead) found 3 additional bugs in the discovery layer:

### Bug 1 — Matrix literal not expanded
Dry-run emits `Install Doctor Uninstall (${{ matrix.os }})` (unexpanded YAML literal). Actual status-check names on PRs are `Install Doctor Uninstall (macos-14)` and `Install Doctor Uninstall (ubuntu-22.04)` (matrix-expanded by GitHub Actions runner). Required-checks list with the unexpanded literal would never match → PR gated forever.

Fix: parse `strategy.matrix.*` in workflow YAML + emit one required-check per matrix combination.

### Bug 2 — Workflow run-frequency filter missing
Dry-run includes workflows like `Package Release`, `Deploy Static Site`, `Fresh-clone preflight + journey-smoke (public path)` that don't run on every PR to main (tag-push triggers, schedule triggers, branch-filter triggers). Including these as required-checks gates PRs on workflows that may never fire for them.

Fix: probe each workflow YAML's `on:` triggers — only include workflows that fire on `pull_request` to default branch (main/master) AS required-checks. Schedule/tag/manual workflows should be EXCLUDED from required-checks (they can still gate releases via other means).

### Bug 3 — skillos repo name wrong (HTTP 307)
Dry-run targets `JYeswak/zeststream-skillos` which redirects (HTTP 307) — actual repo is `JYeswak/skillos`. Fleet-rollout config or apply.sh has wrong slug.

Fix: in fleet rollout config, change `JYeswak/zeststream-skillos` → `JYeswak/skillos`. Verify via `gh repo view <slug>` before apply.

## Deliverables

### A. Patch .flywheel/scripts/branch-protection-apply.sh
- Add matrix expansion: parse `strategy.matrix` in workflow YAML, expand all key×value combinations, emit one required-check per combo formatted as `<job-name> (<matrix-value>)` for single-axis OR `<job-name> (<v1>, <v2>)` for multi-axis (verify the exact pattern GitHub uses)
- Add run-frequency filter: parse workflow `on:` triggers, INCLUDE only workflows that fire on `pull_request` (with default-branch target if specified)
- Emit `discovery_details` field in envelope showing per-check the source workflow + matrix expansion + trigger reason

### B. Patch fleet-rollout config (.flywheel/state/branch-protection-overrides.json or wherever the repo list lives)
- Correct `JYeswak/zeststream-skillos` → `JYeswak/skillos`
- Add `gh repo view <slug>` verification step before each apply call

### C. Re-run dry-run with patched discovery
- Generate corrected `.flywheel/audits/branch-protection-fleet-dry-run-fhbf9-corrected-<ts>.md`
- Compare side-by-side with previous dry-run to surface what changed
- Specific verification: flywheel dry-run should now produce `Install Doctor Uninstall (macos-14)` + `Install Doctor Uninstall (ubuntu-22.04)` as separate required-checks, NOT the unexpanded literal

### D. Smoke fixture extension
Extend `tests/branch-protection-apply-smoke.sh`:
- Synthetic workflow with strategy.matrix.os = [macos-14, ubuntu-22.04] → emit 2 required-checks
- Synthetic workflow with on:schedule only → EXCLUDED from required-checks
- Synthetic workflow with on:pull_request → INCLUDED
- Synthetic workflow with on:[push, pull_request] → INCLUDED
- Existing parity assertion still passes
- Total: 20+ assertions (current was 10 + at minimum 4 new + canonical regression)

### E. Cross-validate with actual flywheel PR data
Run patched dry-run against flywheel, compare list to actual recent PR check names from `gh pr checks <num>`. Document the exact-match rate in the audit report.

## Acceptance

- 3 bugs patched
- Smoke fixture extended
- Post-patch dry-run report generated
- Exact-match rate ≥ 90% against actual recent-PR check names for flywheel
- shellcheck PASS
- Bead flywheel-fhbf9 closed
- DO NOT actually re-apply protection — that's a separate Joshua-gate after this fix lands + dry-run reviewed

## Out of scope

- Actually re-applying protection (Joshua-gated separately after pruning-by-relevance review per repo — some repos like CFS have 19 candidate workflows; trim to top 3-5 load-bearing)
- Branch-protection schema changes beyond required_status_checks
- Branch-protection on protected branches other than main/master

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits to apply.sh + smoke fixture
- socraticode K>=10 with 2 phrasings on existing apply.sh structure + GitHub Actions matrix expansion docs + gh CLI workflow API
- Bridge daemon LIVE
- SCR event: C7_verification_density (canonical-truth probe of actual PR check names) + C6_trauma_outflow (prevents future wrong-applies)
- STOP on Track 1/2 breach, BLOCKED, >2h hard cap

## FIRST ACTION

1. br show flywheel-fhbf9.
2. Read .flywheel/audits/branch-protection-fleet-dry-run-post-n2228-fix-20260520T071031Z.md (current dry-run with the bugs).
3. Read recent PR check names via `gh pr checks 24 --repo JYeswak/flywheel` and `gh pr checks 25 --repo JYeswak/flywheel` for the canonical truth source.
4. ACK row.
5. Patch + smoke + dry-run + cross-validate.
6. Commit + close + DIRECT pane-1 ntm send.
