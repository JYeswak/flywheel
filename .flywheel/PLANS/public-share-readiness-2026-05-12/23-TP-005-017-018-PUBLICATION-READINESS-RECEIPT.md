# TP-005/TP-017/TP-018 Publication Readiness Receipt

Status: blocked on remote publication truth.
Owner: Flywheel + Joshua

This receipt records the current non-proxy state for the final publication
blockers:

- TP-005 public repo/package surface
- TP-017 CI workflows
- TP-018 release signoff

Local packaging, workflow, static website source files, private-live website,
install proxy, external review, and strict agent-lane runtime receipts exist.
Manual Release and Site Deploy dispatches checkout the resolved tag before
packaging or publishing install assets. Release and site checksum manifests use
artifact-relative filenames so downloaded assets can be verified from their own
directory. The remote repository is still private and has no visible GitHub
Actions workflows or runs. The release, asset, and Joshua-signoff surfaces are
also verified explicitly; none can close from local tests alone.

Latest public-export evidence: assembly run `codex-public-export-20260513T2252Z`
classified 14,700 files, copied 10,218 public-safe files, excluded 4,040
denylisted paths, preserved source git status, passed staged readiness,
public-doc, public-link, release-asset, cutover, blocker-coverage, agent-lane,
journey-smoke, and scan-table probes, and retained 7,444 manual-review rows.
This run uses the optimized classifier path that excludes generated
`.flywheel/extraction/**` artifacts before assembly, keeping classification
counts aligned with the staged public export instead of counting prior generated
evidence runs.
It also follows the release-asset digest hardening: publication readiness now
rejects missing or malformed `sha256:` digest metadata on required GitHub
release assets, and the public evidence index names that digest requirement
explicitly.
It also carries the Asupersync gated-adoption packet as public evidence while
keeping that substrate out of the v0.2 runtime, installer, and agent-lane
support claims.
The cutover closeout snippets now capture `headBranch` in `remote-runs.json`,
so saved remote run receipts preserve the default-branch proof required by the
readiness gate.
The public release runbook also names the same default-branch requirement in
its expected closure state.
The cutover closeout block now captures standalone `repo-view.json`,
`remote-workflows.json`, `external-review-release.json`, and
`release-signoff.receipt.json` receipts in addition to publication readiness,
remote runs, release, website, and install checksum evidence.
The main public release runbook now lists the same cutover receipt bundle:
`publication-readiness.json`, `publication-readiness-release.json`,
`repo-view.json`, `remote-workflows.json`, `remote-runs.json`,
`release-view.json`, `external-review-release.json`,
`release-signoff.receipt.json`, `website-head.txt`, `install-sha256.actual`,
`install-sha256.expected`, the private signoff JSON, and the sanitized public
external-review log.

Supplemental external-review update: after the earlier staged export, three public
trust surfaces were added: `docs/evidence/publication-evidence.md`,
`docs/runbooks/release-cutover-authorization.md`, and
`docs/evidence/publication-blocker-coverage.md`. The TP-015 validator now
requires those surfaces. Mobile Eats and Gemini CLI returned current
seven-surface rows with empty `blocking_findings`, and both the private working
log and sanitized public evidence copy validate in release mode.

Latest local evidence refresh: `2026-05-13T22:52Z`. Source gates passed
`tests/public-docs.sh` 144/0, `tests/publication-readiness.sh` 72/0,
`tests/cutover-receipts.sh` 23/0, `tests/public-top-level-files.sh` 21/0, and
`tests/agent-lane-probe.sh` 10/0. Staged public export
`codex-public-export-20260513T2252Z` passed `tests/public-docs.sh` 144/0,
`tests/publication-readiness.sh` 58/0, and depersonalization scan 0 findings.
The link checker reports `source_count=36`, `checked_count=62`, and
`failure_count=0`.

