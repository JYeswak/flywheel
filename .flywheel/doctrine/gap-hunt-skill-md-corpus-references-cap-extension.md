# gap-hunt-probe skill_md_corpus references/*.md per-file cap extension (2xdi.98)

**Class:** META-RULE corpus per-file cap raise for `wired-but-cold` false-positive class
**Filed:** 2026-05-11
**Origin bead:** flywheel-2xdi.98 (P3) — `[gap-wired-but-cold] .claude/skills/cubcloud-ops/scripts/litellm-deep-probe.sh`
**Same META-RULE shape as:** 2xdi.66 (raised SKILL.md cap 4 KB → 256 KB), 2xdi.88 (test corpus glob extension)

## META-RULE

**Fix the corpus per-file budget, not the per-script allowlist.**

When `gap-hunt-probe.sh` flags a `<skill>/scripts/<x>.sh` script as
`wired-but-cold`, verify the FULL doc corpus is being read (especially
`<skill>/references/*.md`) BEFORE filing a per-script wire-in bead or
allowlist row. The probe is false-positive when:

1. The script IS referenced in a `<skill>/references/*.md` doc, AND
2. The first reference appears BEYOND byte 4096 of that doc (the
   pre-2xdi.98 per-file cap), so the corpus silently truncates the
   reference out.

The fix is a 3-pass structure: SKILL.md (256 KB) → references/*.md
(128 KB) → other-*.md (4 KB), not per-script exception.

## Why this works

The canonical skill documentation pattern places:
- **SKILL.md** at skill root (canonical entry doc; 256 KB cap per 2xdi.66)
- **references/*.md** for deeper material (operator workflows, technical
  specs, examples — often 5-100 KB; references in body)
- **examples/**, **assets/**, sibling docs — supporting material

The pre-2xdi.98 corpus gave SKILL.md privileged treatment (256 KB cap) but
folded `references/*.md` into the generic "other md" tier with a 4 KB cap.
The 4 KB cap silently truncated 5+ skill reference docs where flagged
scripts were documented at byte position 4591-89124:

| Reference doc | Flagged script | First-ref byte | File size |
|---|---|---|---|
| `cubcloud-ops/references/LITELLM-MODEL-SPEC.md` | litellm-deep-probe.sh | 12925 | 13968 |
| `git-worktree-branch-rationalization/references/OPERATOR-LIBRARY.md` | conflict-replay.sh | 89124 | 89553 |
| `git-worktree-branch-rationalization/references/OPERATOR-LIBRARY.md` | workspace-export.sh | 88231 | 89553 |
| `documentation-website-for-software-project/references/EXTENDED-PROJECT-TYPES.md` | test-harness.sh* | 6137 | 15706 |
| `mcp-server-design/references/TESTING-PATTERNS.md` | statusline.sh | 4591 | (small) |

\* test-harness.sh remains flagged due to a SEPARATE case-sensitivity bug
in `wired-but-cold`'s substring check (the script is `TEST-HARNESS.sh` all
caps; the doc references `test-harness.mdx` lowercase). That's a different
META-RULE candidate — out of scope for 2xdi.98.

## The fix (3-pass structure)

`.flywheel/scripts/gap-hunt-probe.sh` `skill_md_corpus()`:

```python
# Pre-2xdi.98
skill_md_per_file_cap = 256 * 1024  # SKILL.md priority (2xdi.66)
other_md_per_file_cap = 4_096       # all-other-md including references/

# Post-2xdi.98 (3-pass)
skill_md_per_file_cap = 256 * 1024
references_md_per_file_cap = 128 * 1024  # NEW: privileged tier for references/*.md
other_md_per_file_cap = 4_096

# Pass 1: SKILL.md (256 KB cap)
# Pass 2 (NEW): references/*.md, identified by `any(part == "references" for part in p.parts)` (128 KB cap)
# Pass 3: all-other-md (4 KB cap)
```

128 KB cap covers the largest observed `references/*.md` (116 KB in
`tax-return-preparation-and-advice-generic/references/strategies/ADVANCED-STRATEGIES.md`).

## Verified leverage (4-for-1 in same gap-hunt run)

Single extension resolves 4 OPEN P3 false-positive `wired-but-cold` beads:

| Bead | Subject | references/*.md hit | Status |
|---|---|---|---|
| flywheel-2xdi.98 | cubcloud-ops/scripts/litellm-deep-probe.sh | `cubcloud-ops/references/LITELLM-MODEL-SPEC.md:299` | RESOLVED |
| (sister, no bead) | git-worktree-branch-rationalization/scripts/conflict-replay.sh | `OPERATOR-LIBRARY.md` byte 89124 | RESOLVED |
| (sister, no bead) | git-worktree-branch-rationalization/scripts/workspace-export.sh | `OPERATOR-LIBRARY.md` byte 88231 | RESOLVED |
| (sister, no bead) | mcp-server-design/scripts/statusline.sh (mapped to nano-banana statusline) | `mcp-server-design/references/TESTING-PATTERNS.md` byte 4591 | RESOLVED |

## Budget impact

3278 `references/*.md` files exist across the skill tree, totaling 28 MB of
content. Overall corpus cap is 32 MB; the new tier fits comfortably.

| Pass | Files | Per-file cap | Worst-case budget |
|---|---|---|---|
| 1 (SKILL.md) | ~113 | 256 KB | 29 MB if all hit max (unlikely; observed max 137 KB) |
| 2 (references/*.md) | 3278 | 128 KB | 28 MB (matches observed total content) |
| 3 (other-md) | ~2600 | 4 KB | 10 MB |
| **Overall cap** | — | — | **32 MB** (truncation graceful) |

## What this is NOT

- NOT a relaxation of wire-in discipline. Scripts that are GENUINELY
  unreferenced still get flagged; the fix targets per-file budget, not
  the receiver-check semantics.
- NOT a fix for case-sensitivity (test-harness.sh / TEST-HARNESS.sh class).
  That's a separate META-RULE candidate.
- NOT a substitute for SKILL.md doc completeness. Scripts SHOULD be
  mentioned in SKILL.md when they're canonical entry points; references/*.md
  is the appropriate surface for deeper operator material.

## Regression test

`.flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh` locks
in 5 AGs:
- AG1 `references_md_per_file_cap` + 3-pass structure present
- AG2 litellm-deep-probe.sh no longer flagged
- AG3 sister leverage: 3/3 sister resolutions (conflict-replay, workspace-export, statusline)
- AG4 prior 2xdi.66 SKILL.md 256 KB cap preserved
- AG5 bash -n syntax check

Run quick: `TEST_QUICK=1 .flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh`
Run full: `.flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh`

## Cross-references

- Sister extension: 2xdi.88 (test_files_corpus canonical-cli glob) — 9th
  this session; 2xdi.98 is the 10th
- Precedent for per-file cap fix: 2xdi.66 (raised SKILL.md 4 KB → 256 KB)
- META-RULE precedent: `.flywheel/doctrine/bead-hypothesis-starting-point.md`
- Out-of-scope sister: case-sensitivity in wired-but-cold substring check
  (test-harness.sh vs TEST-HARNESS.sh stem capture) — captured here for
  future maintainer; not auto-filed


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-15 — canonical CLI scoping:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-15-canonical-cli-scoping.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-27 — exact prompt/output template:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-27-exact-prompt-output-template.md` for the canonical pattern.
