# Release Cutover Authorization

This runbook is the public operator checklist for moving Flywheel from a
locally verified release candidate to a live public release. It is deliberately
separate from release approval: passing this checklist tells you what remains;
it does not authorize public actions by itself.

Agents may prepare evidence and re-run gates. Agents must not make the
repository public, push the release tag, publish GitHub releases, deploy DNS or
site surfaces, or create an approved signoff unless Joshua explicitly
authorizes the cutover.

## Authoritative Gate

Run:

```bash
python3 scripts/publication_readiness.py --json
python3 scripts/publication_readiness.py --release --json
```

Before cutover, the expected status is `blocked`. The release is complete only
when release mode returns `status=pass` with zero blockers against real remote,
release, website, install-proxy, external-review, and signoff surfaces.

## Cutover Decisions

| Decision | Blocker code | Operator command | Required verification |
|---|---|---|---|
| Make the approved repository or export path public. | `remote_repo_private` | `gh repo edit JYeswak/flywheel --visibility public` | `gh repo view JYeswak/flywheel --json visibility,isPrivate` reports public and not private. |
| Push publication workflow files to the remote default branch. | `remote_workflows_missing` | Push the reviewed branch or public export containing `.github/workflows/ci.yml`, `installer-smoke.yml`, `release.yml`, and `site.yml`. | `gh api repos/JYeswak/flywheel/actions/workflows --jq '.workflows[].name'` includes `CI`, `Installer Smoke`, `Release`, and `Site Deploy`. |
| Run remote CI and installer smoke to green. | `remote_green_runs_missing` | Trigger or wait for Actions on the public default branch. | `gh run list --repo JYeswak/flywheel --limit 20 --json workflowName,status,conclusion,headBranch` shows successful `CI` and `Installer Smoke` runs on the default branch. |
| Create the public release tag and release after gates pass. | `github_release_missing_or_draft` | `git tag v0.2.0 && git push origin v0.2.0`, then publish the GitHub release from the release workflow. | `gh release view v0.2.0 --repo JYeswak/flywheel --json tagName,isDraft,isPrerelease,url` reports `isDraft=false` and `isPrerelease=false`. |
| Attach and verify required release assets. | `github_release_assets_missing` | Run the release workflow for `v0.2.0`. | Release assets include `install.sh`, `install.sh.sha256`, `SHA256SUMS`, `flywheel-v0.2.0.tar.gz`, and `flywheel-v0.2.0.tar.gz.sha256`; each required asset is uploaded, non-empty, and exposes `sha256:` digest metadata. |
| Deploy the public website. | `website_unavailable` | Run the site workflow and configure `flywheel.zeststream.ai` DNS if needed. | `curl -fsSI https://flywheel.zeststream.ai/` returns a successful status. |
| Confirm deployed site copy is current. | `website_content_stale` | Deploy the reviewed SMB/Yuzu site build. | `publication_readiness.py --release --json` reports `website_content_current` and no `website_content_stale` blocker. |
| Publish matching install proxy assets. | `install_proxy_checksum_mismatch` | Publish `install.sh` and `install.sh.sha256` from the same release artifact set. | `curl -fsSL https://flywheel.zeststream.ai/install.sh \| shasum -a 256` matches the checksum served at `https://flywheel.zeststream.ai/install.sh.sha256`. |
| Refresh external review for the current public trust surface. | `external_review_gate_blocked` | Collect two distinct independent review rows covering README, charter, first-run, public release, cutover, publication evidence, and blocker-coverage evidence docs. | `python3 scripts/validate_external_review.py --release --json` returns `status=pass`. |
| Create final Joshua signoff after all real checks pass. | `joshua_release_signoff_missing` | Copy the release signoff template to `release-signoff.json` and set approved fields. | `publication_readiness.py --release --json` returns `status=pass` with zero blockers. |

## Signoff Boundary

The signoff file is last. It must remain absent or pending until all real public
surfaces pass. A fixture, local staging export, private review packet, or
successful local test suite is useful evidence, but it is not enough to approve
the release.

Required signoff fields:

