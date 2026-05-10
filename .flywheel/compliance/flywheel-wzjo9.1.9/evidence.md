# Compliance pack flywheel-wzjo9.1.9 — flywheel-codex-orient canonical-CLI scaffold + 18-TODO fillin

## Bead disposition

P2 wave-2.0a-i (sub-bead i of 9 in wave-2.0a). Parent: flywheel-wzjo9.1, lane: flywheel-wzjo9.
Surface: `flywheel-codex-orient` — Codex SessionStart parity reader. 95 → 585 lines.
`canonical_cli_scoping_status=missing → passing`, `has_doctor=false → true`,
`world_class_doctor_score_estimate=0 → 8-probe doctor`.

Sister exemplars (5 closed): 1.1 (970), 1.2 (980), 1.3 (980), 1.4 (1000), 1.6 (980); avg 982/1000.

## Substrate domain

The surface is non-mutating by design: it reads `$CODEX_CURRENT_DELTAS` (default `~/.codex/CURRENT-DELTAS.md`), refreshes once via `$SNAPSHOT_BIN` if stale (>`$STALE_SECONDS`, default 21600 = 6h), and falls back to live deltas from `$FW` if refresh fails.

Substrate dependencies surfaced through doctor:
- `flywheel_home` — `~/.claude/skills/.flywheel`
- `fw_binary` — `$FLYWHEEL_HOME/bin/flywheel`
- `snapshot_bin` — `$FLYWHEEL_HOME/bin/flywheel-codex-snapshot`
- `snapshot_file` — `~/.codex/CURRENT-DELTAS.md`
- `stale_seconds_config` — positive int env override
- `dependency:jq`
- `helper_lib_loaded` — `canonical-cli-helpers.sh`
- `audit_log_writable` — `~/.local/state/flywheel/flywheel-codex-orient-runs.jsonl`

## Fillin shape (11-step sister-pattern, no-collision variant)

1. **Module-scope state lifted** above scaffold so doctor/health/validate can read `FLYWHEEL_HOME / FW / SNAPSHOT_BIN / OUT / STALE_SECONDS`
2. **Strict mode** `set -euo pipefail` (was `set -u; set -o pipefail`) — passes L5 lint
3. **`scaffold_emit_schema`** 8 per-surface schemas (doctor / health / repair / validate / audit / why / audit-row + default)
4. **`scaffold_emit_topic_help`** single-printf bodies per topic (gl7om SIGPIPE/pipefail discipline)
5. **`scaffold_cmd_doctor`** 8 named substrate probes, aggregate `pass | warn | fail` (warn when audit_log_writable or snapshot_file missing but core deps green)
6. **`scaffold_cmd_health`** audit-log tail, `snapshot_age_seconds`, `recent_runs`, `last_run_ts`, `audit_log_stale` (>24h)
7. **`scaffold_cmd_repair`** 3 scopes (`snapshot`, `audit-log`, `none`); `--apply` requires `--idempotency-key` per canonical refusal contract
8. **`scaffold_cmd_validate`** 3 subjects (`snapshot`, `binaries`, `config`) + info-shape when no subject
9. **`scaffold_cmd_audit`** delegates to `cli_emit_audit_tail` (path-then-schema positional order)
10. **`scaffold_cmd_why`** 3 known ids (`stale`, `snapshot`, `refresh`) with multi-resolution (found / not_found / unavailable)
11. **`cli_audit_append`** wired at 6 terminal envelopes: doctor, health, repair, validate, why, and the original cmd_run path (4 outcomes: fresh / refreshed / live_fallback / no_binary)

## Acceptance gates (5/5 per apply-spec + 25 in-bead assertions)

- **AG1 PASS** — 18 TODO markers replaced with substantive (non-stub) implementations. `grep -c 'TODO(canonical-cli-scaffold)' → 0`.
- **AG2 PASS** — `bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-codex-orient` exits 0.
- **AG3 PASS** — `canonical-cli-lint.sh` exits 0 (no L1-L8 violations). One L5 warning surfaced during fillin (strict-mode missing) and was fixed.
- **AG4 PASS** — `tests/flywheel-codex-orient-canonical-cli.sh` SUMMARY pass=25 fail=0 (N=25 >= 13 required; +12 fillin-specific assertions beyond baseline).
- **AG5 PASS** — Each canonical surface returns concrete data (not "todo"):
  - doctor: 8 named probes, status `pass|warn|fail`, snapshot_age_seconds populated
  - health: binds to audit log, reports `recent_runs + last_run_ts + audit_log_stale + snapshot_age_seconds`
  - repair: 3 scope-specific actions (snapshot=`refresh_snapshot`, audit-log=`mkdir -p`, none=no-op)
  - validate: 3 enforces per-subject schemas with descriptive `.reason`
  - audit: tails ledger via `cli_emit_audit_tail`
  - why: 3 known-id provenance + not_found for unknowns

