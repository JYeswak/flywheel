# flywheel-k8gcv.2 — low-bead-threshold-detector.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.2 (wave-3-02, P0)
Parent: flywheel-k8gcv (wave-3 P0-partial × non-general lanes)
Surface: `.flywheel/scripts/low-bead-threshold-detector.sh`
Lane: beads
mutates_state: yes (appends to ledger, optionally writes hunt-work bead to `.beads/issues.jsonl`)

## AG3 acceptance gate (wave-3 apply-spec)

```bash
low-bead-threshold-detector.sh --info --json    | jq -e '.name and .version and .capabilities'   # exit 0
low-bead-threshold-detector.sh --schema --json  | jq -e '.input_schema and .output_schema'       # exit 0
low-bead-threshold-detector.sh --examples --json| jq -e '.examples | length > 0'                 # exit 0
low-bead-threshold-detector.sh doctor --json    | jq -e '.checks'                                # exit 0  (mutates_state=yes)
```

All four AG3 probes return exit 0. Verified by `tests/low-bead-threshold-detector-canonical-cli.sh` (22/22 PASS).

## Lint state

Before: 1 violation (L5 missing-strict-mode — `set -u -o pipefail` lacked `-e`).
After: clean (0 violations).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode | `set -u -o pipefail` → `set -euo pipefail` with explicit `set +e/set -e` around `issues_stats` capture |
| 2 | L6 missing-magic-comment | Add `# flywheel-cli-surface: true` |
| 3 | `--info` missing `.capabilities` | Enrich envelope with `subcommands`, `canonical_flags`, `capabilities`, `apply_supported`, `idempotency_key_required_for_apply`, `env_vars`, `default_threshold` |
| 4 | `--schema` flag absent | Add `emit_schema` returning `{input_schema, output_schema}` per AG3 |
| 5 | `--examples` text-only | Add `--examples --json` envelope while preserving text mode for backward compat |
| 6 | `doctor` subcommand absent (mutates_state=yes) | Add 4 checks (jq, ledger_writable, issues_jsonl, repo_dir) |
| 7 | No-dash family absent | Add `health` (last_signal + ledger_row_count), `validate` (schema verify), `audit` (tail), `why` (3 topics), `quickstart` (4 steps), `repair` (ledger-prime + issues-jsonl-prime scopes) |
| 8 | apply contract missing | Add `--apply`/`--dry-run`/`--idempotency-key` on `repair`; rc=3 refusal when `--apply` without key |

## Backward compatibility

The legacy `check` invocation is preserved verbatim:
- `low-bead-threshold-detector.sh check [--repo PATH] [--threshold N] [--auto-bead] [--json]`
- Three dedicated regression tests in the new canonical-cli test:
  - `legacy check RED on empty issues.jsonl` PASS
  - `legacy check GREEN on 10 ready beads` PASS
  - `legacy --auto-bead files hunt bead on RED` + idempotent dedupe PASS

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/low-bead-threshold-detector.sh` | 182 → 414 lines (+232) |
| `tests/low-bead-threshold-detector-canonical-cli.sh` | NEW (~85 lines, 22 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing, doctor present, signals updated |
| `.flywheel/audit/flywheel-k8gcv.2/evidence.md` | NEW |

## Verification commands

```bash
.flywheel/scripts/low-bead-threshold-detector.sh --info --json | jq -e '.name and .version and .capabilities'
.flywheel/scripts/low-bead-threshold-detector.sh --schema --json | jq -e '.input_schema and .output_schema'
.flywheel/scripts/low-bead-threshold-detector.sh --examples --json | jq -e '.examples | length > 0'
.flywheel/scripts/low-bead-threshold-detector.sh doctor --json | jq -e '.checks'
.flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/low-bead-threshold-detector.sh --json | jq .status
bash tests/low-bead-threshold-detector-canonical-cli.sh   # 22/22 PASS
```

## Compliance score

| Dimension | Score |
|---|---|
| AG3 strict (name+version+capabilities; input_schema+output_schema; examples>0; doctor.checks) | PASS (4/4) |
| Lint RC=0 | PASS |
| Backward-compat (legacy `check` + `--auto-bead` shapes) | PASS (4/4 dedicated tests) |
| Magic comment present | PASS |
| apply contract gated by --idempotency-key (rc=3 refusal) | PASS |
| Inventory row updated partial→passing | PASS |
| New canonical-cli test 22/22 | PASS |

**Compliance: 1000/1000.**

## Four-Lens Self-Grade

- brand: 9 — surface is doctrine-grade: GREEN/YELLOW/RED signal tied to threshold/yellow_floor, hunt-work bead with Donella/self-org labels, JSONL-fallback for br outages.
- sniff: 9 — passes lint clean, 22/22 test, AG3 strict gate. Legacy contract locked by 4 regression tests with synthetic issues.jsonl fixtures.
- jeff: 9 — single-purpose probe with idempotent ledger append + by-id dedupe; survives br outage via direct JSONL append (jsonl_fallback branch).
- public: 9 — Three Judges: (a) skeptical operator can run `doctor`/`health`/`audit` to verify wiring; (b) maintainer can extend via subcommand dispatch; (c) future worker re-derives contract from `--schema --json`.

four_lens=brand:9,sniff:9,jeff:9,public:9
