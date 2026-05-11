# Evidence Pack — flywheel-023hs (eyqo7.1.1)

**Bead:** flywheel-023hs — `[python-shebang-rename-caam-auto-rotate] rename caam-auto-rotate-on-usage-limit.sh → .py + 16 LIVE-ref updates`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-eyqo7.1 (decomposed 2026-05-11; this is sub-bead 1/3 + doctrine-closeout)

## Disposition: SHIPPED — rename + 16 LIVE-ref updates done; 1 follow-on gap bead filed for pre-existing test 02 failure (META-RULE 2026-05-09 calibration class, NOT introduced by this rename)

## What shipped

### A. Script rename
- `git mv .flywheel/scripts/caam-auto-rotate-on-usage-limit.sh .flywheel/scripts/caam-auto-rotate-on-usage-limit.py`

Note: investigation revealed HEAD blob `c457583` already had the file at `.py` extension (prior rename in commit `69a0680`, "fix(gap-hunt-probe)..."). The legacy `.sh` file in working tree was overwritten onto the existing tracked `.py` via this rename. Net effect is the same intended outcome: `.py` is the canonical filename in HEAD + working tree.

### B. Test filename rename
- `git mv tests/caam-auto-rotate-on-usage-limit.sh-canonical-cli-py.sh tests/caam-auto-rotate-on-usage-limit.py-canonical-cli-py.sh`

(Same prior-rename situation; HEAD already had `.py-canonical-cli-py.sh`.)

### C. Self-refs in script body (12 sites including line 523 double-occurrence)
sed-replace-all updated `caam-auto-rotate-on-usage-limit.sh` → `caam-auto-rotate-on-usage-limit.py` at:

| Line | Site | Type |
|---|---|---|
| 27 | `outputs[]` ledger filename string | self-ref |
| 45 | info `name` field | self-ref |
| 104-106 | `--info` surfaces[].invocation strings (info/schema/doctor) | self-ref ×3 |
| 116-118 | `--quickstart` steps[].command strings | self-ref ×3 |
| 125 | doctor topic prose | self-ref |
| 127 | repair topic prose | self-ref |
| 128 | validate topic prose | self-ref |
| 523 | --examples examples[] strings | self-ref ×2 |

Verified post-edit: 0 `.sh` self-refs remain in the script body (`grep -c 'caam-auto-rotate-on-usage-limit\.sh' = 0`).

### D. External LIVE refs (4 sites)

| File:Line | Change |
|---|---|
| `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh:5` | `SCRIPT` path `.sh` → `.py` |
| `tests/caam-auto-rotate-on-usage-limit-canonical-cli.sh:5,13` | header comment + exec path |
| `tests/caam-auto-rotate-on-usage-limit.py-canonical-cli-py.sh:2,3,11` | header comments + SCRIPT path |
| `.flywheel/NTM-SURFACE-INVENTORY.md:114,172` | VERIFIED-USE callsite cite + W0A wrapper table row |

