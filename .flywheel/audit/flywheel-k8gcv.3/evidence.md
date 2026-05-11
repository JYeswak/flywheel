# flywheel-k8gcv.3 — capacity-halt-auto-continue-primitive.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.3 (wave-3-03, P0)
Parent: flywheel-k8gcv (wave-3 P0-partial × non-general lanes)
Surface: `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh`
Lane: capacity
mutates_state: yes (sends tmux transport "continue", writes lease/fallback ledger entries)

## AG3 acceptance gate (wave-3 apply-spec)

All four AG3 probes return exit 0. Verified by `tests/capacity-halt-auto-continue-primitive-canonical-cli.sh` (19/19 PASS).

## Starting state

Lint was already clean (passes `set -euo pipefail`, no L1-L10 violations). `--info`/`--examples` already emitted JSON envelopes but:
- `--info` missing `.capabilities` (AG3.1 fail).
- `--schema` flag returned argparse error.
- `doctor` subcommand missing entirely.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 missing-magic-comment | Add `# flywheel-cli-surface: true` and `canonical-cli-scoping: passing` markers |
| 2 | `--info` missing `.capabilities` (AG3) | Enrich Python `info()` to emit `capabilities`, `subcommands`, `apply_supported`, `dry_run_supported`, `mutates_state`, `env_vars`; add `command:"info"` field |
| 3 | `--schema` flag absent | Add bash-side `emit_schema` intercepted before Python dispatch — returns `{input_schema, output_schema, exit_codes}` per AG3 |
| 4 | `doctor` subcommand absent | Add bash-side `emit_doctor` with 8 checks (jq, python3, lease/ntm/success/auth/budget binaries, fallback_ledger) |
| 5 | No-dash canonical family absent | Add `health` (fallback row count + last signal class), `validate` (schema verify), `audit` (tail), `why` (3 topics), `quickstart` (4 steps), `repair` (fallback-ledger-prime scope with `--apply --idempotency-key` gate, rc=3 on missing key) |

## Architecture decision

Python core is preserved verbatim — bash wrapper intercepts canonical subcommands BEFORE Python is invoked. This keeps the existing apply/dry-run/lease/budget/transport pipeline untouched while exposing the canonical CLI surface.

## Backward compatibility

- `--dry-run` with synthetic digest still emits `status=dry_run` + `would_send=true` (regression-tested).
- Malformed input (`--apply` without `--pane`) still returns rc=3 (regression-tested).
- `--info` still includes legacy fields (`lease_bin`, `ntm_bin`, `exit_codes`) (regression-tested).
- `--help` still echoes argparse usage (regression-tested).

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh` | 226 → 489 lines (+263) |
| `tests/capacity-halt-auto-continue-primitive-canonical-cli.sh` | NEW (~70 lines, 19 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing, doctor present, signals updated |
| `.flywheel/audit/flywheel-k8gcv.3/evidence.md` | NEW |

## Verification commands

```bash
.flywheel/scripts/capacity-halt-auto-continue-primitive.sh --info --json | jq -e '.name and .version and .capabilities'
.flywheel/scripts/capacity-halt-auto-continue-primitive.sh --schema --json | jq -e '.input_schema and .output_schema'
.flywheel/scripts/capacity-halt-auto-continue-primitive.sh --examples --json | jq -e '.examples | length > 0'
.flywheel/scripts/capacity-halt-auto-continue-primitive.sh doctor --json | jq -e '.checks'
.flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/capacity-halt-auto-continue-primitive.sh --json | jq .status
bash tests/capacity-halt-auto-continue-primitive-canonical-cli.sh   # 19/19 PASS
```

## Compliance score

| Dimension | Score |
|---|---|
| AG3 strict (name+version+capabilities; input_schema+output_schema; examples>0; doctor.checks) | PASS (4/4) |
| Lint RC=0 | PASS |
| Backward-compat (dry-run, malformed, --info fields, --help) | PASS (4/4) |
| Magic comment present | PASS |
| repair apply contract gated by --idempotency-key | PASS |
| Inventory row updated partial→passing | PASS |
| New canonical-cli test 19/19 | PASS |

**Compliance: 1000/1000.**

## Four-Lens Self-Grade

- brand: 9 — surface reads as Joshua's bounded-discipline primitive: pre-fire authorization, burst-budget gate, lease, transport timeout, post-fire success measurement, fallback signal. Each is a domain-named subsystem.
- sniff: 9 — passes lint clean, 19/19 test, AG3 strict gate. Python core untouched. Bash intercept doesn't shadow Python's apply/dry-run logic.
- jeff: 8 — single-binary primitive with explicit exit-code taxonomy (9 codes), JSONL fallback when budget exhausted, idempotent lease via shasum digest. Not 10 because the apply path itself is not protected by --idempotency-key (Python argparse mutex is sufficient for this transport-side primitive — apply contract is on repair scope only).
- public: 9 — Three Judges: (a) skeptical operator can run `doctor`/`health` to verify dependency chain; (b) maintainer can extend Python core without touching bash canonical surface; (c) future worker re-derives contract from `--schema --json` output and 8 exit codes.

four_lens=brand:9,sniff:9,jeff:8,public:9
