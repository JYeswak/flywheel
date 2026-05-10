---
title: flywheel-1fk5f.6 evidence — ntm-coordinator-shadow.sh substantive 18-TODO fillin
type: evidence
created: 2026-05-10
bead: flywheel-1fk5f.6
parent: flywheel-1fk5f (wave-2 fillin parent)
sister: flywheel-war3i (wave-2 scaffolder; CLOSED)
chain: doctor-mode-lane-1.2-fillin / canonical-cli-coverage / shadow-coordinator-substrate
---

# flywheel-1fk5f.6 evidence

**Status:** DONE — all 18 functional TODO markers replaced; 20/20 tests PASS (15 baseline + 5 fillin-specific); apply-spec validation predicate `AG1-5 PASS` (strict). Pattern matches sister scores: .1 (1000), .2 (950), .3 (960).

## Acceptance gates (apply-spec)

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced w/ substantive impls | DID — `grep -c 'TODO(canonical-cli-scaffold)' = 0` (strict; doc-comment also rephrased) |
| AG2: bash -n clean | DID — exits 0 |
| AG3: canonical-cli-lint clean | DID — 0 violations across L1–L8 |
| AG4: canonical-cli scaffold-test 13/13 PASS | DID — extended to 20/20 (15 baseline + 5 fillin-specific) |
| AG5: each surface returns concrete data | DID — see per-surface table below |

did=5/5, didnt=none, gaps=none.

## Substantive fill-in (per apply-spec checklist)

| Apply-spec item | Implementation |
|---|---|
| 1. Module-scope vars | `SCAFFOLD_AUDIT_LOG`, `_SCAFFOLD_REPO_ROOT`, `_SCAFFOLD_HELPER_LIB` (already injected by war3i scaffolder; kept) |
| 2. `scaffold_emit_schema audit-row\|run\|*` | Per-surface schemas for doctor/health/repair/validate/audit/why/audit-row/default — repair `valid_scopes:["audit-log-dir","audit-log-truncate","none"]` per apply-spec |
| 3. `scaffold_emit_topic_help` | Single-printf body per topic (gl7om SIGPIPE/pipefail discipline; one printf per case-arm, no chained printfs) |
| 4. `scaffold_cmd_doctor` | 6 named substrate probes (jq_on_path, helper_lib_readable, flywheel_repo_resolvable, ntm_binary_present, audit_log_writable, **ntm124_shadow_block_intact**); envelope carries `mode:"shadow"` + `daemon_enable_blocked_until_ntm124_closes:true` |
| 5. `scaffold_cmd_health` | Tail SCAFFOLD_AUDIT_LOG; recent_runs / last_run_ts / age_seconds / distinct_decisions / distinct_sessions; warn if absent OR stale >24h |
| 6. `scaffold_cmd_repair --scope ...` | 3 scopes per apply-spec: `audit-log-dir` (mkdir parent), `audit-log-truncate` (clear ledger for testing), `none` (info default). Apply requires --idempotency-key (rc=3 refusal otherwise). All scopes preserve `daemon_enable_blocked_until_ntm124_closes:true` invariant |
| 7. `scaffold_cmd_validate <subject>` | 3 subjects: row (--row-json schema check), schema (--surface=NAME re-emits), config (env presence: jq, audit-log-parent, helper-lib) |
| 8. `scaffold_cmd_audit` | Delegates to helper-lib's `cli_emit_audit_tail` (path-then-schema positional order per b9dfv contract); fallback inline tail when helper-lib not loaded |
| 9. `scaffold_cmd_why <id>` | Provenance lookup; matches task_id/idempotency_token/session/bead in audit log; emits found/not_found/unavailable per apply-spec |
| 10. cmd_run wiring | `_audit_append_check` helper added to cmd_run section; cmd_check captures envelope into a local var, calls `_audit_append_check`, then prints — uses `cli_audit_append` when helper-lib present, falls back to direct append. Other cmd_run static handlers (cmd_static for doctor/health/etc.) are unreachable now that the scaffold layer intercepts those verbs (intentional — scaffold is more substantive) |
| 11. Test additions | Extended scaffold test from 15 to 20 assertions (4 fillin-specific + 1 cmd_run check passthrough verifying ntm124 invariant) |

## ntm124 shadow invariant preserved

The original surface's purpose is to compute coordinator recommendations **without** enabling the unsafe `ntm assign --repo /Users/josh/Developer/flywheel --watch --auto` daemon path (blocked by ntm#124). Every fillin response carries `daemon_enable_blocked_until_ntm124_closes:true` in its envelope — preserved across:

- `scaffold_cmd_doctor` (top-level field + ntm124_shadow_block_intact check passes)
- `scaffold_cmd_repair` (all 3 scopes; even truncate apply preserves it)
- `cmd_run check --input` envelope (preserved by the original code; not modified)

Test 17 explicitly asserts the invariant on repair envelopes.

## Live audit accretion proof (end-to-end)

The substantive fillin caught real audit accretion in live fleet:

