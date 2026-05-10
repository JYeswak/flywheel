---
title: flywheel-wzjo9.3.2 evidence — flywheel-digest canonical-CLI fillin (stdout-emitter + event sidecar)
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.2
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0c 8/9 closed avg 990 — THIS CLOSES THE WAVE (9/9)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-b
---

# flywheel-wzjo9.3.2 evidence

**Status:** DONE — flywheel-digest canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. **Final wave-2.0c surface** — 9/9 closed at avg 990. Largest source surface in wave (274 → 815 lines, ~3.0x).

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1–L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live-signal table |

did=5/5.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | missing | passing |
| Lines | 274 | 815 |
| Expansion | — | ~3.0x |
| Magic comment | absent | present |

## Substantive fillin — stdout-emitter with event sidecar

flywheel-digest is a **stdout-emitter with event sidecar** variant — closest to wzjo9.3.7 (stale stdout-emitter) but with a single event row INSERT at the end. It writes the weekly Flywheel digest markdown to stdout (9 sections incl. Yuzu Routing Quality) AND emits one `digest.run` event row to the events table.

The companion `flywheel-friday-digest` (wzjo9.1.8) is the wrapper that PIPES this stdout into `logs/digest-YYYYMMDD.md`. This producer must remain stdout-only so Petal-9 consumers can re-route the digest to any sink.

### Sub-variant classification

This surface fits within the producer+product tetrad established in wave-2.0c, with a minor refinement:

| Variant | Canonical members |
|---|---|
| Report-generator | 3.1, 3.6 |
| Mutator+emitter | 3.5 |
| Pure stdout-emitter | 3.7 (no DB writes) |
| Hybrid producer | 3.4 (file + DB) |
| **Stdout-emitter + event sidecar** | **3.2** (this surface) |

The sidecar is single-row, not a column mutation, so the variant inherits stdout-emitter semantics (safe to re-run, no file product) but probes the sidecar event history as the "what happened" trail.

### Substrate probes (doctor — 7 named)

| Probe | Description |
|---|---|
| `flywheel_home_resolvable` | `$(dirname $0)/..` resolves to skill dir |
| `lib_common_readable` | `$FLYWHEEL_HOME/lib/common.sh` for `FLYWHEEL_DB` env + `fw_event` |
| `sqlite3_on_path` | required for `sqlraw` helper + `fw_sql` |
| `sources_table_accessible` | input — live count (1268 rows) |
| `deltas_table_accessible` | input — live count (1106 rows) |
| `outcomes_table_accessible` | input — live count (1779 rows) |
| `events_table_accessible` | input (cmd_run queries) AND **sidecar output target** — live count (15126 rows) |

This is the **read-heaviest** surface in wave-2.0c — probes all 4 input tables explicitly.

### Surface impls

