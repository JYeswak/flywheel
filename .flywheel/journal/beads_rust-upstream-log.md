---
title: "beads_rust Upstream-Contribution Log (Class-3 substrate boundary)"
type: journal
schema_version: beads_rust-upstream-log/v1
created: 2026-05-11
source_bead: flywheel-yn9ne
sister_bead: flywheel-nhqc4 (recommendation that produced this log)
canonical_locator_doctrine: .flywheel/doctrine/substrate-boundary-three-class-taxonomy.md
canonical_substrate_class: Jeff-Premium (Class-3)
upstream_canonical_repo: https://github.com/Dicklesworthstone/beads_rust
read_only_mirror_fork: https://github.com/JYeswak/beads_rust
local_clone: /Users/josh/Developer/beads_rust
local_remote_origin: Dicklesworthstone/beads_rust (canonical)
local_remote_fork: JYeswak/beads_rust (read-only mirror)
fork_ahead_behind_at_creation: ahead=0 / behind=133 (per flywheel-nhqc4 audit 2026-05-11)
---

# beads_rust Upstream-Contribution Log

This log tracks improvement candidates that surface during ZestStream fleet work and would benefit `beads_rust` upstream. Because `beads_rust` is **Class-3 Jeff-Premium substrate**, the canonical contribution path is **upstream issues against `Dicklesworthstone/beads_rust`, not fork commits**.

## 1. Class-3 discipline (the why)

Per the substrate-boundary 3-class taxonomy (see `.flywheel/doctrine/substrate-boundary-three-class-taxonomy.md`):

| Class | Owner | Discipline | This repo |
|---|---|---|---|
| Joshua-domain | Joshua | Direct mutation + paired patch | n/a |
| Skillos-managed | Joshua + skillos:1 | Patch-artifact only; orch flag | n/a |
| **Jeff-Premium** | **Jeffrey Emanuel** | **AUDIT-ONLY; upstream issue only** | **`beads_rust` ✓** |

**Rules:**
1. **No local mutations.** Do not edit `~/Developer/beads_rust/` source.
2. **No fork commits.** Do not push to `JYeswak/beads_rust`. The fork is a read-only mirror; per `flywheel-nhqc4` audit (2026-05-11) it is 0 commits ahead / 133 behind `Dicklesworthstone/beads_rust` and was created as a namespace-continuity artifact, not a divergence vehicle.
3. **No issues filed on the fork.** The fork's Issues tab is not the contribution channel. File against the canonical repo.
4. **Workaround research first.** Per `feedback_jeff_issue_requires_full_workaround_research_first` (META-RULE 2026-05-04): never propose a Jeff issue without first attempting to find the workaround locally. Single-source claims are phantom-substrate; ≥2 independent sources required to claim "this is a bug."
5. **One bead per issue, where useful.** Track each filed issue on the flywheel side too if it has follow-up work (e.g., dogfood receipt obligation, divergence-reproducer bead).

## 2. What counts as an upstream-improvement candidate

A candidate is an observation about `beads_rust` (the `br` CLI, the JSONL/SQLite write paths, the dependency graph commands, the canonical-locator behavior, the discoverability heuristics) that:

- Reproduces against a current `br` version (`br --version`)
- Has been searched against existing `Dicklesworthstone/beads_rust/issues` (avoid duplicates)
- Has no acceptable local workaround OR the workaround is more costly than fixing upstream
- Is in scope for Jeff (not a fleet-orchestration concern that belongs in the flywheel substrate)

Out of scope:
- Anything Jeff has explicitly declined or DEFERRED in another issue (defer to his roadmap)
- Workflow preferences that are subjective taste (e.g., "I'd prefer different default JSON field names")
- Issues that depend on undocumented internal behavior (file as questions, not bug reports)

## 3. Canonical workflow

```text
candidate observed during fleet stamping work
  │
  ▼
┌────────────────────────────────────────────────────────────┐
│  Step 1 — Search canonical issues                          │
│  gh api repos/Dicklesworthstone/beads_rust/issues          │
│    --jq '.[] | select(.title|test("<keyword>";"i"))'       │
└────────────────────────────────────────────────────────────┘
  │  exists? cite the issue ↓ no further filing
  │  doesn't exist?  ↓
┌────────────────────────────────────────────────────────────┐
│  Step 2 — Workaround research (≥2 independent sources)     │
│  socraticode_search + grep + manual probe                  │
└────────────────────────────────────────────────────────────┘
  │  workaround acceptable? ↓ document workaround, defer filing
  │  workaround too costly OR none exists? ↓
┌────────────────────────────────────────────────────────────┐
│  Step 3 — File Dicklesworthstone/beads_rust issue          │
│  Use jeff-issue-chain v1.1+ discipline (per                │
│  ~/.claude/skills/jeff-issue-chain/ if exists)             │
│  Include: repro steps, `br --version`, RUST_LOG output     │
│  if available, expected vs actual                          │
└────────────────────────────────────────────────────────────┘
  │
  ▼
┌────────────────────────────────────────────────────────────┐
│  Step 4 — Log here                                         │
│  Append entry to §6 with issue URL + status + flywheel     │
│  bead cross-link if any                                    │
└────────────────────────────────────────────────────────────┘
  │
  ▼
┌────────────────────────────────────────────────────────────┐
│  Step 5 — Monitor + dogfood when fix lands                 │
│  Update entry status; run `br --version` post-upgrade;     │
│  capture dogfood receipt in a follow-up flywheel bead      │
│  if the fix changes our workflow                           │
└────────────────────────────────────────────────────────────┘
```

## 4. Issue-template scaffold

