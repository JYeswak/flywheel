---
bead: flywheel-1hshd.16
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-NUANCED-PARTIAL-BYPASS + CROSS-SOURCE-CONSISTENCY-2ND
sister_exemplars: 5ke66.8 + 1hshd.11 (NUANCED siblings); 5ke66.11 (cross-source consistency 1st)
---

# Evidence Pack — flywheel-1hshd.16

## Scope

Wave-4-general-16. Apply canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh`
— bounded bare-Enter recovery primitive for codex queued-not-submitted
panes. Coordinates with capacity-halt lease/auth/budget/success
sub-primitives. Emits one of 9 stable exit codes.

## Files touched

`.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh`
(180 → 426 lines after scaffold; TODO=0)
`tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh`
(94 → 162 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh \
  && bash tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Variant choice — NUANCED-PARTIAL-BYPASS

Per-flag baseline probe pre-scaffold confirmed:
- Native `--info --json` emits canonical envelope (info.v1 with full
  metadata + verbs list + exit_codes mapping)
- Native `--examples --json` emits canonical envelope (examples.v1 with
  examples list)
- Native `--schema` does NOT exist (errors with usage)
- Native verbs do NOT exist

Bypass list: `{--info, --examples}` only — scaffold owns `--schema`
AND verbs. Sister to 5ke66.8 + 1hshd.11 (NUANCED variant).

## Cross-source consistency check — 2nd application

Test 19 applies the cross-source consistency pattern from 5ke66.11 to
this surface's exit_codes enum:
- Native `--info --json | jq -r '.exit_codes | keys'` → `[0,1,2,3,4,5,6,7,8]`
- Scaffold `validate exit-code __probe_unknown__ | jq -r '.valid_codes'` →
  `[0,1,2,3,4,5,6,7,8]`
- Sorted-string equality assertion catches enum drift between native
  docstring + scaffold validator

Pattern is now FORMALLY MATURE at 2 occurrences (5ke66.11
conformance-axis + 1hshd.16 exit-code).

## Domain-specific fillins

### doctor (9 named probes)

- `bash`, `jq`, `mktemp` — universal
- `python3_available` — load-bearing for recovery heredoc
- `tmux_available` — load-bearing (sends bare-Enter via tmux send-keys)
- `capacity_halt_lease_executable` — **load-bearing** for lease coordination
- `capacity_halt_auth_executable` — **load-bearing** for pane authorization
- `capacity_halt_budget_executable` — **load-bearing** for burst-budget enforcement
- `audit_log_dir_writable`

### health

7d stale threshold (on-demand recovery primitive — runs only when codex
queued-not-submitted situation detected; tunable via
`CODEX_QUEUED_BARE_ENTER_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes)

- `fallback_ledger_dir` → `mkdir -p ~/.local/state/flywheel`
  (target for fallback ledger when capacity-halt-budget primitive
  unavailable)
- `audit_log_dir`
- Apply contract rc=3 + unknown_scope rc=64

### validate (4 subjects, domain-precise)

- `session-name` regex `^[a-z][a-z0-9_-]*$` matching --session arg
- `pane-index` integer in `[0, 99]` matching --pane arg
- `exit-code` **enum-typed** restricted to 9 codes (0=fired-success,
  1=fired-failed, 2=lease-held, 3=malformed, 4=transport-timeout,
  5=protected-refusal, 6=unknown-pane, 7=topology-stale, 8=budget-
  exhausted) per script L20-L29 docstring AND native --info exit_codes
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/session/pane/run_id matching the per-recovery-event row schema).

## Test calibration (13 → 19)

- Test 2 (`--info`): native shape (info.v1 + 9 exit_codes verified)
- Test 3 (`--schema`): scaffold shape (NOT bypassed)
- Test 4 (`--examples`): native shape (examples.v1)
- Tests 5-13: scaffold owns subcommands

6 fillin assertions:

- Test 14: NUANCED-PARTIAL-BYPASS annotation grep-discoverable
- Test 15: doctor probes capacity_halt trio (lease + auth + budget)
- Test 16: validate exit-code full-enum sweep (all 9 codes)
- Test 17: validate exit-code rejects 9 (out of native enum)
- Test 18: validate pane-index boundary values (0 + 99)
- Test 19: **CROSS-SOURCE CONSISTENCY** — native --info exit_codes keys
  MUST equal scaffold validate valid_codes (sorted equality catches
  drift between native heredoc + scaffold validator). 2nd application
  of this canonical pattern after 5ke66.11.

## Notable

- **9 exit-codes enum** is the surface's primary contract. Both native
  --info and scaffold validate document the same 9 codes; cross-source
  consistency check (test 19) catches drift between the two sources.
- **Capacity-halt trio probe** captures the script's coordination
  dependencies — without lease/auth/budget executables, the recovery
  primitive cannot orchestrate the bare-Enter send safely.
- **Script docstring as source of truth** — exit_codes enum references
  L20-L29 explicitly. Validators reference docstring; tests cross-check
  against native --info; native --info matches docstring. Three-way
  consistency.

## Smoke captures

17 smoke captures: native --info + --examples + scaffold doctor/health/
3 repair scopes/4 validate subjects accept+reject pairs/audit/why/
quickstart/--schema.

## Mission fitness

Class: **adjacent**. codex-queued-not-submitted-bare-enter-primitive.sh
is the bounded recovery primitive for codex panes stuck in
queued-not-submitted state; canonical-CLI surface lets orchestrator
probe substrate (capacity-halt trio + tmux + python) and validate
session/pane/exit-code args before invoking recovery.
