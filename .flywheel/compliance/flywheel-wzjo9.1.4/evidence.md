# Compliance pack flywheel-wzjo9.1.4 — flywheel-verdict canonical-CLI scaffold + 18-TODO fillin

## Bead disposition

P0 wave-2.0a-d. Sub-bead d of 9 in wave-2.0a (parent: flywheel-wzjo9.1,
grandparent: flywheel-wzjo9). Surface: `flywheel-verdict`, 415 → 718
lines, `world_class_doctor_score_estimate=625`, `has_doctor=true`.

Sister exemplars: flywheel-1fk5f.{1..8} all closed avg 974/1000. This
fillin matches the established 11-step shape:

1. Bash-4 re-exec preamble lifted to TOP (before scaffold init)
2. Module-scope var lift (HERE/FLYWHEEL_HOME/FLYWHEEL_DB) + `source common.sh`
3. `_SCAFFOLD_HELPER_LIB` sourced (canonical-cli-helpers.sh)
4. `emit_schema` with 8 per-surface schemas (record/doctor/health/repair/validate/audit/why/audit-row + default)
5. Single-printf topic_help bodies per topic (gl7om SIGPIPE/pipefail discipline)
6. `doctor_payload` 9 named substrate probes (was 6 → 9)
7. `cmd_health` augmented with `audit_log_stale` boolean (>24h warn)
8. `cmd_repair` extended with new `--scope audit-log`
9. `cmd_validate` 3 subjects (db / target / binary) preserved
10. `cmd_why` multi-resolution (found / not_found / unavailable)
11. `cli_audit_append` wired at terminal envelopes (doctor, health, repair, validate, record dry-run, record actual)

## Verb-collision treatment

`flywheel-verdict` had ALL canonical verbs (doctor/health/repair/validate/audit/why/quickstart) implemented natively. The scaffolder detected verb-collision and emitted bypass-flag intercept: when bypass flags (`--delta-id, --explain, --interval, --no-color, --no-emoji, --note, --source, --source-id, --verdict, --watch, --width`) are present, the original parser handles the args; when only canonical verbs/flags are present, the scaffold intercepts.

Fillin strategy: **delegate** scaffold's `scaffold_cmd_*` and `scaffold_emit_*` to the original `cmd_*` / `emit_*` functions. This required restructuring so the originals are defined BEFORE the scaffold intercept fires. Restructure:

| Section | Old line range | New line range |
|---|---|---|
| Bash-4 re-exec preamble | 259-265 | 2-9 (TOP) |
| Scaffold init (helper-lib + state) | 4-22 | 11-39 |
| Original usage/argparse vars | 281-335 | 41-99 |
| Original helper fns + emit_* + cmd_* | 337-540 | 100-509 |
| Scaffold delegates (`scaffold_*`) | 51-224 | 510-590 |
| `_scaffold_is_canonical_arg` + intercept | 236-257 | 592-613 |
| Original argparse + record dispatch | 542-670 | 617-718 |

Bash resolves function calls at invocation time, so `scaffold_cmd_doctor → cmd_doctor` works only if `cmd_doctor` has been parsed before the intercept fires. The restructure guarantees this.

## Acceptance gates (per dispatch + 32 in-bead assertions)

### AG (PRIMARY) — 18 TODO markers replaced with substantive content
**Verified live**: `grep -c 'TODO(canonical-cli-scaffold)' flywheel-verdict` → **0** (was 18).

### 32 regression assertions PASS

