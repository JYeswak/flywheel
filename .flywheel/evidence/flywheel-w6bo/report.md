# flywheel-w6bo — Worker Report

**Task:** [ntm-callback] flywheel pane1 send reports sent but callback token not verifiable
**Bug origin:** flywheel-8ehk closeout 2026-05-07 — first `ntm send` to flywheel pane 1 returned "Sent to pane 1" but token was not verifiable in `ntm history` and a resend hit `ntm send "not in a mode"` for pane %1
**Identity:** MagentaPond (codex-pane on flywheel:1, executed via claude wrapper)
**Repo head:** 7e90c9b (master)
**Status:** done
**Mission fitness:** infrastructure — closes the canonical recovery gap for stuck DONE callbacks so `callback_delivery_verified=true` becomes a reliable signal across copy-mode/visual-mode pane states.

## Verdict

Two cooperating surfaces now form the canonical recovery path:

1. `verify-callback-delivery.sh` (bumped `worker-callback-delivery.v2 → v3`) — captures `ntm send` stderr, classifies `not in a mode` / `pane is in copy mode` as a new `pane_not_in_input_mode` failure class, and **spools** the unsent callback body to `~/.local/state/flywheel/callback-spool/<session>/<task-id>.json` (schema `callback-spool/v1`).
2. `callback-spool-reap.sh` (new, `callback-spool-reap.v1`) — canonical reaper with full canonical-CLI surface (`doctor`, `validate`, `audit`, `schema`, `--info`, `--examples`, `--dry-run` / `--apply`, `--json`). It iterates pending entries, retries `ntm send`, archives on success, and on `attempts >= max_attempts` writes a persisted-failure artifact AND appends a `callback_spool_persisted_failure` row to `dispatch-log.jsonl` so the orchestrator can observe stuck callbacks via the same channel it already polls.

## Acceptance gate coverage

| Bead acceptance gate | Status | Evidence |
|---|---|---|
| **AG1** The artifact, command, or doctrine surface named in `[ntm-callback] flywheel pane1 send reports sent but callback token not verifiable` is updated with close evidence | DID | `verify-callback-delivery.sh` updated v2→v3 with `pane_not_in_input_mode` classifier + spool writer; new canonical reaper at `.flywheel/scripts/callback-spool-reap.sh` |
| **AG2** A targeted test, dry-run, or validator command passes and is named in the close receipt | DID | `tests/verify-callback-delivery.sh` extended with copy_mode case + spool-file assertions, all passing; `tests/callback-spool-reap.sh` (new) covers 14 scenarios — all PASS; `bash -n` clean on both scripts |
| **AG3** `br show flywheel-w6bo` remains open or in_progress until the evidence artifact exists | DID | bead state was OPEN at dispatch start; this report at canonical evidence path was written BEFORE the `br close` (per L120) |

did=3/3, didnt=none, gaps=none.

## Files changed

- `~ .flywheel/scripts/verify-callback-delivery.sh` — version bumped v2→v3; added `--spool-dir` flag, `write_spool()` helper, stderr capture on send, `pane_not_in_input_mode` classifier, `spool_path` JSON output field, updated `--schema` and `--info` to surface the new fields
- `+ .flywheel/scripts/callback-spool-reap.sh` — new canonical reaper (~190 lines, well under the 500-line shell threshold from canonical-cli-scoping)
- `~ tests/verify-callback-delivery.sh` — added `copy_mode` MODE case to fake ntm + new test asserting `pane_not_in_input_mode` failure class + valid spool-file schema
- `+ tests/callback-spool-reap.sh` — 14 assertions covering doctor, dry-run, apply happy-path, retry-pending, persisted-failure, validate, audit, schema, info
- `+ .flywheel/evidence/flywheel-w6bo/report.md` — this file

## Validation

