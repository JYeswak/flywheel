# flywheel-8nrza Evidence — promote coordination-collision-detected to L56 layer-2

Task: `flywheel-8nrza-43046e`
Bead: `flywheel-8nrza` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] coordination-collision-detected (180 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — legitimate L56
promotion of the largest-volume cluster observed this session
(184 events). Recategorizes the trauma class from "failure" to
"healthy back-off signal" while documenting two concrete saturation
hotspots.

## Headline finding — high-volume legitimate promotion

| Surface | Count |
|---|---|
| `INCIDENTS.md` references pre-rework | 0 (no canonical section) |
| `fuckup-log.jsonl` events | 184 (bead headline said 180; current scan shows 184) |
| Open promotion-candidate bead | 1 (this bead) |
| Closed sister bead | 0 |

The cluster is the largest-volume L56 trauma class observed today:
~30× the threshold (3+ events triggers ladder fire). The Forever-Rule
gives the high volume a doctrine landing pad and **recategorizes the
event class from a failure to a healthy collision-prevention signal**.

## Top saturation hotspots

| Path | Collisions | % of cluster |
|---|---|---|
| `/Users/josh/Developer/flywheel/.beads/issues.jsonl` | 94 | 51% |
| `/Users/josh/Developer/flywheel/INCIDENTS.md` | 42 | 23% |
| `~/.claude/skills/.flywheel/lib/portable/core.sh` | 6 | 3% |
| `.flywheel/AGENTS-CANONICAL.md` | 5 | 3% |
| `~/.local/state/flywheel/fuckup-processed.jsonl` | 4 | 2% |
| `~/.claude/skills/.flywheel/lib/loop.sh` | 4 | 2% |
| `~/.claude/skills/.flywheel/bin/flywheel-loop` | 4 | 2% |
| Other paths (1–3 each) | ~25 | ~14% |

74% of the cluster lands on two paths: `.beads/issues.jsonl` and
`INCIDENTS.md`. These are the canonical worker-callback append target
and the L56 doctrine target respectively — both hit at the end of
every worker tick.

## Pane attribution

| Pane | Collisions |
|---|---|
| `flywheel:2` | 74 |
| `flywheel:3` | 55 |
| `flywheel:4` | 51 |
| `flywheel:worker` | 2 |
| `flywheel:?` (unattributed) | 2 |

All three primary worker panes contribute proportionally; the cluster
is structurally distributed across the worker fan-out, not a single
misbehaving pane.

## What changed

### `INCIDENTS.md`

Added new `## coordination-collision-detected` section at line 6045,
inserted immediately after `## worker-evidence-file-write-before-reservation`
(the closest semantic neighbor in the L107 reservation family). All
10 canonical template fields populated:

- Date: 2026-05-09
- Promotion Action: NEW
- Class: `coordination-collision-detected`
- Event Count: 184 events in 7 days (largest L56 cluster observed)
- Severity: medium-volume / low-individual
- Cost: 184 reservation requests returned `status=blocked`; on its
  own each is healthy, the trauma is the volume signal that two
  shared surfaces are saturated.
- Root Cause: canonical worker tick (write evidence → append to
  `.beads/issues.jsonl` via `br close` → append to `INCIDENTS.md`
  via `/flywheel:learn --promote`) hits both top-collision targets
  back-to-back; with 3+ active panes the contention is by design and
  the reservation system catches it.
- Forever-Rule: a `coordination-collision-detected` event is a
  **healthy collision-prevention signal**, not a worker failure.
  Workers MUST treat `status=blocked` as a coordination boundary —
  capture the holder, draft any patch artifacts in the audit pack so
  work doesn't stall, retry after the holder's TTL or release.
- Fix Applied/Status: NEW layer-2 INCIDENTS entry. Recategorizes
  the trauma class from "184 failures" to "184 healthy back-offs."
- Evidence: 184 fuckup-log rows + top-target distribution + pane
  attribution + reservation script path + sister INCIDENTS family
  links + AGENTS.md L107 reference + sister-bead pattern citation
  (`flywheel-uyd9i` this session) + companion dedup bead +
  this bead's id.

### `~/.local/state/flywheel/fuckup-processed.jsonl`

Appended row keyed by `bead_id=flywheel-8nrza`,
`processed_into=INCIDENTS.md#coordination-collision-detected`,
`processed_by=/flywheel:learn --promote`, with the volume note
("184 events 2026-05-07-2026-05-09; 94 .beads/issues.jsonl + 42
INCIDENTS.md = 74 percent of cluster") and the canonical pattern
reference (sister bead `flywheel-uyd9i`).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | INCIDENTS.md gains new section at line 6045; `.flywheel/audit/flywheel-8nrza/` carries this evidence pack + pinned SHA |
| AG2 — targeted validator passes and named | DID | `bash .flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status:"pass"`, `incidents_evidence_missing_count:0`, `entries_checked:110`; template-coverage probe confirms 10/10 fields |
| AG3 — `br show flywheel-8nrza` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Sister-bead canonical reference

`flywheel-uyd9i` (this session) is the canonical worked example of the
Forever-Rule: hit `status=blocked` on INCIDENTS.md reservation, drafted
Path A (sibling-merge) and Path B (standalone) patch artifacts as
audit-pack fallbacks, retried after holder release, applied Path A.
That pattern resolves a single collision; this section gives the
pattern a doctrine name so future workers route through the same
shape.

## Out-of-scope follow-up (NOT this bead)

A `coordination-collision-saturation-hotspots` analysis bead could
quantify whether the `.beads/issues.jsonl` + `INCIDENTS.md`
saturation warrants a per-target reservation TTL tune or a fan-in
serialization gate. That's a Donella-leverage-#5 (rule of the
system) consideration — touching the reservation TTL config is
substrate-tier, requires data on time-to-release distribution, and
should be a separate dispatch under Joshua sign-off. Surfaced in this
section's Fix Applied/Status block but NOT executed here.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| INCIDENTS.md (post-promotion) | `INCIDENTS.md` | (see `pinned-shas.txt`) |

## Verification commands (re-runnable)

```bash
# Confirm new section
grep -n "^## coordination-collision-detected$" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 6045

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq '{status, incidents_evidence_missing_count, entries_checked}'
# expected: status=pass, incidents_evidence_missing_count=0, entries_checked=110

# Reproduce the top-target distribution
grep "coordination-collision-detected" /Users/josh/.local/state/flywheel/fuckup-log.jsonl \
  | jq -r '(.what // .what_happened // "")' \
  | grep -oE 'path=[^[:space:]]+' | sort | uniq -c | sort -rn | head -10
# expected: .beads/issues.jsonl ~94, INCIDENTS.md ~42, etc.

# Confirm dedup heuristic now skips the class (post-merge)
/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
  | jq -r '.skipped[] | select(test("coordination-collision-detected"))'
# expected (post-close): coordination-collision-detected:incidents_covered
```

## L112 probe (worker callback)

```bash
grep -q "^## coordination-collision-detected$" /Users/josh/Developer/flywheel/INCIDENTS.md \
  && bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
       | jq -e '.status == "pass" and .incidents_evidence_missing_count == 0 and (.entries_checked >= 110)' >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No `/flywheel:learn` slash-command invocation.** Worker replicates
  the artifact shape directly, mirroring sister-bead patterns from
  `flywheel-ijsb7`, `flywheel-2tgl`, and the `flywheel-8qal5`
  earlier in session.
- **No reservation script change.** `shared-surface-reservation-check.sh`
  unchanged. The Forever-Rule codifies the existing organic discipline.
- **No reservation TTL tune.** That's the out-of-scope follow-up
  noted above; touching the TTL config affects every shared surface
  fleet-wide and is Joshua-gated.
- **No saturation-hotspot fan-in serialization.** Same out-of-scope
  rationale.
- **Sister sections unchanged.** `## file-reservation-closeout-conflict`
  (line 5882) and `## worker-evidence-file-write-before-reservation`
  (line 5991) are unchanged; the new section sits between them and
  the `## fire-and-forget-dispatch` section that follows.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — INCIDENTS doctrine, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — INCIDENTS.md gained a layer-2 entry; AGENTS.md
  L107 is referenced but unchanged.
- `readme_updated=not_applicable`.
- `no_touch_reason=L56_layer-2_INCIDENTS_promotion_canonical_L-rule_L107_unchanged`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Recategorizes a
  high-volume cluster (184 events) from "failures" to "healthy
  back-offs" with concrete saturation hotspots named.
- **Sniff: 9** — top-target + pane-attribution distributions
  mechanically derived from 184 fuckup-log rows; validator passes;
  template fields 10/10; out-of-scope follow-up explicitly named.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface
  (one INCIDENTS section + one ledger row + one pinned SHA);
  Forever-Rule names existing organic discipline rather than
  proposing new tooling; out-of-scope TTL tune surfaces saturation
  data without authoring it.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: top-target distribution table is
    grep-friendly; sister-bead canonical-example pointer
    (`flywheel-uyd9i`) gives the worked pattern; reproduce-distribution
    shell snippet is one-liner.
  - **maintainer (extending later)**: top-target distribution + pane
    attribution + 184-row baseline give the saturation-hotspot
    follow-up bead a concrete data anchor to start from.
  - **future worker (LLM agent)**: Forever-Rule reframes
    `status=blocked` as healthy boundary; sister-bead reference
    (`flywheel-uyd9i`) is the worked example; future
    `coordination-collision-detected` events route through the same
    drafted-fallback-and-retry pattern.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-8nrza
no_bead_reason=incidents_promotion_complete_184-event_largest_cluster_observed_canonical_pattern_documented_via_sister_bead_flywheel-uyd9i_saturation-hotspot-followup_out-of-scope_for_this_dispatch`.
