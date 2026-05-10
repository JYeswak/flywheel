# flywheel-7axmt fix-specs — 7 Tier-1 surfaces needing --idempotency-key

Each surface gets a minimal recipe: where to add the flag + the canonical refusal + audit-trail wire. The pattern is identical to `cli_refuse_apply_without_idem_key` from `canonical-cli-helpers.sh` and matches sister-fillin shape from wzjo9.1.x.

## Common pattern (all 7)

Add to argument parsing:

```bash
--idempotency-key)
    idempotency_key="$2"; shift 2 ;;
--idempotency-key=*)
    idempotency_key="${1#--idempotency-key=}"; shift ;;
```

Add gate BEFORE first mutation:

```bash
if [[ "$APPLY" -eq 1 && -z "$idempotency_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null 2>&1; then
        cli_refuse_apply_without_idem_key "$SCHEMA_VERSION" "<surface-name>" "$scope"
    else
        jq -nc --arg scope "$scope" \
            '{schema_version:"<surface-name>/v1",command:"<surface-name>",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
        exit 3
    fi
fi
```

Wire audit-trail row with idempotency key:

```bash
cli_audit_append "$AUDIT_LOG" "<action>" "$status" \
    "$(jq -nc --arg k "$idempotency_key" '{idempotency_key:$k}')" >/dev/null 2>&1 || true
```

## Per-surface fix-specs

### 1. `.flywheel/scripts/sync-canonical-doctrine.sh` (P0 — largest blast radius)

**Mutation**: cross-fleet sync to AGENTS.md, validation schemas, doctrine docs, allowlisted scripts, launchd templates, .claude/settings.json across every flywheel-installed repo.

**Fix recipe**:
- Around line 240 (where `--apply)` is parsed), add the `--idempotency-key` parser.
- After `MODE="apply"` is set (around line 245), add the gate block above.
- Each per-repo sync action should append a `cli_audit_append` row carrying `idempotency_key` + per-repo path + content sha256.
- **Bonus**: add `--idempotency-key-replay` flag that no-ops if a prior row with the same key already exists in the audit log (safe re-run).

**Why P0**: backup-before-write protects against single-clobber, but a worker that retries after a partial failure could:
1. First run: half the repos get the new doctrine, half stay old
2. Second run: backs up the new doctrine as `.bak`, writes again — same content but loses the original `.bak` from run 1.

`--idempotency-key` with audit-log replay-check makes this safe.

### 2. `.flywheel/scripts/stale-error-auto-ping.sh` (P1)

**Mutation**: sends `ntm send` ping to detected stuck panes.

**Fix recipe**:
- Around line 97 (`--apply) APPLY=1; DRY_RUN=0`), add the `--idempotency-key` parser.
- Around line 79 (just before the planned_actions/actual_actions emit), add the gate block.
- The audit-trail row should carry `idempotency_key` + per-pane `{pane:N, ts, ping_text}`.

**Why P1**: pinging is external state. Re-running double-pings — operator sees pane chevron flush twice. The key + audit row would let the surface skip pings whose `{idempotency_key, pane}` tuple already appears in the recent audit window.

### 3. `.flywheel/scripts/security-precommit-installer.sh` (P1)

**Mutation**: git commit + push of installed precommit hook config.

**Fix recipe**:
- Around line 297 (`--apply)`), add the parser.
- Before the git commit/push action, add the gate.
- The audit-trail row should carry `{idempotency_key, repo, commit_sha}`.

**Why P1**: git commits accumulate. An interrupted install + retry could double-commit. The gate + audit row would let the surface refuse to commit if the most recent commit on HEAD already has the same idempotency-key in its message body.

### 4. `.flywheel/scripts/regenerate-dicklesworthstone-sources.sh` (P1)

**Mutation**: regenerates Jeff source-repo copies (delete + re-clone + integrate).

**Fix recipe**:
- Around line 146 (`--apply) MODE="apply"`), add the parser.
- Before the regenerate action (rm + clone), add the gate.
- The audit-trail row should carry `{idempotency_key, source_repo, target_path, content_sha}`.

**Why P1**: destructive-then-replace is risky under concurrent retry. The key prevents two operators racing.

### 5. `.flywheel/scripts/hub-blocker-detect.sh` (P2)

**Mutation**: `br set priority=0` on detected hub blockers.

**Fix recipe**:
- Around line 57 (`--apply)`), add the parser.
- Around line 143 (`if [[ "$APPLY" -eq 1 ]]; then` before the br set call), add the gate.
- The audit-trail row should carry `{idempotency_key, bead_id, prior_priority, new_priority}`.

**Why P2**: br set produces an audit row each call. Double-escalation isn't catastrophic but creates noise + double-counts in priority-change metrics.

### 6. `.flywheel/scripts/bcv-task-harness.sh` (P2)

**Mutation**: BCV task execution (bead-callback-validation harness).

**Fix recipe**:
- Around line 413 (`--apply) APPLY="1"`), add the parser.
- Around line 455 (where APPLY != 1 triggers dry-run emit_receipt), invert and add the gate before the apply-path branch.
- The audit-trail row should carry `{idempotency_key, task_id, callback_outcome}`.

**Why P2**: harness execution is workflow-side; non-idempotent but rarely re-run accidentally.

### 7. `.flywheel/scripts/jeff-bead-285-divergence-capture.sh` (P3)

**Mutation**: specific divergence-capture beads write.

**Fix recipe**: standard pattern, low frequency. Same as above.

**Why P3**: single-purpose tool, low re-run risk. Adding the gate is still good hygiene but lowest priority.

## Rollout strategy

Do P0 first, then bundle P1 + P2 + P3 as a sweep PR. Each fix is ~10-15 lines per surface (parser + gate + audit-trail wire). Sister fillins from wzjo9.1.x established the helper-lib pattern; surfaces that source `canonical-cli-helpers.sh` get the refusal envelope for free.

## Verification per fix

After each surface gets the gate:

```bash
# Verify refusal contract
<surface> --apply 2>/dev/null
[[ $? -eq 3 ]] || echo "FAIL: refusal exit code"

# Verify gate fires BEFORE mutation (hoqq8 invariant)
<surface> --apply 2>&1 >/dev/null && \
  [[ ! -f <expected-mutation-target> ]] && echo "PASS: gate before side-effect"

# Verify --apply --idempotency-key path works
<surface> --apply --idempotency-key=test-key-$$ --json
```

Add to `tests/<surface-name>-canonical-cli.sh` baseline assertions.

## Lint-time enforcement (orch-action recommendation)

The m12ji evidence noted "lint-time enforcement" as an orch-action recommendation. The current `canonical-cli-lint.sh` has L1-L9 checks. Add **L10: surface has --apply MUST have --idempotency-key parser AND gate**. The regex:

```
- L10-apply-needs-key: surface has `--apply\)` token but no `--idempotency-key` token AND its mutation patterns include any of (git commit, git push, ntm send, br set, br close, write_text on non-tmp path, rm of non-tmp path, cp/mv of non-tmp path).
```

Allowlist exemption: surfaces that ALSO have `apply_not_supported|read_only_bridge` or `mutates_only_with: --apply` doc-comment with `# IDEMPOTENT-BY-CONSTRUCTION:` marker.

Filing this as a separate orch-action recommendation for a follow-up bead.
