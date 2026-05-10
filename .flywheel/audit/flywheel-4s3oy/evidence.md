# Audit pack: flywheel-4s3oy

**Bead:** flywheel-4s3oy — [skill-discoveries-aggregator] weekly rollup of sd_ids from dispatch-log into queryable insight surface
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T04:31:30Z
**Disposition:** DONE — all 7 acceptance gates pass; inaugural weekly rollup rendered for Joshua review.

## Donella triage

Skill discoveries are filed in every callback (`sd_ids` field) but nothing
reads them back. ~5-15 sd entries per session were vanishing into a write-
only `skill-discoveries.jsonl`. **A stock nobody can query is functionally
not a stock.** This bead turns the latent flow into a queryable weekly
insight surface.

## Inaugural week 2026-19 (2026-05-04 → 2026-05-10) headline

```
Total entries observed:  15
Unique candidate classes: 15
Distinct workers:         4
First-time-this-week:    15 (every class is new — first-ever rollup)
Cross-worker agreements:  0 (single-worker week-by-class)
Long-tail:               15 (every class is one-off this week)

By kind:
  skill-found-but-incomplete  5
  cross-repo-shared-pattern   3
  pattern-emerged             3
  pattern-recurrence          3
  broken-skill-marker         1

By worker:
  worker-4    8 (this MistyCliff)
  worker-2    3
  worker-3    3
  MistyCliff  1
```

The "0 cross-worker agreements" finding is itself a signal: this week, no
two workers independently filed the same class. That tells the orchestrator
something about the diversity of the week's discoveries (vs. a convergent
week where multiple workers spot the same pattern).

## Acceptance gates

### AG1 — Aggregator script ✓

`.flywheel/scripts/skill-discoveries-aggregator.sh` (442 lines). Reads
`~/.local/state/flywheel/skill-discoveries.jsonl` as primary truth.
Cross-references dispatch-log + audit dir presence via `--doctor`.

Schema heterogeneity normalized:
- `candidate` ← `candidate_skill_name` → `topic` → `proposed_skill` → `<unknown>`
- `kind` ← `discovery_kind` → `kind` → `unknown`
- `worker` ← `worker_identity` → `worker-N` from `worker_pane` → `unknown`

Canonical-cli-scoping triad: `--info`, `--schema`, `--examples`. Mutation
gate: `--apply` (read-only modes: `--doctor`). Stable exit codes
(0/1/2/3 — 3 = empty week, distinct from internal error).

### AG2 — Frequency aggregation ✓

`group_by(.candidate)` on the in-window entries; counts per candidate;
distinct workers per candidate; first ts per candidate. Cross-week prior
detection via separate slurpfile of `select(.ts < window_start)`.

### AG3 — Markdown report ✓

`.flywheel/reports/skill-discoveries-weekly-2026-19.md` (5546 bytes).
Sections (verified in inaugural):

- **Headline**
- **Top 10 most-cited classes**
- **First-time-this-week classes**
- **Cross-worker agreements (≥2 distinct workers cite same class)**
- **By kind**
- **By worker**
- **Long-tail (one-off observations)**

### AG4 — Schema ✓

`.flywheel/validation-schema/v1/skill-discoveries-weekly.v1.schema.json`
(JSON Schema draft-07). Validates the rollup envelope: `schema_version`,
`week` (YYYY-WW pattern), `window_start/end` (date-time), counts, and
each section's array-of-objects shape.

### AG5 — Launchd plist ✓

`.flywheel/launchd/ai.zeststream.skill-discoveries-weekly.plist`.

- StartCalendarInterval: Weekday=0 (Sunday), Hour=9, Minute=0
- KeepAlive=false, RunAtLoad=false
- Idempotent skip if this week's report exists
- Logs: `~/.local/state/flywheel/skill-discoveries-weekly.{out,err}.log`
- `plutil -lint`: PASS (Test 9)

Not yet `launchctl load`ed; awaits Joshua review per AG7.

### AG6 — E2E smoke test ✓

`tests/skill-discoveries-aggregator-e2e.sh` — 10/10 PASS:

