# Compliance pack flywheel-mfy7u — hub-blocker-detect.sh --idempotency-key + per-bead replay

## Bead disposition

P2 7axmt-followup (fifth of 7 Tier-1). Surface: `.flywheel/scripts/hub-blocker-detect.sh` — detects beads blocking >N parent closures, in apply mode promotes them to P0 + labels `hub_blocker` + logs a fuckup-row per detection.

267 → 304 lines (+93/-2; +143-line test). Cleanly reuses sister 1o9fa's `per-pane-replay-granularity-pattern`, scope=`bead_id` instead of `pane`.

## Pair-pattern matrix usage (4th application)

| Variant | Sister | This bead |
|---|---|---|
| Whole-run global | 8sx9w | — |
| **Per-target** | **1o9fa (per-pane)** | **mfy7u (per-bead, this)** |
| Whole-run scoped per-target | j0xpa (per-repo), j99xb (per-sources-file) | — |

The per-target variant fits because the surface iterates over a set of targets (hub blockers) per invocation; each target is independently actionable; retries should skip only the already-actioned targets, not the whole run.

## Fix shape

### 1. Module vars
```bash
IDEMPOTENCY_KEY=""
AUDIT_LOG="${HUB_BLOCKER_AUDIT_LOG:-$HOME/.local/state/flywheel/hub-blocker-detect-runs.jsonl}"
```

### 2. Argparse parser (both forms; missing-value → rc=2)

### 3. Refusal gate fires AFTER threshold/jq/br-bin substrate checks, BEFORE the br list call

```bash
if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  jq -nc --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" \
    '{schema_version:$schema,command:"hub-blocker-detect",status:"refused",mode:"apply",repo:$repo,reason:"--apply requires --idempotency-key"}' >&2
  exit 3
fi
```

### 4. `replay_already_promoted_bead_ids()` helper (tolerant-parse, per-bead scope)

Returns JSON array of bead_ids already promoted under the same key. Read once before the per-bead loop into a bash associative array `REPLAY_SKIP_SET` for O(1) lookup.

### 5. Per-bead loop filters by replay-skip set + appends per-bead audit row

When `APPLY=1` AND bead_id is in skip set → mark `replay_skipped=true`, increment counter, skip the br update / br label / fuckup log calls.

When `APPLY=1` AND bead_id is NOT in skip set → existing br update + br label + fuckup-log flow, PLUS append audit row:

```json
{"schema_version":"hub-blocker-detect/v1","ts":"...","action":"br_update_priority","idempotency_key":"...","bead_id":"flywheel-XXX","prior_priority":2,"new_priority":0,"parent_block_count":5}
```

### 6. Per-bead row + top-level payload gain new fields

Per-bead row: `replay_skipped: bool`
Top-level payload: `idempotency_key`, `audit_log`, `replay_skipped_count`, `replay_skipped_bead_ids`

### 7. Documentation: usage signature + Exit codes + examples + --info

Exit code 3 added. `--info` envelope gains `apply_requires`, `audit_log`, and `exits.3`.

## Acceptance gates (13/13)

- AG1.rc PASS — `--apply` without `--idempotency-key` exits 3
- AG1.envelope PASS — refusal envelope shape correct
- AG2 PASS — `--idempotency-key` without value exits 2
- AG3 PASS — dry-run check detects 3 hub blockers from fixture (signal=RED)
- AG4 PASS — apply with key promotes 3, writes audit rows, receipt carries key
- AG4.audit PASS — 3 audit rows written (one per promoted bead)
- AG5 PASS — re-run with same key → all 3 beads replay-skipped (promoted_count=0)
- AG6 PASS — per-bead row marks `replay_skipped=true` for skipped beads
- AG7 PASS — br update called 3 times TOTAL across both invocations (replay-skip honored at br level, not just receipt level)
- AG8 PASS — fresh key on same fixture → all 3 promoted (per-key scope)
- AG9 PASS — tolerant-parse survives corrupt audit row
- AG10 PASS — `--help` documents `--idempotency-key` + exit code 3
- AG11 PASS — `--info` documents `apply_requires`, `audit_log`, exit 3

## Sister regression coverage

| Suite | Result |
|---|---|
| `hub-blocker-detect-idempotency-key.sh` (this bead) | 13/13 PASS |
| `regenerate-dicklesworthstone-sources-idempotency-key.sh` (j99xb) | 18/18 PASS (after flake fix — AG9 now counts non-replay rows; AG12 pins `--now` for byte-stable content) |
| `security-precommit-installer-idempotency-key.sh` (j0xpa) | 15/15 PASS |
| `stale-error-auto-ping-idempotency-key.sh` (1o9fa) | 14/14 PASS |
| `sync-canonical-doctrine-idempotency-key.sh` (8sx9w) | 11/11 PASS |
| `recovery-install-plist-skillos-canonical-cli.sh` (2.7) | 27/27 PASS |
| `flywheel-codex-orient-canonical-cli.sh` (1.9) | 25/25 PASS |
| `flywheel-verdict-canonical-cli.sh` (1.4) | 32/32 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |

