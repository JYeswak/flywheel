# Evidence: flywheel-1hshd.25 — docs-validation-probe.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.25 (P2, wave-4-general-25)
**Task ID**: flywheel-1hshd.25-7ca2da
**Identity**: MistyCliff
**Surface**: `.flywheel/scripts/docs-validation-probe.sh`
**Variant**: PARTIAL-BYPASS (scaffold-verb-first) — native owns --schema only (different shape: metadata_fields/output_fields, no .command field); scaffold owns --info, --examples, doctor/health/repair/validate/audit/why/quickstart/help.

## Per-flag baseline probe

| Flag/verb        | Native pre-scaffold? | Owner after scaffold | Bypass class                                |
|------------------|----------------------|----------------------|---------------------------------------------|
| --info           | NO (unknown arg)     | SCAFFOLD             | scaffold owns                               |
| --schema         | yes (different shape)| NATIVE               | PARTIAL-BYPASS to native                    |
| --doctor         | NO (unknown arg)     | SCAFFOLD via verb    | scaffold owns                               |
| --examples       | NO                   | SCAFFOLD             | scaffold owns                               |
| doctor (verb)    | NO                   | SCAFFOLD             | scaffold owns                               |
| health           | NO                   | SCAFFOLD             | scaffold owns                               |
| repair           | NO                   | SCAFFOLD             | scaffold owns                               |
| validate         | NO                   | SCAFFOLD             | scaffold owns                               |
| audit            | NO                   | SCAFFOLD             | scaffold owns                               |
| why              | NO                   | SCAFFOLD             | scaffold owns                               |
| quickstart       | NO                   | SCAFFOLD             | scaffold owns                               |
| help <topic>     | NO                   | SCAFFOLD             | scaffold owns                               |
| --self-test/--repo/--doc | yes (native flags) | NATIVE          | scaffold yields when no scaffold verb       |

## Fillin completeness

- TODO markers remaining: **0**
- 8 stubs filled: scaffold_emit_schema (7 surfaces), scaffold_emit_topic_help, scaffold_cmd_doctor (6 probes incl awk for field_value), scaffold_cmd_health (binds audit log), scaffold_cmd_repair (2 scopes), scaffold_cmd_validate (3 subjects), scaffold_cmd_audit, scaffold_cmd_why
- Plus _scaffold_is_canonical_arg (PARTIAL-BYPASS verb-first variant)

## Doctor probes (6 total)

| Check                       | Probe                                       | Load-bearing? |
|-----------------------------|---------------------------------------------|---------------|
| bash_available              | command -v bash                             | yes           |
| jq_available                | command -v jq                               | yes           |
| awk_available               | command -v awk                              | **yes** (field_value() metadata reader uses awk) |
| repo_root_resolvable        | -d $REPO                                    | yes           |
| default_docs_anchor         | -r {.flywheel/MISSION.md, STATE.md, README.md} | yes |
| audit_log_dir_writable      | -w dirname($SCAFFOLD_AUDIT_LOG)             | yes           |

## Repair scopes (2 total)

| Scope          | Target                                  | Action            |
|----------------|-----------------------------------------|-------------------|
| audit_log_dir  | dirname($SCAFFOLD_AUDIT_LOG)            | mkdir -p          |
| docs_anchor    | $REPO/.flywheel/                        | mkdir -p          |

## Validate subjects (3 total)

| Subject              | Contract                                                  | Cross-source                                |
|----------------------|-----------------------------------------------------------|---------------------------------------------|
| doc-path             | -r FILE                                                   | file_value() metadata reader                |
| validation-status    | enum {validated, pending, failed, self_validated}         | **native --schema .metadata_fields[0]**     |
| pane-name            | `^[a-z][a-z0-9_-]*$`                                      | validated_by_pane / authored_by_pane shape  |

Validation-status full-enum sweep test (test 15) covers all 4 states + 1 invalid; cross-source consistency with native `--schema .metadata_fields`.

## Test coverage

- Pre-fillin: 13/13 PASS
- Post-fillin: **19/19 PASS**
- Calibrated: test 3 (native PARTIAL-BYPASS shape — metadata_fields/output_fields); test 7 (real scope); test 9 (bare-validate rc=64)
- Added (fillin): doctor probes load-bearing tools; validation-status full-enum sweep; doc-path readable/unreadable; pane-name pattern; 4-direction fidelity

## Lint

- `canonical-cli-lint.sh`: clean (no lint-idiom-fix needed — script already had `set -euo pipefail`)

## Smoke captures

20 surfaces captured under `.flywheel/audit/flywheel-1hshd.25/smoke-*.{json,txt}`.

## Mission fitness

`adjacent` — docs-validation-probe surfaces docs validation metadata cross-pane (docs_validation_status / validated_by_pane / authored_by_pane). Uniform machine-readable scaffold surfaces let future automation aggregate per-doc validation status without re-implementing field_value() parsing.

## Files changed

- `.flywheel/scripts/docs-validation-probe.sh` (149 → ~600 lines)
- `tests/docs-validation-probe-canonical-cli.sh` (94 → ~155 lines)

## L112 verify probe

`bash tests/docs-validation-probe-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`

