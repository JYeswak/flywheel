# Three-Q Surface Registry v1

The registry makes the umbrella three-question audit mechanical for flywheel
surfaces:

1. `q1_validated`: the surface has proof from a test, probe, parser, receipt, or
   explicit manual/external reason.
2. `q2_documented`: the surface has a durable doc location such as AGENTS.md,
   INCIDENTS.md, README.md, a memory note, a skill, or schema docs.
3. `q3_surfaced`: the surface has a place where future workers or doctors see
   the state without pane memory.

Each surface row contains:

- `schema_version`: registry format, currently `three-q-surface-registry/v1`.
- `surface_id`: stable ID for audit output and doctor top-failing rows.
- `category`: finite taxonomy bucket from Lane A.
- `owner` and `owner_bead`: owning runtime/component and bead when known.
- `repo`: canonical repo or external owner path.
- `runtime_scope`: `all`, `claude`, `codex`, or both. If both Claude and Codex
  are listed, validation evidence must include both runtimes.
- `q1_validated`, `q2_documented`, `q3_surfaced`: objects with `state`,
  `evidence_refs`, optional `runtime_evidence`, and optional `probe`.
- `evidence_refs`: summary references for humans and downstream receipts.
- `last_checked_ts`: timestamp used for staleness checks.
- `status`: human lifecycle label.
- `gap_reason`: explicit reason when a row is intentionally incomplete.

Run:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/three-q-surface-audit.py \
  --repo /Users/josh/Developer/flywheel \
  --json
```

Strict mode exits non-zero if any required surface is missing a Q1/Q2/Q3 proof:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/three-q-surface-audit.py \
  --repo /Users/josh/Developer/flywheel \
  --strict \
  --json
```

Filter by category or owner bead:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/three-q-surface-audit.py \
  --category doctor_signals \
  --owner flywheel-m5kg \
  --json
```

When `--write-receipt` is passed, the runner writes a B01 validation receipt
with `learn_route.route=review` for failures. B09 consumes that receipt through
`flywheel-loop validation-learn`, deduping by the generated `three-q:<hash>`
key.
