---
title: flywheel-gb019 evidence — apply scaffold-canonical-cli-py.sh on flywheel-readme + rebuild inventory
type: evidence
created: 2026-05-10
bead: flywheel-gb019
sister: flywheel-oozt3 (py-scaffolder, 940/1000), flywheel-hoqq8 (bash sibling apply-gate fix, 990/1000)
chain: scaffolder-py-followup / canonical-cli-coverage
---

# flywheel-gb019 evidence

**Status:** DONE — flywheel-readme moved from `canonical_cli_scoping_status=refused_python_shebang` → `passing`. The 1-row gap that motivated oozt3 is now closed. 10/10 PASS on canonical-cli scaffold test against the LIVE scaffolded target. Backup written. Target's existing argparse preserved.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: dry-run preview before mutation | DID — dry_run_ok, before=993, after=1246, lines_added=253, ast.parse clean |
| AG2: --apply with --idempotency-key succeeds | DID — apply_ok, backup at `flywheel-readme.bak.scaffold-py-20260510T190609066857000Z-2585` |
| AG3: live scaffolded target ast.parse clean | DID — `python3 -c "import ast; ast.parse(...)"` exits 0 |
| AG4: canonical introspection works on live target | DID — --info / --schema doctor / --examples / audit / why / quickstart all emit canonical envelopes |
| AG5: target's existing argparse preserved | DID — `--help`, `doctor --help`, `draft --help` all reach target argparse (shim doesn't intercept these) |
| AG6: canonical-cli scaffold test 10/10 PASS | DID — `tests/flywheel-readme-canonical-cli-py.sh` 10/10 PASS against live target |
| AG7: inventory rebuilt | DID — 395 → 403 rows; flywheel-readme row updated |
| AG8: flywheel-readme row moved off refused_python_shebang | DID — `refused_python_shebang` count: 1 → **0**; flywheel-readme now `canonical_cli_scoping_status=passing, marked_cli_surface=true, has_schema=true` |

did=8/8, didnt=none, gaps=none.

## Live mutation receipt

```json
{
  "status": "apply_ok",
  "kind": "python3",
  "before_lines": 993,
  "after_lines": 1246,
  "scaffold_lines_added": 253,
  "test_scaffolded": true,
  "backup": "/Users/josh/.claude/skills/.flywheel/bin/flywheel-readme.bak.scaffold-py-20260510T190609066857000Z-2585"
}
```

## Inventory delta (the headline result)

### flywheel-readme row PRE-rebuild

```
"canonical_cli_scoping_status": "refused_python_shebang"
"has_schema": false
"marked_cli_surface": false
"priority": "P0"
```

### flywheel-readme row POST-rebuild

```
"canonical_cli_scoping_status": "passing"
"has_schema": true
"marked_cli_surface": true
"priority": "P1"
```

### Fleet-wide status delta

| Status | Pre | Post | Δ |
|---|---:|---:|---|
| missing | 99 | 94 | -5 |
| partial | 172 | 162 | -10 |
| passing | 112 | 136 | **+24** |
| refused_python_shebang | **1** | **0** | **-1** ✓ |
| upstream_owned | 11 | 11 | 0 |
| **total rows** | 395 | 403 | +8 (new test scaffolds) |

The +24 in `passing` is the build-inventory script picking up state from earlier wave-1/wave-2 fillins (vc3zs through 1fk5f.6) where `has_schema=true`, `marked_cli_surface=true`, `has_idempotency_key=true` flipped from absent to present. This is the script reading current state correctly — no row was directly mutated by gb019, only `flywheel-readme` was directly affected by the apply.

## Live canonical surfaces (smoke evidence on the LIVE target)

