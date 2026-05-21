# Local Actions Preflight

Flywheel uses GitHub Actions as the final hosted-runner approval surface, not
the first place to discover workflow mistakes. Run the local gate before
pushing branches that touch `.github/workflows`, installer smoke, public docs,
or release/site assets.

## Install

Use OrbStack as the Docker-compatible runtime and install the open-source
workflow tools globally:

```bash
brew install act actionlint
docker context use orbstack
```

The global wrapper on Joshua's machine is:

```bash
flywheel-actions-gate
```

Repo-local equivalent:

```bash
scripts/local-actions-preflight.sh
```

## Local Network Boundary

`act` starts temporary artifact/cache servers when workflows upload artifacts or
use cache behavior. Bind those servers to localhost:

```bash
--artifact-server-addr 127.0.0.1
--cache-server-addr 127.0.0.1
```

Joshua's global `~/.actrc` and Flywheel's `scripts/local-actions-preflight.sh`
set these defaults. If macOS asks whether `act` can accept incoming network
connections, it is normally seeing that local emulation server. Do not widen the
bind address unless a workflow explicitly needs cross-host access.

## Gate Order

| Layer | Command | Purpose |
|---|---|---|
| Repo contract | `bash tests/github-workflows.sh` | Proves required workflow commands and public gates are wired. |
| Static workflow lint | `actionlint .github/workflows/*.yml` | Catches invalid GitHub Actions syntax and expressions without a runner. |
| Local Ubuntu runner | `act pull_request ... --job public-surface` | Runs safe CI jobs in OrbStack before spending GitHub minutes. |
| Local installer leg | `act pull_request ... --job install-doctor-uninstall --matrix os:ubuntu-22.04` | Runs the Linux installer smoke leg locally. |
| Deploy dry run | `act workflow_dispatch ... --dryrun` | Validates release and Pages workflow shape without publishing. |

## Act-First PR Gate

`gh pr create` is guarded by `.flywheel/hooks/gh-pr-create-act-gate.sh`.
For every pull-request workflow classified as `act-compatible`, PR creation
requires a green local act receipt newer than 24 hours in:

```bash
~/.local/state/flywheel/act-green-receipts.jsonl
```

Receipt rows are JSONL:

```json
{"schema_version":"flywheel.act_green_receipt.v1","repo":"/path/to/repo","workflow":".github/workflows/ci.yml","status":"pass","ts":"2026-05-20T20:00:00Z"}
```

The classifier writes each repo's current contract to:

```bash
.flywheel/state/workflow-classification.json
```

Emergency override is explicit and audited:

```bash
gh pr create --skip-act-gate="reason"
```

Five consecutive hosted failures with recent local-green evidence are routed by
`.flywheel/scripts/gha-auto-disable-on-local-green.sh`; the cron surface is
`.flywheel/launchd/ai.zeststream.gha-auto-disable-on-local-green.plist`.

## Boundary

`act` is not a full replacement for GitHub-hosted runners. Treat a local pass as
permission to spend GitHub minutes, not as release approval. GitHub remains
authoritative for:

- macOS hosted runner behavior;
- GitHub Pages deployment;
- release upload behavior;
- OIDC and environment protection;
- branch protection and required status checks.

If this gate fails, fix locally and rerun it before pushing. If it passes, push
once and let GitHub serve as the final approval receipt.

## Fleet Stamp

This gate is system-wide on Joshua's workstation, not Flywheel-only. Repos that
use GitHub-style workflows should treat `flywheel-actions-gate` as the local
pre-GitHub check whenever workflow files, installer smoke, release packaging,
or public-site gates change.

Initial fleet targets:

| Repo | Required stance |
|---|---|
| `~/Developer/skillos` | Adopt as the local workflow gate before GitHub runner spend. |
| `~/Developer/mobile-eats` | Adopt as the local workflow gate before GitHub runner spend. |
| `~/Developer/clutterfreespaces` | Adopt as the local workflow gate before GitHub runner spend. |
| `~/Desktop/Projects/clients/alps-insurance` | Adopt as the local workflow gate before GitHub runner spend. |

Each repo may wrap the global command with repo-specific jobs, but the boundary
must stay the same: local contract tests and `actionlint` first, local Ubuntu
`act` jobs second, GitHub-hosted runners only for final approval and surfaces
that require GitHub parity.
