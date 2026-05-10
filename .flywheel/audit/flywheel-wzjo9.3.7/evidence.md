---
title: flywheel-wzjo9.3.7 evidence — flywheel-stale canonical-CLI fillin (stdout-emitter variant)
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.7
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0c 6/9 closed avg 990 (3.8 + 3.3 + 3.9 + 3.1 + 3.6 + 3.5)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-g
---

# flywheel-wzjo9.3.7 evidence

**Status:** DONE — flywheel-stale canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. Seventh wave-2.0c surface (185 → 728 lines, ~3.9x). **Stdout-emitter variant** — third producer+product pattern variant in wave (after report-generator @ 3.1+3.6 and mutator+emitter @ 3.5).

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
| Lines | 185 | 728 |
| Expansion | — | ~3.9x |
| Magic comment | absent | present |

## Substantive fillin (stdout-emitter — third variant)

flywheel-stale is a **stdout-emitter** surface. It emits a 7-category stale-knowledge invariants report to stdout (text default, `--json` for machine-parseable). **No persistent product** — no file artifact like 3.1/3.6, no DB mutation like 3.5. The "product" is the stdout JSON envelope itself.

The 7 invariant categories cmd_run probes:
1. `sources_no_latest` — skill has data/sources.txt but no LATEST.md
2. `latest_older_14d` — LATEST.md older than 14 days
3. `sources_fail_streak_3` — source rows with fail_streak >= 3 (DB)
4. `skill_zero_deltas` — skill has sources rows but never produced a delta (DB)
5. `deltas_unsurfaced_7d` — deltas created but never surfaced for 7+ days (DB)
6. `description_oversized` — SKILL.md frontmatter description >1536 chars (FS)
7. `body_oversized` — SKILL.md TOTAL body >10000 bytes (FS)

