# JSM-import-ready paired patch — cubcloud-ops SKILL.md

**Skill:** `~/.claude/skills/cubcloud-ops` (JSM-unmanaged at apply time)
**Bead:** flywheel-2xdi.99
**Discipline:** direct mutation applied + paired patch per `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`

## What the patch does

Adds a WireGuard tunnel bring-up subsection inside the existing
"### Access Patterns" section. Documents `scripts/setup-cubcloud-wireguard.sh`
as an operator-on-demand utility with bring-up + reinstall + secrets-handling
notes.

## Direct mutation already applied

`jsm show cubcloud-ops` → "not found" → unmanaged. Direct mutation applied
to live SKILL.md as part of this bead's worker-tick.

## Apply (when cubcloud-ops later gets JSM-imported)

```bash
cd <skillos-workspace>/cubcloud-ops
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-2xdi.99/patches/SKILL.md.patch
diff SKILL.md /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-2xdi.99/patches/SKILL.md.proposed
jsm push .
```

## Verify post-apply

```bash
SKILL_DIR=~/.claude/skills/cubcloud-ops
grep -q "scripts/setup-cubcloud-wireguard.sh" "$SKILL_DIR/SKILL.md" && echo OK

bash .flywheel/scripts/gap-hunt-probe.sh --json \
  | jq '.gap_ids[] | select(test("wired-but-cold.*setup-cubcloud-wireguard"))'
# expect empty
```

## Rollback

```bash
cd ~/.claude/skills/cubcloud-ops
patch -p1 -R < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-2xdi.99/patches/SKILL.md.patch
```

`no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`