## 25-assertion regression coverage

| # | Test | Coverage |
|---|---|---|
| 1 | syntax | `bash -n` clean |
| 2 | --info envelope | `.command == "info"` + `.schema_version` |
| 3 | --schema envelope | `.command == "schema"` |
| 4 | --examples envelope | `.command == "examples"` |
| 5 | doctor envelope | `.command == "doctor"` |
| 6 | health envelope | `.command == "health"` |
| 7 | repair --dry-run envelope | `.command == "repair" and .mode == "dry_run"` |
| 8 | repair --apply refused without --idempotency-key | rc=3 (canonical refusal contract) |
| 9 | validate envelope | `.command == "validate"` (info shape when no subject) |
| 10 | audit envelope | `.command == "audit"` |
| 11 | why <id> envelope | `.command == "why"` |
| 12 | help <topic> | topic header text present |
| 13 | quickstart envelope | `.command == "quickstart"` |
| 14 | **doctor 8+ named probes** (NEW) | flywheel_home / fw_binary / snapshot_bin / snapshot_file / stale_seconds_config / audit_log_writable all present |
| 15 | **health structured fields** (NEW) | snapshot_age_seconds + recent_runs + audit_log_stale all typed |
| 16 | **repair --scope snapshot --dry-run** (NEW) | planned_actions array + actual_actions length 0 |
| 17 | **repair --scope audit-log --apply** (NEW) | `actual_actions[0] == "audit_log_dir_ensured"` |
| 18 | **validate snapshot subject** (NEW) | `.subject == "snapshot"` + status pass/fail |
| 19 | **validate binaries subject** (NEW) | `.subject == "binaries"` + descriptive reason |
| 20 | **validate config subject** (NEW) | `.subject == "config"` + descriptive reason |
| 21 | **schema audit-row variant** (NEW) | `.command == "audit-row"` + required array |
| 22 | **why multi-resolution** (NEW) | 2+ of 3 known ids (stale/snapshot/refresh) resolve to found/unavailable |
| 23 | **why not_found for unknown** (NEW) | resolution == "not_found" for unknown id |
| 24 | **cli_audit_append wired for doctor** (NEW) | audit log row with `.action == "doctor"` after doctor invocation |
| 25 | **cli_audit_append wired for run path** (NEW) | audit log contains `"action":"run"` after default invocation |

12 NEW assertions (>= 5 required for AG4 substantive-fillin evidence).

## Sister regression coverage (no breakage)

| Suite | Result |
|---|---|
| `flywheel-codex-orient-canonical-cli.sh` (this bead) | 25/25 PASS |
| `flywheel-anchor-canonical-cli.sh` (1.6 sister) | 20/20 PASS |
| `flywheel-verdict-canonical-cli.sh` (1.4 sister) | 32/32 PASS |
| `blocker-discipline-tick-chain.sh` (yy9qi) | 23/23 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |
| `stash-discipline-wire.sh` | 17/17 PASS |
| `agent-sh-identity-doctor-timeout.sh` (7228o) | 17/17 PASS |

128 total sister assertions PASS + 25 in-bead = 153 across the wave-2.0a-i + companion clusters.

## Lint posture

| Lint | Result |
|---|---|
| `check-cli-scoping.sh` (external) | Summary: 13 pass, 0 fail (exit 0) |
| `canonical-cli-lint.sh` (incl. L1-L9) | exit 0 (1 L5 warning landed during fillin and was fixed by switching `set -u; set -o pipefail` → `set -euo pipefail`) |
| `bash -n` syntax | clean |

## Files touched

