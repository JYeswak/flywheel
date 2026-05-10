# Compliance pack flywheel-j99xb — regenerate-dicklesworthstone-sources.sh --idempotency-key gate + per-(key, sources-file) replay

## Bead disposition

P1 7axmt-followup (fourth of 7 Tier-1). Surface: `.flywheel/scripts/regenerate-dicklesworthstone-sources.sh` — regenerates `~/.claude/skills/dicklesworthstone-stack/data/sources.txt` from live GitHub via `gh repo list Dicklesworthstone`.

213 → 283 lines (+70 / -1; +148-line test).

Cleanly reuses sister j0xpa's `per-repo-scoped-whole-run-replay-pattern`, scoped to `(idempotency_key, sources_file)` instead of `(idempotency_key, repo)`. Variant fits because: one sources file per invocation, sources-file path overrideable via `--sources-file`, mutation is timestamped-backup + content-replace.

## Pre-existing partial idempotency

Surface already had a `cmp -s "$RENDERED" "$SOURCES_FILE"` content-check that skips the mv if unchanged. So the mutation was already partially idempotent at the content level. But timestamped backups still accumulated each `--apply` because the backup-path was `${SOURCES_FILE}.bak.$(date -u +%Y%m%dT%H%M%SZ)` — even content-identical re-runs that skip the mv still wrote a fresh-timestamped backup.

Actually, on closer read: the backup is only written INSIDE `if [[ "$CHANGED" == "true" ]]`. So content-identical re-runs are already idempotent. The non-idempotency is: **content-changed retries** create accumulating backups, and the key prevents that.

The audit row uses `status: "applied"` when CHANGED=true (backup + mv happened) and `status: "no_change"` when CHANGED=false (cmp -s short-circuited). Both statuses count as "successful prior run" for replay-check purposes.

## Pair-pattern matrix (now 3 sisters using whole-run-scoped variants)

| Variant | Audit-row scope | Replay action | Sister |
|---|---|---|---|
| Whole-run global | `{key}` | Exit 0 if any row matches | 8sx9w (sync-canonical-doctrine) |
| Per-target | `{key, target}` per action | Filter work-list | 1o9fa (stale-error-auto-ping) |
| Whole-run scoped per-target | `{key, scope-id}` | Exit 0 if (key, scope) matches | j0xpa (security-precommit-installer, scope=repo), **j99xb (this, scope=sources_file)** |

The per-scope variant is now proven across two different scope identifiers (repo path, sources-file path) — generalizes to any one-target-per-invocation surface with a stable identifier in the parameter set.

## Fix shape

### 1. Module vars
```bash
IDEMPOTENCY_KEY=""
AUDIT_LOG="${REGEN_DICKLESWORTHSTONE_AUDIT_LOG:-$HOME/.local/state/flywheel/regenerate-dicklesworthstone-sources-runs.jsonl}"
```

### 2. Argparse parser (both forms; missing-value via existing `die()` helper → rc=2)
```bash
--idempotency-key) IDEMPOTENCY_KEY="${2:-}"; [[ -n "$IDEMPOTENCY_KEY" ]] || die "--idempotency-key requires VALUE"; shift 2 ;;
--idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; [[ -n "$IDEMPOTENCY_KEY" ]] || die "--idempotency-key requires VALUE"; shift ;;
```

### 3. Refusal gate fires AFTER argparse loop, BEFORE any side-effect
```bash
if [[ "$MODE" == "apply" && -z "$IDEMPOTENCY_KEY" ]]; then
  jq -nc --arg schema "dicklesworthstone-sources-regeneration/v1" --arg sources_file "$SOURCES_FILE" \
    '{schema_version:$schema,command:"regenerate-dicklesworthstone-sources",status:"refused",mode:"apply",sources_file:$sources_file,reason:"--apply requires --idempotency-key"}' >&2
  exit 3
fi
```

### 4. `replay_prior_regen()` (tolerant-parse, per-(key, sources_file) scope)
```bash
jq -Rc --arg k "$IDEMPOTENCY_KEY" --arg sf "$SOURCES_FILE" \
  'fromjson? | select((.idempotency_key // "") == $k and (.sources_file // "") == $sf and ((.status // "") | IN("applied","replay","no_change")))' \
  "$AUDIT_LOG" 2>/dev/null | tail -n 1 || true
```

Status enum includes `"no_change"` (content-unchanged path) so cmp-s short-circuit results also serve as replay anchors.

### 5. `audit_append_regen()` writes per-(key, sources_file) rows
Row shape: `{schema_version, ts, status: applied|no_change, sources_file, idempotency_key, backup_path, content_sha256, active_repo_count}`.

### 6. Apply path
- After argparse: refusal-gate already fired if no key
- Before mutations: replay-check; if prior row exists for (key, sources_file), emit `{status: replay, replay: true, replay_for_idempotency_key}` + exit 0
- Otherwise: existing mkdir + (changed? backup+mv : skip) flow
- After mutation: audit-append with status reflecting actual action (`applied` for changed=true, `no_change` for changed=false)

### 7. Receipt envelope adds `idempotency_key` + `audit_log` fields
Both dry-run and apply paths.

### 8. Documentation: usage with new flag + Idempotency section + exit code 3

## Acceptance gates (18/18)

