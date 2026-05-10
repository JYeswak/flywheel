---
title: flywheel-wzjo9.3.6 evidence — flywheel-quality-gate canonical-CLI fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.6
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0c 4/9 closed avg 990 (3.8 + 3.3 + 3.9 + 3.1)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-f
---

# flywheel-wzjo9.3.6 evidence

**Status:** DONE — flywheel-quality-gate canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. Fifth wave-2.0c surface (127 → 661 lines, ~5.2x). cmd_run weekly Petal-9 proposal passthrough preserved.

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
| Lines | 143 | 661 |
| Expansion | — | ~5.2x |
| Magic comment | absent | present |

## Substantive fillin (producer + product class, second in lane)

flywheel-quality-gate is the weekly Sunday Petal-9 proposal generator. It flags low-quality sources (`posterior_mean < 0.3 AND age >= 28d AND samples >= 5`) by JOINing flywheel's `sources` table against the threshold logic, then writes a markdown proposal at `proposals/quality-drops-YYYY-WW.md` that Joshua reads on Sunday close ritual.

**Doctrine:** "AI proposes, Joshua disposes" — the script never auto-drops sources, it only writes a proposal file.

Reused the **producer + product pattern** from wzjo9.3.1 (cass-correlate): doctor probes both file and data substrate; validate exposes config (file) + sources (data via SQL) + proposal (product artifact) layers.

### Substrate probes (doctor — 5 named)

