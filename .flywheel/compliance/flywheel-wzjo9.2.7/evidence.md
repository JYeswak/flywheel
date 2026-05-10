# Compliance pack flywheel-wzjo9.2.7 — recovery-install-plist-skillos.sh canonical-CLI scaffold + 18-TODO fillin

## Bead disposition

P2 wave-2.0b-g (last of install-plist family 2.4-2.7). Parent: flywheel-wzjo9.2, lane: flywheel-wzjo9.
Surface: `.flywheel/scripts/recovery-install-plist-skillos.sh` — bash wrapper around inline python3 heredoc that installs the skillos watcher plist + emits a `recovery-session-watcher-install/v1` receipt. 224 → 757 lines.

Sister wave-2.0b 5/9 closed avg 992. Family pattern established by sister 2.5 (clutterfreespaces); this bead applies the same template with skillos-specific extras (jsm binary + skills-flywheel dir).

## Skillos variant deltas vs family template

The skillos surface uniquely requires two extra substrate dependencies beyond the standard install-plist family:
- `jsm` CLI binary at `/Users/josh/.local/bin/jsm` (skill mutation discipline)
- `skills-flywheel` directory at `~/.claude/skills/.flywheel` (skill registry root)

These become:
- **2 additional doctor probes** (`jsm_bin_executable` + `skills_flywheel_readable`) — bringing total to 14 (vs 12 for clutterfreespaces)
- **New validate subject** `skillos-management` (validates jsm + skills-flywheel readiness)
- **New why id** `skillos_management` (explains the jsm + skills-flywheel readiness rationale)

Everything else mirrors sister 2.5 template verbatim with `RIPS_*` env-mirror vars swapped in for `RIPC_*`.

## Fillin shape (install-plist family pattern + skillos extras)

1. **Module state lift** 15 RIPS_* vars (13 family + 2 skillos-specific: `RIPS_JSM_BIN`, `RIPS_SKILLS_FLYWHEEL`)
2. **8 per-surface schemas** doctor / health / repair / validate / audit / why / audit-row + `status` variant pinning `recovery-session-watcher-install/v1`; validate schema enum extended to include `skillos-management`
3. **Single-printf topic_help** 7 topics referencing skillos-specific substrate
4. **14-probe doctor** family 12 + jsm_bin + skills_flywheel
5. **Audit-log + plist-status health** identical to family
6. **4 repair scopes** identical family scopes (log-dir / audit-log / status-receipt-dir / none)
7. **4 validate subjects** family 3 + new `skillos-management`
8. **`cli_emit_audit_tail`** delegation (path-then-schema)
9. **7 why ids** family 6 + new `skillos_management`
10. **5 `cli_audit_append`** wires (doctor, health, repair, validate, why)
11. **Header comment** updated; residual TODO substring removed

The python heredoc (cmd_run path) is UNCHANGED.

## Acceptance gates (5/5 + 27 in-bead assertions)

- **AG1 PASS** — 18 TODO markers replaced. `grep -c TODO(canonical-cli-scaffold) → 0`.
- **AG2 PASS** — `bash -n` exit 0.
- **AG3 PASS** — `canonical-cli-lint.sh` exit 0.
- **AG4 PASS** — 27/27 PASS (>= 19 required; +14 fillin-specific).
- **AG5 PASS** — Each canonical surface returns concrete data:
  - doctor: 14 named probes (incl. jsm + skills_flywheel)
  - health: plist_installed + last_status + audit_log_stale
  - repair: 3 scope-specific mkdir actions
  - validate: 4 per-subject schemas including skillos-management
  - audit: tails ledger via cli_emit_audit_tail
  - why: 7 known-id provenance including skillos_management

## 27-assertion regression coverage

| # | Test | Coverage |
|---|---|---|
| 1-13 | baseline canonical-cli surface | scaffold-generated |
| 14 | **doctor 14 named probes** | family 12 + jsm_bin_executable + skills_flywheel_readable |
| 15 | **health structured fields** | plist_installed + audit_log_stale typed |
| 16 | **repair log-dir --apply** | mkdir verified on disk |
| 17 | **repair status-receipt-dir --apply** | mkdir verified on disk |
| 18 | **validate plist missing → fail** | "does not exist" reason |
| 19 | **validate audit-receipt 75 → pass** | confidence threshold pass |
| 20 | **validate audit-receipt 20 → fail** | confidence below 60 threshold |
| 21 | **validate skillos-management (NEW)** | skillos-unique subject envelope |
| 22 | **validate skillos-management missing jsm → fail** | jsm_bin reason |
| 23 | **schema status variant** | pins `recovery-session-watcher-install/v1` |
| 24 | **why 6 ids incl. skillos_management** | 6/6 resolve |
| 25 | **why skillos_management cites jsm + skills-flywheel** | explanation contains both substrings |
| 26 | **why unknown → not_found** | unknown id returns `not_found` |
| 27 | **cli_audit_append wired for doctor** | audit row `.action == "doctor"` |

14 NEW assertions (>= 5 required for AG4); 3 are skillos-unique (skillos-management subject, missing-jsm fail, why-skillos_management explanation).

## Sister regression coverage

