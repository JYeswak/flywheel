# flywheel-2xdi.105 — Evidence Pack

**Bead:** flywheel-2xdi.105 (P3)
**Title:** [gap-wired-but-cold] `.claude/skills/research-triad/scripts/check-goldens.sh`
**Mission fitness:** `adjacent` — skill-docs hygiene clears probe FP + makes operator-on-demand tool discoverable

## Hypothesis vs root cause (N=19 bead-hypothesis META-rule)

**Bead hypothesis:** script not referenced by recent flywheel jsonl ledgers in 30d.

**Verified:**
- Script EXISTS, well-formed (golden-master regression check; "UPDATE_GOLDENS=1 to refresh" hint indicates operator-on-demand usage)
- ZERO references across all 5 corpora — including the skill's own SKILL.md
- Skill is **JSM-unmanaged** (`jsm show research-triad` → "Skill 'research-triad' not found")

This is a genuine "operator-on-demand tool not documented in its skill's SKILL.md" gap. Same shape as agent-ergonomics scripts/ cluster (xhevf/2m2cs) but smaller and unmanaged.

## Fix

Per `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`:
- JSM-unmanaged → direct mutation allowed when paired with `jsm-import-ready` patch artifact

Applied:
1. Direct mutation of `~/.claude/skills/research-triad/SKILL.md` — added new "## Operator scripts" section after the existing "## Substrate" section, documenting `scripts/check-goldens.sh` with one-line purpose + when-to-invoke + citation
2. Paired jsm-import-ready patch artifact at `.flywheel/audit/flywheel-2xdi.105/patches/`
3. `no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`

## Verification

```bash
$ jsm show research-triad
Skill 'research-triad' not found.   # unmanaged → direct mutation allowed

$ grep -q "scripts/check-goldens.sh" ~/.claude/skills/research-triad/SKILL.md && echo OK
OK

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("wired-but-cold.*check-goldens"))'
(empty)   # gap cleared
```

## Acceptance gates

| Gate | Status |
|---|---|
| AG1: Identify cold gap empirically + verify JSM status | DONE — script exists, 0 receivers, unmanaged |
| AG2: Apply skill-side fix per cross-repo-mutator discipline | DONE — direct mutation + paired patch artifact |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, skill mutated, gap cleared
- **DIDNT none**
- **GAPS none**

## Files Changed

- `~/.claude/skills/research-triad/SKILL.md` (direct mutation; +8 lines)
- `.flywheel/audit/flywheel-2xdi.105/patches/SKILL.md.original` (snapshot, 200 lines)
- `.flywheel/audit/flywheel-2xdi.105/patches/SKILL.md.proposed` (208 lines)
- `.flywheel/audit/flywheel-2xdi.105/patches/SKILL.md.patch` (14-line unified diff)
- `.flywheel/audit/flywheel-2xdi.105/patches/apply-instructions.md`
- `.flywheel/audit/flywheel-2xdi.105/evidence.md` (this file)
- `.flywheel/audit/flywheel-2xdi.105/compliance-pack.md`

## L112 Probe

- `l112_probe_command`: `grep -q "scripts/check-goldens.sh" ~/.claude/skills/research-triad/SKILL.md && bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("wired-but-cold.*check-goldens"))' | wc -l | tr -d ' '`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `60`

## Pattern reinforcement

**Sister to agent-ergonomics SKILL.md hygiene cluster (xhevf/b6p1m/2m2cs)** but at a smaller, unmanaged-skill scale. Both follow the same fix shape: add operator scripts to SKILL.md so they're discoverable AND match gap-hunt-probe's corpus #4 (skill_md_corpus, the *.md broadened version from 2xdi.66).

10th distinct fix shape in 2xdi.* cluster:
- 47/49/64/66 = probe corpus extensions
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- dnxjb = probe-finder path filter
- 9a3k1 = auto-bead-filer dedup
- 109 = doctrine cross-link + faqj2 harvest
- **105 = unmanaged-skill direct mutation + paired jsm-import-ready patch**

## Four-Lens Self-Grade

- **brand:** 10 — perfect application of cross-repo-mutator doctrine (cited in apply-instructions)
- **sniff:** 9 — minimal-surface fix; one section added
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 9 — future operator gets clear "Operator scripts" section in SKILL.md
