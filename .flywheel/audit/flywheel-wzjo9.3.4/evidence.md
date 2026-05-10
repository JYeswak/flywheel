---
title: flywheel-wzjo9.3.4 evidence — flywheel-pattern canonical-CLI fillin (hybrid producer variant)
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.4
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0c 7/9 closed avg 990 (3.8 + 3.3 + 3.9 + 3.1 + 3.6 + 3.5 + 3.7)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-d
---

# flywheel-wzjo9.3.4 evidence

**Status:** DONE — flywheel-pattern canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. Eighth wave-2.0c surface (250 → 822 lines, ~3.3x). **Hybrid producer variant** — extends the producer+product triad with a 4th variant.

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
| Lines | 250 | 822 |
| Expansion | — | ~3.3x |
| Magic comment | absent | present |

## Substantive fillin — hybrid producer variant

flywheel-pattern is a **HYBRID** producer surface — combines BOTH report-generator and mutator+emitter behaviors:

- **Report-generator side:** writes 2 markdown proposal files to `proposals/`:
  - `skill-promotions-YYYY-WW.md` (Loop D skill promotion candidates)
  - `skill-crosslinks-YYYY-WW.md` (Loop E skill crosslink candidates)
- **Mutator+emitter side:**
  - UPSERTs into `crosslinks` table (DB-mutator product)
  - INSERTs 2 rows into `events` table (`pattern.promotions` + `pattern.crosslinks`)

This 4th variant extends the producer+product variant triad established in wzjo9.3.1+3.6+3.5+3.7. The canonical fillin probes BOTH product surfaces:
- `validate --proposals` probes the file products (BOTH skill-promotions + skill-crosslinks markdown files)
- `validate --crosslinks` probes the DB-mutator product (crosslinks table state)

### Substrate probes (doctor — 7 named)

