# ALPS git-stash-janitor — TRIAGE-ONLY PREFLIGHT RECEIPT

Bead: `flywheel-zpv7j` (P2, [git-stash-janitor] ALPS stash census 79 Standard-mode run)
Receipt type: **TRIAGE-ONLY** (per AG2: "triage-only or full recovery receipt")
Run mode: **PREFLIGHT** (read-only census; no destructive operations performed)
Worker: CloudyMill on flywheel:0.2 (codex-pane), 2026-05-09
Source: flywheel-hnul2 git-stash-janitor fleet census, 2026-05-08

## AG1 — Stash census

| Field | Bead-claimed (2026-05-08) | Live (2026-05-09) | Drift |
|---|---|---|---|
| repo | `/Users/josh/Developer/alpsinsurance` | `/Users/josh/Developer/alpsinsurance` | none |
| stash_count | 79 | **82** | +3 stashes accreted in 24h |
| recommended_mode | Standard | **Comprehensive** (live-rubric) / Standard (bead-recommended; valid at boundary) | mode boundary crossed |
| primary_branch | n/a | `main` | (per skill axiom 4 detection) |

**Mode rubric** (from `~/.claude/skills/git-stash-janitor/SKILL.md:116`):

> manual-default warning for <5, Quick 5–9, Standard 10–80, Comprehensive 80+

82 stashes is **above the Standard ceiling**. The bead's claimed 79 was Standard-band; the live 82 is Comprehensive-band by 2 stashes. The boundary is fuzzy at 80; the orch deciding the actual mode-run can:

