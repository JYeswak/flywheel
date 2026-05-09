# flywheel-aci8s Evidence — skillos stash-janitor Quick mode triage

Task: `flywheel-aci8s-1727d4`
Bead: `flywheel-aci8s` (P2 OPEN → CLOSED this turn)
Title: [stash-janitor target] skillos — 5 stashes — Quick mode triage
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Target repo: `/Users/josh/Developer/skillos`
Parent: `flywheel-hnul2` (CLOSED 2026-05-08) — git-stash-janitor wire-in.
Mode: Quick (single-agent, ~10-20 min). NO mutation; surface findings only.
Mission fitness: `mission_fitness=infrastructure` — reduces stash-bloat
substrate noise so future ticks see clean ledger surfaces.

## Headline finding

The 2026-05-08T03Z snapshot reported 5 stashes (Quick mode tier). At
2026-05-09T15:48Z **the count is 16, not 5**. The growth is concentrated
in cross-pane "AGENTS-CANONICAL.md mass-bleed" stashes — pane 2 repeatedly
attempted to push 4000-4500 line `.flywheel/AGENTS-CANONICAL.md`
rewrites onto skillos `main`, and the operator stashed each attempt
behind an `out-of-scope-*` label. The accretion pattern is documented in
canonical memory `feedback_canonical_recipe_scoped_commit_by_pathspec.md`
and `feedback_naming_rename_is_cross_repo_wire_or_explain.md`.

11 of 16 stashes are explicitly tagged `out-of-scope*` or
`AGENTS-CANONICAL` cross-pane noise. **Quick mode triage classifies them
as DROP-after-Joshua-signoff candidates**; mutation is owner-gated per
the Joshua-disposes axiom and per the parent bead's plan.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — artifact updated with close evidence | DID | this evidence pack at `.flywheel/audit/flywheel-aci8s/`; per-stash summary, timeline, mass-bleed list captured |
| AG2 — targeted dry-run / validator passes and is named | DID | `git stash list` (16 entries), `git stash show -s` per index, `git stash show --stat` per index, `git log -1 --format=%cI` per index — all read-only re-runnable in <5s |
| AG3 — `br show flywheel-aci8s` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |
| Skillos-side bead surfaced | DID | `beads_filed=skillos-dkq5` (filed below by `br create` against /Users/josh/Developer/skillos beads) |

did=4/4 didnt=none gaps=none.

## Per-stash classification

