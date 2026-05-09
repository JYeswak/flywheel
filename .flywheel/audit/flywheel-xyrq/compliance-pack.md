# flywheel-xyrq Compliance Pack

## Scope

- Bead: `flywheel-xyrq`
- Dispatch: `flywheel-xyrq-b971e7`
- Shared surfaces:
  - `/Users/josh/.claude/commands/flywheel/tick.md`
  - `.flywheel/scripts/dicklesworthstone-signal-gate.py`
  - `tests/dicklesworthstone-signal-gate.sh`
  - `.flywheel/receipts/flywheel-xyrq/xyrq-b971e7-evidence.md`
  - `.flywheel/audit/flywheel-xyrq/compliance-pack.md`

## Acceptance Mapping

- Step 4m added to `/flywheel:tick`: yes.
- Reads Dicklesworthstone signal stats: `.flywheel/scripts/dicklesworthstone-signal-gate.py tick`.
- If active `seen`/`noted` count is greater than 3, files one ranked-promotion bead in `--apply --auto-file-beads` mode.
- Daily quota advances or logs `no_advance_reason`: implemented with `daily_no_advance` rows in `~/.local/state/flywheel/dicklesworthstone-signal-gate.jsonl`.
- 7-day zero-extraction drift files a P1 doctrine-drift bead in `--apply --auto-file-beads` mode.

## Four Lens

- Artifact: new CLI helper, targeted test, tick command doctrine, evidence pack.
- Command: Step 4m command is re-runnable with `--dry-run` or mutating `--apply --auto-file-beads`.
- Doctrine: ties the Jeff 4-state gate to daily tick discipline instead of weekly Petal-9 review.
- Close evidence: targeted test, Python compile, live dry-run, L112 probe.

## Skill Routes

- `canonical-cli-scoping`: used; helper exposes `tick`, `doctor`, `health`, `schema`, `info`, and `examples` surfaces with JSON mode.
- `python-best-practices`: used; typed Python signatures, JSON boundary parsing, fixture-backed shell test.
- `rust-best-practices`: n/a, no Rust touched.
- `readme-writing`: n/a, no README touched.

## L112

Probe:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/dicklesworthstone-signal-gate.py tick --dry-run --json | jq -e '.schema_version == "dicklesworthstone-signal-gate/v1" and .counts.active_signal_count >= 0 and ((.daily_quota.advanced_today_count >= 1) or ((.daily_quota.no_advance_reason // "") | length > 0))'
```

Expected: `jq:true`
