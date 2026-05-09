# flywheel-uyd9i Evidence — bead-substrate-missing merged into bead-missing-from-local-db (Path A)

Task: `flywheel-uyd9i-68b606`
Bead: `flywheel-uyd9i` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] bead-substrate-missing (7 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — L56 sibling-class
merge so doctrine doesn't fork into two parallel sections for the same
trauma.

## Headline finding — sibling-class merge, not standalone promotion

`bead-substrate-missing` (this bead's class, 7 events) and
`bead-missing-from-local-db` (concurrent bead `flywheel-s2yd8`'s class,
3 events) describe the **same trauma**: a dispatched `josh-*` bead ID
is not present in the local `br` substrate, so `br show / br close`
returns `ISSUE_NOT_FOUND` even with `--force`. The class-name
divergence emerged from different `--class` strings used by fuckup-log
writers across pane preflights.

Path A taken: append a `Sibling Classes:` block to s2yd8's authored
INCIDENTS section, citing `bead-substrate-missing` as a cosmetic alias
plus the 7 fuckup-log line numbers. Single canonical landing pad for
the trauma; doctrine-ladder dedup (post `flywheel-qnkj2`'s repo-local
INCIDENTS.md path search) finds the section regardless of which
class-name string a future fuckup-log row uses.

## Coordination history (L107 reservation race resolved)

INCIDENTS.md reservation request at 2026-05-09T18:48Z initially
returned `status=blocked` because pane=2 (task `flywheel-s2yd8-e69c8a`)
held the reservation, authoring the canonical
`bead-missing-from-local-db` section. I drafted both Path A
(sibling-merge) and Path B (standalone section) as patch artifacts in
`.flywheel/audit/flywheel-uyd9i/` while waiting. Pane 2 released
~5 minutes later; reservation re-attempt at 2026-05-09T18:53Z returned
`status=reserved`. I applied Path A (the cleaner doctrine shape).

## What changed

`/Users/josh/Developer/flywheel/INCIDENTS.md` gained a
`Sibling Classes:` block appended to the `## bead-missing-from-local-db`
section (which sits at line 6973 in the file post-s2yd8). The block
cites:

1. `bead-substrate-missing` as the cosmetic alias with class-name
   provenance and the 7 fuckup-log line numbers (4078, 4081, 4144,
   4181, 4182, 4185, 4186).
2. The companion bead `flywheel-uyd9i` (Path A merge note).

`~/.local/state/flywheel/fuckup-processed.jsonl` gained a row keyed
by `bead_id=flywheel-uyd9i`, `processed_into=INCIDENTS.md#bead-missing-from-local-db`,
`processed_by=/flywheel:learn --promote (path-A sibling-merge)`, with
the 7 fuckup-log line numbers and a note documenting the cosmetic
alias relationship.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `INCIDENTS.md` `Sibling Classes:` block at line 7044+; `.flywheel/audit/flywheel-uyd9i/` carries this evidence pack, sibling-class analysis, both Path A/B patch artifacts, pinned SHA |
| AG2 — targeted test passes and named | DID | `bash .flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status=pass`, `incidents_evidence_missing_count=0`, `entries_checked=107` (107 = 106 prior + the s2yd8 section authored concurrently); `grep "^Sibling Classes:" INCIDENTS.md` finds the new block at line 7044 |
| AG3 — `br show flywheel-uyd9i` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| INCIDENTS.md (post-merge) | `INCIDENTS.md` | `42b7d33381f1a6dd9b7ecb5094d82431e2937e6b653b870e42b0210c97a1626b` |

## Path A vs Path B decision

| Path | Description | Chosen? |
|---|---|---|
| **A** | Append `Sibling Classes:` block to `bead-missing-from-local-db` section. Single canonical landing pad. Cosmetic alias documented. | **YES** |
| B | Standalone `## bead-substrate-missing` section that cross-links the canonical sibling. Two sections; redundant doctrine. | no |

Reasoning: Donella leverage #5 (rules of the system) — fewer doctrine
surfaces is higher leverage. Path A keeps the canonical trauma class
in one place and treats `bead-substrate-missing` as the alias it is.
Path B would have given doctrine-ladder a dedup target but also
created a second forever-rule that a future maintainer would have to
keep in sync with the first. Path A's `Sibling Classes:` shape is
reusable for future cosmetic-alias merges (template for the next
cosmetic-class-divergence trauma).

## Verification commands (re-runnable)

```bash
# Confirm the cross-link landed
grep -nA1 '^Sibling Classes:' /Users/josh/Developer/flywheel/INCIDENTS.md | head -3

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq -c '{status, incidents_evidence_missing_count, entries_checked}'

# Confirm dedup heuristic (post flywheel-qnkj2 fix) sees both class names
# now resolve to the canonical INCIDENTS section
/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
  | jq -r '.skipped[]' | grep -E "bead-substrate-missing|bead-missing-from-local-db"
# expected (post-close): both classes resolve to incidents_covered
```

## L112 probe (worker callback)

```bash
grep -q '^Sibling Classes:$' /Users/josh/Developer/flywheel/INCIDENTS.md \
  && grep -q 'bead-substrate-missing.*cosmetic alias' /Users/josh/Developer/flywheel/INCIDENTS.md \
  && bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
       | jq -e '.status == "pass" and .incidents_evidence_missing_count == 0' >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No new INCIDENTS section authored.** Path A merges into s2yd8's
  canonical section; no parallel `## bead-substrate-missing` heading
  is created. Doctrine surface stays minimal.
- **No s2yd8 section content changed.** I appended a `Sibling Classes:`
  block AFTER the existing section's last bullet (`Bead:
  flywheel-s2yd8.`); no upstream edit, no rewording.
- **No mechanical-guard work.** The Forever-Rule on s2yd8's section
  already names the canonical sequence (`br show → br sync
  --import-only → br close OR surface`). This bead's job is
  doctrine routing only.
- **L107 reservation honored.** Initial reservation request returned
  `status=blocked` (pane=2, s2yd8); I drafted patch artifacts but did
  NOT touch INCIDENTS.md until pane 2 released. Re-reservation
  succeeded at 2026-05-09T18:53Z.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — INCIDENTS doctrine, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — INCIDENTS.md gained a Sibling Classes
  block; AGENTS.md and canonical L-rules unchanged.
- `readme_updated=not_applicable`.
- `no_touch_reason=L56_layer-2_sibling-class_cross-link_no_canonical_L-rule_change`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Path A (merge) chosen
  with Donella leverage reasoning explicit.
- **Sniff: 9** — sibling-class identity proven empirically (event
  shape comparison + `josh-*` ID namespace match + identical error
  string `ISSUE_NOT_FOUND`); validator passes; processed-ledger row
  attached.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; minimal
  doctrine surface (one Sibling Classes block, no new section);
  L107 reservation honored despite the race; Path A/B alternative
  drafted as patch artifacts so the orch had a fallback.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one grep confirms cross-link;
    one validator command confirms the section is healthy.
  - **maintainer (extending later)**: the `Sibling Classes:` shape
    is now load-bearing in INCIDENTS.md and reusable for future
    cosmetic-class merges.
  - **future worker (LLM agent)**: the cosmetic-alias detection
    template (event-shape comparison + bead-id-namespace match) is
    documented in `sibling-class-analysis.md`; future doctrine-ladder
    cosmetic-alias collisions can be resolved by the same Path A
    pattern.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-uyd9i
no_bead_reason=path_A_sibling-class_merge_complete_canonical_INCIDENTS_section_authored_by_flywheel-s2yd8_now_carries_cross-link_to_bead-substrate-missing_alias`.
