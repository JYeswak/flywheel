# Upstream Substrate Adoption

Flywheel can learn from fast-moving upstream systems without making them hidden
requirements for public users. This runbook turns upstream interest into a
gated adoption lane.

## Current Asupersync Decision

Status: `gated-evaluation`.

Asupersync is a promising Dicklesworthstone Rust async runtime for future Rust
sidecars, supervisors, and cancellation-sensitive workers. It is not a required
dependency for reduced mode, the public installer, or the current shell/Python
loop engine.

Latest live probe, 2026-05-13T16:00Z: GitHub releases and crates.io report
`0.3.1`, while the public website still advertises `V0.2.6`. GitHub reports
license `NOASSERTION`, and the upstream `LICENSE` includes an OpenAI/Anthropic
rider. Joshua clarified in-thread that this is not a restriction on ordinary
open-source users or adopter-side evaluation; it targets the named restricted
companies directly. Current `main` Actions runs for commit
`f29ff7b4c330f14e2748ec05c1a3420199b9cf77` are queued rather than green.
Issue `#39` for idle CPU burn is now closed, but issue `#35` for a Windows
HTTPS connect failure remains open. Those facts keep the status at
`gated-evaluation` until the adoption packet reconciles source, package,
site/docs, legal/tooling executor, CI, platform, and operational truth.

Current public evidence packet:
[`docs/evidence/asupersync-gated-adoption.md`](../evidence/asupersync-gated-adoption.md).

POC receipt template:
[`docs/evidence/asupersync-poc-receipt.template.json`](../evidence/asupersync-poc-receipt.template.json).

Current isolated local POC receipt:
[`docs/evidence/asupersync-poc-receipt.local.json`](../evidence/asupersync-poc-receipt.local.json).

The standing decision:

- start tracking Asupersync as an upstream substrate;
- use its cancellation, obligation, deterministic-test, and capability-context
  ideas as doctrine where they fit;
- allow bounded proof-of-concept work for new Rust sidecars;
- prioritize the investigation now, using live metadata probes and a
  non-runtime POC plan before public Flywheel adoption;
- do not rewrite the shell/Python loop engine for runtime purity;
- do not describe Asupersync as a supported Flywheel runtime dependency until a
  repo-local proof receipt exists.

## Promotion Gates

Before Flywheel can promote Asupersync from `gated-evaluation` to an approved
runtime dependency for new Rust services, the adoption packet must include:

| Gate | Required evidence |
|---|---|
| Source | Public upstream repository URL and commit/tag under evaluation. |
| Package | Crates.io version and dependency graph review. |
| Executor | Tooling disposition for the OpenAI/Anthropic rider: human operators, non-restricted users, and user-directed local Codex/Claude sessions may evaluate under the upstream license posture when the receipt records that distinction; restricted-company use requires separate clearance. |
| Site/docs | Public website and docs version consistency check. |
| Platform | Apple Silicon path: release asset or documented source-build fallback. |
| Test posture | Known upstream failing-test count and explicit disposition. |
| CI posture | Current upstream Actions status is green for the evaluated commit/tag, not queued or cancelled. |
| Operational posture | Active high-impact issues, including idle CPU burn or scheduler hot-loop reports, are resolved or explicitly accepted for an isolated POC only. |
| POC | Repo-local Rust proof receipt using `Cx`, owned regions, cancellation, and deterministic tests. |
| Boundary | Statement that reduced mode and existing public install flow do not require Asupersync. |

If any gate is missing, the status remains `gated-evaluation`.

## Probe Commands

Run these when refreshing the packet:

```bash
curl -fsSL https://api.github.com/repos/Dicklesworthstone/asupersync/releases/latest \
  > asupersync-release.json
curl -fsSL https://crates.io/api/v1/crates/asupersync \
  > asupersync-crate.json
curl -fsSL https://asupersync.com/ > asupersync-site.html
```

Then inspect:

```bash
jq '{tag_name, published_at, assets: [.assets[].name], body}' asupersync-release.json
jq '{newest_version: .crate.newest_version, updated_at: .crate.updated_at}' asupersync-crate.json
```

Promotion is blocked when the live release notes disclose unresolved failures,
when Apple Silicon support is missing without a source-build fallback, when the
public site version disagrees with crates/release truth, when upstream Actions
are not green for the evaluated commit/tag, or when high-impact operational
issues are open or not explicitly dispositioned.

## Immediate Investigation Lane

This lane should run before any runtime adoption decision:

1. Refresh live metadata: GitHub repo, latest release, crates.io, website
   version, Actions, and high-impact issues.
2. Produce a repo-local POC receipt template for a small Rust sidecar using
   explicit `Cx`, owned regions, cancellation, and deterministic tests.
3. Run source/build/test checks through a user-side or non-restricted executor.
   A user-directed Codex/Claude session is acceptable for adopter-side evaluation
   when the receipt records the rider disposition; restricted-company work
   requires separate clearance.
4. Record results in the adoption packet without adding Asupersync to the
   public installer, reduced mode, doctor, tick, closeout, NTM, or non-NTM
   requirements.

## Public Copy Rule

Public copy may say Flywheel evaluates and adopts upstream substrate through
verified gates. Public copy must not imply that a newly released upstream system
is already part of the runtime stack before the promotion gates pass.
