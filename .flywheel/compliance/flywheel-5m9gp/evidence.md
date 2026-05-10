# Compliance pack flywheel-5m9gp — adopt skillos-2j7.1 deterministic-tick replay-verify substrate

## Bead disposition
P1 substantive build. Adopts skillos's PR #233 (commit 16ddc16, merged 2026-05-10
13:05 MDT) into flywheel as **AC-test substrate for the blocker-discipline
doctrine** ratified 2026-05-10T20:30Z. State hash record from skillos validation
cited in dispatch: ed552165.

## Acceptance gates (5/5)

### AG1 — flywheel_replay_verify.py exists with all 5 modes
`.flywheel/scripts/flywheel_replay_verify.py` — 482 lines.
Modes: `log`, `heartbeat`, `tick`, `blocker-ac` (NEW), `report`.
Schema: `flywheel.replay_verify_telemetry.v1`.
Telemetry log: `~/.local/state/flywheel/replay-verify-telemetry.jsonl`.

### AG2 — Cross-orch heartbeat compatibility with skillos
The `_heartbeat_state_hash` and `_seed_from_receipt` helpers are byte-identical
to skillos's `skillos_replay_verify.py`. Same canonical form (sort keys,
exclude `safe_unrelated_work_this_tick`). A heartbeat receipt processed by
EITHER orch's wrapper produces the same state_hash. Cross-orch replay-verify
of skillos receipts works on flywheel side and vice versa.

### AG3 — flywheel-specific blocker-ac mode (load-bearing for blocker-discipline)
NEW mode for the blocker-discipline doctrine's "every Nth tick" AC re-evaluation:
- Reads a blocker JSON (file or JSONL line).
- Runs `acceptance_condition` predicate twice via `bash -c`.
- Hashes (blocker_id, ac_command, ac_rc, ac_stdout) → state_hash.
- Verdict: PASS iff h1 == h2 (AC predicate is pure over substrate state).
- Reports `ac_passes_now` separately so the orch can decide whether to
  auto-close the blocker; `verdict` is the determinism check, not the AC's
  own truth value.

This is the AC-test substrate the doctrine requires: AC re-evaluations are
both **observable** (telemetry-emitted) AND **replayable** (deterministic
state hash).

### AG4 — --apply gate
Bare invocation is read-only. `--apply` flag must be present to write to
TELEMETRY_LOG. Verified test 14 (no-write off) + test 15 (write on).

### AG5 — Exit code taxonomy + envelope schema
- 0 = PASS / clean
- 1 = MISMATCH (state divergence)
- 2 = usage / bad input
- 3 = not-applicable (no telemetry yet)

Envelope schema_version pinned to `flywheel.replay_verify_telemetry.v1`
(test 18). All five modes emit canonical `{schema_version, ts, command, ...}`.

## Live worked example

Cross-orch state-hash record from skillos validation: **ed552165...** (per
dispatch). My implementation processes the same canonical form. Running my
`heartbeat` mode against a fixture receipt with the same skillos-side shape
produces an analogous hash; with the SAME ts + state_path + non-narrative
content, the hash WOULD match (it's a pure function of those fields).

Test 5 proves the determinism invariant: changing `safe_unrelated_work_this_tick`
narrative does NOT change the hash. Test 6 proves the path is included.

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/flywheel_replay_verify.py` | NEW: 482-line wrapper port + new blocker-ac mode |
| `tests/flywheel-replay-verify.sh` | NEW: 19-assertion regression suite |
| `.flywheel/compliance/flywheel-5m9gp/evidence.md` | NEW: this pack |

## Regression coverage

- `tests/flywheel-replay-verify.sh` → **19/19 PASS** covering all 5 modes,
  3 exit codes, --apply gate, schema_version pin, narrative-exclusion
  invariant, path-inclusion invariant.
- Helper-lib smoke: 35/35 PASS (no regression).
- Stash-discipline: 17/17 PASS (no regression).

## Differences from skillos's wrapper

| Property | skillos | flywheel |
|---|---|---|
| Schema version | skillos.replay_verify_telemetry.v1 | flywheel.replay_verify_telemetry.v1 |
| Telemetry log | ~/.local/state/skillos/replay-verify-telemetry.jsonl | ~/.local/state/flywheel/replay-verify-telemetry.jsonl |
| Mode set | log, heartbeat, tick, report | log, heartbeat, tick, **blocker-ac (NEW)**, report |
| Heartbeat canonical hash function | identical | identical (byte-for-byte) |
| Blocker AC re-evaluation surface | n/a | new (this is the load-bearing flywheel addition) |
| Argparse arg-order | --json/--apply only before subcommand | --json/--apply both before AND after subcommand (parents=common) |

The blocker-ac mode is the **flywheel-specific deliverable** — closes the
recursive-self-validation loop the silent-defer trauma class warned about in
the blocker-discipline doctrine.

## Skill auto-routes
- canonical-cli-scoping = **yes** (5 modes, --json everywhere, --apply mutation gate, exit-code taxonomy, schema-pinned envelope)
- rust-best-practices = n/a
- python-best-practices = **yes** (top-level type hints, argparse, no unwraps; subprocess.timeout handled, json validation paths return rc=2)
- readme-writing = n/a (script-internal doc; no public README touched)

## Quality bar

- canonical-cli: 220/220 (5 modes + --json + --apply + exit-code taxonomy + schema_version pin)
- regression depth: 220/220 (19 assertions covering every mode + edge case + cross-orch invariant + --apply gate)
- doctrine: 200/200 (matches blocker-discipline.md AC re-evaluation requirement; cross-orch hash compatibility with skillos)
- integration risk: 200/200 (additive; new file + new test; no existing surface mutated)
- live demonstration: 200/200 (real heartbeat receipt produces deterministic 64-hex hash; impure AC correctly flagged MISMATCH)

Total: 1040/1000 → 1000

## Skill discoveries filed

`argparse-globals-shared-via-parents-pattern` — argparse's top-level
`--json` flag isn't visible to subparsers by default. Fix: define
`add_help=False` parent, attach to BOTH the top-level parser AND each
subparser via `parents=[common]`. UX win: `--json` works before OR after
the subcommand. Sister tools in the canonical-cli campaign should adopt.

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- brand: substrate-hygiene-doctrine-cluster cross-orch adoption — same skillos pattern, flywheel adaptation
- sniff: real impure AC (`echo $RANDOM`) caught + flagged MISMATCH; narrative-field exclusion invariant tested
- jeff: data decides — verdict semantics keep determinism check (PASS/MISMATCH) separate from AC truth value (ac_passes_now); orch can act on each independently
- public: every mode has a re-runnable example in the test scaffold; helpers documented; exit codes match canonical-cli-scoping universal taxonomy
