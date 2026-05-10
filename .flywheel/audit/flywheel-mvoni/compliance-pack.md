# flywheel-mvoni Compliance Pack

Task: `flywheel-mvoni-6dd814`
Bead: `flywheel-mvoni` (P2)
Decision: DONE (triage-only preflight + explicit deferral via AG3 OR-branch)
Compliance score: 880/1000

## Final receipt

```
ag1_status=PREFLIGHT-COMPLETE — stash_count=16 (drift +11 vs bead-claimed 5; 3.2× count growth in 24h); mode=Standard (live-rubric, escalated from bead's Quick)
ag2_status=TRIAGE-RECEIPT-WRITTEN — bundle path /Users/josh/Developer/skillos-stash-archive-2026-05-09/ named; no-deletion proof captured
ag3_status=EXPLICIT-DEFERRAL-RECORDED — no_bead_reason=triage-only-preflight-complete-orch-must-schedule-multi-pane-standard-run-mode-escalated-from-quick-due-to-plus-11-drift
destructive_operations_performed=0
skillos_repo_mutations=0 (read-only stash list)
files_reserved=NONE_NO_EDITS
active_contention_signal_surfaced=multi-pane-AGENTS-CANONICAL-contention-may-still-be-live
```

## Finding

Significant drift surfaced — the bead's `stash_count=5 recommended_mode=Quick`
is stale by **3.2× the count** (24h growth). Live state is 16 stashes in
Standard band per skill rubric SKILL.md:116 (10-80 = Standard, 5-9 = Quick).

The +11 stash growth on a small repo strongly signals active worker
activity in the skillos session between bead-filing (2026-05-08) and
now. Stash messages reveal a recurring multi-pane AGENTS-CANONICAL
contention class — 8 of the 16 stashes are AGENTS-CANONICAL noise,
including stash@{9}'s explicit "pane 2 re-applied AGENTS-CANONICAL
despite hard guardrail" message text.

Per skill axiom 7 ("never stash, revert, or overwrite changes made by
parallel agents"), the orch-scheduled cleanup should pre-flight check
that the contention has stabilized before invoking Phase-3 BUNDLE.
Otherwise the cleanup itself becomes a parallel-agent-stash race.

## Repair

Triage-only preflight receipt at
`.flywheel/audit/flywheel-mvoni/triage-receipt.md`. The receipt:

- Names the canonical bundle path
  `/Users/josh/Developer/skillos-stash-archive-2026-05-09/`.
- Proves no bundle deletion (path doesn't exist).
- Documents the +11 stash drift vs bead-claimed 5.
- Family-classifies the 16 stashes (AGENTS-CANONICAL noise: 8;
  out-of-scope-tick-heartbeat: 2; WIP/branch-checkpoint: 4;
  pre-commit smoke: 1; unique today's: 1).
- Surfaces the active-contention signal as an axiom-7 pre-flight
  requirement for any orch-scheduled cleanup.
- Recommends skillos-session-scoped dispatch per memory
  `project_skillos_separated.md` (skillos owns its own orchestration).

No destructive operations performed. No skillos repo mutations
beyond read-only `git stash list`.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Run preflight against `/Users/josh/Developer/skillos` and record stash_count=5 + Quick mode | ✓ stash_count=16 (drift +11); mode escalated to Standard per live rubric; primary_branch=main detected |
| AG2 | Produce triage-only or full recovery receipt naming bundle path + proving no bundle deletion | ✓ Triage-only receipt written; canonical path named; no-deletion proof via `ls` exit on non-existent path |
| AG3 | Close only after orch schedules OR records explicit no_bead_reason deferral | ✓ Explicit deferral recorded; orch-action required to schedule cross-session multi-pane run |

did=3/3

## Evidence

```text
$ # AG1 stash census:
$ git -C /Users/josh/Developer/skillos stash list | wc -l
16

$ # AG2 bundle path no-deletion proof:
$ ls -d /Users/josh/Developer/skillos-stash-archive-2026-05-09 2>&1
ls: /Users/josh/Developer/skillos-stash-archive-2026-05-09: No such file or directory

$ # Mode rubric source citation:
$ grep -nE "Standard 10–80" ~/.claude/skills/git-stash-janitor/SKILL.md
116:| **Stash count** ... Standard 10–80, Comprehensive 80+ ...

$ # Active contention signal:
$ grep -E "pane 2.*re-applied" .flywheel/audit/flywheel-mvoni/stash-list.txt
stash@{9}: On main: out-of-scope-ATTEMPT-2: pane 2 re-applied AGENTS-CANONICAL despite hard guardrail
```

## Scope

- Edits: 4 new files in flywheel audit dir (NO skillos edits)
  - `.flywheel/audit/flywheel-mvoni/stash-count.txt`
  - `.flywheel/audit/flywheel-mvoni/stash-list.txt` (full 16-line list)
  - `.flywheel/audit/flywheel-mvoni/triage-receipt.md` (AG2 receipt)
  - `.flywheel/audit/flywheel-mvoni/compliance-pack.md` (this file)
- Files reserved/released: NONE_NO_EDITS
- Out of scope: actual Standard-mode triage run (skillos-session-scoped
  multi-pane work); creating the bundle directory; any destructive ops
  on skillos stash refs

## L52 / L80 / L120 / L61

- DIDNT: actual triage run (deferred per AG3 OR-branch)
- GAPS: none new; +11 stash drift documented in triage-receipt
- beads_filed: none
- beads_updated: none
- no_bead_reason: triage-only-preflight-complete-orch-must-schedule-multi-pane-standard-run-mode-escalated-from-quick-due-to-plus-11-drift
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- flywheel_orch_action_required: schedule-skillos-session-scoped-standard-mode-stash-janitor-after-confirming-AGENTS-CANONICAL-contention-stabilized

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — read-only `git stash list`
  invocation; bundle protocol uses `git stash show -p --binary`
  (axiom 0); receipt avoids the `git format-patch` axiom-6 footgun;
  stable exit codes preserved
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — 3.2× drift surfaced
  rather than bead-claim rubber-stamped; mode escalation
  recommended per live-rubric; cross-session-coordination
  respected per memory `project_skillos_separated.md`)
- Sniff: 9 (claims grounded in live `git stash list` output saved
  as durable evidence; family-classification spot-checks against
  stash messages; active-contention signal cited via
  stash@{9}'s message text; mode-rubric cited at SKILL.md:116;
  axiom 7 cited for the contention pre-flight requirement)
- Jeff: 8 (no Jeffrey-substrate touch; canonical bundle protocol
  honored; the kickstart-trauma stash@{14} reference is observed
  but not acted on)
- Public: 9 (Three-Judges check: an operator can re-run the stash
  count probe; a maintainer 6 months from now sees the drift
  documentation, the family classification, and the active-
  contention signal — and understands WHY this is deferred to
  cross-session orchestration; a downstream skillos-session
  worker can pick up this triage-receipt and start at Phase-3
  BUNDLE with the canonical path already named)

## L112 Probe

```
git -C /Users/josh/Developer/skillos stash list 2>/dev/null | wc -l
```
Expected: `grep:1[0-9]` (a count in the 10s — proves the stash
census class is correct without locking to a specific count
that might shift again given the active-contention signal).
The receipt records the exact value at capture time (16); the
live probe confirms the order-of-magnitude class.
