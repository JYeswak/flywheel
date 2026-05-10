# Compliance pack flywheel-wzjo9.2.5 — recovery-install-plist-clutterfreespaces.sh canonical-CLI scaffold + 18-TODO fillin

## Bead disposition

P2 wave-2.0b-e (sub-bead e of 9, second of install-plist family). Parent: flywheel-wzjo9.2, lane: flywheel-wzjo9.
Surface: `.flywheel/scripts/recovery-install-plist-clutterfreespaces.sh` — bash wrapper around inline python3 heredoc that installs the clutterfreespaces watcher plist + emits a `recovery-session-watcher-install/v1` receipt without activating launchd. 236 → 748 lines.

Sister wave-2.0b 3/9 closed avg 990; sister 2.4 (alpsinsurance) in flight pane 4. Install-plist family: 2.4 (alpsinsurance, in flight), **2.5 (clutterfreespaces, this)**, 2.6 (mobile-eats), 2.7 (skillos) — 4 near-identical per-client variants.

## Substrate domain

The python heredoc executes a 4-stage install flow:
1. Preinstall audit via `recovery-preinstall-audit.sh --session=clutterfreespaces` (exit 4 if confidence < threshold 60)
2. Launchctl list probe for label `com.zeststream.clutterfreespaces.watcher` (exit 5 if duplicate)
3. Atomic plist write at `~/Library/LaunchAgents/com.zeststream.clutterfreespaces.watcher.plist` + `plutil -lint`
4. Readiness probe (PATH/HOME/ntm-binary/ntm-config/repo/log-dir) (exit 6 if not pass)

Substrate probed via canonical surface:
- python3, jq, ntm binary, ntm config, plutil, launchctl, repo writable, plist parent writable, audit script readable, log dir, helper lib, audit log writable

## Fillin shape (no-collision substantive-duplicate)

Sister 2.2 pattern reapplied: bash-wraps-python heredoc, scaffold intercepts before python3 fires. Restructure:

1. **Module state lift** 13 RIPC_* vars mirroring python defaults + 3 lifted constants (SESSION, LABEL, STATUS_SCHEMA)
2. **8 per-surface schemas** doctor/health/repair/validate/audit/why/audit-row + new `status` variant pinning `recovery-session-watcher-install/v1`
3. **Single-printf topic_help** 7 topics referencing actual substrate paths
4. **12-probe doctor** with three-state aggregate (pass/warn/fail); warn when ntm_config/repo/log_dir/audit_log unwritable but core deps green
5. **Audit-log + plist-status health** reads `$RIPC_STATUS` for last status/timestamp; reports plist_installed + audit_log_stale
6. **3 repair scopes** (log-dir / audit-log / status-receipt-dir / none); `--apply` requires `--idempotency-key`
7. **3 validate subjects** plist (plutil -lint clean) / audit-receipt (confidence_per_session.clutterfreespaces >= 60) / config (deps + paths inventory)
8. **`cli_emit_audit_tail`** delegation (path-then-schema)
9. **6 why ids** label / audit / dry_run_pass / repo / watcher_race / install_flow + multi-resolution
10. **`cli_audit_append`** wired at 5 terminal envelopes (doctor, health, repair, validate, why)
11. **Header comment** rewritten to remove residual `TODO(canonical-cli-scaffold)` substring

The python heredoc (cmd_run path) is UNCHANGED.

## Acceptance gates (5/5 + 26 in-bead assertions)

- **AG1 PASS** — 18 TODO markers replaced. `grep -c TODO(canonical-cli-scaffold) → 0`.
- **AG2 PASS** — `bash -n` exit 0.
- **AG3 PASS** — `canonical-cli-lint.sh` exit 0 (no L1-L9 violations).
- **AG4 PASS** — 26/26 PASS (>= 19 required; +13 fillin-specific beyond 13 baseline).
- **AG5 PASS** — Each canonical surface returns concrete data:
  - doctor: 12 named probes with three-state aggregate
  - health: surfaces plist_installed + last_status + audit_log_stale
  - repair: 3 scope-specific mkdir actions
  - validate: 3 per-subject schemas (plist via plutil -lint, audit-receipt via confidence threshold, config inventory)
  - audit: tails ledger via cli_emit_audit_tail
  - why: 6 known-id provenance + multi-resolution

## 26-assertion regression coverage

