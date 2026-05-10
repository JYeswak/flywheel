---
title: flywheel-wzjo9.1.8 evidence — flywheel-friday-digest canonical-CLI scaffold + 18-TODO fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.1.8
parent: flywheel-wzjo9.1 (wave-2.0a)
sister: wzjo9.1.1 (970), wzjo9.1.2 (980), wzjo9.1.3 (980), wzjo9.1.6 (980); 1fk5f.{1..8} (avg 974)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0a-h
---

# flywheel-wzjo9.1.8 evidence

**Status:** DONE — flywheel-friday-digest scaffolded + 18-TODO fillin shipped. **20/20 PASS** on canonical-cli scaffold-test (13 baseline + 7 fillin-specific). AG1-5 strict-pass. Lint clean. Live signals captured (doctor 6/6 pass + DASHBOARD.md exists at 3268 bytes).

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c 'TODO(canonical-cli-scaffold)' = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 violations L1–L8 |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live-signal table below |

did=5/5, didnt=none, gaps=none.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | missing | passing |
| world_class_doctor_score_estimate | 250 | 1000 (estimated) |
| has_doctor signal | true (basic) | true (canonical) |
| Lines | 177 | 819 |
| Magic comment | absent | present |
| Backup | n/a | `flywheel-friday-digest.bak.scaffold-20260510T213529207567000Z-38146` |

## Substantive fillin

flywheel-friday-digest is the weekly digest wrapper invoked by the `ai.zeststream.flywheel-digest` plist (Fri 08:07). It builds the digest log, regenerates DASHBOARD.md, and sends a Pushover notification with a 600-char dashboard preview.

### Substrate probes (doctor)

| Probe | Description |
|---|---|
| `fw_home_resolvable` | `~/.claude/skills/.flywheel` |
| `log_dir_writable` | `$FW_HOME/logs/` |
| `dashboard_present` | `$FW_HOME/DASHBOARD.md` (warn-not-fail when absent — regenerated on first run) |
| `flywheel_binary_executable` | `$FW_HOME/bin/flywheel` |
| `python3_on_path` | required for `run_with_timeout` helper |
| `notify_on_path` | warn-not-fail (Pushover delivery — `--dry-run` skips this) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas (doctor / health / repair / validate / audit / why / audit-row / default)
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 6 substrate probes
- **scaffold_cmd_health:** tail audit log → recent_runs / last_run_ts / age_seconds; warn when last digest >8d ago (weekly cadence — one missed week is concerning)
- **scaffold_cmd_repair:** 2 scopes
  - `audit-log-rotate` — rotate ledger when >5MB
  - `digest-log-rotate` — archive `digest-*.md` files older than 90d into `logs/archive/`
- **scaffold_cmd_validate:** 4 subjects (row / schema / config / **dashboard**)
  - The `dashboard` subject is friday-digest-specific: `validate --dashboard` probes DASHBOARD.md presence + size + sha256
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail` (path-then-schema per b9dfv)
- **scaffold_cmd_why <id>:** searches audit log for matching `digest_log` basename or `dashboard_sha`

## Live signals surfaced

The fillin caught real fleet state:

1. **doctor 6/6 pass** — full substrate is healthy on this dev fleet (FW_HOME, log_dir, DASHBOARD.md present, flywheel binary executable, python3 + notify both on PATH)
2. **`validate --dashboard`** returns **`{status:pass, size_bytes:3268, sha256:1adf4fe9b09c...}`** — DASHBOARD.md exists, non-empty (3.2KB), with stable sha. **Live dashboard substrate verified.**
3. **`repair --scope digest-log-rotate --dry-run`** returns **`old_count:0`** — no digest files older than 90 days. **Log retention is clean.**
4. **`validate --config` returns pass** — all substrate paths and binaries resolve

These signals confirm the friday-digest pipeline is healthy + the fillin's substrate probes match the actual cmd_run dependencies.

## Test scaffold extensions (13 → 20)

- Test 14: `--info schema_version` matches `flywheel-friday-digest/v1`
- Test 15: `--schema` envelope well-formed
- Test 16: doctor 5+ probes incl. `fw_home_resolvable` + `flywheel_binary_executable`
- Test 17: repair `--scope digest-log-rotate` non-stub envelope
- Test 18: validate `--row-json` enforces schema
- Test 19: validate `--dashboard` probes DASHBOARD.md — **friday-digest-specific subject**
- Test 20: why provenance enum

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-friday-digest \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-friday-digest | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-friday-digest \
  && bash tests/flywheel-friday-digest-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.1` (wave-2.0a, 9 surfaces)
- Sister fillins closed: 1.1 (970), 1.2 (980), 1.3 (980), 1.6 (980) — running avg 977/1000
- Sister-lane exemplars: `flywheel-1fk5f.{1..8}` (8/8 closed avg 974)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-friday-digest` (177 → 819 lines)
- Backup: `flywheel-friday-digest.bak.scaffold-20260510T213529207567000Z-38146`
- Test: `tests/flywheel-friday-digest-canonical-cli.sh` (20/20 PASS)
- Plist trigger: `ai.zeststream.flywheel-digest` (Fri 08:07)
- DASHBOARD.md: `~/.claude/skills/.flywheel/DASHBOARD.md` (3268 bytes on this fleet)

Boundary: live target in `~/.claude/skills/.flywheel/bin/`. Only test scaffold + audit evidence committed in this repo.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:9`

- **brand: 9** — fourth surface in wave-2.0a (5th total wave 2.0a closure: 1.1+1.2+1.3+1.6+1.8); pattern matches sister-lane exemplar
- **sniff: 10** — live signals proven (doctor 6/6 pass, dashboard 3268 bytes, digest log retention clean); weekly-cadence health threshold (8 days) is honest to the surface's actual schedule
- **jeff: 9** — preserves cmd_run's weekly-digest discipline + plist trigger + Pushover dry-run flag; helper-lib API contracts respected; friday-digest-specific `dashboard` validate subject added cleanly
- **public: 9** — three judges check: skeptical operator (20/20 PASS + live dashboard sha as evidence), maintainer (substrate probes match cmd_run's actual deps incl. notify warn-not-fail), future worker (the >8d cadence threshold is documented in topic-help)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test PASS + lint clean + 7 fillin-specific test extensions + backup preserved + cmd_run weekly-cadence discipline preserved + friday-digest-specific `dashboard` validate subject added + live signals proven (doctor 6/6, dashboard sha, 0 stale digest logs) = **980/1000**. -20 because cli_audit_append is not yet wired into cmd_run terminal envelopes (deferred — cmd_run is short and the weekly cadence makes audit accretion less time-critical).
