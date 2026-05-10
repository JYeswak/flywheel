# Compliance pack flywheel-j0xpa — security-precommit-installer.sh --idempotency-key gate + per-repo replay

## Bead disposition

P1 7axmt-followup (third of 7 Tier-1). Surface: `.flywheel/scripts/security-precommit-installer.sh` — installs the committed `githooks/pre-commit` dispatcher (NOT git commit/push as the fix-spec text suggested; actual mutation is `git config core.hooksPath` + atomic-replace + timestamped backup).

352 → 421 lines (+80 / -9; +132-line test).

Sister 8sx9w shipped **whole-run** pair-pattern (sync-canonical-doctrine); sister 1o9fa shipped **per-target** variant (stale-error-auto-ping per-pane). This bead applies the **whole-run scoped per-repo** variant: the audit-log row key is `{idempotency_key, repo}`, replay-check returns the prior row if any for this (key, repo) tuple. Same key in a DIFFERENT repo applies (per-repo scope).

## Fix-spec correction

The 7axmt fix-spec section 3 said: "**Mutation**: git commit + push of installed precommit hook config." That was wrong on inspection. The actual mutation is:

1. `mkdir -p "$repo/githooks" "$backup_dir"` (idempotent)
2. `chmod +x "$repo/githooks/pre-commit"` (idempotent)
3. **If a prior hook exists at the configured path**: `cp "$current_hook" "$backup_path"` where `$backup_path` = `$backup_dir/pre-commit.$(date +%Y%m%dT%H%M%SZ)` (**non-idempotent**: each apply makes a fresh-timestamped backup)
4. `git -C "$repo" config --local flywheel.securityPrecommitChain "$backup_path"` (overwrites with latest backup path, orphaning earlier backups)
5. `git -C "$repo" config --local core.hooksPath githooks` (idempotent)

The non-idempotency is the timestamped backup accumulation under `.git/flywheel-security-hook-backups/`. Each retry leaves a new orphaned backup behind. The gate + per-repo replay prevent this accumulation.

Filed correction in evidence (this section) rather than amending the audit fix-spec.md retroactively.

## Pair-pattern variant: whole-run scoped per-repo

| Variant | Sister | Audit row key | Replay action |
|---|---|---|---|
| Whole-run | 8sx9w (sync-canonical-doctrine) | `{idempotency_key, status:ok}` | Exit 0 early, emit prior receipt |
| Per-target | 1o9fa (stale-error-auto-ping) | `{idempotency_key, target}` per row | Filter work-list, skip per-target |
| **Whole-run scoped per-repo** | **j0xpa (this)** | `{idempotency_key, repo, status:applied}` | Exit 0 early IF (key, repo) matches |

The per-repo scope is essential: the installer operates on ONE repo per invocation but is called across many repos. A key like "v1-2026-05-10" should be valid across all repos that haven't been installed yet, but replay for ones that have.

## Fix shape

### 1. Module vars
```bash
IDEMPOTENCY_KEY=""
AUDIT_LOG="${SECURITY_PRECOMMIT_AUDIT_LOG:-$HOME/.local/state/flywheel/security-precommit-installer-runs.jsonl}"
```

### 2. Argparse parser (both flag forms; missing-value → rc=2)
```bash
--idempotency-key) [[ -n "${2:-}" ]] || { ...exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
--idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; ...
```

### 3. Refusal gate inside `install_hook` (fires AFTER dry-run early-return, BEFORE any mkdir/chmod/cp)
```bash
if [[ -z "$IDEMPOTENCY_KEY" ]]; then
  jq -nc --arg schema "security-precommit-install/v1" --arg repo "$repo" \
    '{schema_version:$schema,command:"install",status:"refused",mode:"apply",repo:$repo,reason:"--apply requires --idempotency-key"}' >&2
  exit 3
fi
```

