# flywheel-2xdi.64 — Evidence Pack

**Bead:** flywheel-2xdi.64 (P3)
**Title:** [gap-wired-but-cold] `.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/scripts/archetype-calibrate.sh`
**Mission fitness:** `adjacent` — improves substrate accuracy of the gap-hunt-probe, which underpins continuous orchestrator uptime by removing false-positive cold flags that distract orch attention.

## Hypothesis vs Root Cause (Meadows #5 leverage)

**Bead hypothesis (auto-filed):** `archetype-calibrate.sh` is wired-but-cold (script not invoked by recent flywheel jsonl ledgers).

**Root cause found:** Script IS wired — `~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/bin/aerg:184` invokes it via `run "$SKILL_ROOT/scripts/archetype-calibrate.sh" "$@"`. The probe's `runtime_source_corpus()` did not capture direct-exec patterns (`run`/`exec`/`bash`/`sh` followed by a `.sh` path). Same class as 2xdi.47 (for-loop module list blind spot) and 2xdi.49 (SKILL.md mention blind spot).

**Posture per bead-hypothesis-prior META-rule (N=9 confirmed):** Bead body is Bayesian prior, not posterior. Probe before implementing.

## Fix

`.flywheel/scripts/gap-hunt-probe.sh`:

1. Added `exec_sh_re` regex (line ~666):
   ```python
   exec_sh_re = re.compile(r"\b(?:run|exec|bash|sh)\s+\S*?\.sh\b")
   ```
2. Wired into the per-line scan branch in `runtime_source_corpus()` (after `var_assign_sh_re`):
   ```python
   if exec_sh_re.search(line):
       pieces.append(line.rstrip())
       continue
   ```

This makes the runtime-source corpus see strings like `run "$SKILL_ROOT/scripts/archetype-calibrate.sh" "$@"` so the wired-but-cold detector no longer false-positive flags scripts invoked via wrapper exec.

## Verification

| Gate | Command | Result |
|---|---|---|
| Probe syntax | `bash -n .flywheel/scripts/gap-hunt-probe.sh` | OK |
| Live probe | `bash .flywheel/scripts/gap-hunt-probe.sh --json --dry-run \| jq '[.gaps[] \| select(.class=="wired-but-cold")] \| length'` | `0` |
| Live probe — archetype-calibrate gone | `bash .flywheel/scripts/gap-hunt-probe.sh --json --dry-run \| jq '[.gaps[] \| select(.class=="wired-but-cold" and (.where \| test("archetype-calibrate")))] \| length'` | `0` |
| New regression | `bash tests/gap-hunt-probe-exec-sh-corpus.sh` | 5/5 PASS |
| Sister 2xdi.47 | `bash tests/gap-hunt-probe-for-loop-source-corpus.sh` | 4/4 PASS |
| Sister 2xdi.49 | `bash tests/gap-hunt-probe-skill-md-corpus.sh` | 5/5 PASS |

## DID / DIDNT / GAPS

- **DID 4/4**
  - Probe corpus extended with `exec_sh_re` for direct-exec invocations (run/exec/bash/sh path/to/x.sh)
  - Regex wired into `runtime_source_corpus()` line scan
  - Regression test `tests/gap-hunt-probe-exec-sh-corpus.sh` added (5/5 PASS)
  - Sister corpus tests still green (47, 49)
- **DIDNT none**
- **GAPS none** — no further blind spot signals surfaced. Continuing 2xdi pattern: probe-side fix, not script-side change.

## Files Changed

- `.flywheel/scripts/gap-hunt-probe.sh` — added exec_sh_re definition + branch in for-line loop
- `tests/gap-hunt-probe-exec-sh-corpus.sh` (new, +96 lines)

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/gap-hunt-probe.sh --json --dry-run | jq '[.gaps[] | select(.class=="wired-but-cold" and (.where | test("archetype-calibrate")))] | length'`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `30`

## Pattern (META-rule reinforcement)

This is the third probe-corpus-extension fix in the 2xdi cluster (47, 49, 64). The shape is consistent:
1. Bead hypothesis says X is cold.
2. Investigation finds X is wired via pattern the probe doesn't recognize.
3. Fix extends the probe's corpus collector, not the script.
4. Sister regression test pinned per corpus.
5. Live probe should converge toward 0 wired-but-cold gaps as blind spots are closed.

When the next 2xdi bead with class=wired-but-cold appears, default first action: read the suspect script's wrappers and check whether the invocation pattern is in the probe's corpus before assuming cold.
