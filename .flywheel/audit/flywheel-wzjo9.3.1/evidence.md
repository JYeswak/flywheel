---
title: flywheel-wzjo9.3.1 evidence — flywheel-cass-correlate canonical-CLI fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.1
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0c 3/9 closed avg 990 (wzjo9.3.8 + 3.3 + 3.9)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-a
---

# flywheel-wzjo9.3.1 evidence

**Status:** DONE — flywheel-cass-correlate canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. Fourth wave-2.0c surface (127 → 648 lines, ~5.1x). cmd_run weekly-report passthrough preserved.

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
| Lines | 127 | 648 |
| Expansion | — | ~5.1x |
| Magic comment | absent | present |

## Substantive fillin

flywheel-cass-correlate is a weekly **skill-freshness × success-rate correlation** report generator. It JOINs flywheel's `outcomes` table against `sources.last_ok_at` (max per skill), buckets into fresh (<7d) / medium (7-30d) / stale (>30d), and emits a markdown report at `reports/freshness-correlation-YYYY-WW.md`. Canonical scaffold adds 8 introspection surfaces over the existing cmd_run.

The fillin gives the cass-correlate domain **3 orthogonal canonical surfaces** that observe the same underlying state:

1. **`doctor`** — probes substrate the cmd_run depends on (FLYWHEEL_HOME, lib/common.sh, sqlite3, outcomes table live count, reports dir)
2. **`repair --scope reports-prime`** — read-only probe of reports dir + latest freshness-correlation report path + report count
3. **`validate --report`** — probes the SAME latest report for structural integrity (header / methodology / table-header / size)

### Substrate probes (doctor — 5 named)

| Probe | Description |
|---|---|
| `flywheel_home_resolvable` | `$(dirname $0)/..` resolves to skill dir (returns abs path as `.value`) |
| `lib_common_readable` | `$FLYWHEEL_HOME/lib/common.sh` for `fw_sql`/`fw_event` (returns abs path) |
| `sqlite3_on_path` | required for `fw_sql` to execute (returns abs path) |
| `outcomes_table_accessible` | live `SELECT COUNT(*) FROM outcomes` via `fw_sql` (returns count as `.value`) |
| `reports_dir_writable` | `$FLYWHEEL_HOME/reports/` writable for weekly report emit |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas for doctor/health/repair/validate/audit/why/audit-row
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes (4 with live `.value` field, including 1779-row outcomes count)
- **scaffold_cmd_health:** tail audit log + report-mtime probe; warn stale >8d (weekly cadence threshold)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + `reports-prime` read-only)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **outcomes** / **report**) — last two are cass-correlate-specific
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail` (b9dfv positional order)
- **scaffold_cmd_why:** searches audit log for matching year-week, report path, or skill name (found/not_found/unavailable)

## Live signals (all green — substrate healthy + correlation report fresh)

1. **doctor 5/5 pass** with all probes status="pass":
   - `flywheel_home_resolvable=/Users/josh/.claude/skills/.flywheel`
   - `lib_common_readable=/Users/josh/.claude/skills/.flywheel/lib/common.sh`
   - `sqlite3_on_path=/usr/bin/sqlite3`
   - `outcomes_table_accessible=1779` (live row count from fw_sql)
   - `reports_dir_writable=/Users/josh/.claude/skills/.flywheel/reports`
2. **`repair --scope reports-prime`** → `status:pass, reports_dir_present:true, latest_report:".../freshness-correlation-2026-18.md", report_count:1`
3. **`validate --outcomes`** → `status:pass, outcomes_count:"1779", sources_count:"1268", outcomes_table_accessible:true, sources_table_accessible:true`
4. **`validate --report`** → `status:pass, valid:true, report_path:".../freshness-correlation-2026-18.md", has_header:true, has_methodology:true, has_table_header:true, size_bytes:1057`
5. **cmd_run passthrough** — bare invocation writes weekly report + emits `fw_event cass_correlate.run` + prints `OK: <path>` (original behavior preserved)

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subject) all converge on the same substrate: report present, outcomes table healthy with 1779 rows, sources table healthy with 1268 rows. Real fleet data flowing through the correlation pipeline.

## Cass-correlate-specific subjects

`outcomes` and `report` are domain-specific subjects unique to this surface class:

- **`validate --outcomes`** probes the actual data tables the cmd_run depends on (`outcomes` + `sources`) via `fw_sql`. Returns live row counts. This is the **data-substrate probe** distinct from the file-substrate probes in `config`.
- **`validate --report`** probes the **artifact** the cmd_run produces (the markdown report). Checks structural shape (3 grep predicates: `# Flywheel — Skill-Freshness × Success Correlation` header, `## Methodology` section, `| Bucket | n | successes` table header) + size. Verifies the report is well-formed for operator consumption.

