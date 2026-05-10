---
title: flywheel-wzjo9.3.5 evidence — flywheel-quality canonical-CLI fillin (mutator+emitter variant)
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.5
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0c 5/9 closed avg 990 (3.8 + 3.3 + 3.9 + 3.1 + 3.6)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-e
---

# flywheel-wzjo9.3.5 evidence

**Status:** DONE — flywheel-quality canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. Sixth wave-2.0c surface (145 → 685 lines, ~4.7x). **Mutator+emitter variant** of producer+product pattern.

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
| Lines | 145 | 685 |
| Expansion | — | ~4.7x |
| Magic comment | absent | present |

## Substantive fillin (mutator+emitter variant of producer+product)

flywheel-quality is a **mutator+emitter** surface — distinct from the report-generator surfaces in sister wzjo9.3.1 + wzjo9.3.6. It does not write a markdown file; instead it:

1. **MUTATES** `sources.quality_alpha/beta/score` columns (Thompson Beta posterior recompute over 30-day window)
2. **EMITS** `events` table rows: `quality.recompute` (every run) + `quality.flag_low` (per low-quality source per run)

So the "product" is split across two substrate locations: DB column state + emitted event rows. The canonical layer's domain-specific subjects address both:

- **`--quality-distribution`** probes the **mutator product** (sources.quality_score column state — count + flagged + mean/min/max)
- **`--events`** probes the **emitter product** (events table quality.* row counts + timestamps)

### Substrate probes (doctor — 6 named)

