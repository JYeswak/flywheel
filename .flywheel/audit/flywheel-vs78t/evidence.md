---
bead: flywheel-vs78t
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash
sister_exemplars: lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Evidence Pack — flywheel-vs78t

## Scope

Wave-1-bash-8 (8th of 17 ok1sk sub-beads). Apply canonical-cli scaffold +
substantive fillin to `.flywheel/scripts/verify-watcher-launchd-active.sh` —
the script that verifies per-session launchd watcher daemons (codex-stuck-
detector, coordinator daemon, per-session detectors for mobile-eats,
skillos, alpsinsurance, vrtx) are loaded + active under DOMAIN gui/$(id -u).

## File touched

`.flywheel/scripts/verify-watcher-launchd-active.sh` (174 → 484 lines)
`tests/verify-watcher-launchd-active-canonical-cli.sh` (94 → 142 lines)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/verify-watcher-launchd-active.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/verify-watcher-launchd-active.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/verify-watcher-launchd-active.sh \
  && bash tests/verify-watcher-launchd-active-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Domain-specific fillins

### doctor (7 named probes — domain-tailored)

- `bash_available`, `jq_available`, `mktemp_available` — universal
- `launchctl_available` — **load-bearing** for launchd daemon verification
  (this script's entire reason-for-being is invoking `launchctl print
  $DOMAIN/$LABEL`; if launchctl is missing, all per-spec checks fail)
- `detector_executable` — `.flywheel/scripts/codex-template-stuck-detector.sh`
  is the daemon program that the launchd plists invoke; verifies the
  symlink/binary the watcher daemon spec depends on
- `pattern_test_executable` — `.flywheel/tests/test-detector-pattern-bank-replay.sh`
  is invoked downstream by the verifier to replay detector pattern bank
  for cross-check
- `audit_log_dir_writable` — `~/.local/state/flywheel` is the write target
  for the verify-watcher-launchd-active-runs.jsonl audit log

### health

Reads `$SCAFFOLD_AUDIT_LOG` (default
`~/.local/state/flywheel/verify-watcher-launchd-active-runs.jsonl`) and
emits last_run_ts, age_seconds, recent_runs (last 20), total_runs.
Status flips to `warn` at >24h stale (threshold env-tunable via
`VERIFY_WATCHER_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes, apply contract)

- `state_dir` → `mkdir -p ~/.local/state/flywheel`
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- `--apply` requires `--idempotency-key` (rc=3 refusal)
- Unknown scope returns rc=64 with `unknown_scope` reason

### validate (3 subjects, domain-precise)

- `launchd-label` regex `^ai\.zeststream\.[a-z0-9-]+$` — matches all 6
  DEFAULT_SPECS labels (codex-stuck-detector-watchdog, flywheel-coordinator-
  daemon, mobile-eats-/skillos-/alps-/vrtx-codex-stuck-detector); rejects
  `com.apple.launchd.*` and similar non-canonical labels
- `session-name` regex `^[a-z0-9-]+$` — matches the session column of
  DEFAULT_SPECS (flywheel, mobile-eats, skillos, alpsinsurance, vrtx);
  rejects uppercase
- `audit-row` — JSONL `ts` + `action` required (canonical fleet pattern)

### audit / why

audit uses `cli_emit_audit_tail` (canonical positional path-then-schema-then-
limit signature). why scans against ts / launchd_label / session / run_id
keys and emits found / not_found / unavailable states.

## Test extension (13 → 19, calibrated)

- Test 7 calibrated to use real `--scope state_dir` (was `none` which is
  now an unknown-scope rc=64 refusal under the actual repair contract)
- Test 9 calibrated to test bare `validate` returning rc=64 +
  `missing_subject` envelope (per `feedback_calibrate_test_to_actual_contract`
  META-RULE 2026-05-09)
- 6 fillin assertions added: launchctl_available probe presence,
  launchd-label accept canonical, launchd-label reject non-canonical (rc=1),
  session-name accept lowercase-hyphen, session-name reject uppercase
  (rc=1), repair unknown_scope rc=64 + canonical envelope

## Smoke captures

All 13 smoke captures in this dir verify that domain-specific responses
are sensible (label rejections cite pattern, repair refusals cite reason,
audit/why work against missing log).

## Mission fitness

Class: **direct**. Wave-1 sub-bead from ok1sk decomposition; canonical-cli
scaffold + fillin on a launchd-verification primitive that the codex-stuck-
detector substrate depends on. Rolls up to ok1sk (jloib wave-1 doctrine
adoption).
