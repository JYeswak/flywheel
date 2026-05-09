# flywheel-yu8g Evidence — dispatch-log v2 schema validator wired into tick

Task: `flywheel-yu8g-9e8e19`
Bead: `flywheel-yu8g` (P2 OPEN → CLOSED this turn)
Title: [coord-wire-in T4C] dispatch-log v2 schema validator wired into tick
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission: continuous-orchestrator-uptime-self-sustaining-fleet
mission_fitness=infrastructure (echoed adjacent claim per packet; actual work
is substrate plumbing, not direct enforcement).

## What changed

Three artifacts wire the existing v2 validator into tick + doctor:

1. **`.flywheel/scripts/dispatch-log-schema-validator.sh`** — gained
   `--tail N` flag so callers can bound the row sample. Unchanged behavior
   for `--tail 0` / unset (full log).
2. **`.flywheel/scripts/dispatch-log-v2-violations-doctor.sh`** *(new)* —
   bounded read-only doctor wrapper that calls the validator with `--tail`
   (default 100, env `FLYWHEEL_DISPATCH_LOG_V2_TAIL` overrides), parses the
   summary, emits a `dispatch-log-v2-violations-doctor/v1` packet with
   `dispatch_log_v2_violations_count` and friends. Exits `0` when count == 0,
   `1` when count > 0 (fail-closed), `0` with `status=warn` when validator
   or log are missing (fail-open for tick continuity).
3. **`tests/dispatch-log-schema-validator-tick-wire-in.sh`** *(new)* — fixture
   test that proves clean v2 rows pass and a row with missing required
   fields fails. Twenty PASS gates including doctor-wrapper status, exit
   codes, packet shape, and tick.md citation checks.
4. **`~/.claude/commands/flywheel/tick.md`** — adds Step 4z.1 between
   `Step 4z` and `Step 5: Decision`. Runs the doctor wrapper, parses the
   five `dispatch_log_v2_*_count` fields into the tick receipt, prefers
   HOLD over fresh dispatch when violations > 0, fail-open on
   wrapper/log-missing.
5. **`~/.claude/skills/.flywheel/lib/fleet.d/part-02-peer_orch_productivity_watch_doctor_json-to-workers_to_json.sh`** *(new function)* —
   `dispatch_log_v2_violations_doctor_json()` next to
   `dispatch_contract_doctor_json()`. Tries the repo wrapper first, falls
   back to `~/Developer/flywheel/.flywheel/scripts/...`, fail-opens with
   typed warnings on missing/invalid wrapper.
6. **`~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh`** —
   adds 3 variable assignments next to the dispatch_contract assignments and
   one jq merge entry next to the dispatch_contract merge. The merge
   exposes 7 keys on the `flywheel-loop doctor --json` packet:
   `dispatch_log_v2_violations_count`,
   `dispatch_log_v2_total_rows_checked`,
   `dispatch_log_v2_malformed_count`,
   `dispatch_log_v2_missing_fitness_class_count`,
   `dispatch_log_v2_missing_fitness_claim_count`,
   `dispatch_log_v2_violations_status`,
   `dispatch_log_v2_violations` (full nested packet).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — tick.md gains step | DID | `~/.claude/commands/flywheel/tick.md` Step 4z.1 (sha pinned below); fixture test `PASS tick.md cites dispatch-log-v2-violations-doctor.sh` and `PASS tick.md cites dispatch_log_v2_violations_count field` |
| AG2 — validator returns exit 0 for v2-conformant rows | DID | `tests/dispatch-log-schema-validator-tick-wire-in.sh` `PASS validator exit 0 on 3 conformant v2 rows` (synthetic fixture with all 15 required fields); doctor wrapper `PASS doctor wrapper exit 0 on conformant rows` |
| AG2 — validator fails for missing required fields | DID | fixture `PASS validator exit 1 on row with missing required fields`; `PASS doctor wrapper exit 1 on dirty tail`; `PASS doctor wrapper count==1 on dirty tail` |
| AG3 — doctor exposes `dispatch_log_v2_violations_count` | DID | `flywheel-loop doctor --repo "$PWD" --json` emits the field; see `doctor-field-evidence.json` (count=10 on real-world tail of 10, total=10, status=fail — these reflect upstream emit-side bugs in dispatch-log writers, NOT the wire-in) |
| AG-shape — doctor packet has all five v2 violation fields | DID | jq -e existence checks pass for `dispatch_log_v2_violations_count`, `_total_rows_checked`, `_malformed_count`, `_missing_fitness_class_count`, `_missing_fitness_claim_count`, `_violations_status` |

