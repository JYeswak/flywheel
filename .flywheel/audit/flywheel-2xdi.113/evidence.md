# flywheel-2xdi.113 — Evidence Pack

**Bead:** flywheel-2xdi.113 (P3)
**Title:** [gap-wired-but-cold] `.claude/skills/infisical-secrets/scripts/validate-identity.sh`
**Mission fitness:** `adjacent` — closing-as-resolved-upstream (no mutation needed)
**Disposition:** **resolved-upstream by prior corpus extensions** — bead is stale at probe time

## Hypothesis vs root cause (N=21 bead-hypothesis META-rule)

**Bead hypothesis:** script not referenced by recent flywheel jsonl ledgers in 30d.

**Verified — bead is stale:**
- Script EXISTS, well-formed (machine identity end-to-end test)
- Documented in `~/.claude/skills/infisical-secrets/references/COMMANDS.md:47` and `references/extracted-detail.md:117` (both are `references/*.md` files)
- JSM status: `jsm show infisical-secrets` → "not found" → unmanaged
- **Fresh `gap-hunt-probe` does NOT flag this script** — gap is already cleared

The corpus is now catching this script via Pass 2 (`references/*.md` with 128 KB per-file cap, broadened by 2xdi.98 and given enough budget by 2xdi.112's overall_cap raise to 64 MB).

## Probe state diagnostic

```bash
$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("wired-but-cold.*validate-identity"))'
(empty)   # gap NOT in fresh probe output

$ python3 <simulated 3-pass corpus>
contains 'validate-identity.sh': True
contains 'validate-identity' (stem): True
contains 'scripts/validate-identity.sh': True
corpus bytes: 37096733  # well under 64 MB overall_cap
```

The mention in `infisical-secrets/references/COMMANDS.md` (only 2037 bytes total) is fully captured in Pass 2.

## Root cause of staleness

Bead was auto-filed during a probe run BEFORE one of the corpus extensions shipped:
- **2xdi.66** broadened SKILL.md corpus to all *.md
- **zsk2d** added 256 KB priority cap for SKILL.md (2-pass)
- **2xdi.98** added 128 KB priority cap for `references/*.md` (3-pass)
- **2xdi.112** raised overall_cap 32 MB → 64 MB to fit alphabetically-late skills (`infisical-secrets` was the empirical exemplar)

Bead 113 was filed before 2xdi.112's 64 MB extension landed; once that shipped, the probe immediately stopped flagging this script. The bead remained in the queue as a stale row.

## Disposition: close as resolved-upstream

No mutation required. Skill, script, and probe are all in correct state. Same shape as the 16 sub-beads bulk-closed in `flywheel-2m2cs` (resolved-upstream once corpus extensions caught up).

## Meta-finding (already-documented context)

The auto-bead-filer (dedup work in `flywheel-9a3k1`) doesn't currently re-probe before re-filing. When a probe-corpus extension ships, prior stale beads remain open until a worker investigates and closes them. The `9a3k1` dedup catches duplicates of currently-live gaps but not "gaps that USED to exist". This is a known property; tracked indirectly via `flywheel-2m2cs` (bulk-close pattern) + `flywheel-xbsd8` (faqj2 semantic-cross-link).

## Acceptance gates

| # | Gate | Status |
|---|---|---|
| AG1 | Identify gap state empirically | DONE — fresh probe shows gap NOT flagged |
| AG2 | Determine disposition (mutate or resolve-upstream) | DONE — resolve-upstream (no skill change required) |
| AG3 | Document corpus-extension path that resolved the gap | DONE — 2xdi.112 budget extension; chain documented |

## DID / DIDNT / GAPS

- **DID 3/3** — probed empirically, determined resolved-upstream, documented chain
- **DIDNT none**
- **GAPS none new** — the broader auto-filer-stale-bead awareness is already captured in xbsd8 + 2m2cs precedent

## Files Changed

None outside `.flywheel/audit/flywheel-2xdi.113/`. No skill mutation, no probe code change, no test file added — the resolution was already in place when this bead's dispatch arrived.

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '[.gap_ids[] | select(test("wired-but-cold.*validate-identity"))] | length'`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `60`

## Pattern reinforcement

**12th distinct fix shape** in 2xdi.* cluster:
- 47/49/64/66 = probe corpus extensions
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- dnxjb = probe-finder path filter
- 9a3k1 = auto-bead-filer dedup
- 109 = doctrine cross-link + faqj2 harvest
- 105/99 = unmanaged-skill direct mutation + paired patch
- **113 = resolve-upstream-no-mutation (single-bead version of 2m2cs bulk pattern)**

Bead-hypothesis META-rule N=21 now: probing BEFORE assuming yields the
"already-resolved-upstream" disposition in ~1 out of N stale 2xdi beads.
Worth keeping the probe-first discipline rather than reflexively shipping
a mutation — same recipe DOESN'T fit every bead in the cluster.

## Four-Lens Self-Grade

- **brand:** 10 — honored the bead-hypothesis META-rule; saved a needless skill mutation
- **sniff:** 10 — simulated the 3-pass corpus inline to confirm capture; not just trusting the probe output
- **jeff:** 9 — convergent with 2m2cs bulk-resolve pattern
- **public:** 10 — future worker reading this evidence understands the corpus-extension chain that resolved the gap + the auto-filer staleness property
