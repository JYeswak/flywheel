# JSM-push-ready patch — agent-ergonomics SKILL.md tools/ entries

**Skill:** `agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools`
**JSM status:** managed (per `jsm list`)
**Source bead:** flywheel-b6p1m
**Sister:** flywheel-xhevf (scripts/ side; merge order independent)

## Why a patch instead of direct mutation

Skill is JSM-managed; dispatch contract forbids direct mutation. Owning JSM/skillos flow must apply this patch and `jsm push`.

## What the patch does

Adds 10 rows to the `## Tools` table in `SKILL.md`, documenting per-workspace utilities that exist in `tools/` but were not previously referenced in SKILL.md prose. Sister to flywheel-xhevf which did the same for `scripts/`.

Tools added: audit-doctor, audit-compare, audit-narrative, explain-score, explain-rec, reconcile-scores, provenance-query, telemetry-summary, cost-cap, generate-pr-comment.

## Apply

```bash
cd <skillos-workspace>/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch
jsm push .
```

If the canonical source is `~/.claude/skills/<skill>` itself:

```bash
cd ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch
jsm push .
```

## Order with xhevf

The two patches (xhevf scripts/ + b6p1m tools/) touch different parts of SKILL.md (lines ~620 vs ~644). They can be applied in either order. If applying both in the same session:

```bash
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch
jsm push .
```

The b6p1m patch context references `tools/flip_applied.sh` which is at the same line in both pre-xhevf and post-xhevf states (xhevf adds rows in the Scripts table, ~14 lines earlier). Post-xhevf, the patch context line shifts but the patch still applies (fuzz tolerated by `patch`).

## Verify post-apply

```bash
SKILL_DIR=~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools
missing=0
for t in $(ls "$SKILL_DIR/tools/"); do
  grep -q "tools/$t" "$SKILL_DIR/SKILL.md" || { missing=$((missing+1)); echo "missing: $t"; }
done
echo "missing total: $missing"   # expect 0
```

## Rollback

```bash
patch -p1 -R < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch
```
