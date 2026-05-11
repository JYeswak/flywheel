# JSM-import-ready paired patch — research-triad SKILL.md (batch hygiene)

**Skill:** `~/.claude/skills/research-triad` (JSM-unmanaged at apply time)
**Bead:** flywheel-03yaj
**Discipline:** Joshua-authorized cross-repo batch mutation + paired patch artifact per `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`

## What the patch does

Appends a "### Scripts inventory (canonical)" subsection to the existing
"## Operator scripts" section in `SKILL.md`. Documents the COMPLETE
31-script inventory of `scripts/` in 7 capability-cluster tables:

1. **Spend-ledger + cost accounting** (5 scripts)
2. **Axis pollers + research-axis maintenance** (6 scripts)
3. **Native build + Rust query path** (2 scripts)
4. **Calibration + validation** (6 scripts)
5. **Trauma / incident-archive surfaces** (2 scripts)
6. **X follow-graph + cluster mining** (5 scripts; one cross-listed with cluster 1)
7. **Local-grep + socraticode adapter** (1 script)

The 5 pre-existing scripts in SKILL.md (`check-goldens.sh`, `build-spend-ledger-rust.sh`, `perf-bench.sh`, plus 2 inline narrative mentions) keep their existing form; the new table documents the 26 previously-undocumented scripts.

## Direct mutation already applied

`jsm show research-triad` → "not found" → unmanaged. Joshua authorized
cross-repo batch dispatch (precedent: 2xdi.119 PERFECT 1000). Direct
mutation applied to live SKILL.md during this worker-tick.

## Apply (when research-triad later gets JSM-imported)

```bash
cd <skillos-workspace>/research-triad
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-03yaj/patches/SKILL.md.patch
diff SKILL.md /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-03yaj/patches/SKILL.md.proposed
jsm push .
```

If patches in `.flywheel/audit/flywheel-2xdi.105/patches/` are still
unapplied (the prior single-script `check-goldens.sh` patch), apply that
one FIRST — its context overlaps with this patch's anchor lines.

## Verify post-apply

```bash
SKILL_DIR=~/.claude/skills/research-triad
mentioned=0; missing=0
for f in $(ls "$SKILL_DIR/scripts/"); do
  grep -q "scripts/$f" "$SKILL_DIR/SKILL.md" || missing=$((missing+1))
  grep -q "scripts/$f" "$SKILL_DIR/SKILL.md" && mentioned=$((mentioned+1))
done
echo "coverage: $mentioned / 31, missing: $missing"  # expect 31/31, 0 missing

bash .flywheel/scripts/gap-hunt-probe.sh --json \
  | jq '[.gap_ids[] | select(test("wired-but-cold.*research-triad"))] | length'
# expect 0
```

## Rollback

```bash
cd ~/.claude/skills/research-triad
patch -p1 -R < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-03yaj/patches/SKILL.md.patch
```

## Subordinate beads closed in same tick

Per the bead body's "Auto-close all subordinate auto-beads with
resolved-upstream disposition" requirement:

- flywheel-2xdi.121 (research-axis-status.sh) — CLOSED
- flywheel-2xdi.122 (research-query-route-fix-test.sh) — CLOSED
- flywheel-2xdi.123 (spend-ledger-fast.sh) — CLOSED
- flywheel-2xdi.124 (trauma-ingest-test.sh) — CLOSED

flywheel-2xdi.119 + flywheel-2xdi.120 were already closed pre-tick.

`no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`