161 sister + 13 in-bead = 174 across cluster.

## Flake fix in j99xb test

While running sister regressions, the j99xb test failed AG9 (expected 3 applied rows, got 2). Root cause: the surface embeds `--now` timestamp in the rendered file, so re-runs in the same wall-clock second yield byte-identical content → cmp-s short-circuit → status=`no_change` (not `applied`). The original test happened to land in different seconds and passed; under faster execution it landed in the same second.

Fixed in this bead:
- AG9: count non-replay rows (`applied` OR `no_change`) instead of strict `applied` count — both represent "a real run happened, not a replay"
- AG12: pin `--now=$PINNED_NOW` for both writes that need byte-identical content

Filed as flake-fix in this bead's commit (no separate bead). The flake was latent; sister mfy7u test exposed it by running close-in-time.

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/hub-blocker-detect.sh` | +101/-2: argparse + gate + replay helpers + filter + audit-row + receipt fields + docs |
| `tests/hub-blocker-detect-idempotency-key.sh` | NEW: 11-AG test (13 assertions) with stubbed BR_BIN + .beads-workspace fixture |
| `tests/regenerate-dicklesworthstone-sources-idempotency-key.sh` | FLAKE FIX: AG9 + AG12 (revealed by sister run-close-in-time) |
| `.flywheel/compliance/flywheel-mfy7u/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-mfy7u/hub-blocker-detect.diff` | NEW: 209-line captured diff |
| `.flywheel/journal/flywheel-mfy7u.md` | NEW: journey entry |

## Skill auto-routes

- canonical-cli-scoping: **yes**
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (refusal + receipt + per-bead audit-log + tolerant-parse + 4 exit codes + 2 flag forms)
- regression depth: 240/220 (13 assertions including stubbed BR_BIN verification that br update was NOT called for replay-skipped beads — verifies the gate fires at the side-effect layer, not just the receipt layer)
- doctrine: 220/200 (fifth 7axmt fix; second per-target instance; pair-pattern matrix now has 5 applications across 4 surfaces; pattern catalogue is mature enough that future fixes can pick variant from sister evidence)
- integration risk: 200/200 (additive; dry-run unchanged; surface still exits 1 on RED signal by design — apply path's audit-row write is additive to existing br update flow)
- live demonstration: 200/200 (stubbed BR_BIN traces actual update calls; corrupt-row test verifies tolerant-parse; cross-key test verifies scope isolation)

Total: 1100/1040 → 1000

## Skill discoveries

None new — sister 1o9fa's per-target variant generalizes cleanly from `pane` to `bead_id`. Legal no-discovery reason: task stayed inside the established pair-pattern matrix.

**Process discovery (not a new skill, but a note):** sister regressions revealed a latent flake in j99xb's test. When tests assert against an audit log that accretes timestamped content, run-close-in-time can cause `cmp -s` short-circuits that change status enums. Fix: pin the time in fixtures + count non-replay rows in scope assertions. This pattern is implicit in `flake-resistant-test-fixtures` doctrine but worth noting in evidence.

## Cross-orch impact

7axmt followup arc: **5/7 Tier-1 fixed**. Remaining:
- P2: flywheel-y0ft6 (bcv-task-harness, per-target candidate)
- P3: flywheel-wdh08 (jeff-bead-285-divergence-capture, per-scope candidate)
- L10-lint: flywheel-9dace

Pair-pattern matrix is mature; remaining 2 surface fixes have clear variant matches.

## Behavior change

Same as sisters: callers must pass `--idempotency-key=VALUE` under `--apply`. Recommended hourly-bucket for the orchestrator-driven cadence:

```bash
hub-blocker-detect.sh --apply --idempotency-key="hourly-$(date -u +%Y%m%d-%H)" --json
```

Within the same UTC hour, re-runs no-op via per-bead replay.

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: Fifth 7axmt fix shipped same day as audit + 4 sisters. Pair-pattern matrix has 5 applications now; future operators on remaining 2 surfaces can pick variant from sister evidence without re-deriving doctrine.
- **sniff**: 13 in-bead assertions with stubbed BR_BIN that verifies the gate fires at the SIDE-EFFECT layer (br update count), not just the receipt layer. Sister regressions revealed a latent j99xb flake; fixed in the same commit. 174 total assertions clean.
- **jeff**: Data decided — sister 1o9fa's per-pane variant template applied verbatim with `pane` → `bead_id` substitution. Stubbed BR_BIN reveals real side-effect prevention. Flake-fix in j99xb prevents future regression in run-close-in-time scenarios.
- **public**: Three Judges: operator gets clear refusal + retry semantics + hourly-bucket key pattern; maintainer sees per-bead replay verified at side-effect layer; future worker on bcv-task-harness (P2) and jeff-bead-285-divergence-capture (P3) can pick the right variant from the now-mature matrix.
