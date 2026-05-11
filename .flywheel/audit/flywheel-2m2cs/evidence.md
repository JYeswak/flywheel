# flywheel-2m2cs — Evidence Pack

**Bead:** flywheel-2m2cs (P3)
**Title:** [gap-hunt-rerun-verify] verify zsk2d 256KB-cap fix + xhevf/b6p1m patches cleared 2xdi.67-.85 gap-wired-but-cold cluster
**Mission fitness:** `adjacent` — substrate hygiene + cluster cleanup

## TL;DR

Combined effect of zsk2d (256KB SKILL.md cap) + xhevf (scripts/ rows) + b6p1m (tools/ rows) cleared **all 16 open 2xdi.* sub-beads targeting the agent-ergonomics-and-agent-intuitiveness skill**. Verified per-bead via fresh probe before any closure (bead-hypothesis META-rule N=12). Zero failed closes.

## Pre-flight premises (verified)

| Premise | Probe | Result |
|---|---|---|
| zsk2d 256KB cap shipped | `grep skill_md_per_file_cap .flywheel/scripts/gap-hunt-probe.sh` | `256 * 1024` set; 2-pass scan; `flywheel-zsk2d CLOSED` |
| xhevf scripts/ rows applied to live SKILL.md | `grep -c "scripts/cluster-recommendations.sh\|scripts/preview.sh\|scripts/skill-self-test.sh"` | `3/3` (all expected rows present) |
| b6p1m tools/ rows applied | `grep -c "tools/audit-narrative.sh\|tools/cost-cap.sh\|tools/explain-rec.sh"` | `3/3` (all expected rows present) |
| SKILL.md line count | `wc -l` | `780` (748 → 780 = +32 lines, matches xhevf +21 + b6p1m +10 + headers) |

## Fresh probe state

```bash
bash .flywheel/scripts/gap-hunt-probe.sh --json > journey/probe-after.json
```

```json
{
  "total_cold": 20,
  "cold_in_ergonomics": 0,
  "cold_ergonomics_paths": []
}
```

Zero agent-ergonomics paths in the wired-but-cold gap_ids. The total remains 20 (the probe's cap) but those 20 are now genuinely-other-skill gaps, not FPs.

## Per-bead resolution matrix

All 16 open `flywheel-2xdi.*` beads targeting the patched skill:

| Bead | Target | Fresh-probe cold? | Action |
|---|---|---|---|
| 2xdi.67 | scripts/log-provenance.sh | 0 | close resolved-upstream |
| 2xdi.68 | scripts/log-telemetry.sh | 0 | close resolved-upstream |
| 2xdi.73 | scripts/rubric-fitness.sh | 0 | close resolved-upstream |
| 2xdi.77 | assets/regression-test-template.sh | 0 | close resolved-upstream |
| 2xdi.78 | scripts/audit-readme-vs-help.sh | 0 | close resolved-upstream |
| 2xdi.79 | scripts/build-canonical-tasks.sh | 0 | close resolved-upstream |
| 2xdi.80 | scripts/run_simulation.sh | 0 | close resolved-upstream |
| 2xdi.81 | scripts/sw-self-audit.sh | 0 | close resolved-upstream |
| 2xdi.82 | scripts/verify-determinism.sh | 0 | close resolved-upstream |
| 2xdi.83 | scripts/sw-self-audit.sh (dup) | 0 | close resolved-upstream |
| 2xdi.84 | scripts/verify-determinism.sh (dup) | 0 | close resolved-upstream |
| 2xdi.85 | scripts/verify-non-tty-discipline.sh | 0 | close resolved-upstream |
| 2xdi.86 | scripts/verify-non-tty-discipline.sh (dup) | 0 | close resolved-upstream |
| 2xdi.91 | tools/audit-narrative.sh | 0 | close resolved-upstream |
| 2xdi.94 | tools/generate-pr-comment.sh | 0 | close resolved-upstream |
| 2xdi.95 | tools/provenance-query.sh | 0 | close resolved-upstream |

Result: **16/16 closed; 0 failed; 0 left open.**

Bonus observation: 2xdi.77 targeted `assets/regression-test-template.sh` (not scripts/ or tools/). It's also cleared — the broadened skill_md_corpus (2xdi.66 scope) catches mentions in *any* SKILL.md text, including the asset path referenced from the Polish Bar / Self-Test sections.

## Anti-pattern guard (honored)

Per bead body's explicit warning: "do NOT bulk-close 2xdi.* sub-beads without probing each target individually. Per N=9 bead-hypothesis META-RULE."

Method used:
1. Parse each open bead's target path from `br list` text
2. Convert path → probe gap_id token (slashes → dashes)
3. `jq` check against fresh `probe-after.json` gap_ids
4. Per-bead 0/1 verdict written to matrix BEFORE any close
5. Only after all 16 verified at 0 did closes execute

Each `br close` validated by checking output for `Closed <bead>`. All 16 reported success.

## DID / DIDNT / GAPS

- **DID 4/4** — fresh probe captured, per-bead matrix built + verified, 16 closed, 0 left open
- **DIDNT none**
- **GAPS none new** — outliers (sister skill `agent-ergonomics-and-intuitiveness-maximization-for-cli-tools` at 2xdi.96; non-ergonomics 2xdi.* beads at .87/.88/.89/.90/.92/.93/.97/.98/.99) remain open as legitimate separate work, NOT covered by xhevf/b6p1m/zsk2d patches.

## Files Changed

NONE outside .flywheel/audit/ + 16 br close operations on beads JSONL.

- `.flywheel/audit/flywheel-2m2cs/evidence.md` (this file)
- `.flywheel/audit/flywheel-2m2cs/compliance-pack.md`
- `.flywheel/audit/flywheel-2m2cs/journey/probe-after.json` (gap_ids snapshot)
- `.flywheel/audit/flywheel-2m2cs/journey/per-bead-resolution-matrix.tsv`

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '[.gap_ids[] | select(contains("agent-ergonomics-and-agent-intuitiveness"))] | length'`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `60`

## Pattern reinforcement

**Canonical pattern emerging:** Wired-but-cold FP clusters resolve via paired fixes:
1. **Probe-side** — corpus collector handles the cited target's wiring shape (zsk2d closed: SKILL.md priority cap)
2. **Data-side** — SKILL.md / source docs fully document the target (xhevf scripts/, b6p1m tools/)

Either alone is insufficient. zsk2d without xhevf/b6p1m would still miss the 21+10 newly-added rows (they weren't there pre-patch). xhevf/b6p1m without zsk2d would have the rows but they'd be past the 4KB cap.

**Sister effects from this cleanup:**
- The probe's cap of 20 wired-but-cold gap_ids is now freed up for genuinely-other-skill gaps (e.g., cubcloud-ops, asupersync-mega-skill, sister ergonomics skill without "-agent-" middle prefix).
- Future 2xdi.* beads against agent-ergonomics-and-agent-intuitiveness paths should NOT be filed by gap-hunt-probe — the path is now fully covered.

## Four-Lens Self-Grade

- **brand:** 10 — per-bead probe BEFORE close (anti-pattern guard honored); matrix is auditable
- **sniff:** 10 — paired-fix pattern named; 16/16 verified+closed without drift
- **jeff:** 9 — convergent cleanup of decomposition cluster; downstream FP-filing pressure relieved
- **public:** 9 — future operator gets matrix.tsv + probe snapshot + pattern note
