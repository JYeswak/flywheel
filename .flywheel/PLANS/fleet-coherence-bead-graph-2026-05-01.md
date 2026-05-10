---
title: "Fleet-Coherence Bead Graph (canonical intent)"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Fleet-Coherence Bead Graph (canonical intent)

**Created:** 2026-05-01T16:21Z
**Source:** `/tmp/beads_workflow_fleet_coherence_output.md` + dispatch_synthesis_v2 + jeff audit findings
**Why this file exists:** `br dep add` fails with `OpenRead root page 120` (beads_rust code-path bug — survives sqlite3 VACUUM/recover/dump). Until upstream fix, this markdown holds canonical dep intent.

## Beads (15 total — all created and persisted via `br create`)

| Bead | Title | Priority | Type |
|---|---|---|---|
| flywheel-cgy | Decide fleet-coherence repo home | 1 | question (Joshua) |
| flywheel-2i4 | Decide expected_pane_count semantics | 2 | question (Joshua) |
| flywheel-2te | Phase 0 fleet-coherence schema fixtures | 1 | feature |
| flywheel-1km | Phase 1c fleet-coherence schema writer | 1 | feature |
| flywheel-dzj | Phase 1a fleet-coherence scanner skeleton | 1 | feature |
| flywheel-247 | Phase 1b fleet-coherence launchd lifecycle | 1 | feature |
| flywheel-3eo | Phase 1d drift-status cached command | 1 | feature |
| flywheel-pd9 | Phase 1e fleet-coherence classifier pack | 1 | feature |
| flywheel-1hn | Phase 1f shadow signal-quality report | 1 | task |
| flywheel-hww | Phase 2a authenticated fleet-mail probe | 1 | feature |
| flywheel-1m2 | Phase 2b L61 dual-channel alert sender | 1 | feature |
| flywheel-bkc | Phase 2c degraded alert-channel handling | 1 | feature |
| flywheel-375 | L63 fleet-coherence recovery drills | 1 | task |
| flywheel-2y4 | Phase 3a tick Step 4i read-only consumer | 1 | feature |
| flywheel-1fh | Phase 3b tick Step 4i action consumer | 1 | feature |

## Dependency edges (13 — pending br upstream fix)

```
flywheel-2te → blocks → flywheel-dzj, flywheel-247, flywheel-1km, flywheel-3eo, flywheel-pd9, flywheel-1hn
flywheel-1km → blocks → flywheel-dzj
flywheel-dzj → blocks → flywheel-247, flywheel-3eo
flywheel-247, flywheel-1km, flywheel-3eo → block → flywheel-pd9
flywheel-pd9 → blocks → flywheel-1hn
flywheel-1hn → blocks → flywheel-hww
flywheel-hww → blocks → flywheel-1m2, flywheel-2y4
flywheel-1m2 → blocks → flywheel-bkc, flywheel-2y4
flywheel-bkc → blocks → flywheel-2y4
flywheel-2y4 → blocks → flywheel-1fh
flywheel-375 → blocks → flywheel-1fh
flywheel-cgy → blocks → flywheel-dzj, flywheel-247, flywheel-3eo
flywheel-2i4 → blocks → flywheel-pd9
```

## DAG (text rendered)

```
[2i4 Q] ─┐
         ↓
        [pd9] ─→ [1hn] ─→ [hww] ─┬─→ [1m2] ─→ [bkc] ─→ [2y4] ─→ [1fh]
         ↑                       │       │              ↑       ↑
         │                       └───────┴──────────────┘       │
[247] ───┤                                                      │
[1km] ───┤                                                      │
[3eo] ───┘                                                  [375 drill]
   ↑       ↑
[dzj] ────┘
   ↑
[2te] (Phase 0 — gates everything)
   ↑
[cgy Q] (Joshua repo-home decision — gates 1a/1b/1d)
```

## Recovery checklist when br upstream is fixed

```bash
cd ~/Developer/flywheel
# 13 edges to add
br dep add flywheel-dzj flywheel-2te
br dep add flywheel-247 flywheel-2te
br dep add flywheel-1km flywheel-2te
br dep add flywheel-3eo flywheel-2te
br dep add flywheel-pd9 flywheel-2te
br dep add flywheel-1hn flywheel-2te
br dep add flywheel-dzj flywheel-1km
br dep add flywheel-247 flywheel-dzj
br dep add flywheel-3eo flywheel-dzj
br dep add flywheel-pd9 flywheel-247
br dep add flywheel-pd9 flywheel-1km
br dep add flywheel-pd9 flywheel-3eo
br dep add flywheel-1hn flywheel-pd9
br dep add flywheel-hww flywheel-1hn
br dep add flywheel-1m2 flywheel-hww
br dep add flywheel-bkc flywheel-1m2
br dep add flywheel-2y4 flywheel-hww
br dep add flywheel-2y4 flywheel-1m2
br dep add flywheel-2y4 flywheel-bkc
br dep add flywheel-1fh flywheel-2y4
br dep add flywheel-1fh flywheel-375
br dep add flywheel-dzj flywheel-cgy
br dep add flywheel-247 flywheel-cgy
br dep add flywheel-3eo flywheel-cgy
br dep add flywheel-pd9 flywheel-2i4
br dep cycles  # MUST be empty
```

## Dispatch order (without dep graph in br, use this list manually)

When ready to start implementation, work in this order:

1. **Joshua decisions FIRST** — answer flywheel-cgy + flywheel-2i4 (1-sentence questions in synthesis v2 §10)
2. **Phase 0** — flywheel-2te (schema fixtures)
3. **Phase 1** in parallel where safe:
   - flywheel-1km (schema writer) → unblocks flywheel-dzj
   - flywheel-dzj (scanner skeleton)
   - flywheel-247 + flywheel-3eo can start once dzj has skeleton
4. **Phase 1e** — flywheel-pd9 (classifier pack) after 1a-1d ready
5. **Phase 1f** — flywheel-1hn (24-48h shadow run)
6. **Phase 2** — hww → 1m2 → bkc
7. **L63 drills** — flywheel-375 (any time after Phase 0; gates Phase 3b only)
8. **Phase 3a** — flywheel-2y4 (read-only consumer)
9. **Phase 3b** — flywheel-1fh (action consumer; needs 2y4 + 375)

## Blocker

`br dep add` fails with `OpenRead root page 120` even though sqlite3 reports integrity_check=ok. This is a beads_rust code-path bug. Tracking:
- Trauma row: `fl-2026-05-01-br-dep-add-survives-sqlite-repair`
- Snapshot: `~/Developer/flywheel/.beads.bak.20260501T161552Z`
- Failed workdir: `~/Developer/flywheel/.beads.failed.flywheel14w.20260501T161900Z`
- Worker report: `/tmp/bead_flywheel_14w_output.md` (230 lines)
- Existing upstream issue: frankensqlite#85 (filed 2026-04-30)
- Need to file: beads_rust issue with this specific repro (br dep add OpenRead while sqlite3 integrity_check=ok)
