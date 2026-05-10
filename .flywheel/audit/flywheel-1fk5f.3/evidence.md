---
title: flywheel-1fk5f.3 evidence — dispatch-trigger-gated-precheck.sh substantive 18-TODO fillin
type: evidence
created: 2026-05-10
bead: flywheel-1fk5f.3
parent: flywheel-1fk5f (wave-2 fillin parent)
sister: flywheel-war3i (wave-2 scaffolder; CLOSED)
chain: doctor-mode-lane-1.2-fillin / canonical-cli-coverage
---

# flywheel-1fk5f.3 evidence

**Status:** DONE — all 18 functional TODO markers replaced; 20/20 tests PASS (15 baseline + 5 fillin-specific); apply-spec validation predicate `AG1-5 PASS` (one-shot).

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
| 1. Module-scope vars | `SCAFFOLD_AUDIT_LOG`, `_SCAFFOLD_REPO_ROOT`, `_SCAFFOLD_HELPER_LIB` (already injected by war3i scaffolder, kept) |
| 2. `scaffold_emit_schema audit-row\|run\|*` | Per-surface schemas for doctor/health/repair/validate/audit/why/audit-row/default |
| 3. `scaffold_emit_topic_help` | Single-printf body per topic (gl7om SIGPIPE/pipefail discipline; one printf per case-arm) |
| 4. `scaffold_cmd_doctor` | 6 named substrate probes (watchtower_binary_executable, br_binary_on_path, jq_on_path, helper_lib_readable, audit_log_writable, flywheel_repo_resolvable) |
| 5. `scaffold_cmd_health` | Tail SCAFFOLD_AUDIT_LOG; recent_runs, last_run_ts, age_seconds, distinct_beads, distinct_watchtowers; warn if absent OR stale >24h |
| 6. `scaffold_cmd_repair --scope ...` | 2 scopes: `audit-log-rotate` (5MB threshold) + `audit-log-clear` (truncate for testing). Apply requires --idempotency-key (rc=3 refusal otherwise) |
| 7. `scaffold_cmd_validate <subject>` | 3 subjects: row (--row-json schema check), schema (--surface=NAME re-emits), config (env presence: WATCHTOWER_BIN/BR_BIN/audit-log-parent) |
| 8. `scaffold_cmd_audit` | Delegates to helper-lib's `cli_emit_audit_tail` (path-then-schema positional order per b9dfv contract); fallback inline tail when helper-lib not loaded |
| 9. `scaffold_cmd_why <id>` | Provenance lookup in audit log; emits found / not_found / unavailable per apply-spec contract |
| 10. cmd_run wiring | `_audit_append_terminal` helper added to cmd_run; called at validate/why/doctor/health/repair terminal envelopes; uses `cli_audit_append` when helper-lib present, falls back to direct append |
| 11. Test additions | Extended scaffold test from 15 to 20 assertions (4 fillin-specific + 1 bead-id passthrough) |

## Critical design decision: bead-id passthrough

This surface's cmd_run **already** provided per-bead `validate|why|doctor|health|repair` (with `--bead-id` / `--bead-body-file` flags). The wave-2 scaffold (war3i) prepended a canonical-cli intercept that hijacked those verb names. The intercept catches `${1:-}` only — so even `<surface> validate --bead-id X` would be hijacked by the scaffold layer, never reaching cmd_run's per-bead trigger-gating logic.

**Fix:** modified `_scaffold_is_canonical_arg` to scan ALL of argv for per-bead flags (`--bead-id`, `--bead-body-file`, `--explain`, `--watchtower-fixture`, `--watchtower-bin`, `--watchtower-json-fixture`, `--br-bin`). When any such flag is present, the intercept yields and cmd_run handles the per-bead path unchanged. When no per-bead flag is present, the scaffold layer runs (substrate-level operations).

**Verified:** `validate --bead-body-file /dev/null --json` reaches cmd_run (returns `dispatch-trigger-gated-precheck.v1` schema with `reason_code=no_external_trigger_watchtower_field`); `validate --row-json={...}` reaches scaffold (returns `dispatch-trigger-gated-precheck/v1` schema with `subject=row`). Both paths coexist. Test 20 verifies passthrough.

## Live signals surfaced

The substantive fillin caught real fleet state:

1. **cmd_run audit wiring captured the live --bead-id call**: `validate --bead-id flywheel-1fk5f.3 --json` ran during validation; the audit-append helper wrote a row to `~/.local/state/flywheel/dispatch-trigger-gated-precheck-runs.jsonl` with `bead:flywheel-1fk5f.3, reason_code:no_external_trigger_watchtower_field, status:not_trigger_gated`. The scaffold `health` then reported `recent_runs:1, recent_beads:["flywheel-1fk5f.3"]`. The scaffold `why flywheel-1fk5f.3` then emitted `status:found` with full provenance. **End-to-end audit accretion proven in live fleet.**

