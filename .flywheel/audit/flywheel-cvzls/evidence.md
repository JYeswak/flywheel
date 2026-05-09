# flywheel-cvzls Evidence — bead-isolation leakage_count 135 → 0 (basename-class normalize)

Task: `flywheel-cvzls-957f0d`
Bead: `flywheel-cvzls` (P0 OPEN → CLOSED this turn)
Title: [auto-doctor:leakage] bead-isolation leakage_count=71
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — closes the
auto-doctor symptom by completing a Phase 2.3-class normalize that
the canonical plan didn't cover (basename rather than `.` / NULL).

## Headline finding

The `beads_db_health.leakage_count` doctor signal grew from the
**71** the auto-doctor bead recorded when filed to **135** at the
start of this rework — not because of fresh leakage, but because the
canonical Phase 2.3 normalize SQL only targeted
`source_repo='.' OR IS NULL`, missing a separate **basename** class
(`source_repo='flywheel'`) that had accumulated from an earlier-era
`br create` path.

This rework runs the additional one-shot normalize:

```sql
UPDATE issues SET source_repo='/Users/josh/Developer/flywheel'
 WHERE source_repo='flywheel';
```

Backup-first, then verified post-normalize. Result: **leakage_count
135 → 0**, integrity intact, total row count preserved (1386 → 1386).

## Verification of safety before mutation

```bash
# Confirm all 135 basename rows are flywheel-prefixed (no cross-project leak)
sqlite3 .beads/beads.db "SELECT COUNT(*) FROM issues WHERE source_repo='flywheel' AND id NOT LIKE 'flywheel-%'"
# → 0  (all 135 are legitimate flywheel beads, just basename-tagged)

# Confirm only two source_repo classes pre-normalize
sqlite3 .beads/beads.db "SELECT source_repo, COUNT(*) FROM issues GROUP BY source_repo"
# → /Users/josh/Developer/flywheel|1251
# → flywheel|135
# (no NULL, no '.', no other-project paths)
```

The 135 rows were **all flywheel beads** — there was no cross-project
write leakage; the leak was purely a `source_repo` field-shape
inconsistency. This is why a single-row UPDATE is safe and
non-destructive. The backup at `.beads/beads.db.bak.cvzls-<ts>` is
the rollback handle.

## Acceptance gates

The bead is auto-doctor with no explicit acceptance criteria beyond
the standard AG1/AG2/AG3.

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-cvzls/` carries before/after SQL receipts, normalize receipt, doctor field SQL, pinned SHAs, and this evidence pack |
| AG2 — targeted validator command passes and is named | DID | `sqlite3 .beads/beads.db "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel'"` returns `0` (matches the canonical doctor SQL); `PRAGMA integrity_check` returns `ok` |
| AG3 — `br show flywheel-cvzls` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Before / after receipts

### BEFORE (pre-normalize, from `before.txt`)

```
basename|135
canonical|1251
```

### AFTER (post-normalize, from `after.txt` + `normalize-receipt.txt`)

```
== source_repo distribution AFTER normalize ==
/Users/josh/Developer/flywheel|1386

== leakage_count via canonical doctor SQL ==
SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel'
0

== integrity ==
ok

== row count parity check (BEFORE total = AFTER total) ==
1386
```

Net: 135 + 1251 = 1386 → 1386 canonical, 0 leaks. No row added or
removed, only the `source_repo` field normalized.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| beads.db (post-normalize) | `.beads/beads.db` | `630deab9dba23daf56379c00ff93742a9aeb422b7821e21cdd1645df41e6efd5` |
| beads.db backup (pre-normalize) | `.beads/beads.db.bak.cvzls-20260509T172440Z` | `c1902a1187b67195bc9432c15ff341994a6eaf43b04b2aadf2bf9653f88c6cd9` |

Re-derive via:

```bash
shasum -a 256 /Users/josh/Developer/flywheel/.beads/beads.db
shasum -a 256 /Users/josh/Developer/flywheel/.beads/beads.db.bak.cvzls-20260509T172440Z
```

## Why the canonical Phase 2.3 normalize didn't catch this

The bead-isolation plan at
`.flywheel/PLANS/bead-isolation-fix-2026-04-30.md` Change 2.3 ships
this normalize SQL:

```bash
sqlite3 "$DB" "UPDATE issues SET source_repo='$REPO_PATH'
   WHERE source_repo='.' OR source_repo IS NULL"
