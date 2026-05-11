---
bead: flywheel-5ke66.13
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-NO-BYPASS
sister_exemplars: 5ke66.2 (985, same NO-BYPASS variant)
---

# Evidence Pack — flywheel-5ke66.13

## Scope

Wave-2-general-13 (13th of 21 5ke66 sub-beads). Apply canonical-cli scaffold
+ substantive fillin to `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh`
— bash wrapper that runs `$MOBILE_EATS_PRODUCT_TICK` + mirrors receipt via
`$MOBILE_EATS_RECEIPT_BRIDGE`; appends per-event row to `$MOBILE_EATS_RECEIPT_MIRROR_LOG`
via `fw_jsonl_append_validated`. Surface is **NO-BYPASS** (sister to 5ke66.2).

## Files touched

`.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh` (56 → 302 lines
after scaffold; TODO=0)
`tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh` (94 → 158
lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh \
  && bash tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Variant choice — NO-BYPASS

Per-flag baseline probe pre-scaffold confirmed the script has NO native
canonical surfaces:
- `--info` / `--schema` / `--examples` / `doctor` all just trigger the
  default `cmd_run` path which tries to invoke `$PRODUCT_TICK` + `$BRIDGE`
  (and emits WARN messages when the JSONL log dir is misconfigured)

So scaffold owns ALL canonical surfaces. The script's primary purpose
(running mobile-eats loop + bridging the receipt) is preserved on bare
invocation — `cmd_run` fires when no canonical args present.

## Domain-specific fillins

### doctor (9 named probes — most-instrumented surface this session)

- `bash`, `jq`, `mktemp` — universal
- `product_tick_executable` — **load-bearing** primary action target
  (`$MOBILE_EATS_PRODUCT_TICK` default `~/.local/bin/mobile-eats-flywheel-loop-tick`)
- `bridge_executable` — **load-bearing** receipt mirror
  (`$MOBILE_EATS_RECEIPT_BRIDGE` default
  `<repo>/.flywheel/scripts/mobile-eats-receipt-bridge.sh`)
- `jsonl_append_lib_sourceable` — `$FLYWHEEL_JSONL_APPEND_LIB`; warn-tier
  matching the script's own `append_jsonl_best_effort` semantics
  (warns on missing, doesn't fail)
- `out_dir_writable` — `$MOBILE_EATS_LOOP_OUT_DIR` for
  `last_tick_mobile-eats.json` write
- `log_dir_writable` — dirname of `$MOBILE_EATS_RECEIPT_MIRROR_LOG`
- `audit_log_dir_writable`

### health

2h stale threshold (frequent loop cadence; tunable via
`MOBILE_EATS_LOOP_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (3 scopes — DUAL-STATE + EVENT-LOG pattern)

This surface is the first to need 3 distinct repair scopes because it
manages BOTH a production state dir (out_dir) AND a separate event-log
dir (log_dir) AND the canonical audit log dir. Pattern:

- `out_dir` → `mkdir -p $MOBILE_EATS_LOOP_OUT_DIR` (last-tick JSON target)
- `log_dir` → `mkdir -p $(dirname $MOBILE_EATS_RECEIPT_MIRROR_LOG)`
  (event log JSONL target)
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects, domain-precise)

- `receipt-event` **enum-typed** restricted to `{receipt_mirrored,
  receipt_mirror_failed}` — these are the LOAD-BEARING events the
  script emits in its `row="$(jq -nc ... '{event:...}'`)" calls
- `exit-code` integer in `[0, 255]` (POSIX exit code range)
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/event/path/run_id matching the per-event row schema).

## Test extension (13 → 19)

- Test 7 calibrated to `--scope out_dir`
- Test 9 calibrated to bare `validate` rc=64 + `missing_subject`
- 6 fillin assertions:
  - Test 14: doctor probes product_tick + bridge + jsonl_append_lib (load-bearing triple)
  - Test 15: receipt-event full-enum sweep (both events)
  - Test 16: receipt-event reject unknown
  - Test 17: exit-code accepts boundary values (0 AND 255)
  - Test 18: exit-code rejects 256 out-of-range
  - Test 19: **3-scope structural assertion** — repair MUST list exactly
    `audit_log_dir,log_dir,out_dir` (sorted) — codifies the dual-state-+-
    event-log pattern as a structural test that catches future regressions
    where someone removes one of the three scopes

## Notable

- Test 19 is a NEW canonical pattern for surfaces with multi-dir state:
  structurally assert the EXACT scope-list (sorted-string equality)
  rather than just checking for presence of one scope. Catches both
  scope-add regressions AND scope-remove regressions.
- This is the most-instrumented doctor of the wave-2 sequence (9 probes
  vs 5-7 typical) because the surface coordinates 3 external programs
  ($PRODUCT_TICK / $BRIDGE / $JSONL_APPEND_LIB) plus 3 directories.
- `jsonl_append_lib_sourceable` is intentionally warn-tier (not fail)
  because the script itself uses `append_jsonl_best_effort` which
  warns-and-continues if the lib is missing — doctor mirrors that
  best-effort semantic.

## Smoke captures

17 smoke captures verify all canonical surfaces (doctor/health/3 repair
scopes/2 validate subjects accept+reject/audit/why/quickstart/info/schema).

## Mission fitness

Class: **adjacent** (per dispatch). mobile-eats-loop-with-receipt-mirror.sh
is the mobile-eats integration loop wrapper that mirrors product receipts
into the flywheel-loop state dir; canonical-CLI surface lets the
orchestrator probe substrate (product_tick + bridge + jsonl_append_lib)
and validate event names + exit codes in dispatch packets.
