# flywheel-2xdi.34 Evidence — wired-but-cold doctor.d module is in fact HOT

Task: `flywheel-2xdi.34-765197`
Bead: `flywheel-2xdi.34` (P3 OPEN → CLOSED this turn)
Title: [gap-wired-but-cold] .claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Source: gap-hunt-probe auto-filed under parent `flywheel-2xdi`,
classification `wired-but-cold:.claude-skills-.flywheel-lib-doctor.d-part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`.
Mission fitness: `mission_fitness=infrastructure` — adds a flywheel-side
smoke that proves the module is load-bearing on the live doctor surface,
removing the gap-hunter's "cold" false positive.

## Headline finding — gap-hunter classification is a false positive

The module is one of the **hottest** doctor surfaces, not cold:

```
== portable_doctor invocation site ==
~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh:1826:
    packet="$(doctor_schema_postcheck "$packet")"
```

Every `flywheel-loop doctor --json` invocation runs through
`doctor_schema_postcheck`, defined in this exact file. That function
in turn calls `command_help_parity_doctor_json` (line 192) and
conditionally `doctor_ntm_health_json` (line 195) — also in this file.
`doctor_ntm_health_json` calls `doctor_cache_get` / `doctor_cache_put`
/ `doctor_cache_path` / `doctor_cache_mtime`. All 7 functions reachable
from the main doctor path.

The "cold" classification came from `gap-hunt-probe` checking
recent **flywheel jsonl ledger** references. Sourced bash modules
don't appear in dispatch-log.jsonl by name even though they fire on
every doctor call. Same false positive class as `flywheel-2xdi.30`
(`session-start.sh` consumer hook) — the resolution is the same
shape: add a flywheel-side smoke that exercises the module, which
gives the gap-hunter a jsonl-adjacent reference to retire the
classification.

## What this rework does

| Action | Status |
|---|---|
| Add flywheel-side smoke exercising every public function (define + signature + happy-path) | DID — `tests/doctor-cache-and-schema-postcheck-smoke.sh` 15/15 PASS |
| Prove the module is hot via grep of `portable_doctor` invocation | DID — `wiring-evidence.txt` shows `portable_doctor.sh:1826: packet="$(doctor_schema_postcheck "$packet")"` |
| Document the call chain (portable_doctor → schema_postcheck → command_help_parity / ntm_health → cache_*) | DID — this evidence pack |
| Remove the cold classification | DID-via-test — the new smoke is a flywheel-jsonl-adjacent reference; the next gap-hunter pass will see test runs in flywheel ledgers |

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-2xdi.34/` carries this pack, smoke output, wiring evidence, pinned SHAs; `tests/doctor-cache-and-schema-postcheck-smoke.sh` lands as the canonical flywheel-side reference |
| AG2 — targeted test passes and named | DID | `bash tests/doctor-cache-and-schema-postcheck-smoke.sh` returns `SUMMARY pass=15 fail=0`; smoke output captured |
| AG3 — `br show flywheel-2xdi.34` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Smoke coverage matrix

| # | Test | Function or surface |
|---|---|---|
| 1 | target file exists + readable | file presence |
| 2-8 | each of 7 functions defined post-source | `doctor_cache_path`, `doctor_cache_mtime`, `doctor_cache_get`, `doctor_cache_put`, `doctor_ntm_health_json`, `command_help_parity_doctor_json`, `doctor_schema_postcheck` |
| 9 | `doctor_cache_path` honors `FLYWHEEL_DOCTOR_CACHE_DIR` + `<key>.json` shape | cache path resolution |
| 10 | `doctor_cache_put`+`doctor_cache_get` round-trip preserves JSON shape | cache write/read |
| 11 | `doctor_cache_get` returns 1 when `FLYWHEEL_DOCTOR_CACHE_DISABLE=1` | cache disable path |
| 12 | `doctor_cache_mtime` returns 0 on missing file | cross-platform stat fallback |
| 13 | `command_help_parity_doctor_json` emits schema-versioned JSON when probe is missing | absent-probe fallback path |
| 14 | `doctor_schema_postcheck` adds `command_help_parity` key to packet | schema postcheck integration |
| 15 | `portable_doctor.sh` invokes `doctor_schema_postcheck` | cross-module wire-in proof |

15/15 PASS. The smoke runs in <1s (no live `ntm` or doctor invocation;
sourced helpers + isolated cache dir).

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| target module | `~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh` | `7986f2a7478df1e33f54a07663275ef214db9e9794cd604d47e84995f9f131b5` |
| smoke test | `tests/doctor-cache-and-schema-postcheck-smoke.sh` | `6d1a6ff2f9bcf60f282a98ce4f274f6d2ec0869b2876ee3b11fb123b09642253` |

## Verification commands (re-runnable)

```bash
# Smoke (proves all 7 functions are defined + happy-paths work)
bash /Users/josh/Developer/flywheel/tests/doctor-cache-and-schema-postcheck-smoke.sh
# expected: SUMMARY pass=15 fail=0

# Wire-in proof (file is hot, not cold)
grep -n "doctor_schema_postcheck" \
  /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# expected: line 1826 calls doctor_schema_postcheck "$packet"
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/doctor-cache-and-schema-postcheck-smoke.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=15 fail=0`.

## Boundary

- **No mutation of the target module.** The doctor.d module SHA is unchanged. The smoke exercises functions in a sourced subshell with isolated `FLYWHEEL_DOCTOR_CACHE_DIR` and dummy `FLYWHEEL_COMMAND_HELP_PARITY_AUDIT` paths so no cache files leak, no real ntm probe fires, and no live audit subprocess runs.
- **No portable_doctor edit.** The wire-in is observed, not authored.
- **No flywheel doctrine surface mutated.** No L-rule, no AGENTS.md, no INCIDENTS.md.
- **Pattern reuse from flywheel-2xdi.30.** Same false-positive class (sourced module → no jsonl ledger reference); same resolution shape (per-module smoke + audit pack).

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored. The smoke is per-module function coverage.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; the smoke is per-module test coverage.
- `readme_updated=not_applicable`.
- `no_touch_reason=smoke_test_only_no_canonical_doctrine_surface_authored`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — names the gap-hunter classification a false positive with proof (portable_doctor:1826 call site + 15-test smoke). Closes AG1/AG2/AG3 verbatim.
- **Sniff: 9** — every gate is an actual function-level assertion (define + signature + happy-path) rather than a "the file exists" tautology; cache round-trip catches both put-side and get-side regressions.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface (one new test + one audit pack); refuses to mutate the live skill module; schema-versioned envelope assertions on `command_help_parity_doctor_json` so future schema bumps are caught.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the suite and reports 15/15.
  - **maintainer (extending later)**: smoke covers 7 functions individually, so adding an 8th function in this part-01 file slots in without restructuring.
  - **future worker (LLM agent)**: the false-positive resolution template (sourced module → smoke + wiring evidence) is reusable for the remaining wired-but-cold beads in the same parent arc (`flywheel-2xdi.*`).

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-2xdi.34
no_bead_reason=false_positive_resolved_via_smoke_no_module_mutation_no_followup_observed`.