did=4/4 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| validator (with --tail) | `.flywheel/scripts/dispatch-log-schema-validator.sh` | `6a81ba3fa24a4df195963f60d5b2ecf7e2260f8deb71c5ecae96211a5b97ce22` |
| doctor wrapper | `.flywheel/scripts/dispatch-log-v2-violations-doctor.sh` | `05541f86319a8fcf6b7f6a3842ba22b54732187ae0c64f19588fccf985653b84` |
| schema | `.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json` | `f5d5bd4b23390d611477a83d13dae6de1798997b993d8d4ee72392b6cf27b780` |
| fixture test | `tests/dispatch-log-schema-validator-tick-wire-in.sh` | `40e3978487e35b1dc66592b11253db2eaa8ab1e4912de8c25ea68b66fb90232d` |
| tick.md | `~/.claude/commands/flywheel/tick.md` | `4080a4f131c21fd4e07c878e76d0266c70eeb0ca0171c5038150ec85539286ba` |
| fleet.d probe fn | `~/.claude/skills/.flywheel/lib/fleet.d/part-02-peer_orch_productivity_watch_doctor_json-to-workers_to_json.sh` | `3198081942cf21783018a704137266d666ebead8addb35e7fdacf4b70b82d935` |
| portable_doctor wire-in | `~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh` | `54ebde3a8bae5ab4e5890ebb6dbf367590bb01410b30f91a107c099e82e7fc70` |

These pins are re-derivable in <1s via `shasum -a 256`. Drift in any pin
invalidates the wire-in claim and routes a re-run.

## Verification commands (re-runnable)

```bash
# Acceptance fixture (synthetic v2 conformant + dirty rows)
bash /Users/josh/Developer/flywheel/tests/dispatch-log-schema-validator-tick-wire-in.sh
# Expected: SUMMARY pass=20 fail=0

# Doctor field surfacing on real repo (tail-bounded)
FLYWHEEL_DISPATCH_LOG_V2_TAIL=10 \
  /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel --json \
  | jq '{dispatch_log_v2_violations_count, dispatch_log_v2_total_rows_checked, dispatch_log_v2_violations_status}'

# Validator alone with --tail
bash /Users/josh/Developer/flywheel/.flywheel/scripts/dispatch-log-schema-validator.sh \
  validate --repo /Users/josh/Developer/flywheel --tail 5 --json | jq '.invalid'
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/dispatch-log-schema-validator-tick-wire-in.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=20 fail=0`.

## Boundary

- No production worker code touched. Workers continue to emit dispatch-log
  rows; this rework only adds bounded validation surfaces around the existing
  ledger.
- The 10/10 violation count on real-world tail is **expected and visible**
  on purpose — it reflects upstream emit-side null-claim bugs that the
  T4A/T4B coord-wire-in arc owns. The wire-in's job is to **make the
  violations visible to the tick + doctor**, not to fix the emitters.
- Validator's full-log behavior is unchanged when `--tail` is unset or `0`.
- Doctor wrapper falls back to `~/Developer/flywheel/.flywheel/scripts/...`
  when run from a non-flywheel repo so the lib probe stays functional in
  fleet doctor calls.

## Skill auto-routes

- `canonical-cli-scoping=yes` — validator extends doctor/health/validate
  triad with `--tail N` flag; wrapper exposes `doctor|health|validate|info|
  schema|why|help` subcommands with `--json` and stable exit codes
  `0/1/2`. Help tier present, default-on JSON when `--json` is set.
- `rust-best-practices=n/a` — no Rust touched.
- `python-best-practices=n/a` — no new Python; embedded validator script
  unchanged.
- `readme-writing=n/a` — no public README touched; tick.md is doctrine, not
  README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — wire-in does not introduce new doctrine; it
  consumes existing schema + validator and adds a tick step + doctor field.
  The Step 4z.1 entry in `tick.md` is itself the canonical doctrine surface
  and is updated.
- `readme_updated=not_applicable`.
- `no_touch_reason=tick_md_step_is_canonical_surface_for_this_substrate_no_higher_doctrine_layer_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Tick step, validator exit
  codes for both v2-conformant and missing-required cases, doctor field
  exposed.
- **Sniff: 9** — fixture test exercises clean and dirty paths with
  synthetic inputs that don't depend on real corpus state; doctor wrapper
  uses canonical CLI scoping (doctor/health/validate triad + info/schema/
  why/help tier + `--json` + stable exit codes).
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; problem-statement
  framing for the upstream emit-side bug (call it out, route to T4A/T4B
  arc, don't auto-file); pinned SHAs for every load-bearing artifact;
  small surface (3 new files + 3 surgical edits); no upstream patch on any
  Jeffrey-owned repo.
- **Public: 9** — Three Judges check passes:
  - **operator (skeptical, acting tomorrow)**: one command runs the
    fixture, one command surfaces the doctor field; both deterministic
    in <1s.
  - **maintainer (extending later)**: probe function lives next to
    sibling `dispatch_contract_doctor_json` and the wire-in mirrors the
    `dispatch_contract` packet pattern exactly — future-you can copy the
    pattern for a third probe without re-discovering anything.
  - **future worker (LLM agent)**: bar named, fixture cites `pass=20
    fail=0`, doctor surfaces a single integer field grep-friendly for
    "is the dispatch-log clean tail?" question.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8;
bar = Three Judges + Jeffrey Emanuel publishability + Donella Meadows
leverage).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-yu8g
no_bead_reason=wire-in_acceptance_complete_existing_v2_emit_bugs_owned_by_T4A_T4B_arc`.

## Mission fitness

`mission_fitness=infrastructure` — wire-in adds substrate plumbing
(validator flag, doctor wrapper, tick step, lib doctor packet entry) so
upstream emit drift becomes visible to the orchestrator. Adjacent claim
per packet acknowledged; actual work is infrastructure tier.
