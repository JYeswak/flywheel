---
bead: flywheel-5ke66.2
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash
sister_exemplars: vuc9c (985), d80zq (985), ugjvq (985), 64hud (985), x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Evidence Pack — flywheel-5ke66.2

## Scope

Wave-2-general-2 (2nd of 21 5ke66 sub-beads; FIRST wave-2 surface — wave-2
covers P0 missing × general lane, sister to wave-1's domain-specific lanes).
Apply canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/append-safe-write.sh` — stdin-payload append primitive
with EOF-lease + tail-divergence retry semantics.

## Files touched

`.flywheel/scripts/append-safe-write.sh` (200 → 446 lines after scaffold; TODO=0)
`tests/append-safe-write-canonical-cli.sh` (94 → 156 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/append-safe-write.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/append-safe-write.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/append-safe-write.sh \
  && bash tests/append-safe-write-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Domain-specific fillins

### doctor (6 named probes — primitive surface focus)

- `bash`, `jq` — universal
- `mktemp_available` — load-bearing detail: required for stdin-payload
  capture (`append-safe-write.stdin.XXXXXX` prefix in cmd_run)
- `python3_available` — **load-bearing**: detail flags lock/lease/append
  heredoc dependency (the entire append+EOF-lease+retry primitive logic
  is in the python3 heredoc)
- `scratch_dir_writable` — `$TMPDIR` (default `/tmp`)
- `audit_log_dir_writable` — `~/.local/state/flywheel`

### health

Reads `$SCAFFOLD_AUDIT_LOG`; status=warn at >7d stale (on-demand
primitive; weekly grace; tunable via
APPEND_SAFE_WRITE_HEALTH_STALE_THRESHOLD_SECONDS).

### repair (2 scopes, apply contract)

- `scratch_dir` → `mkdir -p $TMPDIR` (stdin-payload mktemp target)
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- `--apply` requires `--idempotency-key` (rc=3 refusal)
- Unknown scope rc=64 + `unknown_scope`

### validate (3 subjects, domain-precise)

- `target-path` — must be **absolute path** (starts with `/`); rejects
  relative paths with `not_absolute_path` reason. This matches the
  python heredoc's `Path(args.target).expanduser().resolve(strict=False)`
  behavior which would silently normalize relative paths against CWD —
  pre-validating absolute is a safety contract for callers
- `lease-ms` — integer in `[1, 60000]` matching the `--lease-ms` arg's
  default (300) and reasonable max (60s); rejects out-of-range or
  non-integer with `out_of_range_or_not_integer` reason
- `audit-row` — JSONL `ts` + `action` standard

### audit / why

audit uses `cli_emit_audit_tail`. why scans 4 keys
(ts/target/idempotency_key/run_id) — `idempotency_key` is the canonical
audit key for this surface (matches the script's --idempotency-key arg
that drives idempotent_skip status).

## Test extension (13 → 19, calibrated)

- Test 7 calibrated to `--scope scratch_dir`
- Test 9 calibrated to bare `validate` rc=64 + `missing_subject`
- 6 fillin assertions: doctor python3 detail-annotation check (verifies
  the lock/lease/append note is present), target-path accept absolute,
  target-path reject relative (rc=1), lease-ms accept default 300,
  lease-ms reject 99999 out-of-range (rc=1), **backward-compat run-mode**
  verifying cmd_run still appends payload + emits status=ok

## Notable

- Test 19 is the load-bearing fidelity check — pipes a payload to
  `--target` and verifies (a) status=ok with bytes_appended>0 in JSON
  output AND (b) the payload actually landed in the file. This catches
  scaffolder regressions that could break the script's primary purpose.
- target-path validate enforces absolute-path because the script does
  `.resolve(strict=False)` which normalizes relative paths against CWD;
  pre-validating absolute is safer for callers driving via dispatch
  packets where CWD is unpredictable.
- lease-ms range `[1, 60000]` reflects sensible bounds: 1ms minimum
  (lease must take some time), 60s maximum (anything longer is likely a
  bug — the script's default is 300ms).

## Smoke captures

17 smoke captures verify domain-specific responses (target-path
rejection cites contract, lease-ms rejection lists valid_range,
out-of-range and not-integer both fall under same reason, repair
refusals cite reason, audit/why work against missing log).

## Mission fitness

Class: **adjacent** (per dispatch). append-safe-write.sh is the
canonical EOF-lease + tail-divergence-retry append primitive used
by other surfaces; canonical-CLI surface lets the orchestrator validate
target paths + lease values before triggering append calls in dispatch
packets.