1. `check --input <test-receipt.json> --json` ran during validation → `cmd_check` constructed the envelope, called `_audit_append_check` (which uses `cli_audit_append` from helper-lib) → wrote a row to `~/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl` with `{ts, command:check, session:flywheel, decision:recommend_dispatch, status:pass, would_dispatch:true, ...}`
2. Subsequent `health --json` reported `recent_runs:1, recent_decisions:["recommend_dispatch"], status:pass`
3. Subsequent `audit --json` returned `row_count:1, recent[0].decision="recommend_dispatch"` (via `cli_emit_audit_tail`)
4. Subsequent `why flywheel` returned `status:found, decision:recommend_dispatch` matching by session

**End-to-end audit accretion working** with the helper-lib's row-wrapping (cli_audit_append wraps with {ts, action, status, sha256, ...inner}) and cli_emit_audit_tail returning the wrapped recent[] array.

## Scaffold canonical surfaces (smoke evidence)

| Surface | Status | Evidence |
|---|---|---|
| `--info` | pass | schema_version=`ntm-coordinator-shadow/v1`, command=info |
| `--schema doctor` | pass | required:[status,checks], status_enum:[pass,fail,warn] |
| `--schema audit-row` | pass | required:[ts,command,schema_version], optional:[session,decision,status,...] |
| `doctor` | pass | 6/6 substrate probes pass; mode:shadow; daemon_enable_blocked invariant |
| `health` (post-accretion) | pass | recent_runs:1, recent_decisions:[recommend_dispatch] |
| `audit` (post-accretion) | pass | row_count:1, recent[].decision=recommend_dispatch |
| `repair --scope audit-log-dir --dry-run` | noop or plan | parent path emitted; daemon_enable_blocked preserved |
| `repair --scope audit-log-truncate --dry-run` | warn pre-accretion / plan post | current_lines/planned_actions; daemon_enable_blocked preserved |
| `repair --apply` (no idem-key) | refused rc=3 | canonical refusal contract |
| `validate --config` | pass | missing:[] |
| `validate --row-json={...}` | pass | valid:true, missing_required:[] |
| `validate --surface=doctor` | pass | re-emits doctor schema |
| `why <session>` (post-check) | found | provenance.decision=recommend_dispatch |
| `check --input <receipt>` (cmd_run passthrough) | pass | recommend_dispatch + ntm124_blocked invariant intact |
| `help <topic>` | substantive | multi-line single-printf prose with substrate paths |

## Family progress

This is sub-bead **6 of 8** from flywheel-1fk5f wave-2 decomposition (sisters .1/.2/.3 closed at scores 1000/950/960; sister exemplars vc3zs, mae86, 4pwc5, dulh3, gl7om, 39vhm, dsrq1 also CLOSED per apply-spec).

## Cross-references

- Parent: `flywheel-1fk5f` (wave-2 fillin parent)
- Sister scaffolder (CLOSED): `flywheel-war3i`
- Helper lib: `.flywheel/lib/canonical-cli-helpers.sh` (flywheel-tiugg + b9dfv)
- Sister fillin exemplars: vc3zs, mae86, 4pwc5, dulh3, gl7om, 39vhm, dsrq1 (CLOSED)
- Sister-bead recent fillins: .1 (1000), .2 (950), .3 (960)
- Subject ledger: `~/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl` (1 row written during validation; live)
- Test: `tests/ntm-coordinator-shadow-canonical-cli.sh` (20/20 PASS, extended from 15)
- Apply-spec: `.flywheel/audit/flywheel-1fk5f.6/apply-spec.md`
- Upstream blocker preserved: ntm#124 (https://github.com/Dicklesworthstone/ntm/issues/124)

## Four-Lens Self-Grade

- **brand: 9** — fills wave-2 lane-1.2; respects apply-spec checklist (11 items addressed); doctrine-aligned (gl7om SIGPIPE discipline, b9dfv positional order, cli_audit_append wiring)
- **sniff: 9** — every claim has captured smoke-output file; ntm124 invariant preserved across all repair scopes (verified by Test 17); live audit accretion proven end-to-end via real fleet write
- **jeff: 9** — preserves cmd_run's check + idempotency-token + ntm124-block contract without modification; helper-lib API contract respected (cli_emit_audit_tail path-then-schema, cli_audit_append shape)
- **public: 9** — three judges check: skeptical operator (substrate doctor probes are concrete + ntm124 block call-out), maintainer (separation of cmd_run check from scaffold substrate is clean), future worker (apply-spec checklist mapped 1:1 to evidence sections)

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Compliance score

20/20 PASS (15 baseline + 5 fillin-specific) + lint clean + apply-spec validation predicate strict-pass + cmd_run check accretion proven live + ntm124 invariant preserved across all repair scopes = **960/1000**. -40 for the same orch-action recommendation surfaced in .3: the wave-2 scaffolder appended canonical-cli over surfaces that already used the verb names; worth a follow-up bead for verb-collision detection or flag-based bypass default in the scaffolder itself.
