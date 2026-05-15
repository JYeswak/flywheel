---
name: git-stash-discipline
type: doctrine
created: 2026-05-10
status: active
authority: joshua-direct-ask-<timestamp>
cluster: substrate-hygiene-doctrine-cluster
sisters:
  - repo-hygiene-operational-protocol.md
  - git-repo-discipline.md
  - blocker-discipline.md
---

# Git Stash Discipline (Fleet-Wide)

## Substrate-hygiene doctrine cluster

This doctrine is part of the **substrate-hygiene doctrine cluster** alongside
`repo-hygiene-operational-protocol.md`, `git-repo-discipline.md`, and
`blocker-discipline.md`. All four share a Meadows-lens diagnosis:
recursive-self-validation failure modes — substrate that nobody verifies
accumulates as silent debt.

- **git-stash-discipline.md** (this doctrine): addresses stash accumulation as durable storage (paradigm: stash is 24h scratch, not parking lot)
- **repo-hygiene-operational-protocol.md**: addresses repo accretion/bloat
  before it becomes a 70k-file cleanup event
- **git-repo-discipline.md**: addresses dirty working trees as unresolved
  decisions
- **blocker-discipline.md**: addresses blocker accumulation as unverified claims (paradigm: blockers are claims, not facts)

Both rely on per-tick orch verification + worker-time discipline + named trauma classes. When you read one, read the other — failure modes overlap.

## Mandate

Every flywheel-installed repo audits + cleans its `git stash` pile along the way. Stash accumulation is debt — worker handoffs left mid-task, "out-of-scope" inflight discoveries that never got filed as beads, recovery scratch never popped. The /git-stash-janitor skill exists to triage piles ≥5; the discipline is preventing piles from forming.

## Paradigm — stash is 24h scratch, not durable storage

**The Meadows-lens framing ({capability-control-plane}:1 substrate-discovery <timestamp>):** `git stash` is a 24-hour scratch buffer for short-lived "let me test something" interruptions. It is NOT durable storage. NOT a parking lot for "I'll figure this out later." NOT the right tool for tick-heartbeat noise or workspace pollution.

When the paradigm slips ("I'll just stash this for now"), accumulation begins. {capability-control-plane}'s N=16 audit traced 80% of stashes to two failure modes:
- **out-of-scope leak (44%)** — worker found unrelated work, stashed instead of filing a bead
- **AGENTS-CANONICAL pane leak (25%)** — workspace pollution stashed instead of `git restore`'d

Both failure modes are paradigm violations, not tooling gaps. The fix is not "better stash hygiene"; it's "use the right tool":
- Tick heartbeat noise → `git restore <path>` (not `git stash`)
- Out-of-scope discovery → file as bead (not `git stash`)
- Workspace pollution → `git restore` or commit-as-tick-noise (not `git stash`)
- Genuine "let me test something" → `git stash`, with hard 24h lifetime

## Worker responsibilities

A worker MUST NOT close a bead with a non-zero `git stash` count attributable to the worker's own session. Specifically:

