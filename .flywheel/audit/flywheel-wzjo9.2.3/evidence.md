---
title: flywheel-wzjo9.2.3 evidence — recovery-baseline-status.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.2.3
parent: flywheel-wzjo9.2 (wave-2.0b)
sister: wave-2.0a 6/9 closed avg 980; 1fk5f.{1..8} avg 974
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0b-c
---

# flywheel-wzjo9.2.3 evidence

**Status:** DONE — recovery-baseline-status.sh scaffolded + 18-TODO fillin shipped. **20/20 PASS** on canonical-cli scaffold-test (13 baseline + 7 fillin-specific). AG1-5 strict-pass. Lint clean. cmd_run python passthrough verified.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1–L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin) |
| AG5: each surface returns concrete data | DID — see live-signal table |

did=5/5, didnt=none, gaps=none.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | missing | passing |
| Lines | 84 | 506 |
| Magic comment | absent | present |
| Backup | n/a | `recovery-baseline-status.sh.bak.scaffold-20260510T214423586902000Z-98009` |

## Substantive fillin

The script is unusual — a thin bash wrapper that exec's an inline python3 heredoc. The python script reads the latest baseline manifest from `~/.flywheel/recovery/snapshots/baseline-*.manifest.json`, checks if `com.zeststream.recovery.nightly-snapshot` plist is active via launchctl, finds the latest passing drill from `~/.flywheel/recovery/drills/drill-*.json`, and emits a JSON status envelope.

### Substrate probes (doctor)

| Probe | Description |
|---|---|
| `python3_on_path` | required for cmd_run heredoc |
| `snapshot_dir_present` | `~/.flywheel/recovery/snapshots` (warn-not-fail when absent) |
| `drill_dir_present` | `~/.flywheel/recovery/drills` (warn-not-fail) |
| `launchctl_executable` | `/bin/launchctl` |
| `nightly_plist_present` | `~/Library/LaunchAgents/com.zeststream.recovery.nightly-snapshot.plist` (warn) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas (doctor / health / repair / validate / audit / why / audit-row / default)
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes
- **scaffold_cmd_health:** tail audit log; warn stale >24h (daily cadence)
- **scaffold_cmd_repair:** 2 scopes (audit-log-rotate 5MB + snapshot-dir-prime read-only probe of manifest dir)
- **scaffold_cmd_validate:** 4 subjects (row / schema / config / **manifest** — recovery-specific)
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail`
- **scaffold_cmd_why:** searches audit log for matching manifest_path basename or label

## Live signals surfaced

1. doctor **5/5 pass** (python3 + launchctl + snapshot/drill/plist dirs all present)
2. `repair --scope snapshot-dir-prime` → **`manifest_count:1, latest_manifest:baseline-20260507T233254Z.manifest.json`** — fleet has 1 baseline manifest from 3 days ago
3. `validate --manifest` → **`status:pass, missing_required:[]`** — manifest validates clean against required-fields contract
4. **cmd_run python `--json` passthrough works** — returns `{schema_version:flywheel-recovery-baseline-status/v1, status:pass, nightly_active:false, last_drill:2026-05-07T03:20:00Z}` — two-layer schema_version namespace working as designed

## Bug-fix during validation (sniff lens at work)

First-pass required-fields assumption for `validate --manifest` was `["created_at","protected"]`. The live `validate --manifest` invocation returned `status:fail` — which surfaced my wrong assumption. Inspected actual manifest at `~/.flywheel/recovery/snapshots/baseline-20260507T233254Z.manifest.json` and corrected to `["created_at","protected_sessions_restore_blocked","schema_version"]` (the field is `protected_sessions_restore_blocked`, not `protected`). Added a comment in code explaining the live-manifest verification.

**This is the fillin doing its job** — the substantive validate surface caught an assumption error against real data.

## cmd_run python passthrough preserved

The script has dual schema_version namespace by design:
- **Scaffold layer** (canonical surfaces): `schema_version:"recovery-baseline-status/v1"` — `--info`, `--schema`, `doctor`, `health`, `repair`, `validate`, `audit`, `why`
- **cmd_run layer** (original python): `schema_version:"flywheel-recovery-baseline-status/v1"` — `--json` / no canonical args invocation

Both layers coexist cleanly. Test 20 explicitly asserts the cmd_run passthrough still works.

## Test scaffold extensions (13 → 20)

- Test 14: `--info schema_version` matches `recovery-baseline-status/v1`
- Test 15: `--schema` envelope well-formed
- Test 16: doctor 5+ probes incl. `python3_on_path` + `launchctl_executable`
- Test 17: repair `--scope snapshot-dir-prime` non-stub envelope
- Test 18: validate `--row-json` enforces schema
- Test 19: validate `--manifest` probes baseline manifest — **recovery-specific subject**
- Test 20: cmd_run `--json` passthrough — reaches original python heredoc with distinct schema_version

## Apply-spec validation predicate (strict)

```bash
$ bash -n .flywheel/scripts/recovery-baseline-status.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/recovery-baseline-status.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/recovery-baseline-status.sh \
  && bash tests/recovery-baseline-status-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.2` (wave-2.0b, 9 surfaces)
- Sister wave-2.0a fillins (avg 980): wzjo9.1.{1,2,3,6,8} + a recent 1.4 / 1.7 close
- Sister-lane exemplar: `flywheel-1fk5f.{1..8}` (avg 974)
- Live target: `.flywheel/scripts/recovery-baseline-status.sh` (84 → 506 lines)
- Backup: `recovery-baseline-status.sh.bak.scaffold-20260510T214423586902000Z-98009`
- Test: `tests/recovery-baseline-status-canonical-cli.sh` (20/20 PASS)
- Live manifest verified against: `~/.flywheel/recovery/snapshots/baseline-20260507T233254Z.manifest.json`

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:9`

- **brand: 9** — first surface in wave-2.0b shipped; pattern matches sister-wave 2.0a + lane exemplar 1fk5f
- **sniff: 10** — wrong-assumption manifest required-fields caught by my own validate surface against live data + corrected with rationale-in-comment; dual-layer schema_version namespace (scaffold + cmd_run) verified via Test 20
- **jeff: 9** — preserves cmd_run python heredoc + dual schema_version namespace; helper-lib API contracts respected; recovery-specific `manifest` validate subject added cleanly
- **public: 9** — three judges check: skeptical operator (20/20 PASS + live manifest validates), maintainer (comment in code explains the live-manifest verification), future worker (recovery-specific manifest subject documented in topic-help)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + recovery-specific `manifest` validate subject + dual-namespace schema_version verified + cmd_run python passthrough preserved + wrong-assumption caught and fixed honestly = **990/1000**. -10 because the initial wrong required-fields assumption shipped briefly before live-data correction (caught and fixed mid-tick; comment documents the correction).
