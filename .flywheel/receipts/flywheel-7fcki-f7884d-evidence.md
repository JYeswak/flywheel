# flywheel-7fcki-f7884d evidence

## Scope

Bead: `flywheel-7fcki`
Task: `[ntm-wire-in] rewrite idle-pane-auto-dispatch.sh -> ntm wait+assign --watch`

## Result

- Rewrote `.flywheel/scripts/idle-pane-auto-dispatch.sh` from the live 697-line bespoke dispatcher to a 230-line native NTM wrapper.
- Actual live LOC delta: `697 -> 230` (`-467`).
- The wrapper now delegates idle detection to `ntm wait <session> --until=idle --any --timeout=<duration> --json`.
- The wrapper delegates assignment to `ntm assign <session> --repo <path> --dry-run|--auto --json`.
- Watch mode delegates to `ntm assign <session> --watch --stop-when-done --watch-interval=<duration>`.
- Default remains dry-run.
- Native `ntm#124` dependency is closed per `br show flywheel-xyyfg`, but the wrapper still refuses `--watch` when `FLYWHEEL_NTM_124_STATUS=open`.

## Focused tests

Passed:

```bash
bash -n .flywheel/scripts/idle-pane-auto-dispatch.sh \
  tests/idle-pane-auto-dispatch-validated-write-test.sh \
  tests/idle-pane-auto-dispatch-closed-guard-test.sh \
  tests/idle-pane-auto-dispatch-work-started-validation-test.sh
```

Passed:

```bash
bash tests/idle-pane-auto-dispatch-validated-write-test.sh
bash tests/idle-pane-auto-dispatch-closed-guard-test.sh
bash tests/idle-pane-auto-dispatch-work-started-validation-test.sh
```

Passed:

```bash
shellcheck .flywheel/scripts/idle-pane-auto-dispatch.sh \
  tests/idle-pane-auto-dispatch-validated-write-test.sh \
  tests/idle-pane-auto-dispatch-closed-guard-test.sh \
  tests/idle-pane-auto-dispatch-work-started-validation-test.sh
```

Passed:

```bash
.flywheel/scripts/idle-pane-auto-dispatch.sh --session flywheel --repo "$PWD" --dry-run --json \
  | jq -e '.schema_version == "idle-pane-auto-dispatch/v2" and (.status | type == "string") and .dry_run == true'
```

## Gap filed

Filed `flywheel-72z43`: `ntm wait --json timeout emits human text`.

Reason: live `ntm wait flywheel --until=idle --any --timeout=1s --json` returned colored human timeout output instead of JSON. The wrapper handles this by storing raw output inside its JSON receipt, but the native contract gap needs a separate upstream follow-up.

## Canonical CLI checklist

- doctor/health/repair: not applicable; this is a thin wrapper, not a self-healing CLI.
- validate/audit/why: not applicable; verification is via wrapper tests and native command smoke.
- `--json`, schema output, stable exit-code behavior: addressed through `--json`, `--schema`, and status strings.
- `--dry-run` / `--apply`: addressed; dry-run is default, mutation only passes through `ntm assign --auto`.
- file length threshold: addressed; shell script is under 500 lines.

## Four-Lens Self-Grade

- brand: 8
- sniff: 8
- jeff: 8
- public: 8

Three Judges check: skeptical operator sees native NTM delegation, maintainer sees bounded wrapper behavior and tests, future worker sees the remaining native JSON gap in `flywheel-72z43`.
