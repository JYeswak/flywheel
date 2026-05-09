# flywheel-i2k6v Evidence — research-health-prelude-fail merged into integrate-prelude-blocked + diagnostic-opacity follow-up

Task: `flywheel-i2k6v-6921e1`
Bead: `flywheel-i2k6v` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] research-health-prelude-fail (4 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — auto-filed by
`doctrine-ladder-promote.sh`; closes by Path A sibling-sub-class
merge into the existing `## integrate-prelude-blocked` parent
class AND surfaces the substrate diagnostic-opacity bug as
`flywheel-q53pp` so the parent's "route to owner" Forever-Rule
remains executable.

## Headline outcome

**Shipped a layer-2 INCIDENTS sub-class merge that closes the L56
ladder gap for the RESEARCH-tick variant of the safe-refusal
pattern, AND surfaced the underlying probe-quality bug (doctor
emitting `status=fail` with empty errors/warnings) as
`flywheel-q53pp`** so the parent class's "route each blocker to
its owner" Forever-Rule remains executable. Future RESEARCH-tick
preludes that abort on doctor failure now route through the
parent section's wait/observe contract; the 4-row precedent
cluster on 2026-05-02 stops re-firing as an unprocessed
promotion candidate.

## Why Path A (Sibling Sub-Class merge into `integrate-prelude-blocked`), not Path B / C

| Path | Choice | Why |
|---|---|---|
| **Path A (Sibling Sub-Class merge into `integrate-prelude-blocked`)** | line 6813 sub-class block | Same family ("tick prelude refuses safely on doctor failure"), same fleet (`mobile-eats:0.1`), same shape (severity=medium, `what_attempted=[]`). RESEARCH is a different tick than INTEGRATE but the safe-refusal Forever-Rule is identical. Path A preserves the unified narrative and surfaces the diagnostic-opacity divergence as a sub-class caveat instead of duplicating the parent's framing. |
| Path B (standalone NEW `## research-health-prelude-fail`) | reject | Would duplicate the parent's "tick prelude is safe refusal" framing for what is structurally the same pattern in a different tick. The 4-event count is sub-class magnitude. |
| Path C (L-rule cross-reference) | reject | No canonical L-rule numbered for this class; canonical doctrine surfaces (AGENTS.md L91/L95) are already cited by the parent. |
| Path D (rename parent to a tick-agnostic super-name) | reject | Would invalidate the parent's existing references (`flywheel-ozha`, fuckup-log L419-L433 prose) for no operational gain. Sub-class block is lower-cost. |

## What changed

### `INCIDENTS.md` (line 6813)

Inserted `### Sibling Sub-Class: research-health-prelude-fail (RESEARCH variant + diagnostic-opacity caveat — 2026-05-09 merge)` inside the existing `## integrate-prelude-blocked` section (after the parent's `Sibling Classes` block, before the next top-level section `## dispatch-health-and-capacity-gate`). Block names:
- The RESEARCH variant of the parent's INTEGRATE pattern.
- The 4 fuckup-log rows (lines 208, 209, 212, 213 on 2026-05-02).
- The substrate diagnostic-opacity bug as a sub-class CAVEAT (extends the parent's Forever-Rule with the empty-errors special case).
- The substrate-fix follow-up bead `flywheel-q53pp`.

INCIDENTS.md grew 7843 → 7901 lines (+58 lines).

### `flywheel-q53pp` (new follow-up bead, P3)

Title: `[probe-quality] flywheel-loop doctor status=fail with empty errors/warnings — diagnostically opaque`. Names the doctor-emit substrate bug: when `status=fail`, the doctor MUST populate at least one diagnostic field (`errors[]`, `warnings[]`, or fallback `reason=`). Lists 3 candidate root-cause hypotheses + a regression-test gate.

## The 4 events (all 2026-05-02, all mobile-eats:0.1, all codex agent)

| ts (UTC) | what_happened (verbatim) |
|---|---|
| 22:07:24 | "RESEARCH tick aborted: flywheel-loop doctor returned status=fail with empty errors/warnings and ntm health reported mobile-eats pane 1/0 ERROR." |
| 22:17:07 | "RESEARCH tick 20260502T221629Z aborted: flywheel-loop doctor status=fail with empty errors/warnings and ntm health reported mobile-eats panes 0/1 ERROR while pane 2 OK." |
| 22:57:09 | "mobile-eats RESEARCH tick 20260502T225638Z aborted: flywheel-loop doctor status=fail with empty errors/warnings and ntm health reports panes 0/1 ERROR while pane 2 OK" |
| 23:07:32 | "mobile-eats RESEARCH tick 20260502T230640Z aborted: flywheel-loop doctor status=fail with empty errors/warnings and ntm health reports panes 0/1 ERROR while pane 2 OK" |

All `severity=medium`, `what_attempted=[]`, `what_worked=[]`,
`agent=codex`, `commit_sha=60bf303`. Notably:
- **Operationally safe**: tick correctly aborted (matches parent
  class Forever-Rule).
- **Diagnostically opaque**: `errors=[]`, `warnings=[]` — nothing
  to route. This is the substrate bug.
- **ntm health pane fingerprint**: panes 0/1 ERROR, pane 2 OK
  (consistent across all 4 rows; suggests a real fleet pane state
  the doctor failed to enumerate).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | INCIDENTS.md gains sub-class block at line 6813; `.flywheel/audit/flywheel-i2k6v/` carries this evidence pack |
| AG2 — targeted validator passes and named | DID | `bash .flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status=pass`, `incidents_evidence_missing_count=0`, `entries_checked=118` |
| AG3 — `br show flywheel-i2k6v` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=flywheel-q53pp.

## Verification commands (re-runnable)

```bash
# Sub-class block landed inside parent section
grep -n "^### Sibling Sub-Class: research-health-prelude-fail" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 6813

# Parent section still present
grep -n "^## integrate-prelude-blocked" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 6735

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq '{status, incidents_evidence_missing_count, entries_checked}'
# expected: status=pass, missing=0, entries_checked >= 118

# Substrate-fix follow-up bead filed
br show flywheel-q53pp | head -3
# expected: ○ flywheel-q53pp · [probe-quality] flywheel-loop doctor status=fail with empty errors/warnings

# 4 trauma rows still in fuckup-log (precedent intact)
grep -c research-health-prelude-fail /Users/josh/.local/state/flywheel/fuckup-log.jsonl
# expected: 4
```

## L112 probe (worker callback)

```bash
grep -q "^### Sibling Sub-Class: research-health-prelude-fail" /Users/josh/Developer/flywheel/INCIDENTS.md \
  && bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
       | jq -e '.status == "pass"' >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No new top-level INCIDENTS section.** Path A merge into
  existing parent class.
- **No doctor edit.** That's `flywheel-q53pp`'s scope; this bead
  surfaces it but does NOT execute the substrate fix.
- **No fuckup-log retroactive edit.** The 4 historical rows
  remain as precedent evidence.
- **No L-rule numbered.** AGENTS.md L91/L95 (cited by parent) ARE
  the canonical surfaces.
- **No reopen of parent class bead `flywheel-ozha`.** Closed
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
- `no_touch_reason=path_a_sibling_sub-class_merge_into_existing_integrate-prelude-blocked_parent_class_no_doctrine_surface_mutated_no_l-rule_numbered_substrate_diagnostic-opacity_bug_routed_to_flywheel-q53pp_followup`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim; Path A disposition
  preserves the unified narrative with the parent class while
  surfacing the diagnostic-opacity caveat (a substrate divergence
  that the parent's Forever-Rule cannot route on its own).
- **Sniff: 9** — outcome-shaped headline ("shipped layer-2
  INCIDENTS sub-class merge that closes the L56 ladder gap…
  surfaced the underlying probe-quality bug as flywheel-q53pp so
  the parent class's 'route each blocker to its owner'
  Forever-Rule remains executable"); 4-event roster is concrete
  data with timestamps + verbatim what_happened phrasing; the
  diagnostic-opacity caveat is a real divergence, not a
  speculative concern.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one sub-class block + one follow-up bead + one audit
  pack); refuses Path B duplication; refuses to fix the
  substrate bug in this close (that's flywheel-q53pp's scope);
  refuses to retroactively edit the historical fuckup-log rows
  even though the diagnostic was empty.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 5 verification commands
    confirm sub-class + parent + validator + follow-up bead +
    precedent rows in <10s.
  - **maintainer (extending later)**: parent + sub-class
    structure now used 6+ times across today's INCIDENTS work
    (qqv5r, uyd9i, sniff-lens-status-without-outcome cross-link,
    dcg-worktree-remove-block, integrate_worker_not_waiting,
    this); pattern is canonical for "promotion candidate that's
    a tick-variant or shape-variant of an existing parent".
  - **future worker (LLM agent)**: facing a tick-prelude doctor
    failure on RESEARCH/INTEGRATE/any other tick, the worker
    has (a) named class in INCIDENTS so the L56 ladder skips,
    (b) explicit canonical surfaces (AGENTS.md L91/L95 +
    flywheel-q53pp probe-quality follow-up), (c) the
    diagnostic-opacity caveat as a hint that empty errors/warnings
    is a probe-bug class, not a routable doctor class.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-q53pp
beads_updated=flywheel-i2k6v
no_bead_reason=none`.