```bash
# both edited shell scripts pass syntax check
bash -n .flywheel/scripts/verify-callback-delivery.sh && echo verify-syntax-ok
bash -n .flywheel/scripts/callback-spool-reap.sh && echo reap-syntax-ok

# extended verify-callback test (now covers pane_not_in_input_mode + spool write)
bash tests/verify-callback-delivery.sh
# → "verify-callback-delivery tests passed"

# new spool-reap test suite — 14 assertions
bash tests/callback-spool-reap.sh
# → 14 PASS lines + "callback-spool-reap tests passed"

# live canonical-CLI surfaces
.flywheel/scripts/callback-spool-reap.sh doctor --json | jq -c '{status, spool_dir_exists, pending, archived}'
# → {"status":"pass","spool_dir_exists":false,"pending":0,"archived":0}

.flywheel/scripts/callback-spool-reap.sh schema | jq -c '.schema_version, .required_fields'
# → "callback-spool/v1" with required_fields including task_id, session, message, failure_class

.flywheel/scripts/callback-spool-reap.sh --info | jq -c '.name, .version'
# → "callback-spool-reap.sh", "callback-spool-reap.v1"

.flywheel/scripts/verify-callback-delivery.sh --schema | jq -c '.fields'
# → ["status","callback_delivery_verified","attempts","failure_class","verify_method","failed_path","spool_path"]
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/callback-spool-reap.sh 2>&1 | tail -1` expects literal `callback-spool-reap tests passed`.

## How this closes the bug

Original failure trace (from bead body):
1. First `ntm send flywheel --pane=1 ...` → reported "Sent to pane 1" (exit 0)
2. Robot-tail grep on `ntm history` → token not found (the chevron prompt was queued but pane never submitted)
3. Resend → hit `ntm send "not in a mode" for pane %1`
4. File-based retry → same `not in a mode` error

The v3 chain handles each step:

| Step | Old behavior | New behavior |
|---|---|---|
| 1 send returns 0 but token missing | `callback_not_observed` (correct, unchanged) | unchanged |
| 2 resend / pane in copy-mode | exit 1 with class `ntm_send_failed` (loses signal) | classifies stderr → `pane_not_in_input_mode`; writes spool entry with full message body |
| 3 orch polls dispatch-log for callbacks | no spool integration | reaper picks up spool, retries; on success archives; on persistent failure appends `callback_spool_persisted_failure` row to `dispatch-log.jsonl` (which `auto-refill-decision-log.sh` already polls) |
| 4 worker loses callback | callback dropped | callback persisted in spool with full envelope; recoverable across worker restarts |

## canonical-cli-scoping compliance (callback-spool-reap.sh)

| Gate | Surface |
|---|---|
| doctor / health / repair triad | `doctor` subcommand emits `{status, spool_dir_exists, pending, archived, total}` schema |
| validate / audit / why subsidiary triad | `validate` and `audit` subcommands present; `why` n/a (no per-callback rationale needed beyond `failure_class`) |
| `--json`, schema output, stable exit codes | `--json` flag + `schema` subcommand returning `{schema_version:"callback-spool/v1", required_fields:[...]}` |
| `--dry-run` / `--apply` mutation discipline | both flags supported; default mode is `apply` (canonical for periodic reapers per launchd-cron pattern); `--dry-run` returns `would_retry` outcomes without mutation; verified by test `PASS dry-run leaves spool intact` |
| file-length threshold respected | 191 lines of shell — well under the 500-line shell threshold |

## Three-Q

