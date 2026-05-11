---
bead: flywheel-16b53
title: P0 trauma-class investigation — v38e1.5 worker clobbered skillos canonical paths
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE (investigation; 3 mitigation sub-beads filed; mitigations NOT executed in this bead)
priority: P0
mission_fitness: direct
trauma_class: absolute-path-construction-drift-to-peer-canonical-substrate
---

# 16b53 evidence pack — P0 trauma-class investigation

## Disposition

DONE-as-investigation. Three mitigation sub-beads filed (`flywheel-16b53.1/.2/.3`). Per dispatch contract for investigation beads, mitigations are NOT executed here; this bead documents the trauma class + root cause + recovery path + recommended mitigations.

## Incident summary

On 2026-05-11 at approximately T21Z, the v38e1.5 worker (`MagentaPond`, `flywheel:0.3`) shipped 9 cross-reference stubs intended for the flywheel side of the doctrine catalog (8 cohort replacements + 1 new for meta-aggregation-family). The worker correctly authored stubs at `/Users/josh/Developer/flywheel/.flywheel/doctrine/<name>.md` AND drifted to also write stub-content over peer-orch canonical paths at `/Users/josh/Developer/skillos/.flywheel/doctrine/<name>.md`.

The skillos:1 orchestrator detected the unauthorized writes in its working tree and captured the canonical content via `git stash` BEFORE any commit could land. Stash entry:

```
stash@{0}: On arc/cadence-loop-full-closure-2026-05-11: v38e1.5-worker-drift-doctrine-stub-overwrites-skillos-canonical-2026-05-11T21
```

## Blast radius

`git -C /Users/josh/Developer/skillos stash show --stat 'stash@{0}'` returns 10 files affected with `-905/+148` line delta (full canonical bodies → thin stub pointers):

| # | Path (skillos side) | Lines removed | Lines added |
|---|---------------------|---------------|-------------|
| 1 | `.flywheel/doctrine/README.md` | (new) | +58 |
| 2 | `.flywheel/doctrine/additive-v0.0.2-expansion-after-v0.0.1-under-extraction.md` | -102 | (stub) |
| 3 | `.flywheel/doctrine/cross-language-audit-as-cousin-scout.md` | -142 | (stub) |
| 4 | `.flywheel/doctrine/depth-axis-mismatch.md` | -110 | (stub) |
| 5 | `.flywheel/doctrine/dispatch-assumes-fresh-extraction-but-package-preexists.md` | -99 | (stub) |
| 6 | `.flywheel/doctrine/dispatch-expectation-vs-audit-verdict-divergence.md` | -93 | (stub) |
| 7 | `.flywheel/doctrine/dispatch-premise-mismatch.md` | -132 | (stub) |
| 8 | `.flywheel/doctrine/meta-aggregation-family.md` | -110 | (stub) |
| 9 | `.flywheel/doctrine/source-project-aggregation-from-n-repos.md` | -116 | (stub) |
| 10 | `.flywheel/doctrine/substrate-layer-shape-mismatch.md` | -91 | (stub) |

Net: 905 lines of canonical doctrine deleted; 148 lines of stub content inserted. **No data permanently lost** — skillos working tree captured pre-write state into stash before commit.

## kk08x exoneration

The bead title bundles `v38e1.5+kk08x` but only v38e1.5 wrote to skillos. Verified:

- `git show 6ba8a33 --name-only` (kk08x commit) lists 5 paths, all under `/Users/josh/Developer/flywheel/`:
  - `.beads/issues.jsonl`
  - `.flywheel/AGENTS.md`
  - `.flywheel/audit/flywheel-kk08x/compliance-pack.md`
  - `.flywheel/audit/flywheel-kk08x/evidence.md`
  - `.flywheel/doctrine/README.md`
- `git show 6ba8a33 | grep -c "Developer/skillos"` returns `0`

