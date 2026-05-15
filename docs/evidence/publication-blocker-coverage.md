# Publication Blocker Coverage

This public evidence file maps each live publication-readiness blocker code to
the current release owner and public proof required to close it. The registry
validator derives its expected blocker-code set from `publication_readiness.py`
and checks this table against that live set, without exposing private planning
state.

Run:

```bash
python3 scripts/publication_readiness.py --json
python3 .flywheel/scripts/true-publication-registry-validate.py --json
```

Expected local state before cutover:

- `publication_readiness.py` returns `status=blocked` with the blocker codes
  below;
- for TP-005/TP-017/TP-018, the registry validator returns `status=pass`,
  `open_count=3`, and `readiness_blocker_coverage` covers every live
  readiness code plus the conditional remote visibility code;
- the open registry rows are TP-005, TP-017, and TP-018.

| Readiness blocker code | Owner | Public closure proof |
|---|---|---|
| `remote_repo_private` | Release approver | Approved repository or export path is public. |
| `remote_workflows_missing` | Flywheel | Public default branch exposes `CI`, `Installer Smoke`, `Release`, and `Site Deploy`. |
| `remote_green_runs_missing` | Flywheel | `CI` and `Installer Smoke` succeed on the public default branch. |
| `github_release_missing_or_draft` | Flywheel | `v0.2.1` release exists and is neither draft nor prerelease. |
| `github_release_assets_missing` | Flywheel | Required release assets are uploaded, non-empty, and expose `sha256:` digests. |
| `install_proxy_checksum_mismatch` | Flywheel | Hosted `install.sh` and `install.sh.sha256` match the release asset checksum. |
| `joshua_release_signoff_missing` | Release approver | `release-signoff.json` validates after all real checks pass. |

The public release is not complete while any row above remains blocked.
