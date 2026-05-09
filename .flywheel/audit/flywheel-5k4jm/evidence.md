# flywheel-5k4jm Evidence — picoz git-stash-janitor Standard mode triage

Task: `flywheel-5k4jm-782d58`
Bead: `flywheel-5k4jm` (P2 OPEN → CLOSED this turn)
Title: [git-stash-janitor] picoz stash census 34 Standard-mode run
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Target repo: `/Users/josh/Developer/polymarket-pico-z`
Mode: Standard (10-80 stash range; 34 today).
Mission fitness: `mission_fitness=infrastructure` — substrate audit
that pairs the existing 2026-05-08 archive bundle with classification
+ owner-gated cleanup routing.

## Headline finding — bundle already exists, classification + cleanup followup filed

The dispatch's AG2 ("produce a triage-only or full recovery receipt
naming the bundle path `<basename>-stash-archive-YYYY-MM-DD/` and
proving no bundle deletion") is satisfied by an **existing**
4-layer recovery bundle at
`/Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/`,
created 2026-05-08T23:49:48Z. Today's stash count (34) matches that
snapshot — no growth, no deletion, bundle integrity intact.

This rework therefore:

1. Confirms census = 34 + selected mode = Standard (AG1).
2. Cites the existing bundle path + proves no deletion (AG2).
3. Files Joshua-gated cleanup-execution follow-up `bd-nxvfs` against
   picoz beads (AG3).

No `git stash drop`, no `cherry-pick`, no archive mutation, no
working-tree edit.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — preflight against picoz, record stash_count=34 + mode=Standard | DID | `git stash list \| wc -l` = 34 (matches bead expectation); 34 falls in the Standard tier (10-80) per `~/.claude/skills/git-stash-janitor/SKILL.md` mode-by-count table; full timeline in `stash-timeline.txt` |
| AG2 — triage receipt names bundle path, proves no deletion | DID | bundle exists at `/Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/` (created 2026-05-08T23:49:48Z); `bundle-integrity.txt` confirms 34 diffs + 34 meta + 35-line index.tsv (header + 34 rows) + 34 `refs/stash-backup/*` permanent refs (survive git gc); no new bundle created today; no bundle deleted |
| AG3 — close after target orch schedules cleanup OR records explicit no_bead_reason | DID | follow-up `bd-nxvfs` filed in picoz beads (P2 OPEN, labels `stash-janitor,owner-gated,bundle-recovery`) with the 4-step Joshua-gated cleanup sequence; this satisfies the "schedules cleanup" branch of AG3 |

did=3/3 didnt=none gaps=none.

## Mode selection (per skill table)

| Stash count | Mode | This bead |
|---|---|---|
| < 5 | manual-default warning | n/a |
| **5-9** | Quick (single-agent ~15-30min) | n/a |
| **10-80** | **Standard** (Pair or Squad ~1-3h) | **34 → Standard ✓** |
| 80+ | Comprehensive | n/a |

Triage-only path was taken (read-only census + classification +
follow-up). Full recovery (drop + cherry-pick) is owner-gated under
`bd-nxvfs`.

## Per-stash classification (34 stashes)

Two-axis classification: **content tier** (size/scope) × **operator
intent** (named vs WIP-on-bd).

### Distribution by content tier

| Tier | Count | Stashes | Action class |
|---|---|---|---|
| Tiny (<100 ins) | 7 | @{4}, @{5}, @{14}, @{17}, @{21}, @{29}, @{30}, @{32}, @{33} | DROP-CANDIDATE after fresh-eyes; many are bd-* WIP that landed via the named bead |
| Small (100-500 ins) | 18 | @{0}, @{1}, @{2}, @{3}, @{7}, @{8}, @{10}, @{11}, @{13}, @{15}, @{16}, @{18}, @{19}, @{20}, @{22}, @{23}, @{27} | majority WIP-on-bd; cross-check each against the named bead's close commit before drop |
| Medium (500-1500 ins) | 4 | @{6}, @{9}, @{12}, @{26} | NEEDS-OWNER-DECISION; medium scope = possibly unique work |
| Large (>1500 ins) | 4 | @{24} (1541), @{25} (3572), @{28} (9797), @{31} (8562) | **NEEDS-OWNER-DECISION**; one stash has 308 files — likely a full session |

### Distribution by operator intent

- **Operator-named** (8): `@{4} bd-pre-existing-test-fix-WIP`,
  `@{6} agent-F-pre-rebase-stash`, `@{10} wave6-deferred-files`,
  `@{14} pane2-bd-14ufj-corrupted-schema-2026-04-21`,
  `@{19} bd-n9mv7 preserved work: narrow except at Kalshi API boundary
  (blocked on post-ship probe r`,
  `@{29} incomplete P2 cron label fix — needs proper bead`,
  `@{30} session68-bg-worker-wip: incomplete Phase 1B for
  compute_features/edge_analyzer/kalshi_trad`,
  `@{32} my v4_palette gradient helpers — P1 used StyledText instead`.
  These have explicit operator narrative; some explicitly say
  "incomplete" (29, 30) — those need either a proper bead or drop.
- **WIP-on-bd-* (auto)** (22): every other stash. Most likely
  superseded by their named bead's landing commit; drop after the
  fresh-eyes step in `bd-nxvfs` confirms the bd-* parent landed on
  main.