1. **Don't stash and escape.** If you stashed mid-task to test something, pop it before close. If pop conflicts, that's a real signal — file as bead or in-tick fix, don't leave the stash.
2. **Name stashes meaningfully.** If you absolutely must leave a stash temporarily (e.g., long-running build can't be interrupted), use `git stash push -m "<bead-id>: <one-line-reason>"`. Anonymous WIP stashes are forbidden.
3. **24h lifetime cap.** A stash older than 24 hours has crossed the paradigm boundary — it has become durable storage. The worker who created it (or, if absent, the orch on its tick) MUST resolve it: pop, fold into a bead, or drop with explicit recovery-bundle backup. Stashes >24h old that nobody owns become orch-tick triage at next /git-stash-janitor cycle.
4. **Out-of-scope discoveries → bead, not stash.** If you find unrelated work mid-task, do not stash it for later. File it as a bead with the surface-discovery class. The codebase change goes into the bead body, not into a stash. **(out-of-scope leak class, 44% of {capability-control-plane} audit)**
5. **Tick heartbeat noise → `git restore`, not `git stash`.** Workspace pollution from tick automation (heartbeat counters, AGENTS.md drift, generated artifacts) is NEVER a stash candidate. Use `git restore <path>`, `git checkout -- <path>`, or commit-as-tick-noise. **(AGENTS-CANONICAL pane leak class, 25% of {capability-control-plane} audit)**
6. **Pop before close.** Worker close gate (L120 + worker-tick) MUST verify `git stash list | wc -l` is unchanged from session start (or has decreased — popped stashes count).
7. **AGENTS-CANONICAL noise stays unstaged.** Do not stash workspace pollution. If a tick generates noise (heartbeat counters, AGENTS.md drift), revert or commit-as-tick-noise; don't shift it into the stash list.

## Orch responsibilities

The orchestrator MUST audit stash state per tick:

1. **Per-tick stash count probe.** Every tick logs `git stash list | wc -l` for the active repo to STATE.md or tick metadata. Threshold thresholds:
   - N=0: clean (no signal)
   - N=1-4: notable, surface in tick output
   - N≥5: P1 — file `flywheel-stash-cleanup` bead at ≥P1, dispatch /git-stash-janitor at next batch
   - N≥10: P0 — halt new dispatch in current lane until cleaned (debt is too large)
2. **Per-bead stash delta.** When a worker closes a bead, orch verifies stash count didn't increase. If it did, the worker's compliance score drops; orch can refuse-and-redispatch with explicit fix-stash mandate.
3. **Cross-orch surfacing.** When ANY flywheel-installed repo crosses N≥10, orch sends P4 substrate-change letter to peer orchs (not for them to fix it, but for transparency — the discipline is fleet-wide).
4. **Pre-migration gate.** Before substrate-rewrite proposals (e.g., the upcoming Rust migration P3 at T+144h), orch enforces stash <5 across ALL coordinating repos. Migration into a dirty workspace compounds the migration risk.

## Boundary

- This doctrine governs `git stash` only. Uncommitted working-tree changes are a separate discipline (those should commit or revert).
- It does NOT prohibit stash use entirely — stash is a legitimate tool for short-lived "let me test something" interruptions. The discipline is *don't accumulate*.
- It does NOT apply to `refs/stash-backup/*` refs (those are /git-stash-janitor's recovery substrate; preserve them).
- Pop conflicts that reveal real bugs are a *win* — the conflict surfaced a class. File as bead, fix, then re-stash or drop.

## Application sequence

| Phase | Owner | Action |
|---|---|---|
| Worker close | worker | Verify own session's stash delta; refuse close if >0 attributable |
| Orch tick | orch | Probe stash count; emit signal at N≥1; bead at N≥5; halt at N≥10 |
| Cross-orch | orch | P4 letter when any peer repo crosses N≥10 |
| Pre-migration | orch | Enforce N<5 on all coord repos before substrate-rewrite proposals |
| Janitor flow | orch dispatches | /git-stash-janitor for piles N≥5 |

## Today's state (<timestamp>, snapshot)

- flywheel: N=2 (`ac4fy-revert-broken-py-scaffolds-2026-05-10` + WIP on master) — manual inspection class
- {capability-control-plane}: N=16 — P0 cleanup class (10+ threshold crossed)
- {session}, {proof-product}, vrtx, {session}, zesttube: not yet probed; orch tick to add this

This doctrine ratifies retroactively for all current piles AND prospectively for all future flywheel-installed repos.

## Named trauma classes

Two trauma classes codified by {capability-control-plane}:1 audit <timestamp> (preserved here as substrate-discovery; reference to {capability-control-plane}'s memory entry `feedback_stash_discipline_meadows_lens`):

### `out-of-scope-leak` (44% of {capability-control-plane} N=16 audit)

**Symptom:** stash messages like `"On <branch>: out-of-scope: pre-existing X"`, `"out-of-scope-tick-noise: AGENTS + blocker-counters"`, `"out-of-scope-heartbeat: blocker-tick-counters"`.

**Root cause:** worker found unrelated work mid-task, chose stash-and-escape over file-as-bead. The "I'll deal with this later" never happens; the stash accumulates.

**Fix:** out-of-scope discovery → `br create -p 2 -t bug "..."` with the find. The actual file change lives in the bead body or a follow-up commit. Stash is forbidden for this class.

**Detection:** orch tick scans stash messages for `out-of-scope` substring; flags as paradigm violation.

### `AGENTS-CANONICAL-pane-leak` (25% of {capability-control-plane} N=16 audit)

**Symptom:** stash messages like `"AGENTS-CANONICAL pre-reset"`, `"AGENTS-CANONICAL noise blocking pull"`, `"<pane-id> re-applied AGENTS-CANONICAL despite hard guardrail"`.

**Root cause:** tick automation generates AGENTS.md drift / heartbeat counters / workspace state files; worker treats these as stashable WIP rather than restorable noise.

**Fix:** workspace pollution from tick → `git restore <path>`. If the pollution is broad, commit it as `chore(tick): heartbeat noise YYYY-MM-DD` and move on. Stash is forbidden for this class.

**Detection:** orch tick scans stash messages for `AGENTS-CANONICAL` / `heartbeat` / `tick-noise` substrings; flags as paradigm violation.

## Cross-references

- `~/.claude/skills/git-stash-janitor/SKILL.md` — the triage flow when piles already exist
- `.flywheel/doctrine/filesystem-as-rag.md` — sister discipline (repo as RAG substrate)
- `.flywheel/doctrine/canonical-cli-cross-orch-protocols.md` — cross-orch propagation mechanism (when finalized)
- L120 br-close-executed gate — extension point for worker close-time stash check
- {capability-control-plane} memory `feedback_stash_discipline_meadows_lens` — substrate-discovery source for the 24h-scratch paradigm + 2 trauma classes (this doctrine folds those findings in via P1 CONTRACT calibration ratified 2026-05-10)

## Wire-in plan

See `.flywheel/audit/<bead-id>/apply-spec.md` for the bead that implements this doctrine. Filed as separate workstream.