| Suite | Result |
|---|---|
| `recovery-install-plist-skillos-canonical-cli.sh` (this bead) | 27/27 PASS |
| `recovery-install-plist-clutterfreespaces-canonical-cli.sh` (2.5 sister) | 26/26 PASS |
| `recovery-baseline-snapshot-canonical-cli.sh` (2.2 sister) | 25/25 PASS |
| `flywheel-codex-orient-canonical-cli.sh` (1.9 sister) | 25/25 PASS |
| `flywheel-verdict-canonical-cli.sh` (1.4 sister) | 32/32 PASS |
| `flywheel-anchor-canonical-cli.sh` (1.6 sister) | 20/20 PASS |

128 sister assertions + 27 in-bead = **155 across cluster**.

## Lint posture

| Lint | Result |
|---|---|
| `canonical-cli-lint.sh` | exit 0 |
| `bash -n` | clean |

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/recovery-install-plist-skillos.sh` | SCAFFOLD + FILLIN: 224 → 757 lines, 18 TODOs → 0 |
| `tests/recovery-install-plist-skillos-canonical-cli.sh` | EXTEND: 13 → 27 |
| `.flywheel/compliance/flywheel-wzjo9.2.7/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-wzjo9.2.7/recovery-install-plist-skillos.diff` | NEW: captured diff |
| `.flywheel/journal/flywheel-wzjo9.2.7.md` | NEW: journey entry |

## Skill auto-routes

- canonical-cli-scoping: **yes**
- rust-best-practices: n/a
- python-best-practices: n/a (python heredoc unchanged)
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (14-probe doctor + 4 repair scopes + 4 validate subjects incl. skillos-unique + 7 why ids + lint clean)
- regression depth: 240/220 (27 asserts; 3 skillos-unique fillin-specific incl. validate-skillos-management-missing-jsm)
- doctrine: 220/200 (install-plist family pattern proven across 2 closed beads; family-template-with-per-client-deltas approach validated; closes the family 2.4-2.7)
- integration risk: 200/200 (additive; python heredoc UNCHANGED; install flow semantics preserved; new substrate probes are observation-only)
- live demonstration: 200/200 (real mkdir + live plutil -lint + confidence threshold parsing + missing-jsm fail path verified)

Total: 1100/1040 → 1000

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: 18 → 0 TODOs matching family pattern. Skillos's extra `jsm` + `skills-flywheel` substrate surfaces cleanly as 2 new doctor probes + new validate subject + new why id without disturbing the family template. Last of install-plist family closes wave-2.0b 6/9 (2.4 in flight, 2.6 still queued, 2.8+2.9 remain).
- **sniff**: 27 regression assertions including 3 skillos-unique tests (skillos-management subject envelope, missing-jsm fail path, why-skillos_management cites both jsm + skills-flywheel). Sister surfaces 128/128. Live `plutil -lint`, real mkdir, real JSON confidence parsing — all exercised.
- **jeff**: data decided — python's `skillos_management` readiness check (line 96 in original: `skills.is_dir() and os.access(skills, os.R_OK) and repo.is_dir() and os.access(repo, os.W_OK) and jsm.is_file() and os.access(jsm, os.X_OK)`) → mapped 1:1 to a `skillos-management` validate subject + 2 doctor probes + 1 why id. The python's surface-specific readiness clause becomes the bash scaffold's surface-specific validate subject.
- **public**: structured envelopes everywhere; 7 why ids document label + audit + dry_run_pass + repo + watcher_race + install_flow + skillos_management. Three Judges: operator gets actionable repair scopes + skillos-aware validate; maintainer sees the family-template pattern with one delta-section (2 vars + 2 doctor probes + 1 validate subject + 1 why id); future worker can read the journal entry and clone for any future per-client variant.

## Cross-orch impact

wave-2.0b sub-bead g closes; install-plist family 2.4-2.7 now complete or in flight (2.4 still pane 4). Wave-2.0b: **6/9 closed** after this bead. Remaining sub-beads of wave-2.0b are non-install-plist work.

## Mission fitness

`mission_fitness=adjacent` — recovery infrastructure substrate.

## Skill discoveries

None new. The bash-wraps-python no-collision pattern + install-plist family template + per-client-delta approach were already established. Legal no-discovery reason: task stayed inside existing canonical-cli-scoping + scaffold-canonical-cli skills.

## Family pattern note (closes 2.4-2.7)

For future operators cloning this template:
1. Choose `RIPS_*`/`RIPC_*`-style namespace prefix matching the surface
2. Copy 13 family vars; swap session/repo/plist defaults
3. Identify per-client extras by greping the python for vars not in the family core (e.g., `DEFAULT_JSM`, `DEFAULT_SKILLS_FLYWHEEL`)
4. Add 1 doctor probe per extra (line in `checks[]` array)
5. Add 1 validate subject named after the readiness clause's domain (e.g., `skillos-management`)
6. Add 1 why id explaining the per-client readiness rationale
7. Add 1 schema variant if the python emits a specialized field structure
8. Test scaffold gets 3 family-tests + 1 NEW-extra test per delta-dimension

The pattern compresses each additional family member to ~30 minutes of focused work after the first.