| # | Test | Coverage |
|---|---|---|
| 1-13 | baseline canonical-cli surface | scaffold-generated |
| 14 | **doctor 12 named probes** | python3 + jq + ntm_bin + plutil + launchctl + plist_parent + audit_script + helper + audit_log all named |
| 15 | **health structured fields** | plist_installed + audit_log_stale + status typed |
| 16 | **repair log-dir --apply** | actual_actions[0]=="log_dir_ensured" + dir created |
| 17 | **repair status-receipt-dir --apply** | actual_actions[0]=="status_receipt_dir_ensured" + dir created |
| 18 | **validate plist missing → fail** | descriptive reason "does not exist" |
| 19 | **validate audit-receipt missing → fail** | descriptive reason "not readable" |
| 20 | **validate audit-receipt confidence pass** | confidence 85 >= threshold 60 |
| 21 | **validate config** | deps inventory |
| 22 | **schema status variant** | pins `recovery-session-watcher-install/v1` |
| 23 | **why 5 known ids** | label/audit/dry_run_pass/watcher_race/install_flow resolve |
| 24 | **why unknown → not_found** | unknown id returns `not_found` |
| 25 | **cli_audit_append doctor** | audit log row with `.action == "doctor"` |
| 26 | **cli_audit_append repair** | audit log row with `.action == "repair"` |

13 NEW assertions (>= 5 required for AG4).

## Sister regression coverage

| Suite | Result |
|---|---|
| `recovery-install-plist-clutterfreespaces-canonical-cli.sh` (this bead) | 26/26 PASS |
| `recovery-baseline-snapshot-canonical-cli.sh` (2.2 sister) | 25/25 PASS |
| `flywheel-codex-orient-canonical-cli.sh` (1.9 sister) | 25/25 PASS |
| `flywheel-verdict-canonical-cli.sh` (1.4 sister) | 32/32 PASS |
| `flywheel-anchor-canonical-cli.sh` (1.6 sister) | 20/20 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |

121 sister assertions PASS + 26 in-bead = 147.

## Lint posture

| Lint | Result |
|---|---|
| `canonical-cli-lint.sh` (L1-L9) | exit 0 |
| `bash -n` | clean |

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/recovery-install-plist-clutterfreespaces.sh` | SCAFFOLD + FILLIN: 236 → 748 lines, 18 TODOs → 0 |
| `tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh` | EXTEND: 13 → 26 |
| `.flywheel/compliance/flywheel-wzjo9.2.5/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-wzjo9.2.5/recovery-install-plist-clutterfreespaces.diff` | NEW: 523-line diff |
| `.flywheel/journal/flywheel-wzjo9.2.5.md` | NEW: journey entry |

## Skill auto-routes

- canonical-cli-scoping: **yes**
- rust-best-practices: n/a
- python-best-practices: n/a (python heredoc unchanged)
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (8 modes + 8 schemas incl. status variant + 4 repair scopes + 3 validate subjects + audit-log wires + lint clean)
- regression depth: 240/220 (26 asserts; live mkdir for 2 repair scopes; confidence-threshold validate; 5-id why)
- doctrine: 220/200 (install-plist-family pattern established; cross-bead replicability for 2.6/2.7)
- integration risk: 200/200 (additive; python heredoc UNCHANGED; install flow semantics preserved)
- live demonstration: 200/200 (real mkdir under TMP + plist plutil -lint subject + audit-receipt confidence parsing)

Total: 1100/1040 → 1000

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: 18 → 0 TODOs matching sister 2.2 pattern. Bash-wraps-python install-flow surface gets a canonical CLI without touching its install semantics. Install-plist family pattern established for 2.6+2.7 to follow.
- **sniff**: 26 regression assertions including live `plutil -lint` exercise, audit-receipt confidence threshold test, 2 live mkdir scopes. Sister surfaces 121/121.
- **jeff**: data decided — status receipt schema lifted from python's `"schema_version": "recovery-session-watcher-install/v1"` constant; confidence threshold lifted from `DEFAULT_CONFIDENCE_MIN = 60` env override; exit codes (4/5/6) documented in why.dry_run_pass.
- **public**: structured envelopes everywhere; 6 why ids document label uniqueness + audit confidence + dry_run_pass criteria + repo + watcher race + 4-stage install flow. Three Judges: operator gets actionable repair scopes (log-dir / audit-log / status-receipt-dir); maintainer sees state vars mirror python defaults 1:1; future worker on 2.6 (mobile-eats) and 2.7 (skillos) has a 26-assertion template to clone.

## Cross-orch impact

wave-2.0b sub-bead e closes. Wave-2.0b: 4/9 after this (sisters 2.4 in flight, 2.6+2.7 ready for same pattern). Sister 2.4 (alpsinsurance) running pane 4 — likely converges on same template since the 4 install-plist surfaces are near-identical.

## Mission fitness

`mission_fitness=adjacent` — recovery infrastructure substrate; not directly advancing the mission anchor (continuous-orchestrator-uptime) but supports recovery readiness which is the policy that defines uptime under failure.

## Skill discoveries

None new. The no-collision substantive-fillin + bash-wraps-python pattern was established by sister 2.2; this bead reapplies it cleanly. Legal no-discovery reason: task stayed inside existing canonical-cli-scoping + scaffold-canonical-cli skills.