This is the **producer + product** pattern: cmd_run *produces* a report from the data substrate; canonical layer probes both the substrate AND the product. Transferable to other report-generator surfaces (digest, quality-gate, etc.).

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `flywheel-cass-correlate/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `reports-prime`
- Test 16: doctor 5+ probes incl. `flywheel_home_resolvable` + `sqlite3_on_path` + `outcomes_table_accessible` + `reports_dir_writable` (4 named, cass-correlate-specific)
- Test 17: repair `--scope reports-prime` non-stub envelope with `reports_dir` + `latest_report` + `reports_dir_present`
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--outcomes` probes outcomes + sources tables — **cass-correlate-specific subject**
- Test 20: validate `--report` probes freshness-correlation report shape — **cass-correlate-specific subject**

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-cass-correlate \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-cass-correlate | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-cass-correlate \
  && bash tests/flywheel-cass-correlate-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Producer + product pattern doctrine (transferable)

This fillin establishes the canonical pattern for **report-generator surfaces** in the flywheel ecosystem:

1. **Compute local FLYWHEEL_HOME independently** — `$(dirname $0)/..` to match cmd_run's `HERE=...; FLYWHEEL_HOME=...` resolution (do NOT rely on `_SCAFFOLD_REPO_ROOT` for skill bin scripts; lesson learned from wzjo9.3.3 thin-wrapper)
2. **Substrate probes split into data + file dimensions** — doctor probes both filesystem (FLYWHEEL_HOME, lib/common.sh, reports dir) AND data layer (outcomes table via fw_sql) for honest substrate snapshot
3. **Validate exposes BOTH layers** — `--config` (file substrate) + `--outcomes` (data substrate via SQL) + `--report` (product artifact shape)
4. **Repair `reports-prime` is read-only** — observational scope that catalogs reports without mutation (operator orientation)
5. **cmd_run preserves report emit + fw_event** — the original `OK: <path>` line on bare invocation still works for cron / launchd consumers

Sister report-generator surfaces in wave-2.0c (flywheel-digest, flywheel-quality, flywheel-stale, flywheel-pattern) will likely adopt this same producer+product probe pattern.

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c, 9 surfaces)
- Sister wave-2.0c (3/9 closed so far): wzjo9.3.8 (closed 990, version-check), wzjo9.3.3 (closed 990, thin-wrapper), wzjo9.3.9 (closed 990, callback-validator)
- Sister wave-2.0b fillins (avg 992)
- Sister wave-2.0a fillins (avg 984)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-cass-correlate` (127 → 648 lines, ~5.1x)
- Backup: `flywheel-cass-correlate.bak.scaffold-20260510T223507250452000Z-33121`
- Test: `tests/flywheel-cass-correlate-canonical-cli.sh` (20/20 PASS)
- Data substrate: `outcomes` (1779 rows) + `sources` (1268 rows) tables via `fw_sql`
- Product substrate: `freshness-correlation-2026-18.md` (1057 bytes)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — fourth wave-2.0c surface shipped at sister-trend cadence (3.8 + 3.3 + 3.9 all 990); first **report-generator class** in any wave; producer + product pattern doctrine documented for transfer
- **sniff: 10** — 3 orthogonal canonical surfaces converge with consensus on substrate state (1779 outcomes / 1268 sources / report present + well-formed); the `--outcomes` and `--report` cass-correlate-specific subjects expose distinct domain layers (data vs product); cmd_run weekly-report passthrough verified preserved
- **jeff: 9** — preserves cmd_run's heredoc-based SQL + fw_event emit + report write semantics; helper-lib API contracts respected; local FLYWHEEL_HOME pattern from wzjo9.3.3 reused (transferable doctrine)
- **public: 10** — three judges check: skeptical operator (20/20 PASS + 3 canonical surfaces report-consensus on real 1779-row outcomes data), maintainer (producer + product pattern is reusable across other report-generators), future worker (the data+file substrate split in doctor + 5-subject validate is concrete + has live signals demonstrating the pattern works against real fleet data)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + 3 orthogonal canonical surfaces consensus (doctor + repair + validate) + 2 cass-correlate-specific validate subjects (outcomes + report) + producer + product pattern doctrine documented + cmd_run weekly-report passthrough preserved + live signals against real 1779-row outcomes data = **990/1000**. -10 because no cli_audit_append wired into cmd_run terminal envelope (the original wrapper's `echo "OK: $OUT"` is the terminal signal; adding audit row would require small refactor — deferred as deliberate design choice consistent with sister-wave decisions).
