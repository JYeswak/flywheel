# JSM-import-ready patch — flywheel-n4gt1

## Status

**This patch HAS ALREADY been applied to the working tree at
`/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md`** per
Joshua-authorized cross-repo escape hatch (2026-05-11), citing the
2xdi.60.1 + `feedback_cross_repo_consumer_vs_mutator_distinction` precedent
for jsm-unmanaged skills.

The artifacts in this directory exist as a JSM-import-ready snapshot so the
change can be replayed elsewhere or imported into JSM if `canonical-cli-scoping`
later becomes managed.

## Artifacts

| File | Purpose |
|---|---|
| `SKILL.md.original` | Pre-mutation snapshot (hash `d5dd78a4…`) |
| `SKILL.md.proposed` | Post-mutation snapshot (hash `f34e58ee…`) |
| `SKILL.md.patch` | Unified diff `original → proposed` |
| `apply-instructions.md` | This file |

## What the patch adds

1. **T9 row** appended to the ALPS Trap Classes table (after T8):
   bash `=~` regex `{N,M}` quantifier runtime trap.
2. **New subsection** `### Bash regex \`=~\` no \`{N,M}\` repetition (canonical two-check form)`
   after `### Codex chevron-template trap` and before `### \`br create\` body discipline`.
   Includes broken-vs-canonical code, canonical JSON reject envelope shape,
   discovery references.
3. **Updated universal-class summary line** (line 990) to include T9 in the
   list of traps covered by this skill.

No existing content removed or reflowed. Only additive.

## Verification probe (L112)

```bash
SKILL=/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md
[ -f "$SKILL" ] && grep -q "invalid repetition count" "$SKILL" && grep -q "len >= " "$SKILL" && echo callout_present || echo callout_missing
```

Expected: `literal:callout_present`

## Replay this patch (if working tree is reverted)

```bash
cd ~/.claude/skills/canonical-cli-scoping
cp /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.original SKILL.md
patch -p0 SKILL.md < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.patch
# OR (atomic replace from snapshot)
cp /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.proposed SKILL.md
```

Both replay paths land on hash `f34e58ee51d1f9b5435dfb4f25060441c508ae11d8342fae0e3139704f10d3b4`.

## Skillos-side commit (peer-orch responsibility)

The working tree at `~/.claude/skills/` shows `M canonical-cli-scoping/SKILL.md`
(modified, not yet committed in the skillos repo). Per `project_skillos_separated`
boundary discipline, flywheel:1 does NOT commit to the skillos repo. Skillos:1
(or the next .claude/ worker session) owns the commit decision.

Suggested skillos-side commit message:

```text
docs(canonical-cli-scoping): add T9 bash =~ no {N,M} regex repetition trap

Per flywheel-898ji discovery + flywheel-n4gt1 cross-repo wire-in (Joshua-authorized
cross-repo escape hatch, 2026-05-11). META-RULE memory:
feedback_bash_regex_no_brace_repetition.md. Production reference (load-bearing):
flywheel.git/.flywheel/scripts/idempotency-replay-guard.sh:280.

Patch artifact: flywheel.git/.flywheel/audit/flywheel-n4gt1/patches/
```

## JSM import (if skill later becomes managed)

If `canonical-cli-scoping` is later registered with JSM, the import path is:

```bash
jsm import canonical-cli-scoping --from /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.proposed
```

The `.proposed` snapshot represents the canonical post-T9-wire-in state.

## Cross-references

- Parent bead (audit): `flywheel-898ji` (CLOSED 2026-05-11)
- Audit pack: `.flywheel/audit/flywheel-898ji/evidence.md`
- This bead (execution): `flywheel-n4gt1`
- This bead's evidence: `.flywheel/audit/flywheel-n4gt1/evidence.md`
- Authorization: dispatch packet §"JOSHUA-AUTHORIZED CROSS-REPO MUTATION"
- Precedent: flywheel-2xdi.60.1 (direct mutation for jsm-unmanaged skill)
- Boundary doctrine: `project_skillos_separated.md`,
  `feedback_cross_repo_consumer_vs_mutator_distinction.md`