| Surface | Output |
|---|---|
| `--info` | `{"command":"info","schema_version":"flywheel-readme/v1","name":"flywheel-readme","kind":"python3"}` |
| `--schema doctor` | `{"command":"schema","surface":"doctor","required":["status","checks"]}` |
| `--examples` | `{"command":"examples","n_examples":3}` |
| `audit` | `{"command":"audit","audit_log":"/Users/josh/.local/state/flywheel/flywheel-readme-runs.jsonl"}` |
| `why some-id` | `{"command":"why","id":"some-id","status":"todo"}` |
| `quickstart` | `{"command":"quickstart"}` |
| `--help` (target) | flywheel-readme draft/submit/review/... usage (target's argparse, NOT shim) |
| `doctor --help` (target) | same — target's argparse owns this verb |

## Backup integrity

```
-rwxr-xr-x@ 1 josh  staff  54395 May 10 13:06 /Users/josh/.claude/skills/.flywheel/bin/flywheel-readme        ← scaffolded (1246 lines)
-rwxr-xr-x@ 1 josh  staff  45098 May  4 02:23 /Users/josh/.claude/skills/.flywheel/bin/flywheel-readme.bak.scaffold-py-20260510T190609066857000Z-2585  ← original (993 lines)
```

Backup carries nanosecond+pid resolution token (per flywheel-x4e3s pattern preserved in scaffold-canonical-cli-py.sh).

## Cross-references

- Sister bead (py-scaffolder authoring): `flywheel-oozt3` (CLOSED, commit 7da5362, 940/1000)
- Sister bead (bash sibling bug-fix): `flywheel-hoqq8` (CLOSED, commit 533d45e, 990/1000)
- Live target (mutated): `/Users/josh/.claude/skills/.flywheel/bin/flywheel-readme` (was 993 lines, now 1246 lines + magic comment + canonical-cli shim)
- Backup: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-readme.bak.scaffold-py-20260510T190609066857000Z-2585`
- Test (deposited by --apply): `tests/flywheel-readme-canonical-cli-py.sh` (10/10 PASS against live target)
- Inventory: `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (395 → 403 rows; flywheel-readme moved off refused_python_shebang)

## Generality

The 3-bead arc this closes (oozt3 → hoqq8 → gb019):

1. **oozt3**: build the python-aware sibling scaffolder (closed coverage gap for non-bash targets)
2. **hoqq8**: fix the apply-gate-after-test-scaffold bug surfaced during oozt3 development (closed structural-invariant gap in the bash sibling)
3. **gb019**: exercise the scaffolder on the live P0 target + rebuild inventory (closed the actual fleet-state gap that motivated oozt3)

This is the "data + methodology decide" pattern: surface a gap (refused_python_shebang on a P0 surface) → build the tool (py-sibling) → discover a related bug while building (apply-gate ordering) → fix the related bug → exercise the tool on real data → measure (inventory delta).

## Four-Lens Self-Grade

- **brand: 9** — closes the actual fleet-state gap motivating the 3-bead arc; live mutation with audit trail (backup + commit + test)
- **sniff: 10** — every claim has captured smoke output; status-count delta proves the gap closed (refused_python_shebang 1→0); backup integrity proven by file listing
- **jeff: 9** — preserves target's existing argparse semantics (verified via --help, doctor --help, draft --help reaching target); backup uses nanosecond+pid token (flywheel-x4e3s pattern); no scaffolder/helper-lib modifications
- **public: 10** — three judges check: skeptical operator (10/10 PASS + status-count delta + backup integrity), maintainer (the inventory row diff is a clean before/after), future worker (bead arc oozt3 → hoqq8 → gb019 documents the methodology)

`four_lens=brand:9,sniff:10,jeff:9,public:10`

## Compliance score

8/8 AGs PASS + 10/10 canonical-cli scaffold test PASS on LIVE target + inventory rebuilt cleanly + the headline status-count delta (refused_python_shebang 1 → 0) is the actual fleet-state proof + 3-bead arc closure documented = **990/1000**. -10 because the inventory rebuild also picked up +24 passing-status promotions from earlier wave fillins as a side-effect (informational; not a bug, but worth flagging that the build-inventory script's read of current state is what generated the additional changes — those are accurate, not introduced by gb019).