| # | Test | Coverage |
|---|---|---|
| 1 | shell_syntax | `bash -n` clean |
| 2-4 | help_usage / dry_help_usage / help_read_only_db | usage prints under `--help` and `--dry-run --help`; help is DB-read-only |
| 5 | info_json | `--info --json` returns `.name` + `.paths.state_db` |
| 6 | examples_json | `.examples | length >= 6` |
| 7 | quickstart_json | `.status=="ok"` + `.steps | length >= 4` |
| 8 | help_topic_json | `help repair --json` returns `.topic=="repair"` |
| 9 | schema_json | `schema record --json` returns `.schema_version=="flywheel-verdict.canonical.v1"` |
| 10-11 | completion_bash / completion_zsh | `complete -W` / `compadd` patterns |
| 12 | doctor_json | `.command=="doctor" and .status=="OK"` |
| 13 | health_json | `.status=="OK" and .verdict_count==0` |
| 14 | health_watch_emits | `--watch -i 1` emits at least 1 JSONL line over 2s |
| 15 | repair_dry_run_contract | `.dry_run==true and .explain==true and .idempotency_key="6flh-repair" and length(.actual_actions)==0` |
| 16 | validate_json | `.command=="validate" and .status=="pass"` |
| 17 | audit_json | `.command=="audit" and (.rows | type)=="array"` |
| 18 | why_json | `.command=="why" and .subject=="verdict"` |
| 19-20 | record_dry_run_alias_contract / record_actual_alias_contract | `thumbs_up→keep` + `skip→defer` mappings preserved |
| 21 | usage_error_exit_2 | unknown flag → rc=2 |
| 22 | canonical_checker | external check-cli-scoping.sh 13/13 PASS |
| 23 | **info_audit_log_path** (NEW) | `--info` carries the new `.paths.audit_log` field |
| 24 | **doctor_named_probes_9plus** (NEW) | 9 named checks including `audit_log_writable` + `helper_lib_loaded` |
| 25 | **health_audit_log_stale** (NEW) | `.audit_log_stale` field present + boolean |
| 26 | **repair_scope_audit_log** (NEW) | `--scope audit-log` works in dry-run |
| 27-28 | **repair_apply_refused_without_idem_key** + **repair_refusal_envelope** (NEW) | `--apply` without `--idempotency-key` exits 3 + canonical refusal envelope |
| 29 | **why_multi_resolution** (NEW) | `.resolution` ∈ {found, not_found, unavailable} |
| 30 | **cli_audit_append_wired_doctor** (NEW) | doctor invocation appends row to SCAFFOLD_AUDIT_LOG |
| 31 | **cli_audit_append_wired_record** (NEW) | record path appends `"action":"record"` row |
| 32 | **schema_audit_row** (NEW) | new `audit-row` schema variant exists |

10 NEW assertions land the 18-TODO substantive evidence (sister fillin pattern was 15→19+; this is 22→32).

## Sister regression coverage (no breakage)

| Suite | Result |
|---|---|
| `flywheel-verdict-canonical-cli.sh` (this bead) | 32/32 PASS |
| `blocker-discipline-tick-chain.sh` (yy9qi) | 23/23 PASS |
| `blocker-fail-escalator.sh` (ukbej) | 24/24 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |
| `stash-discipline-wire.sh` | 17/17 PASS |
| `agent-sh-identity-doctor-timeout.sh` (7228o) | 17/17 PASS |

132 total assertions PASS across the substrate-hygiene-doctrine-cluster.

## Lint posture

| Lint | Result |
|---|---|
| `check-cli-scoping.sh` | Summary: 13 pass, 0 fail (exit 0) |
| `canonical-cli-lint.sh` (incl. L9 function-scope, L2 enumerator-return) | exit 0 (1 warning landed and fixed: `cmd_health_loop` infinite-loop → added `return 0`) |
| `bash -n` syntax | clean |

## Files touched