Cutover authorization evidence:
`25-RELEASE-CUTOVER-AUTHORIZATION-PACKET.md` maps every remaining live blocker
to the exact operator command, verification receipt, signoff boundary, and stop
condition. It is not approval to publish; it exists so the final remote actions
can be authorized and audited without hiding the remaining public-state gates.
`docs/runbooks/release-cutover-authorization.md` carries the public operator
checklist for the same cutover decisions, and
`docs/runbooks/public-release-runbook.md` now links to it from the final
publication readiness section. `tests/publication-readiness.sh`,
`tests/public-docs.sh`, `tests/public-links.sh`,
`tests/upstream-substrate-adoption.sh`, and `tests/github-workflows.sh` guard
the public surface.

Validate with:

```bash
python3 scripts/publication_readiness.py --json
python3 scripts/publication_readiness.py --release --json
bash tests/publication-readiness.sh
```

Expected current live state before publication:

- `status=blocked`
- blocker `remote_repo_private`
- blocker `remote_workflows_missing`
- blocker `remote_green_runs_missing`
- blocker `github_release_missing_or_draft`
- blocker `github_release_assets_missing`
- blocker `joshua_release_signoff_missing`

TP-015 external review is closed for the current seven-surface public trust set.
The review log contains two distinct current external-agent rows covering
`docs/evidence/publication-blocker-coverage.md`. The public export carries the
sanitized evidence copy at `docs/evidence/external-review-log.jsonl`; the
release workflow validates that public path explicitly instead of relying on
private `.flywheel/PLANS` state.

Private-live website and install-proxy checks are currently green but remain
revalidation checks during public cutover. The private-live site returns HTTP
200, the live-site probe passes, and `install.sh` hash matches served
`install.sh.sha256`. These facts are not a public release claim because the real
remote, remote workflows, remote runs, GitHub release, release assets, and final
signoff are still absent.

Closure requires the release-mode command to return exit 0 against the real
remote and public web surfaces, not a fixture. If future edits invalidate the
external-review log, closure again requires two distinct non-Joshua review rows
covering `README.md`, `CHARTER.md`, `docs/getting-started/first-run.md`,
`docs/evidence/publication-evidence.md`,
`docs/evidence/publication-blocker-coverage.md`,
`docs/runbooks/release-cutover-authorization.md`, and
`docs/runbooks/public-release-runbook.md`. The required release assets are
`install.sh`, `install.sh.sha256`, `SHA256SUMS`,
`flywheel-v0.2.0.tar.gz`, and `flywheel-v0.2.0.tar.gz.sha256`.
The install proxy proof requires `https://flywheel.zeststream.ai/install.sh`
to hash-match `https://flywheel.zeststream.ai/install.sh.sha256`. Joshua
signoff requires
`.flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json`
with the approved tag and remote.
The pending template lives at
`.flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.template.json`;
`tests/publication-readiness.sh` proves a pending template cannot satisfy the
gate.
The final readiness command still calls the TP-015 external-review gate and
website/install proxy probes, so any future edit that invalidates
`review-log.jsonl`, website content, or checksum parity will reintroduce the
corresponding blocker.

The local website source gate covers `site/index.html`,
`site/what-is/index.html`, `site/for-developers/index.html`,
`site/methodology/index.html`, `site/about/index.html`, `site/contact/index.html`,
`site/styles.css`, and `site/assets/loop-map.svg`. Content and accessibility
shape are checked by `bash tests/website-static.sh`.

The local site deploy workflow is `.github/workflows/site.yml`. It is pinned to
specific action SHAs for `actions/configure-pages`,
`actions/upload-pages-artifact`, and `actions/deploy-pages`; fetches tags for
manual dispatch; checks out the resolved tag; builds `site-dist`; copies
`install.sh`; writes `install.sh.sha256` from inside `site-dist`; writes the
`flywheel.zeststream.ai` CNAME; and emits `site-deploy-manifest.json`. Final
readiness still requires the remote `Site Deploy` workflow to exist and the
website/install endpoints to pass against the final `v0.2.0` release assets.
