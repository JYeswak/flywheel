# flywheel-k8gcv.26 — flywheel-verdict canonical-cli partial→passing

Bead: flywheel-k8gcv.26 (wave-3-26, P0)
Surface: `~/.claude/skills/.flywheel/bin/flywheel-verdict` (NOT in flywheel repo — lives in skills tree)
Lane: recovery
mutates_state: yes (sqlite state.db writes for joshua verdicts + events; audit log append)

## AG3 acceptance gate

36/36 PASS (32 pre-existing + 4 new AG3-strict). AG3 strict 4/4. Lint already clean.

## Starting state

Substrate was extremely canonical: full doctor/health/repair/validate/audit/why/schema/examples/quickstart/help/completion subcommands, apply contract with idempotency-key gate, cli_audit_append wiring, bash 3.2 re-exec guard. 32-assertion pre-existing test passed. Only AG3-shape gaps:
- `--info` had `name` + `version` but no `.capabilities` (canonical 4-gate requires it)
- `--schema` returned top-level `{title, type, required, properties}` (JSON-Schema-style) but NOT `{input_schema, output_schema}` (canonical 4-gate requires both)
- doctor envelope already had `.checks` ✓
- examples already had length > 0 ✓

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | `--info` missing `.capabilities` | Enriched emit_info: name+version (bumped to 1.1.0)+capabilities (8 items)+subcommands+canonical_flags+apply_supported+idempotency_key_required_for_apply+mutates_state+env_vars+exit_codes. Legacy paths/supports/exit_codes preserved. |
| 2 | `--schema` missing `.input_schema`+`.output_schema` | Updated the default `*)` case branch of `emit_schema` to add both fields. Per-surface schemas (doctor/health/repair/validate/audit/why/audit-row/record) preserved untouched — they emit per-subcommand shapes. |

## Architecture: per-surface schema + default canonical merge

The script's `emit_schema` is dispatch-style: each subcommand has its own schema variant. `--schema` (without positional) defaults to "doctor" via `emit_schema "${positional[0]:-doctor}"`. For the dash-flag path `--schema --json`, it routes through `scaffold_emit_schema "default"` → falls into the `*)` branch.

I updated only the `*)` default branch to include both `.input_schema` and `.output_schema` alongside the legacy top-level JSON-Schema fields. AG3 gate `jq -e '.input_schema and .output_schema'` passes on the default invocation. Per-surface invocations (`--schema doctor`, `--schema record`, etc.) keep their existing focused shapes.

## Backward compatibility

The pre-existing 32-assertion regression test STILL PASSES:
- All doctor/health/repair/validate/audit/why/record envelopes unchanged.
- Legacy `--info` `paths`/`supports`/`exit_codes` preserved.
- Per-surface `--schema doctor`/`--schema record`/`--schema audit-row` envelopes unchanged.
- apply-contract refusal envelope unchanged.
- cli_audit_append wiring unchanged.

## Files touched

| Path | Δ |
|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel-verdict` | 718 → 759 lines (+41) |
| `tests/flywheel-verdict-canonical-cli.sh` | +20 lines (4 new AG3-strict assertions appended) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.26/evidence.md` | NEW |

Smallest delta to the target script in wave 3 so far (+41 lines) — substrate was already nearly fully canonical.

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
