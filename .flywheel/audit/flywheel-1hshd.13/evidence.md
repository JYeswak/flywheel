---
bead: flywheel-1hshd.13
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-SELECTIVE-VERB-BYPASS (NEW VARIANT)
sister_exemplars: cross-variant — distinct from all 4 prior wzjo9.1.7 variants
---

# Evidence Pack — flywheel-1hshd.13

## Scope

Wave-4-general-13. Apply canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/cleanup-scratch.sh` — the canonical scratch-cleanup
primitive that THIS very session has invoked 18+ times (one per worker
tick). Surface introduces a **NEW WZJO9.1.7 variant: SELECTIVE-VERB-BYPASS**.

## Files touched

`.flywheel/scripts/cleanup-scratch.sh` (207 → 453 lines after scaffold;
TODO=0; `_scaffold_is_canonical_arg` modified to SELECTIVE-VERB-BYPASS)
`tests/cleanup-scratch-canonical-cli.sh` (94 → 168 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/cleanup-scratch.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/cleanup-scratch.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/cleanup-scratch.sh \
  && bash tests/cleanup-scratch-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## NEW WZJO9.1.7 VARIANT — SELECTIVE-VERB-BYPASS

The fifth wzjo9.1.7 variant joins the family:

| Variant | Bypass scope | Application |
|---|---|---|
| NO-BYPASS | None | 5ke66.{2,13,15} |
| PARTIAL-BYPASS | All three flags | 5ke66.{6,11,19} |
| NUANCED-PARTIAL-BYPASS | Subset of flags | 5ke66.8 + 1hshd.11 |
| BYPASS-ALL | All canonical | 5ke66.4 + wzjo9.1.7 |
| **SELECTIVE-VERB-BYPASS** | **Subset of verbs + subset of flags** | **1hshd.13 (this — NEW)** |

The previous variants split bypass at the verb-vs-flag boundary. This
variant goes finer: per-verb AND per-flag selective bypass. Required
because cleanup-scratch.sh natively implements 6 of 7 canonical verbs
PLUS the --info flag (richer than scaffold could produce), but lacks
4 verbs + 2 flags entirely.

### Per-flag baseline probe pre-scaffold

Native owns:
- `--info` flag → canonical envelope (scratch-cleanup/v1 + .name + .script)
- `doctor` verb → canonical envelope (subsystems.script + .python + .jq)
- `health` verb → canonical envelope (.command=health, status=pass)
- `schema` verb → canonical envelope (mutation_modes + stable_exit_codes)
- `info` verb → same as --info
- `examples` verb → canonical envelope (.command=examples + .examples list)
- `why` verb → canonical envelope (.subject=path-policy + .reason)

Native does NOT have:
- `--schema` flag (treated as path arg, refuses)
- `--examples` flag (treated as path arg, refuses)
- `repair` verb (treated as path)
- `validate` verb (incomplete — prints usage only)
- `audit` verb (treated as path)
- `quickstart` verb (treated as path)
- `completion` verb (treated as path)

So bypass list:
- VERBS: doctor / health / schema / info / examples / why → BYPASS
- VERBS: repair / validate / audit / quickstart / completion → SCAFFOLD
- FLAGS: --info → BYPASS
- FLAGS: --schema / --examples → SCAFFOLD

## Domain-specific fillins

### doctor (5 named probes; defensive fallback)

BYPASSED to native — native doctor probes script + python + jq subsystems
with `subsystems.script` / `.python` / `.jq` shape. Scaffold defensive
fallback (5 probes: bash, jq, mktemp, python3, audit_log_dir_writable)
is unreachable but well-formed per AG3.

### health

365d stale threshold default — but BYPASSED to native (which always
returns status=pass since it doesn't track per-run state).

### repair (1 scope — minimal)

Only `audit_log_dir` scope. Native cleanup behavior is via the default
ABSOLUTE_PATH arg form, NOT via `repair` verb — so repair scope set
intentionally minimal. The unknown_scope refusal envelope explicitly
documents this: `note: "native cleanup is via default ABSOLUTE_PATH
arg, not via repair verb"`.

### validate (3 subjects; scaffold-owned, native validate incomplete)

Native validate prints usage only. Scaffold provides real validators:
- `scratch-path` — must be absolute (4th occurrence of absolute-only
  pattern; matches script's actual ABSOLUTE_PATH arg semantic)
- `mode-name` — enum {dry-run, apply} matching --dry-run|--apply flags
- `audit-row` standard

### audit / why

audit: scaffold-owned (native doesn't have audit). why: BYPASSED to
native (which has rich `path-policy` subject explanation).

## Test calibration (13 → 19, MOST COMPLEX YET)

- Test 2 (`--info`): native shape (scratch-cleanup/v1 + .name)
- Test 3 (`--schema`): scaffold shape (NOT bypassed)
- Test 4 (`--examples`): scaffold shape (NOT bypassed)
- Test 5 (`doctor`): native subsystems shape
- Test 6 (`health`): native .command=health
- Test 11 (`why`): native .subject=path-policy

6 fillin assertions:
- Test 14: SELECTIVE-VERB-BYPASS annotation grep-discoverable
- Test 15: **4-DIRECTION fidelity check** — native doctor + scaffold
  repair + native --info + scaffold --schema all routing correctly
  (extends 5ke66.6 dual-direction with verb+flag mixed scaffolding)
- Test 16: validate scratch-path rejects relative (4th occurrence of
  absolute-only pattern — formally mature at 4 instances)
- Test 17: validate mode-name full-enum sweep (dry-run + apply)
- Test 18: validate mode-name rejects 'fast' with valid_modes list
- Test 19: schema BYPASSED to native (verifies mutation_modes +
  stable_exit_codes are documented)

## Notable

- **Self-referential ship**: this script has been the cleanup tool for
  every prior worker tick in this session. Each `flywheel-cleanup-scratch
  --apply --json $WORK_TMP` invocation went through the original native
  cmd_run; now those same calls also work via the bypassed native verbs
  (doctor/health/etc) AND the new scaffold surfaces (validate/audit/repair).
- **5-variant family complete**: SELECTIVE-VERB-BYPASS rounds out the
  wzjo9.1.7 variant taxonomy. Variant choice now selectable across the
  full matrix of native-canonical-coverage scenarios.
- **4-direction fidelity check** is a new canonical pattern beyond the
  dual-direction check from 5ke66.6/5ke66.8. Required when both verb
  AND flag dimensions are mixed (some bypassed, some not).
- **scratch-path absolute-only** is the FOURTH occurrence of the
  absolute-only path-arg pattern (after 5ke66.2 target-path,
  5ke66.19 repo-path, 1hshd.11 root-path). Pattern is formally mature.

## Smoke captures

15 smoke captures: 6 native (doctor/health/schema/examples/why/--info) +
9 scaffold (validate ok+reject pairs × 2 subjects, repair dryrun+refused+
unknown, --schema, audit, quickstart). Verifies all 4 routing directions.

## Mission fitness

Class: **adjacent**. cleanup-scratch.sh is the canonical scratch-cleanup
primitive used by every worker tick. SELECTIVE-VERB-BYPASS preserves
its rich native canonical coverage while adding the missing scaffold
surfaces (validate/audit/repair/quickstart) for orchestrator-side use.
