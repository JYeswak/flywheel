# Evidence Pack — flywheel-49c6i (eyqo7.1.3)

**Bead:** flywheel-49c6i — `[python-shebang-rename-fleet-rotate] rename fleet-rotate-on-caam-swap.sh → .py + 16 LIVE-ref updates incl sister script`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-eyqo7.1 (sub-bead 3/3 of rename arc; final rename pre-doctrine-closeout)

## Disposition: SHIPPED — rename + 16 LIVE-ref updates; canonical-CLI test green; sister script resolves renamed target

## What shipped

### A. Script + test renames
- `git mv .flywheel/scripts/fleet-rotate-on-caam-swap.sh .flywheel/scripts/fleet-rotate-on-caam-swap.py`
- `git mv tests/fleet-rotate-on-caam-swap.sh-canonical-cli-py.sh tests/fleet-rotate-on-caam-swap.py-canonical-cli-py.sh`

### B. Self-refs in script body (11 sites)
sed-replace-all `fleet-rotate-on-caam-swap.sh` → `fleet-rotate-on-caam-swap.py`:

| Lines | Site | Type |
|---|---|---|
| 3 | docstring header | self-ref |
| 61 | outputs[] ledger filename string | self-ref |
| 79 | info `name` field | self-ref |
| 138-140 | --info surfaces[].invocation strings | self-ref ×3 |
| 150-152 | --quickstart steps[].command strings | self-ref ×3 |
| 161, 162 | repair/validate topic prose | self-ref ×2 |

Verified post-edit: 0 `.sh` self-refs remain.

### C. Sister script (.flywheel/scripts/fleet-rotate-all-sessions.sh) — 5 LIVE-ref sites

| Line | Site | Importance |
|---|---|---|
| 18 | `# Wraps fleet-rotate-on-caam-swap.sh —` (top-of-file comment) | Documentation |
| 112 | `doctor) jq -nc ... notes:"...sister scripts (fleet-rotate-on-caam-swap.sh)..."` | Doctor envelope |
| 126 | `printf 'topic: doctor — ... sister fleet-rotate-on-caam-swap.sh, audit_log_dir.'` | Topic prose |
| 158 | `local sister="/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-rotate-on-caam-swap.sh"` | **LOAD-BEARING** — actual sister-resolution variable |
| 433 | `ROTATOR="$HOME/Developer/flywheel/.flywheel/scripts/fleet-rotate-on-caam-swap.sh"` | **LOAD-BEARING** — main rotator path |

Verified post-edit: sister script can still resolve renamed sister (`fleet-rotate-all-sessions.sh doctor --json` → `status:ok` with 6 checks; sister target file exists).

### D. External test LIVE refs (2 files)

| File:Line | Change |
|---|---|
| `tests/fleet-rotate-on-caam-swap-canonical-cli.sh:5,12` | header comment + exec path |
| `tests/fleet-rotate-on-caam-swap.py-canonical-cli-py.sh:2,3,11` | header comments + SCRIPT path |

### E. Doctrine file deferred
`.flywheel/doctrine/scaffolder-bash-vs-python-design-difference.md` still contains `.sh` references — INTENTIONALLY DEFERRED to sub-bead `flywheel-vyzza`. **This is the final rename sub-bead; vyzza is now UNBLOCKED.**

### F. Pre-scaffold .bak file preserved
`.flywheel/scripts/fleet-rotate-on-caam-swap.sh.bak.scaffold-py-20260510T223446185289000Z-25782` UNTOUCHED.

## AG Receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 git mv script + test | DONE | git mv × 2 |
| AG2 update 9 self-refs in script body | DONE | sed-replace-all; 11 occurrences across 11 sites; 0 .sh remaining |
| AG3 update 7 external LIVE ref sites | DONE | 5 sister-script sites + 2 test files |
| AG4 regression test | DONE | canonical-CLI test 14/14 PASS; sister-script doctor 6 checks ok; bash -n on all 3 edited shell files |
| AG5 executability after rename | DONE | python3 ast OK; --info emits `name:"fleet-rotate-on-caam-swap.py"`; doctor returns status=pass with 6 checks |
| AG6 per-ref decision JSONL receipt | DONE | `.flywheel/audit/flywheel-eyqo7.1.3/decisions.jsonl` (17 rows) |

did=6/6. didnt=none. gaps=none.

## Verification commands run

