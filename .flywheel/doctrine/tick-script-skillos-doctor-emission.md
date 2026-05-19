---
title: "Tick-script standard: skillos doctor receipt emission"
type: doctrine
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Tick-script standard: skillos doctor receipt emission

Per cross-orch coordination (skillos:1 / BrightLake → flywheel:1 / LavenderGlen,
2026-05-08T06:11Z), every flywheel-installed repo's tick script SHOULD emit a
skillos doctor receipt on each tick when `skillos` is on PATH.

## Snippet (canonical)

```bash
# Skillos health observability — non-blocking, opt-in via PATH.
# Receipt lands at $REPO/state/skillos-doctor-receipts.jsonl per skillos-15-5h
# contract; failure is recorded in the receipt itself, never breaks the tick.
if command -v skillos >/dev/null 2>&1; then
  mkdir -p "$REPO/state" 2>/dev/null || true
  SKILLOS_DOCTOR_RECEIPT_PATH="$REPO/state/skillos-doctor-receipts.jsonl" \
    skillos doctor --emit-receipt --json >/dev/null 2>&1 || true
fi
```

## Why

- Each tick records skillos subsystem health per-repo (code-packs, skills,
  socraticode availability).
- Honest reporting: receipt records `status: DOWN` when subsystems unreachable.
- Receipts are append-only at `<repo>/state/skillos-doctor-receipts.jsonl`,
  schema `skillos.doctor_receipt.v1`.
- Future cross-repo aggregation surface in `flywheel-loop doctor` becomes
  trivial once receipts exist on every tick.

## Placement contract

The snippet MUST run AFTER the tick script has resolved `$REPO` and (typically)
after `cd "$REPO"` so the receipt directory creation is correctly scoped. It
should run BEFORE any heavy work (doctor probes, dispatch building) so the
receipt records even on tick paths that abort early.

The `SKILLOS_DOCTOR_RECEIPT_PATH` env override is REQUIRED. Without it,
`skillos doctor --emit-receipt` writes to `/Users/josh/Developer/skillos/state/skillos-doctor-receipts.jsonl`
regardless of cwd, which defeats per-repo observability.

## Currently shipped to

- `/Users/josh/.local/bin/alps-flywheel-loop-tick` (after line 52 `cd "$REPO"`)
- `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick` (after the
  prompt-prune block, since this script does not `cd` at top level)

## Out of scope (separate paths needed)

- `flywheel-loop-driver-writeback` — drives flywheel and vrtx ticks; has no
  per-session tick script because the cc orchestrator pane does tick work via
  `/flywheel:loop`. To get per-tick receipts for those sessions, the Python
  driver needs an additional step calling `skillos doctor --emit-receipt`
  per managed repo each cycle.
- Newly-installed flywheel repos — `templates/flywheel-install/` does not
  ship a tick script template today. New repos must include this snippet
  manually until the install template grows a tick-script.tmpl.

## Cross-references

- skillos commit: `4b4adf3 feat(skillos doctor): --emit-receipt appends to skillos-doctor-receipts.jsonl`
- skillos schema: `mcp/skillos-mcp-server/schemas/doctor_receipt.v1.schema.json`
- Cross-orch thread: `cross-orch-skillos-15-5h-doctor-receipts-2026-05-08`
- ACK messages: Agent Mail msg 449 (initial), msg 450 (dispatch landed)
- Anti-pattern guard: `feedback_orch_handshakes_never_gate_on_joshua` (no
  worker dispatch needed for this kind of cross-orch substrate addition)


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