The canonical `validate --invariants` subject replays the 3 DB-backed categories (the FS-scan categories would require re-implementing most of cmd_run's logic — kept the canonical subject focused on the cheap-to-replay subset).

### Substrate probes (doctor — 7 named)

| Probe | Description |
|---|---|
| `flywheel_home_resolvable` | `$(dirname $0)/..` resolves to skill dir |
| `lib_common_readable` | `$FLYWHEEL_HOME/lib/common.sh` for `fw_sql`/`fw_require_db` |
| `sqlite3_on_path` | required for `fw_sql` |
| `bash_version_4_plus` | **stdout-emitter-specific** — `declare -A` for JSM associative array (returns BASH_VERSION as `.value`) |
| `flywheel_skills_dir_present` | **stdout-emitter-specific** — FS scan source for skill dirs |
| `sources_table_accessible` | live `SELECT COUNT(*) FROM sources` (returns count) |
| `deltas_table_accessible` | live `SELECT COUNT(*) FROM deltas` (returns count) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** **7 substrate probes** (now richest in wave; 4 with live `.value` field)
- **scaffold_cmd_health:** tail audit log; warn stale >24h (no product to probe — stdout-emitter has no persistent artifact)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + `jsm-list-prime` read-only — probes JSM exclusion list shape)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **invariants** / **jsm-list**) — last two are stdout-emitter-specific
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail`
- **scaffold_cmd_why:** searches audit log for skill name, invariant category, or delta-id

## Live signals — homology with cmd_run verified

1. **doctor 7/7 pass** with all probes status="pass":
   - `flywheel_home_resolvable=/Users/josh/.claude/skills/.flywheel`
   - `lib_common_readable=/Users/josh/.claude/skills/.flywheel/lib/common.sh`
   - `sqlite3_on_path=/usr/bin/sqlite3`
   - `bash_version_4_plus=5.3.9(1)-release`
   - `flywheel_skills_dir_present=/Users/josh/.claude/skills`
   - `sources_table_accessible=1268`
   - `deltas_table_accessible=1106`
2. **`validate --invariants`** → **identical DB-category counts to cmd_run:**
   - `sources_fail_streak_3="2"` (canonical) ↔ `sources_fail_streak_3:2` (cmd_run --json)
   - `skill_zero_deltas="0"` (canonical) ↔ `skill_zero_deltas:0` (cmd_run --json)
   - `deltas_unsurfaced_7d="0"` (canonical) ↔ `deltas_unsurfaced_7d:0` (cmd_run --json)
3. **`validate --jsm-list`** → `jsm_count:87` (87 JSM-managed skills excluded from FS scan)
4. **`repair --scope jsm-list-prime`** → `jsm_list_present:true, jsm_list_count:87, sample_skills:"..."` (read-only probe with sample)
5. **cmd_run `--json` (full 7-category report)** preserved — bare invocation emits stdout JSON envelope with all 7 invariant categories: 2 fail_streak, 0 zero_deltas, 0 unsurfaced, 1 sources_no_latest, 0 latest_older_14d, 0 description_oversized, **174 body_oversized**

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subject) all converge on the same fleet truth: substrate healthy + 2 active fail_streak sources + 87 JSM-excluded skills. **The canonical `validate --invariants` matches the cmd_run `--json` output exactly on DB-backed categories** — clean pattern homology between canonical layer and cmd_run domain logic.

## Stdout-emitter variant pattern doctrine (transferable)

This fillin completes the producer+product variant triad in wave-2.0c:

| Aspect | Report-generator (3.1, 3.6) | Mutator+emitter (3.5) | Stdout-emitter (3.7) |
|---|---|---|---|
| Product type | markdown file | DB column state + event rows | stdout JSON envelope |
| Product persistence | file on disk | DB state | none — stdout-only |
| Domain subjects | `--<table>` + `--<artifact-file>` | `--<mutator-product>` + `--<emitter-product>` | `--<invariants>` + `--<config-source>` |
| Concrete in fillins | `--outcomes`+`--report` (3.1); `--sources`+`--proposal` (3.6) | `--quality-distribution`+`--events` (3.5) | `--invariants`+`--jsm-list` (3.7) |
| Repair scope | `<dir>-prime` (probe file artifacts) | `events-prime` (probe emitted rows) | `<config-source>-prime` (probe config inputs) |
| Health probe | latest file mtime | latest event ts | audit log only (no product) |
| cmd_run terminal signal | `OK: $OUT_FILE` | `OK: <stats>` (no file) | full report on stdout (text or JSON) |
| Idempotency | safe to re-run | NOT idempotent | safe (pure read) |

All 3 variants share: file substrate probes (FLYWHEEL_HOME, lib, sqlite3), data substrate probes (table row counts), audit-log-rotate scope, row/schema/config validate subjects, why audit-log search.

Sister wave-2.0c remaining: 3.4 (flywheel-pattern, 250 lines), 3.2 (flywheel-digest, 274 lines — largest, last). Both likely variants of these patterns. 3.4 (pattern) probably stdout-emitter or report-generator; 3.2 (digest) likely report-generator with multiple input streams.

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `flywheel-stale/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `jsm-list-prime`
- Test 16: doctor 5+ probes incl. `bash_version_4_plus` + `flywheel_skills_dir_present` + `sources_table` + `deltas_table` (stdout-emitter-specific)
- Test 17: repair `--scope jsm-list-prime` non-stub envelope with `jsm_list_path` + `jsm_list_count` + `jsm_list_present`
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--invariants` replays cmd_run DB probes — **stdout-emitter-specific subject**
- Test 20: validate `--jsm-list` probes JSM exclusion list — **stdout-emitter-specific subject**

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-stale \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-stale | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-stale \
  && bash tests/flywheel-stale-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c, 9 surfaces)
- Sister wave-2.0c (6/9 closed so far): 3.8 (990), 3.3 (990), 3.9 (990), 3.1 (990), 3.6 (990), 3.5 (990) — **third pattern variant introduced here completes the triad**
- Sister wave-2.0b fillins (avg 992)
- Sister wave-2.0a fillins (avg 984)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-stale` (185 → 728 lines, ~3.9x)
- Backup: `flywheel-stale.bak.scaffold-20260510T225117351171000Z-36766`
- Test: `tests/flywheel-stale-canonical-cli.sh` (20/20 PASS)
- Data substrate: `sources` (1268 rows, 2 with fail_streak>=3) + `deltas` (1106 rows, 0 unsurfaced 7d+)
- Config substrate: `~/.claude/skills/.jsm-installed.txt` (87 JSM-managed skills excluded from FS scan)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — seventh wave-2.0c surface shipped at sister-trend cadence (6/6 prior at 990); **completes the producer+product variant triad** (report-generator + mutator+emitter + stdout-emitter); transferable doctrine documented for the final 2 surfaces (3.4 + 3.2)
- **sniff: 10** — doctor 7/7 pass (richest in wave); `validate --invariants` returns identical DB-category counts to cmd_run `--json` (`sources_fail_streak_3="2"` matches `sources_fail_streak_3:2` exactly — pattern homology verified live); 3 orthogonal canonical surfaces consensus on real fleet truth (87 JSM skills, 1268 sources, 1106 deltas, 2 active fail_streak)
- **jeff: 9** — preserves cmd_run's 7-category stdout JSON envelope + bash 4+ re-exec dependency + JSM exclusion list reading; helper-lib API contracts respected; canonical layer doesn't replace cmd_run's full report — it offers a cheaper canonical subset for substrate probing
- **public: 10** — three judges check: skeptical operator (20/20 PASS + 7-probe doctor + canonical-cmd_run consensus on DB categories), maintainer (3-variant transferability table covers all known surface classes in wave so far + each variant's repair-scope / health / idempotency semantics documented), future worker (the canonical `validate --invariants` cheaply replays cmd_run probes for substrate-state monitoring without running the full FS-scan — operationally useful pattern)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + 3 orthogonal canonical surfaces consensus on real fleet data (1268 sources, 1106 deltas, 2 fail_streak, 87 JSM exclusions) + 2 stdout-emitter-specific validate subjects (invariants + jsm-list) + 7-probe doctor (richest in wave) + **canonical-cmd_run DB-category homology verified live** + producer+product variant triad doctrine completed + cmd_run 7-category stdout passthrough preserved + zero bugs mid-tick (3 sister patterns now internalized) = **990/1000**. -10 because `validate --invariants` covers only 3 of 7 categories (deliberate scope choice — the FS-scan categories would require re-implementing most of cmd_run's logic; documented in the subject's `note` field).
