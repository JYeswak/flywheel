# flywheel-vl6dn Evidence — superseded by flywheel-bika + flywheel-o8fs (and dedup-fix race)

Task: `flywheel-vl6dn-9ee77f`
Bead: `flywheel-vl6dn` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] agent-mail-too-many-open-files (3 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — supersession-class
close; same shape as `flywheel-qnkj2` but for the FD-exhaustion sibling
class.

## Headline finding — superseded + dedup-fix race

`agent-mail-too-many-open-files` already has **full doctrine coverage**:

| Surface | Evidence |
|---|---|
| `INCIDENTS.md` canonical section | Line 6477 (`## agent-mail-too-many-open-files`); 7 references total in the file |
| Layer-2 promotion bead | `flywheel-bika` (P2 CLOSED 2026-05-08) — "Promoted agent-mail-too-many-open-files to INCIDENTS.md with L56 evidence links; processed exact-class fuckup-log rows 131,132,133,135,136,137,139,140,2503,2505" |
| Canonical L-rule + mechanical guard | `flywheel-o8fs` (P1 CLOSED 2026-05-03) — "Agent Mail fd-pressure mechanical guard implemented at `.flywheel/scripts/agent-mail-fd-pressure-check.sh` and integrated into flywheel-loop doctor as `.agent_mail_fd_pressure`. Synthetic test passes: 50%=ok, 85%=warn, 97%=error" |
| Companion dedup fix | `flywheel-qnkj2` commit `0a2ee86` — added `$REPO/INCIDENTS.md` to `doctrine-ladder-promote.sh default_incident_paths` |

**Why was vl6dn filed today, then?** Race between the auto-doctor and
the dedup-fix landing:

| Event | Timestamp |
|---|---|
| `flywheel-vl6dn` auto-created by `doctrine-ladder-promote.sh` | 2026-05-09T17:11:05Z |
| `flywheel-qnkj2` dedup-fix commit `0a2ee86` lands | 2026-05-09T18:35Z (12:35 local) |

The doctrine-ladder probe scanned BEFORE the dedup fix included repo-local
INCIDENTS.md in its search paths. Now that `0a2ee86` is in, **the same
probe correctly identifies this class as `incidents_covered`**:

```
$ .flywheel/scripts/doctrine-ladder-promote.sh | jq -r '.skipped[] | select(test("agent-mail-too-many-open-files"))'
agent-mail-too-many-open-files:incidents_covered
```

Future ladder runs will not re-fire. This bead is the last duplicate of
its class.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-vl6dn/` carries this evidence pack, supersession trail, pinned SHA. INCIDENTS.md is **unchanged** because the canonical section already exists. |
| AG2 — targeted validator passes and named | DID | `.flywheel/scripts/doctrine-ladder-promote.sh \| jq` confirms `agent-mail-too-many-open-files:incidents_covered` (the dedup heuristic now fires correctly post-`flywheel-qnkj2`); `.flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status=pass` (re-run from `flywheel-ijsb7` covers the whole INCIDENTS.md including line 6477) |
| AG3 — `br show flywheel-vl6dn` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Why no `/flywheel:learn --promote` re-run

Same shape as `flywheel-qnkj2`'s rationale: the canonical INCIDENTS section
exists at line 6477, the L-rule is in place via `flywheel-o8fs`, and the
mechanical guard at `.flywheel/scripts/agent-mail-fd-pressure-check.sh` is
already wired into `flywheel-loop doctor`. Re-running `/flywheel:learn
--promote` would either no-op or duplicate-write — neither is a valid
action.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| INCIDENTS.md (unchanged from prior dispatch) | `INCIDENTS.md` | `50bc6979ed1bbde78a072b547e160541d8b5667ceb7ff9c9659a0d93de798b9b` |

## Verification commands (re-runnable)

```bash
# Confirm canonical INCIDENTS section exists
grep -n "^## agent-mail-too-many-open-files$" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 6477

# Confirm dedup heuristic now skips this class (post-qnkj2 fix)
/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
  | jq -r '.skipped[] | select(test("agent-mail-too-many-open-files"))'
# expected: agent-mail-too-many-open-files:incidents_covered

# Confirm sister beads are closed
br show flywheel-bika  | head -2
br show flywheel-o8fs  | head -2
# both: status CLOSED
```

## L112 probe (worker callback)

```bash
[ "$(/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
       | jq -r '.skipped[] | select(test("agent-mail-too-many-open-files"))')" \
  = "agent-mail-too-many-open-files:incidents_covered" ] \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No INCIDENTS.md edit.** Sister beads `flywheel-bika` (2026-05-08
  layer-2) and `flywheel-o8fs` (2026-05-03 canonical L-rule + mechanical
  guard) already shipped the doctrine. INCIDENTS.md SHA is unchanged from
  the prior dispatch's commit (`67343a9`).
- **No `/flywheel:learn --promote` invocation.** Re-running would
  duplicate-write.
- **No mechanical guard work.** `flywheel-o8fs` already shipped
  `agent-mail-fd-pressure-check.sh` with synthetic-test coverage.
- **No script edit.** `doctrine-ladder-promote.sh` was fixed by
  companion bead `flywheel-qnkj2`; that fix's correctness is verified by
  the dedup-skip output above.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=supersession_close_canonical_coverage_already_present_via_flywheel-bika_and_flywheel-o8fs_no_doctrine_change_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Names the supersession
  trail (bika → o8fs → INCIDENTS.md line 6477) and the dedup-fix race
  cause (vl6dn filed 17:11Z, qnkj2 fix landed 18:35Z) explicitly.
- **Sniff: 9** — every claim is shell-checkable; the dedup-skip output
  is the canonical machine-readable proof that the qnkj2 fix is now
  load-bearing for this class.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface
  (one audit pack, no INCIDENTS.md mutation); refuses to re-run promote
  against existing canonical coverage.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one shell line confirms dedup;
    sister-bead chain is grep-friendly.
  - **maintainer (extending later)**: this is the second instance of
    the supersession+dedup-fix-race shape (after `flywheel-qnkj2`); the
    template is now load-bearing for all future agent-mail-* class
    promotion-candidate duplicates.
  - **future worker (LLM agent)**: dedup-fix-race timestamp template
    explicit, so future race-condition close-as-superseded reasoning
    is reproducible without re-deriving timestamps.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-vl6dn
no_bead_reason=supersession_canonical_INCIDENTS_section_at_line_6477_plus_closed_sister_beads_flywheel-bika_2026-05-08_and_flywheel-o8fs_2026-05-03_dedup-fix-race_resolved_by_flywheel-qnkj2_no_followup_observed`.