When filing a new issue, the body should include the following sections (this is the structure the prior `jeff-issue-chain` filings used to good effect — see §5 historical entries for the closed-FIXED priors):

```markdown
## Repro
<minimal command sequence reproducing the behavior>

## Environment
- br --version: <X.Y.Z>
- OS: <darwin/linux + version>
- Rust: <rustc --version>

## Expected
<what should happen>

## Actual
<what happens; include RUST_LOG=debug output if available>

## Workaround tried
<what we tried locally and why it's insufficient>

## Why upstream (vs local patch)
<one or two sentences — usually "behavior is in the JSONL/SQLite write
path which fleet workers can't safely shim around without risk of
substrate corruption">

## Cross-reference
- flywheel bead: flywheel-<id>
- log entry: .flywheel/journal/beads_rust-upstream-log.md §<row>
```

## 5. Historical entries (prior art, already filed)

These are issues already closed before this tracker existed. They're recorded here so future candidates can pattern-match against past Jeff response shapes.

| # | Title (truncated) | Filed | Status | Notes |
|---|---|---|---|---|
| [#269](https://github.com/Dicklesworthstone/beads_rust/issues/269) | (per memory `reference_upstream_issues.md`) | 2026-04-30 | CLOSED — FIXED | Part of the original bead-isolation phase-3 SQL/source_repo hardening |
| [#270](https://github.com/Dicklesworthstone/beads_rust/issues/270) | (per memory `reference_upstream_issues.md`) | 2026-04-30 | TRIAGED + FIXED 2026-05-01 | Dogfood receipt 2026-05-04: `br 0.2.4` remains current; disposable fixture exits with `.beads/beads.db-wal` at 0 bytes (expected); closure signal posted upstream |
| [#273](https://github.com/Dicklesworthstone/beads_rust/issues/273) | (per memory `reference_upstream_issues.md`) | 2026-05-03 | CLOSED — FIXED | |
| [#285](https://github.com/Dicklesworthstone/beads_rust/issues/285) | `br close` persists JSONL but not SQLite (divergence) | 2026-05-08 | OPEN | Jeff engaged 2026-05-08 with 2 artifact requests (`RUST_LOG=trace` + `br doctor --json`); reproduction requires live divergence; tracked under flywheel-`f23ix` |

Authoritative source for these rows: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_upstream_issues.md`.

## 6. Active candidates (append-only)

Candidates surfaced but not yet filed, or filed and tracked. Append rows; do not edit closed rows in place — file a follow-up entry instead.

> **Note:** no new candidates have surfaced from the current canonical-stamp work cohort (`rtohf` / `d76sl` / `4be4o`) at the time of this log's creation. All friction in that cohort was downstream of flywheel-side substrate (doctrine-sync.sh shard-fallback per `rhdcq.1`; AGENTS.md split pattern per `4be4o`), not `beads_rust`. This log is **ready for accretion**.

### Template row

```markdown
### CANDIDATE-N — <one-line summary>

**Surfaced by:** flywheel-<bead-id> (during <what work>)
**First-observed:** YYYY-MM-DD
**Repro:** `<minimal command>`
**Workaround tried:** <result>
**Workaround status:** acceptable | too-costly | none
**Disposition:** defer-with-workaround | filed-as-issue | declined-out-of-scope
**Issue URL:** (if filed) https://github.com/Dicklesworthstone/beads_rust/issues/<N>
**Cross-references:**
  - flywheel bead: flywheel-<id>
  - related doctrine: <if any>
  - related memory: <if any>
**Status:** OPEN | DEFERRED | FILED | CLOSED-FIXED | CLOSED-WONTFIX
**Last-checked:** YYYY-MM-DD (and what changed)
```

## 7. Maintenance protocol

This log is **append-only for entries** and **versioned via this repo's git history**. To add a candidate:

1. Append a new row under §6 using the template
2. Commit with `docs(beads_rust-upstream-log): add CANDIDATE-N — <summary> [flywheel-<bead>]`
3. If filing the upstream issue in the same dispatch, run §3 Step 3 first and include the issue URL in the appended row
4. Cross-link from the source bead's audit pack so the candidate is discoverable from both sides

When a filed issue closes upstream (FIXED or WONTFIX):
1. Update the candidate's row Status field
2. If FIXED, run the local dogfood receipt: install the new `br` version, exercise the changed surface, log the receipt result in the row's `Last-checked:` line
3. If WONTFIX, capture Jeff's reasoning in the row + add a `Workaround maintained at:` pointer to the local doctrine that records the workaround

## 8. Cross-references

- Source bead: [flywheel-yn9ne](../audit/flywheel-yn9ne/) (this log's creation)
- Sister recommendation bead: [flywheel-nhqc4](../audit/flywheel-nhqc4/evidence.md) (§2.a recommended this tracker)
- Substrate-boundary doctrine: [.flywheel/doctrine/substrate-boundary-three-class-taxonomy.md](../doctrine/substrate-boundary-three-class-taxonomy.md)
- Joshua memory — discipline: `feedback_jeff_issue_chain` ("file issues not patches; don't derail Jeff's agents")
- Joshua memory — workaround-first: `feedback_jeff_issue_requires_full_workaround_research_first`
- Joshua memory — no-push: `feedback_no_push_ntm_br` (Jeff's repos; changes stay local-and-upstream-only)
- Joshua memory — issue inventory: `reference_upstream_issues` (canonical roll of filed-and-tracked Jeff issues fleet-wide)
- `jeff-issue-chain` skill (if installed at `~/.claude/skills/jeff-issue-chain/`) — protocol details for filing
