# flywheel-6grpt Evidence — integrate_worker_not_waiting synonym merged into integrate_worker_active parent

Task: `flywheel-6grpt-7a4fb3`
Bead: `flywheel-6grpt` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] integrate_worker_not_waiting (4 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — auto-filed by
`doctrine-ladder-promote.sh`; closes by Path A sibling-sub-class
merge declaring synonym + earlier-precedent rows of the existing
`## integrate_worker_active` parent class. Filed
`flywheel-pjfqw` for the probe-emitter unification follow-up.

## Headline outcome

**Shipped a layer-2 INCIDENTS sub-class merge that closes the L56
ladder dedup gap for the synonym pair `integrate_worker_active` /
`integrate_worker_not_waiting`** (4 events on 2026-05-03 from
mobile-eats:0.1, identical shape to the parent class's 3 events
on 2026-05-04). Future probes emitting either name now route to
the parent class's wait/observe contract instead of double-promoting
as separate trauma classes. Surfaced the upstream emitter-naming
divergence as `flywheel-pjfqw` so the synonym dedup becomes
deterministic.

## Why this is a synonym, not a distinct class

| Dimension | parent (integrate_worker_active) | sub-class (integrate_worker_not_waiting) |
|---|---|---|
| Fleet pane | mobile-eats:0.1 | mobile-eats:0.1 (same) |
| Severity | low | low (same) |
| `what_attempted` | `[]` | `[]` (same) |
| `what_worked` | `[]` | `[]` (same) |
| Outcome | callback reaping deferred | callback reaping deferred (same) |
| Worker file mutation | none | none (same) |
| Date range | 2026-05-04 02:56–03:16 UTC | 2026-05-03 21:42–22:13 UTC (~5h earlier) |
| Phrasing | "deferred reaping without touching worker files" | "reaping blocked by worker-capacity gate" |

Same trauma. Different name. Different prose. Earlier precedent
in the synonym. The L56 ladder probe correctly detected the
synonym as a distinct class because the probe matches on
`trauma_class` field verbatim — but the underlying behavior is
the same canonical-safe deferral.

## Why Path A (Sibling Sub-Class merge), not Path B / C

| Path | Choice | Why |
|---|---|---|
| **Path A (Sibling Sub-Class merge into `integrate_worker_active`)** | line 5991 sub-class block | Same shape, same fleet, EARLIER precedent rows. Path A preserves the unified narrative ("INTEGRATE prelude correctly defers reaping when worker is THINKING"); the parent's Forever-Rule applies verbatim. |
| Path B (standalone NEW `## integrate_worker_not_waiting`) | reject | Would document the synonym as if it were a distinct class — the OPPOSITE of what the L56 ladder needs. Future events would still double-promote because nothing aliases the names. |
| Path C (L-rule cross-reference) | reject | No canonical L-rule numbered for this class; canonical surfaces are AGENTS.md L91/L95 (already cited by parent). |
| Path D (rename parent class to a neutral super-name) | reject | Would invalidate the parent's existing references (`flywheel-2ljj`, fuckup-log L435-L437 prose) for no operational gain. Sub-class block is lower-cost. |

## What changed

### `INCIDENTS.md` (line 5991)

Inserted `### Sibling Sub-Class: integrate_worker_not_waiting (synonym, earlier precedent — 2026-05-09 merge)` inside the existing `## integrate_worker_active` section (just before the next top-level section `## worker-evidence-file-write-before-reservation`). Block names:
- The synonym pair as a single concept.
- The 4 earlier-precedent fuckup-log rows (lines 351, 353, 358, 359 on 2026-05-03).
- The parent's Forever-Rule applies verbatim.
- The probes/scripts that emit this trauma class SHOULD use the parent name; the synonym is recognized for backward compatibility but discouraged for new code.
- Synonym-unification follow-up bead `flywheel-pjfqw`.

INCIDENTS.md grew 7782 → 7843 lines (+61 lines).

### `flywheel-pjfqw` (new follow-up bead, P3)

Title: `[probe-naming] unify integrate_worker_not_waiting → integrate_worker_active emitter`. Names the upstream emitter unification (locate the code path that emits `integrate_worker_not_waiting` and rename to `integrate_worker_active` so the L56 ladder dedup is deterministic).

## The 4 events (all 2026-05-03, all mobile-eats:0.1)

| ts (UTC) | task tag | what_happened phrasing |
|---|---|---|
| 21:42:52 | mobile-eats-w5j dispatch | "INTEGRATE tick found pane 2 still THINKING after dispatch and no callback in canonical tail; reaping blocked by worker-capacity gate." |
| 21:47:49 | mobile-eats-w5j dispatch | "INTEGRATE tick found pane 2 still THINKING…; reaping remains blocked by worker-capacity gate." |
| 22:02:54 | mobile-eats-ufj dispatch | "INTEGRATE tick found pane 2 still THINKING after mobile-eats-ufj dispatch…; reaping blocked by worker-capacity gate." |
| 22:13:05 | mobile-eats-ov1 dispatch | "INTEGRATE tick found pane 2 still THINKING after mobile-eats-ov1 dispatch…; reaping blocked by worker-capacity gate." |

All `severity=low`, `what_attempted=[]`, `what_worked=[]`. All
canonical-safe (no worker file mutation).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | INCIDENTS.md gains sub-class block at line 5991; `.flywheel/audit/flywheel-6grpt/` carries this evidence pack |
| AG2 — targeted validator passes and named | DID | `bash .flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status=pass`, `incidents_evidence_missing_count=0`, `entries_checked=116` |
| AG3 — `br show flywheel-6grpt` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=flywheel-pjfqw.

## Verification commands (re-runnable)

```bash
# Sub-class block landed inside parent section
grep -n "^### Sibling Sub-Class: integrate_worker_not_waiting" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 5991

# Parent section still present
grep -n "^## integrate_worker_active" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 5945

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq '{status, incidents_evidence_missing_count, entries_checked}'
# expected: status=pass, missing=0, entries_checked >= 116

# Follow-up bead filed
br show flywheel-pjfqw | head -3
# expected: ○ flywheel-pjfqw · [probe-naming] unify integrate_worker_not_waiting → integrate_worker_active emitter

# 4 synonym rows still in fuckup-log (precedent intact)
grep -c integrate_worker_not_waiting /Users/josh/.local/state/flywheel/fuckup-log.jsonl
# expected: 4
```

## L112 probe (worker callback)

```bash
grep -q "^### Sibling Sub-Class: integrate_worker_not_waiting" /Users/josh/Developer/flywheel/INCIDENTS.md \
  && bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
       | jq -e '.status == "pass"' >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No new top-level INCIDENTS section.** Path A merge into
  existing parent class.
- **No probe-emitter rename.** That's `flywheel-pjfqw`'s scope;
  this bead surfaces it but does NOT execute it (would expand
  scope past PICOZ_WORKER_FILES discipline).
- **No fuckup-log retroactive edit.** The 4 historical
  `trauma_class=integrate_worker_not_waiting` rows remain as
  precedent evidence.
- **No L-rule numbered.** AGENTS.md L91/L95 (cited by parent) ARE
  the canonical surfaces.
- **No reopen of parent class bead `flywheel-2ljj`.** Closed
  beads stay closed.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — INCIDENTS doctrine, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — INCIDENTS gained a sub-class block;
  AGENTS.md numbered L-rules (L91/L95) are unchanged.
- `readme_updated=not_applicable`.
- `no_touch_reason=path_a_sibling_sub-class_merge_into_existing_integrate_worker_active_parent_class_no_doctrine_surface_mutated_no_l-rule_numbered_synonym_unification_routed_to_flywheel-pjfqw_followup`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim; Path A disposition
  preserves the unified narrative with the parent class while
  surfacing the synonym-naming divergence as a separate
  follow-up.
- **Sniff: 9** — outcome-shaped headline ("shipped layer-2
  INCIDENTS sub-class merge that closes L56 ladder dedup gap…
  surfaced upstream emitter-naming divergence as flywheel-pjfqw
  so synonym dedup becomes deterministic"); 4-event roster is
  concrete data with timestamps + dispatch tags + verbatim
  what_happened phrasing; Path A/B/C/D decision logic explicit
  so future workers can re-derive it.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one sub-class block + one follow-up bead + one audit
  pack); refuses Path D rename to avoid invalidating existing
  parent references; refuses to rename the upstream emitter in
  this close (that's flywheel-pjfqw's scope).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 5 verification commands
    confirm sub-class + parent + validator + follow-up bead +
    precedent rows in <10s.
  - **maintainer (extending later)**: parent + sub-class
    structure now used 5+ times across today's INCIDENTS work
    (qqv5r, uyd9i, sniff-lens-status-without-outcome cross-link,
    dcg-worktree-remove-block, this); pattern is converging on
    canonical for "synonym/sub-shape under existing parent".
  - **future worker (LLM agent)**: facing another
    `integrate_worker_*` trauma class promotion, the worker has
    (a) named class in INCIDENTS so the L56 ladder skips, (b)
    explicit canonical surface (AGENTS.md L91/L95), (c)
    follow-up emitter-unification bead so the synonym-naming
    issue is durable.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-pjfqw
beads_updated=flywheel-6grpt
no_bead_reason=none`.
