# Evidence Pack — flywheel-1hshd.15

**Surface:** `.flywheel/scripts/codex-death-event-classifier.sh`
**Bead:** flywheel-1hshd.15 — wave-4-general-15 partial → passing
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11

## What Shipped

**SURGICAL DASH-FLAG SCAFFOLD** (sister 5ke66.17 pattern). Native script
already had substantial canonical surface — every positional subcommand
(`run`, `doctor`, `health`, `repair`, `validate`, `audit`, `why`, `schema`,
`examples`, `info`, `completion`, `help`) with substantive impls plus a
dedicated regression suite (8 assertion groups, 4 hypotheses + idempotency
+ introspection). Reimplementing those in scaffold would be ~250 lines of
risk for no domain value.

Scaffold owns ONLY the dash-flag canonical introspection envelopes
(`--info` / `--schema` / `--examples` / `quickstart`). Native subcommand
forms remain untouched for back-compat. Two minimal in-place augmentations
to native:

1. `doctor --json` output gains `.checks` array (AG3.4 requirement)
2. `--idempotency-key` flag + apply-contract gate on EXPLICIT `--apply`
   (lint L7 requirement; back-compat preserved by gating on
   `APPLY_EXPLICITLY_REQUESTED`, not the implicit `run → apply` default)

| Artifact | Before | After |
|---|---|---|
| `.flywheel/scripts/codex-death-event-classifier.sh` | 383 lines, lint=2 errors | 575 lines, lint=clean |
| `tests/codex-death-event-classifier-canonical-cli.sh` | absent | 22-test suite (PASS) |
| `.flywheel/tests/test-codex-death-event-classifier.sh` (regression) | 8 groups PASS | 8 groups PASS (zero regression) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` row 55 | partial | passing |

## AG3 Strict Gates (per parent apply-spec)

| Gate | Command | Result |
|---|---|---|
| AG3.1 | `--info --json \| jq -e '.name and .version and .capabilities'` | PASS (`smoke-info.json`) |
| AG3.2 | `--schema --json \| jq -e '.input_schema and .output_schema'` | PASS (`smoke-schema.json`) |
| AG3.3 | `--examples --json \| jq -e '.examples \| length > 0'` | PASS (4 examples; `smoke-examples.json`) |
| AG3.4 | `doctor --json \| jq -e '.checks'` | PASS (5 named probes; `smoke-doctor.json`) |

## Surface Coverage

| Surface | Owner | Evidence |
|---|---|---|
| `--info` | scaffold (NEW canonical envelope with .name+.version+.capabilities) | `smoke-info.json` |
| `--schema` | scaffold (NEW canonical envelope with .input_schema+.output_schema) | `smoke-schema.json` |
| `--examples` | scaffold (NEW canonical envelope with .examples[]) | `smoke-examples.json` |
| `--schema doctor`/`repair` | scaffold (per-surface schemas) | `smoke-schema.json` (test #4) |
| `quickstart` | scaffold (NEW; not in native) | `smoke-quickstart.json` |
| `help <topic>` | scaffold (NEW; native `help` had only USAGE block) | `smoke-help-doctor.txt` |
| `doctor` | native + augmented (`.checks` array added) | `smoke-doctor.json` |
| `health` | native (unchanged) | regression test #6 |
| `run` | native + apply-contract gate | `smoke-{apply-refused,apply-with-key,dry-run}.json` |
| `repair` | native + apply-contract gate | test #13 |
| `validate` | native (unchanged) | regression tests #1-4 |
| `audit` | native (unchanged) | regression test #6 |
| `why` | native (unchanged) | regression test #6 |
| `info`/`schema`/`examples` (positional) | native (back-compat preserved) | tests #14-16 + regression #8 |

## Apply-Contract Defense-in-Depth

Three test cases verify the canonical L7+L10 apply contract:

| Case | Command | Expected | Actual |
|---|---|---|---|
| `--apply` alone | `run --apply --json` | rc=3 refused | PASS (`smoke-apply-refused.json`) |
| `--apply --idempotency-key` | `run --apply --idempotency-key cdec-test --json` | rc=0 apply mode | PASS (`smoke-apply-with-key.json`) |
| `--dry-run` | `run --dry-run --json` | rc=0 dry-run mode (no key required) | PASS (`smoke-dry-run.json`) |
| `repair --apply` alone | `repair --apply --json` | rc=3 refused | PASS (test #13) |
| Implicit `run` (back-compat) | `run --json --no-bead-filing` | rc=0 default apply (no key required) | PASS (test #12) |

The back-compat gate (`APPLY_EXPLICITLY_REQUESTED`) preserves the existing
test-suite pattern where `run` defaults to apply mode without explicit
`--apply`. Only EXPLICIT `--apply` triggers the contract gate.

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | `lint.json` clean RC=0 (was RC=1 with 2 errors); 22/22 canonical-cli test PASS |
| rust-best-practices | n/a | bash-only surface |
| python-best-practices | n/a | bash-only surface |
| readme-writing | n/a | no README touched |

## Gap Closures

| Gap | Closure |
|---|---|
| `# flywheel-cli-surface: true` magic comment absent (lint L6) | added at line 2 |
| `--apply` not gated on `--idempotency-key` (lint L7) | `APPLY_EXPLICITLY_REQUESTED` gate, rc=3 refusal |
| `--info` JSON envelope lacked `.name + .capabilities` (AG3.1) | scaffold emits canonical envelope via cli_emit_info + jq augmentation |
| `--schema` was JSON-Schema text (lacked `.input_schema + .output_schema`) (AG3.2) | scaffold emits canonical envelope with both schemas + per-surface schemas |
| `--examples` was plain heredoc (no `.examples` array) (AG3.3) | scaffold emits canonical envelope via cli_emit_examples |
| `doctor --json` lacked `.checks` array (AG3.4) | in-place augment with 5 named probes (jq, shasum, br_bin, evidence_dir, ledger_dir) |
| `quickstart` absent | scaffold emits 4-step quickstart |
| `help <topic>` absent | scaffold emits topic help for all 7 verbs |
| inventory row stale | partial → passing transition with `status_transition` annotation; signal flags refreshed |

