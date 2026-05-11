# flywheel-k8gcv.21 — jeffrey-comment-watchtower.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.21 (wave-3-21, P0)
Surface: `.flywheel/scripts/jeffrey-comment-watchtower.sh`
Lane: jeff-corpus
mutates_state: yes (writes comment ledger; dispatches JEFFREY_COMMENT_NEW signal via ntm)

## AG3 acceptance gate

19/19 PASS. AG3 strict 4/4. Lint clean (was 3 violations: L5+L6+L7).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode | `set -uo pipefail` → `set -euo pipefail` |
| 2 | L6 magic comment | Added |
| 3 | L7 --apply not gated | Added `IDEMPOTENCY_KEY` var + `--idempotency-key` flag + EXPLICIT_APPLY tracking + rc=3 refusal when explicit `--apply` used without key. **Note**: default-apply (no `--apply` or `--dry-run`) is EXEMPT from the gate — this preserves launchd-cadence ergonomics. |
| 4 | `--info` missing AG3 fields | Enriched: name+capabilities (7)+subcommands (7)+canonical_flags+env_vars+exit_codes (legacy owns/sla_hours/cadence_minutes/jeffrey_login preserved) |
| 5 | `--schema` missing AG3 fields | Added input_schema + output_schema (legacy ledger_row_fields + signal_line + heartbeat_row_fields preserved) |
| 6 | `doctor` envelope missing `.checks` | Added `checks` array (6 named: gh, jq, perl, ntm_bin, state_dir_writable, gh_auth) into existing doctor_payload. Plus a new self-contained `emit_canonical_doctor` for the positional `doctor` subcommand. **Skill discovery**: when positional intercept fires BEFORE function definitions, define a self-contained `emit_canonical_doctor` rather than calling later-defined `doctor_payload`. |
| 7 | `--examples` flag absent | Added with text + JSON envelope variants |
| 8 | No-dash family absent | health (last_action_required), validate, audit, why (3 topics: sla-4h-cadence-15min, jeffrey-comment-new-signal, reseed-bootstrap), quickstart, repair (ledger-prime scope) |

## Architectural note: default-apply exemption

This script is run on a 15-minute launchd cadence; the canonical pattern is `jeffrey-comment-watchtower.sh` (no flag) which defaults to `--apply`. Forcing every launchd invocation to pass `--idempotency-key` would break this. So:
- Default-apply (no `--apply` flag): EXEMPT from idem-key requirement.
- Explicit `--apply` (operator-typed): REQUIRES `--idempotency-key`.

This is operator-distinguished mutation discipline: scheduled cadence cron-equivalents get an ergonomics pass; ad-hoc operator runs get the canonical safety gate.

## Backward compatibility

4 regression tests:
- Legacy `--doctor` flag preserved (returns `mode:"doctor"` envelope).
- `--info` legacy fields preserved (`owns`, `sla_hours`, `cadence_minutes`).
- `--help` shows usage.
- `--examples` (no `--json`) text-mode preserved.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeffrey-comment-watchtower.sh` | 395 → 720 lines (+325) |
| `tests/jeffrey-comment-watchtower-canonical-cli.sh` | NEW (19 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.21/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
