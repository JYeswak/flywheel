---
bead: flywheel-5ke66.8
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-NUANCED-PARTIAL-BYPASS
sister_exemplars: 5ke66.6 (985, full PARTIAL-BYPASS); 5ke66.4 (985, BYPASS-ALL); 5ke66.2 (985, NO-BYPASS)
---

# Evidence Pack — flywheel-5ke66.8

## Scope

Wave-2-general-8 (8th of 21 5ke66 sub-beads). Apply canonical-cli scaffold +
substantive fillin to `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh`
— per-session META-RULE-CACHE.md staleness probe vs canonical INDEX.md.
Surface is a **NUANCED-PARTIAL-BYPASS variant** (fourth wzjo9.1.7 variant
documented): native owns ONLY `--info|--schema` (NOT `--examples` because
native errors on it).

## Files touched

`.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` (111 → 357 lines
after scaffold; TODO=0; `_scaffold_is_canonical_arg` modified to NUANCED-
PARTIAL-BYPASS)
`tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh` (94 → 162
lines, 13 → 19 tests calibrated to NUANCED-PARTIAL-BYPASS contract)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/fleet-canonical-rule-freshness-probe.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/fleet-canonical-rule-freshness-probe.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/fleet-canonical-rule-freshness-probe.sh \
  && bash tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## WZJO9.1.7 variants now documented (FOUR)

| Variant | Bypass scope | Application |
|---|---|---|
| **NO-BYPASS** | None — scaffold owns all canonical | 5ke66.2 (append-safe-write) |
| **PARTIAL-BYPASS** | All three flags `--info / --schema / --examples` | 5ke66.6 (daily-report) |
| **NUANCED-PARTIAL-BYPASS** | Only `--info / --schema` (NOT `--examples`) | 5ke66.8 (this surface) |
| **BYPASS-ALL** | All canonical surfaces (verbs + flags) | 5ke66.4 (bleed-ledger-watch) + wzjo9.1.7 (flywheel-loop) |

This is the NUANCED variant because the native script implements `--info`
and `--schema` but NOT `--examples` (errors with rc=64 on unknown arg).
Letting `--examples` route to native would silently break the canonical-CLI
contract; routing it to scaffold provides the canonical envelope.

The fix:

```bash
case "${1:-}" in
  doctor|health|repair|validate|audit|why|...) return 0 ;;  # scaffold
  --info|--schema) return 1 ;;  # PARTIAL-BYPASS to native
  --examples) return 0 ;;        # NOT bypassed — scaffold owns
  ...
esac
```

## Domain-specific fillins

### doctor (6 named probes)

- `bash`, `jq` — universal
- `mktemp_available`
- `stat_available` — **load-bearing** with detail field annotating BSD
  (`-f %m`) + GNU (`-c %Y`) form fallback (the script's actual mtime
  computation tries both)
- `canonical_index_readable` — `~/.flywheel/canonical-meta-rules/INDEX.md`
  (warn-tier; rc=2 in cmd_run if missing)
- `audit_log_dir_writable`

### health

12h stale threshold (intra-day cadence; tunable via
`FLEET_CANONICAL_RULE_FRESHNESS_PROBE_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes)

- `canonical_index_dir` → `mkdir -p ~/.flywheel/canonical-meta-rules`
  (note: only ensures dir; INDEX.md must be populated separately)
- `audit_log_dir`
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects)

- `session-name` regex `^[a-z][a-z0-9_-]*$` matching the SESSIONS array
  fixture values (flywheel/alpsinsurance/vrtx/skillos/mobile-eats)
- `status-value` **enum-typed** restricted to `{fresh, stale, missing}` —
  these are the LOAD-BEARING values from the script's per-session emit()
  function and the native --schema enum
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/session/cache_path/run_id matching the per-session row schema).

## Test calibration (13 → 19, NUANCED contract)

Baseline tests calibrated to NUANCED-PARTIAL-BYPASS contract:

- Test 2 (`--info`): native text shape (grep for `fleet-canonical-rule-
  freshness-probe`)
- Test 3 (`--schema`): native raw JSON-Schema (.type=="object" + properties.
  status); NOT canonical envelope shape
- Test 4 (`--examples`): scaffold envelope (NOT bypassed — calibrated per
  this variant's nuanced rule)
- Test 5 (`doctor`): scaffold envelope with >=5 checks
- Tests 6-13: scaffold owns subcommands

6 fillin assertions:

- Test 14: NUANCED-PARTIAL-BYPASS annotation grep-discoverable
- Test 15: **dual-direction fidelity check** — `--info` goes native (text +
  no schema_version) AND `--examples` goes scaffold (canonical envelope);
  catches regressions where someone over-bypasses or under-bypasses
- Test 16: validate status-value full-enum sweep (fresh/stale/missing all
  accepted)
- Test 17: validate status-value rejects unknown enum (`expired`)
- Test 18: doctor stat_available probe annotates BSD + GNU mtime forms
- Test 19: backward-compat — native default-run still emits per-session
  staleness rows for the SESSIONS array

## Notable bug-catch

Test 19 initially used `"$SCRIPT" --json | head -1 | jq` which failed
under `set -uo pipefail` because `head -1` closes the pipe early on the
producer side, generating SIGPIPE → rc=141 → if-statement reads non-zero
→ test fails. Reproduced interactively (true, rc=0) but failed in test
runner. Fixed with file-capture pattern (`"$SCRIPT" --json >tmpfile;
head -1 tmpfile | jq`) which avoids the SIGPIPE entirely. Worth noting
as a META-RULE: `set -uo pipefail` + `command | head -N | jq` is unsafe
when the command is a long-running producer.

## Smoke captures

17 smoke captures verify all four route directions
(--info native, --schema native, --examples scaffold, doctor scaffold,
all validate subjects, both repair scopes, audit/why, native default-run
preserved).

## Mission fitness

Class: **adjacent** (per dispatch). fleet-canonical-rule-freshness-probe.sh
is the cross-session META-RULE-CACHE staleness detector;
canonical-CLI surface (mixed scaffold + native) lets the orchestrator
probe substrate (stat / canonical INDEX) and validate session names +
status enum values in dispatch packets.