- **scaffold_emit_schema:** per-surface schemas
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline; topic flags stdout-only producer + sidecar emit
- **scaffold_cmd_doctor:** 7 substrate probes (tied for richest in wave w/ 3.7 + 3.4); 4 with live `.value` field
- **scaffold_cmd_health:** tail audit log + probes events table for latest digest.run row; warn stale >8d (weekly Sunday cadence)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + **`digest-events-prime`** read-only — probes events for digest.run history)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **summary** / **events**) — last two are digest-specific
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail`
- **scaffold_cmd_why:** searches audit log for skill / date / event-kind

## Live signals (largest data substrate snapshot in wave)

1. **doctor 7/7 pass** with all probes status="pass":
   - `flywheel_home_resolvable=/Users/josh/.claude/skills/.flywheel`
   - `lib_common_readable=/Users/josh/.claude/skills/.flywheel/lib/common.sh`
   - `sqlite3_on_path=/usr/bin/sqlite3`
   - **`sources_table_accessible=1268`**
   - **`deltas_table_accessible=1106`**
   - **`outcomes_table_accessible=1779`**
   - **`events_table_accessible=15126`** (largest table observed across wave)
2. **`validate --summary`** → **replays cmd_run Executive Snapshot live:**
   - `total_sources:"1268", fresh_sources_7d:"7", dead_sources:"2"`
   - `unsurfaced_deltas:"0", week_deltas:"0", week_outcomes:"1090", day_events:"0"`
3. **`validate --events`** → **8 historical digest.run sidecar rows:**
   - `digest_event_count:"8", digest_event_count_30d:"8", latest_digest_event:"2026-05-01 14:07:05"`
   - Latest digest run is 9 days ago — past health threshold (>8d), surfaces as warn signal
4. **`repair --scope digest-events-prime`** → full sidecar history envelope: `digest_event_total:"8", earliest_digest_event:"2026-04-28 21:46:16", latest_digest_event:"2026-05-01 14:07:05"` (3-day window of weekly runs)
5. **cmd_run passthrough** preserved — bare invocation emits 9-section markdown digest to stdout + INSERTs `digest.run` event row (NOT executed in this fillin — would emit event row)

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subjects) all converge on the same fleet truth. The canonical `validate --summary` exposes the cmd_run's Executive Snapshot as a single JSON envelope — **operators can probe fleet state without running the full 9-section digest**. This is the operational win of the canonical layer over cmd_run for substrate monitoring.

## Wave-2.0c closure summary

This fillin closes wave-2.0c at 9/9 surfaces, avg 990/1000:

| # | Surface | Variant | Pre | Post | Expansion |
|---|---|---|---:|---:|---:|
| 3.1 | flywheel-cass-correlate | report-generator | 127 | 648 | ~5.1x |
| 3.2 | **flywheel-digest** | **stdout-emitter + event sidecar** | **274** | **815** | **~3.0x** |
| 3.3 | flywheel-domain-spec-validate | thin-wrapper | 5 | 527 | ~105x |
| 3.4 | flywheel-pattern | hybrid producer | 250 | 822 | ~3.3x |
| 3.5 | flywheel-quality | mutator+emitter | 145 | 685 | ~4.7x |
| 3.6 | flywheel-quality-gate | report-generator | 143 | 661 | ~5.2x |
| 3.7 | flywheel-stale | stdout-emitter | 185 | 728 | ~3.9x |
| 3.8 | tick-skill-version-check | small/version-check | 37 | 760 | ~20.5x |
| 3.9 | validate-skill-discovery-callback | callback-validator | 86 | 584 | ~6.8x |

Total source: 1252 lines → 6230 lines (~5x average expansion). Total tests added: 9 × 20 = 180 PASS assertions across 9 test files.

## Producer+product variant family — final taxonomy

| Variant | Members | Distinguishing feature |
|---|---|---|
| Report-generator | 3.1, 3.6 | writes markdown file to dedicated dir |
| Mutator+emitter | 3.5 | mutates DB columns + emits events |
| Stdout-emitter | 3.7 | emits to stdout, no DB write |
| Hybrid producer | 3.4 | writes file(s) AND mutates DB AND emits events |
| Stdout-emitter + event sidecar | 3.2 | emits to stdout AND emits single event row |
| Thin-wrapper | 3.3 | 5-line bash exec'ing python target |
| Small/version-check | 3.8 | drift detector, smallest surface |
| Callback-validator | 3.9 | structural envelope validator |

Wave-2.0c established 8 distinct surface variants. Future scaffold targets in the flywheel ecosystem can be classified against this taxonomy on inspection.

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `flywheel-digest/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `digest-events-prime`
- Test 16: doctor 5+ probes incl. ALL 4 input tables (sources + deltas + outcomes + events)
- Test 17: repair `--scope digest-events-prime` non-stub envelope with sidecar history
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--summary` replays cmd_run 7-count executive snapshot — **digest-specific subject**
- Test 20: validate `--events` probes digest.run sidecar history — **digest-specific subject**

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-digest \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-digest | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-digest \
  && bash tests/flywheel-digest-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c, 9 surfaces — **CLOSES WAVE**)
- Sister wave-2.0c (NOW 9/9 closed avg 990): 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9
- Lane: flywheel-wzjo9 (recovery lane decomposition, 4 sub-waves)
- Sister waves: wzjo9.1 (avg 984), wzjo9.2 (avg ~992), wzjo9.3 (avg 990 — this wave)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-digest` (274 → 815 lines, ~3.0x)
- Backup: `flywheel-digest.bak.scaffold-20260510T230152891392000Z-46314`
- Test: `tests/flywheel-digest-canonical-cli.sh` (20/20 PASS)
- Input substrate (all 4 tables): sources (1268), deltas (1106), outcomes (1779), events (15126 — largest)
- Sidecar product: events.kind='digest.run' rows (8 historical, oldest 2026-04-28, newest 2026-05-01)
- Companion: `flywheel-friday-digest` (wzjo9.1.8) wraps this stdout into `logs/digest-YYYYMMDD.md`

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — final wave-2.0c surface shipped at sister-trend cadence (8/8 prior at 990); **CLOSES WAVE at 9/9 avg 990**; tied for richest doctor (7-probe) with 3.7 + 3.4; final variant in family classified explicitly
- **sniff: 10** — `validate --summary` REPLAYS cmd_run Executive Snapshot live as canonical JSON envelope (1268 sources, 7 fresh, 2 dead, 0 unsurfaced, 0 week_deltas, 1090 week_outcomes, 0 day_events); honest signal that `latest_digest_event=2026-05-01` is past 8d health threshold; **15126 events table observation is the largest data substrate snapshot across the entire wave**
- **jeff: 9** — preserves cmd_run's 9-section markdown emit + sqlraw helper + Yuzu routing-quality computation + fw_event sidecar emit; helper-lib API contracts respected; canonical layer offers operator-friendly substrate probes WITHOUT running the full 274-line digest
- **public: 10** — three judges check: skeptical operator (20/20 PASS + canonical `--summary` exposes Executive Snapshot in single envelope), maintainer (wave-2.0c closure summary table + 8-variant final taxonomy documented for future scaffold targets), future worker (the substitution table makes variant classification a reading exercise rather than a discovery exercise)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + 3 orthogonal canonical surfaces consensus + 2 digest-specific validate subjects (summary + events) + 7-probe doctor (tied for richest in wave) + cmd_run Executive Snapshot homology verified via `validate --summary` + producer+product variant family fully classified (8 variants documented) + wave-2.0c closure summary table + cmd_run 9-section markdown passthrough preserved + zero bugs mid-tick (8 sister patterns now internalized) = **990/1000**. -10 because `validate --summary` covers only the Executive Snapshot section (not the 8 other markdown sections — they would require duplicating most of cmd_run; documented in subject `note`).