| Stash | TS | Branch | Subject | Class | Reason |
|---|---|---|---|---|---|
| @{0} | 2026-05-09T09:14 | chore/jeff-stack-triage-2026-05-09 | phase18-fork-stash | NEEDS-OWNER-DECISION | Recent (today). 92-line `.flywheel/run-30m-loop.sh` + 2 state files. Active branch context. |
| @{1} | 2026-05-08T12:57 | main | out-of-scope: pre-existing blocker-tick-counters | DROP-CANDIDATE | Tiny 4-line state file edit, explicit out-of-scope tag, sibling of the AGENTS-CANONICAL bleed cluster. |
| @{2} | 2026-05-08T11:58 | main | out-of-scope: pre-existing AGENTS+blocker noise | DROP-CANDIDATE | AGENTS-CANONICAL +4583 / +4169 lines. Cross-pane bleed pattern. |
| @{3} | 2026-05-08T10:48 | main | out-of-scope-tick-noise: AGENTS + blocker-counters | DROP-CANDIDATE | Same shape as @{2}; near-duplicate. |
| @{4} | 2026-05-08T10:24 | main | AGENTS-CANONICAL pre-reset | DROP-CANDIDATE | AGENTS-CANONICAL +4583 / +4167 lines. |
| @{5} | 2026-05-08T10:19 | main | AGENTS-CANONICAL noise blocking pull | DROP-CANDIDATE | AGENTS-CANONICAL +4578 / +4162 lines. |
| @{6} | 2026-05-08T10:11 | main | out-of-scope: AGENTS-CANONICAL.md pre-existing leak | DROP-CANDIDATE | AGENTS-CANONICAL +4578 / +4162 lines. |
| @{7} | 2026-05-08T09:57 | feat/skillos-15-5k-expand-audit-patterns | out-of-scope-heartbeat: blocker-tick-counters | DROP-CANDIDATE | 4-line state edit; tagged out-of-scope. |
| @{8} | 2026-05-08T09:23 | feat/skillos-15-5fghij-cli-unify-doctor-hooks-extractions | out-of-scope-tick-heartbeat: AGENTS + state ledgers | DROP-CANDIDATE-PARTIAL | AGENTS-CANONICAL +4543 (drop part) BUT also touches `state/skill-drift.jsonl`, `state/skill-freshness.jsonl`, `state/skill-inventory.json` — those state ledger edits MAY contain unique signal. Owner should split before drop. |
| @{9} | 2026-05-08T00:00 | main | out-of-scope-ATTEMPT-2: pane 2 re-applied AGENTS-CANONICAL despite hard guardrail | DROP-CANDIDATE | AGENTS-CANONICAL +4436 / +4020 lines. Explicit guardrail-violation label from operator. |
| @{10} | 2026-05-07T23:48 | main | out-of-scope: pane 2 AGENTS-CANONICAL rewrite + heartbeat | DROP-CANDIDATE | AGENTS-CANONICAL +4436 / +4022 lines. |
| @{11} | 2026-05-07T10:48 | feat/loop-1-wave-c-drift-router | wave-d-stash | DROP-CANDIDATE | Empty diff (no insertions). Likely an empty-stash artifact. |
| @{12} | 2026-05-07T09:45 | feat/yuzu-hero-upgrade | track-1-stash-1778168754 | DROP-CANDIDATE | Only `__pycache__/*.pyc` binary diffs. Pycache stashes are never useful. |
| @{13} | 2026-05-06T22:28 | master | j1ad-linter-stripped-class | NEEDS-OWNER-DECISION | 3 files, +126/-18: routing ledger + receipt + `tests/unit/test_pack_registry.py` deletions. Linter-stripped tests may matter. |
| @{14} | 2026-05-06T13:05 | master | WIP on master: b1d7d9f fix(jsm-db) skillos-hhx2 | NEEDS-OWNER-DECISION | 9275 insertions across beads/issues.jsonl + AGENTS-CANONICAL +3551 + MISSION +2139 + AGENTS.md +3379 + scripts. Largest stash. WIP on a real commit (`skillos-hhx2`) — may have shipped already or carry residual fix work. |
| @{15} | 2026-05-05T16:00 | master | G-pre-commit-smoke | NEEDS-OWNER-DECISION | scripts/sniff/sniff -1421 lines (binary deletion!) + AGENTS-CANONICAL +45 + MISSION +1162 + last_closeout_receipt.json delta. The sniff-binary deletion is significant; if the deletion landed via a different path the stash is moot, but if not, this represents either a revert or a binary-management change. |

## Class distribution

- DROP-CANDIDATE: 12 (75%) — out-of-scope cross-pane bleed, pycache, empty
- NEEDS-OWNER-DECISION: 4 (25%) — @{0}, @{13}, @{14}, @{15}
- KEEP-AS-IS: 0

## Bleed-cluster signal

8 of 16 stashes (@{2}, @{3}, @{4}, @{5}, @{6}, @{8}, @{9}, @{10}) all carry
AGENTS-CANONICAL.md mass-edits in the +4000 to +4583 line range, with
identical-shape diff stat lines. Operator labels them out-of-scope or
pre-reset noise. This is the **canonical-recipe-scoped-commit-by-pathspec
trauma class** repeating: peer pane (likely pane 2) rewriting
AGENTS-CANONICAL via untrimmed `git add -A` + push attempt; operator
stashes the residue to keep main pull-clean.

The growth from 5 → 16 stashes in ~36h is meaningful — the bleed pattern
hasn't been remediated upstream; pane 2 keeps re-attempting.
**Action proposed (skillos-side bead, NOT executed here)**: install a
pre-commit guard on skillos that refuses cross-pane AGENTS-CANONICAL
diffs >500 lines without an explicit `--canonical-rewrite-approved`
sentinel.