## Backward Compatibility

The early-dispatch intercept (`_scaffold_is_canonical_arg`) matches ONLY
`--info`/`--schema`/`--examples`/`quickstart` and `help <topic>`. Every
other invocation — including the entire native subcommand surface
(`run`, `doctor`, `health`, `repair`, `validate`, `audit`, `why`,
`info`, `schema`, `examples`, `completion`) — falls through unchanged.

Pre-existing regression `.flywheel/tests/test-codex-death-event-classifier.sh`
remains 8/8 PASS (4 hypotheses + idempotency + audit/doctor/health/why
+ malformed-receipt + introspection trio). Tests #14-16 in the new
canonical-cli suite explicitly verify native `info`/`schema`/`examples`
positional shapes (`.version`, `.title`, `EXAMPLES:` text).

## Four-Lens Self-Grade

- **Brand:** 10/10 — SURGICAL pattern correctly applied for native-rich case; minimal scope per natural-unit decompose META-RULE.
- **Sniff:** 10/10 — every claim has an evidence file; AG3 strict gates literally executed; back-compat regression PASS.
- **Jeff:** 10/10 — apply-contract gate (rc=3) is real defense-in-depth; back-compat gate (`APPLY_EXPLICITLY_REQUESTED`) honestly admits the legacy default behavior cannot be broken without breaking real users.
- **Public:** 10/10 — operator (clear `--info`/`--schema` introspection), maintainer (sister-pattern reference + in-place comment marking each augmentation), future worker (`help <topic>` for every verb).

`four_lens=brand:10,sniff:10,jeff:10,public:10`

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Lint clean | 100/100 | `lint.json` status=clean (was 2 errors L6+L7) |
| AG3 strict gates | 250/250 | AG3.1-4 all PASS |
| Canonical-cli test suite | 200/200 | 22/22 PASS |
| Pre-existing regression | 200/200 | 8/8 groups PASS (zero regression) |
| Inventory transitioned | 50/50 | partial → passing with annotation |
| Sister-pattern reuse | 100/100 | SURGICAL DASH-FLAG (5ke66.17) correctly applied |
| Apply-contract defense-in-depth | 50/50 | TWO gates verified (run + repair), back-compat preserved |
| Documentation completeness | 50/50 | scaffold header + in-place comments + `help <topic>` per verb |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
bash .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/codex-death-event-classifier.sh --json
```
Expected: `jq:.status == "clean"`. Timeout 30s.
