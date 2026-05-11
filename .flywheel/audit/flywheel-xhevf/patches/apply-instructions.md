# JSM-push-ready patch — agent-ergonomics SKILL.md

**Skill:** `agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools`
**JSM status:** managed (per `jsm list` + `skill-enhance-jsm-discipline.sh --validate-packet`)
**Source bead:** flywheel-xhevf

## Why a patch instead of direct mutation

This skill is JSM-managed. The dispatch packet's `SKILL-ENHANCE JSM DISCIPLINE BLOCK` forbids direct live mutation under `~/.claude/skills/<skill>/` for JSM-managed skills. The owning JSM/skillos flow must apply this patch and `jsm push` so the canonical cloud source stays the truth.

## What the patch does

Adds 21 rows to the `## Scripts` table in `SKILL.md`, documenting operator-on-demand scripts that exist in `scripts/` but were not previously referenced in `SKILL.md` prose. This eliminates a wired-but-cold false-positive cluster surfaced by `gap-hunt-probe` (see `flywheel-xhevf` evidence pack for the audit + counts).

No content is removed. No phase-loop scripts are reclassified. The skill's existing structure (one Scripts table containing both phase-loop and utility scripts) is preserved.

## Apply

In the skillos workspace where the canonical JSM source lives:

```bash
cd <skillos-workspace>/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
patch -p1 < .flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch
# Verify
diff SKILL.md .flywheel/audit/flywheel-xhevf/patches/SKILL.md.proposed
# Push
jsm push .
```

If the canonical source is `~/.claude/skills/<skill>` itself (no separate skillos workspace):

```bash
cd ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch
jsm push .
```

## Verify post-apply

```bash
# All 47 scripts mentioned in SKILL.md after patch
SKILL_DIR=~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
missing=0
for s in $(ls "$SKILL_DIR/scripts/"); do
  grep -q "scripts/$s" "$SKILL_DIR/SKILL.md" || { missing=$((missing+1)); echo "missing: $s"; }
done
echo "missing total: $missing"   # expect 0
```

```bash
# gap-hunt-probe wired-but-cold count drops by ~10 for this skill's scripts
bash .flywheel/scripts/gap-hunt-probe.sh --json \
  | jq '.gap_ids | map(select(test("wired-but-cold:.claude-skills-agent-ergonomics-and-agent-intuitiveness"))) | length'
# Pre-patch: ≥10; post-patch + cache refresh: expect 0 or near-0
```

## Files in this patches/ dir

- `SKILL.md.original` — copy of live SKILL.md at patch-generation time (`748` lines)
- `SKILL.md.proposed` — proposed result (`770` lines = +22)
- `SKILL.md.patch` — unified diff, applies via `patch -p1`
- `apply-instructions.md` — this file

## Rollback

If the patch needs to be reverted:

```bash
cd ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
patch -p1 -R < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch
```