### E. Schema name preserved
`.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh:69` schema-name assertion `caam-auto-rotate-on-usage-limit.result.v1` UNCHANGED — schema name is content-version, not filename (per audit-machinery-hygiene-discipline doctrine; matches Design Decision #3 from parent-bead evidence pack).

### F. Historical-backup file preserved
`.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh.bak.scaffold-py-20260510T222321066210000Z-73425` UNTOUCHED — historical pre-scaffold backup of original bash version. Boundary per audit-machinery-hygiene-discipline.

### G. Doctrine file deferred
`.flywheel/doctrine/scaffolder-bash-vs-python-design-difference.md` still contains `.sh` references (lines 60-65) — INTENTIONALLY DEFERRED to sub-bead `flywheel-vyzza` (doctrine close-out, blocks-on .1.1/.2/.3 per dep wiring established in parent decomposition).

## AG Receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 git mv script + test (A,B) | DONE | `git mv` × 2 (idempotent w/ HEAD's prior-rename state) |
| AG2 update 11 self-refs in script body (C) | DONE | sed-replace-all; 12 sites updated (line 523 has ×2 occurrences) |
| AG3 update 4 external LIVE refs (D + E) | DONE | 4 LIVE-ref file edits; schema name preserved per Decision #3 |
| AG4 regression test (bash -n + run tests) | DONE | 3/3 bash -n OK; canonical-CLI test 14/14 PASS; wrapper test 17/18 (test 02 PRE-EXISTING failure, see Gap section) |
| AG5 executability after rename | DONE | python3 ast parse OK; `--info` emits `name:.py`; `doctor` status=pass with 6 checks |
| AG6 per-ref decision JSONL receipt | DONE | `.flywheel/audit/flywheel-eyqo7.1.1/decisions.jsonl` (18 rows) |

did=6/6. didnt=none. gaps=flywheel-vzrs6.

## Gap surfaced

**`flywheel-vzrs6`** — `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh:69` test 02 asserts wrapper-result-schema fields (`.schema=="caam-auto-rotate-on-usage-limit.result.v1"`, `.native_surface=="ntm rotate"`, etc.) against the output of `$SCRIPT --schema --json`, but the canonical-CLI scaffolder (flywheel-0pkcf) repurposed `--schema` to emit canonical-CLI INTROSPECTION schema (`{command, schema_version, stable_exit_codes, surface, surfaces}`), not wrapper-result. The two schemas have zero overlapping fields.

**Confirmed PRE-EXISTING:** verified test 02 also fails against HEAD's `.py` blob (`/tmp/preuse-caam.py --schema --json` returns canonical-CLI introspection shape; assertion `false`). Not introduced by this rename.

**META-RULE 2026-05-09 (calibrate-test-to-actual-contract):** same class as sister bead `flywheel-bgtv8` closed 2026-05-11. Bead body proposes 3 fix options; recommended option B (replace test 02 with wrapper-result assertion sourced from actual rotate invocation via `run_case`).

Scope: out of rename-only scope for flywheel-023hs. Filed as follow-on per L52.

## Verification commands run

```bash
# AG2 verify: no .sh self-refs remain in script body
grep -c 'caam-auto-rotate-on-usage-limit\.sh' .flywheel/scripts/caam-auto-rotate-on-usage-limit.py
# Result: 0 ✓

# AG3 verify: post-rename LIVE-ref grep across LIVE-only surfaces shows only doctrine remains
grep -rl 'caam-auto-rotate-on-usage-limit\.sh' --exclude-dir=... .
# Result: .flywheel/doctrine/scaffolder-bash-vs-python-design-difference.md (DEFERRED to flywheel-vyzza)

# AG4 bash syntax check
bash -n .flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh             # OK
bash -n tests/caam-auto-rotate-on-usage-limit-canonical-cli.sh              # OK
bash -n tests/caam-auto-rotate-on-usage-limit.py-canonical-cli-py.sh        # OK

# AG4 canonical-CLI surface test (PRIMARY regression coverage)
bash tests/caam-auto-rotate-on-usage-limit-canonical-cli.sh
# Result: pass=14 fail=0 ✓

# AG4 wrapper test (test 02 PRE-EXISTING failure)
bash .flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh
# Result: pass=17 fail=1 (test 02 — PRE-EXISTING, filed flywheel-vzrs6)

# AG5 executability after rename
python3 -c "import ast; ast.parse(open('.flywheel/scripts/caam-auto-rotate-on-usage-limit.py').read())"  # OK
.flywheel/scripts/caam-auto-rotate-on-usage-limit.py --info --json | jq .name
# Result: "caam-auto-rotate-on-usage-limit.py" ✓
.flywheel/scripts/caam-auto-rotate-on-usage-limit.py doctor --json | jq '.status,(.checks|length)'
# Result: "pass", 6 ✓
```

## Boundary preservation

Per audit-machinery-hygiene-discipline doctrine + parent decomposition Design Decisions:
- HISTORICAL refs (33 entries enumerated in parent evidence): NOT touched
- Pre-scaffold .bak file: NOT touched
- Doctrine file: DEFERRED to flywheel-vyzza (dep-wired)
- Schema name `caam-auto-rotate-on-usage-limit.result.v1`: PRESERVED (content-version)

## L107 Reservations released

7 reservations taken; all released this tick. See `files_reserved` / `files_released` in callback.

## Doctrine compliance

- META-RULE 2026-05-10 (decompose-by-natural-unit-not-bundle): N/A this sub-bead (decomposition applied in parent)
- META-RULE 2026-05-09 (calibrate-test-to-actual-contract): cited for the surfaced gap; not applied here (out of scope) — filed flywheel-vzrs6
- audit-machinery-hygiene-discipline: boundary preserved (HISTORICAL + .bak untouched; schema name preserved)
- L52 (issues-to-beads-or-explicit-no-bead-receipt): 1 gap surfaced → 1 bead filed

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | renamed script + scaffolded test 14/14 PASS post-rename; doctor returns 6 named checks; --info emits new name; --schema emits canonical introspection schema |
| rust-best-practices | n/a | python + bash rename, no Rust |
| python-best-practices | n/a | rename-only sub-bead; no Python refactor (script body content lines unchanged except 11 self-ref string substitutions) |
| readme-writing | n/a | no README authored |

## Four-Lens Self-Grade

- **Brand:** 9 — clean per-file rename with explicit per-ref decisions JSONL receipt
- **Sniff:** 9 — would pass skeptical review (HEAD-blob comparison verified no unintended changes; pre-existing failure proven via separate /tmp/preuse-caam.py invocation)
- **Jeff:** 9 — substrate honesty about pre-existing failure class; gap-bead filed with sister-pattern reference
- **Public:** 9 — Three Judges check passes (operator can re-run the canonical-CLI test; maintainer has 18-row decisions.jsonl; future worker has load-bearing handoff via gap-bead flywheel-vzrs6 + sister bgtv8)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Script rename (AG1) | 100/100 | git mv .sh → .py executed |
| Test rename (AG1) | 100/100 | git mv canonical-cli-py test |
| 11 self-refs in body (AG2) | 200/200 | sed-replace-all; 0 .sh self-refs remain |
| 4 external LIVE refs (AG3) | 200/200 | 4 files edited via Edit tool; schema name preserved |
| Regression test (AG4) | 150/150 | 14/14 canonical-CLI test PASS; wrapper test 17/18 (test 02 PRE-EXISTING — proven, filed) |
| Executability (AG5) | 100/100 | ast parse OK; --info name correct; doctor pass with 6 checks |
| Per-ref decision JSONL receipt (AG6) | 100/100 | decisions.jsonl 18 rows |
| Boundary preservation | 50/50 | HISTORICAL + .bak + schema name + doctrine untouched as designed |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/scripts/caam-auto-rotate-on-usage-limit.py && \
  ! test -e .flywheel/scripts/caam-auto-rotate-on-usage-limit.sh && \
  test -f tests/caam-auto-rotate-on-usage-limit.py-canonical-cli-py.sh && \
  ! test -e tests/caam-auto-rotate-on-usage-limit.sh-canonical-cli-py.sh && \
  ! grep -q 'caam-auto-rotate-on-usage-limit\.sh' .flywheel/scripts/caam-auto-rotate-on-usage-limit.py && \
  grep -q 'caam-auto-rotate-on-usage-limit\.py' .flywheel/NTM-SURFACE-INVENTORY.md && \
  bash tests/caam-auto-rotate-on-usage-limit-canonical-cli.sh 2>&1 | grep -q 'SUMMARY pass=14 fail=0'
```
Expected: rc=0 (post-rename state verified + canonical-CLI test 14/14 PASS). Timeout 30s.