| Probe | Description |
|---|---|
| `flywheel_home_resolvable` | `$(dirname $0)/..` resolves to skill dir |
| `lib_common_readable` | `$FLYWHEEL_HOME/lib/common.sh` for FLYWHEEL_DB env |
| `sqlite3_on_path` | required for fw_sql |
| `python3_on_path` | **hybrid-specific** — cmd_run uses python3 heredoc for token analysis + crosslinks UPSERT (returns abs path) |
| `flywheel_skills_dir_present` | required for FS dedupe check (cmd_run excludes tokens that already have SKILL.md) |
| `deltas_table_accessible` | input data substrate (1106 rows) |
| `crosslinks_table_accessible` | **hybrid-specific** — mutator output substrate (599 rows from historical runs) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline; topic explicitly flags HYBRID nature
- **scaffold_cmd_doctor:** 7 substrate probes (tied for richest in wave w/ 3.7); 4 with live `.value` field
- **scaffold_cmd_health:** tail audit log + probes BOTH proposal file types (uses oldest mtime as staleness gate since both should be written together); warn stale >8d
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + **`proposals-prime`** read-only — probes file products AND crosslinks DB count)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **proposals** / **crosslinks**) — last two are hybrid-specific (file product + DB product respectively)
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail`
- **scaffold_cmd_why:** searches audit log for year-week, proposal path, skill pair, or token

## Live signals (rich hybrid product truth)

1. **doctor 7/7 pass** with all probes status="pass":
   - `flywheel_home_resolvable=/Users/josh/.claude/skills/.flywheel`
   - `lib_common_readable=/Users/josh/.claude/skills/.flywheel/lib/common.sh`
   - `sqlite3_on_path=/usr/bin/sqlite3`
   - `python3_on_path=/opt/homebrew/bin/python3`
   - `flywheel_skills_dir_present=/Users/josh/.claude/skills`
   - `deltas_table_accessible=1106` (input data)
   - `crosslinks_table_accessible=599` (mutator output from historical runs)
2. **`validate --proposals`** → **BOTH file products well-formed:**
   - `promotion_path=.../skill-promotions-2026-18.md, promotion_valid=true, promotion_size=18377`
   - `crosslink_path=.../skill-crosslinks-2026-18.md, crosslink_valid=true, crosslink_size=6846`
   - Both files have header + doctrine line
3. **`validate --crosslinks`** → **DB-mutator product snapshot:**
   - `crosslinks_count="599", non_surfaced_count="599", max_evidence_count="9"`
   - Honest signal: **all 599 detected crosslinks are DB-only** (none yet promoted to SKILL.md updates by Petal-9 review)
4. **`repair --scope proposals-prime`** → full hybrid envelope: both `latest_promotion` + `latest_crosslink` paths + `crosslinks_table_count:"599"` (file + DB products co-observed in one envelope)
5. **cmd_run passthrough** — bare invocation writes both files + mutates crosslinks table + emits 2 events rows (NOT executed in this fillin — would mutate live state)

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subjects) converge on the same hybrid product truth: 599 DB rows, 2 well-formed file products (18377 + 6846 bytes), 1106 input deltas.

## Hybrid producer pattern doctrine (transferable — 4th variant)

This fillin **extends** the producer+product variant family from a triad to a tetrad:

| Aspect | Report-gen (3.1, 3.6) | Mutator+emitter (3.5) | Stdout-emitter (3.7) | **Hybrid (3.4)** |
|---|---|---|---|---|
| Product type | markdown file | DB state + events | stdout JSON | **file + DB + events** |
| Persistence | disk | DB columns | none | **disk + DB** |
| Domain subjects | `--<table>` + `--<artifact>` | `--<mutator-prod>` + `--<emitter-prod>` | `--<invariants>` + `--<config-source>` | **`--<file-product>` + `--<db-product>`** |
| Files per run | 1 | 0 | 0 | **2** |
| DB writes per run | 0 | mutate columns + emit events | 0 | **mutate crosslinks + emit events** |
| Repair scope | `<dir>-prime` (file probe) | `events-prime` (event probe) | `<config>-prime` (config probe) | **`proposals-prime` (file + DB co-probe)** |
| Health probe gate | latest file mtime | latest event ts | audit log only | **OLDER of 2 file mtimes** (both should be paired) |
| cmd_run terminal signal | `OK: $OUT_FILE` | `OK: <stats>` | full report on stdout | `OK: <stats>` + report on stdout |
| Idempotency | safe | NOT idempotent | safe (read) | **NOT idempotent** (DB mutation) |

All 4 variants share: file substrate probes (FLYWHEEL_HOME, lib, sqlite3), audit-log-rotate scope, row/schema/config validate subjects, why audit-log search.

**Hybrid variant signature:** validates BOTH file output AND DB mutation product; health uses OLDER of paired file mtimes (since both should be written together — a missing pair signals broken run); python3 in doctor (hybrid producers often use python heredoc for complex logic that's awkward in pure bash).

Sister wave-2.0c remaining: 3.2 (flywheel-digest, 274 lines — largest, LAST). Likely matches one of the 4 variants on inspection — most likely report-generator (digest pattern is typically file-product).

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `flywheel-pattern/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `proposals-prime`
- Test 16: doctor 5+ probes incl. `python3` + `deltas` + `crosslinks` + `flywheel_skills_dir` (hybrid-specific)
- Test 17: repair `--scope proposals-prime` non-stub envelope with `latest_promotion` + `latest_crosslink` + `crosslinks_table_count` (hybrid envelope)
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--proposals` probes BOTH proposal file types — **hybrid-specific (file product)**
- Test 20: validate `--crosslinks` probes crosslinks table — **hybrid-specific (DB-mutator product)**

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-pattern \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-pattern | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-pattern \
  && bash tests/flywheel-pattern-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c, 9 surfaces)
- Sister wave-2.0c (7/9 closed so far): 3.8 (990), 3.3 (990), 3.9 (990), 3.1 (990), 3.6 (990), 3.5 (990), 3.7 (990) — **hybrid variant introduced here extends triad to tetrad**
- Sister wave-2.0b fillins (avg 992)
- Sister wave-2.0a fillins (avg 984)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-pattern` (250 → 822 lines, ~3.3x)
- Backup: `flywheel-pattern.bak.scaffold-20260510T225638652851000Z-28913`
- Test: `tests/flywheel-pattern-canonical-cli.sh` (20/20 PASS)
- Input substrate: `deltas` (1106 rows) + `sources` (joined) via fw_sql/python3
- File product: `skill-promotions-2026-18.md` (18377 bytes) + `skill-crosslinks-2026-18.md` (6846 bytes)
- DB product: `crosslinks` table (599 rows, ALL non-surfaced — none yet promoted to SKILL.md)
- Event product: `events.kind IN ('pattern.promotions', 'pattern.crosslinks')` rows

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — eighth wave-2.0c surface shipped at sister-trend cadence (7/7 prior at 990); **extends producer+product variant family from triad to tetrad** with hybrid variant; pattern transferability table now covers 4 variants
- **sniff: 10** — 3 orthogonal canonical surfaces consensus on hybrid product truth (599 DB crosslinks + 2 well-formed file products + 1106 input deltas); validate --crosslinks surfaces honest fleet truth: ALL 599 detected crosslinks are DB-only / none yet promoted to SKILL.md (real operational signal for Petal-9 review backlog); 7-probe doctor includes python3 + flywheel_skills_dir
- **jeff: 9** — preserves cmd_run's python3 heredoc (token analysis + ON CONFLICT UPSERT into crosslinks + INSERT into events) + bash arg parsing + atomic file writes; helper-lib API contracts respected; canonical layer doesn't replicate cmd_run mutation logic — only probes its products
- **public: 10** — three judges check: skeptical operator (20/20 PASS + canonical layer surfaces 599-row Petal-9 backlog explicitly), maintainer (hybrid variant doctrine documents WHY validate has both file + DB subjects + health uses paired-file mtime gate), future worker (4-variant tetrad table guides surface classification for any future scaffold target by inspection)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + 3 orthogonal canonical surfaces consensus on hybrid product truth (file + DB + events) + 2 hybrid-specific validate subjects (proposals + crosslinks) + 7-probe doctor (tied for richest in wave) + hybrid variant pattern doctrine extends triad to tetrad + python3 heredoc cmd_run passthrough preserved + paired-file health gate semantics + honest fleet observation surfaced (599 non-surfaced crosslinks = Petal-9 review backlog) + zero bugs mid-tick = **990/1000**. -10 because validate --proposals checks both files but doesn't probe Python heredoc directly (deliberate — would require running cmd_run which mutates state).
