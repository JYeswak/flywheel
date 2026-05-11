# Evidence Pack — flywheel-oyxd8 (eyqo7.1.2)

**Bead:** flywheel-oyxd8 — `[python-shebang-rename-jeff-issue] rename jeff-issue.sh → .py + 19 LIVE-ref updates`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-eyqo7.1 (sub-bead 2/3)

## Disposition: SHIPPED — rename + 19 LIVE-ref updates; both test suites green post-rename

## What shipped

### A. Script rename
- `git mv .flywheel/scripts/jeff-issue.sh .flywheel/scripts/jeff-issue.py`

### B. Test filenames PRESERVED
- `tests/jeff-issue.sh` KEEP — `.sh` reflects test interpreter (bash), not unit-under-test
- `tests/jeff-issue-canonical-cli.sh` KEEP — same

### C. Self-refs in script body (22 occurrences across 17 sites)
sed-replace-all `jeff-issue.sh` → `jeff-issue.py`:

| Lines | Site | Type |
|---|---|---|
| 116-130 | `--help` usage strings | self-ref ×15 |
| 144 | info `name` field | self-ref |
| 183-186 | --examples examples[] strings | self-ref ×4 |
| 271 | completion bash hook | self-ref |
| 308 | producer string | self-ref |

Verified post-edit: 0 `.sh` self-refs remain in script body.

### D. External LIVE refs (5 sites across 2 test files)

