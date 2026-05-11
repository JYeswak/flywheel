---
bead: flywheel-5ke66.11
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-PARTIAL-BYPASS
sister_exemplars: 5ke66.6 (985, same PARTIAL-BYPASS variant); 5ke66.8 (985, NUANCED variant); 5ke66.4 (985, BYPASS-ALL); 5ke66.2 (985, NO-BYPASS)
---

# Evidence Pack — flywheel-5ke66.11

## Scope

Wave-2-general-11 (11th of 21 5ke66 sub-beads). Apply canonical-cli scaffold
+ substantive fillin to `.flywheel/scripts/fleet-conformance-probe.sh` —
bounded fleet conformance scorer per session over 6 axes
(canonical_l_rule_coverage / doctor_status / identity_drift /
meta_rule_cache_freshness / mission_lock_age / agents_mtime_age). Surface
is **PARTIAL-BYPASS** (sister to 5ke66.6 daily-report).

## Files touched

`.flywheel/scripts/fleet-conformance-probe.sh` (507 → 753 lines after
scaffold; TODO=0; `_scaffold_is_canonical_arg` modified to PARTIAL-BYPASS)
`tests/fleet-conformance-probe-canonical-cli.sh` (94 → 168 lines, 13 → 19
tests calibrated to PARTIAL-BYPASS contract)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/fleet-conformance-probe.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/fleet-conformance-probe.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/fleet-conformance-probe.sh \
  && bash tests/fleet-conformance-probe-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## WZJO9.1.7 PARTIAL-BYPASS variant (second application)

Five wzjo9.1.7 application data points now in this codebase:

| Variant | Bypass list | Application |
|---|---|---|
| **NO-BYPASS** | None | 5ke66.2 append-safe-write |
| **PARTIAL-BYPASS** | `--info / --schema / --examples` | 5ke66.6 daily-report |
| **PARTIAL-BYPASS** | (same) | **5ke66.11 (this — second occurrence)** |
| **NUANCED-PARTIAL-BYPASS** | Only `--info / --schema` (NOT --examples) | 5ke66.8 freshness-probe |
| **BYPASS-ALL** | All canonical | 5ke66.4 bleed-ledger-watch + wzjo9.1.7 flywheel-loop |

This surface is PARTIAL-BYPASS because:
- Native `--info` emits `schema_version: "fleet-conformance-observatory/v1"`
  + 6-axis enumeration + canonical_cli_flags + Donella leverage points
- Native `--schema` emits full JSON-Schema for the `fleet_conformance`
  result envelope (red/yellow/green counts + worst session + min score)
- Native `--examples` emits text invocation lines (--fleet --json patterns)

All three are domain-richer than scaffold could produce → bypass to native.

## Domain-specific fillins

### doctor (7 named probes)

- `bash`, `jq`, `mktemp` — universal
- `python3_available` (load-bearing, detail flags fleet-conformance heredoc)
- `loops_dir_readable` (~/.flywheel/loops; per-session loop state for
  conformance scoring; warn-tier)
- `canonical_agents_readable` (~/.flywheel/canonical-agents.json; identity
  drift baseline; warn-tier)
- `audit_log_dir_writable`

### health

12h stale threshold (intra-day cadence; tunable via
`FLEET_CONFORMANCE_PROBE_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes)

- `cache_dir` → `mkdir -p $FLEET_CONFORMANCE_CACHE_DIR` (60s default-TTL
  conformance cache target, matches native `cache_ttl_seconds_default`)
- `audit_log_dir`
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects)

- `session-name` regex `^[a-z][a-z0-9_-]*$`
- `conformance-axis` **enum-typed** restricted to the 6 axes from native
  `--info` axes field (canonical_l_rule_coverage, doctor_status,
  identity_drift, meta_rule_cache_freshness, mission_lock_age,
  agents_mtime_age) — load-bearing because these ARE the axes the
  scoring fn uses
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/session/axis/run_id matching the per-session conformance row schema).

## Test calibration (13 → 19)

Baseline tests calibrated to PARTIAL-BYPASS:

- Test 2 (`--info`): native `.schema_version observatory/v1 + .axes (6)`
- Test 3 (`--schema`): native `.type=object + .properties.fleet_conformance`
- Test 4 (`--examples`): native text invocations (grep-based)
- Tests 5-13: scaffold owns subcommands

6 fillin assertions:

- Test 14: PARTIAL-BYPASS annotation grep-discoverable
- Test 15: dual-direction fidelity check (--info goes native observatory/v1
  AND doctor goes scaffold probe/v1) — validates that BOTH schema_version
  contracts coexist correctly
- Test 16: full-enum sweep over all 6 conformance axes
- Test 17: rejects unknown axis with valid_axes enumeration
- Test 18: doctor probes load-bearing python3 + loops_dir + canonical_agents
- Test 19: **cross-source consistency check** — native `--info` `.axes`
  array MUST equal scaffold validate `.valid_axes` (sorted comparison) —
  catches enum drift between the two sources of truth (native heredoc
  + scaffold validator) for the SAME canonical 6-axis enum

## Notable

- Test 19 is the LOAD-BEARING canonical pattern for surfaces where BOTH
  native and scaffold encode the same enum: cross-source equality check
  catches the case where a maintainer adds an axis to one location and
  forgets the other. Pulls scaffold's enum via the `validate <subj>
  <unknown>` reject envelope (which surfaces `valid_axes`) since the
  scaffold's `--schema validate` access route is bypassed to native.
- Initial test 19 attempted `--schema validate` to access scaffold's
  per-surface schema, but `--schema` is bypassed to native which doesn't
  understand positional args. Fixed by using `validate <subject>
  <unknown>` reject envelope instead — this access route is scaffold-
  owned because the verb is scaffold-owned.
- The two variant=PARTIAL-BYPASS cases (5ke66.6 daily-report + this one)
  confirm the variant is robust enough to apply mechanically to scripts
  with rich native flag-form introspection.

## Smoke captures

15 smoke captures verify all four route directions
(--info/--schema/--examples native, doctor/health/repair/validate/audit/why
scaffold).

## Mission fitness

Class: **adjacent** (per dispatch). fleet-conformance-probe.sh is the
bounded fleet conformance scorer with auto-fix-bead drive (Donella
leverage points 5,6); canonical-CLI surface (mixed scaffold + native)
lets orchestrator probe substrate (loops_dir, canonical-agents) and
validate session names + axis enum values in dispatch packets.