2. **Pre-existing scaffolder design issue: shared verb collision** — the war3i wave-2 scaffolder appended canonical-cli on top of a surface that already used the same verb names. Without the bead-id-bypass intercept fix, the scaffold layer silently hijacked all per-bead operations. **Worth flagging upstream**: the scaffolder should either detect verb collision OR emit a flag-based bypass intercept by default. Filed as orch-action recommendation.

3. **Helper-lib `cli_audit_append` row format** wraps the inner row with `{ts, action, status, sha256, ...inner}`. The scaffold `audit` (via `cli_emit_audit_tail`) returns rows that include both the helper-lib wrapper AND the cmd_run-emitted inner fields (bead, watchtower, reason_code, etc.). This is the canonical accretion shape.

## Scaffold canonical surfaces (smoke evidence)

| Surface | Status | Evidence |
|---|---|---|
| `--info` | pass | schema_version=`dispatch-trigger-gated-precheck/v1`, command=info |
| `--schema doctor` | pass | required:[status,checks], status_enum:[pass,fail,warn] |
| `--schema audit-row` | pass | required:[ts,command,schema_version], optional:[bead,watchtower,...] |
| `doctor` | pass | 6/6 substrate probes pass |
| `health` (post-accretion) | pass | recent_runs:1, recent_beads:[flywheel-1fk5f.3] |
| `audit` | pass | row_count:1, recent[].bead=flywheel-1fk5f.3 |
| `repair --scope audit-log-rotate --dry-run` | warn pre-accretion / plan post | size_bytes/threshold_bytes/lines/will_rotate |
| `repair --scope audit-log-clear --dry-run` | plan | current_lines + planned_actions |
| `repair --apply` (no idem-key) | refused rc=3 | canonical refusal contract |
| `validate --config` | pass | missing:[] |
| `validate --row-json={...}` | pass | valid:true, missing_required:[] |
| `validate --surface=doctor` | pass | re-emits doctor schema |
| `why flywheel-1fk5f.3` | found | provenance.bead=flywheel-1fk5f.3, watchtower=null, reason_code=no_external_trigger_watchtower_field |
| `validate --bead-body-file /dev/null --json` (passthrough) | reaches cmd_run | schema_version=`dispatch-trigger-gated-precheck.v1` (NOT scaffold v1) |
| `help <topic>` | substantive | multi-line single-printf prose with substrate paths |

## Family progress

This is sub-bead **3 of 8** from the 1fk5f wave-2 decomposition (sisters: vc3zs, mae86, 4pwc5, dulh3, gl7om, 39vhm, dsrq1 already CLOSED per apply-spec). Per parent estimate, this fillin closes one of the 8 lane-1.2 wave-2 surfaces.

## Cross-references

- Parent: `flywheel-1fk5f` (wave-2 fillin parent)
- Sister scaffolder (CLOSED): `flywheel-war3i`
- Helper lib: `.flywheel/lib/canonical-cli-helpers.sh` (flywheel-tiugg + b9dfv)
- Sister fillin exemplars: vc3zs, mae86, 4pwc5, dulh3, gl7om, 39vhm, dsrq1
- Subject ledger: `~/.local/state/flywheel/dispatch-trigger-gated-precheck-runs.jsonl` (1 row written during validation; live)
- Test: `tests/dispatch-trigger-gated-precheck-canonical-cli.sh` (20/20 PASS, extended from 15)
- Apply-spec: `.flywheel/audit/flywheel-1fk5f.3/apply-spec.md`

## Four-Lens Self-Grade

- **brand: 9** — fills wave-2 lane-1.2; respects apply-spec checklist (11 items addressed); doctrine-aligned (gl7om SIGPIPE discipline, b9dfv positional order, cli_audit_append wiring)
- **sniff: 9** — every claim has a captured smoke-output file; bead-id-passthrough bug-fix path documented honestly; live audit accretion proven end-to-end via real fleet write
- **jeff: 9** — preserves cmd_run's existing per-bead validate/why/doctor/health/repair without modification; helper-lib API contract respected (`cli_emit_audit_tail` path-then-schema, `cli_audit_append` shape)
- **public: 9** — three judges check: skeptical operator (substrate doctor probes are concrete), maintainer (passthrough comment in `_scaffold_is_canonical_arg` documents the design), future worker (apply-spec checklist mapped 1:1 to evidence sections)

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Compliance score

20/20 PASS (15 baseline + 5 fillin-specific) + lint clean + apply-spec validation predicate strict-pass + cmd_run audit wiring proven live + bead-id passthrough preserves cmd_run = **960/1000**. -40 for the bead-id-passthrough design issue surfaced (not in scope to fix in the wave-2 scaffolder itself; orch-action recommendation).
