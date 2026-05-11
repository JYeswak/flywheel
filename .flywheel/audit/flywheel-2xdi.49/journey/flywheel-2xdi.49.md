# Journey: flywheel-2xdi.49

Bead: protected-session-recovery.sh wired-but-cold. Investigation: 4-line compat wrapper documented in SKILL.md ("also available at: ~/.claude/skills/.flywheel/scripts/..."). No string-match callers, but documentation IS the wiring.

Joshua chose Path A (extend probe corpus to honor SKILL.md mentions) over Path B (delete wrapper) or Path C (per-script registry entry). Meadows #5 leverage path — catches all SKILL.md-documented scripts, not just this one.

Fix: 4th corpus (`skill_md_corpus`) walking `~/.claude/skills/**/SKILL.md`. ~55-line patch + 5/5 regression test.

Live probe post-fix: 0 wired-but-cold gaps (combined effect of 2xdi.47 for-loop fix + 2xdi.49 SKILL.md fix). Existing tests: 30/30 + 6/6 + 7/7 + 4/4 — all green.

N=3 of bead-hypothesis-is-prior-not-posterior META-RULE this session: o40x0 → 2xdi.47 → 2xdi.49. Pattern is fully load-bearing.