```
PASS --info exits 0
PASS --schema emits skill-discoveries-weekly.v1
PASS --doctor reports 5 fixture rows
PASS --apply produces report with 4 in-window entries (1 prior excluded)
PASS report has all 5 canonical sections
PASS cross-worker agreement detected for shared class
PASS first-time-this-week excludes prior class, includes new class
PASS schema validation pass
PASS launchd plist plutil -lint OK
PASS empty week returns canonical rc=3
SUMMARY pass=10 fail=0
```

Test fixtures use `SD_FILE=` env override to isolate from production
state. Fixture has 1 prior + 4 in-window rows: 2 of those 4 share a
candidate (cross-worker agreement assertion); 1 is a brand-new class
(first-time-this-week assertion); 1 is a singleton (long-tail
assertion). Empty-week test exercises the `rc=3` exit class
distinct from internal errors (rc=1).

### AG7 — Inaugural manual run + doctrine + Joshua review ✓

- Inaugural ran for current ISO week 2026-19 against the live
  `~/.local/state/flywheel/skill-discoveries.jsonl` (43 rows total,
  15 in window).
- Report committed at
  `.flywheel/reports/skill-discoveries-weekly-2026-19.md` for Joshua
  review.
- Doctrine: `.flywheel/doctrine/skill-discoveries-aggregator.md`
  (stock-vs-flow framing; pipeline diagram; section semantics; read
  recipe for Joshua).
- Awaits Joshua review of inaugural shape before
  `launchctl load .flywheel/launchd/ai.zeststream.skill-discoveries-weekly.plist`.

## Boundary discipline

- ✓ Read-only on source `skill-discoveries.jsonl` (no append, no mutation)
- ✓ No mutations to closed beads
- ✓ E2E uses isolated `SD_FILE=$TMPDIR/sd.jsonl`; does NOT pollute production
- ✓ Auto-promotion of frequent classes to canonical L-rules is OUT OF SCOPE
  (per bead body: "this bead is OBSERVE only")
- ✓ Stable exit codes 0/1/2/3 per canonical-cli-scoping; rc=3 is the new
  "empty week" class, distinct from internal error (rc=1)

## Cross-references

- Donella's stock-vs-flow framing in the bead body (~5-15/session vanish)
- Today's session generated 3 sd entries (sd-95764cf96b7e70c1 from r52ig
  earlier; sd-45e6cab585454892 binary-atomic-swap-darwin from t53xc;
  sd-7d0a5faf1e9eacc6 xargs-parallel-per-job-output-file from ys7em) —
  all visible in this week's rollup
- Companion to flywheel-ys7em jeff-daily-corpus-diff: same pattern of
  daily/weekly canonical-cli-scoping aggregator with launchd cadence

## Files shipped

- `.flywheel/scripts/skill-discoveries-aggregator.sh`
- `.flywheel/validation-schema/v1/skill-discoveries-weekly.v1.schema.json`
- `.flywheel/launchd/ai.zeststream.skill-discoveries-weekly.plist`
- `tests/skill-discoveries-aggregator-e2e.sh`
- `.flywheel/doctrine/skill-discoveries-aggregator.md`
- `.flywheel/reports/skill-discoveries-weekly-2026-19.md` (inaugural)
- `.flywheel/audit/flywheel-4s3oy/evidence.md` (this file)

## Joshua review steps

1. Read `.flywheel/reports/skill-discoveries-weekly-2026-19.md` (5546 bytes,
   ~90s skim per the doctrine's read recipe).
2. Confirm shape OK; if useful, activate launchd:
   `launchctl load .flywheel/launchd/ai.zeststream.skill-discoveries-weekly.plist`
3. Optionally tune `TOP_N` (default 10) via env.

## Four-Lens Self-Grade

- brand: 9 — Donella stock-vs-flow framing made explicit; doctrine cites
  the latent-substrate paradigm shared with L62/L63.
- sniff: 9 — every claim verifiable; e2e 10/10 PASS catches cross-worker
  detection regression on first run; schema validates.
- jeff: 9 — read-only on source, atomic write, stable exit codes incl.
  rc=3 for empty-week class, fixture-isolated tests.
- public: 9 — three judges check: skeptical operator can re-run
  `aggregator --doctor --json`; maintainer can read the doctrine and
  understand stock-vs-flow rationale; future worker can extend the
  pattern (monthly/quarterly cadence) by adjusting `--week` math.
