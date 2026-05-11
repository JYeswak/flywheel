---
bead: flywheel-2xdi.64
title: gap-hunt-probe corpus extension — direct-exec invocations (run/exec/bash/sh path/to/x.sh)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_exemplars: flywheel-2xdi.47 (for-loop module list corpus), flywheel-2xdi.49 (SKILL.md corpus)
---

# Journey: flywheel-2xdi.64

## What the bead claimed

Auto-filed by gap-hunt-probe: `archetype-calibrate.sh` is wired-but-cold; script
not referenced by recent flywheel jsonl ledgers in last 30d.

## What I found (Bayesian posterior)

The script IS wired. `~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-
maximization-for-cli-tools/bin/aerg` line 184:

    run "$SKILL_ROOT/scripts/archetype-calibrate.sh" "$@"

The probe's `runtime_source_corpus()` scanned for `source X`, `. X`, `for ... in`,
`dot_d`, and `var_assign_sh` patterns — but not direct execs via `run`, `exec`,
`bash`, or `sh` followed by a `.sh` path. Same META-rule shape as 2xdi.47 and
2xdi.49: probe corpus blind spot, not dead code.

This is the 9th confirmed instance this session of the
`bead-hypothesis-is-prior-not-posterior` META-rule.

## Fix

`.flywheel/scripts/gap-hunt-probe.sh`:

1. Added regex `exec_sh_re = re.compile(r"\b(?:run|exec|bash|sh)\s+\S*?\.sh\b")`
2. Added a branch in the per-line loop of `runtime_source_corpus()` that
   captures matching lines into the corpus pieces.

## Verification

- Live probe → 0 wired-but-cold gaps for archetype-calibrate
- Live probe → 0 wired-but-cold gaps total (combined 2xdi.47 + .49 + .64)
- New regression test `tests/gap-hunt-probe-exec-sh-corpus.sh`: 5/5 PASS
- Sister `gap-hunt-probe-for-loop-source-corpus.sh`: 4/4 PASS
- Sister `gap-hunt-probe-skill-md-corpus.sh`: 5/5 PASS

## L112 probe

    bash .flywheel/scripts/gap-hunt-probe.sh --json --dry-run \
      | jq '[.gaps[] | select(.class=="wired-but-cold" and (.where | test("archetype-calibrate")))] | length'

Expected: `literal:0`.

## Pattern reinforcement

When a 2xdi-class bead reports wired-but-cold, the orchestrator default is
not to ship the script change. Read the script's wrappers and bin/ entry
points. If the invocation pattern is unrecognized by the probe's corpus
collector, extend the corpus, not the script.
