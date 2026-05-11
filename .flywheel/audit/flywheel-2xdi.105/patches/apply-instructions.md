# JSM-import-ready paired patch — research-triad SKILL.md

**Skill:** `~/.claude/skills/research-triad` (JSM-unmanaged at apply time)
**Bead:** flywheel-2xdi.105
**Discipline:** direct mutation applied + paired patch artifact written, per `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`

## What the patch does

Adds a new "## Operator scripts" section to `SKILL.md` immediately after the
existing "## Substrate" section. Documents `scripts/check-goldens.sh` as an
operator-on-demand utility for golden-master regression checks on dogfood
queries.

## Direct mutation already applied

Per the unmanaged-skill discipline (`jsm show research-triad` → "not found"
== unmanaged), direct mutation was applied to the live SKILL.md as part of
this bead's worker-tick. The patch artifact below records the change for
future JSM-import discipline.

## Apply (when research-triad later gets JSM-imported)

```bash
cd <skillos-workspace>/research-triad
patch -p1 < .flywheel/audit/flywheel-2xdi.105/patches/SKILL.md.patch
# Verify
diff SKILL.md .flywheel/audit/flywheel-2xdi.105/patches/SKILL.md.proposed
# After remaining skill changes are also imported, push:
jsm push .
```

## Verify post-apply

```bash
SKILL_DIR=~/.claude/skills/research-triad
grep -q "scripts/check-goldens.sh" "$SKILL_DIR/SKILL.md" && echo OK || echo MISSING

# Probe should no longer flag the script as wired-but-cold
bash .flywheel/scripts/gap-hunt-probe.sh --json \
  | jq '.gap_ids[] | select(test("wired-but-cold.*check-goldens"))'
# expect empty output
```

## Files in this patches/ dir

- `SKILL.md.original` — copy of live SKILL.md pre-mutation (200 lines)
- `SKILL.md.proposed` — proposed/applied result (208 lines = +8)
- `SKILL.md.patch` — unified diff, 14 lines
- `apply-instructions.md` — this file

## Rollback

```bash
cd ~/.claude/skills/research-triad
patch -p1 -R < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-2xdi.105/patches/SKILL.md.patch
```

`no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`