The "+kk08x" naming reflects sister-bead-in-cohort proximity (both touched the doctrine catalog surface in the same 30-min window), not co-clobber.

## Root cause analysis

Per Joshua-memory `feedback_bead_hypothesis_starting_point_not_conclusion` N=43 instance: probed before concluding.

**Mechanism (worker side):** the v38e1.5 worker constructed absolute write-paths using a pattern that resolved to both flywheel and skillos doctrine dirs. The exact construction shape is not directly observable from artifact evidence (the audit-snapshot dir at `.flywheel/audit/flywheel-v38e1.5/mirror-snapshots-before-stub-replacement/` only preserves pre-stub flywheel-side snapshots — not the script or path-construction logic). Most likely hypothesis: a copy-paste, glob, or loop variable that pointed at both `/Users/josh/Developer/flywheel/.flywheel/doctrine/` AND `/Users/josh/Developer/skillos/.flywheel/doctrine/` during the stub-replacement pass.

**Mechanism (orch side):** the v38e1.5 dispatch packet did NOT include an `OWNED_WRITE_ROOTS` allowlist constraint. The canonical dispatch-template at `~/.claude/commands/flywheel/_shared/dispatch-template.md` has:
- `## FILE DISCIPLINE (PICOZ_WORKER_FILES)` — names files for narrow staging, but does NOT constrain Write-tool destination paths
- `## SHARED-SURFACE RESERVATION BLOCK (L107)` — covers shared-pane reservation, NOT cross-repo write-root scoping
- No `OWNED_WRITE_ROOTS=` block

A worker that constructs an absolute path outside the flywheel repo can write to peer-orch canonical substrate without any orch-side guard catching the intent-vs-action mismatch.

**Detection gap:** there's no pre-Write path-vs-allowlist check. DCG handles destructive-substring patterns (e.g., `rm -rf` to home), but does not enforce per-bead write-root allowlists. The pre-commit guard at peer-orch side would have caught it eventually (skillos has a precommit-guard for non-skillos-authored doctrine writes), but only post-commit; the working-tree clobber happened first.

## Recovery (skillos:1 side)

Per the stash message and skillos commit log, skillos:1 caught the unauthorized writes during its own tick cycle. Sequence inferred:

1. skillos:1 observes dirty working tree with unexpected diffs on 10 canonical doctrine files
2. skillos:1 runs `git status` and `git diff` to confirm the canonical content is being replaced with stubs
3. skillos:1 stashes the working tree with a descriptive message naming the upstream bead (`v38e1.5-worker-drift-doctrine-stub-overwrites-skillos-canonical-2026-05-11T21`)
4. skillos:1 continues its own work; canonical files remain intact at HEAD on the `arc/cadence-loop-full-closure-2026-05-11` branch

Recovery effective: stash captured all 10 files; HEAD remained correct; downstream commits (visible in `git log --oneline -10`) continued the skillos:1 mainline without disruption.

## Acceptance gates (implicit from bead title)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Probe + confirm v38e1.5 worker clobbered skillos canonical paths | DID | stash entry name; 10-file blast-radius table |
| 2 | Probe + confirm 9 doctrine files + README affected | DID | `git stash show --stat` exact match: 9 doctrine `.md` + 1 README = 10 total |
| 3 | Probe + confirm absolute-path construction was the mechanism | DID-via-hypothesis | absolute-path-construction-drift documented; exact construction shape not recoverable from artifacts but most-likely hypothesis named |
| 4 | Probe + confirm skillos recovered via git stash | DID | stash entry `stash@{0}` exists with descriptive message; skillos `git log --oneline -10` shows continuing mainline post-incident |
| 5 | Probe + identify orch-side failure (write-path not scoped) | DID | dispatch-template inspection: no `OWNED_WRITE_ROOTS` block; only PICOZ_WORKER_FILES (staging-only) and L107 (pane-only) |
| 6 | Exonerate or implicate kk08x in the clobber | DID-exonerated | `git show 6ba8a33 --name-only` returns only flywheel paths; 0 skillos-path matches in diff |
| 7 | File mitigation follow-up beads (do NOT execute) | DID | 3 P0 sub-beads filed: `16b53.1` (OWNED_WRITE_ROOTS block), `16b53.2` (pre-write-path-guard.sh), `16b53.3` (cross-repo-write-path-discipline doctrine) |