```bash
# AG2 verify
grep -c 'fleet-rotate-on-caam-swap\.sh' .flywheel/scripts/fleet-rotate-on-caam-swap.py
# Result: 0 ✓

# AG3 sister-script verify (LOAD-BEARING)
grep -c 'fleet-rotate-on-caam-swap\.sh' .flywheel/scripts/fleet-rotate-all-sessions.sh
# Result: 0 ✓

# AG3 full LIVE-surface verify
grep -rl 'fleet-rotate-on-caam-swap\.sh' --exclude-dir=... .
# Result: .flywheel/doctrine/scaffolder-bash-vs-python-design-difference.md (DEFERRED) only

# AG4 bash -n
bash -n .flywheel/scripts/fleet-rotate-all-sessions.sh         # OK
bash -n tests/fleet-rotate-on-caam-swap-canonical-cli.sh       # OK
bash -n tests/fleet-rotate-on-caam-swap.py-canonical-cli-py.sh # OK

# AG4 canonical-CLI test (PRIMARY regression coverage)
bash tests/fleet-rotate-on-caam-swap-canonical-cli.sh
# Result: SUMMARY pass=14 fail=0 ✓

# AG4 sister-script resolves renamed sister (CRITICAL — load-bearing local var + ROTATOR)
.flywheel/scripts/fleet-rotate-all-sessions.sh doctor --json | jq -c '{command,status,checks_len:(.checks|length)}'
# Result: {"command":"doctor","status":"ok","checks_len":6} ✓
test -f .flywheel/scripts/fleet-rotate-on-caam-swap.py
# Result: exists ✓

# AG5 executability after rename
python3 -c "import ast; ast.parse(open('.flywheel/scripts/fleet-rotate-on-caam-swap.py').read())"  # OK
.flywheel/scripts/fleet-rotate-on-caam-swap.py --info --json | jq .name
# Result: "fleet-rotate-on-caam-swap.py" ✓
.flywheel/scripts/fleet-rotate-on-caam-swap.py doctor --json | jq -c '{command,status,checks_len:(.checks|length)}'
# Result: {"command":"doctor","status":"pass","checks_len":6} ✓
```

## Boundary preservation

- HISTORICAL refs (23 entries enumerated in parent evidence): NOT touched
- Pre-scaffold .bak file: NOT touched
- Doctrine file: DEFERRED to flywheel-vyzza (dep-wired, now UNBLOCKED — all 3 renames shipped)

## L107 Reservations released

6 reservations taken; all released this tick.

## Doctrine compliance

- META-RULE 2026-05-10 (decompose-by-natural-unit-not-bundle): N/A this sub-bead (decomposition applied in parent)
- META-RULE 2026-05-09 (calibrate-test-to-actual-contract): not triggered — clean tick
- audit-machinery-hygiene-discipline: boundary preserved (HISTORICAL + .bak untouched)
- L52: 0 gaps surfaced; clean tick

## Sister script load-bearing test

**Why this is the highest-risk sub-bead of the three:** sister script `fleet-rotate-all-sessions.sh` is the actual orchestrator entry point; it consumes the renamed script via 2 load-bearing variables (`local sister=` at :158 and `ROTATOR=` at :433). If those failed to resolve, the orchestrator would fail.

Both verified post-rename:
- `fleet-rotate-all-sessions.sh doctor --json` exits 0 with `status:ok`
- Sister target file exists at `.flywheel/scripts/fleet-rotate-on-caam-swap.py`
- 6 named doctor checks returned (load-bearing for the rotation orchestration)

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | canonical-CLI test 14/14 PASS; doctor returns 6 named checks; --info emits new name; sister-script doctor envelope continues to reference renamed sister correctly |
| rust-best-practices | n/a | python + bash rename, no Rust |
| python-best-practices | n/a | rename-only sub-bead |
| readme-writing | n/a | no README |

## Four-Lens Self-Grade

- **Brand:** 10 — clean per-file rename with explicit load-bearing variable verification
- **Sniff:** 10 — sister-script doctor envelope tested post-rename to prove load-bearing path resolution still works
- **Jeff:** 10 — final-rename-of-arc; doctrine closeout (vyzza) now unblocked
- **Public:** 10 — Three Judges check passes (operator can re-run canonical test + sister doctor; maintainer has 17-row decisions.jsonl with load-bearing annotations; future worker has clean handoff)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Script + test rename (AG1) | 150/150 | git mv × 2 executed |
| 9 self-refs in body (AG2) | 200/200 | sed-replace-all; 11 occurrences; 0 .sh remaining |
| 7 external LIVE refs (AG3) | 200/200 | sister script 5 sites + 2 test files |
| Regression test (AG4) | 200/200 | canonical-CLI 14/14 PASS; sister-script doctor pass with 6 checks |
| Executability (AG5) | 100/100 | python3 ast OK; --info name correct; doctor pass |
| Per-ref decision JSONL receipt (AG6) | 100/100 | decisions.jsonl 17 rows |
| Load-bearing sister-script verification | 50/50 | sister script doctor pass post-rename + target file exists |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## Arc completion status

This is sub-bead 3/3 of the rename arc. After this commit:
- flywheel-eyqo7.1.1 (caam-auto-rotate) ✓ shipped
- flywheel-eyqo7.1.2 (jeff-issue) ✓ shipped
- flywheel-eyqo7.1.3 (fleet-rotate) ✓ shipping now
- flywheel-vyzza (doctrine closeout) — now UNBLOCKED (deps all resolved)

## L112 Verify Probe

```bash
test -f .flywheel/scripts/fleet-rotate-on-caam-swap.py && \
  ! test -e .flywheel/scripts/fleet-rotate-on-caam-swap.sh && \
  test -f tests/fleet-rotate-on-caam-swap.py-canonical-cli-py.sh && \
  ! test -e tests/fleet-rotate-on-caam-swap.sh-canonical-cli-py.sh && \
  ! grep -q 'fleet-rotate-on-caam-swap\.sh' .flywheel/scripts/fleet-rotate-on-caam-swap.py && \
  ! grep -q 'fleet-rotate-on-caam-swap\.sh' .flywheel/scripts/fleet-rotate-all-sessions.sh && \
  bash tests/fleet-rotate-on-caam-swap-canonical-cli.sh 2>&1 | grep -q 'SUMMARY pass=14 fail=0'
```
Expected: rc=0 (post-rename state + sister script clean + canonical-CLI 14/14 PASS). Timeout 30s.
