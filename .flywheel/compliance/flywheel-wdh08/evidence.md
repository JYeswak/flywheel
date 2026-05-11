# Compliance pack flywheel-wdh08 — jeff-bead-285-divergence-capture.sh --idempotency-key + per-(key, bead_id) replay

## Bead disposition

P3 7axmt-followup (**seventh and final of 7 Tier-1**). Surface: `.flywheel/scripts/jeff-bead-285-divergence-capture.sh` — forensic capture tool for Jeff Emanuel's beads_rust upstream issue #285 (br close divergence). Captures pre/post `br doctor` snapshots + `br close` RUST_LOG trace into a timestamped capture dir.

278 → 332 lines (+54/-1; +98-line test). Sister j0xpa per-target template applied with scope=`bead_id`.

## Fix shape (standard sister-template application)

### 1. Module vars
```bash
IDEMPOTENCY_KEY=""
AUDIT_LOG="${JEFF_285_AUDIT_LOG:-$HOME/.local/state/flywheel/jeff-bead-285-divergence-capture-runs.jsonl}"
```

### 2. Argparse parser (both forms; missing-value → rc=2)

### 3. Refusal gate fires AFTER the dry-run early-return, BEFORE `mkdir -p "$CAPTURE_DIR"` (hoqq8 invariant: gate before any side-effect — capture-dir creation is the first mutation)

### 4. `replay_prior_capture()` (tolerant-parse, per-(key, bead_id) scope)

```bash
jq -Rc --arg k "$IDEMPOTENCY_KEY" --arg b "$BEAD_ID" \
  'fromjson? | select((.idempotency_key // "") == $k and (.bead_id // "") == $b and ((.status // "") | IN("captured","replay")))' \
  "$AUDIT_LOG" 2>/dev/null | tail -n 1 || true
```

### 5. Replay-no-op emits prior receipt + exit 0

### 6. `audit_append_capture()` writes row after manifest with `{idempotency_key, bead_id, capture_dir, manifest, close_exit_code, pre_status, post_status, divergence_observed, ts}`

### 7. Documentation updates: usage, info_json (flags, env_vars, mutation_requires, apply_requires, audit_log, exit_codes), examples

## Acceptance gates (11/11)

- AG1.rc PASS — `--apply` without `--idempotency-key` exits 3
- AG1.envelope PASS — refusal envelope shape + bead_id field
- AG2 PASS — `--idempotency-key` without value exits 2
- AG3 PASS — `--idempotency-key=VALUE` equals form parses + dry-run still works
- AG4 PASS — `--info` documents `apply_requires`, `audit_log`, and `--idempotency-key` in flags
- AG5 PASS — `--help` shows `--idempotency-key`
- AG6 PASS — `--examples` shows `--idempotency-key` usage
- AG7 PASS — replay-check fires for (key, bead_id) match → status=replay, exit 0
- AG8 PASS — different bead_id under same key does NOT replay (per-target scope honored)
- AG9 PASS — tolerant-parse survives corrupt audit row
- AG10 PASS — `--schema` still emits valid envelope (existing behavior preserved)

## Sister regression coverage — complete 7axmt arc

| Suite | Result | Variant | Scope |
|---|---|---|---|
| `jeff-bead-285-divergence-capture-idempotency-key.sh` (this, wdh08) | 11/11 PASS | per-target | bead_id |
| `bcv-task-harness-idempotency-key.sh` (y0ft6) | 11/11 PASS | per-target-set | sha(sorted target_beads) |
| `hub-blocker-detect-idempotency-key.sh` (mfy7u) | 13/13 PASS | per-target | bead_id |
| `regenerate-dicklesworthstone-sources-idempotency-key.sh` (j99xb) | 18/18 PASS | per-target-set | sources_file |
| `security-precommit-installer-idempotency-key.sh` (j0xpa) | 15/15 PASS | per-target-set | repo |
| `stale-error-auto-ping-idempotency-key.sh` (1o9fa) | 14/14 PASS | per-target | pane |
| `sync-canonical-doctrine-idempotency-key.sh` (8sx9w) | 11/11 PASS | whole-run global | — |

