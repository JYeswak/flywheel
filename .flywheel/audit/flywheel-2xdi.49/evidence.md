# Evidence: flywheel-2xdi.49 — gap-hunt-probe SKILL.md corpus blind spot

**Bead**: flywheel-2xdi.49 (P3) | **Task ID**: flywheel-2xdi.49-e7c700 | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/gap-hunt-probe.sh` (probe; root cause)
**Originally flagged**: `~/.claude/skills/.flywheel/scripts/protected-session-recovery.sh` (false-positive recipient)

## Bug shape

Bead premise: `protected-session-recovery.sh` wired-but-cold. Investigation: the file is a **4-line compat wrapper** documented in `~/.claude/skills/protected-session-recovery/SKILL.md` as an "also available at" stable invocation path:

```bash
#!/usr/bin/env bash
set -euo pipefail
exec "$HOME/.claude/skills/protected-session-recovery/scripts/protected-session-recovery.sh" "$@"
```

No automation invokes the wrapper string-literal — everyone uses the canonical full path. BUT the SKILL.md documents the wrapper as a stable entry point. The probe's three corpora (recent_ledger_text, sibling_repo_ledger_corpus, runtime_source_corpus) don't include SKILL.md content, so the documented entry point looks cold.

**Same META-rule shape as 2xdi.47 (and o40x0 before that)**: bead-hypothesis-is-starting-point-not-conclusion. Bead said "dead code"; investigation found "probe blind spot for SKILL.md-documented entry points".

## Fix

`.flywheel/scripts/gap-hunt-probe.sh`: add `skill_md_corpus()` as a FOURTH corpus + check `in_skill_md` in `probe_wired_but_cold`.

```python
_SKILL_MD_CORPUS: str | None = None

def skill_md_corpus(max_bytes: int = 1_500_000) -> str:
    # Walk all SKILL.md files under ~/.claude/skills/ and concatenate content.
    # Names corpus always-complete + content corpus budgeted.

def probe_wired_but_cold():
    ...
    skill_md_text = skill_md_corpus()
    ...
    in_skill_md = bool(skill_md_text) and (name in skill_md_text or script.stem in skill_md_text)
    if not (in_local or in_sibling or in_source or in_skill_md):
        # cold
```

Catches all SKILL.md-documented scripts (compat wrappers + entry points) in one corpus addition. Same Meadows #5 leverage as 2xdi.47.

## Verification

Live probe post-fix:
- `protected-session-recovery.sh` no longer flagged (its name appears in `~/.claude/skills/protected-session-recovery/SKILL.md`)
- Total wired-but-cold gaps: **0** (combined effect of 2xdi.47 for-loop fix + 2xdi.49 SKILL.md fix)

## Regression test

New: `tests/gap-hunt-probe-skill-md-corpus.sh` (5 assertions):

1. Probe defines `skill_md_corpus()` + `_SKILL_MD_CORPUS` cache
2. `probe_wired_but_cold` checks `in_skill_md` as fourth corpus
3. Live probe: `protected-session-recovery.sh` no longer flagged
4. Live probe: 0 wired-but-cold gaps total (combined 2xdi.47 + 2xdi.49 fix effect)
5. Synthetic fixture proves SKILL.md content is captured by the corpus collector

**5/5 PASS.** Existing tests also pass:
- gap-hunt-probe-canonical-cli.sh: 30/30
- gap-hunt-probe-on-demand-validator-allowlist.sh: 6/6
- gap-hunt-probe-0h0b-suppression-smoke.sh: 7/7
- gap-hunt-probe-for-loop-source-corpus.sh: 4/4 (2xdi.47 fix)

## Acceptance

Bead asked to address wired-but-cold gap for `protected-session-recovery.sh`. Chosen path: extend probe corpus to honor SKILL.md mentions (Joshua-selected). Same shape as 2xdi.47 root-cause fix.

This is the **3rd application** of the bead-hypothesis-is-starting-point-not-conclusion META-rule this session:
1. o40x0 (race condition hypothesis → canonicalization mismatch root cause)
2. 2xdi.47 (dead code hypothesis → for-loop indirect-source corpus blind spot)
3. 2xdi.49 (dead code hypothesis → SKILL.md documentation corpus blind spot)

N=3 → META-RULE candidate confirmed; already memorized as `feedback_bead_hypothesis_starting_point_not_conclusion`.

## Files changed

- `.flywheel/scripts/gap-hunt-probe.sh` (+~55 lines: skill_md_corpus function + in_skill_md check)
- `tests/gap-hunt-probe-skill-md-corpus.sh` (NEW: 5-assertion regression test)

## L112 verify probe

`bash tests/gap-hunt-probe-skill-md-corpus.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=5 fail=0`
