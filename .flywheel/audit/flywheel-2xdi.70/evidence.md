# flywheel-2xdi.70 — cross-source-silos: flywheel-sync-runs.jsonl

Bead: flywheel-2xdi.70 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Lane: gap-detector-quality
mutates_state: yes (one row appended to `.flywheel/gap-hunt-known-silos.jsonl` allowlist)

## Bead claim vs reality

Probed per 2xdi.54 META-RULE (probe before implementing):

**Ledger inspection** of `~/.local/state/flywheel/flywheel-sync-runs.jsonl`:
- Exists: yes (1.3KB, 6 rows, last modified 2026-05-10T21:26Z)
- Writer: `~/.claude/skills/.flywheel/bin/flywheel-sync` (daily rsync utility for multi-machine flywheel state)
- Sample: all 6 entries are `action:"log_dir_exists_noop"` scaffold-doctor probes with `idempotency_key:"flywheel-sync-test-key"` or empty — **all test-run data, no production sync events**
- Documented at: `~/.claude/skills/.flywheel/references/MULTI-MACHINE-SYNC.md`

**flywheel-sync purpose** (per its header): "daily rsync of flywheel state across machines" — syncs SQLite state.db, sources.txt skill feeds, LATEST.md digests, DASHBOARD/STATE/WORK/GOAL.md.

The ledger is an **audit trail for an operational tool** consumed primarily by operator inspection (tail/grep on failed runs). It's NOT meant to drive flywheel-loop tick/status/synth/doctrine — like the substrate-doctor-*-test.sh and agentmail-fd-pressure-probe.sh I dispositioned earlier, it's intentionally a diagnostic surface.

## Disposition: known-silos allowlist entry (canonical mechanism)

`gap-hunt-probe.sh`'s `probe_cross_source_silos()` consults `known_silos()` which reads `.flywheel/gap-hunt-known-silos.jsonl` (96 existing entries; format `{name, class, writer, rationale}` per the docstring at gap-hunt-probe.sh:1382).

This file IS in flywheel.git (not in `.claude/skills/`), so editing it from this dispatch respects repo boundaries. Added one row:

```json
{"name":"flywheel-sync-runs.jsonl","class":"operational-telemetry","writer":"~/.claude/skills/.flywheel/bin/flywheel-sync","rationale":"Audit trail for flywheel-sync (daily rsync utility for multi-machine flywheel state; documented at ~/.claude/skills/.flywheel/references/MULTI-MACHINE-SYNC.md). Consumed by operator inspection on failed runs, not by tick/status/synth/doctrine drivers — diagnostic-only ledger. Filed per flywheel-2xdi.70."}
```

Format mirrors existing entries (especially `fuckup-log.jsonl` and `file-reservations.jsonl` which are operational-telemetry class).

## Live verification (post-fix)

Pre-fix: `flywheel-sync-runs.jsonl` IN `gaps_by_class["cross-source-silos"]`.

Post-fix:
```bash
$ jq -r '[.gaps_by_class["cross-source-silos"][]?.name | select(contains("flywheel-sync-runs"))] | length' /tmp/gh.json
0
```

## Acceptance gates

Auto-filed by gap-hunt-probe. Inferred AGs:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the ledger exists + identify writer | **DONE** | 1.3KB ledger; writer = `~/.claude/skills/.flywheel/bin/flywheel-sync`; documented at MULTI-MACHINE-SYNC.md |
| AG2 | Verify the "no downstream consumer" claim | **DONE** | Probe-receiver-text (tick/status/synth/AGENTS/INCIDENTS/README + PLANS + doctrine after 2xdi.54 fix) confirmed not citing the ledger basename or stem. Receiver class is operator inspection, not driver consumption. |
| AG3 | Classify the silo (intentional diagnostic vs missing-receiver) | **DONE** | INTENTIONAL DIAGNOSTIC — flywheel-sync is operator tool; ledger is audit trail consumed by `tail/grep` not by tick driver. Same class as fuckup-log.jsonl / file-reservations.jsonl already in allowlist. |
| AG4 | Apply the canonical fix mechanism | **DONE** | Added row to `.flywheel/gap-hunt-known-silos.jsonl`. Format mirrors operational-telemetry precedent. Live probe verified: named target dropped from cross-source-silos (1 → 0). |
| AG5 | Cite related dispositions | **DONE** | Same on-demand-diagnostic class as flywheel-2xdi.60 (agentmail-fd-pressure-probe) and 2xdi.50-side-finding (substrate-doctor-*-test.sh). The substrate-registry on-demand allowlist is the equivalent mechanism for SCRIPTS; gap-hunt-known-silos.jsonl is the equivalent for LEDGERS. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/gap-hunt-known-silos.jsonl` | +1 row (96 → 97 entries) |
| `.flywheel/audit/flywheel-2xdi.70/evidence.md` | NEW |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: canonical-allowlist mechanism applied in-repo; no new gaps surfaced. flywheel-sync's deferred scheduling (no launchd plist found) is a separate concern documented but not bead-filed — it lives in `.claude/skills/` repo and depends on Joshua's multi-machine deployment plan.

## Side-finding (documented, not filed)

flywheel-sync is designed for "daily rsync" but I found **no launchd plist or cron schedule** for it. The 6 ledger entries are all test-run data. The tool is built but not currently scheduled.

This is a separate concern from the silo audit:
- If flywheel-sync should be running daily, it needs a launchd plist (in `.claude/skills/` repo)
- If flywheel-sync is on-demand-only, then the ledger entry I just added correctly classifies it as operational-telemetry

NOT filing a sister bead because:
- The decision (schedule daily vs on-demand) requires Joshua's multi-machine deployment intent (do you have other macs to sync to right now?)
- The fix lives in `.claude/skills/` repo per `feedback_no_push_ntm_br` boundary
- The current state (no schedule + test-data-only ledger) is consistent with on-demand classification I just applied

## Skill auto-routes addressed

- All `n/a` — internal allowlist append; no surface authored or modified.

## Four-Lens Self-Grade

- **brand** (10): used the canonical allowlist mechanism (`gap-hunt-known-silos.jsonl`); format mirrors `fuckup-log.jsonl` + `file-reservations.jsonl` precedent for operational-telemetry class.
- **sniff** (10): empirical inspection of ledger (all 6 entries reviewed; all test-run data) + writer + receiver-text scan + post-fix live probe verification (1 → 0).
- **jeff** (10): didn't extend gap-hunt-probe corpus a 6th time today (cross-source-silos is a different probe than wired-but-cold; appropriate boundary). Didn't propose flywheel-sync scheduling change (out-of-scope; `.claude/skills/` repo).
- **public** (10): Three Judges check —
  - Skeptical operator: allowlist entry has full rationale + writer + class; reproducible.
  - Maintainer: format matches 96 existing entries; future maintainer sees the pattern.
  - Future worker: when flywheel-sync IS scheduled for production, this allowlist entry stays valid (the ledger is still operator-consumed, not tick-driver-consumed).

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE. ✓
- Empirical pre/post (1 → 0 in cross-source-silos list). ✓
- Canonical mechanism used (gap-hunt-known-silos.jsonl). ✓
- Format mirrors existing operational-telemetry entries. ✓
- Side-finding (deferred scheduling) documented honestly without speculative bead-filing. ✓

## L112 probe

Command: `jq -c 'select(.name == "flywheel-sync-runs.jsonl")' /Users/josh/Developer/flywheel/.flywheel/gap-hunt-known-silos.jsonl | wc -l | tr -d ' '`
Expected: `literal:1` (exactly one allowlist entry for the named ledger)
Timeout: 5 seconds