| File:Line | Change |
|---|---|
| `tests/jeff-issue-canonical-cli.sh:7` | SCRIPT path `.sh` → `.py` |
| `tests/jeff-issue-canonical-cli.sh:50` | KEEP — substring `jeff-issue` matches both extensions |
| `tests/jeff-issue.sh:5` | CLI path `.sh` → `.py` |
| `tests/jeff-issue.sh:28` | grep `'jeff-issue.sh doctor'` → `'jeff-issue.py doctor'` (script's `--help` emits argv[0] basename post-rename) |
| `tests/jeff-issue.sh:132` | grep `'jeff-issue.sh'` → `'jeff-issue.py'` (completion emits argv[0] basename) |
| `tests/jeff-issue.sh:133` | KEEP — slash wrapper path `$HOME/.claude/commands/flywheel/jeff-issue.md` (slash command name, no `.sh`) |

### E. Doctrine file deferred
`.flywheel/doctrine/scaffolder-bash-vs-python-design-difference.md` still contains `.sh` references — INTENTIONALLY DEFERRED to sub-bead `flywheel-vyzza` (doctrine close-out, blocks-on `.1.1/.1.2/.1.3` per dep wiring).

## AG Receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 git mv script (A) | DONE | git mv .sh → .py |
| AG2 update 17 self-refs in script body (C) | DONE | sed-replace-all; 22 occurrences across 17 sites; 0 .sh remaining |
| AG3 update 2 external test files with --help-grep dependency (D) | DONE | 5 LIVE-ref edits in test files; 2 substring-match decisions documented |
| AG4 regression test (both test suites) | DONE | tests/jeff-issue-canonical-cli.sh: 16/16 PASS; tests/jeff-issue.sh: 26/26 PASS |
| AG5 executability + correct argv[0] in --help | DONE | python3 ast OK; --help emits `Usage: jeff-issue.py doctor [--json]`; --info emits `name:"jeff-issue.py"`; doctor returns mode=doctor with checks+signals |
| AG6 per-ref decision JSONL receipt | DONE | `.flywheel/audit/flywheel-eyqo7.1.2/decisions.jsonl` (15 rows) |

did=6/6. didnt=none. gaps=none.

## Verification commands run

```bash
# AG2 verify
grep -c 'jeff-issue\.sh' .flywheel/scripts/jeff-issue.py
# Result: 0 ✓

# AG3 verify
grep -rl 'jeff-issue\.sh' --exclude-dir=... .
# Result: .flywheel/doctrine/scaffolder-bash-vs-python-design-difference.md (DEFERRED) only

# AG4 bash syntax
bash -n tests/jeff-issue.sh                     # OK
bash -n tests/jeff-issue-canonical-cli.sh       # OK

# AG4 canonical-cli test
bash tests/jeff-issue-canonical-cli.sh
# Result: SUMMARY pass=16 fail=0 ✓

# AG4 wrapper test (full functional)
bash tests/jeff-issue.sh
# Result: Summary: 26 passed, 0 failed ✓

# AG5 executability + argv[0] correctness
python3 -c "import ast; ast.parse(open('.flywheel/scripts/jeff-issue.py').read())"   # OK
.flywheel/scripts/jeff-issue.py --info --json | jq -r '.name'
# Result: "jeff-issue.py" ✓
.flywheel/scripts/jeff-issue.py --help | head -3
# Result: shows "Usage:" + "jeff-issue.py doctor [--json]" + "jeff-issue.py health [--json]" ✓
.flywheel/scripts/jeff-issue.py doctor --json | jq -c '{mode, has_checks:(has("checks")), has_signals:(has("signals"))}'
# Result: {"mode":"doctor","has_checks":true,"has_signals":true} ✓
```

## Boundary preservation

- HISTORICAL refs (21 entries enumerated in parent evidence): NOT touched
- Slash-command-name path `jeff-issue.md`: PRESERVED (slash command name, no `.sh` to update)
- Doctrine file: DEFERRED to flywheel-vyzza (dep-wired)
- Test filenames: PRESERVED (Design Decision: test extension = test interpreter, not unit-under-test)

## L107 Reservations released

5 reservations taken; all released this tick.

## Doctrine compliance

- META-RULE 2026-05-10 (decompose-by-natural-unit-not-bundle): N/A this sub-bead (decomposition applied in parent)
- META-RULE 2026-05-09 (calibrate-test-to-actual-contract): not triggered — both test suites green; --help-grep dependency calibrated proactively per dispatch packet AG3 Design Decision #4
- audit-machinery-hygiene-discipline: boundary preserved
- L52 (issues-to-beads-or-explicit-no-bead-receipt): 0 gaps surfaced; clean tick

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | renamed script + canonical-CLI test 16/16 PASS post-rename; doctor returns mode+checks; --help emits new name |
| rust-best-practices | n/a | python + bash rename, no Rust |
| python-best-practices | n/a | rename-only sub-bead; no Python refactor |
| readme-writing | n/a | no README |

## Four-Lens Self-Grade

- **Brand:** 10 — clean per-file rename; both test suites green; argv[0]-grep calibration applied proactively
- **Sniff:** 10 — would pass skeptical review (no remaining .sh self-refs; 2 substring-match decisions explicit; doctrine deferral documented in decisions.jsonl)
- **Jeff:** 10 — substrate honesty; 0 gaps surfaced (clean tick); calibration applied to test surfaces proactively
- **Public:** 10 — Three Judges check passes (operator can re-run both tests; maintainer has 15-row decisions.jsonl; future worker has clean handoff)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Script rename (AG1) | 100/100 | git mv .sh → .py executed |
| Test filenames preservation (AG1 boundary) | 50/50 | both jeff-issue test filenames preserved per Design Decision |
| 17 self-refs in body (AG2) | 200/200 | sed-replace-all; 22 occurrences; 0 .sh remaining |
| 5 external LIVE refs (AG3) | 200/200 | 2 test files edited; argv[0]-grep calibration applied proactively |
| Regression test (AG4) | 200/200 | 16/16 canonical-cli + 26/26 functional PASS post-rename |
| Executability (AG5) | 100/100 | ast parse OK; --help/--info/doctor all emit correct .py argv[0] |
| Per-ref decision JSONL receipt (AG6) | 100/100 | decisions.jsonl 15 rows |
| Boundary preservation | 50/50 | slash-command + doctrine + test filenames preserved per design |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/scripts/jeff-issue.py && \
  ! test -e .flywheel/scripts/jeff-issue.sh && \
  test -f tests/jeff-issue.sh && \
  test -f tests/jeff-issue-canonical-cli.sh && \
  ! grep -q 'jeff-issue\.sh' .flywheel/scripts/jeff-issue.py && \
  ! grep -q 'jeff-issue\.sh' tests/jeff-issue.sh && \
  bash tests/jeff-issue-canonical-cli.sh 2>&1 | grep -q 'SUMMARY pass=16 fail=0' && \
  bash tests/jeff-issue.sh 2>&1 | grep -q '26 passed, 0 failed'
```
Expected: rc=0 (post-rename state verified + both test suites green). Timeout 60s.