`did=7/7`, `didnt=none`, `gaps=flywheel-16b53.1+flywheel-16b53.2+flywheel-16b53.3` (mitigations queued as gaps for follow-up).

## Mitigation summary

Three coupled P0 sub-beads filed (NOT executed):

| Sub-bead | Mitigation | Layer |
|----------|-----------|-------|
| `flywheel-16b53.1` | Add `OWNED_WRITE_ROOTS` block to canonical dispatch-template | Orch-side (per-bead declaration) |
| `flywheel-16b53.2` | Author `.flywheel/scripts/pre-write-path-guard.sh` + wire into canonical-cli-helpers | Worker-side (pre-Write check) |
| `flywheel-16b53.3` | Author `.flywheel/doctrine/cross-repo-write-path-discipline.md` | Doctrine-layer (canonical rule + cross-references) |

Defense-in-depth: orch declares allowed roots (.1) → worker pre-write guard enforces (.2) → doctrine doc names the trauma class + how to apply (.3). Any one layer alone is insufficient; together they close the gap.

## L112 probe

```bash
git -C /Users/josh/Developer/skillos stash list | grep -c "v38e1.5-worker-drift-doctrine-stub-overwrites-skillos-canonical"
```

Expected: literal `1` (the stash entry exists and is uniquely-named).

## Files changed

In flywheel repo:
- `.flywheel/audit/flywheel-16b53/evidence.md` — this pack
- `.flywheel/audit/flywheel-16b53/compliance-pack.md` — compliance breakdown
- `.beads/issues.jsonl` — 3 sub-bead rows (16b53.1, .2, .3)

No mutations to skillos repo (read-only investigation). No mutations to executable substrate (mitigations queued, not executed).

## Mission fitness

`mission_fitness=direct`. P0 trauma-class investigation directly supports the continuous-orchestrator-uptime-self-sustaining-fleet mission anchor. The fleet's self-sustaining property depends on workers NOT corrupting peer-orch canonical substrate; this investigation + the three mitigation sub-beads close the discovered drift gap at three defensive layers. Cite: `feedback_substrate_boundary_three_class_taxonomy` + `feedback_cross_repo_consumer_vs_mutator`.

## Skill discoveries

`skill_discoveries=1 sd_ids=pattern-emerged-absolute-path-construction-drift-to-peer-canonical-substrate`. New trauma class identified: workers writing to peer-orch absolute paths via construction error. Patterns previously catalogued (cluster-maintainer, Option E, single-axis-reframe, bead-hypothesis) do not cover this specific class. Promotion path: at N=2 instances (next occurrence), promote to canonical doctrine doc per the 16b53.3 sub-bead scaffold.

## Four-Lens Self-Grade

- Brand: 9/10 — P0 trauma class properly investigated with empirical evidence (stash entry, diff stats, commit-byte counts); kk08x exoneration via concrete git evidence
- Sniff: 10/10 — 7/7 implicit gates DID; 3 mitigation sub-beads filed at defense-in-depth layers; honest "exact construction shape not recoverable" caveat where evidence permits
- Jeff: 10/10 — Class 2 substrate-boundary discipline rigorously preserved (no skillos mutation during investigation); cross-orch incident handled with proper provenance trail back to skillos:1's stash-based recovery
- Public: 9/10 — three judges: skeptical operator sees concrete evidence + uniquely-named stash anchor; maintainer sees 3-layer defense plan; future worker sees the trauma-class shape + recovery template
