# flywheel-me08 evidence

Task: flywheel-me08-84f2bf
Bead: flywheel-me08
Status: DONE-ready

## Acceptance

- PASS: Pi support landed as a pi-only commit on upstream-track branch `upstream-track/flywheel-me08-pi`.
  - Commit: `7d1fc78e feat(ensemble): add pi agent support`.
  - Proof: branch has `AgentTypePi`, `pi-agent` canonicalization, ensemble normalization, launch defaults, tmux detection, and tests.
  - Proof: `git grep cubcode upstream-track/flywheel-me08-pi -- internal/agent/types.go internal/cli/ensemble.go internal/ensemble/assignment.go internal/swarm/agent_launcher.go internal/tmux/session.go` returns no rows.
- PASS: Cubcode support landed separately on local-only branch `local/bead-isolation-reconciled-20260502T170928`.
  - Commit: `a84fb65b feat(ensemble): add local cubcode agent support`.
  - Proof: cubcode symbols appear on the local branch and not in the upstream-track pi commit.
- PASS: `ntm` rebuild passes after pi support.
  - `go build ./...`
  - Focused tests:
    - `go test ./internal/agent -run 'TestAgentType_(String|DisplayName|Canonical|IsValid|ProfileName)$'`
    - `go test ./internal/cli -run TestNormalizeEnsembleAgentType`
    - `go test ./internal/swarm -run 'TestValidateAgentType|TestDefaultAgentCommands|TestDefaultAgentArgs'`
    - `go test ./internal/tmux -run 'TestDetectAgentFromCommand'`
    - `go test ./internal/ensemble -run 'TestAssignByCategory|TestAssignRoundRobin|TestAssignExplicit'`
- PASS: Memory updated to reflect `pi=Jeff`, `cubcode=Joshua`.
  - CASS/cm bullet: `b-moxyv7vy-guk35f`.
- PASS: Doctrine documented.
  - `.flywheel/doctrine/split-boundary.md`.

## Verification notes

- `go test ./internal/agent ./internal/cli ./internal/ensemble ./internal/swarm ./internal/tmux` was stopped after `internal/cli` hung for several minutes. This is not specific to the pi patch; targeted tests and `go build ./...` passed.
- `go test ./internal/ensemble` fails a pre-existing environment-specific `XDG_CACHE_HOME` expectation in `TestDefaultContextCacheDir_UsesXDGCacheHome`; targeted assignment tests passed.
- `jsm status cubcode --json` is unsupported by the installed `jsm status` command shape; `skill-enhance-jsm-discipline.sh --validate-packet` timed out on `jsm list --json`. No skill files were mutated.

## Four-Lens Self-Grade

- brand: 8 — the split matches Jeff-canonical vs Joshua-local ownership and avoids silently dropping pi.
- sniff: 8 — branch/commit proofs are direct and greppable; broad tests have one unrelated environment failure documented.
- jeff: 9 — pi support is isolated for upstream-track without cubcode contamination.
- public: 8 — skeptical operator, maintainer, and future worker can re-run the L112 probe and see the branch split.

## Compliance pack

- socraticode_queries: 1
- indexed_chunks_observed: 10
- skill_auto_routes_addressed: canonical-cli-scoping=n/a, rust-best-practices=yes, python-best-practices=n/a, readme-writing=n/a
- skill_discoveries: 0
- beads_filed: none
- beads_updated: flywheel-me08
- no_bead_reason: no new gap; existing bead closed
- agents_md_updated: no
- readme_updated: no
- no_touch_reason: doctrine note is narrowly scoped; canonical AGENTS/README landing not required for this non-L-rule operational note
