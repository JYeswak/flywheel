# Evidence: flywheel-1hshd.24 — customer-facing-observability-probe.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.24 (P2, wave-4-general-24)
**Task ID**: flywheel-1hshd.24-0d0a8a
**Identity**: MistyCliff
**Started**: 2026-05-11T05:13:49Z
**Closed**: 2026-05-11T05:18Z
**Surface**: `.flywheel/scripts/customer-facing-observability-probe.sh`
**Variant**: NUANCED-PARTIAL-BYPASS (scaffold-verb-first refinement)

## Per-flag baseline probe

| Flag/verb        | Native pre-scaffold? | Owner after scaffold | Bypass class                                |
|------------------|----------------------|----------------------|---------------------------------------------|
| --info           | yes (mode=info)      | NATIVE               | bypass                                      |
| --schema         | yes (mode=schema)    | NATIVE               | bypass                                      |
| --doctor (flag)  | yes (mode=doctor)    | NATIVE               | bypass when no scaffold verb at args[0]     |
| --examples       | no                   | SCAFFOLD             | scaffold owns                               |
| doctor (verb)    | no                   | SCAFFOLD             | scaffold verb-first                         |
| health           | no                   | SCAFFOLD             | scaffold owns                               |
| repair           | no                   | SCAFFOLD             | scaffold owns; --apply/--dry-run mean per-verb here |
| validate         | no                   | SCAFFOLD             | scaffold owns                               |
| audit            | no                   | SCAFFOLD             | scaffold owns                               |
| why              | no                   | SCAFFOLD             | scaffold owns                               |
| quickstart       | no                   | SCAFFOLD             | scaffold owns                               |
| help <topic>     | no                   | SCAFFOLD             | scaffold owns                               |

**Refinement note**: scaffold-verb-first ordering applied because native script uses `--apply`/`--dry-run` as top-level flags for the run verb, but scaffold's `repair` also accepts them. Without verb-first, `repair --apply --json` was bypassed to native and treated as unknown arg.

## Fillin completeness

- TODO markers remaining: **0**
- 8 stubs filled: scaffold_emit_schema (7 surfaces), scaffold_emit_topic_help (per-topic), scaffold_cmd_doctor (6 probes), scaffold_cmd_health (binds audit log + freshness budget), scaffold_cmd_repair (2 scopes + apply contract), scaffold_cmd_validate (3 subjects incl observability-state full enum), scaffold_cmd_audit (cli_emit_audit_tail), scaffold_cmd_why (4-key match)
- Plus _scaffold_is_canonical_arg (NUANCED-PARTIAL-BYPASS verb-first variant)

## Doctor probes (6 total)

| Check                       | Probe                                       | Load-bearing? |
|-----------------------------|---------------------------------------------|---------------|
| bash_available              | command -v bash                             | yes           |
| jq_available                | command -v jq                               | yes           |
| dev_root_exists             | -d $CUSTOMER_OBS_DEV_ROOT (default /Users/josh/Developer) | yes (client/product repos resolve here) |
| ledger_dir_writable         | -w dirname($CUSTOMER_OBS_LEDGER)            | yes           |
| audit_log_dir_writable      | -w dirname($SCAFFOLD_AUDIT_LOG)             | yes           |
| client_repos_resolvable     | -d under dev_root for {alpsinsurance, blackfoot, terratitle} | yes (3 canonical clients) |
| product_repos_resolvable    | -d under dev_root for {zesttube, mobile-eats} | yes |

## Repair scopes (2 total)

| Scope          | Target                              | Action            |
|----------------|-------------------------------------|-------------------|
| ledger_dir     | dirname($CUSTOMER_OBS_LEDGER)       | mkdir -p          |
| audit_log_dir  | dirname($SCAFFOLD_AUDIT_LOG)        | mkdir -p          |

Apply contract: `--apply` requires `--idempotency-key` (rc=3 refusal). Unknown scope = rc=64.

## Validate subjects (3 total)

| Subject              | Contract                                                  | Cross-source                                |
|----------------------|-----------------------------------------------------------|---------------------------------------------|
| client-slug          | enum {alpsinsurance, blackfoot, terratitle, zesttube, mobile-eats} | CLIENT_SLUGS + PRODUCT_SLUGS arrays |
| freshness-hours      | integer in [1, 720]; default 72                           | $CUSTOMER_OBS_FRESHNESS_HOURS env contract  |
| observability-state  | enum {no_aggregation_pipeline_yet, draft, wired}          | **--schema .customer_observability_state_enum (3 states)** |

Observability-state full-enum sweep test (test 15) covers all 3 states + 1 invalid; cross-source consistency with `--schema .customer_observability_state_enum`.

## Test coverage

- Pre-fillin: 13/13 PASS (canonical scaffold baseline)
- Post-fillin: **19/19 PASS** (6 fillin assertions added)
- Calibrated: tests 2/3 (native `.mode` shape); test 7 (real scope `ledger_dir`); test 9 (bare-validate rc=64 + `missing_subject`)
- Added (fillin):
  - 14: doctor probes dev_root + ledger + per-client/product repos
  - 15: observability-state full-enum sweep (3 accept + 1 reject)
  - 16: validate client-slug accepts canonical (alpsinsurance)
  - 17: validate client-slug rejects non-canonical
  - 18: validate freshness-hours accepts default 72
  - 19: 4-direction fidelity (NUANCED-PARTIAL-BYPASS verb-first variant)

## Lint

- `canonical-cli-lint.sh`: clean
- Lint-idiom-fix applied: `set -euo pipefail; set +e` two-line idiom (4th recurrence this session)

## Smoke captures

20 surfaces captured under `.flywheel/audit/flywheel-1hshd.24/smoke-*.{json,txt}`.

## Mission fitness

`adjacent` — substrate work for canonical-CLI fleet rollout. Customer-facing-observability-probe is value-gap dimension #3; uniform machine-readable surfaces (doctor/health/repair/validate/audit/why) let future automation probe + recover the per-client/product observability state without reading source.

## Files changed

- `.flywheel/scripts/customer-facing-observability-probe.sh` (308 → ~700 lines; 18 stubs filled; lint-idiom-fix)
- `tests/customer-facing-observability-probe-canonical-cli.sh` (94 → ~155 lines; tests 2/3/7/9 calibrated, 6 fillin tests added)

## L112 verify probe

`bash tests/customer-facing-observability-probe-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`

