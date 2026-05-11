# flywheel-xhevf — Evidence Pack

**Bead:** flywheel-xhevf (P3)
**Title:** [skill-hygiene] agent-ergonomics SKILL.md should document operator-on-demand scripts to eliminate wired-but-cold FP cluster
**Mission fitness:** `adjacent` — skill-docs hygiene supports gap-hunt-probe accuracy, which supports continuous orch uptime.

## Acceptance gates (4)

| # | Gate | Status |
|---|---|---|
| AG1 | Audit agent-ergonomics scripts/*.sh against SKILL.md mentions | DONE — 26 mentioned, 21 missing |
| AG2 | Add SKILL.md references for documented operator-on-demand scripts | DONE — as JSM-push-ready patch artifact (skill is JSM-managed; direct mutation forbidden) |
| AG3 | Re-run gap-hunt-probe; verify 10+ flagged scripts no longer in wired-but-cold list | DEFERRED — gated on (a) JSM push of patch artifact AND (b) probe-cap regression fix `flywheel-zsk2d` |
| AG4 | Receipt at `.flywheel/audit/<this-bead>/evidence.md` with before/after counts | DONE — this file |

## JSM discipline (forced patch-artifact path)

Skill `agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools` is JSM-managed (per `jsm list` and `.flywheel/scripts/skill-enhance-jsm-discipline.sh --validate-packet`). Dispatch packet's `SKILL-ENHANCE JSM DISCIPLINE BLOCK` explicitly forbids direct live mutation; produced `jsm-push-ready` patch artifact instead.

**Patch artifact:** `.flywheel/audit/flywheel-xhevf/patches/`
- `SKILL.md.original` — snapshot of live SKILL.md (748 lines)
- `SKILL.md.proposed` — proposed result (770 lines = +22)
- `SKILL.md.patch` — unified diff, `patch -p1 < SKILL.md.patch` applies cleanly (verified against fresh copy)
- `apply-instructions.md` — how-to-apply + verification + rollback

## Findings

### Audit (AG1)

```
scripts/ inventory: 47 files
mentioned in SKILL.md: 26
NOT mentioned: 21
```

Missing list (21 scripts/ files added by patch):
preview.sh, estimate.sh, archetype-calibrate.sh, rubric-calibrate.sh,
rubric-fitness.sh, scorer-prompt-fitness.sh, dryrun-llm.sh, dryrun-verify.sh,
stub-scorer.sh, diff_test.sh, dirty-surfaces.sh, cluster-recommendations.sh,
render_scorecard_html.sh, audit-replay.sh, migrate-scores.sh,
validate-artifacts-strict.sh, verify-non-tty-discipline.sh, skill-self-test.sh,
log-provenance.sh, log-telemetry.sh, watch.sh, workspace-gc.sh

### Pre-patch baseline (gap-hunt-probe)

```bash
bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '{
  ergonomics_cold_count: ([.gap_ids[] | select(startswith("wired-but-cold:") and contains("agent-ergonomics-and-agent-intuitiveness"))] | length),
  total_cold_count: ([.gap_ids[] | select(startswith("wired-but-cold:"))] | length)
}'
```

Result:
- `ergonomics_cold_count: 14` (13 scripts/ + 1 tools/)
- `total_cold_count: 20` (the probe's cap)

### Coverage check (proposed SKILL.md vs flagged scripts)

For each currently-flagged script, the proposed SKILL.md contains the name:
- 13 of 14 covered (all scripts/ entries; 6 newly-added rows for the unmentioned subset; 7 ALREADY in SKILL.md but past the 4KB cap)
- 1 not covered: `tools/audit-narrative.sh` (out-of-scope; filed as `flywheel-b6p1m`)

### Sub-discoveries

1. **flywheel-zsk2d (P2):** gap-hunt-probe's `skill_md_corpus` per-file 4KB cap (introduced by 2xdi.66) truncates SKILL.md content past byte-4096. The Scripts table in this skill's SKILL.md starts at line 596 — already-mentioned scripts (audit-readme-vs-help, build-canonical-tasks, measure-help-readtime, run_simulation, sw-self-audit, verify-determinism, verify-non-tty-discipline) ARE in SKILL.md but past the cap, so they show cold. AG3 requires this probe fix to flip them empirically.

2. **flywheel-b6p1m (P4):** `tools/` directory has 17 utilities, only 7 documented. Same pattern as this bead but for tools/, filed as sister.

## DID / DIDNT / GAPS

- **DID 3/4** — AG1, AG2 (as patch artifact), AG4
- **DIDNT** = AG3 deferred (`flywheel-zsk2d`); requires JSM push + probe fix
- **GAPS** = `flywheel-zsk2d` (P2 probe per-file-cap regression) + `flywheel-b6p1m` (P4 tools/ sister)

## Files Changed

NONE in flywheel repo source. Only audit-pack files:
- `.flywheel/audit/flywheel-xhevf/patches/SKILL.md.original` (snapshot, 748 lines)
- `.flywheel/audit/flywheel-xhevf/patches/SKILL.md.proposed` (770 lines)
- `.flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch` (unified diff, 31 lines)
- `.flywheel/audit/flywheel-xhevf/patches/apply-instructions.md`
- `.flywheel/audit/flywheel-xhevf/evidence.md` (this file)
- `.flywheel/audit/flywheel-xhevf/compliance-pack.md`
- `.flywheel/audit/flywheel-xhevf/journey/...`

NO direct mutation of `~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md` (JSM-managed; patch is push-ready).

## L112 Probe

- `l112_probe_command`: `patch -p1 --dry-run < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch < ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`
- `l112_probe_expected`: `grep:patching file`  (verifies patch applies cleanly without errors)
- `l112_probe_timeout_sec`: `10`

(Note: AG3's empirical verification ("10+ flagged scripts unflag") is post-JSM-push + post-zsk2d-fix; not testable in this bead's window.)

## Four-Lens Self-Grade

- **brand:** 9 — honors JSM-managed-skill discipline; patch artifact is reproducible + reversible
- **sniff:** 9 — coverage check confirms the patch addresses the named target class; sub-discoveries called out
- **jeff:** 9 — discovered regression in 2xdi.66 (the per-file cap); surfaced with concrete acceptance gates
- **public:** 9 — apply-instructions.md is operator-pasteable; rollback documented

`no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`