- **VALIDATED:** 14 spool-reap assertions + 5 verify-callback assertions all PASS; `bash -n` clean on both scripts; live `doctor`/`schema`/`--info` surfaces emit valid JSON.
- **DOCUMENTED:** updated `--schema` output now includes `spool_path` field; new reaper has `--info`, `--examples`, `--help`, `schema` topic surfaces; this evidence file at canonical path documents the canonical recovery path.
- **SURFACED:** persistent failures are visible to the orchestrator via the existing `dispatch-log.jsonl` channel (which `auto-refill-decision-log.sh:243-244` already polls); no new orch-side wiring required.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** minimal-surface — extends an existing v2 script to v3 (additive, not breaking) and adds one new reaper. No churn beyond what the bug requires. Versioned schema (`callback-spool/v1`).
- **Sniff (9/10):** every behavior change has a deterministic test fixture (fake `ntm` with `MODE=copy_mode`); all 19 assertions across the two suites pass; failure-class enumeration is complete (4 classes: `ntm_send_failed`, `pane_not_in_input_mode`, `pane_disappeared`, `callback_not_observed`).
- **Jeff (9/10):** cites operational primitives — `ntm send`, `jq`, `tmpfile`, atomic `mv`, JSONL ledger appends. Versioned receipts (`callback-spool/v1`, `callback-spool-reap.v1`, `worker-callback-delivery.v3`). Reaper integrates with the existing `dispatch-log.jsonl` channel already used by `auto-refill-decision-log.sh` — no new orch-side substrate to maintain.
- **Public (9/10):** **Three Judges publishability bar** (`publishability-bar/v1`):
  - **Skeptical operator:** drops a synthetic spool entry, runs `callback-spool-reap.sh --dry-run --json`, sees `would_retry`; runs `--apply`, sees `reaped` and the entry archived. Reproducible deterministic test fixture covers it.
  - **Maintainer:** the recovery contract is named (`callback-spool/v1`) and documented in both scripts' `--info` and `--schema`. `--max-attempts` is parameterized (default 5). The `dispatch-log.jsonl` integration uses an existing channel, no new contracts to learn.
  - **Future worker:** if a pane goes into copy-mode mid-callback, the worker's `verify-callback-delivery.sh` writes the full envelope to spool and exits with a distinct failure class. The orchestrator (or a launchd cron of the reaper) picks it up later. No callback bodies are silently lost.

`publishability_bar_version=publishability-bar/v1`. `worker_callback_delivery_version=worker-callback-delivery.v3`. `callback_spool_reap_version=callback-spool-reap.v1`. `callback_spool_schema=callback-spool/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — new `callback-spool-reap.sh` ships full canonical-CLI surfaces (doctor, validate, audit, schema, --info, --examples, --help, --dry-run/--apply, --json, stable exit codes via `set -u` + explicit case branching). Verified by `PASS schema endpoint` and `PASS info endpoint` assertions. File length (191 lines) under the 500-line shell threshold.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README; this is canonical evidence.

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits the canonical bug-fix-with-recovery-spool pattern (precedent: `auto-refill-decision-log.sh` uses the same `dispatch-log.jsonl` integration channel; this work extends that pattern to a new failure class). No new convergent_evolution / meta_rule / trauma_class signal surfaced.

## L61 ecosystem-touch

- `agents_md_updated=no` — this is a substrate fix, not a doctrine landing. The recovery contract is documented inline in script `--info` and this evidence file.
- `readme_updated=no` — same.
- `no_touch_reason=substrate_fix_with_inline_documentation_no_l-rule_or_doctrine_change`

## Compliance Pack

Score: 920/1000.

- 3/3 acceptance gates DID
- 14 + 5 = 19 test assertions PASS, 0 FAIL
- 4/4 lenses with 9/10 self-grades
- Three Judges block explicit
- Versioned receipts cited (`callback-spool/v1`, `callback-spool-reap.v1`, `worker-callback-delivery.v3`)
- L107 reservations acquired/released for all 5 touched paths
- canonical-cli-scoping verified `yes` with multiple PASS test assertions

Pack path: `.flywheel/evidence/flywheel-w6bo/`.

## Cross-references

- Triggering bead: `flywheel-8ehk` (closed 2026-05-07; reported the failure modes addressed here)
- Existing orchestrator integration point: `.flywheel/scripts/auto-refill-decision-log.sh:243-244` (already polls `dispatch-log.jsonl` for `callback_reaped` events; persisted-failure rows now flow through the same channel)
- Sibling test pattern: `tests/test_hot_pane_refill_after_callback_reap.sh` (consumes `callback_reaped` events from dispatch-log)
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt, applied), L52 (issues-to-beads receipt — see skill_discoveries=0 reason)
