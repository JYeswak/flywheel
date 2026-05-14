# Asupersync Gated Adoption Evidence

Status: `gated-evaluation`.

This packet records why Asupersync is tracked as an upstream substrate candidate
but is not part of the Flywheel v0.2 public runtime, installer, reduced-mode
journey, or agent-lane support claim.

## Live Snapshot

Captured: 2026-05-13T16:00Z.

| Surface | Observed fact | Publication decision |
|---|---|---|
| GitHub repo | `Dicklesworthstone/asupersync`, default branch `main`, pushed at `2026-05-13T15:56:10Z`, updated at `2026-05-13T15:56:11Z`, GitHub license `NOASSERTION`. | Track as upstream candidate only. |
| Latest release | `v0.3.1`, published `2026-04-22T00:13:43Z`, non-draft, non-prerelease. Assets: linux amd64 tarball, windows amd64 zip, `SHA256SUMS.txt`. | No Apple Silicon release asset; require source-build or darwin/arm64 proof before any Mac-first dependency claim. |
| Crates.io | Newest crate version `0.3.1`, updated `2026-04-21T23:58:52.791068Z`. | Package surface is ahead of the public website. |
| Website | `https://asupersync.com/` still advertises `V0.2.6`. | Version-surface mismatch blocks promotion. |
| License/tooling | Upstream license contains an OpenAI/Anthropic rider and says restricted parties receive no rights. | Treat human operators, non-restricted users, and user-directed local Codex/Claude sessions as open-source evaluation lanes when the receipt records that distinction; restricted-company use requires separate clearance. |
| CI | Latest `main` Actions rows for `f29ff7b4c330f14e2748ec05c1a3420199b9cf77` are queued for CI, Conformance Tests, Property Tests, Tokio Parity Dashboard Drift Gate, and Benchmarks; one earlier Benchmarks run is cancelled. | No green upstream CI proof for the evaluated commit. |
| Issues | Issue `#39` idle CPU burn is closed as of `2026-05-13T11:53:51Z`; issue `#35` Windows HTTPS connect failure remains open. | Operational risk is improved but not fully dispositioned. |

## Commands Used

```bash
curl -fsSL https://api.github.com/repos/Dicklesworthstone/asupersync
curl -fsSL https://api.github.com/repos/Dicklesworthstone/asupersync/releases/latest
curl -fsSL 'https://api.github.com/repos/Dicklesworthstone/asupersync/actions/runs?per_page=8'
curl -fsSL https://crates.io/api/v1/crates/asupersync
curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/asupersync/main/LICENSE
curl -fsSL https://asupersync.com/
curl -fsSL https://api.github.com/repos/Dicklesworthstone/asupersync/issues/35
curl -fsSL https://api.github.com/repos/Dicklesworthstone/asupersync/issues/39
```

## Adoption Decision

Flywheel may learn from Asupersync's design: explicit `Cx`, owned regions,
cancel-correct work, linear obligations, deterministic testing, and
capability-aware boundaries.

Flywheel should prioritize an isolated investigation now. The investigation may
refresh live public metadata and design a repo-local POC receipt. A local
crate-level POC receipt exists at
`docs/evidence/asupersync-poc-receipt.local.json`; it proves Apple Silicon
source-build viability for the published crate plus explicit `Cx`, owned scope,
cancellation checkpoint, deterministic test harness, and `Outcome` smoke
coverage. It is not runtime promotion evidence.

Flywheel must not:

- add Asupersync to the public install path;
- require it for reduced mode, doctor, tick, closeout, NTM, or non-NTM flows;
- claim Claude, Codex, Gemini, or OpenClaw support depends on it;
- treat the rider as disqualifying ordinary users or adopter-side evaluation;
- present user-directed Codex/Claude POC checks as evidence that restricted
  companies have rights under the upstream license;
- promote it from `gated-evaluation` until site/docs, package, CI, platform,
  legal, and operational gates all pass.

The next allowed step is a separate isolated POC packet, not runtime adoption.
That POC must use explicit `Cx`, owned regions, cancellation semantics, and
deterministic test evidence, and it must remain outside Flywheel v0.2 release
requirements.