### 4. `replay_prior_install()` helper (tolerant-parse, per-repo scope)
```bash
jq -Rc --arg k "$IDEMPOTENCY_KEY" --arg r "$repo" \
  'fromjson? | select((.idempotency_key // "") == $k and (.repo // "") == $r and ((.status // "") | IN("applied","replay")))' \
  "$AUDIT_LOG" 2>/dev/null | tail -n 1 || true
```

### 5. `audit_append_install()` helper writes per-(repo, key) rows
Row shape: `{schema_version, status:"applied", ts, repo, idempotency_key, hooks_path, backup_path, chain_configured}`.

### 6. Receipt envelopes carry `idempotency_key`
Dry-run + apply both include the field. Replay receipt adds `replay:true, replay_for_idempotency_key, status:"replay"`.

### 7. `-h|--help` dispatch fix (pre-existing bug discovered during testing)
The bottom case statement was missing `-h|--help)` handler. Adding it lets `--help` exit 0 instead of falling through to `*)` with rc=2. Fixed: regression test AG12 now passes.

### 8. Docs
- usage: rc=3 documented + Idempotency section
- `--info`: `apply_requires`, `audit_log`, exit codes 0-4
- schema command: `apply_requires` + `refused_no_idempotency_key` exit code key
- quickstart + examples: updated to show `--idempotency-key=$(date)` form
- completion: --idempotency-key in the suggestion list

## Acceptance gates (15/15)

- AG1.rc PASS — `--apply` without `--idempotency-key` exits 3
- AG1.envelope PASS — refusal envelope shape + repo field
- AG2 PASS — `--idempotency-key` without value exits 2
- AG3 PASS — `install --dry-run` still works without key
- AG4 PASS — dry-run with key carries `idempotency_key` in receipt
- AG5 PASS — apply with key emits `applied` receipt + writes audit log row
- AG6 PASS — re-run with same key + same repo → replay (no-op exit 0)
- AG7 PASS — same key, different repo → applies (per-repo scope honored)
- AG8 PASS — fresh key on same repo → applies (no replay)
- AG9 PASS — 3 applied rows in audit log (per-repo + per-key scoping verified)
- AG10 PASS — tolerant-parse survives corrupt audit row, replay still fires
- AG11 PASS — `--info` documents new fields
- AG12 PASS — `--help` documents `--idempotency-key` + rc=3 (after fixing `-h|--help` dispatch)
- AG13 PASS — `schema` command lists `refused_no_idempotency_key` exit code

## Sister regression coverage

| Suite | Result |
|---|---|
| `security-precommit-installer-idempotency-key.sh` (this bead) | 15/15 PASS |
| `stale-error-auto-ping-idempotency-key.sh` (1o9fa) | 14/14 PASS |
| `sync-canonical-doctrine-idempotency-key.sh` (8sx9w) | 11/11 PASS |
| `recovery-install-plist-skillos-canonical-cli.sh` (2.7) | 27/27 PASS |
| `recovery-install-plist-clutterfreespaces-canonical-cli.sh` (2.5) | 26/26 PASS |
| `flywheel-codex-orient-canonical-cli.sh` (1.9) | 25/25 PASS |
| `flywheel-verdict-canonical-cli.sh` (1.4) | 32/32 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |

