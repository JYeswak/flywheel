# flywheel-k8gcv.22 — escalate-capsule-plan-consumer.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.22 (wave-3-22, P0)
Surface: `.flywheel/scripts/escalate-capsule-plan-consumer.sh`
Lane: mission
mutates_state: yes (opens /flywheel:plan intent state, writes reply + action ledgers)

## AG3 acceptance gate

18/18 PASS. AG3 strict 4/4. Lint already clean.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added preventively |
| 2 | `--apply` flag absent | Added with rc=3 refusal when missing `--idempotency-key` |
| 3 | `--info` flag absent | Added emit_info (name+version+capabilities (6)+subcommands (9)+canonical_flags+env_vars+exit_codes) |
| 4 | `--schema` flag absent | Added emit_schema (input/output schemas) |
| 5 | `--examples` flag absent | Added with text + JSON envelope variants |
| 6 | positional `doctor` absent | Added emit_canonical_doctor (4 checks: jq, python3, reply_ledger, action_ledger) |
| 7 | No-dash family absent | health, validate, audit, why (3 topics), quickstart, repair (ledger-prime scope) |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/escalate-capsule-plan-consumer.sh` | 338 → 593 lines (+255) |
| `tests/escalate-capsule-plan-consumer-canonical-cli.sh` | NEW (18 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.22/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