- AG1.rc PASS — `--apply` without `--idempotency-key` exits 3
- AG1.envelope PASS — refusal envelope shape + sources_file field
- AG2 PASS — `--idempotency-key` without value exits 2
- AG3 PASS — `--dry-run` still works without key
- AG3.content PASS — rendered file includes active repos, excludes archived
- AG4 PASS — dry-run with key carries `idempotency_key` in receipt
- AG5 PASS — apply with key emits ok receipt
- AG5.write PASS — sources file written
- AG5.audit PASS — audit log row with key + status=applied
- AG6 PASS — re-run same (key, sources-file) → replay
- AG7 PASS — same key, different sources-file → applies (per-target scope honored)
- AG8 PASS — fresh key on same sources-file → applies (no replay)
- AG9 PASS — audit log has 3 applied rows
- AG10 PASS — audit rows carry `content_sha256` + `backup_path`
- AG11 PASS — tolerant-parse survives corrupt audit row
- AG12 PASS — content-unchanged path uses `changed=false`
- AG12.audit PASS — `no_change` status recorded for unchanged content
- AG13 PASS — `--help` documents `--idempotency-key` + rc=3

## Sister regression coverage

| Suite | Result |
|---|---|
| `regenerate-dicklesworthstone-sources-idempotency-key.sh` (this) | 18/18 PASS |
| `security-precommit-installer-idempotency-key.sh` (j0xpa) | 15/15 PASS |
| `stale-error-auto-ping-idempotency-key.sh` (1o9fa) | 14/14 PASS |
| `sync-canonical-doctrine-idempotency-key.sh` (8sx9w) | 11/11 PASS |
| `recovery-install-plist-skillos-canonical-cli.sh` (2.7) | 27/27 PASS |
| `recovery-install-plist-clutterfreespaces-canonical-cli.sh` (2.5) | 26/26 PASS |
| `flywheel-codex-orient-canonical-cli.sh` (1.9) | 25/25 PASS |
| `flywheel-verdict-canonical-cli.sh` (1.4) | 32/32 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |

169 sister + 18 in-bead = 187 across cluster.

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/regenerate-dicklesworthstone-sources.sh` | +70/-1: argparse + gate + replay-check + audit-append + receipt fields + docs |
| `tests/regenerate-dicklesworthstone-sources-idempotency-key.sh` | NEW: 13-AG test (18 assertions) with gh-fixture |
| `.flywheel/compliance/flywheel-j99xb/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-j99xb/regenerate-dicklesworthstone-sources.diff` | NEW: 141-line diff |
| `.flywheel/journal/flywheel-j99xb.md` | NEW: journey entry |

## Skill auto-routes

- canonical-cli-scoping: **yes** (refusal + receipt + per-(key, sources-file) audit-log + tolerant-parse)
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (refusal + receipt + per-(key, sources-file) replay + tolerant-parse + 3 exit codes + 2 flag forms)
- regression depth: 240/220 (18 assertions; 2-sources-file fixture; corrupt-row test; changed=false path tested with no_change audit status)
- doctrine: 220/200 (fourth 7axmt fix; generalized j0xpa's per-scope variant from `(key, repo)` to `(key, scope-id)`; proves pattern reusable across scope identifiers)
- integration risk: 200/200 (additive; dry-run unchanged; cmp-s content-check preserved; existing `--apply` callers will refuse — INTENTIONAL behavior change consistent with sisters)
- live demonstration: 200/200 (2-sources-file fixture exercises per-target replay isolation; gh-fixture format verified; 3 audit rows accumulated correctly)

Total: 1100/1040 → 1000

## Skill discoveries

None new this bead — the per-scope variant from sister j0xpa generalizes cleanly. Legal no-discovery reason: task stayed inside the canonical-cli-scoping + 7axmt-followup pair-pattern matrix established by sisters 8sx9w/1o9fa/j0xpa.

## Behavior change

Same as sisters: callers must pass `--idempotency-key=VALUE` under `--apply`. Recommended date-based key for the documented daily runner:

```bash
regenerate-dicklesworthstone-sources.sh --apply --idempotency-key="daily-$(date -u +%Y%m%d)" --json
```

(Daily bucket — within the same UTC day, re-runs no-op via replay.)

## Cross-orch impact

7axmt followup arc: **4/7 Tier-1 fixed**. Remaining:
- P2: flywheel-mfy7u (hub-blocker-detect, per-target candidate), flywheel-y0ft6 (bcv-task-harness, per-target candidate)
- P3: flywheel-wdh08 (jeff-bead-285-divergence-capture, per-scope candidate)
- L10-lint: flywheel-9dace

Pair-pattern matrix is now mature — remaining 3 surface fixes can pick directly from the established variants.

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: Fourth 7axmt fix shipped same-day. Pair-pattern matrix proven reusable across scope identifiers. Generalized j0xpa's `(key, repo)` to `(key, scope-id)` — same code shape, different field name.
- **sniff**: 18 regression assertions including 2-sources-file fixture for per-target scope isolation, gh-fixture format with mixed active+archived repos, content-unchanged path verification with `no_change` status. Sister surfaces 169/169 clean.
- **jeff**: Data decided — read the surface, identified the existing `cmp -s` partial idempotency, decided the new gate adds backup-accumulation prevention (not pure-prevention) on the changed=true path. Status enum extended to include `no_change` so cmp-s short-circuits serve as replay anchors.
- **public**: Three Judges: operator gets clear refusal + retry semantics; maintainer sees the per-scope generalization documented; future worker on remaining 3 Tier-1 surfaces can pick the matching variant from the matrix.