## Verification commands (re-runnable)

```bash
cd /Users/josh/Developer/skillos

# Re-derive stash list + timeline
git stash list
for i in $(seq 0 15); do
  ts="$(git log -1 --format=%cI "stash@{$i}" 2>/dev/null)"
  subj="$(git log -1 --format=%s "stash@{$i}" 2>/dev/null | head -c 90)"
  printf 'stash@{%d}\t%s\t%s\n' "$i" "${ts:0:19}" "$subj"
done

# Re-derive mass-bleed cluster (insertions > 1500)
for i in $(seq 0 15); do
  ins="$(git stash show --stat "stash@{$i}" 2>/dev/null | tail -1 \
        | grep -oE '[0-9]+ insertions' | grep -oE '[0-9]+' | head -1)"
  ins="${ins:-0}"
  [[ "$ins" -gt 1500 ]] && echo "stash@{$i}: insertions=$ins"
done
```

## L112 probe (worker callback)

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-aci8s/evidence.md \
  && grep -q "DROP-CANDIDATE: 12" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-aci8s/evidence.md \
  && grep -q "NEEDS-OWNER-DECISION: 4" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-aci8s/evidence.md \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No stash mutation.** No `git stash drop`, no `git stash apply`, no
  branch creation, no pop. Quick mode = surface only; mutation is
  Joshua-gated per the parent bead's plan (skillos has pending L126
  doctrine cohort plan `flywheel-rdqc7` per the dispatch packet — stash
  drop must wait for cohort apply or run on an isolated branch).
- **No skillos production code touched.** Read-only commands only.
- **Cross-repo discipline.** Bead `flywheel-aci8s` lives in flywheel
  beads; the evidence pack lives in flywheel `.flywheel/audit/`. The
  actionable follow-up bead is filed against /Users/josh/Developer/skillos
  beads (skillos-dkq5) so skillos:1 orch can pick it up.
- **Count growth flagged.** The bead's headline `5 stashes` is stale at
  the time of this triage (16 stashes). The triage applies the requested
  Quick mode protocol but the operator should reclassify the work tier
  if drop-execution is dispatched separately (16 stashes is technically
  Standard tier, 10-80 range).

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored; `git stash` is the
  read-only surface.
- `rust-best-practices=n/a` — no Rust touched.
- `python-best-practices=n/a` — no Python touched.
- `readme-writing=n/a` — audit-doc style.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — read-only triage; no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=read_only_quick_mode_triage_no_mutation_of_skillos_or_flywheel_canonical_surfaces`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes the 3 acceptance gates verbatim. The 5→16 count
  growth is called out as part of the triage, not buried.
- **Sniff: 9** — every classification cites concrete evidence (insertion
  count, label, branch, ts). The mass-bleed cluster is detected
  algorithmically (insertions > 1500) and cross-checked against the
  operator's stash messages.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; problem-statement
  framing for the bleed pattern (route to skillos-side pre-commit guard,
  don't auto-fix); no upstream patch to any Jeffrey-owned repo; small
  surface (one audit doc + one follow-up bead).
- **Public: 9** — Three Judges check passes:
  - **operator (skeptical, acting tomorrow)**: 12-row class table is
    grep-friendly; one shell loop re-derives the timeline + mass-bleed
    list in <5s.
  - **maintainer (extending later)**: insertion-count threshold (>1500)
    is explicit so future re-runs catch the same cluster shape.
  - **future worker (LLM agent)**: bar named (Three Judges + Jeffrey +
    Donella); class semantics (DROP-CANDIDATE vs NEEDS-OWNER-DECISION)
    explicit so a future stash-janitor pass can act on the same
    classification without re-deriving it.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8;
bar = Three Judges + Jeffrey Emanuel publishability + Donella Meadows
leverage).

## L52 Receipt

`beads_filed=skillos-dkq5 beads_updated=flywheel-aci8s
no_bead_reason=triage_complete_skillos_side_followup_filed_for_drop_execution_on_isolated_branch`.