- **Other** (4): pure `WIP on main` without bd-* (e.g., @{0}/@{1}
  duplicate of bd-1iyf8 commit a73b7576).

### Staleness

- **Oldest:** stash@{33} 2026-04-07 (32 days).
- **Youngest:** stash@{0} 2026-04-25 (14 days).
- **No stash created in the last 14 days** — repo has been quiet,
  consistent with picoz being on a maintenance pause.

## Bundle integrity (verbatim from `bundle-integrity.txt`)

```
== bundle path ==
/Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08

== bundle exists (no deletion) ==
drwxr-xr-x@ 7 josh  staff  224 May  8 17:49 /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08

== contents counts ==
diffs:          34
meta:           34
index:          35

== refs/stash-backup ref count ==
      34

== current stash count (parity check vs bundle) ==
      34
```

The 4 layers per the bundle's own README:

1. `refs/stash-backup/<NNN>` — permanent refs inside picoz `.git/`,
   34 confirmed via `git for-each-ref refs/stash-backup/`.
2. `diffs/<NNN>.diff` — tracked/index diffs, 34 confirmed.
3. `meta/<NNN>.txt` — sha + parent + date + author + untracked flag
   + message, 34 confirmed.
4. `stashed-untracked/<NNN>/` — materialized untracked files (only
   for `git stash -u` stashes), present in bundle.

Recovery recipes (cited in bundle README):

```bash
# Single stash by backup ref (preferred)
git cherry-pick -m 1 refs/stash-backup/034

# Single stash by bundle diff
git apply --3way --check /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs/034.diff
```

## Follow-up bead — `bd-nxvfs`

P2 OPEN in picoz beads with 4-step Joshua-gated cleanup sequence:

1. Operator fresh-eyes review of the 4 large stashes (@{24}, @{25},
   @{28}, @{31}) and 8 operator-named stashes against current main.
2. For stashes whose `bd-*` parent landed, `git stash drop`.
3. For stashes with unique work, `git cherry-pick -m 1
   refs/stash-backup/<NNN>` onto a feature branch.
4. Verify post-drop count + bundle integrity.

Bundle recoverability is permanent (`refs/stash-backup/*` survive
`git stash drop` and `git gc`); drop is fully reversible until the
bundle dir is deleted.

## Verification commands (re-runnable)

```bash
# Census parity
cd /Users/josh/Developer/polymarket-pico-z && git stash list | wc -l
# expected: 34

# Bundle layers intact
ls -d /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08
ls /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs/ | wc -l   # expected: 34
ls /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/meta/  | wc -l   # expected: 34
wc -l /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/index.tsv     # expected: 35
( cd /Users/josh/Developer/polymarket-pico-z && git for-each-ref refs/stash-backup/ | wc -l )
# expected: 34

# Follow-up bead exists
( cd /Users/josh/Developer/polymarket-pico-z && br show bd-nxvfs | head -2 )
```

## L112 probe (worker callback)

```bash
test -d /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08 \
  && [ "$(ls /Users/josh/Developer/polymarket-pico-z-stash-archive-2026-05-08/diffs | wc -l | tr -d ' ')" -eq 34 ] \
  && [ "$( cd /Users/josh/Developer/polymarket-pico-z && git stash list | wc -l | tr -d ' ' )" -eq 34 ] \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No stash mutation.** No `git stash drop`, no `cherry-pick`, no
  bundle deletion.
- **No working-tree edit in picoz.** Read-only commands only.
- **No flywheel doctrine surface mutated.** No L-rule, no AGENTS.md,
  no INCIDENTS.
- **Cross-repo discipline.** Bead `flywheel-5k4jm` lives in flywheel
  beads; the audit pack lives in flywheel `.flywheel/audit/`; the
  cleanup-execution follow-up `bd-nxvfs` lives in picoz beads so the
  picoz orchestrator can pick it up.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored. `git stash` is the
  read-only surface; the bundle was generated by the existing
  `git-stash-janitor` skill yesterday.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; this is a
  per-repo triage receipt, not a new L-rule.
- `readme_updated=not_applicable`.
- `no_touch_reason=read_only_triage_no_canonical_surface_or_doctrine_mutated`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. The existing 2026-05-08
  bundle is named explicitly so the deliverable is a clean
  triage-receipt rather than a redundant rebuild.
- **Sniff: 9** — bundle integrity is verified four ways
  (diffs count, meta count, index lines, packed-refs `stash-backup`
  refs); current stash count parity with the bundle snapshot proves
  no growth or shrinkage; no destructive operation.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface
  (one audit pack + one follow-up bead); refuses unsigned cleanup
  execution per Joshua-disposes; no upstream patch.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: classification table is
    grep-friendly, recovery recipes pasted from the bundle README, one
    shell snippet validates each integrity claim.
  - **maintainer (extending later)**: tier definitions explicit so a
    future picoz triage can drop into the same shape.
  - **future worker (LLM agent)**: bar named, follow-up bead carries
    the 4-step gated sequence, the Standard-mode template is
    reusable for the next 10-80 stash repo.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=bd-nxvfs beads_updated=flywheel-5k4jm
no_bead_reason=triage_complete_picoz_side_followup_filed_for_owner_gated_cleanup_execution`.