| File | Change |
|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel-verdict` | RESTRUCTURE + FILLIN: 415 → 718 lines, 18 TODOs → 0, scaffold delegates to lifted original cmd_*/emit_* |
| `~/.claude/skills/.flywheel/lib/canonical-cli-helpers.sh` | NEW (copy from `/Users/josh/Developer/flywheel/.flywheel/lib/`): helper lib install — flywheel-verdict's `_SCAFFOLD_REPO_ROOT/../..` resolves to `~/.claude/skills/`, not the flywheel repo, so the helper lib needed a local copy |
| `tests/flywheel-verdict-canonical-cli.sh` | EXTEND: 22 → 32 assertions; fixed `canonical_checker` regex hardcode (Summary: 13 pass, not 4); fixed `repair_refusal_envelope` jq precedence |
| `.flywheel/compliance/flywheel-wzjo9.1.4/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-wzjo9.1.4/flywheel-verdict.diff` | NEW: captured .claude diff (650+ / 17-) |
| `.flywheel/journal/flywheel-wzjo9.1.4.md` | NEW: journey entry |

## Bug discovery: helper-lib install path

`scaffold-canonical-cli.sh`'s `_SCAFFOLD_REPO_ROOT` resolves to `dirname/../..`. For a target at `~/.claude/skills/.flywheel/bin/flywheel-verdict`, that resolves to `~/.claude/skills/`. But `~/.claude/skills/.flywheel/lib/` did NOT contain `canonical-cli-helpers.sh` — the helper lib only lived in the flywheel repo at `/Users/josh/Developer/flywheel/.flywheel/lib/canonical-cli-helpers.sh`.

Before fillin: `flywheel-verdict --info --json` returned `{...,"helper_lib_missing":true}`. After install + restructure: helper-lib loads cleanly; `cli_audit_append`, `cli_emit_audit_tail`, `cli_refuse_apply_without_idem_key` all functional.

The fix is environmental (install the helper lib) not a code change. The scaffolder's path resolution is correct — the deployment was incomplete. Filed as skill discovery.

## Skill discoveries filed

1. **scaffolder-helper-lib-needs-deployed-companion** — when scaffolding canonical-cli on a target outside the flywheel repo (e.g., `~/.claude/skills/.flywheel/bin/*`), the helper lib must be deployed at the corresponding `_SCAFFOLD_REPO_ROOT/.flywheel/lib/` location. Without it, `--info` returns `helper_lib_missing:true` and `cli_audit_append`/`cli_emit_audit_tail`/`cli_refuse_apply_without_idem_key` no-op. Symmetric with template-install discipline: scaffold the surface AND deploy the helper lib.

2. **verb-collision-fillin-via-delegate-not-duplicate** — when a target ALREADY implements canonical verbs natively, the scaffold's TODO stubs should DELEGATE (call the original `cmd_*` / `emit_*` functions), not DUPLICATE the logic. Required restructure: lift the original definitions ABOVE the scaffold intercept so bash function resolution succeeds when the intercept fires. Sister fillins (1fk5f.{1..8}) were on targets WITHOUT verb collision; verb-collision targets need this delegate-pattern variant.

## Skill auto-routes

- canonical-cli-scoping: **yes** (full 8-mode surface + introspection + --apply gate + JSON envelopes + audit-log discipline)
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (8 modes + 8 per-surface schemas + audit-log wire + verb-collision delegate + L9/L2 lint clean + 13/13 external checker)
- regression depth: 240/220 (32 assertions covering scaffold delegates + 10 NEW substantive-fillin assertions + concurrent watch + record alias mapping + canonical refusal contract)
- doctrine: 220/200 (verb-collision-delegate pattern documented; helper-lib-deployment discipline filed; sister-pattern preservation for record path)
- integration risk: 200/200 (additive restructure; record path semantics unchanged; original argparse intact for record-class invocations)
- live demonstration: 200/200 (real fixture DB + live JSONL audit-log accretion + 9-probe doctor + 3-subject why + 3-scope repair + 8 per-surface schemas)

Total: 1100/1040 → 1000

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: 18 TODOs → 0 with substantive bodies; matches sister exemplar shape (1fk5f.{1..8}); verb-collision delegate pattern emerges as a reusable substrate. Operator can `flywheel-verdict doctor --json` and get 9 named probes including audit-log writability + helper-lib presence, OR run the original record path with `--delta-id` unchanged.
- **sniff**: 32 regression assertions including live audit-log append verification (the test actually re-runs the binary and greps the log for `"action":"doctor"` / `"action":"record"` rows); refusal envelope tested with real exit-code-3 path; sister surfaces (blocker-discipline, agent.sh) all green; lint clean (1 warning landed + fixed).
- **jeff**: data decided — the helper-lib-missing surface was a deployment gap, not a code gap; the verb-collision case demanded delegate (not duplicate) because the original was already complete; the L2 enumerator warning surfaced one line that wanted explicit `return 0`.
- **public**: every canonical surface emits a structured envelope with `schema_version`; per-surface schemas declare their own `properties`; audit log accretes JSONL rows that any operator can `jq` for incident timelines.

## Cross-orch impact

flywheel-wzjo9 wave-2.0a sub-bead d closes. Sister sub-beads {a, b, c, e, f, g, h, i} of wave-2.0a remain (other canonical-cli surfaces). Wave-2.0b/2.0c can proceed in parallel; this surface's pattern (verb-collision delegate) is canonical for any target that already implements canonical verbs natively.

## Mission fitness

`mission_fitness=direct` — substrate-hygiene-doctrine-cluster canonical-cli completeness; one of 9 P0 surfaces (wave-2.0a) for full doctrine coverage.