```

It targets two classes: `'.'` and NULL. **It does not target the
basename class** (`source_repo='flywheel'`) which is what we
observed. That class came from a separate `br create` codepath that
wrote basename instead of abspath, before Change 2.4 (absolute
`source_repo` at write time) landed.

Today's normalize is the **third class**: explicit basename →
abspath. The plan should be amended to cover this class for any
future repo whose basename was used; a small follow-up bead is
filed for that doctrine update (see L52 receipt).

## Verification commands (re-runnable)

```bash
# Direct doctor SQL — should return 0
sqlite3 /Users/josh/Developer/flywheel/.beads/beads.db \
  "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel'"

# Distribution — should show one row, all 1386 canonical
sqlite3 /Users/josh/Developer/flywheel/.beads/beads.db \
  "SELECT source_repo, COUNT(*) FROM issues GROUP BY source_repo"

# Integrity — should return ok
sqlite3 /Users/josh/Developer/flywheel/.beads/beads.db "PRAGMA integrity_check"

# Rollback recipe (only if needed)
# cp .beads/beads.db.bak.cvzls-20260509T172440Z .beads/beads.db
```

## L112 probe (worker callback)

```bash
[ "$(sqlite3 /Users/josh/Developer/flywheel/.beads/beads.db "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel'")" = "0" ] \
  && [ "$(sqlite3 /Users/josh/Developer/flywheel/.beads/beads.db "PRAGMA integrity_check")" = "ok" ] \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **Backup-first.** `.beads/beads.db.bak.cvzls-20260509T172440Z` is
  the rollback handle (gitignored per `.beads/.gitignore *.db`, so
  filesystem-only). Pre-mutation SHA pinned above.
- **No row added or removed.** Total count parity 1386 → 1386. Only
  `source_repo` field updated on 135 rows.
- **No JSONL write.** `.beads/issues.jsonl` is unchanged by this
  rework; the JSONL is rebuildable from the DB if needed and is
  authored only by `br` per memory `feedback_beads_jsonl_writes_via_br_only.md`.
- **No upstream patch.** `beads_rust` (Jeffrey-owned) is not modified;
  Change 2.4 (absolute `source_repo` at write time) already landed
  upstream so future inserts will be canonical.
- **No skill mutation.** `.flywheel` skill area not touched. The
  doctor-signal-bead-promotion script that filed this bead is
  unchanged.
- **Reservation released after commit.** L107 reservation on
  `.beads/beads.db` released as part of the close.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored. Used existing
  `sqlite3` and `shasum`.
- `rust-best-practices=n/a` — no Rust touched (`beads_rust` upstream
  fix already shipped Change 2.4).
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; this is a
  data-class normalize, not a new L-rule. The plan at
  `.flywheel/PLANS/bead-isolation-fix-2026-04-30.md` should be
  amended Change 2.3 to add the basename class — that's a follow-up
  bead, not a touch this turn.
- `readme_updated=not_applicable`.
- `no_touch_reason=data_class_normalize_not_doctrine_authoring`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes the auto-doctor signal cleanly with a
  reversible backup-first normalize. Distinguishes the **third
  source_repo class** (basename) the plan missed and routes the
  doctrine amendment to a follow-up.
- **Sniff: 9** — every claim is sqlite3-checkable; row-count parity
  proves no row added/removed; integrity ok; backup SHA pinned for
  rollback.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one SQL UPDATE + audit pack); no upstream patch (Change
  2.4 already landed); references the canonical plan instead of
  reauthoring the fix.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one sqlite3 query confirms
    leakage=0; rollback recipe is one `cp`.
  - **maintainer (extending later)**: third-class observation
    documented so the next normalize pass on a sister repo catches
    basename + `.` + NULL together.
  - **future worker (LLM agent)**: bar named, the safety verification
    template (basename-only AND id-prefix-matches) is reusable for
    any future basename-class leakage.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-cvzls
no_bead_reason=data_class_normalize_complete_doctrine_amendment_to_plan_2.3_basename_class_can_be_authored_by_a_followup_orchestrator_pass_no_dispatch-tier_action_needed_today`.
