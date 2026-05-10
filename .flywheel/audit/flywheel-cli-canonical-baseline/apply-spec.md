# Bead 2: flywheel-cli-canonical-baseline

Depends on flywheel-cli-inventory (bead 1). Ships
canonical-cli-scoping baseline introspection on every P0/P1 own-binary
identified by bead 1.

## Goal

Every flywheel-authored CLI exposes the canonical introspection surface:
`--help`, `--version`, `--info --json`, `--schema --json`, `--examples --json`.
Doctor/health/repair triad is present (even if minimal). This is the gate
that bead 3 (doctor-mode-upgrade) requires before its ten-phase loop runs.

## Scope

### AG1: read inventory

Source: `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (bead 1 output).
Filter: `ownership=own AND canonical_cli_scoping_status IN (missing, partial)`.
Skip: `ownership=jeff-stack` (file issues upstream, do not patch).

### AG2: per-binary canonical-cli-scoping pass

For each filtered binary, follow the `/canonical-cli-scoping` skill end-to-end:
1. Add `--info --json` returning `{name, version, purpose, capabilities[]}`
2. Add `--schema --json` returning the binary's input/output schemas
3. Add `--examples --json` returning canonical invocation patterns
4. If binary has any state-mutating subcommand, ensure `doctor` exists
   (minimal implementation acceptable; bead 3 hardens it)
5. Validate envelope shapes against the canonical-cli-scoping skill's
   reference schemas

### AG3: per-binary acceptance gate

Before closing per-binary work:
- `<bin> --info --json | jq -e '.name and .version and .capabilities'` exits 0
- `<bin> --schema --json | jq -e '.input_schema and .output_schema'` exits 0
- `<bin> --examples --json | jq -e '.examples | length > 0'` exits 0
- If state-mutating: `<bin> doctor --json` returns capability dictionary

### AG4: dispatch model

This bead chains to multiple worker dispatches — one per binary in the
filtered set. Use canonical /flywheel:dispatch with bead-prefixed task IDs.
Each per-binary dispatch is its own callback; this parent bead closes when
all per-binary closes are accepted.

### AG5: receipt

Write `.flywheel/audit/flywheel-cli-canonical-baseline/evidence.md`:
- Binaries baselined (with before/after canonical_cli_scoping_status)
- Schema-validation receipts per binary
- Any binaries that escalated to upstream issues (e.g., framework limits)
- Updated inventory.jsonl with new statuses

## Boundary

- DO NOT touch jeff-stack binaries. File upstream issues for any gaps.
- DO NOT begin doctor-mode upgrades (bead 3) on any binary; baseline only.
- One commit per binary's baseline ship; one PR per binary unless the change
  is <20 lines and a single file (AGENTS.md exemption).

## Success criteria

- 100% of P0/P1 own-binaries pass AG3 acceptance gate
- inventory.jsonl reflects updated statuses
- bead 3's eligible-input-set is unambiguous