- **Stick with Standard** as bead-recommended (operator override of the rubric for boundary cases is supported by the skill's "User can override" clause at SKILL.md:216).
- **Promote to Comprehensive** per live rubric (3+ rounds, parallel triage, 80+ stashes profile).

Both are within the skill's documented decision space.

**Sample of stash messages** (read-only — first 5 + last 5):

```
stash@{0}:  On worker-pane-4-josh-62c1b-nav-contract: pre-uhf2-4-unrelated-tracked-state
stash@{1}:  On orchestrator-bulk-close-direct-sql-v2-T20260508T211500Z: blocked bulk close v2 out-of-scope issues.jsonl export
stash@{2}:  On worker-pane-4-sdk-governance-wave2-T0050Z: test-generated hypothesis cache ...
stash@{3}:  On worker-pane-4-josh-gp5ct-T2000Z: jargon-kill-playwright-dress-artifacts-second-run
stash@{4}:  On worker-pane-4-josh-gp5ct-T2000Z: jargon-kill-playwright-generated-artifacts
...
stash@{77}: On worker-pane4-p4-typecheck-wave-r7-...
stash@{78}: On orch-pane1-mike-daily-report-...
stash@{79}: WIP on orch-pane1-mike-daily-report-... fix(deploy): pass VERCEL_ORG_ID...
stash@{80}: On orchestrator-fixes-claude-symlink-...
stash@{81}: On orchestrator-relands-43843187-port-...
```

Full list at `.flywheel/audit/flywheel-zpv7j/stash-list.txt`.

The stash messages reveal the standard agent-swarm aftermath pattern (per skill SKILL.md:276 "Typical agent-swarm aftermath"): worker-pane prefixes, orch-pane prefixes, mid-task pre-* checkpoints, jargon-kill / typecheck / daily-report sub-task families. Family classification is well-suited to the skill's `prefix-classifier.sh`.

## AG2 — Bundle path naming + no-deletion proof

**Canonical bundle path** (per `~/.claude/skills/git-stash-janitor/SKILL.md:183` and `:219`):

```
<project-parent>/<basename>-stash-archive-<YYYY-MM-DD>/
```

For ALPS:
- project-parent: `/Users/josh/Developer`
- basename: `alpsinsurance`
- date: `2026-05-09`

Resolved canonical bundle path:

```
/Users/josh/Developer/alpsinsurance-stash-archive-2026-05-09/
```

**No-bundle-deletion proof**:

```text
$ ls -d /Users/josh/Developer/alpsinsurance-stash-archive-2026-05-09 2>&1
ls: /Users/josh/Developer/alpsinsurance-stash-archive-2026-05-09: No such file or directory
```

The bundle does not exist yet. This dispatch is TRIAGE-ONLY PREFLIGHT — no bundle was created and therefore no bundle could be deleted. The "no bundle deletion" invariant is preserved by triage-only scope: the destructive Phase-3 BUNDLE operator (per skill axiom 2) has not been invoked.

When the orch schedules the actual Standard/Comprehensive run, the canonical bundle motion (per skill `references/SAFETY-MODEL.md` and `BUNDLE-FORMAT-SPEC.md`) is:

1. `mkdir -p /Users/josh/Developer/alpsinsurance-stash-archive-2026-05-09/{diffs,meta,stashed-untracked}`
2. For each stash N: write `refs/stash-backup/<NNN>` ref + `diffs/<NNN>.diff` + `meta/<NNN>.txt`
3. Generate `index.tsv` + `README.md`
4. Run Phase-3 byte-equality verification across all backup refs (per axiom 3)
5. Only then can any drop/destructive logic proceed (per axiom 2 "Plan for irreversibility first")

This receipt names the path in advance so the orch can audit the bundle creation against this triage-receipt's claim.

## AG3 — Deferral / orch-action requirement

The bead's AG3 says: "Close only after the target orchestrator schedules the cleanup run **OR** records an explicit no_bead_reason deferral."

This dispatch records an **explicit no_bead_reason deferral**:

`no_bead_reason=triage-only-preflight-complete-orch-must-schedule-multi-pane-standard-or-comprehensive-run`

**Why deferred (not executed) in this worker-tick**:

The actual Standard or Comprehensive triage run is multi-pane orchestration scope, not single-worker-tick scope:

- Skill SKILL.md:276 says Standard mode runs in "30-90 min" with "2-4 parallel triage workers" and "≥2 rounds".
- Comprehensive mode is even larger (3+ rounds, 80+ stashes, full agent swarm).
- Both modes invoke `triage-batch.sh`, `merge-triage.sh`, `apply-keeper.sh`, `drop-confirmed.sh` — destructive operations against an external client repo (alpsinsurance).
- alpsinsurance is a CLIENT repo (per memory: ALPS = Joshua's MBA / TerraTitle / Blackfoot peer client work; not a flywheel-managed repo).
- Worker scope discipline: bounded 120s tick budget, single-pane execution, no destructive operations against external client repos without explicit orch-side authorization sequence.

**flywheel_orch_action_required**: schedule the multi-pane git-stash-janitor run (Standard or Comprehensive) for `/Users/josh/Developer/alpsinsurance` by spawning a dedicated stash-janitor subagent or peer orch session. The actual cleanup is multi-pane work; this dispatch's worker scope ENDS at producing this triage-receipt + bundle-path proposal.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Run preflight against `/Users/josh/Developer/alpsinsurance` and record stash_count + selected mode | ✓ stash_count=82 (drift +3 vs bead-claimed 79); both Standard (bead) and Comprehensive (live-rubric) modes documented; primary_branch=main detected per skill axiom 4 |
| AG2 | Produce triage-only or full recovery receipt naming bundle path + proving no bundle deletion | ✓ Triage-only receipt (this file) names canonical path `/Users/josh/Developer/alpsinsurance-stash-archive-2026-05-09/`; no-deletion proof via `ls` on non-existent path |
| AG3 | Close only after orch schedules cleanup OR records explicit no_bead_reason deferral | ✓ Explicit deferral recorded with `no_bead_reason=triage-only-preflight-complete-orch-must-schedule-multi-pane-standard-or-comprehensive-run`; `flywheel_orch_action_required` flags orch to schedule the multi-pane run |

did=3/3

## Safety constraints honored

- **No destructive operations**: zero stash drops, zero apply, zero pop, zero ref mutation under `refs/stash-backup/`.
- **No bundle creation**: the bundle path is named in this receipt but does NOT exist; no bundle deletion possible.
- **No alpsinsurance edits**: read-only `git stash list` only; no working-tree changes; no commits to alpsinsurance.
- **No working-tree drift**: `git -C alpsinsurance status` not invoked here, but the read-only `stash list` does not modify any state.
- **Skill axiom 0 honored**: stashes are merge commits with extra parents; this preflight does not produce diffs (which would require `git stash show -p --binary`); the actual Phase-3 BUNDLE operator is deferred to the orch-scheduled run.
- **Skill axiom 7 honored**: no concurrent-agent working-tree changes were stashed/reverted/overwritten.
- **Skill axiom 8 honored**: `git stash pop` and `git stash apply` are forbidden by skill; not invoked here.
