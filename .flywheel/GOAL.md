# flywheel Goal

schema_version: 1
doc_type: goal
status: locked
repo: /Users/josh/Developer/flywheel
repo_realpath: /Users/josh/Developer/flywheel
installed_from: /Users/josh/Developer/flywheel/templates/flywheel-install
template_version: "0.1.0"
template_hash: 43d3b3f39af636be079de8e8d2728360fced885e6438c26afd88f5e461a17ebf
rendered_at: 20260501T052023Z
rendered_by: flywheel-loop-reconcile
lock_hash: 4f90a45d22b52c0e1ad6f1a251618cc921de8e471c3ea35b7fba07872be8904d
locked_at: 2026-05-13T22:58:13Z
locked_by: template-live-doc-backfill
source_path: /Users/josh/Developer/flywheel/.flywheel/GOAL.md
source_sha256: 576e5bb5975e223e3fb10e498a9d405f0d38ee56df7352dbaa3513af9d91fc03
source_section: legacy compact live doc
provenance_note: Backfilled from the flywheel legacy operational goal without removing live sections.

## Current Goal

Make Flywheel truly publishable: complete ecosystem renaming, publish the repo
and installable package surfaces, and prove end-to-end install/run workflows in
isolated environments for Claude, Codex, Gemini, and OpenClaw with full runbooks
and public journey stories.

This supersedes the May 12 public-preview readiness closeout. Public-preview
evidence is useful prior art, but it is not sufficient for this goal.

## Publication Definition

True publishability means a business owner, developer, or agent operator can
find the public repo from a ZestStream surface, understand what Flywheel is,
install it without Joshua-local assumptions, run a guided journey, and inspect
the receipts that prove the system behaves across supported agent surfaces.

The claim is not publishable until every supported path has an isolated proof,
not just local macOS evidence.

Every TODO, gap item, audit finding, doctor warning, unproven support claim,
private-overlay dependency, and release-blocking ambiguity must be either
closed with an executable receipt or carried in a named release-blocker registry
with owner, evidence, next action, and disposition. No informal "later" bucket is
allowed for this goal.

## Required Workstreams

1. Rename the ecosystem surfaces so public names, package names, CLI names,
   docs, examples, tests, receipts, templates, and generated artifacts are
   coherent and free of stale private naming.
2. Separate publishable engine from private overlay: classify, remove, rewrite,
   or gate Joshua-local paths, private client references, secrets-shaped
   examples, and non-distributable SkillOS/JSM/Agent Mail dependencies.
3. Publish the public repo/package surfaces, including install entrypoints,
   version metadata, release notes, license posture, and a clean public branch
   or export path.
4. Prove fresh install and first-run flows in isolated environments for:
   Claude, Codex, Gemini, OpenClaw, and reduced local mode.
5. Produce public runbooks and journey stories for each path, including what
   the user sees, what the agent does, how failure is diagnosed, and where
   receipts live.
6. Keep long-running checks fast: apply profile-first optimization to any
   publication validation path that becomes materially slow.
7. Coordinate with SkillOS and adjacent repos when a missing skill, public
   boundary, or reusable substrate gap is discovered.
8. Maintain a release-blocker registry that accounts for every TODO/gap item
   found during publication work until it is closed, deferred with an explicit
   non-release disposition, or promoted into a tracked issue/bead.

## Measured Acceptance Criteria

- A clean clone or exported public repo can install without `/Users/josh`,
  private `.claude`, private `.flywheel`, NTM-only, or local database
  assumptions.
- Every public first-run command works in a disposable isolated environment.
- Claude, Codex, Gemini, and OpenClaw each have an end-to-end receipt covering
  install, doctor/preflight, first action, failure handling, and closeout.
- Reduced local mode remains a guaranteed fallback when multi-agent substrate is
  absent.
- Public runbooks exist for all supported paths and contain exact commands,
  expected outputs, troubleshooting branches, and receipt locations.
- Public journey stories exist for SMB/business-owner trust and developer
  operator trust.
- Naming tests reject stale private names and verify final public names across
  docs, scripts, templates, tests, and package metadata.
- Publishability doctor/probe reports pass or blocks release with a concrete
  next action; no warning is allowed to be waved through without classification.
- The release surface is actually published or staged in the exact public
  location named by the release plan.
- The release-blocker registry has zero unowned rows and no open `release_blocker`
  rows at final publication time.

## Validation Commands

- `/Users/josh/Developer/flywheel/tests/naming-conventions.sh`
- `/Users/josh/Developer/flywheel/tests/public-flywheel-cli.sh`
- `/Users/josh/Developer/flywheel/tests/zeststream-public-prepublish-hook.sh`
- `/Users/josh/Developer/flywheel/tests/installer-smoke.sh`
- `/Users/josh/Developer/flywheel/tests/journey-smoke.sh`
- `/Users/josh/Developer/flywheel/tests/true-publication-registry-validate.sh`
- `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json`
- `/Users/josh/Developer/flywheel/tests/isolated-agent-lane-smoke.sh`
- `/Users/josh/Developer/flywheel/tests/agent-lane-probe.sh`
- `/Users/josh/Developer/flywheel/tests/public-surface-gap-scanner.sh`
- `/Users/josh/Developer/flywheel/tests/publication-readiness.sh`
- Current isolated agent receipts cover Claude, Codex, Gemini, OpenClaw, and
  reduced local mode; final release still depends on the live remote, workflow,
  release-asset, and signoff blockers reported by `publication_readiness.py`.
- TODO/gap scan coverage is executable and release-bound through
  `public-surface-gap-scanner.sh`, the true-publication registry, Beads, and
  explicit non-release dispositions.

## Current Blockers

- The repository/export path is not yet public.
- Public GitHub Actions workflows have not yet run green on the public default
  branch.
- The `v0.2.0` GitHub release and required checksum-bearing assets are not yet
  published.
- Joshua's release signoff receipt is intentionally pending until the real
  public remote, workflow, release, website, install proxy, external-review,
  and signoff surfaces pass.
- Private-live site and install proxy evidence can support review, but it is
  not a substitute for the final public cutover proof.

## Safe Next Action

Keep the six live release blockers visible, refresh any stale public-readiness
wording that conflicts with current receipts, and do not promote the public repo
or release until the cutover receipt bundle and Joshua signoff pass against the
actual public surfaces.

## Out Of Scope

- Claiming Gemini or OpenClaw full support from registry-only dry-run evidence.
- Publishing Joshua-private overlays, client material, secrets-shaped fixtures,
  or machine-local assumptions.
- Treating NTM as required for every user; NTM is one supported path, not the
  only operating mode.
- Declaring final release on the basis of local macOS success alone.

## Lock Receipt

Re-locked on 2026-05-13 to capture the true publishability goal requested by
Joshua: renamed, published, isolated, cross-agent, runbooked, and story-backed.
