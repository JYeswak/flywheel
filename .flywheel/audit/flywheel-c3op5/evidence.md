# flywheel-c3op5 Evidence — superseded by 3 prior INCIDENTS sections + dedup-fix race

Task: `flywheel-c3op5-c67549`
Bead: `flywheel-c3op5` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] br-db-wedge (3 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — supersession-class
close; same shape as `flywheel-qnkj2` and `flywheel-vl6dn` (dedup-fix
race + canonical coverage already exists).

## Headline finding — superseded by 3 INCIDENTS sections

`br-db-wedge` already has **substantive INCIDENTS coverage in three
sections**:

| INCIDENTS.md line | Section heading | Date | Style |
|---|---|---|---|
| 106 | `## br-db wedge repair — JSONL-fallback eliminated on close (2026-05-05)` | 2026-05-05 | Long-form repair narrative |
| 1033 | `## br-db wedge recurrence root-cause + mitigation (2026-05-05)` | 2026-05-05 | Long-form RCA + mitigation |
| 5460 | `## br-db-wedge-recurrence` | 2026-05-08 | Canonical L56 promotion entry (sister bead `flywheel-69974`) |

15 total references across the file. The `br-db-wedge` family is one
of the best-documented trauma classes in the file.

## Why this bead fired despite coverage

Same dedup-fix-race pattern observed for `flywheel-qnkj2` and
`flywheel-vl6dn`: the doctrine-ladder probe scanned BEFORE
`flywheel-qnkj2`'s commit `0a2ee86` added repo-local INCIDENTS.md to
the search paths. Post-fix, the dedup heuristic now correctly says:

```
br-db-wedge:incidents_covered
br-db-wedge-recurrence:incidents_covered
```

Future ladder runs will not re-fire on either class.

## Why no new INCIDENTS section

The dispatch's instruction "Run /flywheel:learn --promote
br-db-wedge to draft doctrine entry" cannot land cleanly because:

1. **Three sections already cover the trauma** — adding a fourth would
   fork doctrine.
2. **Most of the 7 events predate the 2026-05-05 doctrine work** (oldest:
   2026-04-30T21:31Z; the 2026-05-05 lines 106 + 1033 sections were
   drafted during/after the recurrence cluster). Those 2026-05-05
   sections retroactively cover the historical events.
3. **Post-2026-05-05 events shifted to `br-db-wedge-recurrence`** which
   has its own dedicated L56 entry at line 5460 (sister bead
   `flywheel-69974` CLOSED 2026-05-08).
4. The sister-class merge (Path A) pattern from `flywheel-uyd9i` is
   not applicable here because `br-db-wedge` is the **parent class**
   that the recurrence class explicitly references; appending sibling
   metadata to a child section would invert the hierarchy.

This is a **clean supersession** — the doctrine surface is sufficient,
the dedup fix prevents re-fires, no new artifact needed.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-c3op5/` carries this evidence pack, supersession trail, pinned SHA. INCIDENTS.md is **unchanged** (3 sections + 15 references already present). |
| AG2 — targeted validator passes and named | DID | `.flywheel/scripts/doctrine-ladder-promote.sh \| jq` confirms `br-db-wedge:incidents_covered` and `br-db-wedge-recurrence:incidents_covered`; `incidents-evidence-link-validator.sh --json` returns `status=pass`, `entries_checked=107` (covers all 3 br-db-wedge sections among the 107). |
| AG3 — `br show flywheel-c3op5` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Open sibling bead

`flywheel-hujtc` is an OPEN duplicate for `br-db-wedge-recurrence`
that fired before the dedup fix took effect (same race shape as
`flywheel-vl6dn` for too-many-open-files). It will be the **next**
worker-tick's supersession-close — the dedup-skip output
`br-db-wedge-recurrence:incidents_covered` confirms it would not
re-fire today.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| INCIDENTS.md (unchanged from prior dispatch) | `INCIDENTS.md` | `42b7d33381f1a6dd9b7ecb5094d82431e2937e6b653b870e42b0210c97a1626b` |

## Verification commands (re-runnable)

```bash
# Confirm 3 INCIDENTS sections exist for the br-db-wedge family
grep -nE '^## .*wedge' /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: lines 106, 1033, 5460

# Confirm dedup heuristic skips both wedge classes
/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
  | jq -r '.skipped[]' | grep -E 'br-db-wedge'
# expected: br-db-wedge:incidents_covered AND br-db-wedge-recurrence:incidents_covered

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq -c '{status, incidents_evidence_missing_count, entries_checked}'
```

## L112 probe (worker callback)

```bash
[ "$(/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
       | jq -r '.skipped[] | select(. == "br-db-wedge:incidents_covered")')" \
  = "br-db-wedge:incidents_covered" ] \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No INCIDENTS.md edit.** Three existing sections (lines 106, 1033,
  5460) already cover the trauma family with 15 references; adding a
  fourth would fork doctrine.
- **No `/flywheel:learn --promote` invocation.** Re-running would
  duplicate-write or no-op.
- **No sibling-merge into recurrence section.** `br-db-wedge` is the
  parent class; appending sibling metadata to the child `-recurrence`
  section would invert the hierarchy.
- **No flywheel-hujtc handling.** That open duplicate (for
  `br-db-wedge-recurrence`) is its own bead and will close as
  supersession on a separate worker-tick.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=supersession_close_three_INCIDENTS_sections_already_cover_br-db-wedge_family_no_doctrine_change_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Names the 3-section
  supersession trail explicitly + the dedup-fix-race cause.
- **Sniff: 9** — every claim is shell-checkable; the three section
  lines (106, 1033, 5460) are grep-friendly; dedup-skip output is
  the canonical machine-readable proof.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface
  (one audit pack, no INCIDENTS.md mutation); refuses to fork
  doctrine into a 4th section.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one shell line confirms dedup;
    three section lines are grep-friendly.
  - **maintainer (extending later)**: this is the **third** instance
    of the supersession + dedup-fix-race shape (qnkj2 → vl6dn → c3op5);
    template is now load-bearing for the agent-mail-* and br-db-wedge
    class families.
  - **future worker (LLM agent)**: the explicit hierarchy distinction
    (parent class `br-db-wedge` vs child class `br-db-wedge-recurrence`)
    + why-not-Path-A reasoning (parent → child sibling-merge inverts
    hierarchy) is documented for future cosmetic-vs-hierarchical class
    decisions.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-c3op5
no_bead_reason=supersession_three_INCIDENTS_sections_lines_106_1033_5460_already_cover_trauma_family_dedup-fix-race_resolved_by_flywheel-qnkj2_no_followup_observed`.