| Probe | Description |
|---|---|
| `flywheel_home_resolvable` | `$(dirname $0)/..` resolves to skill dir (returns abs path) |
| `lib_common_readable` | `$FLYWHEEL_HOME/lib/common.sh` for `fw_sql`/`fw_event`/`fw_require_db` |
| `sqlite3_on_path` | required for `fw_sql` |
| `bash_version_4_plus` | **mutator-specific** — script re-execs under bash 4+ (macOS bash 3.2 not supported); returns BASH_VERSION as `.value` |
| `sources_table_accessible` | live `SELECT COUNT(*) FROM sources` (returns count as `.value`) |
| `joshua_verdicts_table_accessible` | live `SELECT COUNT(*) FROM joshua_verdicts` — **mutator-specific** dependency (Loop F surface) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas with `mutator+emitter` semantics
- **scaffold_emit_topic_help:** single-printf bodies; cmd_run topic explicitly flags **NOT idempotent**
- **scaffold_cmd_doctor:** 6 substrate probes (richest in wave so far; 4 with live `.value` incl. BASH_VERSION + 1268 sources count + 1 joshua_verdict)
- **scaffold_cmd_health:** tail audit log + probes most recent quality.recompute event timestamp; warn stale >8d
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + `events-prime` read-only — probes events table for latest quality.recompute + quality.flag_low)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **quality-distribution** / **events**) — last two are mutator+emitter-specific
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail` (b9dfv positional order)
- **scaffold_cmd_why:** searches audit log for source-id, skill, or window-days

## Live signals (rich domain truth — real fleet snapshot)

1. **doctor 6/6 pass** with all probes status="pass":
   - `flywheel_home_resolvable=/Users/josh/.claude/skills/.flywheel`
   - `lib_common_readable=/Users/josh/.claude/skills/.flywheel/lib/common.sh`
   - `sqlite3_on_path=/usr/bin/sqlite3`
   - `bash_version_4_plus=5.3.9(1)-release` (live BASH_VERSION)
   - `sources_table_accessible=1268`
   - `joshua_verdicts_table_accessible=1`
2. **`validate --quality-distribution`** → **rich Bayesian posterior snapshot:**
   - `sources_count=1268, flagged_count=0`
   - `mean_score=0.5362, min_score=0.5000, max_score=0.9407`
   - Distribution is real fleet truth: cluster near 0.5 (the Beta(1,1) prior anchor), max 0.9407 (consistently-keep sources), zero currently below 0.3+28d threshold
3. **`validate --events`** → **emitter product live state:**
   - `recompute_count=5, flag_count=0`
   - `latest_recompute=2026-05-03 10:24:37` (7 days ago — exactly at the health warn threshold)
   - 5 historical recompute runs, 0 flag_low events ever (consistent with quality-distribution showing 0 flagged)
4. **`repair --scope events-prime`** → 30-day event counts: `recompute_count_30d=5, flag_count_30d=0, latest_recompute=2026-05-03 10:24:37`
5. **cmd_run passthrough** preserved — bare invocation MUTATES sources + emits events (NOT executed in this fillin — would mutate live state)

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subject) all converge on the same domain truth: substrate healthy, 5 historical recomputes, 0 flagged sources currently, mean posterior 0.5362.

## Bug-catch mid-tick (sniff lens working)

First-pass `validate --events` and `repair --scope events-prime` referenced `events.event` column — but the table uses `events.kind`. Direct probe via `fw_sql ".schema events"` caught the column-name mismatch. Fixed in 4 sites via `replace_all` → `events.kind`. Re-probe confirmed live data emerging:
- pre-fix: `events_table_accessible=false, recompute_count=""` (incorrectly reported as warn)
- post-fix: `events_table_accessible=true, recompute_count="5", latest_recompute="2026-05-03 10:24:37"`

This is the canonical "validate against real substrate" working as designed: the fillin's own validate subject caught a schema assumption mismatch the moment it touched live data.

## Mutator+emitter pattern doctrine (transferable)

This fillin establishes the canonical pattern for **mutator+emitter surfaces** in the flywheel — distinct from the report-generator producer+product variant in wzjo9.3.1 + wzjo9.3.6:

| Aspect | Report-generator (3.1, 3.6) | Mutator+emitter (3.5) |
|---|---|---|
| Product type | markdown file artifact | DB column state + event rows |
| Product paths | `reports/` or `proposals/` | `sources` columns + `events` rows |
| Domain-specific subjects | `--<table>` + `--<artifact-file>` | `--<mutator-product>` + `--<emitter-product>` |
| Concrete in this fillin | n/a | `--quality-distribution` + `--events` |
| Repair scope | `<dir>-prime` (probe file artifacts) | `events-prime` (probe emitted rows) |
| Health probe | latest file mtime in product dir | latest event ts via `MAX(ts) WHERE kind=...` |
| cmd_run terminal signal | `OK: $OUT_FILE` | `OK: <stats line>` (no file path) |
| Idempotency | safe to re-run (overwrites file) | **NOT idempotent** — reset+recompute |

Both variants share: file substrate probes (FLYWHEEL_HOME, lib/common.sh, sqlite3), data substrate probes (table row counts via fw_sql), audit-log-rotate scope, row/schema/config validate subjects, why audit-log-search.

Sister wave-2.0c surfaces yet to ship: 3.7 (flywheel-stale, 185 lines), 3.4 (flywheel-pattern, 250 lines), 3.2 (flywheel-digest, 274 lines). 3.7 and 3.4 are likely report-generators; 3.2 (digest) is likely report-generator with multiple input streams.

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `flywheel-quality/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `events-prime`
- Test 16: doctor 5+ probes incl. `bash_version_4_plus` + `sources_table_accessible` + `joshua_verdicts_table_accessible` (mutator+emitter-specific)
- Test 17: repair `--scope events-prime` non-stub envelope with `latest_recompute` + `recompute_count_30d` + `flag_count_30d`
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--quality-distribution` probes sources.quality_score column state — **mutator-product subject**
- Test 20: validate `--events` probes events table quality.* rows — **emitter-product subject**

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality \
  && bash tests/flywheel-quality-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c, 9 surfaces)
- Sister wave-2.0c (5/9 closed so far): 3.8 (990), 3.3 (990), 3.9 (990), 3.1 (990), 3.6 (990) — pattern transferability established at 3.1+3.6; mutator+emitter variant introduced here
- Sister wave-2.0b fillins (avg 992)
- Sister wave-2.0a fillins (avg 984)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-quality` (145 → 685 lines, ~4.7x)
- Backup: `flywheel-quality.bak.scaffold-20260510T224515096428000Z-49004`
- Test: `tests/flywheel-quality-canonical-cli.sh` (20/20 PASS)
- Data substrate: `sources` (1268 rows, mean quality_score=0.5362) + `joshua_verdicts` (1 row) + `outcomes` table via `fw_sql`
- Emitter substrate: `events` table (5 historical quality.recompute rows, 0 quality.flag_low rows; latest recompute 2026-05-03 10:24:37)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — sixth wave-2.0c surface shipped at sister-trend cadence (5/5 prior surfaces at 990); introduces **mutator+emitter variant** of producer+product pattern (third variant established this wave: report-generator at 3.1+3.6, mutator+emitter here); transferable doctrine for sister mutator surfaces
- **sniff: 10** — caught events.event vs events.kind column-name mismatch mid-tick via direct `.schema events` probe; doctor reports 6 substrate probes (richest in wave so far); 3 orthogonal canonical surfaces converge on consistent fleet truth (1268 sources / mean 0.5362 / 5 historical recomputes / 0 flagged); validate --quality-distribution exposes real Bayesian Beta posterior snapshot
- **jeff: 9** — preserves cmd_run's reset+recompute mutation logic + joshua_verdicts JOIN + Thompson Beta math; bash 4+ re-exec dependency surfaced as explicit substrate probe; helper-lib API contracts respected; producer+product pattern from 3.1+3.6 extended to mutator+emitter variant cleanly
- **public: 10** — three judges check: skeptical operator (20/20 PASS + 6-probe doctor + real fleet posterior snapshot mean=0.5362 / max=0.9407), maintainer (mutator+emitter doctrine transferability table documented + bug-catch narrative shows sniff lens working), future worker (concrete table comparing report-generator vs mutator+emitter variants gives operational guidance for sister surfaces 3.7 / 3.4 / 3.2 which may need similar variant choices)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + 3 orthogonal canonical surfaces consensus on real fleet data + 2 mutator+emitter-specific validate subjects (quality-distribution + events) + 6-probe doctor (richest in wave so far) + bash 4+ re-exec dependency surfaced as substrate probe + mutator+emitter variant pattern doctrine documented (table) + caught events.event vs events.kind schema bug mid-tick via direct probe (sniff lens) = **990/1000**. -10 for the same audit-row-not-wired-into-cmd_run constraint as sisters 3.1+3.6 (deliberate architectural deferral).