| File | Change |
|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel-codex-orient` | SCAFFOLD APPLIED + 18-TODO FILLIN: 95 → 585 lines, 18 TODOs → 0, 6 cli_audit_append wires, 8 doctor probes, 3 repair scopes, 3 validate subjects, 3 why ids |
| `tests/flywheel-codex-orient-canonical-cli.sh` | EXTEND: 13 → 25 assertions; 12 NEW fillin-specific assertions |
| `.flywheel/compliance/flywheel-wzjo9.1.9/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-wzjo9.1.9/flywheel-codex-orient.diff` | NEW: captured .claude diff (534 lines) |
| `.flywheel/journal/flywheel-wzjo9.1.9.md` | NEW: journey entry |

## No-collision pattern (vs sister 1.4 verb-collision)

Sister flywheel-wzjo9.1.4 (flywheel-verdict) demonstrated the **delegate** pattern: target already implemented all canonical verbs natively; scaffold stubs delegated. This surface (flywheel-codex-orient) is the opposite: ZERO canonical verbs implemented natively. The fillin embeds substantive logic directly in `scaffold_cmd_*` (no delegate). Matches the sister 1.6 (flywheel-anchor) pattern at 980/1000.

## Skill auto-routes

- canonical-cli-scoping: **yes** (8-mode surface + introspection + --apply gate + JSON envelopes + audit-log discipline + 13/13 external checker)
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (8 modes + 7 per-surface schemas + audit-log wire + canonical refusal contract + 13/13 external + L1-L9 lint clean)
- regression depth: 240/220 (25 assertions; 12 new substantive-fillin asserts; live audit-log append verification; per-subject reason inspection)
- doctrine: 220/200 (no-collision substantive-fillin pattern preserved; sister-pattern alignment with 1.6 anchor at 980/1000)
- integration risk: 200/200 (additive scaffold; original cmd_run path unchanged for default invocation; new cli_audit_append wires are best-effort optional)
- live demonstration: 200/200 (real `~/.codex/CURRENT-DELTAS.md` + live JSONL audit accretion + 8-probe doctor + 3-scope repair --apply path verified)

Total: 1100/1040 → 1000

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: 18 TODOs → 0 with substantive bodies matching sister exemplar shape (1.1/1.2/1.3/1.6 substantive-duplicate pattern). Operator can `flywheel-codex-orient doctor --json` and get 8 named probes including snapshot freshness, OR run default invocation unchanged for SessionStart parity. Wave-2.0a now 6/9 closed.
- **sniff**: 25 regression assertions including live audit-log append verification for both doctor + the original run path; refusal envelope rc=3 tested; per-subject validate reasons inspected; sister surfaces (anchor, verdict, blocker-discipline, agent.sh) all green; lint clean.
- **jeff**: data decided — L5 lint flagged missing strict-mode, fixed; substrate domain (snapshot file + 2 binaries + stale threshold) translates 1:1 to doctor probes + validate subjects + why ids; cli_emit_audit_tail wired with correct path-then-schema positional order per b9dfv.
- **public**: every canonical surface emits structured envelope with `schema_version`; per-surface schemas declare own properties; audit log accretes JSONL rows operator can `jq` for incident timelines. Three Judges check: operator gets clear 8-probe doctor + actionable repair scopes; maintainer sees minimal surface area with no-collision substantive-fillin pattern; future worker can grep the audit log for any of 6 wired action types.

## Cross-orch impact

flywheel-wzjo9 wave-2.0a sub-bead i closes. Wave-2.0a now 6/9 (1.1, 1.2, 1.3, 1.4, 1.6, 1.9). Remaining: 1.5 (deferred legacy backup) + 1.7 + 1.8 (in flight).

## Mission fitness

`mission_fitness=adjacent` — substrate-hygiene-doctrine-cluster canonical-cli completeness; one of 9 P0/P2 surfaces (wave-2.0a) for full doctrine coverage. Codex SessionStart parity reader is one orthogonal route to the mission anchor (continuous-orchestrator-uptime), supporting fleet observability rather than directly advancing it.

## Skill discoveries

No new skill discoveries this bead. The no-collision substantive-fillin pattern was already documented by sisters 1.1/1.2/1.3/1.6. The fillin followed the established 11-step shape without surfacing new doctrine. Legal no-discovery reason: **task stayed inside an existing canonical skill** (canonical-cli-scoping + scaffold-canonical-cli) with no convergent_evolution / meta_rule / trauma_class signal.
