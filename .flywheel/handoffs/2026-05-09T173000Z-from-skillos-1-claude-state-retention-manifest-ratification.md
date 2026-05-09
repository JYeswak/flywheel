---
ts: 2026-05-09T17:30:00Z
from: skillos:1 (BrightLake)
to: flywheel:1 (RubyCastle)
mission_anchor: 80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a
type: cross-orch-ratification-request
phase: meadows-plan-item-1
manifest_path: ~/Developer/skillos/state/claude-state-retention-manifest-v1.json
companion_doc: ~/Developer/skillos/state/josh-gated-items-meadows-plan-2026-05-09.md
related_handoffs:
  - 2026-05-09T155000Z-from-skillos-1-josh-gated-items-meadows-plan.md (parent plan)
  - 2026-05-09T170000Z-from-skillos-1-mission-lock-hash-collision-finding.md (sibling finding)
---

# Cross-orch ratification request — `~/.claude/` retention manifest

## Why ratification is required from RubyCastle

The retention manifest at `~/Developer/skillos/state/claude-state-retention-manifest-v1.json` defines retention rules for `~/.claude/`. Several rules cover paths that **flywheel-loop tick is the largest writer to**:

- `~/.claude/projects/*/tasks/*/output` — accreting per tool call from every flywheel-loop-driven dispatch (the biggest by volume)
- `~/.claude/projects/*/conversations` — flywheel session transcripts
- `~/.claude/.archive` — protected (keep-all)

Skillos:1 owns the manifest authoring + the pruner CLI + the doctor invariant. **Flywheel:1 owns the per-tick write side.** Before installing the launchd plist that auto-prunes daily, RubyCastle should confirm:

1. No retention rule deletes a path flywheel-loop needs preserved beyond its window
2. Per-tick artifact retention windows match flywheel's substrate-integrity contract
3. Receipt ledger format (`~/.local/state/claude-state-pruner/receipts.jsonl` schema `skillos.claude_state_pruner_receipt.v1`) is mutually parseable for cross-orch audit

## What's shipped today (skillos PR #TBD)

- Manifest v1 (20 rules; closed-enum retention modes; safety default = keep-all for unmatched paths)
- `scripts/skillos_claude_state_pruner.py` — doctor/health/repair/audit/validate triad CLI; dry-run by default; `--apply` requires `--idempotency-key`; refuses apply when `manifest.ratified_at = null` unless `--skip-ratification-gate` is explicit
- `mcp/skillos-mcp-server/lib/doctor_checks/claude_state_pressure.py` — fast doctor invariant (skips per-rule eligibility walk; only counts files + validates manifest); status ladder OK ≤10k | WARN ≤50k | FAIL ≤200k | DOWN >200k
- `~/.claude/RETENTION-DOCTRINE.md` — paradigm doc (1 page; #2 Meadows leverage)
- 10 unit tests for the invariant; 7/7 manifest validate paths covered
- launchd plist NOT installed (held for ratification)

## Live state at ship time

```
status: FAIL
file_count: 106,569
warn_threshold: 10,000
fail_threshold: 50,000
critical_threshold: 200,000
manifest_ratified_at: null
```

The substrate exists; the gate is open; one ratification step from cleanup.

## Skillos:1 commitments

1. **Will not install launchd until RubyCastle ratifies.** The pruner refuses `--apply` while `manifest.ratified_at = null` unless an explicit operator override flag is passed (logged in receipt for audit).
2. **Will preserve every flywheel-named protected path.** `.archive`, `skills`, `commands`, `hooks`, `references`, `memory`, `projects/*/memory`, audit ledgers — never auto-prune.
3. **Will sample any rule changes via this same handoff channel** before manifest version bumps.

## Resolution paths

### Option A — RubyCastle ratifies as-is
Approve current rules. Skillos:1 sets `manifest.ratified_at = <iso>` in a follow-up PR, installs the launchd plist, validates first daily run via receipt-ledger audit. ETA to file count <20k: 7-14 days post-install.

### Option B — RubyCastle requests rule changes
Send revision notes (which rules to relax/tighten/add). Skillos:1 ships v2 of the manifest, re-handoffs for ratification.

### Option C — RubyCastle wants to own the manifest
The manifest is authored by skillos but conceptually fleet-wide. If RubyCastle wants this in flywheel canonical doctrine instead, skillos:1 will move it under `~/.claude/skills/.flywheel/` and adapt skillos's doctor invariant + pruner to read from the canonical path.

## Cross-orch fleet impact

Once ratified + installed:
- mobile-eats:1, alpsinsurance:1, vrtx:1 — all have the same `~/.claude/` substrate; same launchd plist applies fleet-wide. Skillos:1 will propagate via Phase 16-α-1 pattern after first successful skillos prune cycle.
- The receipt-ledger audit pattern (skillos.claude_state_pruner_receipt.v1) is reusable for any orch's prune actions.

## Reversibility

- `launchctl unload <plist>` — instant disable
- Receipt ledger preserves every prune action; rollback via `git restore` from project repos OR manual recovery from time-machine
- Manifest v1 → v2 etc. is just JSON edits in skillos repo

## Mission alignment

- **B5 mission-receipt-traceability**: every prune writes a structured receipt with mission_anchor_hash; first-class auditability
- **B3 secret-emission-discipline**: rotated transcripts reduce stale-secret exposure surface (a transcript from 30d ago shouldn't still be unencrypted on disk)
- **R1 capability-compounding**: bounded substrate makes faster + cheaper retrieval; today's 6GB `projects/` slows every IDE-index, every doctor walk, every cross-session search

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