**93 total assertions, 0 fail across the complete 7axmt-followup arc.**

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/jeff-bead-285-divergence-capture.sh` | +54/-1: argparse + gate + replay helpers + audit-row + docs |
| `tests/jeff-bead-285-divergence-capture-idempotency-key.sh` | NEW: 10-AG test (11 assertions) with seeded-audit-log replay verification |
| `.flywheel/compliance/flywheel-wdh08/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-wdh08/jeff-bead-285-divergence-capture.diff` | NEW: 132-line captured diff |
| `.flywheel/journal/flywheel-wdh08.md` | NEW: journey entry + arc-summary |

## Skill auto-routes

- canonical-cli-scoping: **yes**
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (refusal + receipt + per-(key, bead_id) replay + tolerant-parse + 4 exit codes + 2 flag forms)
- regression depth: 240/220 (11 assertions including seeded-audit-log replay verification + per-target scope isolation + tolerant-parse + existing-behavior preservation)
- doctrine: 220/200 (seventh and final 7axmt fix; pair-pattern matrix now has 7 worked applications)
- integration risk: 200/200 (additive; dry-run unchanged; capture-dir creation is the first side effect and the gate fires before it)
- live demonstration: 200/200 (seeded audit log → replay no-op verified; per-bead scope isolation verified)

Total: 1100/1040 → 1000

## Skill discoveries

None new — sister j0xpa template + scope substitution to `bead_id`. Pair-pattern matrix complete and stable.

## 7axmt arc completion summary

The 7axmt fleet audit identified 7 surfaces (Tier-1) and 1 lint-rule (orch-action). All 7 surface fixes now shipped:

| # | Bead | Surface | Priority | Variant | Commit |
|---|---|---|---|---|---|
| 1 | 8sx9w | sync-canonical-doctrine.sh | P0 | Whole-run global | 19c8cfc |
| 2 | 1o9fa | stale-error-auto-ping.sh | P1 | Per-target (pane) | 5f66a44 |
| 3 | j0xpa | security-precommit-installer.sh | P1 | Per-target-set (repo) | 074d66e |
| 4 | j99xb | regenerate-dicklesworthstone-sources.sh | P1 | Per-target-set (sources_file) | c55f962 |
| 5 | mfy7u | hub-blocker-detect.sh | P2 | Per-target (bead_id) | ca86bcf |
| 6 | y0ft6 | bcv-task-harness.sh | P2 | Per-target-set (target_beads_sha) | aff20b7 |
| 7 | **wdh08 (this)** | jeff-bead-285-divergence-capture.sh | P3 | Per-target (bead_id) | (this commit) |

Remaining 7axmt deliverable: flywheel-9dace (L10 canonical-cli-lint rule — orch-action recommendation). Not a surface fix; a lint enhancement to PREVENT future surfaces from regressing into the bug class.

## Pair-pattern matrix (final state)

| Variant | When to use | Audit-row scope | Replay action | Applications |
|---|---|---|---|---|
| Whole-run global | Single-atomic-operation surface (one transaction per invocation) | `{key, status:ok}` | Exit 0 early, emit prior receipt | 8sx9w |
| Per-target | Surface iterates over N targets in one invocation; each target independently actionable | `{key, target}` per action | Filter work-list, mark skip in receipt | 1o9fa (pane), mfy7u (bead_id), **wdh08 (bead_id)** |
| Per-target-set | Surface operates on ONE target-or-set per invocation, can be called many times across the fleet | `{key, scope-id, status:applied}` | Exit 0 if (key, scope-id) matches | j0xpa (repo), j99xb (sources_file), y0ft6 (target_beads_sha) |

3 variants, 7 worked applications, 93 regression assertions. Mature pattern catalogue.

## Skill discoveries (cumulative across the arc)

| Discovery | Sister | Stable |
|---|---|---|
| `ledger-replay-check-with-tolerant-parse` | 8sx9w | yes — applied in all 7 fixes |
| `idempotency-key-with-replay-check pair-pattern` | 8sx9w | yes — the foundational pattern |
| `per-pane-replay-granularity-pattern` (per-target variant) | 1o9fa | yes — applied in mfy7u, wdh08 |
| `per-repo-scoped-whole-run-replay-pattern` (per-target-set variant) | j0xpa | yes — generalized to scope-id in j99xb, y0ft6 |
| `fix-spec-correction-via-evidence` | j0xpa | yes — applied in y0ft6 (task_id → target_beads_sha) |

5 skill discoveries cumulative. All consumed by subsequent fixes; pattern catalogue stabilized.

## Behavior change announcement (complete arc)

All 7 surfaces now refuse `--apply` without `--idempotency-key`. Search affected automation:

```bash
rg -l 'sync-canonical-doctrine.*--apply|stale-error-auto-ping.*--apply|security-precommit-installer.*install.*--apply|regenerate-dicklesworthstone-sources.*--apply|hub-blocker-detect.*--apply|bcv-task-harness.*--apply|jeff-bead-285-divergence-capture.*--apply' --type sh
```

Each invocation should be updated to pass an appropriate key. Recommended bucketing:
- Hourly cadence: `--idempotency-key="hourly-$(date -u +%Y%m%d-%H)"`
- Daily cadence: `--idempotency-key="daily-$(date -u +%Y%m%d)"`
- Per-commit cadence: `--idempotency-key="$(git rev-parse HEAD)"`
- Named rollout: `--idempotency-key="rollout-$NAME"`

## Cross-orch impact

7axmt followup arc **COMPLETE**: 7/7 Tier-1 fixed. Remaining: flywheel-9dace (L10 canonical-cli-lint rule, orch-action recommendation). The lint, when shipped, will:
- Detect new surfaces adding `--apply` without `--idempotency-key`
- Prevent regression into the 7axmt bug class fleet-wide
- Allowlist exemption for surfaces with explicit refusal patterns (`apply_not_supported`, etc.) or `# IDEMPOTENT-BY-CONSTRUCTION:` marker comments

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: Seventh and final 7axmt fix shipped same day as the audit + 6 sisters. Complete arc closed in one session. Pattern catalogue mature at 3 variants with 7 worked applications across diverse surface types (config-sync, ping-sender, hook-installer, regen-tool, beads-promoter, multi-phase-harness, forensic-capture).
- **sniff**: 11 in-bead assertions + 82 sister assertions = 93 total across the arc. Hermetic test approach with seeded audit logs verifies replay-check semantics without real br/python3/skill dependencies. Per-target scope isolation verified (different bead_id under same key does NOT replay).
- **jeff**: Data decided — sister j0xpa template applied verbatim with scope substitution (`repo` → `bead_id`). The audit's fix-spec section 7 said "standard pattern, low frequency" without specifying scope; substrate inspection chose `bead_id` as the natural per-target identifier (the surface takes `<bead-id>` as positional arg).
- **public**: Three Judges: operator gets clear refusal + retry semantics across all 7 surfaces with consistent vocabulary; maintainer sees the complete pair-pattern matrix documented with worked examples; future worker on lint-rule (flywheel-9dace) can codify the patterns into automated detection without needing to re-derive doctrine.