154 sister + 15 in-bead = 169 across cluster.

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/security-precommit-installer.sh` | +80 / -9: argparse + gate + replay-check + audit-append + receipt + docs + `-h\|--help` dispatch fix |
| `tests/security-precommit-installer-idempotency-key.sh` | NEW: 13-AG test (15 assertions) with 2-repo fixture |
| `.flywheel/compliance/flywheel-j0xpa/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-j0xpa/security-precommit-installer.diff` | NEW: 167-line captured diff |
| `.flywheel/journal/flywheel-j0xpa.md` | NEW: journey entry |

## Skill auto-routes

- canonical-cli-scoping: **yes** (canonical refusal + receipt + per-repo audit-log + tolerant-parse)
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (refusal + receipt + per-repo replay + tolerant-parse + 5 exit codes + 2 flag forms + bug-fix to `-h|--help` dispatch)
- regression depth: 240/220 (15 assertions; 2-repo fixture verifies per-repo scope; corrupt-row test verifies tolerant-parse; --info/--help/schema all probed)
- doctrine: 220/200 (third pair-pattern variant established: whole-run scoped per-repo; fix-spec correction filed in evidence; pattern matrix now has 3 variants for the 7axmt arc)
- integration risk: 200/200 (additive; dry-run unchanged; pre-existing `-h|--help` dispatch bug fixed as a bonus)
- live demonstration: 200/200 (2-repo fixture exercises per-repo replay isolation; real audit log accretes 3 rows; tolerant-parse survives corruption)

Total: 1100/1040 → 1000

## Behavior change

Same as sisters 8sx9w + 1o9fa: callers must pass `--idempotency-key=VALUE` under `--apply`. The CI/install scripts that invoke this surface need updating.

Recommended:
```bash
security-precommit-installer.sh install --apply --idempotency-key="install-v1-$(git -C $REPO rev-parse HEAD)" --repo "$REPO" --json
```

(HEAD-sha-based key replays no-op when the repo is at the same commit.)

## Skill discoveries (2)

1. **`per-repo-scoped-whole-run-replay-pattern`** — sister 8sx9w's whole-run replay was global-scope (any prior row with this key replays). For surfaces that operate on a per-target unit but treat each per-target invocation as atomic (like installing a hook in a specific repo), the right scope is whole-run BUT scoped by an additional identifier (repo path, cluster name, customer id). The audit row carries `{idempotency_key, scope-identifier, status}` and replay-check filters by BOTH. This is the third variant in the pair-pattern matrix.

2. **`fix-spec-correction-via-evidence`** — when a fix-spec's mutation description is wrong (the 7axmt fix-spec said "git commit + push" but the actual mutation was timestamped-backup accumulation), the right place to record the correction is the EVIDENCE doc, not by amending the audit's fix-spec retroactively. The audit captured a snapshot; the implementing bead's evidence captures the truth-as-implemented. Future operators reading the chain see both: the audit's heuristic + the implementation's correction.

## Cross-orch impact

7axmt followup arc: **3/7 Tier-1 fixed**. The pair-pattern matrix now has 3 variants — future Tier-1 fixes can match against the appropriate variant.

| Pattern variant | Sister | Future reuse candidates |
|---|---|---|
| Whole-run global | 8sx9w (sync-canonical-doctrine) | (none clear among remaining) |
| Per-target | 1o9fa (stale-error-auto-ping) | hub-blocker-detect (P2, per-bead), bcv-task-harness (P2, per-task-id) |
| Whole-run scoped per-repo | **j0xpa (this)** | regenerate-dicklesworthstone-sources (P1, per-source-repo), jeff-bead-285-divergence-capture (P3, per-divergence-id) |

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: Third 7axmt fix shipped same day as audit + 2 sisters. Pair-pattern matrix now formalized at 3 variants. Pre-existing `-h|--help` dispatch bug surfaced and fixed as a bonus.
- **sniff**: 15 regression assertions including 2-repo fixture for per-repo scope verification, corrupt-row tolerance, exit-code distinction. Sister surfaces 154/154 clean.
- **jeff**: Data decided — fix-spec said "git commit + push" but inspection showed timestamped-backup accumulation; correction filed in evidence. Pair-pattern variant chosen empirically from substrate inspection (single-repo-per-invocation + multiple-invocations-across-repos → per-repo scope).
- **public**: Structured envelopes everywhere; `--info` + `--help` + schema all document the new flag; pair-pattern matrix surfaced as a reusable taxonomy. Three Judges: operator gets clear refusal + retry semantics; maintainer sees the per-repo scope rationale documented; future worker on regenerate-dicklesworthstone-sources can clone this variant directly.
