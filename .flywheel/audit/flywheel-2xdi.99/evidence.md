# flywheel-2xdi.99 — Evidence Pack

**Bead:** flywheel-2xdi.99 (P3)
**Title:** [gap-wired-but-cold] `.claude/skills/cubcloud-ops/scripts/setup-cubcloud-wireguard.sh`
**Mission fitness:** `adjacent` — operator-on-demand utility documented in SKILL.md (corpus #4 hit)
**Sister recipe:** flywheel-2xdi.105 (shipped earlier this tick; same unmanaged-skill mutation pattern)

## Hypothesis vs root cause (N=20 bead-hypothesis META-rule)

**Bead hypothesis:** script not referenced by recent flywheel jsonl ledgers in 30d.

**Verified:**
- Script EXISTS, well-documented (WireGuard tunnel bring-up; FortiClient/Tailscale alternative path)
- ZERO references in any of the 5 corpora — including its own SKILL.md
- One reference in `LATEST.md.legacy` (legacy doc; not a current corpus surface)
- JSM status: `jsm show cubcloud-ops` → "not found" → **unmanaged**
- File mode `-rw-------` (not currently executable) — operator must `chmod +x` before invoking; the script self-chmods itself 600 on first run for secret protection

## Fix

Per `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`:
- JSM-unmanaged → direct mutation + paired jsm-import-ready patch artifact

Applied:
1. Direct mutation of `~/.claude/skills/cubcloud-ops/SKILL.md` — added a WireGuard tunnel bring-up subsection inside the existing "### Access Patterns" section. Documents the script's purpose, idempotency contract (`--reinstall` flag), secrets handling (owner-readable; self-chmod to 600), and when to invoke (FortiClient/Tailscale unavailable).
2. Updated the inline access-methods comment from 2 methods to 3 (added "3. WireGuard tunnel").
3. Paired jsm-import-ready patch artifact at `.flywheel/audit/flywheel-2xdi.99/patches/`.

`no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`

## Acceptance gates

| Gate | Status |
|---|---|
| AG1: Identify cold gap empirically + verify JSM status | DONE — 0 corpus hits, unmanaged |
| AG2: Apply skill-side fix per cross-repo-mutator discipline | DONE — direct mutation + paired patch |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ jsm show cubcloud-ops
Skill 'cubcloud-ops' not found.

$ grep -q "scripts/setup-cubcloud-wireguard.sh" ~/.claude/skills/cubcloud-ops/SKILL.md && echo OK
OK

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("wired-but-cold.*setup-cubcloud-wireguard"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, skill mutated, gap cleared
- **DIDNT none**
- **GAPS none**

## Files Changed

- `~/.claude/skills/cubcloud-ops/SKILL.md` (direct mutation; +14 lines net inside Network Architecture section)
- `.flywheel/audit/flywheel-2xdi.99/patches/SKILL.md.{original,proposed,patch}` (25-line unified diff)
- `.flywheel/audit/flywheel-2xdi.99/patches/apply-instructions.md`
- `.flywheel/audit/flywheel-2xdi.99/{evidence,compliance-pack}.md`

## L112 Probe

- `l112_probe_command`: `grep -q "scripts/setup-cubcloud-wireguard.sh" ~/.claude/skills/cubcloud-ops/SKILL.md && bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("wired-but-cold.*setup-cubcloud-wireguard"))' | wc -l | tr -d ' '`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `60`

## Pattern reinforcement

**11th distinct fix shape** in 2xdi.* cluster (same shape as 2xdi.105):
- 47/49/64/66 = probe corpus extensions
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- dnxjb = probe-finder path filter
- 9a3k1 = auto-bead-filer dedup
- 109 = doctrine cross-link + faqj2 harvest
- 105/99 = unmanaged-skill direct mutation + paired patch (N=2 instances now)

Cross-repo-mutator pattern N=7 instances this session (xhevf, b6p1m, n4gt1, myfak.1, d6zk1.1, 105, 99). At N=10 this becomes a candidate doctrine sub-section (currently a paragraph in the boundary doctrine; could expand to a full procedural checklist).

## Four-Lens Self-Grade

- **brand:** 10 — faithful sister of 2xdi.105 recipe; consistent application
- **sniff:** 9 — natural placement inside Network Architecture > Access Patterns
- **jeff:** 9 — convergent with 2xdi.* cluster; pattern proven
- **public:** 9 — future operator finding cubcloud-ops needs to bring up WG sees the canonical script reference + idempotency notes + secrets-handling caveat