| Field | Required value |
|---|---|
| `schema_version` | `flywheel.release_signoff.v0` |
| `status` | `approved` |
| `approver` | `Joshua Nowak` |
| `remote` | `JYeswak/flywheel` |
| `tag` | `v0.2.0` |
| `signed_at` | ISO-8601 UTC timestamp ending in `Z` |

## Stop Conditions

Stop and keep TP-005, TP-017, or TP-018 open, and reopen TP-015 if the
external-review gate regresses, when any of these are true:

- `publication_readiness.py --release --json` returns `blocked`;
- GitHub Actions does not show both `CI` and `Installer Smoke` successful on
  the public remote;
- the release exists but is a draft or lacks any required asset;
- the website endpoint is unavailable;
- the website is reachable but still serves stale copy that lacks the approved
  SMB/Yuzu journey markers;
- the install proxy checksum does not match;
- the external-review log does not cover the current public trust surface;
- Joshua has not explicitly approved release signoff.

## Closeout Evidence

After cutover, capture these receipts before closing the goal:

```bash
python3 scripts/publication_readiness.py --json > publication-readiness.json
python3 scripts/publication_readiness.py --release --json > publication-readiness-release.json
python3 scripts/validate_user_journey_pack.py --json > user-journey-pack-validation.json
jq -e '.status == "pass" and (.errors | length) == 0' \
  user-journey-pack-validation.json
gh repo view JYeswak/flywheel --json nameWithOwner,visibility,isPrivate,defaultBranchRef,url > repo-view.json
gh api repos/JYeswak/flywheel/actions/workflows > remote-workflows.json
gh run list --repo JYeswak/flywheel --limit 20 --json workflowName,status,conclusion,headBranch > remote-runs.json
gh release view v0.2.0 --repo JYeswak/flywheel --json tagName,isDraft,isPrerelease,url,assets > release-view.json
python3 scripts/validate_external_review.py --release --json > external-review-release.json
jq '{schema_version,status,approver,remote,tag,signed_at}' \
  .flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json \
  > release-signoff.receipt.json
curl -fsSI https://flywheel.zeststream.ai/ > website-head.txt
python3 scripts/live_site_probe.py --base-url https://flywheel.zeststream.ai/ --json \
  > live-site-probe.json
jq -e '.status == "pass" and .failure_count == 0' live-site-probe.json
python3 - <<'PY'
import importlib.util, json
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "publication_readiness", "scripts/publication_readiness.py"
)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
for url, out in [
    ("https://flywheel.zeststream.ai/", "website-probe.json"),
    ("https://flywheel.zeststream.ai/install.sh", "install-probe.json"),
    ("https://flywheel.zeststream.ai/install.sh.sha256", "install-sha256-probe.json"),
]:
    probe, error = module.probe_url(url)
    if error:
        raise SystemExit(error)
    Path(out).write_text(json.dumps(probe, separators=(",", ":")) + "\n")
PY
curl -fsSL https://flywheel.zeststream.ai/install.sh | shasum -a 256 | awk '{print $1}' > install-sha256.actual
curl -fsSL https://flywheel.zeststream.ai/install.sh.sha256 | awk '{print $1}' > install-sha256.expected
diff -u install-sha256.expected install-sha256.actual
python3 scripts/publication_readiness.py --release --json \
  --repo-view-json repo-view.json \
  --workflows-json remote-workflows.json \
  --runs-json remote-runs.json \
  --release-json release-view.json \
  --review-json external-review-release.json \
  --website-probe-json website-probe.json \
  --install-probe-json install-probe.json \
  --install-sha256-probe-json install-sha256-probe.json \
  --signoff-json release-signoff.receipt.json \
  > publication-readiness-replay.json
jq -e '.status == "pass" and (.blockers | length) == 0' \
  publication-readiness-replay.json
python3 scripts/validate_cutover_receipts.py --receipt-dir . --release --json \
  > cutover-receipts-validation.json
jq -e '.status == "pass" and (.errors | length) == 0' \
  cutover-receipts-validation.json
```

Refresh the completion audit only after these receipts exist and the release
gate passes against real public surfaces.