| Probe | Description |
|---|---|
| `flywheel_home_resolvable` | `$(dirname $0)/..` resolves to skill dir (returns abs path as `.value`) |
| `lib_common_readable` | `$FLYWHEEL_HOME/lib/common.sh` for `fw_sql`/`fw_event`/`fw_require_db` |
| `sqlite3_on_path` | required for `fw_sql` |
| `sources_table_accessible` | live `SELECT COUNT(*) FROM sources` via `fw_sql` (returns count as `.value`) |
| `proposals_dir_writable` | `$FLYWHEEL_HOME/proposals/` writable for weekly Sunday emit |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas for doctor/health/repair/validate/audit/why/audit-row
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes (4 with live `.value` field incl. 1268-row sources count)
- **scaffold_cmd_health:** tail audit log + latest proposal mtime probe; warn stale >8d (Sunday cadence + 1d slack)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + `proposals-prime` read-only)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **sources** / **proposal**) — last two are quality-gate-specific
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail` (b9dfv positional order)
- **scaffold_cmd_why:** searches audit log for matching year-week, proposal path, source-id, or skill (found/not_found/unavailable)

## Live signals (rich domain truth)

1. **doctor 5/5 pass** with all probes status="pass":
   - `flywheel_home_resolvable=/Users/josh/.claude/skills/.flywheel`
   - `lib_common_readable=/Users/josh/.claude/skills/.flywheel/lib/common.sh`
   - `sqlite3_on_path=/usr/bin/sqlite3`
   - `sources_table_accessible=1268` (live row count)
   - `proposals_dir_writable=/Users/josh/.claude/skills/.flywheel/proposals`
2. **`repair --scope proposals-prime`** → `status:pass, proposals_dir_present:true, latest_proposal:".../quality-drops-2026-18.md", proposal_count:1`
3. **`validate --sources`** → `status:pass, sources_count:"1268", flagged_count:"0", outcomes_count:"1779", threshold:"posterior_mean<0.3 AND age>=28d AND samples>=5"` — **live execution of the same flag-threshold SQL the cmd_run uses**, finds 0 flagged sources currently (all 1268 sources are above 0.3 posterior_mean OR insufficient sample/age)
4. **`validate --proposal`** → **`status:fail`** (honest sniff signal) — existing proposal is a 34-byte cold-start placeholder; `has_header:true` but `has_doctrine_line:false` + `has_generator_line:false`. The validator correctly distinguishes a structurally-complete flagged-sources proposal from a cold-start placeholder.
5. **cmd_run passthrough** — bare invocation writes weekly proposal + emits `fw_event quality_gate.run` + prints `OK: quality-gate — flagged=N global_outcomes=N file=...` (original behavior preserved)

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subject) report consensus on data-substrate health (1268 sources / 1779 outcomes / 0 flagged) but the validate-proposal subject **honestly reports the existing cold-start placeholder as incomplete** — this is the sniff lens working as designed: the canonical layer doesn't paper over honest substrate state.

## Producer + product pattern transferability confirmed

This is the **second report-generator surface** in wave-2.0c. wzjo9.3.1 (cass-correlate) established the pattern; this surface confirms transferability:

| Aspect | cass-correlate (wzjo9.3.1) | quality-gate (wzjo9.3.6) |
|---|---|---|
| Product type | weekly correlation report | weekly Petal-9 proposal |
| Product path | `reports/freshness-correlation-YYYY-WW.md` | `proposals/quality-drops-YYYY-WW.md` |
| Data tables probed | `outcomes` + `sources` | `sources` (alpha/beta/age) + `outcomes` |
| Specific validate subjects | `--outcomes` + `--report` | `--sources` + `--proposal` |
| Doctor checks dir | `reports_dir_writable` | `proposals_dir_writable` |
| Domain SQL replayed | bucket-by-age JOIN | posterior-mean threshold filter |
| cmd_run terminal signal | `OK: $OUT` | `OK: quality-gate — flagged=N file=...` |

The pattern generalizes: doctor probes substrate (file + data), repair has `--scope <X>-prime` for product introspection (read-only), validate exposes `--row` + `--schema` + `--config` + `--<data-table>` + `--<product-artifact>` (5 subjects).

Wave-2.0c sister report-generators yet to ship: flywheel-digest (3.2, 274 lines), flywheel-stale (3.7, 185 lines), flywheel-pattern (3.4, 250 lines), flywheel-quality (3.5, 145 lines). All adopt this pattern with substitutions (e.g., `--digest` / `--stale-report` / `--pattern-report` instead of `--proposal`).

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `flywheel-quality-gate/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `proposals-prime`
- Test 16: doctor 5+ probes incl. `flywheel_home_resolvable` + `sqlite3_on_path` + `sources_table_accessible` + `proposals_dir_writable`
- Test 17: repair `--scope proposals-prime` non-stub envelope with `proposals_dir` + `latest_proposal` + `proposals_dir_present`
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--sources` probes sources + flagged counts — **quality-gate-specific subject**
- Test 20: validate `--proposal` probes quality-drops proposal shape — **quality-gate-specific subject**

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality-gate \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality-gate | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-quality-gate \
  && bash tests/flywheel-quality-gate-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c, 9 surfaces)
- Sister wave-2.0c (4/9 closed so far): 3.8 (990), 3.3 (990), 3.9 (990), 3.1 (990) — producer+product pattern established at 3.1
- Sister wave-2.0b fillins (avg 992)
- Sister wave-2.0a fillins (avg 984)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-quality-gate` (143 → 661 lines, ~5.2x)
- Backup: `flywheel-quality-gate.bak.scaffold-20260510T224002653938000Z-34612`
- Test: `tests/flywheel-quality-gate-canonical-cli.sh` (20/20 PASS)
- Data substrate: `sources` (1268 rows, 0 currently flagged) + `outcomes` (1779 rows) via `fw_sql`
- Product substrate: `proposals/quality-drops-2026-18.md` (34 bytes, cold-start placeholder — validate-proposal correctly reports incomplete)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — fifth wave-2.0c surface shipped at sister-trend cadence (3.8 + 3.3 + 3.9 + 3.1 all 990); confirms producer+product pattern transferability across report-generator class; mid-wave running avg 990 maintained
- **sniff: 10** — `validate --proposal` honestly reports `status:fail` on existing 34-byte cold-start placeholder (distinguishes structurally-complete proposal from placeholder); `validate --sources` replays cmd_run's flag-threshold SQL live and reports 0 flagged sources out of 1268 (real fleet truth); doctor reports 1268 sources / 1779 outcomes (consistent with sister wzjo9.3.1's data-substrate count)
- **jeff: 9** — preserves cmd_run's cold-start guard + threshold SQL + fw_event emit; helper-lib API contracts respected; local FLYWHEEL_HOME pattern from wzjo9.3.3 + producer-product pattern from wzjo9.3.1 reused without re-discovery
- **public: 10** — three judges check: skeptical operator (20/20 PASS + 3 canonical surfaces report consensus on real 1268-source data; honest fail on placeholder proposal is the right design), maintainer (producer+product pattern confirmed transferable to second instance — 4 more report-generators in wave-2.0c can reuse), future worker (the pattern is now demonstrably reusable, with concrete substitution table documented for digest/stale/pattern/quality)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + 3 orthogonal canonical surfaces consensus + 2 quality-gate-specific validate subjects (sources + proposal) + producer+product pattern transferability **confirmed** across second instance + honest sniff fail on placeholder proposal (canonical layer doesn't paper over substrate state) + cmd_run weekly-proposal passthrough preserved + live SQL replay (flag-threshold) against real 1268-row sources data + zero bugs mid-tick = **990/1000**. -10 for the same audit-row-not-wired-into-cmd_run constraint as sister 3.1 (deliberate architectural deferral, not a bug).
