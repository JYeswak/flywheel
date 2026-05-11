# flywheel-k8gcv.4 — capacity-halt-lease-primitive.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.4 (wave-3-04, P0)
Parent: flywheel-k8gcv (wave-3 P0-partial × non-general lanes)
Surface: `.flywheel/scripts/capacity-halt-lease-primitive.sh`
Lane: capacity
mutates_state: yes (appends acquire/release rows to lease ledger)

## AG3 acceptance gate (wave-3 apply-spec)

All four AG3 probes return exit 0. Verified by `tests/capacity-halt-lease-primitive-canonical-cli.sh` (21/21 PASS).

## Starting state

Lint was already clean. `--info`/`--examples` emitted JSON envelopes but `--info` was missing `.capabilities`, `--schema` flag returned argparse error, `doctor` subcommand absent.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 missing-magic-comment | `# flywheel-cli-surface: true` + `canonical-cli-scoping: passing` |
| 2 | `--info` missing `.capabilities` | Python `info_envelope()` enriched: `capabilities`, `subcommands`, `mutates_state`, `apply_supported`, `env_vars`, `command:"info"` |
| 3 | `--schema` flag absent | bash-side `emit_schema` intercepted before Python — returns `{input_schema, output_schema, exit_codes}` |
| 4 | `doctor` subcommand absent | bash-side `emit_doctor` with 3 checks (jq, python3, ledger_writable) |
| 5 | No-dash family absent | `health` (active_lease_count via python inline), `validate` (schema verify), `audit` (tail), `why` (3 topics: lease-semantics, digest-keying, already-held), `quickstart` (4 steps), `repair` (ledger-prime scope with `--apply --idempotency-key` gate, rc=3) |

## Architecture decision

Python core preserved verbatim. Bash wrapper intercepts canonical subcommands BEFORE Python dispatch — same pattern as k8gcv.3.

## Backward compatibility

- `--list` still emits leases array (regression-tested).
- `--acquire` writes ledger row, returns `acquired` + ledger_written=true (regression-tested).
- `--acquire` on already-held lease returns rc=1 with status=already_held (regression-tested).
- `--release` writes release row (regression-tested).
- Malformed input (missing `--digest`) returns rc=2 (regression-tested).
- `--help` echoes argparse usage (regression-tested).

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/capacity-halt-lease-primitive.sh` | 121 → 364 lines (+243) |
| `tests/capacity-halt-lease-primitive-canonical-cli.sh` | NEW (21 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing, doctor present |
| `.flywheel/audit/flywheel-k8gcv.4/evidence.md` | NEW |

## Compliance score

| Dimension | Score |
|---|---|
| AG3 strict (info+schema+examples+doctor) | PASS (4/4) |
| Lint RC=0 | PASS |
| Backward-compat (list/acquire/release/already-held/malformed/help) | PASS (6/6) |
| Magic comment | PASS |
| repair apply contract gated by --idempotency-key | PASS |
| Inventory updated | PASS |
| New test 21/21 | PASS |

**Compliance: 1000/1000.**

## Four-Lens Self-Grade

- brand: 9 — primitive is doctrine-grade: per-(session,pane,digest) idempotency lease, ttl-bound, append-only ledger, stale-acquire detection. Domain-named.
- sniff: 9 — passes lint, 21/21 test, AG3 strict. Python core untouched, bash intercept preserves apply pipeline.
- jeff: 9 — single-binary primitive with explicit exit-code taxonomy (4 codes), JSONL ledger, idempotent by digest-keying. Survives concurrent invocations via row-append semantics.
- public: 9 — Three Judges: (a) operator can run doctor/health/audit; (b) maintainer extends Python core without touching canonical surface; (c) future worker re-derives contract from --schema.

four_lens=brand:9,sniff:9,jeff:9,public:9
