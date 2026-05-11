# Evidence Pack — flywheel-1hshd.12

**Surface:** `.flywheel/scripts/check-trauma-class-substrate.sh`
**Bead:** flywheel-1hshd.12 — wave-4-general-12 partial → passing
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11

## What Shipped

WZJO9.1.7 **FULL-BYPASS** scaffold added to a read-only B56 trauma-class
scanner. Native had zero canonical surfaces; scaffold owns every canonical
verb + introspection flag. Original scanner behavior is preserved through
the early-dispatch intercept (`_scaffold_is_canonical_arg` → fall-through).

| Artifact | Before | After |
|---|---|---|
| `.flywheel/scripts/check-trauma-class-substrate.sh` | 273 lines, lint=2 warn | 737 lines, lint=clean |
| `tests/check-trauma-class-substrate-canonical-cli.sh` | absent | 26-test suite (PASS) |
| `tests/check-trauma-class-substrate-test.sh` (regression) | 14/14 PASS | 14/14 PASS (unchanged) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` row 48 | partial | passing |

## AG3 Strict Gates (per parent apply-spec)

| Gate | Command | Result |
|---|---|---|
| AG3.1 | `--info --json \| jq -e '.name and .version and .capabilities'` | PASS (`smoke-info.json`) |
| AG3.2 | `--schema --json \| jq -e '.input_schema and .output_schema'` | PASS (`smoke-schema.json`) |
| AG3.3 | `--examples --json \| jq -e '.examples \| length > 0'` | PASS (4 examples; `smoke-examples.json`) |
| AG3.4 | `doctor --json \| jq -e '.checks'` | PASS (7 named probes; `smoke-doctor.json`) |

## Per-Binary AG3 (parent), full canonical surface

| Surface | Coverage | Evidence |
|---|---|---|
| `--info` | name, version, schema_version, capabilities[7], paths, env_vars, mutates_state=false | `smoke-info.json` |
| `--schema` | input_schema, output_schema, surfaces[7] | `smoke-schema.json` |
| `--examples` | 4 examples (default scan, doctor, validate, repair) | `smoke-examples.json` |
| `doctor` | 7 named probes (bash, jq, mktemp, PlistBuddy, registry, launchagents, audit_log_dir) | `smoke-doctor.json` |
| `health` | binds `$SCAFFOLD_AUDIT_LOG`, 24h stale threshold (daily scanner cadence) | `smoke-health.json` |
| `repair` | 2 scopes (audit_log_dir + registry_path REPORT-ONLY); `--apply` requires `--idempotency-key` (rc=3) | `smoke-repair-{dryrun,refused,report,unknown}.json` |
| `validate` | 3 subjects (root-path, class-name, audit-row); reject rc=1; unknown subject rc=64 | `smoke-validate-*.json` |
| `audit` | `cli_emit_audit_tail` integration; missing/empty/pass states | `smoke-audit{,-with-rows}.json` |
| `why` | 3 states (found/not_found/unavailable) | `smoke-why-{found,notfound,unavail}.json` |
| `quickstart` | 3 steps | `smoke-quickstart.json` |

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | `lint.json` clean RC=0 (was 2 warnings); 26/26 canonical-cli test PASS |
| rust-best-practices | n/a | bash-only surface |
| python-best-practices | n/a | bash-only surface |
| readme-writing | n/a | no README touched (operator help is in `scaffold_usage`) |

## Gap Closures

| Gap | Closure |
|---|---|
| `--info` absent | scaffold_emit_info via cli_emit_info + jq augmentation for `.capabilities` |
| `--schema` absent | scaffold_emit_schema with input/output schemas + 6 surface schemas |
| `--examples` absent | scaffold_emit_examples (4 curated invocations) |
| `doctor` absent | 7 named probes including load-bearing PlistBuddy probe |
| `health` absent | 24h stale threshold (daily scanner cadence — slower than 12h drift cadence) |
| `repair` absent | 2 scopes: audit_log_dir (mutating) + registry_path (REPORT-ONLY, sister to 1hshd.11 sync_helper_path pattern) |
| `validate` absent | 3 subjects matching scanner enum: root-path, class-name, audit-row |
| `audit` + `why` absent | cli_emit_audit_tail + 3-state why (found/not_found/unavailable) |
| L2 lint warnings | added explicit `return 0` to `scan_destructive_defaults` (L141) and `scan_unregistered_processes` (L232) enumerator functions |
| inventory row stale | partial → passing transition with `status_transition` annotation; corrected `mutates_state` false-positive (read-only scanner) |

## Backward Compatibility

The early-dispatch intercept (`_scaffold_is_canonical_arg`) only matches
canonical verbs/flags; every other invocation falls through to the original
scanner unchanged. Pre-existing regression `tests/check-trauma-class-substrate-test.sh`
remains 14/14 PASS (silent-write, destructive-default, unregistered-process,
clean fixtures) — see `test-run.txt`.

Test 21 in the new canonical-cli suite explicitly verifies bare invocation
still emits `[]` against an empty fixture root.

## Four-Lens Self-Grade

- **Brand:** 10/10 — scaffold matches sister 1hshd.{10,11} pattern; FULL-BYPASS variant correctly applied for native-zero-canonical case.
- **Sniff:** 10/10 — every claim has an evidence file; AG3 strict gates literally executed; no shortcuts.
- **Jeff:** 9/10 — read-only scanner discipline preserved; REPORT-ONLY repair scope honestly admits the registry isn't this surface's authority.
- **Public:** 10/10 — operator (clear `scaffold_usage`), maintainer (sister-exemplar references in scaffold header), future worker (every verb has a `help <topic>` entry).

`four_lens=brand:10,sniff:10,jeff:9,public:10`

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Lint clean | 100/100 | `lint.json` status=clean, violations=[] |
| AG3 strict gates | 250/250 | AG3.1-4 all PASS |
| Canonical-cli test suite | 200/200 | 26/26 PASS |
| Regression suite | 150/150 | 14/14 PASS (zero regression) |
| Inventory transitioned | 50/50 | partial → passing with annotation |
| Sister-pattern reuse | 100/100 | FULL-BYPASS correct + REPORT-ONLY scope reused from 1hshd.11 |
| Apply contract (rc=3 + rc=64) | 50/50 | TWO defensive gates verified by tests #7 + #14 |
| Scaffold backward-compat (test 21) | 50/50 | bare invocation falls through to native |
| Documentation completeness | 50/50 | `scaffold_usage` + `help <topic>` for every verb |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
bash .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/check-trauma-class-substrate.sh --json
```
Expected: `jq:.status == "clean"` (or grep:`"status":"clean"`). Timeout 30s.
