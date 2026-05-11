# Compliance Evidence Pack — flywheel-1hshd.4

Surface: `.flywheel/scripts/apply-tmux-tuning.sh`
Bead: flywheel-1hshd.4 (wave-4-general-4)
Parent bead: flywheel-1hshd (jloib wave-4 decomposition, closed)
Identity: MagentaPond

## Summary — sister of flywheel-1hshd.3 (apply-substrate-tuning)

589-line existing canonical-CLI script (tmux 3.6a tuning for agent swarms). SISTER pattern of flywheel-1hshd.3 (apply-substrate-tuning.sh) — same 4-gap surgical patch profile. Inventory signals: identical pattern to apply-substrate-tuning (`has_apply`/`has_revert`/`has_repair`/`has_examples`/`has_info`/`has_doctor`/`has_health` all true; `has_schema:false`, `marked_cli_surface:false`, `has_idempotency_key:false`).

Size: 589 → 636 lines (+47 lines, ~8% growth). 20/20 PASS, AG1+AG3 strict, lint RC=0 (was RC=1).

## Gaps closed (4 — sister pattern of 1hshd.3)

1. **L6 missing-magic-comment error** → added `# flywheel-cli-surface: true`
2. **L7 apply-without-idempotency-key error** → added `--idempotency-key` flag + pre-dispatch gate refusing `--apply` with rc=3 when key absent
3. **--schema dash-flag missing** → parity with existing positional `schema <topic>` subcommand; defaults topic to `config` (most useful for AG3 --schema --json probe)
4. **--info plain-text-only** → added JSON branch with AG3 `.name`/`.version`/`.subcommands` fields; plain-text fallback preserved

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json \| jq -e '.name and .version and .subcommands'` | PASS (**NEW**) |
| `--schema --json \| jq -e '.schema_version'` | PASS (**NEW**) |
| `--examples --json \| ...` | PASS (pre-existing) |
| canonical-cli-lint.sh RC=0 | PASS (**NEW** — was RC=1) |
| `--apply` without `--idempotency-key` → rc=3 | PASS (**NEW**) |

## Per-binary AG3 coverage

- **doctor** (existing positional `mode_doctor`): drift JSON envelope.
- **health** (existing): tails ledger.
- **repair / revert** (existing): NOW gated on `--idempotency-key` when `--apply` is given.
- **revert without APPROVE=yes**: blocks safely (rc=4 + `schema_version:"tmux-tuning.v1.blocked"`) — defense-in-depth alongside the new idempotency-key gate.
- **validate / audit / why / schema** (existing): all dispatched.
- **--schema config / ledger / backup** (NEW dash form): emits surface-specific schemas matching positional `schema <topic>`.

## Live signals

```
$ apply-tmux-tuning.sh --info --json | jq -e '.name and .version and .subcommands'
true

$ apply-tmux-tuning.sh --apply --json; echo $?
{"schema_version":"tmux-tuning.v1","status":"refused","mode":"apply",
 "reason":"--apply requires --idempotency-key KEY (canonical apply contract)",
 "exit_code":3}
3

$ apply-tmux-tuning.sh --revert --json; echo $?
{"schema_version":"tmux-tuning.v1.blocked","status":"blocked",
 "reason":"APPROVE=yes required for mutation"}
4
(Double-safety: --apply needs --idempotency-key AND APPROVE=yes for mutation)
```

## Test suite

`tests/apply-tmux-tuning-canonical-cli.sh` — 20/20 PASS. Test #19 verifies `--revert` defense-in-depth behavior (rc=4 + blocked envelope without APPROVE=yes).

## Pre-existing test regression

No `tests/apply-tmux-tuning*.sh` file. Backward-compat verified by dedicated assertions in new test suite (positional `doctor`, `audit`, `why`, `quickstart`, default scan).

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 (4 gaps closed, sister-pattern with 1hshd.3) |
| Heredoc fallback preserved | 150/150 (plain-text --info fallback + APPROVE=yes mutation gate preserved) |
| Test coverage (20/20) | 100/100 |
| Documentation | 50/50 (sister-pattern attribution) |
| Style / Bash hygiene | 100/100 (lint RC=0 was RC=1) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — direct sister-pattern of 1hshd.3 with explicit cross-reference.
- **sniff:10** — double-safety gate (--idempotency-key + APPROVE=yes) for `~/.tmux.conf` mutation; both preserved.
- **jeff:10** — minimum-touch surgical; defaults `--schema` topic to `config` (sensible default for AG3 probe).
- **public:10** — Three Judges check: operator sees both safety gates; future worker has clear sister-pattern reference.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — 4 gaps closed; lint RC=0; apply contract rc=3
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a**
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/apply-tmux-tuning.sh` reserved + released.

## Backup

`.flywheel/scripts/apply-tmux-tuning.sh.bak.scaffold-20260511T024911683376000Z-52327` (gitignored).
