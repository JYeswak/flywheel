# flywheel-cg1i9 Evidence — identity.py shape-parity fixture (Phase 3, file 2/3)

Task: `flywheel-cg1i9-5fe54c`
Bead: `flywheel-cg1i9` (P3 OPEN → CLOSED this turn)
Title: [file-length-split] flywheel-hzsro.3 — split phase 3 per .flywheel/audit/flywheel-hzsro/split-plan.md
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Plan: `.flywheel/audit/flywheel-hzsro/split-plan.md` File 2 (1098 lines → 6 sub-modules with re-export pattern).
Mission fitness: `mission_fitness=infrastructure` — adds the parity-fixture
gate that the actual identity.py split (Phase 4 / `flywheel-vzfo5`) will
use as its apply-gate, per the plan's Order-of-Operations rule
("each split's apply gate is `pre-split fixture passes AND post-split
fixture passes AND JSON shapes are byte-equal`").

## Headline finding — Phase 3 = identity.py parity fixture (NOT the split)

The split-plan's Order-of-Operations table (lines 232-239) reads:

```
flywheel-hzsro.3  →  fixture: identity.py parity contract  (P2, ~50 assertions)
```

So this bead's deliverable is the **fixture file**, not the actual
split. The split lands in `flywheel-vzfo5` (Phase 4), gated on this
fixture passing pre-split AND post-split. Same pattern as Phase 1
(`flywheel-n5wa5`, commit `02830cf` — `tests/loop_driver_doctor_json_parity_fixture.sh`).

The new fixture is `tests/identity_py_parity_fixture.sh`. It mirrors
the Phase 1 template's modes (`--check-shape` default, `--record-baseline`
optional) and exercises 4 distinct CLI surfaces.

## What the fixture asserts

| # | Surface | Assertions |
|---|---|---|
| 1 | `--schema` (static) | emits valid JSON envelope (top-level `$id` / `id` / `$schema`) |
| 2 | `--examples` (static) | cites `--register`, `--preallocate-workers`, `--doctor` (the three example invocations the script's `examples()` helper prints) |
| 3 | `resolve` (default mode, fresh empty registry) | 17 required top-level keys: `schema_version`, `session`, `pane`, `role`, `identity_name`, `token_path`, `token_sha256`, `registered_ts`, `last_used_ts`, `fleet_mail_project_key`, `predecessor_identity`, `rotation_reason`, `status`, `identity_resolved`, `agent_mail_ready`, `proposed_identity`, `joshua_disposes_required`. Plus 4 semantic gates: `schema_version` starts with `agent-mail-identity-registry/`, session+pane echoed, fresh-empty status is `needs_registration`, fresh-empty requires `joshua_disposes`. |
| 4 | `--doctor` (against empty fixture registry) | emits `schema_version` + `rows` array |

Total: 9 PASS gates exercising 4 surfaces. The fixture isolates HOME
to `$TMP` so `save_row()`/`all_rows()` only touch `$TMP/.local/state/flywheel/`
and never contaminate the real identity registry. Topology is empty
(`FLYWHEEL_SESSION_TOPOLOGY` points at an empty JSONL).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `tests/identity_py_parity_fixture.sh` lands; `.flywheel/audit/flywheel-cg1i9/` pack |
| AG2 — targeted test passes and is named | DID | `bash tests/identity_py_parity_fixture.sh` returns exit 0 with 9 PASS gates; output captured at `fixture-output.txt` |
| AG3 — `br show flywheel-cg1i9` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Phase-1 template alignment

The new fixture is intentionally shape-isomorphic to Phase 1's
`tests/loop_driver_doctor_json_parity_fixture.sh` (commit `02830cf`):

| Element | Phase 1 (loop_driver_doctor) | Phase 3 (identity.py) |
|---|---|---|
| File path | `tests/loop_driver_doctor_json_parity_fixture.sh` | `tests/identity_py_parity_fixture.sh` |
| Modes | `--check-shape` (default), `--record-baseline` | same |
| TMP isolation | `mktemp -d` + trap cleanup | same |
| Required top-level key gate | 20 keys via `jq -e 'has($k)'` loop | 17 keys via same pattern |
| Sub-shape gate | `drain_receipts` substructure assertion | `schema_version` prefix + rows-array assertion |
| Baseline mode | optional `cp $out $baseline` | optional `jq -n` snapshot of `{resolve, doctor}` |
| Allow-large receipt cite | line 1 of fixture | same (audit pack reference) |

Future Phase 5 (`portable_doctor` parity fixture, `flywheel-xmd4y`)
will follow the same template.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| target script | `~/.claude/skills/.flywheel/lib/portable/identity.d/identity.py` | `b3824139416c1b7e2dc98defebada4c2737464cf30b126510d346d2652450623` |
| Phase 3 fixture | `tests/identity_py_parity_fixture.sh` | `a540ca73de52338db2390f8a1c43847d942da4042a08b464824c9077c0643e6c` |
| Phase 1 template | `tests/loop_driver_doctor_json_parity_fixture.sh` | `fafbffc7535cc275ce356b67bca80d71721e41e43eab9252e89cc48795109d8d` |

## Verification commands (re-runnable)

```bash
# Default fixture (shape-only assertions, ~1s)
bash /Users/josh/Developer/flywheel/tests/identity_py_parity_fixture.sh
# expected: identity.py shape-parity fixture passed (9 PASS)

# Record an isolated baseline (optional; baseline is the post-split apply-gate)
bash /Users/josh/Developer/flywheel/tests/identity_py_parity_fixture.sh --record-baseline
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/identity_py_parity_fixture.sh 2>/dev/null | tail -1
```

Expected (literal): `identity.py shape-parity fixture passed`.

## Boundary

- **No identity.py mutation.** The 1098-line module is unchanged. Its
  SHA stays at `b3824139416c1b7e2dc98defebada4c2737464cf30b126510d346d2652450623`.
- **No registry contamination.** All `save_row()` writes go to `$TMP/.local/state/flywheel/agent-mail/sessions/`; the trap deletes the tmp dir on exit.
- **No topology mutation.** `FLYWHEEL_SESSION_TOPOLOGY` points at a synthetic empty file; the real `~/.local/state/flywheel/session-topology.jsonl` is not read or written.
- **No skill mutation.** `~/.claude/skills/.flywheel/lib/portable/identity.d/` not touched. Per the audit pack's Caveats, identity.py is NOT JSM-managed (`jsm list | grep .flywheel` returns 0 today), so future-Phase-4 splits can land directly with paired audit pack and parity-fixture pre/post run.
- **No Phase 4 work.** This bead's deliverable ENDS at the fixture. The actual identity.py split is `flywheel-vzfo5` and depends on this fixture as its apply-gate.
- **Sister bead overlap acknowledged.** `flywheel-tymof` is a parallel listing of the same Phase 1 deliverable (filed by `flywheel-n5wa5`'s L52 receipt as a companion to this work). They reference the same fixture file (`tests/identity_py_parity_fixture.sh`); landing it under `flywheel-cg1i9` satisfies both bead IDs. tymof can close as superseded (no separate work needed) — surfaced as a gap in the L52 receipt.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored. The fixture exercises identity.py's existing CLI surface; no new CLI surface added.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python authored. The fixture invokes identity.py via `python3` but adds no Python module of its own.
- `readme-writing=n/a` — audit doc; fixture is a test, not a public-facing surface.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=fixture_only_no_canonical_doctrine_surface_authored_no_skill_mutation`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. The fixture mirrors the Phase 1 template precisely, so future maintainers see one consistent shape across all three parity fixtures.
- **Sniff: 9** — every gate is a `jq -e` predicate or shape-asserting `grep`; HOME isolation prevents real-registry contamination; rc=0 across 4 distinct CLI surfaces.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface (one new test); refuses to author the actual split (Phase 4 routes through `flywheel-vzfo5`); plan reference precise (line citations from `split-plan.md`).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the 9-gate fixture in <1s.
  - **maintainer (extending later)**: shape-isomorphic to Phase 1 fixture, so adding Phase 5 (`portable_doctor` fixture) slots into the same template.
  - **future worker (LLM agent)**: each surface (--schema / --examples / resolve / --doctor) gets its own labeled assertion block; the 17 required keys are explicit, so post-split shape divergence is caught key-by-key.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-cg1i9
no_bead_reason=fixture_authored_phase_4_split_routes_to_existing_flywheel-vzfo5_sister_bead_flywheel-tymof_can_close_as_superseded_via_orch_pass_no_dispatch-tier_followup_today`.
