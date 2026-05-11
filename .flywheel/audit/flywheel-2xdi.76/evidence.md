# flywheel-2xdi.76 — cross-source-silos: idle-pane-auto-dispatch-runs.jsonl

Bead: flywheel-2xdi.76 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Lane: gap-detector-quality
mutates_state: yes (one row appended to `.flywheel/gap-hunt-known-silos.jsonl` allowlist)

## Probed per META-RULE 2xdi.54

Ledger inspection of `~/.local/state/flywheel/idle-pane-auto-dispatch-runs.jsonl`:
- Exists: 3.9KB, 12 rows, last entry 2026-05-11T06:48Z
- Writer: `.flywheel/scripts/idle-pane-auto-dispatch.sh` (in flywheel.git)
- Script schedule: **5 launchd plists** (flywheel/alps/skillos/mobile-eats/vrtx-idle-pane-watch.plist) — actively running across fleet
- Self-consumer: script's own canonical-cli `audit`/`health`/`why` subcommands consume this ledger via `cli_audit_append` (filed per flywheel-1fk5f.4)

**Script-level documentation** exists in `.flywheel/doctrine/mission-fidelity-substrate.md` (cites `.flywheel/scripts/idle-pane-auto-dispatch.sh` at line 25), BUT the LEDGER FILENAME (`idle-pane-auto-dispatch-runs.jsonl`) doesn't appear there. The doctrine corpus extension (2xdi.54) catches script-name references, not derived-ledger-name references.

## Classification: operational-telemetry (same as 2xdi.70)

This ledger is the **canonical-cli audit-log** for an actively-scheduled fleet substrate (5-plist coverage). It's NOT a missing-receiver — it IS consumed, just by the script's OWN `audit`/`why` subcommands, not by a driver. Same operational-telemetry class as:
- `flywheel-sync-runs.jsonl` (2xdi.70 — just allowlisted)
- `file-reservations.jsonl` (already allowlisted)
- `fuckup-log.jsonl` (already allowlisted)
- `polish.jsonl` (already allowlisted)

## Fix

Appended one row to `.flywheel/gap-hunt-known-silos.jsonl` (98 → 99 entries):

```json
{
  "name": "idle-pane-auto-dispatch-runs.jsonl",
  "class": "operational-telemetry",
  "writer": ".flywheel/scripts/idle-pane-auto-dispatch.sh",
  "rationale": "Canonical-cli audit-log for idle-pane-auto-dispatch.sh (scheduled via 5 launchd plists: flywheel/alps/skillos/mobile-eats/vrtx-idle-pane-watch). Self-consumed by script's own audit/health/why subcommands via cli_audit_append; not driver-consumed by tick/status/synth surfaces. Script is documented in .flywheel/doctrine/mission-fidelity-substrate.md (by script name, not ledger filename — hence cross-source-silos false-positive). Filed per flywheel-2xdi.76."
}
```

Live probe verified: 1 → 0.

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify ledger + writer + scheduling | **DONE** | 3.9KB ledger; writer = `.flywheel/scripts/idle-pane-auto-dispatch.sh`; scheduled via 5 launchd plists across fleet. |
| AG2 | Verify no driver consumer | **DONE** | Script's own canonical-cli audit/health/why subcommands consume the ledger (self-consumption pattern). NO tick/status/synth driver reads it. |
| AG3 | Classify the silo | **DONE** | operational-telemetry (same as flywheel-sync-runs.jsonl 2xdi.70 + 3 existing allowlist entries). |
| AG4 | Apply canonical fix | **DONE** | Appended row to `.flywheel/gap-hunt-known-silos.jsonl`. Live probe verified 1→0. |
| AG5 | Document why script-doctrine reference didn't catch it | **DONE** | Doctrine cites script name (`idle-pane-auto-dispatch.sh`), NOT derived ledger basename (`idle-pane-auto-dispatch-runs.jsonl`). 2xdi.54 doctrine corpus catches the former but not the latter. |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: canonical-allowlist mechanism applied in-repo (no cross-repo boundary); no new gaps surfaced.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/gap-hunt-known-silos.jsonl` | +1 row (98 → 99 entries) |
| `.flywheel/audit/flywheel-2xdi.76/evidence.md` | NEW |

## Four-Lens Self-Grade

- **brand** (10): used canonical allowlist mechanism (no new gap-hunt-probe edit; 8 today is plenty). Format mirrors 2xdi.70 + 3 existing operational-telemetry entries.
- **sniff** (10): empirical — ledger inspected, writer traced, 5 launchd plists confirmed scheduled, self-consumption pattern documented; live probe verified 1→0.
- **jeff** (10): in-repo fix; cited 2xdi.70 precedent; no speculative bead-filing (8 today's gap-hunt edits already; class-fix vs corpus-creep budget balanced).
- **public** (10): Three Judges — operator sees allowlist row + rationale; maintainer sees same operational-telemetry class as 4 existing entries; future worker can pattern-match.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE. ✓
- Empirical pre/post (1→0). ✓
- Canonical mechanism (allowlist row append). ✓
- Format mirrors 4 operational-telemetry precedents. ✓
- Script-vs-ledger-name distinction documented for future maintainers. ✓

## L112 probe

Command: `jq -c 'select(.name == "idle-pane-auto-dispatch-runs.jsonl")' /Users/josh/Developer/flywheel/.flywheel/gap-hunt-known-silos.jsonl | wc -l | tr -d ' '`
Expected: `literal:1`
Timeout: 5 seconds
