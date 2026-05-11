# flywheel-b6p1m — Evidence Pack

**Bead:** flywheel-b6p1m (P4)
**Title:** [skill-hygiene] agent-ergonomics SKILL.md missing tools/ entries (10+ undocumented utilities)
**Mission fitness:** `adjacent` — skill-docs hygiene supports gap-hunt-probe accuracy.
**Sister:** flywheel-xhevf (scripts/ side, shipped earlier this session)

## Acceptance gates (3)

| # | Gate | Status |
|---|---|---|
| AG1 | Audit agent-ergonomics tools/*.sh against SKILL.md mentions | DONE — 7 mentioned, 10 missing |
| AG2 | Add SKILL.md references for missing tools as JSM-push-ready patch (sister to xhevf) | DONE — patch artifact at `.flywheel/audit/flywheel-b6p1m/patches/` |
| AG3 | Verify patch applies cleanly | DONE — `patch -p1 --dry-run` + `patch -p1` both succeed on fresh copy |

## JSM discipline

Skill is JSM-managed. Patch artifact produced; no live mutation. Same disposition as xhevf:
`no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`

## Findings

### Audit (AG1)

```
tools/ inventory: 17 files
mentioned in SKILL.md: 7
NOT mentioned: 10
```

Missing list (10 tools/ files added by patch):
audit-doctor, audit-compare, audit-narrative, explain-score, explain-rec, reconcile-scores, provenance-query, telemetry-summary, cost-cap, generate-pr-comment.

Note: `tools/audit-narrative.sh` is the one currently flagged wired-but-cold by gap-hunt-probe (per flywheel-xhevf evidence). Its empirical flip-to-warm is still gated on `flywheel-zsk2d` probe-cap regression fix; this patch addresses the SKILL.md side.

## Verification

| Gate | Command | Result |
|---|---|---|
| Audit | `for t in $(ls tools/); do grep -q "tools/$t" SKILL.md && OK \|\| MISSING; done` | 7 mentioned / 10 missing |
| Patch generation | `diff -u --label a/SKILL.md --label b/SKILL.md ...` | 19-line unified diff |
| Patch dry-run | `patch -p1 --dry-run < SKILL.md.patch` on fresh copy of live SKILL.md | `patching file SKILL.md` (clean) |
| Patch apply | `patch -p1 < SKILL.md.patch` on fresh copy | applied; `diff -q` against `.proposed` → identical |

## DID / DIDNT / GAPS

- **DID 3/3** — AG1, AG2, AG3 all met
- **DIDNT none**
- **GAPS none** — `flywheel-zsk2d` (probe per-file-cap regression) was already filed in xhevf; this bead doesn't surface new ones.

## Files Changed

NONE in flywheel repo source. Only audit-pack:
- `.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.original` (snapshot, 748 lines)
- `.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.proposed` (758 lines = +10)
- `.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch` (unified diff, 19 lines)
- `.flywheel/audit/flywheel-b6p1m/patches/apply-instructions.md`
- `.flywheel/audit/flywheel-b6p1m/evidence.md` (this file)
- `.flywheel/audit/flywheel-b6p1m/compliance-pack.md`
- `.flywheel/audit/flywheel-b6p1m/journey/audit-log.txt`

NO direct mutation of live SKILL.md.

## L112 Probe

- `l112_probe_command`: `patch -p1 --dry-run < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch < ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`
- `l112_probe_expected`: `grep:patching file`
- `l112_probe_timeout_sec`: `10`

## Four-Lens Self-Grade

- **brand:** 9 — sister-pattern faithful to xhevf
- **sniff:** 10 — covers all 10 missing tools; coverage assertion clean
- **jeff:** 9 — JSM discipline preserved
- **public:** 9 — apply-instructions documents order-independence with xhevf

`no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`
