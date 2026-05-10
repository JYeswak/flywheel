# flywheel-ovd29 Evidence — worker_capacity_gate_failed merged into integrate_worker_active + ERROR-state escalation gap

Task: `flywheel-ovd29-883643`
Bead: `flywheel-ovd29` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] worker_capacity_gate_failed (12 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — auto-filed by
`doctrine-ladder-promote.sh`; closes by Path A sibling-sub-class
merge into the existing `## integrate_worker_active` parent class
AND surfaces the ERROR-state-with-callback-available L95
escalation gap as `flywheel-xp50r`.

## Headline outcome

**Shipped a layer-2 INCIDENTS sub-class merge that closes the L56
ladder gap for `worker_capacity_gate_failed` (third synonym in
the integrate_worker_active family) AND surfaced the
integrate-prelude N-strikes-then-escalate caller-side wiring gap
as `flywheel-xp50r`** so the parent class's L91/L95 worker-stall
recovery path actually fires after pane goes to ERROR with
callback already delivered. Future workers facing
`worker_capacity_gate_failed` events route through the parent
class's wait/observe contract; ERROR-state recurrences after N
cycles route through `flywheel-xp50r`'s L95 escalation work.

## Why this is the third synonym in the family

| Class name | Events | Fleet | Date range | Disposition |
|---|---|---|---|---|
| `integrate_worker_active` (parent) | 3 | mobile-eats:0.1 | 2026-05-04 02:56-03:16Z | NEW INCIDENTS section, 2026-05-08 |
| `integrate_worker_not_waiting` (sibling sub-class A) | 4 | mobile-eats:0.1 | 2026-05-03 21:42-22:13Z | Sibling Sub-Class merge, 2026-05-09 (flywheel-6grpt) |
| **`worker_capacity_gate_failed`** (sibling sub-class B, this bead) | **12** | **mobile-eats:0.1** | **2026-05-03 19:11-20:07Z** | **Sibling Sub-Class merge + escalation gap follow-up, 2026-05-09 (flywheel-ovd29)** |

All three are mobile-eats:0.1, all three are "INTEGRATE prelude
refuses safely on non-WAITING pane" family. The
`worker_capacity_gate_failed` events PRE-DATE both the parent and
the first sibling sub-class. Three different code paths emitting
three names for the same trauma family.

## Two sub-shapes within this sub-class

| Sub-shape | Count | Pane state | Severity | Time range | Disposition |
|---|---|---|---|---|---|
| A — pane THINKING | 6 | active worker | low | 2026-05-03 19:11-19:36Z | Parent class behavior verbatim |
| B — pane ERROR after callback delivered | 6 | failed worker | medium | 2026-05-03 19:41-20:07Z | Parent's wait/observe applies for prelude-refusal; L95 stall escalation gap captured by `flywheel-xp50r` |

The first medium-severity row (2026-05-03T19:41:37Z) explicitly
notes: *"INTEGRATE tick aborted because pane 2 robot-activity was
ERROR, not WAITING, **despite mobile-eats-o73 callback being
available**."* The work was DONE, the callback was DELIVERED, but
pane 2 went to ERROR and the INTEGRATE gate kept correctly
refusing for 6 cycles (~30 minutes) without invoking the
canonical L95 worker-stall recovery ladder. That's a CALLER-SIDE
gap: integrate-prelude lacks N-strikes-then-escalate.

## Why Path A (Sibling Sub-Class merge), not Path B

| Path | Choice | Why |
|---|---|---|
| **Path A (Sibling Sub-Class merge into `integrate_worker_active`)** | line 6058 sub-class block | Same family ("tick prelude refuses safely on non-WAITING pane"), same fleet, third synonym already accumulated in the same section. Path A keeps the unified narrative and surfaces the ERROR-state escalation gap as a separate follow-up (`flywheel-xp50r`). |
| Path B (standalone NEW `## worker_capacity_gate_failed`) | reject | Would orphan the third synonym from the same parent's two existing sub-classes. Pane 2 just landed `## worker_capacity_gate_false_block` as a separate L90 cross-reference because that class's 5 events (2026-05-03T20:10-21:17Z, adjacent timeline) had a different canonical surface. Mine has the same surface as the parent (L91/L95). |
| Path C (L-rule cross-reference) | reject | No new L-rule needed; AGENTS.md L91/L95 (cited by parent) ARE the canonical surfaces. The L95 escalation wiring gap is a CALLER-SIDE bug (probe doesn't invoke L95), not a doctrine gap. |

## What changed

### `INCIDENTS.md` (line 6058)

Inserted `### Sibling Sub-Class: worker_capacity_gate_failed (synonym + ERROR-state escalation gap — 2026-05-09 merge)` inside the existing `## integrate_worker_active` section (after the prior 2026-05-09 sibling sub-class for `integrate_worker_not_waiting`, before the next top-level section `## worker-evidence-file-write-before-reservation`). Block names:
- The third synonym in the family.
- Two sub-shapes (THINKING canonical + ERROR escalation gap).
- The 12 fuckup-log rows split by sub-shape.
- The L95 caller-side escalation gap as a follow-up bead (`flywheel-xp50r`).
- Cross-link to the synonym-unification follow-up `flywheel-pjfqw` already filed by flywheel-6grpt.

INCIDENTS.md grew 8186 → 8268 lines (+82 lines).

### `flywheel-xp50r` (new follow-up bead, P3)

Title: `[worker-stall-recovery] integrate-side detection of pane=ERROR-after-callback should escalate via L95`. Names the integrate-prelude N-strikes-then-escalate gap (after N=3 consecutive trauma emissions on the same pane, invoke L95 worker-stall recovery instead of re-firing the same fuckup-log row).

## L107 reservation timeline (notable for this close)

| ts | event |
|---|---|
| 2026-05-09T20:39:16Z | Pane 2 (task `flywheel-q1y1d-e26679`) reserved INCIDENTS.md |
| 2026-05-09T20:39:36Z | Pane 4 (this dispatch) attempted reserve → BLOCKED |
| 2026-05-09T20:40:27Z | Wait 2min (per established 8nrza canonical pattern) |
| 2026-05-09T20:42:36Z | Retry → still BLOCKED; pane 2 actively committing (833dfc1, 8e258fe) |
| 2026-05-09T20:44:10Z | Wait 3min more |
| 2026-05-09T20:48:11Z | Retry → still BLOCKED; pane 2 hung on DCG `git stash drop` warn dialog awaiting Joshua |
| 2026-05-09T20:48:11Z | Wait 3min more (final cycle before BLOCKED disposition) |
| 2026-05-09T20:51:53Z | Pane 2 committed `1198f1b incidents(dfs9y): cross-reference worker_capacity_gate_false_block to L90` — close-cousin class |
| 2026-05-09T20:52:00Z+ | Retry → ACQUIRED. Resumed. |

Total wait: ~12 minutes across 3 retry cycles + 3 commits by holder. Patch was drafted in WORK_TMP during the wait per 8nrza canonical pattern.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | INCIDENTS.md gains sub-class block at line 6058; this audit pack carries timeline + disposition |
| AG2 — targeted validator passes and named | DID | `bash .flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status=pass`, `incidents_evidence_missing_count=0`, `entries_checked=121` |
| AG3 — `br show flywheel-ovd29` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=flywheel-xp50r.

## Verification commands (re-runnable)

```bash
# Sub-class block landed inside parent section
grep -n "^### Sibling Sub-Class: worker_capacity_gate_failed" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 6058

# Parent section still present
grep -n "^## integrate_worker_active" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 5945

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq '{status, incidents_evidence_missing_count, entries_checked}'
# expected: status=pass, missing=0, entries_checked >= 121

# Follow-up bead filed
br show flywheel-xp50r | head -3
# expected: ○ flywheel-xp50r · [worker-stall-recovery] integrate-side detection of pane=ERROR-after-callback should escalate via L95

# 12 trauma rows still in fuckup-log (precedent intact)
grep -c worker_capacity_gate_failed /Users/josh/.local/state/flywheel/fuckup-log.jsonl
# expected: 12

# Sub-shape split (6 low + 6 medium)
grep worker_capacity_gate_failed /Users/josh/.local/state/flywheel/fuckup-log.jsonl \
  | jq -r .severity | sort | uniq -c
# expected: 6 low, 6 medium
```

## L112 probe (worker callback)

```bash
grep -q "^### Sibling Sub-Class: worker_capacity_gate_failed" /Users/josh/Developer/flywheel/INCIDENTS.md \
  && bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
       | jq -e '.status == "pass"' >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No new top-level INCIDENTS section.** Path A merge into
  existing parent class.
- **No integrate-prelude probe edit.** L95 escalation wiring is
  `flywheel-xp50r`'s scope.
- **No L-rule numbered.** AGENTS.md L91/L95 (cited by parent) ARE
  the canonical surfaces.
- **No fuckup-log retroactive edit.** The 12 historical rows
  remain as precedent evidence.
- **No reopen of parent class bead `flywheel-2ljj`.** Closed
  beads stay closed.
- **No edit to pane 2's adjacent commit.** `1198f1b` lands
  `worker_capacity_gate_false_block` as L90 cross-reference;
  that's a sibling but distinct class with a different canonical
  surface (L90 vs L91/L95).
- **No reservation breakage.** Held 12-min wait via established
  8nrza canonical pattern (draft in WORK_TMP, retry after release).

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — INCIDENTS doctrine, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — INCIDENTS gained a sub-class block;
  AGENTS.md numbered L-rules (L91/L95) are unchanged.
- `readme_updated=not_applicable`.
- `no_touch_reason=path_a_sibling_sub-class_merge_into_existing_integrate_worker_active_parent_class_no_doctrine_surface_mutated_no_l-rule_numbered_l95_caller_side_escalation_gap_routed_to_flywheel-xp50r_followup`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim; Path A disposition
  preserves the unified narrative across three synonyms in the
  family; the ERROR-state escalation gap is named as a real
  caller-side bug with concrete N-strikes-then-escalate
  prescription.
- **Sniff: 9** — outcome-shaped headline ("shipped layer-2
  INCIDENTS sub-class merge that closes the L56 ladder gap…
  surfaced the integrate-prelude N-strikes-then-escalate
  caller-side wiring gap as flywheel-xp50r so the parent class's
  L91/L95 worker-stall recovery path actually fires"); 12-event
  roster split by severity with concrete sub-shape disposition;
  L107 reservation timeline documented for the 12-min wait.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one sub-class block + one follow-up bead + one audit
  pack); refuses Path B duplication; refuses to break the L107
  reservation despite 12-min wait; refuses to fix the L95
  escalation in this close (that's flywheel-xp50r's scope);
  documents the 8nrza canonical wait pattern verbatim.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 5 verification commands
    confirm sub-class + parent + validator + follow-up bead +
    sub-shape split in <10s.
  - **maintainer (extending later)**: parent + sub-class
    structure now used 7+ times across today's INCIDENTS work;
    the integrate_worker_active section has accumulated three
    synonym sub-classes, demonstrating the canonical synonym-merge
    pattern works even at N>=3.
  - **future worker (LLM agent)**: facing ANY trauma in the
    integrate_worker_* family, the worker has (a) named class in
    INCIDENTS so the L56 ladder skips, (b) explicit canonical
    surfaces (AGENTS.md L91/L95), (c) two follow-up beads
    (flywheel-pjfqw for emitter unification, flywheel-xp50r for
    L95 caller-side wiring); the family's coverage is now
    deterministic.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-xp50r
beads_updated=flywheel-ovd29
no_bead_reason=none`.
