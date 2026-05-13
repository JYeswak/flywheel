# Release Cutover Authorization Packet

Generated: 2026-05-13T06:41Z
Status: awaiting explicit Joshua authorization

This packet is the human authorization surface for the remaining public
publication steps. It does not approve any public action by itself. Agents may
prepare evidence and re-run gates, but must not make the repository public,
push the release tag, publish GitHub releases, deploy DNS/site surfaces, or
create an approved signoff unless Joshua explicitly authorizes that cutover.

Public-facing companion:
`docs/runbooks/release-cutover-authorization.md`. Keep the public runbook and
this maintainer packet aligned when blocker codes, commands, or stop conditions
change.

## Current Gate

Authoritative command:

```bash
python3 scripts/publication_readiness.py --json
python3 scripts/publication_readiness.py --release --json
```

Current expected status before cutover: `blocked`.

## Required Authorization Decisions

| Decision | Current blocker | Operator command | Required verification |
|---|---|---|---|
| Make the approved repository or export path public. | `remote_repo_private` | `gh repo edit JYeswak/flywheel --visibility public` | `gh repo view JYeswak/flywheel --json visibility,isPrivate` reports public and not private. |
| Push publication workflow files to the remote default branch. | `remote_workflows_missing` | Push the reviewed branch or public export containing `.github/workflows/ci.yml`, `installer-smoke.yml`, `release.yml`, and `site.yml`. | `gh api repos/JYeswak/flywheel/actions/workflows --jq '.workflows[].name'` includes `CI`, `Installer Smoke`, `Release`, and `Site Deploy`. |
| Run remote CI and installer smoke to green. | `remote_green_runs_missing` | Trigger or wait for Actions on the public default branch. | `gh run list --repo JYeswak/flywheel --limit 20 --json workflowName,status,conclusion,headBranch` shows successful `CI` and `Installer Smoke` runs on the default branch. |
| Create the public release tag and release only after gates pass. | `github_release_missing_or_draft` | `git tag v0.2.0 && git push origin v0.2.0`, then publish the GitHub release from the release workflow. | `gh release view v0.2.0 --repo JYeswak/flywheel --json tagName,isDraft,isPrerelease,url` reports `isDraft=false` and `isPrerelease=false`. |
| Attach and verify required release assets. | `github_release_assets_missing` | Run the release workflow for `v0.2.0`. | Release assets include `install.sh`, `install.sh.sha256`, `SHA256SUMS`, `flywheel-v0.2.0.tar.gz`, and `flywheel-v0.2.0.tar.gz.sha256`; each required asset is uploaded, non-empty, and exposes `sha256:` digest metadata. |
| Deploy the public website. | `website_unavailable` | Run the site workflow and configure `flywheel.zeststream.ai` DNS if needed. | `curl -fsSI https://flywheel.zeststream.ai/` returns a successful status. |
| Publish matching install proxy assets. | `install_proxy_checksum_mismatch` | Publish `install.sh` and `install.sh.sha256` from the same release artifact set. | `curl -fsSL https://flywheel.zeststream.ai/install.sh \| shasum -a 256` matches `https://flywheel.zeststream.ai/install.sh.sha256`. |
| Refresh external review for the current public trust surface. | `external_review_gate_blocked` | Collect two distinct independent review rows covering README, charter, first-run, public release, cutover, publication evidence, and blocker-coverage evidence docs. | `python3 scripts/validate_external_review.py --release --json` returns `status=pass`. |
| Create final Joshua signoff after all real checks pass. | `joshua_release_signoff_missing` | Copy `release-signoff.template.json` to `release-signoff.json` and set approved fields. | `publication_readiness.py --release --json` returns `status=pass` with zero blockers. |

## Signoff Boundary

The signoff file is intentionally last. It must remain absent or pending until
the public repository, remote workflows, green runs, release assets, website,
install proxy checksum, and external-review gate all pass against real
surfaces. A fixture, local staging export, or private review packet is not
enough.

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
- the install proxy checksum does not match;
- the external-review log does not cover the current public trust surface;
- Joshua has not explicitly approved release signoff.

## Closeout Evidence

After cutover, capture these receipts before closing the goal:

```bash
python3 scripts/publication_readiness.py --release --json > publication-readiness-release.json
gh repo view JYeswak/flywheel --json nameWithOwner,visibility,isPrivate,defaultBranchRef,url > repo-view.json
gh api repos/JYeswak/flywheel/actions/workflows > remote-workflows.json
gh run list --repo JYeswak/flywheel --limit 20 --json workflowName,status,conclusion,headBranch > remote-runs.json
gh release view v0.2.0 --repo JYeswak/flywheel --json tagName,isDraft,isPrerelease,url,assets > release-view.json
python3 scripts/validate_external_review.py --release --json > external-review-release.json
jq '{schema_version,status,approver,remote,tag,signed_at}' \
  .flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json \
  > release-signoff.receipt.json
curl -fsSI https://flywheel.zeststream.ai/ > website-head.txt
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

Only then should the completion audit be refreshed and `/goal` marked complete.
